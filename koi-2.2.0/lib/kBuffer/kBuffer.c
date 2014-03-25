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
 * $TAHI: koi/lib/kBuffer/kBuffer.c,v 1.25 2007/04/06 01:32:07 akisada Exp $
 *
 * $Id: kBuffer.c,v 1.2 2008/06/03 07:39:55 akisada Exp $
 *
 */

#include <stdio.h>
#include <stdlib.h>
#include <string.h>

#include <koi.h>

#include "kBuffer.h"



static short     g_ld_datanum   = 0;	/* table number */
static LeftData *g_ld_start_ptr = NULL;	/* start point */
static LeftData *g_ld_last_ptr  = NULL;	/* last point */



/*********************
 * Left Data Section
 *
 *********************/
/* init */
bool
kBufferInit(void)
{
	LeftData *current_position = NULL;
	LeftData *next_position    = NULL;
    
#ifdef DBG_BUFFER
	kdbg("/tmp/dbg_buffer.txt", "%s\n", "initializing.");
#endif	/* DBG_BUFFER */
	kLogWrite(L_INFO, "%s(): start", __FUNCTION__);

	if(g_ld_start_ptr) {
		/*
		 * set NULL to start position
		 */
		current_position = g_ld_start_ptr;
		g_ld_start_ptr   = NULL;

		/*
		 * save next position first, and free data
		 * if *next is NULL, end
		 */

		for( ; ; ) {
			next_position = current_position->ld_next;

			/* 
			 * free data
			 */

			free(current_position->ld_data);
			kLogWrite(L_DEBUG,
				"%s: left-data for socoketid [%d] is cleared",
				__FUNCTION__, current_position->ld_socketid);

			/*
			 * go next
			 */

			if(next_position) {
				current_position = next_position;
			} else {
				break;
			}
		}

		kLogWrite(L_INFO, "%s: data all cleared", __FUNCTION__);
	} else {
		kLogWrite(L_INFO, "%s: there is no left-data", __FUNCTION__);
	}

	g_ld_datanum = 0;

	return(true);
}



/* set */
bool
kBufferSet(short socketid, long datalen, unsigned char* data)
{
	LeftData	*new;
	LeftData	*current_position;	/* for search loop */

#ifdef DBG_BUFFER
	kdbg("/tmp/dbg_buffer.txt", "%s\n", "initializing.");
#endif	/* DBG_BUFFER */
	kLogWrite(L_INFO,
		"%s: start--------------------------------", __FUNCTION__);

	/* 
	 * max number check 
	 * g_ld_datanum           this table number 
	 * g_socket_socketid       current number 
	 */
	if(g_ld_datanum == g_socket_socketid) {
		kLogWrite(L_INFO, "%s: current sock_num is %d. "
			"you cannot regist more than %d",
			__FUNCTION__, g_ld_datanum,g_ld_datanum);
		return(false);
	}

	/*
	 * if already exist, invalid
	 * because exixt data means you have to get data first
	 * and merge read-data
	 * you read data, data is removed so that must be not exist
	 */
	current_position = g_ld_start_ptr;
    
	if(g_ld_start_ptr) {
		for( ; ; ) {
			if(current_position->ld_socketid == socketid) {
				/* data exist */
				kLogWrite(L_INFO, "%s: left-data for socketid[%d] is "
					"already exist. abort", __FUNCTION__, socketid);
				return(false);
			}

			if(current_position->ld_next) {
				current_position = current_position->ld_next;
			} else {
				/* data no exist */
				kLogWrite(L_DEBUG, "%s: OK. no data exist for "
					"socketid[%d]", __FUNCTION__, socketid);
				break;
			}
		}
	}
    
	/* 
	 * allocate memory
	 */
	if(!(new = (LeftData *)malloc(sizeof(LeftData)))) {
		kLogWrite(L_ERROR,
			"%s: malloc for new structure fail. abort", __FUNCTION__);
		return(false);
	}

	kLogWrite(L_DEBUG, "%s: allocate memory for structure", __FUNCTION__);
	memset(new, 0, sizeof(*new));

	if(!(new->ld_data = (unsigned char*)malloc(datalen))) {
		kLogWrite(L_ERROR, "%s: malloc for new data fail. abort", __FUNCTION__);
		free(new);
		return(false);
	}

	kLogWrite(L_DEBUG, "%s: allocate memory for data", __FUNCTION__);
	memset(new->ld_data, 0, sizeof(datalen));

	/*
	 * build message
	 */
	new->ld_socketid = socketid;
	new->ld_datalen  = datalen;
	memcpy(new->ld_data, data, datalen);
	kLogWrite(L_DEBUG, "%s: set[%100.100s] size[%ld] g_ld_datanum[%d]",
		__FUNCTION__, new->ld_data, new->ld_datalen, g_ld_datanum + 1);
	g_ld_datanum ++;

	/*
	 * link to list
	 */

	if(g_ld_start_ptr) {
		/* last data's next is new */
		g_ld_last_ptr->ld_next = new;
		kLogWrite(L_INFO, "%s: add data successfully socoketid[%d]",
			__FUNCTION__, socketid);
	} else {
		/* first data */
		g_ld_start_ptr = new;
		kLogWrite(L_INFO, "%s: add data successfully it was first for "
			"socketid[%d]", __FUNCTION__, socketid);
	}

	/* new datas next is NULL */
	new->ld_next = NULL;
    
	/* now, last is new */
	g_ld_last_ptr = new;

	return(true);
}



