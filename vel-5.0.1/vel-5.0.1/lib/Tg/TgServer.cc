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
#include <errno.h>
#include <unistd.h>
#include "timeval.h"
#include "Timer.h"
#include "CmMain.h"
#include "TgServer.h"
#include "TgTypes.h"
#include "TcAccept.h"
#include "TcSocket.h"
#include "TcTCPSocket.h"
#include "TcUDPSocket.h"
#include "TgFrame.h"
#include "TcAgent.h"
#include "TgAgntLg.h"

struct CmSocket;
struct TcAgentSet;
struct TgFrame;
struct TgAgentLog;

void TgServer::connectionLost(CmSocket*){
	TgAgentLog::instance().writeEnd();
	socket()->close();
	delete this;
}
////////////////////////////////////////////////////////////////////////
//	access methods for TcAgentSet
////////////////////////////////////////////////////////////////////////
TcAgentSet& TgServer::agentSet(){
	if(agentSet_==0){agentSet_=new TcAgentSet(defaultTcSocket);}
	return *agentSet_;
}

TcAgent* TgServer::addAgent(TcAgent* v){
	if(v!=0){
		TcAgentSet& s=agentSet();
		return (TcAgent*)s.add(v);
	}
	return 0;
}

TcAgent* TgServer::removeAgent(TcAgent* v){
	if(v!=0){
		TcAgentSet& s=agentSet();
		return (TcAgent*)s.remove(v);
	}
	return 0;
}

TcAgent* TgServer::findAgent(){
	TcAgentSet& s=agentSet();
	TcAgent tmp(header().receipt());
	return (TcAgent*)s.find(&tmp);
}

TcAgent* TgServer::findAgent(int v){
	TcAgentSet& s=agentSet();
	TcAgent tmp(v);
	return (TcAgent*)s.find(&tmp);
}

////////////////////////////////////////////////////////////////////////
//	
////////////////////////////////////////////////////////////////////////
TgServer::TgServer(CmSocket* s):TgInterface(s),agentSet_(0) {
	if(dbgFlags['E']){
		cmdproxy_ = new TeClient(this);
	}
	else{
		cmdproxy_ = 0;
	}
}

TgServer::~TgServer() {
	TcAgentSet& s=agentSet();
	s.deleteContents();
	if(cmdproxy_)	delete cmdproxy_;
}

void TgServer::setStartTime(){
	timeval current=TimerQueue::currentTime();
	setStartTime(&current);
}

void TgServer::setStartTime(const struct timeval* tv){
	memcpy(&stime_,tv,sizeof(stime_));
	memset(&etime_,0,sizeof(etime_));
}

void TgServer::setEndTime(){
	timeval current=TimerQueue::currentTime();
	setEndTime(&current);
}

void TgServer::setEndTime(const struct timeval* tv){
	memcpy(&etime_,tv,sizeof(etime_));
}

int TgServer::report(int16_t n,int16_t rn,int rc,int32_t v,int32_t l,CSTR s){
	return TgInterface::response(n,rn,rc,v,l,s);
}

int TgServer::report(	int16_t n,	// request kind
			int16_t rn,	// request no
			int rc,		// receipt no
			int32_t v,	// result value
			int16_t k,	// v4 or v6
			sockaddr* addr,
			struct timeval& s,
			struct timeval& e
){
	timeval delta=EPOCHTIMEVAL;
	if(logLevel==1){
		if(s<e) {delta=e-s;}
		printf("%6ld.%06lu : %s-%s\n", 
			delta.tv_sec,delta.tv_usec,
			(n!=eAccepted_)?"response":"report",requestName(n));
	}
	int sz=(k==eV4St_)?sizeof(sockaddr_in):sizeof(sockaddr_in6);
	int32_t l=((n!=eAccepted_)?2*sizeof(struct timeval):0)+(4+sz);
	TgFrame	f(l);
	f.encode(k);
	int16_t tmp=0;	// filler
	f.encode(tmp);
	f.encode(addr,sz);
	if(n!=eAccepted_){
		f.encode(s);
		f.encode(e);
		return TgInterface::response(n,rn,rc,v,f.length(),f.buffer(0));
	}
	else {
		return TgInterface::report(n,rn,rc,v,f.length(),f.buffer(0));
	}
}

int TgServer::report(	int16_t n,	// request kind
			int16_t rn,	// request no
			int rc,		// receipt no
			int32_t v,	// result value
			trafficInfo* i,
			struct timeval& s,
			struct timeval& e
){
	timeval delta=EPOCHTIMEVAL;
	if(logLevel==1){
		if(s<e) {delta=e-s;}
		printf("%6ld.%06lu : %s-%s sc=%d rc=%d\n", 
			delta.tv_sec,delta.tv_usec,
			(n!=eClosed_)?"response":"report",requestName(n),
				i->scount(),i->rcount());
	}
	int32_t l=2*sizeof(struct timeval)
			+((n!=eClosed_)?sizeof(trafficInfo):0);
	TgFrame	f(l);
	if(n!=eClosed_){
		f.encode(i);
		f.encode(s);
		f.encode(e);
		return TgInterface::response(n,rn,rc,v,f.length(),f.buffer(0));
	}
	else {
		f.encode(s);
		f.encode(e);
		return TgInterface::report(n,rn,rc,v,f.length(),f.buffer(0));
	}
}

