#
# $Name: REL_2_1_1 $
#
# $TAHI: ct/ipsec4/Makefile,v 1.8 2001/10/05 06:38:59 masaxmasa Exp $
#
INSTALL_DIR=$(PREFIX)/ct/ipsec4
XFILES = *.seq
FILES = *.def INDEX* *.html 00README .footer

all:

install:
	install -d -o bin -g bin -m 755 $(INSTALL_DIR)
	install -c -o bin -g bin -m 555 $(XFILES) $(INSTALL_DIR)
	install -c -o bin -g bin -m 444 $(FILES) $(INSTALL_DIR)
	install -c -o bin -g bin -m 444 Makefile.test $(INSTALL_DIR)/Makefile

.include "Makefile.test"
