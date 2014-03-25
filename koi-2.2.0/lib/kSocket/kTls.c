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
 * $TAHI: koi/lib/kSocket/kTls.c,v 1.3 2007/04/05 07:54:17 akisada Exp $
 *
 * $Id: kTls.c,v 1.3 2008/07/14 02:17:02 inoue Exp $
 *
 */

#ifdef SUPPORT_TLS
#include <errno.h>
#include <netdb.h>
#include <stdio.h>
#include <stdlib.h>
#include <string.h>
#include <unistd.h>

#include <netinet/in.h>

#include <arpa/inet.h>	/* for inet_ntop() */

#include <sys/socket.h>
#include <sys/types.h>
#include <sys/un.h>	/* for unix domein socket address structure */
#include <sys/stat.h>
#include <fcntl.h>

#include <signal.h>
#include <netinet/tcp.h>
#include <openssl/bio.h>
#include <openssl/err.h>
#include <openssl/rand.h>
#include <openssl/ssl.h>
#include <openssl/x509v3.h>

#include <koi.h>
#include "kSocket.h"

#define SESSION_TIMEOUT   300
#define ROOT_PEM   "/usr/local/koi/keys/root.pem"
#define MY_PEM     "/usr/local/koi/keys/tn.pem"
#define PASSWORD   "nutsip"
#define RANDOM     "random.pem"
#define DHFILE1024 "/usr/local/koi/keys/dh1024.pem"

static void TLSClose(SSL*,int clr);

static int password_cb(char *buf,int num,int rwflag,void *userdata);
static void remove_session_cb(SSL_CTX *ctx,SSL_SESSION *session);

/* CTXオブジェクト */
static SSL_CTX     *TLSctx;
/* セッションキャッシュモード */
static int TLSSessionMode;
/* パスワード */
static char TLSPasswd[128];
/* セッションコンテキスト */
static int TLSServerSessionIdContext = 1;
/* ステータス名 */
static char *SSL_STATUS[] ={"SSL_ERROR_NONE","SSL_ERROR_SSL",
			    "SSL_ERROR_WANT_READ","SSL_ERROR_WANT_WRITE",
			    "SSL_ERROR_WANT_X509_LOOKUP","SSL_ERROR_SYSCALL",
			    "SSL_ERROR_ZERO_RETURN","SSL_ERROR_WANT_CONNECT",
			    "SSL_ERROR_WANT_ACCEPT" ,"","",""};
/* Nagleアルゴリズムの無効化 */
static int NagleFlag = 1;

void TLSError(char *funcname,int err,SSL *ssl);
int VerifyCallback(int ok, X509_STORE_CTX *store);
/* TLSの初期化完了か？ */
bool kIsTLSInitialize()
{
  return TLSctx?1:0;
}
/* SSL経由で読み込み処理 */
int kTLSSend(void *tlsssl,char *buff,int buffsize)
{
  int status;
  SSL *ssl=(SSL*)tlsssl;

  if(!ssl) return RETURN_NG;

  while(1){
    status=SSL_write(ssl, buff, buffsize);
    status=SSL_get_error(ssl,status);
    kLogWrite(L_TLS,"%s: SSL_write status[%s] data[%10.10s]",__FUNCTION__,SSL_STATUS[status],buff);
    switch(status){
    case SSL_ERROR_NONE:
      return RETURN_OK;
    case SSL_ERROR_WANT_WRITE:
      break;
    default:
      TLSClose(ssl,0);
      kLogWrite(L_WARNING,"%s: SSL write problem",__FUNCTION__);
      return RETURN_NG;
    }
  }
  return RETURN_NG;
}
/* SSL経由で読み込み処理 */
int kTLSRecv(void *tlsssl,char *buff,int buffsize)
{
  int leng,status;
  SSL *ssl=(SSL*)tlsssl;

  if(!ssl) return -1;

  do {
    /* SSL経由で読み込み */
    leng=status=SSL_read(ssl,buff,buffsize);
  
    /* SSL_readのステータスを取得する */
    status=SSL_get_error(ssl,status);
    kLogWrite(L_TLS,"%s: SSL_read status[%s]",__FUNCTION__,SSL_STATUS[status]);

    switch(status){
    case SSL_ERROR_NONE:
      /* 正常によめた */
      kLogWrite(L_TLS,"%s: SSL_read leng[%d] data[%10.10s]",__FUNCTION__,leng,buff);
      return leng;
    case SSL_ERROR_ZERO_RETURN:
      /* クローズされた */
      TLSClose(ssl,0);
      return 0;
    case SSL_ERROR_SYSCALL:
      kLogWrite(L_WARNING,"%s: kTLSRecv SSL_read status[%s]",__FUNCTION__,SSL_STATUS[status]);
      TLSClose(ssl,0);
      return 0;
    case SSL_ERROR_WANT_READ:
      /* 再読み込み */
      break;
    case SSL_ERROR_WANT_WRITE:
      /* どうしようか？？ */
      kLogWrite(L_WARNING,"%s: kTLSRecv SSL_read status[%s]",__FUNCTION__,SSL_STATUS[status]);
      break;
    default:
      TLSClose(ssl,0);
      kLogWrite(L_WARNING,"%s: kTLSRecv SSL_read status[%x]",__FUNCTION__,status);
      return -1;
    }
  } while (SSL_pending(ssl));

  return leng;
}

