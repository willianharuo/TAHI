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
 * $TAHI: koi/include/koi.h,v 1.125 2007/04/06 01:32:07 akisada Exp $
 *
 * $Id: koi.h,v 1.7 2008/12/25 11:40:02 inoue Exp $
 *
 */

#ifndef _KOI_H_
#define _KOI_H_

#include <sys/types.h>
#include <sys/socket.h>

/**********************************************************************
 * main                                                               *
 **********************************************************************/
#include <debug.h>

#define BUFSIZE		(256)	/* basic size for buffer */
				/* XXX: shouldn't be used */

#define	RETURN_OK	(0)	/* XXX: I hate this, it will be removed */
#define	RETURN_NG	(-1)	/* XXX: I hate this, it will be removed */

typedef unsigned char bool;
static const bool false	= 0;
static const bool true	= 1;

const char *xbasename(const char *);



/**********************************************************************
 * kBuffer I/F
 **********************************************************************/
bool kBufferInit(void);
bool kBufferSet(short, long, unsigned char *);
bool kBufferGet(short, long *, unsigned char *);



/**********************************************************************
 * kData I/F
 **********************************************************************/
#include <sys/time.h>
#include <netinet/in.h>

/*
 * packet data table
 * this tabel stocks receive/send data
 */

#define MSG_SOCKETMODE_RECV	(1)	/* receive data */
#define MSG_SOCKETMODE_SEND	(2)	/* send data */

typedef struct msg_data {
	long             msg_dataid;		/* data id */
	short            msg_socketid;		/* socket id */
	struct timeval   msg_timestamp;		/* time stamp */
	unsigned char    msg_socketmode;	/* socket mode receive/send */
	unsigned short   msg_s_port;		/* source port */
	unsigned short   msg_d_port;		/* dist port */
	struct in6_addr  msg_s_addr;		/* source addr */
	struct in6_addr  msg_d_addr;		/* dist addr */
	unsigned char    msg_recvflg;		/* receive flag read/not yet */
	unsigned char	 msg_family;
	long             msg_datalen;		/* msg data length */
	unsigned char   *msg_data_ptr;		/* msg data */
	struct msg_data *msg_next_ptr;		/* next msg data */
} MsgData;

bool kDataInit(void);
bool kDataClear(short, short, short, long);
int kDataRegist(short, unsigned char, long, unsigned char *, struct timeval);
int kDataGetDataByDataid(long, MsgData *, unsigned char *);
int kDataGetDataBySocketid(short, MsgData *, unsigned char *);
#if SUPPORT_TLS
int kTLSInitialize(int,int,int,char *,char *,char *,char *,int,int,int,int,char *);
int kTLSAccept(int handle,void **tlsssl,void **tlssession);
void *kTLSConnect(int, void *);
int kTLSSend(void *tlsssl,char *buff,int buffsize);
int kTLSRecv(void *tlsssl,char *buff,int buffsize);
int kTLSClear(int);
bool kIsTLSInitialize(void);
void *kGetTLSSession(void *);
char *kAddr2Str0(int, void *);
#endif	/* SUPPORT_TLS */

extern long    g_msg_dataid;		/* msg data id */
extern MsgData *g_msg_start_ptr;	/* msg first data pointer */



/**********************************************************************
 * kLog I/F                                                           *
 **********************************************************************/
#define L_DATA		(4096)	/* 0x1000 */
#define L_SOCKET	(2048)	/* 0x0800 */
#define L_TIME		(1024)	/* 0x0400 */
#define L_BUFFER	(512)	/* 0x0200 */
#define L_INIT		(256)	/* 0x0100 */
#define L_CMD		(128)	/* 0x0080 */
#define L_PARSE		(64)	/* 0x0040 */
#define L_DEBUG		(32)	/* 0x0020 */
#define L_INFO		(16)	/* 0x0010 */
#define L_TLS		(8)		/* 0x0008 */
#define L_IO		(4)		/* 0x0004 */
#define L_WARNING	(2)		/* 0x0002 */
#define L_ERROR		(1)		/* 0x0001 */

bool	kLogInit(const char *, int);
bool	kLogWrite(int, const char *, ...);
bool	kIsLogLevel(int);
void	kLogFinalize(void);



/**********************************************************************
 * kParser I/F
 **********************************************************************/
