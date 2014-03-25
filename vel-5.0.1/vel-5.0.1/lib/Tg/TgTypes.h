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
#ifndef __TgTypes_h__
#define __TgTypes_h__   1
#include <sys/types.h>
#include <netinet/in.h>
#include "CmTypes.h"
enum eRequest {
	eStart_		=0x0100,	// (0) session start
	eOpen_		=0x0001,	// (1) release socket
	eListen_	=0x0002,	// (2) release socket + listen
	eAccepted_	=0x0020,	// (2') accepted
	eConnect_	=0x0003,	// (3) connect
	eSnd_		=0x0004,	// (4) send
	eRecv_		=0x0005,	// (5) receive
	eRecvEffect_	=0x0050,	// (5') received?
	eSndRecv_	=0x0006,	// (6) send + receive
	eRecvSnd_	=0x0007,	// (7) receive + send
	eConnectSnd_	=0x0008,	// (8) connect + send
	eConnectSndRecv_=0x0009,	// (9) connect + send + receive
	eListenRecv_	=0x0010,	//(10) listen + receive
	eListenRecvSnd_	=0x0011,	//(11) listen + receive + send 
	eClose_		=0x0012,	//(12) close
	eClosed_	=0x0015,	//(12') closed
	eCmdExec_	=0x0013,	//(13) command execute 
	eCmdCancel_	=0x0014,	//(14) command cancel
	eResponse_      =0x8000,        // Response indicator
	eMask_		=0x7fff		// Request Mask
};
enum eConnKind { 
	eVUnknown_	=0x7fff,
	eV4St_		=0x0001,
	eV4Dg_		=0x0002,
	eV6St_		=0x0003,
	eV6Dg_		=0x0004
};

enum eLogKind {eRead_,eWrite_};

#define LogKind(k)   ((k==eRead_)?"R":(k==eWrite_)?"S":"?")

struct tcpHead {
private:
	uint16_t request_;
	uint16_t length_;
	uint16_t reqno_;
	uint16_t receipt_;
	int32_t	result_;
public:
	uint16_t request() const;
	uint16_t length() const;
	uint16_t reqno() const;
	uint16_t receipt() const;
	int32_t result() const;
	void request(uint16_t);
	void length(uint16_t);
	void reqno(uint16_t);
	void receipt(uint16_t);
	void result(int32_t);
	tcpHead(uint16_t=0,uint16_t=0,int32_t=0);
};
inline uint16_t	tcpHead::request() const {return ntohs(request_);}
inline uint16_t	tcpHead::length() const {return ntohs(length_);}
inline uint16_t	tcpHead::reqno() const {return ntohs(reqno_);}
inline uint16_t	tcpHead::receipt() const {return ntohs(receipt_);}
inline int32_t	tcpHead::result() const {return ntohl(result_);}
inline void tcpHead::request(uint16_t v) {request_=htons(v);}
inline void tcpHead::length(uint16_t v) {length_=htons(v);}
inline void tcpHead::reqno(uint16_t v) {reqno_=htons(v);}
inline void tcpHead::receipt(uint16_t v) {receipt_=htons(v);}
inline void tcpHead::result(int32_t v) {result_=htonl(v);}

inline tcpHead::tcpHead(uint16_t r,uint16_t rn,int32_t rc):request_(htons(r)),length_(0),reqno_(htons(rn)),receipt_(htons(rc)),result_(0) {};
#endif
