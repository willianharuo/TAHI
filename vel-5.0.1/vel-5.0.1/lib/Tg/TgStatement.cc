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
 * TgInfo : TG Information classes
 */
#include <stdio.h>
#include <unistd.h>
#include "CmLexer.h"
#include "CmMain.h"
#include "TgStatement.h"
#include "TgAgntCtrl.h"
#include "TgExecThread.h"
#include "TgSyncEvent.h"
#include "TgExecTimer.h"
#include "TgError.h"
#include "TgDebug.h"
#include "TgInfo.h"

// ====================================================================
//  Set additional information ----------------------------------------
void TgStmtSync::setInfo(void*,va_list ap) {
	DCLA(TgInfoScenarioFile*,scnFile);
	CSTR fn=fileName_.string();
	int ln=lineNo_;
	CSTR en=event_.string();
	const TgInfoEventCltn* eventList=scnFile->eventList();
	TgInfoEvent* ev=eventList!=0?eventList->findByName(event_):0;
	if(ev==0||action_==0) {
		CmLexer::eouts(fn,ln,'E',
			"event %s is not defined in event list.",en);
		return;}
	CStringList* acts=ev->actions();
	
	// not perfomed on Linux
	//CmCString* act=acts!=0?acts->findMatching((CmCString*)action_):0;

	CmCString* act = NULL;
	for (int i=0, size=acts->size(); i <size; i++) {
		CmCString *elm = (CmCString*) acts->at(i);
		CSTR s = elm->string();
		CSTR t = action_->name();
		int r=0;
		if (s!=0 && t!=0) { r = strcmp(s, t); }
		else if (s==0 && t==0) { r = 0; }
		else if (s!=0 && t==0) { r = 1; }
		else if (s==0 && t!=0) { r = -1; }
		
		if (r == 0) {
            act = elm;
            break;
		}
	}
	
	if(act==0) {
		CmLexer::eouts(fn,ln,'E',
			"%s is not defined in event %s.",action_->name(),en);}}

void TgStmtWait::setInfo(void*,va_list ap) {
	DCLA(TgInfoScenarioFile*,scnFile);
	CSTR fn=fileName_.string();
	int ln=lineNo_;
	CSTR en=event_.string();
	const TgInfoEventCltn* eventList=scnFile->eventList();
	TgInfoEvent* ev=eventList!=0?eventList->findByName(event_):0;
	if(ev==0||action_==0) {
		CmLexer::eouts(fn,ln,'E',
			"event %s is not defined in event list.",en);
		return;}
	CStringList* acts=ev->actions();
	
	// not performed on Linux
	//CmCString* act=acts!=0?acts->findMatching((CmCString*)action_):0;

	CmCString* act = NULL;
	for (int i=0, size=acts->size(); i <size; i++) {
		CmCString *elm = (CmCString*) acts->at(i);
		CSTR s = elm->string();
		CSTR t = action_->name();
		int r=0;
		if (s!=0 && t!=0) { r = strcmp(s, t); }
		else if (s==0 && t==0) { r = 0; }
		else if (s!=0 && t==0) { r = 1; }
		else if (s==0 && t!=0) { r = -1; }
		
		if (r == 0) {
            act = elm;
            break;
		}
	}

	if(act==0) {
		CmLexer::eouts(fn,ln,'E',
			"%s is not defined in event %s.",action_->name(),en);}}

// ====================================================================
// Step ---------------------------------------------------------------
bool TgStmtConnect::doStep(bool& abort) {
	CSTR clName=clientPort()->host()->name();
	CSTR svName=serverPort()->host()->name();
	TgAgntCtrl* client=agents_->findByName(clName);
	TgAgntCtrl* server=agents_->findByName(svName);
	if(client==0 || server==0) {
		TgError::execError(thread_->name(),"",name()," %s agent not found on step %d(internal)",client==0 ? "Client" : "Server",step_);
		abort=true; return false;}
	int32_t id_req=getReqId();
	for(;;step_++) {
		bool result,waitf;
		switch(step_) {
			case 0:			// Client - open
				setTime(startTime_);
				result=client->opOpen(thread_,this,id_req,clientPort()->socket(),serverPort()->socket(),protocol(),waitf);
				break;
			case 1:			// Server - Listen
				result=server->opListen(thread_,this,id_req,serverPort()->socket(),protocol(),waitf);
				break;
			case 2:			// Clienct - Connect
				result=client->opConnect(thread_,this,id_req,clientPort()->socket(),protocol(),waitf);
				break;
			case 3:			// Server - Accept
				result=server->opAccept(thread_,this,id_req,serverPort()->socket(),clientPort()->socket(),protocol(),waitf);
				break;
			default:
				setTime(endTime_);
				managerLog("%s->%s",clName,svName);
				abort=false; return false;}
		if(result==false) {abort=true; return false;}
		if(waitf) break;}
	lock(id_req);
	return true;}

