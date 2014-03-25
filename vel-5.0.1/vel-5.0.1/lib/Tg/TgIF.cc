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
#include "TgAgent.h"
#include <stdio.h>
#include <stdlib.h>
#include <unistd.h>
#include <errno.h>
#include <sys/param.h>
#include "TgIF.h"
#include "TgDefine.h"
#include "CmMain.h"

trafficInfo::trafficInfo(uint32_t sc,uint32_t s,uint32_t rc,uint32_t r,uint32_t t):scount_(htonl(sc)),slen_(htonl(s)),rcount_(htonl(rc)),rlen_(htonl(r)),sinterval_(htonl(t)){};

TgInterface::TgInterface(CmSocket* s):TgAgent(s),
	header_(),allocated_(0),buffer_(0) {}
TgInterface::~TgInterface() {
	if(buffer_) {delete [] buffer_; buffer_=0;}}

void TgInterface::debugPacket(CSTR sr,const tcpHead& h,int32_t l,CSTR s) {
        CmSocket* sock=socket();
	int r=h.request();
	printf("%s: %d request=%s-%s len=%d req=%d receipt=%d result=%d",
		sr,sock!=0?sock->fileDesc():-1,
		(r&eResponse_)?"RSP":"REQ",requestName(r&eMask_),
		l,h.reqno(),h.receipt(),h.result());
	dump(l,s); printf("\n");}

int TgInterface::sendPacket(tcpHead& h,int32_t l,CSTR s) {
	h.length(l);
	if(dbgFlags['p']) {
		debugPacket("S",h,l,s);}
	int rc=send((CSTR)&h,sizeof(h));
	if(rc>=0 && l>0) {rc=send(s,l);}
	return rc;}

STR TgInterface::buffer(int32_t l) {
	if(allocated_<l) {
		delete [] buffer_; buffer_=0;
		int32_t n=packetSize<l?l:packetSize;
		buffer_=new char[(allocated_=round8(n))];}
	return buffer_;}

int TgInterface::receiveBuffer(STR s,int32_t len) {
        CmSocket* sock=socket();
	if(sock==0) {return -1;}
	int l=sock->recvAll(s,len);
	return l;}

int TgInterface::response(int16_t n,int16_t rn,int16_t rc,int32_t v,int32_t l,CSTR s) {
	return report(n|eResponse_,rn,rc,v,l,s);
}
int TgInterface::report(int16_t n,int16_t rn,int16_t rc,int32_t v,int32_t l,CSTR s) {
	tcpHead h;
	h.request(n);
	h.reqno(rn);
	h.receipt(rc);
	h.result(v);
	return sendPacket(h,l,s)>=0?0:-1;}
//======================================================================
int TgInterface::receiveHeader() {
	return receiveBuffer((STR)&header_,sizeof(header_));}
	
int TgInterface::receiveBody() {
	int l=bodyLength();
	if(l==0) {return 0;}
	return receiveBuffer(buffer(l),l);}

CSTR TgInterface::requestName(uint32_t r) const {
	CSTR rc="UNKNOWN";
	uint32_t e=(r&eMask_);
	switch(e) {
		case eStart_:		rc="START";		break;
		case eOpen_:		rc="OPEN";		break;
		case eClose_:		rc="CLOSE";		break;
		case eClosed_:		rc="CLOSED";		break;
		case eListen_:		rc="LISTEN";		break;
		case eAccepted_:	rc="ACCEPTED";		break;
		case eConnect_:		rc="CONNECT";		break;
		case eSnd_:		rc="SEND";		break;
		case eRecv_:		rc="W-RECV";		break;
		case eRecvEffect_:	rc="RECV";		break;
		case eSndRecv_:		rc="SENDRECV";		break;
		case eRecvSnd_:		rc="W-RECVSEND";	break;
		case eConnectSnd_:	rc="CONNSEND";		break;
		case eConnectSndRecv_:	rc="CONNSENDRECV";	break;
		case eListenRecv_:	rc="LSNRECV";		break;
		case eListenRecvSnd_:	rc="LSNRECVSND";	break;
		case eCmdExec_:		rc="EXECUTE";		break;
		case eCmdCancel_:	rc="CANCEL";		break;
		default: break;}
	return rc;}

