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
 *
 * TgInfo:TG Information classes
 */

#if !defined(__TgInfo_h__)
#define	__TgInfo_h__

#include <sys/types.h>
#include <sys/socket.h>
#include <netinet/in.h>
#include <arpa/inet.h>
#include "CmCltn.h"
#include "CmSocket.h"

#include "TgBase.h"
#include "TgPostPrcs.h"

class TgInfoHost;
class TgInfoNic;
class TgInfoIpName;
class TgInfoIPV4Name;
class TgInfoIPV6Name;
class TgInfoConn;
class TgInfoPort;
class TgInfoScenario;
class TgInfoAction;
class TgInfoTraffic;
class TgInfoCommand;
class TgInfoEvent;

class TgInfoHostFile;
class TgInfoScenarioFile;

class TgInfoHostCltn;
class TgInfoNicCltn;
class TgInfoIpCltn;
class TgInfoConnCltn;
class TgInfoPortCltn;
class ActionName;
class TgInfoScenarioCltn;
class TgInfoActionCltn;
class TgInfoEventCltn;

class TgStatementCltn;

// ====================================================================
//	TgInfo:base class
// ====================================================================
class TgInfo:public TgBaseObject {
protected:
	CmCString fileName_;
	int32_t lineNo_;
public:
	TgInfo(CSTR fileName = "",int32_t line = 0);
virtual	~TgInfo();
	TgInfo& operator=(const TgInfo& ref);
};

// ====================================================================
//	Host
// ====================================================================
class TgInfoHost:public TgInfo,public TgBaseName,public TgPostPrcs {
	friend class TgInfoHostCltn;	// Collection Class
protected:
	TgInfoNicCltn* nicList_;
	TgInfoPort* tgaPort_;
private:
	CmCString tgaName_;
	uint32_t tga_no_;
	bool mark_;
public:
	TgInfoHost(CSTR,int32_t,const CmCString,TgInfoNicCltn*,const CmCString,const uint32_t);
	TgInfoHost(const TgInfoHost&);
	TgInfoHost& operator=(const TgInfoHost&);
virtual	~TgInfoHost();
protected:
	TgInfoHost(const CmCString);
public:
virtual	void setInfo  (void*,va_list);
virtual	void _printOut(void*,va_list) const;
	TgInfoIpName* findIpByName(const CmCString&) const;
	void setMark(bool m=true) {mark_=m;}
	const TgInfoNicCltn* nicList() const {return nicList_;}
	const TgInfoPort* tgaPort() const {return tgaPort_;}
	const bool isMarked() const {return mark_;}
	bool isEqual(const TgInfoHost* e) const {return TgBaseName::isEqual(e);}
};

// ====================================================================
//	NIC
// ====================================================================
class TgInfoNic:public TgInfo,public TgBaseName {
	friend class TgInfoNicCltn;
protected:
	CmCString mac_;
	TgInfoIpCltn* ipList_;
public:
	TgInfoNic(CSTR,int32_t,const CmCString,const CmCString,TgInfoIpCltn*);
virtual	~TgInfoNic();
protected:
	TgInfoNic(const CmCString);
public:
virtual	void _printOut(void*,va_list) const;
	const CmCString&   macAddr() const  {return mac_;}
	const TgInfoIpCltn* ipList() const  {return ipList_;}
	bool isEqual(const TgInfoNic* e) const {return TgBaseName::isEqual(e);}
};

// ====================================================================
//	IP Statement(Base)
// ====================================================================
class TgInfoIpName:public TgInfo,public TgBaseName {
	friend class TgInfoIpCltn;
public:
	TgInfoIpName(CSTR,int32_t,const CmCString);
	TgInfoIpName(const TgInfoIpName&);
	TgInfoIpName();
	TgInfoIpName& operator=(const TgInfoIpName&);
virtual	~TgInfoIpName();
protected:
	TgInfoIpName(const CmCString&);
public:
virtual	CmSocket* socket(uint32_t) const {return 0;}
virtual	void _printOut(void*,va_list) const {}
virtual	int versionCode() const {return 0/*undefined*/;}
	bool isEqual(const TgInfoIpName* e) const {return TgBaseName::isEqual(e);}
};

// ====================================================================
//	IP Statement(IPV4)
// ====================================================================
class TgInfoIPV4Name:public TgInfoIpName {
protected:
	in_addr ipaddr_;
public:
	TgInfoIPV4Name(CSTR,int32_t,const CmCString,in_addr&);
	TgInfoIPV4Name(const TgInfoIPV4Name&);
	TgInfoIPV4Name& operator=(const TgInfoIPV4Name&);
virtual	~TgInfoIPV4Name();
virtual	CmSocket* socket(uint32_t) const;
virtual	void _printOut(void*,va_list) const;
virtual	int versionCode() const;
	in_addr ipAddr() const;
};
inline int TgInfoIPV4Name::versionCode() const {return 4;}
inline in_addr TgInfoIPV4Name::ipAddr() const {return ipaddr_;}

