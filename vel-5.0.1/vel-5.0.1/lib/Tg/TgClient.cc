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
#include <stdio.h>
#include "CmMain.h"
#include "CmDispatch.h"
#include "TgFrame.h"
#include "TgClient.h"

struct TgFrame;

///////////////////////////////////////////////////////////////////////
//
///////////////////////////////////////////////////////////////////////
TgClient::TgClient(CmSocket* s):TgInterface(s),dispatch_(dispatch()) {}

TgClient::~TgClient() {}

bool TgClient::start() {
	CmSocket* s=socket();
	if((s->connect())<0) {
		s->close();
		return false;}
	if(dbgFlags['c']) {printf("TgClient::start "); s->print();}
	receiver();
	return true;
}

void TgClient::setEffectTime(TgFrame* f){
	f->decode(&start_);
	f->decode(&end_);
}

void TgClient::setEffectInfo(TgFrame* f){
	f->decode(&effect_);
}

///////////////////////////////////////////////////////////////////////
//	Traffic Genarate Manager -> Traffic Genarate Agent
///////////////////////////////////////////////////////////////////////
// (0) say Hello!
void TgClient::sendStartIndication(CSTR fname) {
        tcpHead h(eStart_,0);
        sendPacket(h,strlen(fname),fname);
}

// (1) release socket
void TgClient::sendOpenIndication(int16_t n,int16_t k,sockaddr_in& s,sockaddr_in& d) {
        tcpHead h(eOpen_,n);
	TgFrame f(OPEN_IND_LEN);
	f.encode(k);
	int16_t tmp=0;	//filler
	f.encode(tmp);
	f.encode(s);
	f.encode(d);
        sendPacket(h,f.length(),f.buffer(0));
}

void TgClient::sendOpenIndication(int16_t n,int16_t k,sockaddr_in6& s,sockaddr_in6& d) {
	tcpHead h(eOpen_,n);
	TgFrame f(OPEN6_IND_LEN);
	f.encode(k);
	int16_t tmp=0;	//filler
	f.encode(tmp);
	f.encode(s);
	f.encode(d);
        sendPacket(h,f.length(),f.buffer(0));
}

// (2) release socket + listen
void TgClient::sendListenIndication(int16_t n,int16_t k,sockaddr_in& s){
        tcpHead h(eListen_,n);
	TgFrame f(LISTEN_IND_LEN);
	f.encode(k);
	int16_t tmp=0;	//filler
	f.encode(tmp);
	f.encode(s);
        sendPacket(h,f.length(),f.buffer(0));
}

void TgClient::sendListenIndication(int16_t n,int16_t k,sockaddr_in6& s){
	tcpHead h(eListen_,n);
	TgFrame f(LISTEN6_IND_LEN);
	f.encode(k);
	int16_t tmp=0;	//filler
	f.encode(tmp);
	f.encode(s);
        sendPacket(h,f.length(),f.buffer(0));
}

// (3) connect
void TgClient::sendConnectIndication(int16_t r){
        tcpHead h(eConnect_,0,r);
        sendPacket(h,0,0);
}

// (4) send
void TgClient::sendSndIndication(int16_t r,trafficInfo* i){
        tcpHead h(eSnd_,0,r);
        sendPacket(h,sizeof(trafficInfo),(CSTR)i);
}

// (5) receive
void TgClient::sendRecvIndication(int16_t r,trafficInfo* i){
        tcpHead h(eRecv_,0,r);
        sendPacket(h,sizeof(trafficInfo),(CSTR)i);
}

// (5') receive effect
void TgClient::sendRecvEffectIndication(int16_t r){
        tcpHead h(eRecvEffect_,0,r);
        sendPacket(h,0,0);
}
// (6) send + receive
void TgClient::sendSndRecvIndication(int16_t r,trafficInfo* i){
        tcpHead h(eSndRecv_,0,r);
        sendPacket(h,sizeof(trafficInfo),(CSTR)i);
}

// (7) receive + send
void TgClient::sendRecvSndIndication(int16_t r,trafficInfo* i){
        tcpHead h(eRecvSnd_,0,r);
        sendPacket(h,sizeof(trafficInfo),(CSTR)i);
}

// (8) connect + send
void TgClient::sendConnectSndIndication(int16_t r,trafficInfo* i){
        tcpHead h(eConnectSnd_,0,r);
        sendPacket(h,sizeof(trafficInfo),(CSTR)i);
}

