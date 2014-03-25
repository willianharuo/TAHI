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
 * $TAHI: koi/lib/kDispatcher/kDispatcher.c,v 1.59 2007/04/05 07:54:16 akisada Exp $
 *
 * $Id: kDispatcher.c,v 1.14 2009/06/16 08:43:19 velo Exp $
 *
 */

/*
  08/4/18 SocketInfoDump: change display information
  08/3/18 read_unixd_data: create
          udpaccept,process_si_type_unixd: add setsockopt(SO_SNDBUF,SO_RCVBUF)
          process_si_type_unixd_data: call read_unixd_data in place of read
*/

#include <stdio.h>
#include <stdlib.h>
#include <unistd.h>
#include <errno.h>

#include <string.h>

#include <sys/types.h>
#include <sys/socket.h>
#include <netinet/in.h>	/* for arpa/inet.h */
#include <arpa/inet.h>	/* for inet_ntop() */
#include <sys/un.h> 	/* unix domein socket address structure */
#include <sys/uio.h>
#include <netdb.h>

#include <koi.h>

#include "kDispatcher.h"

/* process socket data */
static int process_unixd(int, unsigned char);

/* process SocketInfo type functins */
static int process_si_type_unixd(int);
static int process_si_type_unixd_data(int);
static int process_si_type_udp(int);
static int process_si_type_tcp(int);
static int process_si_type_listen(int, unsigned char);
static int process_si_type_raw(int);

/* accept(2) for udp */
static int udpaccept(int, struct sockaddr *, socklen_t *, char *, int *);

/* ack functions */
static int connec_send_ack_return(int,
	short, short, short, short, long, struct timeval);
static int close_wait_ack_return(int, short, short, short, short);
static int sockinfo_ack_return(int,
	short, short, short, SocketInfo *, DatasocketInfo *, ListenportInfo *);
static int datainfo_ack_return(int, short, short, short, MsgData *);
static bool flush_ack_return(int, short, short, short);
#ifdef SUPPORT_TLS
static bool tls_setup_ack_return(int, short, short, short);
static bool tls_clear_ack_return(int, short, short, short);
#endif	/* SUPPORT_TLS */



/*
 * process command functions
 * These are called by process_si_type_unixd_data().
 */
static int process_command_connect_req(int, short, char *, long);
static int process_command_send_req(int, short, char *, long);
static int process_command_recv_req(int, short, char *, long);
static int process_command_close_req(int, short, char *, long);
static int process_command_wait_req(int, short, char *, long);
static int process_command_sockinfo_req(int, short, char *, long);
static int process_command_datainfo_req(int, short, char *, long);
static bool process_command_flush_req(int, short, char *, long);
#ifdef SUPPORT_TLS
static bool process_command_tls_setup_req(int, short, char*, long);
static bool process_command_tls_clear_req(int, short, char*, long);
#endif	/* SUPPORT_TLS */
static bool process_command_parser_attach_req(int, short, char *, long);

/* debug function */
static void SocketInfoDump(void);



static char *COMMAND_NAME[] = {
	"Conect Send",
	"Send",
	"Receive",
	"Close",
	"Receive Waiting",
	"Get SocketInfo",
	"Get DataInfo",
	"FLUSH",
	"TLS SETUP",
	"TLS CLEAR"
};



/*--------------------------------------------------------------------*
 * int kDispatcherProc(int, unsigned char);                           *
 *--------------------------------------------------------------------*/
/* dispatcher */
int
kDispatcherProc(int handle, unsigned char type)
{
  static char *Type[]={"UNIX","UNIX-DATA","UDP-DATA","TCP-DATA","UDP","TCP"};

	kLogWrite(L_DEBUG,"%s: socketfd[%d] pkt-type[%s] <=", __FUNCTION__, handle, Type[type-1]);

	switch(type) {
		case SI_TYPE_UNIX:
		case SI_TYPE_UNIX_DATA:
			process_unixd(handle, type);
			break;
		case SI_TYPE_UDP:
			process_si_type_udp(handle);
			break;
		case SI_TYPE_DATA:
			process_si_type_tcp(handle);
			break;
		case SI_TYPE_LISTEN_TCP:	/* XXX */
		case SI_TYPE_LISTEN_UDP:
			process_si_type_listen(handle, type);
			break;
		case SI_TYPE_RAW:
			process_si_type_raw(handle);
			break;
		default:
			return(false);
	}
	kLogWrite(L_DEBUG,"%s: socketfd[%d] pkt-type[%s] =>", __FUNCTION__, handle, Type[type-1]);

	return(true);
}



/*--------------------------------------------------------------------*
 * static int process_unixd(int, unsigned char);                      *
 *--------------------------------------------------------------------*/
/* obsoletes fd_command_action */
static int
process_unixd(int handle, unsigned char type)
{
	kLogWrite(L_INFO, "%s: start-------------------------", __FUNCTION__);

	switch (type) {
		case SI_TYPE_UNIX:
			if(process_si_type_unixd(handle) < 0) {
				return(RETURN_NG);
			}

			return(RETURN_OK);
			break;

		case SI_TYPE_UNIX_DATA:
			if(process_si_type_unixd_data(handle) < 0) {
				return(RETURN_NG);
			}

			return(RETURN_OK);
			break;

		default:
			/* error */
			kLogWrite(L_WARNING, "%s: invalid type[%d] for handle[%d] . abort",
				__FUNCTION__, type, handle);
			return(RETURN_NG);
	}

	return(RETURN_OK);
}



/*--------------------------------------------------------------------*
 * int udpaccept(int, struct sockaddr *, socklen_t *, char *, int *); *
 *--------------------------------------------------------------------*/
int
udpaccept(int fd,
	struct sockaddr *from, socklen_t *fromlen, char *buf, int *buflen)
{
	struct iovec iov;
	char control[1024];
	struct msghdr msg;
	int n = 0;
	struct sockaddr_storage src;
	socklen_t srclen = sizeof(src);
	int flag = NI_NUMERICHOST;
	char hbuf[1024];
	int hbuflen = sizeof(hbuf);
	int af = 0;
	int udpfd = 0;
	const int on = 1;
	struct cmsghdr *cmsgptr = NULL;
	unsigned char dstaddr[32];
	int sndbuf = 0xffff;
	int rcvbuf = 0xffff;

	memset(&iov, 0, sizeof(iov));
	memset(control, 0, sizeof(control));
	memset(&msg, 0, sizeof(msg));
	memset(&src, 0, sizeof(src));
	memset(hbuf, 0, sizeof(hbuf));
	memset(dstaddr, 0, sizeof(dstaddr));

	iov.iov_base = buf;
	iov.iov_len = *buflen;

	msg.msg_name = (caddr_t)from;
	msg.msg_namelen = *fromlen;
	msg.msg_iov = &iov;
	msg.msg_iovlen = 1;
	msg.msg_control = control;
	msg.msg_controllen = sizeof(control);

	msg.msg_flags = 0;

	kLogWrite(L_INFO, "%s: start for sockethandle[%d]", __FUNCTION__, fd);

	*buflen = n = recvmsg(fd, &msg, 0);
	if(n < 1) {
		perror("recvmsg");

		kLogWrite(L_WARNING,
			"%s: recvmsg() fail. errno[%d]", __FUNCTION__, errno);

		return(-1);
	}
	kLogWrite(L_SOCKET,
		"%s: handle[%d] recvmsg() success -- %ld bytes",
			__FUNCTION__, fd, *buflen);

	for (cmsgptr = CMSG_FIRSTHDR(&msg); cmsgptr != NULL; cmsgptr = CMSG_NXTHDR(&msg, cmsgptr)) {
	  if (cmsgptr->cmsg_level == IPPROTO_IP && cmsgptr->cmsg_type == DSTADDR_SOCKOPT) {
	    /* printf("IPV4 src port[%d]\n",ntohs(((struct sockaddr_in*)from)->sin_port)); */
	    memcpy(dstaddr, (char *)dstaddr(cmsgptr), sizeof(struct in_addr));
	  }
	  if (cmsgptr->cmsg_level == IPPROTO_IPV6 && cmsgptr->cmsg_type == IPV6_PKTINFO) {
	    /* printf("IPV6 src port[%d]\n", ntohs(((struct sockaddr_in6*)from)->sin6_port) ); */
	    memcpy(dstaddr, (char *) dstaddr6(cmsgptr), sizeof(struct in6_addr));
	  }
	}
	*fromlen = msg.msg_namelen;

	if(getsockname(fd, (struct sockaddr *)&src, &srclen) < 0) {
		perror("getsockname");

		kLogWrite(L_WARNING,
			"%s: getsockname() fail. errno[%d]", __FUNCTION__, errno);
		return(-1);
	}

	if(src.ss_family == AF_INET)
	  memcpy(&((struct sockaddr_in  *)&src)->sin_addr, dstaddr, sizeof(struct in_addr));
	if(src.ss_family == AF_INET6) {
	  memcpy(&((struct sockaddr_in6 *)&src)->sin6_addr, dstaddr, sizeof(struct in6_addr));
		((struct sockaddr_in6 *)&src)->sin6_scope_id =
			((struct sockaddr_in6 *)from)->sin6_scope_id;
	}

	if(getnameinfo((struct sockaddr *)&src,
		src.ss_len, hbuf, hbuflen, NULL, 0, flag) != 0) {
		kLogWrite(L_WARNING, "%s: could not resolve hostname", __FUNCTION__);
		return(-1);
	}

	switch(src.ss_family) {
		case AF_INET:
			{
				struct sockaddr_in *sin = (struct sockaddr_in *)&src;

				kLogWrite(L_DEBUG,
					"%s:\n\taf(%d) addr(%s) port(%d) len(%d)\n", __FUNCTION__,
					sin->sin_family, hbuf, ntohs(sin->sin_port), sin->sin_len);
			}

			break;

		case AF_INET6:
			{
				struct sockaddr_in6 *sin6 = (struct sockaddr_in6 *)&src;

				kLogWrite(L_DEBUG,
					"%s:\n\taf(%d) addr(%s) port(%d) scope(%d) len(%d)\n",
					__FUNCTION__,
					sin6->sin6_family, hbuf, ntohs(sin6->sin6_port),
					sin6->sin6_scope_id, sin6->sin6_len);
			}

			break;

		default:
			break;
	}

	af = src.ss_family;

	if((udpfd = socket(af, SOCK_DGRAM, IPPROTO_UDP)) < 0) {
		perror("socket");

		kLogWrite(L_WARNING,
			"%s: socket() fail. errno[%d]", __FUNCTION__, errno);
		return(-1);
	}

	if(af == AF_INET6) {	/* XXX: ??? Is IPV6_FAITH needed? */
		if(setsockopt(udpfd, IPPROTO_IPV6, IPV6_FAITH, &on, sizeof(int)) < 0) {
			close(udpfd);

			kLogWrite(L_WARNING, "%s: setsockopt() IPV6_FAITH fail. errno[%d]",
				__FUNCTION__, errno);

			return(-1);
		}
	}

	if(setsockopt(udpfd, SOL_SOCKET, SO_REUSEPORT, &on, sizeof(int)) < 0) {
		close(udpfd);

		kLogWrite(L_WARNING, "%s: setsockopt() SO_REUSEPORT fail. errno[%d]",
			__FUNCTION__, errno);

		return(-1);
	}

	if(setsockopt(udpfd, SOL_SOCKET, SO_REUSEADDR, &on, sizeof(int)) < 0) {
		close(udpfd);

		kLogWrite(L_WARNING, "%s: setsockopt() SO_REUSEADDR fail. errno[%d]",
			__FUNCTION__, errno);

		return(-1);
	}