// ====================================================================
//	IP Statement(IPV6)
// ====================================================================
class TgInfoIPV6Name:public TgInfoIpName {
protected:
	in6_addr  ipaddr_;
public:
	TgInfoIPV6Name(CSTR,int32_t,const CmCString,in6_addr&);
	TgInfoIPV6Name(const TgInfoIPV6Name&);
	TgInfoIPV6Name& operator=(const TgInfoIPV6Name&);
virtual	~TgInfoIPV6Name();
virtual	CmSocket* socket(uint32_t) const;
virtual	void _printOut(void*,va_list) const;
virtual	int versionCode() const;
};
inline int TgInfoIPV6Name::versionCode() const {return 6;}

// ====================================================================
//	Connection
// ====================================================================
class TgInfoConn:public TgInfo,public TgBaseName,public TgPostPrcs {
	friend class TgInfoConnCltn;	// Collection Class
public:
	enum Protocol {TCP_, UDP_};
	enum Version  {IPv4_,IPv6_};
private:
	TgInfoPort* client_;
	TgInfoPort* server_;
	Protocol protocol_;
	Version version_;
public:
	TgInfoConn(CSTR,int32_t,const CmCString,const Protocol,TgInfoPort*,TgInfoPort*);
	TgInfoConn(const TgInfoConn&);
	TgInfoConn& operator=(const TgInfoConn&);
virtual	 ~TgInfoConn();
protected:
	TgInfoConn(const CmCString);
public:
virtual	void setInfo  (void*,va_list);
virtual	void _printOut(void*,va_list) const;
	TgInfoPort* client() const {return client_;}
	TgInfoPort* server() const {return server_;}
	Protocol protocol() const  {return protocol_;}
	Version version () const   {return version_;}
	bool isEqual(const TgInfoConn* e) const {return TgBaseName::isEqual(e);}
};

// ====================================================================
//	Port
// ====================================================================
class TgInfoPort:public TgInfo {
protected:
	TgInfoHost* host_;
	TgInfoIpName* ipName_;
	uint32_t port_;
private:
	CmCString  csHostName_;
	CmCString  csIpName_;
public:
	TgInfoPort(CSTR,int32_t,const CmCString,const CmCString,uint32_t);
	TgInfoPort(CSTR,int32_t,TgInfoHost*,TgInfoIpName*,uint32_t);
	TgInfoPort(const TgInfoPort&);
	TgInfoPort& operator=(const TgInfoPort&);
virtual	~TgInfoPort();
virtual	void _printOut(void*,va_list) const;
	bool setIpInfo(CSTR,TgInfoHostFile*);
	CmSocket* socket() const;
	TgInfoHost* host() const;
	TgInfoIpName* ipName() const;
	uint32_t port() const;
	int versionCode() const;
	bool isEqual(TgInfoPort* e) const;
};
inline TgInfoHost* TgInfoPort::host() const {return host_;}
inline TgInfoIpName* TgInfoPort::ipName() const {return ipName_;}
inline uint32_t TgInfoPort::port() const {return port_;}
inline int TgInfoPort::versionCode() const {return ipName()->versionCode();}
inline bool TgInfoPort::isEqual(TgInfoPort* e) const {
	return (csHostName_==e->csHostName_ &&
		csIpName_==e->csIpName_ &&
		port_==e->port_);}

// ====================================================================
//	Event
// ====================================================================
class TgInfoEvent:public TgInfo,public TgBaseName,public TgPostPrcs {
	friend class TgInfoEventCltn;	// Collection Class
protected:
	CStringList*  actions_;
public:
	TgInfoEvent(CSTR,int32_t,const CmCString,CStringList*);
	TgInfoEvent(const TgInfoEvent&);
	TgInfoEvent& operator=(const TgInfoEvent&);
virtual	~TgInfoEvent();
protected:
	TgInfoEvent(const CmCString);
public:
virtual	void setInfo(void*,va_list);
virtual	void _printOut(void*,va_list) const;
	CStringList* actions() const {return actions_;}
	bool isEqual(TgInfoEvent* e) const {return TgBaseName::isEqual(e);}
};

// ====================================================================
//	Scenario operarion
// ====================================================================
class TgInfoScenario:public TgInfo,public TgBaseName,public TgPostPrcs {
	friend class TgInfoScenarioCltn;		// Collection Class
protected:
	TgInfoActionCltn* actionList_;
private:
	CStringList*  actionName_;
public:
	TgInfoScenario(CSTR,int32_t,const CmCString,CStringList*);
virtual	~TgInfoScenario();
protected:
	TgInfoScenario(const CmCString);
public:
virtual	void setInfo(void*,va_list);
virtual	void _printOut(void*,va_list) const;
	TgInfoActionCltn* actionList() const {return actionList_;}
	bool isEqual(const TgInfoScenario* e) const {return TgBaseName::isEqual(e);}
};