void *kTLSConnect(int handle,void *tlsssl)
{
  int status;
  BIO *bio;
  SSL_SESSION *session=NULL;
  SSL *ssl=(SSL*)tlsssl;
  X509 *peer;
  char peer_CN[256];
  bool flg;

  if(!TLSctx){return NULL;}
  
  /* Nagle アルゴリズムを無効にする */
  if(!NagleFlag){
    flg=true;
    if(setsockopt(handle,IPPROTO_TCP,TCP_NODELAY,(char*)&flg,sizeof(flg))){
      kLogWrite(L_ERROR,"%s: Couldn't setsocktopt TCP_NODELAY",__FUNCTION__);
    }
  }

  /* セッションを再利用可能なTLSセッションの取得 */
  if(TLSSessionMode && ssl) session=SSL_get_session(ssl);

  /* SSLオブジェクトを生成する */
  ssl=SSL_new(TLSctx);

  /* すでに存在するソケットを用いてBIOオブジェクトを生成する。BIOオブジェクトが破棄されてもソケットはクローズされない */
  bio=BIO_new_socket(handle,BIO_NOCLOSE);
  
  /* SSLオブジェクトに読み込み／書き込み用BIOオブジェクトをバインドする */
  SSL_set_bio(ssl,bio,bio);
  
  /* セッションを再利用 */
  if(session){
    SSL_set_session(ssl,session);
    kLogWrite(L_TLS,"%s: Session reuse",__FUNCTION__);
  }

  /* SSL Handshakeを開始する */
  if(SSL_connect(ssl)<=0){
    TLSClose(ssl,0);
    BIO_free(bio);
    kLogWrite(L_ERROR,"%s: SSL connect error",__FUNCTION__);
    return NULL;
  }
  
  /* 検証フェーズのステータスを確認し、正常ならピアの証明書のＣＮフィールドが指定したホスト名と一致するか確認する */
  status = SSL_get_verify_result(ssl);
  if(status!=X509_V_OK){
    TLSClose(ssl,0);
    BIO_free(bio);
    kLogWrite(L_ERROR,"%s: SSL_get_verify_result error[%d]",__FUNCTION__,status);
    return NULL;
  }

  /* ピア証明書を含むX509オブジェクトを取得する */
  if( (peer=SSL_get_peer_certificate(ssl)) ){
    /* ピアのCommonNameを取得し、確認する */
    X509_NAME_get_text_by_NID(X509_get_subject_name(peer), NID_commonName, peer_CN, 256);
    kLogWrite(L_TLS,"%s: peer Name[%s]",__FUNCTION__,peer_CN);
    X509_free(peer);
  }

  kLogWrite(L_TLS,"%s: TLS Connect OK",__FUNCTION__);
  return (void*)ssl;
}

