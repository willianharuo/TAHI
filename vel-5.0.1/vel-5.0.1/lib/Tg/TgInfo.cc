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
 * TgInfo:TG Information classes
 */

#include <stdio.h>
#include "CmLexer.h"
#include "TgInfo.h"
#include "TgSyncEvent.h"
#include "TgStatement.h"

//====================================================================
//  Create New Socket Instance ----------------------------------------
CmSocket* TgInfoIPV4Name::socket(uint32_t port) const {
	return InetSocket::stream((int)port,ipaddr_); }

//  Create New Socket Instance ----------------------------------------
CmSocket* TgInfoIPV6Name::socket(uint32_t port) const {
	return InetSocket::stream((int)port,ipaddr_); }

//  Create New Socket Instance ----------------------------------------
CmSocket* TgInfoPort::socket() const {
	if(ipName_==0) return 0;
	return ipName_->socket(port_);}

//====================================================================
//  Set IPname --------------------------------------------------------
bool TgInfoPort::setIpInfo(CSTR conn,TgInfoHostFile* pHostFile) {
	if(host_==0 && ipName_==0) {
		host_=pHostFile->hostList()->findByName(csHostName_);
		if(host_==0) {
			CmLexer::eouts(fileName_.string(),lineNo_,'E',"Host \"%s\" for connection \"%s\" is not defined.",csHostName_.string(),conn);
			return false;}
		ipName_=host_->findIpByName(csIpName_);
		if(ipName_==0) {
			CmLexer::eouts(fileName_.string(),lineNo_,'E',"IP \"%s\" for connection \"%s\" is not defined.",csIpName_.string(),conn);
			return false;}}
	return true;}

//  Set TGA Port Information ------------------------------------------
void TgInfoHost::setInfo(void* s,va_list) {
	TgInfoHostFile* hostFile=(TgInfoHostFile*)s;
	if(tgaName_.length()==0) {
		tgaPort_=0;
		return;}
	TgInfoIpName* pIpName=findIpByName(tgaName_);
	if(!pIpName) {
		CmLexer::eouts(fileName_.string(),lineNo_,'E',"Tga IP\"%s\" is not defined for host %s",tgaName_.string(),name());
		return; }
	tgaPort_=new TgInfoPort(fileName_.string(),lineNo_,*this,*pIpName,tga_no_);
	tgaPort_->setIpInfo("tga",hostFile);}

//  Setup Port Information --------------------------------------------
void TgInfoConn::setInfo(void* s,va_list) {
	TgInfoHostFile* hostFile=(TgInfoHostFile*)s;
	bool rc=true;
	if(client_==0||!client_->setIpInfo(name(),hostFile)) rc=false;
	if(server_==0||!server_->setIpInfo(name(),hostFile)) rc=false;
	if(!rc) return;
	if(client_->versionCode() != server_->versionCode()){
		CmLexer::eouts(fileName_.string(),lineNo_,'E',"Illegal connection:%s and %s.",client_->ipName()->name(),server_->ipName()->name());
		return;}
	version_=(client_->versionCode()==4 ? IPv4_:IPv6_);}

//  Set Host Info -----------------------------------------------------
void TgInfoCommand::setInfo(void* s,va_list) {
	TgInfoHostFile* hostFile=(TgInfoHostFile*)s;
	if(hostFile->hostList()) {
		host_=hostFile->hostList()->findByName(csHost_);
		if(host_==0) {
			CmLexer::eouts(fileName_.string(),lineNo_,'E',"Host \"%s\" for command \"%s\" is not defined.",csHost_.string(),name());}}}

//  Set Action --------------------------------------------------------
void TgInfoEvent::setInfo(void*,va_list ap) {
	DCLA(TgInfoScenarioFile*,scnFile);
	if(actions_ && scnFile->actionList()) {
		for(uint32_t n=0; n < actions_->size(); ++n) {
			CmCString* action=actions_->index(n);
			if(scnFile->actionList()->findByName(*action)==0) {
				CmLexer::eouts(fileName_.string(),lineNo_,'E',"Event %s: action %s is not defined.",this->name(),action->string());}}}
	TgSyncEvent::addEventObject(this);}

