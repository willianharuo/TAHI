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
#include <errno.h>
#include <unistd.h>
#include <fcntl.h>
#include <signal.h>
#include <sys/types.h>
#include <sys/wait.h>
#include "Timer.h"
#include "TeIF.h"
#include "TeServer.h"
#include "TeAccept.h"
#include "TeCmd.h"
#include "TgFrame.h"

struct TgFrame;
struct TeCmd;

static TeServer* This_;

static void childEnd(int /*sig*/,int /*code*/,struct sigcontext *,char *){
	This_->setEndTime();
	char buf[BUFSIZ];
	int status=0;
	int pid=0;
	int16_t	cmd=0;
	if((pid=wait(&status))==-1) {
		exit(0);
	}
	if(status) {
		int errCode=WIFEXITED(status);
		if(errCode)	sprintf(buf,"*** Error code %d",errCode);
		else		sprintf(buf,"*** Termination code %d",status);
		cmd=eCmdCancel_;
	}
	else cmd=eCmdExec_;

	TeCmd* e=This_->findReqno(pid);
	if(e){
		This_->report(cmd,e->reqno(),WEXITSTATUS(status));
		This_->removeCmd(e);
	}
	else {
		This_->set_find_reqno_failure(1);
	}

	signal(SIGCHLD,(sigHandler)childEnd);
}

struct TeCmdSet;

void TeServer::connectionLost(CmSocket*){
	socket()->close();
	delete this;
}

////////////////////////////////////////////////////////////////////////
//	access methods for TeCmdSet	
////////////////////////////////////////////////////////////////////////
TeCmdSet& TeServer::cmdSet(){
	if(cmdSet_==0){
		cmdSet_=new TeCmdSet(100);
	}
	return *cmdSet_;
}

TeCmd* TeServer::addCmd(TeCmd* v){
	if(v!=0){
		TeCmdSet& s=cmdSet();
		return (TeCmd*)s.add(v);
	}
	return 0;
}

TeCmd* TeServer::removeCmd(TeCmd* v){
	if(v!=0){
		TeCmdSet& s=cmdSet();
		return (TeCmd*)s.remove(v);
	}
	return 0;
}

TeCmd* TeServer::findReqno(int32_t pid){
	if(pid!=0){
		TeCmdSet& s=cmdSet();
		TeCmd tmp(pid);
		return (TeCmd*)s.find(&tmp);
	}
	return 0;
}

TeCmd* TeServer::findPid(int16_t reqno){
	if(reqno!=0){
		TeCmdSet& s=cmdSet();
		TeCmd tmp(0,reqno);
		return (TeCmd*)s.findMatching(&tmp,(TeCmdEqFunc)&TeCmd::isReqnoEqual);
	}
	return 0;
}

u_long TeServer::noOfElements() {
	TeCmdSet& s = cmdSet();
	return(s.noOfElements());
}


////////////////////////////////////////////////////////////////////////
//	
////////////////////////////////////////////////////////////////////////
TeServer::TeServer(CmSocket* s):TeInterface(s) {
	This_=this;
	set_find_reqno_failure(0);
	signal(SIGCHLD,(sigHandler)childEnd);
}

TeServer::~TeServer() {
}

void TeServer::set_find_reqno_failure(int i) {
	is_find_reqno_failure = i;
}

int TeServer::get_find_reqno_failure() {
	return(is_find_reqno_failure);
}

void TeServer::setStartTime(){
	stime_=TimerQueue::currentTime();
}

void TeServer::setEndTime(){
	etime_=TimerQueue::currentTime();
}

void TeServer::report(int16_t n,int16_t rn,int32_t v){
	TgFrame f(2*sizeof(struct timeval));
	f.encode(stime_);
	f.encode(etime_);
	TeInterface::response(n,rn,0,v,f.length(),f.buffer(0));
}

int TeServer::cmdExecRequest(){
	char cmd[BUFSIZ];
	int16_t len=header().length();
	strncpy(cmd,buffer(0),len);
	cmd[len]='\0';
	expandRun(header().request(),cmd);
	return 0;
}

int TeServer::cmdCancelRequest(){
	int16_t	rn=header().reqno();
	TeCmd*	e=findPid(rn);
	if(e){
		setStartTime();
		int ret=0;
		if((ret=kill(e->pid(),SIGKILL))!=0){
			report(eCmdCancel_,rn,ret);
			removeCmd(e);
		}
	}
	return 0;
}

int TeServer::expandRun(int16_t reqno,STR cmd) {
	int pid;
	setStartTime();
	if((pid=vfork())==0) {	// child process
		::close(0);
		open("/dev/null",O_RDONLY);
		int sz=getdtablesize();
		for(int i=3;i<sz;i++) ::close(i);
		run(reqno,cmd);
	}
	else if(pid>0){		// parent process
		TeCmd* v=new TeCmd(pid,header().reqno());
		u_long num = noOfElements();

		if (num == 0 && get_find_reqno_failure()) {
			/*
			 * If findReqno() fails in childEnd(), vela and velo cannot 
			 * respond to ExecCmd requst (TeCmd* v).
			 * Instead of childEnd(), a response to v is sent here.
			 * And responded v is not added to TeCmdSet.
			 */
			int16_t	cmd = eCmdCancel_;
			int status = 0;
			This_->report(cmd, v->reqno(), WEXITSTATUS(status));
			set_find_reqno_failure(0);
		}
		else {
			/*
			 * Un-responded v is added to TeCmdSet.
			 */
			addCmd(v);
		}
	}
	else{
		report(eCmdExec_,reqno,-2);
		printf( "vfork error\n" );
	}
	return 0;
}

void TeServer::run(int16_t reqno,STR cmdStr)	{
	static STR	argArea[33]; static int argMax=32;
	static STR	*argArray= argArea;
	STR file, p;
	STR delim = " \t\n";
	int i=0;
	bool shFlag = false;
	for(file=p=strtok(cmdStr, delim);p;p=strtok(0, delim)) {
		argArray[i++]=p;
		if(i>=argMax) {
			STR *old=argArray;
			argArray=(STR*)calloc((argMax*=2)+1,sizeof(STR));
			register int j;
			for(j=0;j<i;j++) {argArray[j]=old[j];}
			if(old!=argArea) free(old);}

		// process if argments include '/bin/sh -c'
		if (strcmp(p, "/bin/sh") == 0 || strcmp(p, "sh") == 0) {
			shFlag = true;
		}
		else if (shFlag && strcmp(p, "-c") == 0) {
			delim = "\n";
		}
		// 
	}

	argArray[i]=0;
	execvp(file,argArray);
	// error occur
	This_->report(eCmdExec_,reqno,errno);
	exit(1);
}