int kTLSAccept(int handle,void **tlsssl,void **tlssession)
{
  BIO *bio;
  SSL *ssl;
  int ofcmode;
  bool flg;

  if(!TLSctx){return(RETURN_NG);}

  /* すでに存在するソケットを用いてBIOオブジェクトを生成する。BIOオブジェクトが破棄されてもソケットはクローズされない */
  bio=BIO_new_socket(handle,BIO_NOCLOSE);
  
  /* SSLオブジェクトを生成する */
  ssl=SSL_new(TLSctx);
  
  /* SSLオブジェクトに読み込み／書き込み用BIOオブジェクトをバインドする */
  SSL_set_bio(ssl,bio,bio);
  
  /* 認証 */
  if (SSL_accept(ssl) <= 0){
    kLogWrite(L_ERROR,"%s: Error accepting SSL connection",__FUNCTION__);
    TLSClose(ssl,0);
    return(RETURN_NG);
  }
  
  /* 非ブロックモードに変更 */
  ofcmode=fcntl(handle,F_GETFL,0);
  ofcmode|=O_NDELAY;
  if(fcntl(handle,F_SETFL,ofcmode)){
    kLogWrite(L_ERROR,"%s: Couldn't make socket nonblocking",__FUNCTION__);
    TLSClose(ssl,0);
    return(RETURN_NG);
  }
  /* Nagle アルゴリズムを無効にする */
  if(!NagleFlag){
    flg=true;
    if(setsockopt(handle,IPPROTO_TCP,TCP_NODELAY,(char*)&flg,sizeof(flg))){
      kLogWrite(L_ERROR,"%s: Couldn't setsocktopt TCP_NODELAY",__FUNCTION__);
    }
  }

  *tlsssl=(void*)ssl;
  *tlssession=(void*)SSL_get_session(ssl);
  kLogWrite(L_TLS,"%s: TLS Accept socket nonblocking OK",__FUNCTION__);
  return(RETURN_OK);
}

