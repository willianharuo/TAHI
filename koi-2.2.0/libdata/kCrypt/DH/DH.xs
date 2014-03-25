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
 * $Id: DH.xs,v 1.3 2008/06/03 07:39:59 akisada Exp $
 *
 */

#include "EXTERN.h"
#include "perl.h"
#include "XSUB.h"

#include <stdio.h>
#include <openssl/dh.h>
#include <openssl/engine.h>

/* macros # */
#define DEFAULT_PRIME_LEN	1024
#define DEFAULT_GENERATOR	2
#define SECRET_BUFSIZ		1024

/* prototypes # */
int inline_generate_key(SV *);
int inline_compute_key(SV *, SV *, SV *);
int inline_set_dh(SV *, DH *);
HV *inline_ref_hv(SV *);
void inline_deref_hv(SV *);
void inline_print_dh(DH *);

void inline_do_debug();
void inline_no_debug();

/* global variables */
int debug = 0;

/* functions # */
int
inline_generate_key(SV *sv)
{
	DH *dh = NULL;
	int prime_len;
	int generator;
	int error = 0;

	SV **svp = NULL;
	HV *hv = NULL;
	char *str;
	STRLEN strlen;

	if (!SvROK(sv)) {
		fprintf(stderr, "generate_key: argument is not a reference\n");
		return(0);
	}

	if (!(SvTYPE(SvRV(sv)) == SVt_PVHV)) {
		fprintf(stderr, "generate_key: argument is not a hash reference\n");
		return(0);
	}

	dh = DH_new();
	if (dh == NULL) {
		fprintf(stderr, "DH_new: %lu\n", ERR_get_error());
		return(0);
	}

	hv = inline_ref_hv(sv);
	svp = hv_fetch(hv, "p", 1, FALSE);
	if (svp != NULL && !(SvTYPE(SvRV(*svp)) == SVt_NULL)) {
		str = SvPV(*svp, strlen);
		BN_dec2bn(&dh->p, str);
	}
	svp = hv_fetch(hv, "g", 1, FALSE);
	if (svp != NULL && !(SvTYPE(SvRV(*svp)) == SVt_NULL)) {
		str = SvPV(*svp, strlen);
		BN_dec2bn(&dh->g, str);
	}
	inline_deref_hv(sv);

	if (dh->p == NULL || dh->g == NULL) {
		hv = inline_ref_hv(sv);
		svp = hv_fetch(hv, "prime_len", 9, FALSE);
		prime_len = svp ? SvIV(*svp) : DEFAULT_PRIME_LEN;
		svp = hv_fetch(hv, "g", 1, FALSE);
		generator = svp ? SvIV(*svp) : DEFAULT_GENERATOR;
		inline_deref_hv(sv);

		dh = DH_generate_parameters(prime_len, generator, NULL, NULL);
		if (dh == NULL) {
			fprintf(stderr, "DH_generate_parameters: %lu\n", ERR_get_error());
			return(0);
		}
	}

	if (DH_check(dh, &error) == 0) {
		fprintf(stderr, "DH_check: %d\n", error);
		return(0);
	}

	if (DH_generate_key(dh) == 0) {
		fprintf(stderr, "DH_generate_key: %lu\n", ERR_get_error());
		return(0);
	}

	if (inline_set_dh(sv, dh) == 0) {
		return(0);
	}

	if (debug) {
		inline_print_dh(dh);
	}

	DH_free(dh);

	return(1);
}


int
inline_compute_key(SV *sv_secret, SV *sv_pub_key, SV *sv_dh)
{
	DH *dh = NULL;

	SV **svp = NULL;
	HV *hv = NULL;
	char *str;
	STRLEN strlen;
	unsigned char secretbuf[SECRET_BUFSIZ];
	int secretsize = 0;
	int i = 0;
	BIGNUM secret;
	BIGNUM pub_key;
	BIGNUM *bnp = NULL;

	/* setup */
	BN_init(&secret);
	BN_init(&pub_key);
	memset(secretbuf, 0, sizeof(secretbuf));

	if (!SvPOK(sv_secret)) {
		fprintf(stderr, "compute_key: argument is not a string\n");
		return(0);
	}

	if (!SvPOK(sv_pub_key)) {
		fprintf(stderr, "compute_key: argument is not a string\n");
		return(0);
	}

	if (!SvROK(sv_dh)) {
		fprintf(stderr, "compute_key: argument is not a reference\n");
		return(0);
	}

	if (!(SvTYPE(SvRV(sv_dh)) == SVt_PVHV)) {
		fprintf(stderr, "compute_key: argument is not a hash reference\n");
		return(0);
	}

	dh = DH_new();
	if (dh == NULL) {
		fprintf(stderr, "DH_new: %lu\n", ERR_get_error());
		return(0);
	}

	/* set public key */
	str = SvPV(sv_pub_key, strlen);
	bnp = &pub_key;
	BN_dec2bn(&bnp, str);

	/* set dh */
	hv = inline_ref_hv(sv_dh);
	svp = hv_fetch(hv, "p", 1, FALSE);
	if (svp != NULL && !(SvTYPE(SvRV(*svp)) == SVt_NULL)) {
		str = SvPV(*svp, strlen);
		BN_dec2bn(&dh->p, str);
	}
	svp = hv_fetch(hv, "g", 1, FALSE);
	if (svp != NULL && !(SvTYPE(SvRV(*svp)) == SVt_NULL)) {
		str = SvPV(*svp, strlen);
		BN_dec2bn(&dh->g, str);
	}
	svp = hv_fetch(hv, "priv_key", 8, FALSE);
	if (svp != NULL && !(SvTYPE(SvRV(*svp)) == SVt_NULL)) {
		str = SvPV(*svp, strlen);
		BN_dec2bn(&dh->priv_key, str);
	}
	svp = hv_fetch(hv, "pub_key", 7, FALSE);
	if (svp != NULL && !(SvTYPE(SvRV(*svp)) == SVt_NULL)) {
		str = SvPV(*svp, strlen);
		BN_dec2bn(&dh->pub_key, str);
	}
	inline_deref_hv(sv_dh);

	/* compute shared secret key */
	secretsize = DH_compute_key(secretbuf, &pub_key, dh);
	if (BN_bin2bn(secretbuf, secretsize, &secret) == NULL) {
		fprintf(stderr, "BN_bin2bn: error\n");
		return(0);
	}

	/* set shared secret key to return value */
	sv_setpv(sv_secret, BN_bn2dec(&secret));

	return(secretsize);
}