	if(setsockopt(udpfd,
		      SOL_SOCKET,SO_SNDBUF, &sndbuf, sizeof(sndbuf))) {
		close(udpfd);
		kLogWrite(L_WARNING,
		    "%s: setsockopt(SO_SNDBUF) fails", __FUNCTION__);
		return(-1);
	}

	if(setsockopt(udpfd,
		      SOL_SOCKET,SO_RCVBUF, &rcvbuf, sizeof(rcvbuf))) {
		close(udpfd);
		kLogWrite(L_WARNING,
		    "%s: setsockopt(SO_RCVBUF) fails", __FUNCTION__);
		return(-1);
	}

	if(bind(udpfd, (struct sockaddr *)&src, srclen) < 0) {
		perror("bind");
		close(udpfd);

		kLogWrite(L_WARNING, "%s: bind() fail. errno[%d]", __FUNCTION__, errno);

		return(-1);
	}

	if(connect(udpfd, from, *fromlen) < 0) {
		perror("connect");
		close(udpfd);

		kLogWrite(L_WARNING,
			"%s: connect() fail. errno[%d]", __FUNCTION__, errno);

		return(-1);
	}

	kLogWrite(L_SOCKET, "%s: UDP accept new socket fd[%d]", __FUNCTION__, udpfd);

	return(udpfd);
}



/*--------------------------------------------------------------------*
 * static int process_si_type_listen(int, unsigned char);             *
 *--------------------------------------------------------------------*/
/* obsoletes fd_listen_action */
static int
process_si_type_listen(int handle, unsigned char type)
{
	int	data_socket_handle = 0;
	SocketInfo	socketinfo;
	DatasocketInfo	datasocketinfo;
	ListenportInfo	listenportinfo;
	int	(*parser)(long, unsigned char*, unsigned char**, short*);
	char	recvbuf[MSG_MAXDATALEN + 1];
	int	recvbufsize = sizeof(recvbuf);
	int	si_type = 0;
	int	newid = 0;
	unsigned char	af = 0;
	void *tlsssl=NULL,*tlssession=NULL;

	struct sockaddr_storage	src;
	struct sockaddr_storage	dst;
	socklen_t	socklen;
	socklen_t	srclen = sizeof(src);
	char	hbuf[1024];
	int	hbuflen = 0;
	int	flag = 0;

	memset(&socketinfo, 0, sizeof(socketinfo));
	memset(&datasocketinfo, 0, sizeof(datasocketinfo));
	memset(&listenportinfo, 0, sizeof(listenportinfo));
	memset(&src, 0, sizeof(src));
	memset(&dst, 0, sizeof(dst));
	memset(recvbuf, 0, sizeof(recvbuf));

	kLogWrite(L_INFO,
		"%s: start for sockethandle[%d]--------", __FUNCTION__, handle);

	/* accept */
	socklen = sizeof(struct sockaddr_in6);
	if (type == SI_TYPE_LISTEN_UDP) {
		data_socket_handle = udpaccept(handle,
					       (struct sockaddr*)&dst,
					       &socklen,
					       recvbuf, &recvbufsize);
		if(data_socket_handle < 0) {
			perror("udpaccept");
			kLogWrite(L_ERROR,
				 "%s: udpaccept() fail. errno is [%d]. abort",
					__FUNCTION__, errno);
			return(RETURN_NG);
		}

	}
	else { /* SI_TYPE_LISTEN_TCP */
		data_socket_handle = accept(handle,
					    (struct sockaddr*)&dst,
					    &socklen);
		if(data_socket_handle < 0) {
			kLogWrite(L_ERROR,
				"%s: accept() fail. errno is [%d]. abort",
				__FUNCTION__, errno);
			return(RETURN_NG);
		}
	}

	kLogWrite(L_INFO,
		"%s: new data socket handle[%d]", __FUNCTION__, data_socket_handle);

	/* get local address */
	if (getsockname(data_socket_handle, (struct sockaddr *)&src, &srclen) < 0) {
		perror("getsockname");

		kLogWrite(L_WARNING,
			"%s: getsockname() fail. errno[%d]", __FUNCTION__, errno);

		return(-1);
	}

	hbuflen = sizeof(hbuf);
	flag = NI_NUMERICHOST;
	if (getnameinfo((struct sockaddr *)&src, src.ss_len,
			hbuf, hbuflen, NULL, 0, flag) != 0) {
		kLogWrite(L_WARNING,
			 "%s: could not resolve hostname", __FUNCTION__);
		return(-1);
	}

	kLogWrite(L_DEBUG,
		"%s: getsockname() %s", __FUNCTION__, hbuf);

	if (getnameinfo((struct sockaddr *)&dst, dst.ss_len,
			hbuf, hbuflen, NULL, 0, flag) != 0) {
		kLogWrite(L_WARNING,
			"%s: could not resolve hostname", __FUNCTION__);
		return(-1);
	}

	kLogWrite(L_DEBUG,
		"%s: getsockname() %s", __FUNCTION__, hbuf);

	/* get parent si */
	if (type == SI_TYPE_LISTEN_UDP) {
		if((kSocketGetSIBySocketHandle(handle, &socketinfo,
					       NULL,
					       &datasocketinfo,
					       NULL)) < 0) {
			kLogWrite(L_INFO,
				"%s: kSocketGetSIBySocketHandle(listen_udp) error. abort",
				__FUNCTION__);
			return(RETURN_NG);
		}

	}
	else { /* SI_TYPE_LISTEN_TCP */
		if((kSocketGetSIBySocketHandle(handle, &socketinfo,
					       NULL, NULL,
					       &listenportinfo)) < 0) {
			kLogWrite(L_INFO,
				"%s: kSocketGetSIBySocketHandle(listen_tcp) error. abort",
				__FUNCTION__);
			return(RETURN_NG);
		}

	}

	/* get parser */
	if(!kParserGet(socketinfo.si_peyload_type,
			socketinfo.si_type, &parser)) {
#ifdef DBG_PARSER
	kdbg("/tmp/dbg_parser.txt", "kParserGet: %s\n", "false");
#endif	/* DBG_PARSER */
		kLogWrite(L_INFO,
			"%s: kParserGet for [%d] is error. abort.",
			__FUNCTION__, socketinfo.si_peyload_type);
		return(RETURN_NG);
	}
#ifdef DBG_PARSER
	kdbg("/tmp/dbg_parser.txt", "kParserGet: %s\n", "true");
	kdbg("/tmp/dbg_parser.txt", "parser: %p\n", parser);
#endif	/* DBG_PARSER */

#ifdef SUPPORT_TLS
	/* TLS auth Handshake */
	if(socketinfo.si_tls_mode){
	  if(kTLSAccept(data_socket_handle,&tlsssl,&tlssession)){
		kLogWrite(L_CMD, "%s: kTLSAccept TLS connection accesp error. abort.",__FUNCTION__);
		return(RETURN_NG);
	  }
	}
#endif	
	/* regist child socoket */
	si_type = (type == SI_TYPE_LISTEN_TCP) 
		? SI_TYPE_DATA : SI_TYPE_UDP;
	af = (si_type == SI_TYPE_DATA)
		? listenportinfo.li_family : datasocketinfo.di_family;

	newid = kSocketRegistDataSocketInfo(
		si_type,
		data_socket_handle,
		socketinfo.si_linkname,
		socketinfo.si_peyload_type,
		src,
		dst,
		parser,
		socketinfo.si_socketid,
		af,socketinfo.si_tls_mode,tlsssl);

	/* select */
	kSocketSelectOperation(data_socket_handle, SELECT_IN);

	/* registdata */
	if (type == SI_TYPE_LISTEN_UDP &&
	    newid > 0) {
		struct timeval	current_time;
		gettimeofday(&current_time, NULL);
		if((kDataRegist(newid, MSG_SOCKETMODE_RECV,
				recvbufsize, (unsigned char *)recvbuf, current_time)) < 0) {
			kLogWrite(L_INFO,
				"%s: regist_data fail for handle[%d] socketid[%d]",
				__FUNCTION__, handle, newid);
		}
	}

	return(RETURN_OK);
}



/*--------------------------------------------------------------------*
 * int recv_ack_return(int, short, short, short, short, MsgData *);   *
 *--------------------------------------------------------------------*/
/* recv_ack_return */
int
recv_ack_return(int handle, short command,
	short request_num, short result, short socketid, MsgData *msgdata)
{
	int	write_data_size = 0;
	RECV_ACK recv_ack;

	memset(&recv_ack, 0, sizeof(recv_ack));

#ifdef DBG_DISPATCHER
	kdbg("/tmp/dbg_dispatcher.txt", "%s\n", "initializing.");
#endif  /* DBG_DISPATCHER */

	kLogWrite(L_CMD,
		"%s:>> command is [%s] result[%d]",
		__FUNCTION__, COMMAND_NAME[(command & 0xF) - 1], result);

	/* data generation */
	recv_ack.command		= htons(command);
	recv_ack.request_num	= htons(request_num);

	if(result) {
		/* NG */
		recv_ack.result		= htons(result);
		recv_ack.socketid	= htons(socketid);
		kLogWrite(L_DEBUG, "%s: result NG", __FUNCTION__);
	} else {
		/* OK */
		recv_ack.result				= htons(result);
		recv_ack.socketid			= htons(socketid);
		recv_ack.dataid				= htonl(msgdata->msg_dataid);
		recv_ack.timestamp.tv_sec	= htonl(msgdata->msg_timestamp.tv_sec);
		recv_ack.timestamp.tv_usec	= htonl(msgdata->msg_timestamp.tv_usec);
		recv_ack.s_port				= htons(msgdata->msg_s_port);
		recv_ack.d_port				= htons(msgdata->msg_d_port);
		if (msgdata->msg_family == AF_INET) {
			recv_ack.ipver	= CM_IP_IPV4;
		}
		else if (msgdata->msg_family == AF_INET6) {
			recv_ack.ipver	= CM_IP_IPV6;
		}
		else {
			kLogWrite(L_ERROR, "%s: unknown address family(%d)",
				__FUNCTION__, msgdata->msg_family);
		}

		memcpy(&(recv_ack.s_addr),
			&(msgdata->msg_s_addr), sizeof(recv_ack.s_addr));
		memcpy(&(recv_ack.d_addr),
			&(msgdata->msg_d_addr), sizeof(recv_ack.d_addr));

		recv_ack.datalen	= htonl(msgdata->msg_datalen);

		memcpy(recv_ack.data, msgdata->msg_data_ptr,
			msgdata->msg_datalen);
#ifdef DBG_DISPATCHER
		kdmp("/tmp/dbg_dispatcher.txt", "msgdata",
			msgdata->msg_data_ptr, msgdata->msg_datalen);
#endif  /* DBG_DISPATCHER */
		write_data_size = msgdata->msg_datalen;
		kLogWrite(L_DEBUG, "%s: result OK", __FUNCTION__);
	}

	/* send back */
	/* printf("recv_ack_return [%d]\n",write_data_size); */
	if((write(handle, &recv_ack,
		(sizeof(recv_ack) - (MSG_MAXDATALEN) + write_data_size))) < 0) {

		kLogWrite(L_WARNING,
			"%s: write() error. errno is %d.", __FUNCTION__, errno);
		return(RETURN_NG);
	}
	kLogWrite(L_INFO, "%s: write() success", __FUNCTION__);

	return(RETURN_OK);
}



/*--------------------------------------------------------------------*
 * static int                                                         *
 * connec_send_ack_return(int,                                        *
 *     short, short, short, short, long, struct timeval)              *
 *--------------------------------------------------------------------*/