/* デフォルトの証明書は 自分:/usr/local/ct/cert/tn.pem 認証局:/usr/local/ct/cert/root.pem */
int kTLSInitialize(int sessionMode,int initialmode,int timeout,char *passwd,char *rootPEM,char *myPEM,
		   char *dhPEM,int version,int nagle,int clientveri,int tmprsa,char *enc)
{
    BIO         *bio;
    SSL_METHOD *meth;
    RSA *rsa;
    DH *dh=0;
    struct stat tmp;

    /* Nagleアルゴリズムの無効化フラグの保存 */
    NagleFlag=nagle;

    if(TLSctx){
      /* 強制初期化モードがある場合 */
      if(initialmode){
	TLSClose(NULL,0);
	kLogWrite(L_TLS, "%s: TLS ReInitialize", __FUNCTION__);
      }
      else
	return RETURN_OK;
    }

    /* パラメータの取得 */
    timeout = timeout<=0 ? SESSION_TIMEOUT : timeout;
    TLSSessionMode = sessionMode;
    kLogWrite(L_TLS,"%s: Session cache mode : %s   Session timeout : %d(s)",__FUNCTION__,sessionMode?"Enable":"Disable",timeout);

    rootPEM = (rootPEM && rootPEM[0]) ? rootPEM : ROOT_PEM;
    myPEM   = (myPEM && myPEM[0]) ?   myPEM   : MY_PEM;
    dhPEM   = (dhPEM && dhPEM[0]) ?   dhPEM   : DHFILE1024;
    strcpy(TLSPasswd,(passwd && passwd[0]) ?  passwd  : PASSWORD);

    if(lstat(rootPEM,&tmp)<0){
      kLogWrite(L_ERROR, "%s: TLS Initialize file[%s] not exist", __FUNCTION__,rootPEM);
      return(RETURN_NG);
    }
    if(lstat(myPEM,&tmp)<0){
      kLogWrite(L_ERROR, "%s: TLS Initialize file[%s] not exist", __FUNCTION__,myPEM);
      return(RETURN_NG);
    }
    if(lstat(dhPEM,&tmp)<0){
      kLogWrite(L_ERROR, "%s: TLS Initialize file[%s] not exist", __FUNCTION__,dhPEM);
      return(RETURN_NG);
    }

    /* SSLライブラリの初期化 */
    if(!SSL_library_init()){
      kLogWrite(L_ERROR, "%s: OpenSSL initialization failed!",__FUNCTION__);
      return(RETURN_NG);
    }
    kLogWrite(L_TLS,"%s: SSL_library_init OK",__FUNCTION__);

    /* エラーメッセージの視覚化 */
    SSL_load_error_strings();

    RAND_load_file("/dev/urandom", 1024);
    kLogWrite(L_TLS,"%s: RAND_load_file OK",__FUNCTION__);

    /* SSL_METHODオブジェクトの取得 */
    if(version == 2)
      meth=SSLv2_method();
    else if(version == 3)
      meth=SSLv3_method();
    else if(version == 1)
      meth=TLSv1_method();
    else if(version == 23)
      meth=SSLv23_method();
    else
      meth=TLSv1_method();

    kLogWrite(L_TLS,"%s: SSL verion [%d] 2:SSLv2 23:SSLv23 3:SSLv3 1:TLSv1",__FUNCTION__,version);
    
    /* SSL_CTXオブジェクトの取得 */
    TLSctx=SSL_CTX_new(meth);
    kLogWrite(L_TLS,"%s: SSL_CTX_new OK",__FUNCTION__);

    /* SSL_CTXオブジェクトに証明書と秘密鍵を同時にロードする */
    if(!(SSL_CTX_use_certificate_file(TLSctx,myPEM,SSL_FILETYPE_PEM))){
      TLSClose(NULL,0);
      kLogWrite(L_ERROR, "%s: Couldn't read certificate file",__FUNCTION__);
      return(RETURN_NG);
    }
    kLogWrite(L_TLS,"%s: SSL_CTX_use_certificate_file[%s] OK",__FUNCTION__,myPEM);

    /* パスフレーズのコールバック関数を登録する */
    SSL_CTX_set_default_passwd_cb(TLSctx,password_cb);

    if(!(SSL_CTX_use_PrivateKey_file(TLSctx,myPEM,SSL_FILETYPE_PEM))){
      TLSClose(NULL,0);
      kLogWrite(L_ERROR, "%s: Couldn't read key file",__FUNCTION__);
      return(RETURN_NG);
    }
    kLogWrite(L_TLS,"%s: SSL_CTX_use_PrivateKey_file[%s] OK",__FUNCTION__,myPEM);
  
    /* SSL_CTXオブジェクトに信頼できるＣＡ証明書をロードする */
    if(!(SSL_CTX_load_verify_locations(TLSctx,rootPEM,0))){
      TLSClose(NULL,0);
      kLogWrite(L_ERROR, "%s: Couldn't read CA list",__FUNCTION__);
      return(RETURN_NG);
    }
    kLogWrite(L_TLS,"%s: SSL_CTX_load_verify_locations[%s] OK",__FUNCTION__,rootPEM);

    /* 認証コールバック関数の登録 */
    /* Server Key Exchange オプションを付与する (クライアント認証を行う) */
    kLogWrite(L_TLS,"%s: Server Key Exchange option : %s",__FUNCTION__,clientveri?"Enable":"Disable");
    SSL_CTX_set_verify(TLSctx, clientveri?SSL_VERIFY_PEER:SSL_VERIFY_NONE,VerifyCallback);
    kLogWrite(L_TLS,"%s:  SSL_CTX_set_verify[%s] OK",__FUNCTION__,clientveri?"PEER":"NONE");
    
    /* 信頼できる証明書に到達するまでのチェーンの回数を指定する */
    /* SSL_CTX_set_verify_depth(TLSctx,1); */

    /* SSLv2を選択不可にする */
    if(version != 2 && version != 23){
      SSL_CTX_set_options(TLSctx,SSL_OP_NO_SSLv2);
      kLogWrite(L_TLS,"%s: SSL_CTX_set_options NO_SSLv2",__FUNCTION__);
    }

    /* Certificate Request オプションを付与する (一時的RSAを使う ) */
    kLogWrite(L_TLS,"%s: Certificate Request option : %s",__FUNCTION__,tmprsa?"Enable":"Disable");
    if(tmprsa){

      /* BIOオブジェクトを使ってファイルをオープンする */
      if ((bio=BIO_new_file(dhPEM,"r")) == NULL){
	TLSClose(NULL,0);
	kLogWrite(L_ERROR, "%s: Couldn't open DH file",__FUNCTION__);
	return(RETURN_NG);
      }
      kLogWrite(L_TLS,"%s: BIO_new_file[%s] OK",__FUNCTION__,dhPEM);
    
      /* ＤＨパラメータを読み込む */
      dh=PEM_read_bio_DHparams(bio,NULL,NULL,NULL);
      kLogWrite(L_TLS,"%s: PEM_read_bio_DHparams[%s] OK",__FUNCTION__,dhPEM);
      
      /* ファイルをクローズする */
      BIO_free(bio);
    
      /* ＤＨパラメータをCTXオブジェクトにロードする */
      if(SSL_CTX_set_tmp_dh(TLSctx,dh)<0){
	TLSClose(NULL,0);
	kLogWrite(L_ERROR, "%s: Couldn't set DH parameters",__FUNCTION__);
	return(RETURN_NG);
      }
      kLogWrite(L_TLS,"%s: SSL_CTX_set_tmp_dh OK",__FUNCTION__);
    }

    /* 暗号スイートの選択 */
    if(enc && enc[0]){
      kLogWrite(L_TLS,"%s: Encrypt suit specified",__FUNCTION__);

      if(SSL_CTX_set_cipher_list(TLSctx,enc))
	kLogWrite(L_TLS,"%s:  SSL_CTX_set_cipher_list[%s] OK",__FUNCTION__,enc);
      else
	kLogWrite(L_TLS,"%s:  SSL_CTX_set_cipher_list[%s] invalid",__FUNCTION__,enc);
    }

    /* ＲＳＡ鍵のペアを生成する */
    rsa=RSA_generate_key(512,RSA_F4,NULL,NULL);
    kLogWrite(L_TLS,"%s: RSA_generate_key OK",__FUNCTION__);
    
    /* ＲＳＡ鍵をCTXオブジェクトにロードする */
    if (!SSL_CTX_set_tmp_rsa(TLSctx,rsa)){
      TLSClose(NULL,0);
      kLogWrite(L_ERROR, "%s: Couldn't set RSA key", __FUNCTION__);
      return(RETURN_NG);
    }
    kLogWrite(L_TLS,"%s: SSL_CTX_set_tmp_rsa OK",__FUNCTION__);
    
    RSA_free(rsa);
  
    /* セッションキャッシュを有効モードに設定する */
    SSL_CTX_set_session_id_context(TLSctx,(void*)&TLSServerSessionIdContext, sizeof(TLSServerSessionIdContext));
    kLogWrite(L_TLS,"%s: SSL_CTX_set_session_id_context OK", __FUNCTION__);

    /* セッション削除時のコールバック設定 */
    SSL_CTX_sess_set_remove_cb(TLSctx,remove_session_cb);
    SSL_CTX_set_timeout(TLSctx,timeout);

    kLogWrite(L_TLS,"%s: Nagle algorithm : %s",__FUNCTION__,NagleFlag?"Enable":"Disable");

    return(RETURN_OK);
}

