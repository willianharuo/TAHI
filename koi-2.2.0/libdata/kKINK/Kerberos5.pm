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
# $Id: Kerberos5.pm,v 1.2 2010/07/22 13:23:57 velo Exp $
#
################################################################

package kKINK::Kerberos5;

use strict;
use warnings;

use constant {
	'MY_PRINCIPAL_NAME' => 'kink/tn.example.com',
	'SERVICE' => 'kink',
	'SERVER' => 'nut.example.com',
	'REALM' => 'EXAMPLE.COM',
	'KRB5_TOOL_DIR' => '/usr/local/koi/bin',
};

my $debug = 0; # 1;

sub initialize()
{
	my %ret = ();
	my $cmd = KRB5_TOOL_DIR . '/krb5_init';

	if ($debug) {
		printf("dbg: initialize: %s: %s: cmd(%s)\n", __FILE__, __LINE__, $cmd);
	}

	my ($status, @lines) = kCommon::execCmd($cmd);

	if ($status) {
		return(undef);
	}

	my $result = {
	};
	return($result);
}

sub finalize($)
{
	my ($krb5_handle) = @_;

	return;
}

sub tgt($)
{
	my ($krb5_handle) = @_;

	my %ret = ();
	my $cmd = KRB5_TOOL_DIR . '/krb5_tgt';

	if ($debug) {
		printf("dbg: tgt: %s: %s: cmd(%s)\n", __FILE__, __LINE__, $cmd);
	}

	my ($status, @lines) = kCommon::execCmd($cmd);

	foreach (@lines) {
		if($_ =~ /^tgt:([0-9a-zA-Z]+)$/ ) {
			$ret{'tgt'}	= pack('H*', $1);
		}
	}

	unless (defined($ret{'tgt'})) {
		return(undef);
	}

	if ($debug) {
		printf("dbg: tgt: %s: %s: TGT(%s, %s)\n", __FILE__, __LINE__,
		       length($ret{'tgt'}), unpack('H*', $ret{'tgt'}));
	}
	return($ret{'tgt'});
}

sub get_srvtkt($)
{
	my ($krb5_handle) = @_;

	my %ret = ();
	my $cmd = KRB5_TOOL_DIR . '/krb5_srvtkt';

	if ($debug) {
		printf("dbg: mk_req: %s: %s: cmd(%s)\n", __FILE__, __LINE__, $cmd);
	}

	my ($status, @lines) = kCommon::execCmd($cmd);

	return($status);
}

sub mk_req($)
{
	my ($krb5_handle) = @_;

	my %ret = ();
	my $cmd = KRB5_TOOL_DIR . '/krb5_ap_req';

	if ($debug) {
		printf("dbg: mk_req: %s: %s: cmd(%s)\n", __FILE__, __LINE__, $cmd);
	}

	my ($status, @lines) = kCommon::execCmd($cmd);

	foreach (@lines) {
		if($_ =~ /^ap_req:([0-9a-zA-Z]+)$/ ) {
			$ret{'ap_req'}	= pack('H*', $1);
		}
	}

	unless (defined($ret{'ap_req'})) {
		return(undef);
	}

	if ($debug) {
		printf("dbg: mk_rep: %s: %s: AP_REQ(%s, %s)\n", __FILE__, __LINE__,
		       length($ret{'ap_req'}), unpack('H*', $ret{'ap_req'}));
	}
	return($ret{'ap_req'});
}

sub mk_rep($$)
{
	my ($krb5_handle, $ap_req) = @_;

	my %ret = ();
	my $cmd = KRB5_TOOL_DIR . '/krb5_ap_rep';
	if ($ap_req) {
		$cmd .= ' -q ' . unpack('H*', $ap_req);
	}

	if ($debug) {
		printf("dbg: mk_rep: %s: %s: cmd(%s)\n", __FILE__, __LINE__, $cmd);
	}

	my ($status, @lines) = kCommon::execCmd($cmd);

	foreach (@lines) {
		if($_ =~ /^ap_rep:([0-9a-zA-Z]+)$/ ) {
			$ret{'ap_rep'}	= pack('H*', $1);
		}
	}

	unless (defined($ret{'ap_rep'})) {
		return(undef);
	}

	if ($debug) {
		printf("dbg: mk_rep: %s: %s: AP_REP(%s, %s)\n", __FILE__, __LINE__,
	       length($ret{'ap_rep'}), unpack('H*', $ret{'ap_rep'}));
	}
	return($ret{'ap_rep'});
}

