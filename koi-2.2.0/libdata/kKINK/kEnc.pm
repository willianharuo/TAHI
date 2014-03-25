#!/usr/bin/perl
#
# Copyright (C) 2004, 2005, 2006, 2007, 2008, 2009, 2010
# NTT Advanced Technology, Yokogawa Electric Corporation.
# All rights reserved.
# 
# Redistribution and use of this software in source and binary
# forms, with or without modification, are permitted provided that
# the following conditions and disclaimer are agreed and accepted
# by the user:
# 
# 1. Redistributions of source code must retain the above copyright
#    notice, this list of conditions and the following disclaimer.
# 
# 2. Redistributions in binary form must reproduce the above copyright
#    notice, this list of conditions and the following disclaimer in
#    the documentation and/or other materials provided with
#    the distribution.
# 
# 3. Neither the names of the copyrighters, the name of the project
#    which is related to this software (hereinafter referred to as
#    "project") nor the names of the contributors may be used to
#    endorse or promote products derived from this software without
#    specific prior written permission.
# 
# 4. No merchantable use may be permitted without prior written
#    notification to the copyrighters.
# 
# 5. The copyrighters, the project and the contributors may prohibit
#    the use of this software at any time.
# 
# THIS SOFTWARE IS PROVIDED BY THE COPYRIGHTERS, THE PROJECT AND
# CONTRIBUTORS "AS IS" AND ANY EXPRESS OR IMPLIED WARRANTIES, INCLUDING
# BUT NOT LIMITED THE IMPLIED WARRANTIES OF MERCHANTABILITY AND FITNESS
# FOR A PARTICULAR PURPOSE, ARE DISCLAIMED.  IN NO EVENT SHALL THE
# COPYRIGHTERS, THE PROJECT OR CONTRIBUTORS BE LIABLE FOR ANY DIRECT,
# INDIRECT, INCIDENTAL, SPECIAL, EXEMPLARY, OR CONSEQUENTIAL DAMAGES
# (INCLUDING, BUT NOT LIMITED TO, PROCUREMENT OF SUBSTITUTE GOODS OR
# SERVICES; LOSS OF USE, DATA, OR PROFITS; OR BUSINESS INTERRUPTION)
# HOWEVER CAUSED AND ON ANY THEORY OF LIABILITY, WHETHER IN CONTRACT,
# STRICT LIABILITY, OR TORT (INCLUDING NEGLIGENCE OR OTHERWISE) ARISING
# IN ANY WAY OUT OF THE USE OF THIS SOFTWARE, EVEN IF ADVISED OF THE
# POSSIBILITY OF SUCH DAMAGE.
#
# $TAHI: devel-kink/koi/libdata/kKINK/kEnc.pm,v 1.11 2009/07/08 06:57:17 doo Exp $
#
# $Id: kEnc.pm,v 1.2 2010/07/22 13:23:57 velo Exp $
#
########################################################################

package kKINK::kEnc;

use strict;
use warnings;
use Exporter;
use kKINK::kConsts;
use kKINK::kUtil;
use kKINK::kKINK;
use kKINK::ISAKMP;

our @ISA = qw(Exporter);
our @EXPORT = qw(
	kEncKINKPacket
);

# prototypes
sub encode_KINK_Header($);
sub encode_KINK_Payload($;$);
sub encode_KINK_AP_REQ($);
sub encode_KINK_AP_REP($);
sub encode_KINK_KRB_ERROR($);
sub encode_KINK_TGT_REQ($);
sub encode_KINK_ISAKMP($);
sub encode_KINK_ENCRYPT($$);
sub encode_KINK_ERROR($);
sub encode_ASN1_Length($);
sub encode_Kerberos_PrincipalName($);
sub encode_Kerberos_KRB_ERROR($);

