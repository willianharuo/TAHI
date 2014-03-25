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
 *
 *  HostDefParser : Parser for Host Definition File
 */

#include <stdio.h>
#include <string.h>
#include "CmSocket.h"
#include "TgHostDef.h"

// ====================================================================
//  HostDefParser
// ====================================================================

//  Constructor / Destructor ------------------------------------------
HostDefParser::HostDefParser(CSTR file):
	lexer_(file),hostList_(0),nicList_(0),ipList_(0),tgaInfo_(0),macAddr_(0) {}

HostDefParser::~HostDefParser() {
	if(hostList_) delete hostList_;
	if(nicList_) delete nicList_;
	if(ipList_) delete ipList_;
	if(tgaInfo_) delete tgaInfo_;
	if(macAddr_) delete macAddr_;}

//  "HOST" file operation ---------------------------------------------
TgInfoHostFile* HostDefParser::HostFile() {
	TgInfoHostFile* hostFile=new TgInfoHostFile(lexer_.fileName(),lexer_.lineNo(),hostList_);
	hostList_=0;
	return hostFile;}

//  "HOST" statement --------------------------------------------------
void HostDefParser::HostStatement(CmCString* name) {
	if(hostList_ && hostList_->findByName(*name)) {
		lexer_.error('E',"Host\"%s\" is already defined.",name->string());
		return;}
	if(hostList_==0) hostList_=new TgInfoHostCltn();
	CmCString tga_name("");
	uint32_t tga_port(0);
	if(tgaInfo_) {
		tga_name=tgaInfo_->csName_;
		tga_port=tgaInfo_->unPort_;
		delete tgaInfo_;
		tgaInfo_=0;}
	hostList_->add(new TgInfoHost(lexer_.fileName(),lexer_.lineNo(),*name,nicList_,tga_name,tga_port));
	nicList_=0;
	delete name;}

//  "NIC" statement -------------------------------------------------
void HostDefParser::NicStatement(CmCString* name) {
	if(nicList_ && nicList_->findByName(*name)) {
		lexer_.error('E',"NIC\"%s\" is already defined.",name->string());
		return;}
	if(nicList_==0) nicList_=new TgInfoNicCltn();
	nicList_->add(new TgInfoNic(lexer_.fileName(),lexer_.lineNo(),*name,macAddr_?*macAddr_:CmCString(""),ipList_));
	ipList_=0;
	macAddr_=0;
	delete name;}

//  "TgAgent" statement -----------------------------------------------
void HostDefParser::TgaStatement(CmCString* ptgaName,uint32_t unPort) {
	if(tgaInfo_ != 0) {
		lexer_.error('E',"TgAgent is multiply defined.");
		return;}
	tgaInfo_=new TgaInfo(*ptgaName,unPort);
	delete ptgaName;}

//  "MAC" address statement -------------------------------------------
void HostDefParser::MacStatement(CmCString* mac) {
	if(macAddr_) {
		lexer_.error('E',"MacAddress is multiply defined.");
		delete mac;
		return;}
	macAddr_=mac;}

//  find IP address ---------------------------------------------------
const TgInfoIpName* HostDefParser::findIpByName(const CmCString& ipName) {
	if(nicList_==0) return 0;
	const TgInfoNicCltn& nics=*nicList_;
	uint32_t i=0,i9=nics.size();
	for(i=0;i<i9;++i) {
		const TgInfoNic* nic=nics[i];
		if(nic==0) continue;
		const TgInfoIpCltn* ips=nic->ipList();
		if(ips==0) continue;
		const TgInfoIpName* ip=ips->findByName(ipName);
		if(ip!=0) return ip;}
	return 0;}


//  "IPV4" IP address statement ---------------------------------------
void HostDefParser::Ipv4Statement(CmCString* name,CmCString* addr) {
	const TgInfoIpName* ip=findIpByName(*name);
	if(ip!=0) {
		lexer_.error('E',"IP \"%s\" is already defined.",name->string());
		return;}
	if(ipList_==0) ipList_=new TgInfoIpCltn();
	in_addr sin;
	bool b=(inet_pton(AF_INET,addr->string(),&sin)==1);
	if(!b) {
		lexer_.error('E',"\"%s\" : illegal format of IP address.",addr->string());}
	else {
		ipList_->add(new TgInfoIPV4Name(lexer_.fileName(),lexer_.lineNo(),*name,sin));}
	delete name;
	delete addr;}

//  "IPV6" IP address statement ---------------------------------------
void HostDefParser::Ipv6Statement(CmCString* name,CmCString* addr) {
	const TgInfoIpName* ip=findIpByName(*name);
	if(ip!=0) {
		lexer_.error('E',"IP \"%s\" is already defined.",name->string());
		return;}
	if(ipList_==0) ipList_=new TgInfoIpCltn();
	in6_addr sin;
	bool b=(inet_pton(AF_INET6,addr->string(),&sin)==1);
	if(!b) {
		lexer_.error('E',"\"%s\" : illegal format of IP address.",addr->string());}
	else {
		ipList_->add(new TgInfoIPV6Name(lexer_.fileName(),lexer_.lineNo(),*name,sin));}
	delete name;
	delete addr;}

//  Parse -----------------------------------------------------------------
extern "C" int hostdef_yyparse();

bool HostDefParser::parse(CSTR file,TgInfoHostFile*& info) {
	extern HostDefLexer	*gHstLexer;
	extern HostDefParser	*gHstParser;

	HostDefParser ps(file);
	gHstLexer=&ps.lexer_;
	gHstParser=&ps;
//	ps.yyparse();
	hostdef_yyparse();
	if(ps.errors()>0) return false;
	info=ps.HostFile();
	return true;}
