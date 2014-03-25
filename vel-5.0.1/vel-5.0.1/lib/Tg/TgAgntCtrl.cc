/* -*-Mode:C++-*-
 *
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
 *
 * TgAgntCtrl:Agent Control Class
 */

#include "CmSocket.h"
#include "TgTypes.h"
#include "TgInfo.h"
#include "TgAgntCtrl.h"
#include "TgExecThread.h"
#include "TgError.h"
#include "TgDebug.h"
#include <assert.h>

inline CSTR eno2mes(int res) {
	return (res==-1)?"ReceiptNo error":strerror(res);}

// ==================================================================
//	TgAgntCtrlCltn:Agent Control Collection Class
// ==================================================================
implementCmList(_TgAgntCtrlCltn,TgAgntCtrl);

// search by name ----------------------------------------------------
TgAgntCtrl* TgAgntCtrlCltn::findByName(const CmCString& name) const {
	for(uint32_t n=0; n < size(); ++n) {
		TgAgntCtrl* pe=(TgAgntCtrl*)index(n);
		if(name==pe->name())
			return pe;}
	return 0;}

// Check for ready --------------------------------------------------
bool TgAgntCtrlCltn::isAllReady() const {
	for(uint32_t n=0; n < size(); ++n) {
		TgAgntCtrl* pe=(TgAgntCtrl*)index(n);
		if(!pe->isReady())
			return false;}
	return true;}

// ==================================================================
//	TgAgntCtrl:Agent Control Class
// ==================================================================

//  Constructor / Class Factory -------------------------------------
TgAgntCtrl::TgAgntCtrl(const CmCString name,CmSocket* sock):TgClient(sock),TgBaseName(name) {
	ready_=false;}

TgAgntCtrl* TgAgntCtrl::createInstance(const TgInfoHost* host) {
	assert(host!=0);
	if(host->tgaPort()==0) {
		TgError::execError("",host->name(),"TGA","TgAgent for host %s is not defined.", host->name());
		return 0;}
	CmSocket* sock=host->tgaPort()->socket();
	assert(sock!=0);
	return new TgAgntCtrl(host->name(),sock);}

//  Destructor -------------------------------------------------------
TgAgntCtrl::~TgAgntCtrl() {}

// Initialize --------------------------------------------------------
void TgAgntCtrl::initialize(void* s,va_list) {
	dbgTrace(("Agent %s:start\n",this->name()));
	if(start()!=true) {
		TgError::execError("",name(),"TGA","TgAgent startup failed.");
		return;}
	dbgTrace(("Agent %s:hello(%s)\n",this->name(),s));
	CSTR scenario=(CSTR)s;
	sendStartIndication(scenario);}

//  Operation:Open -------------------------------------------------
bool TgAgntCtrl::opOpen(TgExecThread* thread,TgStatement* caller,int32_t call_id,
		const CmSocket* srcSock,const CmSocket* dstSock,int16_t type,bool& waitf) {
	dbgTrace(("Thread %s:open\n",thread->name()));
	int32_t req=TgReqElm::newRequestNo();
	openIndication(req,type,srcSock,dstSock);
	requests_.add(new TgReqElm(TgReqElm::REQ_OPEN,req,thread,caller,call_id,srcSock,type));
	waitf=true;
	return true;}

//  Operation:Listen -----------------------------------------------
bool TgAgntCtrl::opListen(TgExecThread* thread,TgStatement* caller,int32_t call_id,
		const CmSocket* srcSock,int16_t type,bool& waitf) {
	dbgTrace(("Thread %s:listen\n",thread->name()));
	if(type==TgInfoConn::TCP_ && listens_.find(srcSock)!=0) {
		waitf=false;
		return true;}
	int32_t req=TgReqElm::newRequestNo();
	listenIndication(req,type,srcSock);
	requests_.add(new TgReqElm(TgReqElm::REQ_LISTEN,req,thread,caller,call_id,srcSock,type));
	listens_.add(new TgListenElm(TgListenElm::REQ_LISTEN,req,0,srcSock));
	waitf=true;
	return true;}

