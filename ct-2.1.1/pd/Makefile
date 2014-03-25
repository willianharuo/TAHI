INSTALL_DIR=$(PREFIX)/ct/pd

SFILES= *.seq *.pm
DFILES= *.def *.tmpl
ETCFILES= \
	.footer \
	00README \
	retrans_mech \
	INDEX* \
	*.html

all:

install:
	install -d -o bin -g bin -m 755 $(INSTALL_DIR)
	install -c -o bin -g bin -m 555 $(SFILES) $(INSTALL_DIR)
	install -c -o bin -g bin -m 444 $(DFILES) $(INSTALL_DIR)
	install -c -o bin -g bin -m 444 $(ETCFILES) $(INSTALL_DIR)
	install -c -o bin -g bin -m 444 Makefile.test $(INSTALL_DIR)/Makefile

.include "./Makefile.test"
