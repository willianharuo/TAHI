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
 * $TAHI: koi/lib/kUtils/kUtils.c,v 1.5 2007/04/05 07:54:17 akisada Exp $
 *
 * $Id: kUtils.c,v 1.2 2008/06/03 07:39:58 akisada Exp $
 *
 */

#include <stdio.h>
#include <string.h>
#include <sys/param.h>
#include <koi.h>

#include "kUtils.h"



const char *
xbasename(const char *path)
{
	int d = 0;
#ifdef XXX_BASENAME
/*
 * OK: "/usr/local/koi/bin/koid"	=> "koid"
 * OK: "/usr/local/koi/bin/koid/"	=> "koid"
 * OK: "usr/local/koi/bin/koid"		=> "koid"
 * OK: "/koid"				=> "koid"
 * OK: "koid/"				=> "koid"
 * OK: "koid"				=> "koid"
 * OK: ""				=> ""
 *
 * XXX: has a problem.
 *      This function always return the same pointer.
 *      And it is the same as the basename(3) behavior.
 */
	static char basename[MAXPATHLEN];

	memset(basename, 0, sizeof(basename));
	memcpy(basename, path, strlen(path));
	basename[strlen(basename)] = '\0';

	for(d = 0; path[d]; d ++) {
		if(path[d] == '/') {
			if(path[d + 1]) {
				char *ptr = path + d + 1;
				memcpy(basename, ptr, strlen(ptr));
				basename[strlen(ptr)] = '\0';
			} else {
				basename[strlen(basename) - 1] = '\0';
			}
		}
	}
#else	/* XXX_BASENAME */
/*
 * OK: "/usr/local/koi/bin/koid"	=> "koid"
 * NG: "/usr/local/koi/bin/koid/"	=> "koid/"
 * OK: "usr/local/koi/bin/koid"		=> "koid"
 * OK: "/koid"				=> "koid"
 * NG: "koid/"				=> "koid/"
 * OK: "koid"				=> "koid"
 * OK: ""				=> ""
 */
	const char *basename = path;

	for(d = 0; path[d]; d ++) {
		if(path[d] == '/') {
			if(path[d + 1]) {
				basename = path + d + 1;
			}
		}
	}
#endif	/* XXX_BASENAME */

	return(basename);
}