//  Operation:Connect ----------------------------------------------
bool TgAgntCtrl::opConnect(TgExecThread* thread,TgStatement* caller,int32_t call_id,
		const CmSocket* srcSock,int16_t type,bool& waitf) {
	TgConnElm* ce=connects_.find(srcSock,thread,TgConnElm::OPENED);
	if(ce==0) {
		TgError::execError(thread->name(),name(),"Connect","connect to unopened socket(internal).");
		return false;}
	dbgTrace(("Thread %s:connect(%d)\n",thread->name(),ce->id_sock()));
	connectIndication(ce->id_sock());
	requests_.add(new TgReqElm(TgReqElm::REQ_CONNECT,ce->id_sock(),thread,caller,call_id,srcSock,type));
	waitf=true;
	return true;}

//  Operation:Accept ------------------------------------------------
bool TgAgntCtrl::opAccept(TgExecThread* thread,TgStatement* caller,int32_t call_id,
		const CmSocket* srcSock,const CmSocket* dstSock,int16_t type,bool& waitf) {
	// No operation for UDP
	if(type==TgInfoConn::UDP_) {
		waitf=false;
		return true;}
	TgAcceptElm* ae=accepts_.find(dstSock,srcSock);
	if(ae!=0) {
		connects_.add(new TgConnElm(TgConnElm::CONNECTED,ae->id_sock(),ae->saddr(),thread));
		accepts_.remove(ae);
		delete ae;
		waitf=false;
		return true;}
	TgListenElm* le=listens_.find(srcSock);
	if(le==0) {
		TgError::execError(thread->name(),name(),"Accept","socket is not in listen(internal).");
		return false;}
	requests_.add(new TgReqElm(TgReqElm::REQ_ACCEPT,le->id_req(),thread,caller,call_id,dstSock,type));
	waitf=true;
	return true;}

//  Operation:Send --------------------------------------------------
bool TgAgntCtrl::opSend(TgExecThread* thread,TgStatement* caller,int32_t call_id,
		const CmSocket* srcSock,int16_t type,uint32_t count,uint32_t length,
		uint32_t interval,bool& waitf) {
	TgConnElm* ce=connects_.find(srcSock,thread,TgConnElm::CONNECTED);
	if(ce==0) {
		TgError::execError(thread->name(),name(),"Send","Not connected");
		return false;}
	dbgTrace(("Thread %s:send(%d)\n",thread->name(),ce->id_sock()));
	sndIndication(ce->id_sock(),count,length,interval);
	requests_.add(new TgReqElm(TgReqElm::REQ_SEND,ce->id_sock(),thread,caller,call_id,srcSock,type));
	waitf=true;
	return true;}

//  Operation:Receive -----------------------------------------------
bool TgAgntCtrl::opReceive(TgExecThread* thread,TgStatement* caller,
		int32_t call_id,const CmSocket* srcSock,int16_t type,
		uint32_t count,uint32_t length,bool& waitf) {
	TgConnElm* ce=connects_.find(srcSock,thread,TgConnElm::CONNECTED);
	if(ce==0) {
		TgError::execError(thread->name(),name(),"Receive","Not connected.");
		return false;}
	dbgTrace(("Thread %s:receive(%d)\n",thread->name(),ce->id_sock()));
	recvIndication(ce->id_sock(),count,length);
	requests_.add(new TgReqElm(TgReqElm::REQ_RECV,ce->id_sock(),thread,caller,call_id,srcSock,type));
	waitf=true;
	return true;}

//  Operation:Send - Receive ----------------------------------------
bool TgAgntCtrl::opSendRecv(TgExecThread* thread,TgStatement* caller,
		int32_t call_id,const CmSocket* srcSock,int16_t type,
		uint32_t count,uint32_t length,uint32_t interval,bool& waitf) {
	dbgTrace(("Thread %s:send-rcv\n",thread->name()));
	TgConnElm* ce=connects_.find(srcSock,thread,TgConnElm::CONNECTED);
	if(ce==0) {
		TgError::execError(thread->name(),name(),"SendRcv","Not connected");
		return false;}
	sndRecvIndication(ce->id_sock(),count,length,interval);
	requests_.add(new TgReqElm(TgReqElm::REQ_SENDRECV,ce->id_sock(),thread,caller,call_id,srcSock,type));
	waitf=true;
	return true;}