/* connec_send_ack_return() */
static int
connec_send_ack_return(int handle, short command, short request_num,
	short result, short socketid, long dataid, struct timeval timestamp)
{
	CONNEC_ACK	connec_ack;

	memset(&connec_ack, 0, sizeof(connec_ack));

	if(command == (short)CM_CM_SIG_CONNEC_ACK) {
		kLogWrite(L_INFO, "%s: command is CONNEC_ACK", __FUNCTION__);
	} else if(command == (short)CM_CM_SIG_SEND_ACK) {
		kLogWrite(L_INFO, "%s: command is SEND_ACK", __FUNCTION__);
	}

	connec_ack.command	= htons(command);
	connec_ack.request_num	= htons(request_num);

	if(result) {
		/* NG */
		connec_ack.result = htons(result);
		kLogWrite(L_DEBUG, "%s: result NG", __FUNCTION__);
	} else {
		connec_ack.result	= htons(result);
		connec_ack.socketid	= htons(socketid);
		connec_ack.dataid	= htonl(dataid);
		connec_ack.timestamp.tv_sec	= htonl(timestamp.tv_sec);
		connec_ack.timestamp.tv_usec	= htonl(timestamp.tv_usec);
		kLogWrite(L_DEBUG, "%s: result OK", __FUNCTION__);
	}

	/* send back */
	if((write(handle, &connec_ack, sizeof(connec_ack))) < 0) {
		kLogWrite(L_WARNING,
			"%s: write() error. errno is %d.", __FUNCTION__, errno);
		return(RETURN_NG);
	}

	kLogWrite(L_INFO, "%s: write() success", __FUNCTION__);

	return(RETURN_OK);
}



/*--------------------------------------------------------------------*
 * static int close_wait_ack_return(int, short, short, short, short); *
 *--------------------------------------------------------------------*/
static int
close_wait_ack_return(int handle,
	short command, short request_num, short result, short socketid)
{
	CLOSE_ACK	close_ack;

	memset(&close_ack, 0, sizeof(CLOSE_ACK));

	if(command == (short)CM_CM_SIG_CLOSE_ACK) {
		kLogWrite(L_INFO, "%s: command is CLOSE_ACK", __FUNCTION__);
	} else if(command == (short)CM_CM_SIG_WAIT_ACK) {
		kLogWrite(L_INFO, "%s: command is WAIT_ACK", __FUNCTION__);
	}

	/* data generation */
	close_ack.command	= htons(command);
	close_ack.request_num	= htons(request_num);

	if(result) {
		/* NG */
		close_ack.result = htons(result);
		kLogWrite(L_DEBUG, "%s: result NG", __FUNCTION__);
	} else {
		/* OK */
		close_ack.result	= htons(result);
		close_ack.socketid	= htons(socketid);
		kLogWrite(L_DEBUG, "%s: result OK", __FUNCTION__);
	}

	/* send back */
	if((write(handle, &close_ack, sizeof(close_ack))) < 0) {
		kLogWrite(L_WARNING,
			"%s: write() error. errno is %d.", __FUNCTION__, errno);
		return(RETURN_NG);
	}

	kLogWrite(L_INFO, "%s: write() success", __FUNCTION__);
	return(RETURN_OK);
}



/*--------------------------------------------------------------------*
 * static int                                                         *
 * sockinfo_ack_return(int, short, short, short, SocketInfo *,        *
 *     DatasocketInfo *, ListenportInfo *);                           *
 *--------------------------------------------------------------------*/
static int
sockinfo_ack_return(int handle, short command, short request_num, short result,
	SocketInfo *socketinfo, DatasocketInfo *datasocketinfo,
	ListenportInfo *listenportinfo)
{
	SOCKINFO_ACK	sockinfo_ack;

	memset(&sockinfo_ack, 0, sizeof(sockinfo_ack));

	kLogWrite(L_INFO, "%s: command is SOCKINFO_ACK", __FUNCTION__);

	/*
	 * data generation
	 */
	sockinfo_ack.command	= htons(command);
	sockinfo_ack.request_num	= htons(request_num);

	if(result) {
		/* NG */
		sockinfo_ack.result = htons(result);
		kLogWrite(L_DEBUG, "%s: result NG", __FUNCTION__);
	} else {
		/* OK */

		sockinfo_ack.result	= htons(result);

		/*
		 * protocol
		 */
		if((socketinfo->si_type == SI_TYPE_DATA) ||
		   (socketinfo->si_type == SI_TYPE_LISTEN_TCP)) {
			sockinfo_ack.protocol = socketinfo->si_tls_mode ? CM_PROT_TLS : CM_PROT_TCP;
			kLogWrite(L_DEBUG, "%s: type is TCP", __FUNCTION__);
		} else if((socketinfo->si_type == SI_TYPE_UDP) ||
			(socketinfo->si_type == SI_TYPE_LISTEN_UDP)) {
			sockinfo_ack.protocol = CM_PROT_UDP;

			kLogWrite(L_DEBUG, "%s: type is UDP", __FUNCTION__);
		}
		else if (socketinfo->si_type == SI_TYPE_RAW) {
			sockinfo_ack.protocol = CM_PROT_ICMP;

			kLogWrite(L_DEBUG, "%s: type is ICMP", __FUNCTION__);
		} else {
			kLogWrite(L_WARNING,
				"%s: socoketid[%d].requested socket's type is UNIX.abort",
				__FUNCTION__, socketinfo->si_socketid);
			return(RETURN_NG);
		}

		/* status */
		if(socketinfo->si_socket_status == SI_STATUS_CLOSE) {
			sockinfo_ack.connection_status = CM_STATUS_CLOSE;
			kLogWrite(L_DEBUG, "%s: connection is closed", __FUNCTION__);
		} else if(socketinfo->si_type == SI_TYPE_LISTEN_UDP ||
			socketinfo->si_type == SI_TYPE_LISTEN_TCP) {
			sockinfo_ack.connection_status = CM_STATUS_LISTEN;
			kLogWrite(L_DEBUG,
				"%s: connection is listening someone", __FUNCTION__);
		} else {
			sockinfo_ack.connection_status = CM_STATUS_CONNEC;
			kLogWrite(L_DEBUG, "%s: connection is now ongoing", __FUNCTION__);
		}

		/* ip version */
		if(datasocketinfo) {
			if(datasocketinfo->di_family == AF_INET6) {
				sockinfo_ack.ipver = CM_IP_IPV6;
			} else if (datasocketinfo->di_family == AF_INET) {
				sockinfo_ack.ipver = CM_IP_IPV4;
			} else {
				sockinfo_ack.ipver = 0;
				kLogWrite(L_ERROR, "%s: unknown address family(%d) in di",
					__FUNCTION__, datasocketinfo->di_family);
			}
		} else if(listenportinfo) {
			if (listenportinfo->li_family == AF_INET6) {
				sockinfo_ack.ipver = CM_IP_IPV6;
			} else if (listenportinfo->li_family == AF_INET) {
				sockinfo_ack.ipver = CM_IP_IPV4;
			} else {
				sockinfo_ack.ipver = 0;
				kLogWrite(L_ERROR,
					"%s: unknown address family(%d) in li",
					__FUNCTION__, listenportinfo->li_family);
			}
		}

		/*
		 * port and address
		 */
		if((socketinfo->si_type == SI_TYPE_DATA) ||
		    (socketinfo->si_type == SI_TYPE_UDP)) {

			sockinfo_ack.s_port	= htons(datasocketinfo->di_s_port);
			sockinfo_ack.d_port	= htons(datasocketinfo->di_d_port);
			memcpy(&(sockinfo_ack.s_addr), &(datasocketinfo->di_s_addr),
			       sizeof(sockinfo_ack.s_addr));
			memcpy(&(sockinfo_ack.d_addr), &(datasocketinfo->di_d_addr),
			       sizeof(sockinfo_ack.d_addr));
			kLogWrite(L_DEBUG,
				"%s: s_port d_port s_addr d_addr avaliable", __FUNCTION__);

		} else if(socketinfo->si_type == SI_TYPE_LISTEN_UDP) {
			sockinfo_ack.s_port	= htons(datasocketinfo->di_s_port);
			memcpy(&(sockinfo_ack.s_addr), &(datasocketinfo->di_s_addr),
			       sizeof(sockinfo_ack.s_addr));
			kLogWrite(L_DEBUG, "%s: s_port s_addr avaliable", __FUNCTION__);
		} else if(socketinfo->si_type == SI_TYPE_LISTEN_TCP) {
			sockinfo_ack.s_port	= htons(listenportinfo->li_s_port);
			memcpy(&(sockinfo_ack.s_addr), &(listenportinfo->li_s_addr),
			       sizeof(sockinfo_ack.s_addr));
			kLogWrite(L_DEBUG, "%s: s_port s_addr avaliable", __FUNCTION__);
		}
		else if (socketinfo->si_type == SI_TYPE_RAW) {
			sockinfo_ack.d_port	= htons(datasocketinfo->di_d_port);
			memcpy(&(sockinfo_ack.s_addr), &(datasocketinfo->di_s_addr),
			       sizeof(sockinfo_ack.s_addr));
			memcpy(&(sockinfo_ack.d_addr), &(datasocketinfo->di_d_addr),
			       sizeof(sockinfo_ack.d_addr));
			kLogWrite(L_DEBUG,
				"%s: s_addr d_addr avaliable", __FUNCTION__);
		}

		/* interfaceid and frameid */
		sockinfo_ack.frameid		= htons(socketinfo->si_peyload_type);
		sockinfo_ack.interfaceid
			= htons(atoi((const char *)&(socketinfo->si_linkname[IF_KEYSIZE])));
		sockinfo_ack.tlsmode		= htons(socketinfo->si_tls_mode);
		sockinfo_ack.tlsssl		= htonl((u_long)socketinfo->si_tls_ssl_ptr);
		sockinfo_ack.tlssession	= htonl((u_long)kGetTLSSession(socketinfo->si_tls_ssl_ptr));

		kLogWrite(L_DEBUG, "%s: result OK", __FUNCTION__);
	}

	/* send back */
	if((write(handle, &sockinfo_ack, sizeof(sockinfo_ack))) < 0) {
		kLogWrite(L_WARNING,
			"%s: write() error. errno is %d.", __FUNCTION__, errno);
		return(RETURN_NG);
	}

	kLogWrite(L_INFO, "%s: write() success", __FUNCTION__);
	return(RETURN_OK);
}



/*--------------------------------------------------------------------*
 * static int                                                         *
 * datainfo_ack_return(int, short, short, short, MsgData *);          *
 *--------------------------------------------------------------------*/
static int
datainfo_ack_return(int handle,
	short command, short request_num, short result, MsgData *msgdata)
{
	DATAINFO_ACK	datainfo_ack;
	int				write_data_size=0;

	memset(&datainfo_ack, 0, sizeof(datainfo_ack));

	kLogWrite(L_INFO, "%s: command is DATAINFO_ACK", __FUNCTION__);

	/* data generation */
	datainfo_ack.command		= htons(command);
	datainfo_ack.request_num	= htons(request_num);

	if(result) {
		/* NG */
		datainfo_ack.result = htons(result);
		kLogWrite(L_DEBUG, "%s: result NG", __FUNCTION__);
	} else {
		/* OK */
		datainfo_ack.result		= htons(result);
		datainfo_ack.socketid		= htons(msgdata->msg_socketid);
		datainfo_ack.timestamp.tv_sec	= htonl(msgdata->msg_timestamp.tv_sec);
		datainfo_ack.timestamp.tv_usec = htonl(msgdata->msg_timestamp.tv_usec);
		datainfo_ack.datalen		= htonl(msgdata->msg_datalen);
		memcpy(datainfo_ack.data, msgdata->msg_data_ptr, msgdata->msg_datalen);

		write_data_size = msgdata->msg_datalen;
		kLogWrite(L_DEBUG, "%s: result OK", __FUNCTION__);
	}

	/* send back */
	if((write(handle, &datainfo_ack,
		   sizeof(datainfo_ack) - MSG_MAXDATALEN + write_data_size)) < 0) {
		kLogWrite(L_WARNING,
			"%s: write() error. errno is %d.", __FUNCTION__, errno);
		return(RETURN_NG);
	}

	kLogWrite(L_INFO, "%s: write() success", __FUNCTION__);
	return(RETURN_OK);
}