//  Step  ------------------------------------------------------------
bool TgStmtOneWay::doStep(bool& abort) {
	CSTR clName=clientPort()->host()->name();
	CSTR svName=serverPort()->host()->name();
	TgAgntCtrl* client=agents_->findByName(clName);
	TgAgntCtrl* server=agents_->findByName(svName);
	if(client==0 || server==0) {
		TgError::execError(thread_->name(),"",name()," %s agent not found on step %d(internal)",client==0 ? "Client" : "Server",step_);
		abort=true; return false;}
	int32_t id_req=getReqId();
	for(;; step_++) {
		bool result,waitf;
		switch((int)step_) {
			case 0:
				setTime(startTime_);
				result=server->opReceive(thread_,this,id_req,serverPort()->socket(),protocol(),count_,sendlen_,waitf);
				break;
			case 1:
				result=client->opSend(thread_,this,id_req,clientPort()->socket(),protocol(),count_,sendlen_,interval_,waitf);
				break;
			case 2:
				result=server->opRecvTerminate(thread_,this,id_req,serverPort()->socket(),protocol(),waitf);
				break;
			default: {
				setTime(endTime_);
				managerLog("%s->%s {%d,%d,%d}",clName,svName,sendlen_,count_,interval_);
				abort=false; return false;}
				break;}
		if(result==false) {abort=true; return false;}
		if(waitf) break;}
	lock(id_req);
	return true;}

//  Step  -------------------------------------------------------------
bool TgStmtTurnaround::doStep(bool& abort) {
	CSTR clName=clientPort()->host()->name();
	CSTR svName=serverPort()->host()->name();
	TgAgntCtrl* client=agents_->findByName(clName);
	TgAgntCtrl* server=agents_->findByName(svName);
	if(client==0 || server==0) {
		TgError::execError(thread_->name(),"",name()," %s agent not found on step %d(internal)",client==0 ? "Client" : "Server",step_);
		abort=true; return false;}
	int32_t id_req=getReqId();
	for(;;step_++) {
		bool result,waitf;
		switch((int)step_) {
			case 0:
				setTime(startTime_);
				result=server->opRecvSend(thread_,this,id_req,serverPort()->socket(),protocol(),count_,sendlen_,interval_,waitf);
				break;
			case 1:
				result=client->opSendRecv(thread_,this,id_req,clientPort()->socket(),protocol(),count_,sendlen_,interval_,waitf);
				break;
			case 2:
				result=server->opRecvTerminate(thread_,this,id_req,serverPort()->socket(),protocol(),waitf);
				break;
			default: {
				setTime(endTime_);
				managerLog("%s<->%s {%d,%d,%d}",clName,svName,sendlen_,count_,interval_);
				abort=false; return false;}
				break;}
		if(result==false) {abort=true; return false;}
		if(waitf==true) break;}
	lock(id_req);
	return true;}

//  Step  -------------------------------------------------------------
bool TgStmtClose::doStep(bool& abort) {
	CSTR clName=clientPort()->host()->name();
	CSTR svName=serverPort()->host()->name();
	TgAgntCtrl* client=agents_->findByName(clName);
	TgAgntCtrl* server=agents_->findByName(svName);
	if(client==0 || server==0) {
		TgError::execError(thread_->name(),"",name()," %s agent not found on step %d(internal)",client==0 ? "Client" : "Server",step_);
		abort=true;
		return false;}
	int32_t id_req=getReqId();
	bool result,waitf;
	for(;;step_++) {
		switch((int)step_) {
			case 0:
				setTime(startTime_);
				result=client->opClose(thread_,this,id_req,clientPort()->socket(),protocol(),waitf);
				break;
			case 1:
				result=server->opClose(thread_,this,id_req,serverPort()->socket(),protocol(),waitf);
				break;
			default:
				setTime(endTime_);
				if(logLevel>=1) managerLog( "%s,%s",clName,svName);
				abort=false; return false;}
		if(result==false) {abort=true; return false;}
		if(waitf==true) break;}
	lock(id_req);
	return true;}

