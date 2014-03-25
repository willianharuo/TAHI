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
 * $TAHI: koi/lib/kRecvTimeoutTimer/kRecvTimeoutTimer.c,v 1.16 2007/04/04 06:39:36 akisada Exp $
 *
 * $Id: kRecvTimeoutTimer.c,v 1.2 2008/06/03 07:39:57 akisada Exp $
 *
 */

#include <stdio.h>
#include <stdlib.h>
#include <string.h>

#include <koi.h>

#include "kRecvTimeoutTimer.h"

static int kRecvTimerRemove(short);

int          g_rt_num       = 0;
RecvTimeout *g_rt_start_ptr = NULL;	/* recv timout table */
RecvTimeout *g_rt_last_ptr  = NULL;	/* recv timout table */



/* init */
int
kRecvTimerInit(void)
{
	RecvTimeout *next_position    = NULL;
	RecvTimeout *current_position = NULL;
	short        socketid         = 0;	/* for logout */

	if(!g_rt_start_ptr) {
		kLogWrite(L_DEBUG, "%s: no seted timer. no need to init", __FUNCTION__);

		return(RETURN_OK);
	}

	current_position = g_rt_start_ptr;

	for( ; ; ) {
		/* save next */
		socketid	= current_position->rt_socketid;
		next_position	= current_position->rt_next;

		free(current_position);
		kLogWrite(L_DEBUG,
			"%s: tablenum[%d] for socketid[%d] was freed",
			__FUNCTION__, g_rt_num,socketid);

		if(!next_position) {
			kLogWrite(L_DEBUG, "%s: all inited", __FUNCTION__);
			break;
		}

		current_position = next_position;
	}

	g_rt_start_ptr	= NULL;
	g_rt_num	= 0;

	return(RETURN_OK);
}



/* set */
int
kRecvTimerSet(int handle,short socketid, int sec, short request_num)
{
	RecvTimeout    *current_position = NULL;
	RecvTimeout    *new              = NULL;
	struct timeval  set_time;

	memset(&set_time, 0, sizeof(set_time));

	if(socketid < 0) {
		kLogWrite(L_INFO,
			"%s: invalid socketid[%d]. abort", __FUNCTION__, socketid);
		return(RETURN_NG);
	}

	kLogWrite(L_DEBUG, "%s: start", __FUNCTION__);

	/*
	 * max number check
	 * g_rt_num                this table number
	 * g_socket_socketid       current number
	 */
	if(g_rt_num == g_socket_socketid) {
		kLogWrite(L_INFO,
			"%s: current sock_num is %d. you cannot regist more than %d",
			__FUNCTION__, g_socket_socketid, g_socket_socketid);
		return(RETURN_NG);
	}

	/*
	 * if already exist, invalid
	 */
	current_position = g_rt_start_ptr;

	if(g_rt_start_ptr) {
		for( ; ; ) {
			if(current_position->rt_socketid == socketid) {
				/* data exist */
				kLogWrite(L_INFO,
					"%s: socketid[%d] exist. abort", __FUNCTION__, socketid);
				return(RETURN_NG);
			}

			if(!(current_position->rt_next)) {
				/* data no exist */
				kLogWrite(L_DEBUG,
					"%s: OK. no data exist for socketid[%d]",
					__FUNCTION__, socketid);

				break;
			}

			current_position = current_position->rt_next;
		}
	}

	/*
	 * allocate memory
	 */
	if(!(new = (RecvTimeout*)malloc(sizeof(RecvTimeout)))) {
		kLogWrite(L_ERROR,
			"%s: malloc for new structure fail. abort", __FUNCTION__);

		return(RETURN_NG);
	}

	kLogWrite(L_DEBUG, "%s: allocate memory for structure", __FUNCTION__);
	memset(new, 0, sizeof(*new));

	/*
	 * build message
	 */
	new->rt_sockethandle = handle;
	new->rt_socketid     = socketid;

	gettimeofday(&set_time, NULL);

	kLogWrite(L_INFO, "%s: sec(%ld) usec(%ld)",
		__FUNCTION__, set_time.tv_sec, set_time.tv_usec);

	set_time.tv_sec      = set_time.tv_sec + sec;
	new->rt_expire       = set_time;
	new->rt_request_num  = request_num;

	g_rt_num ++;

	kLogWrite(L_INFO,
		"%s: sec(%ld) usec(%ld)",
		__FUNCTION__, set_time.tv_sec, set_time.tv_usec);

	/*
	 * link to list
	 */
	if(g_rt_start_ptr) {
		/* last data's next is new */
		g_rt_last_ptr->rt_next = new;
		kLogWrite(L_INFO,
			"%s: add data successfully socoketid[%d]", __FUNCTION__, socketid);
	} else {
		/* first data */
		g_rt_start_ptr = new;
		kLogWrite(L_INFO,
			"%s: add the first data for socketid[%d]",
			__FUNCTION__, socketid);
	}

	/* new datas next is NULL */
	new->rt_next = NULL;

	/* now, last is new */
	g_rt_last_ptr = new;

	return(RETURN_OK);
}



/*
 * recv_timeout timer
 */
