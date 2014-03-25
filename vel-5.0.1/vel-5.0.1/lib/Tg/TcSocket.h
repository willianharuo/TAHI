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
#ifndef __TcSocket_h__
#define __TcSocket_h__	1
#include <sys/times.h>
#include "CmSocket.h"
#include "TgServer.h"
#include "TcAgent.h"
typedef u_int64_t uint64_t;

struct TcAgent;
struct TgServer;

struct TcSocket:public TcAgent {
private:
	int32_t allocated_;
	STR buffer_;
	CmSocket* 	dest_;
	int32_t 	seqno_;
	timeval	stime_;
	timeval	etime_;
	char		recvseq_;
	//
	void timeup(time_t,uint32_t);
	int32_t nextseqno();
	char recvseqno();
	int32_t seqno();
	void printIO(CSTR,int32_t,CSTR);
virtual	void preReceive(int16_t);
virtual	void postReceive(int16_t);
	void preSend(int16_t);
virtual	void postSend(int16_t);
protected:
	int sendPacket();
	// scheduled traffic
	uint32_t	sendcnt_;
	uint32_t	recvcnt_;
	uint32_t	sendlen_;
	uint32_t	recvlen_;
	// result traffic
	uint32_t	sentcnt_;
	uint32_t	recvdcnt_;
	uint64_t	sentlen_;
	uint64_t	recvdlen_;
	uint32_t	sinterval_;
	bool		effectreq_;
	int32_t		regard_;	// regard as received on timeup
	void setStartTime();
	void setEndTime();
	void report(int16_t,int32_t);
public:
	int receivePacket(int);
	TcSocket(int);
	TcSocket(int16_t,TgServer*,CmSocket*,int);
	TcSocket(int16_t,TgServer*,CmSocket*,CmSocket*);
	void setStartTime(struct timeval*);
virtual	~TcSocket();
	void receiver();
	void dest(CmSocket*);
	CmSocket* dest();
	void close();
virtual	int sendtoPeer(CSTR buf,int len)=0;
	void startTimer(time_t,uint32_t);
virtual	void startTimer();
	STR buffer(int32_t);
virtual	int receiveBuffer(STR s,int32_t len);
	int connectIndication();
virtual	int connectAction()=0;
virtual	sockaddr* destSock()=0;
	int sndIndication(const int32_t c,const int32_t l,const uint32_t t);
	int recvEffectIndication();
virtual	int effectAction(int32_t);
	int recvIndication(const int32_t c,const int32_t l);
	int sndrecvIndication(const int32_t c,const int32_t s,const int32_t r,const uint32_t t =0);
	int recvsndIndication(const int32_t c,const int32_t s,const int32_t r);
};
inline void TcSocket::receiver() {
	readAction((agentFunc)&TcSocket::receivePacket);}
inline int32_t TcSocket::nextseqno() {return ++seqno_;}
inline int32_t TcSocket::seqno() {return seqno_;}
inline char TcSocket::recvseqno() {return recvseq_;}
inline void TcSocket::dest(CmSocket* s) {dest_=s;}
inline CmSocket* TcSocket::dest() {return dest_;}
#endif