bool kParserInit(void);
bool kParserGet(int, unsigned char,
		int (**)(long, unsigned char *, unsigned char **, short *));



/**********************************************************************
 * kSocket I/F
 **********************************************************************/
#include<sys/time.h>	/* struct timeval */
#include<netinet/in.h>	/* struct in6_addr */

/*
 * socket info
 *
 * this structure is listed to next one by "si_next_sock".
 * if you want to create anoter socket, execute "malloc" for this
 * structure and let thoes be pointed by last one's
 * pointer "si_next_socket_info".
 */
typedef struct socket_info {
	unsigned char		si_type;			/* type ex.unix,udp,listen,data */
	short				si_socketid;		/* socket id */
	int					si_sockethandle;	/* socket handle */
	unsigned char		si_linkname[16];	/* if linkname ex. Link0 */
	unsigned char		si_socket_status;	/* socket status ex.alive/close */
	void				*si_uniq_info_ptr;	/* depends on each type */
	short				si_peyload_type;	/* data type ex. SIP */
	struct socket_info	*si_next_socket_info_ptr;
											/* pointing next sock_info */
#ifdef SUPPORT_TLS
	int					si_tls_mode;		/* TLS mode */
	void				*si_tls_ssl_ptr;	/* TLS SSL object */
#endif	/* SUPPORT_TLS */
} SocketInfo;

/* XXX: change to use enum */
#define	SI_TYPE_UNIX		(1)	/* unix domain socket */
#define	SI_TYPE_UNIX_DATA	(2)	/* unix data scoket */
#define	SI_TYPE_UDP		(3)	/* udp socket */
#define	SI_TYPE_DATA		(4)	/* tcp child socket */
#define	SI_TYPE_LISTEN_UDP	(5)	/* udp parent socket */
#define	SI_TYPE_LISTEN_TCP	(6)	/* tcp parent socket */
#define SI_TYPE_RAW		(7)	/* raw socket */

/* XXX: change to use enum */
#define	SI_STATUS_ALIVE		(1)	/* now under using */
#define	SI_STATUS_CLOSE		(2)	/* socket already closed */

/*
 * uniq_info type 1
 * socket info for unix domein socket
 * used for si_uniq_info see above
 */
typedef struct {
    unsigned char	ui_sockpath[256];	/* pathname for unix_dsocket */
    int (*ui_parser)(long, unsigned char*, unsigned char**, short*);
} UnixdInfo;

/*
 * uniq_info tyep 2
 * for datasock_info like tcp data socket and udp socket
 * for si_uniq_info
 */
typedef struct {
	unsigned short	di_s_port;		/* source port */
	unsigned short	di_d_port;		/* distnation port */
	struct in6_addr	di_s_addr;		/* source address */
	struct in6_addr	di_d_addr;		/* distnation address */
	int (*di_parser)(long, unsigned char*, unsigned char**, short*);
	struct timeval	di_close_waitvalue;	/* wait time for close */
	short		di_parent_socketid;	/* parent socket id */
	unsigned char	di_family;
	struct sockaddr_storage di_sss_addr;
	struct sockaddr_storage di_ssd_addr;
} DatasocketInfo;

/*
 * uniq_info type3
 * for parent(lisnten) socket
 * for si_uniq_info
 */
typedef struct {
	unsigned short	li_s_port;	/* listening port */
	struct in6_addr	li_s_addr;	/* listening address */
	unsigned char	li_family;
} ListenportInfo;


/* global variables */
extern short		g_socket_socketid;	/* socket id */
extern SocketInfo	*g_socket_start_ptr;	/* socket table */
extern SocketInfo	*g_socket_last_ptr;	/* current last position */

extern fd_set		g_readfds;		/* original data */
extern fd_set		g_execfds;		/* you call func with this */

/* socket connection */
#define	SELECT_IN		(1)
#define	SELECT_OUT		(2)
#define	SOCKET_MAXNUM		(0x7fff)			/* signed 2byte length */

/* parser */
#define P_COMMAND	(0)		/* command for UNIX */

/*
 * functions
 */
int kSocketInit(void);

/* used in fd_command_action() */
int kSocketOpen(unsigned char, short, char,
		unsigned short, struct in6_addr,
		unsigned short, struct in6_addr,
		unsigned char[], short, short, short *);