sub encrypt($$$)
{
	my ($krb5_handle, $dec, $ap_req) = @_;

	my %ret = ();
	my $cmd = KRB5_TOOL_DIR . '/krb5_encrypt';
	if ($ap_req) {
		$cmd .= ' -q ' . unpack('H*', $ap_req);
	}
	$cmd .= ' ' . unpack('H*', $dec);

	if ($debug) {
		printf("dbg: encrypt: %s: %s: cmd(%s)\n", __FILE__, __LINE__, $cmd);
		printf("dbg: encrypt: %s: %s: PLAIN(%s, %s)\n", __FILE__, __LINE__,
		       length($dec), unpack('H*', $dec));
	}

	my ($status, @lines) = kCommon::execCmd($cmd);

	foreach (@lines) {
		if($_ =~ /^cipher_text:([0-9a-zA-Z]+)$/ ) {
			$ret{'cipher_text'}	= pack('H*', $1);
		}
	}

	unless (defined($ret{'cipher_text'})) {
		return(undef);
	}

	if ($debug) {
		printf("dbg: encrypt: %s: %s: CIPHER(%s, %s)\n", __FILE__, __LINE__,
	       length($ret{'cipher_text'}), unpack('H*', $ret{'cipher_text'}));
	}
	return($ret{'cipher_text'});
}

sub decrypt($$$)
{
	my ($krb5_handle, $enc, $ap_req) = @_;

	my %ret = ();
	my $cmd = KRB5_TOOL_DIR . '/krb5_decrypt';
	if ($ap_req) {
		$cmd .= ' -q ' . unpack('H*', $ap_req);
	}
	$cmd .= ' ' . unpack('H*', $enc);

	if ($debug) {
		printf("dbg: decrypt: %s: %s: cmd(%s)\n", __FILE__, __LINE__, $cmd);
		printf("dbg: decrypt: %s: %s: CIPHER(%s, %s)\n", __FILE__, __LINE__,
		       length($enc), unpack('H*', $enc));
	}

	my ($status, @lines) = kCommon::execCmd($cmd);

	foreach (@lines) {
		if($_ =~ /^plain_text:([0-9a-zA-Z]+)$/ ) {
			$ret{'plain_text'}	= pack('H*', $1);
		}
	}

	unless (defined($ret{'plain_text'})) {
		return(undef);
	}

	if ($debug) {
		printf("dbg: decrypt: %s: %s: PLAIN(%s, %s)\n", __FILE__, __LINE__,
		       length($ret{'plain_text'}), unpack('H*', $ret{'plain_text'}));
	}
	return($ret{'plain_text'});
}

sub calculate_checksum($$$)
{
	my ($krb5_handle, $data, $ap_req) = @_;

	my %ret = ();
	my $cmd = KRB5_TOOL_DIR . '/krb5_cksum';
	if ($ap_req) {
		$cmd .= ' -q ' . unpack('H*', $ap_req);
	}
	$cmd .= ' ' . unpack('H*', $data);

	if ($debug) {
		printf("dbg: decrypt: %s: %s: cmd(%s)\n", __FILE__, __LINE__, $cmd);
		printf("dbg: calculate_checksum: DATA(%s)\n", unpack('H*', $data));
	}

	my ($status, @lines) = kCommon::execCmd($cmd);

	foreach (@lines) {
		if($_ =~ /^cksum:([0-9a-zA-Z]+)$/ ) {
			$ret{'cksum'}	= pack('H*', $1);
		}
	}

	unless (defined($ret{'cksum'})) {
		return(undef);
	}

	if ($debug) {
		printf("dbg: calculate_checksum: CKSUM(%s)\n", unpack('H*', $ret{'cksum'}));
	}

	return($ret{'cksum'});
}

sub prf($$$)
{
	# input binary data and output binary data
	my ($krb5_handle, $data, $ap_req) = @_;

	my %ret = ();
	my $cmd = KRB5_TOOL_DIR . '/krb5_prf';
	if ($ap_req) {
		$cmd .= ' -q ' . unpack('H*', $ap_req);
	}
	$cmd .= ' ' . unpack('H*', $data);

	my ($status, @lines) = kCommon::execCmd($cmd);

	foreach (@lines) {
		if($_ =~ /^prf:([0-9a-zA-Z]+)$/ ) {
			$ret{'prf'}	= pack('H*', $1);
		}
	}

	unless (defined($ret{'prf'})) {
		return(undef);
	}

	return($ret{'prf'});
}


1;

