/*
 *
 * Copyright (C) 2004, 2005, 2006, 2007, 2008, 2009, 2010
 * NTT Advanced Technology, Yokogawa Electric Corporation.
 * All rights reserved.
 * 
 * Redistribution and use of this software in source and binary
 * forms, with or without modification, are permitted provided that
 * the following conditions and disclaimer are agreed and accepted
 * by the user:
 * 
 * 1. Redistributions of source code must retain the above copyright
 *    notice, this list of conditions and the following disclaimer.
 * 
 * 2. Redistributions in binary form must reproduce the above copyright
 *    notice, this list of conditions and the following disclaimer in
 *    the documentation and/or other materials provided with
 *    the distribution.
 * 
 * 3. Neither the names of the copyrighters, the name of the project
 *    which is related to this software (hereinafter referred to as
 *    "project") nor the names of the contributors may be used to
 *    endorse or promote products derived from this software without
 *    specific prior written permission.
 * 
 * 4. No merchantable use may be permitted without prior written
 *    notification to the copyrighters.
 * 
 * 5. The copyrighters, the project and the contributors may prohibit
 *    the use of this software at any time.
 * 
 * THIS SOFTWARE IS PROVIDED BY THE COPYRIGHTERS, THE PROJECT AND
 * CONTRIBUTORS "AS IS" AND ANY EXPRESS OR IMPLIED WARRANTIES, INCLUDING
 * BUT NOT LIMITED THE IMPLIED WARRANTIES OF MERCHANTABILITY AND FITNESS
 * FOR A PARTICULAR PURPOSE, ARE DISCLAIMED.  IN NO EVENT SHALL THE
 * COPYRIGHTERS, THE PROJECT OR CONTRIBUTORS BE LIABLE FOR ANY DIRECT,
 * INDIRECT, INCIDENTAL, SPECIAL, EXEMPLARY, OR CONSEQUENTIAL DAMAGES
 * (INCLUDING, BUT NOT LIMITED TO, PROCUREMENT OF SUBSTITUTE GOODS OR
 * SERVICES; LOSS OF USE, DATA, OR PROFITS; OR BUSINESS INTERRUPTION)
 * HOWEVER CAUSED AND ON ANY THEORY OF LIABILITY, WHETHER IN CONTRACT,
 * STRICT LIABILITY, OR TORT (INCLUDING NEGLIGENCE OR OTHERWISE) ARISING
 * IN ANY WAY OUT OF THE USE OF THIS SOFTWARE, EVEN IF ADVISED OF THE
 * POSSIBILITY OF SUCH DAMAGE.
 *
 * $TAHI: koi/lib/kSocket/kSocket.c,v 1.79 2007/04/05 07:54:17 akisada Exp $
 *
 * $Id: kSocket.c,v 1.8 2008/12/25 11:50:57 inoue Exp $
 *
 */

/*
  08/4/18 kSocketCheckNewSocket: add dst-port for search parameters
  08/3/18 kSocketOpen: add setsockopt(SO_RCVBUF,SO_SNDBUF)
          kSocketOpenWaitSocket: add setsockopt(SO_RCVBUF,SO_SNDBUF)
*/

#include <errno.h>
#include <netdb.h>
#include <stdio.h>
#include <stdlib.h>
#include <string.h>
#include <unistd.h>

#include <netinet/in.h>

#include <sys/socket.h>
#include <sys/types.h>
#include <sys/un.h>	/* for unix domein socket address structure */
#include <arpa/inet.h>	/* for inet_ntop() */
#include <sys/ioctl.h>
#include <sys/uio.h>
#include <net/if.h>

#include <net/if.h>
#include <netinet/in.h>
#include <arpa/inet.h>
#include <netinet/in_systm.h>
#include <netinet/ip.h>
#include <netinet/ip_icmp.h>
#include <netinet/icmp6.h>

#include <koi.h>

#include "kSocket.h"



/* global variables */
short       g_socket_socketid  = 0;	/* socket id */
SocketInfo *g_socket_start_ptr = NULL;	/* socket table */
SocketInfo *g_socket_last_ptr  = NULL;	/* current last position */

fd_set      g_readfds;			/* original data */
fd_set      g_execfds;			/* you call func with this */



/* static functions */
static int kSocketMakeSocketStatusClose(int);
static bool kSocketSendDataUdp(short, long, unsigned char*);
#ifdef SUPPORT_TLS
static int IsExistSameSocket(unsigned char,
	char, unsigned short, struct in6_addr);
int kSocketTLSSession(struct sockaddr *, struct sockaddr *, int, void **);
char *kAddr2Str(struct sockaddr *);
#endif	/* SUPPORT_TLS */

static unsigned int linkname2ifindex(const unsigned char*);
static int icmp_send(int, const unsigned char*,
		     struct sockaddr*, socklen_t,
		     struct sockaddr*, socklen_t,
		     long, unsigned char*);

const char *inaddr2string(struct in_addr*, char*, int*);
const char *in6addr2string(struct in6_addr*, char*, int*);

/******************************
 * init socket table          *
 ******************************/
int
kSocketInit(void)
{
	SocketInfo *current_position = NULL;
	SocketInfo *next_position    = NULL;
	short       log_socketid     = 0;	/* seve value before free() */

#ifdef DBG_SOCKET
	kdbg("/tmp/dbg_socket.txt", "%s\n", "initializing.");
#endif	/* DBG_SOCKET */

	/* set the NULL to first data pointer */
	/* if there are some data table, clear those. */
	if(g_socket_start_ptr) {
		/* set NULL */
		current_position = g_socket_start_ptr;
		g_socket_start_ptr  = NULL;

		/*
		 * save next position first. and free uniq_data part,next
		 * structure.if next is NULL, it is end so finish
		 */
		for( ; ; ) {
			next_position =
				current_position->si_next_socket_info_ptr;
			/*
			 * free uniq_data part
			 */
			free(current_position->si_uniq_info_ptr);

			kLogWrite(L_DEBUG,
				"%s: socket_id[%d] clear uniq_data part",
				__FUNCTION__, current_position->si_socketid);

			/*
			 * free socketinfo structure
			 */
			log_socketid = current_position->si_socketid;
			free(current_position);
			kLogWrite(L_DEBUG,
				"%s: socket_id [%d] clear SocketInfo",
				__FUNCTION__, log_socketid);

			if(next_position) {
				current_position = next_position;
				continue;
			}

			break;
		}

		kLogWrite(L_DEBUG, "%s: all data cleared", __FUNCTION__);
	} else {
		kLogWrite(L_DEBUG,
			"%s: there is no socket data in table", __FUNCTION__);
	}

	/*
	 * socket id reset
	 */
	g_socket_socketid = 0;
	kLogWrite(L_SOCKET, "%s: socket_id reset done", __FUNCTION__);

	return(RETURN_OK);
}



/******************************************************
 * make fds into or out from g_readfds(Global Value)  *
 * switch option                                      *
 * SELECT_IN  into                                    *
 * SELECT_OUT out                                     *
 ******************************************************/
int
kSocketSelectOperation(int fds, int option)
{
#ifdef DBG_SOCKET
	kdbg("/tmp/dbg_socket.txt", "%s\n", "initializing.");
#endif	/* DBG_SOCKET */
	/*
	 * socket discriptor check
	 */
	if(fds < 0) {
		kLogWrite(L_ERROR,
			 "%s: file discriptor [%d] is invalid. cannot handle it",
			 __FUNCTION__, fds);
		return(RETURN_NG);
	}

	/*
	 * do as option SELECT_IN or SELECT_OUT
	 */
	switch(option) {
		case SELECT_IN:
			FD_SET(fds, &g_readfds);
			kLogWrite(L_DEBUG, "%s: add fd[%d] into select list successfully",
				__FUNCTION__, fds);
			break;
		case SELECT_OUT:
			FD_CLR(fds, &g_readfds);
			kLogWrite(L_DEBUG, "%s: clear fd[%d] from select list successfully",
				__FUNCTION__, fds);
			break;
		default:
			kLogWrite(L_ERROR, "%s: invalid option[%d]. cannot handle it",
				__FUNCTION__, option);
			return(RETURN_NG);
			break;
	}

	return(RETURN_OK);
}



/*--------------------------------------------------------------------*
 * int kSocketOpen(unsigned char, char, unsigned short,               *
 *     struct in6_addr, unsigned short, struct in6_addr,              *
 *     unsigned char *, short, short, short *);                       *
 *--------------------------------------------------------------------*/
/**************************************************************
 * open socket for tcp/child, client and udp.                 *
 * if you want to create socket for listening (TCP/parent)    *
 * use create_wait_socket()                                   *
 **************************************************************/
