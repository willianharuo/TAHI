/* -*-Mode: C++-*-
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
 * TgSyncEvent : Event/Sync operation class
 */

#include "TgExecThread.h"
#include "TgSyncEvent.h"
#include "TgDebug.h"
#include "TgError.h"


// ===================================================================
//	TgSyncEventList : Collection of TgSyncEvent
// ===================================================================
implementCmList(TgSyncEventList,TgSyncEvent);

// ===================================================================
//   TgSyncEvent : "SYNC" object
// ===================================================================

// Constructor ------------------------------------------------------
TgSyncEvent::TgSyncEvent(const TgInfoEvent* pe):TgBaseName(pe->name()) {
	waitfor_=*pe->actions();}
TgSyncEvent::TgSyncEvent(const TgSyncEvent& ref) {*this=ref;}
TgSyncEvent& TgSyncEvent::operator=(const TgSyncEvent& ref) {
	TgBaseName::operator=(ref);	
	waitfor_=ref.waitfor_;
	cblist_=ref.cblist_;
	return *this;}

// Destructor ------------------------------------------------------
TgSyncEvent::~TgSyncEvent() { }

// Instance control ------------------------------------------------
TgSyncEventList* TgSyncEvent::list_=0;
TgSyncEventList* TgSyncEvent::list() {
	if(list_==0) list_=new TgSyncEventList();
	return list_;}

// Operation : add new object -------------------------------------
void TgSyncEvent::addEventObject(const TgInfoEvent* pe) {
	list()->add(new TgSyncEvent(pe));}

// Operation : sync -----------------------------------------------
bool TgSyncEvent::syncEvent(TgExecThread* thread,TgStatement* statement,int32_t reqid,const CmCString event,bool& wait) {
	TgSyncEvent* e=list()->findMatching(&event);
	if(e==0) {
		TgError::execError(thread->name(),"","Sync","Event \"%s\" is not defined",event.string() );
		return false;
	}

	CmCString* cs;
	if((cs=e->waitfor_.findMatching(thread))==0) {
		TgError::execError(thread->name(),"","Sync","Thread %s is not defined as a member of Event \"%s\"",thread->name(),e->name());
		return false;
	}
	dbgTrace(("Thread %s : sync %s\n",thread->name(),event.string()));
	e->cblist_.add(new TgStmtCb(statement,reqid));
	e->waitfor_.remove(cs);

	if(e->waitfor_.size()==0) e->syncComplete();
	wait=true;
	return true;
}

// Operation : wait -----------------------------------------------
bool TgSyncEvent::waitEvent(TgExecThread* thread,TgStatement* statement,int32_t reqid,const CmCString event,bool& wait) {
	TgSyncEvent* e=list()->findMatching(&event);
	if(e==0) {
		TgError::execError(thread->name(),"","Wait","Event \"%s\" is not defined",event.string() );
		return false;
	}

	CmCString* cs;
	if((cs=e->waitfor_.findMatching(thread))==0) {
		TgError::execError(thread->name(),"","Wait","Thread %s is not defined as a member of Event \"%s\"",thread->name(),e->name());
		return false;
	}
	dbgTrace(("Thread %s : wait %s\n",thread->name(),event.string()));
	e->cblist_.add(new TgStmtCb(statement,reqid));
	e->waitfor_.remove(cs);

	if(e->waitfor_.size()==0) {
		char buf[1024];		
		if (fgets(buf, sizeof(buf), stdin) == NULL) {
			perror("fgets");
			exit(1);
		}
		e->waitComplete();
	}

	wait=true;
	return true;
}


void TgSyncEvent::syncComplete() {
	dbgTrace(("Event %s : sync completed.\n",this->name()));
	dispatch()->startTimer(0,0,this);}

void TgSyncEvent::waitComplete() {
	dbgTrace(("Event %s : wait completed.\n",this->name()));
	dispatch()->startTimer(0,0,this);}

void TgSyncEvent::timerExpired(time_t,uint32_t) {
	cblist_.elementsPerform((TgStmtCbFunc)&TgStmtCb::complete);
	cblist_.deleteContents();
	list()->remove(this);
	delete this;}

