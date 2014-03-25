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
#include "TeAgent.h"
#include <stdio.h>
#include <stdlib.h>
#include <unistd.h>
#include <errno.h>
#include <sys/param.h>
#include "TeIF.h"
#include "TgDefine.h"
#include "CmMain.h"

TeInterface::TeInterface(CmSocket* s):TeAgent(s),
	header_(),allocated_(0),buffer_(0) {}
TeInterface::~TeInterface() {
	if(buffer_) {delete [] buffer_; buffer_=0;}}

void TeInterface::debugPacket(CSTR sr,const tcpHead& h,int32_t l,CSTR s) {
	printf("%s: request=%4.4x, len=%d result=%d",
		sr,h.request()&0xffff,l,h.result());
	dump(l,s); printf("\n");}

int TeInterface::sendPacket(tcpHead& h,int32_t l,CSTR s) {
	h.length(l);
	if(dbgFlags['p']) {
		debugPacket("S",h,l,s);}
	int rc=send((CSTR)&h,sizeof(h));
	if(rc>=0 && l>0) {rc=send(s,l);}
	return rc;}

STR TeInterface::buffer(int32_t l) {
	if(allocated_<l) {
		delete [] buffer_; buffer_=0;
		int32_t n=packetSize<l?l:packetSize;
		buffer_=new char[(allocated_=round8(n))];}
	return buffer_;}

int TeInterface::receiveBuffer(STR s,int32_t len) {
        CmSocket* sock=socket();
	if(sock==0) {return -1;}
	int l=sock->recvAll(s,len);
	return l;}

int TeInterface::response(int16_t n,int16_t rn,int16_t rc,int32_t v,int32_t l,CSTR s) {
	tcpHead h;
	h.request(n|eResponse_);
	h.reqno(rn);
	h.receipt(rc);
	h.result(v);
	return sendPacket(h,l,s)>=0?0:-1;}

//======================================================================
int TeInterface::receiveHeader() {
	return receiveBuffer((STR)&header_,sizeof(header_));}
	
int TeInterface::receiveBody() {
	int l=bodyLength();
	if(l==0) {return 0;}
	return receiveBuffer(buffer(l),l);}

int TeInterface::analizeRequest(int32_t r) {
	int rc=0;
	switch(r) {
		case eCmdExec_:
			rc=cmdExecRequest();
			break;
		case eCmdCancel_:
			rc=cmdCancelRequest();
			break;
		default:
			/* nop */			break;}
	return rc;}

int TeInterface::analizeConfirm(int32_t r) {
	int rc=0;
	switch(r) {
		case eCmdExec_:
			rc=cmdExecConfirm();
			break;
		case eCmdCancel_:
			rc=cmdCancelConfirm();
			break;
		default:
			/* nop */			break;}
	return rc;}

int TeInterface::analizePacket() {
	int rc=0;
	eRequest r=(eRequest)request();
	if(dbgFlags['p']) {
		debugPacket("R",header(),bodyLength(),buffer(0));}
	if(r&eResponse_)	{rc=analizeConfirm(r&eMask_);}
	else			{rc=analizeRequest(r);}
	return rc;}

int TeInterface::receivePacket(int) {
	if(receiveHeader()<0||receiveBody()<0) {
		CmSocket* sock=socket();
		connectionLost(sock);
		return -1;}
	return analizePacket();}

int TeInterface::cmdExecRequest() {return 0;}
int TeInterface::cmdCancelRequest() {return 0;}
int TeInterface::cmdExecConfirm() {return 0;}
int TeInterface::cmdCancelConfirm() {return 0;}
