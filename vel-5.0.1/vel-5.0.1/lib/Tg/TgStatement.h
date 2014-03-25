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
 * TgStatement:Action Statement Class
 */
#if !defined(__TgStatement_h__)
#define	__TgStatement_h__

#include <sys/types.h>
#include <sys/socket.h>
#include <netinet/in.h>
#include <arpa/inet.h>
#include <sys/time.h>
#include "CmCltn.h"
#include "CmSocket.h"
#include "timeval.h"

#include "TgBase.h"
#include "TgInfo.h"
#include "TgPostPrcs.h"

class TgExecThread;
class TgExecDelayTimer;

// ==================================================================
//	Statement - BaseClass
// ==================================================================
class TgInfoAction;
class TgAgntCtrl;
class TgAgntCtrlCltn;
class TgInfoConn;

class TgStatement:public TgBaseObject {
protected:
	TgExecThread* thread_;
	TgAgntCtrlCltn* agents_;
	const TgInfoAction* action_;
	CmCString fileName_;
	int32_t lineNo_;
	int32_t step_;
	int32_t errors_;
	timeval startTime_;
	timeval endTime_;
	
public:
	//	constructor
	TgStatement(CSTR="", int32_t=0);
	TgStatement(const TgStatement&);
	TgStatement& operator=(const TgStatement&);

	//	destructor
virtual	~TgStatement();

	//	Event Control
protected:
static	int32_t id_seed_;
#define	ID_SIZE	32
	int32_t  id_lock[ID_SIZE];

	int32_t  getReqId();
	void  lock(int32_t);
	void  unlock(int32_t);
	int32_t  numWaits() const;

	//	Processing Control
public:
virtual	void setAction(void*,...);
virtual	void  reset(void*, va_list);
virtual	bool  doStep(bool&) = 0;	// abstruct

virtual	void  onExpired (int32_t);
virtual	void  onComplete(int32_t);
virtual	void  onError(int32_t, uint32_t);

	//	Information
public:
virtual	CSTR name() const = 0;
virtual	void  _printOut(void*, va_list) const = 0;
	CSTR  thread() const;
	void managerLog(CSTR,...) const;
virtual	void log(const TgAgntCtrl*) const;
virtual	void throughput(CSTR,const TgAgntCtrl*) const;
inline	const timeval& startTime() const;
inline	const timeval& endTime() const;

	//  Log
protected:
	void setTime(timeval&);
};
inline	const timeval& TgStatement::startTime() const {return startTime_;}
inline	const timeval& TgStatement::endTime() const {return endTime_;}

// ==================================================================
//	Statement List
// ==================================================================
typedef void (TgStatement::*TgStatementFunc)(void*,...) const;

class TgStatementCltn:public BtList {
public:
	interfaceBtCltn(List, TgStatementCltn, TgStatement);
};

// ==================================================================
//	Traffic Statements(Connect/OneWay/Turnaround/Close)
// ==================================================================

class TrafficStatement:public TgStatement {
public:
	TrafficStatement();
	TrafficStatement(CSTR,int32_t);
	TrafficStatement(CSTR,int32_t,uint32_t,uint32_t,uint32_t,uint32_t);
	TrafficStatement& operator=(const TrafficStatement&);
protected:
	uint32_t  sendlen_;
	uint32_t  recvlen_;
	uint32_t  count_;
	uint32_t  interval_;

inline	TgInfoConn::Protocol protocol() const;
inline	TgInfoConn::Version version() const;
inline	TgInfoPort* clientPort() const;
inline	TgInfoPort* serverPort() const;
	void logTP(const TgAgntCtrl*,CSTR,uint32_t,uint32_t) const;
virtual	void throughput(CSTR,const TgAgntCtrl*) const;
};

inline TgInfoConn::Protocol TrafficStatement::protocol() const {
	return (((TgInfoTraffic*)action_)->connect())->protocol(); };
inline TgInfoConn::Version TrafficStatement::version() const {
	return (((TgInfoTraffic*)action_)->connect())->version(); };
inline TgInfoPort* TrafficStatement::clientPort() const {
	return (((TgInfoTraffic*)action_)->connect())->client(); };
inline TgInfoPort* TrafficStatement::serverPort() const {
	return (((TgInfoTraffic*)action_)->connect())->server(); };

inline TrafficStatement::TrafficStatement():
	sendlen_(0),recvlen_(0),count_(0),interval_(0) { }

inline TrafficStatement::TrafficStatement(CSTR file,int32_t line) :
	TgStatement(file,line),
	sendlen_(0),recvlen_(0),count_(0),interval_(0) { }

inline TrafficStatement::TrafficStatement(CSTR file,int32_t line,
	uint32_t sendlen,uint32_t recvlen,uint32_t count,uint32_t interval) :
	TgStatement(file,line),sendlen_(sendlen),recvlen_(recvlen),
	count_(count),interval_(interval) {}

inline TrafficStatement& TrafficStatement::operator=(const TrafficStatement& ref) {
	TgStatement::operator=(ref);
	sendlen_ = ref.sendlen_;
	recvlen_ = ref.recvlen_;
	count_ = ref.count_;
	interval_ = ref.interval_;
	return *this;}

