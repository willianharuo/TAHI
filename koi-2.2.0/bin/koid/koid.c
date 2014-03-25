/*
 *
 * Copyright (C) 2004, 2005, 2006, 2007, 2008, 2009, 2010
 * NTT Advanced Technology, Yokogawa Electric Corporation.
 * All rights reserved.
 * 
 * Redistribution and use of this software in source and binary
 * forms, with or without modification, are permitted provided that
 * the following conditions and disclaimer are agreed and accepted
 * by the user:
 * 
 * 1. Redistributions of source code must retain the above copyright
 *    notice, this list of conditions and the following disclaimer.
 * 
 * 2. Redistributions in binary form must reproduce the above copyright
 *    notice, this list of conditions and the following disclaimer in
 *    the documentation and/or other materials provided with
 *    the distribution.
 * 
 * 3. Neither the names of the copyrighters, the name of the project
 *    which is related to this software (hereinafter referred to as
 *    "project") nor the names of the contributors may be used to
 *    endorse or promote products derived from this software without
 *    specific prior written permission.
 * 
 * 4. No merchantable use may be permitted without prior written
 *    notification to the copyrighters.
 * 
 * 5. The copyrighters, the project and the contributors may prohibit
 *    the use of this software at any time.
 * 
 * THIS SOFTWARE IS PROVIDED BY THE COPYRIGHTERS, THE PROJECT AND
 * CONTRIBUTORS "AS IS" AND ANY EXPRESS OR IMPLIED WARRANTIES, INCLUDING
 * BUT NOT LIMITED THE IMPLIED WARRANTIES OF MERCHANTABILITY AND FITNESS
 * FOR A PARTICULAR PURPOSE, ARE DISCLAIMED.  IN NO EVENT SHALL THE
 * COPYRIGHTERS, THE PROJECT OR CONTRIBUTORS BE LIABLE FOR ANY DIRECT,
 * INDIRECT, INCIDENTAL, SPECIAL, EXEMPLARY, OR CONSEQUENTIAL DAMAGES
 * (INCLUDING, BUT NOT LIMITED TO, PROCUREMENT OF SUBSTITUTE GOODS OR
 * SERVICES; LOSS OF USE, DATA, OR PROFITS; OR BUSINESS INTERRUPTION)
 * HOWEVER CAUSED AND ON ANY THEORY OF LIABILITY, WHETHER IN CONTRACT,
 * STRICT LIABILITY, OR TORT (INCLUDING NEGLIGENCE OR OTHERWISE) ARISING
 * IN ANY WAY OUT OF THE USE OF THIS SOFTWARE, EVEN IF ADVISED OF THE
 * POSSIBILITY OF SUCH DAMAGE.
 *
 * $TAHI: koi/bin/koid/koid.c,v 1.105 2007/04/06 01:32:06 akisada Exp $
 *
 * $Id: koid.c,v 1.5 2008/07/14 02:17:02 inoue Exp $
 *
 */

#include <errno.h>
#include <signal.h>
#include <stdio.h>
#include <stdlib.h>
#include <string.h>
#include <unistd.h>

#include <sys/types.h>
#include <sys/time.h>

#include <koi.h>

#include "koid.h"


/*
  08/3/18 usage: display version 
          command line: add -V option
*/

/*
 * function prototypes
 */
static bool	initialize_modules(char *, char *, int);
static void	finalize(void);
static void	finalizebysignal(int);
#ifdef XXX_DAEMON
static bool	start_daemon(void);
#endif	/* XXX_DAEMON */
static void	usage(char **);



/*
 * static global variables
 */
static const char	*prog	 = NULL;
static const char	*koi_version = KOI_VERSION;
static bool	terminate_process	= 0;
									/* initializer element must be constant */



/*--------------------------------------------------------------------*
 * int main(int, char **, char **);                                   *
 *--------------------------------------------------------------------*/