int
inline_set_dh(SV *sv, DH *dh)
{
	HV *hv = NULL;
	SV **svp = NULL;
	char *str = NULL;
	STRLEN  strlen;

	hv = inline_ref_hv(sv);

	svp = hv_fetch(hv, "p", 1, FALSE);
	sv_setpv(*svp, BN_bn2dec(dh->p));
//	str = svp ? SvPV(*svp, strlen) : "";

	svp = hv_fetch(hv, "g", 1, FALSE);
	sv_setpv(*svp, BN_bn2dec(dh->g));
//	str = svp ? SvPV(*svp, strlen) : "";

	svp = hv_fetch(hv, "priv_key", 8, FALSE);
	sv_setpv(*svp, BN_bn2dec(dh->priv_key));
//	str = svp ? SvPV(*svp, strlen) : "";

	svp = hv_fetch(hv, "pub_key", 7, FALSE);
	sv_setpv(*svp, BN_bn2dec(dh->pub_key));
//	str = svp ? SvPV(*svp, strlen) : "";

	inline_deref_hv(sv);

	return(1);
}

HV *
inline_ref_hv(SV *sv)
{
	return((HV *)SvREFCNT_inc(SvRV(sv)));
}

void
inline_deref_hv(SV *sv)
{
	SvREFCNT_dec(SvRV(sv));
}

void
inline_print_dh(DH *dh)
{
	printf("===> p\n");
	printf("p<%s, 0x%s>\n", BN_bn2dec(dh->p), BN_bn2hex(dh->p));
	printf("===> g\n");
	printf("g<%s, 0x%s>\n", BN_bn2dec(dh->g), BN_bn2hex(dh->g));
	printf("===> priv_key\n");
	printf("priv_key<%s, 0x%s>\n", BN_bn2dec(dh->priv_key), BN_bn2hex(dh->priv_key));
	printf("===> pub_key\n");
	printf("pub_key<%s, 0x%s>\n", BN_bn2dec(dh->pub_key), BN_bn2hex(dh->pub_key));
}

void
inline_do_debug()
{
	debug = 1;
}

void
inline_no_debug()
{
	debug = 0;
}

MODULE = kCrypt::DH	PACKAGE = kCrypt::DH	

PROTOTYPES: DISABLE


int
inline_generate_key (sv)
	SV *	sv

int
inline_compute_key (sv_secret, sv_pub_key, sv_dh)
	SV *	sv_secret
	SV *	sv_pub_key
	SV *	sv_dh

HV *
inline_ref_hv (sv)
	SV *	sv

void
inline_deref_hv (sv)
	SV *	sv
	PREINIT:
	I32* temp;
	PPCODE:
	temp = PL_markstack_ptr++;
	inline_deref_hv(sv);
	if (PL_markstack_ptr != temp) {
          /* truly void, because dXSARGS not invoked */
	  PL_markstack_ptr = temp;
	  XSRETURN_EMPTY; /* return empty stack */
        }
        /* must have used dXSARGS; list context implied */
	return; /* assume stack size is correct */

void
inline_do_debug ()
	PREINIT:
	I32* temp;
	PPCODE:
	temp = PL_markstack_ptr++;
	inline_do_debug();
	if (PL_markstack_ptr != temp) {
          /* truly void, because dXSARGS not invoked */
	  PL_markstack_ptr = temp;
	  XSRETURN_EMPTY; /* return empty stack */
        }
        /* must have used dXSARGS; list context implied */
	return; /* assume stack size is correct */

void
inline_no_debug ()
	PREINIT:
	I32* temp;
	PPCODE:
	temp = PL_markstack_ptr++;
	inline_no_debug();
	if (PL_markstack_ptr != temp) {
          /* truly void, because dXSARGS not invoked */
	  PL_markstack_ptr = temp;
	  XSRETURN_EMPTY; /* return empty stack */
        }
        /* must have used dXSARGS; list context implied */
	return; /* assume stack size is correct */