//  Step Execution  ---------------------------------------------------
bool TgStmtExecute::doStep(bool& abort) {
	const TgInfoHost* host=((TgInfoCommand*)action_)->pHost();
	TgAgntCtrl* agent=agents_->findByName(host->name());
	if(agent==0) {
		TgError::execError(thread_->name(),"",name()," agent not found on step %d(internal)",step_);
		abort=true; return false;}
	int32_t id_req=getReqId();
	bool result,waitf;
	for(;;++step_) {
		switch((int)step_) {
			case 0:
				setTime(startTime_);
				result=agent->opCommand(thread_,this,id_req,command_.string(),waitf);
				break;
			default:
				setTime(endTime_);
				managerLog("%s (\"%s\")",host->name(),command_.string());
				abort=false; return  false;}
		if(result==false) {abort=true; return false;}
		if(waitf==true) break;}
	lock(id_req);
	return true;}

//  Step --------------------------------------------------------------
bool TgStmtSync::doStep(bool& abort) {
	int32_t id_req=getReqId();
	bool result,waitf;
	for(;;++step_) {
		switch((int)step_) {
			case 0:
				setTime(startTime_);
				result=TgSyncEvent::syncEvent(thread_,this,id_req,event_,waitf);
				break;
			default:
				setTime(endTime_);
				managerLog( "(\"%s\")",event_.string());
				abort=false; return  false;
		}
		if(result==false) {abort=true; return false;}
		if(waitf==true) break;
	}
	lock(id_req);
	return true;}

//  Step Execution ---------------------------------------------------
bool TgStmtDelay::doStep(bool& abort) {
	switch((int)step_) {
		case 0:
			setTime(startTime_);
			timer_->waitTimer((time_t)delaySec_,(uint32_t)0,this);
			return true;
		default:
			setTime(endTime_);
			managerLog( "(%d)",delaySec_);
			abort=false; return false;}}

//  Step ---------------------------------------------------
bool TgStmtWait::doStep(bool& abort) {
	int32_t id_req=getReqId();
	bool result,waitf;
	for(;;++step_) {
		switch((int)step_) {
			case 0:
				setTime(startTime_);
				result=TgSyncEvent::waitEvent(thread_,this,id_req,event_,waitf);
				break;
			default:
				setTime(endTime_);
				managerLog( "(\"%s\")",event_.string());
				abort=false; return  false;
		}
		if(result==false) {abort=true; return false;}
		if(waitf==true) break;
	}
	lock(id_req);
	return true;
}

//  Step ---------------------------------------------------
bool TgStmtPrint::doStep(bool& abort) {
	int reqid = 0;
	switch((int)step_) {
		case 0:
			setTime(startTime_);
			printf("%s\n", str_.string());
			onComplete(reqid);
			return true;
		default:
			setTime(endTime_);
			//managerLog( "(%s)",str_);
			abort=false;
			return false;
	}
}


// ====================================================================
//	Statement : Base Class
// ====================================================================

// Constructor --------------------------------------------------------
TgStatement::TgStatement(CSTR file,int32_t line):thread_(0),agents_(0),fileName_(file),lineNo_(line),step_(0),errors_(0) {
	for(int32_t n=0;n<ID_SIZE; ++n) id_lock[n]=0;}

TgStatement::TgStatement(const TgStatement& ref) { *this=ref; }

TgStatement& TgStatement::operator=(const TgStatement& ref) {
	step_=ref.step_;
	errors_=ref.errors_;
	agents_=ref.agents_;
	thread_=ref.thread_;
	fileName_=ref.fileName_;
	lineNo_=ref.lineNo_;
	return *this;}

// Destructor ---------------------------------------------------------
TgStatement::~TgStatement() {}

// Reset --------------------------------------------------------------
void TgStatement::setAction(void* v,...) {
	action_=(const TgInfoAction*)v;}
