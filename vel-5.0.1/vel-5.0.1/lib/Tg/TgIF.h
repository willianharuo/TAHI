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
#ifndef __TgIF_h__
#define __TgIF_h__   1
#include "TgAgent.h"
#include "TgTypes.h"

#define CONN_KIND_LEN sizeof(int16_t)+sizeof(int16_t)
#define OPEN_IND_LEN CONN_KIND_LEN+sizeof(sockaddr_in)+sizeof(sockaddr_in)
#define OPEN6_IND_LEN CONN_KIND_LEN+sizeof(sockaddr_in6)+sizeof(sockaddr_in6)
#define LISTEN_IND_LEN CONN_KIND_LEN+sizeof(sockaddr_in)
#define LISTEN6_IND_LEN CONN_KIND_LEN+sizeof(sockaddr_in6)

struct trafficInfo {
private:
	uint32_t	scount_;
	uint32_t	slen_;	
	uint32_t	rcount_;
	uint32_t	rlen_;
	uint32_t	sinterval_;
public:
	const uint32_t	scount() const;
	const uint32_t	rcount() const;
	const uint32_t	slen() const;
	const uint32_t	rlen() const;
	const uint32_t	sinterval() const;
	trafficInfo(uint32_t sc=0,uint32_t rc=0,uint32_t s=0,uint32_t r=0,uint32_t t=0);
	void	scount(uint32_t);
	void	rcount(uint32_t);
	void	slen(uint32_t);
	void	rlen(uint32_t);
	void	sinterval(uint32_t);
};
inline const uint32_t trafficInfo::scount() const {return ntohl(scount_);}
inline const uint32_t trafficInfo::rcount() const {return ntohl(rcount_);}
inline const uint32_t trafficInfo::slen() const {return ntohl(slen_);}
inline const uint32_t trafficInfo::rlen() const {return ntohl(rlen_);}
inline const uint32_t trafficInfo::sinterval() const {return ntohl(sinterval_);}
inline void trafficInfo::scount(uint32_t v) {scount_=htonl(v);}
inline void trafficInfo::rcount(uint32_t v) {rcount_=htonl(v);}
inline void trafficInfo::slen(uint32_t v) {slen_=htonl(v);}
inline void trafficInfo::rlen(uint32_t v) {rlen_=htonl(v);}
inline void trafficInfo::sinterval(uint32_t v) {sinterval_=htonl(v);}

struct TgInterface:public TgAgent {
private:
	tcpHead header_;
	int32_t allocated_;
	STR buffer_;
//----------------------------------------------------------------------
// SendRequest
public:
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
// ReceiveConfirm
protected:
virtual	int startConfirm();
virtual	int openConfirm();
virtual	int listenConfirm();
virtual	int acceptedReport();
virtual	int connectConfirm();
virtual	int sndConfirm();
virtual	int recvConfirm();
virtual	int recvEffectConfirm();
virtual	int sndrecvConfirm();
virtual	int recvsndConfirm();
virtual	int connectsndConfirm();
virtual	int connectsndrecvConfirm();
virtual	int lietenrecvConfirm();
virtual	int listenrecvsndConfirm();
virtual	int closeConfirm();
virtual	int closedReport();
virtual	int cmdexecConfirm();
virtual	int cmdcancelConfirm();
//----------------------------------------------------------------------
public:
inline	int16_t connKind();
	int receivePacket(int);
	TgInterface(CmSocket* =0);
virtual	~TgInterface();
inline	void receiver();
inline	CSTR requestName() const;
protected:
	int sendPacket(tcpHead&,int32_t =0,CSTR =0);
	void debugPacket(CSTR,const tcpHead&,int32_t,CSTR);
	int receiveBuffer(STR,int32_t);
virtual void connectionLost(CmSocket*){};
virtual	int receiveHeader();
virtual	int receiveBody();
inline	uint16_t request() const;
inline	int result() const;
	STR buffer(int32_t);
inline	int bodyLength() const;
	const tcpHead& header() const;
	int response(int16_t,int16_t,int16_t,int32_t,int32_t =0,CSTR =0);
	int report(int16_t,int16_t,int16_t,int32_t,int32_t =0,CSTR =0);
	int analizeRequest(uint32_t);
	int analizeConfirm(uint32_t);
	int analizePacket();
	CSTR requestName(uint32_t r) const;
};
inline void TgInterface::receiver() {
	readAction((agentFunc)&TgInterface::receivePacket);}
inline const tcpHead& TgInterface::header() const {return header_;}
inline uint16_t TgInterface::request() const {return header_.request();}
inline int TgInterface::bodyLength() const {return header_.length();}
inline int TgInterface::result() const {return header_.result();}
inline int16_t TgInterface::connKind() {return htons(*(int16_t*)buffer(0));}
inline CSTR TgInterface::requestName() const {return requestName(request());}
#endif
