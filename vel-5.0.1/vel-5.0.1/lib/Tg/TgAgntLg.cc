/*
 * Copyright (C) 1999, 2000, 2001, 2002, 2003, 2004, 2005, 2006, 2007, 2008, 2009
 * Yokogawa Electric Corporation.
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
 */
#include <stdio.h>
#include <stdlib.h>
#include <string.h>
#include <errno.h>
#include "TgDefine.h"
#include "TgAgntLg.h"
#include <time.h>

alogHead::alogHead(
			struct timeval*	t,
			int16_t		n,
			int16_t		k,
			int16_t		tl,
			int16_t		bl
){
	if(t==0)	memset(&tv_,0,sizeof(tv_));
	else		memcpy(&tv_,t,sizeof(tv_));
	keynum_=n;
	kind_=k;
	txtlen_=tl;
	bodylen_=bl;
}

TgAgentLog::TgAgentLog(){}
TgAgentLog::~TgAgentLog() {
}

TgAgentLog& TgAgentLog::instance(){
	if(instance_ == 0) {
		instance_=new TgAgentLog();
	}
	return *instance_;
}

CSTR TgAgentLog::formatTime(STR s,struct timeval* t){
	time_t tt = t->tv_sec;
	struct tm*      lt = ::localtime(&tt);
	sprintf(s,"%02d:%02d:%02d.%04ld",lt->tm_hour,lt->tm_min,lt->tm_sec,
							(t->tv_usec)/1000);
	return s;
}

int TgAgentLog::writeStart(CSTR fname){
	char fn[BUFSIZ];
	char* path = ::getenv(envLogDir);
	if(path==0)	sprintf(fn,"%s.log",fname);
	else		sprintf(fn,"%s/%s.log",path,fname);
	if((fp_=fopen(fn,"w"))==0){
		printf("writeStart: can not open %s\n",fn);
		return errno;
	}
	else {
		return 0;
	}
}

int TgAgentLog::writeEnd(){
	if(fp_){
		fflush(fp_);
		fclose(fp_);
	}
	return 0;
}

int TgAgentLog::writeHead(alogHead* v){
	if(fp_==0)	return 0;
	int len=sizeof(alogHead);
	int ret=fwrite(v,len,1,fp_);
	if(ret<1)	printf("writeHead: can not write.\n");
	return ret;
}

int TgAgentLog::writeBody(CSTR v,int32_t len){
	if(fp_==0)	return 0;
	int ret=fwrite(v,len,1,fp_);
	if(ret<1)	printf("writeBody: can not write.\n");
	return ret;
}

int TgAgentLog::readStart(CSTR fname){
	char fn[BUFSIZ];
	sprintf(fn,"%s",fname);
	if((fp_=fopen(fn,"r"))==0){
		return errno;
	}
	else return 0;
}

int TgAgentLog::readEnd(){
	if(fp_){
		fclose(fp_);
	}
	return 0;
}

int TgAgentLog::readHead(alogHead* h){
	if(fp_==0)	return 0;
	int ret=fread(h,sizeof(alogHead),1,fp_);
	return ret;
}

CSTR TgAgentLog::readBody(int l){
	if(fp_==0)	return 0;
	char buf[BUFSIZ],s[BUFSIZ];
	fread(buf,l,1,fp_);
	static char str[BUFSIZ];
	memset(str,0,BUFSIZ);
	for(int i=0;i<l;i++){
		sprintf(s,"%02x ",buf[i]&0xff);
		strcat(str,s);
	}
	return str;
}

TgAgentLog* TgAgentLog::instance_=0;
