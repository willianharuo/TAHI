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
 * $TAHI: koi/lib/kData/kData.c,v 1.39 2007/04/06 01:32:07 akisada Exp $
 *
 * $Id: kData.c,v 1.3 2008/06/03 07:39:55 akisada Exp $
 *
 */

#include <stdio.h>
#include <stdlib.h>
#include <string.h>
#include <sys/types.h>
#include <sys/socket.h>
#include <netinet/in.h>
#include <arpa/inet.h>

#include <koi.h>

#include "kData.h"

long     g_msg_dataid     = 0;		/* msg data id */
MsgData *g_msg_start_ptr = NULL;	/* msg first data pointer */

static MsgData *g_msg_last_ptr  = NULL;	/* current last position */
					/* change to use tailq */



/********************************************
 * packet data table
 ********************************************/
/*
 * initialize data_tabel.
 */
bool
kDataInit(void)
{
	MsgData	*current_position	= NULL;
	MsgData	*next_position		= NULL;
	long	log_dataid			= 0;	/* seve value before free() */

#ifdef DBG_DATA
	kdbg("/tmp/dbg_data.txt", "%s\n", "initializing.");
#endif	/* DBG_DATA */

	g_msg_last_ptr = NULL;
	/* set the NULL to first data pointer */
	/* if there are some data table, clear those. */

	if(g_msg_start_ptr) {
		/* set NULL */
		current_position	= g_msg_start_ptr;
		g_msg_start_ptr	= NULL;

		/* 
		 * save next position firest. and free data part,next 
		 * structure.if next is NULL, it is end so finish
		 */
		for( ; ; ) {
			next_position = current_position->msg_next_ptr;

			/*
			 * free data part 
			 */
			free(current_position->msg_data_ptr);
			kLogWrite(L_DEBUG, "%s: data_id %ld clear data part",
				 __FUNCTION__, current_position->msg_dataid);
	    
			/*
			 * free MsgData structure
			 */
			log_dataid = current_position->msg_dataid;
			free(current_position);
			kLogWrite(L_DEBUG, "%s: data_id [%ld] clear MsgData", __FUNCTION__,
				log_dataid);
	    
			if(next_position) {
				current_position = next_position;
			} else {
				break;
			}
		}
	
		kLogWrite(L_DEBUG, "%s: send/receive data all cleared", __FUNCTION__);
	} else {
		kLogWrite(L_DEBUG, "%s: no send/receive data", __FUNCTION__);
	}

	/* 
	 * data id reset 
	 */
	g_msg_dataid = 0;
	kLogWrite(L_DEBUG, "%s: data_id reset done", __FUNCTION__);
  
	return(true);
}



/*
 * clear data from the linked list
 */
bool
kDataClear(short socketid_flag, short dataid_flag, short socketid, long dataid)
{
	MsgData *current = NULL;
	MsgData *prev    = NULL;
	MsgData *garbage = NULL;
	bool clear_flag  = false;

	if(!g_msg_start_ptr) {
		kLogWrite(L_INFO, "%s: no data in table", __FUNCTION__);
		return(true);
	}

	if(!socketid_flag && !dataid_flag) {
		if(!socketid && !dataid) {
			kLogWrite(L_DEBUG, "%s: clear all data", __FUNCTION__);
			kDataInit();
			return(true);
		}

		kLogWrite(L_DEBUG,
			 "%s: either socketid_flag or dataid_flag must be 1 "
			 "or all fields are 0.", __FUNCTION__);
		return(false);
	}

	kLogWrite(L_DEBUG,
		 "%s: clear data which matches as socketid_flag(%d) "
		 "dataid_flag(%d) socketid(%d) dataid(%ld).",
		 __FUNCTION__, socketid_flag, dataid_flag, socketid, dataid);
	
	prev = NULL;
	for(current = g_msg_start_ptr; current; ) {
		kLogWrite(L_DEBUG,
			 "%s: current dataid(%ld) socketid(%d)", __FUNCTION__,
			 current->msg_dataid, current->msg_socketid);

		if(dataid_flag == 1 && current->msg_dataid == dataid) {
			clear_flag = true;
		}

		if(socketid_flag == 1 && current->msg_socketid == socketid) {
			clear_flag = true;
		}

		if(!clear_flag) {
			prev = current;
			current = current->msg_next_ptr;
			continue;
		}

		clear_flag = false;

		garbage = current;

		if(prev) {
			prev->msg_next_ptr = garbage->msg_next_ptr;
		} else {
			g_msg_start_ptr = garbage->msg_next_ptr;
		}

		if(current == g_msg_start_ptr) {
			g_msg_start_ptr = prev;
		}

		kLogWrite(L_DEBUG,
			 "%s: data [dataid(%ld) socketid(%d)] is cleared.",
			 __FUNCTION__, current->msg_dataid, current->msg_socketid);

		current = garbage->msg_next_ptr;
		free(garbage);
	}

	return(true);
}