int
kSocketOpen(
	unsigned char	type,		/* socket type must be child or udp */
	short			tlsmode,	/* TLS */
	char			addressFamily,
	unsigned short	d_port,
	struct in6_addr	d_addr,
	unsigned short	s_port,		/* option */
	struct in6_addr	s_addr,		/* option */
	unsigned char	*linkname,
	short			peyload_type,
	short			flags,
	short			*socketid)	/* return value */
{
	SocketInfo              *socketInfo     = NULL;
	DatasocketInfo          *dataSocketInfo = NULL;

	struct sockaddr_storage  ss;
	struct sockaddr_in6      local_si6;
	struct sockaddr_in       local_si;
	socklen_t                localaddr_len = 0;

	struct addrinfo         *dstRes        = NULL;
	struct addrinfo         *srcRes        = NULL;
	struct addrinfo         *aip           = NULL;
	struct addrinfo          srcHints;
	struct addrinfo          dstHints;
	int                      sockfd        = -1;
	int                      error         = 0;
	char                    *dstAddr       = NULL;
	char                     dstAddrStr[INET6_ADDRSTRLEN];
	char                    *srcAddr       = NULL;
	char                     srcAddrStr[INET6_ADDRSTRLEN];
	char                    *dstHostname   = NULL;
	char                    *srcHostname   = NULL;
	char                     dstPort[32];
	char                     srcPort[32];
	const char              *ifname        = NULL;

	char                     hbuf[NI_MAXHOST];
	char                     sbuf[NI_MAXSERV];
#ifdef SUPPORT_TLS
	void					*tlsssl			= NULL;
#endif	/* SUPPORT_TLS */

	bool multicast = false;
	bool broadcast = false;
	const int on = 1;
	const short BROADCAST_MASK = 0x0001;

	int sndbuf = 0xffff;
	int rcvbuf = 0xffff;

	memset(&ss,         0, sizeof(ss));
	memset(&local_si6,  0, sizeof(local_si6));
	memset(&local_si,   0, sizeof(local_si));
	memset( dstAddrStr, 0, sizeof(dstAddrStr));
	memset( srcAddrStr, 0, sizeof(srcAddrStr));
	memset( dstPort,    0, sizeof(dstPort));
	memset( srcPort,    0, sizeof(srcPort));
	memset( hbuf,       0, sizeof(hbuf));
	memset( sbuf,       0, sizeof(sbuf));
#ifdef DBG_SOCKET
	kdbg("/tmp/dbg_socket.txt", "%s\n", "initializing.");
#endif	/* DBG_SOCKET */
	kLogWrite(L_INFO, "%s: start", __FUNCTION__);

	/* argument check */
	if(!linkname) {
		kLogWrite(L_WARNING,
			"%s: linkname is NULL pointer. abort.", __FUNCTION__);
		return(RETURN_NG);
	}

	if(peyload_type < 1) {
		kLogWrite(L_WARNING,
			"%s: peyload_type must be more than 1. abort.", __FUNCTION__);
		return(RETURN_NG);
	}

	if(!socketid) {
		kLogWrite(L_WARNING,
			"%s: socketid is NULL pointer. abort.", __FUNCTION__);
		return(RETURN_NG);
	}

	if(IN_MULTICAST(&d_addr) || IN6_IS_ADDR_MULTICAST(&d_addr)) {
		multicast = true;
	}

	if(flags & BROADCAST_MASK) {
		broadcast = true;
	}

	kLogWrite(L_DEBUG, "%s: argument check OK", __FUNCTION__);

	/* max socket number check */
	if(g_socket_socketid == SOCKET_MAXNUM) {
		kLogWrite(L_WARNING, "%s: socket number limit [%d]. cannot create more",
			__FUNCTION__, g_socket_socketid);
		return(RETURN_NG);
	}

	kLogWrite(L_DEBUG, "%s: socket number limit passed. current num is [%d]",
		__FUNCTION__, g_socket_socketid);

	/*
	 * create socket as socket type
	 */
	kLogWrite(L_DEBUG, "%s: socket creation", __FUNCTION__);

	if(addressFamily == CM_IP_IPV6) {
		/* dst */
		dstAddr = (char *)inet_ntop(AF_INET6, (void *)&(d_addr),
					    dstAddrStr, INET6_ADDRSTRLEN);
		ifname = kIFGetDevicenameByLinkname(linkname);
		if(!ifname) {
			kLogWrite(L_WARNING, "%s: kIFGetDevicenameByLinkname() failed. "
				"ifname(%s) ifnamelen(%d)",
				__FUNCTION__, ifname, strlen(ifname));
			return(RETURN_NG);
		}

		kLogWrite(L_DEBUG,
			 "%s: kIFGetDevicenameByLinkname() succeed. ifname:%s",
			 __FUNCTION__, ifname);

		dstHostname = (char *)malloc(INET6_ADDRSTRLEN + strlen(ifname) + 1);
		if(IN6_IS_ADDR_LINKLOCAL((const struct in6_addr *)&d_addr)) {
			snprintf(dstHostname,
				 INET6_ADDRSTRLEN+ strlen(ifname)+ 1,
				"%s%%%s", dstAddr, ifname);
		} else {
			snprintf(dstHostname, INET6_ADDRSTRLEN, "%s", dstAddr);
		}

		/* src */
		srcAddr = (char *)inet_ntop(AF_INET6, (void *)&(s_addr),
					    srcAddrStr, INET6_ADDRSTRLEN);
		srcHostname = (char *)malloc(INET6_ADDRSTRLEN);

		if(IN6_IS_ADDR_LINKLOCAL(&s_addr)) {
			snprintf(srcHostname, INET6_ADDRSTRLEN,
				"%s%%%s", srcAddr, ifname);
		} else {
			memcpy(srcHostname, srcAddr, INET6_ADDRSTRLEN);
		}
	} else {
		/* dst */
		dstAddr = (char *)inet_ntop(AF_INET, (void *)&(d_addr),
					    dstAddrStr, INET_ADDRSTRLEN);
		dstHostname = (char *)malloc(INET_ADDRSTRLEN);
		memcpy(dstHostname, dstAddr, INET_ADDRSTRLEN);

		/* src */
		srcAddr = (char *)inet_ntop(AF_INET, (void *)&(s_addr),
				srcAddrStr, INET_ADDRSTRLEN);
		srcHostname = (char *)malloc(INET_ADDRSTRLEN);
		memcpy(srcHostname, srcAddr, INET_ADDRSTRLEN);
	}

	snprintf(dstPort, sizeof(dstPort), "%d", d_port);
	snprintf(srcPort, sizeof(srcPort), "%d", s_port);

	/* get sockaddr for destination */
	memset(&dstHints, 0, sizeof(dstHints));
	dstHints.ai_family =
		(addressFamily == CM_IP_IPV6)? PF_INET6: PF_INET;
	dstHints.ai_socktype =
		(type == SI_TYPE_DATA)? SOCK_STREAM: SOCK_DGRAM;

	if((error = getaddrinfo(dstHostname, dstPort, &dstHints, &dstRes))) {
		kLogWrite(L_WARNING,
			"%s: getaddrinfo failed. error(%d) dstHostname(%s) servname(%s)",
			__FUNCTION__, error, dstHostname, dstPort);
		free(dstHostname);
		return(-1);
	}

	kLogWrite(L_SOCKET,
		"%s: getaddrinfo suceeded. dstHostname(%s)", __FUNCTION__, dstHostname);
	free(dstHostname);

	/* get sockaddr for source */
	memset(&srcHints, 0, sizeof(srcHints));
	srcHints.ai_family =
		(addressFamily == CM_IP_IPV6)? PF_INET6: PF_INET;
	srcHints.ai_socktype =
		(type == SI_TYPE_DATA)? SOCK_STREAM: SOCK_DGRAM;

	if((error = getaddrinfo(srcHostname, srcPort, &srcHints, &srcRes))) {
		kLogWrite(L_WARNING,
			"%s: getaddrinfo failed. error(%d) srcHostname(%s) servname(%s)",
			__FUNCTION__, error, srcHostname, srcPort);
		free(srcHostname);
		return(-1);
	}

	kLogWrite(L_SOCKET, "%s: getaddrinfo suceeded. srcHostname(%s)",
		__FUNCTION__, srcHostname);
	free(srcHostname);

	/* socket() / bind() / connect() */
	for(aip = dstRes; aip; aip = aip->ai_next) {
		if((error = getnameinfo(aip->ai_addr, aip->ai_addrlen,
				hbuf, sizeof(hbuf),
				sbuf, sizeof(sbuf),
				NI_NUMERICHOST | NI_NUMERICSERV))) {

			kLogWrite(L_WARNING,
				 "%s: %s", __FUNCTION__, gai_strerror(error));
			close(sockfd);
			return(RETURN_NG);
		}

		kLogWrite(L_DEBUG, "%s: getnameinfo success: hbuf(%s) sbuf(%s)",
			__FUNCTION__, hbuf, sbuf);

		if((sockfd = socket(aip->ai_family,
			aip->ai_socktype, aip->ai_protocol)) < 0) {

			perror("socket");
			continue;
		}

		if((error = setsockopt(sockfd,
			SOL_SOCKET, SO_REUSEADDR, &on, sizeof(on)))) {

			kLogWrite(L_WARNING,
				"%s: setsockopt(SO_REUSEADDR) fails", __FUNCTION__);
			close (sockfd);
			continue;
		}

		if((error = setsockopt(sockfd,
			SOL_SOCKET, SO_REUSEPORT, &on, sizeof(on)))) {

			kLogWrite(L_WARNING,
				"%s: setsockopt(SO_REUSEPORT) fails", __FUNCTION__);
			close (sockfd);
			continue;
		}

		if((error = setsockopt(sockfd,
			SOL_SOCKET,SO_SNDBUF, &sndbuf, sizeof(sndbuf)))) {

			kLogWrite(L_WARNING,
				"%s: setsockopt(SO_SNDBUF) fails", __FUNCTION__);
			close (sockfd);
			continue;
		}

		if((error = setsockopt(sockfd,
			SOL_SOCKET,SO_RCVBUF, &rcvbuf, sizeof(rcvbuf)))) {

			kLogWrite(L_WARNING,
				"%s: setsockopt(SO_RCVBUF) fails", __FUNCTION__);
			close (sockfd);
			continue;
		}

		if(multicast && (aip->ai_family == AF_INET6)) {
			unsigned int ifindex = 0;

			if(!(ifindex = linkname2ifindex(linkname))) {
				kLogWrite(L_WARNING, "%s: cannot get ifidx", __FUNCTION__);
				close (sockfd);
				continue;
			}

			if((error = setsockopt(sockfd, IPPROTO_IPV6, IPV6_MULTICAST_IF,
					   &ifindex, sizeof(ifindex))) < 0) {
				kLogWrite(L_WARNING,
					"%s: setsockopt(IPV6_MULTICAST_IF) fails", __FUNCTION__);
				close (sockfd);
				continue;
			}

			kLogWrite(L_DEBUG, "%s: setsockopt(IPV6_MULTICAST_IF) succeed "
				"for socket handle[%d], ifindex[%d]", sockfd, ifindex);
		}

		if(multicast && (aip->ai_family == AF_INET)) {
			struct sockaddr_in *sin = NULL;

			sin = (struct sockaddr_in *)&srcRes->ai_addr;

			if((error = setsockopt(sockfd, IPPROTO_IP, IP_MULTICAST_IF,
				&(sin->sin_addr), sizeof(sin->sin_addr))) < 0) {
				kLogWrite(L_WARNING,
					"%s: setsockopt(IP_MULTICAST_IF) fails", __FUNCTION__);
				close (sockfd);
				continue;
			}

			kLogWrite(L_DEBUG, "%s: setsockopt(IP_MULTICAST_IF) succeed "
				"for socket handle[%d]", sockfd);
		}

		if(broadcast) {
			if((error = setsockopt(sockfd, SOL_SOCKET, SO_BROADCAST,
				&on, sizeof(on))) < 0) {

				kLogWrite(L_WARNING,
					"%s: setsockopt(SO_BROADCAST) fails", __FUNCTION__);
				close (sockfd);
				continue;
			}

			kLogWrite(L_DEBUG,
				"%s: setsockopt(SO_BROADCAST) succeed for socket handle[%d]",
				sockfd);
		}

		if(bind(sockfd, srcRes->ai_addr, srcRes->ai_addrlen) < 0) {
			perror("bind");
			freeaddrinfo(dstRes);
			freeaddrinfo(srcRes);
			continue;
		}

		if(connect(sockfd, aip->ai_addr, aip->ai_addrlen) < 0) {
			perror("connect");
			(void)close(sockfd);
			sockfd = -1;
			continue;
		}

		kLogWrite(L_DEBUG,
			"%s: connect OK. socket handle[%d]", __FUNCTION__, sockfd);
#ifdef SUPPORT_TLS
		if(tlsmode){
			/* get re-use TLS connection */
			kSocketTLSSession(srcRes->ai_addr, aip->ai_addr, d_port, &tlsssl);

			if(!(tlsssl=kTLSConnect(sockfd,tlsssl))) {
				perror("connect");
				(void)close(sockfd);
				sockfd = -1;
				continue;
			}
		}
#endif	/* SUPPORT_TLS */

		break;
	}

	memcpy(&ss, dstRes->ai_addr, dstRes->ai_addrlen);
	freeaddrinfo(dstRes);
	freeaddrinfo(srcRes);

	/*
	 * check there is no socket that has same sockethandle
	 * and make sure close
	 */
	kSocketMakeSocketStatusClose(sockfd);

	/* select action */
	if(kSocketSelectOperation(sockfd, SELECT_IN) < 0) {
		kLogWrite(L_WARNING,
			 "%s: error of kSocketSelectOperation", __FUNCTION__);
		close(sockfd);
		return(RETURN_NG);
	}

	/* allocate memory for new SocketInfo space */
	if(!(socketInfo = (SocketInfo*)malloc(sizeof(SocketInfo)))) {
		kLogWrite(L_ERROR,
			 "%s: malloc for new SocketInfo fail", __FUNCTION__);
		kSocketSelectOperation(sockfd,SELECT_OUT); /* recovery */
		close(sockfd);
		return(RETURN_NG);
	}

	memset(socketInfo, 0, sizeof(*socketInfo));
	kLogWrite(L_DEBUG,
		 "%s: allocate memory for SocketInfo structure", __FUNCTION__);

	/* allocate memory for uniq_data part of new SocketInfo */
	if(!(socketInfo->si_uniq_info_ptr
	     = (DatasocketInfo*)malloc(sizeof(DatasocketInfo)))) {
		kLogWrite(L_ERROR,
			"%s: malloc for uniq_data space fail", __FUNCTION__);
		free(socketInfo);
		kSocketSelectOperation(sockfd,SELECT_OUT); /* recovery */
		close(sockfd);
		return(RETURN_NG);
	}
	memset(socketInfo->si_uniq_info_ptr, 0, sizeof(DatasocketInfo));

	kLogWrite(L_DEBUG, "%s: allocate memory for uniq_data", __FUNCTION__);

	/*
	 * set data
	 */
	socketInfo->si_type	= type;

	g_socket_socketid ++;	/* increment for next first start from 1*/
	socketInfo->si_socketid	= g_socket_socketid;

	socketInfo->si_sockethandle = sockfd;
	strcpy((char *)socketInfo->si_linkname, (const char *)linkname);
	socketInfo->si_socket_status = SI_STATUS_ALIVE;
	socketInfo->si_peyload_type = peyload_type;
#ifdef SUPPORT_TLS
	socketInfo->si_tls_mode         = tlsmode;
	socketInfo->si_tls_ssl_ptr      = tlsssl;
#endif	/* SUPPORT_TLS */

	/* pointer change for cast */
	dataSocketInfo = (DatasocketInfo*)socketInfo->si_uniq_info_ptr;
	dataSocketInfo->di_family = ss.ss_family;

	/*
	 * uniq_info DatasocketInfo
	 * this has no source port, address, timeout, parentsocketid
	 * because this is sending socket
	 */
	if(!kParserGet(peyload_type, type, &(dataSocketInfo->di_parser))) {
#ifdef DBG_PARSER
	kdbg("/tmp/dbg_parser.txt", "kParserGet: %s\n", "false");
#endif	/* DBG_PARSER */
		kLogWrite(L_WARNING, "%s: kParserGet fail. abort", __FUNCTION__);

		/* recovery */
		free(socketInfo->si_uniq_info_ptr);
		free(socketInfo);
		g_socket_socketid --;
		kSocketSelectOperation(sockfd, SELECT_OUT);
		close(sockfd);
		return(RETURN_NG);
	}
#ifdef DBG_PARSER
	kdbg("/tmp/dbg_parser.txt", "kParserGet: %s\n", "true");
	kdbg("/tmp/dbg_parser.txt",
		"di_parser: %p\n", dataSocketInfo->di_parser);
#endif	/* DBG_PARSER */
	/* set source port and src addr */
	if(ss.ss_family == PF_INET6) {
		/* dst */
		memcpy(&(local_si6),
		       &ss,
		       sizeof(struct sockaddr_in6));
		dataSocketInfo->di_d_port = ntohs(local_si6.sin6_port);
		memcpy(&(dataSocketInfo->di_d_addr),
		       &local_si6.sin6_addr,
		       sizeof(struct in6_addr));

		/* src */
		localaddr_len = sizeof(local_si6);
		if((getsockname(sockfd, (struct sockaddr*)&local_si6,
				 &localaddr_len)) < 0) {
			kLogWrite(L_WARNING,
				"%s: getsockname for localaddr fail. abort", __FUNCTION__);
			close(sockfd);
			return(RETURN_NG);
		}

		dataSocketInfo->di_s_port = ntohs(local_si6.sin6_port);
		memcpy(&(dataSocketInfo->di_s_addr),
		       &(local_si6.sin6_addr),
		       sizeof(struct in6_addr));
	} else {
		/* dst */
		memcpy(&(local_si),
		       &ss,
		       sizeof(struct sockaddr_in));
		dataSocketInfo->di_d_port = ntohs(local_si.sin_port);
		memcpy(&(dataSocketInfo->di_d_addr),
		       &local_si.sin_addr,
		       sizeof(struct in_addr));

		/* src */
		localaddr_len = sizeof(local_si);
		if((getsockname(sockfd, (struct sockaddr*)&local_si,
				 &localaddr_len)) < 0) {
			kLogWrite(L_WARNING,
				"%s: getsockname for localaddr fail. abort", __FUNCTION__);
			close(sockfd);
			return(RETURN_NG);
		}

		dataSocketInfo->di_s_port = ntohs(local_si.sin_port);
		memcpy(&(dataSocketInfo->di_s_addr),
		       &(local_si.sin_addr),
		       sizeof(struct in_addr));
	}

	/*
	 * connect SocketInfo to linked list
	 */
	if(g_socket_start_ptr) {
		/* last data's next is new */
		g_socket_last_ptr->si_next_socket_info_ptr = socketInfo;
		kLogWrite(L_DEBUG, "%s: SocketInfo added to table", __FUNCTION__);
	} else {
		/* it is first one */
		g_socket_start_ptr = socketInfo;
		kLogWrite(L_DEBUG,
			"%s: SocketInfo added to table. it was first data", __FUNCTION__);
	}

	/* new data's next is NULL */
	socketInfo->si_next_socket_info_ptr = NULL;

	/* now, last data is new */
	g_socket_last_ptr = socketInfo;

	/* return value set */
	*socketid = socketInfo->si_socketid;

	kLogWrite(L_SOCKET,
		"%s: as socket_id[%d]", __FUNCTION__, socketInfo->si_socketid);

	return(RETURN_OK);
}



/******************************************************
 * int                                                *
 * kSocketOpenWaitSocket(unsigned char, short, char,  *
 *     unsigned short, struct in6_addr,               *
 *     unsigned char *, short, short, short *);       *
 ******************************************************/
