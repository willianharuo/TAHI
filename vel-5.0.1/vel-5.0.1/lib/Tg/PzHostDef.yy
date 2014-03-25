/* -*-Mode: C++-*-
 *
 * Copyright (C) 1999, 2000, 2001, 2002, 2003, 2004, 2005
 *     Yokogawa Electric Corporation.
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
 * PzHostDef : Host Definition File Parser
 */

%term NAME
%term STRING
%term NUMBER
%term HOST
%term INTERFACE
%term IPV4
%term IPV6
%term MAC
%term TGAGENT

%{
#include <stdio.h>
#include <string.h>
#include <sys/types.h>
#include <sys/socket.h>
#include <netinet/in.h>
#include <arpa/inet.h>
#include "LxHostDef.h"
#include "TgHostDef.h"

HostDefLexer	*gHstLexer;
HostDefParser	*gHstParser;

#define yyparse		hostdef_yyparse
#define yylex()		(gHstLexer)->lex()
#define yyerror		(gHstLexer)->yaccError

extern "C" int yyparse();

// #define yyparse	hostdef_yyparse

// #define YYPARSE_PARAM	hostdef_parser
// #define HOSTDEF_PARSER	((HostDefParser*) YYPARSE_PARAM)
// #define HPLEXER	HOSTDEF_PARSER->lexer_
// #define yylex()	HPLEXER.lex()
// #define yyerror	HPLEXER.yaccError

#define HOSTDEF_PARSER		(gHstParser)
#define HostStatement		HOSTDEF_PARSER->HostStatement
#define NicStatement		HOSTDEF_PARSER->NicStatement
#define TgaStatement		HOSTDEF_PARSER->TgaStatement
#define MacStatement		HOSTDEF_PARSER->MacStatement
#define Ipv4Statement		HOSTDEF_PARSER->Ipv4Statement
#define Ipv6Statement		HOSTDEF_PARSER->Ipv6Statement


//#define yyparse(lex)    HostDefParser::yyparse(lex)
//#define	yyparse()	HostDefParser::yyparse()
//#define yyparse    HostDefParser::yyparse
//#define yylex()		lexer_.lex()
//#define yyerror		lexer_.yaccError
#ifdef __GNUC__
# undef __GNUC__
#endif

#define	yymaxdepth hostdef_yymaxdepth
#define	yylval	hostdef_yylval
#define	yychar	hostdef_yychar
#define	yydebug	hostdef_yydebug
#define	yypact	hostdef_yypact
#define	yyr1	hostdef_yyr1
#define	yyr2	hostdef_yyr2
#define	yydef	hostdef_yydef
#define	yychk	hostdef_yychk
#define	yypgo	hostdef_yypgo
#define	yyact	hostdef_yyact
#define	yyexca	hostdef_yyexca
#define yyerrflag hostdef_yyerrflag
#define yynerrs	hostdef_yynerrs
#define	yyps	hostdef_yyps
#define	yypv	hostdef_yypv
#define	yys	hostdef_yys
#define	yy_yys	hostdef_yy_yys
#define	yystate	hostdef_yystate
#define	yytmp	hostdef_yytmp
#define	yyv	hostdef_yyv
#define	yy_yyv	hostdef_yy_yyv
#define	yyval	hostdef_yyval
#define	yylloc	hostdef_yylloc
#define yyreds	hostdef_yyreds
#define yytoks	hostdef_yytoks
#define yylhs	hostdef_yylhs
#define yylen	hostdef_yylen
#define yydefred hostdef_yydefred
#define yydgoto	hostdef_yydgoto
#define yysindex hostdef_yysindex
#define yyrindex hostdef_yyrindex
#define yygindex hostdef_yygindex
#define yytable	 hostdef_yytable
#define yycheck	 hostdef_yycheck
#define yyname   hostdef_yyname
#define yyrule   hostdef_yyrule

#define yyssp		hostdef_yyssp
#define yyvsp		hostdef_yyvsp
#define yyss		hostdef_yyss
#define yysslim		hostdef_yysslim
#define yyvs		hostdef_yyvs
#define yystacksize	hostdef_yystacksize

// #define yydebug  	host_yydebug
// #define yynerrs 	host_yynerrs
// #define yyerrflag  	host_yyerrflag
// #define yychar  	host_yychar
// #define yyssp		host_yyssp
// #define yyvsp		host_yyvsp
// #define yyval		host_yyval
// #define yylval		host_yylval
// #define yyss		host_yyss
// #define yysslim		host_yysslim
// #define yyvs		host_yyvs
// #define yystacksize	host_yystacksize
%}

// ====================================================================
//	Syntax
// ====================================================================

%%

HostFile:
|		HostFile HostStatement;

HostStatement:	HOST NAME '{' HostItems '}'		{HostStatement($2);};
HostItems:
|		HostItems NicStatement
|		HostItems TgaStatement;

NicStatement:	INTERFACE NAME '{' IpDefList '}'	{NicStatement($2);};

TgaStatement:	TGAGENT NAME NUMBER ';'			{TgaStatement($2,(uint32_t)$3);}
|		TGAGENT NAME ';'			{TgaStatement($2,(uint32_t)0);};

IpDefList:
|		IpDefList MacStatement
|		IpDefList IpStatement;

MacStatement:	MAC STRING ';'				{MacStatement($2);};

IpStatement:	IPV4 NAME STRING ';'			{Ipv4Statement($2,$3);}
|		IPV6 NAME STRING ';'			{Ipv6Statement($2,$3);};

%%
