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
 * $TAHI: koi/lib/kLog/kLog.c,v 1.33 2007/04/06 01:32:08 akisada Exp $
 *
 * $Id: kLog.c,v 1.4 2008/06/03 07:39:56 akisada Exp $
 *
 */
#include <stdio.h>
#include <string.h>
#include <stdarg.h>
#ifdef USE_SYSLOG
#include <syslog.h>
#endif	/* USE_SYSLOG */
#include <sys/time.h>

#include <koi.h>

#include "kLog.h"

/*
  08/3/18 kIsLogLevel,kLogLevelTxt: create
          default log level: replace L_INFO with L_WARNING
*/

/*
 * static global variables
 */
#ifndef USE_SYSLOG
static FILE	*g_l_filep	= NULL;	/* log file pointer */
#endif	/* USE_SYSLOG */
static int	g_l_level	= L_DEFAULTLEVEL;	/* log level */



#ifdef USE_SYSLOG
/*--------------------------------------------------------------------*
 * bool kLogInit(const char *, int);                                  *
 *--------------------------------------------------------------------*/
bool
kLogInit(const char *ident, int level)
{
	openlog(ident, LOG_CONS | LOG_NDELAY | LOG_PID, LOG_USER);

	kLogWrite(L_INFO, "%s(): start", __FUNCTION__);

	/*
	 * regiester the level
	 * if level is not undefined, level is treat as L_DEFALUTLEVEL
	 */

	if(level) {
		g_l_level = level;
	}

	kLogWrite(L_DEBUG, "%s(): g_l_level: 0x%04x", __FUNCTION__, g_l_level);

	return(true);
}

bool kIsLogLevel(int level)
{
  return (g_l_level & level);
}

char *kLogLevelTxt(int level)
{
  switch(level){
  case L_DATA: return "DATA";
  case L_SOCKET: return "SOCK";
  case L_TIME: return "TIME";
  case L_BUFFER: return "BUFF";
  case L_INIT: return "INIT";
  case L_CMD: return "CMD ";
  case L_PARSE: return "PARS";
  case L_DEBUG: return "DEBG";
  case L_INFO: return "INFO";
  case L_TLS: return "TLS ";
  case L_IO: return "IO  ";
  case L_WARNING: return "WARN";
  case L_ERROR: return "ERR ";
  }
  return "----";
}

/*--------------------------------------------------------------------*
 * bool kLogWrite(int, const char *, ...);                            *
 *--------------------------------------------------------------------*/
bool
kLogWrite(int level, const char *message, ...)
{
        char   str[1024],msg[1024];
	va_list args = NULL;

	if(!(g_l_level & level)) {
		return(false);
	}

	va_start(args, message);
	vsprintf(str,message,args);
	va_end(args);
#if 1 
	sprintf(msg,"%s|%s\n", kLogLevelTxt(level),str);
	vsyslog(LOG_NOTICE, msg, NULL);
#else
        struct tm	  *time_obj;
	struct timeval time_value;
	gettimeofday(&time_value,NULL);
	time_obj = (struct tm*)localtime((const time_t *)&(time_value.tv_sec));
	sprintf(msg,"%02d/%02d %2d:%02d:%02d.%02d|%s|%s\n",
		time_obj->tm_mon + 1,
		time_obj->tm_mday, 
		time_obj->tm_hour,
		time_obj->tm_min, 
		time_obj->tm_sec, 
		(int)(time_value.tv_usec/10000), kLogLevelTxt(level),str);
	printf(msg);
	fflush(stdout);
	fflush(stderr);
#endif
	return(true);
}



/*--------------------------------------------------------------------*
 * void kLogFinalize(void);                                           *
 *--------------------------------------------------------------------*/
void
kLogFinalize(void)
{
	kLogWrite(L_DEBUG, "%s(): start", __FUNCTION__);

	closelog();
}
#else	/* USE_SYSLOG */
bool
kLogInit(const char *filename, int level)
{
	char *name_string = NULL;
	char temp_string[L_FILENAMELEN];	/* temporaly string for log */

	memset(temp_string, 0, sizeof(temp_string));
# ifdef DBG_LOG
	kdbg("/tmp/dbg_log.txt", "%s\n", "initializing.");
# endif	/* DBG_LOG */
	/*
	 * open file selection L_DEFAULTNAME or inputed name
	 */

	name_string = filename? filename: _PATH_KOID_LOG;

	if(!(g_l_filep = fopen(name_string, "a"))) {
		printf("%s: log file fopen() fail\n", __FUNCTION__);
		return(false);
	}

	/*
	 * ready for write to log file
	 */
	kLogWrite(L_DEBUG, "%s:---log file create---", __FUNCTION__);

	kLogWrite(L_DEBUG, "%s: log file [%s]", __FUNCTION__, name_string);

	/*
	 * regiest level
	 * if level is not avaliable, set L_DEFALUTLEVEL
	 */

	if(level) {
		g_l_level = level;

		kLogWrite(L_DEBUG, "%s: set log level %d", __FUNCTION__, g_l_level);
	} else {
		g_l_level = L_DEFAULTLEVEL;

		kLogWrite(L_INFO,
			"%s: set log level DEFAULT %d", __FUNCTION__, L_DEFAULTLEVEL);
	}

	return(true);
}