static void remove_session_cb(SSL_CTX *ctx,SSL_SESSION *session)
{
  kLogWrite(L_TLS,"%s: remove_session_cb[%x]",__FUNCTION__,(unsigned int)session);
}

static int password_cb(char *buf,int num,int rwflag,void *userdata)
{
  if(num<strlen(TLSPasswd)+1)
    return(0);
  kLogWrite(L_TLS,"%s: passwd_cb[%s]",__FUNCTION__,TLSPasswd);
  
  strcpy(buf,TLSPasswd);
  return(strlen(TLSPasswd));
}

/*
  TLSClose(NULL,0) 全TLSセッションのキャッシュをクリアとCTXインスタンスの解放
  TLSClose(NULL,1) 全TLSセッションのキャッシュをクリア
  TLSClose(SSL,0)  指定されたSSLのシャットダウン
  TLSClose(SSL,1)  指定されたSSLのシャットダウンかつTLSセッションのキャッシュをクリア
 */
static void TLSClose(SSL *ssl,int clr)
{
  int ret1,ret2,ret3=0;
  if(ssl){
    ret1=SSL_get_shutdown(ssl);
    ret2=SSL_shutdown(ssl);
    if(!TLSSessionMode || clr){
      ret3=SSL_clear(ssl);
      SSL_free(ssl); 
      kSocketTLSClose(ssl);
    }
    kLogWrite(L_TLS,"%s: SSL[%x] SSL_get_shutdown[%d] SSL_shutdown[%d] SSL_clear[%d]",__FUNCTION__,ssl,ret1,ret2,ret3);
  }
  else{
    extern SocketInfo *g_socket_start_ptr;
    SocketInfo *current_position = g_socket_start_ptr;
    while(current_position){
      if(current_position->si_tls_ssl_ptr) {
	ret3=SSL_clear((SSL*)current_position->si_tls_ssl_ptr);
	SSL_free((SSL*)current_position->si_tls_ssl_ptr); 
	current_position->si_tls_ssl_ptr=NULL;
	kLogWrite(L_TLS,"%s: SSL[%x] SSL_clear[%d]",__FUNCTION__,ssl,ret3);
      }
      current_position = current_position->si_next_socket_info_ptr;
    }
    if(!clr){
      if(!TLSctx) return;
      SSL_CTX_free(TLSctx);
      ERR_free_strings();
      TLSctx=NULL;
    }
  }
}