//  Set Action --------------------------------------------------------
void TgInfoScenario::setInfo(void*,va_list ap) {
	DCLA(TgInfoScenarioFile*,scnFile);
	if(actionName_ && scnFile->actionList()) {
		actionList_=new TgInfoActionCltn();
		for(uint32_t n=0; n < actionName_->size(); ++n) {
			CmCString* pname=actionName_->index(n);
			TgInfoAction* pAction =
			scnFile->actionList()->findByName(*pname);
			if(pAction==0) {
				CmLexer::eouts(fileName_.string(),lineNo_,'E',"Scenario %s: action %s is not defined.",this->name(),pname->string());}
			else
				actionList_->add(pAction);}}}

//  Set Info ----------------------------------------------------------
void TgInfoTraffic::setInfo(void*,va_list ap) {
	DCLA(TgInfoScenarioFile*,scnFile);
	if(scnFile->connList()) {
		connect_ =scnFile->connList()->findByName(csConnect_);
		if(connect_==0) {
			CmLexer::eouts(fileName_.string(),lineNo_,'E',"Connection \"%s\" for Traffic \"%s\" is not defined.",csConnect_.string(),name());}}}

//====================================================================
//  Set mark to host --------------------------------------------------
void TgInfoTraffic::setHostRefMark() {
	connect_->client()->host()->setMark();
	connect_->server()->host()->setMark();}

void TgInfoCommand::setHostRefMark() {
	if(host_) host_->setMark();}

//====================================================================
// List
// search by name -=---------------------------------------------------
TgInfoIpName* TgInfoHost::findIpByName(const CmCString& ipName) const {
	if(nicList_==0) return 0;
	for(uint32_t n=0; n < nicList_->size(); ++n) {
		const TgInfoIpCltn* ipList=nicList_->index(n)->ipList();
		if(ipList==0) continue;
		for(uint32_t m=0; m < ipList->size(); ++m) {
			TgInfoIpName* ip=ipList->index(m);
			if(ip != 0 && ipName==ip->name())
			return ip;}}
	return 0;}

TgInfoAction* TgInfoActionCltn::findByName(const CmCString& name) const {
	for(uint32_t n=0; n < this->size(); ++n) {
		TgInfoAction* p=(TgInfoAction*)this->index(n);
		if(name==p->name()) return p;}
	return 0;}

TgInfoHost* TgInfoHostCltn::findByName(const CmCString& name) const {
	TgInfoHost key(name);
	return this->findMatching(&key);}

TgInfoNic* TgInfoNicCltn::findByName(const CmCString& name) const {
	TgInfoNic key(name);
	return this->findMatching(&key);}

TgInfoIpName* TgInfoIpCltn::findByName(const CmCString& name) const {
	TgInfoIpName key(name);
	return this->findMatching(&key);}

TgInfoConn* TgInfoConnCltn::findByName(const CmCString& name) const {
	TgInfoConn key(name);
	return this->findMatching(&key);}

TgInfoEvent* TgInfoEventCltn::findByName(const CmCString& name) const {
	TgInfoEvent key(name);
	return this->findMatching(&key);}

TgInfoScenario* TgInfoScenarioCltn::findByName(const CmCString name) const {
	TgInfoScenario key(name);
	return this->findMatching(&key);}

//====================================================================
// TgInfo:base class
TgInfo::TgInfo(CSTR file,int32_t line):fileName_(file),lineNo_(line) {}

//====================================================================
// Host
TgInfoHost::TgInfoHost(CSTR file,int32_t line,CmCString csName,TgInfoNicCltn* l,CmCString ts,uint32_t tn):
	TgInfo(file,line),TgBaseName(csName),
	nicList_(l),tgaPort_(0),tgaName_(ts),tga_no_(tn),mark_(false) {}
TgInfoHost::TgInfoHost(CmCString name):TgInfo(0,0),TgBaseName(name),
	nicList_(0),tgaPort_(0),tgaName_(0),tga_no_(0),mark_(false) {}
TgInfoHost::TgInfoHost(const TgInfoHost& ref) {*this=ref;}

