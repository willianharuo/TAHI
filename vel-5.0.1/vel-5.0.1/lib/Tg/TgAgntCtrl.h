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
#if !defined(__TGAGNTCTRL_H__)
#define __TGAGNTCTRL_H__

//////////////////////////////////////////////////////////////////////
//									//
//		TgAgntCtrl: Agent Control Class				//
//									//
//////////////////////////////////////////////////////////////////////
#include <stdarg.h>
#include "CmCltn.h"
#include "CmSocket.h"
#include "TgClient.h"
#include "TgReqElm.h"

// ==================================================================
//  TgAgntCtrl - TgAgent Control Class
// ==================================================================
class TgInfoHost;
class TgAgntCtrlCltn;

class TgAgntCtrl:public TgClient,public TgBaseName {
	// properties ---------------------------------------------------
protected:
	TgReqCltn requests_;
	TgListenCltn listens_;
	TgAcceptCltn accepts_;
	TgConnCltn connects_;

	// constructor/destructor ---------------------------------------
protected:
	TgAgntCtrl(const CmCString name,CmSocket* sock=0);
public:
static	TgAgntCtrl*	createInstance(const TgInfoHost*);
virtual	~TgAgntCtrl();

	// Log ----------------------------------------------------------
protected:
	const TgStatement* log(const TgReqElm*) const;
	const TgStatement* throughput(CSTR,const TgReqElm*) const;

	// Status control -----------------------------------------------
protected:
	bool ready_;
public:
	void initialize(void*,va_list);
	bool isReady() const {return ready_;};

	// search -------------------------------------------------------
	bool isEqual(const TgAgntCtrl* e) const
	{return TgBaseName::isEqual(e);};

	// Operations ---------------------------------------------------
	bool opOpen(TgExecThread*,TgStatement*,int32_t,const CmSocket*,const CmSocket*,int16_t,bool&);
	bool opListen(TgExecThread*,TgStatement*,int32_t,const CmSocket*,int16_t,bool&);
	bool opConnect(TgExecThread*,TgStatement*,int32_t,const CmSocket*,int16_t,bool&);
	bool opAccept(TgExecThread*,TgStatement*,int32_t,const CmSocket*,const CmSocket*,int16_t,bool& lockf);
	bool opSend(TgExecThread*,TgStatement*,int32_t,const CmSocket*,int16_t,uint32_t,uint32_t,uint32_t,bool&);
	bool opReceive(TgExecThread*,TgStatement*,int32_t,const CmSocket*,int16_t,uint32_t,uint32_t,bool&);
	bool opSendRecv(TgExecThread*,TgStatement*,int32_t,const CmSocket*,int16_t,uint32_t,uint32_t,uint32_t,bool&);
	bool opRecvSend(TgExecThread*,TgStatement*,int32_t,const CmSocket*,int16_t,uint32_t,uint32_t,uint32_t,bool&);
	bool opRecvTerminate(TgExecThread*,TgStatement*,int32_t,const CmSocket*,int16_t,bool&);
	bool opClose(TgExecThread*,TgStatement*,int32_t,const CmSocket*,int16_t,bool&);
	bool opCommand(TgExecThread*,TgStatement*,int32_t,CSTR,bool&);
	int  opConnectConfirm(int16_t,int32_t,const CmSocket&);
	int  opAcceptedReport(int16_t,int16_t,int32_t,const CmSocket*);

protected:
	void openIndication(int16_t,int16_t,const CmSocket*,const CmSocket*);
	void listenIndication(int16_t,int16_t,const CmSocket*);
	void connectIndication(int16_t);
	void sndIndication(int16_t,uint32_t,uint32_t,uint32_t);
	void recvIndication(int16_t,uint32_t,uint32_t);
	void sndRecvIndication(int16_t,uint32_t,uint32_t,uint32_t);
	void recvSndIndication(int16_t,uint32_t,uint32_t,uint32_t);
	void recvTermIndication(int16_t);
	void closeIndication(int16_t);
	void commandIndication(int16_t,CSTR);

public:
virtual	int recvStartConfirm(int32_t);
virtual	int recvOpenConfirm(int16_t,int16_t,int32_t);
virtual	int recvListenConfirm(int16_t,int16_t,int32_t);
virtual	int recvAcceptedReport(int16_t,int16_t,int32_t,sockaddr_in&);
virtual	int recvAcceptedReport(int16_t,int16_t,int32_t,sockaddr_in6&);
virtual	int recvConnectConfirm(int16_t,int32_t,sockaddr_in&);
virtual	int recvConnectConfirm(int16_t,int32_t,sockaddr_in6&);
virtual	int recvSndConfirm(int16_t,int32_t);
virtual	int recvRecvConfirm(int16_t,int32_t);
virtual	int recvRecvEffectConfirm(int16_t,int32_t);
virtual	int recvSndrecvConfirm(int16_t,int32_t);
virtual	int recvRecvsndConfirm(int16_t,int32_t);
virtual	int recvCloseConfirm(int16_t,int32_t);
virtual	int recvCmdExecConfirm(int16_t,int32_t);
virtual	int recvCmdCancelConfirm(int16_t,int32_t);
virtual	int recvClosedReport(int16_t,int32_t);
virtual void connectionLost(CmSocket*);

	friend class TgAgntCtrlCltn;
};

// ==================================================================
//  TgAgntCtrlCltn - List of TgAgent Control Class
// ==================================================================
interfaceCmList(_TgAgntCtrlCltn,TgAgntCtrl);
class TgAgntCtrlCltn : public _TgAgntCtrlCltn {
public:
	TgAgntCtrl* findByName(const CmCString&) const;
	bool isAllReady() const;
};

#endif