//  Operation:Receive - Send ----------------------------------------
bool TgAgntCtrl::opRecvSend(TgExecThread* thread,TgStatement* caller,
		int32_t call_id,const CmSocket* srcSock,int16_t type,
		uint32_t count,uint32_t length,uint32_t interval,bool& waitf) {
	dbgTrace(("Thread %s:recv-send\n",thread->name()));
	TgConnElm* ce=connects_.find(srcSock,thread,TgConnElm::CONNECTED);
	if(ce==0) {
		TgError::execError(thread->name(),name(),"RcvSend","Not connected");
		return false;}
	recvSndIndication(ce->id_sock(),count,length,interval);
	requests_.add(new TgReqElm(TgReqElm::REQ_RECVSEND,ce->id_sock(),thread,caller,call_id,srcSock,type));
	waitf=true;
	return true;}

// Operation:Terminate Receiption -----------------------------------
bool TgAgntCtrl::opRecvTerminate(TgExecThread* thread,TgStatement* caller,
		int32_t call_id,const CmSocket* srcSock,int16_t type,bool& waitf) {
	dbgTrace(("Thread %s:recv termiantion\n",thread->name()));
	TgConnElm* ce=connects_.find(srcSock,thread,TgConnElm::CONNECTED);
	if(ce==0) {
		TgError::execError(thread->name(),name(),"RcvSend","receive termination to unopened socket(internal).");
		return false;}
	recvTermIndication(ce->id_sock());
	requests_.add(new TgReqElm(TgReqElm::REQ_RECVTERM,ce->id_sock(),thread,caller,call_id,srcSock,type));
	waitf=true;
	return true;}

//  Operation:Close -------------------------------------------------
bool TgAgntCtrl::opClose(TgExecThread* thread,TgStatement* caller,
		int32_t call_id,const CmSocket* srcSock,int16_t type,bool& waitf) {
	dbgTrace(("Thread %s:close\n",thread->name()));
	TgConnElm* ce=connects_.find(srcSock,thread,TgConnElm::CONNECTED);
	if(ce==0) {			// not-opened / already-closed
		waitf=false;
		return true;}

	dbgTrace(("Thread %s:closing\n",thread->name()));
	ce->setStatus(TgConnElm::CLOSING);
	closeIndication(ce->id_sock());
	requests_.add(new TgReqElm(TgReqElm::REQ_CLOSE,ce->id_sock(),thread,caller,call_id,srcSock,type));
	waitf=true;
	return true;}

// Operation - Execute Subcommand -------------------------------------
bool TgAgntCtrl::opCommand(TgExecThread* thread,TgStatement* caller,
		int32_t call_id,CSTR command,bool& waitf) {
	dbgTrace(("Thread %s:exec command\"%s\"\n",thread->name(),command));
	int32_t id_req=TgReqElm::newRequestNo();
	commandIndication(id_req,command);
	requests_.add(new TgReqElm(TgReqElm::REQ_EXECCMD,id_req,thread,caller,call_id,0,TgInfoConn::TCP_));
	waitf=true;
	return true;}

//  Indication - open -------------------------------------------------
void TgAgntCtrl::openIndication(int16_t requestNo,int16_t type,
		const CmSocket* client,const CmSocket* server) {
	enum eConnKind kind;
	switch((int)client->family()) {
		case AF_INET:{
			sockaddr_in* pcaddr=(sockaddr_in*)(client->sockAddr());
			sockaddr_in* psaddr=(sockaddr_in*)(server->sockAddr());
			kind=(type==TgInfoConn::TCP_?eV4St_:eV4Dg_);
			sendOpenIndication(requestNo,kind,*pcaddr,*psaddr);}
		break;
		case AF_INET6:{
			sockaddr_in6* pcaddr=(sockaddr_in6*)(client->sockAddr());
			sockaddr_in6* psaddr=(sockaddr_in6*)(server->sockAddr());
			kind=(type==TgInfoConn::TCP_?eV6St_:eV6Dg_);
			sendOpenIndication(requestNo,kind,*pcaddr,*psaddr);}
		break;
		default:
			TgError::execError("",name(),"OpenInd","Unknown address family %d (internal)",(int)client->family());
		break;}}

