/*
 *
 * Copyright (C) 2004, 2005, 2006, 2007, 2008, 2009, 2010
 * NTT Advanced Technology, Yokogawa Electric Corporation.
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
 * $TAHI: koi/lib/kParser/kParserDNS.c,v 1.7 2006/06/26 01:12:33 akisada Exp $
 *
 * $Id: kParserDNS.c,v 1.3 2008/06/03 07:39:56 akisada Exp $
 *
 */

#include <stdio.h>
#include <string.h>
#include <sys/param.h>
#include <koi.h>

#include "kParser.h"
#include "kParserDNS.h"



/*--------------------------------------------------------------------*
 * UDP/DNS                                                            *
 *--------------------------------------------------------------------*/
int
kParserUDPDNS(long indatalen, unsigned char *indata,
	unsigned char **packet_start_point, short *packet_size)
{
#ifdef DBG_PARSER
	kdbg("/tmp/dbg_parser.txt", "%s\n", "initializing.");
	kdbg("/tmp/dbg_parser.txt", "indatalen: %ld\n", indatalen);
#endif	/* DBG_PARSER */
	return(PA_JUSTONE);
}



/*--------------------------------------------------------------------*
 * TCP/DNS                                                            *
 *--------------------------------------------------------------------*/
int
kParserDNS(
	long indatalen,		/* 処理すべきバッファに蓄積されたデータの長さ */
	unsigned char *indata,	/* 処理すべきバッファの先頭ポインタ */
	unsigned char **packet_start_point,
	short *packet_size
)
{
	int startPos		= 0;
	int n_messagelen	= 0;
	int h_messagelen	= 0;
#ifdef DBG_PARSER
	kdbg("/tmp/dbg_parser.txt", "%s\n", "initializing.");
	kdbg("/tmp/dbg_parser.txt", "indatalen: %ld\n", indatalen);
#endif	/* DBG_PARSER */
	memcpy(&n_messagelen, indata, sizeof(n_messagelen));
	h_messagelen = ntohs(n_messagelen);

	if(h_messagelen + 2 > indatalen) {
		return(PA_NOMATCH);	/* データ不足 */
	}

	*packet_start_point = &indata[startPos];
	*packet_size        = h_messagelen + 2;
#ifdef DBG_PARSER
	kdbg("/tmp/dbg_parser.txt", "messagelen: %d\n", *packet_size);
#endif	/* DBG_PARSER */
	if(h_messagelen + 2 < indatalen) {
		return(PA_LEFTDATA);
	}

	return(PA_JUSTONE);
}