// (9) connect + send + receive
void TgClient::sendConnectSndRecvIndication(int16_t r,trafficInfo* i){
        tcpHead h(eConnectSndRecv_,0,r);
        sendPacket(h,sizeof(trafficInfo),(CSTR)i);
}

// (10) listen + receive
void TgClient::sendListenRecvIndication(int16_t k,sockaddr_in& s,trafficInfo* i){
	tcpHead h(eListenRecv_,0);
	TgFrame f(LISTEN_IND_LEN+sizeof(trafficInfo));
	f.encode(k);
	int16_t tmp=0;	//filler
	f.encode(tmp);
	f.encode(s);
	f.encode(i,sizeof(trafficInfo));
        sendPacket(h,f.length(),f.buffer(0));
}
void TgClient::sendListenRecvIndication(int16_t k,sockaddr_in6& s,trafficInfo* i){
	tcpHead h(eListenRecv_,0);
	TgFrame f(LISTEN6_IND_LEN+sizeof(trafficInfo));
	f.encode(k);
	int16_t tmp=0;	//filler
	f.encode(tmp);
	f.encode(s);
	f.encode(i,sizeof(trafficInfo));
        sendPacket(h,f.length(),f.buffer(0));
}

// (11) listen + receive + send
void TgClient::sendListenRecvSndIndication(int16_t k,sockaddr_in& s,trafficInfo* i){
	tcpHead h(eListenRecvSnd_,0);
	TgFrame f(LISTEN_IND_LEN+sizeof(trafficInfo));
	f.encode(k);
	int16_t tmp=0;	//filler
	f.encode(tmp);
	f.encode(s);
	f.encode(i,sizeof(trafficInfo));
        sendPacket(h,f.length(),f.buffer(0));
}
void TgClient::sendListenRecvSndIndication(int16_t k,sockaddr_in6& s,trafficInfo* i){
	tcpHead h(eListenRecvSnd_,0);
	TgFrame f(LISTEN6_IND_LEN+sizeof(trafficInfo));
	f.encode(k);
	int16_t tmp=0;	//filler
	f.encode(tmp);
	f.encode(s);
	f.encode(i,sizeof(trafficInfo));
        sendPacket(h,f.length(),f.buffer(0));
}

// (12) close
void TgClient::sendCloseIndication(int16_t r){
        tcpHead h(eClose_,0,r);
        sendPacket(h,0,0);
}

// (13) command execute
void TgClient::sendCmdExecIndication(int16_t r,CSTR cmd){
        tcpHead h(eCmdExec_,r);
        sendPacket(h,strlen(cmd),cmd);
}

// (14) command cancel
void TgClient::sendCmdCancelIndication(int16_t r){
        tcpHead h(eCmdCancel_,r);
        sendPacket(h,0,0);
}

///////////////////////////////////////////////////////////////////////
//	Traffic Genarate Agent -> Traffic Genarate Manager 
///////////////////////////////////////////////////////////////////////
// (0) say Hello!
int TgClient::startConfirm(){
	int32_t result=header().result();
	recvStartConfirm(result);
	return 0;
}

// (1) release socket
int TgClient::openConfirm(){
	int16_t	reqno=header().reqno();
	int16_t	receipt=header().receipt();
	int32_t result=header().result();
	TgFrame f(header().length(),buffer(0));
	setEffectTime(&f);
	recvOpenConfirm(reqno,receipt,result);
	return 0;
}

// (2) release socket + listen
int TgClient::listenConfirm(){
	int16_t	reqno=header().reqno();
	int16_t	receipt=header().receipt();
	int32_t result=header().result();
	TgFrame f(header().length(),buffer(0));
	setEffectTime(&f);
	recvListenConfirm(reqno,receipt,result);
	return 0;
}

int TgClient::acceptedReport(){
	int16_t	reqno=header().reqno();
	int16_t	receipt=header().receipt();
	int32_t result=header().result();
	int16_t k=connKind();
	TgFrame f(header().length(),buffer(0));
	int16_t tmp=0;
	f.decode(&k);
	f.decode(&tmp);
	sockaddr_in d4;
	sockaddr_in6 d6;
	switch(k){
	  case eV4St_:
		f.decode(&d4);
		recvAcceptedReport(reqno,receipt,result,d4);
		break;
	  case eV6St_:
		f.decode(&d6);
		recvAcceptedReport(reqno,receipt,result,d6);
		break;
	  default:
		break;
	}
	return 0;
}