int
kSocketOpenWaitSocket(
	unsigned char	type,		/* SI_TYPE_LISTEN_TCP or SI_TYPE_LISTEN_UDP */
	short			tlsmode,	/* TLS */
	char			addressFamily,
	unsigned short	s_port,
	struct in6_addr	s_addr,
	unsigned char	*linkname,
	short			peyload_type,
	short			flags,
	short 			*socketid)
{
	SocketInfo	*socketInfo;
	DatasocketInfo	*dataSocketInfo = NULL;
	ListenportInfo	*listenPortInfo = NULL;

	struct sockaddr_storage ss;
	struct sockaddr_in6 local_si6;
	struct sockaddr_in local_si;
	socklen_t localaddr_len = 0;

	int sockfd = -1;
	int error;
	char srcAddrStr[INET6_ADDRSTRLEN];
	char srcPort[32];
	char *srcAddr;
	char *srcHostname;

	struct addrinfo *srcRes, *aip, srcHints;
	char hbuf[NI_MAXHOST], sbuf[NI_MAXSERV];
	const int on = 1;
	char *interface = NULL;
	bool multicast = false;
	bool broadcast = false;
	const short BROADCAST_MASK = 0x0001;
	int sndbuf = 0xffff;
	int rcvbuf = 0xffff;

#ifdef DBG_SOCKET
	kdbg("/tmp/dbg_socket.txt", "%s\n", "initializing.");
#endif	/* DBG_SOCKET */
	kLogWrite(L_SOCKET, "%s: start", __FUNCTION__);

	/* argument check */
	if(peyload_type < 0) {
		kLogWrite(L_WARNING,
			 "%s: peyload_type[%d] must be more than 0. avoid",
			 __FUNCTION__, peyload_type);
		return(RETURN_NG);
	}

	if(!socketid) {
		kLogWrite(L_WARNING,
			 "%s: socketid is NULL pointer. avoid", __FUNCTION__);
		return(RETURN_NG);
	}

	if(!linkname) {
		kLogWrite(L_WARNING,
			"%s: linkname is NULL pointer. avoid", __FUNCTION__);
		return(RETURN_NG);
	}

	if(!(interface = (char *)kIFGetDevicenameByLinkname(linkname))) {
		kLogWrite(L_WARNING,
			 "%s: linkname is NULL pointer. avoid", __FUNCTION__);
		return(RETURN_NG);
	}
#ifdef SUPPORT_TLS
	if(IsExistSameSocket(type, addressFamily, s_port, s_addr)) {
		kLogWrite(L_SOCKET, "%s: Same socket exist", __FUNCTION__);
		return(RETURN_OK);
	}
#endif	/* SUPPORT_TLS */
	if(IN_MULTICAST(&s_addr) || IN6_IS_ADDR_MULTICAST(&s_addr)) {
		multicast = true;
	}

	if (flags & BROADCAST_MASK) {
		broadcast = true;
	}

#ifdef DBG_SOCKET
	kdbg("/tmp/dbg_socket.txt", "interface: %s\n", interface);
#endif	/* DBG_SOCKET */

	/* max socket number check */
	if(g_socket_socketid == SOCKET_MAXNUM) {
		kLogWrite(L_WARNING,
			"%s: socket number limit [%d]. cannot create more",
			__FUNCTION__, g_socket_socketid);
		return(RETURN_NG);
	}

	kLogWrite(L_DEBUG,
		"%s: socket number limit passed. current num is [%d]",
		__FUNCTION__, g_socket_socketid);

#ifdef DBG_SOCKET
	kdmp("/tmp/dbg_socket.txt", "s_addr", &s_addr, sizeof(s_addr));
	kdbg("/tmp/dbg_socket.txt", "ai_passive: %s\n",
		ai_passive? "true": "false");
#endif	/* DBG_SOCKET */

	/* set address and port */
	if(addressFamily == CM_IP_IPV6) {
		/* src */
		srcAddr = (char *)inet_ntop(AF_INET6, (void *)&(s_addr),
					    srcAddrStr, INET6_ADDRSTRLEN);

		srcHostname = (char *)malloc(INET6_ADDRSTRLEN);

		if(IN6_IS_ADDR_LINKLOCAL(&s_addr)) {
#ifdef DBG_SOCKET
			kdbg("/tmp/dbg_socket.txt",
			     "IN6_IS_ADDR_LINKLOCAL: %s\n", "true");
#endif	/* DBG_SOCKET */
			strncpy(srcHostname, srcAddr, INET6_ADDRSTRLEN);
			snprintf(srcHostname, INET6_ADDRSTRLEN,
				"%s%%%s", srcAddr, interface);
		} else {
#ifdef DBG_SOCKET
			kdbg("/tmp/dbg_socket.txt",
			     "IN6_IS_ADDR_LINKLOCAL: %s\n", "false");
#endif	/* DBG_SOCKET */
			strncpy(srcHostname, srcAddr, INET6_ADDRSTRLEN);
		}
	}
	else { /* CM_IP_IPV4 */
		/* src */
		srcAddr = (char*)inet_ntop(AF_INET, (void *)&(s_addr),
			srcAddrStr, INET_ADDRSTRLEN);
		srcHostname = (char*)malloc(INET_ADDRSTRLEN);
		strncpy(srcHostname, srcAddr, INET_ADDRSTRLEN);
	}

	snprintf(srcPort, sizeof(srcPort), "%d", s_port);

#ifdef DBG_SOCKET
	kdbg("/tmp/dbg_socket.txt", "srcHostname: %s\n", srcHostname);
	kdbg("/tmp/dbg_socket.txt", "srcPort: %s\n",     srcPort);
#endif	/* DBG_SOCKET */

	/* get sockaddr for source */
	memset(&srcHints, 0, sizeof(srcHints));

	srcHints.ai_flags    = AI_PASSIVE;
	srcHints.ai_family   = (addressFamily == CM_IP_IPV6)? PF_INET6: PF_INET;
	srcHints.ai_socktype =
		(type == SI_TYPE_LISTEN_TCP) ? SOCK_STREAM : SOCK_DGRAM;

#ifdef DBG_SOCKET
	kdbg("/tmp/dbg_socket.txt",
		"srcHints.ai_socktype: %s\n",
		(type == SI_TYPE_LISTEN_TCP) ? "SOCK_STREAM": "SOCK_DGRAM");
#endif	/* DBG_SOCKET */

	error = getaddrinfo(srcHostname, srcPort, &srcHints, &srcRes);
	
	if(error) {
		kLogWrite(L_WARNING,
			"%s: getaddrinfo failed. error(%d) srcHostname(%s) servname(%s)",
			__FUNCTION__, error, srcHostname, srcPort);
		free(srcHostname);
		return(-1);
	}
	kLogWrite(L_DEBUG,
		 "%s: getaddrinfo suceeded. addressFamily(%c) srcHostname(%s)",
		 __FUNCTION__, addressFamily, srcHostname);
	free(srcHostname);

	/* socket() / bind() / listen() */
	for(aip = srcRes; aip != NULL; aip = aip->ai_next) {
		sockfd = socket(aip->ai_family, aip->ai_socktype,
				aip->ai_protocol);
		if(sockfd == -1) {
			perror("socket");
			continue;
		}

		error = setsockopt(sockfd, SOL_SOCKET, SO_REUSEADDR,
				   &on, sizeof(on));
		if (error) {
			perror("setsockopt");
			close (sockfd);
			continue;
		}

		error = setsockopt(sockfd, SOL_SOCKET, SO_REUSEPORT,
				   &on, sizeof(on));
		if (error) {
			perror("setsockopt");
			close (sockfd);
			continue;
		}

		if (aip->ai_family == AF_INET) {
			error = setsockopt(sockfd, IPPROTO_IP, IP_RECVDSTADDR,
					   &on, sizeof(on));
			if (error) {
				perror("setsockopt");
				close (sockfd);
				continue;
			}
			if(type==SI_TYPE_LISTEN_UDP){
				error = setsockopt(sockfd, IPPROTO_IP, DSTADDR_SOCKOPT, &on, sizeof(on));
				if (error) {
					perror("setsockopt");
					close (sockfd);
				continue;
				}
			}

			error = setsockopt(sockfd, IPPROTO_IP, IP_RECVIF,
					   &on, sizeof(on));
			if (error) {
				perror("setsockopt");
				close (sockfd);
				continue;
			}
		}
		if (aip->ai_family == AF_INET6 && type==SI_TYPE_LISTEN_UDP){
			error = setsockopt(sockfd, IPPROTO_IPV6, DSTADDR_SOCKOPT6, &on, sizeof(on));
			if (error) {
				perror("setsockopt");
				close (sockfd);
			continue;
			}
		}

		if (multicast) {
			if (aip->ai_family == AF_INET) {
				struct ip_mreq mreq;
				struct ifreq ifreq;
				inet_pton(aip->ai_family,
					  srcHostname,
					  &mreq.imr_multiaddr);
				strncpy(ifreq.ifr_name, interface, IFNAMSIZ);

				if (ioctl(sockfd, SIOCGIFADDR, &ifreq) < 0)
					return(-1);
				memcpy(&mreq.imr_interface,
				       &((struct sockaddr_in *) &ifreq.ifr_addr)->sin_addr,
				       sizeof(struct in_addr));
				error = setsockopt(sockfd, IPPROTO_IP,
						   IP_ADD_MEMBERSHIP,
						   &mreq, sizeof(mreq));
				if (error) {
					perror("setsockopt IP_ADD_MEMBERSHIP");
					close (sockfd);
					continue;
				}

				kLogWrite(L_INFO, "%s: multicast", __FUNCTION__);
			}
			else if(aip->ai_family == AF_INET6) {
				struct ipv6_mreq mreq6;
				mreq6.ipv6mr_interface = if_nametoindex(interface);
				inet_pton(aip->ai_family, srcHostname,
					  &mreq6.ipv6mr_multiaddr);

#ifdef __FreeBSD__
				error = setsockopt(sockfd, IPPROTO_IPV6,
						   IPV6_JOIN_GROUP,
						   &mreq6, sizeof(mreq6));
#else
				error = setsockopt(sockfd, IPPROTO_IPV6,
						   IPV6_ADD_MEMBERSHIP,
						   &mreq6, sizeof(mreq6));
#endif /* __FreeBSD__ */

				if (error < 0) {
					perror("setsockopt IPV6_JOIN_GROUP");
					close(sockfd);
					continue;
				}

				kLogWrite(L_INFO, "%s: multicast6", __FUNCTION__);
			}
		}

		if (broadcast) {
			error = setsockopt(sockfd, SOL_SOCKET, SO_BROADCAST,
					   &on, sizeof(on));
			if (error) {
				perror("setsockopt broadcast");
				close (sockfd);
				continue;
			}
		}

		if(type==SI_TYPE_LISTEN_UDP){
			if((error = setsockopt(sockfd,
				SOL_SOCKET,SO_SNDBUF, &sndbuf, sizeof(sndbuf)))) {

				kLogWrite(L_WARNING,
					"%s: setsockopt(SO_SNDBUF) fails", __FUNCTION__);
				close (sockfd);
				continue;
			}

			if((error = setsockopt(sockfd,
				SOL_SOCKET,SO_RCVBUF, &rcvbuf, sizeof(rcvbuf)))) {

				kLogWrite(L_WARNING,
					"%s: setsockopt(SO_RCVBUF) fails", __FUNCTION__);
				close (sockfd);
				continue;
			}
		}
		
		if(bind(sockfd, aip->ai_addr, aip->ai_addrlen) < 0) {
			perror("bind");
			kLogWrite(L_WARNING, "%s: bind() fail. sockfd(%d) error(%d)",
				 __FUNCTION__, sockfd, errno);
			close(sockfd);
			sockfd = -1;
			continue;
		}

		error = getnameinfo(aip->ai_addr, aip->ai_addrlen,
				    hbuf, sizeof(hbuf),
				    sbuf, sizeof(sbuf),
				    NI_NUMERICHOST | NI_NUMERICSERV);
		if(error) {
			kLogWrite(L_WARNING,
				 "%s: %s", __FUNCTION__, gai_strerror(error));
			close(sockfd);
			return(RETURN_NG);
		}

		if(aip->ai_socktype == SOCK_DGRAM) {
			kLogWrite(L_INFO, "%s: listen to %s %s", __FUNCTION__, hbuf, sbuf);
			break;
		}

		if(listen(sockfd, 5) < 0) {
			close(sockfd);
			sockfd = -1;
			continue;
		}

		kLogWrite(L_INFO, "%s: listen to %s %s", __FUNCTION__, hbuf, sbuf);
		/*break;*/
	}

	if(sockfd < 0) {
		freeaddrinfo(srcRes);
		kLogWrite(L_WARNING, "%s: can't open socket", __FUNCTION__);
		return(RETURN_NG);
	}

	memcpy(&ss, srcRes->ai_addr, srcRes->ai_addrlen);
	freeaddrinfo(srcRes);

	/* make sure socket is close */
	kSocketMakeSocketStatusClose(sockfd);

	/* select action */
	if((kSocketSelectOperation(sockfd, SELECT_IN)) < 0) {
		kLogWrite(L_WARNING,
			"%s: kSocketSelectOperation() error", __FUNCTION__);
		close(sockfd);
		return(RETURN_NG);
	}

	/* unique data generation */
        /* allocate memory for new SocketInfo space */
	if(!(socketInfo = (SocketInfo*)malloc(sizeof(SocketInfo)))) {
                kLogWrite(L_ERROR,
					"%s: malloc for new SocketInfo fail", __FUNCTION__);
                kSocketSelectOperation(sockfd, SELECT_OUT); /* recovery */
                close(sockfd);
                return(RETURN_NG);
        }

        memset(socketInfo, 0, sizeof(*socketInfo));
        kLogWrite(L_DEBUG,
			"%s: allocate memory for SocketInfo structure", __FUNCTION__);

        /* allocate memory for uniq_data part of new SocketInfo structure */
	switch(type) {
	case SI_TYPE_LISTEN_TCP:
		socketInfo->si_uniq_info_ptr =
			(ListenportInfo *)malloc(sizeof(ListenportInfo));
		if(!socketInfo->si_uniq_info_ptr) {
			kLogWrite(L_ERROR,
				"%s: malloc for uniq_data space fail", __FUNCTION__);

			free(socketInfo);
			/* recovery */
			kSocketSelectOperation(sockfd, SELECT_OUT);
			close(sockfd);
			return(RETURN_NG);
		}

		memset(socketInfo->si_uniq_info_ptr, 0,
		       sizeof(ListenportInfo));
		kLogWrite(L_DEBUG, "%s: allocate memory for uniq_data", __FUNCTION__);

		listenPortInfo =
			(ListenportInfo *)socketInfo->si_uniq_info_ptr;
		break;

	case SI_TYPE_LISTEN_UDP:
		socketInfo->si_uniq_info_ptr
			= (DatasocketInfo*)malloc(sizeof(DatasocketInfo));
		if(!socketInfo->si_uniq_info_ptr) {
			kLogWrite(L_ERROR,
				"%s: malloc for uniq_data space fail", __FUNCTION__);
			free(socketInfo);

			/* recovery */
			kSocketSelectOperation(sockfd,SELECT_OUT);
			close(sockfd);
			return(RETURN_NG);
		}

		memset(socketInfo->si_uniq_info_ptr, 0,
		       sizeof(DatasocketInfo));

		kLogWrite(L_DEBUG,
			"%s: allocate memory for uniq_data", __FUNCTION__);

		dataSocketInfo = (DatasocketInfo *)
			socketInfo->si_uniq_info_ptr;
		break;

	default:
		kLogWrite(L_ERROR,
			"%s: invalid Socketinfo type(%d)", __FUNCTION__, type);
		return(RETURN_NG);
	}

	/* set data */
	socketInfo->si_type = type;

	g_socket_socketid ++;	/* increment for next first start from 1*/
	socketInfo->si_socketid	= g_socket_socketid;

	socketInfo->si_sockethandle	= sockfd;
	strcpy((char *)socketInfo->si_linkname, (const char *)linkname);
	socketInfo->si_socket_status	= SI_STATUS_ALIVE;
	socketInfo->si_peyload_type	= peyload_type;
	socketInfo->si_tls_mode 	= tlsmode;

	if(ss.ss_family == PF_INET6) {
		/* src */
		localaddr_len = sizeof(local_si6);
		if((getsockname(sockfd, (struct sockaddr*)&local_si6,
				&localaddr_len)) < 0) {
			kLogWrite(L_WARNING,
				"%s: getsockname for localaddr fail. abort", __FUNCTION__);
			close(sockfd);
			return(RETURN_NG);
		}
	} else {  /* PF_INET */
		/* src */
		localaddr_len = sizeof(local_si);
		if((getsockname(sockfd, (struct sockaddr*)&local_si,
				&localaddr_len)) < 0) {
			kLogWrite(L_WARNING,
				"%s: getsockname for localaddr fail. abort", __FUNCTION__);
			close(sockfd);
			return(RETURN_NG);
		}
	}

	switch(type) {
	case SI_TYPE_LISTEN_TCP:
		listenPortInfo->li_family = ss.ss_family;

		if(listenPortInfo->li_family == PF_INET6) {
			listenPortInfo->li_s_port =
				ntohs(local_si6.sin6_port);

			memcpy(&(listenPortInfo->li_s_addr),
			       &(local_si6.sin6_addr),
			       sizeof(struct in6_addr));
		} else {
			listenPortInfo->li_s_port =
				ntohs(local_si.sin_port);

			memcpy(&(listenPortInfo->li_s_addr),
			       &(local_si.sin_addr),
			       sizeof(struct in_addr));
		}
		break;

	case SI_TYPE_LISTEN_UDP:
		dataSocketInfo->di_family = ss.ss_family;

		if(dataSocketInfo->di_family == PF_INET6) {
			dataSocketInfo->di_s_port =
				ntohs(local_si6.sin6_port);

			memcpy(&(dataSocketInfo->di_s_addr),
			       &(local_si6.sin6_addr),
			       sizeof(struct in6_addr));
		} else {
			dataSocketInfo->di_s_port =
				ntohs(local_si.sin_port);

			memcpy(&(dataSocketInfo->di_s_addr),
			       &(local_si.sin_addr),
			       sizeof(struct in_addr));
		}

		if(!kParserGet(peyload_type, type,
			       &(dataSocketInfo->di_parser))) {
#ifdef DBG_PARSER
			kdbg("/tmp/dbg_parser.txt",
			     "kParserGet: %s\n", "false");
#endif	/* DBG_PARSER */
			kLogWrite(L_WARNING,
				"%s: get parser for uniq_info.abort", __FUNCTION__);

			free(dataSocketInfo);
			free(socketInfo);
			kSocketSelectOperation(sockfd,SELECT_OUT);
			close(sockfd);
			return(RETURN_NG);
		}
#ifdef DBG_PARSER
		kdbg("/tmp/dbg_parser.txt", "kParserGet: %s\n", "true");
		kdbg("/tmp/dbg_parser.txt",
		     "di_parser: %p\n", dataSocketInfo->di_parser);
#endif	/* DBG_PARSER */
		break;

	default:
		/* NOTREACHED */
		break;
	}

	/* append SocketInfo to linked list */
	if(g_socket_start_ptr) {
		/* new last data */
		g_socket_last_ptr->si_next_socket_info_ptr = socketInfo;
		kLogWrite(L_DEBUG, "%s: SocketInfo added to table", __FUNCTION__);
	} else {
		/* first one */
		g_socket_start_ptr = socketInfo;
		kLogWrite(L_DEBUG,
			"%s: SocketInfo added to table. it was first data", __FUNCTION__);
	}

	socketInfo->si_next_socket_info_ptr = NULL;
	g_socket_last_ptr = socketInfo;
	*socketid = socketInfo->si_socketid;

	kLogWrite(L_INFO,
		"%s: as socket_id[%d]", __FUNCTION__, socketInfo->si_socketid);
	return(RETURN_OK);
}



/**********************************************************************
 * kSocketOpenUnixdSocket()                                           *
 * open socket for unix domain. It is used by only main() in koid.c.  *
 * exported from open_wait_socket() to simplify it.                   *
 * if the other type is needed, kSocketOpen() or                      *
 *     kSocketOpenWaitSocket() is used.                               *
 * XXX: still include redundant                                       *
 **********************************************************************/
