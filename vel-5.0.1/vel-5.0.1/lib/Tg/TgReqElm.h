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
 */
#if !defined(__TgReqElm_h__)
#define __TgReqElm_h__

//////////////////////////////////////////////////////////////////////
//									//
//		TgAgntCtrl: Agent Control Class				//
//									//
//////////////////////////////////////////////////////////////////////
#include <stdarg.h>
#include "CmCltn.h"
#include "CmSocket.h"

// ==================================================================
//	Statement - Callback Class
// ==================================================================
class TgStatement;
class TgStmtCb {
protected:
	TgStatement* caller_;
	int32_t reqid_;
public:
	TgStmtCb(TgStatement* caller = 0, int32_t reqid = 0);
	TgStmtCb(const TgStmtCb&);
	TgStmtCb& operator=(const TgStmtCb&);
virtual	~TgStmtCb();

	CSTR thread();

	void complete();
	void error(uint32_t);
	void expired ();
inline	TgStatement* caller() const;
	bool isEqual(const TgStmtCb* cb) {
		return (caller_ == cb->caller_ && reqid_ == cb->reqid_);}
};
inline TgStatement* TgStmtCb::caller() const {return caller_;}
interfaceCmList(TgStmtCbList, TgStmtCb);

// ==================================================================
//  List of Request
// ==================================================================
class TgReqElm;
class TgReqCltn;
class TgExecThread;
class CmSocket;
// Element class ---------------------------------------------------
class TgReqElm : public TgStmtCb {
	// properties
public:
	enum enStatus {
		REQ_OPEN,
		REQ_LISTEN,
		REQ_ACCEPT,
		REQ_EXECCMD,
		REQ_CONNECT,
		REQ_SEND,
		REQ_RECV,
		REQ_SENDRECV,
		REQ_RECVSEND,
		REQ_RECVTERM,
		REQ_CLOSE,
		REQ_CMDEXEC};
protected:
	enStatus  stat_;
	int16_t  id_;
	const TgExecThread* thread_;
	const CmSocket* addr_;
	int16_t  type_;

	// constructor / destructor
public:
	TgReqElm(enStatus,int16_t,TgExecThread*,TgStatement*,int32_t,const CmSocket*,int16_t);
	TgReqElm(const TgReqElm&);
	const TgReqElm& operator=(const TgReqElm&);
virtual	~TgReqElm();

	// utility : get new Request No.
public:
static	int32_t newRequestNo() {
		static	int32_t rno_base = 1;
		return rno_base++;}

	// acces to properties
public:
	enStatus status() const			{return stat_;};
	int16_t id() const			{return id_;};
	const TgExecThread* thread() const	{return thread_;};
	const CmSocket* addr() const		{return addr_;};
	int16_t type() const			{return type_;};

	// search
protected:
	TgReqElm(int16_t id,enStatus stat);
	TgReqElm();
public:
	uint32_t hash() const;
	bool isEqual(const TgReqElm* e) const;

	friend class TgReqCltn;
};

// ==================================================================
//  List of Connecting/Listening Sockets
// ==================================================================
class TgListenElm;
class TgListenCltn;

// Element ----------------------------------------------------------
class TgListenElm {
	// properties
public:
	enum enStatus {REQ_LISTEN,LISTEN};

protected:
	enStatus stat_;
	int16_t id_req_;
	int16_t id_sock_;
	const CmSocket* addr_;

	//	constructor / destructor
public:
	TgListenElm(enStatus,int16_t,int16_t,const CmSocket*);
	TgListenElm(const TgListenElm&);
	const TgListenElm& operator=(const TgListenElm&);
virtual	~TgListenElm();

	// access to properties
public:
	enStatus status() const		{return stat_;};
	int16_t id_req() const		{return id_req_;};
	int16_t id_sock() const		{return id_sock_;};
	const CmSocket* addr() const	{return addr_;};

	// search
protected:
	TgListenElm(const CmSocket*);
	TgListenElm();
public:
	uint32_t hash() const;
	bool isEqual(const TgListenElm* pe) const;

	friend class TgListenCltn;
};

// ==================================================================
//  List of Accepted Sockets
// ==================================================================
class TgAcceptElm;
class TgAcceptCltn;

// Element class ---------------------------------------------------
class TgAcceptElm {
	// properties
protected:
	int16_t id_sock_;
	const CmSocket* caddr_;
	const CmSocket* saddr_;

	// constructor / destructor
public:
	TgAcceptElm(int16_t,const CmSocket*,const CmSocket*);
	TgAcceptElm(const TgAcceptElm&);
	const TgAcceptElm& operator=(const TgAcceptElm&);
virtual	~TgAcceptElm();

	// access to properties
public:
	int32_t id_sock() const	{return id_sock_;};
	const CmSocket* caddr() const {return caddr_;};
	const CmSocket* saddr() const {return saddr_;};

	// search
protected:
	TgAcceptElm(const CmSocket* caddr,const CmSocket* saddr);
	TgAcceptElm();
public:
	uint32_t hash() const;
	bool isEqual(const TgAcceptElm*) const;

	friend class TgAcceptCltn;
};

// ==================================================================
//  List of Opened Sockets
// ==================================================================
class TgConnElm;
class TgConnCltn;

// Element class ---------------------------------------------------
class TgConnElm {
	// properties
public:
	enum enStatus {OPENED,CONNECTED,CLOSING};
protected:
	enStatus stat_;
	int16_t id_sock_;
	const CmSocket* addr_;
	const TgExecThread* thread_;

	// constructor/destructor
public:
	TgConnElm(enStatus,int16_t,const CmSocket*,const TgExecThread*);
	TgConnElm(const TgConnElm&);
	const TgConnElm& operator=(const TgConnElm&);
virtual	~TgConnElm();

	//	access to properties
public:
	enStatus status() const			{return stat_;}
	int16_t id_sock() const			{return id_sock_;}
	const CmSocket* addr() const		{return addr_;}
	const TgExecThread* thread() const	{return thread_;}
	void setStatus(enStatus newStat)	{stat_=newStat;}

	// search
protected:
	TgConnElm(const CmSocket*,const TgExecThread*,enStatus);
	TgConnElm();
public:
	uint32_t hash() const;
	bool isEqual(const TgConnElm* e) const;

	friend class TgConnCltn;
};

// Collection class -------------------------------------------------
interfaceCmSet(_TgReqCltn,TgReqElm);
class TgReqCltn : public _TgReqCltn {
public:
	TgReqElm* find(int16_t,TgReqElm::enStatus);
};

// Collection Class --------------------------------------------------
interfaceCmSet(_TgListenCltn,TgListenElm);
class TgListenCltn : public _TgListenCltn {
public:
	TgListenElm* find(int16_t) const;
	TgListenElm* find(const CmSocket*);
};

// Collection class -------------------------------------------------
interfaceCmSet(_TgAcceptCltn,TgAcceptElm);
class TgAcceptCltn: public _TgAcceptCltn {
public:
	TgAcceptElm* find(const CmSocket*,const CmSocket*);
};

// Collection class -------------------------------------------------
interfaceCmSet(_TgConnCltn,TgConnElm);
class TgConnCltn: public _TgConnCltn {
public:
	TgConnElm* find(int16_t);
	TgConnElm* find(const CmSocket*,const TgExecThread*,TgConnElm::enStatus);
};
#endif