bool
kLogWrite(int level, char *fmt, ...)
{
	char			msg[L_MSGLEN];			/* msg data */
	struct tm		*time_obj = NULL;		/* current data object */
	char			tmpbuf[L_MSGLEN];		/* temporaly buffer */
	char			level_word[L_LEVELLEN];	/* level string for output */
	struct timeval 	time_value;				/* time value structure */
	va_list ap	= NULL;

	memset(msg, 0, sizeof(msg));
	memset(tmpbuf, 0, sizeof(tmpbuf));
	memset(level_word, 0, sizeof(level_word));
	memset(&time_value, 0, sizeof(time_value));

	/* check the input level for seted level */
	if(!(g_l_level & level)) {
		return(true);
	}

	va_start(ap, fmt);
	vsprintf(tmpbuf, fmt, ap);
	va_end(ap);

# ifdef DBG_LOG
	kdbg("/tmp/dbg_log.txt", "%s\n", "initializing.");
# endif	/* DBG_LOG */

	if(strlen(tmpbuf) > (L_MSGLEN - L_MSGHEADERLEN - 1)) {
		strncpy(tmpbuf, tmpbuf, (L_MSGLEN - L_MSGHEADERLEN - 2));
		printf("%s: too long message to write log down.\n", __FUNCTION__);
	}

	if((level != L_DEBUG)	&&
	   (level != L_INFO)	&&
	   (level != L_WARNING)	&&
	   (level != L_ERROR)) {
		level = L_DEFAULTLEVEL;
	}

	/* generate level word */
	switch(level) {
		case L_DATA:
			memcpy(level_word, L_WDATA, sizeof(level_word));
			break;

		case L_SOCKET:
			memcpy(level_word, L_WSOCKET, sizeof(level_word));
			break;

		case L_TIME:
			memcpy(level_word, L_WTIME, sizeof(level_word));
			break;

		case L_BUFFER:
			memcpy(level_word, L_WBUFFER, sizeof(level_word));
			break;

		case L_INIT:
			memcpy(level_word, L_WINIT, sizeof(level_word));
			break;

		case L_DEBUG:
			memcpy(level_word, L_WDEBUG, sizeof(level_word));
			break;

		case L_INFO:
			memcpy(level_word, L_WINFO, sizeof(level_word));
			break;

		case L_CMD:
			memcpy(level_word, L_WCMD, sizeof(level_word));
			break;

		case L_PARSE:
			memcpy(level_word, L_WPARSE, sizeof(level_word));
			break;

		case L_TLS:
			memcpy(level_word, L_WTLS, sizeof(level_word));
			break;

		case L_IO:
			memcpy(level_word, L_WIO, sizeof(level_word));
			break;

		case L_WARNING:
			memcpy(level_word, L_WWARNING, sizeof(level_word));
			break;

		case L_ERROR:
			memcpy(level_word, L_WERROR, sizeof(level_word));
			break;

		default:
			;
	}

	/* generate current time */
	gettimeofday(&time_value, NULL);

	time_obj = (struct tm *)localtime((const time_t *)&(time_value.tv_sec));

	/*
	 * gen message like
	 * "WARNING 2004 6/23 12:22:33:233456 file open fail."
	 */
	snprintf(msg, sizeof(msg),
		"KOI:%s %02d/%02d/%02d %2d:%02d:%02d.%02ld %s\n",
		level_word,
		time_obj->tm_year - 100,
		time_obj->tm_mon + 1,
		time_obj->tm_mday,
		time_obj->tm_hour,
		time_obj->tm_min,
		time_obj->tm_sec,
		time_value.tv_usec / 10000,
		tmpbuf);

	/* write into file */
	printf(msg);
	fputs(msg, g_l_filep);
	fflush(g_l_filep);	/* write down right now */
	fflush(stdout);	/* write down right now */
	fflush(stderr);	/* write down right now */

	return(true);
}



void
kLogFinalize(void)
{
	kLogWrite(L_DEBUG, "%s: finish", __FUNCTION__);

	fclose(g_l_filep);
}
#endif	/* USE_SYSLOG */
