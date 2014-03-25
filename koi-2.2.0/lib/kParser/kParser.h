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
 * $TAHI: koi/lib/kParser/kParser.h,v 1.11 2007/04/06 01:32:08 akisada Exp $
 *
 * $Id: kParser.h,v 1.6 2010/07/22 13:28:32 velo Exp $
 *
 */

#ifndef _K_PARSER_H_
#define _K_PARSER_H_

/* XXX: change order not to depend on SIP, NULL should be first */
/* XXX: use hash? */
#define P_SIP	1	/* SIP */
#define P_NULL	2	/* NULL */
#define P_DNS	3	/* TCP/DNS */
#define P_ICMP  4
#define P_IKEv2	5	/* IKEv2 */
#define P_UDPDNS	6	/* UDP/DNS */
#define P_KINK	7	/* KINK */

#define P_MAXNUMBER	20	/* table array number */
				/* XXX: should be in kParser lib */

/*
 * parser info
 * parser table
 * when module starts, command parser and SIP parser are added to this
 */

/* XXX: change to use list */
typedef struct {
	short pi_peyload_type;  /* data type ex. 1(SIP) */
	int (*pi_parser)(long, unsigned char *, unsigned char **, short *);
        void *pi_attachhandle;
} ParserInfo;

#endif	/* _K_PARSER_H_ */
