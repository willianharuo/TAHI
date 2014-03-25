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
 * $TAHI: koi/lib/kIF/kIF.c,v 1.16 2007/04/06 01:32:07 akisada Exp $
 *
 * $Id: kIF.c,v 1.4 2008/12/25 11:44:31 inoue Exp $
 *
 */

#include <stdio.h>
#include <string.h>

#include <sys/types.h>
#include <sys/socket.h>
#include <sys/un.h>	/* for unix domein socket address structure */
#include <net/if.h>	/* for if_nametoindex() */

#include <koi.h>

#include "kIF.h"



/* static global variables */
static IfInfo	g_ii_table[IF_MAXNUMBER];	/* I/F table array */



/**********************************************************************
 * int kIFInit(char *);                                               *
 **********************************************************************/
/* 
 * create if table
 */
bool
kIFInit(char *deffilename)
{
	FILE			*def_fp	= NULL;		/* file pointer for deffile */
	char			one_line[BUFSIZ];	/* for get 1 line */
	char			*each_token = NULL;	/* splited token into here */
	unsigned int	scopeid;			/* return value of ifnametoindex */
	char			tmp_linkname[BUFSIZ];
	char			tmp_devicename[IFNAMSIZ];
	int				record_counter	= 0;
	int				read_line_num	= 0;

	kLogWrite(L_INFO, "%s: start", __FUNCTION__);

	/* open def file */
	if(!(def_fp = fopen(deffilename? deffilename: _PATH_TN_DEF, "r"))) {
		kLogWrite(L_ERROR,
			"%s: cannot open def_file[%s]", __FUNCTION__,
			deffilename? deffilename: _PATH_TN_DEF);
		return(false);
	}

	kLogWrite(L_DEBUG,
		"%s: def_file[%s] open success", __FUNCTION__,
		deffilename? deffilename: _PATH_TN_DEF);

	/* create table and initialize */
	memset(g_ii_table, 0, sizeof(g_ii_table));
	kLogWrite(L_DEBUG, "%s: clear I/F table", __FUNCTION__);

	/* 
	 * parsing line and find THE line
	 */

	/* read 1-line loop */
	for( ; ; ) {
		/* 1-line buf reset */
		memset(one_line, 0, sizeof(one_line));

		/* get 1 line from def file */
		if(fgets(one_line, sizeof(one_line), def_fp) == 0) {

			/* here is last of file. */
			if((strcmp((const char *)g_ii_table[0].ii_linkname, "")) == 0) {
				kLogWrite(L_ERROR,
					"%s: no available I/F in def file. file closed",
					__FUNCTION__);
					  
				fclose(def_fp);
				return(false);

			} else {
				kLogWrite(L_DEBUG,
					"%s: %d I/F registered successfully "
					"and def file closed", __FUNCTION__, record_counter);
				fclose(def_fp);
				return(true);
			}

		}

		read_line_num ++;
		kLogWrite(L_DEBUG, "%s: read line #%d", __FUNCTION__, read_line_num);

		/* split into tokens */
		if(!(each_token = strtok(one_line, IF_DELIMITER))) {
			/* 
			 * one_line has no token. each_token points NULL
			 * goto next line
			 */
			kLogWrite(L_DEBUG,
				"%s: line has no token. goto next...", __FUNCTION__);
			continue;
		}

		/* keep anyway linkname and remove linefeed */
		strcpy(tmp_linkname, each_token);
		if(tmp_linkname[strlen(tmp_linkname) - 1 ] == '\n') {
			tmp_linkname[strlen(tmp_linkname) - 1] = '\0';
		}
	    
		kLogWrite(L_DEBUG,
			"%s: first token [%s]", __FUNCTION__, tmp_linkname);
	    
		/* judge whether first token includs IF_KEYWORD */
		if(strncmp(each_token, IF_KEYWORD, IF_KEYSIZE) != 0) {
			/* don't match */
			kLogWrite(L_DEBUG,
				"%s: line has no keyword. goto next....", __FUNCTION__);
			continue;
		}

		/* match */
		kLogWrite(L_DEBUG,
			"%s: first token match [%s]", __FUNCTION__, IF_KEYWORD);
		
		/* get devicename that must be second token */
		if(!(each_token = strtok(NULL, IF_DELIMITER))) {
			/* there is no second token. go nextline */
			kLogWrite(L_INFO, "%s: no second token", __FUNCTION__);
			continue;
		}
				
		kLogWrite(L_DEBUG, "%s: second token [%s]", __FUNCTION__, each_token);
		
		/* keep anyway devicename */
		strcpy(tmp_devicename, each_token);
		
		/* resolute scopeid */
		if(!(scopeid = if_nametoindex(tmp_devicename))) {
			/* scope id dose not exist. goto next line */
			kLogWrite(L_INFO, "%s: scope_id for [%s] dose not exist",
				__FUNCTION__, tmp_devicename); 
			continue;
		}

		kLogWrite(L_DEBUG, "%s: scope_id for [%s] is [%d]",
			__FUNCTION__, tmp_devicename, scopeid);

		/* 
		 * finally you got the right data set for one 
		 * if data table record 
		 */

		strcpy((char *)g_ii_table[record_counter].ii_linkname,
		       tmp_linkname);
		strcpy((char *)g_ii_table[record_counter].ii_devicename,
		       tmp_devicename);
		g_ii_table[record_counter].ii_scope_id = scopeid;

		kLogWrite(L_INIT,
			"%s: regist success linkname[%s] devicename[%s] scopeid[%ld]",
			__FUNCTION__,
			g_ii_table[record_counter].ii_linkname,
			g_ii_table[record_counter].ii_devicename,
			g_ii_table[record_counter].ii_scope_id);

		record_counter ++;
	}
	
	fclose(def_fp);
	kLogWrite(L_INFO, "%s: def file closed", __FUNCTION__);
	return(true);
}



/* get device name */
const char*
kIFGetDevicenameByLinkname(const unsigned char *linkname)
{
	int	counter;

	if(!linkname) {	/* || ( == NULL)) {*/
		kLogWrite(L_ERROR,
			"%s: linkname/scope_id is NULL pointer. abort", __FUNCTION__);
		return(NULL);
	}

	kLogWrite(L_INFO, "%s: start --------------------", __FUNCTION__);

	for(counter = 0; counter < IF_MAXNUMBER; counter ++) {
		if(strcmp((const char *)g_ii_table[counter].ii_linkname, (const char *)linkname) == 0) {
			kLogWrite(L_DEBUG,
				 "%s: get devicename[%s] sucessefully "
				 "by linkname[%s]", __FUNCTION__,
				 g_ii_table[counter].ii_devicename,
				 g_ii_table[counter].ii_linkname);
			kLogWrite(L_INFO, "%s: found.", __FUNCTION__);

			return((const char *)g_ii_table[counter].ii_devicename);
		}
	}

	kLogWrite(L_ERROR,
		"%s: no avalialble devicename for [%s]", __FUNCTION__, linkname);
	return(NULL);
}
