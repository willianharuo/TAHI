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
#include "TgFrame.h"
//======================================================================
TgFrame::TgFrame():allocated_(0),length_(0),buffer_(0) {
}

TgFrame::TgFrame(uint32_t l,CSTR s):allocated_(0),length_(l),buffer_((STR)s) {
	if(buffer_==0&&l>0) {
		buffer_=new char[allocated_=l];
	}
	pos_=buffer_;
}

TgFrame::~TgFrame() {
	if(allocated_!=0) {
		delete [] buffer_; allocated_=0;}
	buffer_=0;
}

CSTR TgFrame::buffer(uint32_t n){
	uint32_t l=length();
	if(n>l) {abort();}
	if(buffer_==0&&l>0) {
		buffer_=new char[allocated_=l];
		pos_=buffer_;
	}
	return buffer_+n;
}

void TgFrame::encode(void* v,int32_t sz){
	memcpy(pos_,v,sz);
	pos_+=sz;
}

void TgFrame::encode(int16_t v){
	int16_t tmp=htons(v);
	encode(&tmp,sizeof(tmp));
}

void TgFrame::encode(uint32_t v){
	uint32_t tmp=htonl(v);
	encode(&tmp,sizeof(tmp));
}

void TgFrame::encode(int32_t v){
	int32_t tmp=htonl(v);
	encode(&tmp,sizeof(tmp));
}

void TgFrame::encode(sockaddr_in& v){
	encode(&v,sizeof(v));
}

void TgFrame::encode(sockaddr_in6& v){
	encode(&v,sizeof(v));
}

void TgFrame::encode(timeval& v){
	timeval tmp;
	tmp.tv_sec=htonl(v.tv_sec);
	tmp.tv_usec=htonl(v.tv_usec);
	encode(&tmp,sizeof(tmp));
}

void TgFrame::encode(trafficInfo* v){
	encode(v->scount());
	encode(v->slen());
	encode(v->rcount());
	encode(v->rlen());
}
void TgFrame::decode(void* v,int16_t sz){
	memcpy(v,pos_,sz);
	pos_+=sz;
}

void TgFrame::decode(int16_t* v){
	static int16_t tmp;
	decode(&tmp,sizeof(tmp));
	*v=htons(tmp);
}

void TgFrame::decode(uint32_t* v){
	static uint32_t tmp;
	decode(&tmp,sizeof(tmp));
	*v=htonl(tmp);
}

void TgFrame::decode(int32_t* v){
	static int32_t tmp;
	decode(&tmp,sizeof(tmp));
	*v=htonl(tmp);
}

void TgFrame::decode(sockaddr_in* v){
	decode(v,sizeof(*v));
}

void TgFrame::decode(sockaddr_in6* v){
	decode(v,sizeof(*v));
}

void TgFrame::decode(timeval* v){
	timeval tmp;
	decode(&tmp,sizeof(tmp));
	v->tv_sec=ntohl(tmp.tv_sec);
	v->tv_usec=ntohl(tmp.tv_usec);
}

void TgFrame::decode(trafficInfo* v){
	uint32_t tmp=0;
	decode(&tmp);
	v->scount(tmp);
	decode(&tmp);
	v->slen(tmp);
	decode(&tmp);
	v->rcount(tmp);
	decode(&tmp);
	v->rlen(tmp);
}