//====================================================================
// NIC class
TgInfoNic::TgInfoNic(CSTR file,int32_t line,CmCString csNicName,CmCString csMacAddr,TgInfoIpCltn* pIpList):
	TgInfo(file,line),TgBaseName(csNicName),mac_(csMacAddr),ipList_(pIpList) {}
TgInfoNic::TgInfoNic(const CmCString name):TgBaseName(name),ipList_(0) {}

//====================================================================
// Ip Name - Base Class
TgInfoIpName::TgInfoIpName(CSTR file,int32_t line,CmCString csName):
	TgInfo(file,line),TgBaseName(csName.string()) {}
TgInfoIpName::TgInfoIpName(const CmCString& name):
	TgBaseName(name.string()) {}
TgInfoIpName::TgInfoIpName(const TgInfoIpName& ref):
	TgBaseName(ref.name()) {}
TgInfoIpName::TgInfoIpName() {}

//====================================================================
// Ip Name - IPV4
TgInfoIPV4Name::TgInfoIPV4Name(CSTR file,int32_t line,CmCString csIpName,in_addr& addr):
	TgInfoIpName(file,line,csIpName) { ipaddr_=addr; }
TgInfoIPV4Name::TgInfoIPV4Name(const TgInfoIPV4Name& ref) { *this=ref; }

//====================================================================
// Ip Name - IPV6
TgInfoIPV6Name::TgInfoIPV6Name(CSTR file,int32_t line,CmCString csIpName,in6_addr& addr):
	TgInfoIpName(file,line,csIpName) { ipaddr_=addr; }
TgInfoIPV6Name::TgInfoIPV6Name(const TgInfoIPV6Name& ref) { *this=ref; }

//====================================================================
// connection
TgInfoConn::TgInfoConn(
	CSTR file,int32_t line,const CmCString csName,Protocol ptcl,
	TgInfoPort* client,TgInfoPort* server):
	TgInfo(file,line),TgBaseName(csName),client_(client),server_(server),protocol_(ptcl) {}
TgInfoConn::TgInfoConn(const CmCString name): TgBaseName(name) {
	client_=0;
	server_=0;
	protocol_=TCP_;}
TgInfoConn::TgInfoConn(const TgInfoConn& ref) { *this=ref; }

//====================================================================
// Event
TgInfoEvent::TgInfoEvent(const CmCString name):TgBaseName(name) {}
TgInfoEvent::TgInfoEvent(CSTR file,int32_t line,const CmCString name,CStringList* actions):
	TgInfo(file,line),TgBaseName(name),actions_(actions) {}
TgInfoEvent::TgInfoEvent(const TgInfoEvent& ref) { *this=ref; }

//====================================================================
// Port
TgInfoPort::TgInfoPort(CSTR file,int32_t line,CmCString hostName,CmCString ipName,uint32_t port):
	TgInfo(file,line),host_(0),ipName_(0),port_(port),csHostName_(hostName),csIpName_(ipName) {}
TgInfoPort::TgInfoPort(CSTR file,int32_t line,TgInfoHost* pHost,TgInfoIpName* pIpName,
	uint32_t unPort):TgInfo(file,line),host_(pHost),ipName_(pIpName),port_(unPort) {}
TgInfoPort::TgInfoPort(const TgInfoPort& ref) { *this=ref; }

//====================================================================
// Scenario operarion
TgInfoScenario::TgInfoScenario(CSTR file,int32_t line,const CmCString name,CStringList* acts):
	TgInfo(file,line),TgBaseName(name),actionList_(0),actionName_(acts) {}
TgInfoScenario::TgInfoScenario(const CmCString name):
	TgBaseName(name),actionList_(0),actionName_(0) {}

//====================================================================
// Action - Base Class
TgInfoAction::TgInfoAction() {}
TgInfoAction::TgInfoAction(
	CSTR file,int32_t line,CmCString name,TgStatementCltn* stmtList):
	TgInfo(file,line),TgBaseName(name),statements_(stmtList) {
	if(stmtList!=0) {stmtList->elementsPerformWith((TgStatementFunc)&TgStatement::setAction,this);}}
TgInfoAction::TgInfoAction(CmCString name):TgBaseName(name),statements_(0) {}
TgInfoAction::TgInfoAction(const TgInfoAction& ref) { *this=ref; }