void TgStatement::reset(void* s,va_list ap) {
	thread_=(TgExecThread*)s;
	DCLA(TgAgntCtrlCltn*,agent);
	DCLA(TgInfoAction*,action);
	agents_=agent;
	action_=action;
	step_=0;}

// get unique request id ----------------------------------------------
int32_t TgStatement::getReqId() { return ++id_seed_; }

// Add new element to wait list ---------------------------------------
void TgStatement::lock(int32_t id) {
	dbgTrace(("LOCK %d\n",id));
	id_lock[id % ID_SIZE]=id;}

// Remove element from wait list --------------------------------------
void TgStatement::unlock(int32_t id) {
	if(id_lock[id % ID_SIZE]==id) {
		dbgTrace(("UNLOCK %d\n",id));
		id_lock[id % ID_SIZE]=0;}}

// check for complete -------------------------------------------------
int32_t TgStatement::numWaits() const {
	int32_t count=0;
	for(int32_t n=0;n<ID_SIZE;++n) {if(id_lock[n]) ++count;}
	return count;}

// get thread name ---------------------------------------------------
CSTR TgStatement::thread() const { return thread_->name(); }

//  OnComplete --------------------------------------------------------
void TgStatement::onComplete(int32_t id) {
	unlock(id);
	if(numWaits()==0 && errors_==0) {
		step_++;
		thread_->onComplete();}}

//  OnError ----------------------------------------------------------
void TgStatement::onError(int32_t id,uint32_t ecode) {
	unlock(id);
	errors_++;
	thread_->onError(ecode);}

//  Timer Expired ----------------------------------------------------
void TgStatement::onExpired(int32_t /*reqid*/) {
	step_++;
	thread_->onComplete();}

//  Log Message ------------------------------------------------------
void TgStatement::setTime(timeval& t) {
	::gettimeofday(&t,0);}

// ====================================================================
//	"Connect" Operation
// ====================================================================

// Constructor --------------------------------------------------------
TgStmtConnect::TgStmtConnect(CSTR file,int32_t line):TrafficStatement(file,line) {}

TgStmtConnect::TgStmtConnect(const TgStmtConnect& ref) { *this=ref; }

TgStmtConnect& TgStmtConnect::operator=(const TgStmtConnect& ref) {
	TrafficStatement::operator=(ref);
	return *this;}

// Destructor ---------------------------------------------------------
TgStmtConnect::~TgStmtConnect() {}

// Print Information --------------------------------------------------
void TgStmtConnect::_printOut(void* s,va_list) const {
	uint32_t level=(uint32_t)s;
	_indent(level);
	ooutf("Connect - %p\n",this);}

// ====================================================================
//	"Delay" Operation
// ====================================================================

//  Constructor -------------------------------------------------------
TgStmtDelay::TgStmtDelay(CSTR file,int32_t line,uint32_t delaySec):
	TgStatement(file,line),delaySec_(delaySec),timer_(0) {}

TgStmtDelay::TgStmtDelay(const TgStmtDelay& ref) { *this=ref; }

TgStmtDelay& TgStmtDelay::operator=(const TgStmtDelay& ref) {
	TgStatement::operator=(ref);
	return *this;}

//  Destructor -------------------------------------------------------
TgStmtDelay::~TgStmtDelay() {
	if(timer_) delete timer_;}

//  Print Information ------------------------------------------------
void TgStmtDelay::_printOut(void* s,va_list) const {
	uint32_t level=(uint32_t)s;
	_indent(level);
	ooutf("Delay %d - %p\n",delaySec_,this);}

//  Reset ------------------------------------------------------------
void TgStmtDelay::reset(void* s,va_list ap) {
	TgStatement::reset(s,ap);
	if(timer_==0) timer_=new TgExecDelayTimer();}

// ====================================================================
//	"OneWay" Operation
// ====================================================================

//  Constructor  ------------------------------------------------------
TgStmtOneWay::TgStmtOneWay(CSTR file,int32_t line,uint32_t length,uint32_t count,uint32_t interval):
	TrafficStatement(file,line,length,length,count,interval) {}

TgStmtOneWay::TgStmtOneWay(const TgStmtOneWay& ref) { *this=ref; }

TgStmtOneWay& TgStmtOneWay::operator=(const TgStmtOneWay& ref) {
	TrafficStatement::operator=(ref);
	return *this;}

