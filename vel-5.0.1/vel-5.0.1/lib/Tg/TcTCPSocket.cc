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
#include "CmMain.h"
#include "CmAgent.h"
#include "TcTCPSocket.h"
#include <time.h>

//======================================================================
TcTCPSocket::TcTCPSocket(int r):TcSocket(r){
}

TcTCPSocket::TcTCPSocket(int16_t n,TgServer* t,CmSocket* s,int r) 
						:TcSocket(n,t,s,r){
}

TcTCPSocket::TcTCPSocket(int16_t n,TgServer* t,CmSocket* s,CmSocket* d) 
						:TcSocket(n,t,s,d){
}

TcTCPSocket::~TcTCPSocket() {
}

int TcTCPSocket::connectAction(){
	int ret=socket()->connect(dest());
	if(dbgFlags['e']){
		if(ret!=-1){
			printf("TcTCPSocket::connectAction ");
			socket()->printPeers();
		}
	}
	return ret;
}

int TcTCPSocket::receiveBuffer(STR s,int32_t len) {
	CmSocket* sock=socket();
	if(sock==0) {return -1;}
	int l=sock->recvAll(s,len);
	return l;}

int TcTCPSocket::sendtoPeer(CSTR buf,int len){
	CmSocket* s=socket();
	int ret=s->sendAll(buf,len);
	return ret;
}

void TcTCPSocket::postSend(int16_t req){
	switch(req){
	  case eSnd_: case eConnectSnd_:
		if(sentcnt_<sendcnt_)	{startTimer();}
		else			{report(req,0);}
		break;
	  default:
		break;
	}
}

sockaddr* TcTCPSocket::destSock(){
	return socket()->getsockname()->sockAddr();
}

void TcTCPSocket::postReceive(int16_t req){
	if(recvcnt_*recvlen_==recvdlen_){
		switch(req){
		  case eRecv_:
		  case eSndRecv_:
		  case eConnectSndRecv_:
		  case eListenRecv_:
			if(req==eSndRecv_||req==eConnectSndRecv_){
				report(req,0);
			}
			else if((req==eRecv_)&&effectreq_){
				report(eRecvEffect_,0);
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
		if(sentcnt_>recvdcnt_)	return;
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

void TcTCPSocket::preReceive(int16_t req){
	switch(req){
	  case eRecv_: case eRecvSnd_:
		setStartTime();
		break;
	  default:
		// nop
		break;
	}
}

int TcTCPSocket::effectAction(int32_t diff){
	if(diff){
	}
	else report(eRecvEffect_,0);
	return 0;
}
