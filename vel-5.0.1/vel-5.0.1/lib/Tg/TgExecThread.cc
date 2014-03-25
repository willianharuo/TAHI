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
 * TgExecThread: Thread Control Class
 */

#include "TgExecThread.h"
#include "TgError.h"


// ==================================================================
//	TgExecThread : Thread Class
// ==================================================================

// Constructor ------------------------------------------------------
TgExecThread::TgExecThread(TgInfoAction* act):TgBaseName(act->name()),pAction_(act) {
	TgStatementCltn* list=(act!=0)?act->stmtList():0;
	if(list) cStatements_=*list;}

TgExecThread::TgExecThread(const TgExecThread& elm):TgBaseName(elm.name()),pAction_(elm.pAction_) {
	cStatements_=elm.cStatements_;}

TgExecThread& TgExecThread::operator=(const TgExecThread& elm) {
	CmCString::operator=(elm.name());
	pAction_=elm.pAction_;
	cStatements_=elm.cStatements_;
	return *this;}

//  Destructor -------------------------------------------------------
TgExecThread::~TgExecThread() { }

// Start -------------------------------------------------------------
void TgExecThread::start(void* s,va_list) {
	TgAgntCtrlCltn* alist=(TgAgntCtrlCltn*)s;
	cStatements_.elementsPerformWith((TgStatementFunc)&TgStatement::reset,this,alist,pAction_);
	stmtPos_=0;
	next();}

// Next -------------------------------------------------------------
void TgExecThread::next() {
	while(stmtPos_<(int32_t)cStatements_.size()) {
		bool abort;
		TgStatement* stmt=(TgStatement*)cStatements_.index(stmtPos_);
		if(stmt->doStep(abort) == true) break;
		if(abort) {
			TgError::execError(name(),"",stmt->name(),"Thread aborts.");
			stmtPos_=-1;
			return;}
		stmtPos_++;}}

// isEnd ------------------------------------------------------------
bool TgExecThread::isEnd() {
	if(stmtPos_==-1) return true;		// Error
	if(stmtPos_>=(int32_t)cStatements_.size()) return true;		// Complete
	return false;}

// On Complete ------------------------------------------------------
void TgExecThread::onComplete() {
	next();}

// On Error ---------------------------------------------------------
void TgExecThread::onError(uint32_t ecode) {
	if(stmtPos_ >= 0) {
		TgStatement* stmt=(TgStatement*)cStatements_.index(stmtPos_);
		TgError::execError(name(),"",stmt->name(),"Thread aborts on error %d",ecode);
		stmtPos_=-1;}}

// ==================================================================
//	TgExecThreadCltn : Thread Collection
// ==================================================================

implementBtCltn(List,TgExecThreadCltn,TgExecThread);

// Check for complete -----------------------------------------------
bool TgExecThreadCltn::isAllComplete() const {
	for(uint32_t n=0; n < size(); ++n) {
		TgExecThread* pTh=(TgExecThread*)this->index(n);
		if(!pTh->isEnd()) return false;}
	return true;}