#
sub encode_KINK_Header($)
{
	my ($packet) = @_;
	my $key = undef;
	my $result = undef;

	$key = 'Type';
	unless (defined($packet->{$key})) {
		printf("dbg: %s: %s: encode_KINK_Header: invalid %s\n",
			__FILE__, __LINE__, $key);
		return(undef);
	}
	my $type = $packet->{$key};

	$key = 'MjVer';
	unless (defined($packet->{$key})) {
		printf("dbg: %s: %s: encode_KINK_Header: invalid %s\n",
			__FILE__, __LINE__, $key);
		return(undef);
	}
	my $mjver = $packet->{$key};

	$key = 'RESERVED';
	unless (defined($packet->{$key})) {
		printf("dbg: %s: %s: encode_KINK_Header: invalid %s\n",
			__FILE__, __LINE__, $key);
		return(undef);
	}
	my $reserved = $packet->{$key};

	$key = 'Length';
	unless (defined($packet->{$key})) {
		printf("dbg: %s: %s: encode_KINK_Header: invalid %s\n",
			__FILE__, __LINE__, $key);
		return(undef);
	}
	my $length = $packet->{$key};

	$key = 'DOI';
	unless (defined($packet->{$key})) {
		printf("dbg: %s: %s: encode_KINK_Header: invalid %s\n",
			__FILE__, __LINE__, $key);
		return(undef);
	}
	my $doi = $packet->{$key};

	$key = 'XID';
	unless (defined($packet->{$key})) {
		printf("dbg: %s: %s: encode_KINK_Header: invalid %s\n",
			__FILE__, __LINE__, $key);
		return(undef);
	}
	my $xid = $packet->{$key};

	$key = 'NextPayload';
	unless (defined($packet->{$key})) {
		printf("dbg: %s: %s: encode_KINK_Header: invalid %s\n",
			__FILE__, __LINE__, $key);
		return(undef);
	}
	my $next_payload = $packet->{$key};

	$key = 'ACKREQ';
	unless (defined($packet->{$key})) {
		printf("dbg: %s: %s: encode_KINK_Header: invalid %s\n",
			__FILE__, __LINE__, $key);
		return(undef);
	}
	my $ackreq = $packet->{$key};

	$key = 'RESERVED2';
	unless (defined($packet->{$key})) {
		printf("dbg: %s: %s: encode_KINK_Header: invalid %s\n",
			__FILE__, __LINE__, $key);
		return(undef);
	}
	my $reserved2 = $packet->{$key};

	$key = 'CksumLen';
	unless (defined($packet->{$key})) {
		printf("dbg: %s: %s: encode_KINK_Header: invalid %s\n",
			__FILE__, __LINE__, $key);
		return(undef);
	}
	my $cksumlen = $packet->{$key};

	# header
	$result = pack('C C n N N C C n',
		       $type,
		       ($mjver << 4) | $reserved,
		       $length,
		       $doi,
		       $xid,
		       $next_payload,
		       ($ackreq << 7) | $reserved2,
		       $cksumlen);

	return($result);
}


#
sub encode_KINK_Payload($;$)
{
	my ($kink_handle, $packet) = @_;

	my $payload = undef;
	if ($packet->{'_name'} eq 'KINK_AP_REQ Payload') {
		$payload = encode_KINK_AP_REQ($packet);
	}
	elsif ($packet->{'_name'} eq 'KINK_AP_REP Payload') {
		$payload = encode_KINK_AP_REP($packet);
	}
	elsif ($packet->{'_name'} eq 'KINK_KRB_ERROR Payload') {
		$payload = encode_KINK_KRB_ERROR($packet);
	}
	elsif ($packet->{'_name'} eq 'KINK_TGT_REQ Payload') {
		$payload = encode_KINK_TGT_REQ($packet);
	}
	elsif ($packet->{'_name'} eq 'KINK_TGT_REP Payload') {
		$payload = encode_KINK_TGT_REP($packet);
	}
	elsif ($packet->{'_name'} eq 'KINK_ISAKMP Payload') {
		$payload = encode_KINK_ISAKMP($packet);
	}
	elsif ($packet->{'_name'} eq 'KINK_ENCRYPT Payload') {
		$payload = encode_KINK_ENCRYPT($kink_handle, $packet);
	}
	elsif ($packet->{'_name'} eq 'KINK_ERROR Payload') {
		$payload = encode_KINK_ERROR($packet);
	}
	else {
		# XXX error
		printf("dbg: %s: %s: encode_KINK_Payload: invalid payload name(%s)\n",
		       __FILE__, __LINE__, $packet->{'_name'});
		exit(1);
		# NOTREACHED
	}

	# padding
	my $pad_length = align(length($payload), 4) - length($payload);
	for (my $i=0; $i < $pad_length; $i++) {
		$payload .= pack('C', 0);
	}

	return($payload);
}


