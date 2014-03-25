/**
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
 * $TAHI:$
 * 
 * $Id: krb5_prf.c,v 1.2 2010/07/22 13:23:56 velo Exp $
 */

#include <stdio.h>
#include <errno.h>
#include <libgen.h>	/* basename */
#include <ctype.h>	/* isxdigit */
#include <inttypes.h>
#include <stdlib.h>
#include <string.h>
#include <krb5.h>

/* for calculating prf */
#include <openssl/evp.h>
#define PRF_CONSTANT "prf"

static const char *prog = NULL;

static krb5_error_code prf_simplified_profile(krb5_context context, krb5_crypto crypto, krb5_keyblock *keyblock, const krb5_data *in, krb5_data *out);
static int val(char c);
static krb5_data *hex2krb5data(const char *str, krb5_data *data);
static void dump_krb5_data(krb5_data *data);
static void dump_krb5_keyblock(krb5_keyblock *keyblock);
static void usage(void);

int main(int argc, char **argv)
{
	int log_level = 0;
	char *prf_src_str;
	char *ap_req_str = NULL;

	/* krb5 */
	krb5_error_code ret;
	krb5_context context;
	krb5_auth_context auth_context;
	char *princ_str_tn = "kink/tn.example.com";
	krb5_principal princ_tn;
	char *princ_str_nut = "kink/nut.example.com";
	krb5_principal princ_nut;
	char *princ_str_krbtgt = "krbtgt/EXAMPLE.COM";
	krb5_principal princ_krbtgt;
	krb5_ccache ccache;
	krb5_keytab keytab;
	krb5_creds creds_tgt;
	krb5_data ap_req;
	krb5_data prf_src;
	krb5_data prf_out;

	prog = (const char *) basename(argv[0]);
	if (prog == NULL) {
		fprintf(stderr,
			"basename: %s -- %s\n", strerror(errno), argv[0]);

		return(0);
		/* NOTREACHED */
	}

	{
		int ch = 0;

		while ((ch = getopt(argc, argv, "dq:")) != -1) {
			switch (ch) {
			case 'd':
				log_level++;
				break;
			case 'q':
				ap_req_str = optarg;
				break;
			default:
				usage();
				/* NOTREACHED */

				break;
			}
		}

		argc -= optind;
		argv += optind;
	}

	if (!argc) {
		usage();
		/* NOTREACHED */
	}
	prf_src_str = argv[0];

	{
		printf("DBG: %s starts arg(%s)\n", prog, prf_src_str);
	}

	/* prepare encrypted data */
	{
		hex2krb5data(prf_src_str, &prf_src);
		if (log_level) {
			dump_krb5_data(&prf_src);
		}
		{ /* stdout */
			int i = 0;
			unsigned char *p;
			p = (unsigned char *)prf_src.data;
			printf("std:prf_src:");
			for (i = 0; i < prf_src.length; i++) {
				printf("%02x", *p++);
			}
			printf("\n");
		}
	}

	if (ap_req_str != NULL) {
		hex2krb5data(ap_req_str, &ap_req);
		if (log_level) {
			dump_krb5_data(&ap_req);
		}
		{ /* stdout */
			int i = 0;
			unsigned char *p;
			p = (unsigned char *)ap_req.data;
			printf("std:ap_req:");
			for (i = 0; i < ap_req.length; i++) {
				printf("%02x", *p++);
			}
			printf("\n");
		}
	}

	/* prepare krb5 context */
	{
		/** init context */
		ret = krb5_init_context(&context);
		if (ret != 0) {
			printf("ERR:krb5_init_context:%s\n", krb5_get_err_text(context, ret));
			return(ret);
		}

		/** setup principals */
		ret = krb5_parse_name(context, princ_str_tn, &princ_tn);
		if (ret != 0) {
			printf("ERR:krb5_parse_name:%s\n", krb5_get_err_text(context, ret));
			return(ret);
		}
		ret = krb5_parse_name(context, princ_str_nut, &princ_nut);
		if (ret != 0) {
			printf("ERR:krb5_parse_name:%s\n", krb5_get_err_text(context, ret));
			return(ret);
		}
		ret = krb5_parse_name(context, princ_str_krbtgt, &princ_krbtgt);
		if (ret != 0) {
			printf("ERR:krb5_parse_name:%s\n", krb5_get_err_text(context, ret));
			return(ret);
		}

		/** prepare credential cache */
		ret = krb5_cc_default(context, &ccache);
		if (ret != 0) {
			printf("ERR:krb5_cc_default:%s\n", krb5_get_err_text(context, ret));
			return(ret);
		}

		/** prepare keytab */
		/*ret = krb5_kt_resolve(context, "/usr/local/var/krb5kdc/kadm5.keytab", &keytab);*/
		ret = krb5_kt_default(context, &keytab);
		if (ret != 0) {
			/* printf("ERR:krb5_kt_default:%s", krb5_get_err_text(context, ret)); */
			printf("ERR:krb5_kt_resolve:%s", krb5_get_err_text(context, ret));
			return(ret);
		}
	}

	/* get TGT */
	{
		krb5_creds mcreds;
		memset(&mcreds, 0, sizeof(mcreds));
		mcreds.client = princ_tn;
		mcreds.server = princ_krbtgt;

		ret = krb5_cc_retrieve_cred(context, ccache, 0, &mcreds, &creds_tgt);
		if (ret != 0) {
			printf("ERR:krb5_cc_retrieve_cred:%s\n", krb5_get_err_text(context, ret));
			return(ret);
		}
	}

	/* prepare authentiation context */
	{
		ret = krb5_auth_con_init(context, &auth_context);
		if (ret != 0) {
			printf("ERR:krb5_auth_con_init:%s\n", krb5_get_err_text(context, ret));
			return(ret);
		}

		ret = krb5_auth_con_setflags(context, auth_context,
					     KRB5_AUTH_CONTEXT_DO_SEQUENCE);
		if (ret != 0) {
			printf("ERR:krb5_auth_con_setflags:%s\n", krb5_get_err_text(context, ret));
			return(ret);
		}

		/* if USE_SKEY */
		/*
		ret = krb5_auth_con_setuserkey(context, auth_context, &creds_tgt.session);
		if (ret != 0) {
			printf("ERR:krb5_auth_con_setuseruserkey:%s\n", krb5_get_err_text(context, ret));
			return(ret);
		}
		*/
	}

	/* set keyblock in auth_context */
	if (ap_req_str != NULL) {
		krb5_ticket *ticket;
		krb5_flags ap_req_options;
		
		ap_req_options = AP_OPTS_MUTUAL_REQUIRED;
		ticket = NULL;
		ret = krb5_rd_req(context,
				  &auth_context,
				  &ap_req,
				  NULL,
				  keytab,
				  &ap_req_options,
				  &ticket);
		if (log_level) {
			printf("info: ticket.ticket.key is SKEYID_d\n");
			/*dump_krb5_ticket(context, *ticket);*/
		}
		if (log_level) {
			printf("ap_req_opt (%d)\n", ap_req_options);
		}
		if (ret != 0) {
			printf("ERR:krb5_rd_req:%s\n", krb5_get_err_text(context, ret));
			return(ret);
		}
		if (log_level) {
			dump_krb5_keyblock(auth_context->keyblock);
		}

		krb5_free_ticket(context, ticket);
	}
	else {
		krb5_creds mcreds;
		krb5_creds *cred;
		krb5_creds cred_copy;

		memset(&mcreds, 0, sizeof(mcreds));
		mcreds.client = princ_tn;
		mcreds.server = princ_nut;

		ret = krb5_get_credentials(context, KRB5_GC_CACHED, ccache, &mcreds, &cred);
		if (ret != 0) {
			printf("ERR:krb5_get_credentials:%s\n", krb5_get_err_text(context, ret));
			return(ret);
		}

		/* mk_req_extends reallocate cred, so use a copy */
		ret = krb5_copy_creds_contents(context,
					       (const krb5_creds *)cred,
					       &cred_copy);
		if (ret != 0) {
			printf("ERR:krb5_copy_creds_contents:%s\n", krb5_get_err_text(context, ret));
			return(ret);
		}

		/*
		 * If auth_con == NULL, one is allocated.
		 * This is used later. (keyblock is used to decrypt AP_REP)
		 */
		ret = krb5_mk_req_extended(context,
					   &auth_context,
					   AP_OPTS_MUTUAL_REQUIRED,
					   NULL /* in_data */,
					   &cred_copy,
					   &ap_req);
		if (ret != 0) {
			printf("ERR:krb5_mk_req_extended:%s\n", krb5_get_err_text(context, ret));
			return(ret);
		}
	}

	/* prf */
	{
		krb5_crypto crypto;

		ret = krb5_crypto_init(context,
				       auth_context->keyblock,
				       auth_context->keyblock->keytype,
				       &crypto);
		if (ret != 0) {
			printf("ERR:krb5_crypto_init:%s\n", krb5_get_err_text(context, ret));
			return(ret);
		}

		if (0) {
			dump_krb5_keyblock(auth_context->keyblock);
		}
		{
			/*
			ret = krb5_crypto_prf(context, crypto, &prf_src, &prf_out);
			if (ret != 0) {
				printf("ERR:krb5_crypto_prf:%s\n", krb5_get_err_text(context, ret));
				return(ret);
			}
			*/
			ret = prf_simplified_profile(context,
						     crypto,
						     auth_context->keyblock,
						     &prf_src,
						     &prf_out);
		}
		if (ret != 0) {
			printf("ERR:prf:%s\n", krb5_get_err_text(context, ret));
			return(ret);
		}

		{ /* stdout */
			int i = 0;
			unsigned char *p;
			p = (unsigned char *)prf_out.data;
			printf("std:prf:");
			for (i = 0; i < prf_out.length; i++) {
				printf("%02x", *p++);
			}
			printf("\n");
		}

		krb5_crypto_destroy(context, crypto);
	}

	/* clenaup */
	{
		krb5_data_free(&prf_out);
		/*krb5_free_cred_contents(context, &creds_tgt);*/

		ret = krb5_kt_close(context, keytab);
		if (ret != 0) {
			printf("ERR:krb5_kt_close:%s\n", krb5_get_err_text(context, ret));
			return(ret);
		}

		ret = krb5_cc_close(context, ccache);
		if (ret != 0) {
			printf("ERR:krb5_cc_close:%s\n", krb5_get_err_text(context, ret));
			return(ret);
		}

		krb5_free_principal(context, princ_krbtgt);
		krb5_free_principal(context, princ_nut);
		krb5_free_principal(context, princ_tn);
		krb5_free_context(context);
	}

	return(0);
}

