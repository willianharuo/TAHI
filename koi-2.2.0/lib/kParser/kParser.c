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
 * $TAHI: koi/lib/kParser/kParser.c,v 1.30 2007/04/04 06:39:36 akisada Exp $
 *
 * $Id: kParser.c,v 1.6 2010/07/22 13:28:32 velo Exp $
 *
 */

#include <stdio.h>
#include <string.h>
#include <dlfcn.h>
#include <koi.h>

#include "kParser.h"
#include "kParserNULL.h"
#include "kParserSIP.h"
#include "kParserDNS.h"
#include "kParserIKEv2.h"
#include "kParserKINK.h"

/* XXX: change to use list */
static ParserInfo g_pi_table[P_MAXNUMBER];	/* parser array */

static bool kParserClear(void);
static bool kParserSet(int,
	int (*)(long, unsigned char*, unsigned char**, short*),void *handle);



/**********************************************************************
 * return values
 * 	true:  success
 * 	false: error
 **********************************************************************/

bool
kParserInit(void)
{
	memset(g_pi_table, 0, sizeof(g_pi_table));
#ifdef DBG_PARSER
	kdbg("/tmp/dbg_parser.txt", "%s\n", "initializing.");
#endif	/* DBG_PARSER */
	if(!kParserClear()) {
		return(false);
	}

	if(!kParserSet(P_NULL, kParserNULL,NULL)) {
		return(false);
	}

	if(!kParserSet(P_SIP, kParserSIP,NULL)) {
		return(false);
	}

	if(!kParserSet(P_DNS, kParserDNS,NULL)) {
		return(false);
	}

	if(!kParserSet(P_UDPDNS, kParserUDPDNS,NULL)) {
		return(false);
	}

	if(!kParserSet(P_IKEv2, kParserIKEv2,NULL)) {
		return(false);
	}

	if(!kParserSet(P_KINK, kParserKINK,NULL)) {
		return(false);
	}

	return(true);
}



/**********************************************************************
 * return values
 * 	true:  success
 * 	false: error
 **********************************************************************/
bool
kParserGet(int keyword,
	   unsigned char protocol,
	   int (**parser)(long, unsigned char *, unsigned char **, short *))
{
	int  counter = 0;
 
#ifdef DBG_PARSER
	kdbg("/tmp/dbg_parser.txt", "%s\n", "initializing.");
#endif	/* DBG_PARSER */
	kLogWrite(L_INFO, "%s: start", __FUNCTION__);
 
	/* argument NULL check */
	if(!parser) {
		kLogWrite(L_WARNING, "%s: parser is NULL", __FUNCTION__);
		return(false);
	}
 
	/* search */
	for(counter = 0 ; counter < P_MAXNUMBER ; counter ++) {
		if(g_pi_table[counter].pi_peyload_type == keyword) {
			/* parser found */
			*parser = g_pi_table[counter].pi_parser;

			kLogWrite(L_INFO,
				"%s: parser found for [%d]", __FUNCTION__, keyword);

			return(true);
		}
	}
 
	/* not found */
	kLogWrite(L_WARNING, "%s: no parser found for [%d]", __FUNCTION__, keyword);

	return(false);
}



/**********************************************************************
 * return values
 * 	true:  success
 * 	false: error
 **********************************************************************/
static bool
kParserClear(void)
{
	/* loop counter */
	int counter = 0;

#ifdef DBG_PARSER
	kdbg("/tmp/dbg_parser.txt", "%s\n", "initializing.");
#endif	/* DBG_PARSER */

	/* there is no guarantee that member "pi_peyload_type" is NULL */
	/* XXX: why not? I hate this. */
	for(counter = 0; counter < P_MAXNUMBER; counter ++) {
		g_pi_table[counter].pi_peyload_type = -1;
	}

	kLogWrite(L_DEBUG, "%s: parser table all cleared", __FUNCTION__);

	return(true);
}



/**********************************************************************
 * return values
 * 	true:  success
 * 	false: error
 **********************************************************************/
