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
#ifndef __TcAgent_h__
#define __TcAgent_h__	1
#include "CmSocket.h"
#include "CmAgent.h"
#include "TgServer.h"

struct CmAgent;
struct CmSocket;
struct TgServer;

struct TcAgent:public CmAgent {
private:
	CmSocket *socket_;
	TgServer *server_;
	int16_t request_;
	int receipt_;
public:
	TcAgent(int);
	TcAgent(int16_t,CmSocket*,TgServer*,int);
virtual	~TcAgent();
virtual	int fileDesc() const;
	CmSocket* socket() const;
	TgServer* server() const;
virtual	int16_t request() const;
	void request(const int16_t);
virtual	int receipt() const;
	void receipt(const int);
	int hash() const;
	bool isEqual(const TcAgent* o) const;
	void close();
virtual	void print();
	int send(CSTR,int32_t);
	void vsend(CSTR,va_list);
virtual	int connectIndication(){return 0;};
virtual	int sndIndication(const int32_t,const int32_t,const uint32_t){return 0;};
virtual	int recvIndication(const int32_t,const int32_t){return 0;};
virtual	int recvEffectIndication(){return 0;};
virtual	int sndrecvIndication(const int32_t,const int32_t,const int32_t,const uint32_t){return 0;};
virtual	int recvsndIndication(const int32_t,const int32_t,const int32_t){return 0;};
};
inline CmSocket* TcAgent::socket() const {return socket_;}
inline TgServer* TcAgent::server() const {return server_;}
inline int TcAgent::fileDesc() const {return (socket_!=0)?socket_->fileDesc():-1;}
inline void TcAgent::request(const int16_t r) {request_=r;}
inline int16_t TcAgent::request() const {return request_;}
inline void TcAgent::receipt(const int r) {receipt_=r;}
inline int TcAgent::receipt() const {return receipt_;}
inline int TcAgent::hash() const {return receipt_;}
inline bool TcAgent::isEqual(const TcAgent* o) const {
	return (o->receipt()==receipt_);}
inline void TcAgent::print() {socket()->print();}

interfaceCmSet(TcAgentSet,TcAgent);
#endif
