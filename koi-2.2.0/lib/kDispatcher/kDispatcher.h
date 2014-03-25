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
 * $TAHI: koi/lib/kDispatcher/kDispatcher.h,v 1.17 2007/04/05 07:54:16 akisada Exp $
 *
 * $Id: kDispatcher.h,v 1.4 2008/12/25 11:41:55 inoue Exp $
 *
 */

#ifndef _K_DISPATCHER_H_
#define _K_DISPATCHER_H_

/* command */
#define CM_STATUS_LISTEN	0x01
#define CM_STATUS_CONNEC	0x02
#define CM_STATUS_CLOSE		0x03

#define	CM_MAX_CM_LENGTH	(MSG_MAXDATALEN + 4 * 16)
#ifdef SUPPORT_TLS
#define PASSWORD_LENGTH	32
#define CERTFILE_PATH	128
#endif	/* SUPPORT_TLS */

#define MODULE_PATH	128
#define PARSER_NAME	64


/*
 * req structure
 */
typedef struct {
	short			command;				/* 16bit */
	short			request_num;			/* 16bit */
	short			s_port;					/* 16bit */
	short			d_port;					/* 16bit */
	char			ipver;					/* 8bit */
	char			protocol;				/* 8bit */
	short			interfaceid;			/* 16bit */
	struct in6_addr	s_addr;					/* 128bit */
	struct in6_addr	d_addr;					/* 128bit */
	short			flags;					/* 16bit */
	short			frameid;				/* 16bit */
	long			datalen;				/* 32bit */
	unsigned char	data[MSG_MAXDATALEN];	/* 64k bytes */
} CONNEC_REQ;

typedef struct {
	short			command;				/* 16bit */
	short			request_num;			/* 16bit */
	short			socketid;				/* 16bit */
	short			reserve;				/* 16bit */
	long			datalen;				/* 32bit */
	unsigned char	data[MSG_MAXDATALEN];	/* 64k bytes */
} SEND_REQ;

typedef struct{
	short	command;		/* 16bit */
	short	request_num;	/* 16bit */
	short	socketid;		/* 16bit */
	short	timeout_timer;	/* 16bit */
} RECV_REQ;

typedef struct{
	short	command;		/* 16bit */
	short	request_num;	/* 16bit */
	short	socketid;		/* 16bit */
	short	waittime;		/* 16bit */
} CLOSE_REQ;

typedef struct{
	short			command;		/* 16bit */
	short			request_num;	/* 16bit */
	short			interfaceid;	/* 16bit */
	short			frameid;		/* 16bit */
	char			ipver;			/* 8bit */
	char			protocol;		/* 8bit */
	short			s_port;			/* 16bit */
	struct in6_addr	s_addr;			/* 128bit */
	short			flags;			/* 16bit */
} WAIT_REQ;

typedef struct {
	short	command;		/* 16bit */
	short	request_num;	/* 16bit */
	short	socketid;		/* 16bit */
} SOCKINFO_REQ;

typedef struct {
	short	command;		/* 16bit */
	short	request_num;	/* 16bit */
	long	dataid;			/* 32bit */
} DATAINFO_REQ;

typedef struct {
	short	command;		/* 16bit */
	short	request_num;	/* 16bit */
	short	socketid_flag;	/* 16bit */
	short	dataid_flag;	/* 16bit */
	short	socketid;		/* 16bit */
	long	dataid;			/* 16bit */
} FLUSH_REQ;

#ifdef SUPPORT_TLS
typedef struct {
	short			command;					/* 16bit */
	short			request_num;				/* 16bit */
	short			sessionmode;				/* 16bit */
	short			initialmode;				/* 16bit */
	short			ssltimeout;					/* 16bit */
	short			sslversion;					/* 16bit */
	unsigned char	passwd[PASSWORD_LENGTH];	/* 32 bytes */
	unsigned char	rootpem[CERTFILE_PATH];		/* 128 bytes */
	unsigned char	mypem[CERTFILE_PATH];		/* 128 bytes */
	unsigned char	dhpem[CERTFILE_PATH];		/* 128 bytes */
	short			nagle;			/* 16bit */
	short			clientveri;		/* 16bit */
	short			tmprsa;			/* 16bit */
	unsigned char		encsuit[CERTFILE_PATH];	/* 128 bytes */
} TLS_SETUP_REQ;