bool
kParserSet(int keyword,
	int(*parser)(long, unsigned char*, unsigned char**, short*),void *attachhandle)
{
	int counter = 0;
	int emp_point = -1;

#ifdef DBG_PARSER
	kdbg("/tmp/dbg_parser.txt", "%s\n", "initializing.");
	kdbg("/tmp/dbg_parser.txt", "keyword: %d\n", keyword);
	kdbg("/tmp/dbg_parser.txt", "parser: %p\n", parser);
#endif	/* DBG_PARSER */

	kLogWrite(L_INFO, "%s: start", __FUNCTION__);

	/* argument NULL check */
	if(!parser) {
		kLogWrite(L_WARNING,
			"%s: pointer[parser] is NULL. abort", __FUNCTION__);
		return(false);
	}

	if(keyword < 1) {
		kLogWrite(L_WARNING,
			"%s: too few value [%d].invalid and abort", __FUNCTION__, keyword);
		return(false);
	}
    
	/* search all array once */
	/* for double registration check */
	/* and search empty point which has youngest number */
	for(counter = 0 ;counter < P_MAXNUMBER; counter ++ ) {
#if 0
#ifdef DBG_PARSER
		kdbg("/tmp/dbg_parser.txt", "counter: %d\n", counter);
		kdbg("/tmp/dbg_parser.txt",
			"g_pi_table[%d].pi_peyload_type: %d\n",
			counter, g_pi_table[counter].pi_peyload_type);
		kdbg("/tmp/dbg_parser.txt", "emp_point: %d\n", emp_point);
#endif	/* DBG_PARSER */
#endif	/* 0 */
		if((g_pi_table[counter].pi_peyload_type == -1) &&
		   (emp_point < 0)) {
			/* refresh emp_point only first time find empty */
			emp_point = counter;
		}
#if 0
#ifdef DBG_PARSER
		kdbg("/tmp/dbg_parser.txt", "emp_point: %d\n", emp_point);
#endif	/* DBG_PARSER */
#endif	/* 0 */
		if(g_pi_table[counter].pi_peyload_type == keyword) {
			kLogWrite(L_WARNING, "%s: already parser for [%d] registered",
				__FUNCTION__, keyword);

			return(false);
		}
	}
    
	/* no space for regist */
	if(emp_point < 0) {
		kLogWrite(L_WARNING,
			"%s: parser table is full. can't regist", __FUNCTION__);
		return(false);
	} else {
		/* copy keyword and parser */
		g_pi_table[emp_point].pi_peyload_type = keyword;
		g_pi_table[emp_point].pi_parser = parser;
		g_pi_table[emp_point].pi_attachhandle = attachhandle;
		kLogWrite(L_PARSE,
			"%s: regist parser for [%d] complete", __FUNCTION__, keyword);
	}

	return(true);
}

bool
kParserSet2(int keyword, char *parsername,char *modulepath)
{
	int(*parser)(long, unsigned char*, unsigned char**, short*);
	void *attachhandle;

	/* load module */
	if( !(attachhandle = dlopen(modulepath,RTLD_NOW)) ){
		kLogWrite(L_ERROR, "%s: dlopen fail. %s", __FUNCTION__, dlerror());
		return(false);
	}
	else{
		/* find parser function */
		if( !(parser = dlsym(attachhandle,parsername)) ){
			kLogWrite(L_ERROR, "%s: dlsym fail. %s", __FUNCTION__, dlerror());
			return(false);
		}
		else{
			if( !kParserSet(keyword, parser, attachhandle) ){
			  return(false);
			}
		}
	}
	return(true);
}

bool
kParserDelete(int keyword)
{
	int  counter = 0;
	for(counter = 0 ; counter < P_MAXNUMBER ; counter ++) {
		if(g_pi_table[counter].pi_peyload_type == keyword) {
			if(g_pi_table[counter].pi_attachhandle)
				dlclose(g_pi_table[counter].pi_attachhandle);
			g_pi_table[counter].pi_peyload_type = -1;
			g_pi_table[counter].pi_attachhandle=NULL;
			g_pi_table[counter].pi_parser = NULL;
			return(true);
		}
	}
	return(false);
}

