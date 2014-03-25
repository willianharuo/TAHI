#
# $TAHI: koi/Makefile,v 1.6 2006/06/26 01:12:28 akisada Exp $
#

SUBDIR=	lib	\
	bin	\
	libdata	\
	etc

PREFIX=	/usr/local/koi
DIRS=	${PREFIX} ${PREFIX}/bin

beforeinstall:
	for dir in ${DIRS}; do \
		[ -d $$dir ] || mkdir -p $$dir; \
	done
.include <bsd.subdir.mk>