//  Indication - listen -----------------------------------------------
void TgAgntCtrl::listenIndication(int16_t requestNo,int16_t type,const CmSocket* sAddr) {
	enum eConnKind kind;
	switch((int)sAddr->family()) {
		case AF_INET:{
			sockaddr_in* psaddr=(sockaddr_in*)sAddr->sockAddr();
			kind=(type==TgInfoConn::TCP_?eV4St_:eV4Dg_);
			sendListenIndication(requestNo,kind,*psaddr);}
		break;
		case AF_INET6:{
			sockaddr_in6* psaddr=(sockaddr_in6*)sAddr->sockAddr();
			kind=(type==TgInfoConn::TCP_?eV6St_:eV6Dg_);
			sendListenIndication(requestNo,kind,*psaddr);}
		break;
		default:
			TgError::execError("",name(),"ListenInd","Unknown address family %d (internal)",(int)sAddr->family());
		break;}}

//  Indication - connect ----------------------------------------------
void TgAgntCtrl::connectIndication(int16_t id_sock) {sendConnectIndication(id_sock);}

//  Indication - Send -------------------------------------------------
void TgAgntCtrl::sndIndication(int16_t id_sock,uint32_t count,uint32_t length,uint32_t interval) {
	trafficInfo info(count,length,0,length,interval);
	sendSndIndication(id_sock,&info);}

//  Indication - receive ----------------------------------------------
void TgAgntCtrl::recvIndication(int16_t id_sock,uint32_t count,uint32_t length) {
	trafficInfo info(0,length,count,length);
	sendRecvIndication(id_sock,&info);}

//  Indication - send + receive ---------------------------------------
void TgAgntCtrl::sndRecvIndication(int16_t id_sock,uint32_t count,uint32_t length,uint32_t interval) {
	trafficInfo info(count,length,count,length,interval);
	sendSndRecvIndication(id_sock,&info);}

//  Indication - receive + send ---------------------------------------
void TgAgntCtrl::recvSndIndication(int16_t id_sock,uint32_t count,uint32_t length,uint32_t/*interval*/) {
	trafficInfo info(count,length,count,length);
	sendRecvSndIndication(id_sock,&info);}

//  Indication - receive termination ----------------------------------
void TgAgntCtrl::recvTermIndication(int16_t id_sock) {
	sendRecvEffectIndication(id_sock);}

//  Indication - close ------------------------------------------------
void TgAgntCtrl::closeIndication(int16_t id_sock) {
	sendCloseIndication(id_sock);}

// Indication - Execute Subcommand ------------------------------------
void TgAgntCtrl::commandIndication(int16_t id_req,CSTR cmd) {
	sendCmdExecIndication(id_req,cmd);}


// Response - Start ---------------------------------------------------
int TgAgntCtrl::recvStartConfirm(int32_t res) {
	if(res!=0) {
		TgError::execError("",name(),"Agent::startup","Agent[%s] startup error %d <%s>.",name(),res,eno2mes(res));
		return -1;}
//	if(logLevel>=2) {log(re);}
	ready_=true;		// I'm ready.
	return 0;}

// Response - Open ----------------------------------------------------
int TgAgntCtrl::recvOpenConfirm(int16_t id_req,int16_t id_sock,int32_t res) {
	TgReqElm* re=requests_.find(id_req,TgReqElm::REQ_OPEN);
	if(re==0) {
		TgError::execError("",name(),"recvOpenConfirm","Open Confirmation from unexpected socket(internal)");
		return -1;}
	requests_.remove(re);
	if(res==0) {
		if(logLevel>=1) log(re);
		TgConnElm* new_ce=new TgConnElm(TgConnElm::OPENED,id_sock,re->addr(),re->thread());
		connects_.add(new_ce);
		re->complete();}
	else {
		TgError::execError(re->thread()->name(),name(),"recvOpenConfirm","Open Confirmation results error %d <%s>.",res,eno2mes(res));
		re->error(res);}
	delete re;
	return 0;}

