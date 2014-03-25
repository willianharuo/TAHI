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
#if !defined(__TeServer_h__)
#define	__TeServer_h__	1
#include <sys/time.h>
#include "TeAgent.h"
#include "TeAccept.h"
#include "TeIF.h"

struct TeAgent;
struct TeCmd;
struct TeCmdSet;

typedef void (*sigHandler)(int);

struct TeServer:public TeInterface {
private:
virtual	void connectionLost(CmSocket*);
	int	is_find_reqno_failure;
	TeCmdSet* cmdSet_;
	TeCmd* addCmd(TeCmd*);
	TeCmd* findPid(int16_t reqno);
	u_long noOfElements();
	int	expandRun(int16_t,STR);
	void 	run(int16_t,STR);
	struct timeval	stime_;	
	struct timeval	etime_;	
	void	setStartTime();
//static  void 	childEnd(int /*sig*/,int /*code*/,struct sigcontext *,char *);
public:
	void	setEndTime();
	void	report(int16_t n,int16_t rn,int32_t v);
	TeCmd* removeCmd(TeCmd*);
	TeCmd* findReqno(int32_t pid);
	void	set_find_reqno_failure(int i);
	int	get_find_reqno_failure();
	TeServer(CmSocket*);
virtual	~TeServer();
//----------------------------------------------------------------------
// member function of receiving Request
public: 
virtual int cmdExecRequest();
virtual int cmdCancelRequest();
//----------------------------------------------------------------------
// member function of receiving Confirmation
public:
//----------------------------------------------------------------------
protected:
	TeCmdSet& cmdSet();
};
#endif
