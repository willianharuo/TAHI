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
#ifndef __TeIF_h__
#define __TeIF_h__   1
#include "TgTypes.h"
#include "TeAgent.h"

/* Interface Definition */
struct TeInterface:public TeAgent {
private:
	tcpHead header_;
	int32_t allocated_;
	STR buffer_;
//----------------------------------------------------------------------
// SendRequest
public:
virtual int cmdExecRequest();
virtual int cmdCancelRequest();
//----------------------------------------------------------------------
// ReceiveConfirm
protected:
virtual	int cmdExecConfirm();
virtual	int cmdCancelConfirm();
//----------------------------------------------------------------------
public:
	int receivePacket(int);
	TeInterface(CmSocket* =0);
virtual	~TeInterface();
	void receiver();
protected:
	int sendPacket(tcpHead&,int32_t =0,CSTR =0);
	void debugPacket(CSTR,const tcpHead&,int32_t,CSTR);
	int receiveBuffer(STR,int32_t);
virtual void connectionLost(CmSocket*){};
virtual	int receiveHeader();
virtual	int receiveBody();
	int request() const;
	int result() const;
	STR buffer(int32_t);
	int bodyLength() const;
	const tcpHead& header() const;
	int response(int16_t,int16_t,int16_t,int32_t,int32_t =0,CSTR =0);
	int analizeRequest(int32_t);
	int analizeConfirm(int32_t);
	int analizePacket();
};
inline void TeInterface::receiver() {
	readAction((agentFunc)&TeInterface::receivePacket);}
inline const tcpHead& TeInterface::header() const {return header_;}
inline int TeInterface::request() const {return header_.request();}
inline int TeInterface::bodyLength() const {return header_.length();}
inline int TeInterface::result() const {return header_.result();}
#endif