// Response - Listen --------------------------------------------------
int TgAgntCtrl::recvListenConfirm(int16_t id_req,int16_t id_sock,int32_t res) {
	TgReqElm* re=requests_.find(id_req,TgReqElm::REQ_LISTEN);
	if(re==0) {
		TgError::execError("",name(),"ListenConf","Listen Confirmation from unrequested socket(internal)");
		return -1;}
	TgListenElm* le=listens_.find(re->addr());
	if(le==0 || le->status()!=TgListenElm::REQ_LISTEN) {
		TgError::execError("",name(),"ListenConf","Unacceptable Listen Confirmation(internal)");
		return -1;}
	requests_.remove(re);
	listens_.remove(le);
	if(res==0) {
		if(logLevel>=1) log(re);
		if(re->type()==TgInfoConn::TCP_) {
			TgListenElm* new_le=new TgListenElm(TgListenElm::LISTEN,id_req,id_sock,re->addr());
			listens_.add(new_le);}
		else {
			TgConnElm* new_cn=new TgConnElm(TgConnElm::CONNECTED,id_sock,le->addr()/*=Server Address */,re->thread());
			connects_.add(new_cn);}
		re->complete();}
	else {
		TgError::execError(re->thread()->name(),name(),"recvListenConfirm","Listen confrimation results error %d <%s>.",res,eno2mes(res));
		re->error(res);}
	delete re;
	delete le;
	return 0;}


// Response - Accept --------------------------------------------------
int TgAgntCtrl::opAcceptedReport(int16_t id_req,int16_t id_sock,int32_t res,const CmSocket* caddr) {
	TgListenElm* le=listens_.find(id_req);
	if(le==0) {
		TgError::execError("",name(),"AcceptReport","Accept Report from unrequested socket(internal)");
		return 0;}

	// 終了コードチェック
	if(res!=0) {
		TgError::execError("",name(),"AcceptedReport","Accept Report results error %d <%s>.",res,eno2mes(res));
		return -1;}
	TgReqElm* re=requests_.find(id_req,TgReqElm::REQ_ACCEPT);
	if(re!=0&&logLevel>=1) {log(re);}
	if(re!=0 && re->addr()->isEqual(caddr)) {
		//re->addr()->print();
		//caddr->print();
		requests_.remove(re);
		if(res==0) {
			TgConnElm* new_cn=new TgConnElm(TgConnElm::CONNECTED,id_sock,le->addr()/*=Server Address */,re->thread());
			connects_.add(new_cn);
			re->complete();}
		else {
			TgError::execError("",name(),"AcceptedReport","Accept Report results error %d <%s>.",res,eno2mes(res));
			re->error(res);}
		delete re;}
	else {
		if(res==0) {
			TgAcceptElm* new_an =new TgAcceptElm(id_sock,caddr,le->addr());
			accepts_.add(new_an);}
		else {
			TgError::execError("",name(),"AcceptedReport","Receive Accept Report with error %d <%s> - ignore",res,eno2mes(res));}}
	return 0;}

int TgAgntCtrl::recvAcceptedReport(int16_t reqId,int16_t id_sock,int32_t res,sockaddr_in& sock) {
	return opAcceptedReport(reqId,id_sock,res,new CmStream(sock));}

int TgAgntCtrl::recvAcceptedReport(int16_t reqId,int16_t id_sock,int32_t res,sockaddr_in6& sock) {
	return opAcceptedReport(reqId,id_sock,res,new CmStream(sock));}