int
kSocketOpenUnixdSocket(
	char  *socketpath,	/* path for UNIX domain */
	short  peyload_type,	/* may be just P_COMMAND value */
	short *socketid)	/* return value */
{
	unsigned char  type       = SI_TYPE_UNIX;
	int            fd         = 0;
	char           path[256];	/* if socketpath is null, set default */
	SocketInfo    *new        = NULL;
				/* new SocketInfo created in this func */
	UnixdInfo     *temp_unixd = NULL;	/* pointer for cast uniq_info */

	struct sockaddr_un  uaddr;		/* for unix domain socket */

	memset( path,   0, sizeof(path));
	memset(&uaddr,  0, sizeof(uaddr));
#ifdef DBG_SOCKET
	kdbg("/tmp/dbg_socket.txt", "%s\n", "initializing.");
#endif	/* DBG_SOCKET */
	kLogWrite(L_INFO, "%s: start", __FUNCTION__);

	/* if prot is UNIX, create waiting socket  */
	kLogWrite(L_DEBUG, "%s: socket type is UNIX domain socket", __FUNCTION__);

	/*
	 * set path
	 * if inputed path is NULL, use default
	 * if not, use inputed path
	 */
	strcpy(path, socketpath? socketpath: _PATH_SOCKET);

	kLogWrite(L_INIT,
		"%s: set [%s] as unix domain path name", __FUNCTION__, path);

	/*
	 * socket
	 */
	if((fd = socket(AF_UNIX, SOCK_STREAM, 0)) < 0) {
		kLogWrite(L_WARNING,
			 "%s: cannot create socket UNIX. abort. errno is [%d]",
			 __FUNCTION__, errno);
		return(RETURN_NG);
	}

	kLogWrite(L_DEBUG, "%s: socket() OK. socket handle[%d]", __FUNCTION__, fd);

	/*
	 * bind
	 */
	/* remove file to make sure that there is no path file */
	unlink(path);
	kLogWrite(L_DEBUG, "%s: unlink [%s] done", __FUNCTION__, path);

	/* addrres set */
	uaddr.sun_family = AF_UNIX;
	strcpy(uaddr.sun_path, path);

	/* bind */
	if((bind(fd, (struct sockaddr*)&uaddr, sizeof(uaddr))) < 0) {
		kLogWrite(L_WARNING,
			"%s: bind fail. errno is [%d]", __FUNCTION__, errno);
		close(fd);
		return(RETURN_NG);
	}

	kLogWrite(L_DEBUG, "%s: bind() OK. socket handle[%d]", __FUNCTION__, fd);

	/* listen */
	if((listen(fd, SOCKET_BACKLOG)) < 0) {
		kLogWrite(L_WARNING,
			"%s: listen fail.errno is [%d]", __FUNCTION__, errno);
		close(fd);
		return(RETURN_NG);
	}

	kLogWrite(L_DEBUG, "%s: listen() OK. handle is [%d]", __FUNCTION__, fd);

	/* make sure socket is close */
	kSocketMakeSocketStatusClose(fd);

	/*
	 * select action
	 */
	if((kSocketSelectOperation(fd,SELECT_IN)) < 0) {
		kLogWrite(L_WARNING,
			"%s: error of kSocketSelectOperation", __FUNCTION__);
		close(fd);
		return(RETURN_NG);
	}

	/* data generation */

	/*
	 * allocate memory for new SocketInfo space
	 */
	if(!(new = (SocketInfo*)malloc(sizeof(SocketInfo)))) {
		kLogWrite(L_ERROR, "%s: malloc for new SocketInfo fail", __FUNCTION__);
		kSocketSelectOperation(fd,SELECT_OUT); /* recovery */
		close(fd);
		return(RETURN_NG);
	}

	kLogWrite(L_DEBUG,
		"%s: allocate memory for SocketInfo structure", __FUNCTION__);
	memset(new, 0, sizeof(*new));

	/*
	 * allocate memory for uniq_data part of new SocketInfo structure
	 */
	if(!(new->si_uniq_info_ptr
	     = (UnixdInfo*)malloc(sizeof(UnixdInfo)))) {

		kLogWrite(L_ERROR,
			"%s: malloc for uniq_data[UNIX] space fail", __FUNCTION__);
		free(new);
		kSocketSelectOperation(fd,SELECT_OUT); /* recovery */
		close(fd);
		return(RETURN_NG);
	}

	kLogWrite(L_DEBUG, "%s: allocate memory for uniq_data[UNIX]", __FUNCTION__);

	memset(new->si_uniq_info_ptr, 0, sizeof(UnixdInfo));

	/* pointer change for cast and complete uniq_info */
	temp_unixd = (UnixdInfo*)new->si_uniq_info_ptr;
	strcpy((char *)temp_unixd->ui_sockpath, path);

	/****************************************************
	 * warning    UNIX domein socket "don't need" parser*
	 * because those dispater is prepared for
	 * fd_command_action()
	 ****************************************************/
	kLogWrite(L_DEBUG, "%s: complete uniq_info for unixd done", __FUNCTION__);

	/*
	 * generate general part of structure
	 */
	new->si_type = type;

	g_socket_socketid ++;	/* increment for next start from 1 */
	new->si_socketid      = g_socket_socketid;
	new->si_sockethandle  = fd;
	new->si_socket_status = SI_STATUS_ALIVE;
	new->si_peyload_type  = peyload_type;

	/*
	 * connect SocketInfo to linked list
	 */
	if(g_socket_start_ptr) {
		/* last data's next is new */
		g_socket_last_ptr->si_next_socket_info_ptr = new;
		kLogWrite(L_DEBUG, "%s: SocketInfo added to table", __FUNCTION__);
	} else {
		/* it is first one */
		g_socket_start_ptr = new;
		kLogWrite(L_DEBUG,
			"%s: SocketInfo added to table. it was first data", __FUNCTION__);
	}

	/* new data's next is NULL */
	new->si_next_socket_info_ptr = NULL;

	/* now, last data is new */
	g_socket_last_ptr = new;

	/* return value set */
	*socketid = new->si_socketid;
	kLogWrite(L_INFO, "%s: as socket_id[%d]", __FUNCTION__, new->si_socketid);

	return(RETURN_OK);
}



/**********************
 * kSocketClose()     *
 **********************/
int
kSocketClose(short socketid)
{
	SocketInfo	*si = NULL;
	int		loop;
	SocketInfo	socketinfo;
	UnixdInfo	unixdinfo;
	DatasocketInfo	datasocketinfo;
	ListenportInfo	listenportinfo;
#ifdef DBG_SOCKET
	kdbg("/tmp/dbg_socket.txt", "%s\n", "initializing.");
#endif	/* DBG_SOCKET */
	kLogWrite(L_INFO, "%s: start to close socoketid [%d]---------------------",
		__FUNCTION__, socketid);

	/*
	 * check socketid
	 */
	if(socketid < 0) {
		kLogWrite(L_WARNING,
			"%s: invalid socketid [%d]", __FUNCTION__, socketid);
		return(RETURN_NG);
	}

	/* get si by socketid if socketid is not 0 */
	if(socketid &&
	    (kSocketGetSIBySocketId(socketid,
				    &socketinfo,
				    &unixdinfo,
				    &datasocketinfo,
				    &listenportinfo)) < 0) {
		kLogWrite(L_INFO,
			"%s: get_si_by_socketid fail. abort", __FUNCTION__);
		return(RETURN_NG);
	}

	/*
	 * close socket
	 * pattern 1 socketid 0
	 *     -> close all sockets
	 * pattern 2 socket_type is TCP/LISTEN
	 *     -> close socket which has inputed socketid as
	 *        parent_socket and close inputed socket
	 * pattenr 3 other
	 *     -> just close socket
	 */

	/* get SocketInfo into pointer[si] */
	si = g_socket_start_ptr;
	if(!si) {
		kLogWrite(L_INFO, "%s: no socket in table", __FUNCTION__);
		return(RETURN_NG);
	}

	/********** pattern 1 ***********/
	if(socketid == 0) {
		kLogWrite(L_DEBUG,
			"%s: [pattern1] start to clear all sockets", __FUNCTION__);

		for(loop = 0; loop < SOCKET_MAXNUM; loop ++) {

			/* close socket if connection is alive */
			if(si->si_socket_status == SI_STATUS_CLOSE) {
				kLogWrite(L_DEBUG,
					"%s: socketid[%d] is already closed",
					__FUNCTION__, si->si_socketid);

				if(si->si_next_socket_info_ptr == NULL) {
					kLogWrite(L_DEBUG, "%s: finish", __FUNCTION__);

					break;
				}
				si = si->si_next_socket_info_ptr;

				continue;
			}

			/* protect UNIX socket */
			if((si->si_type == SI_TYPE_UNIX) ||
			    (si->si_type == SI_TYPE_UNIX_DATA)) {
				kLogWrite(L_DEBUG,
					"%s: socketid[%d] cannot close UNIX sockets. ",
					__FUNCTION__, si->si_socketid);

				if(si->si_next_socket_info_ptr == NULL) {
					kLogWrite(L_DEBUG, "%s: finish", __FUNCTION__);
					break;
				}
				si = si->si_next_socket_info_ptr;

				continue;
			}

			if((close(si->si_sockethandle)) < 0) {
				kLogWrite(L_WARNING,
					"%s: close() fail. errno is [%d]", __FUNCTION__, errno);
				if(si->si_next_socket_info_ptr == NULL) {
					kLogWrite(L_DEBUG, "%s: finish", __FUNCTION__);
					break;
				}
				si = si->si_next_socket_info_ptr;

				continue;
			} else {
				kLogWrite(L_DEBUG,
					"%s: close() success. id[%d] handle[%d] type[%d]",
					__FUNCTION__,
					si->si_socketid, si->si_sockethandle, si->si_type);
			}

			/*
			 * select action
			 */
			kSocketSelectOperation(si->si_sockethandle, SELECT_OUT);

			/*
			 * update SocketInfomation
			 */
			si->si_socket_status = SI_STATUS_CLOSE;
			kLogWrite(L_DEBUG,
				"%s: socket status is changed to CLOSE", __FUNCTION__);

			/* go next */
			if(si->si_next_socket_info_ptr == NULL) {
				kLogWrite(L_DEBUG, "%s: finish", __FUNCTION__);
				break;
			}

			si = si->si_next_socket_info_ptr;
		}
	}
	else if(socketinfo.si_type == SI_TYPE_LISTEN_TCP) {
		/************ pattern 2 ***************/
		kLogWrite(L_DEBUG, "%s: [pattern2]", __FUNCTION__);

		for(loop = 0; loop < g_socket_socketid; loop ++) {
			/* close socket if connection is alive */
			if(si->si_socket_status == SI_STATUS_CLOSE) {

				kLogWrite(L_DEBUG, "%s: socketid[%d] is already closed",
					__FUNCTION__, si->si_socketid);

				if(si->si_next_socket_info_ptr == NULL) {
					kLogWrite(L_DEBUG, "%s: finish", __FUNCTION__);
					break;
				}
				si = si->si_next_socket_info_ptr;

				continue;
			}

			/* protect UNIX socket */
			if((si->si_type == SI_TYPE_UNIX) ||
			    (si->si_type == SI_TYPE_UNIX_DATA)) {

				kLogWrite(L_DEBUG,
					"%s: socketid[%d] cannot close UNIX sockets.",
					__FUNCTION__, si->si_socketid);

				if(si->si_next_socket_info_ptr == NULL) {
					kLogWrite(L_DEBUG, "%s: finish", __FUNCTION__);
					break;
				}
				si = si->si_next_socket_info_ptr;

				continue;
			}

			kSocketGetSIBySocketId(si->si_socketid,
					       &socketinfo,
					       &unixdinfo,
					       &datasocketinfo,
					       &listenportinfo);

			/******* condition for judgement ************/
			/* whether just socket or not */
			/* whther tcp/child and parent socketid equals
			 *  inputed socketid or not */
			if((si->si_socketid == socketid) ||
			    ((socketinfo.si_type == SI_TYPE_DATA) ||
			     (datasocketinfo.di_parent_socketid == socketid))) {
				if((close(si->si_sockethandle)) < 0) {
					kLogWrite(L_WARNING,
						"%s: close() fail. errno is [%d]", __FUNCTION__, errno);
					if(!(si->si_next_socket_info_ptr)) {
						kLogWrite(L_DEBUG, "%s: finish", __FUNCTION__);
						break;
					}
					si = si->si_next_socket_info_ptr;
					continue;
				} else {
					kLogWrite(L_DEBUG,
						"%s: close() success. id[%d] handle[%d] type[%d]",
						 __FUNCTION__,
						 si->si_socketid, si->si_sockethandle, si->si_type);
				}
			} else {
				if(!(si->si_next_socket_info_ptr)) {
					kLogWrite(L_DEBUG, "%s: finish", __FUNCTION__);
					break;
				}
				si = si->si_next_socket_info_ptr;
				continue;
			}
			/***************************************************/

			/*
			 * select action
			 */
			kSocketSelectOperation(si->si_sockethandle, SELECT_OUT);

			/*
			 * update SocketInfomation
			 */
			si->si_socket_status = SI_STATUS_CLOSE;
			kLogWrite(L_DEBUG,
				"%s: socket status is changed to CLOSE", __FUNCTION__);

			/* go next */
			if(si->si_next_socket_info_ptr == NULL) {
				kLogWrite(L_DEBUG, "%s: finish", __FUNCTION__);
				break;
			}
			si = si->si_next_socket_info_ptr;
		}

	}
	else {
		/************ pattern 3 ***************/
		kLogWrite(L_DEBUG, "%s: [pattern3]", __FUNCTION__);

		for(loop = 0; loop < SOCKET_MAXNUM; loop ++) {
			if(si->si_socketid != socketid) {
				/* go next */
				if(!(si->si_next_socket_info_ptr)) {
					kLogWrite(L_DEBUG, "%s: cannot find socketid [%d] in table",
						 __FUNCTION__, socketid);
					return(RETURN_NG);
				}

				si = si->si_next_socket_info_ptr;
				continue;
			}

			/* protect UNIX socket, but UNIX_DATA is OK */
			if(si->si_type == SI_TYPE_UNIX) {
				/*
				 * socket is UNIX domein
				 * you cannot close this soket
				 */
				kLogWrite(L_DEBUG,
					"%s: socketid[%d] cannot close UNIX sockets. ",
					__FUNCTION__, si->si_socketid);

				return(RETURN_NG);
			}

			/* close socket if connection is alive */
			if(si->si_socket_status == SI_STATUS_CLOSE) {
				kLogWrite(L_DEBUG, "%s: socketid[%d] is already closed",
					__FUNCTION__, si->si_socketid);
				return(RETURN_NG);
			}

			if((close(si->si_sockethandle)) < 0) {
				kLogWrite(L_WARNING,
					"%s: close() fail. errno is [%d]", __FUNCTION__, errno);
				return(RETURN_NG);
			} else {
				kLogWrite(L_DEBUG,
					 "%s: close() success. id[%d] handle[%d] type[%d]",
					 __FUNCTION__,
					 si->si_socketid, si->si_sockethandle, si->si_type);
			}

			/*
			 * select action
			 */
			kSocketSelectOperation(si->si_sockethandle,
					       SELECT_OUT);

			/*
			 * update SocketInfomation
			 */
			si->si_socket_status = SI_STATUS_CLOSE;
			kLogWrite(L_INFO,
				 "%s: socket status is changed to CLOSE", __FUNCTION__);

			/* reach here means end */
			break;
		} /* for */
	} /* outer */

	return(RETURN_OK);
}


static unsigned int
linkname2ifindex(const unsigned char *linkname)
{
	char *ifname;
	ifname = (char *)kIFGetDevicenameByLinkname(linkname);
	if (ifname == NULL) {
		kLogWrite(L_ERROR,
			"%s: invalid linkname[%s].", __FUNCTION__, linkname);
		return(0);
	}

	return(if_nametoindex(ifname));
}

/******************************
 * kSocketSend                *
 * send data with socketid    *
 ******************************/
