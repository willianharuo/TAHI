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
#if !defined(__TgClient_h__)
#define __TgClient_h__ 1
#include <sys/time.h>
#include "TgDefine.h"
#include "TgIF.h"

struct CmDispatch;
struct TgFrame;

struct TgClient:public TgInterface {
public:
        TgClient(CmSocket*);
virtual ~TgClient();
private:
	CmDispatch* dispatch_;
	void createConnection(time_t,uint32_t);
	trafficInfo	effect_;
	struct timeval	start_;
	struct timeval	end_;
	void setEffectTime(TgFrame* f);
	void setEffectInfo(TgFrame* f);
public:
	bool start();
	const trafficInfo& effectInfo() const;
	const timeval& startTime() const;
	const timeval& endTime() const;
//--------------------------------------------------------------------
// received confirmation from TgServer
private:
	int startConfirm();
	int openConfirm();
	int listenConfirm();
	int acceptedReport();
	int connectConfirm();
	int sndConfirm();
	int recvConfirm();
	int recvEffectConfirm();
	int sndrecvConfirm();
	int recvsndConfirm();
	int connectsndConfirm();
	int connectsndrecvConfirm();
	int lietenrecvConfirm();
	int listenrecvsndConfirm();
	int closeConfirm();
	int closedReport();
	int cmdexecConfirm();
	int cmdcancelConfirm();
//--------------------------------------------------------------------
// send indication to TgServer
public:
virtual void sendStartIndication(CSTR);
virtual void sendOpenIndication(int16_t,int16_t,sockaddr_in&,sockaddr_in&);
virtual void sendOpenIndication(int16_t,int16_t,sockaddr_in6&,sockaddr_in6&);
virtual void sendListenIndication(int16_t,int16_t,sockaddr_in&);
virtual void sendListenIndication(int16_t,int16_t,sockaddr_in6&);
virtual void sendConnectIndication(int16_t);
virtual void sendSndIndication(int16_t,trafficInfo*);
virtual void sendRecvIndication(int16_t,trafficInfo*);
virtual void sendRecvEffectIndication(int16_t);
virtual void sendSndRecvIndication(int16_t,trafficInfo*);
virtual void sendRecvSndIndication(int16_t,trafficInfo*);
virtual void sendConnectSndIndication(int16_t,trafficInfo*);
virtual void sendConnectSndRecvIndication(int16_t,trafficInfo*);
virtual void sendListenRecvIndication(int16_t,sockaddr_in&,trafficInfo*);
virtual void sendListenRecvIndication(int16_t,sockaddr_in6&,trafficInfo*);
virtual void sendListenRecvSndIndication(int16_t,sockaddr_in&,trafficInfo*);
virtual void sendListenRecvSndIndication(int16_t,sockaddr_in6&,trafficInfo*);
virtual void sendCloseIndication(int16_t);
virtual void sendCmdExecIndication(int16_t,CSTR);
virtual void sendCmdCancelIndication(int16_t);
//
//
virtual	int recvStartConfirm(int32_t){return 0;};
virtual	int recvOpenConfirm(int16_t,int16_t,int32_t){return 0;};
virtual	int recvListenConfirm(int16_t,int16_t,int32_t){return 0;};
virtual	int recvAcceptedReport(int16_t,int16_t,int32_t,sockaddr_in&){return 0;};
virtual	int recvAcceptedReport(int16_t,int16_t,int32_t,sockaddr_in6&){return 0;};
virtual	int recvConnectConfirm(int16_t,int32_t,sockaddr_in&){return 0;};
virtual	int recvConnectConfirm(int16_t,int32_t,sockaddr_in6&){return 0;};
virtual	int recvSndConfirm(int16_t,int32_t){return 0;};
virtual	int recvRecvConfirm(int16_t,int32_t){return 0;};
virtual	int recvRecvEffectConfirm(int16_t,int32_t){return 0;};
virtual	int recvSndrecvConfirm(int16_t,int32_t){return 0;};
virtual	int recvRecvsndConfirm(int16_t,int32_t){return 0;};
virtual	int recvConnectsndConfirm(int16_t,int32_t){return 0;};
virtual	int recvConnectsndrecvConfirm(int16_t,int32_t){return 0;};
virtual	int recvListenrecvConfirm(int16_t,int32_t){return 0;};
virtual	int recvListenrecvsndConfirm(int16_t,int32_t){return 0;};
virtual	int recvCloseConfirm(int16_t,int32_t){return 0;};
virtual	int recvClosedReport(int16_t,int32_t){return 0;};
virtual	int recvCmdExecConfirm(int16_t,int32_t){return 0;};
virtual	int recvCmdCancelConfirm(int16_t,int32_t){return 0;};
//
};
inline	const trafficInfo& TgClient::effectInfo() const {return effect_;}
inline	const timeval& TgClient::startTime() const {return start_;}
inline	const timeval& TgClient::endTime() const {return end_;}
#endif