#
sub encode_KINK_AP_REQ($)
{
	my ($packet) = @_;

	my $key = undef;
	my $result = undef;

	$key = 'NextPayload';
	unless (defined($packet->{$key})) {
		printf("dbg: %s: %s: encode_KINK_AP_REQ: invalid %s\n",
			__FILE__, __LINE__, $key);
		exit(1);
		# NOTREACHED
	}
	my $next_payload = $packet->{$key};

	$key = 'RESERVED';
	unless (defined($packet->{$key})) {
		printf("dbg: %s: %s: encode_KINK_AP_REQ: invalid %s\n",
			__FILE__, __LINE__, $key);
		exit(1);
		# NOTREACHED
	}
	my $reserved = $packet->{$key};

	$key = 'EPOCH';
	unless (defined($packet->{$key})) {
		printf("dbg: %s: %s: encode_KINK_AP_REQ: invalid %s\n",
			__FILE__, __LINE__, $key);
		exit(1);
		# NOTREACHED
	}
	my $epoch = $packet->{$key};

	$key = 'AP-REQ';
	unless (defined($packet->{$key})) {
		printf("dbg: %s: %s: encode_KINK_AP_REQ: invalid %s\n",
			__FILE__, __LINE__, $key);
		exit(1);
		# NOTREACHED
	}
	my $ap_req = $packet->{$key};

	$key = 'Payload Length';
	my $length = ($packet->{$key} eq 'auto') ? 8 + length($ap_req) : $packet->{$key};

	$result = pack('C C n N',
		       $next_payload,
		       $reserved,
		       $length,
		       $epoch);
	$result .= $ap_req;

	return($result);
}


#
sub encode_KINK_AP_REP($)
{
	my ($packet) = @_;

	my $key = undef;
	my $result = undef;

	$key = 'NextPayload';
	unless (defined($packet->{$key})) {
		printf("dbg: %s: %s: encode_KINK_AP_REP: invalid %s\n",
			__FILE__, __LINE__, $key);
		exit(1);
		# NOTREACHED
	}
	my $next_payload = $packet->{$key};

	$key = 'RESERVED';
	unless (defined($packet->{$key})) {
		printf("dbg: %s: %s: encode_KINK_AP_REP: invalid %s\n",
			__FILE__, __LINE__, $key);
		exit(1);
		# NOTREACHED
	}
	my $reserved = $packet->{$key};

	$key = 'EPOCH';
	unless (defined($packet->{$key})) {
		printf("dbg: %s: %s: encode_KINK_AP_REP: invalid %s\n",
			__FILE__, __LINE__, $key);
		exit(1);
		# NOTREACHED
	}
	my $epoch = $packet->{$key};

	$key = 'AP-REP';
	unless (defined($packet->{$key})) {
		printf("dbg: %s: %s: encode_KINK_AP_REP: invalid %s\n",
			__FILE__, __LINE__, $key);
		exit(1);
		# NOTREACHED
	}
	my $ap_rep = $packet->{$key};

	$key = 'Payload Length';
	my $length = ($packet->{$key} eq 'auto') ? 8 + length($ap_rep) : $packet->{$key};

	$result = pack('C C n N',
		       $next_payload,
		       $reserved,
		       $length,
		       $epoch);
	$result .= $ap_rep;

	return($result);
}


