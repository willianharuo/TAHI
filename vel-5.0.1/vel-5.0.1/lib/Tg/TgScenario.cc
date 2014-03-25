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
 * ScenarioParser : Parser for Scenario File
 */
#include <string.h>
#include "TgScenario.h"

// ====================================================================
//  Scenario Parser
// ====================================================================

//  Constructor / Destructor ------------------------------------------
ScenarioParser::ScenarioParser(CSTR fname):
	lexer_(fname),connList_(0),eventList_(0),actionList_(0),
	scenarioList_(0),statementList_(0),srcPort_(0),dstPort_(0),
	nameList_(0) {}
ScenarioParser::~ScenarioParser() {
	if(connList_) delete connList_;
	if(eventList_) delete eventList_;
	if(actionList_) delete actionList_;
	if(scenarioList_) delete scenarioList_;
	if(statementList_) delete statementList_;
	if(srcPort_) delete srcPort_;
	if(dstPort_) delete dstPort_;
	if(nameList_) delete nameList_;}

//  "Scenario File"  operation ----------------------------------------
TgInfoScenarioFile* ScenarioParser::ScenarioFile() {
	TgInfoScenarioFile* file =new TgInfoScenarioFile(lexer_.fileName(),lexer_.lineNo(),connList_,eventList_,actionList_,scenarioList_);
	connList_=0;
	eventList_=0;
	actionList_=0;
	scenarioList_=0;
	return file;}

//  Connect Statement ----------------------------------------------------
void ScenarioParser::ConnectStatement(CmCString* name,TgInfoConn::Protocol ptcl) {
	if(connList_ &&  connList_->findByName(*name)){
		lexer_.error('E',"conn\"%s\" is already defined.",name->string());
		return;}
	if(connList_==0) connList_=new TgInfoConnCltn();
	connList_->add(new TgInfoConn(lexer_.fileName(),lexer_.lineNo(),*name,ptcl,srcPort_,dstPort_));
	srcPort_=0;
	dstPort_=0;
	delete name;}

//  Port Definition -------------------------------------------------------
void ScenarioParser::SrcPortStatement(CmCString* host,CmCString* conn,uint32_t port) {
	srcPort_=new TgInfoPort(lexer_.fileName(),lexer_.lineNo(),*host,*conn,port);
	delete host;
	delete conn;}

void ScenarioParser::DstPortStatement(CmCString* host,CmCString* conn,uint32_t port) {
	dstPort_ =new TgInfoPort(lexer_.fileName(),lexer_.lineNo(),*host,*conn,port);
	delete host;
	delete conn;}

bool dupCheck(const CStringList& l) {
	StringSet set;
	uint32_t i=0, i9=l.size();
	for(i=0;i<i9;i++) {
		CmCString* s=l[i];
		if(s==0) continue;
		const CmString* o=(const CmString*)set.add(s);
		if(o==0) return false;}
	return true;}

//  Event Statement ------------------------------------------------------
void ScenarioParser::EventStatement(CmCString* name) {
	CSTR en=name->string();
	if(eventList_ && eventList_->findByName(*name)) {
		lexer_.error('E',"event\"%s\" is already defined.",en);
		return;}
	if(nameList_==0 || nameList_->size()==0) {
		lexer_.error('E',"no action defined in event %s.",en);
		return;}
	if(!dupCheck(*nameList_)) {
		lexer_.error('E',"duplicated action defined in event %s.",en);
		return;}
	if(eventList_==0) eventList_=new TgInfoEventCltn();
	eventList_->add(new TgInfoEvent(lexer_.fileName(),lexer_.lineNo(),*name,nameList_));
	nameList_=0;
	delete name;}

void ScenarioParser::SyncEventStatement(CmCString* name) {
	EventStatement(name);
}

void ScenarioParser::WaitEventStatement(CmCString* name) {
	EventStatement(name);
}

//  Traffic Statement ----------------------------------------------------
void ScenarioParser::TrafficStatement(CmCString* name,CmCString* conn) {
	if(actionList_ && actionList_->findByName(*name)) {
		lexer_.error('E',"Action \"%s\" is already defined.",name->string());
		return;}
	if(actionList_==0) actionList_=new TgInfoActionCltn();
	actionList_->add(new TgInfoTraffic(lexer_.fileName(),lexer_.lineNo(),*name,*conn,statementList_));
	statementList_=0;
	delete name;
	delete conn;}