/*--------------------------------------------------------------------*
 * static bool flush_ack_return(int, short, short, short);            *
 *--------------------------------------------------------------------*/
/* flush_ack_return */
static bool
flush_ack_return(int handle, short command, short request_num, short result)
{
	FLUSH_ACK	flush_ack;

	memset(&flush_ack, 0, sizeof(flush_ack));

	kLogWrite(L_INFO, "%s: command is FLUSH_ACK", __FUNCTION__);

	/* data generatin */
	flush_ack.command	= htons(command);
	flush_ack.request_num	= htons(request_num);

	if(result) {
		/* NG */
		flush_ack.result = htons(result);
		kLogWrite(L_DEBUG, "%s: result NG", __FUNCTION__);
	} else {
		/* OK */
		flush_ack.result	= htons(result);
		kLogWrite(L_DEBUG, "%s: result OK", __FUNCTION__);
	}

	/* send back */
	if((write(handle, &flush_ack, sizeof(FLUSH_ACK))) < 0) {
		kLogWrite(L_WARNING,
			"%s: write() error. errno is %d.", __FUNCTION__, errno);
		return(false);
	}

	return(true);
}

#ifdef SUPPORT_TLS
/*--------------------------------------------------------------------*
 * static bool tls_setup_ack_return(int, short, short, short);        *
 *--------------------------------------------------------------------*/
/* tls_setup_ack_return */
static bool
tls_setup_ack_return(int handle, short command, short request_num, short result)
{
	TLS_SETUP_ACK   tls_setup_ack;

	memset(&tls_setup_ack, 0, sizeof(tls_setup_ack));

	kLogWrite(L_CMD, "%s: command is TLS_SETUP_ACK", __FUNCTION__);

	/* data generatin */
	tls_setup_ack.command		= htons(command);
	tls_setup_ack.request_num	= htons(request_num);

	if(result) {
		/* NG */
		tls_setup_ack.result = htons(result);
		kLogWrite(L_WARNING, "%s: result NG", __FUNCTION__);
	} else {
		/* OK */
		tls_setup_ack.result	= htons(result);
		kLogWrite(L_DEBUG, "%s: result OK", __FUNCTION__);
	}

	/* send back */
	if((write(handle, &tls_setup_ack, sizeof(tls_setup_ack))) < 0) {
		kLogWrite(L_WARNING,
			"%s: write() error. errno is %d.", __FUNCTION__, errno);
		return(false);
	}

	return(true);
}



/*--------------------------------------------------------------------*
 * static bool tls_clear_ack_return(int, short, short, short);        *
 *--------------------------------------------------------------------*/
/* tls_clear_ack_return */
static bool
tls_clear_ack_return(int handle, short command, short request_num, short result)
{
	TLS_CLEAR_ACK   tls_clear_ack;

	memset(&tls_clear_ack, 0, sizeof(tls_clear_ack));

	kLogWrite(L_CMD, "%s: command is TLS_CLEAR_ACK", __FUNCTION__);

	/* data generatin */
	tls_clear_ack.command		= htons(command);
	tls_clear_ack.request_num	= htons(request_num);

	if(result) {
		/* NG */
		tls_clear_ack.result	= htons(result);
		kLogWrite(L_WARNING, "%s: result NG", __FUNCTION__);
	} else {
		/* OK */
		tls_clear_ack.result	= htons(result);
		kLogWrite(L_DEBUG, "%s: result OK", __FUNCTION__);
	}

	/* send back */
	if((write(handle, &tls_clear_ack, sizeof(TLS_CLEAR_ACK))) < 0) {
		kLogWrite(L_WARNING,
			"%s: write() error. errno is %d.", __FUNCTION__, errno);
		return(false);
	}

	return(true);
}
#endif	/* SUPPORT_TLS */

/* process_si_type_unixd */
static int
process_si_type_unixd(int handle)
{
	socklen_t	socklen;
	int		data_socket_handle;
	struct sockaddr_un 	serveradd;

	int sndbuf = 0xffff;
	int rcvbuf = 0xffff;

	/*
	 * 1  accept connection
	 * 2  into the select list
	 * 3  get parent SocketInfo
	 * 4  new() the child/socket SocketInfo
	 * 5  copy the data
	 */

	/* accept */
	socklen = sizeof(struct sockaddr_un);
	data_socket_handle = accept(handle,
				    (struct sockaddr*)&serveradd,
				    &socklen);

	kLogWrite(L_SOCKET," Unix domain sock accept[%d] parent[%d]",data_socket_handle,handle);

	if(setsockopt(data_socket_handle,
		      SOL_SOCKET,SO_SNDBUF, &sndbuf, sizeof(sndbuf))) {
	  kLogWrite(L_WARNING,
		    "%s: setsockopt(SO_SNDBUF) fails", __FUNCTION__);
	}

	if(setsockopt(data_socket_handle,
		      SOL_SOCKET,SO_RCVBUF, &rcvbuf, sizeof(rcvbuf))) {
  
	  kLogWrite(L_WARNING,
		    "%s: setsockopt(SO_RCVBUF) fails", __FUNCTION__);
	}

	/* regist child socoket */
	kSocketRegistUnixdSocketInfo(SI_TYPE_UNIX_DATA,
				     data_socket_handle,
				     (unsigned char *)serveradd.sun_path);

	/* select() */
	kSocketSelectOperation(data_socket_handle, SELECT_IN);

	return(RETURN_OK);
}

static int
read_unixd_data(int handle,char *buff,int bufsize)
{
  int datalen,pktlen,len;
  short command;

  datalen = read(handle, buff, sizeof(command));
  if(datalen < sizeof(command)) goto ERR;

  command = ntohs(*((short*)buff));

  switch( command ){
  case CM_CM_SIG_CONNEC_REQ:
    datalen += read(handle, buff+datalen, sizeof(CONNEC_REQ)-datalen-MSG_MAXDATALEN);
    if(datalen < sizeof(CONNEC_REQ)-MSG_MAXDATALEN) goto ERR;
    pktlen = ntohl( ((CONNEC_REQ*)buff)->datalen );
    while(datalen<sizeof(CONNEC_REQ)-MSG_MAXDATALEN+pktlen){
      len = read(handle, buff+datalen, sizeof(CONNEC_REQ)-datalen);
      /* printf("read_unixd_data [%d][%d]\n",len,datalen); */
      if(len <= 0) goto ERR;
      datalen += len;
    }
    break;
  case CM_CM_SIG_SEND_REQ:
    datalen += read(handle, buff+datalen, sizeof(SEND_REQ)-datalen-MSG_MAXDATALEN);
    if(datalen < sizeof(SEND_REQ)-MSG_MAXDATALEN) goto ERR;
    pktlen = ntohl( ((SEND_REQ*)buff)->datalen );
    while(datalen<sizeof(SEND_REQ)-MSG_MAXDATALEN+pktlen){
      len = read(handle, buff+datalen, sizeof(SEND_REQ)-datalen);
      /* printf("read_unixd_data [%d][%d]\n",len,datalen); */
      if(len <= 0) goto ERR;
      datalen += len;
    }
    break;
  default:
    datalen += read(handle, buff+datalen, bufsize-datalen);
    break;
  }
  /* printf("read_unixd_data OK len[%d]\n",datalen); */
  return datalen;

 ERR:
  /* printf("read_unixd_data too short len[%d]\n",datalen); */
  return datalen;
}

static int
process_si_type_unixd_data(int handle)
{
	SocketInfo	socketinfo;
	UnixdInfo	unixdinfo;
	char		databuf[CM_MAX_CM_LENGTH];
	long		datalen;
	short		command;
	short		request_num;
	char		*current_position;
	static   char   *Service[]={"ConnectSend","Send","Recv","Close","StartRecv","ConnectInfo","DataInfo","Clear",
				    "TLS-Setup","TLS-Clear","----"};

	/* read() */
	/* datalen = read(handle, databuf, CM_MAX_CM_LENGTH); */
	datalen = read_unixd_data(handle, databuf, CM_MAX_CM_LENGTH);
	if(datalen < 0) {
		kLogWrite(L_WARNING,
			"%s: read fail for handle[%d]. errno is [%d]",
			__FUNCTION__, handle, errno);
		return(RETURN_NG);
	}

	if(!datalen) {
		/* get parent si */
		if((kSocketGetSIBySocketHandle(handle, &socketinfo,
						&unixdinfo, NULL, NULL)) < 0) {
			kLogWrite(L_INFO,
				 "%s: kSocketGetSIBySocketHandle error. abort",
				 __FUNCTION__);

			return(RETURN_NG);
		}

		kSocketClose(socketinfo.si_socketid);
		kLogWrite(L_SOCKET,
			"%s: read_size0 for socketid[%d] handle[%d], so closed",
			__FUNCTION__, socketinfo.si_socketid, handle);

		/*
		 * and all sockets clear
		 */
		kSocketClose(0);
		kLogWrite(L_DEBUG,
			 "%s: kSocketClose(0) for closing all sockets", __FUNCTION__);

		kCloseTimerInit();
		kBufferInit();
		kRecvTimerInit();

		return(RETURN_OK);
	}

	/* parse command */
	current_position	= (char*)databuf;
	command			= ntohs(*((short*)current_position));
	request_num		= ntohs(*((short*)current_position+1));

	kLogWrite(L_CMD," service command <=[%s] leng(%ld)", Service[(command & 0xf)-1],datalen);

	switch (command) {
	case CM_CM_SIG_CONNEC_REQ:
		if(process_command_connect_req(handle, request_num,
						databuf, datalen) < 0) {
		        goto ERR;
		}

		break;

	case CM_CM_SIG_SEND_REQ:
		if(process_command_send_req(handle, request_num,
					     databuf, datalen) < 0) {
		        goto ERR;
		}

		break;

	case CM_CM_SIG_RECV_REQ:
		if(process_command_recv_req(handle, request_num,
					     databuf, datalen) < 0) {
		        goto ERR;
		}

		break;

	case CM_CM_SIG_CLOSE_REQ:
		if(process_command_close_req(handle, request_num,
					      databuf, datalen) < 0) {
		        goto ERR;
		}

		break;

	case CM_CM_SIG_WAIT_REQ:
		if(process_command_wait_req(handle, request_num,
					     databuf, datalen) < 0) {
		        goto ERR;
		}

		break;

	case CM_CM_SIG_SOCKINFO_REQ:
		if(process_command_sockinfo_req(handle, request_num,
						 databuf, datalen) < 0) {
		        goto ERR;
		}

		break;

	case CM_CM_SIG_DATAINFO_REQ:
		if(process_command_datainfo_req(handle, request_num,
						 databuf, datalen) < 0) {
		        goto ERR;
		}

		break;

	case CM_CM_SIG_FLUSH_REQ:
		if(process_command_flush_req(handle, request_num,
					      databuf, datalen)) {
		        goto ERR;
		}

		break;

#ifdef SUPPORT_TLS
	case CM_CM_SIG_TLS_SETUP_REQ:
		if(process_command_tls_setup_req(handle,
			request_num, databuf, datalen)) {
		        goto ERR;
		}

		break;

	case CM_CM_SIG_TLS_CLEAR_REQ:
		if(process_command_tls_clear_req(handle,
			request_num, databuf, datalen)) {
		        goto ERR;
		}

		break;
#endif	/* SUPPORT_TLS */

	case CM_CM_SIG_PARSER_ATTACH_REQ:
		if(process_command_parser_attach_req(handle, request_num,
					      databuf, datalen)) {
		        goto ERR;
		}

		break;

	default:
		kLogWrite(L_ERROR, "%s: invalid service command <=[%x]", __FUNCTION__, command);
		return(RETURN_NG);
	}
	kLogWrite(L_CMD," service command =>[%s] OK", Service[(command & 0xf)-1]);
	return(RETURN_OK);

	ERR:
	kLogWrite(L_CMD," service command =>[%s] NG", Service[(command & 0xf)-1]);
	return(RETURN_NG);
}