/*
 * regist data to the linked list
 */
int
kDataRegist(short socketid, unsigned char mode, long datalen,
	unsigned char *data, struct timeval datatime)
{
	MsgData        *new        = NULL;	/* new data location */
	SocketInfo      socketinfo;		/* get si info here */
	UnixdInfo       unixdinfo;		/* for socketinfo */
	DatasocketInfo  datasocketinfo;		/* for socketinfo */
	ListenportInfo  listenportinfo;		/* for socketinfo */
	int             ret        = 0;
	struct tm      *time_obj   = NULL;	/* for log out timestamp */
	char            s_addr[INET6_ADDRSTRLEN];
	char            d_addr[INET6_ADDRSTRLEN];
	char           *s_addr_ptr = NULL;
	char           *d_addr_ptr = NULL;

	memset(&socketinfo,     0, sizeof(socketinfo));
	memset(&unixdinfo,      0, sizeof(unixdinfo));
	memset(&datasocketinfo, 0, sizeof(datasocketinfo));
	memset(&listenportinfo, 0, sizeof(listenportinfo));
	memset(s_addr,          0, sizeof(s_addr));
	memset(d_addr,          0, sizeof(d_addr));
#ifdef DBG_DATA
	kdbg("/tmp/dbg_data.txt", "%s\n", "initializing.");
	kdmp("/tmp/dbg_data.txt", "data", data, datalen);
#endif	/* DBG_DATA */
	kLogWrite(L_INFO, "%s: start", __FUNCTION__);

	/* 
	 * check the maxmum number of data
	 */
    
	if(g_msg_dataid == MSG_MAXMSGNUM) {
		kLogWrite(L_WARNING, "%s: msg data full %ld",
			__FUNCTION__, g_msg_dataid);
		return(RETURN_NG);
	}

	/* 
	 * socket type check UDP/TCP child accept only
	 */

	if((ret = kSocketGetSIBySocketId(socketid, &socketinfo, &unixdinfo,
					 &datasocketinfo, &listenportinfo))) {
		kLogWrite(L_WARNING, "%s: kSocketGetSIBySocketId() fail", __FUNCTION__);
		return(RETURN_NG);
	}

	kLogWrite(L_DEBUG, "%s: get socketinfo [socketid = %d]",
		__FUNCTION__, socketinfo.si_socketid);
    
	if((socketinfo.si_type == SI_TYPE_UNIX)		||
	   (socketinfo.si_type == SI_TYPE_UNIX_DATA)	||
	   (socketinfo.si_type == SI_TYPE_LISTEN_UDP)   ||
	   (socketinfo.si_type == SI_TYPE_LISTEN_TCP)) {

		kLogWrite(L_WARNING,
			"%s: invalid socket type[%d] to regist data",
			__FUNCTION__, socketinfo.si_type);

		return(RETURN_NG);
	}

	/* 
	 * allocate memory for new data space 
	 */

	if(!(new = (MsgData *)malloc(sizeof(MsgData)))) {
		kLogWrite(L_ERROR, "%s: malloc for new data fail", __FUNCTION__);
		return(RETURN_NG);
	}

	memset(new, 0, sizeof(*new));

	kLogWrite(L_DEBUG, "%s: allocate memory for data structure", __FUNCTION__);

	/* 
	 * allocate memory for data part of new data structure 
	 */
	if(!(new->msg_data_ptr = (unsigned char *)malloc(datalen))) {
		kLogWrite(L_ERROR, "%s: malloc for data space fail",
			__FUNCTION__);
		free(new);
		return(RETURN_NG);
	}

	memset(new->msg_data_ptr, 0, datalen);
#ifdef DBG_DATA
	kdmp("/tmp/dbg_data.txt", "msg_data", new->msg_data_ptr, datalen);
	kdbg("/tmp/dbg_data.txt", "msg_data: %p\n", new->msg_data_ptr);
#endif	/* DBG_DATA */

	kLogWrite(L_DEBUG, "%s: allocate memory for data", __FUNCTION__);
    
	/* 
	 ****************************************
	 * build the msg using inputed socketid *
	 ****************************************
	 */

	/* data id */
	g_msg_dataid ++;
	new->msg_dataid = g_msg_dataid;
    
	kLogWrite(L_DEBUG, "%s: data_id is %ld", __FUNCTION__, new->msg_dataid);
    
	/* socketid */
	new->msg_socketid = socketinfo.si_socketid;
    
	kLogWrite(L_DEBUG, "%s: socket_id is %d", __FUNCTION__, new->msg_socketid);

	/* time stamp */
	new->msg_timestamp = datatime;

	time_obj = localtime((const time_t *)&(new->msg_timestamp.tv_sec));
	kLogWrite(L_DEBUG, "%s: %d %d/%d %2d:%02d:%02d:%06ld", __FUNCTION__,
		time_obj->tm_year + 1900,
		time_obj->tm_mon + 1,
		time_obj->tm_mday, 
		time_obj->tm_hour,
		time_obj->tm_min, 
		time_obj->tm_sec, 
		new->msg_timestamp.tv_usec);
   
	/* socket mode receive/send */
	new->msg_socketmode = mode;
    
	kLogWrite(L_DEBUG, "%s mode is %d", __FUNCTION__, new->msg_socketmode);
    
	/***************************************************/
	/* source port */
	/* dest port */
	/* source address */
	/* dest address */
	/* 
	 * this is depend on type of sokeet.
	 * UNIX DOMEIN is no port number and address
	 * TCP data and udp has all
	 * TCP listen has source port and address
	 ***************************************************/
	
	/*
	 * TCP child or UDP
	 * all data available only
	 */
	switch(mode) {
		case MSG_SOCKETMODE_SEND:
			kLogWrite(L_DEBUG, "%s: now registing sending data", __FUNCTION__);
			new->msg_s_port = datasocketinfo.di_s_port;
			new->msg_d_port = datasocketinfo.di_d_port;
			memcpy(&(new->msg_s_addr),
				&(datasocketinfo.di_s_addr), 16);
			memcpy(&(new->msg_d_addr),
				&(datasocketinfo.di_d_addr), 16);
			break;
		case MSG_SOCKETMODE_RECV:
			/*
			 * if datamode is RECV, reverse addrress dst<-->src
			 */
			kLogWrite(L_DEBUG,
				"%s: now registing receiving data", __FUNCTION__);
			new->msg_d_port = datasocketinfo.di_s_port;
			new->msg_s_port = datasocketinfo.di_d_port;
			memcpy(&(new->msg_d_addr),
				&(datasocketinfo.di_s_addr), 16);
			memcpy(&(new->msg_s_addr),
				&(datasocketinfo.di_d_addr), 16);
			break;
		default:
			kLogWrite(L_INFO,
				"%s: invalid mode [%d]. abort.", __FUNCTION__, mode);
	}

	s_addr_ptr = (char *)inet_ntop(AF_INET6, (void *)&(new->msg_s_addr),
				s_addr, INET6_ADDRSTRLEN);
	d_addr_ptr = (char *)inet_ntop(AF_INET6, (void *)&(new->msg_d_addr),
				d_addr, INET6_ADDRSTRLEN);
    
	kLogWrite(L_DEBUG,
		"%s: socket type [%d] s_port is [%d] d_port is [%d] "
		"s_addres is [%s] d_address is [%s]", __FUNCTION__, socketinfo.si_type,
		new->msg_s_port, new->msg_d_port, s_addr_ptr, d_addr_ptr);
    
	/* address family */
	if (datasocketinfo.di_family) {
		new->msg_family = datasocketinfo.di_family;
		kLogWrite(L_DEBUG, "%s: address family[d] is %d",
			 __FUNCTION__, new->msg_family);
	}
	else if (listenportinfo.li_family) {
		new->msg_family = listenportinfo.li_family;
		kLogWrite(L_DEBUG, "%s: address family[l] is %d",
			__FUNCTION__, new->msg_family);
	}

	/* receive flg */
	new->msg_recvflg = MSG_RECVFLG_NOT_READ;
	kLogWrite(L_DEBUG, "%s: recv flg is %d", __FUNCTION__, new->msg_recvflg);
    
	/* data len */
	new->msg_datalen = datalen;
	kLogWrite(L_DEBUG, "%s: datalen is %ld", __FUNCTION__, new->msg_datalen);
    
	/* data */
	memcpy(new->msg_data_ptr, data, datalen);
#ifdef DBG_DATA
	kdmp("/tmp/dbg_data.txt", "data", data, datalen);
	kdmp("/tmp/dbg_data.txt", "msg_data",
		new->msg_data_ptr, new->msg_datalen);
	kdbg("/tmp/dbg_data.txt", "msg_data: %p\n", new->msg_data_ptr);
#endif	/* DBG_DATA */
	kLogWrite(L_DEBUG, "%s: write data [%100.100s]", __FUNCTION__, data);
    
	/* 
	 * connect the msg to linked list
	 */

	if(g_msg_start_ptr) {
		/* last data's next is new */
		g_msg_last_ptr->msg_next_ptr = new;
		kLogWrite(L_INFO, "%s: added sucsessfully", __FUNCTION__);
	} else {
		/* it is first one */
		g_msg_start_ptr = new;
		kLogWrite(L_INFO,
			"%s: added sucsessfully it was first data", __FUNCTION__);
	}

	/* new data's next is NULL */
	new->msg_next_ptr = NULL;
    
	/* now, last data is new */
	g_msg_last_ptr = new;
    
	return(RETURN_OK);
}



