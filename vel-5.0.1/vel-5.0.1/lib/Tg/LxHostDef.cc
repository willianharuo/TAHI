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
 * HostDefLexer : Lexer for Host Definition File
 */

#include <stdio.h>
#include <string.h>
#include "LxHostDef.h"
#include "PzHostDef.h"

// ====================================================================
//	Constructor / Destructor
// ====================================================================
HostDefLexer::HostDefLexer(const CmCString& file) : LxLexer(file) {}
HostDefLexer::~HostDefLexer() {}

// ====================================================================
//	method : lookup
// ====================================================================
int32_t HostDefLexer::lookup(CmCString& csWord) {
	struct sKeyTable {
		CSTR	csKeyWord;
		int32_t nKeyValue;};
	static sKeyTable  sHostKeyDef[] = {
		{ "HOST",	HOST		},
		{ "INTERFACE",	INTERFACE	},
		{ "IPV4",	IPV4		},
		{ "IPV6",	IPV6		},
		{ "MAC",	MAC		},
		{ "TGAGENT",	TGAGENT		},
		{ 0,		0		}};
	for(sKeyTable* pKey = sHostKeyDef; pKey->csKeyWord; ++pKey) {
		CmCString csKeyWord(pKey->csKeyWord);
		if(compareKeyWord(csWord, csKeyWord))
			return pKey->nKeyValue;}
	return NAME;}

// ====================================================================
//	method : lex
// ====================================================================
int32_t HostDefLexer::lex() {
	extern YYSTYPE hostdef_yylval;
	STR s = nextToken();
	if(s == 0) return 0;			// EOF
	int c = (int)*s;
	if(isdigit(c)) {
		hostdef_yylval = (YYSTYPE)digitLex(s);
		return NUMBER;}
	else if(c == '\"') {
		CmCString tmp;
		hostdef_yylval = new CmCString(stringLex(s, tmp));
		return STRING;}
	else if(c == ';' || c == '{' || c == '}') {
		next(1);
		return c;}
	else {
		CmCString cm;
		hostdef_yylval = new CmCString(nameLex(s, cm));
		return lookup(cm);}}