//====================================================================
// Action - Traffic
TgInfoTraffic::TgInfoTraffic(CSTR file,int32_t line,CmCString name,CmCString connName,TgStatementCltn* stmtList):
	TgInfoAction(file,line,name,stmtList),connect_(0),csConnect_(connName) {
	if(statements_) statements_->add(new TgStmtClose());}
TgInfoTraffic::TgInfoTraffic(const TgInfoTraffic& ref) { *this=ref; }

//====================================================================
// Command
TgInfoCommand::TgInfoCommand(CSTR file,int32_t line,CmCString name,CmCString host,
	TgStatementCltn* stmtList):
	TgInfoAction(file,line,name,stmtList),host_(0),csHost_(host) {}
TgInfoCommand::TgInfoCommand(const TgInfoCommand& ref) { *this=ref; }

//====================================================================
// Host Definition File
TgInfoHostFile::TgInfoHostFile(CSTR file,int32_t line,TgInfoHostCltn* hostList):hosts_(hostList) {
	if(hosts_==0) {
		CmLexer::eouts(file,line,'E',"No host definition in HostFile.");}}

//====================================================================
// Scenario File
TgInfoScenarioFile::TgInfoScenarioFile(CSTR file, int32_t line,
									   TgInfoConnCltn* connList,
									   TgInfoEventCltn* eventList,
									   TgInfoActionCltn* actList,
									   TgInfoScenarioCltn* scnList):
	connList_(connList), eventList_(eventList), 
	actionList_(actList), scenarioList_(scnList) {
#ifdef PACKAGE_NAME
	if (strcmp(PACKAGE_NAME, "vel") != 0) {
		// conn statement is a needless statement for interoperability test
		if (connList==0) {
			CmLexer::eouts(file,line,'E',"No Connection is defined in scenario file.");
		}
	}
#endif
	if (actList==0) {
		CmLexer::eouts(file,line,'E',"No Action is defined in scenario file.");
	}
}

//======================================================================
TgInfo& TgInfo::operator=(const TgInfo& ref) {
	fileName_=ref.fileName_;
	lineNo_=ref.lineNo_;
	return *this;}

TgInfoHost& TgInfoHost::operator=(const TgInfoHost& ref) {
	TgInfo::operator=(ref);
	TgBaseName::operator=(ref.name());
	tgaName_=ref.tgaName_;
	tga_no_ =ref. tga_no_;
	if(ref.tgaPort_)
		tgaPort_=new TgInfoPort(*ref.tgaPort_);
	else
		tgaPort_=0;
	mark_=false;
	return *this;}

TgInfoIpName& TgInfoIpName::operator=(const TgInfoIpName& ref) {
	TgInfo::operator=(ref);
	TgBaseName::operator=(ref.name());
	return *this;}

TgInfoIPV4Name& TgInfoIPV4Name::operator=(const TgInfoIPV4Name& ref) {
	TgInfo::operator=(ref);
	TgBaseName::operator=(ref.string());
	ipaddr_=ref.ipaddr_;
	return *this;}

TgInfoIPV6Name& TgInfoIPV6Name::operator=(const TgInfoIPV6Name& ref) {
	TgInfo::operator=(ref);
	TgBaseName::operator=(ref.name());
	ipaddr_=ref.ipaddr_;
	return *this;}

TgInfoConn& TgInfoConn::operator=(const TgInfoConn& ref) {
	TgInfo::operator=(ref);
	TgBaseName::operator=(ref.name());
	if(ref.client_)
		client_=new TgInfoPort(*ref.client_);
	else
		client_=0;
	if(ref.server_)
		server_=new TgInfoPort(*ref.server_);
	else
		server_=0;
	protocol_=ref.protocol_;
	return *this;}

TgInfoEvent& TgInfoEvent::operator=(const TgInfoEvent& ref) {
	TgBaseName::operator=(ref.name());
	actions_=new CStringList(*ref.actions_);
	return *this;}

TgInfoPort& TgInfoPort::operator=(const TgInfoPort& ref) {
	TgInfo::operator=(ref);
	host_=ref.host_;
	ipName_=ref.ipName_;
	port_=ref.port_;
	csHostName_=ref.csHostName_;
	csIpName_=ref.csIpName_;
	return *this;}

