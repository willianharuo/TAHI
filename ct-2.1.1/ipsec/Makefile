#
# $Name: REL_2_1_1 $
#
# $TAHI: ct/ipsec/Makefile,v 1.9 2003/06/10 12:11:16 ozoe Exp $
#
INSTALL_DIR=$(PREFIX)/ct/ipsec
XFILES = *.seq *.pm
FILES = *.def INDEX* *.html 00README .footer *.tmpl

all:

install:
	install -d -o bin -g bin -m 755 $(INSTALL_DIR)
	install -c -o bin -g bin -m 555 $(XFILES) $(INSTALL_DIR)
	install -c -o bin -g bin -m 444 $(FILES) $(INSTALL_DIR)
	install -c -o bin -g bin -m 444 Makefile.test $(INSTALL_DIR)/Makefile

.include "Makefile.test"