//  Command Statement -----------------------------------------------------
void ScenarioParser::ExecuteStatement(CmCString* name,CmCString* host) {
	if(actionList_ && actionList_->findByName(*name)) {
		lexer_.error('E',"Action \"%s\" is already defined.",name->string());
		return;}
	if(actionList_==0) actionList_=new TgInfoActionCltn();
	actionList_->add(new TgInfoCommand(lexer_.fileName(),lexer_.lineNo(),*name,*host,statementList_));
	statementList_=0;
	delete name;
	delete host;}

//  "Connect" Operation ---------------------------------------------------
void ScenarioParser::ActConnectStatement() {
	if(statementList_==0) statementList_=new TgStatementCltn();
	statementList_->add(new TgStmtConnect(lexer_.fileName(),lexer_.lineNo()));}

//  "Delay" Operation -----------------------------------------------------
void ScenarioParser::ActDelayStatement(uint32_t delaySec) {
	if(statementList_==0) statementList_=new TgStatementCltn();
	statementList_->add(new TgStmtDelay(lexer_.fileName(),lexer_.lineNo(),delaySec));}

//  "OneWay" Operation ----------------------------------------------------
void ScenarioParser::ActOneWayStatement(uint32_t size,uint32_t count,uint32_t interval) {
	if(size==0) lexer_.error('E',"invalid data size zero");
	if(size>MAX_DATA_SIZE) lexer_.error('E',"data size too long (max:%d)",MAX_DATA_SIZE);
	if(statementList_==0) statementList_=new TgStatementCltn();
	statementList_->add(new TgStmtOneWay(lexer_.fileName(),lexer_.lineNo(),size,count,interval));}

//  "Turnaround" Operation ------------------------------------------------
void ScenarioParser::ActTurnaroundStatement(uint32_t size,uint32_t count,uint32_t interval) {
	if(size==0) lexer_.error('E',"invalid data size zero");
	if(size>MAX_DATA_SIZE) lexer_.error('E',"data size too long (max:%d)",MAX_DATA_SIZE);
	if(statementList_==0) statementList_=new TgStatementCltn();
	statementList_->add(new TgStmtTurnaround(lexer_.fileName(),lexer_.lineNo(),size,count,interval));}

//  "Execute" Operation ---------------------------------------------------
void ScenarioParser::ActExecuteStatement(CmCString* command) {
	if(statementList_==0) statementList_=new TgStatementCltn();
	statementList_->add(new TgStmtExecute(lexer_.fileName(),lexer_.lineNo(),*command));
	delete command;}

//  "Sync" Operation ------------------------------------------------------
void ScenarioParser::ActSyncStatement(CmCString* action) {
	if(statementList_==0) statementList_=new TgStatementCltn();
	statementList_->add(new TgStmtSync(lexer_.fileName(),lexer_.lineNo(),*action));
	delete action;}

//  "Wait" Operation ------------------------------------------------------
void ScenarioParser::ActWaitStatement(CmCString* action) {
	if(statementList_==0) statementList_=new TgStatementCltn();
	statementList_->add(new TgStmtWait(lexer_.fileName(),lexer_.lineNo(),*action));
}

//  "Print" Operation ---------------------------------------------------
void ScenarioParser::ActPrintStatement(CmCString* str) {
	if(statementList_==0) statementList_=new TgStatementCltn();
	statementList_->add(new TgStmtPrint(lexer_.fileName(),lexer_.lineNo(),*str));
	delete str;}

//  Name ------------------------------------------------------------------
void ScenarioParser::NameStatement(CmCString* name) {
	if(nameList_==0) nameList_=new CStringList();
	nameList_->add(name);}

//  Scenario Statement ----------------------------------------------------
void ScenarioParser::ScenarioStatement(CmCString* name) {
	if(scenarioList_ && scenarioList_->findByName(*name)) {
		lexer_.error('E',"Scenario\"%s\" is already defined.",name->string());
		return;}
	if(scenarioList_==0) scenarioList_=new TgInfoScenarioCltn();
	scenarioList_->add(new TgInfoScenario(lexer_.fileName(),lexer_.lineNo(),*name,nameList_));
	nameList_=0;
	delete name;}

//  Parse -----------------------------------------------------------------
extern "C" int scenario_yyparse();

bool ScenarioParser::parse(CSTR file,TgInfoScenarioFile*& info) {
	extern ScenarioLexer	*gSnrLexer;
	extern ScenarioParser	*gSnrParser;

	ScenarioParser ps(file);
	gSnrLexer=&ps.lexer_;
	gSnrParser=&ps;
//	ps.yyparse();
	scenario_yyparse();
	if(ps.errors()>0) return false;
	info=ps.ScenarioFile();
	return true;}