/* 
 * get data by dataid
 * return minus value    something bad
 * return 0              data return
 * return plus value     no data found 
 *
 * when this function called, always recvflg is MSG_RECVFLG_READ
 * because user has no way to get the dataid.
 * receive function call, so get the dataid.
 */
int
kDataGetDataByDataid(long dataid, MsgData *msginfo, unsigned char *data)
{
	MsgData *current_position = NULL;

#ifdef DBG_DATA
	kdbg("/tmp/dbg_data.txt", "%s\n", "initializing.");
#endif	/* DBG_DATA */
	/* 
	 * input check 
	 * dataid may be less than MSG_MAXMSGNUM
	 * dont have to check value 
	 */
	if(!msginfo || !data) {
		kLogWrite(L_WARNING, "%s: arg[data space] inputed NULL", __FUNCTION__);
		return(RETURN_NG);
	}

	kLogWrite(L_INFO, "%s: data search start-------", __FUNCTION__);

	/*
	 * set MsgData start point
	 */
	if(!g_msg_start_ptr) {
		kLogWrite(L_INFO, "%s: no data in table", __FUNCTION__);
		return(1);
	}

	current_position = g_msg_start_ptr;
    
	/* 
	 * search MsgData by dataid start by g_msg_start_ptr 
	 */
	for( ; ; ) {
		/*
		 * dataid match
		 */
		if(current_position->msg_dataid == dataid) {
			kLogWrite(L_DEBUG, "%s: found data id=[%ld]", __FUNCTION__, dataid);

			memcpy(msginfo, current_position, sizeof(MsgData));

			kLogWrite(L_DEBUG, "%s: copy MsgData", __FUNCTION__);

			memcpy(data, current_position->msg_data_ptr,
				current_position->msg_datalen);
			msginfo->msg_data_ptr = data;	/* insurance */

			kLogWrite(L_INFO, "%s: copy data", __FUNCTION__);
	    
			kLogWrite(L_DEBUG,
				"%s: dataid[%ld] socketid[%d] "
				"socketmode[%d] recvflg[%d] datalen[%ld]",
				__FUNCTION__, msginfo->msg_dataid,
				msginfo->msg_socketid, msginfo->msg_socketmode,
				msginfo->msg_recvflg, msginfo->msg_datalen);

			return(RETURN_OK);
		}

		/*
		 * data not found
		 */
		if(!current_position->msg_next_ptr) {
			/* at the last */
			kLogWrite(L_INFO,
				"%s: not found data_id=[%ld]", __FUNCTION__, dataid);

			/* no data found */
			return(1);
		}
	
		/* next data preparetion */
		current_position = current_position->msg_next_ptr;
	}

	return(RETURN_OK);
}