/* process_command_connect_req */
static int
process_command_connect_req(
	int handle,
	short request_num,
	char *databuf,
	long datalen
	)
{
	int				ret = 0;
	long			dataid=0;
	struct timeval	timestamp;
	CONNEC_REQ		connec_req;

	unsigned char	newconnec_type = 0;
	unsigned char	linkname[BUFSIZE];
	unsigned char	linkname_temp_char[2];
	short			socketid = 0;
	short			checksocketid = 0;	/* for kSocketCheckNewSocket() */

	memset(&timestamp, 0, sizeof(timestamp));
	memset(&connec_req, 0, sizeof(CONNEC_REQ));
	memset(linkname, 0, sizeof(linkname));
	memset(linkname_temp_char, 0, sizeof(linkname_temp_char));

	kLogWrite(L_DEBUG, "%s: command is CONNECT_REQ", __FUNCTION__);

	/*
	 * data copy and valance from network byte order
	 * to hostbyteorder
	 */
	memcpy(&connec_req, databuf, datalen);
	connec_req.s_port	= ntohs(connec_req.s_port);
	connec_req.d_port	= ntohs(connec_req.d_port);
	connec_req.interfaceid	= ntohs(connec_req.interfaceid);
	connec_req.flags	= ntohs(connec_req.flags);
	connec_req.frameid	= ntohs(connec_req.frameid);
	connec_req.datalen	= ntohl(connec_req.datalen);

	if(connec_req.ipver == CM_IP_IPV6) {
		kLogWrite(L_DEBUG,
			"%s: ipver: 0x%x", __FUNCTION__, connec_req.ipver);
	} else if(connec_req.ipver == CM_IP_IPV4) {
		kLogWrite(L_DEBUG, "%s: ipver: 0x%x", __FUNCTION__, connec_req.ipver);
	}

	/* data preparation */
	if(connec_req.protocol == CM_PROT_TCP) {
		newconnec_type = SI_TYPE_DATA;
		kLogWrite(L_DEBUG,
			"%s: new connection's type will be data", __FUNCTION__);
	} else if(connec_req.protocol == CM_PROT_UDP) {
		newconnec_type = SI_TYPE_UDP;
		kLogWrite(L_DEBUG,
			"%s: new connection's type will be udp", __FUNCTION__);
	} else if(connec_req.protocol == CM_PROT_ICMP) {
		newconnec_type = SI_TYPE_RAW;
		kLogWrite(L_DEBUG,
			"%s: new connection's type will be raw", __FUNCTION__);
#ifdef SUPPORT_TLS
	} else if(connec_req.protocol == CM_PROT_TLS) {
		if(!kIsTLSInitialize()) {
			kLogWrite(L_WARNING, "%s: TLS not Initialize yet", __FUNCTION__);
			connec_send_ack_return(handle, CM_CM_SIG_CONNEC_ACK, request_num,
				CM_RESULT_SIG_TLS_NOINIT, 0, 0, timestamp);
			return(RETURN_NG);
		}

		newconnec_type = SI_TYPE_DATA;
		kLogWrite(L_DEBUG,
			"%s: new connection's type will be tls", __FUNCTION__);
#endif	/* SUPPORT_TLS */
	}

	snprintf((char *)linkname_temp_char, sizeof(linkname_temp_char),
		"%d", connec_req.interfaceid);
	strcat((char *)linkname, IF_KEYWORD);
	strcat((char *)linkname, (const char *)linkname_temp_char);

	/* check whether create new socket or re-use socket */
	if((kSocketCheckNewSocket(connec_req.s_port, connec_req.s_addr,
		connec_req.d_port, connec_req.d_addr, connec_req.protocol,
		&checksocketid)) < 0) {

		kLogWrite(L_WARNING,
			"%s: kSocketCheckNewSocket() error. abort", __FUNCTION__);

		connec_send_ack_return(handle, CM_CM_SIG_CONNEC_ACK,
			request_num, CM_RESULT_SIG_NG_OTHER, 0, 0, timestamp);
		return(RETURN_NG);
	}

	kLogWrite(L_DEBUG, "%s: kSocketCheckNewSocket() done", __FUNCTION__);

	/*
	 * kSocketCheckNewSocket() return socketid 0, kSocketOpen()
	 * return not 0, use thus socketid for kSocketSend()
	 */
	if(!checksocketid) {
		kLogWrite(L_DEBUG,
			"%s: checksocketid is 0, so open new socket", __FUNCTION__);

		/* opensocket */
		switch(newconnec_type) {
			case SI_TYPE_UDP:
			case SI_TYPE_DATA:
				if((ret = kSocketOpen(newconnec_type,
#ifdef SUPPORT_TLS
					connec_req.protocol == CM_PROT_TLS,
#else	/* SUPPORT_TLS */
					false,
#endif	/* SUPPORT_TLS */
					connec_req.ipver,
					connec_req.d_port, connec_req.d_addr, connec_req.s_port,
					connec_req.s_addr, linkname, connec_req.frameid,
					connec_req.flags, &socketid)) < 0) {

					kLogWrite(L_INFO,
						"%s: kSocketOpen() fail. abort", __FUNCTION__);

					connec_send_ack_return(handle, CM_CM_SIG_CONNEC_ACK,
						request_num, CM_RESULT_SIG_NG_OTHER, 0, 0, timestamp);
					return(RETURN_NG);
				}
				break;

			case SI_TYPE_RAW:
				if((ret = kSocketOpenRaw(connec_req.ipver,
					connec_req.d_addr,
					connec_req.s_addr, connec_req.protocol, connec_req.frameid,
					linkname, &socketid)) < 0) {

					kLogWrite(L_INFO,
						"%s: kSocketOpenRaw() fail. abort", __FUNCTION__);

					connec_send_ack_return(handle, CM_CM_SIG_CONNEC_ACK,
						request_num, CM_RESULT_SIG_NG_OTHER, 0, 0, timestamp);
					return(RETURN_NG);
			}
			break;

			default:
				break;
		}
	} else {
		kLogWrite(L_DEBUG,
			"%s: just re-use socketid[%d] for bind duplication",
			__FUNCTION__, checksocketid);
		socketid = checksocketid;
	}

	/* if data is there, kSocketSend() */
	if(connec_req.datalen) {
		if((ret = kSocketSend(socketid, connec_req.datalen, connec_req.data,
			&dataid, &timestamp))) {

			connec_send_ack_return(handle, CM_CM_SIG_CONNEC_ACK, request_num,
				CM_RESULT_SIG_NG_OTHER, socketid, dataid, timestamp);
			kLogWrite(L_INFO, "%s: kSocketSend() fail.", __FUNCTION__);
		}
	}

	/*
	 * command return section
	 */
	connec_send_ack_return(handle, CM_CM_SIG_CONNEC_ACK, request_num,
		CM_RESULT_OK, socketid, dataid, timestamp);

	return(RETURN_OK);
}



/*--------------------------------------------------------------------*
 * static int process_command_send_req(int, short, char *, long);     *
 *--------------------------------------------------------------------*/
/* process_command_send_req */
static int
process_command_send_req(int handle,
	short request_num, char *databuf, long datalen)
{
	int	ret = 0;
	long	dataid = 0;
	struct timeval	timestamp;
	SEND_REQ	send_req;

	kLogWrite(L_DEBUG, "%s: command is SEND_REQ", __FUNCTION__);

	memset(&timestamp, 0, sizeof(timestamp));
	memset(&send_req, 0, sizeof(send_req));

	/*
	 * data copy and valance from network byte order
	 * to hostbyteorder
	 */
	memcpy(&send_req, databuf, datalen);
	send_req.socketid	= ntohs(send_req.socketid);
	send_req.datalen	= ntohl(send_req.datalen);

	/* send */
	if((ret = kSocketSend(send_req.socketid,
		send_req.datalen, send_req.data, &dataid, &timestamp))) {

		connec_send_ack_return(handle, CM_CM_SIG_SEND_ACK, request_num,
			CM_RESULT_SIG_NG_OTHER, send_req.socketid, dataid, timestamp);
		kLogWrite(L_INFO, "%s: kSocketSend() fail.", __FUNCTION__);

		/* XXX: which value returns RETURN_OK or RETURN_NG?
		 *      original code finally returns RETURN_OK.
		 */
		return(RETURN_OK);
	}

	/*
	 * command return section
	 */
	connec_send_ack_return(handle, CM_CM_SIG_SEND_ACK, request_num,
		CM_RESULT_OK, send_req.socketid, dataid, timestamp);

	return(RETURN_OK);
}



/*--------------------------------------------------------------------*
 * static int process_command_recv_req(int, short, char *, long);     *
 *--------------------------------------------------------------------*/
/* process_command_recv_req */
static int
process_command_recv_req(int handle,
	short request_num, char *databuf, long datalen)
{
	int		ret = 0;
	RECV_REQ	recv_req;

	MsgData		recvmsg;
	unsigned char	recvmsgdata[MSG_MAXDATALEN];

	memset(&recv_req, 0, sizeof(recv_req));
	memset(&recvmsg, 0, sizeof(recvmsg));
	memset(recvmsgdata, 0, sizeof(recvmsgdata));

	kLogWrite(L_DEBUG, "%s: command is RECV_REQ", __FUNCTION__);

	/*
	 * data copy and valance from network byte order
	 * to hostbyteorder
	 */
	memcpy(&recv_req, databuf, datalen);
	recv_req.socketid	= ntohs(recv_req.socketid);
	recv_req.timeout_timer	= ntohs(recv_req.timeout_timer);

	kLogWrite(L_INFO, "%s: socketid(%d) timeout(%d)",
		__FUNCTION__, recv_req.socketid, recv_req.timeout_timer);

	/* recv */
	if((ret = kDataGetDataBySocketid(recv_req.socketid,
		&recvmsg, recvmsgdata)) < 0) {

		/* error */
		kLogWrite(L_INFO,
			"%s: kDataGetDataBySocketid() fail. abort", __FUNCTION__);

		recv_ack_return(handle, CM_CM_SIG_RECV_ACK, request_num,
			CM_RESULT_SIG_NG_OTHER, recv_req.socketid, (MsgData*)NULL);

		return(RETURN_NG);

	} else if(ret > 0) {
		/* there was no data, regist timer */
		kRecvTimerSet(handle,
			recv_req.socketid, recv_req.timeout_timer, request_num);

		/* end */
		kLogWrite(L_DEBUG, "%s: no data. regist recv timer. end", __FUNCTION__);
		/* XXX: which value returns RETURN_OK or RETURN_NG?
		 *      original code finally returns RETURN_OK.
		 */
		return(RETURN_OK);

	}

	/* data found (ret == 0) */
	recv_ack_return(handle, CM_CM_SIG_RECV_ACK, request_num, CM_RESULT_OK,
		recvmsg.msg_socketid, (MsgData*)&recvmsg);

	return(RETURN_OK);
}



/*--------------------------------------------------------------------*
 * static int                                                         *
 * process_command_close_req(int, short, char *, long);               *
 *--------------------------------------------------------------------*/
