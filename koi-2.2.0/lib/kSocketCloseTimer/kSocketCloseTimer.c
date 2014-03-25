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
 * $TAHI: koi/lib/kSocketCloseTimer/kSocketCloseTimer.c,v 1.14 2007/04/04 06:39:36 akisada Exp $
 *
 * $Id: kSocketCloseTimer.c,v 1.2 2008/06/03 07:39:57 akisada Exp $
 *
 */

#include <stdio.h>
#include <string.h>
#include <koi.h>

#include "kSocketCloseTimer.h"

static int kCloseTimerRemove(short);

SocketCloseTable g_t_socket_close_table[T_SCT_MAXNUM]; /* socket close table */
int		 g_t_current_socket_close_table_num = 0;

/* init socket close table */
int
kCloseTimerInit(void)
{
	int counter;

	/* 
	 * set all 0
	 */
	memset(g_t_socket_close_table, 0,
	       (sizeof(SocketCloseTable) * T_SCT_MAXNUM ));
    
	/* 
	 * there is no guarantee that member "sct_socketid" is 0
	 */
	for(counter = 0; counter < T_SCT_MAXNUM ; counter ++) {
		g_t_socket_close_table[counter].sct_socketid = T_SCT_INIT;
	}

	/* 
	 * number set 0
	 */
	g_t_current_socket_close_table_num = 0;

	kLogWrite(L_INFO, "%s: socket close table initialized", __FUNCTION__);
   
	return(RETURN_OK);
}

/* set to table */
int
kCloseTimerSet(short socketid, int sec)
{
	struct timeval	set_time;
	int		loop;
	int		vacant_point=-1;

	/* 
	 * socket id check
	 */
	if(socketid < 0) {
		kLogWrite(L_WARNING,
			"%s: invalid socketid [%d]. abort", __FUNCTION__, socketid);
		return(RETURN_NG);
	}
   
	/* 
	 * max check
	 */
	if(g_t_current_socket_close_table_num == T_SCT_MAXNUM) {
		kLogWrite(L_WARNING, "%s: table limit %d. abort",
			__FUNCTION__, g_t_current_socket_close_table_num);
		return(RETURN_NG);
	}

	kLogWrite(L_INFO, "%s: start---------------------------", __FUNCTION__);

	/*
	 * get current time
	 */
	gettimeofday(&set_time, NULL);

	/*
	 * double regist protection 
	 * and seve first vacant space for regist
	 */
	for(loop = 0; loop < T_SCT_MAXNUM; loop ++) {

		if(g_t_socket_close_table[loop].sct_socketid == socketid) {
			kLogWrite(L_INFO,
				"%s: already registed socketid[%d].abort",
				__FUNCTION__, socketid);
			return(RETURN_NG);
		}
	
		/* saving first vacant space */
		if(vacant_point < 0) {
			if(g_t_socket_close_table[loop].sct_socketid == T_SCT_INIT) {
				vacant_point = loop;
			}
		}
	}

	if(vacant_point == -1) {
		kLogWrite(L_WARNING, "%s: anyway no space", __FUNCTION__);
		return(RETURN_NG);
	}

	/*
	 * regist to vacant space
	 */
	set_time.tv_sec = set_time.tv_sec + sec;
	g_t_socket_close_table[vacant_point].sct_socketid = socketid;
	g_t_socket_close_table[vacant_point].sct_expire = set_time;
	kLogWrite(L_DEBUG, "%s: registed socketid[%d] time to go[%d sec]",
		__FUNCTION__, socketid, sec);
    
	/* 
	 * increment table num
	 */
	g_t_current_socket_close_table_num ++;
	kLogWrite(L_INFO, "%s: so now table num is [%d]",
		__FUNCTION__, g_t_current_socket_close_table_num);
    
	return(RETURN_OK);
}



/* close socket timer */
int
kCloseTimerProc(void)
{
	struct timeval	current_time;
	int		loop     = 0;
	short		socketid = 0;

	memset(&current_time, 0, sizeof(current_time));

	/* get current time */
	gettimeofday(&current_time, NULL);

	/* check the socket close table */
	/* if match, kSocketClose() and kCloseTimerRemov() */

	for(loop = 0; loop < T_SCT_MAXNUM; loop ++) {
		socketid = g_t_socket_close_table[loop].sct_socketid;
		if(socketid == T_SCT_INIT) {
			continue;
		}

		/* socketid != T_SCT_INIT */

		if(g_t_socket_close_table[loop].sct_expire.tv_sec > 
		    current_time.tv_sec) {
		
			/* time to expire is over 1 sec */
			continue;
		} else if((g_t_socket_close_table[loop].sct_expire.tv_sec ==
			  current_time.tv_sec) && 
			 (g_t_socket_close_table[loop].sct_expire.tv_usec >
			  current_time.tv_usec)){
		
			/* time to expire is under 1sec */
			continue;
		}

		/* 
		 * timer expired
		 */
		kLogWrite(L_DEBUG,
			"%s: close_timer expired socketid[%d]", __FUNCTION__, socketid);
		
		/* kSocketClose() */
		if((kSocketClose(socketid)) < 0) {
			kLogWrite(L_INFO,
				"%s: kSocketClose() sometihg error", __FUNCTION__);
		}
		
		/* kCloseTimerRemove() */
		if((kCloseTimerRemove(socketid)) < 0) {
			kLogWrite(L_INFO, "%s: kCloseTimerRemove() sometihg error",
				__FUNCTION__);
		}
	}

	return(RETURN_OK);
}



/* remove from table */
static int
kCloseTimerRemove(short socketid)
{
	int	loop;

	/* 
	 * socket id check
	 */
	if(socketid < 0) {
		kLogWrite(L_WARNING,
			"%s: invalid socketid [%d]", __FUNCTION__, socketid);
		return(RETURN_NG);
	}

	/* 
	 * num check
	 */
	if(!g_t_current_socket_close_table_num) {
		kLogWrite(L_WARNING, "%s: no socket registerd now", __FUNCTION__);
		return(RETURN_NG);
	}

	kLogWrite(L_DEBUG, "%s: start---------------------------", __FUNCTION__);

	/*
	 * search and reset
	 */
	for(loop=0; loop < T_SCT_MAXNUM; loop ++) {
		if(g_t_socket_close_table[loop].sct_socketid == socketid) {

			/* clear */
			g_t_socket_close_table[loop].sct_socketid = T_SCT_INIT;

			kLogWrite(L_DEBUG, "%s: removed socketid[%d] from close_table",
				__FUNCTION__, socketid);
			break;
		}
	}

	if(loop == T_SCT_MAXNUM) {
		kLogWrite(L_WARNING,
			"%s: socketid[%d] no match. abort", __FUNCTION__, socketid);
		return(RETURN_NG);
	}
    
	/* 
	 * decrement num
	 */
	g_t_current_socket_close_table_num--;
	kLogWrite(L_INFO, "%s: so now table num is [%d]",
		__FUNCTION__, g_t_current_socket_close_table_num);

	return(RETURN_OK);
}