/* used in fd_command_action() and main() */
int kSocketOpenWaitSocket(unsigned char, short, char,
			  unsigned short, struct in6_addr,
			  unsigned char[], short, short, short *);

int kSocketOpenRaw(char, struct in6_addr, struct in6_addr,
		   char, short, unsigned char *, short *);

/* used in fd_command_action() and main() */
/* XXX: experimental */
int kSocketOpenUnixdSocket(char *, short, short *);

/* used in fd_command_action() and t_socket_close() */
int kSocketClose(short);

/* used in fd_command_action() */
int kSocketSend(short, long, unsigned char*, long*, struct timeval*);

/* used in fd_data_action() and fd_listen_action() */
int kSocketSelectOperation(int, int);

#ifdef SUPPORT_TLS
int kSocketGetAddrFamily(int);
#endif	/* SUPPORT_TLS */

/* used in main loop */
int kSocketGetSelectedHandle(int*, unsigned char*);
#ifdef SUPPORT_TLS
void kSocketTLSClose(void *);
#endif	/* SUPPORT_TLS */

/* used in fd_command_action() */
int kSocketRegistUnixdSocketInfo(unsigned char, int, unsigned char[]);

/* used in fd_listen_action() */
int kSocketRegistDataSocketInfo(
	unsigned char,
	int,
	unsigned char[],
	short,
/*	unsigned short,
	unsigned short,
	struct in6_addr,
	struct in6_addr,*/
	struct sockaddr_storage s_addr,
	struct sockaddr_storage d_addr,
	int (*)(long, unsigned char*,	unsigned char**, short*),
	short,
	unsigned char,int,void*);

/* use in kData  */
int kSocketGetSIBySocketId(short, SocketInfo *, UnixdInfo *,
			   DatasocketInfo *, ListenportInfo *);

/* use in fd_data_action() and fd_listen_action() */
int kSocketGetSIBySocketHandle(int, SocketInfo*, UnixdInfo*,
			       DatasocketInfo*, ListenportInfo*);

/* use in fd_command_action() */
int kSocketCheckNewSocket(unsigned short, struct in6_addr,
			  unsigned short, struct in6_addr, char, short*);

int icmp_recv(int, const unsigned char*,
	      struct sockaddr*, socklen_t,
	      struct sockaddr*, socklen_t,
	      char *, int);



/**********************************************************************
 * kSocket I/F
 **********************************************************************/

/*
 * IfInfo
 * inteface table which has linkname, devivename and scopeid
 * when module starts, made by def file and if_nametoindex
 */
typedef struct {
	unsigned char	ii_linkname[16];	/* linkname ex. Link0 */
	unsigned char	ii_devicename[16];	/* devicename ex. fxp0 */
	unsigned long	ii_scope_id;		/* scope id got by if_nametoindex */
} IfInfo;

#define	IF_KEYWORD	"Link"	/* line matching key word */
#define	IF_KEYSIZE	(4)		/* and size */

/* I/F table creation */
bool kIFInit(char*);
const char* kIFGetDevicenameByLinkname(const unsigned char*);



/**********************************************************************
 * kCloseTimer I/F
 **********************************************************************/

/* functions */
int kCloseTimerInit(void);
int kCloseTimerSet(short,int);
int kCloseTimerProc(void);


/**********************************************************************
 * kRecvTimer I/F
 **********************************************************************/

/* functions */
int kRecvTimerInit(void);
int kRecvTimerSet(int,short,int,short);
int kRecvTimerProc(void);

#define	MSG_MAXDATALEN	(64 * 1024)	/* packet max length 64kbyte */

/* base(2byte) */
#define	CM_CM_TYPE_REQ		(0x0000)
#define	CM_CM_TYPE_ACK		(0x8000)
#define	CM_CM_CATEG_SIG		(0x0100)

#define	CM_CM_SUB_CONNEC	(0x0001)
#define	CM_CM_SUB_SEND		(0x0002)
#define	CM_CM_SUB_RECV		(0x0003)
#define	CM_CM_SUB_CLOSE		(0x0004)
#define	CM_CM_SUB_WAIT		(0x0005)
#define	CM_CM_SUB_SOCKINFO	(0x0006)
#define	CM_CM_SUB_DATAINFO	(0x0007)
#define	CM_CM_SUB_FLUSH		(0x0008)
#ifdef SUPPORT_TLS
#define CM_CM_SUB_TLS_SETUP	(0x0009)
#define CM_CM_SUB_TLS_CLEAR	(0x000A)
#endif	/* SUPPORT_TLS */
#define	CM_CM_SUB_PARSER_ATTACH	(0x000B)

