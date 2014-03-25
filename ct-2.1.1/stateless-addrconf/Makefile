INSTALL_DIR=$(PREFIX)/ct/stateless-addrconf
XFILES = *.seq *.pm
FILES = *.def *.pktdesc INDEX* *.html 00README .footer

.include "Makefile.test"

all:

install:
	install -d -o bin -g bin -m 755 $(INSTALL_DIR)
	install -c -o bin -g bin -m 555 $(XFILES) $(INSTALL_DIR)
	install -c -o bin -g bin -m 444 $(FILES) $(INSTALL_DIR)
	install -c -o bin -g bin -m 444 Makefile.test $(INSTALL_DIR)/Makefile

.include "../Makefile.inc"