/*
 * get
 * you've got data, data is cleared
 * that means every socket has only one left-data
 * if there is no match-data, this func sets 0 to datalen 
 */ 
bool
kBufferGet(short socketid, long *datalen, unsigned char *data)
{
	LeftData *current_position  = NULL;	/* for search loop */
	LeftData *previous_position = NULL;	/* for search loop */

#ifdef DBG_BUFFER
	kdbg("/tmp/dbg_buffer.txt", "%s\n", "initializing.");
#endif	/* DBG_BUFFER */
	kLogWrite(L_INFO, "%s: start------------------------------", __FUNCTION__);

	/* 
	 * argument NULL check 
	 */
	if(!datalen) {
		kLogWrite(L_INFO, "%s: datalen is NULL pointer. abort", __FUNCTION__);
		return(false);
	}

	if(!data) {
		kLogWrite(L_INFO, "%s: data is NULL pointer. abort", __FUNCTION__);
		return(false);
	}
    
	if(!g_ld_start_ptr || !g_ld_datanum) {
		kLogWrite(L_INFO, "%s: no left-data in table", __FUNCTION__);
		*datalen = 0;
		return(true);
	}

	/*
	 * search matched-left_data
	 */
	current_position = g_ld_start_ptr;

	for( ; ; ) {
		if(current_position->ld_socketid == socketid) {
			/* found data */
			*datalen = current_position->ld_datalen;
			memcpy(data, current_position->ld_data,
				current_position->ld_datalen);
			kLogWrite(L_DEBUG, "%s: get successfully for socketid[%d]",
				__FUNCTION__, socketid);
	    
			/* 
			 * now remove current_position
			 */
			if(previous_position) {
				previous_position->ld_next
					= current_position->ld_next;
				g_ld_last_ptr = previous_position;

				kLogWrite(L_DEBUG, "%s: the data is not first one",
					__FUNCTION__);
			} else {
				/* matched data was first one */

				/* so now, second data will be start point */
				g_ld_start_ptr = current_position->ld_next;

				kLogWrite(L_DEBUG, "%s: the data is first one", __FUNCTION__);
			}

			/* free */
			free(current_position->ld_data);
			free(current_position);
			kLogWrite(L_DEBUG, "%s: clear tha left-data for "
				"socketid[%d] g_ld_datanum[%d]",
				__FUNCTION__, socketid, g_ld_datanum -1);
	    
			/* g_ld_datanum -- */
			g_ld_datanum --;

			return(true);
		}

		if(current_position->ld_next) {
			previous_position = current_position;
			current_position  = current_position->ld_next;
		} else {
			kLogWrite(L_DEBUG, "%s: no left-data for socketid[%d]",
				__FUNCTION__, socketid);
			*datalen = 0;
			return(true);
		}
	}
    
	return(true);
}
