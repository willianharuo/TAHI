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
 * $TAHI: koi/lib/kParser/kParserSIP.c,v 1.9 2007/03/27 08:42:18 akisada Exp $
 *
 * $Id: kParserSIP.c,v 1.4 2008/06/03 07:39:56 akisada Exp $
 *
 */

#include <stdio.h>
#include <stdlib.h>
#include <string.h>
#include <sys/types.h>
#include <unistd.h>
#include <regex.h>
#include <koi.h>

#include "kParser.h"
#include "kParserSIP.h"

#define SIPPAT1  "(^|[[:space:]]*\r\n)(((INVITE|ACK|OPTIONS|BYE|CANCEL|REGISTER|SUBSCRIBE|NOTIFY|REFER|PRACK|UPDATE|INFO|MESSAGE|PUBLISH)[[:space:]]+)|SIP).+(\r\n\r\n).*"
#define SIPPAT2  "\r\n(Content-Length|l)[[:space:]]*:[[:space:]]*([0-9]*)[[:space:]]*\r\n"
#define SIPPAT3  "(^|\r\n)(((INVITE|ACK|OPTIONS|BYE|CANCEL|REGISTER|SUBSCRIBE|NOTIFY|REFER|PRACK|UPDATE|INFO|MESSAGE|PUBLISH)[[:space:]]+)|SIP/)"

int kParserSIP(long indatalen,unsigned char *indata,unsigned char **packet_start_point,short *packet_size)
{
  static char tmpBuff[256];
  int i,nmatch=6,ret,startPos,endPos,bodyPos,contentLen;
  regex_t pat1,pat2,pat3;
  regmatch_t match[nmatch];
  char errbuf[100];
#ifdef DBG_PARSER
	kdbg("/tmp/dbg_parser.txt", "%s\n", "initializing.");
	kdbg("/tmp/dbg_parser.txt", "indatalen: %ld\n", indatalen);
#endif	/* DBG_PARSER */
  if(!indatalen) return(PA_ERROR);

  /* パターン文字列のコンパイル */
  if((ret=regcomp(&pat1,SIPPAT1,REG_EXTENDED|REG_ICASE))){
    regerror(ret,&pat1,errbuf,sizeof errbuf);
    kLogWrite(L_ERROR,"%s: regcomp:%d:%s",__FUNCTION__,ret,errbuf);
    return(PA_ERROR);
  }
  if((ret=regcomp(&pat2,SIPPAT2,REG_EXTENDED|REG_ICASE))){
    regerror(ret,&pat2,errbuf,sizeof errbuf);
    kLogWrite(L_ERROR,"%s: regcomp:%d:%s\n",__FUNCTION__,ret,errbuf);
    return(PA_ERROR);
  }
  if((ret=regcomp(&pat3,SIPPAT3,REG_EXTENDED|REG_ICASE))){
    regerror(ret,&pat3,errbuf,sizeof errbuf);
    kLogWrite(L_ERROR,"%s: regcomp:%d:%s\n",__FUNCTION__,ret,errbuf);
    return(PA_ERROR);
  }

  kLogWrite(L_PARSE,"%s: String Length[%ld]\n",__FUNCTION__,indatalen);
  /* SIPパターンのマッチング */
  if( !regexec(&pat1,(const char *)indata,nmatch,match,0) ){

    /* 開始位置の保存 */
    startPos=match[2].rm_so;
    endPos=match[0].rm_eo;
    *packet_start_point=&indata[startPos];
    *packet_size=endPos-startPos;
    
    /* ボディ（\r\n）の検索 */
    for(bodyPos = -1, i = startPos; i < endPos; i ++){
      if(!memcmp("\r\n\r\n",&indata[i],4)){
	bodyPos=i+4;
	break;
      }
    }
    if(bodyPos == -1){
      kLogWrite(L_WARNING,"%s: SIP Body match error",__FUNCTION__);
      return(PA_ERROR);
    }
    kLogWrite(L_PARSE,"%s: Start[%d] Body[%d] End[%d]",__FUNCTION__,startPos,bodyPos,endPos);

    /* Contents-Lengthの検索 */
    if( !regexec(&pat2,(const char *)&indata[startPos],nmatch,match,0)){
      if(match[2].rm_so != -1 && match[2].rm_eo != -1 && match[2].rm_so < bodyPos){
	/* Contents-Lengthがある場合 */
	memcpy(tmpBuff,&indata[startPos+match[2].rm_so],match[2].rm_eo-match[2].rm_so+1);
	tmpBuff[match[2].rm_eo-match[2].rm_so+1]=0;
	contentLen=atoi(tmpBuff);
	kLogWrite(L_PARSE,"%s: Content-Length[%d] Body+Content[%d] Total[%ld]",
		  __FUNCTION__,contentLen,bodyPos+contentLen,indatalen);
	/* マッチした長さを設定 */
	if(bodyPos+contentLen<indatalen){
	  *packet_size=bodyPos+contentLen-startPos;
	  ret=PA_LEFTDATA;
	} else if(bodyPos+contentLen==indatalen){
	  *packet_size=bodyPos+contentLen-startPos;
	  ret=PA_JUSTONE;
	} else{
	  ret=PA_NOMATCH;
	}
	goto EXIT;
      }
    }

    /* Contents-Lengthがない場合、とりあえずボディ部以降にコマンド行があるか調べてみる */
    if( !regexec(&pat3,(const char *)&indata[bodyPos],nmatch,match,0)){
      kLogWrite(L_PARSE,"%s: Next command line exist[%lld]",__FUNCTION__,bodyPos+match[2].rm_so);
      *packet_size=bodyPos+match[2].rm_so-startPos;
      ret=PA_LEFTDATA;
    } else{
      /* ボディ部以降にボディ（\r\n）があればそこまでで区切る */
      for(i = bodyPos ; i < endPos; i ++){
	if(!memcmp("\r\n\r\n",&indata[i],4)){
	  *packet_size=i-startPos+2;
	  ret=PA_LEFTDATA;
	  /* ボディ部以降にボディ（\\r\\n）にあり[%d] */
	  kLogWrite(L_PARSE,"%s: [\\r\\n] exist, after body [%d]",__FUNCTION__,i);
	  goto EXIT;
	}
      }
      kLogWrite(L_PARSE,"%s: One matched",__FUNCTION__);
      ret=PA_JUSTONE;
    }
  } else{
    kLogWrite(L_PARSE,"%s: Not matched",__FUNCTION__);
    ret=PA_NOMATCH;
  }

 EXIT:
  regfree(&pat1);
  regfree(&pat2);
  regfree(&pat3);
  return(ret);
}
