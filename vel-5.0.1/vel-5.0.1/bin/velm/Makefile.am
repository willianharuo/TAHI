## Process this file with automake to create makefile.in.

bin_PROGRAMS = velm

velm_SOURCES = tg.cc

velm_LDADD = -lTg -lCm
velm_LDFLAGS = -L$(top_builddir)/lib/Cm -L$(top_builddir)/lib/Tg -L/usr/local/lib

# specify include directory
INCLUDES = -I$(top_srcdir)/lib/Cm -I$(top_srcdir)/lib/Tg
