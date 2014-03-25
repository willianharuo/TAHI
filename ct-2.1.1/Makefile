#
# Makefile
#
# $TAHI: ct/Makefile,v 1.22 2003/06/10 10:59:28 akisada Exp $
#

INSTALL_DIR=$(PREFIX)/ct
DOC_DIR=$(PREFIX)/doc
DOCFILES= 00README.ct CHANGELOG.ct INSTALL.ct
CRFILES= COPYRIGHT

all:

afterinstall:
	install -d -o bin -g bin -m 755 $(INSTALL_DIR)
	install -d -o bin -g bin -m 755 $(DOC_DIR)
	install -c -o bin -g bin -m 444 $(CRFILES) $(INSTALL_DIR)
	install -c -o bin -g bin -m 444 $(DOCFILES) $(INSTALL_DIR)
	install -c -o bin -g bin -m 444 $(DOCFILES) $(DOC_DIR)
	install -c -o bin -g bin -m 444 index.html $(INSTALL_DIR)
	install -c -o bin -g bin -m 444 Makefile.inc $(INSTALL_DIR)
	install -c -o bin -g bin -m 444 Makefile.test $(INSTALL_DIR)/Makefile

.include "Makefile.test"
.include "Makefile.inc"