#
sub encode_KINK_KRB_ERROR($)
{
	my ($packet) = @_;

	my $key = undef;
	my $result = undef;

	$key = 'NextPayload';
	unless (defined($packet->{$key})) {
		printf("dbg: %s: %s: encode_KINK_KRB_ERROR: invalid %s\n",
			__FILE__, __LINE__, $key);
		exit(1);
		# NOTREACHED
	}
	my $next_payload = $packet->{$key};

	$key = 'RESERVED';
	my $reserved = defined($packet->{$key}) ? $packet->{$key} : 0;

	$key = 'KRB-ERROR';
	unless (defined($packet->{$key})) {
		printf("dbg: %s: %s: encode_KINK_KRB_ERROR: invalid %s\n",
			__FILE__, __LINE__, $key);
		exit(1);
		# NOTREACHED
	}
	my $krb_error = encode_Kerberos_KRB_ERROR($packet->{$key});

	$key = 'Payload Length';
	my $length = ($packet->{$key} eq 'auto') ? 4 + length($krb_error) : $packet->{$key};

	$result = pack('C C n',
		       $next_payload,
		       $reserved,
		       $length);
	$result .= $krb_error;

	return($result)
}


#
sub encode_KINK_TGT_REQ($)
{
	my ($packet) = @_;

	my $key = undef;
	my $result = undef;

	$key = 'NextPayload';
	unless (defined($packet->{$key})) {
		printf("dbg: %s: %s: encode_KINK_TGT_REQ: invalid %s\n",
			__FILE__, __LINE__, $key);
		exit(1);
		# NOTREACHED
	}
	my $next_payload = $packet->{$key};

	$key = 'RESERVED';
	my $reserved = defined($packet->{$key}) ? $packet->{$key} : 0;

	$key = 'PrincName';
	unless (defined($packet->{$key})) {
		printf("dbg: %s: %s: encode_KINK_TGT_REQ: invalid %s\n",
			__FILE__, __LINE__, $key);
		exit(1);
		# NOTREACHED
	}
	my $princname = $packet->{$key};
	$princname =~ s/\\/\\\\/g;
	$princname =~ s/\0/\\0/g;
	$princname =~ s/\t/\\t/g;
	$princname =~ s/\n/\\n/g;
	$princname =~ s/@/\\@/g;
	$princname =~ s/\//\\\//g;
	$princname = pack('A*', $princname);

	$key = 'Payload Length';
	my $length = ($packet->{$key} eq 'auto') ? 4 + 2 + length($princname) : $packet->{$key};
	$result = pack('C C n',
		       $next_payload,
		       $reserved,
		       $length);
	$result .= pack('n', length($princname));
	$result .= $princname;

	return($result)
}

#
sub encode_KINK_TGT_REP($)
{
	my ($packet) = @_;

	my $key = undef;
	my $result = undef;

	printf("TGT_REP %s %s %s\n", $packet->{'NextPayload'}, $packet->{'RESERVED'}, unpack('H*', $packet->{'TGT'}));

	$key = 'NextPayload';
	unless (defined($packet->{$key})) {
		printf("dbg: %s: %s: encode_KINK_TGT_REP: invalid %s\n",
			__FILE__, __LINE__, $key);
		exit(1);
		# NOTREACHED
	}
	my $next_payload = $packet->{$key};

	$key = 'RESERVED';
	my $reserved = defined($packet->{$key}) ? $packet->{$key} : 0;

	$key = 'TGT';
	unless (defined($packet->{$key})) {
		printf("dbg: %s: %s: encode_KINK_TGT_REP: invalid %s\n",
			__FILE__, __LINE__, $key);
		exit(1);
		# NOTREACHED
	}
	my $tgt = $packet->{$key};

	$key = 'Payload Length';
	my $length = ($packet->{$key} eq 'auto') ? 4 + 2 + length($tgt) : $packet->{$key};
	$result = pack('C C n',
		       $next_payload,
		       $reserved,
		       $length);
	$result .= $tgt;

	return($result)
}