// Connect Statement ------------------------------------------------
class TgStmtConnect:public TrafficStatement {
public:
	TgStmtConnect(CSTR,int32_t);
	TgStmtConnect(const TgStmtConnect&);
	TgStmtConnect& operator=(const TgStmtConnect&);
virtual	~TgStmtConnect();

virtual	CSTR name() const { return "connect"; };
virtual	void _printOut(void*, va_list) const;
virtual	bool doStep(bool&);
};

// OneWay Statement -------------------------------------------------
class TgStmtOneWay:public TrafficStatement {
public:
	TgStmtOneWay(CSTR,int32_t,uint32_t,uint32_t,uint32_t=0);
	TgStmtOneWay(const TgStmtOneWay&);
	TgStmtOneWay& operator=(const TgStmtOneWay&);
virtual	~TgStmtOneWay();

virtual	CSTR name() const { return "oneway"; };
virtual	void _printOut(void*, va_list) const;
virtual	bool doStep(bool&);
};

// Turnaround Statement ---------------------------------------------
class TgStmtTurnaround:public TrafficStatement {
public:
	TgStmtTurnaround(CSTR,int32_t,uint32_t,uint32_t,uint32_t=0);
	TgStmtTurnaround(const TgStmtTurnaround&);
	TgStmtTurnaround& operator=(const TgStmtTurnaround&);
virtual	~TgStmtTurnaround();

virtual	CSTR name() const { return "turnaround"; };
virtual	void  _printOut(void*, va_list) const;
virtual	bool  doStep(bool&);
};

// Close(dummy) Statement -------------------------------------------
class TgStmtClose:public TrafficStatement {
public:
	TgStmtClose();
	TgStmtClose(const TgStmtClose&);
	TgStmtClose& operator=(const TgStmtClose&);
virtual	~TgStmtClose();

virtual	CSTR name() const { return "close"; };
virtual	void  _printOut(void*, va_list) const;
virtual	bool  doStep(bool&);
};

// ==================================================================
//	Delay Statement
// ==================================================================
class TgStmtDelay:public TgStatement {
protected:
	uint32_t  delaySec_;
private:
	TgExecDelayTimer* timer_;
public:
	TgStmtDelay(CSTR,int32_t,uint32_t);
	TgStmtDelay(const TgStmtDelay&);
	TgStmtDelay& operator=(const TgStmtDelay&);

virtual	~TgStmtDelay();

virtual	CSTR name() const { return "delay"; };
virtual	void  _printOut(void*, va_list) const;
virtual	void  reset(void*, va_list);
virtual	bool  doStep(bool&);
};

// ==================================================================
//	Execute Statement
// ==================================================================
class TgStmtExecute:public TgStatement {
protected:
	CmCString  command_;
public:
	TgStmtExecute(CSTR,int32_t);
	TgStmtExecute(CSTR,int32_t, const CmCString);
	TgStmtExecute(const TgStmtExecute&);
	TgStmtExecute& operator=(const TgStmtExecute&);

virtual	~TgStmtExecute();

virtual	CSTR name() const { return "execute"; };
virtual	void  _printOut(void*, va_list) const;
virtual	bool  doStep(bool&);
inline const CmCString command() const;
};
inline const CmCString TgStmtExecute::command() const {
	return command_;
}

// ==================================================================
//	Sync Statement
// ==================================================================
class TgStmtSync:public TgStatement, public TgPostPrcs {
protected:
	CmCString event_;
public:
	TgStmtSync(CSTR,int32_t);
	TgStmtSync(CSTR,int32_t,const CmCString);
	TgStmtSync(const TgStmtSync&);
	TgStmtSync& operator=(const TgStmtSync&);
virtual	~TgStmtSync();

virtual	CSTR name() const { return "sync"; };
virtual	void setInfo  (void*, va_list);
virtual	void _printOut(void*, va_list) const;
virtual	bool  doStep(bool&);
};

// ==================================================================
//	Wait Statement
// ==================================================================
class TgStmtWait:public TgStatement, public TgPostPrcs {
protected:
	CmCString event_;
public:
	TgStmtWait(CSTR,int32_t);
	TgStmtWait(CSTR,int32_t,const CmCString);
	TgStmtWait(const TgStmtWait&);
	TgStmtWait& operator=(const TgStmtWait&);
virtual	~TgStmtWait();

virtual	CSTR name() const { return "wait"; };
virtual	void setInfo  (void*, va_list);
virtual	void _printOut(void*, va_list) const;
virtual	bool  doStep(bool&);
};

// ==================================================================
//	Print Statement
// ==================================================================
class TgStmtPrint:public TgStatement {
protected:
	CmCString  str_;
public:
	TgStmtPrint(CSTR,int32_t, const CmCString);
	TgStmtPrint(const TgStmtPrint&);
	TgStmtPrint& operator=(const TgStmtPrint&);

virtual	~TgStmtPrint();

virtual	CSTR name() const { return "print"; };
virtual	void  _printOut(void*, va_list) const;
virtual	bool  doStep(bool&);
};

#endif