int
main(int argc, char **argv, char **envp)
{
	int				loglevel	= 0;
	char			*logfile	= NULL;
	char			*deffile	= NULL;
	char			*socketpath	= NULL;
	char			**arguments	= argv;
	short			socketid	= 0;
	unsigned char	type	= 0;
	struct timeval	looptimeout;
	int	ret	= 0;
	int	handle	= 0;
#ifdef SUPPORT_TLS
	char			*passwd	= NULL;
	char			*rootpem	= NULL;
	char			*mypem	= NULL;
	char			*dhpem	= NULL, *enc=NULL;
	short			tlsmode	= false;
	int			version=1,nagle=1,clientveri=1,tmprsa=1;
#endif	/* SUPPORT_TLS */

	memset(&looptimeout, 0, sizeof(looptimeout));
#ifdef SUPPORT_TLS
#endif	/* SUPPORT_TLS */

	setvbuf(stdout, NULL, _IOLBF, 0);
	setvbuf(stderr, NULL, _IOLBF, 0);

	prog = xbasename(argv[0]);

	{	/* XXX: change args? koid [options] interface ... */
		int ch = 0;

		while((ch = getopt(argc, argv, "f:l:d:p:sVP:r:m:v:h:")) != -1) {
			switch(ch) {
				case 'd':
					deffile = optarg;
					break;

				case 'f':
					logfile = optarg;
					break;

				case 'l':
					if(!strcmp(optarg,"DEBUG")) {
						loglevel |= L_ERROR | L_WARNING | L_DEBUG;
					} else if(!strcmp(optarg,"SOCKET")) {
						loglevel |= L_ERROR | L_WARNING | L_SOCKET;
					} else if(!strcmp(optarg,"DATA")) {
						loglevel |= L_ERROR | L_WARNING | L_DATA;
					} else if(!strcmp(optarg,"TIME")) {
						loglevel |= L_ERROR | L_WARNING | L_TIME;
					} else if(!strcmp(optarg,"BUFFER")) {
						loglevel |= L_ERROR | L_WARNING | L_BUFFER;
					} else if(!strcmp(optarg,"INIT")) {
						loglevel |= L_ERROR | L_WARNING | L_INIT;
					} else if(!strcmp(optarg,"INFO")) {
						loglevel |= L_ERROR | L_WARNING | L_INFO;
					} else if(!strcmp(optarg,"COMMAND")) {
						loglevel |= L_ERROR | L_WARNING | L_CMD;
					} else if(!strcmp(optarg,"PARSE")) {
						loglevel |= L_ERROR | L_WARNING | L_PARSE;
					} else if(!strcmp(optarg,"TLS")) {
						loglevel |= L_ERROR | L_WARNING | L_TLS;
					} else if(!strcmp(optarg,"IO")) {
						loglevel |= L_ERROR | L_WARNING | L_IO;
					} else if(!strcmp(optarg,"WARNING")) {
						loglevel |= L_ERROR | L_WARNING;
					} else if(!strcmp(optarg,"ERROR")) {
						loglevel |= L_ERROR;
					} else{
						usage(arguments);
					}

					break;

				case 'p':
					socketpath = optarg;
					break;
#ifdef SUPPORT_TLS
				case 's':
					tlsmode = true;
					break;

				case 'P':
					passwd = optarg;
					break;

				case 'r':
					rootpem = optarg;
					break;

				case 'm':
					mypem = optarg;
					break;

				case 'h':
					dhpem = optarg;
					break;
			        case 'n': /* Nagle */
					if(!strcmp(optarg,"YES")||!strcmp(optarg,"yes")) nagle = 1;
					if(!strcmp(optarg,"NO")||!strcmp(optarg,"no")) nagle = 0;
					break;
			        case 'c': /* Client verify */
					if(!strcmp(optarg,"YES")||!strcmp(optarg,"yes")) clientveri = 1;
					if(!strcmp(optarg,"NO")||!strcmp(optarg,"no")) clientveri = 0;
					break;
			        case 'e': /* encrypt suit */
					enc = optarg;
					break;
			        case 't': /* temp RSA */
					if(!strcmp(optarg,"YES")||!strcmp(optarg,"yes")) tmprsa = 1;
					if(!strcmp(optarg,"NO")||!strcmp(optarg,"no")) tmprsa = 0;
					break;
				case 'v':
					if(!strcmp(optarg,"SSLv2") || !strcmp(optarg,"v2")) {
						version = 2;
					} else if(!strcmp(optarg,"SSLv23") || !strcmp(optarg,"v23")) {
						version = 23;
					} else if(!strcmp(optarg,"SSLv3") || !strcmp(optarg,"v3")) {
						version = 3;
					} else if(!strcmp(optarg,"TLSv1") || !strcmp(optarg,"tls")) {
						version = 1;
					} else {
						printf("ERROR: SSL version[%s] invalid.  "
							"select SSLv2|SSLv23|SSLv3|TLSv1.\n", optarg);
						return(-1);
					}

					break;
#endif	/* SUPPORT_TLS */
				case 'V':
					usage(NULL);
					break;
				default:
					usage(arguments);
					/* NOTREACHED */
			}
		}

		argc -= optind;
		argv += optind;
	}

	if(argc) {
		usage(arguments);
		/* NOTREACHED */
	}

	atexit(finalize);

	/*--------------------------------------------------------------------*
	 * No  Name    Default Action      Description                        *
	 * ================================================================   *
	 * 2   SIGINT  terminate process   interrupt program                  *
	 * 13  SIGPIPE terminate process   write on a pipe with no reader     *
	 * 15  SIGTERM terminate process   software termination signal        *
	 *--------------------------------------------------------------------*/

	signal(SIGINT,	finalizebysignal);
	signal(SIGPIPE,	SIG_IGN);
	signal(SIGTERM,	finalizebysignal);

	if(!initialize_modules(deffile, logfile, loglevel)) {
		printf("exit: %s: %d: initialize_modules: failure\n",
			xbasename(__FILE__), __LINE__);
		return(-1);
	}

	/* open unix domain socket */
	if(kSocketOpenUnixdSocket(socketpath, P_COMMAND, &socketid) < 0 ) {
		printf("exit: %s: %d: kSocketOpenUnixdSocket: failure\n",
			xbasename(__FILE__), __LINE__);
		return(-1);
	}
#ifdef SUPPORT_TLS
	/* TLS initialize */
	if(tlsmode) {
		if(kTLSInitialize(true,1,0,passwd,rootpem,mypem,dhpem,version,nagle,clientveri,tmprsa,enc)) {
			printf("exit: %s: %d: TLS Initialize: failure\n",
				xbasename(__FILE__), __LINE__);

			return(-1);
		}

		kLogWrite(L_INIT, "%s: TLS initialize ok\n", __FUNCTION__);
	}
#endif	/* SUPPORT_TLS */

	/* set time for main while loop */
	looptimeout.tv_sec	= LOOPWAIT_SEC;
	looptimeout.tv_usec	= LOOPWAIT_USEC;
#ifdef XXX_DAEMON
	if(!start_daemon()) {
		printf("exit: %s: %d: start_daemon: failure\n",
			xbasename(__FILE__), __LINE__);
		return(-1);
	}
#endif	/* XXX_DAEMON */
	printf("pipe: %s: %d: %s: ready\n",
		xbasename(__FILE__), __LINE__, prog);

	while(!terminate_process) {
		/* timer function */
		kCloseTimerProc();
		kRecvTimerProc();

		/* fds set */
		g_execfds = g_readfds;

		/*
		 * main select
		 */
		ret = select(FD_SETSIZE, &g_execfds, NULL, NULL, &looptimeout);
		if(ret <= 0) {
			continue;
		}

		/* get sockethandle */
		if((kSocketGetSelectedHandle(&handle, &type)) < 0) {
			continue;
		}

		/* dispatcher selection and execute */
		kDispatcherProc(handle, type);
		/* XXX: If false, should we break here? */
	}

	kSocketClose(0);
	kSocketClose(-1);

	return(0);
}