// Response - Connect -------------------------------------------------
int TgAgntCtrl::opConnectConfirm(int16_t id_sock,int32_t res,const CmSocket&) {
	TgReqElm* re=requests_.find(id_sock,TgReqElm::REQ_CONNECT);
	if(re==0) {
		TgError::execError("",name(),"recvConnectConfirm","Connect Confirmation from unexpected socket(internal)");
		return -1;}
	requests_.remove(re);
	if(res==0) {
		if(logLevel>=1) log(re);
		TgConnElm* ce=new TgConnElm(TgConnElm::CONNECTED,id_sock,re->addr(),re->thread());
		connects_.add(ce);
		re->complete();}
	else {
		TgError::execError(re->thread()->name(),name(),"ConnectConfrim","ConnectConfirm results error %d <%s>.",res,eno2mes(res));
		re->error(res);}
	delete re;
	return 0;}

int TgAgntCtrl::recvConnectConfirm(int16_t id_sock,int32_t res,sockaddr_in& raddr) {
	return opConnectConfirm(id_sock,res,CmStream(raddr));}

int TgAgntCtrl::recvConnectConfirm(int16_t id_sock,int32_t res,sockaddr_in6& raddr) {
	return opConnectConfirm(id_sock,res,CmStream(raddr));}

// Response - Send ----------------------------------------------------
int TgAgntCtrl::recvSndConfirm(int16_t id_sock,int32_t res) {
	TgReqElm* re=requests_.find(id_sock,TgReqElm::REQ_SEND);
	if(re==0) {
		TgError::execError("",name(),"SendConfirm","Send Confirmation from unexpected socket(internal)");
		return -1;}
	requests_.remove(re);
	if(res==0) {
		throughput("send",re);
		re->complete();}
	else {
		TgError::execError(re->thread()->name(),name(),"SendConfirm","Send Confrim results error %d <%s>.",res,eno2mes(res));
		re->error(res);}
	delete re;
	return 0;}

// Response - Receive -------------------------------------------------
int TgAgntCtrl::recvRecvConfirm(int16_t id_sock,int32_t res) {
	TgReqElm* re=requests_.find(id_sock,TgReqElm::REQ_RECV);
	if(re==0) {
		TgError::execError("",name(),"SendConf","Receive Confirmation from unexpected socket(internal)");
		return -1;}
	requests_.remove(re);
	if(res==0) {
		if(logLevel>=1) log(re);
		re->complete();}
	else {
		TgError::execError(re->thread()->name(),name(),"SendConf","Send Conform results error %d <%s>.",res,eno2mes(res));
		re->error(res);}
	delete re;
	return 0;}

// Response - Receive Result ------------------------------------------
int TgAgntCtrl::recvRecvEffectConfirm(int16_t id_sock,int32_t res) {
	TgReqElm* re=requests_.find(id_sock,TgReqElm::REQ_RECVTERM);
	if(re==0) {
		TgError::execError("",name(),"RecvEffectConfirm","RecvEffectConfirm from unexpected socket(internal)");
		return -1;}
	requests_.remove(re);
	if(res==0) {
		throughput("recv",re);
		re->complete();}
	else {
		TgError::execError(re->thread()->name(),name(),"RecvEffectConfirm","RecvEffect Confrim results error %d <%s>.",res,eno2mes(res));
		re->error(res);}
	delete re;
	return 0;}

// Response - Send/Receive --------------------------------------------
int TgAgntCtrl::recvSndrecvConfirm(int16_t id_sock,int32_t res) {
	TgReqElm* re=requests_.find(id_sock,TgReqElm::REQ_SENDRECV);
	if(re==0) {
		TgError::execError("",name(),"SendRecvConf","Send/Receive Confirmation from unexpected socket(internal)");
		return -1;}
	requests_.remove(re);
	if(res==0) {
		throughput("send",re);
		re->complete();}
	else {
		TgError::execError(re->thread()->name(),name(),"SndRecvConfrom","Send/Receive Confirm results error %d <%s>.",res,eno2mes(res));
		re->error(res);}
	delete re;
	return 0;}

// Response - Receive/Send --------------------------------------------
int TgAgntCtrl::recvRecvsndConfirm(int16_t id_sock,int32_t res) {
	TgReqElm* re=requests_.find(id_sock,TgReqElm::REQ_RECVSEND);
	if(re==0) {
		TgError::execError("",name(),"RecvSendConf","Receive/Send Confirmation from unexpected socket(internal)");
		return -1;}
	requests_.remove(re);
	if(res==0) {
		if(logLevel>=1) log(re);
		re->complete();}
	else {
		TgError::execError(re->thread()->name(),name(),"RecvSndConfrom","Receive/Send Confirm results error %d <%s>.",res,eno2mes(res));
		re->error(res);}
	delete re;
	return 0;}

