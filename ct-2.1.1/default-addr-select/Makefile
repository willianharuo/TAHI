#
# $Name: REL_2_1_1 $
#
# $TAHI: ct/default-addr-select/Makefile,v 1.1 2002/09/25 12:07:24 kenta Exp $
#
INSTALL_DIR=$(PREFIX)/ct/default-addr-select
XFILES = *.seq *.pm 
FILES = *.def INDEX* *.html 00README .footer

all:

install:
	install -d -o bin -g bin -m 755 $(INSTALL_DIR)
	install -c -o bin -g bin -m 555 $(XFILES) $(INSTALL_DIR)
	install -c -o bin -g bin -m 444 $(FILES) $(INSTALL_DIR)
	install -c -o bin -g bin -m 444 Makefile.test $(INSTALL_DIR)/Makefile

.include "Makefile.test"
