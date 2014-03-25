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
#if !defined(__TgAgentLog_h__)
#define	__TgAgentLog_h__	1
#include <stdio.h>
#include <string.h>
#include <sys/time.h>
#include "CmTypes.h"

struct alogHead {
private:
	struct timeval	tv_;
	int16_t		keynum_;
	int16_t		kind_;
	int16_t		txtlen_;
	int16_t		bodylen_;
public:
	struct timeval*	tv();
	int16_t	keynum() const;
	int16_t	kind() const;
	int16_t	txtlen() const;
	int16_t	bodylen() const;
	void tv(struct timeval*);
	void keynum(int16_t);
	void kind(int16_t);
	void txtlen(int16_t);
	void bodylen(int16_t);
	alogHead(struct timeval* =0,int16_t=0,int16_t=0,int16_t=0,int16_t=0);
};
inline struct timeval* alogHead::tv() {return &tv_;}
inline int16_t alogHead::keynum() const {return keynum_;}
inline int16_t alogHead::kind() const {return kind_;}
inline int16_t alogHead::txtlen() const {return txtlen_;}
inline int16_t alogHead::bodylen() const {return bodylen_;}
inline void alogHead::tv(struct timeval* v){memcpy(&tv_,v,sizeof(tv_));}
inline void alogHead::keynum(int16_t v){keynum_=v;}
inline void alogHead::kind(int16_t v){kind_=v;}
inline void alogHead::txtlen(int16_t v){txtlen_=v;}
inline void alogHead::bodylen(int16_t v){bodylen_=v;}

struct TgAgentLog {
private:
static	TgAgentLog* instance_;
	FILE*		fp_;
	int	cnt_;
public:
	TgAgentLog();
virtual	~TgAgentLog();
static	TgAgentLog& instance();
	int writeStart(CSTR);
	int writeEnd();
	int writeHead(alogHead*);
	int writeBody(CSTR,int32_t);
	int readStart(CSTR);
	int readEnd();
	int readHead(alogHead*);
	CSTR readBody(int);
	CSTR formatTime(STR,struct timeval*);
protected:
};

#endif