int val(char c)
{
	if (isxdigit(c)) {
		if (isdigit(c)) {
			return(c - '0');
		}
		if (isupper(c)) {
			return(c - 'A' + 10);
		}
		return(c - 'a' + 10);
	}
	return(-1);
}

krb5_data *hex2krb5data(const char *str, krb5_data *data)
{
	size_t len = 0;
	unsigned char *p;
	const char *q;
	int hi, lo;
	
	len = strlen(str);
	len = len/2 + len%2;
	krb5_data_zero(data);
	krb5_data_alloc(data, len);
	p = data->data;
	q = str;
	for (;;) {
		if (*q == '\0' || *q == '\n') {
			*p = '\0';
			break;
		}
		hi = val(*q++);
		if (*q == '\0' || *q == '\n') {
			lo = 0;
		}
		else {
			lo = val(*q++);
		}
		*p++ = (hi << 4) | lo;
	}
	return(data);
}

#define BUFSIZE 1024
void dump_krb5_data(krb5_data *data)
{
	krb5_data *p;
	unsigned char *q;

	printf("dbg: call dump_krb5_data\n");

	p = data;
	q = (unsigned char *)(p->data);
	printf("\tkrb5_data.len: %d\n", p->length);
	printf("\tkrb5_data.data: <");
	if (p->length > 0) {
		int i = 0;
		for (i=0; i < p->length; i++) {
			printf("%02x", q[i]);
		}
	}
	printf(">\n");
	return;
}

