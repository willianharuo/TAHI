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
 */
//////////////////////////////////////////////////////////////////////
//								    //
//		   TgError: Error Information			    //
//								    //
//////////////////////////////////////////////////////////////////////
#include "TgError.h"
#include <stdio.h>
// ====================================================================
//	TgError : Collection of Error Information
// ====================================================================

//  report message ----------------------------------------------------
bool TgError::report(CSTR phase) {
	uint32_t n=errorCount_;
	errorCount_=0;
	if(n>0) {::fprintf(stderr,"*** %d Error(s) in %s ***\n",n,phase);}
	return (n>0);}

// General error ------------------------------------------------------
void TgError::error(CSTR cform, ...) {
	va_list ap;
	va_start(ap, cform);
	::vfprintf(stderr, cform, ap);
	countup();
	va_end(ap);}

// Execution Time Error -----------------------------------------------
void TgError::execError(CSTR id, CSTR action, CSTR op, CSTR cform, ...) {
	va_list ap;
	va_start(ap, cform);
	::fprintf(stderr, " Thread %s:%s:%s - ",id,action,op);
	::vfprintf(stderr, cform, ap);
	::fprintf(stderr, "\n");
	countup();
	va_end(ap);}

uint32_t TgError::errorCount_ = 0;