int
kSocketSend(
	short           socketid,
	long            datalen,
	unsigned char  *data,
	long           *dataid,		/* return value */
	struct timeval *timestamp)	/* return value */
{
	SocketInfo     socketinfo;
	DatasocketInfo datasocketinfo;
	struct timeval time_value;
#ifdef DBG_SOCKET
	kdbg("/tmp/dbg_socket.txt", "%s\n", "initializing.");
#endif	/* DBG_SOCKET */
	kLogWrite(L_INFO, "%s: start for socketid[%d]-------------------------",
		__FUNCTION__, socketid);

	/*
	 * argument check
	 */
	if(socketid < 1) {
		kLogWrite(L_INFO, "%s: invalid socoketid [%d]", __FUNCTION__, socketid);
		return(RETURN_NG);
	}

	if(!data) {
		kLogWrite(L_INFO, "%s: data is NULL. abort", __FUNCTION__);
		return(RETURN_NG);
	}

	if(!dataid) {
		kLogWrite(L_INFO, "%s: dataid is NULL. abort", __FUNCTION__);
		return(RETURN_NG);
	}

	if(!timestamp) {
		kLogWrite(L_INFO, "%s: timestamp is NULL. abort", __FUNCTION__);
		return(RETURN_NG);
	}

	/*
	 * get socket info and check type where tcp/child or udp
	 * if socket type is unix/listen, abort
	 */
	if((kSocketGetSIBySocketId(socketid, &socketinfo, NULL,
				   &datasocketinfo, NULL)) < 0) {
		kLogWrite(L_INFO, "%s: socketid[%d]'s type is not data/udp. abort",
			__FUNCTION__, socketid);
		return(RETURN_NG);
	}

	if(socketinfo.si_type == SI_TYPE_DATA) {
		/*
		 * if tcp/child just send()
		 * and get current time for kDataRegist()
		 */
		kLogWrite(L_DEBUG, "%s: socket is tcp/data socket", __FUNCTION__);

#ifdef SUPPORT_TLS
		if(socketinfo.si_tls_mode){
		  /* send TLS */
		  if(socketinfo.si_tls_ssl_ptr){
		    if( kTLSSend(socketinfo.si_tls_ssl_ptr, (char*)data, datalen) < 0 ){
		      kLogWrite(L_WARNING,"%s: TLS send() fail. errno is [%d]",  __FUNCTION__, errno);
		      return(RETURN_NG);
		    }
		    kLogWrite(L_IO, "%s: TLS size[%d] socketID[%d] send OK",__FUNCTION__,datalen,socketinfo.si_socketid);
		  }
		  else{
		    kLogWrite(L_WARNING, "%s: TLS ssl is empty,so can't send socketID[%d]",__FUNCTION__,socketinfo.si_socketid);
		  }
		}
		else{
		/* send TCP */
		  if((send(socketinfo.si_sockethandle, data, datalen, 0)) < 0) {
			kLogWrite(L_WARNING,
				"%s: send() fail. errno is [%d]", __FUNCTION__, errno);
			return(RETURN_NG);
		  }
		  kLogWrite(L_IO, "%s: TCP send() OK", __FUNCTION__);
		}
#else
		/* send TCP */
		if((send(socketinfo.si_sockethandle, data, datalen, 0)) < 0) {
		  kLogWrite(L_WARNING,
			    "%s: send() fail. errno is [%d]", __FUNCTION__, errno);
		  return(RETURN_NG);
		}
		kLogWrite(L_IO, "%s: send() OK", __FUNCTION__);
#endif
	}
	else if(socketinfo.si_type == SI_TYPE_UDP) {
		/*
		 * if udp, get d_port and d_address from datasocketinfo
		 * ando sendto()
		 */
		kLogWrite(L_DEBUG, "%s: socket is udp socket", __FUNCTION__);

		if(!kSocketSendDataUdp(socketid, datalen, data)) {
 			return(RETURN_NG);
 		}
 	}
	else if (socketinfo.si_type == SI_TYPE_RAW) {
		icmp_send(socketinfo.si_sockethandle,
			  socketinfo.si_linkname,
			  (struct sockaddr *)&datasocketinfo.di_sss_addr,
			  datasocketinfo.di_sss_addr.ss_len,
			  (struct sockaddr *)&datasocketinfo.di_ssd_addr,
			  datasocketinfo.di_ssd_addr.ss_len,
			  datalen,
			  data);
	}
	

	/* generate current time */
	gettimeofday(&time_value, NULL);

	/*
	 *  regist data
	 */
	if(kDataRegist(socketinfo.si_socketid,
		       MSG_SOCKETMODE_SEND, datalen, data, time_value) < 0) {
		kLogWrite(L_INFO, "%s: kDataRegist() fail. abort", __FUNCTION__);
		return(RETURN_NG);
	}

	kLogWrite(L_DEBUG, "%s: kSocketSend end", __FUNCTION__);

	/*
	 * return data
	 */
	*timestamp	= time_value;
	*dataid		= g_msg_dataid;
	kLogWrite(L_INFO, "%s: dataid is [%ld]", __FUNCTION__, g_msg_dataid);

	return(RETURN_OK);
}



static bool
kSocketSendDataUdp(short socketid, long datalen, unsigned char *data)
{
	struct sockaddr_in6  sin6;
	struct sockaddr_in   sin;
	SocketInfo           socketinfo;
	DatasocketInfo       datasocketinfo;

	char dstaddr[NI_MAXHOST];
	char dstport[NI_MAXSERV];
	char *interface = NULL;
	struct addrinfo hints;
	struct addrinfo *res = NULL;
	int error = 0;

	memset(&sin6,           0, sizeof(sin6));
	memset(&sin,            0, sizeof(sin));
	memset(&socketinfo,     0, sizeof(socketinfo));
	memset(&datasocketinfo, 0, sizeof(datasocketinfo));

	memset( dstaddr, 0, sizeof(dstaddr));
	memset( dstport, 0, sizeof(dstport));
	memset(&hints,   0, sizeof(hints));
#ifdef DBG_SOCKET
	kdbg("/tmp/dbg_socket.txt", "%s\n", "initializing.");
#endif	/* DBG_SOCKET */
	if((kSocketGetSIBySocketId(socketid,
		&socketinfo, NULL, &datasocketinfo, NULL)) < 0) {

		kLogWrite(L_INFO,
			"%s: socketid[%d]'s type is not data/udp. abort",
			__FUNCTION__, socketid);
		return(RETURN_NG);
	}

	if(!inet_ntop(datasocketinfo.di_family,
		&(datasocketinfo.di_d_addr), dstaddr, sizeof(dstaddr))) {

		kLogWrite(L_INFO, "%s: inet_ntop: %s", __FUNCTION__, strerror(errno));
		return(RETURN_NG);
	}

	if((datasocketinfo.di_family == PF_INET6) &&
	   IN6_IS_ADDR_LINKLOCAL(&(datasocketinfo.di_d_addr))) {
		interface = (char *)kIFGetDevicenameByLinkname(
			socketinfo.si_linkname);
		
		if(!interface) {
			kLogWrite(L_WARNING,
				"%s: linkname is NULL pointer. avoid", __FUNCTION__);

			return(RETURN_NG);
		}

		kLogWrite(L_INFO, "%s%%%s", dstaddr, interface);
	}

	snprintf(dstport, sizeof(dstport), "%d", datasocketinfo.di_d_port);
#ifdef DBG_SOCKET
	kdbg("/tmp/dbg_socket.txt", "dstaddr: %s\n", dstaddr);
	kdbg("/tmp/dbg_socket.txt", "dstport: %s\n", dstport);
#endif	/* DBG_SOCKET */
	hints.ai_flags    = AI_NUMERICHOST;
	hints.ai_family   = datasocketinfo.di_family;
	hints.ai_socktype = SOCK_DGRAM;

	error = getaddrinfo(dstaddr, dstport, &hints, &res);
	if(error) {
		kLogWrite(L_INFO,
			"%s: getaddrinfo: %s", __FUNCTION__, gai_strerror(error));
		return(RETURN_NG);
	}

	/* send() */
	if (send(socketinfo.si_sockethandle, data, datalen, 0) < 0) {
		kLogWrite(L_WARNING,
			"%s: send() fail. errno is [%d]", __FUNCTION__, errno);
		return(false);
	}

	kLogWrite(L_DEBUG, "%s: send() OK", __FUNCTION__);

	freeaddrinfo(res);

	return(true);
}



/*****************************
 * kSocketGetSIBySocketId    *
 *****************************/
int
kSocketGetSIBySocketId(
	short           socketid,
	SocketInfo     *socketinfo,
	UnixdInfo      *unixdinfo,
	DatasocketInfo *datasocketinfo,
	ListenportInfo *listenportinfo)
{
	SocketInfo *si   = NULL;
	int         loop = 0;
#ifdef DBG_SOCKET
	kdbg("/tmp/dbg_socket.txt", "%s\n", "initializing.");
#endif	/* DBG_SOCKET */
	kLogWrite(L_INFO, "%s: start", __FUNCTION__);

	/* socket table avaliavle */
	if(!g_socket_start_ptr) {
		kLogWrite(L_INFO, "%s: no SocketInfo now. abort", __FUNCTION__);
		return(RETURN_NG);
	}

	/*
	 * socketid check
	 */
	if(socketid < 0) {
		kLogWrite(L_INFO,
			"%s: invalid socketid [%d]. abort", __FUNCTION__, socketid);
		return(RETURN_NG);
	}

	kLogWrite(L_DEBUG, "%s: start for socketid [%d]", __FUNCTION__, socketid);

	/*
	 * get SocketInfo into pointer[si]
	 */

	si = g_socket_start_ptr;

	for(loop = 0; loop < SOCKET_MAXNUM; loop ++) {
		if(si->si_socketid == socketid) {
			kLogWrite(L_DEBUG, "%s: SocketInfomation found socketid[%d]",
				__FUNCTION__, socketid);
			break;
		}

		if(!(si->si_next_socket_info_ptr)) {
		  /*
			kLogWrite(L_WARNING,
				"%s: search end. not found for socketid[%d]",
				__FUNCTION__, socketid);
		  */
			return(RETURN_NG);
		}

		si = si->si_next_socket_info_ptr;
	}

	/* copy SocketInfo*/
	/* general part */
	if(!socketinfo) {
		kLogWrite(L_WARNING,
			"%s: pointer[socketinfo] is NULL. abort", __FUNCTION__);

		return(RETURN_NG);
	}
	*socketinfo = *si;

	kLogWrite(L_DEBUG, "%s: general part data copy done", __FUNCTION__);

	/* uniq_part */
	switch(si->si_type) {
	case SI_TYPE_UNIX:
	case SI_TYPE_UNIX_DATA:
		if(!unixdinfo) {
			kLogWrite(L_WARNING,
				 "%s: pointer[unixdinfo] is NULL. abort", __FUNCTION__);

			return(RETURN_NG);
		}

		*unixdinfo = *((UnixdInfo*)(si->si_uniq_info_ptr));
		socketinfo->si_uniq_info_ptr = unixdinfo;
		kLogWrite(L_DEBUG, "%s: unixdinfo data copy done", __FUNCTION__);

		break;
	case SI_TYPE_UDP:
	case SI_TYPE_LISTEN_UDP:
	case SI_TYPE_DATA:
	case SI_TYPE_RAW:
		if(!datasocketinfo) {
			kLogWrite(L_WARNING,
				 "%s: pointer[datasocketinfo] is NULL. abort", __FUNCTION__);

			return(RETURN_NG);
		}
		*datasocketinfo =
			*((DatasocketInfo*)(si->si_uniq_info_ptr));

		socketinfo->si_uniq_info_ptr = datasocketinfo;
		kLogWrite(L_DEBUG, "%s: datasocketinfo data copy done", __FUNCTION__);

		break;
	case SI_TYPE_LISTEN_TCP:
		if(!listenportinfo) {
			kLogWrite(L_WARNING,
				"%s: pointer[listenportinfo] is NULL. abort", __FUNCTION__);
			return(RETURN_NG);
		}

		*listenportinfo =
			*((ListenportInfo*)(si->si_uniq_info_ptr));
		socketinfo->si_uniq_info_ptr = listenportinfo;
		kLogWrite(L_DEBUG, "%s: listenortinfo data copy done", __FUNCTION__);

		break;
	default:
		;
		/* anyone can come here */
	}

	return(RETURN_OK);
}



/******************************
 * kSocketGetSIBySocketHandle *
 ******************************/
int
kSocketGetSIBySocketHandle(
	int             sockethandle,
	SocketInfo     *socketinfo,
	UnixdInfo      *unixdinfo,
	DatasocketInfo *datasocketinfo,
	ListenportInfo *listenportinfo)
{
	SocketInfo *si = NULL;
	int         loop = 0;

#ifdef DBG_SOCKET
	kdbg("/tmp/dbg_socket.txt", "%s\n", "initializing.");
#endif	/* DBG_SOCKET */
	kLogWrite(L_INFO, "%s: start", __FUNCTION__);

	/* socket table avaliavle? */
	if(!g_socket_start_ptr) {
		kLogWrite(L_INFO, "%s: no SocketInfo now. abort", __FUNCTION__);

		return(RETURN_NG);
	}

	/*
	 * socketid check
	 */
	if(sockethandle < 0) {
		kLogWrite(L_INFO, "%s: invalid socket handle [%d]. abort",
			__FUNCTION__, sockethandle);
		return(RETURN_NG);
	}

	kLogWrite(L_DEBUG,
		"%s: start for sockethandle [%d]", __FUNCTION__, sockethandle);

	/*
	 * get SocketInfo into pointer[si]
	 */

	si = g_socket_start_ptr;

	for(loop = 0; loop < SOCKET_MAXNUM; loop ++) {
		if((si->si_sockethandle == sockethandle) &&
		    (si->si_socket_status == SI_STATUS_ALIVE)) {
			kLogWrite(L_DEBUG, "%s: SocketInfomation found sockethandle[%d]",
				__FUNCTION__, sockethandle);

			break;
		}

		if(!(si->si_next_socket_info_ptr)) {
			kLogWrite(L_WARNING,
				"%s: search end. not found for sockethandle[%d]",
				__FUNCTION__, sockethandle);

			return(RETURN_NG);
		}

		si = si->si_next_socket_info_ptr;
	}

	/*
	 * copy SocketInfo
	 */

	/* general part */
	if(!socketinfo) {
		kLogWrite(L_WARNING,
			"%s: pointer[socketinfo] is NULL. abort", __FUNCTION__);

		return(RETURN_NG);
	}

	*socketinfo = *si;
	kLogWrite(L_DEBUG,
		"%s: general part data copy done. socketid[%d]",
		__FUNCTION__, si->si_socketid);

	/* uniq_part */
	switch(si->si_type) {
		case SI_TYPE_UNIX:
		case SI_TYPE_UNIX_DATA:
			if(!unixdinfo) {
				kLogWrite(L_WARNING,
					"%s: pointer[unixdinfo] is NULL. abort", __FUNCTION__);

				return(RETURN_NG);
			}

			*unixdinfo = *((UnixdInfo*)(si->si_uniq_info_ptr));
			socketinfo->si_uniq_info_ptr = unixdinfo;
			kLogWrite(L_DEBUG, "%s: unixdinfo data copy done", __FUNCTION__);
			break;
		case SI_TYPE_UDP:
		case SI_TYPE_DATA:
			if(!datasocketinfo) {
				kLogWrite(L_WARNING,
					"%s: pointer[datasocketinfo] is NULL. abort", __FUNCTION__);

				return(RETURN_NG);
			}

			*datasocketinfo =
				*((DatasocketInfo*)(si->si_uniq_info_ptr));
			socketinfo->si_uniq_info_ptr = datasocketinfo;
			kLogWrite(L_DEBUG,
				 "%s: datasocketinfo data copy done %d %d %d %d",
				 __FUNCTION__,
				 datasocketinfo->di_s_port, datasocketinfo->di_d_port,
				 datasocketinfo->di_parent_socketid, datasocketinfo->di_family);
			break;

		case SI_TYPE_LISTEN_UDP:
			if(!datasocketinfo) {
				kLogWrite(L_WARNING,
					"%s: pointer[datasocketinfo] is NULL. abort", __FUNCTION__);

				return(RETURN_NG);
			}

			*datasocketinfo =
				*((DatasocketInfo*)(si->si_uniq_info_ptr));
			socketinfo->si_uniq_info_ptr = datasocketinfo;
			kLogWrite(L_DEBUG,
				 "%s: datasocketinfo data copy done %d %d %d %d", __FUNCTION__,
				 datasocketinfo->di_s_port, datasocketinfo->di_d_port,
				 datasocketinfo->di_parent_socketid, datasocketinfo->di_family);
			break;

		case SI_TYPE_LISTEN_TCP:
			if(listenportinfo == NULL) {
				kLogWrite(L_WARNING,
					"%s: pointer[listenportinfo] is NULL. abort", __FUNCTION__);

				return(RETURN_NG);
			}

			*listenportinfo =
				*((ListenportInfo*)(si->si_uniq_info_ptr));
			socketinfo->si_uniq_info_ptr = listenportinfo;
			kLogWrite(L_DEBUG,
				"%s: listenortinfo data copy done", __FUNCTION__);

			break;
		default:
			;
			/* anyone can come here */
	}

	return(RETURN_OK);
}