/*--------------------------------------------------------------------*
 * static bool initialize_modules(char *, char *, int);               *
 *--------------------------------------------------------------------*/
static bool
initialize_modules(char *deffile, char *logfile, int loglevel)
{
	/* FD zero clear */
	FD_ZERO(&g_readfds);
	FD_ZERO(&g_execfds);

	/* open log file as append mode */
	/* set log level to appropriate level */
#ifdef USE_SYSLOG
	if(!kLogInit(prog, loglevel)) {	/* must be the 1st */
		printf("error: %s: %d: kLogInit: failure\n",
			xbasename(__FILE__), __LINE__);
		return(false);
	}
#else	/* USE_SYSLOG */
	if(!kLogInit(logfile, loglevel)) {	/* must be the 1st */
		printf("error: %s: %d: kLogInit: failure\n",
			xbasename(__FILE__), __LINE__);
		return(false);
	}
#endif	/* USE_SYSLOG */

	/* initialize table */
	if(!kDataInit()) {
		printf("error: %s: %d: kDataInit: failure\n",
			xbasename(__FILE__), __LINE__);
		return(false);
	}

	/* initialize table */
	if((kSocketInit()) < 0) {
		printf("error: %s: %d: kSocketInit: failure\n",
			xbasename(__FILE__), __LINE__);
		return(false);
	}

	/* read tn.def */
	/* initialize table */
	if(!kIFInit(deffile)) {
		printf("error: %s: %d: create_if_table: failure\n",
			xbasename(__FILE__), __LINE__);
		return(false);
	}

	/* initialize table */
	if((kCloseTimerInit()) < 0) {
		printf("error: %s: %d: kCloseTimerInit: failure\n",
			xbasename(__FILE__), __LINE__);
		return(false);
	}

	/* initialize table */
	if(!kBufferInit()) {
		printf("error: %s: %d: kBufferInit: failure\n",
			xbasename(__FILE__), __LINE__);
		return(false);
	}

	/* initialize table */
	if((kRecvTimerInit()) < 0) {
		printf("error: %s: %d: kRecvTimerInit: failure\n",
			xbasename(__FILE__), __LINE__);
		return(false);
	}

	/* initialize table */
	/* register parser */
	if(!kParserInit()) {
		printf("error: %s: %d: kParserInit: failure\n",
			xbasename(__FILE__), __LINE__);
		return(false);
	}

	return(true);
}



