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
#include <unistd.h>
#include <errno.h>
#include <sys/param.h>
#include "timeval.h"
#include "Timer.h"
#include "CmDispatch.h"
#include "CmMain.h"
#include "CmAgent.h"
#include "TcSocket.h"
#include "TgFrame.h"
#include "TgAgntLg.h"

//======================================================================
TcSocket::TcSocket(int r):TcAgent(r),dest_(0),
	seqno_(0),recvseq_(0),
	sendcnt_(0),recvcnt_(0),sendlen_(0),recvlen_(0),sentcnt_(0),
	recvdcnt_(0),sentlen_(0),recvdlen_(0),sinterval_(0),
	effectreq_(false),regard_(0){
}

TcSocket::TcSocket(int16_t n,TgServer* t,CmSocket* s,int r) 
						:TcAgent(n,s,t,r),dest_(0),
	seqno_(0),recvseq_(0),
	sendcnt_(0),recvcnt_(0),sendlen_(0),recvlen_(0),sentcnt_(0),
	recvdcnt_(0),sentlen_(0),recvdlen_(0),sinterval_(0),
	effectreq_(false),regard_(0){
	receipt(s->fileDesc());
	timerAction((timerFunc)&TcSocket::timeup);
}

TcSocket::TcSocket(int16_t n,TgServer* t,CmSocket* s,CmSocket* d) 
						:TcAgent(n,s,t,0),dest_(d),
	seqno_(0),recvseq_(0),
	sendcnt_(0),recvcnt_(0),sendlen_(0),recvlen_(0),sentcnt_(0),
	recvdcnt_(0),sentlen_(0),recvdlen_(0),sinterval_(0),
	effectreq_(false),regard_(0){
	receipt(s->fileDesc());
	timerAction((timerFunc)&TcSocket::timeup);
}

TcSocket::~TcSocket() {
}

void TcSocket::printIO(CSTR kwd,int32_t l,CSTR s){
	time_t t=time(0); 
	struct tm* tt=localtime(&t);
	printf( "%02d:%02d:%02d %s:fd=%d length=%d seqno=0x%02x\n", 
	tt->tm_hour,tt->tm_min,tt->tm_sec,kwd,socket()->fileDesc(),l,s[0]&0xff );
}

void TcSocket::report(int16_t r,int32_t ret){
	trafficInfo info;
	switch(r){
	  case eSnd_:
	  case eRecvSnd_:
	  case eConnectSnd_:
	  case eListenRecvSnd_:
	  case eRecvEffect_:
	  case eSndRecv_:
	  case eConnectSndRecv_:
		info.scount(sentcnt_);
		info.rcount(recvdcnt_);
		break;
	  default:
		break;
	}
	info.slen(sentlen_);
	info.rlen(recvdlen_);
	server()->report(r,0,receipt(),ret,&info,stime_,etime_);
	if(r==eRecvEffect_)	effectreq_=false;
}

void TcSocket::setStartTime(){
	stime_=TimerQueue::currentTime();
	etime_=stime_;
}

void TcSocket::setStartTime(timeval* tv){
	stime_= *tv;
	etime_= *tv;
}

void TcSocket::setEndTime(){
	etime_=TimerQueue::currentTime();
}

STR TcSocket::buffer(int32_t l) {
	if(allocated_<l) {
		delete [] buffer_; buffer_=0;
		int32_t n=packetSize<l?l:packetSize;
		buffer_=new char[(allocated_=round8(n))];}
	return buffer_;}

int TcSocket::receiveBuffer(STR,int32_t) {return 0;}

void TcSocket::preReceive(int16_t){return;}

void TcSocket::postReceive(int16_t){return;}

int TcSocket::receivePacket(int){
	dispatch()->stopTimer(this);
	int16_t	req=request();
	if(recvdcnt_==0){ 
		preReceive(req);
	}
	if(recvcnt_*recvlen_==0){
		postReceive(req);
		return 0;
	}
	char buf[packetSize];
	int32_t l=receiveBuffer(buf,recvlen_);
	setEndTime();
	if(l<=0) {
		setStartTime();
		trafficInfo dummy;
		dummy.scount(sentcnt_);
		dummy.rcount(recvdcnt_);
		server()->report(eClosed_,0,receipt(),(l<0)?socket()->syserrno():0,&dummy,stime_,stime_);
		server()->closedSocket(this);
		return -1;
	}
	recvseq_=buf[0];
	if(l>0&&dbgFlags['t']){ printIO("R",l,buf); }
	recvdcnt_++;
	recvdlen_+=l;
	postReceive(req);
	return 0;
}