// ====================================================================
//	Action
// ====================================================================
class TgInfoAction:public TgInfo,public TgBaseName,public TgPostPrcs {
protected:
	TgStatementCltn* statements_;
public:
	TgInfoAction();
	TgInfoAction(CSTR,int32_t,const CmCString,TgStatementCltn*);
	TgInfoAction(const CmCString);
	TgInfoAction(const TgInfoAction&);
	TgInfoAction& operator=(const TgInfoAction&);
virtual	~TgInfoAction();
virtual	void setInfo(void*,va_list) = 0;
virtual	void setHostRefMark() = 0;
virtual	void _printOut(void*,va_list) const = 0;
	TgStatementCltn*  stmtList() const {return statements_;}
	bool isEqual(const TgInfoAction* e) const {return TgBaseName::isEqual(e);}
};

// ====================================================================
//	Traffic Action
// ====================================================================
class TgInfoTraffic:public TgInfoAction {
protected:
	TgInfoConn*  connect_;
private:
	CmCString  csConnect_;
public:
	TgInfoTraffic(CSTR,int32_t,const CmCString,const CmCString,TgStatementCltn*);
	TgInfoTraffic(const TgInfoTraffic&);
	TgInfoTraffic& operator=(const TgInfoTraffic&);
virtual	~TgInfoTraffic();
virtual	void setInfo(void*,va_list);
virtual	void setHostRefMark();
virtual	void _printOut(void*,va_list) const;
	const TgInfoConn* connect() const  {return connect_;}
};

// ====================================================================
//	Command Action
// ====================================================================
class TgInfoCommand:public TgInfoAction {
protected:
	TgInfoHost*  host_;
private:
	CmCString  csHost_;
public:
	TgInfoCommand(CSTR,int32_t,const CmCString,const CmCString,TgStatementCltn*);
	TgInfoCommand(const TgInfoCommand&);
	TgInfoCommand& operator=(const TgInfoCommand&);
virtual	~TgInfoCommand();
virtual	void setInfo(void*,va_list);
virtual	void setHostRefMark();
virtual	void _printOut(void*,va_list) const;
	const TgInfoHost* pHost() const	{return host_;}
};

// ====================================================================
//	Host Definition File
// ====================================================================
class TgInfoHostFile {
protected:
	TgInfoHostCltn* hosts_;
public:
	TgInfoHostFile(CSTR,int32_t,TgInfoHostCltn*);
virtual	~TgInfoHostFile();
	void printOut() const;
	const TgInfoHostCltn* hostList() const	{return hosts_;}
};

// ====================================================================
//	Scenario File
// ====================================================================
class TgInfoScenarioFile {
protected:
	const TgInfoConnCltn*  connList_;
	const TgInfoEventCltn*  eventList_;
	const TgInfoActionCltn*  actionList_;
	const TgInfoScenarioCltn*  scenarioList_;
public:
	TgInfoScenarioFile(CSTR,int32_t,TgInfoConnCltn*,TgInfoEventCltn*,TgInfoActionCltn*,TgInfoScenarioCltn*);
virtual	~TgInfoScenarioFile();
	void printOut() const;
	const TgInfoConnCltn* connList() const {return connList_;}
	const TgInfoEventCltn* eventList() const {return eventList_;}
	const TgInfoActionCltn* actionList() const {return actionList_;}
	const TgInfoScenarioCltn* scenarioList() const {return scenarioList_;}
};

//======================================================================
interfaceCmList(_TgInfoHostCltn,TgInfoHost);
interfaceCmList(_TgInfoNicCltn,TgInfoNic);
interfaceCmList(_TgInfoIpCltn ,TgInfoIpName);
interfaceCmList(_TgInfoConnCltn ,TgInfoConn);
interfaceCmList(TgInfoPortCltn,TgInfoPort);
interfaceCmList(_TgInfoEventCltn,TgInfoEvent);
interfaceCmList(_TgInfoScenarioCltn ,TgInfoScenario);
interfaceCmList(_TgInfoActionCltn ,TgInfoAction);

class TgInfoHostCltn:public _TgInfoHostCltn {
public:
	TgInfoHost* findByName(const CmCString&) const;
};

class TgInfoNicCltn:public _TgInfoNicCltn {
public:
	TgInfoNic* findByName(const CmCString&) const;
};

class TgInfoIpCltn:public _TgInfoIpCltn {
public:
	TgInfoIpName* findByName(const CmCString&) const;
};

class TgInfoConnCltn:public _TgInfoConnCltn {
public:
	TgInfoConn* findByName(const CmCString&) const;
};

class TgInfoEventCltn:public _TgInfoEventCltn {
public:
	TgInfoEvent* findByName(const CmCString&) const;
};

class TgInfoScenarioCltn:public _TgInfoScenarioCltn {
public:
	TgInfoScenario* findByName(const CmCString) const;
};

class TgInfoActionCltn:public _TgInfoActionCltn {
public:
	TgInfoAction*  findByName(const CmCString&) const;
};
#endif