/* process_command_close_req */
static int
process_command_close_req(int handle,
	short request_num, char *databuf, long datalen)
{
	int		ret = 0;
	CLOSE_REQ	close_req;

	memset(&close_req, 0, sizeof(close_req));

	kLogWrite(L_DEBUG, "%s: command is CLOSE_REQ", __FUNCTION__);

	/*
	 * data copy and valance from network byte order
	 * to hostbyteorder
	 */
	memcpy(&close_req, databuf, datalen);
	close_req.socketid	= ntohs(close_req.socketid);
	close_req.waittime	= ntohs(close_req.waittime);

	if((close_req.socketid < 0) || (close_req.waittime < 0)) {
		if(close_req.socketid < 0) {
			kLogWrite(L_WARNING, "%s: invalid socketid[%d].abort",
				__FUNCTION__, close_req.socketid);
		} else if(close_req.waittime <0){
			kLogWrite(L_WARNING, "%s: invalid waittime[%d].abort",
				__FUNCTION__, close_req.waittime);
		}

		close_wait_ack_return(handle,
			CM_CM_SIG_CLOSE_ACK, request_num, CM_RESULT_SIG_NG_OTHER, 0);

		return(RETURN_NG);
	}

	/* set close time */
	if((ret = kCloseTimerSet(close_req.socketid, close_req.waittime))) {
		kLogWrite(L_INFO, "%s: kCloseTimerSet fail.abort", __FUNCTION__);
		close_wait_ack_return(handle, CM_CM_SIG_CLOSE_ACK, request_num,
			CM_RESULT_SIG_NG_OTHER, 0);

		return(RETURN_NG);
	}

	kLogWrite(L_INFO, "%s: kCloseTimerSet success", __FUNCTION__);
	close_wait_ack_return(handle,
		CM_CM_SIG_CLOSE_ACK, request_num, CM_RESULT_OK, close_req.socketid);

	return(RETURN_OK);
}



/*--------------------------------------------------------------------*
 * static int process_command_wait_req(int, short, char *, long);     *
 *--------------------------------------------------------------------*/
/* process_command_wait_req */
static int
process_command_wait_req(int handle,
	short request_num, char *databuf, long datalen)
{
	int		ret	= 0;
	WAIT_REQ	wait_req;

	short		socketid	= 0;
	unsigned char	newconnec_type = 0;
	unsigned char	linkname[BUFSIZE];
	unsigned char	linkname_temp_char[2];

	memset(&wait_req, 0, sizeof(wait_req));
	memset(linkname, 0, sizeof(linkname));
	memset(linkname_temp_char, 0, sizeof(linkname_temp_char));

	kLogWrite(L_DEBUG, "%s: command is WAIT_REQ", __FUNCTION__);

	/*
	 * data copy and valance from network byte order
	 * to hostbyteorder
	 */
	memcpy(&wait_req, databuf, datalen);
	wait_req.interfaceid	= ntohs(wait_req.interfaceid);
	wait_req.frameid		= ntohs(wait_req.frameid);
	wait_req.s_port			= ntohs(wait_req.s_port);
	wait_req.flags			= ntohs(wait_req.flags);

	snprintf((char *)linkname_temp_char,
		sizeof(linkname_temp_char), "%d", wait_req.interfaceid);
	strcat((char *)linkname, IF_KEYWORD);
	strcat((char *)linkname, (const char *)linkname_temp_char);

	/* data preparation */
	if(wait_req.protocol == CM_PROT_TCP) {
		newconnec_type = SI_TYPE_LISTEN_TCP;
		kLogWrite(L_DEBUG,
			"%s: new connection's type will be tcp parent", __FUNCTION__);
	} else if(wait_req.protocol == CM_PROT_UDP) {
		newconnec_type = SI_TYPE_LISTEN_UDP;
		kLogWrite(L_DEBUG,
			"%s: new connection's type will be udp parent", __FUNCTION__);
	} else if(wait_req.protocol == CM_PROT_ICMP) {
		newconnec_type = SI_TYPE_RAW;
		kLogWrite(L_DEBUG,
			"%s: new connection's type will be raw", __FUNCTION__);
#ifdef SUPPORT_TLS
	} else if(wait_req.protocol == CM_PROT_TLS) {
		if(!kIsTLSInitialize()){
			kLogWrite(L_WARNING, "%s: TLS not Initialize yet", __FUNCTION__);
			close_wait_ack_return(handle, CM_CM_SIG_WAIT_ACK, request_num,
				CM_RESULT_SIG_TLS_NOINIT, 0);
			return(RETURN_NG);
		}

		newconnec_type = SI_TYPE_LISTEN_TCP;
		kLogWrite(L_DEBUG,
			"%s: new connection's type will be tls", __FUNCTION__);
#endif	/* SUPPORT_TLS */
	}

	/* open_wait_socket */
	if(newconnec_type == SI_TYPE_RAW) {
		ret = kSocketOpenRaw(wait_req.ipver, in6addr_any, wait_req.s_addr,
			wait_req.protocol, wait_req.frameid, linkname, &socketid);
	} else {
		ret = kSocketOpenWaitSocket(newconnec_type,
#ifdef SUPPORT_TLS
			wait_req.protocol == CM_PROT_TLS,
#else	/* SUPPORT_TLS */
			false,
#endif	/* SUPPORT_TLS */
			wait_req.ipver,
			wait_req.s_port, wait_req.s_addr, linkname, wait_req.frameid,
			wait_req.flags, &socketid);
	}

	if(ret) {
		kLogWrite(L_WARNING, "%s: open_wait_socket fail.abort", __FUNCTION__);

		close_wait_ack_return(handle, CM_CM_SIG_WAIT_ACK,
			request_num, CM_RESULT_SIG_NG_OTHER, 0);

		return(RETURN_NG);

	}

	close_wait_ack_return(handle,
		CM_CM_SIG_WAIT_ACK, request_num, CM_RESULT_OK, socketid);

	return(RETURN_OK);
}



/*--------------------------------------------------------------------*
 * static int                                                         *
 * process_command_sockinfo_req(int, short, char *, long)             *
 *--------------------------------------------------------------------*/
/* process_command_sockinfo_req */
static int
process_command_sockinfo_req(int handle,
	short request_num, char *databuf, long datalen)
{
	int		ret	= 0;
	SOCKINFO_REQ	sockinfo_req;

	SocketInfo	socketinfo;
	DatasocketInfo	datasocketinfo;
	ListenportInfo	listenportinfo;

	memset(&sockinfo_req, 0, sizeof(sockinfo_req));
	memset(&socketinfo, 0, sizeof(socketinfo));
	memset(&datasocketinfo, 0, sizeof(datasocketinfo));
	memset(&listenportinfo, 0, sizeof(listenportinfo));

	kLogWrite(L_DEBUG, "%s: command is SOCKINFO_REQ", __FUNCTION__);

	/*
	 * data copy and valance from network byte order
	 * to hostbyteorder
	 */
	memcpy(&sockinfo_req, databuf, datalen);
	sockinfo_req.socketid	= ntohs(sockinfo_req.socketid);

	/* get si by socketid */
	if((ret = kSocketGetSIBySocketId(sockinfo_req.socketid,
		&socketinfo, NULL, &datasocketinfo, &listenportinfo))) {

		kLogWrite(L_DEBUG,
			"%s: kSocketGetSIBySocketId() fail.abort", __FUNCTION__);

		sockinfo_ack_return(handle, CM_CM_SIG_SOCKINFO_ACK, request_num,
			CM_RESULT_SIG_NG_OTHER, (SocketInfo *)NULL, (DatasocketInfo *)NULL,
			(ListenportInfo *)NULL);

		SocketInfoDump();
		return(RETURN_NG);
	}

	sockinfo_ack_return(handle, CM_CM_SIG_SOCKINFO_ACK, request_num,
		CM_RESULT_OK, (SocketInfo *)&socketinfo,
		(DatasocketInfo *)&datasocketinfo, (ListenportInfo *)&listenportinfo);

	SocketInfoDump();
	return(RETURN_OK);
}



/*--------------------------------------------------------------------*
 * static int process_command_datainfo_req(int, short, char *, long); *
 *--------------------------------------------------------------------*/
/* process_command_datainfo_req */
static int
process_command_datainfo_req(int handle,
	short request_num, char *databuf, long datalen)
{
	DATAINFO_REQ	datainfo_req;
	int		ret = 0;
	MsgData		recvmsg;
	unsigned char	recvmsgdata[MSG_MAXDATALEN];

	memset(&datainfo_req, 0, sizeof(datainfo_req));
	memset(&recvmsg, 0, sizeof(recvmsg));
	memset(recvmsgdata, 0, sizeof(recvmsgdata));

	kLogWrite(L_DEBUG, "%s: command is DATAINFO_REQ", __FUNCTION__);

	/*
	 * data copy and valance from network byte order
	 * to hostbyteorder
	 */
	memcpy(&datainfo_req, databuf, datalen);
	datainfo_req.dataid = ntohl(datainfo_req.dataid);

	/* kDataGetDataByDataid */
	if((ret = kDataGetDataByDataid(datainfo_req.dataid,
		&recvmsg, recvmsgdata))) {

		kLogWrite(L_WARNING,
			"%s: kDataGetDataByDataid() fail. abort", __FUNCTION__);

		datainfo_ack_return(handle, CM_CM_SIG_DATAINFO_ACK, request_num,
			CM_RESULT_SIG_NG_OTHER, NULL);

		return(RETURN_NG);
	}

	datainfo_ack_return(handle, CM_CM_SIG_DATAINFO_ACK, request_num,
		CM_RESULT_OK, &recvmsg);

	return(RETURN_OK);
}



#ifdef SUPPORT_TLS
/*--------------------------------------------------------------------*
 * static bool                                                        *
 * process_command_tls_setup_req(int, short, char *, long);           *
 *--------------------------------------------------------------------*/
/* process_command_tls_setup_req */
static bool
process_command_tls_setup_req(int handle,
	short request_num, char *databuf, long datalen)
{
	bool		ret = 0;
	TLS_SETUP_REQ	tls_setup_req;

	memset(&tls_setup_req, 0, sizeof(tls_setup_req));

	kLogWrite(L_DEBUG, "%s: command is TLS_SETUP_REQ", __FUNCTION__);

	/*
	 * data copy and valance from network byte order
	 * to hostbyteorder
	 */
	memcpy(&tls_setup_req, databuf, datalen);

	tls_setup_req.sessionmode	= ntohs(tls_setup_req.sessionmode);
	tls_setup_req.initialmode	= ntohs(tls_setup_req.initialmode);
	tls_setup_req.ssltimeout	= ntohs(tls_setup_req.ssltimeout);
	tls_setup_req.sslversion	= ntohs(tls_setup_req.sslversion);
	tls_setup_req.nagle		= ntohs(tls_setup_req.nagle);
	tls_setup_req.clientveri	= ntohs(tls_setup_req.clientveri);
	tls_setup_req.tmprsa		= ntohs(tls_setup_req.tmprsa);

	/* TLS initialize */
	ret = kTLSInitialize(tls_setup_req.sessionmode,tls_setup_req.initialmode,tls_setup_req.ssltimeout,
			     (char*)tls_setup_req.passwd,(char*)tls_setup_req.rootpem,
			     (char*)tls_setup_req.mypem,(char*)tls_setup_req.dhpem,tls_setup_req.sslversion,
			     tls_setup_req.nagle,tls_setup_req.clientveri,tls_setup_req.tmprsa,
			     tls_setup_req.encsuit?(char*)tls_setup_req.encsuit:"");

	if(ret) {

		kLogWrite(L_CMD, "%s: TLS initilize fail. abort", __FUNCTION__);

		tls_setup_ack_return(handle,
			CM_CM_SIG_TLS_SETUP_ACK, request_num, CM_RESULT_SIG_NG_OTHER);

		return(false);
	}

	kLogWrite(L_CMD, "%s: TLS initilize success", __FUNCTION__);

	tls_setup_ack_return(handle,
		CM_CM_SIG_TLS_SETUP_ACK, request_num, CM_RESULT_OK);

	return(true);
}