/*--------------------------------------------------------------------*
 * static void finalize(void);                                        *
 *--------------------------------------------------------------------*/
static void
finalize(void)
{
	static int finalizecount = 0;

	if(finalizecount) {
		return;
	}

	printf("koid: finalize\n");

	kLogFinalize();

	finalizecount ++;

	return;
}



/*--------------------------------------------------------------------*
 * static void finalizebysignal(int);                                 *
 *--------------------------------------------------------------------*/
static void
finalizebysignal(int sig) {
	terminate_process = true;
	finalize();

	return;
}



#ifdef XXX_DAEMON
/*--------------------------------------------------------------------*
 * static bool start_daemon(void);                                    *
 *--------------------------------------------------------------------*/
static bool
start_daemon(void)
{
	FILE *stream = NULL;
	pid_t pid = 0;

	daemon(0, 0);

	pid = getpid();

	if(!(stream = fopen(_PATH_PID, "w"))) {
		printf("error: %s: %d: fopen: %s\n",
			xbasename(__FILE__), __LINE__, strerror(errno));
		return(false);
	}

	fprintf(stream, "%d\n", pid);
	fclose(stream);

	return(true);
}
#endif	/* XXX_DAEMON */



/*--------------------------------------------------------------------*
 * static void usage(char **);                                        *
 *--------------------------------------------------------------------*/
static void
usage(char **argv)
{
	int d = 0;

	if(argv) {
		printf("exit: %s: %d: invalid command line --",
			xbasename(__FILE__), __LINE__);

		for(d = 0; argv[d]; d ++) {
			printf(" %s", argv[d]);
		}

		printf("\n");
	}

	printf("\nversion: %s\n"
	       "usage  : %s [-V] [-p socketpath] [-d tn.def] [-f logfile]\n"
		"              [-l INIT|SOCKET|BUFFER|DATA|COMMAND|PARSE|TLS|IO]\n"
#ifdef SUPPORT_TLS
		"              [-s] [-v SSLv2|SSLv23|SSLv3|TLSv1]\n"
		"              [-r rootpem] [-m mypem] [-h DH.pem] [-r root.pem] [-m my.pem] [-h DH.pem] [-P passphrase]\n"
	        "              [-n yes|no] [-c yes|no] [-t yes|no] [-e encrypt suit]\n"
#endif	/* SUPPORT_TLS */
		"\n", koi_version, prog);

	exit(-1);
	/* NOTREACHED */

	return;
}
