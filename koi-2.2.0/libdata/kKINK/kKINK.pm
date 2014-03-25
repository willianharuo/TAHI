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
# $TAHI: devel-kink/koi/libdata/kKINK/kKINK.pm,v 1.8 2009/07/08 06:58:56 doo Exp $
#
# $Id: kKINK.pm,v 1.2 2010/07/22 13:23:57 velo Exp $
#
########################################################################

package kKINK::kKINK;

use strict;
use warnings;
use Exporter;

use kKINK::kConnection;
use kKINK::Kerberos5;

our @ISA = qw(Exporter);
our @EXPORT = qw(
	kKINK_new
	kKINK_initialize
	kKINK_finalize
	kKINK_create_session

	kKINK_dump

	kKINK_krb5_tgt
	kKINK_krb5_get_srvtkt
	kKINK_krb5_mk_req
	kKINK_krb5_mk_rep

	kKINK_krb5_encrypt
	kKINK_krb5_decrypt
	kKINK_krb5_calculate_checksum
	kKINK_krb5_prf
);

# $kink_handle = {
#        'krb5_handle' => ?,  # return value from kKINK::Kerberos5::initialize()
#        'session' => ?,      # return value from kKINK::kConnection->new(), kKINK::kConnection object
#        'epoch' => ?,        # time at which kKINK_initialize is called
#        'xid' => ?,          # transaction id
#                             # this value is used only for sending request
#                             # At sending request, send the current value and then increment this value
#        'ap_req' => ?,       # return value from kKINK::Kerberos5::mk_req
#        'ap_rep' => ?,       # return value from kKINK::Kerberos5::mk_rep
#        'decoded' => ?,      # XXX
# }

sub kKINK_new()
{
	my $kink_handle = {};

	return($kink_handle);
}


sub kKINK_initialize($)
{
	my ($kink_handle) = @_;

	my $krb5_handle = kKINK::Kerberos5::initialize();
	unless ($krb5_handle) {
		printf("dbg: %s: %s: kKINK::Kerberos5::initialize: initialization failed\n",
			__FILE__, __LINE__);
		return(undef);
	}
	$kink_handle->{'krb5_handle'} = $krb5_handle;
	$kink_handle->{'epoch'} = time();
	$kink_handle->{'xid'} = 0;

	return($kink_handle);
}

sub kKINK_finalize($)
{
	my ($kink_handle) = @_;

	kKINK::Kerberos5::finalize($kink_handle->{'krb5_handle'});
	$kink_handle->{'session'}->close();
}

sub kKINK_create_session($$$$$)
{
	my ($kink_handle, $tn_addr, $tn_port, $nut_addr, $nut_port) = @_;

	my $session = kKINK::kConnection->new(
		'Link0',	# $interface (Link0|Link1|...)
		#(ADDRESS_FAMILY == AF_INET6) ? 'INET6' : 'INET', # address family (INET|INET6)
		'INET6',
		'UDP',		# protocol (TCP|UDP|ICMP)
		'KINK',	# frameid (NULL|DNS|SIP|IKEv2|KINK)
		$tn_addr,	# srcaddr [undef] 0.0.0.0 or :: is used
		$tn_port,	# srcport [undef] 0 is used
		$nut_addr,	# dstaddr
		$nut_port,	# dstport
	);

	$kink_handle->{'session'} = $session;
	return(1);
}

