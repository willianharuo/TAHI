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

#include "CmString.h"
#include "CmMain.h"
#include "CmDispatch.h"

#include "TgInfo.h"
#include "TgHostDef.h"
#include "TgScenario.h"
#include "TgPostPrcs.h"
#include "TgAgntCtrl.h"
#include "TgError.h"
#include "TgDebug.h"
#include "TgExecThread.h"


// ====================================================================
//   	Usage
// ====================================================================
static void usage(void) {
	fprintf(stderr,
		"Usage: tg [-d debug]"
			"[-l loglevel]"
			"[-s scenario]"
			"[-e envdef]"
			"scenario\n");}

static CSTR envfile="./env.def";
static CSTR scnfile="./scenario.sc";
// ====================================================================
//	Check Parameters
// ====================================================================
static bool analyzeArguments(CmMain* m,StringList& l) {
	bool rc=true;
	CSTR p, opt;
	for(STR* argv=m->argv();*argv&&(p=*++argv);) {
		if(*p!='-') {
			l.add(new CmCString(p));
			continue;}
		switch(*++p) {
		case 's':
			opt=(*++p)?p:(*++argv);
			scnfile=opt;
			break;
		case 'e':
			opt=(*++p)?p:(*++argv);
			envfile=opt;
			break;
		case 'd':
			CmMain::setDbgFlags(++p);
			break;
		case 'l':
			opt=++p;
			logLevel=(*opt)?atoi(opt):1;
			break;
		default:
			rc=false;}}
	if(!rc) {usage();}
	return rc;}

// ====================================================================
//	Application Main
// ====================================================================
void applicationMain(CmMain* main) {
	StringList list;
	if(!analyzeArguments(main,list)) exit(1);
	if(list.size()!=1) {usage(); exit(1);}
	CSTR scnName=list[0]->string();

	//==============================================================
	// 1. Parse Deffiles.
	TgInfoHostFile* pHostFile;
	TgInfoScenarioFile* pScenarioFile;
	{

		//------------------------------------------------------
		// 1) read & parse "HostFile"
		dbgTrace(("Parsing HostDef file ...\n"));
		if(!HostDefParser::parse(envfile, pHostFile)) exit(1);
		//------------------------------------------------------
		// 2) Read & parse "Scenario file"
		dbgTrace(("Parsing Scenario file ...\n"));
		if(!ScenarioParser::parse(scnfile, pScenarioFile)) exit(1);
		//------------------------------------------------------
		// 3) Post Processing
		dbgTrace(("Host & Scenario postprocessing ...\n"));
		if(!TgPostPrcsCltn::setInfo(pHostFile, pScenarioFile)) exit(1);
	}
	if(dbgFlags['d']) {pHostFile->printOut(); pScenarioFile->printOut();}

	//==============================================================
	// 2. Initialize 
	TgInfoScenario* scn=0;
	TgAgntCtrlCltn  agentList;
	TgExecThreadCltn  threadList;
	{
		//------------------------------------------------------
		// 1) Select scenario
		dbgTrace(("Searching Senario definition [%s] ...\n",scnName));
		const TgInfoScenarioCltn* scnList=pScenarioFile->scenarioList();
		if(scnList==0) {
			TgError::error("No scneario is defined in Scenario file."); exit(1);}
		if((scn=scnList->findByName(scnName))==0) {
			TgError::error("Scneario \"%s\" is not found in Scenario file.",scnName);}
		if(TgError::report("Searching Scenario from Scenario File")) exit(1);
		//------------------------------------------------------
		// 2) get List of host definition
		dbgTrace(("Searching TgAgent for use .... \n"));
		const TgInfoActionCltn* pActList=scn->actionList();
		if(pActList==0) {
			TgError::error("No action in scneario %s.",scnName); exit(1);}
		pActList->elementsPerform((TgInfoActionFunc)&TgInfoAction::setHostRefMark);
		bool rc=true;
		for(uint32_t n=0; n < pHostFile->hostList()->size(); ++n) {
			const TgInfoHost* pHost=pHostFile->hostList()->index(n);
			if(pHost->isMarked()) {
				TgAgntCtrl* pCtrl=TgAgntCtrl::createInstance(pHost);
				if(pCtrl==0) {rc=false; break;}
				if(pCtrl) agentList.add(pCtrl);}}
		if(!rc) exit(1);
		agentList.elementsPerformWith((TgAgntCtrlFunc)&TgAgntCtrl::initialize,(void*)scnName);
		if(TgError::report("Agent(s) initailize")) exit(1);
		//------------------------------------------------------
		// 3) Create thread instance
		dbgTrace(("Creating Agent Control instance .... \n"));
		for(uint32_t n=0; n < pActList->size(); ++n) {
			TgExecThread* et=new TgExecThread(pActList->index(n));
			threadList.add(et);}
	}

	//==============================================================
	// 3. Execution
	{
		CmDispatch& disp=CmDispatch::instance();
		//------------------------------------------------------
		// 1) Initailzie AGENT connection
		dbgTrace(("Startup Agents ... \n"));
		while(!agentList.isAllReady()) {
			disp.dispatch();
			if(TgError::report("Agent(s) startup")) exit(1);}
		//------------------------------------------------------
		// 2) Start all threads
		dbgTrace(("Start all threads ... \n"));
		threadList.elementsPerformWith(
			(TgExecThreadFunc)&TgExecThread::start, &agentList);
		//------------------------------------------------------
		// 3) Dispatch loop
		dbgTrace(("Enter dispatch loop ... \n"));
		while(!threadList.isAllComplete()) {
			disp.dispatch();}
	}

	//==============================================================
	// 4. Complete.
	exit(0);
}