int TgServer::response(int16_t n,int16_t rn,int16_t rc,int32_t v,int32_t l,CSTR s){
	TgFrame	f(l+2*sizeof(struct timeval));
	f.encode((void*)s,l);
	f.encode(stime_);
	f.encode(etime_);
	timeval delta=EPOCHTIMEVAL;
	if(logLevel==1){
		if(stime_<etime_) {delta=etime_-stime_;}
		printf("%6ld.%06lu : %s-%s\n", 
			delta.tv_sec,delta.tv_usec,"response",requestName(n));
	}
	return TgInterface::response(n,rn,rc,v,f.length(),f.buffer(0));
}

int TgServer::myResponse(int32_t v,int32_t l,CSTR s){
	tcpHead h=header();
	return response(h.request(),h.reqno(),h.receipt(),v,l,s);
}

TcSocket* TgServer::makeSocket(){
	CmSocket *src =0,*dest =0;
	int16_t k=connKind();
	TgFrame f(header().length(),buffer(0));
	int16_t tmp=0;
	f.decode(&k);
	f.decode(&tmp);
	sockaddr_in s4,d4;
	sockaddr_in6 s6,d6;
	switch(k){
	  case eV4St_: 
		f.decode(&s4);
		f.decode(&d4);
		src=new CmStream(s4);
		dest=new CmStream(d4);
		break;
	  case eV6St_:
		f.decode(&s6);
		f.decode(&d6);
		src=new CmStream(s6);
		dest=new CmStream(d6);
		break;
	  case eV4Dg_: 
		f.decode(&s4);
		f.decode(&d4);
		src=new CmDgram(s4);
		dest=new CmDgram(d4);
		break;
	  case eV6Dg_:
		f.decode(&s6);
		f.decode(&d6);
		src=new CmDgram(s6);
		dest=new CmDgram(d6);
		break;
	  default:
		break;
	}
	if(src==0||dest==0) return 0;
	if(src->bind()==-1) return 0;
	TcSocket* sockets=0;
	if(k==eV4St_||k==eV6St_){
		sockets=new TcTCPSocket(header().request(),this,src,dest);
	}
	else if(k==eV4Dg_||k==eV6Dg_){
		sockets=new TcUDPSocket(header().request(),this,src,dest);
	}
	if(sockets==0)	return sockets;	
	addAgent(sockets);
	sockets->receiver();
	if(dbgFlags['e']){printf("TgServer::makeSocket "); sockets->print();}
	return sockets;
}

TcAccept* TgServer::makeAccepter(trafficInfo* i){
	CmSocket *src =0;
	int16_t k=connKind();
	TgFrame f(header().length(),buffer(0));
	int16_t tmp=0;
	f.decode(&k);
	f.decode(&tmp);
	sockaddr_in s4;
	sockaddr_in6 s6;
	switch(k){
	  case eV4St_: 
		f.decode(&s4);
		src=new CmStream(s4);
		break;
	  case eV6St_:
		f.decode(&s6);
		src=new CmStream(s6);
		break;
	  case eV4Dg_: 
		f.decode(&s4);
		src=new CmDgram(s4);
		break;
	  case eV6Dg_:
		f.decode(&s6);
		src=new CmDgram(s6);
		break;
	  default:
		break;
	}
	tcpHead h=header();
	if(src->bind()==-1) return 0;
	TcAccept* sockets=new TcAccept(k,h.request(),h.reqno(),src,this);
	if(i!=0){
		sockets->traffic(*i);
	}
	if(sockets->listen()==-1) return 0;
	addAgent(sockets);
	return sockets;
}

trafficInfo& TgServer::getTrafficInfo() {
	static trafficInfo i;
	int16_t len=header().length();
	int16_t ilen=sizeof(i);
	TgFrame f(len,buffer(0));
	memcpy(&i,f.buffer(len-ilen),sizeof(i));
	return i;
}

////////////////////////////////////////////////////////////////////////
//	Traffic Genarate Manager -> Traffic Genarate Agent
////////////////////////////////////////////////////////////////////////
int TgServer::startRequest() {
	setStartTime();
	char senario[BUFSIZ];
	int16_t len=header().length();
	strncpy(senario,buffer(0),len);
	senario[len]='\0';
	TgAgentLog::instance().writeStart(senario);
	setEndTime();
	return response(eStart_,0,0,0);
}