sub kKINK_dump($)
{
	my ($kink_handle) = @_;

	my $key = undef;

	printf("dbg: %s: %s: kKINK_dump:\n",
	       __FILE__, __LINE__);
	$key = 'xid';
	if ($kink_handle->{$key}) {
		printf("dbg:\t%s -> (%s)\n", $key, $kink_handle->{$key});
	}
	$key = 'SPIi';
	if ($kink_handle->{$key}) {
		printf("dbg:\t%s -> (0x%08s)\n", $key, $kink_handle->{$key});
	}
	$key = 'SPIr';
	if ($kink_handle->{$key}) {
		printf("dbg:\t%s -> (0x%08s)\n", $key, $kink_handle->{$key});
	}
	$key = 'Ni_b';
	if ($kink_handle->{$key}) {
		printf("dbg:\t%s -> (%d, %s)\n",
		       $key, length($kink_handle->{$key}), $kink_handle->{$key});
	}
	$key = 'Nr_b';
	if ($kink_handle->{$key}) {
		printf("dbg:\t%s -> (%d, %s)\n",
		       $key, length($kink_handle->{$key}), $kink_handle->{$key});
	}

	return;
}

# Kerberos5 interface
sub kKINK_krb5_tgt($)
{
	my ($kink_handle) = @_;
	my $tgt = kKINK::Kerberos5::tgt($kink_handle->{'krb5_handle'});
	unless ($tgt) {
		printf("dbg: %s: %s: kKINK_krb5_tgt: kKINK::Kerberos5::tgt failed\n",
		       __FILE__, __LINE__);
		return(undef);
	}

	return($tgt);
}

sub kKINK_krb5_get_srvtkt($)
{
	my ($kink_handle) = @_;

	my $ret = kKINK::Kerberos5::get_srvtkt($kink_handle->{'krb5_handle'});
	if ($ret) {
		printf("dbg: %s: %s: kKINK_krb5_mk_req: kKINK::Kerberos5::srvtkt failed\n",
		       __FILE__, __LINE__);
		return(undef);
	}

	return($ret);
}

sub kKINK_krb5_mk_req($)
{
	my ($kink_handle) = @_;
	my $ap_req = kKINK::Kerberos5::mk_req($kink_handle->{'krb5_handle'});
	unless ($ap_req) {
		printf("dbg: %s: %s: kKINK_krb5_mk_req: kKINK::Kerberos5::mk_req failed\n",
		       __FILE__, __LINE__);
		return(undef);
	}

	return($ap_req);
}

sub kKINK_krb5_mk_rep($$)
{
	my ($kink_handle, $ap_req) = @_;
	my $ap_rep = kKINK::Kerberos5::mk_rep($kink_handle->{'krb5_handle'}, $ap_req);
	unless ($ap_rep) {
		printf("dbg: %s: %s: kKINK_krb5_mk_rep: kKINK::Kerberos5::mk_rep failed\n",
		       __FILE__, __LINE__);
		return(undef);
	}
	return($ap_rep);
}

sub kKINK_krb5_encrypt($$$)
{
	my ($kink_handle, $data, $ap_req) = @_;
	my $result = kKINK::Kerberos5::encrypt($kink_handle->{'krb5_handle'}, $data, $ap_req);
	unless ($result) {
		printf("dbg: %s: %s: kKINK_krb5_encrypt: kKINK::Kerberos5::encrypt failed\n",
		       __FILE__, __LINE__);
		return(undef);
	}
	return($result);
}

sub kKINK_krb5_decrypt($$$)
{
	my ($kink_handle, $data, $ap_req) = @_;
	my $result = kKINK::Kerberos5::decrypt($kink_handle->{'krb5_handle'}, $data, $ap_req);
	unless ($result) {
		printf("dbg: %s: %s: kKINK_krb5_decrypt: kKINK::Kerberos5::decrypt failed\n",
		       __FILE__, __LINE__);
		return(undef);
	}
	return($result);
}

sub kKINK_krb5_calculate_checksum($$$)
{
	my ($kink_handle, $data, $ap_req) = @_;
	return(kKINK::Kerberos5::calculate_checksum($kink_handle->{'krb5_handle'}, $data, $ap_req));
}

sub kKINK_krb5_prf($$$)
{
	my ($kink_handle, $data, $ap_req) = @_;
	return(kKINK::Kerberos5::prf($kink_handle->{'krb5_handle'}, $data, $ap_req));
}


1;
