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
#include "Timer.h"
#include "CmMain.h"
#include "TgServer.h"
#include "TgAgent.h"
#include "TcSocket.h"
#include "TcTCPSocket.h"
#include "TcUDPSocket.h"
#include "TcAccept.h"
#include "TgTypes.h"
#include "TgFrame.h"

struct TgFrame;

TcAccept::TcAccept(int16_t c,int16_t r,int16_t rn,CmSocket* s,TgServer* t)
			:TcAgent(r,s,t,s->fileDesc()),conn_(c),reqno_(rn){}
TcAccept::~TcAccept() {
}

//======================================================================
// STARTING SERVICE
void TcAccept::setStartTime(){
	stime_=TimerQueue::currentTime();
}

int TcAccept::listen(){
	CmSocket* s=socket();
	int rc=-1;
	switch(conn()){
	  case eV4St_: case eV6St_:
		rc=s->listen(SOMAXCONN);
		if(rc<0) return rc;
		s->setReuseAddrOpt();
		readAction((agentFunc)&TcAccept::accept);
		break;
	  case eV4Dg_: case eV6Dg_:
		rc=noaccept();
		break;
	  default:
		break;
	}
	return rc;
}

//======================================================================
// ESTABLISH THE CONNECTION
int TcAccept::accept() {
	setStartTime();
	CmSocket* s=socket()->accept();
	if(s!=0) {
		TcSocket* agent=new TcTCPSocket(request(),server(),s,s->fileDesc());
		makeTcSocket(agent);
		report(agent);
		if(dbgFlags['e']){
			printf("TcAccept::accept "); 
			agent->socket()->printPeers();
		}
	}
	return 0;
}

int TcAccept::noaccept() {
	CmSocket* s=socket();
	if(s!=0) {
		TcSocket* agent=new TcUDPSocket(request(),server(),s,s->fileDesc());
		makeTcSocket(agent);
		if(dbgFlags['e']){
			printf("TcAccept::noaccept "); 
			agent->socket()->print();
		}
	}
	return 0;
}

int TcAccept::makeTcSocket(TcSocket* agent){
	server()->addAgent(agent);
	agent->receiver();
	switch(request()){
	  case eListenRecv_:
		agent->setStartTime(&stime_);
		agent->recvIndication(rcount(),rlen());
		break;
	  case eListenRecvSnd_:
		agent->setStartTime(&stime_);
		agent->recvsndIndication(rcount(),slen(),rlen());
		break;
	  default:
		break;
	}
	return 0;
}

void TcAccept::report(TcSocket* agent){
	CmSocket* sock=agent->socket();
	sockaddr* d;
	int16_t k;
	if(sock->family()==AF_INET){
		k=eV4St_;
	}
	else {
		k=eV6St_;
	}
//	if(conn()==eV4Dg_||conn()==eV6Dg_){
//		d=sock->sockAddr();
//	}
//	else{
		d=sock->getpeername()->sockAddr();
//	}
	struct timeval dummy;
	server()->report(eAccepted_,reqno(),agent->receipt(),0,
						conn(),d,dummy,dummy);
}