int TgServer::openRequest() {
	setStartTime();
	TcSocket* sockets=makeSocket();
	setEndTime();
	if(sockets==0) return myResponse(errno);
	return response(eOpen_,header().reqno(),sockets->receipt(),0);
}

int TgServer::listenRequest() {
	setStartTime();
	TcAccept* accepter=makeAccepter();
	setEndTime();
	if(accepter==0) return myResponse(errno);
	return response(eListen_,header().reqno(),accepter->receipt(),0);
}

int TgServer::connectRequest() {
	TcAgent* s=findAgent();
	if(s==0) return myResponse(errno);
	s->request(eConnect_);
	s->connectIndication();
	return 0;
}

int TgServer::sndRequest() {
	TcAgent* s=findAgent();
	if(s==0) return myResponse(-1);
	trafficInfo* val=(trafficInfo*)buffer(0);
	s->request(eSnd_);
	s->sndIndication(val->scount(),val->slen(),val->sinterval());
	return 0;}

int TgServer::recvRequest() {
	TcAgent* s=findAgent();
	if(s==0) return myResponse(-1);
	trafficInfo* val=(trafficInfo*)buffer(0);
	s->request(eRecv_);
	setStartTime();
	int32_t	ret=s->recvIndication(val->rcount(),val->rlen());
	setEndTime();
	response(eRecv_,header().reqno(),s->receipt(),ret,0,0);
	return 0;}

int TgServer::recvEffectRequest() {
	TcAgent* s=findAgent();
	if(s==0) return myResponse(-1);
	s->recvEffectIndication();
	return 0;}

int TgServer::sndrecvRequest() {
	TcAgent* s=findAgent();
	if(s==0) return myResponse(-1);
	trafficInfo* val=(trafficInfo*)buffer(0);
	s->request(eSndRecv_);
	s->sndrecvIndication(val->scount(),val->slen(),val->rlen(),val->sinterval());
	return 0;}

int TgServer::recvsndRequest() {
	TcAgent* s=findAgent();
	if(s==0) return myResponse(-1);
	trafficInfo* val=(trafficInfo*)buffer(0);
	s->request(eRecvSnd_);
	setStartTime();
	s->recvsndIndication(val->rcount(),val->slen(),val->rlen());
	setEndTime();
	response(eRecvSnd_,header().reqno(),s->receipt(),0,0,0);
	return 0;}

int TgServer::connectsndRequest() {
	TcAgent* s=findAgent();
	if(s==0) return myResponse(-1);
	s->request(eConnectSnd_);
	int r=s->connectIndication();
	if(r==-1) return myResponse(-1);
	trafficInfo* val=(trafficInfo*)buffer(0);
	s->sndIndication(val->scount(),val->slen(),val->sinterval());
	return 0;}

int TgServer::connectsndrecvRequest() {
	TcAgent* s=findAgent();
	if(s==0) return myResponse(-1);
	s->request(eConnectSndRecv_);
	int r=s->connectIndication();
	if(r==-1) return myResponse(-1);
	trafficInfo* val=(trafficInfo*)buffer(0);
	s->sndrecvIndication(val->scount(),val->slen(),val->rlen(),val->sinterval());
	return 0;}

int TgServer::lietenrecvRequest() {
	trafficInfo i=getTrafficInfo();
	setStartTime();
	TcAccept* accepter=makeAccepter(&i);
	setEndTime();
	if(accepter==0) return myResponse(errno);
	return response(eListenRecv_,header().reqno(),accepter->receipt(),0);
}

int TgServer::listenrecvsndRequest() {
	trafficInfo i=getTrafficInfo();
	setStartTime();
	TcAccept* accepter=makeAccepter(&i);
	setEndTime();
	if(accepter==0) return myResponse(errno);
	return response(eListenRecvSnd_,header().reqno(),accepter->receipt(),0);
}

int TgServer::closeAgntConnection(TcAgent* s){
	removeAgent(s);
	delete s;
	return 0;
}

int TgServer::closeRequest() {
	setStartTime();
	TcAgent* s=findAgent();
	setEndTime();
	if(s==0) return myResponse(-1);
	if(dbgFlags['e']){printf("TgServer::closeRequest "); s->print();}
	closeAgntConnection(s);
	setEndTime();
	myResponse(0);
	return 0;}

int TgServer::closedSocket(TcAgent* s){
	if(dbgFlags['e']){printf("TgServer::closedRequest "); s->print();}
	closeAgntConnection(s);
	return 0;
}

int TgServer::cmdexecRequest(){
	tcpHead h=header();
	char cmd[BUFSIZ];
	int16_t len=h.length();
	strncpy(cmd,buffer(0),len);
	cmd[len]='\0';
	if(cmdproxy_)	cmdproxy_->sendcmdExecIndication(h.reqno(),cmd);
	return 0;
}

int TgServer::cmdcancelRequest(){
	if(cmdproxy_)	cmdproxy_->sendcmdCancelIndication(header().reqno());
	return 0;
}