/* 
 * get data by socketid
 * return minus value    something bad
 * return 0              data return
 * return plus value     no data found 
 */
int
kDataGetDataBySocketid(short socketid, MsgData *msginfo, unsigned char *data)
{
	int            ret = 0;
	MsgData        *current_data_position = NULL;
	SocketInfo     socketinfo;
	UnixdInfo      unixdinfo;
	DatasocketInfo datasocketinfo;
	ListenportInfo listenportinfo;

	memset(&socketinfo,     0, sizeof(socketinfo));
	memset(&unixdinfo,      0, sizeof(unixdinfo));
	memset(&datasocketinfo, 0, sizeof(datasocketinfo));
	memset(&listenportinfo, 0, sizeof(listenportinfo));
#ifdef DBG_DATA
	kdbg("/tmp/dbg_data.txt", "%s\n", "initializing.");
#endif	/* DBG_DATA */
	kLogWrite(L_INFO, "%s: start to search ---------------", __FUNCTION__);

	/* set the start */
	if(!g_msg_start_ptr) {
		kLogWrite(L_INFO, "%s: no data in table", __FUNCTION__);
		return(1);
	}

	current_data_position = g_msg_start_ptr;

	/* 
	 * check the socket type udp or child or parent or minus
	 * so get the socketinfo 
	 * socketid 0 means anydata wanted and no need socketinfo-type
	 */
	if(socketid > 0) {
		ret = kSocketGetSIBySocketId(socketid, &socketinfo, &unixdinfo,
					     &datasocketinfo, &listenportinfo);
		if(ret < 0) {
			kLogWrite(L_WARNING,
				 "%s: get socketinfo fail socket_id[%d]",
				 __FUNCTION__, socketid);
			return(RETURN_NG);
		}
	} else if(socketid < 0) {
		kLogWrite(L_WARNING,
			"%s: invalid socketid [%d]", __FUNCTION__, socketid);
		return(RETURN_NG);
	}

	/* find the first data which is not read yet and receive data 
	 * MSG_RECVFLG_NOT_READ
	 * MSG_SOCKETMODE_RECV 
	 *
	 * udp socket just socketid matched socket
	 * tcp child  just scoketid matched socket
	 * tcp listen parent scoketid in the DatasocketInfo's field matced 
	 *		  socket(tcp child)
	 * socketid minus-value just first data matched
	 */

	if(!socketid) {
		/* anydata no-read caller want */
		kLogWrite(L_DEBUG,
			"%s: no sockeied input. data searching,,,,", __FUNCTION__);

		for( ; ; ) {
			if((current_data_position->msg_socketmode ==
				MSG_SOCKETMODE_RECV)	&&
			   (current_data_position->msg_recvflg ==
				MSG_RECVFLG_NOT_READ)) {

				kLogWrite(L_DEBUG, "%s: data found data_id[%ld]",
					__FUNCTION__, current_data_position->msg_dataid);
				break;
			}

			/* if next is NULL, searching end */
			if(!current_data_position->msg_next_ptr) {
				kLogWrite(L_INFO, "%s: no un-read data", __FUNCTION__);
				return(1);
			}

			/* set next */
			current_data_position =
				current_data_position->msg_next_ptr;
		}
	}
	else if(socketinfo.si_type == SI_TYPE_UDP
		|| socketinfo.si_type == SI_TYPE_DATA
		|| socketinfo.si_type == SI_TYPE_RAW) {
		/* socketid match data caller want */
		kLogWrite(L_DEBUG,
			"%s: udp or tcp data socket socket_id[%d] input. "
			"data searching,,", __FUNCTION__, socketid);

		for( ; ; ) {
			if((current_data_position->msg_socketmode == 
				MSG_SOCKETMODE_RECV)	&&
			   (current_data_position->msg_recvflg == 
				MSG_RECVFLG_NOT_READ)	&&
			   (current_data_position->msg_socketid == socketid)) {
				kLogWrite(L_DEBUG, "%s: data found data_id[%ld]",
					__FUNCTION__, current_data_position->msg_dataid);
				break;
			}

			/* if next is NULL, searching end */
			if(!current_data_position->msg_next_ptr) {
				kLogWrite(L_INFO, "%s: no un-read data", __FUNCTION__);
				return(1);
			}

			/* set next */
			current_data_position =
				current_data_position->msg_next_ptr;
		}
	}
	else if(socketinfo.si_type == SI_TYPE_LISTEN_TCP ||
		/* XXX */
		(socketinfo.si_type == SI_TYPE_LISTEN_UDP)) {
		/* tcp child socket which parent socketid match */
		kLogWrite(L_DEBUG, "%s: listen sock_id[%d] input. data searching,,",
			__FUNCTION__, socketid);

		for( ; ; ) {
			/* 
			 * get si by current_data->socketid 
			 * and whether tcp child or not
			 * whether parentid is equal to inputed socketid
			 */

			/* 
			 * 1 whether next data's socket type is tcp/child or not
			 */
			ret = kSocketGetSIBySocketId(
				current_data_position->msg_socketid,
				&socketinfo,
				&unixdinfo,
				&datasocketinfo,
				&listenportinfo);

			/*
			 * 2 get socketinfo fail, log down and,,,,
			 */
			if(ret < 0) {
				kLogWrite(L_INFO,
					"%s: get socketinfo fail socket_id[%d] "
						"go search next data,,,",
					__FUNCTION__, current_data_position->msg_socketid);
			}
	    
			/*
			 * 3 get socketinfo OK and type TCP/child,
			 * check the data
			 *     if not, throuth the check 
			 */
			if((ret > -1 )	&&
			   (socketinfo.si_type == SI_TYPE_DATA ||
			    socketinfo.si_type == SI_TYPE_UDP) &&
			   (socketinfo.si_socket_status == SI_STATUS_ALIVE)) {
		
				if((current_data_position->msg_socketmode == 
					MSG_SOCKETMODE_RECV)	&&
				   (current_data_position->msg_recvflg == 
					MSG_RECVFLG_NOT_READ)	&&
				   (datasocketinfo.di_parent_socketid ==
					socketid)) {

					kLogWrite(L_DEBUG,
						"%s: data found data_id[%ld] recvflg[%d]", __FUNCTION__,
						current_data_position->msg_dataid,
						current_data_position->msg_recvflg);

					break;
				}
			}
	    
			/*
			 * 4 if next is NULL, searching must end here
			 */
			if(!current_data_position->msg_next_ptr) {
				kLogWrite(L_INFO, "%s: no un-read data", __FUNCTION__);
				return(1);
			}

			/* 5 set next */
			current_data_position =
				current_data_position->msg_next_ptr;
		}
	}
	else {
		/* 
		 * inputed socketid which someone want data
		 * from has invalid type
		 * not UDP
		 * not DATA
		 * not LISTEN
		 */
		kLogWrite(L_WARNING,
			"%s: socket_id[%d] has invalid socket type[%d]",
			__FUNCTION__, socketinfo.si_socketid, socketinfo.si_type);
	
		return(RETURN_NG);
	}
    
	/*
	 * data found 
	 * now current_data_position points matched data
	 */

	/* copy data value from found MsgInfo to msginfo and data */
    
	memcpy(msginfo, current_data_position, sizeof(MsgData));
	kLogWrite(L_DEBUG, "%s: copy MsgData", __FUNCTION__);
    
	memcpy(data, current_data_position->msg_data_ptr,
		current_data_position->msg_datalen);

	msginfo->msg_data_ptr = data;	/* insurance */
	kLogWrite(L_INFO, "%s: copy data", __FUNCTION__);
    
	/* set flg MSG_RECVFLG_NOT_READ to MSG_RECVFLG_READ */

	if (datasocketinfo.di_family) {
		msginfo->msg_family = datasocketinfo.di_family;
		kLogWrite(L_DEBUG,
			 "%s: address family[d] is %d", __FUNCTION__, msginfo->msg_family);
	}
	else if (listenportinfo.li_family) {
		msginfo->msg_family = listenportinfo.li_family;
		kLogWrite(L_DEBUG,
			 "%s: address family[l] is %d", __FUNCTION__, msginfo->msg_family);
	}

	msginfo->msg_recvflg               = MSG_RECVFLG_READ;
	current_data_position->msg_recvflg = MSG_RECVFLG_READ;

	kLogWrite(L_INFO,
		"%s: dataid[%ld] socketid[%d] socketmode[%d] "
		"recvflg[%d] family[%d] datalen[%ld] data[%100.100s]",
		__FUNCTION__, msginfo->msg_dataid,
		msginfo->msg_socketid, msginfo->msg_socketmode,
		msginfo->msg_recvflg, msginfo->msg_family,
		msginfo->msg_datalen, msginfo->msg_data_ptr);

	return(RETURN_OK);
}