int TgInterface::analizeRequest(uint32_t r) {
	int rc=0;
	if(logLevel==1){
		printf("request-%s\n", requestName(r));
	}
	switch(r) {
		case eStart_:
			rc=startRequest();	break;
		case eOpen_:
			rc=openRequest();	break;
		case eClose_:
			rc=closeRequest();	break;
		case eClosed_:
			rc=closedReport();	break;
		case eListen_:
			rc=listenRequest();	break;
		case eConnect_:
			rc=connectRequest();	break;
		case eAccepted_:
			rc=acceptedReport();	break;
		case eSnd_:
			rc=sndRequest();	break;
		case eRecv_:
			rc=recvRequest();	break;
		case eRecvEffect_:
			rc=recvEffectRequest();	break;
		case eSndRecv_:
			rc=sndrecvRequest();	break;
		case eRecvSnd_:
			rc=recvsndRequest();	break;
		case eConnectSnd_:
			rc=connectsndRequest();	break;
		case eConnectSndRecv_:
			rc=connectsndrecvRequest();	break;
		case eListenRecv_:
			rc=lietenrecvRequest();	break;
		case eListenRecvSnd_:
			rc=listenrecvsndRequest();	break;
		case eCmdExec_:
			rc=cmdexecRequest();	break;
		case eCmdCancel_:
			rc=cmdcancelRequest();	break;
		default:
			/* nop */			break;}
	return rc;}

int TgInterface::analizeConfirm(uint32_t r) {
	int rc=0;
	switch(r) {
		case eStart_:
			rc=startConfirm();	break;
		case eOpen_:
			rc=openConfirm();	break;
		case eListen_:
			rc=listenConfirm();	break;
		case eConnect_:
			rc=connectConfirm();	break;
		case eSnd_:
			rc=sndConfirm();	break;
		case eRecv_:
			rc=recvConfirm();	break;
		case eRecvEffect_:
			rc=recvEffectConfirm();	break;
		case eSndRecv_:
			rc=sndrecvConfirm();	break;
		case eRecvSnd_:
			rc=recvsndConfirm();	break;
		case eConnectSnd_:
			rc=connectsndConfirm();	break;
		case eConnectSndRecv_:
			rc=connectsndrecvConfirm();	break;
		case eListenRecv_:
			rc=lietenrecvConfirm();	break;
		case eListenRecvSnd_:
			rc=listenrecvsndConfirm();	break;
		case eClose_:
			rc=closeConfirm();	break;
		case eCmdExec_:
			rc=cmdexecConfirm();	break;
		case eCmdCancel_:
			rc=cmdcancelConfirm();	break;
		default:
			/* nop */			break;}
	return rc;}

int TgInterface::analizePacket() {
	int rc=0;
	eRequest r=(eRequest)request();
	if(dbgFlags['p']) {
		debugPacket("R",header(),bodyLength(),buffer(0));}
	if(r&eResponse_)	{rc=analizeConfirm(r&eMask_);}
	else			{rc=analizeRequest(r);}
	return rc;}

int TgInterface::receivePacket(int) {
	if(receiveHeader()<0||receiveBody()<0) {
		CmSocket* sock=socket();
		connectionLost(sock);
		return -1;}
	return analizePacket();}

int TgInterface::startRequest() {return 0;}
int TgInterface::openRequest() {return 0;}
int TgInterface::closeRequest() {return 0;}
int TgInterface::listenRequest() {return 0;}
int TgInterface::connectRequest() {return 0;}
int TgInterface::sndRequest() {return 0;}
int TgInterface::recvRequest() {return 0;}
int TgInterface::recvEffectRequest() {return 0;}
int TgInterface::sndrecvRequest() {return 0;}
int TgInterface::recvsndRequest() {return 0;}
int TgInterface::connectsndRequest() {return 0;}
int TgInterface::connectsndrecvRequest() {return 0;}
int TgInterface::lietenrecvRequest() {return 0;}
int TgInterface::listenrecvsndRequest() {return 0;}
int TgInterface::cmdexecRequest() {return 0;}
int TgInterface::cmdcancelRequest() {return 0;}

int TgInterface::startConfirm() {return 0;}
int TgInterface::openConfirm() {return 0;}
int TgInterface::listenConfirm() {return 0;}
int TgInterface::acceptedReport() {return 0;}
int TgInterface::connectConfirm() {return 0;}
int TgInterface::sndConfirm() {return 0;}
int TgInterface::recvConfirm() {return 0;}
int TgInterface::recvEffectConfirm() {return 0;}
int TgInterface::sndrecvConfirm() {return 0;}
int TgInterface::recvsndConfirm() {return 0;}
int TgInterface::connectsndConfirm() {return 0;}
int TgInterface::connectsndrecvConfirm() {return 0;}
int TgInterface::lietenrecvConfirm() {return 0;}
int TgInterface::listenrecvsndConfirm() {return 0;}
int TgInterface::cmdexecConfirm() {return 0;}
int TgInterface::cmdcancelConfirm() {return 0;}
int TgInterface::closeConfirm() {return 0;}
int TgInterface::closedReport() {return 0;}