#
sub encode_KINK_ISAKMP($)
{
	my ($packet) = @_;

	my $key = undef;
	my $result = undef;

	$key = 'NextPayload';
	unless (defined($packet->{$key})) {
		printf("dbg: %s: %s: encode_KINK_ISAKMP: invalid %s\n",
			__FILE__, __LINE__, $key);
		exit(1);
		# NOTREACHED
	}
	my $next_payload = $packet->{$key};

	$key = 'RESERVED';
	my $reserved = defined($packet->{$key}) ? $packet->{$key} : 0;

	$key = 'InnerNextPayload';
	unless (defined($packet->{$key})) {
		printf("dbg: %s: %s: encode_KINK_ISAKMP: invalid %s\n",
			__FILE__, __LINE__, $key);
		exit(1);
		# NOTREACHED
	}
	my $inner_next_payload = $packet->{$key};

	$key = 'QMMaj';
	my $qmmaj = defined($packet->{$key}) ? $packet->{$key} : 1;

	$key = 'QMMin';
	my $qmmin = defined($packet->{$key}) ? $packet->{$key} : 0;

	$key = 'RESERVED2';
	my $reserved2 = defined($packet->{$key}) ? $packet->{$key} : 0;

	$key = 'Quick Mode Payloads';
	unless (defined($packet->{$key})) {
		printf("dbg: %s: %s: encode_KINK_ISAKMP: invalid %s\n",
			__FILE__, __LINE__, $key);
		exit(1);
		# NOTREACHED
	}
	my $quick_mode_payload = kKINK::ISAKMP::encode_ISAKMP_Payload($packet->{$key});

	$key = 'Payload Length';
	my $length = ($packet->{$key} eq 'auto') ? 8 + length($quick_mode_payload) : $packet->{$key};

	$result = pack('C C n C C n',
		       $next_payload,
		       $reserved,
		       $length,
		       $inner_next_payload,
		       ($qmmaj << 4) | $qmmin,
		       $reserved2);
	$result .= $quick_mode_payload;

	return($result)
}


#
sub encode_KINK_ENCRYPT($$)
{
	my ($kink_handle, $packet) = @_;

	my $key = undef;
	my $result = undef;

	$key = 'NextPayload';
	unless (defined($packet->{$key})) {
		printf("dbg: %s: %s: encode_KINK_ENCRYPT: invalid %s\n",
			__FILE__, __LINE__, $key);
		exit(1);
		# NOTREACHED
	}
	my $next_payload = $packet->{$key};

	$key = 'RESERVED';
	unless (defined($packet->{$key})) {
		printf("dbg: %s: %s: encode_KINK_ENCRYPT: invalid %s\n",
			__FILE__, __LINE__, $key);
		exit(1);
		# NOTREACHED
	}
	my $reserved = defined($packet->{$key}) ? $packet->{$key} : 0;

	my $payload = undef;
	if ($packet->{'_encrypted'}) {
		$payload = $packet->{'_encrypted'};
	}
	else {
		$key = 'InnerNextPayload';
		my $inner_next_payload = defined($packet->{$key}) ? $packet->{$key} : 0;

		$key = 'RESERVED2';
		my $reserved2 = defined($packet->{$key}) ? $packet->{$key} : 0;

		$key = 'Payload';
		unless (defined($packet->{$key})) {
			printf("dbg: %s: %s: encode_KINK_ENCRYPT: invalid %s\n",
			       __FILE__, __LINE__, $key);
			exit(1);
			# NOTREACHED
		}
		my $payloads = $packet->{$key};
		$payload = '';
		foreach my $p (@{$payloads}) {
			$payload .= encode_KINK_Payload($kink_handle, $p);
		}
		$payload = pack('C C n', $inner_next_payload, ($reserved2 >> 8) & 0xf, $reserved2 & 0xff) . $payload;
		my $ap_req = undef;
		if ($kink_handle->{'TN'}->{'role'} eq 'Responder') {
			$ap_req = $kink_handle->{'ap_req'};
		}
		$payload = kKINK_krb5_encrypt($kink_handle, $payload, $ap_req);
	}

	$key = 'Payload Length';
	my $length = undef;
	if ($packet->{$key} eq 'auto') {
		$length = 4 + length($payload);
		$packet->{$key} = $length;
	}
	else {
		$length = $packet->{$key};
	}

	$result = pack('C C n',
		       $next_payload,
		       $reserved,
		       $length);
	$result .= $payload;

	return($result);
}