//  Destructor  -------------------------------------------------------
TgStmtOneWay::~TgStmtOneWay() {}

//  Print Information  ------------------------------------------------
void TgStmtOneWay::_printOut(void* s,va_list) const {
	uint32_t level=(uint32_t)s;
	_indent(level);
	ooutf("OneWay %d,%d,%d - %p\n",sendlen_,count_,interval_,this);}

// ====================================================================
//	"Turnaround" Operation
// ====================================================================

//  Constructor  ------------------------------------------------------
TgStmtTurnaround::TgStmtTurnaround(CSTR file,int32_t line,uint32_t length,uint32_t count,uint32_t interval):
	TrafficStatement(file,line,length,length,count,interval) {}

TgStmtTurnaround::TgStmtTurnaround(const TgStmtTurnaround& ref) { *this=ref; }

TgStmtTurnaround& TgStmtTurnaround::operator=(const TgStmtTurnaround& elm) {
	TrafficStatement::operator=(elm);
	return *this;}

//  Destructor --------------------------------------------------------
TgStmtTurnaround::~TgStmtTurnaround() {}

//  Print Information -------------------------------------------------
void TgStmtTurnaround::_printOut(void* s,va_list) const {
	uint32_t level=(uint32_t)s;
	_indent(level);
	ooutf("Turnaround %d,%d,%d - %p\n",sendlen_,count_,interval_,this);}

// ====================================================================
//	"Execute" Operation
// ====================================================================

//  Constructor  ------------------------------------------------------
TgStmtExecute::TgStmtExecute(CSTR file,int32_t line):TgStatement(file,line) {}

TgStmtExecute::TgStmtExecute(CSTR file,int32_t line,CmCString cmd):TgStatement(file,line),command_(cmd) {}

TgStmtExecute::TgStmtExecute(const TgStmtExecute& ref) { *this=ref; }

TgStmtExecute& TgStmtExecute::operator=(const TgStmtExecute& elm) {
	TgStatement::operator=(elm);
	command_=elm.command_;
	return *this;}

//  Destructor  -------------------------------------------------------
TgStmtExecute::~TgStmtExecute() {}

//  Print Information  ------------------------------------------------
void TgStmtExecute::_printOut(void* s,va_list) const {
	uint32_t level=(uint32_t)s;
	_indent(level);
	ooutf("Execute \"%s\"- %p\n",command_.string(),this);}

// ====================================================================
//	"Sync" Operation
// ====================================================================

//  Constructor  ------------------------------------------------------
TgStmtSync::TgStmtSync(CSTR file,int32_t line):TgStatement(file,line) {}
TgStmtSync::TgStmtSync(CSTR file,int32_t line,const CmCString event):TgStatement(file,line),event_(event) {}
TgStmtSync::TgStmtSync(const TgStmtSync& ref) { *this=ref; }

TgStmtSync& TgStmtSync::operator=(const TgStmtSync& ref) {
	event_=ref.event_;
	return *this;}

//  Destructor  -------------------------------------------------------
TgStmtSync::~TgStmtSync() {}

//  Print Information  ------------------------------------------------
void TgStmtSync::_printOut(void* s,va_list) const {
	_indent((uint32_t)s);
	ooutf("Sync %s - 0x%X\n",event_.string(),this);}

// ====================================================================
//	"Wait" Operation
// ====================================================================

//  Constructor  ------------------------------------------------------
TgStmtWait::TgStmtWait(CSTR file,int32_t line):TgStatement(file,line) {}
TgStmtWait::TgStmtWait(CSTR file,int32_t line,const CmCString event):TgStatement(file,line),event_(event) {}
TgStmtWait::TgStmtWait(const TgStmtWait& ref) { *this=ref; }

TgStmtWait& TgStmtWait::operator=(const TgStmtWait& ref) {
	event_=ref.event_;
	return *this;}

//  Destructor  -------------------------------------------------------
TgStmtWait::~TgStmtWait() {}

//  Print Information  ------------------------------------------------
void TgStmtWait::_printOut(void* s,va_list) const {
	_indent((uint32_t)s);
	ooutf("Wait %s - 0x%X\n",event_.string(),this);}

// ====================================================================
//	"Print" Operation
// ====================================================================

//  Constructor  ------------------------------------------------------
TgStmtPrint::TgStmtPrint(CSTR file,int32_t line,CmCString str):TgStatement(file,line),str_(str) {}

