## Process this file with automake to create makefile.in.

bin_PROGRAMS = vela

vela_SOURCES = tgd.cc

vela_LDADD = -lTg -lCm
vela_LDFLAGS = -L$(top_builddir)/lib/Cm -L$(top_builddir)/lib/Tg -L/usr/local/lib

# specify include directory
INCLUDES = -I$(top_srcdir)/lib/Cm -I$(top_srcdir)/lib/Tg
