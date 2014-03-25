noinst_LIBRARIES = libTg.a
libTg_a_SOURCES = PzHostDef.yy PzScenario.yy \
                  TcAgent.h TgAgent.cc TgHostDef.h \
                  LxHostDef.cc TcSocket.cc TgAgent.h TgIF.cc \
                  LxHostDef.h TcSocket.h TgAgntCtrl.cc  TgIF.h \
                  LxLexer.cc TcTCPSocket.cc TgAgntCtrl.h TgInfo.cc \
                  LxLexer.h TcTCPSocket.h TgAgntLg.cc TgInfo.h \
                  LxScenario.cc TcUDPSocket.cc TgAgntLg.h TgPostPrcs.cc \
                  LxScenario.h TcUDPSocket.h TgBase.h TgPostPrcs.h \
                  TeAccept.cc TgClient.cc TgReqElm.cc \
                  TeAccept.h TgClient.h TgReqElm.h \
                  TeAgent.cc TgDebug.cc TgScenario.cc \
                  TeAgent.h  TgDebug.h  TgScenario.h \
                  TeClient.cc TgDefine.h TgServer.cc \
                  TeClient.h TgError.cc TgServer.h \
                  TeCmd.cc TgError.h TgStatement.cc \
                  TeCmd.h TgExecThread.cc TgStatement.h \
                  TeIF.cc TgExecThread.h TgSyncEvent.cc \
                  TeIF.h TgExecTimer.cc TgSyncEvent.h \
                  TeServer.cc TgExecTimer.h TgTypes.h \
                  TcAccept.cc TeServer.h TgFrame.cc \
                  TcAccept.h TgAccept.cc TgFrame.h \
                  TcAgent.cc TgAccept.h TgHostDef.cc

nodist_libTg_a_SOURCES = PzHostDef.cc PzScenario.cc

EXTRA_DIST = yacc_post_proc.pl

INCLUDES = -I$(top_srcdir)/lib/Cm

CLEANFILES = PzHostDef.h PzHostDef.cc PzHostDef.rule PzHostDef.output\
             PzScenario.h PzScenario.cc PzScenario.rule PzScenario.output

AM_YFLAGS = -dv && perl $(top_srcdir)/lib/Tg/yacc_post_proc.pl $@
YACC = yacc

dist-hook:
		rm -rf `find $(distdir) -name "Pz*.cc"`