typedef struct {
	short	command;		/* 16bit */
	short	request_num;	/* 16bit */
	short	socketid;		/* 32bit */
} TLS_CLEAR_REQ;
#endif	/* SUPPORT_TLS */

typedef struct {
	short	command;		/* 16bit */
	short	request_num;	/* 16bit */
	short	parserid;	/* 16bit */
	short	mode;	/* 16bit */
        char    parsernname[PARSER_NAME];
        char    modulepath[MODULE_PATH];
} PARSER_ATTACH_REQ;

/*
 * ack structure
 */
typedef struct {
	short			command;		/* 16bit */
	short			request_num;	/* 16bit */
	short			result;			/* 16bit */
	short			socketid;		/* 16bit */
	long			dataid;			/* 32bit */
	struct timeval	timestamp;		/* 64bit */
} CONNEC_ACK;

typedef struct {
	short			command;				/* 16bit */
	short			request_num;			/* 16bit */
	short			result;					/* 16bit */
	short			socketid;				/* 16bit */
	long			dataid;					/* 32bit */
	struct timeval	timestamp;				/* 64bit */
	short			s_port;					/* 16bit */
	short			d_port;					/* 16bit */
	char			ipver;					/* 8bit */
	char			reserve1;				/* 8bit */
	short			reserve2;				/* 16bit */
	struct in6_addr	s_addr;					/* 128bit */
	struct in6_addr	d_addr;					/* 128bit */
	long			datalen;				/* 32bit */
	unsigned char	data[MSG_MAXDATALEN];	/* 64k bytes */
} RECV_ACK;

typedef struct {
	short	command;		/* 16bit */
	short	request_num;	/* 16bit */
	short	result;			/* 16bit */
	short	socketid;		/* 16bit */
} CLOSE_ACK;

typedef struct {
	short			command;			/* 16bit */
	short			request_num;		/* 16bit */
	short			result;				/* 16bit */
	char			protocol;			/* 8bit */
	char			connection_status;	/* 8bit */
	char			ipver;				/* 8bit */
	char			reserve1;			/* 8bit */
	short			reserve2;			/* 16bit */
	short			s_port;				/* 16bit */
	short			d_port;				/* 16bit */
	struct in6_addr	s_addr;				/* 128bit */
	struct in6_addr	d_addr;				/* 128bit */
	short			frameid;			/* 16bit */
	short			interfaceid;		/* 16bit */
	long		tlsmode;	/* 32bit */
	unsigned long	tlsssl;		/* 32bit */
	unsigned long	tlssession;	/* 32bit */
} SOCKINFO_ACK;

typedef struct {
	short			command;				/* 16bit */
	short			request_num;			/* 16bit */
	unsigned short	result;					/* 16bit */
	short			socketid;				/* 16bit */
	struct timeval	timestamp;				/* 64bit */
	long			datalen;				/* 32bit */
	unsigned char	data[MSG_MAXDATALEN];	/* 64k bytes */
} DATAINFO_ACK;

typedef struct {
	short			command;		/* 16bit */
	short			request_num;	/* 16bit */
	unsigned short	result;			/* 16bit */
} FLUSH_ACK;

#ifdef SUPPORT_TLS
typedef struct {
	short			command;		/* 16bit */
	short			request_num;	/* 16bit */
	unsigned short	result;			/* 16bit */
} TLS_SETUP_ACK;

typedef struct {
	short			command;		/* 16bit */
	short			request_num;	/* 16bit */
	unsigned short	result;			/* 16bit */
} TLS_CLEAR_ACK;
#endif	/* SUPPORT_TLS */
#endif	/* _K_DISPATCHER_H_ */