/* command(2byte) */
#define	CM_CM_SIG_CONNEC_REQ	\
	((CM_CM_CATEG_SIG)	| (CM_CM_SUB_CONNEC)	| (CM_CM_TYPE_REQ))
#define	CM_CM_SIG_CONNEC_ACK	\
	((CM_CM_CATEG_SIG)	| (CM_CM_SUB_CONNEC)	| (CM_CM_TYPE_ACK))
#define	CM_CM_SIG_SEND_REQ	\
	((CM_CM_CATEG_SIG)	| (CM_CM_SUB_SEND)		| (CM_CM_TYPE_REQ))
#define	CM_CM_SIG_SEND_ACK	\
	((CM_CM_CATEG_SIG)	| (CM_CM_SUB_SEND)		| (CM_CM_TYPE_ACK))
#define	CM_CM_SIG_RECV_REQ	\
	((CM_CM_CATEG_SIG)	| (CM_CM_SUB_RECV)		| (CM_CM_TYPE_REQ))
#define	CM_CM_SIG_RECV_ACK	\
	((CM_CM_CATEG_SIG)	| (CM_CM_SUB_RECV)		| (CM_CM_TYPE_ACK))
#define	CM_CM_SIG_CLOSE_REQ	\
	((CM_CM_CATEG_SIG)	| (CM_CM_SUB_CLOSE)		| (CM_CM_TYPE_REQ))
#define	CM_CM_SIG_CLOSE_ACK	\
	((CM_CM_CATEG_SIG)	| (CM_CM_SUB_CLOSE)		| (CM_CM_TYPE_ACK))
#define	CM_CM_SIG_WAIT_REQ	\
	((CM_CM_CATEG_SIG)	| (CM_CM_SUB_WAIT)		| (CM_CM_TYPE_REQ))
#define	CM_CM_SIG_WAIT_ACK	\
	((CM_CM_CATEG_SIG)	| (CM_CM_SUB_WAIT)		| (CM_CM_TYPE_ACK))
#define	CM_CM_SIG_SOCKINFO_REQ	\
	((CM_CM_CATEG_SIG)	| (CM_CM_SUB_SOCKINFO)	| (CM_CM_TYPE_REQ))
#define	CM_CM_SIG_SOCKINFO_ACK	\
	((CM_CM_CATEG_SIG)	| (CM_CM_SUB_SOCKINFO)	| (CM_CM_TYPE_ACK))
#define	CM_CM_SIG_DATAINFO_REQ	\
	((CM_CM_CATEG_SIG)	| (CM_CM_SUB_DATAINFO)	| (CM_CM_TYPE_REQ))
#define	CM_CM_SIG_DATAINFO_ACK	\
	((CM_CM_CATEG_SIG)	| (CM_CM_SUB_DATAINFO)	| (CM_CM_TYPE_ACK))
#define	CM_CM_SIG_FLUSH_REQ	\
	((CM_CM_CATEG_SIG)	| (CM_CM_SUB_FLUSH)	| (CM_CM_TYPE_REQ))
#define	CM_CM_SIG_FLUSH_ACK	\
	((CM_CM_CATEG_SIG)	| (CM_CM_SUB_FLUSH)	| (CM_CM_TYPE_ACK))
#ifdef SUPPORT_TLS
#define CM_CM_SIG_TLS_SETUP_REQ	\
	((CM_CM_CATEG_SIG)	| (CM_CM_SUB_TLS_SETUP)	| (CM_CM_TYPE_REQ))
#define CM_CM_SIG_TLS_SETUP_ACK	\
	((CM_CM_CATEG_SIG)	| (CM_CM_SUB_TLS_SETUP)	| (CM_CM_TYPE_ACK))
#define CM_CM_SIG_TLS_CLEAR_REQ	\
	((CM_CM_CATEG_SIG)	| (CM_CM_SUB_TLS_CLEAR)	| (CM_CM_TYPE_REQ))
#define CM_CM_SIG_TLS_CLEAR_ACK	\
	((CM_CM_CATEG_SIG)	| (CM_CM_SUB_TLS_CLEAR)	| (CM_CM_TYPE_ACK))
