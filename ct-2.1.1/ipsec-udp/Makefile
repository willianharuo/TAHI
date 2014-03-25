#
# $Name: REL_2_1_1 $
#
# $TAHI: ct/ipsec-udp/Makefile,v 1.2 2003/06/10 10:48:48 akisada Exp $
#
INSTALL_DIR=$(PREFIX)/ct/ipsec-udp
FILES = *.def INDEX* *.html 00README .footer *.tmpl

all:

install:
	install -d -o bin -g bin -m 755 $(INSTALL_DIR)
	install -c -o bin -g bin -m 444 $(FILES) $(INSTALL_DIR)
	install -c -o bin -g bin -m 444 Makefile.test $(INSTALL_DIR)/Makefile

.include "Makefile.test"