/******************************
 * get selected handle        *
 ******************************/
int
kSocketGetSelectedHandle(int *handle, unsigned char *type)
{
	SocketInfo *current_position = NULL;

#ifdef DBG_SOCKET
	kdbg("/tmp/dbg_socket.txt", "%s\n", "initializing.");
#endif	/* DBG_SOCKET */
	/* return matched handle for FD_ISSET(handle, &g_execfds) */

	if(!handle) {
		kLogWrite(L_INFO, "%s: handle is NULL pointer", __FUNCTION__);
		return(RETURN_NG);
	}

	if(!type) {
		kLogWrite(L_INFO, "%s: type is NULL pointer", __FUNCTION__);
		return(RETURN_NG);
	}

	current_position = g_socket_start_ptr;
	if(!current_position) {
		kLogWrite(L_INFO, "%s: no avaliavle socket now. abort", __FUNCTION__);

		return(RETURN_NG);
	}

	for( ; ; ) {
		if(current_position->si_socket_status != SI_STATUS_CLOSE) {
			if(FD_ISSET(current_position->si_sockethandle,
				&g_execfds)) {

				*handle = current_position->si_sockethandle;
				*type	= current_position->si_type;
				kLogWrite(L_INFO, "%s: handle[%d] match",
					__FUNCTION__, current_position->si_sockethandle);
				return(RETURN_OK);
			}
		}

		if(!(current_position->si_next_socket_info_ptr)) {
			kLogWrite(L_WARNING, "%s: no match. abort", __FUNCTION__);
			return(RETURN_NG);
		}

		current_position = current_position->si_next_socket_info_ptr;
	}

	return(RETURN_OK);
}



#ifdef SUPPORT_TLS
void 
kSocketTLSClose(void *tlsssl)
{
	SocketInfo *current_position = g_socket_start_ptr;
	while(current_position){
		if(current_position->si_tls_ssl_ptr == tlsssl) {
			current_position->si_tls_ssl_ptr=NULL;
		}

		current_position = current_position->si_next_socket_info_ptr;
	}
}

int 
kSocketTLSSession(struct sockaddr *src,	struct sockaddr *dst, int port, void **tlsssl)
{
	struct sockaddr_in  *src4,*dst4;
	struct sockaddr_in6 *src6,*dst6;
	DatasocketInfo *info;
	SocketInfo *current_position = g_socket_start_ptr;

	if(src->sa_family == AF_INET){
		src4=(struct sockaddr_in*)src;dst4=(struct sockaddr_in*)dst;
		while(current_position){
		  if(current_position->si_tls_mode &&
		     current_position->si_tls_ssl_ptr &&
		     current_position->si_type==SI_TYPE_DATA &&
		     (info=(DatasocketInfo*)current_position->si_uniq_info_ptr)) {
		    if((info->di_d_port == port || info->di_s_port == port) && 
		       !memcmp(&info->di_s_addr, &src4->sin_addr, 4) &&
		       !memcmp(&info->di_d_addr, &dst4->sin_addr, 4)) {
		      *tlsssl=current_position->si_tls_ssl_ptr;
		      return(RETURN_OK);
		    }
		  }
		  current_position = current_position->si_next_socket_info_ptr;
		}
	} else {
		src6 = (struct sockaddr_in6*)src;dst6=(struct sockaddr_in6*)dst;
		while(current_position){
		  if(current_position->si_tls_mode &&
		     current_position->si_tls_ssl_ptr &&
		     current_position->si_type == SI_TYPE_DATA &&
		     (info=(DatasocketInfo*)current_position->si_uniq_info_ptr)) {
		    if((info->di_d_port == port || info->di_s_port == port) && 
		       !memcmp(&info->di_s_addr, &src6->sin6_addr, 16) &&
		       !memcmp(&info->di_d_addr, &dst6->sin6_addr, 16)) {
		      *tlsssl=current_position->si_tls_ssl_ptr;
		      return(RETURN_OK);
		    }
		  }
		  current_position = current_position->si_next_socket_info_ptr;
		}
	}

	*tlsssl = NULL;
	return(RETURN_NG);
}
#endif	/* SUPPORT_TLS */



/******************************
 * regist si unixd domain     *
 ******************************/
int
kSocketRegistUnixdSocketInfo(
	unsigned char	type,		/* type ex.unix,udp,listen,data */
	int		sockethandle,	/* socket handle */
	unsigned char	sockpath[])	/* pathname for unix_dsocket */
{
	SocketInfo *new        = NULL;
	UnixdInfo  *temp_unixd = NULL;
#ifdef DBG_SOCKET
	kdbg("/tmp/dbg_socket.txt", "%s\n", "initializing.");
#endif	/* DBG_SOCKET */
	kLogWrite(L_INFO, "%s: start", __FUNCTION__);

	if(!sockpath) {
		kLogWrite(L_WARNING,
			"%s: sockpath is NULL pointer. abort", __FUNCTION__);

		return(RETURN_NG);
	}

	/*
	 * max socket number check
	 */
	if(g_socket_socketid == SOCKET_MAXNUM) {
		kLogWrite(L_WARNING, "%s: socket number limit [%d]. cannot create more",
			__FUNCTION__, g_socket_socketid);
		return(RETURN_NG);
	}

	kLogWrite(L_DEBUG, "%s: socket number limit passed. current num is [%d]",
		__FUNCTION__, g_socket_socketid);

	/* data generation */

	/*
	 * allocate memory for new SocketInfo space
	 */
	if(!(new = (SocketInfo*)malloc(sizeof(SocketInfo)))) {
		kLogWrite(L_ERROR, "%s: malloc for new SocketInfo fail", __FUNCTION__);

		return(RETURN_NG);
	}

	kLogWrite(L_DEBUG,
		"%s: allocate memory for SocketInfo structure", __FUNCTION__);

	memset(new, 0, sizeof(SocketInfo));

	/*
	 * allocate memory for uniq_data part of new SocketInfo structure
	 */

	if(!(new->si_uniq_info_ptr = (UnixdInfo*)malloc(sizeof(UnixdInfo)))) {
		kLogWrite(L_ERROR,
			"%s: malloc for uniq_data[UNIX] space fail", __FUNCTION__);

		free(new);
		return(RETURN_NG);
	}

	kLogWrite(L_DEBUG, "%s: allocate memory for uniq_data[UNIX]", __FUNCTION__);

	memset(new->si_uniq_info_ptr, 0, sizeof(UnixdInfo));

	/* pointer change for cast and complete uniq_info */
	temp_unixd = (UnixdInfo*)new->si_uniq_info_ptr;
	strcpy((char *)temp_unixd->ui_sockpath, (const char *)sockpath);

	/*
	 * generate general part of structure
	 */
	new->si_type = type;

	g_socket_socketid ++;	/* increment for next start from 1 */
	new->si_socketid = g_socket_socketid;

	new->si_sockethandle  = sockethandle;
	new->si_socket_status = SI_STATUS_ALIVE;
	new->si_peyload_type  = P_COMMAND;

	/*
	 * connect SocketInfo to linked list
	 */
	if(g_socket_start_ptr) {
		/* last data's next is new */
		g_socket_last_ptr->si_next_socket_info_ptr	= new;
		kLogWrite(L_DEBUG, "%s: SocketInfo added to table", __FUNCTION__);
	} else {
		/* it is first one */
		g_socket_start_ptr = new;
		kLogWrite(L_DEBUG,
			"%s: SocketInfo added to table. it was first data", __FUNCTION__);
	}

	/* new data's next is NULL */
	new->si_next_socket_info_ptr = NULL;

	/* now, last data is new */
	g_socket_last_ptr = new;

	kLogWrite(L_INFO, "%s: socketid[%d] handle[%d] is done",
		__FUNCTION__, new->si_socketid,sockethandle);
	return(RETURN_OK);
}



/**************************************
 * kSocketRegistDataSocketInfo        *
 **************************************/
int
kSocketRegistDataSocketInfo(
	unsigned char   type,
	int             handle,
	unsigned char   linkname[],
	short           peyload_type,
	struct sockaddr_storage s_addr,
	struct sockaddr_storage d_addr,
	int (*parser)(long, unsigned char *, unsigned char **, short *),
	short           socketid,
	unsigned char   family,
	int		tls_mode,
	void		*tls_ssl)
{
	char buf[BUFSIZE];
	socklen_t buflen = sizeof(buf);
	SocketInfo     *new            = NULL;
	DatasocketInfo *datasocketinfo = NULL;

#ifdef DBG_SOCKET
	kdbg("/tmp/dbg_socket.txt", "%s\n", "initializing.");
#endif	/* DBG_SOCKET */
	kLogWrite(L_INFO, "%s: start", __FUNCTION__);

	if(!linkname) {
		kLogWrite(L_WARNING,
			"%s: linkname is NULL pointer. abort", __FUNCTION__);

		return(RETURN_NG);
	}

	/*
	 * max socket number check
	 */
	if(g_socket_socketid == SOCKET_MAXNUM) {
		kLogWrite(L_WARNING,
			"%s: socket number limit [%d]. cannot create more",
			__FUNCTION__, g_socket_socketid);
		return(RETURN_NG);
	}

	kLogWrite(L_DEBUG,
		"%s: socket number limit passed. current num is [%d]",
		__FUNCTION__, g_socket_socketid);

	/* data generation */

	/*
	 * allocate memory for new SocketInfo space
	 */
	if(!(new = (SocketInfo*)malloc(sizeof(SocketInfo)))) {
		kLogWrite(L_ERROR, "%s: malloc for new SocketInfo fail", __FUNCTION__);

		return(RETURN_NG);
	}

	kLogWrite(L_DEBUG,
		"%s: allocate memory for SocketInfo structure", __FUNCTION__);

	memset(new,0,sizeof(SocketInfo));

	/*
	 * allocate memory for uniq_data part of new SocketInfo structure
	 */

	if(!(new->si_uniq_info_ptr
	     = (DatasocketInfo*)malloc(sizeof(DatasocketInfo)))) {
		kLogWrite(L_ERROR,
			"%s: malloc for uniq_data[DATA] space fail", __FUNCTION__);

		free(new);
		return(RETURN_NG);
	}

	kLogWrite(L_DEBUG, "%s: allocate memory for uniq_data[DATA]", __FUNCTION__);

	memset(new->si_uniq_info_ptr, 0, sizeof(DatasocketInfo));

	/* pointer change for cast and complete uniq_info */
	datasocketinfo = (DatasocketInfo*)new->si_uniq_info_ptr;

	/*
	 * generate general part of structure
	 */
	new->si_type = type;

	g_socket_socketid ++;	/* increment for next start from 1 */
	new->si_socketid = g_socket_socketid;

	new->si_sockethandle  = handle;
	strcpy((char *)new->si_linkname, (const char *)linkname);
	new->si_socket_status = SI_STATUS_ALIVE;
	new->si_peyload_type  = peyload_type;
	new->si_tls_mode      = tls_mode;
	new->si_tls_ssl_ptr   = tls_ssl;

	datasocketinfo->di_parser = parser;
	datasocketinfo->di_parent_socketid = socketid;
	datasocketinfo->di_family = family;

	if (family == AF_INET) {
		datasocketinfo->di_s_port
			= ntohs(((struct sockaddr_in *)&s_addr)->sin_port);
		datasocketinfo->di_d_port
			= ntohs(((struct sockaddr_in *)&d_addr)->sin_port);
		memcpy(&(datasocketinfo->di_s_addr),
		       &(((struct sockaddr_in *)&s_addr)->sin_addr),
		       s_addr.ss_len);
		memcpy(&(datasocketinfo->di_d_addr),
		       &(((struct sockaddr_in *)&d_addr)->sin_addr),
		       d_addr.ss_len);
	}
	else { /* AF_INET6 */
		datasocketinfo->di_s_port
			= ntohs(((struct sockaddr_in6 *)&s_addr)->sin6_port);
		datasocketinfo->di_d_port
			= ntohs(((struct sockaddr_in6 *)&d_addr)->sin6_port);
		memcpy(&(datasocketinfo->di_s_addr),
		       &(((struct sockaddr_in6 *)&s_addr)->sin6_addr),
		       s_addr.ss_len);
		memcpy(&(datasocketinfo->di_d_addr),
		       &(((struct sockaddr_in6 *)&d_addr)->sin6_addr),
		       d_addr.ss_len);
	}

	kLogWrite(L_DEBUG,
		"%s: type(%d) srcport(%d) dstport(%d) socketid(%d) af(%d)",
		__FUNCTION__, type,
		datasocketinfo->di_s_port, datasocketinfo->di_d_port,
		socketid, family);

	if (family == AF_INET) {
		inaddr2string((struct in_addr *)&datasocketinfo->di_s_addr,
			      buf, (int *)&buflen);
		kLogWrite(L_DEBUG, "%s: srcaddr(%s)", __FUNCTION__, buf);

		inaddr2string((struct in_addr *)&datasocketinfo->di_d_addr,
			      buf, (int *)&buflen);
		kLogWrite(L_DEBUG, "%s: dstaddr(%s)", __FUNCTION__, buf);
	}
	else {
		in6addr2string((struct in6_addr *)&datasocketinfo->di_s_addr,
			       buf, (int *)&buflen);
		kLogWrite(L_DEBUG, "%s: srcaddr(%s)", __FUNCTION__, buf);

		in6addr2string((struct in6_addr *)&datasocketinfo->di_d_addr,
			       buf, (int *)&buflen);
		kLogWrite(L_DEBUG, "%s: dstaddr(%s)", __FUNCTION__, buf);
	}

	/*
	 * connect SocketInfo to linked list
	 */
	if(g_socket_start_ptr) {
		/* last data's next is new */
		g_socket_last_ptr->si_next_socket_info_ptr	= new;
		kLogWrite(L_DEBUG, "%s: SocketInfo added to table", __FUNCTION__);
	} else {
		/* it is first one */
		g_socket_start_ptr = new;

		kLogWrite(L_DEBUG,
			"%s: SocketInfo added to table. it was first data", __FUNCTION__);
	}

	/* new data's next is NULL */
	new->si_next_socket_info_ptr = NULL;

	/* now, last data is new */
	g_socket_last_ptr = new;

	kLogWrite(L_INFO, "%s: socketid[%d] handle[%d] is done",
		__FUNCTION__, new->si_socketid, handle);

	return(new->si_socketid);
}


/******************************
 * kSocketCheckNewSocket()    *
 ******************************/