void dump_krb5_keyblock(krb5_keyblock *keyblock)
{
	printf("dbg: call dump_krb5_keyblock\n");

	{
		int i = 0;
		unsigned char *p;
		printf("\tkeyblock.keytype(%d)\n", keyblock->keytype);
		printf("\tkeyblock.keyvalue.length(%d)\n", keyblock->keyvalue.length);
		printf("\tkeyblock.keyvalue.data<");
		p = (unsigned char *) &keyblock->keyvalue.data;
		for (i = 0; i < keyblock->keyvalue.length; i++) {
			printf("%02x", *p++);
		}
		printf(">\n");
	}
}

/* simplified profile */
struct key_data {
	krb5_keyblock *key;
	krb5_data *schedule;
};
struct key_usage {
	unsigned usage;
	struct key_data key;
};
struct krb5_crypto_data {
	struct encryption_type *et;
	struct key_data key;
	int num_key_usage;
	struct key_usage *key_usage;
};
struct key_type {
	krb5_keytype type; /* XXX */
	const char *name;
	size_t bits;
	size_t size;
	size_t schedule_size;
#if 0	/* stab for heim_oid *oid; */
	int *stab;
#endif
	void (*random_key)(krb5_context, krb5_keyblock*);
	void (*schedule)(krb5_context, struct key_data *);
	struct salt_type *string_to_key;
};
struct checksum_type {
	krb5_cksumtype type;
	const char *name;
	size_t blocksize;
	size_t checksumsize;
	unsigned flags;
	void (*checksum)(krb5_context context,
			 struct key_data *key,
			 const void *buf, size_t len,
			 unsigned usage,
			 Checksum *csum);
	krb5_error_code (*verify)(krb5_context context,
				  struct key_data *key,
				  const void *buf, size_t len,
				  unsigned usage,
				  Checksum *csum);
};
struct encryption_type {
	krb5_enctype type;
	const char *name;
	size_t blocksize;
#if 1
	krb5_cksumtype *heim_oid;
#endif
	size_t padsize;
	size_t confoundersize;
	struct key_type *keytype;
	struct checksum_type *checksum;
	struct checksum_type *keyed_checksum;
	unsigned flags;
	krb5_error_code (*encrypt)(krb5_context context,
				   struct key_data *key,
				   void *data, size_t len,
				   krb5_boolean encrypt,
				   int usage,
				   void *ivec);
};