#
sub encode_KINK_ERROR($)
{
	my ($packet) = @_;

	my $key = undef;
	my $result = undef;

	$key = 'NextPayload';
	unless (defined($packet->{$key})) {
		printf("dbg: %s: %s: encode_KINK_ERROR: invalid %s\n",
			__FILE__, __LINE__, $key);
		exit(1);
		# NOTREACHED
	}
	my $next_payload = $packet->{$key};

	$key = 'RESERVED';
	my $reserved = defined($packet->{$key}) ? $packet->{$key} : 0;

	$key = 'Payload Length';
	my $length = ($packet->{$key} eq 'auto') ? 8 : $packet->{$key};


	$key = 'ErrorCode';
	unless (defined($packet->{$key})) {
		printf("dbg: %s: %s: encode_KINK_ERROR: invalid %s\n",
			__FILE__, __LINE__, $key);
		exit(1);
		# NOTREACHED
	}
	my $error_code = $packet->{$key};

	$result = pack('C C n N',
		       $next_payload,
		       $reserved,
		       $length,
		       $error_code);

	return($result);
}

# Kerberos
sub encode_ASN1_Length($)
{
	my ($length) = @_;
	my $ret = undef;

	if ($length > 127) {
		my $len = sprintf('%x', $length);
		if (length($len) % 2) {
			$len = '0' . $len;
		}
		$len = pack('H*', $len);
		$ret = pack('C', 0x80 + length($len)) . $len;
	}
	else {
		my $len = sprintf('%x', $length);
		if (length($len) % 2) {
			$len = '0' . $len;
		}
		$ret = pack('H*', $len);
	}

	return($ret);
}

sub encode_Kerberos_PrincipalName($)
{
	my ($pname) = @_;

	my $ret = undef;
	my $key = undef;
	my $type = undef;
	my $length = undef;
	my $value = undef;

	my $name_type = undef;
	my $name_string = undef;
	{
		# name-type
		$key = 'name-type';
		unless (defined($pname->{$key})) {
			printf("dbg: %s: %s: encode_Kerberos_KRB_ERROR: invalid %s\n",
			       __FILE__, __LINE__, $key);
			exit(1);
			# NOTREACHED
		}
		# Type
		$type = 0x02;
		$type = pack('C', $type);

		# Value
		$value = $pname->{$key};
		$value = sprintf('%x', $value);
		if (length($value) % 2) {
			$value = '0' . $value;
		}
		$value = pack('H*', $value);

		# Length
		$length = encode_ASN1_Length(length($value));
		$value = $type . $length . $value;

		# a0
		$type = 0xa0;
		$type = pack('C', $type);
		$length = encode_ASN1_Length(length($value));

		$name_type = $type . $length . $value;
	}
	{
		$key = 'name-string';
		unless (defined($pname->{$key})) {
			printf("dbg: %s: %s: encode_Kerberos_KRB_ERROR: invalid %s\n",
			       __FILE__, __LINE__, $key);
			exit(1);
			# NOTREACHED
		}

		# Value
		my @name = @{$pname->{$key}};
		$value = '';
		foreach my $elm (@name) {
			$type = 0x1b;
			$value .= pack('C', $type);
			$value .= encode_ASN1_Length(length($elm));
			$value .= pack('A*', $elm);
		}

		$type = 0x30;
		$type = pack('C', $type);
		$length = encode_ASN1_Length(length($value));
		$value = $type . $length . $value;

		# a1
		$type = 0xa1;
		$type = pack('C', $type);
		$length = encode_ASN1_Length(length($value));

		$name_string = $type . $length . $value;
	}

	$type = 0x30;
	$type = pack('C', $type);
	$value = $name_type . $name_string;
	$length = encode_ASN1_Length(length($value));

	$ret = $type . $length . $value;

	return($ret);
}