int
kSocketCheckNewSocket(
	unsigned short	s_port,
	struct in6_addr	s_addr,
	unsigned short	d_port,
	struct in6_addr	d_addr,
	char		protocol,
	short           *socketid)	/* return value */
{
	SocketInfo     *si             = NULL;
	SocketInfo     *reuseinfo      = NULL;
	DatasocketInfo *datasocketinfo = NULL;
	struct in6_addr in6dummy;
	bool            flg            = true;

	memset(&in6dummy, 0, sizeof(in6dummy));

#ifdef DBG_SOCKET
	kdbg("/tmp/dbg_socket.txt", "%s\n", "initializing.");
#endif	/* DBG_SOCKET */

	kLogWrite(L_INFO, "%s: start", __FUNCTION__);

	/*
	 * socketid pointer check and input 0
	 */
	if(!socketid) {
		kLogWrite(L_WARNING, "%s: socketid NULL pointer.abort", __FUNCTION__);

		return(RETURN_NG);
	}

	*socketid = 0;

	/*
	 * search same s_port
	 */
	memset(&in6dummy, 0, sizeof(in6dummy));

	for(si = g_socket_start_ptr;
	    si->si_next_socket_info_ptr != NULL;
	    si = si->si_next_socket_info_ptr) {
		
		if(protocol == CM_PROT_TCP &&
		   si->si_type == SI_TYPE_UDP) {
			continue;
		}
		else if(protocol == CM_PROT_UDP &&
			(si->si_type == SI_TYPE_DATA ||
			 si->si_type == SI_TYPE_LISTEN_TCP ||
			 si->si_type == SI_TYPE_LISTEN_UDP)) {
			continue;
		}

		if((si->si_type == SI_TYPE_UDP) &&
		    (si->si_socket_status == SI_STATUS_ALIVE)) {
			datasocketinfo = (DatasocketInfo*)si->si_uniq_info_ptr;
/*			if(datasocketinfo->di_s_port == s_port) { 08/4/18 */
			if(datasocketinfo->di_s_port == s_port && (!d_port || (datasocketinfo->di_d_port == d_port))) {
				flg = false;
				reuseinfo = si;

				if(
					memcmp(&in6dummy,
						&(datasocketinfo->di_s_addr),
						sizeof(struct in6_addr)) &&
					memcmp(&in6dummy,
						&s_addr,
						sizeof(struct in6_addr)) &&
					memcmp(&s_addr,
						&(datasocketinfo->di_s_addr),
						sizeof(struct in6_addr))
				) {
					/* addr duprication */
					flg =true;
				}
			}
		}
	}

	if(flg) {
		kLogWrite(L_INFO, "%s: now you can create new", __FUNCTION__);
	} else {
		*socketid      = reuseinfo->si_socketid;
		datasocketinfo = (DatasocketInfo*)reuseinfo->si_uniq_info_ptr;
		datasocketinfo->di_d_port = d_port;

		memcpy(&(datasocketinfo->di_d_addr),
			&d_addr, sizeof(struct in6_addr));

		kLogWrite(L_INFO,
			"%s: re-use socketid[%d]",
			__FUNCTION__, reuseinfo->si_socketid);
	}

	return(RETURN_OK);
}



static int
kSocketMakeSocketStatusClose(int sockethandle)
{
	SocketInfo *si   = NULL;
	int         loop = 0;
#ifdef DBG_SOCKET
	kdbg("/tmp/dbg_socket.txt", "%s\n", "initializing.");
#endif	/* DBG_SOCKET */
	kLogWrite(L_INFO, "%s: start", __FUNCTION__);

	/* socket table avaliavle? */
	if(!g_socket_start_ptr) {
		kLogWrite(L_INFO, "%s: no SocketInfo now.", __FUNCTION__);
		return(RETURN_OK);
	}

	/*
	 * socketid check
	 */
	if(sockethandle < 0) {
		kLogWrite(L_INFO, "%s: invalid socket handle [%d]. abort",
			__FUNCTION__, sockethandle);
		return(RETURN_NG);
	} else {
		kLogWrite(L_DEBUG,
			"%s: start for sockethandle [%d]", __FUNCTION__, sockethandle);
	}

	/*
	 * get SocketInfo into pointer[si]
	 */
	si = g_socket_start_ptr;

	for(loop = 0; loop < SOCKET_MAXNUM; loop ++) {
		if(si->si_sockethandle == sockethandle) {
			kLogWrite(L_DEBUG, "%s: SocketInfomation found sockethandle[%d]",
				__FUNCTION__, sockethandle);
			break;
		}

		if(!(si->si_next_socket_info_ptr)) {
			kLogWrite(L_WARNING,
				"%s: not found for sockethandle[%d]",
				__FUNCTION__, sockethandle);
			return(RETURN_OK);
		}

		si = si->si_next_socket_info_ptr;
	}

	si->si_socket_status = SI_STATUS_CLOSE;
	kLogWrite(L_SOCKET,
		"%s: socketid[%d] handle[%d] change to status close ->[%d]",
		__FUNCTION__,
		si->si_socketid, si->si_sockethandle, si->si_socket_status);

	return(RETURN_OK);
}



const char *
inaddr2string(struct in_addr *addr, char *buf, int *buflen)
{
	const char *result = inet_ntop(AF_INET, (void *)addr, buf, *buflen);
	printf("\tINET %s\n", result);
	return result;
}


const char *
in6addr2string(struct in6_addr *addr, char *buf, int *buflen)
{
	const char *result = inet_ntop(AF_INET6, (void *)addr, buf, *buflen);
	printf("\tINET6 %s\n", result);
	return result;
}

const char *
sockaddr2string(struct sockaddr *sap, char *buf, int *buflen)
{
	int flag = NI_NUMERICHOST;
	struct sockaddr_in *sin = NULL;
	struct sockaddr_in6 *sin6 = NULL;

	if (!sap) {
		return "----";
	}

	if (getnameinfo(sap, sap->sa_len, buf, *buflen, NULL, 0, flag) != 0) {
		printf("\t?\n");
		return "?";
	}
	
	switch (sap->sa_family) {
	case AF_INET:
		sin = (struct sockaddr_in *) sap;
		kLogWrite(L_WARNING,
			"%s: sap af:%d addr:%s port:%d len:%d", __FUNCTION__,
			sin->sin_family, buf, sin->sin_port, sin->sin_len);
		break;
	case AF_INET6:
		sin6 = (struct sockaddr_in6 *) sap;
		kLogWrite(L_WARNING, "%s: sap af:%d addr:%s port:%d len:%d",
			__FUNCTION__,
			sin6->sin6_family, buf, sin6->sin6_port, sin6->sin6_len);
		break;
	default:
		break;
	}

	return buf;
}

bool
probe_srcaddr(const char *hostname, int domain,
	      struct sockaddr_storage *src, socklen_t *srclen)
{
	struct addrinfo hints, *res;
	int ret_ga = 0;

	memset(&hints, 0, sizeof(struct addrinfo));
	hints.ai_socktype = SOCK_RAW;
	hints.ai_flags = AI_NUMERICHOST; /* allow hostname? */

	if (domain == AF_INET) {
		hints.ai_family = AF_INET;
		hints.ai_protocol = IPPROTO_ICMP;
	}
	else {
		hints.ai_family = AF_INET6;
		hints.ai_protocol = IPPROTO_ICMPV6;
	}

	ret_ga = getaddrinfo(hostname, NULL, &hints, &res);
	if (ret_ga) {
		kLogWrite(L_WARNING, "%s: invalid source address: %s",
			__FUNCTION__, gai_strerror(ret_ga));
		return false;
	}
	/*
	 * res->ai_family must be AF_INET6 and res->ai_addrlen
	 * must be sizeof(src).
	 */
	memcpy(src, res->ai_addr, res->ai_addrlen);
	*srclen = res->ai_addrlen;
	freeaddrinfo(res);

	if (domain == AF_INET) {
		struct sockaddr_in *sin = (struct sockaddr_in *) src;
		sin->sin_port = 0;
	}
	else {
		struct sockaddr_in6 *sin6 = (struct sockaddr_in6 *) src;
		sin6->sin6_port = 0;
	}

	return true;
}

unsigned short
checksum(unsigned short *buf, int buflen)
{
	unsigned long sum = 0;
	while (buflen > 1) {
		sum += *buf;
		buf++;
		buflen -= 2;
	}

	if (buflen == 1) {
		sum += *(unsigned char *) buf;
	}

	sum = (sum & 0xff) + (sum >> 16);
	sum = (sum & 0xff) + (sum >> 16);
	return ~sum;
}

static int
icmp_send(int fd, const unsigned char *linkname,
	  struct sockaddr *src, socklen_t srclen,
	  struct sockaddr *dst, socklen_t dstlen,
	  long datalen, unsigned char *data)
{
	int n;
	u_char buf[MSG_MAXDATALEN];
	size_t buflen;

	/* for struct msghdr */
	struct msghdr msg;
	struct iovec iov;
	char control[1024];

	char *scmsg = NULL;

	memset(&iov, 0, sizeof(iov));
	memset(control, 0, sizeof(control));

	kLogWrite(L_INFO, "%s: start af(%d)", __FUNCTION__, src->sa_family);

	/* prepare packet */
	if (src->sa_family == AF_INET) {
		struct icmp *icmp_header;
		icmp_header = (struct icmp *) buf;
		memset(icmp_header, 0, sizeof(struct icmp));

		if (datalen > 3) {
			memcpy(icmp_header, data, 2);
		}
		else {
			icmp_header->icmp_type = ICMP_ECHO;
			icmp_header->icmp_code = 0;
		}
		icmp_header->icmp_cksum = 0;
		icmp_header->icmp_id = 0;
		icmp_header->icmp_seq = 0;
		memset(icmp_header->icmp_data, 0, 20);
			
		icmp_header->icmp_cksum =
			checksum((unsigned short *)icmp_header,
				 sizeof(struct icmp)+20);

		msg.msg_control = NULL;
		msg.msg_controllen = 0;

		buflen = sizeof(struct icmp) + 20;
	}
	else {
		struct icmp6_hdr *icmp6_header = NULL;
		int ip6optlen = 0;
		struct sockaddr_in6 *sin6 = (struct sockaddr_in6 *)src;
		struct cmsghdr *scmsgp = NULL;
		struct in6_pktinfo *pktinfo = NULL;

		icmp6_header = (struct icmp6_hdr *) buf;

		if (datalen > 3) {
			/* ICMPv6 Type (1) + ICMPv6 Code (1) */
			memcpy(icmp6_header, data, 2);
		}
		else {
			icmp6_header->icmp6_type = ICMP6_ECHO_REQUEST;
			icmp6_header->icmp6_code = htons(0);
		}
		/* Checksum is calculated by kernel in IPv6 */
		icmp6_header->icmp6_cksum = htons(0);
		icmp6_header->icmp6_id = htons(0);
		icmp6_header->icmp6_seq = htons(0);

		memcpy(data, icmp6_header, sizeof(struct icmp6_hdr));

		ip6optlen += CMSG_SPACE(sizeof(struct in6_pktinfo));

		if ((scmsg = (char *)malloc(ip6optlen)) == 0) {
			fprintf(stderr, "can't allocate memory\n");
		}

		msg.msg_control = (caddr_t) scmsg;
		msg.msg_controllen = ip6optlen;
		scmsgp = (struct cmsghdr *)scmsg;

		pktinfo = (struct in6_pktinfo *)(CMSG_DATA(scmsgp));

		memset(pktinfo, 0, sizeof(*pktinfo));
		scmsgp->cmsg_len = CMSG_LEN(sizeof(struct in6_pktinfo));
		scmsgp->cmsg_level = IPPROTO_IPV6;
		scmsgp->cmsg_type = IPV6_PKTINFO;
		scmsgp = CMSG_NXTHDR(&msg, scmsgp);


		memcpy(&pktinfo->ipi6_addr,
		       &sin6->sin6_addr,
		       sizeof(struct in6_addr));

		if (IN6_IS_ADDR_LINKLOCAL(&sin6->sin6_addr)) {
			pktinfo->ipi6_ifindex = linkname2ifindex(linkname);
			if (pktinfo->ipi6_ifindex == 0) {
				fprintf(stderr,
					"%s: %d is invalid interface index.",
					__FUNCTION__, pktinfo->ipi6_ifindex);
			}
		}

		buflen = sizeof(struct icmp6_hdr) + ip6optlen;
	}

	iov.iov_base = (caddr_t) buf;
	iov.iov_len = buflen;

	msg.msg_name = NULL;
	msg.msg_namelen = 0;
	msg.msg_iov = &iov;
	msg.msg_iovlen = 1;
	msg.msg_flags = 0;

	n = sendmsg(fd, &msg, 0);
	if (n < 1) {
		perror("sendmsg");
	}

	if (scmsg) {
		free(scmsg);
	}
	kLogWrite(L_INFO, "%s: done", __FUNCTION__);
	return n;
}

int
icmp_recv(int fd, const unsigned char *linkname,
	  struct sockaddr *src, socklen_t srclen,
	  struct sockaddr *dst, socklen_t dstlen,
	  char *buf, int buflen)
{
	int n;

	struct ip *ip_header_ptr;
	struct icmp *icmp_header_ptr;
	struct icmp6_hdr *icmp6_header_ptr;

	struct iovec iov;
	char control[1024];
	struct msghdr msg;
	struct cmsghdr *cmsg = NULL;

	kLogWrite(L_INFO, "%s: start", __FUNCTION__);

	memset(buf, 0, sizeof(buf));
	memset(control, 0, sizeof(control));

	if (src->sa_family == AF_INET6) {
		int ip6optlen = 0;
		struct sockaddr_in6 *sin6 = (struct sockaddr_in6 *)src;
		if (IN6_IS_ADDR_LINKLOCAL(&sin6->sin6_addr)) {
			/* use link-local address */
			struct cmsghdr *scmsgp = NULL;
			char *scmsg;
			struct in6_pktinfo *pktinfo = NULL;

			ip6optlen += CMSG_SPACE(sizeof(struct in6_pktinfo));

			if ((scmsg = (char *)malloc(ip6optlen)) == 0) {
				fprintf(stderr, "can't allocate memory\n");
			}

			msg.msg_control = (caddr_t) scmsg;
			msg.msg_controllen = ip6optlen;
			scmsgp = (struct cmsghdr *)scmsg;

			pktinfo = (struct in6_pktinfo *)(CMSG_DATA(scmsgp));

			memset(pktinfo, 0, sizeof(*pktinfo));
			scmsgp->cmsg_len = CMSG_LEN(sizeof(struct in6_pktinfo));
			scmsgp->cmsg_level = IPPROTO_IPV6;
			scmsgp->cmsg_type = IPV6_PKTINFO;
			scmsgp = CMSG_NXTHDR(&msg, scmsgp);

			pktinfo->ipi6_ifindex = linkname2ifindex(linkname);
			if (pktinfo->ipi6_ifindex == 0) {
				fprintf(stderr,
					"%s: %d is invalid interface index.",
					__FUNCTION__, pktinfo->ipi6_ifindex);
			}

			memcpy(&pktinfo->ipi6_addr,
			       &((struct sockaddr_in6 *)dst)->sin6_addr,
			       sizeof(struct in6_addr));
		}
		
		buflen = sizeof(struct icmp6_hdr) + ip6optlen;
	}

	iov.iov_base = (caddr_t) buf;
	iov.iov_len = buflen;
	
	msg.msg_name = NULL;
	msg.msg_namelen = 0;
	msg.msg_iov = &iov;
	msg.msg_iovlen = 1;
	msg.msg_control = control;
	msg.msg_controllen = sizeof(control);

	msg.msg_flags = 0;

	n = recvmsg(fd, &msg, 0);
	if (n < 1) {
		perror("recvmsg");
	}

	kLogWrite(L_INFO,
		"%s: received %d bytes icmp header and date", __FUNCTION__, n);

	for (cmsg = CMSG_FIRSTHDR(&msg); cmsg != NULL;
	     cmsg = CMSG_NXTHDR(&msg, cmsg)) {
		if (cmsg->cmsg_len == 0) {
			printf("error\n");
			break;
		}
	}

	if (src->sa_family == AF_INET) {
		ip_header_ptr = (struct ip *) buf;
		icmp_header_ptr =
			(struct icmp *)	(buf + (ip_header_ptr->ip_hl * 4));

		if (icmp_header_ptr->icmp_type == ICMP_ECHO) {
			printf("\t\tICMP Echo Request ");
		}
		else if (icmp_header_ptr->icmp_type == ICMP_ECHOREPLY) {
			printf("\t\tICMP Echo Reply ");
		}
		else {
			printf("\t\tICMP ");
		}
		printf("(Type:%d)\n", icmp_header_ptr->icmp_type);

	}
	else { /* AF_INET6 */
		icmp6_header_ptr = (struct icmp6_hdr *) buf;
		
		if (icmp6_header_ptr->icmp6_type == ICMP6_ECHO_REQUEST) {
			printf("\t\tICMPv6 Echo Request ");
		}
		else if (icmp6_header_ptr->icmp6_type == ICMP6_ECHO_REPLY) {
			printf("\t\tICMPv6 Echo Reply ");
		}
		else {
			printf("\t\tICMPv6 ");
		}
		printf("(Type:%d)\n", icmp6_header_ptr->icmp6_type);
	}

	kLogWrite(L_INFO, "%s: done", __FUNCTION__);

	/* 8 = ICMPv6 Type (1) + ICMPv6 Code (1) + ICMPv6 Checksum (2) +
	       ICMPv6 ID (2) + ICMPv6 Seq (2) */
	return(8); 
}

