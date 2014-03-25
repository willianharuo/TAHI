#
# $TAHI: koi/Makefile.inc,v 1.16 2007/04/05 07:54:16 akisada Exp $
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