// (3) connect
int TgClient::connectConfirm(){
	int16_t	receipt=header().receipt();
	int32_t result=header().result();
	int16_t k=connKind();
	TgFrame f(header().length(),buffer(0));
	int16_t tmp=0;
	f.decode(&k);
	f.decode(&tmp);
	sockaddr_in d4;
	sockaddr_in6 d6;
	switch (k){
	  case eV4St_: case eV4Dg_:
		f.decode(&d4);
		setEffectTime(&f);
		recvConnectConfirm(receipt,result,d4);
		break;
	  case eV6St_: case eV6Dg_:
		f.decode(&d6);
		setEffectTime(&f);
		recvConnectConfirm(receipt,result,d6);
		break;
	  default:
		break;
	}
	return 0;
}

// (4) send
int TgClient::sndConfirm(){
	int16_t	receipt=header().receipt();
	int32_t result=header().result();
	TgFrame f(header().length(),buffer(0));
	setEffectInfo(&f);
	setEffectTime(&f);
	recvSndConfirm(receipt,result);
	return 0;
}

// (5) receive
int TgClient::recvConfirm(){
	int16_t	receipt=header().receipt();
	int32_t result=header().result();
	TgFrame f(header().length(),buffer(0));
	setEffectTime(&f);
	recvRecvConfirm(receipt,result);
	return 0;
}

// (5') receive effect
int TgClient::recvEffectConfirm(){
	int16_t	receipt=header().receipt();
	int32_t result=header().result();
	TgFrame f(header().length(),buffer(0));
	setEffectInfo(&f);
	setEffectTime(&f);
	recvRecvEffectConfirm(receipt,result);
	return 0;
}

// (6) send + receive
int TgClient::sndrecvConfirm(){
	int16_t	receipt=header().receipt();
	int32_t result=header().result();
	TgFrame f(header().length(),buffer(0));
	setEffectInfo(&f);
	setEffectTime(&f);
	recvSndrecvConfirm(receipt,result);
	return 0;
}

// (7) receive + send
int TgClient::recvsndConfirm(){
	int16_t	receipt=header().receipt();
	int32_t result=header().result();
	TgFrame f(header().length(),buffer(0));
	setEffectTime(&f);
	recvRecvsndConfirm(receipt,result);
	return 0;
}

// (8) connect + send
int TgClient::connectsndConfirm(){
	int16_t	receipt=header().receipt();
	int32_t result=header().result();
	TgFrame f(header().length(),buffer(0));
	setEffectInfo(&f);
	setEffectTime(&f);
	recvConnectsndConfirm(receipt,result);
	return 0;
}

// (9) connect + send + receive
int TgClient::connectsndrecvConfirm(){
	int16_t	receipt=header().receipt();
	int32_t result=header().result();
	TgFrame f(header().length(),buffer(0));
	setEffectInfo(&f);
	setEffectTime(&f);
	recvConnectsndrecvConfirm(receipt,result);
	return 0;
}

// (10) listen + receive
int TgClient::lietenrecvConfirm(){
	int16_t	receipt=header().receipt();
	int32_t result=header().result();
	TgFrame f(header().length(),buffer(0));
	setEffectTime(&f);
	recvListenrecvConfirm(receipt,result);
	return 0;
}

// (11) listen + receive + send
int TgClient::listenrecvsndConfirm(){
	int16_t	receipt=header().receipt();
	int32_t result=header().result();
	TgFrame f(header().length(),buffer(0));
	setEffectTime(&f);
	recvListenrecvsndConfirm(receipt,result);
	return 0;
}

// (12) close
int TgClient::closeConfirm(){
	int16_t	receipt=header().receipt();
	int32_t result=header().result();
	TgFrame f(header().length(),buffer(0));
	setEffectTime(&f);
	recvCloseConfirm(receipt,result);
	return 0;
}

// (12') closed
int TgClient::closedReport(){
	int16_t	receipt=header().receipt();
	int32_t result=header().result();
	TgFrame f(header().length(),buffer(0));
	setEffectTime(&f);
	recvClosedReport(receipt,result);
	return 0;
}

// (13) command execute
int TgClient::cmdexecConfirm(){
	int16_t	reqno=header().reqno();
	int32_t result=header().result();
	TgFrame f(header().length(),buffer(0));
	setEffectTime(&f);
	recvCmdExecConfirm(reqno,result);
	return 0;
}

// (14) command cancel
int TgClient::cmdcancelConfirm(){
	int16_t	reqno=header().reqno();
	int32_t result=header().result();
	TgFrame f(header().length(),buffer(0));
	setEffectTime(&f);
	recvCmdCancelConfirm(reqno,result);
	return 0;
}