void TcSocket::timeup(time_t, uint32_t){
	regard_++;
	postReceive(request());
}

void TcSocket::startTimer(time_t sec,uint32_t usec) {
	CmDispatch* disp=dispatch();
	disp->startTimer(sec,usec,this);}

void TcSocket::startTimer() {
	startTimer(sinterval_/1000000,sinterval_%1000000);}

void TcSocket::preSend(int16_t req){
	switch(req){
	  case eSnd_: case eSndRecv_:
		setStartTime();
		break;
	  default:
		// nop
		break;
	}
}

void TcSocket::postSend(int16_t){};

int TcSocket::sendPacket(){
	CmDispatch* disp=dispatch();
	disp->stopTimer(this);
	char	s[packetSize];
	int	req=request();
	if(sentcnt_==0){ 
		preSend(req);
	}
	switch(req){
	  case eSnd_: case eSndRecv_: case eConnectSnd_: case eConnectSndRecv_:
		s[0]=nextseqno()&0xff;
		break;
	  case eRecvSnd_: case eListenRecvSnd_: 
		s[0]=recvseqno();
		break;
	}
	if(sendcnt_*sendlen_!=0){
		if(sendcnt_<=sentcnt_) return 0;
		int r=sendtoPeer(s,sendlen_);
		setEndTime();
		if(r<0) {
			CmSocket* s=socket();
			if(s->retryError()) {postSend(req); return 0;}
			report(req,s->syserrno());
			return -1;}
		++sentcnt_;
		sentlen_+=r;
		if(dbgFlags['t']){ printIO("S",r,s); }
	}
	postSend(req);
	return 0;
}

int TcSocket::connectIndication(){
	setStartTime();
	CmSocket* sock=socket();
	int32_t ret=(connectAction()==-1)?sock->syserrno():0;
	setEndTime();
	if((ret==0)&&(request()!=eConnect_)) return ret;

	int16_t k;
	if(sock->family()==AF_INET){
		k=eV4St_;
	}
	else {
		k=eV6St_;
	}

	union{sockaddr_in i_v4; sockaddr_in6 i_v6;} addr;
	if(ret == 0){
	    if(k==eV4St_)
		memcpy(&addr.i_v4,destSock(),sizeof(sockaddr_in));
	    else
		memcpy(&addr.i_v6,destSock(),sizeof(sockaddr_in6));
	}
	else{
	    memset(&addr,0,(size_t)sizeof(addr));
	}
	server()->report(eConnect_,0,receipt(),ret,k,(sockaddr*)&addr,stime_,etime_);
	return 0;
}

int TcSocket::sndIndication(const int32_t c,const int32_t l,const uint32_t t){
	seqno_=0;
	sentcnt_=0;
	recvdcnt_=0;
	sentlen_=0;
	recvdlen_=0;
	regard_=0;
	sendcnt_=c;
	sendlen_=l;
	sinterval_=t;
	sendPacket();
	return 0;
}

int TcSocket::recvIndication(const int32_t c,const int32_t l){
	effectreq_=false;
	sentcnt_=0;
	recvdcnt_=0;
	sentlen_=0;
	recvdlen_=0;
	recvcnt_=c;
	recvlen_=l;
	return 0;
}

int TcSocket::sndrecvIndication(const int32_t c,const int32_t s,const int32_t r,const uint32_t t){
	recvIndication(c,r);
	sndIndication(c,s,t);
	return 0;
}

int TcSocket::recvsndIndication(const int32_t c,const int32_t s,const int32_t r){
	sentcnt_=0;
	sentlen_=0;
	sendcnt_=c;
	sendlen_=s;
	recvIndication(c,r);
	return 0;
}

int TcSocket::effectAction(int32_t){return 0;}

int TcSocket::recvEffectIndication(){
	effectreq_=true;
	if(etime_==stime_){
		setEndTime();
	}
	effectAction((recvcnt_*recvlen_)-recvdlen_);
	return 0;
}