int kTLSClear(int socketid)
{
  if(socketid){
    SocketInfo	socketinfo;
    memset(&socketinfo,0,sizeof(socketinfo));
    kSocketGetSIBySocketId(socketid,&socketinfo,NULL,NULL,NULL);
    if(socketinfo.si_tls_ssl_ptr)
      TLSClose((SSL*)socketinfo.si_tls_ssl_ptr,1);
  }
  else{
    TLSClose(NULL,1);
  }
  return RETURN_OK;
}

void *kGetTLSSession(void *ssl)
{
  if(!ssl) return NULL;
  return SSL_get_session((SSL*)ssl);
}

/* 検証時のコールバック関数 */
int VerifyCallback(int ok, X509_STORE_CTX *store)
{
    char data[256];
 
    if (!ok)
    {
        X509 *cert = X509_STORE_CTX_get_current_cert(store);
        int  depth = X509_STORE_CTX_get_error_depth(store);
        int  err = X509_STORE_CTX_get_error(store);
 
        X509_NAME_oneline(X509_get_issuer_name(cert), data, 256);
	kLogWrite(L_ERROR, "%s: Cert verify invalid", __FUNCTION__);
	kLogWrite(L_ERROR, "%s:   depth: %i issuer: %s", __FUNCTION__, depth,data);
        X509_NAME_oneline(X509_get_subject_name(cert), data, 256);
	kLogWrite(L_ERROR, "%s:   subject: %s", __FUNCTION__, data);
        kLogWrite(L_ERROR, "%s:   ERR[%i]:%s", __FUNCTION__, err, X509_verify_cert_error_string(err));
    }
 
    return ok;
}

void TLSError(char *funcname,int err,SSL *ssl)
{
  int flags,line;
  char buff[256];
  const char *data,*file;
  unsigned long code;

  ERR_error_string_n(SSL_get_error(ssl,err),buff,sizeof(buff));
  kLogWrite(L_ERROR,"%s: %s",funcname,buff);
  return;

  code = ERR_get_error_line_data(&file,&line,&data,&flags);
  while(code){
    if(data && (flags & ERR_TXT_STRING))
      kLogWrite(L_ERROR,"%s: %s",funcname,data);
    code = ERR_get_error_line_data(&file,&line,&data,&flags);
  }
}


#endif	/* SUPPORT_TLS */
