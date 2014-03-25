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
 * PzScenario : Scenario File Parser
 */

%term NAME
%term STRING
%term NUMBER
%term BYTESIZE
%term CONN
%term TCP
%term UDP
%term TRAFFIC
%term COMMAND
%term SCENARIO
%term CONNECT
%term DELAY
%term ONEWAY
%term TURNAROUND
%term EXECUTE
%term WAITEVENT
%term WAIT
%term SYNCEVENT
%term SYNC
%term PRINT

%{
#include <string.h>
#include "LxScenario.h"
#include "TgScenario.h"


ScenarioLexer	*gSnrLexer;
ScenarioParser	*gSnrParser;

#define yyparse		scenario_yyparse
#define yylex()		(gSnrLexer)->lex()
#define yyerror		(gSnrLexer)->yaccError

extern "C" int yyparse();

//#define yyparse(lex)    ScenarioParser::yyparse(lex)
//#define yyparse()    ScenarioParser::yyparse()
//#define yyparse    ScenarioParser::yyparse
//#define yylex()		lexer_.lex()
//#define yyerror		lexer_.yaccError
#ifdef __GNUC__
# undef __GNUC__
#endif

// #define yyparse scenario_yyparse

// #define YYPARSE_PARAM	scenario_parser
// #define SCENARIO_PARSER	((ScenarioParser*) YYPARSE_PARAM)
// #define SPLEXER	SCENARIO_PARSER->lexer_
// #define yylex()	SPLEXER.lex()
// #define yyerror	SPLEXER.yaccError

#define SCENARIO_PARSER		(gSnrParser)
#define ConnectStatement	SCENARIO_PARSER->ConnectStatement
#define EventStatement		SCENARIO_PARSER->EventStatement
#define SyncEventStatement	SCENARIO_PARSER->SyncEventStatement
#define WaitEventStatement	SCENARIO_PARSER->WaitEventStatement
#define TrafficStatement	SCENARIO_PARSER->TrafficStatement
#define ExecuteStatement	SCENARIO_PARSER->ExecuteStatement
#define ActConnectStatement	SCENARIO_PARSER->ActConnectStatement
#define ActDelayStatement	SCENARIO_PARSER->ActDelayStatement
#define ActOneWayStatement	SCENARIO_PARSER->ActOneWayStatement
#define ActTurnaroundStatement	SCENARIO_PARSER->ActTurnaroundStatement
#define ActExecuteStatement	SCENARIO_PARSER->ActExecuteStatement
#define ActSyncStatement	SCENARIO_PARSER->ActSyncStatement
#define ActWaitStatement	SCENARIO_PARSER->ActWaitStatement
#define ActPrintStatement	SCENARIO_PARSER->ActPrintStatement
#define ScenarioStatement	SCENARIO_PARSER->ScenarioStatement
#define NameStatement		SCENARIO_PARSER->NameStatement
#define SrcPortStatement	SCENARIO_PARSER->SrcPortStatement
#define DstPortStatement	SCENARIO_PARSER->DstPortStatement


/*
#define yydebug  	scenario_yydebug
#define yynerrs 	scenario_yynerrs
#define yyerrflag  	scenario_yyerrflag
#define yychar  	scenario_yychar
#define yyssp		scenario_yyssp
#define yyvsp		scenario_yyvsp
#define yyval		scenario_yyval
#define yylval		scenario_yylval
#define yyss		scenario_yyss
#define yysslim		scenario_yysslim
#define yyvs		scenario_yyvs
#define yystacksize	scenario_yystacksize
*/
#define	yymaxdepth scenario_maxdepth
#define	yylval	scenario_lval
#define	yychar	scenario_char
#define	yydebug	scenario_debug
#define	yypact	scenario_pact
#define	yyr1	scenario_r1
#define	yyr2	scenario_r2
#define	yydef	scenario_def
#define	yychk	scenario_chk
#define	yypgo	scenario_pgo
#define	yyact	scenario_act
#define	yyexca	scenario_exca
#define yyerrflag scenario_errflag
#define yynerrs	scenario_nerrs
#define	yyps	scenario_ps
#define	yypv	scenario_pv
#define	yys	scenario_s
#define	yy_yys	scenario_yys
#define	yystate	scenario_state
#define	yytmp	scenario_tmp
#define	yyv	scenario_v
#define	yy_yyv	scenario_yyv
#define	yyval	scenario_val
#define	yylloc	scenario_lloc
#define yyreds	scenario_reds
#define yytoks	scenario_toks
#define yylhs	scenario_yylhs
#define yylen	scenario_yylen
#define yydefred scenario_yydefred
#define yydgoto	scenario_yydgoto
#define yysindex scenario_yysindex
#define yyrindex scenario_yyrindex
#define yygindex scenario_yygindex
#define yytable	 scenario_yytable
#define yycheck	 scenario_yycheck
#define yyname   scenario_yyname
#define yyrule   scenario_yyrule

#define yyssp		scenario_yyssp
#define yyvsp		scenario_yyvsp
#define yyss		scenario_yyss
#define yysslim		scenario_yysslim
#define yyvs		scenario_yyvs
#define yystacksize	scenario_yystacksize

%}