sub encode_Kerberos_KRB_ERROR($)
{
	my ($packet) = @_;

	# KRB-ERROR       ::= [APPLICATION 30] SEQUENCE {
	#         pvno            [0] INTEGER (5),
	#         msg-type        [1] INTEGER (30),
	#         ctime           [2] KerberosTime OPTIONAL,
	#         cusec           [3] Microseconds OPTIONAL,
	#         stime           [4] KerberosTime,
	#         susec           [5] Microseconds,
	#         error-code      [6] Int32,
	#         crealm          [7] Realm OPTIONAL,
	#         cname           [8] PrincipalName OPTIONAL,
	#         realm           [9] Realm -- service realm --,
	#         sname           [10] PrincipalName -- service name --,
	#         e-text          [11] KerberosString OPTIONAL,
	#         e-data          [12] OCTET STRING OPTIONAL
	#   }

	my $result = undef;
	my $key = undef;
	my $type = undef;
	my $length = undef;
	my $value = undef;

	my @data = ();

	{
		#         pvno            [0] INTEGER (5),
		$key = 'pvno';
		unless (defined($packet->{$key})) {
			printf("dbg: %s: %s: encode_Kerberos_KRB_ERROR: invalid %s\n",
			       __FILE__, __LINE__, $key);
			exit(1);
			# NOTREACHED
		}
		# Type
		$type = 0x02;
		$type = pack('C', $type);

		# Value
		$value = $packet->{$key};
		$value = sprintf('%x', $value);
		if (length($value) % 2) {
			$value = '0' . $value;
		}
		$value = pack('H*', $value);

		# Length
		$length = encode_ASN1_Length(length($value));

		$data[0] = $type . $length . $value;
	}
	{
		#         msg-type        [1] INTEGER (30),
		$key = 'msg-type';
		unless (defined($packet->{$key})) {
			printf("dbg: %s: %s: encode_Kerberos_KRB_ERROR: invalid %s\n",
			       __FILE__, __LINE__, $key);
			exit(1);
			# NOTREACHED
		}
		# Type
		$type = 0x02;
		$type = pack('C', $type);

		# Value
		$value = $packet->{$key};
		$value = sprintf('%x', $value);
		if (length($value) % 2) {
			$value = '0' . $value;
		}
		$value = pack('H*', $value);

		# Length
		$length = encode_ASN1_Length(length($value));

		$data[1] = $type . $length . $value;
	}
	{
		#         ctime           [2] KerberosTime OPTIONAL,
		$key = 'ctime';
		if (defined($packet->{$key})) {
			# Type
			$type = 0x18;
			$type = pack('C', $type);

			# Value
			$value = $packet->{$key}; # 20090810 145300
			$value = pack('A*', $value);
			$value .= pack('C', 0x5a); # (UTC)

			# Length
			$length = encode_ASN1_Length(length($value));

			$data[2] = $type . $length . $value;
		}
	}
	{
		#         cusec           [3] Microseconds OPTIONAL,
		$key = 'cusec';
		if (defined($packet->{$key})) {
			# Type
			$type = 0x02;
			$type = pack('C', $type);

			# Value
			$value = $packet->{$key};
			$value = sprintf('%x', $value);
			if (length($value) % 2) {
				$value = '0' . $value;
			}
			$value = pack('H*', $value);

			# Length
			$length = encode_ASN1_Length(length($value));

			$data[3] = $type . $length . $value;
		}
	}
	{
		#         stime           [4] KerberosTime,
		$key = 'stime';
		unless (defined($packet->{$key})) {
			printf("dbg: %s: %s: encode_Kerberos_KRB_ERROR: invalid %s\n",
			       __FILE__, __LINE__, $key);
			exit(1);
			# NOTREACHED
		}

		# Type
		$type = 0x18;
		$type = pack('C', $type);

		# Value
		$value = $packet->{$key}; # 20090810 145300
		$value = pack('A*', $value);
		$value .= pack('C', 0x5a); # (UTC)

		# Length
		$length = encode_ASN1_Length(length($value));

		$data[4] = $type . $length . $value;
	}
	{
		#         susec           [5] Microseconds,
		$key = 'susec';
		unless (defined($packet->{$key})) {
			printf("dbg: %s: %s: encode_Kerberos_KRB_ERROR: invalid %s\n",
			       __FILE__, __LINE__, $key);
			exit(1);
			# NOTREACHED
		}
		# Type
		$type = 0x02;
		$type = pack('C', $type);

		# Value
		$value = $packet->{$key};
		$value = sprintf('%x', $value);
		if (length($value) % 2) {
			$value = '0' . $value;
		}
		$value = pack('H*', $value);

		# Length
		$length = encode_ASN1_Length(length($value));

		$data[5] = $type . $length . $value;
	}
	{
		#         error-code      [6] Int32,
		$key = 'error-code';
		unless (defined($packet->{$key})) {
			printf("dbg: %s: %s: encode_Kerberos_KRB_ERROR: invalid %s\n",
			       __FILE__, __LINE__, $key);
			exit(1);
			# NOTREACHED
		}
		# Type
		$type = 0x02;
		$type = pack('C', $type);

		# Value
		$value = $packet->{$key};
		$value = sprintf('%x', $value);
		if (length($value) % 2) {
			$value = '0' . $value;
		}
		$value = pack('H*', $value);

		# Length
		$length = encode_ASN1_Length(length($value));

		$data[6] = $type . $length . $value;
	}
	{
		#         crealm          [7] Realm OPTIONAL,
		$key = 'crealm';
		unless (defined($packet->{$key})) {
			printf("dbg: %s: %s: encode_Kerberos_KRB_ERROR: invalid %s\n",
			       __FILE__, __LINE__, $key);
			exit(1);
			# NOTREACHED
		}
		# Type
		$type = 0x1b;
		$type = pack('C', $type);

		# Value
		$value = $packet->{$key};
		$value = pack('A*', $value);

		# Length
		$length = encode_ASN1_Length(length($value));

		$data[7] = $type . $length . $value;
	}
	{
		#         cname           [8] PrincipalName OPTIONAL,
		$key = 'cname';
		unless (defined($packet->{$key})) {
			printf("dbg: %s: %s: encode_Kerberos_KRB_ERROR: invalid %s\n",
			       __FILE__, __LINE__, $key);
			exit(1);
			# NOTREACHED
		}

		$data[8] = encode_Kerberos_PrincipalName($packet->{$key});
	}
	{
		#         realm           [9] Realm -- service realm --,
		$key = 'realm';
		unless (defined($packet->{$key})) {
			printf("dbg: %s: %s: encode_Kerberos_KRB_ERROR: invalid %s\n",
			       __FILE__, __LINE__, $key);
			exit(1);
			# NOTREACHED
		}
		# Type
		$type = 0x1b;
		$type = pack('C', $type);

		# Value
		$value = $packet->{$key};
		$value = pack('A*', $value);

		# Length
		$length = encode_ASN1_Length(length($value));

		$data[9] = $type . $length . $value;
	}
	{
		#         sname           [10] PrincipalName -- service name --,
		$key = 'sname';
		unless (defined($packet->{$key})) {
			printf("dbg: %s: %s: encode_Kerberos_KRB_ERROR: invalid %s\n",
			       __FILE__, __LINE__, $key);
			exit(1);
			# NOTREACHED
		}

		$data[10] = encode_Kerberos_PrincipalName($packet->{$key});
	}
	{
		#         e-text          [11] KerberosString OPTIONAL,
		$key = 'e-text';
		if (defined($packet->{$key})) {
			# Type
			$type = 0x1b;
			$type = pack('C', $type);

			# Value
			$value = $packet->{$key};
			$value = pack('A*', $value);

			# Length
			$length = encode_ASN1_Length(length($value));

			$data[11] = $type . $length . $value;
		}
	}
	{
		#         e-data          [12] OCTET STRING OPTIONAL
		$key = 'e-data';
		if (defined($packet->{$key})) {
			# Type
			$type = 0x04;
			$type = pack('C', $type);

			# Value
			$value = $packet->{$key};
			$value = pack('H*', $value);

			# Length
			$length = encode_ASN1_Length(length($value));

			$data[12] = $type . $length . $value;
		}
	}

	# KRB-ERROR       ::= [APPLICATION 30] SEQUENCE {
	$value = '';

	for (my $i=0; $i < 13; $i++) {
		unless (defined($data[$i])) {
			next;
		}

		my $index = 'a' . sprintf('%x', $i);
		$type = pack('H*', $index);
		$length = encode_ASN1_Length(length($data[$i]));

		$value .= $type . $length . $data[$i];
	}

	# SEQUENCE
	$type = 0x30;
	$type = pack('C', $type);
	$length = encode_ASN1_Length(length($value));
	$value = $type . $length . $value;

	# [APPLICATION 30]
	$type = 0x7e;
	$type = pack('C', $type);
	$length = encode_ASN1_Length(length($value));
	$result = $type . $length . $value;

	return($result);
}

1;