#if 0
#include <openssl/aes.h>
static void AES_cts_encrypt(
	const unsigned char *in, unsigned char *out,
	const unsigned long length, const AES_KEY *key,
	unsigned char *ivec, const int enc);

static void
AES_cts_encrypt(
	const unsigned char *in, unsigned char *out,
	const unsigned long length, const AES_KEY *key,
	unsigned char *ivec, const int enc)
{
	unsigned char lastblk[AES_BLOCK_SIZE];
	size_t cbclen, fraglen, i;

	if (length <= AES_BLOCK_SIZE)
		return AES_cbc_encrypt(in, out, length, key, ivec, enc);
	fraglen = (length - 1) % AES_BLOCK_SIZE + 1;
	cbclen = length - fraglen - AES_BLOCK_SIZE;

	if (enc == AES_ENCRYPT) {
		/* Same with CBC until the last 2 blocks. */
		AES_cbc_encrypt(in, out, cbclen + AES_BLOCK_SIZE,
		    key, ivec, AES_ENCRYPT);

		/* Adjust the second last plainblock. */
		memcpy(out + cbclen + AES_BLOCK_SIZE, out + cbclen, fraglen);

		/* Encrypt the last plainblock. */
		memcpy(lastblk, ivec, AES_BLOCK_SIZE);
		for (i = 0; i < fraglen; i++)
			lastblk[i] ^= (in + cbclen + AES_BLOCK_SIZE)[i];
		AES_encrypt(lastblk, out + cbclen, key);
	} else {
		/* Decrypt the last plainblock. */
		AES_decrypt(in + cbclen, lastblk, key);
		for (i = 0; i < fraglen; i++)
			(out + cbclen + AES_BLOCK_SIZE)[i] =
			    lastblk[i] ^ (in + cbclen + AES_BLOCK_SIZE)[i];

		/* Decrypt the second last block. */
		memcpy(lastblk, in + cbclen + AES_BLOCK_SIZE, fraglen);
		AES_decrypt(lastblk, out + cbclen, key);
		if (cbclen == 0)
			for (i = 0; i < AES_BLOCK_SIZE; i++)
				(out + cbclen)[i] ^= ivec[i];
		else
			for (i = 0; i < AES_BLOCK_SIZE; i++)
				(out + cbclen)[i] ^=
				    (in + cbclen - AES_BLOCK_SIZE)[i];

		/* Same with CBC until the last 2 blocks. */
		AES_cbc_encrypt(in, out, cbclen, key, ivec, AES_DECRYPT);
	}
}
#endif

static krb5_enctype krb5_crypto_getenctype_stab(krb5_crypto crypto)
{
	return(crypto->et->type);
}

