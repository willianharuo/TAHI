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
#if !defined(__TgServer_h__)
#define	__TgServer_h__	1
#include "TcAgent.h"
#include "TcAccept.h"
#include "TgDefine.h"
#include "TgIF.h"
#include "TeClient.h"

struct TcAgent;
struct TcAgentSet;
struct TcAccept;
struct TcSocket;
struct TeClient;

struct TgServer:public TgInterface {
private:
	TeClient* cmdproxy_;
	void connectionLost(CmSocket*);
	TcAgentSet* agentSet_;
	int response(int16_t,int16_t,int16_t,int32_t,int32_t =0,CSTR =0);
	int myResponse(int32_t,int32_t=0,CSTR=0);
	TcSocket* makeSocket();
	TcAccept* makeAccepter(trafficInfo* =0);
	trafficInfo& getTrafficInfo();
	struct timeval stime_;
	struct timeval etime_;
	int closeAgntConnection(TcAgent*);
public:
	TgServer(CmSocket*);
virtual	~TgServer();
	void	setStartTime();
	void	setStartTime(const struct timeval*);
	void	setEndTime();
	void	setEndTime(const struct timeval*);
//----------------------------------------------------------------------
// member function of receiving Request
public: 
	TcAgent* addAgent(TcAgent*);
	TcAgent* removeAgent(TcAgent*);
	TcAgent* findAgent();
	TcAgent* findAgent(int);
	int report(int16_t,int16_t,int,int32_t,int32_t=0,CSTR=0);
	int report(int16_t,int16_t,int,int32_t,trafficInfo*,struct timeval&,struct timeval&);
	int report(int16_t,int16_t,int,int32_t,int16_t,sockaddr*,struct timeval&,struct timeval&);
virtual int startRequest();
virtual int openRequest();
virtual int listenRequest();
virtual int connectRequest();
virtual int sndRequest();
virtual int recvRequest();
virtual int recvEffectRequest();
virtual int sndrecvRequest();
virtual int recvsndRequest();
virtual int connectsndRequest();
virtual int connectsndrecvRequest();
virtual int lietenrecvRequest();
virtual int listenrecvsndRequest();
virtual int closeRequest();
virtual int cmdexecRequest();
virtual int cmdcancelRequest();
//----------------------------------------------------------------------
// member function of receiving Report
public:
	int closedSocket(TcAgent*);
//----------------------------------------------------------------------
protected:
	TcAgentSet& agentSet();
};
#endif