// ====================================================================
//	Syntax
// ====================================================================

%%
ScenarioFile:
|		ScenarioFile ConnStatement
|		ScenarioFile EventStatement
|		ScenarioFile ActionStatement
|		ScenarioFile ScenarioStatement;

// Connection Definition ---------------------------------------------

ConnStatement:	CONN NAME '{' ConnSrc '}' '{' ConnDst '}' TCP ';' {
				ConnectStatement($2, TgInfoConn::TCP_); }
|		CONN NAME '{' ConnSrc '}' '{' ConnDst '}' UDP ';' {
				ConnectStatement($2, TgInfoConn::UDP_); }
|		CONN NAME '{' ConnSrc '}' '{' ConnDst '}' ';' {
				ConnectStatement($2, TgInfoConn::TCP_); };
ConnSrc:	NAME ',' NAME ',' NUMBER {
				SrcPortStatement($1, $3, (uint32_t)$5); };
ConnDst:	NAME ',' NAME ',' NUMBER {
				DstPortStatement($1, $3, (uint32_t)$5); };

// Event Definition --------------------------------------------------

EventStatement: SyncEventStatement
|			WaitEventStatement;
SyncEventStatement: SYNCEVENT NAME EventThreads ';' { SyncEventStatement($2); };
WaitEventStatement: WAITEVENT NAME EventThreads ';' { WaitEventStatement($2); };
EventThreads:	NameDef
|		NameDef ',' EventThreads;

// Action Definition ------------------------------------------------

ActionStatement:	TrafficStatement
|			ExecuteStatement;

TrafficStatement: TRAFFIC NAME NAME '{' TrafficCommandList '}' {
				TrafficStatement($2, $3); };
TrafficCommandList:
|		TrafficCommandList TrafficCommand;

TrafficCommand: ConnectStatement
|		DelayStatement
|		OnewayStatement
|		TurnaroundStatement
|		SyncStatement
|		WaitStatement
|		PrintStatement;

ExecuteStatement: COMMAND NAME NAME '{' ExecuteCommandList '}' {
				ExecuteStatement($2, $3); };
ExecuteCommandList:
|		ExecuteCommandList ExecuteCommand;

ExecuteCommand:	DelayStatement
|		ExecuteStatement
|		SyncStatement
|		WaitStatement
|		PrintStatement;

ConnectStatement: CONNECT ';' { ActConnectStatement(); };
DelayStatement: DELAY NUMBER ';' { ActDelayStatement((uint32_t)$2); };
OnewayStatement: ONEWAY '{' NUMBER ',' ByteSize ','  NUMBER '}' ';' { 
				ActOneWayStatement((uint32_t)$3, (uint32_t)$5, (uint32_t)$7);	}
|		ONEWAY '{' NUMBER ',' ByteSize '}' ';' {
				ActOneWayStatement((uint32_t)$3, (uint32_t)$5, 0); };
TurnaroundStatement: TURNAROUND '{' NUMBER ',' ByteSize ','  NUMBER '}' ';' {
				ActTurnaroundStatement((uint32_t)$3, (uint32_t)$5, (uint32_t)$7); }
|		TURNAROUND '{' NUMBER ',' ByteSize '}' ';' {
				ActTurnaroundStatement((uint32_t)$3, (uint32_t)$5, 0); };
ExecuteStatement: EXECUTE STRING ';' { ActExecuteStatement($2); };
SyncStatement: SYNC NAME ';' { ActSyncStatement($2); };
WaitStatement: WAIT NAME ';' { ActWaitStatement($2); };
PrintStatement: PRINT STRING ';' { ActPrintStatement($2); };

// Scenario Definition ----------------------------------------------

ScenarioStatement: SCENARIO NAME '{' ScenarioActions '}' { ScenarioStatement($2); };
ScenarioActions:
|		NameDef ';' ScenarioActions;

// name, number -----------------------------------------------------

NameDef: NAME { NameStatement($1); };
ByteSize:	BYTESIZE
|		NUMBER;

%%