TgInfoAction& TgInfoAction::operator=(const TgInfoAction& ref) {
	TgInfo::operator=(ref);
	TgBaseName::operator=(ref.name());
	statements_=ref.statements_;
	return *this;}

TgInfoTraffic& TgInfoTraffic::operator=(const TgInfoTraffic& ref) {
	TgInfoAction::operator=(ref);
	connect_=ref.connect_;
	csConnect_=ref.csConnect_;
	return *this;}

TgInfoCommand& TgInfoCommand::operator=(const TgInfoCommand& ref) {
	TgInfoAction::operator=(ref);
	host_=ref.host_;
	csHost_=ref.csHost_;
	return *this;}

//====================================================================
void TgInfoHost::_printOut(void* s,va_list) const {
	uint32_t level=(uint32_t)s;
	_indent(level++);
	ooutf("Host:\"%s\" - %p\n",string(),this);
	if(nicList_) {
		nicList_->elementsPerformWith(
			(TgInfoNicFunc)&TgInfoNic::_printOut,(void*)level);}
	_indent(level++);
	ooutf("TgAgent:\n");
	if(tgaPort_) tgaPort_->_printOut((void*)level,(va_list)0);
	else {
		_indent(level);
		ooutf("%s,%d\n",tgaName_.string(),tga_no_);}}

void TgInfoNic::_printOut(void* s,va_list) const {
	uint32_t level=(uint32_t)s;
	_indent(level++);
	ooutf("NIC:\"%s\" - %p\n",string(),this);
	_indent(level);
	ooutf("MAC: %s\n",mac_.string());
	if(ipList_) {
		ipList_->elementsPerformWith(
			(TgInfoIpNameFunc)&TgInfoIpName::_printOut,
			(void*)level);}}

void TgInfoIPV4Name::_printOut(void* s,va_list) const {
	uint32_t level=(uint32_t)s;
	_indent(level);
	ooutf("IPV4:\"%s\" %s - %p\n",name(),::inet_ntoa(ipaddr_),this);}

void TgInfoIPV6Name::_printOut(void* s,va_list) const {
	uint32_t level=(uint32_t)s;
	char tmp[sizeof "ffff:ffff:ffff:ffff:ffff:ffff:255.255.255.255"];
	inet_ntop(AF_INET6,&ipaddr_,tmp,sizeof(tmp));
	_indent(level);
	ooutf("IPV6:\"%s\" %s - %p\n",name(),tmp,this);}

void TgInfoConn::_printOut(void* s,va_list) const {
	uint32_t level=(uint32_t)s;
	_indent(level++);
	ooutf("CONN:\"%s\" - %p\n",name(),this);
	TgInfoPortCltn portList;
	portList.add(client_);
	portList.add(server_);
	portList.elementsPerformWith(
		(TgInfoPortFunc)&TgInfoPort::_printOut,(void*)level);
	_indent(level);
	ooutf("Type: %s\n",(protocol_==TCP_ ? "TCP":"UDP"));}

void TgInfoEvent::_printOut(void* s,va_list) const {
	uint32_t level=(uint32_t)s;
	_indent(level++);
	ooutf("Event:\"%s\" ",name());
	for(uint32_t n=0; actions_ != 0 && n < actions_->size(); ++n)
		ooutf("%s ",(CmCString*)(actions_->index(n))->string());
	ooutf(" - 0x%X\n",this);}

void TgInfoPort::_printOut(void* s,va_list) const {
	uint32_t level=(uint32_t)s;
	_indent(level++);
	ooutf("Port: %s,%s,%d  - %p\n",
	csHostName_.string(),csIpName_.string(),port_,this);}

void TgInfoScenario::_printOut(void* s,va_list) const {
	uint32_t level=(uint32_t)s;
	_indent(level++);
	ooutf("SCENARIO:\"%s\" ",name());
	if(actionName_) {
		ooutf(" ( ");
		for(uint32_t n=0; n < actionName_->size(); ++n) {
			CmCString* str=(CmCString*)actionName_->at(n);
			ooutf("%s ",str->string());}
		ooutf(")");}
	ooutf(" - %p\n",this);
	if(actionList_)
	actionList_->elementsPerformWith(
		(TgInfoActionFunc)&TgInfoAction::_printOut,(void*)level);}

