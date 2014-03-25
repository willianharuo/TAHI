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

#include "TgTypes.h"
#include "TgInfo.h"
#include "TgReqElm.h"
#include "CmSocket.h"
#include "TgStatement.h"
#include <assert.h>

// ==================================================================
//	Statement - Callback Class
// ==================================================================

// Constructor ------------------------------------------------------
TgStmtCb::TgStmtCb(TgStatement* caller,int32_t reqid):caller_(caller),reqid_(reqid) {}

TgStmtCb::TgStmtCb(const TgStmtCb& e) { *this=e; }

TgStmtCb& TgStmtCb::operator=(const TgStmtCb& e) {
	caller_=e.caller_;
	reqid_=e.reqid_;
	return *this;}

// Destructor -------------------------------------------------------
TgStmtCb::~TgStmtCb() {}

// Callback Procedure ------------------------------------------------
void TgStmtCb::complete() {
	if(caller_) caller_->onComplete(reqid_);}
void TgStmtCb::error(uint32_t ecode) {
	if(caller_) caller_->onError(reqid_,ecode);}
void TgStmtCb::expired() {
	if(caller_) caller_->onExpired(reqid_);}
CSTR TgStmtCb::thread()	{
	return caller_!=0?caller_->thread():0;}

// ==================================================================
//  List of Request
// ==================================================================

// Element class ---------------------------------------------------
TgReqElm::TgReqElm() {}
TgReqElm::TgReqElm(int16_t id,enStatus stat):stat_(stat),id_(id) {}
TgReqElm::TgReqElm(enStatus stat,int16_t id,TgExecThread* thread,
		   TgStatement* caller,int32_t reqid,
		   const CmSocket* addr,int16_t type):
	TgStmtCb(caller,reqid),stat_(stat),id_(id),
		thread_(thread),addr_(addr),type_(type) {}
TgReqElm::TgReqElm(const TgReqElm& e) {*this=e;}

const TgReqElm& TgReqElm::operator=(const TgReqElm& e) {
	TgStmtCb::operator=(e);
	stat_=e.stat_;
	id_=e.id_;
	thread_=e.thread_;
	addr_=e.addr_;
	type_=e.type_;
	return *this;}

TgReqElm::~TgReqElm() {}

uint32_t TgReqElm::hash() const {return (uint32_t)id_;}

bool TgReqElm::isEqual(const TgReqElm* e) const {
	return (id_==e->id_ && stat_==e->stat_);}

// Collection class -------------------------------------------------
implementCmSet(_TgReqCltn,TgReqElm);

TgReqElm* TgReqCltn::find(int16_t id,TgReqElm::enStatus stat) {
	TgReqElm e(id,stat);
	return _TgReqCltn::find(&e);}

// ==================================================================
//  List of Connecting/Listening Sockets
// ==================================================================

// Element ----------------------------------------------------------
TgListenElm::TgListenElm() {};
TgListenElm::TgListenElm(const CmSocket* addr):addr_(addr) {};
TgListenElm::TgListenElm(enStatus stat,int16_t id_req,int16_t id_sock,const CmSocket* addr):
	stat_(stat),id_req_(id_req),id_sock_(id_sock),addr_(addr) {}
TgListenElm::TgListenElm(const TgListenElm& e) {*this=e;}

const TgListenElm& TgListenElm::operator=(const TgListenElm& e) {
	stat_=e.stat_;
	id_req_=e.id_req_;
	id_sock_=e.id_sock_;
	addr_ =e.addr_;
	return *this;}

TgListenElm::~TgListenElm() {}

uint32_t TgListenElm::hash() const {return addr_->hash();}

bool TgListenElm::isEqual(const TgListenElm* pe) const {
	return addr_->isEqual(pe->addr_);}

// Collection Class --------------------------------------------------
implementCmSet(_TgListenCltn,TgListenElm);

TgListenElm* TgListenCltn::find(int16_t id_req) const {
	for(uint32_t n=0; n < size(); ++n) {
		TgListenElm* e=(TgListenElm*)index(n);
		if(e!=0 && e->id_req_==id_req)
			return e;}
	return 0;}

TgListenElm* TgListenCltn::find(const CmSocket* addr) {
	TgListenElm e(addr);
	return _TgListenCltn::find(&e);}

// ==================================================================
//  List of Accepted Sockets
// ==================================================================

// Element class ---------------------------------------------------
TgAcceptElm::TgAcceptElm() {}
TgAcceptElm::TgAcceptElm(const CmSocket* caddr,const CmSocket* saddr):
	caddr_(caddr),saddr_(saddr) {}
TgAcceptElm::TgAcceptElm(int16_t id_sock,const CmSocket* caddr,const CmSocket* saddr):
	id_sock_(id_sock),caddr_(caddr),saddr_(saddr) {}
TgAcceptElm::TgAcceptElm(const TgAcceptElm& e) {*this=e;}

const TgAcceptElm& TgAcceptElm::operator=(const TgAcceptElm& e) {
	id_sock_=e.id_sock_;
	caddr_=e.caddr_;
	saddr_=e.saddr_;
	return *this;}

TgAcceptElm::~TgAcceptElm() {}

uint32_t TgAcceptElm::hash() const {return caddr_->hash() + saddr_->hash();}

bool TgAcceptElm::isEqual(const TgAcceptElm* e) const {
	return caddr_->isEqual(e->caddr_) && saddr_->isEqual(e->saddr_);}

// Collection class -------------------------------------------------
implementCmSet(_TgAcceptCltn,TgAcceptElm);

TgAcceptElm* TgAcceptCltn::find(const CmSocket* caddr,const CmSocket* saddr) {
	TgAcceptElm e(caddr,saddr);
	return _TgAcceptCltn::find(&e);}

// ==================================================================
//  List of Opened Sockets
// ==================================================================

// Element class ---------------------------------------------------
TgConnElm::TgConnElm() {}

TgConnElm::TgConnElm(const CmSocket* addr,const TgExecThread* thread,enStatus stat):
	stat_(stat),addr_(addr),thread_(thread) {}

TgConnElm::TgConnElm(enStatus stat,int16_t id,const CmSocket* addr,const TgExecThread* thread):
	stat_(stat),id_sock_(id),addr_(addr),thread_(thread) {}

TgConnElm::TgConnElm(const TgConnElm& e) {*this=e;}

const TgConnElm& TgConnElm::operator=(const TgConnElm& e) {
	stat_=e.stat_;
	id_sock_=e.id_sock_;
	addr_=e.addr_;
	thread_=e.thread_;
	return *this;}

TgConnElm::~TgConnElm() {}

uint32_t TgConnElm::hash() const {return addr_->hash();}

bool TgConnElm::isEqual(const TgConnElm* e) const {
	return (addr_->isEqual(e->addr_) && thread_==e->thread_ && stat_==e->stat_);}

// Collection class -------------------------------------------------
implementCmSet(_TgConnCltn,TgConnElm);

TgConnElm* TgConnCltn::find(int16_t id_sock) {
	for(uint32_t n=0; n < size(); ++n) {
		TgConnElm* e=(TgConnElm*)index(n);
		if(e!=0 && e->id_sock_==id_sock)
			return e;}
	return 0;}

TgConnElm* TgConnCltn::find(const CmSocket* addr,const TgExecThread* thread,TgConnElm::enStatus stat) {
	TgConnElm e(addr,thread,stat);
	return _TgConnCltn::find(&e);}