#endif	/* SUPPORT_TLS */
#define	CM_CM_SIG_PARSER_ATTACH_REQ	\
	((CM_CM_CATEG_SIG)	| (CM_CM_SUB_PARSER_ATTACH)	| (CM_CM_TYPE_REQ))
#define	CM_CM_SIG_PARSER_ATTACH_ACK	\
	((CM_CM_CATEG_SIG)	| (CM_CM_SUB_PARSER_ATTACH)	| (CM_CM_TYPE_ACK))

/* result(2byte)*/
#define	CM_RESULT_OK			(0x0000)
#define	CM_RESULT_NG			(0x8000)

#define	CM_RESULT_CATEG_SIG		(0x0100)

#define CM_RESULT_SIG_NG			((CM_RESULT_NG) | (CM_RESULT_CATEG_SIG))
#define	CM_RESULT_SIG_NG_TIMEOUT	(0x0001 | (CM_RESULT_SIG_NG))
#define	CM_RESULT_SIG_NG_PARMERR	(0x0002 | (CM_RESULT_SIG_NG))
#define	CM_RESULT_SIG_NG_SOCKID		(0x0003 | (CM_RESULT_SIG_NG))
#define	CM_RESULT_SIG_NG_SYSCALL	(0x0004 | (CM_RESULT_SIG_NG))
#define	CM_RESULT_SIG_NG_OTHER		(0x0005 | (CM_RESULT_SIG_NG))
#ifdef SUPPORT_TLS
#define CM_RESULT_SIG_TLS_NOINIT	(0x0006 | (CM_RESULT_SIG_NG))
#endif	/* SUPPORT_TLS */

#define CM_IP_IPV6		(0x06)
#define CM_IP_IPV4		(0x04)

#define CM_PROT_TCP		(0x01)
#define CM_PROT_UDP		(0x02)
#define CM_PROT_ICMP	(0x03)
#ifdef SUPPORT_TLS
#define CM_PROT_TLS		(0x04)
#endif	/* SUPPORT_TLS */

/**********************************************************************
 * kDispatcher I/F
 **********************************************************************/

/* parser*/
/* XXX: change to use enum */
#define PA_ERROR	(-1)	/* no message in data */
#define PA_JUSTONE	(0)	/* Just 1 message in data */
#define PA_LEFTDATA	(1)	/* Have more message in data */
#define PA_NOMATCH	(2)
		/* Not enough data for message (maybe more data exist) */

/* functions */
int kDispatcherProc(int, unsigned char);

/* XXX: put only definition for kRecvTimeoutTimer lib */
int recv_ack_return(int,short,short,short,short,MsgData*);

/**********************************************************************
 * socket option 
 **********************************************************************/
#if defined IP_RECVDSTADDR
# define DSTADDR_SOCKOPT IP_RECVDSTADDR
#if defined IPV6_RECVPKTINFO
# define DSTADDR_SOCKOPT6 IPV6_RECVPKTINFO
#elif defined IPV6_RECVDSTADDR
# define DSTADDR_SOCKOPT6 IPV6_RECVDSTADDR
#else
# define DSTADDR_SOCKOPT6 IP_RECVDSTADDR
#endif
# define DSTADDR_DATASIZE (CMSG_SPACE(sizeof(struct in_addr)))
# define DSTADDR_DATASIZE6 (CMSG_SPACE(sizeof(struct in6_addr)))
# define dstaddr(x) (CMSG_DATA(x))
# define dstaddr6(x) (CMSG_DATA(x))
#elif defined IP_PKTINFO
# define DSTADDR_SOCKOPT IP_PKTINFO
# define DSTADDR_SOCKOPT6 IPV6_PKTINFO
# define DSTADDR_DATASIZE (CMSG_SPACE(sizeof(struct in_pktinfo)))
# define DSTADDR_DATASIZE6 (CMSG_SPACE(sizeof(struct in6_pktinfo)))
# define dstaddr(x) (&(((struct in_pktinfo *)(CMSG_DATA(x)))->ipi_addr))
# define dstaddr6(x) (&(((struct in6_pktinfo *)(CMSG_DATA(x)))->ipi6_addr))
#else
# error "can't determine socket option"
#endif

#endif	/* _KOI_H_ */