void TgInfoTraffic::_printOut(void* s,va_list) const {
	uint32_t level=(uint32_t)s;
	_indent(level++);
	ooutf("Traffic:\%s\" - %p\n",name(),this);
	_indent(level);
	ooutf("CONN: ");
	if(connect_) {
		ooutf("\"%s\" - %p\n",connect_->name(),connect_);}
	else {
		ooutf("\"%s\"\n",csConnect_.string());}
	if(statements_) {
		statements_->elementsPerformWith(
			   (TgStatementFunc)&TgStatement::_printOut,(void*)level);}}

void TgInfoCommand::_printOut(void* s,va_list) const {
	uint32_t level=(uint32_t)s;
	_indent(level++);
	ooutf("Command:\%s\" - %p\n",name(),this);
	_indent(level);
	ooutf("Host: ");
	if(host_) {
		ooutf("\"%s\" - %p\n",host_->name(),host_);}
	else {
		ooutf("\"%s\"\n",csHost_.string());}
	if(statements_) {
		statements_->elementsPerformWith(
			   (TgStatementFunc)&TgStatement::_printOut,(void*)level);}}

void TgInfoHostFile::printOut() const {
	ooutf("TgInfoHostFile: - %p\n",this);
	if(hosts_)
		hosts_->elementsPerformWith(
			(TgInfoHostFunc)&TgInfoHost::_printOut,(void*)1);}

void TgInfoScenarioFile::printOut() const {
	ooutf("ScenarioFile: - %p\n",this);
	if(connList_)
		connList_->elementsPerformWith(
			(TgInfoConnFunc)&TgInfoConn::_printOut,(void*)1);
	if(actionList_)
		actionList_->elementsPerformWith(
			(TgInfoActionFunc)&TgInfoAction::_printOut,(void*)1);
	if(scenarioList_)
		scenarioList_->elementsPerformWith(
			(TgInfoScenarioFunc)&TgInfoScenario::_printOut,(void*)1);}

//======================================================================
TgInfo::~TgInfo() {}
TgInfoHost::~TgInfoHost() {
	if(nicList_) {
		nicList_->deleteContents();
		delete nicList_;}
	if(tgaPort_) delete tgaPort_;}
TgInfoNic::~TgInfoNic() {
	if(ipList_) {
		ipList_->deleteContents();
		delete ipList_;}}
TgInfoIpName::~TgInfoIpName() {}
TgInfoIPV4Name::~TgInfoIPV4Name() {}
TgInfoIPV6Name::~TgInfoIPV6Name() {}
TgInfoConn::~TgInfoConn() {
	if(client_) delete client_;
	if(server_) delete server_;}
TgInfoEvent::~TgInfoEvent() {}
TgInfoPort::~TgInfoPort() {}
TgInfoScenario::~TgInfoScenario() {
	if(actionList_) delete actionList_;
	if(actionName_) {
		actionName_->deleteContents();
		delete actionName_;}}
TgInfoAction::~TgInfoAction() {
	if(statements_) delete statements_;}
TgInfoTraffic::~TgInfoTraffic() {}
TgInfoCommand::~TgInfoCommand() {}
TgInfoHostFile::~TgInfoHostFile() {
	if(hosts_) delete hosts_;}
TgInfoScenarioFile::~TgInfoScenarioFile() {
	if(connList_) delete connList_;
	if(actionList_) delete actionList_;
	if(scenarioList_) delete scenarioList_;}

//======================================================================
implementCmList(_TgInfoHostCltn,TgInfoHost);
implementCmList(_TgInfoNicCltn,TgInfoNic);
implementCmList(_TgInfoIpCltn,TgInfoIpName);
implementCmList(_TgInfoConnCltn,TgInfoConn);
implementCmList(_TgInfoEventCltn,TgInfoEvent);
implementCmList(TgInfoPortCltn,TgInfoPort);
implementCmList(_TgInfoScenarioCltn,TgInfoScenario);
implementCmList(_TgInfoActionCltn,TgInfoAction);