int
kSocketOpenRaw(char af, struct in6_addr d_addr, struct in6_addr s_addr,
	       char proto, short frameid, unsigned char *linkname,
	       short *socketid)	/* return value */
{
	char buf[BUFSIZE];

	socklen_t buflen = sizeof(buf);
	int error = 0;

	char srcaddrstr[INET6_ADDRSTRLEN];
	char dstaddrstr[INET6_ADDRSTRLEN];
	char *servname = NULL;

	/* preparation */
	int addrfamily = (af == CM_IP_IPV4) ? AF_INET : AF_INET6;
	int protocol = (addrfamily == AF_INET) ? IPPROTO_ICMP : IPPROTO_ICMPV6;

	struct sockaddr_storage src;
	socklen_t srclen;

	struct addrinfo hints, *res0 = NULL;
	int fd = 0;
	const int on = 1;
	struct icmp6_filter filter;
	SocketInfo *socketInfo = NULL;
	DatasocketInfo *dataSocketInfo = NULL;
	int nullparser = 2;

	memset(buf, 0, sizeof(buf));
	memset(srcaddrstr, 0, sizeof(srcaddrstr));
	memset(dstaddrstr, 0, sizeof(dstaddrstr));
	memset(&hints, 0, sizeof(hints));
	memset(&filter, 0, sizeof(filter));

	kLogWrite(L_INFO, "%s: start", __FUNCTION__);

	if (proto != CM_PROT_ICMP) {
		kLogWrite(L_WARNING, "%s: protocol[%d] not support",
			__FUNCTION__, proto);
		return(-1);
	}

	if(addrfamily == AF_INET) {
		inaddr2string((struct in_addr *)&s_addr, buf, (int *)&buflen);
		strcpy(srcaddrstr, buf);
		inaddr2string((struct in_addr *)&d_addr, buf, (int *)&buflen);
		strcpy(dstaddrstr, buf);

		kLogWrite(L_INFO, "%s: src addr inet(%s)", __FUNCTION__, srcaddrstr);
		kLogWrite(L_INFO, "%s: dst addr inet(%s)", __FUNCTION__, dstaddrstr);
	}
	else if(addrfamily == AF_INET6) {
		in6addr2string(&s_addr, buf, (int *)&buflen);
		strcpy(srcaddrstr, buf);
		in6addr2string(&d_addr, buf, (int *)&buflen);
		strcpy(dstaddrstr, buf);

		kLogWrite(L_INFO, "%s: src addr inet6(%s)", __FUNCTION__, srcaddrstr);
		kLogWrite(L_INFO, "%s: dst addr inet6(%s)", __FUNCTION__, dstaddrstr);
	}

	/* probe source addr */
	if (!probe_srcaddr(srcaddrstr, addrfamily, &src, &srclen)) {
		kLogWrite(L_WARNING, "%s: fail", __FUNCTION__);
		return(-1);
	}

	sockaddr2string((struct sockaddr *)&src, buf, (int *)&buflen);

	/* probe destination addr */
	hints.ai_family = addrfamily;
	hints.ai_socktype = SOCK_RAW;
	hints.ai_protocol = protocol;
	hints.ai_flags = AI_NUMERICHOST;
#ifdef AI_NUMERICSERV
	hints.ai_flags |= AI_NUMERICSERV;
#endif	/* AI_NUMERICSERV */

	error = getaddrinfo(dstaddrstr, servname, &hints, &res0);
	if (error) {
		kLogWrite(L_WARNING,
			"%s: getaddrinfo(af(%d) st(%d) pr(%d)) fail (%s)", __FUNCTION__,
			res0->ai_family, res0->ai_socktype, res0->ai_protocol,
			gai_strerror(error));
		freeaddrinfo(res0);
		return(-1);
	}
	
	buflen = sizeof(buf);
	sockaddr2string(res0->ai_addr, buf, (int *)&buflen);

	fd = socket(res0->ai_family, res0->ai_socktype, res0->ai_protocol);
	if (fd < 0) {
		perror("socket");
		freeaddrinfo(res0);
		return(-1);
	}

	error = setsockopt(fd, SOL_SOCKET, SO_DEBUG,
			   (char *)&on, sizeof(on));
	if (error) {
		perror("setsockopt");
		freeaddrinfo(res0);
		close(fd);
		return(-1);
	}

/*
	error = setsockopt(fd, SOL_SOCKET, SO_DONTROUTE,
			   (char *)&on, sizeof(on));
	if (error) {
		perror("setsockopt");
		freeaddrinfo(res0);
		close(fd);
		return(-1);
	}
*/

	error = setsockopt(fd, SOL_SOCKET, SO_REUSEADDR,
			   &on, sizeof(on));
	if (error) {
		perror("setsockopt");
		freeaddrinfo(res0);
		close(fd);
		return(-1);
	}

	error = setsockopt(fd, SOL_SOCKET, SO_REUSEPORT,
			   &on, sizeof(on));
	if (error) {
		perror("setsockopt");
		freeaddrinfo(res0);
		close(fd);
		return(-1);
	}

	if (addrfamily == AF_INET) {
		error = setsockopt(fd, IPPROTO_IP, IP_RECVDSTADDR,
				   &on, sizeof(on));
		if (error) {
			perror("setsockopt");
			freeaddrinfo(res0);
			close(fd);
			return(-1);
		}

		error = setsockopt(fd, IPPROTO_IP, IP_RECVIF,
				   &on, sizeof(on));
		if (error) {
			perror("setsockopt");
			freeaddrinfo(res0);
			close(fd);
			return(-1);
		}
	}

	if (addrfamily == AF_INET6) {
		int offset = 2;

		error = setsockopt(fd, IPPROTO_IPV6, IPV6_FAITH,
				   &on, sizeof(on));
		if (error) {
			perror("setsockopt");
			freeaddrinfo(res0);
			close(fd);
			return(-1);
		}

		error = setsockopt(fd, IPPROTO_IPV6, IPV6_CHECKSUM,
				   &offset, sizeof(offset));
		if (error) {
			perror("setsockopt");
			freeaddrinfo(res0);
			close(fd);
			return(-1);
		}

		error = setsockopt(fd, IPPROTO_IPV6, IPV6_V6ONLY,
				   &on, sizeof(on));
		if (error) {
			perror("setsockopt");
			freeaddrinfo(res0);
			close (fd);
			return(-1);
		}
#ifdef IPV6_RECVPKTINFO
		error = setsockopt(fd, IPPROTO_IPV6, IPV6_RECVPKTINFO,
				   &on, sizeof(on));
#else	/* IPV6_RECVPKTINFO */
		error = setsockopt(fd, IPPROTO_IPV6, IPV6_PKTINFO,
				   &on, sizeof(on));
#endif	/* IPV6_RECVPKTINFO */
		if (error) {
			perror("setsockopt");
			freeaddrinfo(res0);
			close (fd);
			return(-1);
		}

		ICMP6_FILTER_SETBLOCKALL (&filter);
		ICMP6_FILTER_SETPASS (ICMP6_ECHO_REQUEST, &filter);
		ICMP6_FILTER_SETPASS (ICMP6_ECHO_REPLY, &filter);
		/*ICMP6_FILTER_SETPASS (ICMP6_DST_UNREACH, &filter);*/
		/*ICMP6_FILTER_SETPASS (ICMP6_PACKET_TOO_BIG, &filter);*/
		/*ICMP6_FILTER_SETPASS (ICMP6_TIME_EXCEEDED, &filter);*/
		/*ICMP6_FILTER_SETPASS (ICMP6_PARAM_PROB, &filter);*/

		error = setsockopt(fd, IPPROTO_ICMPV6, ICMP6_FILTER,
				   &filter, sizeof (filter));
		if (error) {
			perror("setsockopt");
			freeaddrinfo(res0);
			close (fd);
			return(-1);
		}

#ifdef IPV6_RECVHOPLIMIT
		error = setsockopt(fd, IPPROTO_IPV6, IPV6_RECVHOPLIMIT,
				   &on, sizeof (on));
#else	/* IPV6_RECVHOPLIMIT */
		error = setsockopt(fd, IPPROTO_IPV6, IPV6_HOPLIMIT,
				   &on, sizeof (on));
#endif	/* IPV6_RECVHOPLIMIT */
		if (error) {
			perror("setsockopt");
			freeaddrinfo(res0);
			close (fd);
			return(-1);
		}
	}

	if (bind(fd, (struct sockaddr *)&src, src.ss_len) < 0) {
		perror("bind");
		close(fd);
		freeaddrinfo(res0);
		return(-1);
	}

	if (connect(fd, res0->ai_addr, res0->ai_addrlen) < 0) {
		perror("connect");
		close(fd);
		freeaddrinfo(res0);
		return(-1);
	}

	kLogWrite(L_INFO, "%s: connected", __FUNCTION__);

	kSocketMakeSocketStatusClose(fd);

	/* select action */
	if((kSocketSelectOperation(fd, SELECT_IN)) < 0) {
		kLogWrite(L_WARNING,
			"%s: kSocketSelectOperation() error", __FUNCTION__);
		close(fd);
		return(-1);
	}

	/* allocate memory for new SocketInfo space */
	socketInfo = (SocketInfo*)malloc(sizeof(SocketInfo));
	if(!socketInfo) {
		kLogWrite(L_ERROR, "%s: malloc for new SocketInfo fail", __FUNCTION__);
		kSocketSelectOperation(fd,SELECT_OUT); /* recovery */
		close(fd);
		return(-1);
	}
	memset(socketInfo, 0, sizeof(*socketInfo));

	kLogWrite(L_DEBUG,
		"%s: allocate memory for SocketInfo structure", __FUNCTION__);

	/* allocate memory for uniq_data part of new SocketInfo */
	socketInfo->si_uniq_info_ptr
		= (DatasocketInfo*)malloc(sizeof(DatasocketInfo));
	if(!socketInfo->si_uniq_info_ptr) {
		kLogWrite(L_ERROR, "%s: malloc for uniq_data space fail", __FUNCTION__);
		free(socketInfo);
		kSocketSelectOperation(fd, SELECT_OUT); /* recovery */
		close(fd);
		return(-1);
	}
	memset(socketInfo->si_uniq_info_ptr, 0, sizeof(DatasocketInfo));

	kLogWrite(L_DEBUG, "%s: allocate memory for uniq_data", __FUNCTION__);

	/* set data */
	socketInfo->si_type = SI_TYPE_RAW;

	g_socket_socketid ++;	/* increment for next first start from 1*/
	socketInfo->si_socketid	= g_socket_socketid;

	socketInfo->si_sockethandle = fd;
	strcpy((char *)socketInfo->si_linkname, (const char *)linkname);
	socketInfo->si_socket_status = SI_STATUS_ALIVE;
	socketInfo->si_peyload_type = nullparser; /* P_NULL */

	dataSocketInfo = (DatasocketInfo*)socketInfo->si_uniq_info_ptr;
	dataSocketInfo->di_family = src.ss_family;

	/* set parser */
	if(!kParserGet(nullparser, SI_TYPE_RAW, &(dataSocketInfo->di_parser))) {
		kLogWrite(L_WARNING, "%s: kParserGet fail. abort", __FUNCTION__);

		/* recovery */
		free(socketInfo->si_uniq_info_ptr);
		free(socketInfo);
		g_socket_socketid --;
		kSocketSelectOperation(fd, SELECT_OUT);
		close(fd);
		return(-1);
	}

	/* advanced */
	memcpy(&dataSocketInfo->di_sss_addr,
	       &src, sizeof(src));
	memcpy(&dataSocketInfo->di_ssd_addr,
	       res0->ai_addr, res0->ai_addrlen);
	dataSocketInfo->di_s_port = 0;
	dataSocketInfo->di_d_port = 0;

	/* set source port and src addr */
	if(src.ss_family == PF_INET6) {
		/* src */
		struct sockaddr_in6 *sin6 = (struct sockaddr_in6 *)&src;
		memcpy(&dataSocketInfo->di_s_addr,
		       &sin6->sin6_addr, sizeof(struct in6_addr));

		/* dst */
		sin6 = (struct sockaddr_in6 *)res0->ai_addr;
		memcpy(&dataSocketInfo->di_d_addr,
		       &sin6->sin6_addr, sizeof(struct in6_addr));
	} else {
		/* src */
		struct sockaddr_in *sin = (struct sockaddr_in *)&src;
		memcpy(&dataSocketInfo->di_s_addr,
		       &sin->sin_addr, sizeof(struct in_addr));

		/* dst */
		sin = (struct sockaddr_in *)res0->ai_addr;
		memcpy(&dataSocketInfo->di_d_addr,
		       &sin->sin_addr, sizeof(struct in_addr));
	}

	/* add SocketInfo to linked list */
	if(g_socket_start_ptr) {
		/* last data's next is new */
		g_socket_last_ptr->si_next_socket_info_ptr = socketInfo;
		kLogWrite(L_DEBUG, "%s: SocketInfo added to table", __FUNCTION__);
	}
	else {
		/* it is first one */
		g_socket_start_ptr = socketInfo;
		kLogWrite(L_DEBUG,
			"%s: SocketInfo added to table. it was first data", __FUNCTION__);
	}

	/* new data's next is NULL */
	socketInfo->si_next_socket_info_ptr = NULL;

	/* now, last data is new */
	g_socket_last_ptr = socketInfo;

	/* return value set */
	*socketid = socketInfo->si_socketid;

	kLogWrite(L_INFO,
		"%s: as socket_id[%d]", __FUNCTION__, socketInfo->si_socketid);

	freeaddrinfo(res0);

	return(RETURN_OK);
}



#ifdef SUPPORT_TLS
static int
IsExistSameSocket(unsigned char type,
	char addressFamily, unsigned short s_port, struct in6_addr s_addr)
{
	ListenportInfo *info = NULL;
	int loop = 0;
	SocketInfo *si = g_socket_start_ptr;

	addressFamily = (addressFamily == CM_IP_IPV6 ? AF_INET6 : AF_INET);

	for(loop = 0; si && loop < SOCKET_MAXNUM; loop ++) {
		if(((type == SI_TYPE_LISTEN_UDP) || (type == SI_TYPE_LISTEN_TCP)) &&
			si->si_type == type &&
			si->si_socket_status == SI_STATUS_ALIVE) {

			info = (ListenportInfo*)(si->si_uniq_info_ptr);
			if(info->li_s_port == s_port && info->li_family == addressFamily) {
				return(1);
			}
		}

		si = si->si_next_socket_info_ptr;   
	}

	return(0);
}



char *   
kAddr2Str(struct sockaddr *addr)
{
	if(addr->sa_family == AF_INET){
		return(kAddr2Str0(addr->sa_family,
			(void*)&(((struct sockaddr_in*)addr)->sin_addr)));
	} else{
		return(kAddr2Str0(addr->sa_family,
			(void*)&(((struct sockaddr_in6*)addr)->sin6_addr)));
	}
}



char *
kAddr2Str0(int family, void *addr)
{      
	u_char *v4;
	u_int16_t *v6;
	static char AddrName[64];

	if(family == AF_INET) {
		v4 = (u_char *)addr;
		sprintf(AddrName,"%d.%d.%d.%d", v4[0], v4[1], v4[2], v4[3]);
	} else if(family == AF_INET6) {
		v6 = (u_int16_t *)addr;
		sprintf(AddrName, "%04x:%04x:%04x:%04x:%04x:%04x:%04x:%04x",
			v6[0], v6[1], v6[2], v6[3], v6[4], v6[5], v6[6], v6[7]);
	} else {
		kLogWrite(L_WARNING,"%s: Address family[%d] invalid",
			__FUNCTION__,family);
		AddrName[0] = 0;
	}

	return(AddrName);
}
#endif	/* SUPPORT_TLS */
