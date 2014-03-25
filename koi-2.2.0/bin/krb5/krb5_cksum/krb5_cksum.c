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
 * $Id: krb5_cksum.c,v 1.2 2010/07/22 13:23:56 velo Exp $
 */

#include <stdio.h>
#include <errno.h>
#include <libgen.h>	/* basename */
#include <ctype.h>	/* isxdigit */
#include <inttypes.h>
#include <stdlib.h>
#include <string.h>
#include <krb5.h>

static const char *prog = NULL;

static int val(char c);
static unsigned char *hex2data(const char *str, unsigned char *data);
static krb5_data *hex2krb5data(const char *str, krb5_data *data);
static void dump_krb5_checksum(krb5_checksum cksum);
static void dump_krb5_data(krb5_data *data);
static void dump_krb5_keyblock(krb5_keyblock *keyblock);
static void usage(void);

int main(int argc, char **argv)
{
	int log_level = 0;
	char *data_str;
	char *ap_req_str = NULL;
	unsigned char *data;
	size_t data_len;

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
	data_str = argv[0];

	{
		printf("dbg: %s starts arg(%s)\n", prog, data_str);
	}

	{
		{ /* stdout */
			printf("std:data:%s\n", data_str);
		}
		data_len = strlen(data_str);
		data_len = data_len/2 + data_len%2;
		data = (unsigned char *)malloc(data_len);
		memset(data, 0, data_len);
		data = hex2data(data_str, data);
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
		ret = krb5_mk_req_extended(context, &auth_context,
					   AP_OPTS_MUTUAL_REQUIRED,
					   NULL /* in_data */,
					   &cred_copy,
					   &ap_req);
		if (ret != 0) {
			printf("ERR:krb5_mk_req_extended:%s\n", krb5_get_err_text(context, ret));
			return(ret);
		}
	}

	/* create checksum */
	{
		krb5_crypto crypto;
		krb5_checksum cksum;

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
		ret = krb5_create_checksum(context,
					   crypto,
					   40,
					   0 /* krb5_cksumtype type */,
					   data,
					   data_len,
					   &cksum);
		if (ret != 0) {
			printf("ERR:krb5_create_checksum:%s\n", krb5_get_err_text(context, ret));
			return(ret);
		}
		if (log_level) {
			dump_krb5_checksum(cksum);
		}
		{ /* stdout */
			int i = 0;
			unsigned char *p;
			p = (unsigned char *)cksum.checksum.data;
			printf("std:cksum:");
			for (i = 0; i < cksum.checksum.length; i++) {
				printf("%02x", *p++);
			}
			printf("\n");
		}

		krb5_crypto_destroy(context, crypto);
	}

	/* clenaup */
	{
		/*free(data);*/
		/*krb5_data_free(&ap_req);*/
		krb5_free_cred_contents(context, &creds_tgt);

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

unsigned char *hex2data(const char *str, unsigned char *data)
{
	unsigned char *ret = data;
	unsigned char *p;
	const char *q;
	int hi, lo;
	
	p = data;
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
	return(ret);
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

void dump_krb5_checksum(krb5_checksum cksum)
{
	krb5_data *p;
	unsigned char *q;

	printf("dbg: call dump_krb5_checksum\n");
	printf("\tkrb5_checksum.CKSUMTYPE: %d\n", cksum.cksumtype);

	p = &cksum.checksum;
	q = (unsigned char *)(p->data);
	printf("\tkrb5_ckecksum.len: %d\n", p->length);
	printf("\tkrb5_checksum.data: <");
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

static void usage(void)
{
	fprintf(stderr, "err: usage: %s data\n", prog);

	exit(-1);
	/* NOTREACHED */

	return;
}