/*--------------------------------------------------------------------*
 * static bool                                                        *
 * process_command_tls_clear_req(int, short, char *, long);           *
 *--------------------------------------------------------------------*/
/* process_command_tls_clear_req */
static bool
process_command_tls_clear_req(int handle,
	short request_num, char *databuf, long datalen)
{
	bool	ret = 0;
	TLS_CLEAR_REQ	tls_clear_req;

	memset(&tls_clear_req, 0, sizeof(tls_clear_req));

	kLogWrite(L_DEBUG, "%s: command is TLS_CLEAR_REQ", __FUNCTION__);

	/*
	 * data copy and valance from network byte order
	 * to hostbyteorder
	 */
	memcpy(&tls_clear_req, databuf, datalen);

	tls_clear_req.socketid= ntohs(tls_clear_req.socketid);

	/* TLS initialize */
	if(!(ret = kTLSClear(tls_clear_req.socketid))) {
		kLogWrite(L_CMD, "%s: TLS initilize fail. abort", __FUNCTION__);

		tls_clear_ack_return(handle,
			CM_CM_SIG_TLS_CLEAR_ACK, request_num, CM_RESULT_SIG_NG_OTHER);

		return(false);
	}

	kLogWrite(L_CMD, "%s: TLS initilize success", __FUNCTION__);

	tls_clear_ack_return(handle,
		CM_CM_SIG_TLS_CLEAR_ACK, request_num, CM_RESULT_OK);

	return(true);
}
#endif	/* SUPPORT_TLS */



/*--------------------------------------------------------------------*
 * static bool process_command_flush_req(int, short, char *, long);   *
 *--------------------------------------------------------------------*/
/* process_command_flush_req */
static bool
process_command_flush_req(int handle,
	short request_num, char *databuf, long datalen)
{
	bool		ret = 0;
	FLUSH_REQ	flush_req;

	memset(&flush_req, 0, sizeof(flush_req));

	kLogWrite(L_DEBUG, "%s: command is FLUSH_REQ", __FUNCTION__);

 	/*
	 * data copy and valance from network byte order
	 * to hostbyteorder
	 */
	memcpy(&flush_req, databuf, datalen);

	flush_req.socketid_flag	= ntohs(flush_req.socketid_flag);
	flush_req.dataid_flag	= ntohs(flush_req.dataid_flag);
	flush_req.socketid	= ntohs(flush_req.socketid);
	flush_req.dataid	= ntohs(flush_req.dataid);

	/* flush data */
	if(!(ret = kDataClear(flush_req.socketid_flag,
		flush_req.dataid_flag, flush_req.socketid, flush_req.dataid))) {

		kLogWrite(L_CMD, "%s: clear data fail. abort", __FUNCTION__);

		flush_ack_return(handle,
			CM_CM_SIG_FLUSH_ACK, request_num, CM_RESULT_SIG_NG_OTHER);

		return(false);
	}

	kLogWrite(L_CMD, "%s: clear data success", __FUNCTION__);

	flush_ack_return(handle, CM_CM_SIG_FLUSH_ACK, request_num, CM_RESULT_OK);
	return(true);
}

/*--------------------------------------------------------------------*
 * static bool process_command_parser_attach_req(int, short, char *, long);   *
 *--------------------------------------------------------------------*/
/* process_command_parser_attach_req */
static bool
process_command_parser_attach_req(int handle,
	short request_num, char *databuf, long datalen)
{
	bool		ret = 0;
	PARSER_ATTACH_REQ	attach_req;
	extern bool kParserSet2(int,char*,char*);
	extern bool kParserDelete(int);

	memset(&attach_req, 0, sizeof(attach_req));

	kLogWrite(L_DEBUG, "%s: command is PARSER ARRATCH REQ", __FUNCTION__);

 	/*
	 * data copy and valance from network byte order
	 * to hostbyteorder
	 */
	memcpy(&attach_req, databuf, datalen);

	attach_req.parserid	= ntohs(attach_req.parserid);
	attach_req.mode	= ntohs(attach_req.mode);

	if(attach_req.mode == 0)
	  ret = !kParserSet2(attach_req.parserid,attach_req.parsernname,attach_req.modulepath);
	else
	  ret = !kParserDelete(attach_req.parserid);

	kLogWrite(L_CMD, "%s: parser %s %s", __FUNCTION__,
		  attach_req.mode?"detach":"attach",
		  ret?"error":"success");

	flush_ack_return(handle, CM_CM_SIG_PARSER_ATTACH_ACK, request_num, ret?CM_RESULT_SIG_NG_OTHER:CM_RESULT_OK);
	return(true);
}


/* process_si_type_udp */
static int
process_si_type_udp(int handle)
{
	char 		recvbuf[MSG_MAXDATALEN];
	long		recvbufsize;
	struct timeval	current_time;

	struct sockaddr *addr;
	struct sockaddr_in6	sin6;
	struct sockaddr_in6	local_sin6;
	struct sockaddr_in	sin;
	struct sockaddr_in	local_sin;
	socklen_t	socklen;
	socklen_t	localaddr_len;

	SocketInfo	socketInfo;
	SocketInfo	*si;
	DatasocketInfo	dataSocketInfo;
	DatasocketInfo	*dsi = NULL;

	char		addr_temp_string[INET6_ADDRSTRLEN];

	kLogWrite(L_DEBUG,
		"%s: UDP connec sockethandle[%d] coming...", __FUNCTION__, handle);

	/* get si */
	if((kSocketGetSIBySocketHandle(handle, &socketInfo, NULL,
					&dataSocketInfo, NULL)) < 0) {
		kLogWrite(L_WARNING,
			"%s: kSocketGetSIBySocketHandle() error. abort", __FUNCTION__);

		return(RETURN_NG);
	}

	if(dataSocketInfo.di_family == PF_INET6) {
		addr = (struct sockaddr *)&sin6;
		socklen = sizeof(sin6);
	} else if(dataSocketInfo.di_family == PF_INET) {
		addr = (struct sockaddr *)&sin;
		socklen = sizeof(sin);
	} else {
		kLogWrite(L_WARNING,
			"%s: invalid address family(%x)",
			__FUNCTION__, dataSocketInfo.di_family);
		return(RETURN_NG);
	}

	/* recvfrom */
	recvbufsize = recvfrom(handle, recvbuf, sizeof(recvbuf), 0,
			       addr, &socklen);
	if(recvbufsize < 0) {
		kLogWrite(L_WARNING, "%s: handle[%d] recvfrom() fail. errno is [%d]",
			__FUNCTION__, handle, errno);
		return(RETURN_NG);
	}

	kLogWrite(L_SOCKET,
		"%s: handle[%d] recvfrom() success -- %ld bytes",
			__FUNCTION__, handle, recvbufsize);

	/* get DatasocketInfo which matched with sockethandle*/
	for(si = g_socket_start_ptr; ; si = si->si_next_socket_info_ptr) {
		if(!si) {
			kLogWrite(L_WARNING,
				"%s: socket no match for handle[%d].abort",
				__FUNCTION__, handle);
			return(RETURN_NG);
		}

		if((si->si_sockethandle == socketInfo.si_sockethandle) &&
		    (si->si_socket_status == SI_STATUS_ALIVE)){
			kLogWrite(L_DEBUG, "%s: set port and address", __FUNCTION__);

			dsi = (DatasocketInfo*)si->si_uniq_info_ptr;
			break;
		}
	}

	if(dataSocketInfo.di_family == PF_INET6) {
		inet_ntop(AF_INET6, (void*)&(sin6.sin6_addr),
			  addr_temp_string, INET6_ADDRSTRLEN);
		kLogWrite(L_DEBUG, "%s: data from addr[%s] port[%d]",
			 __FUNCTION__, addr_temp_string, ntohs(sin6.sin6_port));

		/* get local address */
		localaddr_len = sizeof(local_sin6);
		if((getsockname(handle, (struct sockaddr*)&local_sin6,
				 &localaddr_len)) < 0) {
			kLogWrite(L_WARNING,
				"%s: getsockname for localaddr fail. abort", __FUNCTION__);
			return(RETURN_NG);
		}

		kLogWrite(L_DEBUG,
			 "%s: getsockname() done for localaddr", __FUNCTION__);

		inet_ntop(AF_INET6, (void*)&(local_sin6.sin6_addr),
			  addr_temp_string, INET6_ADDRSTRLEN);

		kLogWrite(L_DEBUG,
			 "%s: addr[%s] port[%d]", __FUNCTION__,
			 addr_temp_string, ntohs(local_sin6.sin6_port));

		/* set port and address */
		dsi->di_d_port = ntohs(sin6.sin6_port);
		dsi->di_s_port = ntohs(local_sin6.sin6_port);
		memcpy(&(dsi->di_d_addr),
		       &(sin6.sin6_addr),
		       sizeof(struct in6_addr));
		memcpy(&(dsi->di_s_addr),
		       &(local_sin6.sin6_addr),
		       sizeof(struct in6_addr));

	} else if(dataSocketInfo.di_family == PF_INET) {
		inet_ntop(AF_INET, (void*)&(sin.sin_addr),
			  addr_temp_string, INET_ADDRSTRLEN);
		kLogWrite(L_DEBUG, "%s: data from addr[%s] port[%d]", __FUNCTION__,
			 addr_temp_string, ntohs(sin.sin_port));

		/* get local address */
		localaddr_len = sizeof(local_sin);
		if((getsockname(handle, (struct sockaddr*)&local_sin,
				 &localaddr_len)) < 0) {
			kLogWrite(L_WARNING,
				"%s: getsockname for localaddr fail. abort", __FUNCTION__);
			return(RETURN_NG);
		}

		kLogWrite(L_DEBUG,
			"%s: getsockname() done for localaddr", __FUNCTION__);

		inet_ntop(AF_INET, (void*)&(local_sin.sin_addr),
			  addr_temp_string, INET_ADDRSTRLEN);

		kLogWrite(L_DEBUG,
			"%s: addr[%s] port[%d]", __FUNCTION__,
			addr_temp_string, ntohs(local_sin.sin_port));

		/* set port and address */
		kLogWrite(L_DEBUG, "%s: set port and address", __FUNCTION__);

		dsi->di_d_port = ntohs(sin.sin_port);
		dsi->di_s_port = ntohs(local_sin.sin_port);

		memcpy(&(dsi->di_d_addr), &(sin.sin_addr),
		       sizeof(struct in_addr));
		memcpy(&(dsi->di_s_addr), &(local_sin.sin_addr),
		       sizeof(struct in_addr));
	}

	/* gettime */
	gettimeofday(&current_time, NULL);

	/* registdata */
	if((kDataRegist(si->si_socketid, MSG_SOCKETMODE_RECV,
			recvbufsize, (unsigned char *)recvbuf, current_time)) < 0) {
		kLogWrite(L_INFO,
			"%s: regist_data fail for handle[%d] socketid[%d]",
			__FUNCTION__, handle, si->si_socketid);
	}

	return(RETURN_OK);
}

