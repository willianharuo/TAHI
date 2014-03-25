#
# Copyright (C) 2004, 2005, 2006, 2007, 2008, 2009, 2010
# NTT Advanced Technology, Yokogawa Electric Corporation.
# All rights reserved.
# 
# Redistribution and use of this software in source and binary
# forms, with or without modification, are permitted provided that
# the following conditions and disclaimer are agreed and accepted
# by the user:
# 
# 1. Redistributions of source code must retain the above copyright
#    notice, this list of conditions and the following disclaimer.
# 
# 2. Redistributions in binary form must reproduce the above copyright
#    notice, this list of conditions and the following disclaimer in
#    the documentation and/or other materials provided with
#    the distribution.
# 
# 3. Neither the names of the copyrighters, the name of the project
#    which is related to this software (hereinafter referred to as
#    "project") nor the names of the contributors may be used to
#    endorse or promote products derived from this software without
#    specific prior written permission.
# 
# 4. No merchantable use may be permitted without prior written
#    notification to the copyrighters.
# 
# 5. The copyrighters, the project and the contributors may prohibit
#    the use of this software at any time.
# 
# THIS SOFTWARE IS PROVIDED BY THE COPYRIGHTERS, THE PROJECT AND
# CONTRIBUTORS "AS IS" AND ANY EXPRESS OR IMPLIED WARRANTIES, INCLUDING
# BUT NOT LIMITED THE IMPLIED WARRANTIES OF MERCHANTABILITY AND FITNESS
# FOR A PARTICULAR PURPOSE, ARE DISCLAIMED.  IN NO EVENT SHALL THE
# COPYRIGHTERS, THE PROJECT OR CONTRIBUTORS BE LIABLE FOR ANY DIRECT,
# INDIRECT, INCIDENTAL, SPECIAL, EXEMPLARY, OR CONSEQUENTIAL DAMAGES
# (INCLUDING, BUT NOT LIMITED TO, PROCUREMENT OF SUBSTITUTE GOODS OR
# SERVICES; LOSS OF USE, DATA, OR PROFITS; OR BUSINESS INTERRUPTION)
# HOWEVER CAUSED AND ON ANY THEORY OF LIABILITY, WHETHER IN CONTRACT,
# STRICT LIABILITY, OR TORT (INCLUDING NEGLIGENCE OR OTHERWISE) ARISING
# IN ANY WAY OUT OF THE USE OF THIS SOFTWARE, EVEN IF ADVISED OF THE
# POSSIBILITY OF SUCH DAMAGE.
#
# $TAHI: koi/Makefile.inc,v 1.16 2007/04/05 07:54:16 akisada Exp $
#
# $Id: Makefile.inc,v 1.2 2008/06/03 07:39:50 akisada Exp $
#

PREFIX=	/usr/local/koi
BINDIR=	${PREFIX}/bin

CFLAGS+=	-ansi	# Language Options
CFLAGS+=	-Wall	# Warning Options
CFLAGS+=	-Werror	# Warning Options
CFLAGS+=	-g	# Debugging Options

CFLAGS+=	-D_PATH_PID=\"/tmp/koid.pid\"

CFLAGS+=	-DUSE_SYSLOG
CFLAGS+=	-DSUPPORT_TLS



#
# electricfence-2.2.2 environment
#
# LDFLAGS+=	-L/usr/local/lib
# LDADD+=	-lefence
#

# CFLAGS+=	-DDBG_IF		# kIF debug
# CFLAGS+=	-DDBG_BUFFER		# kBuffer debug
# CFLAGS+=	-DDBG_DATA		# kData debug
# CFLAGS+=	-DDBG_LOG		# kLog debug
# CFLAGS+=	-DDBG_PARSER		# kParser debug
# CFLAGS+=	-DDBG_SOCKET		# kSocket debug
# CFLAGS+=	-DDBG_DISPATCHER	# kDispatcher debug