// Response - Close ---------------------------------------------------
int TgAgntCtrl::recvCloseConfirm(int16_t id_sock,int32_t res) {
	TgReqElm* re=requests_.find(id_sock,TgReqElm::REQ_CLOSE);
	if(re==0) {
		TgError::execError("",name(),"CloseConf","Close Confirmation from unexpected socket(internal)");
		return -1;}
	requests_.remove(re);
	TgConnElm* ce =connects_.find(re->addr(),re->thread(),TgConnElm::CLOSING);
	if(logLevel>=2) {log(re);}
	if(ce==0) { // Closed and reported with "ClosedReport"
		re->complete();}
	else {
		connects_.remove(ce);
		delete ce;
		if(res==0) {
			re->complete();}
		else {
			TgError::execError(re->thread()->name(),name(),"CloseConfrom","Close Confirm results error %d <%s>.",res,eno2mes(res));
			re->error(res);}}
	delete re;
	return 0;}

// Response - Command Execution ---------------------------------------
int TgAgntCtrl::recvCmdExecConfirm(int16_t id_req,int32_t result) {
	TgReqElm* request=requests_.find(id_req,TgReqElm::REQ_EXECCMD);

	if (request == 0) {
		TgError::execError("",name(),"CmdExecConf","CmdExec Confirm from unexpected socket(internal)");
		return -1;
	}

	requests_.remove(request);

	if(result == 0) {
		log(request);
		request->complete();
	}
	else {
		TgError::execError(request->thread()->name(),name(),"CmdExecConfirm","CmdExec Confrim results error %d <%s>.",result,eno2mes(result));
		request->error(result);
	}
	
	delete request;
	return 0;
}

int TgAgntCtrl::recvCmdCancelConfirm(int16_t id_req,int32_t result) {
	TgReqElm* request = requests_.find(id_req,TgReqElm::REQ_EXECCMD);
	if (request == 0) {
		TgError::execError("",name(),"CmdCancelConf","CmdCancel Confirm from unexpected socket(internal)");
		return -1;
	}

	requests_.remove(request);

	bool complete = false;
	if (result == 0) {
		log(request);
		complete = true;
	}
	else {
		if (TgStmtExecute* caller = dynamic_cast<TgStmtExecute*>(request->caller())) {
			::fprintf(stderr, "\n\n%s> %s(%s) was canceled by <%s>.\n\n", 
					  name(), caller->name(), caller->command().string(),
					  eno2mes(result), request->thread()->name());
			complete = true;
		}
		else {
			TgError::execError(request->thread()->name(), name(), "CmdCancelConfirm", "CmdExec Confrim results error %d <%s>.", result,eno2mes(result));
			request->error(result);
		}
	}

	if (complete) {
		request->complete();
	}

	delete request;
	return 0;
}

// Report - Close -----------------------------------------------------
int TgAgntCtrl::recvClosedReport(int16_t id_sock,int32_t/*res*/) {
	TgConnElm* ce=connects_.find(id_sock);
	if(ce!=0) {
//		if(logLevel>=2) log(ce);
		connects_.remove(ce);
		delete ce;}
	return 0;}

void TgAgntCtrl::connectionLost(CmSocket* sock) {
	sock->print();
	TgError::execError("",name(),"","connection lost");}

// Log ---------------------------------------------------------------
const TgStatement* TgAgntCtrl::log(const TgReqElm* re) const {
	TgStatement* stmt=re->caller();
	if(stmt) {stmt->log(this); printf("\n");}
	return stmt;}

const TgStatement* TgAgntCtrl::throughput(CSTR s,const TgReqElm* re) const {
	TgStatement* stmt=re->caller();
	if(stmt) {stmt->throughput(s,this);}
	return stmt;}