static krb5_error_code prf_simplified_profile(krb5_context context, krb5_crypto crypto, krb5_keyblock *keyblock, const krb5_data *in, krb5_data *out)
{
	krb5_error_code ret;
	Checksum cksum;
	krb5_keyblock *dk;

	

	/*
	 * pseudo-random function    tmp1 = H(octet-string)
	 *                           tmp2 = truncate tmp1 to multiple of m
	 *                           PRF = E(DK(protocol-key, prfconstant),
	 *                                   tmp2, initial-cipher-state)
	 */
	/* tmp1 = H(octet-string) */
	struct checksum_type *ct;
	ct = crypto->et->checksum;
	cksum.cksumtype = ct->type;
	ret = krb5_data_alloc(&cksum.checksum, ct->checksumsize);
	if (ret) {
		printf("ERR: krb5_data_alloc:%s\n", krb5_get_err_text(context, ret));
		return(ret);
	}

	(*ct->checksum)(context, NULL, in->data, in->length, 0, &cksum);
	if (cksum.checksum.length < crypto->et->blocksize) {
		krb5_abortx(context, "internal prf error");
	}
#if 0
	{
		krb5_cksumtype ctype;
		ret = krb5_crypto_get_checksum_type(context, crypto, &ctype);
		if (ret) {
			printf("ERR: krb5_crypto_get_checksum_type:%s\n", krb5_get_err_text(context, ret));
			return(ret);
		}

		ret = krb5_create_checksum(context,
				crypto,
				40, /* usage */
				ctype, /* type */
				in->data,
				in->length,
				&cksum);
		if (ret) {
			printf("ERR: krb5_create_checksum:%s\n", krb5_get_err_text(context, ret));
			return(ret);
		}
	}
#endif	/* 0 */

	/* tmp2 = truncate tmp1 to multiple of m */
	/*
	cksum.checksum.length /= crypto->et->blocksize;
	cksum.checksum.length *= crypto->et->blocksize;
	*/
	size_t blocksize;
	{
		ret = krb5_crypto_getblocksize(context, crypto, &blocksize);
		if (ret) {
			printf("ERR: krb5_crypto_getblocksize:%s\n", krb5_get_err_text(context, ret));
			return(ret);
		}

		cksum.checksum.length /= blocksize;
		cksum.checksum.length *= blocksize;
	}

	/* DK(protocol-key, prfconstant) */
	{
		krb5_enctype etype;
		etype = krb5_crypto_getenctype_stab(crypto);
		/* XXX: krb5_crypto_getenctype requires FreeBSD 8.0 or higher
		ret = krb5_crypto_getenctype(context, crypto, &etype);
		if (ret) {
			printf("ERR: krb5_derive_key:%s\n", krb5_get_err_text(context, ret));
			return(ret);
		}
		*/

		dk = NULL;
		ret = krb5_derive_key(context, keyblock, etype, PRF_CONSTANT, strlen(PRF_CONSTANT), &dk);
		if (ret) {
			printf("ERR: krb5_derive_key:%s\n", krb5_get_err_text(context, ret));
			return(ret);
		}
	}

	/* E(DK(protocol-key, prfconstant), tmp2, initial-cipher-state) */
	ret = krb5_data_alloc(out, blocksize);
	if (ret) {
		printf("ERR: krb5_data_alloc:%s\n", krb5_get_err_text(context, ret));
		return(ret);
	}

	{
		/* XXX: velo, depends on encryption type */
		const EVP_CIPHER *c = EVP_des_ede3_cbc();
		EVP_CIPHER_CTX ctx;

		EVP_CIPHER_CTX_init(&ctx);
		EVP_CipherInit_ex(&ctx, c, NULL, dk->keyvalue.data, NULL, 1);
		EVP_CipherUpdate(&ctx, out->data, (int *)&out->length, cksum.checksum.data, cksum.checksum.length);
		/* no padding
		EVP_CipherFinal_ex(&ctx, out->data, &out->length);
		*/
		EVP_CIPHER_CTX_cleanup(&ctx);
	}

	krb5_data_free(&cksum.checksum);
	krb5_free_keyblock(context, dk);

	return(0);
}

static void usage(void)
{
	fprintf(stderr, "err: usage: %s data\n", prog);

	exit(-1);
	/* NOTREACHED */

	return;
}

