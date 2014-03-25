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
#include "CmDispatch.h"
#include "Timer.h"
#include "CmMain.h"
#include "CmAgent.h"
#include "TcUDPSocket.h"
#include "TgAgntLg.h"
#include "TgDefine.h"
#include <timeval.h>

//======================================================================
TcUDPSocket::TcUDPSocket(int r):TcSocket(r){
}

TcUDPSocket::TcUDPSocket(int16_t n,TgServer* t,CmSocket* s,int r) 
						:TcSocket(n,t,s,r){
}

TcUDPSocket::TcUDPSocket(int16_t n,TgServer* t,CmSocket* s,CmSocket* d) 
						:TcSocket(n,t,s,d){
	dest(d);
}

TcUDPSocket::~TcUDPSocket() {
}

int TcUDPSocket::connectAction(){
	int rc=0;
	if(dbgFlags['C']) {
		rc=socket()->connect(dest());
		printf("%d=TcUDPSocket::connectAction() %s\n",rc,rc<0?"NG":"OK");}
	else {
		if(dbgFlags['e']){
			printf("TcUDPSocket::connectAction "); socket()->print();}}
        return 0;
}

int TcUDPSocket::receiveBuffer(STR s,int32_t len) {
	int32_t l=0;
	CmSocket* sock=socket();
	if(sock==0) {return -1;}
	CmDgram from(0);
	l=sock->recvfrom(s,len,&from);
	if(l<=0) return l;
	if(dest()==0) {dest(new CmDgram(from.length(),from.sockAddr()));}
	alogHead h(&(TimerQueue::currentTime()),receipt(),eRead_,l,defaultLgBody);
	TgAgentLog lg=TgAgentLog::instance();
	lg.writeHead(&h);
	lg.writeBody(s,defaultLgBody);
	return l;}

int TcUDPSocket::sendtoPeer(CSTR buf,int len){
	CmSocket* s=socket();
	int l=0;
	if(dbgFlags['C']) {
		l=s->send(buf,len);}
	else {
		l=s->sendto(buf,len,dest());}
	if(l>0){
		alogHead h(&(TimerQueue::currentTime()),receipt(),eWrite_,l,defaultLgBody);
		TgAgentLog lg=TgAgentLog::instance();
		lg.writeHead(&h);
		lg.writeBody(buf,defaultLgBody);
	}
	return l;
}

static void nop() {}
void TcUDPSocket::startTimer() {
	if(dbgFlags['R']==0||request()!=eSnd_) {
		TcSocket::startTimer();
		return;}
	for(uint32_t i=0;i<sinterval_;i++) {nop();}
	TcSocket::startTimer(0,0);}


void TcUDPSocket::postSend(int16_t req){
	switch(req){
	  case eSnd_: case eConnectSnd_:
		if(sentcnt_<sendcnt_)	{startTimer();}
		else			{report(req,0);}
		break;
	  case eSndRecv_: case eConnectSndRecv_:
		startTimer();
		break;
	  default:
		break;
	}
}

sockaddr* TcUDPSocket::destSock(){
	return socket()->sockAddr();
}

void TcUDPSocket::postReceive(int16_t req){
	if(recvcnt_==recvdcnt_+regard_){
		switch(req){
		  case eRecv_:
		  case eSndRecv_:
		  case eConnectSndRecv_:
		  case eListenRecv_:
			setEndTime();
			if(req==eSndRecv_||req==eConnectSndRecv_){
				report(req,0);
			}
			break;
		  default:
			break;
		}
	}
	if(sendcnt_<=sentcnt_) return;
	// (recv)+Send
	switch(req){
	  case eSndRecv_:
	  case eConnectSndRecv_:
		// if sent packets before receive by timeout
		// ignore next send.
		if(sentcnt_>recvdcnt_+regard_)	return;
	  case eSnd_:
	  case eConnectSnd_:
	  case eRecvSnd_:
	  case eListenRecvSnd_:
		sendPacket();
		break;
	  default:
		break;
	}
}

void TcUDPSocket::preReceive(int16_t req){
	switch(req){
	  case eRecv_: case eRecvSnd_:
	  case eListenRecv_: case eListenRecvSnd_:
		setStartTime();
		break;
	  default:
		// nop
		break;
	}
}

int TcUDPSocket::effectAction(int32_t){
	report(eRecvEffect_,0);
	return 0;
}