int
kRecvTimerProc(void)
{
	struct timeval  current_time;
	RecvTimeout    *current_position = NULL;
	MsgData         msg_data;
	unsigned char   data[MSG_MAXDATALEN];
	int             ret = 0;
	int i=0;

	memset(&current_time, 0, sizeof(current_time));
	memset(&msg_data,     0, sizeof(msg_data));
	memset( data,         0, sizeof(data));

	gettimeofday(&current_time, NULL);

	/*
	 * nothing registerd, no action
	 */
	if(!g_rt_num) {
		return(RETURN_OK);
	}

	/*
	 * all action for registerd socket
	 */
	for(current_position = g_rt_start_ptr; current_position;
	    current_position = current_position->rt_next, ++i) {

		/* first, try to find data */
		ret = kDataGetDataBySocketid(current_position->rt_socketid,
					     &msg_data, data);
		if(ret < 0) {
			/* someting error */
			kLogWrite(L_INFO,
				"%s: kDataGetDataBySocketid() error. socketid[%d] end",
				__FUNCTION__, current_position->rt_socketid);

			kRecvTimerRemove(current_position->rt_socketid);
		}
		else if(ret > 0) {
			/* there ware no data. so now check the timer */

			kLogWrite(L_INFO,
				"%s: kDataGetDataBySocketid():%d "
				"process no data case socketid[%d]",
				__FUNCTION__, i, current_position->rt_socketid);

			if(current_position->rt_expire.tv_sec >
			    current_time.tv_sec) {
				/*
				 * time to expire is over 1 sec
				 * no action here
				 */
				kLogWrite(L_INFO, "%s: time to expire is %ld sec", __FUNCTION__,
					current_position->rt_expire.tv_sec - current_time.tv_sec);
			}
			else if((current_position->rt_expire.tv_sec ==
				   current_time.tv_sec) &&
				  (current_position->rt_expire.tv_usec >
				   current_time.tv_usec)) {
				/*
				 * time to expire is unger 1 sec
				 * no action here
				 */
				kLogWrite(L_INFO,
					"%s: time to expire is %ld sec %ld ", __FUNCTION__,
					current_position->rt_expire.tv_sec - current_time.tv_sec,
					current_position->rt_expire.tv_usec - current_time.tv_usec);
			}
			else {
				/******* time expired *******/
				kLogWrite(L_DEBUG,
					"%s: socoketid[%d] is expired",
					__FUNCTION__, current_position->rt_socketid);

				/*
				 * command return
				 */
				kLogWrite(L_DEBUG, "%s: return ack_command", __FUNCTION__);
				recv_ack_return(
					current_position->rt_sockethandle,
					CM_CM_SIG_RECV_ACK,
					current_position->rt_request_num,
					CM_RESULT_SIG_NG_TIMEOUT,
					current_position->rt_socketid,
					(MsgData*)NULL);

				/*
				 * check end
				 */
				kRecvTimerRemove(current_position->rt_socketid);
			}
		}
		else {
			/*
			 * found data
			 */
			kLogWrite(L_DEBUG,
				 "%s: found data[%100.100s] for socketid[%d] in timeout loop",
				 __FUNCTION__, data, current_position->rt_socketid);

			/*
			 * command return
			 */
			recv_ack_return(current_position->rt_sockethandle,
					CM_CM_SIG_RECV_ACK,
					current_position->rt_request_num,
					CM_RESULT_OK,
					msg_data.msg_socketid,
					(MsgData*)&msg_data);

			/*
			 * check end
			 */
			kRecvTimerRemove(current_position->rt_socketid);

		}
	}

	return(RETURN_OK);
}



/* remove */
static int
kRecvTimerRemove(short socketid)
{
	RecvTimeout *current_position  = NULL; /* for search loop */
	RecvTimeout *previous_position = NULL; /* for search loop */

	kLogWrite(L_DEBUG, "kRecvTimerRemove: start -----------------------");

	/*
	 * argument NULL check
	 */
	if(socketid < 0) {
		kLogWrite(L_INFO,
			"%s: invalid socketid[%d]. abort", __FUNCTION__, socketid);
		return(RETURN_NG);
	}

	/*
	 * search matched-data
	 */
	current_position = g_rt_start_ptr;

	for( ; ; ) {
		if(current_position->rt_socketid == socketid) {
			/*
			 * now remove current_position
			 */
			if(previous_position) {
				previous_position->rt_next =
					current_position->rt_next;

				g_rt_last_ptr = previous_position;

				kLogWrite(L_DEBUG,
					"%s: the data is not first one", __FUNCTION__);

			} else {
				/* matched data was first one */

				/* so now, second data will be start point */
				g_rt_start_ptr = current_position->rt_next;

				kLogWrite(L_DEBUG, "%s: the data is first one", __FUNCTION__);
			}

			/* free */
			free(current_position);
			kLogWrite(L_DEBUG,
				"%s: clear tha data for socketid[%d]", __FUNCTION__, socketid);

			/* g_rt_datanum -- */
			g_rt_num --;

			return(RETURN_OK);

		}

		if(!(current_position->rt_next)) {
			kLogWrite(L_INFO,
				"%s: no data for socketid[%d]", __FUNCTION__, socketid);
			return(RETURN_NG);
		}

		previous_position	= current_position;
		current_position	= current_position->rt_next;
	}

	return(RETURN_OK);
}
