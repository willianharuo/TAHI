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
#include <stdlib.h>
#include <stdio.h>
#include <unistd.h>
#include <sys/param.h>
#include "CmMain.h"
#include "CmDispatch.h"
#include "TgAccept.h"
#include "TgServer.h"

struct TgAccept;
struct TgServer;

void server(){
	int serv=InetSocket::defaultService(
		serviceName,envService,defaultSrvService);
	CmSocket* sock4=InetSocket::stream(serv);
	TgAccept* accept4=new TgAccept(sock4);
	accept4->listen();
	CmDispatch&	disp=CmDispatch::instance();
	for(;disp.count()!=0;) {disp.dispatch();}
	delete accept4;
	exit(0);
}

void callMeWhenExit() {
	printf("tgd...callMeWhenExit()\n");
}

applMain() {
	int argc=main->argc();
	STR *argv=main->argv();
	int i; char * p;
	atexit(callMeWhenExit);
	for(i=1;i<argc;i++) {
		if(*(p=argv[i])=='-') {
			switch(*++p) {
				case 'd': CmMain::setDbgFlags(++p); break;
//				case 'e': dbgFlags['E']++; break;
				case 'r': dbgFlags['R']++; break;
				case 'l': logLevel=1; break;
				default: break;}}}
	dbgFlags['E']++;
	server();
	exit(0);}
