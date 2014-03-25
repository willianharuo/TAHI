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
 * $TAHI: koi/include/debug.h,v 1.11 2006/06/26 01:12:32 akisada Exp $
 *
 * $Id: debug.h,v 1.2 2008/06/03 07:39:55 akisada Exp $
 *
 */

#ifndef _DEBUG_H_
#define _DEBUG_H_

#ifdef DBG_BUFFER
#ifndef DBG_XXX
#define DBG_XXX
#endif	/* DBG_XXX */
#endif	/* DBG_BUFFER */

#ifdef DBG_DATA
#ifndef DBG_XXX
#define DBG_XXX
#endif	/* DBG_XXX */
#endif	/* DBG_DATA */

#ifdef DBG_LOG
#ifndef DBG_XXX
#define DBG_XXX
#endif	/* DBG_XXX */
#endif	/* DBG_LOG */

#ifdef DBG_PARSER
#ifndef DBG_XXX
#define DBG_XXX
#endif	/* DBG_XXX */
#endif	/* DBG_PARSER */

#ifdef DBG_SOCKET
#ifndef DBG_XXX
#define DBG_XXX
#endif	/* DBG_XXX */
#endif	/* DBG_SOCKET */

#ifdef DBG_DISPATCHER
#ifndef DBG_XXX
#define DBG_XXX
#endif	/* DBG_XXX */
#endif	/* DBG_DISPATCHER */

#ifdef DBG_XXX
#include <stdio.h>
#include <sys/types.h>
#include <unistd.h>

#ifndef kdbg
#define kdbg(file, fmt, args...) \
{ \
FILE *stream = fopen(file, "a"); \
if(stream) { \
fprintf(stream, "kdbg[%d]: %s: %d: %s(): " fmt, \
getpid(), __FILE__, __LINE__, __FUNCTION__, ##args); \
fclose(stream); \
} \
}
#endif	/* kdbg */

#ifndef kdmp
#define kdmp(file, name, buf, buflen) \
{ \
FILE *stream = fopen(file, "a"); \
if(stream) { \
unsigned char *buffer = (unsigned char *)buf; \
unsigned int length = (unsigned int)buflen; \
unsigned int d = 0; \
fprintf(stream, "kdmp[%d]: %s: %d: %s(): %s: buffer: ", \
getpid(), __FILE__, __LINE__, __FUNCTION__, name); \
for(d = 0; d < length; d ++) { \
fprintf(stream, "%02x", buffer[d]); \
} \
fputc('\n', stream); \
fprintf(stream, "kdmp[%d]: %s: %d: %s(): %s: length: %d\n", \
getpid(), __FILE__, __LINE__, __FUNCTION__, name, length); \
fclose(stream); \
} \
}
#endif	/* kdmp */
#endif	/* DBG_XXX */
#endif	/* _DEBUG_H_ */
