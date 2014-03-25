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
 *
 * $TAHI: vel/lib/Cm/CmTypes.h,v 1.1.1.1 2005/07/13 01:46:14 doo Exp $
 */
#ifndef _Cm_CmTypes_h_
#define _Cm_CmTypes_h_	1

#include <config.h>

#if defined(HAVE_STDINT_H)
# include <stdint.h>
#elif defined(HAVE_INTTYPES_H)
# include <inttypes.h>
#endif

#include <sys/types.h>
#include <stdarg.h>
#include <ctype.h>

typedef char *STR;
typedef const char *CSTR;

#if !defined(HAVE_STDINT_H) && !defined(HAVE_INTTYPES_H)
typedef u_int8_t uint8_t;
typedef u_int16_t uint16_t;
typedef u_int32_t uint32_t;
typedef u_int64_t uint64_t;
#endif /* !defined(HAVE_STDINT_H) && !defined(HAVE_INTTYPES_H) */

inline int32_t round8(int32_t n) {return (n+(0x08-1))&(~(0x08-1));}
inline int32_t round16(int32_t n) {return (n+(0x10-1))&(~(0x10-1));}
inline int32_t roundK(int32_t n) {return (n+(0x400-1))&(~(0x400-1));}
inline int32_t roundM(int32_t n) {return (n+(0x100000-1))&(~(0x100000-1));}
typedef int (*fmtOutputFunction)(CSTR fmt,va_list v);
extern int eoutf(CSTR fmt, ...);
extern int ooutf(CSTR fmt, ...);
extern void eerr(CSTR fmt);
extern uint32_t basicHash(CSTR,int32_t);
fmtOutputFunction regEoutFunc(fmtOutputFunction);
fmtOutputFunction regOoutFunc(fmtOutputFunction);
#if !defined(name2)
#define name2(a,b)a ## b
#endif

// a char to number
inline int toNum(int c) {
	return ('0'<=c&&c<='9')?(c-'0'):(toupper(c)+10-'A');}
// number to a char
inline char toChar(int c) {
	return (c<10)?(c+'0'):(c-10+'A');}
#endif