TgStmtPrint::TgStmtPrint(const TgStmtPrint& ref) { *this=ref; }

TgStmtPrint& TgStmtPrint::operator=(const TgStmtPrint& elm) {
	TgStatement::operator=(elm);
	str_=elm.str_;
	return *this;}

//  Destructor  -------------------------------------------------------
TgStmtPrint::~TgStmtPrint() {}

//  Print Information  ------------------------------------------------
void TgStmtPrint::_printOut(void* s,va_list) const {
	uint32_t level=(uint32_t)s;
	_indent(level);
	ooutf("Print \"%s\"- %p\n",str_.string(),this);}

// ====================================================================
//	"DisConnect" Operation
// ====================================================================

//  Constructor  ------------------------------------------------------
TgStmtClose::TgStmtClose() {}

TgStmtClose::TgStmtClose(const TgStmtClose& ref) { *this=ref; }

TgStmtClose& TgStmtClose::operator=(const TgStmtClose& ref) {
	TgStatement::operator=(ref);
	return *this;}

//  Destructor  -------------------------------------------------------
TgStmtClose::~TgStmtClose() {}

//  Print Information  ------------------------------------------------
void TgStmtClose::_printOut(void* s,va_list) const {
	_indent((uint32_t)s);
	ooutf("Close - %p\n",this);}

void TgStatement::log(const TgAgntCtrl* ac) const {
	static CSTR space="                               ";
	CSTR tn=thread_->name();
	timeval st,et;
	CSTR hn=0;
	CSTR sub=0;
	CSTR me=name();
	if(ac==0) {
		hn="mgr";
		st=startTime();
		et=endTime();}
	else {
		hn=ac->name();
		st=ac->startTime();
		et=ac->endTime();
		sub=ac->requestName();}
	int32_t nl=strlen(tn)+strlen(hn)+1;
	int32_t rl=(nl<14)?(14-nl):1;
	timeval delta=EPOCHTIMEVAL;
	if(st<et) {delta=et-st;}
	printf("%s@%s%*.*s: %6ld.%06lu : %s%s%s",
		tn,hn,rl,rl,space,delta.tv_sec,delta.tv_usec,
		me,sub!=0?"-":" ",sub!=0?sub:"");}

void TgStatement::throughput(CSTR,const TgAgntCtrl* ac) const {
	log(ac); printf("\n");}

void TrafficStatement::logTP(const TgAgntCtrl* ac,CSTR s,uint32_t sc,uint32_t rc) const {
	timeval st=ac->startTime();
	timeval et=ac->endTime();
	timeval delta;
	if(et<=st) {delta.tv_sec=0; delta.tv_usec=1;}
	else {delta=et-st;}
	double d_delta = (double)delta.tv_sec + (double)delta.tv_usec/(double)ONE_SECOND;
	double tp=(((double)sendlen_*(double)sc)+((double)recvlen_*(double)rc))/d_delta;
	printf("%14s: %.4e bytes/sec(payload)",s,tp);
	if(protocol()==TgInfoConn::TCP_) {printf("\n");}
	else {
		double hs = (version() == TgInfoConn::IPv4_ ? 28:48);
		double fp=((double)(sc+rc))/d_delta;
		tp=(((double)(sendlen_+hs)*(double)sc)+((double)(recvlen_+hs)*(double)rc))/d_delta;
		printf(" sc=%d rc=%d %.4e pkt/sec sec %.4e bytes/sec(udp)\n",sc,rc,fp,tp);}}

void TrafficStatement::throughput(CSTR s,const TgAgntCtrl* ac) const {
	log(ac); printf("\n");
	const trafficInfo& ti=ac->effectInfo();
	uint32_t sc=ti.scount();
	uint32_t rc=ti.rcount();
	logTP(ac,s,sc,rc);}

void TgStatement::managerLog(CSTR fmt,...) const {
	log(0);
	va_list ap;
	va_start(ap,fmt);
	vprintf(fmt,ap);
	va_end(ap);
	printf("\n");}

// ====================================================================
//	Statement Callback Collection
// ====================================================================
implementCmList(TgStmtCbList,TgStmtCb);
implementBtCltn(List,TgStatementCltn,TgStatement);
int32_t TgStatement::id_seed_=0;