/* process_si_type_raw */
static int
process_si_type_raw(int handle)
{
	struct timeval current_time;

	SocketInfo socketinfo;
	DatasocketInfo datasocketinfo;

	char recvbuf[MSG_MAXDATALEN];
	int recvbufsize = sizeof(recvbuf);
	int len = 0;

	kLogWrite(L_DEBUG,
		"%s: UDP connec sockethandle[%d] coming...",
		__FUNCTION__, handle);

	/* get si */
	if((kSocketGetSIBySocketHandle(handle, &socketinfo, NULL,
				       &datasocketinfo, NULL)) < 0) {
		kLogWrite(L_INFO,
			"%s: kSocketGetSIBySocketHandle() error. abort", __FUNCTION__);

		return(RETURN_NG);
	}

	len = icmp_recv(socketinfo.si_sockethandle,
			socketinfo.si_linkname,
			(struct sockaddr *)&datasocketinfo.di_sss_addr,
			datasocketinfo.di_sss_addr.ss_len,
			(struct sockaddr *)&datasocketinfo.di_ssd_addr,
			datasocketinfo.di_ssd_addr.ss_len,
			recvbuf,
			recvbufsize);

	/* gettime */
	gettimeofday(&current_time, NULL);

	if((kDataRegist(socketinfo.si_socketid, MSG_SOCKETMODE_RECV,
			len, (unsigned char *)recvbuf, current_time)) < 0) {
		kLogWrite(L_INFO,
			"%s: regist_data fail for handle[%d] socketid[%d]",
			__FUNCTION__, handle, socketinfo.si_socketid);
	}

	return(RETURN_OK);
}



/* process_si_type_tcp */
static int
process_si_type_tcp(int handle)
{
	char            recvbuf[MSG_MAXDATALEN];
	long            recvbufsize            = 0;

	struct timeval  current_time;
	DatasocketInfo *datasocketinfo         = NULL;
	SocketInfo      vsocketinfo;
	DatasocketInfo  vdatasocketinfo;
	char            packet_gen_space[MSG_MAXDATALEN];
	long            packet_gen_space_len   = 0;
	unsigned char  *parse_current_position = NULL;
	short           parse_size             = 0;
	int             ret                    = 0;

	memset( recvbuf,          0, sizeof(recvbuf));
	memset(&current_time,     0, sizeof(current_time));
	memset(&vsocketinfo,      0, sizeof(vsocketinfo));
	memset( packet_gen_space, 0, sizeof(packet_gen_space));

	kLogWrite(L_DEBUG,
		"%s: TCP/DATA connec sockethandle[%d] coming...", __FUNCTION__, handle);

	/* get si */
	if((kSocketGetSIBySocketHandle(handle, &vsocketinfo, NULL,
					&vdatasocketinfo, NULL)) < 0) {
		kLogWrite(L_INFO,
			"%s: kSocketGetSIBySocketHandle() error. abort", __FUNCTION__);
		return(RETURN_NG);
	}

	/* recv */
#ifdef SUPPORT_TLS
	if(vsocketinfo.si_tls_mode){
	  /* TLS data receive */
	  recvbufsize=kTLSRecv(vsocketinfo.si_tls_ssl_ptr,recvbuf,sizeof(recvbuf));
	}
	else{
	  /* TCP data receive */
	  recvbufsize = recv(handle, recvbuf, sizeof(recvbuf), 0);
	}
#else
	/* TCP data receive */
	recvbufsize = recv(handle, recvbuf, sizeof(recvbuf), 0);
#endif

	if( recvbufsize < 0) {
		kLogWrite(L_WARNING, "%s: handle[%d] recv() fail. errno is [%d]",
			__FUNCTION__, handle, errno);
		return(RETURN_NG);
	}
	if(!recvbufsize) {
		kCloseTimerSet(vsocketinfo.si_socketid, 0);

		kLogWrite(L_INFO,
			"%s: read_size0 for socketid[%d] handle[%d], so closed",
			__FUNCTION__, vsocketinfo.si_socketid, handle);
		return(RETURN_OK);
	}
#if 0
#ifdef DBG_PARSER
	kdmp("/tmp/dbg_parser.txt", "recvbuf", recvbuf, recvbufsize);
#endif	/* DBG_PARSER */
#endif	/* 0 */
	kLogWrite(L_IO, "%s: %s size[%d] socketID[%d] recv OK",__FUNCTION__,
		  vsocketinfo.si_tls_mode?"TLS":"TCP" ,recvbufsize,vsocketinfo.si_socketid);

	/* timestamp */
	gettimeofday(&current_time, NULL);

	/*********** parsing data ****************/
	/*
	 * get left data and merge
	 */
	memset(packet_gen_space, 0, sizeof(packet_gen_space));
	kBufferGet(vsocketinfo.si_socketid,
		&packet_gen_space_len, (unsigned char *)packet_gen_space);
	kLogWrite(L_DEBUG,
		"%s: left data for socketid[%d]'s size is %ld packetspace[%100.100s]",
		__FUNCTION__, vsocketinfo.si_socketid,
		packet_gen_space_len, packet_gen_space);

	/*
	 * if packet_gen_space_len is 0, just recvbuf
	 */
	memcpy(packet_gen_space + packet_gen_space_len,
	       recvbuf,
	       recvbufsize);
	packet_gen_space_len += recvbufsize;

	kLogWrite(L_DEBUG,
		"%s: from now parsing data size is [%ld] space[%100.100s]",
		__FUNCTION__, packet_gen_space_len, packet_gen_space);

	/*
	 *  loop and parse
	 */
	datasocketinfo = (DatasocketInfo*)vsocketinfo.si_uniq_info_ptr;
	parse_current_position = (unsigned char  *)packet_gen_space;

	/* get parser */
	if(!kParserGet(vsocketinfo.si_peyload_type,
		       vsocketinfo.si_type, &(datasocketinfo->di_parser))) {
#ifdef DBG_PARSER
		kdbg("/tmp/dbg_parser.txt", "kParserGet: %s\n", "false");
#endif	/* DBG_PARSER */
		kLogWrite(L_INFO,
			"%s: kParserGet for [%d] is error. abort.",
			__FUNCTION__, vsocketinfo.si_peyload_type);
		return(RETURN_NG);
	}
#ifdef DBG_PARSER
	kdbg("/tmp/dbg_parser.txt", "kParserGet: %s\n", "true");
	kdbg("/tmp/dbg_parser.txt", "parser: %p\n", parser);
#endif	/* DBG_PARSER */

	while(1) {
#ifdef DBG_PARSER
	kdbg("/tmp/dbg_parser.txt", "datasocketinfo: %p\n", datasocketinfo);
#endif	/* DBG_PARSER */
		ret = datasocketinfo->di_parser(
				packet_gen_space_len,
				parse_current_position,
				&parse_current_position,
				&parse_size);

		kLogWrite(L_DEBUG, "%s: parser return anyway", __FUNCTION__);

		kLogWrite(L_DEBUG,
			"%s: parser return size[%d] current_position from [%100.100s]",
			__FUNCTION__, parse_size, parse_current_position);

		if(ret == PA_ERROR) {
			kLogWrite(L_WARNING,
				"%s: data parse for socketid[%d] is fail. abort",
				__FUNCTION__, vsocketinfo.si_socketid);
			return(RETURN_NG);
		} else if(ret == PA_JUSTONE) {
			/* regist data */
			kLogWrite(L_PARSE,
				"%s: just one packet there. finish parsing", __FUNCTION__);

			kDataRegist(vsocketinfo.si_socketid,
				    MSG_SOCKETMODE_RECV,
				    parse_size,
				    parse_current_position,
				    current_time);
			break;
		} else if(ret == PA_LEFTDATA) {
			/* regist data */
			kLogWrite(L_PARSE,
				"%s: you got one packet, repeat parsing....", __FUNCTION__);

			kDataRegist(vsocketinfo.si_socketid,
				    MSG_SOCKETMODE_RECV,
				    parse_size,
				    parse_current_position,
				    current_time);

			kLogWrite(L_DEBUG,
				"%s: current_position from [%100.100s]", __FUNCTION__,
				parse_current_position);

			parse_current_position
				= parse_current_position + parse_size;
			packet_gen_space_len -= parse_size;
			/* one more challenge */
		} else if(ret == PA_NOMATCH) {
			if(!packet_gen_space_len) {
				kLogWrite(L_DEBUG, "%s: no left_data", __FUNCTION__);
				break;
			}

			kLogWrite(L_PARSE,
				"%s: there is imcomplete data. odd data size is [%ld]. set "
				"left_data.finish parings", __FUNCTION__, packet_gen_space_len);
			kBufferSet(vsocketinfo.si_socketid,
				   packet_gen_space_len,
				   parse_current_position);
			break;
		} else {
			/* anyone can come here */
			break;
		}
	}

	return(RETURN_OK);
}



/***** Dump for Debug ****/
static void
SocketInfoDump(void)
{
  const char *in6addr2string(struct in6_addr *addr, char *buf, int *buflen);
  const char *inaddr2string(struct in_addr *addr, char *buf, int *buflen);

	SocketInfo	*sock;
	int no1=0;
	/*
	MsgData 	*msg;
	int no1=0, no2;
	char		s_addr[INET6_ADDRSTRLEN];
	char		d_addr[INET6_ADDRSTRLEN];
	*/
	DatasocketInfo *info;
	char buf[BUFSIZE];
	socklen_t buflen = sizeof(buf);

	if(!kIsLogLevel(L_CMD)) return;

	sock = g_socket_start_ptr;
	while(sock) {
		printf("\n== SocketInfo [%d] ==\n", no1 ++);
		printf("  Type:[%d]\n",        sock->si_type);
		printf("  Socketid:[%d]\n",    sock->si_socketid);
		printf("  Sockethandle:[%d]\n",sock->si_sockethandle);
		printf("  Linkname:[%s]\n",    sock->si_linkname);
		printf("  Status:[%d]\n",      sock->si_socket_status);
		printf("  PayloadType:[%d]\n", sock->si_peyload_type);
#ifdef SUPPORT_TLS
		printf("  TLS flag:[%d]\n",    sock->si_tls_mode);
		printf("  TLS SSL:[%x]\n",     (u_int)sock->si_tls_ssl_ptr);
#endif
		if(sock->si_type == SI_TYPE_UDP &&
		   sock->si_socket_status == SI_STATUS_ALIVE &&
		   sock->si_uniq_info_ptr
		   ) {
		  info=(DatasocketInfo*)sock->si_uniq_info_ptr;
		  if( info->di_family == PF_INET6 )
		    in6addr2string(&info->di_s_addr,buf,(int *)&buflen);
		  else
		    inaddr2string((struct in_addr *)&info->di_s_addr,buf,(int *)&buflen);
		  printf("  Src addr:[%s]\n",buf);
		  if( info->di_family == PF_INET6 )
		    in6addr2string(&info->di_d_addr,buf,(int *)&buflen);
		  else
		    inaddr2string((struct in_addr *)&info->di_d_addr,buf,(int *)&buflen);
		  printf("  Dst addr:[%s]\n",buf);
		  printf("  Src port:[%d]\n",info->di_s_port);
		  printf("  Dst port:[%d]\n",info->di_d_port);
		}

#if 0
		msg=g_msg_start_ptr; no2=0;
		while(msg) {
			if(msg->msg_socketid == sock->si_socketid) {

				inet_ntop(AF_INET6, (void*)&(msg->msg_s_addr),
					  s_addr, INET6_ADDRSTRLEN);
				inet_ntop(AF_INET6, (void*)&(msg->msg_d_addr),
					  d_addr, INET6_ADDRSTRLEN);

				printf("  == MsgData [%d] ==\n", no2 ++);
				printf("    Dataid:[%ld]\n", msg->msg_dataid);
				printf("    Socketmode:[%d]\n",
					msg->msg_socketmode);
				printf("    S_port:[%d]\n", msg->msg_s_port);
				printf("    D_port:[%d]\n", msg->msg_d_port);
				printf("    S_addr:[%p]\n", s_addr);
				printf("    D_addr:[%p]\n", d_addr);
				printf("    Datalen:[%ld]\n", msg->msg_datalen);
				/* XXX: */
				/* if socket is RAW socket, this value points to NULL */

				  printf("    Data:[%30.30s]\n",
				  msg->msg_data_ptr);


				break;
			}

			msg=msg->msg_next_ptr;
		}
#endif	/* 0 */
		sock=sock->si_next_socket_info_ptr;
	}
}
