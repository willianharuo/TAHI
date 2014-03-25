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
# $Id: kJudge.pm,v 1.11 2010/07/22 12:41:17 velo Exp $
#
########################################################################

package kIKE::kJudge;

use strict;
use warnings;
use Exporter;
use kIKE::kHelpers;
use kIKE::kConsts;

our @ISA = qw(Exporter);

our @EXPORT = qw (
	kJudgeIKEMessage2
	kJudgeIKEMessage
	kJudgePrepare2
	kJudgePrepare
	enable_debug
);


#
our $TRUE = $kIKE::kConsts::TRUE;
our $FALSE = $kIKE::kConsts::FALSE;
my $DEBUG = 0; # 1, 2

my $is_initial_exchanges = $FALSE;

my %judge_func = (
	'HDR'	=> \&judge_IKEHeader,
	'SA'	=> \&judge_SecurityAssociationPayload,
	'KE'	=> \&judge_KeyExchangePayload,
	'IDi'	=> \&judge_IdentificationInitiatorPayload,
	'IDr'	=> \&judge_IdentificationResponderPayload,
	'CERT'	=> \&judge_CertificationPayload,
	'CERTREQ'	=> \&judge_CertificationRequestPayload,
	'AUTH'	=> \&judge_AuthenticationPayload,
	'Ni, Nr'	=> \&judge_NoncePayload,
	'N'	=> \&judge_NotifyPayload,
	'D'	=> \&judge_DeletePayload,
	'V'	=> \&judge_VendorIDPayload,
	'TSi'	=> \&judge_TrafficSelectorInitiatorPayload,
	'TSr'	=> \&judge_TrafficSelectorResponderPayload,
	'E'	=> \&judge_EncryptedPayload,
	'CP'	=> \&judge_ConfigurationPayload,
	'EAP'	=> \&judge_stub,
);

my %judgmentFunctions = (
	HDR => \&kJudgeIKEHeader,
	SA => \&kJudgeSecurityAssociationPayload2,
	KE => \&kJudgeKeyExchangePayload,
	IDi => \&kJudgeIdentificationIPayload,
	IDr => \&kJudgeIdentificationRPayload,
	CERT => \&kJudgeCertificationPayload,
	CERTREQ => \&kJudgeCertificationRequestPayload,
	 AUTH => \&kJudgeAuthenticationPayload,
	'Ni, Nr' => \&kJudgeNoncePayload,
	N => \&kJudgeNotifyPayload,
	D => \&kJudgeDeletePayload,
	V => \&kJudgeVendorIDPayload,
	TSi => \&kJudgeTrafficSelectorIPayload,
	TSr => \&kJudgeTrafficSelectorRPayload,
	E => \&kJudgeEncryptedPayload,
	CP => \&kJudgeConfigurationPayload,
#	EAP => \&kJudge,
);

# Hash of payloads' names.
my %payloadsNames = (
	'HDR' => 'IKE Header',
	'SA' => 'Security Association Payload',
	'P' => 'Proposal Substructure',
	'T' => 'Transform Substructure',
	'Attr' => 'Transform Attribute',
	'KE' => 'Key Exchange Payload',
	'IDi' => 'Identification Payload - Initiator',
	'IDr' => 'Identification Payload - Responder',
	'CERT' => 'Certificate Payload',
	'CERTREQ' => 'Certificate Request Payload',
	'AUTH' => 'Authentication Payload',
	'Ni, Nr' => 'Nonce Payload',
	'N' => 'Notify Payload',
	'D' => 'Delete Payload',
	'V' => 'Vendor Payload',
	'TS' => 'Traffic Selector',
	'TSi' => 'Traffic Selector Payload - Initiator',
	'TSr' => 'Traffic Selector Payload - Responder',
	'E' => 'Encrypted Payload',
	'CP' => 'Configuration Payload',
	'EAP' => 'Extended Authentication Protocol Payload',
);

# Hash of field names which need to convert to show correctly.
my %fieldsConvertFunctions = (
	'publicKey'	=> \&convert_Math_BigInt,
	'nonce'		=> \&convert_Math_BigInt,
);

# for payload order check
## IKE_SA_INIT request
my $order_sa_init_req =
[
	{
		type => 'N(COOKIE)',
		omittable => 1,
	},
	{
		type => 'SA',
		omittable => 0,
	},
	{
		type => 'KE',
		omittable => 0,
	},
	{
		type => 'Ni, Nr',
		omittable => 0,
	},
	{
		type => 'N(NAT_DETECTION_SOURCE_IP)',
		omittable => 1,
	},
	{
		type => 'N(NAT_DETECTION_DESTINATION_IP)',
		omittable => 1,
	},
];

## IKE_SA_INIT response
my $order_sa_init_resp =
[
	{
		type => 'N(COOKIE)',
		omittable => 1,
	},
	{
		type => 'SA',
		omittable => 0,
	},
	{
		type => 'KE',
		omittable => 0,
	},
	{
		type => 'Ni, Nr',
		omittable => 0,
	},
	{
		type => 'N(NAT_DETECTION_SOURCE_IP)',
		omittable => 1, # comb with N(NAT_DETECTION_DESTINATION_IP)
	},
	{
		type => 'N(NAT_DETECTION_DESTINATION_IP)',
		omittable => 1, # comb with N(NAT_DETECTION_SOURCE_IP)
	},
	{
		type => 'N(HTTP_CERT_LOOKUP_SUPPORTED)',
		omittable => 1,
	},
	{
		type => 'CERTREQ',
		omittable => 1,
	},
];

## IKE_AUTH request
my $order_auth_req =
[
	{
		type => 'E',
		omittable => 0,
	},
	{
		type => 'IDi',
		omittable => 0,
	},
	{
		type => 'CERT',
		omittable => 1,
	},
	{
		type => 'N(INITIAL_CONTACT)',
		omittable => 1,
	},
	{
		type => 'N(HTTP_CERT_LOOKUP_SUPPORTED)',
		omittable => 1,
	},
	{
		type => 'CERTREQ',
		omittable => 1,
	},
	{
		type => 'IDr',
		omittable => 1,
	},
	{
		type => 'AUTH',
		omittable => 0,
	},
	{
		type => 'CP',
		omittable => 1,
	},
	{
		type => 'N(IPCOMP_SUPPORTED)',
		omittable => 1,
	},
	{
		type => 'N(USE_TRANSPORT_MODE)',
		omittable => 1,
	},
	{
		type => 'N(ESP_TFC_PADDING_NOT_SUPPORTED)',
		omittable => 1,
	},
	{
		type => 'N(NON_FIRST_FRAGMENTS_ALSO)',
		omittable => 1,
	},
	{
		type => 'SA',
		omittable => 0,
	},
	{
		type => 'TSi',
		omittable => 0,
	},
	{
		type => 'TSr',
		omittable => 0,
	},
	# XXX
	# add N(USE_TRANSPORT_MODE) to test with StrongSwan
	# temporarily added and MUST be removed
	#{
	#	type => 'N(USE_TRANSPORT_MODE)',
	#	omittable => 1,
	#},
	# XXX
];

## IKE_AUTH response
my $order_auth_resp =
[
	{
		type => 'E',
		omittable => 0,
	},
	{
		type => 'IDr',
		omittable => 0,
	},
	{
		type => 'CERT',
		omittable => 1,
	},
	{	# XXX
		# IKE_AUTH response should not include N(INITIAL_CONTACT)
		# (See RFC4718 Appendix A.2)
		# but racoon2 include N(INITIAL_CONTACT) in IKE_AUTH response
		type => 'N(INITIAL_CONTACT)',
		omittable => 1,
	},
	{
		type => 'AUTH',
		omittable => 0,
	},
	{
		type => 'CP',
		omittable => 1,
	},
	{
		type => 'N(IPCOMP_SUPPORTED)',
		omittable => 1,
	},
	{
		type => 'N(USE_TRANSPORT_MODE)',
		omittable => 1,
	},
	{
		type => 'N(ESP_TFC_PADDING_NOT_SUPPORTED)',
		omittable => 1,
	},
	{
		type => 'N(NON_FIRST_FRAGMENTS_ALSO)',
		omittable => 1,
	},
	{
		type => 'SA',
		omittable => 0,
	},
	{
		type => 'TSi',
		omittable => 0,
	},
	{
		type => 'TSr',
		omittable => 0,
	},
	{
		type => 'N(ADDITIONAL_TS_POSSIBLE)',
		omittable => 1,
	},
];

## CREATE_CHILD_SA request
my $order_create_child_sa_req =
[
	{
		type => 'E',
		omittable => 0,
	},
	{
		type => 'N(REKEY_SA)',
		omittable => 1,
	},
	{
		type => 'N(IPCOMP_SUPPORTED)',
		omittable => 1,
	},
	{
		type => 'N(USE_TRANSPORT_MODE)',
		omittable => 1,
	},
	{
		type => 'N(ESP_TFC_PADDING_NOT_SUPPORTED)',
		omittable => 1,
	},
	{
		type => 'N(NON_FIRST_FRAGMENTS_ALSO)',
		omittable => 1,
	},
	{
		type => 'SA',
		omittable => 0,
	},
	{
		type => 'Ni, Nr',
		omittable => 0,
	},
	{
		type => 'KE',
		omittable => 1,
	},
	{
		type => 'TSi',
		omittable => 0,
	},
	{
		type => 'TSr',
		omittable => 0,
	},
];

## CREATE_CHILD_SA response
my $order_create_child_sa_resp =
[
	{
		type => 'E',
		omittable => 0,
	},
	{
		type => 'N(IPCOMP_SUPPORTED)',
		omittable => 1,
	},
	{
		type => 'N(USE_TRANSPORT_MODE)',
		omittable => 1,
	},
	{
		type => 'N(ESP_TFC_PADDING_NOT_SUPPORTED)',
		omittable => 1,
	},
	{
		type => 'N(NON_FIRST_FRAGMENTS_ALSO)',
		omittable => 1,
	},
	{
		type => 'SA',
		omittable => 0,
	},
	{
		type => 'Ni, Nr',
		omittable => 0,
	},
	{
		type => 'KE',
		omittable => 1,
	},
	{
		type => 'TSi',
		omittable => 0,
	},
	{
		type => 'TSr',
		omittable => 0,
	},
	{
		type => 'N(ADDITIONAL_TS_POSSIBLE)',
		omittable => 1,
	},
];

## CREATE_CHILD_SA request to rekey IKE_SA
my $order_create_child_sa_rekey_ike_sa_req =
[
	{
		type => 'E',
		omittable => 0,
	},
	{
		type => 'SA',
		omittable => 0,
	},
	{
		type => 'Ni, Nr',
		omittable => 0,
	},
	{
		type => 'KE',
		omittable => 1,
	},
];

## CREATE_CHILD_SA response to rekey IKE_SA
my $order_create_child_sa_rekey_ike_sa_resp =
[
	{
		type => 'E',
		omittable => 0,
	},
	{
		type => 'SA',
		omittable => 0,
	},
	{
		type => 'Ni, Nr',
		omittable => 0,
	},
	{
		type => 'KE',
		omittable => 1,
	},
];

## INFORMATIONAL request
my $order_informational_req =
[
	{
		type => 'N',
		omittable => 1,
	},
	{
		type => 'D',
		omittable => 1,
	},
	{
		type => 'CP(CFG_REQUEST)',
		omittable => 1,
	},
];

## INFORMATIONAL response
my $order_informational_resp =
[
	{
		type => 'N',
		omittable => 1,
	},
	{
		type => 'D',
		omittable => 1,
	},
	{
		type => 'CP(CFG_REPLY)',
		omittable => 1,
	},
];

my $message_order =
{
	IKE_SA_INIT => {
		0 => $order_sa_init_req,
		1 => $order_sa_init_resp
	},
	IKE_AUTH => {
		0 => $order_auth_req,
		1 => $order_auth_resp
	},
	CREATE_CHILD_SA => {
		0 => $order_create_child_sa_req,
		1 => $order_create_child_sa_resp
	},
	CREATE_CHILD_SA_REKEY_IKE_SA => {
		0 => $order_create_child_sa_rekey_ike_sa_req,
		1 => $order_create_child_sa_rekey_ike_sa_resp
	},
	INFORMATIONAL => {
		0 => $order_informational_req,
		1 => $order_informational_resp
	},
};

my $comparison_result =
{
	FALSE => 0,
	TRUE => 1,
	COMB_FALSE => 2,
};


# static functions
sub debug(@);
sub kJudgeCheckPayloadOrder($$);
sub check_payload_order($$$;$);
sub kJudgePrepareExpected($$);
sub prepare_expected_payloads($$$);
sub is_defined_notify_type($);

sub enable_debug() { $DEBUG++; }
sub debug(@)
{
	if ($DEBUG < 2) {
		return;
	}

	print('dbg: ');
	printf(@_);
	return;
}

sub match($$$)
{
	my ($rcv, $exp, $cmp) = @_;

	my $result = $FALSE;
	if ($cmp eq 'range') {
		if (ref($exp) ne 'ARRAY') {
			debug("dbg: kJudge::match: \$exp should be ARRAY for comparator 'range'\n");
			return($FALSE);
		}

		if (scalar(@{$exp}) != 2) {
			debug("dbg: kJudge::match: \$exp should be include min value and max value " .
			       "in ARRAY for comparator 'range'\n");
			return($FALSE);
		}

		debug("dbg: kJudge::match: %s, %s\n", $exp->[0], $exp->[1]);
		my $min = $exp->[0];
		my $max = $exp->[0];

		foreach my $v (@{$exp}) {
			if ($min > $v) {
				$min = $v;
			}
			elsif ($max < $v) {
				$max = $v;
			}
		}

		if ($rcv >= $min && $rcv <= $max) {
			$result = $TRUE;
		}
	}
	elsif ($cmp =~ /^[a-z]{2}$/) {
		my $expression = "'$rcv' $cmp '$exp'";
		$result = (eval($expression)) ? $TRUE : $FALSE;
	}
	elsif ($cmp eq 'already checked') {
		$result = $TRUE;
	}
	elsif ($cmp eq 'any') {
		$result = $TRUE;
	}
	else {
		debug("dbg: kJudge::match: unknown comparator '$cmp'\n");
	}

	return($result);
}

sub set_comparator($$$$)
{
	my ($field, $checked, $exp, $cmp) = @_;

	# if this value has been already checked, skip comparison
	my $has_checked = $FALSE;
	foreach my $elm (@{$checked}) {
		if ($field eq $elm && !defined($cmp)) {
			$has_checked = $TRUE;
			last;
		}
	}

	if ($has_checked) {
		$exp = 'any';
	}
	elsif (!defined($exp)) {
		$exp = 'any';
	}

	# set comparator
	if ($has_checked) {
		$cmp = 'already checked';
	}
	elsif  ($exp =~ /[aA][nN][yY]/) {
		$cmp = 'any';
	}
	elsif (!defined($cmp) || $cmp eq 'nop') {
		$cmp = 'eq';
	}

	# check comparator
	if (defined($cmp)) {
		if (! (!defined($cmp) ||
		       $cmp eq 'eq' ||
		       $cmp eq 'ne' ||
		       $cmp eq 'any' ||
		       $cmp eq 'already checked' ||
		       $cmp eq 'range')) {
			debug("kJudge::set_comparator: unknown comparator '$cmp'\n");
		}
	}

	return($exp, $cmp);
}

sub compare($$$;$)
{
	my ($key, $rcv, $exp, $cmp) = @_;

	debug("kJudge::compare: field(%s) rcv(%s) exp(%s) comp(%s)\n",
	       $key,
	       defined($rcv) ? $rcv : 'undefined',
	       defined($exp) ? $exp : 'undefined',
	       $cmp);

	# check if arguments are valid value
	unless (defined($rcv)) {
		debug("kJudge::compare: undefined value in received packet\n");
		my $result = $FALSE;
		my $str = "<font color='#ff0000'><b>NG</b></font>\t$key";
		$str .= ":\t(received: <font color='#ff0000'><b>undefined</b></font>, expected: $exp, comp: $cmp)";
		return ($result, $str);
	}

	# XXX: should care (ref $exp eq 'ARRAY') here ?

	# convert values to strings. It should be scalar values.
	if ($cmp =~ /^[a-z]{2}$/) {
		$rcv = $rcv . '';
		$exp = $exp . '';
	}

	my $result = match($rcv, $exp, $cmp);

	# XXX: should care reformating here ?

	if ($rcv !~ m/^[ -~]*$/i) {
		do {
			$rcv = kIKE::kHelpers::formatHex(uc(unpack('H*', $rcv)));
		} if (length($rcv) <= 32);
	}

	if ($exp !~ m/^[ -~]*$/i) {
		do {
			$exp = kIKE::kHelpers::formatHex(uc(unpack('H*', $exp)));
		} if (length($exp) <= 32);
	}
	elsif (ref($exp) eq 'ARRAY') {
		$exp = '(' . join(', ', sort(@{$exp})) . ')';
	}
	else {
# 		if (exists($fieldsConvertFunctions{$key})) {
# 			my $conv = $fieldsConvertFunctions{$key};
# 			$exp = $conv->($exp, 0);
# 		}
	}

	my $str = '';
	if ($result) {
		$str = "<b>OK</b>\t$key";
	}
	else {
		$str = "<font color='#ff0000'><b>NG</b></font>\t$key";
	}
	$str .= ":\t(received: $rcv, expected: $exp, comp: $cmp)";

	debug("kJudge::compare: result(%s) str(%s)\n", $result, $str);
	return ($result, $str);
}

sub kJudgeCompare($$$;$) {
	# Read the parameters.
	my ($key, $val, $exp, $comp) = @_;

	if(ref $exp eq 'ARRAY') {
		return(kJudgeCompareArray($key, $val, $exp, $comp));
	}

	# Initialize result.
	my $result;
	my $bRes = $TRUE;
	my $showExp = $TRUE;
	my $any = undef;
	my $expression = undef;

	$comp = 'eq' if (!defined($comp) || $comp eq 'nop');
	if (!defined($exp) || $exp =~ /[aA][nN][yY]/) {
		$result = $TRUE;
		$any = 'any';
		$exp = $val;
	}

	# Convert values to strings. It should be scalar values.
	if ($comp =~ /[a-z]{2}/) {
		$val = $val . '';
		$exp = $exp . '';
	}

	unless (defined($any)) {
		$expression = ($comp =~ /[a-z]{2}/) ? "'$val' $comp '$exp'" : "$val $comp $exp";
		$result = (eval($expression)) ? $TRUE : $FALSE;
	}

	# Reformat the value if not printable or deactivate its showing if to long.
	if  (!defined($val)) {
		$val = 'undef';
	}
	elsif ($val !~ m/^[ -~]*$/i) {
		do {
			$val = kIKE::kHelpers::formatHex(uc(unpack('H*', $val)));
		} if (length($val) <= 32);
	}
	else {
		if (exists($fieldsConvertFunctions{$key})) {
			my $conv = $fieldsConvertFunctions{$key};
			$val = $conv->($val, 0);
		}
	}

	if (defined($any)) {
		$exp = $any;
	}
	elsif (!defined($exp)) {
		$exp = 'undef';
	}
	elsif ($exp !~ m/^[ -~]*$/i) {
		do {
			$exp = kIKE::kHelpers::formatHex(uc(unpack('H*', $exp)));
		} if (length($exp) <= 32);
	}
	else {
		if (exists($fieldsConvertFunctions{$key})) {
			my $conv = $fieldsConvertFunctions{$key};
			$exp = $conv->($exp, 0);
		}
	}

	# Set the result message.
	if ($result) {
		$result = "<b>OK</b>\t$key";
	}
	else {
		$result = "<font color='#ff0000'><b>NG</b></font>\t$key";
		$bRes = $FALSE;
	}
	# Add the clue of the comparison if not deactivated.
	$result .= ":\t(received: $val, expected: $exp, comp: $comp)" if $showExp;
	# Return result and message.
	return ($bRes, $result);
}



sub
kJudgeCompareArray($$$;$)
{
	# Read the parameters.
	my ($key, $val, $exp, $comp) = @_;

	my $showExp	= $TRUE;
	my $bRes	= $FALSE;
	my $result	= undef;

	if(!defined($comp) || ($comp eq 'nop')) {
		$comp = 'oneof';
	}

	if($comp eq 'range') {
		#
		# range
		#
		my $min = $exp->[0];
		my $max = $exp->[0];

		for(my $d = 0; $d <= $#$exp; $d ++) {
			if($min > $exp->[$d]) {
				$min = $exp->[$d];
			}

			if($max < $exp->[$d]) {
				$max = $exp->[$d];
			}
		}

		if(($val >= $min) && ($val <= $max)) {
			$bRes = $TRUE;
		}

		if($bRes) {
			$result = "<B>OK</B>";
		} else {
			$result = "<FONT COLOR=\"#ff0000\"><B>NG</B></FONT>";
			$bRes = $FALSE;
		}

		$result	.= "\t$key";

		if($showExp) {
			$result .= ":\t(received: $val, expected: [$min-$max], comp: $comp)"
		}
	} else {
		#
		# oneof
		#
		for(my $d = 0; $d <= $#$exp; $d ++) {
			if($val == $exp->[$d]) {
				$bRes = $TRUE;
				last;
			}
		}

		if($bRes) {
			$result = "<B>OK</B>";
		} else {
			$result = "<FONT COLOR=\"#ff0000\"><B>NG</B></FONT>";
			$bRes = $FALSE;
		}

		$result	.= "\t$key";

		if($showExp) {
			$result .= ":\t(received: $val, expected: [";

			for(my $d = 0; $d <= $#$exp; $d ++) {
				if($d) {
					$result .= ', ';
				}

				$result .= "$exp->[$d]";
			}

			$result .= "], comp: $comp)"
		}
	}

	return($bRes, $result);
}

sub find_payload($$);
sub find_payload($$)
{
	my ($packet, $payload) = @_;

	my $target = $payload->{'self'};
	if ($payload->{'self'} eq 'N') {
		$target = $payload->{'self'} . '(' . $payload->{'type'} . ')';
	}

	foreach my $p (@{$packet}) {
		my $type = $p->{'self'};
		if ($type eq 'N') {
			$type = $p->{'self'} . '(' . $p->{'type'} . ')';
		}

		if ($type eq $target) {
			return($p);
		}
		elsif ($type eq 'E') {
			return(find_payload($p->{'innerPayloads'}, $payload));
		}
	}

	return(undef);
}

sub get_payload_types($);
sub get_payload_types($)
{
	my ($packet) = @_;

	my @array = ();
	foreach my $payload0 (@{$packet}) {
		my $tmp = $payload0->{'self'};
		if ($payload0->{'self'} eq 'E') {
			$tmp .= get_payload_types($payload0->{'innerPayloads'});
		}
		elsif ($payload0->{'self'} eq 'SA') {
			$tmp .= get_payload_types($payload0->{'proposals'});
		}
		elsif ($payload0->{'self'} eq 'P') {
			$tmp .= get_payload_types($payload0->{'transforms'});
		}
		elsif ($payload0->{'self'} eq 'T') {
			$tmp .= get_payload_types($payload0->{'attributes'});
		}
		elsif ($payload0->{'self'} eq 'TSi' || $payload0->{'self'} eq 'TSr') {
			$tmp .= get_payload_types($payload0->{'selectors'});
		}

		push(@array, $tmp);
	}

	my $str = '';
	if (scalar(@array)) {
		$str = join(', ', @array);
		$str = '(' . $str . ')';
	}

	return($str);
}

sub show_judglog($)
{
	my ($log) = @_;

	if ($DEBUG == 0) {
		return;
	}

	foreach my $elm (@{$log}) {
		unless (defined($elm)) {
			next;
		}
		unless (ref($elm)) {
			printf("dbg: kJudge::show_judglog: %s\n", $elm);
			next;
		}
		my $str = join("\n", @{$elm});
		printf("dbg: kJudge::show_judglog: %s\n", $str);
	}
	return;
}

sub judge_payload($$;$)
{
	my ($rcv, $exp, $operation) = @_;

	my $ret = {};
	my $result = $TRUE;
	my $exp_payload_type = $exp->{'self'};

	my @judgment = ();

	if (defined($rcv)) {
		debug("kJudge::judge_payload: rcv(%s), exp(%s)\n", $rcv->{'self'}, $exp->{'self'});
		my $tmp = &{$judge_func{$exp_payload_type}}($rcv, $exp);
		debug("kJudge::judge_payload: result(%s)\n", $tmp->{'result'});
		$result = $FALSE unless($tmp->{'result'});
		push(@judgment, @{$tmp->{'log'}});

		# collect flags
		$ret = store_flags($tmp, $ret);
	}
	else {
		$result = $FALSE;
		my $log = [];
		my $str = '';
		$str .= "<font color='#ff0000'><b>NG</b></font>\t";
		$str .= $exp_payload_type;
		$str .= '(' . $exp->{'type'} . ')' if ($exp->{'self'} eq 'N');
		$str .= ' is expected.';

		push(@{$log}, $str);
		push(@judgment, $log);
		debug("kJudge::judge_payload rcv(undefined), exp(%s)\n", $exp->{'self'});
	}

	show_judglog(\@judgment);
	kIKE::kPrint::kPrint_JudgeLog2(\@judgment);

	$ret->{'result'} = $result;
	$ret->{'log'} = \@judgment;

	return($ret);
}

sub judge_stub($$)
{
	my ($rcv, $exp) = @_;

	my $result = $TRUE;
	my @log = ();
	debug("kJudge::judge_stub: call\n");

	return($result, @log);
}

sub judge_IKEHeader($$);
my @IKEHeader_Fields = (
	'initSPI',
	'respSPI',
	'nexttype',
	'major',
	'minor',
	'exchType',
	'reserved1',
	'initiator',
	'higher',
	'response',
	'reserved2',
	'messID',
	'length',
);
sub judge_IKEHeader($$)
{
	my ($received, $expected) = @_;

	my $result = $TRUE;
	my @judgment = ();
	my @log = ();

	my $payload_type = 'HDR';
	push(@log, kIKE::kPrint::html_bold($payloadsNames{$payload_type}));

	my @checked = ('length');

	foreach my $field (@IKEHeader_Fields) {
		my $rcv = $received->{$field};
		my $exp = $expected->{$field};
		my $cmp = $expected->{$field . '_comparator'};

		($exp, $cmp) = set_comparator($field, \@checked, $exp, $cmp);

		my ($bool, $str) = compare($field, $rcv, $exp, $cmp);
		$result = $FALSE unless $bool;
		push(@log, $str);
	}

	unshift(@judgment, \@log);

	my $ret = {};
	$ret->{'result'} = $result;
	$ret->{'log'} = \@judgment;

	return($ret);
}

sub judge_GenericPayloadHeader($$);
my @GenericPayloadHeader_fields = (
	'nexttype',
	'critical',
	'reserved',
	'length',
);
sub judge_GenericPayloadHeader($$) {
	my ($received, $expected) = @_;

	my $result = $TRUE;
	my @log = ();

	# skip NextPayload field and Payload Length field,
	# because they has been already checked at decoding phase
	my @checked = ('nexttype', 'length');

	foreach my $field (@GenericPayloadHeader_fields) {
		my $rcv = $received->{$field};
		my $exp = $expected->{$field};
		my $cmp = $expected->{$field . '_comparator'};

		($exp, $cmp) = set_comparator($field, \@checked, $exp, $cmp);

		my ($bool, $str) = compare($field, $rcv, $exp, $cmp);
		$result = $FALSE unless $bool;
		push(@log, $str);
	}

	my $ret = {};
	$ret->{'result'} = $result;
	$ret->{'log'} = \@log;

	return ($ret);
}

sub judge_SecurityAssociationPayload($$);
my @SecurityAssociationPayload_fields = (
);
sub judge_SecurityAssociationPayload($$)
{
	my ($received, $expected) = @_;

	my $result = $TRUE;
	my @judgment = ();
	my @log = ();
	my $ret = {};

	my $payload_type = 'SA';
	push(@log, kIKE::kPrint::html_bold($payloadsNames{$payload_type}));
	{
		my $tmp = judge_GenericPayloadHeader($received, $expected);
		$result = $FALSE unless($tmp->{'result'});
		push(@log, @{$tmp->{'log'}});
	}

	my @checked = ();

	foreach my $field (@SecurityAssociationPayload_fields) {
		my $rcv = $received->{$field};
		my $exp = $expected->{$field};
		my $cmp = $expected->{$field . '_comparator'};

		($exp, $cmp) = set_comparator($field, \@checked, $exp, $cmp);

		my ($bool, $str) = compare($field, $rcv, $exp, $cmp);
		$result = $FALSE unless $bool;
		push(@log, $str);
	}

	{
		my $tmp = judge_SA_Proposals($received, $expected);
		unless ($tmp->{'result'}) {
			$result = $FALSE;
		}
		push(@judgment, @{$tmp->{'log'}});
	}

	# XXX: have to consider the number of Proposals
	{
		my $rcv_num = scalar(@{$received->{'proposals'}});
		my $exp_num = scalar(@{$expected->{'proposals'}});

		for (my $i = 0; $i < $exp_num; $i++) {
			# $tmp_result is a flag for $exp_num ($i)
			my $tmp_result = $FALSE;
			for (my $j = 0; $j < $rcv_num; $j++) {
				my $tmp = judge_ProposalSubstructure($received->{'proposals'}->[$j],
								     $expected->{'proposals'}->[$i]);
				if ($tmp->{'result'}) {
					# match $expected->{'proposals'}->[$i]
					# with $recieved->{'proposals'}->[$j]
					$received->{'proposals'}->[$j]->{'_checked'} = $i;
					$expected->{'proposals'}->[$i]->{'_checked'} = $i;
					$tmp_result = $TRUE;
					push(@judgment, @{$tmp->{'log'}});
					last;
				}
				else {
					# not match $expected->{'proposals'}->[$i]
					# with $received->{'proposals'}->[$j]
					push(@judgment, @{$tmp->{'log'}});
				}
			}

			if ($tmp_result) {
				# match $expected->{'proposals'}->[$i]
				# with $received->{'proposals'}->[$j]
			}
			else {
				# not match $expected->{'proposals'}->[$i]
				# with any $received->{'proposals'}->[XXX]
				$result = $FALSE;
			}
		}
	}

	unshift(@judgment, \@log);

	$ret->{'result'} = $result;
	$ret->{'log'} = \@judgment;

	return($ret);
}

sub judge_SA_Proposals($$);
sub judge_SA_Proposals($$)
{
	my ($received, $expected) = @_;

	my $result = $TRUE;
	my @log = ();
	my $exp_proposals = $expected->{'proposals'};
	my $rcv_proposals = $received->{'proposals'};

	# convert proposals to comparable format
	my $exp_conv_proposals = convert_proposals($exp_proposals);
	my $rcv_conv_proposals = convert_proposals($rcv_proposals);

	# check if integrity algorithm is empty
	# if empty, it indicates INTEG_NONE
	my $omit_integrity_alg = $FALSE;
	{
		my $index_integ = 2;

		foreach my $proposals (@{$exp_conv_proposals}) {
			foreach my $proposal (@{$proposals}) {
				my $transform_integ = $proposal->[$index_integ];
				my $num_alg = @{$transform_integ};
				if ($num_alg == 0) {
					push(@{$transform_integ}, 'INTEG_NONE');
					last;
				}
			}
		}
		foreach my $proposals (@{$rcv_conv_proposals}) {
			foreach my $proposal (@{$proposals}) {
				my $transform_integ = $proposal->[$index_integ];
				my $num_alg = @{$transform_integ};
				if ($num_alg == 0) {
					push(@{$transform_integ}, 'INTEG_NONE');
					$omit_integrity_alg = $TRUE;
					last;
				}
			}
		}
	}

	# compare SA Proposals
	{
		my $tmp = compare_proposals($rcv_conv_proposals, $exp_conv_proposals);
		unless ($tmp->{'result'}) {
			$result = $FALSE;
		}
		push(@log, @{$tmp->{'log'}});
	}

	my $ret = {};
	$ret->{'result'} = $result;
	$ret->{'log'} = \@log;
	$ret->{'omit_integrity_alg'} = $omit_integrity_alg;

	return($ret);
}

sub judge_ProposalSubstructure($$);
my @ProposalSubstructure_fields = (
	'nexttype',
	'reserved',
	'proposalLen',
	'number',
	'id',
	'spiSize',
	'transformCount',
	'spi',
);
sub judge_ProposalSubstructure($$)
{
	my ($received, $expected) = @_;

	my $result = $TRUE;
	my @judgment = ();
	my @log = ();

	my $payload_type = 'P';
	push(@log, kIKE::kPrint::html_bold($payloadsNames{$payload_type}));

	my @checked = ('nexttype', 'proposalLen');

	foreach my $field (@ProposalSubstructure_fields) {
		my $rcv = $received->{$field};
		my $exp = $expected->{$field};
		my $cmp = $expected->{$field . '_comparator'};

		($exp, $cmp) = set_comparator($field, \@checked, $exp, $cmp);

		my ($bool, $str) = compare($field, $rcv, $exp, $cmp);
		$result = $FALSE unless $bool;
		push(@log, $str);
	}

	# XXX: have to consider the number of received Transforms
	{
		my $rcv_num = scalar(@{$received->{'transforms'}});
		my $exp_num = scalar(@{$expected->{'transforms'}});

		for (my $i = 0; $i < $exp_num; $i++) {
			debug("kJudge::judge_ProposalSubstructure: i(%s)\n", $i);
			# $tmp_result is a flag for $exp_num ($i)
			my $tmp_result = $FALSE;
			for (my $j = 0; $j < $rcv_num; $j++) {
				debug("kJudge::judge_ProposalSubstructure: j(%s) has _checked(%s)\n",
				       $j,
				       defined($received->{'transforms'}->[$j]->{'_checked'}) ? 'defined' : 'undefined');
				if (defined($received->{'transforms'}->[$j]->{'_checked'})) {
					debug("kJudge::judge_ProposalSubstructure: j(%s) has already checked\n", $j);
					next;
				}
				debug("kJudge::judge_ProposalSubstructure: checking j(%s)\n", $j);

				my $tmp = judge_TransformSubstructure($received->{'transforms'}->[$j],
								      $expected->{'transforms'}->[$i]);
				if ($tmp->{'result'}) {
					# match $expected->{'transforms'}->[$i]
					# with $received->{'transforms'}->[$j]
					debug("kJudge::judge_ProposalSubstructure: marking _checked to j(%s)\n", $j);
					$received->{'transforms'}->[$j]->{'_checked'} = $i;
					$expected->{'transforms'}->[$i]->{'_checked'} = $i;
					$tmp_result = $TRUE;
					push(@judgment, @{$tmp->{'log'}});
					last;
				}
				else {
					# not match $expected->{'transforms'}->[$i]
					# with $received->{'transforms'}->[$j]
				}
			}

			if ($tmp_result) {
				# match $expected->{'transforms'}->[$i]
				# with $received->{'transforms'}->[$j]
				printf("kJudge::judge_ProposalSubstructure: tmp_result(1)\n\n");
			}
			else {
				# not match $expected->{'transforms'}->[$i]
				# with any $received->{'transforms'}->[XXX]
				printf("kJudge::judge_ProposalSubstructure: tmp_result(0)\n\n");
				$result = $FALSE;
			}
		}
	}

	{ # cleanup added flags of expected packets
		foreach my $t (@{$expected->{'transforms'}}) {
			undef($t->{'_checked'});
		}
		foreach my $t (@{$received->{'transforms'}}) {
			undef($t->{'_checked'});
		}
	}

	unshift(@judgment, \@log);

	my $ret = {};
	$ret->{'result'} = $result;
	$ret->{'log'} = \@judgment;

	return($ret);
}

sub judge_TransformSubstructure($$);
my @TransformSubstructure_fields = (
	'nexttype',
	'reserved1',
	'transformLen',
	'type',
	'reserved2',
	'id',
);
sub judge_TransformSubstructure($$)
{
	my ($received, $expected) = @_;

	my $result = $TRUE;
	my @judgment = ();
	my @log = ();

	my $payload_type = 'T';
	push(@log, kIKE::kPrint::html_bold($payloadsNames{$payload_type}));

	my @checked = ('nexttype', 'transformLen');

	foreach my $field (@TransformSubstructure_fields) {
		my $rcv = $received->{$field};
		my $exp = $expected->{$field};
		my $cmp = $expected->{$field . '_comparator'};

		($exp, $cmp) = set_comparator($field, \@checked, $exp, $cmp);

		my ($bool, $str) = compare($field, $rcv, $exp, $cmp);
		$result = $FALSE unless $bool;
		push(@log, $str);
	}

	# XXX: have to consider the number of received Attributes
	{
		my $rcv_num = scalar(@{$received->{'attributes'}});
		my $exp_num = scalar(@{$expected->{'attributes'}});
		if ($exp_num > 0 && $rcv_num == 0) {
			my $str = "<font color='#ff0000'><b>NG</b></font>\tSA Attribute is required";
			push(@log, $str);
			unshift(@judgment, \@log);

			my $ret = {};
			$ret->{'result'} = $FALSE;
			$ret->{'log'} = \@judgment;
			return($ret);
		}

		for (my $i = 0; $i < $exp_num; $i++) {
			my $tmp = judge_TransformAttribute($received->{'attributes'}->[0], $expected->{'attributes'}->[$i]);
			$result = $FALSE unless($tmp->{'result'});
			push(@judgment, @{$tmp->{'log'}});
		}
	}

	unshift(@judgment, \@log);

	my $ret = {};
	$ret->{'result'} = $result;
	$ret->{'log'} = \@judgment;

	return($ret);
}

sub judge_TransformAttribute($$);
my @TransformAttribute_fields = (
	'af',
	'type',
	'length',
	'value',
);
sub judge_TransformAttribute($$)
{
	my ($received, $expected) = @_;

	my $result = $TRUE;
	my @judgment = ();
	my @log = ();

	my $payload_type = 'Attr';
	push(@log, kIKE::kPrint::html_bold($payloadsNames{$payload_type}));

	my @checked = ('length');

	foreach my $field (@TransformAttribute_fields) {
		my $rcv = $received->{$field};
		my $exp = $expected->{$field};
		my $cmp = $expected->{$field . '_comparator'};

		($exp, $cmp) = set_comparator($field, \@checked, $exp, $cmp);

		if ($field eq 'length' && $received->{'af'} eq '1') {
			next;
		}

		my ($bool, $str) = compare($field, $rcv, $exp, $cmp);
		$result = $FALSE unless $bool;
		push(@log, $str);
	}

	unshift(@judgment, \@log);

	my $ret = {};
	$ret->{'result'} = $result;
	$ret->{'log'} = \@judgment;

	return($ret);
}

sub judge_KeyExchangePayload($$);
my @KeyExchangePayload_fields = (
	'group',
	'reserved1',
	'publicKey',
);
sub judge_KeyExchangePayload($$)
{
	my ($received, $expected) = @_;

	my $result = $TRUE;
	my @judgment = ();
	my @log = ();

	my $payload_type = 'KE';
	push(@log, kIKE::kPrint::html_bold($payloadsNames{$payload_type}));
	{
		my $tmp = judge_GenericPayloadHeader($received, $expected);
		$result = $FALSE unless($tmp->{'result'});
		push(@log, @{$tmp->{'log'}});
	}

	my @checked = ();

	foreach my $field (@KeyExchangePayload_fields) {
		my $rcv = $received->{$field};
		my $exp = $expected->{$field};
		my $cmp = $expected->{$field . '_comparator'};

		($exp, $cmp) = set_comparator($field, \@checked, $exp, $cmp);

		my ($bool, $str) = compare($field, $rcv, $exp, $cmp);
		$result = $FALSE unless $bool;
		push(@log, $str);
	}

	unshift(@judgment, \@log);

	my $ret = {};
	$ret->{'result'} = $result;
	$ret->{'log'} = \@judgment;

	return($ret);
}

sub judge_NoncePayload($$);
my @NoncePayload_fields = (
	'nonce',
);
sub judge_NoncePayload($$)
{
	my ($received, $expected) = @_;

	my $result = $TRUE;
	my @judgment = ();
	my @log = ();

	my $payload_type = 'Ni, Nr';
	push(@log, kIKE::kPrint::html_bold($payloadsNames{$payload_type}));
	{
		my $tmp = judge_GenericPayloadHeader($received, $expected);
		$result = $FALSE unless($tmp->{'result'});
		push(@log, @{$tmp->{'log'}});
	}

	my @checked = ();

	foreach my $field (@NoncePayload_fields) {
		my $rcv = $received->{$field};
		my $exp = $expected->{$field};
		my $cmp = $expected->{$field . '_comparator'};

		($exp, $cmp) = set_comparator($field, \@checked, $exp, $cmp);

		my ($bool, $str) = compare($field, $rcv, $exp, $cmp);
		$result = $FALSE unless $bool;
		push(@log, $str);
	}

	unshift(@judgment, \@log);

	my $ret = {};
	$ret->{'result'} = $result;
	$ret->{'log'} = \@judgment;

	return($ret);
}

sub judge_IdentificationInitiatorPayload($$);
my @IdentificationInitiatorPayload_fields = (
	'type',
	'reserved1',
	'value',
);
sub judge_IdentificationInitiatorPayload($$)
{
	my ($received, $expected) = @_;

	my $result = $TRUE;
	my @judgment = ();
	my @log = ();

	my $payload_type = 'IDi';
	push(@log, kIKE::kPrint::html_bold($payloadsNames{$payload_type}));
	{
		my $tmp = judge_GenericPayloadHeader($received, $expected);
		$result = $FALSE unless($tmp->{'result'});
		push(@log, @{$tmp->{'log'}});
	}

	my @checked = ();

	foreach my $field (@IdentificationInitiatorPayload_fields) {
		my $rcv = $received->{$field};
		my $exp = $expected->{$field};
		my $cmp = $expected->{$field . '_comparator'};

		($exp, $cmp) = set_comparator($field, \@checked, $exp, $cmp);

		my ($bool, $str) = compare($field, $rcv, $exp, $cmp);
		$result = $FALSE unless $bool;
		push(@log, $str);
	}

	unshift(@judgment, \@log);

	my $ret = {};
	$ret->{'result'} = $result;
	$ret->{'log'} = \@judgment;

	return($ret);
}

sub judge_IdentificationResponderPayload($$);
my @IdentificationResponderPayload_fields = (
	'type',
	'reserved1',
	'value',
);
sub judge_IdentificationResponderPayload($$)
{
	my ($received, $expected) = @_;

	my $result = $TRUE;
	my @judgment = ();
	my @log = ();

	my $payload_type = 'IDr';
	push(@log, kIKE::kPrint::html_bold($payloadsNames{$payload_type}));
	{
		my $tmp = judge_GenericPayloadHeader($received, $expected);
		$result = $FALSE unless($tmp->{'result'});
		push(@log, @{$tmp->{'log'}});
	}

	my @checked = ();

	foreach my $field (@IdentificationResponderPayload_fields) {
		my $rcv = $received->{$field};
		my $exp = $expected->{$field};
		my $cmp = $expected->{$field . '_comparator'};

		($exp, $cmp) = set_comparator($field, \@checked, $exp, $cmp);

		my ($bool, $str) = compare($field, $rcv, $exp, $cmp);
		$result = $FALSE unless $bool;
		push(@log, $str);
	}

	unshift(@judgment, \@log);

	my $ret = {};
	$ret->{'result'} = $result;
	$ret->{'log'} = \@judgment;

	return($ret);
}

sub judge_AuthenticationPayload($$);
my @AuthenticationPayload_fields = (
	'method',
	'reserved1',
	'data',
);
sub judge_AuthenticationPayload($$)
{
	my ($received, $expected) = @_;

	my $result = $TRUE;
	my @judgment = ();
	my @log = ();

	my $payload_type = 'AUTH';
	push(@log, kIKE::kPrint::html_bold($payloadsNames{$payload_type}));
	{
		my $tmp = judge_GenericPayloadHeader($received, $expected);
		$result = $FALSE unless($tmp->{'result'});
		push(@log, @{$tmp->{'log'}});
	}

	my @checked = ('data');

	foreach my $field (@AuthenticationPayload_fields) {
		my $rcv = $received->{$field};
		my $exp = $expected->{$field};
		my $cmp = $expected->{$field . '_comparator'};

		($exp, $cmp) = set_comparator($field, \@checked, $exp, $cmp);

		my ($bool, $str) = compare($field, $rcv, $exp, $cmp);
		$result = $FALSE unless $bool;
		push(@log, $str);
	}

	unshift(@judgment, \@log);

	my $ret = {};
	$ret->{'result'} = $result;
	$ret->{'log'} = \@judgment;

	return($ret);
}

sub judge_CertificationPayload($$);
my @CertificationPayload_fields = (
	'cert_encoding',
	'cert_data',
);
sub judge_CertificationPayload($$)
{
	my ($received, $expected) = @_;

	my $result = $TRUE;
	my @judgment = ();
	my @log = ();

	my $payload_type = 'CERT';
	push(@log, kIKE::kPrint::html_bold($payloadsNames{$payload_type}));
	{
		my $tmp = judge_GenericPayloadHeader($received, $expected);
		$result = $FALSE unless($tmp->{'result'});
		push(@log, @{$tmp->{'log'}});
	}

	my @checked = ();

	foreach my $field (@CertificationPayload_fields) {
		my $rcv = $received->{$field};
		my $exp = $expected->{$field};
		my $cmp = $expected->{$field . '_comparator'};

		($exp, $cmp) = set_comparator($field, \@checked, $exp, $cmp);

		my ($bool, $str) = compare($field, $rcv, $exp, $cmp);
		$result = $FALSE unless $bool;
		push(@log, $str);
	}

	unshift(@judgment, \@log);

	my $ret = {};
	$ret->{'result'} = $result;
	$ret->{'log'} = \@judgment;

	return($ret);
}

sub judge_CertificationRequestPayload($$);
my @CertificationRequestPayload_fields = (
	'cert_encoding',
	'cert_auth',
);
sub judge_CertificationRequestPayload($$)
{
	my ($received, $expected) = @_;

	my $result = $TRUE;
	my @judgment = ();
	my @log = ();

	my $payload_type = 'CERTREQ';
	push(@log, kIKE::kPrint::html_bold($payloadsNames{$payload_type}));
	{
		my $tmp = judge_GenericPayloadHeader($received, $expected);
		$result = $FALSE unless($tmp->{'result'});
		push(@log, @{$tmp->{'log'}});
	}

	my @checked = ();

	foreach my $field (@CertificationRequestPayload_fields) {
		my $rcv = $received->{$field};
		my $exp = $expected->{$field};
		my $cmp = $expected->{$field . '_comparator'};

		($exp, $cmp) = set_comparator($field, \@checked, $exp, $cmp);

		my ($bool, $str) = compare($field, $rcv, $exp, $cmp);
		$result = $FALSE unless $bool;
		push(@log, $str);
	}

	unshift(@judgment, \@log);

	my $ret = {};
	$ret->{'result'} = $result;
	$ret->{'log'} = \@judgment;

	return($ret);
}

sub judge_NotifyPayload($$);
my @NotifyPayload_fields = (
	'id',
	'spiSize',
	'type',
	'spi',
	'data',
);
sub judge_NotifyPayload($$)
{
	my ($received, $expected) = @_;

	my $result = $TRUE;
	my @judgment = ();
	my @log = ();

	my $payload_type = 'N';
	push(@log, kIKE::kPrint::html_bold($payloadsNames{$payload_type}));
	{
		my $tmp = judge_GenericPayloadHeader($received, $expected);
		$result = $FALSE unless($tmp->{'result'});
		push(@log, @{$tmp->{'log'}});
	}

	my @checked = ();

	foreach my $field (@NotifyPayload_fields) {
		my $rcv = $received->{$field};
		my $exp = $expected->{$field};
		my $cmp = $expected->{$field . '_comparator'};

		($exp, $cmp) = set_comparator($field, \@checked, $exp, $cmp);

		my ($bool, $str) = compare($field, $rcv, $exp, $cmp);
		$result = $FALSE unless $bool;
		push(@log, $str);
	}

	unshift(@judgment, \@log);

	my $ret = {};
	$ret->{'result'} = $result;
	$ret->{'log'} = \@judgment;

	# set Notify flag
	if ($received->{'type'} eq 'USE_TRANSPORT_MODE') {
		$ret->{'use_transport_mode'} = $TRUE;
	}

	return($ret);
}

sub judge_DeletePayload($$);
my @DeletePayload_fields = (
	'id',
	'spiSize',
	'spiCount',
	'spis',
);
sub judge_DeletePayload($$)
{
	my ($received, $expected) = @_;

	my $result = $TRUE;
	my @judgment = ();
	my @log = ();

	my $payload_type = 'D';
	push(@log, kIKE::kPrint::html_bold($payloadsNames{$payload_type}));
	{
		my $tmp = judge_GenericPayloadHeader($received, $expected);
		$result = $FALSE unless($tmp->{'result'});
		push(@log, @{$tmp->{'log'}});
	}

	my @checked = ();

	foreach my $field (@DeletePayload_fields) {
		my $rcv = $received->{$field};
		my $exp = $expected->{$field};
		my $cmp = $expected->{$field . '_comparator'};

		($exp, $cmp) = set_comparator($field, \@checked, $exp, $cmp);

		my ($bool, $str) = compare($field, $rcv, $exp, $cmp);
		$result = $FALSE unless $bool;
		push(@log, $str);
	}

	unshift(@judgment, \@log);

	my $ret = {};
	$ret->{'result'} = $result;
	$ret->{'log'} = \@judgment;

	return($ret);
}

sub judge_VendorIDPayload($$);
my @VendorIDPayload_fields = (
	'vendorID',
);
sub judge_VendorIDPayload($$)
{
	my ($received, $expected) = @_;

	my $result = $TRUE;
	my @judgment = ();
	my @log = ();

	my $payload_type = 'V';
	push(@log, kIKE::kPrint::html_bold($payloadsNames{$payload_type}));
	{
		my $tmp = judge_GenericPayloadHeader($received, $expected);
		$result = $FALSE unless($tmp->{'result'});
		push(@log, @{$tmp->{'log'}});
	}

	my @checked = ();

	foreach my $field (@VendorIDPayload_fields) {
		my $rcv = $received->{$field};
		my $exp = $expected->{$field};
		my $cmp = $expected->{$field . '_comparator'};

		($exp, $cmp) = set_comparator($field, \@checked, $exp, $cmp);

		my ($bool, $str) = compare($field, $rcv, $exp, $cmp);
		$result = $FALSE unless $bool;
		push(@log, $str);
	}

	unshift(@judgment, \@log);

	my $ret = {};
	$ret->{'result'} = $result;
	$ret->{'log'} = \@judgment;

	return($ret);
}

sub judge_TrafficSelector($$);
my @TrafficSelector_fields = (
	'type',
	'protocol',
	'selectorLen',
	'sport',
	'eport',
	'saddr',
	'eaddr',
);
sub judge_TrafficSelector($$)
{
	my ($received, $expected) = @_;

	debug("kJudge::judge_TrafficSelectorPayload:: call\n");

	my $result = $TRUE;
	my @judgment = ();
	my @log = ();

	my $payload_type = 'TS';
	push(@log, kIKE::kPrint::html_bold($payloadsNames{$payload_type}));

	my @checked = ('selectorLen');

	foreach my $field (@TrafficSelector_fields) {
		my $rcv = $received->{$field};
		my $exp = $expected->{$field};
		my $cmp = $expected->{$field . '_comparator'};

		($exp, $cmp) = set_comparator($field, \@checked, $exp, $cmp);

		my ($bool, $str) = compare($field, $rcv, $exp, $cmp);
		$result = $FALSE unless $bool;
		push(@log, $str);
	}

	unshift(@judgment, \@log);

	my $ret = {};
	$ret->{'result'} = $result;
	$ret->{'log'} = \@judgment;

	return($ret);
}

sub judge_TrafficSelectors($$);
sub judge_TrafficSelectors($$)
{
	my ($received, $expected) = @_;

	my @log = ();

	my $rcv_num = scalar(@{$received->{'selectors'}});
	my $exp_num = scalar(@{$expected->{'selectors'}});

	my $pass_num = 0;
	for (my $i = 0; $i < $exp_num; $i++) {
		for (my $j = 0; $j < $rcv_num; $j++) {
			if (defined($received->{'selectors'}->[$j]->{'_checked'})) {
				next;
			}

			printf("kJudge::judge_TrafficSelectors: rcv(%s) exp(%s)\n", $i, $j);
			my $tmp = judge_TrafficSelector($received->{'selectors'}->[$j],
							$expected->{'selectors'}->[$i]);
			push(@log, @{$tmp->{'log'}});
			if ($tmp->{'result'}) {
				$pass_num++;
				$received->{'selectors'}->[$j]->{'_checked'} = $i;
				next;
			}
		}
	}

	{
		foreach my $elm (@{$received->{'selectors'}}) {
			undef($elm->{'_checked'});
		}
	}

	printf("kJudge::judge_TrafficSelectors: pass_num(%s) exp_num(%s)\n", $pass_num, $exp_num);
	my $result = $FALSE;
	if ($pass_num > 0 && $pass_num eq $exp_num) {
		$result= $TRUE;
	}

	my $ret = {};
	$ret->{'result'} = $result;
	$ret->{'log'} = \@log;
	return($ret);
}

sub judge_TrafficSelectorInitiatorPayload($$);
my @TrafficSelectorInitiatorPayload_fields = (
	'count',
	'reserved1',
);
sub judge_TrafficSelectorInitiatorPayload($$)
{
	my ($received, $expected) = @_;

	my $result = $TRUE;
	my @judgment = ();
	my @log = ();

	my $payload_type = 'TSi';
	push(@log, kIKE::kPrint::html_bold($payloadsNames{$payload_type}));
	{
		my $tmp = judge_GenericPayloadHeader($received, $expected);
		$result = $FALSE unless($tmp->{'result'});
		push(@log, @{$tmp->{'log'}});
	}

	my @checked = ('count');

	foreach my $field (@TrafficSelectorInitiatorPayload_fields) {
		my $rcv = $received->{$field};
		my $exp = $expected->{$field};
		my $cmp = $expected->{$field . '_comparator'};

		($exp, $cmp) = set_comparator($field, \@checked, $exp, $cmp);

		my ($bool, $str) = compare($field, $rcv, $exp, $cmp);
		$result = $FALSE unless $bool;
		push(@log, $str);
	}

	# XXX: have to consider comparator selectors_comparator
	if (1) {
		my $tmp = judge_TrafficSelectors($received, $expected);
		unless ($tmp->{'result'}) {
			$result = $FALSE;
		}
		push(@judgment, @{$tmp->{'log'}});
	}
	if (0) {
		my $rcv_num = scalar(@{$received->{'selectors'}});
		my $exp_num = scalar(@{$expected->{'selectors'}});

		my $tmp_result = $TRUE;
		for (my $i = 0; $i < $exp_num; $i++) {
			for (my $j = 0; $j < $rcv_num; $j++) {
				my $tmp = judge_TrafficSelector($received->{'selectors'}->[$j], $expected->{'selectors'}->[$i]);
				$tmp_result = $FALSE unless($tmp->{'result'});
				push(@judgment, @{$tmp->{'log'}});
			}
		}
	}

	unshift(@judgment, \@log);

	my $ret = {};
	$ret->{'result'} = $result;
	$ret->{'log'} = \@judgment;

	return($ret);
}

sub judge_TrafficSelectorResponderPayload($$);
my @TrafficSelectorResponderPayload_fields = (
	'count',
	'reserved1',
);
sub judge_TrafficSelectorResponderPayload($$)
{
	my ($received, $expected) = @_;

	my $result = $TRUE;
	my @judgment = ();
	my @log = ();

	my $payload_type = 'TSr';
	push(@log, kIKE::kPrint::html_bold($payloadsNames{$payload_type}));
	{
		my $tmp = judge_GenericPayloadHeader($received, $expected);
		$result = $FALSE unless($tmp->{'result'});
		push(@log, @{$tmp->{'log'}});
	}

	my @checked = ('count');

	foreach my $field (@TrafficSelectorResponderPayload_fields) {
		my $rcv = $received->{$field};
		my $exp = $expected->{$field};
		my $cmp = $expected->{$field . '_comparator'};

		($exp, $cmp) = set_comparator($field, \@checked, $exp, $cmp);

		my ($bool, $str) = compare($field, $rcv, $exp, $cmp);
		$result = $FALSE unless $bool;
		push(@log, $str);
	}

	# XXX: have to consider comparator selectors_comparator
	if (1) {
		my $tmp = judge_TrafficSelectors($received, $expected);
		unless ($tmp->{'result'}) {
			$result = $FALSE;
		}
		push(@judgment, @{$tmp->{'log'}});
	}
	if (0) {
		my $rcv_num = scalar(@{$received->{'selectors'}});
		my $exp_num = scalar(@{$expected->{'selectors'}});

		for (my $i = 0; $i < $exp_num; $i++) {
			for (my $j = 0; $j < $rcv_num; $j++) {
				my $tmp = judge_TrafficSelector($received->{'selectors'}->[$j], $expected->{'selectors'}->[$i]);
				$result = $FALSE unless($tmp->{'result'});
				push(@judgment, @{$tmp->{'log'}});
			}
		}
	}

	unshift(@judgment, \@log);

	my $ret = {};
	$ret->{'result'} = $result;
	$ret->{'log'} = \@judgment;

	return($ret);
}

sub judge_EncryptedPayload($$);
my @EncryptedPayload_fields = (
	'innerType',
	'critical',
	'reserved',
	'length',
	'iv',
	'checksum',
);
sub judge_EncryptedPayload($$)
{
	my ($received, $expected) = @_;

	my $result = $TRUE;
	my @judgment = ();
	my @log = ();

	my $payload_type = 'E';
	push(@log, kIKE::kPrint::html_bold($payloadsNames{$payload_type}));

	my @checked = ('innerType', 'length', 'iv', 'checksum');

	foreach my $field (@EncryptedPayload_fields) {
		my $rcv = $received->{$field};
		my $exp = $expected->{$field};
		my $cmp = $expected->{$field . '_comparator'};

		($exp, $cmp) = set_comparator($field, \@checked, $exp, $cmp);

		my ($bool, $str) = compare($field, $rcv, $exp, $cmp);
		$result = $FALSE unless $bool;
		push(@log, $str);
	}

	unshift(@judgment, \@log);

	my $ret = {};
	$ret->{'result'} = $result;
	$ret->{'log'} = \@judgment;

	return($ret);
}

sub judge_ConfigurationPayload($$);
my @ConfigurationPayload_fields = (
	'cfg_type',
	'reserved1',
);
sub judge_ConfigurationPayload($$)
{
	my ($received, $expected) = @_;

	my $result = $TRUE;
	my @judgment = ();
	my @log = ();

	my $payload_type = 'CP';
	push(@log, kIKE::kPrint::html_bold($payloadsNames{$payload_type}));
	{
		my $tmp = judge_GenericPayloadHeader($received, $expected);
		$result = $FALSE unless($tmp->{'result'});
		push(@log, @{$tmp->{'log'}});
	}

	my @checked = ('count');

	foreach my $field (@ConfigurationPayload_fields) {
		my $rcv = $received->{$field};
		my $exp = $expected->{$field};
		my $cmp = $expected->{$field . '_comparator'};

		($exp, $cmp) = set_comparator($field, \@checked, $exp, $cmp);

		my ($bool, $str) = compare($field, $rcv, $exp, $cmp);
		$result = $FALSE unless $bool;
		push(@log, $str);
	}

	# XXX: have to consider comparator selectors_comparator
	if (1) {
		my $tmp = judge_ConfigurationAttributes($received, $expected);
		unless ($tmp->{'result'}) {
			$result = $FALSE;
		}
		push(@judgment, @{$tmp->{'log'}});
	}

	unshift(@judgment, \@log);

	my $ret = {};
	$ret->{'result'} = $result;
	$ret->{'log'} = \@judgment;

	return($ret);
}

sub judge_ConfigurationAttribute($$);
my @ConfigurationAttribute_fields = (
	'reserved',
	'attr_type',
	'length',
	'value',
);
sub judge_ConfigurationAttribute($$)
{
	my ($received, $expected) = @_;

	debug("kJudge::judge_ConfigurationAttribute:: call\n");

	my $result = $TRUE;
	my @judgment = ();
	my @log = ();

	my $payload_type = 'CP';
	push(@log, kIKE::kPrint::html_bold($payloadsNames{$payload_type}));

	my @checked = ('length');

	foreach my $field (@ConfigurationAttribute_fields) {
		my $rcv = $received->{$field};
		my $exp = $expected->{$field};
		my $cmp = $expected->{$field . '_comparator'};

		($exp, $cmp) = set_comparator($field, \@checked, $exp, $cmp);

		my ($bool, $str) = compare($field, $rcv, $exp, $cmp);
		$result = $FALSE unless $bool;
		push(@log, $str);
	}

	unshift(@judgment, \@log);

	my $ret = {};
	$ret->{'result'} = $result;
	$ret->{'log'} = \@judgment;

	return($ret);
}

sub judge_ConfigurationAttributes($$);
sub judge_ConfigurationAttributes($$)
{
	my ($received, $expected) = @_;

	my @log = ();

	my $rcv_num = scalar(@{$received->{'attributes'}});
	my $exp_num = scalar(@{$expected->{'attributes'}});

	my $pass_num = 0;
	for (my $i = 0; $i < $exp_num; $i++) {
		for (my $j = 0; $j < $rcv_num; $j++) {
			if (defined($received->{'attributes'}->[$j]->{'_checked'})) {
				next;
			}

			printf("kJudge::judge_ConfigurationAttributes: rcv(%s) exp(%s)\n", $i, $j);
			my $tmp = judge_ConfigurationAttribute($received->{'attributes'}->[$j],
							       $expected->{'attributes'}->[$i]);
			push(@log, @{$tmp->{'log'}});
			if ($tmp->{'result'}) {
				$pass_num++;
				$received->{'attributes'}->[$j]->{'_checked'} = $i;
				next;
			}
		}
	}

	{
		foreach my $elm (@{$received->{'attributes'}}) {
			undef($elm->{'_checked'});
		}
	}

	printf("kJudge::judge_ConfigurationAttributes: pass_num(%s) exp_num(%s)\n", $pass_num, $exp_num);
	my $result = $FALSE;
	if ($pass_num > 0 && $pass_num eq $exp_num) {
		$result= $TRUE;
	}

	my $ret = {};
	$ret->{'result'} = $result;
	$ret->{'log'} = \@log;
	return($ret);
}

#
sub kJudgeIKEMessage($$;$)
{
	my ($received, $expected, $operation) = @_;

	my $ret = {};
	my $result = $TRUE;
	my $exchange_type = undef;
	my $is_request = undef;

	# collect basic data
	{
		foreach my $payload0 (@{$received}) {
			if ($payload0->{'self'} eq 'HDR') {
				$exchange_type = $payload0->{'exchType'};
				if ($payload0->{'response'}) {
					$is_request = 0;
				}
				else {
					$is_request = 1;
				}
				last;
			}
		}

		$ret->{'is_request'} = $is_request;
		$ret->{'exchange_type'} = $exchange_type;
	}

	# show payload order
	{
		my $tmp = get_payload_types($received);

		my $str = "<TR VALIGN=\"top\">\n";
		$str .= '<TD></TD><TD><B>';
		$str .= 'Payload Order ';
		$str .= $tmp;
		$str .= '</B></TD>';
		$str .= '</TR>';
		kCommon::prLogHTML($str);
	}

	# traverse expected payload
	{
		my $tmp = $TRUE;
		my $rcv_payload = undef;
		my $exp_payload = undef;
		foreach $exp_payload (@{$expected}) {
			$rcv_payload = find_payload($received, $exp_payload);
			$tmp = judge_payload($rcv_payload, $exp_payload);
			if (!$tmp->{'result'}) {
				$result = $FALSE;
			}

			# collect flags
			$ret = store_flags($tmp, $ret);

			if ($exp_payload->{'self'} eq 'E') {
				my $e = $exp_payload;
				foreach $exp_payload (@{$e->{'innerPayloads'}}) {
					$rcv_payload = find_payload($received, $exp_payload);
					$tmp = judge_payload($rcv_payload, $exp_payload);
					if (!$tmp->{'result'}) {
						$result = $FALSE;
					}

					# collect flags
					$ret = store_flags($tmp, $ret);
				}
			}
		}
	}

	$ret->{'result'} = $result;

	return($ret);
}

sub store_flags($$)
{
	my ($src, $dst) = @_;

	my $ret = {};
	foreach my $key (keys(%{$dst})) {
		$ret->{$key} = $dst->{$key};
	}

	foreach my $key (keys(%{$src})) {
		if ($key eq 'log' || $key eq 'result') {
			next;
		}

		# store
		#   'is_request',
		#   'exchange_type',
		#   'omit_integrity_alg',
		#   'use_transport_mode',
		$ret->{$key} = $src->{$key};
	}

	return($ret);
}

sub kJudgeIKEMessage2($$;$)
{
	my ($message, $expected, $operation) = @_;

	my $result = $TRUE;
	my @judgment = ();
	my $nexttype_rcv = 'HDR';
	my $nexttype_exp = 'HDR';

	foreach my $rcv (@{$message}) {
		my $exp = shift(@{$expected});
		my $match = undef;
		my @output = undef;

		if (!defined($exp) ||
		    !defined($exp->{'self'}) ||
		    $nexttype_rcv ne $exp->{'self'}) {
			my $str = '';
			$str .= "<font color='#ff0000'><b>NG</b></font>\t";
			$str .= $nexttype_rcv;
			$str .= ' is unexpected. ';
			$str .= $nexttype_exp;
			$str .= ' is expected.';

			@output = ($str);
			push(@judgment, \@output);
		}
		elsif (defined($judgmentFunctions{$nexttype_rcv})) {
			($match, @output) = &{$judgmentFunctions{$nexttype_rcv}}($rcv, $exp, $operation);
			push(@judgment, @output);
		}
		else {
			($match, @output) = judge_GenericPayloadHeader($rcv, $exp);
			push(@judgment, \@output);
		}

		$result = $FALSE unless ($match);
		$nexttype_rcv = $rcv->{'nexttype'};
		$nexttype_exp = $exp->{'nexttype'};
	}

	my $str = "<TR VALIGN=\"top\">\n";
	$str .= '<TD>' . kCommon::getTimeStamp() . "</TD>\n";
	$str .= '<TD>Checking Fields ...</TD>';
	$str .= '</TR>';
	kCommon::prLogHTML($str);

	kIKE::kPrint::kPrint_JudgeLog2(\@judgment);

	return($result, @judgment);
}

sub kJudgeIKEHeader($$$) {
	# Read the parameters.
	my ($header, $expected, $operation) = @_;
	# Initialize the values.
	my $result = $TRUE;
	my @judgment = ();
	my @output = ();

	unshift(@output, kIKE::kPrint::html_bold($payloadsNames{'HDR'}));

	foreach my $key qw(initSPI respSPI nexttype major minor exchType reserved1 initiator higher response reserved2 messID length) {
		my $exp = $expected->{$key};
		my $comp = (defined($expected->{$key . '_comparator'})) ? $expected->{$key . '_comparator'} : 'nop';
		my ($bool, $texte) = kJudgeCompare($key, $header->{$key}, $exp, $comp);
		# Set the result.
		$result = $FALSE unless $bool;
		# Save the message.
		push @output, $texte;
	}
	push(@judgment, \@output);
	# Return the result and messages.
	return ($result, @judgment);
}

sub kJudgeGenericPayloadHeader($$) {
	# Read the parameters.
	my ($header, $expected) = @_;
	# Initialize the values.
	my $result = $TRUE;
	my @judgment = ();
	my @output = ();

	# Process comparison of values.
	foreach my $key qw(nexttype critical reserved length) {
		# Get the expected value
		my $exp = $expected->{$key};
		my $comp = (defined($expected->{$key . '_comparator'})) ? $expected->{$key . '_comparator'} : 'nop';
		# Compare a value to its expected.
		my ($bool, $texte) = kJudgeCompare($key, $header->{$key}, $exp, $comp);
		# Set the result.
		$result = $FALSE unless $bool;
		# Save the message.
		push(@output, $texte);
	}
	push(@judgment, @output);
	# Return the result and messages.
	return ($result, @judgment);
}

sub kJudgeSecurityAssociationPayload($$$) {
	# Read the parameters.
	my ($payload, $expected, $operation) = @_;

	my @judgment = ();
	my @output = undef;
	my $result = undef;

	# Process the payload common header.
	($result, @output) = judge_GenericPayloadHeader($payload, $expected);
	unshift(@output, kIKE::kPrint::html_bold($payloadsNames{'SA'}));
	push(@judgment, \@output);

	my $op_hash = $operation->{SA} if (defined($operation));
	my $op_operation = (defined($operation)) ? $op_hash->{operation} : 'standard';
	my $tmp_result = undef;
	my @tmp_output = undef;

	if ($op_operation eq 'standard') {
		($tmp_result, @tmp_output) = kJudgeSAStandard($payload, $expected, $operation);
	}
	elsif ($op_operation eq 'comb') {
		($tmp_result, @tmp_output) = kJudgeSAComb($payload, $expected, $operation);
	}

	$result = $FALSE unless ($tmp_result == $comparison_result->{TRUE});
	push(@judgment, @tmp_output);

	# Return the result and messages.
	return ($result, @judgment);
}

# subroutine prototypes
sub compare($$$;$);
sub compare_sa_payload($$);
sub compare_proposals($$);
sub compare_proposal($$);
sub compare_transforms($$);
sub evaluate_sa_payload($$);
sub evaluate_sa_proposal($$);
sub evaluate_sa_transform($);
sub evaluate_transform_attribute($);
sub convert_proposals($);
sub convert_transforms($);
sub get_proposals_str($);
sub get_proposal_str($);
sub get_transforms_str($);


# global variables
my @transform_types = ('ENCR', 'PRF', 'INTEG', 'D-H', 'ESN');
my %transform_ids = (
	'ENCR'	=> [
		'RESERVED',
		'DES_IV64',
		'DES',
		'3DES',
		'RC5',
		'IDEA',
		'CAST',
		'BLOWFISH',
		'3IDEA',
		'DES_IV32',
		'RESERVED',
		'NULL',
		'AES_CBC',
		'AES_CTR',
		'AES-CCM_8',
		'AES-CCM_12',
		'AES-CCM_16',
		'AES-GCM_8',
		'AES-GCM_12',
		'AES-GCM_16',
		'NULL_AUTH_AES_GMAC',
	],
	'PRF'	=> [
		'RESERVED',
		'HMAC_MD5',
		'HMAC_SHA1',
		'HMAC_TIGER',
		'AES128_XCBC',
		'HMAC_SHA2_256',
		'HMAC_SHA2_384',
		'HMAC_SHA2_512',
		'AES128_CMAC',
	],
	'INTEG'	=> [
		'NONE',
		'HMAC_MD5_96',
		'HMAC_SHA1_96',
		'HMAC_DES_MAC',
		'HMAC_KPDK_MD5',
		'AES_XCBC_96',
		'HMAC_MD5_128',
		'HMAC_SHA1_160',
		'AES_CMAC_96',
		'AES_128_GMAC',
		'AES_192_GMAC',
		'AES_256_GMAC',
		'HMAC_SHA2_256_128',
		'HMAC_SHA2_384_192',
		'HMAC_SHA2_512_256',
	],
	'D-H'	=> [
		'1024 MODP Group',
		'1536 MODP Group',
		'2048 MODP Group',
		'3072 MODP Group',
		'4096 MODP Group',
		'6144 MODP Group',
		'8192 MODP Group',
		'256-bit random ECP group',
		'384-bit random ECP group',
		'512-bit random ECP group',
		'1024-bit MODP group with 160-bit prime Order Subgroup',
		'2048-bit MODP group with 224-bit prime Order Subgroup',
		'2048-bit MODP group with 256-bit prime Order Subgroup',
		'192-bit Random ECP Group',
		'224-bit Random ECP Group',
	],
	'ESN'	=> [
		'ESN',
		'No ESN'
	],
);

sub kJudgeSecurityAssociationPayload2($$$) {
	my ($rcv_payload, $exp_payload, $operation) = @_;

	my $result = 1;
	my $tmp_result = undef;
	my @output = ();
	my @tmp_output = undef;
	my $exp_proposals = $exp_payload->{'proposals'};
	my $rcv_proposals = $rcv_payload->{'proposals'};
	my $exp_proposals_num = @{$exp_proposals};
	my $rcv_proposals_num = @{$rcv_proposals};

	# convert proposals to comparable format
	my $exp_conv_proposals = convert_proposals($exp_proposals);
	my $rcv_conv_proposals = convert_proposals($rcv_proposals);

	# check if integrity algorithm is empty
	# if empty, it indicates INTEG_NONE
	{
		my $index_integ = 2;
		foreach my $proposals (@{$exp_conv_proposals}) {
			foreach my $proposal (@{$proposals}) {
				my $transform_integ = $proposal->[$index_integ];
				my $num_alg = @{$transform_integ};
				if ($num_alg == 0) {
					push(@{$transform_integ}, 'INTEG_NONE');
					last;
				}
			}
		}
		foreach my $proposals (@{$rcv_conv_proposals}) {
			foreach my $proposal (@{$proposals}) {
				my $transform_integ = $proposal->[$index_integ];
				my $num_alg = @{$transform_integ};
				if ($num_alg == 0) {
					push(@{$transform_integ}, 'INTEG_NONE');
					last;
				}
			}
		}
	}

	# compare SA proposals
	($tmp_result, @tmp_output) = compare_proposals($rcv_conv_proposals, $exp_conv_proposals);
	unless ($tmp_result) {
		$result = undef;
	}
	push(@output, @tmp_output);

	# evaluate contents of SA payload
	($tmp_result, @tmp_output) = evaluate_sa_payload($rcv_payload, $exp_payload);
	unless ($tmp_result) {
		$result = undef;
	}
	push(@output, @tmp_output);

	return($result, @output);
}


#
# subroutines to compare SA payload
# procedure:
# 1. convert IKEv2 format to comparable ARRAY format 
#    to eliminate the order of Transforms like below.
#	SA payload (ARRAY)
#		Proposals (ARRAY)
#			Proposal #1 (ARRAY)
#				ENCR Transforms  (ARRAY)
#					ENCR_3DES, ENCR_AES_CBC, ...
#				PRF Transforms   (ARRAY)
#				INTEG Transforms (ARRAY)
#				D-H Transforms   (ARRAY)
#				ESN Transforms   (ARRAY)
#			Proposal #1
#				...
#		Proposals
#			Proposal #2
#				...
# 2. compare ARRAY format
#	compare Proposals
#		compare Proposal
#			compare Transforms

# proposals
sub compare_proposals($$)
{
	my ($rcv_proposals, $exp_proposals) = @_;

	# setup
	my $result = undef;
	my $match_count = 0;
	my @matched_proposals = ();
	my @judgment = ();

	my $exp_proposals_num = @{$exp_proposals};
	my $rcv_proposals_num = @{$rcv_proposals};

	# compare SA proposal
	for (my $i = 0; $i < $exp_proposals_num; $i++) {
		my $exp_proposal = $exp_proposals->[$i];
		my $tmp_result = undef;
		my @tmp_judgment = undef;

		for (my $j = 0; $j < $rcv_proposals_num; $j++) {
			# skip proposal which has been matched already
			my $next = undef;
			foreach my $index (@matched_proposals) {
				if ($j == $index) {
					$next = 1;
					last;
				}
			}

			if ($next) {
				next;
			}

			# compare proposal
			my $rcv_proposal = $rcv_proposals->[$j];
			($tmp_result, @tmp_judgment) = compare_proposal($rcv_proposal, $exp_proposal);

			if ($tmp_result) {
				push(@matched_proposals, $j);
				last;
			}
		}

		# store judgment result for each proposal
		push(@judgment, @tmp_judgment);
		if ($tmp_result) {
			$match_count++;
		}
	}

	# judge
	if ($exp_proposals_num == $match_count) {
		$result = 1;
	}
	else {
		$result = undef;
		my @str = (
			"<font color='#ff0000'><b>NG</b></font>" .
			"\tThe number of matched SA Proposals is not enough.",
		);
		push(@judgment, \@str);
	}

	my $ret = {};
	$ret->{'result'} = $result;
	$ret->{'log'} = \@judgment;

	return($ret);
}

sub compare_proposals2($$)
{
	my ($rcv_proposals, $exp_proposals) = @_;

	# setup
	my $result = undef;
	my $match_count = 0;
	my @matched_proposals = ();
	my @judgment = ();

	my $exp_proposals_num = @{$exp_proposals};
	my $rcv_proposals_num = @{$rcv_proposals};

	# compare SA proposal
	for (my $i = 0; $i < $exp_proposals_num; $i++) {
		my $exp_proposal = $exp_proposals->[$i];
		my $tmp_result = undef;
		my @tmp_judgment = undef;

		for (my $j = 0; $j < $rcv_proposals_num; $j++) {
			# skip proposal which has been matched already
			my $next = undef;
			foreach my $index (@matched_proposals) {
				if ($j == $index) {
					$next = 1;
					last;
				}
			}

			if ($next) {
				next;
			}

			# compare proposal
			my $rcv_proposal = $rcv_proposals->[$j];
			($tmp_result, @tmp_judgment) = compare_proposal($rcv_proposal, $exp_proposal);

			if ($tmp_result) {
				push(@matched_proposals, $j);
				last;
			}
		}

		# store judgment result for each proposal
		push(@judgment, @tmp_judgment);
		if ($tmp_result) {
			$match_count++;
		}
	}

	# judge
	if ($exp_proposals_num == $match_count) {
		$result = 1;
	}
	else {
		$result = undef;
		my @str = (
			"<font color='#ff0000'><b>NG</b></font>" .
			"\tThe number of matched SA Proposals is not enough.",
		);
		push(@judgment, \@str);
	}

	return($result, @judgment);
}

# proposal
sub compare_proposal($$)
{
	my ($rcv_proposals, $exp_proposals) = @_;

	my $result = 1;
	my @judgment = ();
	my $exp_proposal_num = @{$exp_proposals};
	my $rcv_proposal_num = @{$rcv_proposals};

	for (my $i = 0; $i < $exp_proposal_num; $i++) {
		my $exp_proposal = $exp_proposals->[$i];

		if ($i+1 > $rcv_proposal_num) {
			$result = undef;
			last;
		}

		my $tmp_result = undef;
		my @tmp_output = undef;
		for (my $j = 0; $j < $rcv_proposal_num; $j++) {
			my $rcv_proposal = $rcv_proposals->[$j];
			($tmp_result, @tmp_output) = compare_transforms($rcv_proposal, $exp_proposal);
			push(@judgment, \@tmp_output);
		}
		unless ($tmp_result) {
			$result = undef;
		}
	}

	return($result, @judgment);
}

# transform
my $ok_str = "<b>OK</b>";
my $ng_str = "<font color='#ff0000'><b>NG</b></font>";
sub compare_transforms($$)
{
	my ($rcv_proposal, $exp_proposal) = @_;

	my $result = 1;
	my $str = undef;
	my @judgment = ();

	push(@judgment, kIKE::kPrint::html_bold('SA Proposal Comparison'));
	for (my $k = 0; $k < $#transform_types+1; $k++) {
		my $exp_transforms = get_transforms_str($exp_proposal->[$k]);
		my $rcv_transforms = get_transforms_str($rcv_proposal->[$k]);

		# XXX: 20100125
		{
			my $exp_transforms_num = scalar(@{$exp_proposal->[$k]});
			my $rcv_transforms_num = scalar(@{$rcv_proposal->[$k]});
			if ($exp_transforms_num < $rcv_transforms_num) {
				#printf("include $exp_transforms_num $rcv_transforms_num\n");
				my $n = 0;
				foreach my $exp (@{$exp_proposal->[$k]}) {
					foreach my $rcv (@{$rcv_proposal->[$k]}) {
						if ($exp eq $rcv) {
							$n++;
						}
					}
				}

				if ($n != $exp_transforms_num) {
					$result = undef;
					$str = $ng_str;
				}
				else {
					$str = $ok_str;
				}
			}
			else {
				if ($exp_transforms ne $rcv_transforms) {
					$result = undef;
					$str = $ng_str;
				}
				else {
					$str = $ok_str;
				}
			}
		}

		$str .= "\t" . $transform_types[$k] .
			":\t(received:" . $rcv_transforms . ", expected:" . $exp_transforms . ")";

		push(@judgment, $str);
	}

	return($result, @judgment);
}

# 
sub evaluate_sa_payload($$)
{
	my ($rcv_payload, $exp_payload) = @_;

	# setup
	my $result = 1;
	my @judgment = ();
	my @output = ();
	my $payload_length = 4;
	my $str = undef;
	my $key = undef;

	# SA Payload
	push(@judgment, kIKE::kPrint::html_bold($payloadsNames{'SA'}));

	# NextType
	$key = 'nexttype';
	if ($rcv_payload->{$key} eq $exp_payload->{$key}) {
		$str = $ok_str;
	}
	else {
		$str = $ng_str;
		$result = undef;
	}
	$str .= "\t$key: (received:$rcv_payload->{$key}, expected:$exp_payload->{$key}, comp: eq)";
	push(@judgment, $str);

	# Critical bit
	$key = 'critical';
	if ($rcv_payload->{$key} == $exp_payload->{$key}) {
		$str = $ok_str;
	}
	else {
		$str = $ng_str;
		$result = undef;
	}
	$str .= "\t$key: (received:$rcv_payload->{$key}, expected:0, comp: eq)";
	push(@judgment, $str);

	# RESERVED
	$key = 'reserved';
	if ($rcv_payload->{$key} == $exp_payload->{$key}) {
		$str = $ok_str;
	}
	else {
		$str = $ng_str;
		$result = undef;
	}
	$str .= "\t$key: (received:$rcv_payload->{$key}, expected:0, comp: eq)";
	push(@judgment, $str);

	push(@output, \@judgment);

	#
	my $tmp_result = undef;
	my $proposals_length = undef;
	my @tmp_output = undef;
	($tmp_result, $proposals_length, @tmp_output) = evaluate_sa_proposal($rcv_payload, $exp_payload);

	unless ($tmp_result) {
		$result = undef;
	}
	push(@output, @tmp_output);

	# Payload Length
	$key = 'length';
	if ($rcv_payload->{$key} == $payload_length + $proposals_length) {
		$str = $ok_str;
	}
	else {
		$str = $ng_str;
		$result = undef;
	}
	$str .= "\t$key: (received:$rcv_payload->{$key}, expected:" .
		($payload_length + $proposals_length) .
		", comp: eq)";
	push(@judgment, $str);

	return($result, @output);
}

sub evaluate_sa_proposal($$)
{
	my ($rcv_payload, $exp_payload) = @_;

	# setup
	my $result = 1;
	my $proposals_length = 0;
	my @output = ();
	my $str = undef;
	my $key = undef;

	my $exp_proposals = $exp_payload->{'proposals'};
	my $rcv_proposals = $rcv_payload->{'proposals'};
	my $exp_proposals_num = @{$exp_proposals};
	my $rcv_proposals_num = @{$rcv_proposals};

	my $exp_protocol_id = $exp_proposals->[0]->{'id'};
	my $exp_spi_size = $exp_proposals->[0]->{'spiSize'};
	my $exp_transform_count = $exp_proposals->[0]->{'transformCount'};
	my $first_proposal = 1;

	# Proposal Substructure
	for (my $i = 0; $i < $rcv_proposals_num; $i++) {
		my $rcv_proposal = $rcv_proposals->[$i];
		my @judgment = ();
		push(@judgment, kIKE::kPrint::html_bold('Proposal Substructure'));

		my $proposal_length = 8;

		# NextType (0 or 2)
		$key = 'nexttype';
		if ($i+1 == $rcv_proposals_num) {
			if ($rcv_proposal->{$key} == 0) {
				$str = $ok_str;
			}
			else {
				$str = $ng_str;
				$result = undef;
			}
			$str .= "\t$key: (received:$rcv_proposal->{$key}, expected:0, comp: eq)";
			push(@judgment, $str);
		}
		else {
			if ($rcv_proposal->{$key} == 2) {
				$str = $ok_str;
			}
			else {
				$str = $ng_str;
				$result = undef;
			}
			$str .= "\t$key: (received:$rcv_proposal->{$key}, expected:2, comp: eq)";
			push(@judgment, $str);
		}

		# RESERVED
		$key = 'reserved';
		if ($rcv_proposal->{$key} == 0) {
			$str = $ok_str;
		}
		else {
			$str = $ng_str;
			$result = undef;
		}
		$str .= "\t$key: (received:$rcv_proposal->{$key}, expected:0, comp: eq)";
		push(@judgment, $str);

		# Proposal#
		$key = 'number';
		if ($first_proposal && $rcv_proposal->{$key} ==1) {
			$str = $ok_str;
			$str .= "\t$key: (received:$rcv_proposal->{$key}, expected:1, comp: eq)";
		}
		else {
			if ($rcv_proposal->{$key} != 0) {
				$str = $ok_str;
			}
			else {
				$str = $ng_str;
				$result = undef;
			}
			$str .= "\t$key: (received:$rcv_proposal->{$key}, expected:0, comp: ne)";
		}
		push(@judgment, $str);

		# Protocol ID
		$key = 'id';
		if ($rcv_proposal->{$key} eq $exp_protocol_id) {
			$str = $ok_str;
		}
		else {
			$str = $ng_str;
			$result = undef;
		}
		$str .= "\t$key: (received:$rcv_proposal->{$key}, expected:$exp_protocol_id, comp: eq)";
		push(@judgment, $str);

		# SPI Size
		$key = 'spiSize';
		if ($rcv_proposal->{$key} eq $exp_spi_size) {
			$str = $ok_str;
		}
		else {
			$str = $ng_str;
			$result = undef;
		}
		$str .= "\t$key: (received:$rcv_proposal->{$key}, expected:$exp_spi_size, comp: eq)";
		push(@judgment, $str);
		$proposal_length += $rcv_proposal->{$key};

		# SPI
		if ($exp_spi_size) {
			$key = 'spi';
			if ($rcv_proposal->{$key}) {
				$str = $ok_str;
			}
			else {
				$str = $ng_str;
				$result = undef;
			}
			$str .= "\t$key: (received:$rcv_proposal->{$key}, expected:any, comp: eq)";
			push(@judgment, $str);
		}

		push(@output, \@judgment);

		my $tmp_result = undef;
		my $transforms_count = undef;
		my $transforms_length = undef;
		my @tmp_output = undef;
		($tmp_result, $transforms_count, $transforms_length, @tmp_output) =
			evaluate_sa_transform($rcv_proposal);

		unless ($tmp_result) {
			$result = undef;
		}
		push(@output, @tmp_output);

		# # of Transforms
#		if ($is_initial_exchanges) {
#			$transforms_count = $exp_transform_count;
#		}
		$key = 'transformCount';
		if ($rcv_proposal->{$key} eq $transforms_count) {
			$str = $ok_str;
		}
		else {
			$str = $ng_str;
			$result = undef;
		}
		$str .= "\t$key: (received:$rcv_proposal->{$key}, expected:$transforms_count, comp: eq)";
		splice(@judgment, -2, 0, $str);

		# Proposal Length
		$key = 'proposalLen';
		if ($rcv_proposal->{$key} == $proposal_length + $transforms_length) {
			$str = $ok_str;
		}
		else {
			$str = $ng_str;
			$result = undef;
		}
		$str .= "\t$key: (received:$rcv_proposal->{$key}, expected:" .
			($proposal_length + $transforms_length) .
			", comp: eq)";
		splice(@judgment, -3, 0, $str);

		$proposals_length += $proposal_length + $transforms_length;
	}

	return($result, $proposals_length, @output);
}


sub evaluate_sa_transform($)
{
	my ($rcv_proposal) = @_;

	# setup
	my $result = 1;
	my $transforms_length = 0;
	my @output = ();
	my $str = undef;
	my $key = undef;

	# Transform Substructure
	my $rcv_transforms = $rcv_proposal->{'transforms'};
	my $rcv_transforms_num = @{$rcv_transforms};
	for (my $j = 0; $j < $rcv_transforms_num; $j++) {
		my $rcv_transform = $rcv_transforms->[$j];
		my @judgment = ();
		push(@judgment, kIKE::kPrint::html_bold('Transform Substructure'));

		my $transform_length = 8;

		# NextType (0 or 3)
		$key = 'nexttype';
		if ($j+1 == $rcv_transforms_num) {
			if ($rcv_transform->{$key} == 0) {
				$str = $ok_str;
			}
			else {
				$str = $ng_str;
				$result = undef;
			}
			$str .= "\t$key: (received:$rcv_transform->{$key}, expected:0, comp: eq)";
			push(@judgment, $str);
		}
		else {
			if ($rcv_transform->{$key} == 3) {
				$str = $ok_str;
			}
			else {
				$str = $ng_str;
				$result = undef;
			}
			$str .= "\t$key: (received:$rcv_transform->{$key}, expected:3, comp: eq)";
			push(@judgment, $str);
		}

		# RESERVED
		$key = 'reserved1';
		if ($rcv_transform->{$key} == 0) {
			$str = $ok_str;
		}
		else {
			$str = $ng_str;
			$result = undef;
		}
		$str .= "\t$key: (received:$rcv_transform->{$key}, expected:0, comp: eq)";
		push(@judgment, $str);

		# Transform Type
		$key = 'type';
		my $is_included = undef;
		foreach my $elm (@transform_types) {
			if ($rcv_transform->{$key} eq $elm) {
				$is_included = 1;
				last;
			}
		}
		if ($is_included) {
			$str = $ok_str;
		}
		else {
			$str = $ng_str;
			$result = undef;
		}
		$str .= "\t$key: (received:$rcv_transform->{$key}, expected:$rcv_transform->{$key}, comp: eq)";
		push(@judgment, $str);

		# RESERVED
		$key = 'reserved2';
		if ($rcv_transform->{$key} == 0) {
			$str = $ok_str;
		}
		else {
			$str = $ng_str;
			$result = undef;
		}
		$str .= "\t$key: (received:$rcv_transform->{$key}, expected:0, comp: eq)";
		push(@judgment, $str);

		# Transform ID
		$key = 'id';
		$is_included = undef;
		foreach my $elm (@{$transform_ids{$rcv_transform->{'type'}}}) {
			if ($rcv_transform->{$key} eq $elm) {
				$is_included = 1;
				last;
			}
		}
		if ($is_included) {
			$str = $ok_str;
		}
		else {
			$str = $ng_str;
			$result = undef;
		}
		$str .= "\t$key: (received:$rcv_transform->{$key}, expected:$rcv_transform->{$key}, comp: eq)";
		push(@judgment, $str);

		push(@output, \@judgment);

		# Transform Length
		my $rcv_attributes = $rcv_transform->{'attributes'};
		my $rcv_attributes_num = @{$rcv_attributes};
		$key = 'transformLen';
		if ($rcv_transform->{'transformLen'} == 8) {
			if ($rcv_attributes_num == 0) {
				$str = $ok_str .
					"\t$key: (received:$rcv_transform->{$key}, expected:$rcv_transform->{$key}, comp: eq)";
				splice(@judgment, -3, 0, $str);
				$transforms_length += $transform_length;
			}
			else {
				$str = $ng_str .
					"\t$key: (received:$rcv_transform->{$key}, expected:12, comp: eq)";
				splice(@judgment, -3, 0, $str);
				$transforms_length += $transform_length + 4;
			}
			next;
		}

		my $tmp_result = undef;
		my $attributes_length = undef;
		my @tmp_output = undef;
		($tmp_result, $attributes_length, @tmp_output) = evaluate_transform_attribute($rcv_transform);

		unless ($tmp_result) {
			$result = undef;
		}
		push(@output, @tmp_output);

		if ($rcv_transform->{$key} == $transform_length + $attributes_length) {
			$str = $ok_str;
		}
		else {
			$str = $ng_str;
			$result = undef;
		}
		$str .= "\t$key: (received:$rcv_transform->{$key}, expected:" .
			($transform_length + $attributes_length) .
			", comp: eq)";
		splice(@judgment, -3, 0, $str);
		$transforms_length += $transform_length + $attributes_length;
	}

	return($result, $rcv_transforms_num, $transforms_length, @output);
}

sub evaluate_transform_attribute($)
{
	my ($rcv_transform) = @_;

	# setup
	my $result = 1;
	my $attributes_length = 0;
	my @output = ();
	my $str = undef;
	my $key = undef;

	# Transform Attribute
	my $rcv_attributes = $rcv_transform->{'attributes'};
	my $rcv_attributes_num = @{$rcv_attributes};
	for (my $k = 0; $k < $rcv_attributes_num; $k++) {
		my $rcv_attribute = $rcv_attributes->[$k];
		my @judgment = ();
		push(@judgment, kIKE::kPrint::html_bold('Transform Attribute'));

		# 
		$key = 'type';
		if ($rcv_attribute->{$key} eq 'Key Length') {
			$str = $ok_str;
		}
		else {
			$str = $ng_str;
			$result = undef;
		}
		$str .= "\t$key: (received:$rcv_attribute->{$key}, expected:$rcv_attribute->{$key}, comp: eq)";
		push(@judgment, $str);

		#
		if ($rcv_attribute->{'af'} == 0) {
			$key = 'length';
			if ($rcv_attribute->{$key} > 0) {
				$str = $ok_str;
			}
			else {
				$str = $ng_str;
				$result = undef;
			}
			$str .= "\t$key: (received:$rcv_attribute->{$key}, expected:$rcv_attribute->{$key}, comp: eq)";
			push(@judgment, $str);
			$attributes_length += $rcv_attribute->{$key};
		}
		else {
			$attributes_length += 4;
		}

		#
		$key = 'value';
		if ($rcv_attribute->{$key} == 128 || $rcv_attribute->{$key} == 192 || $rcv_attribute->{$key} == 256) {
			$str = $ok_str;
		}
		else {
			$str = $ng_str;
			$result = undef;
		}
		$str .= "\t$key: (received:$rcv_attribute->{$key}, expected:$rcv_attribute->{$key}, comp: eq)";
		push(@judgment, $str);

		push(@output, \@judgment);
	}

	return($result, $attributes_length, @output);
}



#
# subroutines to convert IKEv2 format to comparable ARRAY format
#
sub convert_proposals($)
{
	my ($proposals) = @_;

	my $conv_proposals = [];

	my $last_proposal_number = $proposals->[@{$proposals} -1]->{'number'};
	for (my $i = 0; $i < $last_proposal_number; $i++) {
		push(@{$conv_proposals}, []);
	}

	my $last = 0;
	foreach my $proposal (@{$proposals}) {
		if ($last) {
			last;
		}

		unless ($proposal->{'nexttype'} == 2) {
			$last = 1;
		}

		my $conv_transforms = convert_transforms($proposal->{'transforms'});

		push(@{$conv_proposals->[$proposal->{'number'} - 1]}, $conv_transforms);
	}

	return($conv_proposals);
}

sub convert_transforms($)
{
	my ($transforms) = @_;

	# setup
	my $encr = [];
	my $prf = [];
	my $integ = [];
	my $dh = [];
	my $esn = [];

	# body
	my $last = 0;
	foreach my $transform (@{$transforms}) {
		if ($last) {
			last;
		}

		unless ($transform->{'nexttype'} == 3) {
			$last = 1;
		}

		# combine type, id and key length
		my $str = $transform->{'type'} . '_' . $transform->{'id'};
		foreach my $attribute (@{$transform->{'attributes'}}) {
			if ($attribute->{'type'} ne 'Key Length') {
				next;
			}

			$str .= '-' . $attribute->{'value'};
		}

		# sort out string to each transform
		if ($transform->{'type'} eq 'ENCR') {
			push(@{$encr}, $str);
		}
		elsif ($transform->{'type'} eq 'PRF') {
			push(@{$prf}, $str);
		}
		elsif ($transform->{'type'} eq 'INTEG') {
			push(@{$integ}, $str);
		}
		elsif ($transform->{'type'} eq 'D-H') {
			push(@{$dh}, $str);
		}
		elsif ($transform->{'type'} eq 'ESN') {
			push(@{$esn}, $str);
		}
	}

	return([$encr, $prf, $integ, $dh, $esn]);
}


#
# subroutines to get string
#
sub get_proposals_str($)
{
	my ($proposals) = @_;

	my $str = '';
	my $n = @{$proposals};
	for (my $i = 0; $i < $n; $i++) {
		$str .= '#' . ($i+1) . ': '. get_proposal_str($proposals->[$i]) . "\n";
	}

	return($str);
}

sub get_proposal_str($)
{
	my ($proposal) = @_;

	my $str = '';
	foreach my $transform (@{$proposal}) {
		my $n = @{$transform};
		unless ($n > 0) {
			next;
		}
		foreach my $tid (@{$transform}) {
			$str .= $tid . ', ';
		}
	}
	$str = substr($str, 0, -2);
	return($str);
}

sub get_transforms_str($)
{
	my ($transforms) = @_;

	return(join(', ', sort(@{$transforms})));
}


sub kJudgeSAStandard($$$) {
	my ($received, $expected, $operation) = @_;

	my @judgment = ();
	my $result = $TRUE;
	my @rcv_proposals = @{$received->{proposals}};
	my @exp_proposals = @{$expected->{proposals}};
	my @op_proposals = (defined($operation)) ? @{$operation->{SA}->{array}} : undef;
	my $rcv_num = scalar(@rcv_proposals);
	my $exp_num = scalar(@exp_proposals);

	for (my $rcv_index = 0; $rcv_index < $rcv_num; $rcv_index++) {
		my $rcv_proposal = $rcv_proposals[$rcv_index];

		for (my $exp_index = 0; $exp_index < $exp_num; $exp_index++) {
			my $exp_proposal = $exp_proposals[$exp_index];
			my $op_proposal = (defined($operation)) ? $op_proposals[$exp_index] : undef;
			my $op_trans_operation = (defined($operation)) ?
				$op_proposal->{transforms}->{operation} : 'standard';

			# Judge the proposal.
			my $tmp_result = undef;
			my @tmp_output = undef;
			if ($op_trans_operation eq 'standard') {
				($tmp_result, @tmp_output) =
					kJudgeSAProposalStandard($rcv_proposal, $exp_proposal, $op_proposal);
			} elsif ($op_trans_operation eq 'comb') {
				($tmp_result, @tmp_output) =
					kJudgeSAProposalComb($rcv_proposal, $exp_proposal, $op_proposal);
			}

			# Set the result.
			$result = $FALSE unless $tmp_result;
			# Save the proposal's messages.
			push(@judgment, @tmp_output);
		}
	}
	# Return the result and messages.
	return ($result, @judgment);
}

sub kJudgeSAComb($$$) {
	my ($received, $expected, $operation) = @_;

	my @judgment = ();
	my $result = $TRUE;
	my @rcv_proposals = @{$received->{proposals}};
	my @exp_proposals = @{$expected->{proposals}};
	my @op_proposals = (defined($operation)) ? @{$operation->{SA}->{array}} : undef;
	my $rcv_num = scalar(@rcv_proposals);
	my $exp_num = scalar(@exp_proposals);
	my @passed = ();
	my @results = ();

	for (my $rcv_index = 0; $rcv_index < $rcv_num; $rcv_index++) {
		my $rcv_proposal = $rcv_proposals[$rcv_index];

		my $tmp_result1 = $FALSE;
		my @tmp_output1 = ();
		for (my $exp_index = 0; $exp_index < $exp_num; $exp_index++) {
			my @checked = grep {$exp_index == $_} @passed;
			next if ($#checked >= 0);

			my $exp_proposal = $exp_proposals[$exp_index];
			my $op_proposal = (defined($operation)) ? $op_proposals[$exp_index] : undef;
			my $op_trans_operation = (defined($operation)) ?
				$op_proposal->{transforms}->{operation} : 'standard';

			# Judge the proposal.
			my $tmp_result2 = undef;
			my @tmp_output2 = undef;
			if ($op_trans_operation eq 'standard') {
				($tmp_result2, @tmp_output2) =
					kJudgeSAProposalStandard($rcv_proposal, $exp_proposal, $op_proposal);
			} elsif ($op_trans_operation eq 'comb') {
				($tmp_result2, @tmp_output2) =
					kJudgeSAProposalComb($rcv_proposal, $exp_proposal, $op_proposal);
			}

			push(@tmp_output1, @tmp_output2);
			if ($tmp_result2) {
				push(@passed, $exp_index);
				$tmp_result1 = $tmp_result2;
				last;
			}
		}

		push(@results, $tmp_result1);
		if ($tmp_result1) {
			push(@judgment, @tmp_output1);
		}
	}

	@results = grep {$_ == $TRUE} @results;
	if (scalar(@results)) {
		$result = $TRUE;
	}

	if ($result != $FALSE && scalar(@passed) != scalar(@exp_proposals)) {
		my $str =  "<font color='#ff0000'><b>NG</b></font>" .
			"\tThe number of proposals is not enough.";
		push(@judgment, $str);
		$result = $comparison_result->{COMB_FALSE};
	}

	# Return the result and messages.
	return ($result, @judgment);
}

sub kJudgeSAProposalStandard($$$) {
	my ($proposal, $expected, $operation) = @_;

	my $result = $TRUE;
	my @judgment = ();
	my @output = ();

	# Process comparisons of values.
	foreach my $key qw(nexttype reserved proposalLen number id spiSize transformCount spi ) {
		# Get the expected value
		my $exp = $expected->{$key};
		my $comp = (defined($expected->{$key . '_comparator'})) ? $expected->{$key . '_comparator'} : 'nop';
		# Compare a value to its expected.
		my ($bool, $texte) = kJudgeCompare($key, $proposal->{$key}, $exp, $comp);
		# Set the result.
		$result = $FALSE unless $bool;
		# Save the message.
		push(@output, $texte);
	}
	unshift(@output, kIKE::kPrint::html_bold('SA Proposal'));
	push(@judgment, \@output);

	# Get the transforms.
	my @rcv_transforms = @{$proposal->{transforms}};
	my @exp_transforms = @{$expected->{transforms}};
	my @op_transforms = (defined($operation)) ? @{$operation->{transforms}->{array}} : undef;
	# Process the tranforms
	for (my $i = 0; $i < scalar(@rcv_transforms); $i++) {
		my $rcv_transform = $rcv_transforms[$i];
		my $exp_transform = $exp_transforms[$i];
		my $op_transform = (defined($operation)) ? $op_transforms[$i] : undef;
		my $op_attr_operation = (defined($operation)) ?
			$op_transform->{attributes}->{operation} : 'standard';

		# Skip empty entries.
		#next unless (exists $expected->{transforms}->[$i]) && (defined $expected->{transforms}->[$i]);
		# Judge the transform.
		my $tmp_result = undef;
		my @tmp_output = undef;
		if ($op_attr_operation eq 'standard') {
			($tmp_result, @tmp_output) =
				kJudgeSATransformStarndard($rcv_transform, $exp_transform, $op_transform);
		}
		elsif ($op_attr_operation eq 'comb') {
			($tmp_result, @tmp_output) = kJudgeSATransformComb($rcv_transform, $exp_transform, $op_transform);
		}
		# Set the result.
		$result = $FALSE unless ($tmp_result);
		# Save the transform's messages.
		push(@judgment, @tmp_output);
	}

	# Return the result and messages.
	return ($result, @judgment);
}

sub kJudgeSAProposalComb($$$) {
	my ($proposal, $expected, $operation) = @_;

	# Initialize the values.
	my $result = $TRUE;
	my @judgment = ();
	my @output = ();
	push(@output, kIKE::kPrint::html_bold('SA Proposal'));

	# Process comparisons of values.
	#foreach my $key qw(nexttype reserved proposalLen number id spiSize transformCount spi ) {
	# if combination comparison is enabled, nexttype is omitted
	foreach my $key qw(reserved proposalLen number id spiSize transformCount spi ) {
		# Get the expected value
		my $exp = $expected->{$key};
		my $comp = (defined($expected->{$key . '_comparator'})) ? $expected->{$key . '_comparator'} : 'nop';
		# Compare a value to its expected.
		my ($bool, $texte) = kJudgeCompare($key, $proposal->{$key}, $exp, $comp);
		# Set the result.
		$result = $FALSE unless $bool;
		# Save the message.
		push(@output, $texte);
	}

	# Get the transforms.
	my @rcv_transforms = @{$proposal->{transforms}};
	my @exp_transforms = @{$expected->{transforms}};
	my @op_transforms = (defined($operation)) ? @{$operation->{transforms}->{array}} : undef;
	my @passed = ();

	# Process the tranforms
	for (my $rcv_index = 0; $rcv_index < scalar(@rcv_transforms); $rcv_index++) {
		my $rcv_transform = $rcv_transforms[$rcv_index];

		my $tmp_result1 = $FALSE;
		my @tmp_output1 = ();
		for (my $exp_index = 0; $exp_index < scalar(@exp_transforms); $exp_index++) {
			# Skip entries checked already
			my @checked = grep {$exp_index == $_} @passed;
			next if ($#checked >= 0);

			my $exp_transform = $exp_transforms[$exp_index];
			my $op_transform = (defined($operation)) ? $op_transforms[$exp_index] : undef;
			my $op_attr_operation = (defined($operation)) ?
				$op_transform->{attributes}->{operation} : 'standard';

			# Judge the transform.
			my $tmp_result2 = undef;
			my @tmp_output2 = undef;
			if ($op_attr_operation eq 'standard') {
				($tmp_result2, @tmp_output2) =
					kJudgeSATransformStarndard($rcv_transform, $exp_transform, $op_transform);
			}
			elsif ($op_attr_operation eq 'comb') {
				($tmp_result2, @tmp_output2) =
					kJudgeSATransformComb($rcv_transform, $exp_transform, $op_transform);
			}

			push(@tmp_output1, @tmp_output2);
			if ($tmp_result2) {
				push(@passed, $exp_index);
				$tmp_result1 = $tmp_result2;
				last;
			}
		}

		$result = $FALSE unless ($tmp_result1);
		push(@judgment,  @tmp_output1) if ($result);
	}

	unshift(@judgment, \@output) if ($result);

	if ($result != $FALSE && scalar(@passed) != scalar(@exp_transforms)) {
		my $str =  "<font color='#ff0000'><b>NG</b></font>" .
			"\tThe number of transforms is not enough.";
		push(@judgment, $str);
		$result = $comparison_result->{COMB_FALSE};
	}

	# Return the result and messages.
	return ($result, @judgment);
}

sub kJudgeSATransformStarndard($$$) {
	# Read the parameters.
	my ($transform, $expected, $operation) = @_;

	# Initialize the values.
	my $result = $TRUE;
	my @judgment = ();
	my @output = ();
	push(@output, kIKE::kPrint::html_bold('SA Transform'));

	# Process comparisons of values.
	foreach my $key qw(nexttype reserved1 transformLen type reserved2 id ) {
		# Get the expected value
		my $exp = $expected->{$key};
		# Compare a value to its expected.
		my ($bool, $texte) = kJudgeCompare($key, $transform->{$key}, $exp);
		# Set the result.
		$result = $FALSE unless $bool;
		# Save the message.
		push(@output, $texte);
	}
	push(@judgment, \@output);

	# Get the attributes.
	my @attributes = @{$transform->{attributes}};
	# Process the attributes.
	for (my $i = 0; $i < scalar(@attributes); $i++) {
		# Skip empty entries.
		#next unless (exists $expected->{attributes}->[$i]) && (defined $expected->{attributes}->[$i]);
		# Judge the attribute.
		my ($tmpRes, @tmpOut) = kJudgeSAAttribute($attributes[$i], $expected->{attributes}->[$i]);
		# Set the result.
		$result = $FALSE unless $tmpRes;
		# Save the attribute's messages.
		push(@judgment, @tmpOut);
	}

	# Return the result and messages.
	return ($result, @judgment);
}

sub kJudgeSATransformComb($$$) {
	# Read the parameters.
	my ($transform, $expected, $operation) = @_;

	# Initialize the values.
	my $result = $TRUE;
	my @judgment = ();
	my @output = ();
	push(@output, kIKE::kPrint::html_bold('SA Transform'));

	# Process comparisons of values.
	foreach my $key qw(nexttype reserved1 transformLen type reserved2 id ) {
		# Get the expected value
		my $exp = $expected->{$key};
		# Compare a value to its expected.
		my ($bool, $texte) = kJudgeCompare($key, $transform->{$key}, $exp);
		# Set the result.
		$result = $FALSE unless $bool;
		# Save the message.
		push(@output, $texte);
	}
	push(@judgment, \@output);

	# Get the attributes.
	my @rcv_attributes = @{$transform->{attributes}};
	my @exp_attributes = @{$expected->{attributes}};
	my @passed = ();

	# Process the attributes.
	for (my $rcv_index = 0; $rcv_index < scalar(@rcv_attributes); $rcv_index++) {
		my $rcv_attribute = $rcv_attributes[$rcv_index];

		my $tmp_result1 = $FALSE;
		for (my $exp_index = 0; $exp_index < scalar(@exp_attributes); $exp_index++) {
			my $exp_attribute = $exp_attributes[$exp_index];
			my ($tmp_result2, @tmp_output) = kJudgeSAAttribute($rcv_attribute, $exp_attribute);

			push(@judgment, @tmp_output);
			if ($tmp_result2) {
				push(@passed, $exp_index);
				$tmp_result1 = $tmp_result2;
				last;
			}
		}
		$result = $FALSE unless ($tmp_result1);
	}

	if ($result != $FALSE && scalar(@passed) != scalar(@exp_attributes)) {
		my $str =  "<font color='#ff0000'><b>NG</b></font>" .
			"\tThe number of attributes is not enough.";
		push(@judgment, $str);
		$result = $comparison_result->{COMB_FALSE};
	}

	# Return the result and messages.
	return ($result, @judgment);
}

sub kJudgeSAAttribute($$) {
	# Read the parameters.
	my ($attribute, $expected) = @_;
	# Initialize the values.
	my $result = $TRUE;
	my @output = ();
	push(@output, kIKE::kPrint::html_bold('SA Attribute'));

	# Process comparisons of values.
	foreach my $key qw(type value) {
		# Get the expected value
		my $exp = $expected->{$key};
		# Compare a value to its expected.
		my ($bool, $texte) = kJudgeCompare($key, $attribute->{$key}, $exp);
		# Set the result.
		$result = $FALSE unless $bool;
		# Save the message.
		push(@output, $texte);

		unless ($attribute->{$key} && 0x8000) {
			$exp = $expected->{length};
			($bool, $texte) = kJudgeCompare($key, $attribute->{length}, $exp);
			# Set the result.
			$result = $FALSE unless $bool;
			# Save the message.
			push(@output, $texte);
		}

	}
	# Return the result and messages.
	return ($result, \@output);
}

sub kJudgeKeyExchangePayload($$$) {
	# Read the parameters.
	my ($ke, $expected, $operation) = @_;

	my @judgment = ();
	my @output = undef;
	my $result = undef;

	# Process the payload common header.
	($result, @output) = judge_GenericPayloadHeader($ke, $expected);
	unshift(@output, kIKE::kPrint::html_bold($payloadsNames{'KE'}));

	# Process comparisons of values.
	foreach my $key qw(group reserved1 publicKey) {
		# Get the expected value
		my $exp = $expected->{$key};
		# Compare a value to its expected.
		my ($bool, $texte) = kJudgeCompare($key, $ke->{$key}, $exp);
		# Set the result.
		$result = $FALSE unless $bool;
		# Save the message.
		push(@output, $texte);
	}
	push(@judgment, \@output);

	# Return the result and messages.
	return ($result, @judgment);
}

sub kJudgeIdentificationIPayload($$$) {
	return(kJudgeIdentificationPayload('IDi', @_));
}

sub kJudgeIdentificationRPayload($$$) {
	return(kJudgeIdentificationPayload('IDr', @_));
}

sub kJudgeIdentificationPayload($$$$) {
	# Read the parameters.
	my ($type, $id, $expected, $operation) = @_;

	my @judgment = ();
	my @output = undef;
	my $result = undef;

	# Process the payload common header.
	($result, @output) = judge_GenericPayloadHeader($id, $expected);
	unshift(@output, kIKE::kPrint::html_bold($payloadsNames{$type}));

	# Process comparisons of values.
	foreach my $key qw(type reserved1 value) {
		# Get the expected value
		my $exp = $expected->{$key};
		# Compare a value to its expected.
		my ($bool, $texte) = kJudgeCompare($key, $id->{$key}, $exp);
		# Set the result.
		$result = $FALSE unless $bool;
		# Save the message.
		push(@output, $texte);
	}
	push(@judgment, \@output);

	# Return the result and messages.
	return ($result, @judgment);
}

sub kJudgeNoncePayload($$$) {
	# Read the parameters.
	my ($nonce, $expected, $operation) = @_;

	my @judgment = ();
	my @output = undef;
	my $result = undef;

	# Process the payload common header.
	($result, @output) = judge_GenericPayloadHeader($nonce, $expected);
	unshift(@output, kIKE::kPrint::html_bold($payloadsNames{'Ni, Nr'}));

	# Process comparisons of values.
	foreach my $key qw(nonce) {
		# Get the expected value
		my $exp = $expected->{$key};
		# Compare a value to its expected.
		my ($bool, $texte) = kJudgeCompare($key, $nonce->{$key}, $exp);
		# Set the result.
		$result = $FALSE unless $bool;
		# Save the message.
		push(@output, $texte);
	}
	push(@judgment, \@output);

	# Return the result and messages.
	return ($result, @judgment);
}

sub kJudgeDeletePayload($$$) {
	# Read the parameters.
	my ($self, $expected, $operation) = @_;

	my @judgment = ();
	my @output = undef;
	my $result = undef;

	# Process the payload common header.
	($result, @output) = judge_GenericPayloadHeader($self, $expected);
	unshift(@output, kIKE::kPrint::html_bold($payloadsNames{'D'}));

	# Process comparisons of values.
	foreach my $key qw(id spiSize spiCount spis) {
		# Get the expected value
		my $exp = $expected->{$key};
		# Compare a value to its expected.
		my ($bool, $texte) = kJudgeCompare($key, $self->{$key}, $exp);
		# Set the result.
		$result = $FALSE unless $bool;
		# Save the message.
		push(@output, $texte);
	}
	push(@judgment, \@output);

	# Return the result and messages.
	return ($result, @judgment);
}

sub kJudgeCertificationPayload($$$)
{
	# Read the parameters.
	my ($self, $expected, $operation) = @_;

	my @judgment = ();
	my @output = undef;
	my $result = undef;

	# Process the payload common header.
	($result, @output) = judge_GenericPayloadHeader($self, $expected);
	unshift(@output, kIKE::kPrint::html_bold($payloadsNames{'CERT'}));

	# Process comparisons of values.
	foreach my $key qw(cert_encoding cert_data) {
		my $exp = $expected->{$key};
		my ($bool, $texte) = kJudgeCompare($key, $self->{$key}, $exp);
		$result = $FALSE unless $bool;
		push(@output, $texte);
	}
	push(@judgment, \@output);

	# Return the result and messages.
	return ($result, @judgment);
}

sub kJudgeCertificationRequestPayload($$$)
{
	# Read the parameters.
	my ($self, $expected, $operation) = @_;

	my @judgment = ();
	my @output = undef;
	my $result = undef;

	# Process the payload common header.
	($result, @output) = judge_GenericPayloadHeader($self, $expected);
	unshift(@output, kIKE::kPrint::html_bold($payloadsNames{'CERTREQ'}));

	# Process comparisons of values.
	foreach my $key qw(cert_encoding cert_auth) {
		my $exp = $expected->{$key};
		my ($bool, $texte) = kJudgeCompare($key, $self->{$key}, $exp);
		$result = $FALSE unless $bool;
		push(@output, $texte);
	}
	push(@judgment, \@output);

	# Return the result and messages.
	return ($result, @judgment);
}

sub kJudgeAuthenticationPayload($$$) {
	# Read the parameters.
	my ($auth, $expected, $operation) = @_;

	my @judgment = ();
	my @output = undef;
	my $result = undef;

	# Process the payload common header.
	($result, @output) = judge_GenericPayloadHeader($auth, $expected);
	unshift(@output, kIKE::kPrint::html_bold($payloadsNames{'AUTH'}));

	# Process comparisons of values.
	foreach my $key qw(method reserved1 data) {
		# Get the expected value
		my $exp = $expected->{$key};
		# Compare a value to its expected.
		my ($bool, $texte) = kJudgeCompare($key, $auth->{$key}, $exp);
		# Set the result.
		$result = $FALSE unless $bool;
		# Save the message.
		push(@output, $texte);
	}
	push(@judgment, \@output);

	# Return the result and messages.
	return ($result, @judgment);
}

sub kJudgeNotifyPayload($$$) {
	# Read the parameters.
	my ($n, $expected, $operation) = @_;

	my @judgment = ();
	my @output = undef;
	my $result = undef;

	# Process the payload common header.
	($result, @output) = judge_GenericPayloadHeader($n, $expected);
	unshift(@output, kIKE::kPrint::html_bold($payloadsNames{'N'}));

	# Process comparisons of values.
	foreach my $key qw(id spiSize type spi data) {
		# Get the expected value
		my $exp = $expected->{$key};
		# Compare a value to its expected.
		my ($bool, $texte) = kJudgeCompare($key, $n->{$key}, $exp);
		# Set the result.
		$result = $FALSE unless $bool;
		# Save the message.
		push(@output, $texte);
	}
	push(@judgment, \@output);

	# Return the result and messages.
	return ($result, @judgment);
}

sub kJudgeVendorIDPayload($$$) {
	# Read the parameters.
	my ($self, $expected, $operation) = @_;

	my @judgment = ();
	my @output = undef;
	my $result = undef;

	# Process the payload common header.
	($result, @output) = judge_GenericPayloadHeader($self, $expected);
	unshift(@output, kIKE::kPrint::html_bold($payloadsNames{'V'}));

	# Process comparisons of values.
	foreach my $key qw(vendorID) {
		# Get the expected value
		my $exp = $expected->{$key};
		# Compare a value to its expected.
		my ($bool, $texte) = kJudgeCompare($key, $self->{$key}, $exp);
		# Set the result.
		$result = $FALSE unless $bool;
		# Save the message.
		push(@output, $texte);
	}
	push(@judgment, \@output);

	# Return the result and messages.
	return ($result, @judgment);
}

sub kJudgeTrafficSelectorIPayload($$$) {
	return(kJudgeTrafficSelectorPayload('TSi', @_));
}

sub kJudgeTrafficSelectorRPayload($$$) {
	return(kJudgeTrafficSelectorPayload('TSr', @_));
}

sub kJudgeTrafficSelectorPayload($$$$) {
	# Read the parameters.
	my ($type, $ts, $expected, $operation) = @_;

	my @judgment = ();
	my @output = undef;
	my $result = undef;

	# Process the payload common header.
	($result, @output) = judge_GenericPayloadHeader($ts, $expected);
	unshift(@output, kIKE::kPrint::html_bold($payloadsNames{$type}));

	# Process comparisons of values.
	foreach my $key qw(count reserved1) {
		# Get the expected value
		my $exp = $expected->{$key};
		# Compare a value to its expected.
		my ($bool, $texte) = kJudgeCompare($key, $ts->{$key}, $exp);
		# Set the result.
		$result = $FALSE unless $bool;
		# Save the message.
		push(@output, $texte);
	}
	push(@judgment, \@output);

	unless (defined($expected->{selectors})) {
		return($result, @judgment);
	}

	my $op_hash = (defined($operation)) ? $operation->{$type} : undef;
	my $op_operation = (defined($operation)) ? $op_hash->{operation} : 'standard';
	my $tmp_result = undef;
	my @tmp_output = undef;
	if ($op_operation eq 'standard') {
		($tmp_result, @tmp_output) = kJudgeTSSelectorStandard($ts, $expected);
	}
	elsif ($op_operation eq 'comb') {
		($tmp_result, @tmp_output) = kJudgeTSSelectorComb($ts, $expected);
	}

	$result = $FALSE unless ($tmp_result);
	push(@judgment, @tmp_output);

	# Return the result and messages.
	return ($result, @judgment);
}

sub kJudgeTSSelectorStandard($$) {
	my ($received, $expected) = @_;

	my @judgment = ();
	my $result = $TRUE;
	my @rcv_selectors = @{$received->{selectors}};
	my @exp_selectors = @{$expected->{selectors}};

	# Process the selectors.
	foreach my $rcv_selector (@rcv_selectors) {
		my $exp_selector = shift(@exp_selectors);

		my @output = ();
		push(@output, kIKE::kPrint::html_bold('Traffic Selector'));

		# Process comparisons of values.
		foreach my $key qw(type protocol selectorLen sport eport saddr eaddr) {
			# Compare a value to its expected.
			my ($bool, $texte) = kJudgeCompare($key, $rcv_selector->{$key}, $exp_selector->{$key});
			# Set the result.
			$result = $FALSE unless $bool;
			# Save the message.
			push(@output, $texte);
		}

		# Save selector's messages.
		push(@judgment, \@output);
	}

	return ($result, @judgment);
}

sub kJudgeTSSelectorComb($$) {
	my ($received, $expected) = @_;

	my @judgment = ();
	my $result = $TRUE;
	my @rcv_selectors = @{$received->{selectors}};
	my @exp_selectors = @{$expected->{selectors}};
	my $rcv_num = scalar(@rcv_selectors);
	my $exp_num = scalar(@exp_selectors);
	my @passed = ();

	# Process the selectors.
	for (my $rcv_index = 0; $rcv_index < $rcv_num; $rcv_index++) {
		my $tmp_result1 = $FALSE;
		my $rcv_selector = $rcv_selectors[$rcv_index];

		for (my $exp_index = 0; $exp_index < $exp_num; $exp_index++) {
			my $tmp_result2 = $TRUE;
			my $exp_selector = $exp_selectors[$exp_index];

			# skip if checked already
			my @checked = grep {$exp_index == $_} @passed;
			next if ($#checked >= 0);

			my @tmp_output = ();
			push(@tmp_output, kIKE::kPrint::html_bold('Traffic Selector (expected #'. $exp_index . ')'));

			# Process comparisons of values.
			foreach my $key qw(type protocol selectorLen sport eport saddr eaddr) {
				# Compare a value to its expected.
				my ($bool, $texte) = kJudgeCompare($key, $rcv_selector->{$key}, $exp_selector->{$key});
				# Set the result.
				$tmp_result2 = $FALSE unless $bool;
				# Save the message.
				push(@tmp_output, $texte);
			}

			if ($tmp_result2) {
				$tmp_result1 = $TRUE;
				push(@passed, $exp_index);
				# Save selector's messages.
				push(@judgment, \@tmp_output);
				last;
			}
			elsif ($exp_index == $exp_num - 1) {
				# does not match with the last expected TS
				push(@judgment, \@tmp_output);
			}
		}

		$result = $FALSE unless($tmp_result1);
	}

	return ($result, @judgment);
}

sub kJudgeEncryptedPayload($$$) {
	return($TRUE, []);
}

sub kJudgeEncryptedPayload2($$$) {
	# Read the parameters.
	my ($e, $expected, $operation) = @_;

	my @judgment = ();
	my @output = undef;
	my $result = undef;

	# Get inner payloads.
	my @innerPayloads = @{$e->{'innerPayloads'}};

	# Process the payload common header.
	@output = ();
	$result = $TRUE;
	unshift(@output, kIKE::kPrint::html_bold($payloadsNames{'E'}));

	# Process comparisons of values.
	foreach my $key qw(innerType critical reserved length iv checksum) {
		# Get the expected value
		my $exp = $expected->{$key};
		# Compare a value to its expected.
		my ($bool, $texte) = kJudgeCompare($key, $e->{$key}, $exp);
		# Set the result.
		$result = $FALSE unless $bool;
		# Save the message.
		push(@output, $texte);
	}
	push(@judgment, \@output);

	unless (defined($expected->{'innerPayloads'})) {
		return($result, @judgment);
	}

	# Initialize the values for parsing inner payloads.
	my $nexttype_rcv = $e->{'innerType'};
	my $nexttype_exp = $expected->{'innerType'};
	my @exp_innerpayloads = @{$expected->{'innerPayloads'}};

	# Process inner payloads.
	foreach my $payload (@innerPayloads) {
		my $exp = shift(@exp_innerpayloads);

		my $tmpRes = undef;
		my @tmpOut = undef;

		# Judge the payload with the dedicated function or only its header.
		if (!defined($exp) ||
		    !defined($exp->{'self'}) ||
		    $nexttype_rcv ne $exp->{'self'}) {
			my @tmp = ();
			my $str = '';
			$str .= "<font color='#ff0000'><b>NG</b></font>\t";
			$str .= $nexttype_rcv;
			$str .= ' is unexpected.';
			$str .= $nexttype_exp;
			$str .= ' is expected.';

			push(@tmp, $str);
			push(@tmpOut, \@tmp);
		}
		elsif (defined $judgmentFunctions{$nexttype_rcv}) {
			($tmpRes, @tmpOut) = &{$judgmentFunctions{$nexttype_rcv}}($payload, $exp, $operation);
		}
		else {
			($tmpRes, @tmpOut) = judge_GenericPayloadHeader($payload, $exp);
		}
		# Set the result.
		$result = $FALSE unless $tmpRes;

		# Add the resulting message list to its section in the result messages.
		push(@judgment, @tmpOut);

		# Advance to next payload.
		$nexttype_rcv = $payload->{'nexttype'};
		$nexttype_exp = $exp->{'nexttype'};
	}

	# Return the result and messages.
	return ($result, @judgment);
}

sub kJudgeConfigurationPayload($$) {
	my ($conf, $expected) = @_;

	my @judgment = ();
	my @output = undef;
	my $result = undef;

	($result, @output) = judge_GenericPayloadHeader($conf, $expected);
	unshift(@output, kIKE::kPrint::html_bold($payloadsNames{'CP'}));

	foreach my $key qw(cfg_type reserved1) {
		my $exp = $expected->{$key};
		# Compare a value to its expected.
		my ($bool, $texte) = kJudgeCompare($key, $conf->{$key}, $exp);
		# Set the result.
		$result = $FALSE unless $bool;
		# Save the message.
		push(@output, $texte);
	}
	push(@judgment, \@output);

	# compare configuration attributes
	my $tmp_result = undef;
	my @tmp_output = undef;
	($tmp_result, @tmp_output) = kJudgeConfigurationAttribute($conf->{'attributes'}, $expected->{'attributes'});

	$result = $FALSE unless ($tmp_result);
	push(@judgment, @tmp_output);

	return($result, @judgment);
}


sub kJudgeConfigurationAttribute($$)
{
	my ($received, $expected) = @_;

	my @judgment = ();
	my @output = undef;
	my $result = $TRUE;
	my @rcv_attrs = @{$received};
	my @exp_attrs = @{$expected};
	my $rcv_index = 0;
	my $exp_index = 0;

	push(@output, kIKE::kPrint::html_bold('Configuration Attribute'));

	foreach my $rcv_attr (@rcv_attrs) {
		my $exp_attr = $exp_attrs[$exp_index];

		foreach my $key qw(reserved attr_type length value) {
			# Compare a value to its expected.
			my ($bool, $texte) = kJudgeCompare($key, $rcv_attr->{$key}, $exp_attr->{$key});
			# Set the result.
			$result = $FALSE unless $bool;
			# Save the message.
			push(@output, $texte);
		}
		push(@judgment, \@output);

		$exp_index ++;
	}

	return($result, @judgment);
}

sub kJudgePrepare($$;$$) {
	return($TRUE);
}

sub kJudgePrepare2($$;$$) {
	my ($received, $expected, $enable_check_order, $enable_prepare_payloads) = @_;

	# don't compare messages which have diffrent Exchange Type
	if ($received->[0]->{'exchType'} ne $expected->[0]->{'exchType'}) {
		my $str = "<TR VALIGN=\"top\">\n";
		$str .= '<TD>' . kCommon::getTimeStamp() . "</TD>\n";
		$str .= '<TD>Different Exchange Type ';
		$str .= '(received: ' . $received->[0]->{'exchType'};
		$str .= ', expected: ' . $expected->[0]->{'exchType'} . ')';
		$str .= '</TD></TR>';
		kCommon::prLogHTML($str);

		return($FALSE);
	}

	$enable_check_order = (defined($enable_check_order)) ? $enable_check_order : $TRUE;
	$enable_prepare_payloads = (defined($enable_prepare_payloads)) ? $enable_prepare_payloads : $TRUE;

	my $result = $TRUE;

	# check payload order
	if (0) { # make test packet
# 		my $payload1 = {	# Key Exchange Payload
# 			'self'		=> 'KE',	# *** MUST BE HERE ***

# 			'nexttype'	=> 'TSi',	# Next Payload
# 			'critical'	=> '0',		# Critical
# 			'reserved'	=> '0',		# RESERVED
# 			'length'	=> '136',	# Payload Length
# 			'group'		=> '2',		# DH Group #
# 			'reserved1'	=> '0',		# RESERVED
# 			'publicKey'	=> undef	# Key Exchange Data
# 		};
		my $payload1 = {	# Notify Payload
			'self'		=> 'N',			# *** MUST BE HERE ***

			'nexttype'	=> 'IDi', 		# Next Payload
			'critical'	=> '0',			# Critical
			'reserved'	=> '0',			# RESERVED
			'length'	=> '8',			# Payload Length
			'id'		=> '0',			# Protocol ID
			'spiSize'	=> '0',			# SPI Size
			'type'		=> 'ESP_TFC_PADDING_NOT_SUPPORTED',	# Notify Type
			'spi'		=> '',			# SPI
			'data'		=> ''			# Notification Data
		};
		my $payload2 =	{	# Identification Payload - Responder
			'self'		=> 'IDr',		# *** MUST BE HERE ***

			'nexttype'	=> 'N',		# Next Payload
			'critical'	=> '0',			# Critical
			'reserved'	=> '0',			# RESERVED
			# XXX: IPV4
			#'length'	=> '24',		# Payload Length
			'length'	=> undef,
			# XXX: IPV4
			#'type'		=> 'IPV6_ADDR',		# ID Type
			'type'		=> undef,
			'reserved1'	=> '0',			# RESERVED
			'value'		=> undef,
		};
		my $payload3 = {	# Transform Substructure
			'nexttype'		=> '0',		# Next
			'reserved1'		=> '0',		# RESERVED
			'transformLen'		=> '8',		# Transform Length
			'type'			=> 'ESN',	# Transform Type
			'reserved2'		=> '0',		# RESERVED
			'id'			=> 'ESN',	# Transform ID
			'attributes'	=> [		# Transfom Attributes
			]
		};
		my $payload4 = {	# Notify Payload
			'self'		=> 'N',			# *** MUST BE HERE ***

			'nexttype'	=> 'IDi', 		# Next Payload
			'critical'	=> '0',			# Critical
			'reserved'	=> '0',			# RESERVED
			'length'	=> '8',			# Payload Length
			'id'		=> '0',			# Protocol ID
			'spiSize'	=> '0',			# SPI Size
			'type'		=> 'AUTHENTICATION_FAILED',	# Notify Type
			'spi'		=> '',			# SPI
			'data'		=> ''			# Notification Data
		};


		my $num_rcv = scalar(@{$received});
		my $num_exp = scalar(@{$expected});
		my $nexttype = 'HDR';
		for (my $i=0; $i < $num_rcv; $i++) {
			my $p0 = $received->[$i];

			printf("SELF p0(%s)\n", $nexttype);

			if ($nexttype eq 'HDR') {
				#if ($p0->{'exchType'} ne 'CREATE_CHILD_SA') {
				if ($p0->{'exchType'} ne 'IKE_AUTH') {
					last;
				}
			}
			elsif ($nexttype eq 'E') {
				my $inner = $p0->{'innerPayloads'};
				splice(@{$inner}, 0, 0, $payload1);
				$p0->{'innerType'} = 'N';
				$nexttype = $p0->{'innerType'};

				for (my $j=0; $j < scalar(@{$inner}); $j++) {
					my $p1 = $inner->[$j];
					printf("SELF p1(%s)\n", $nexttype);
					#if ($nexttype eq 'IDi') {
					#splice(@{$inner}, $j+1, 0, $payload2);
					#$p1->{'nexttype'} = 'IDr';
					#}
					if ($nexttype eq 'SA') {
						foreach my $transform (@{$p1->{'proposals'}->[0]->{'transforms'}}) {
							$transform->{'nexttype'} = 3;
						}
						push(@{$p1->{'proposals'}->[0]->{'transforms'}}, $payload3);
					}
					$nexttype = $p1->{'nexttype'};
				}
			}
			$nexttype = $p0->{'nexttype'};
		}
	}
	if (0) { # make test packet
		my $payload1 = {	# Notify Payload
			'self'		=> 'N',			# *** MUST BE HERE ***

			'nexttype'	=> '0', 		# Next Payload
			'critical'	=> '0',			# Critical
			'reserved'	=> '0',			# RESERVED
			'length'	=> '8',			# Payload Length
			'id'		=> '0',			# Protocol ID
			'spiSize'	=> '0',			# SPI Size
			'type'		=> 'AUTHENTICATION_FAILED',	# Notify Type
			'spi'		=> '',			# SPI
			'data'		=> ''			# Notification Data
		};

		if ($received->[0]->{'exchType'} eq 'IKE_AUTH') {
			splice(@{$received}, 1);
			$received->[0]->{'nexttype'} = 'N';
			push(@{$received}, $payload1);
		}
	}

	if ($enable_check_order) {
		unless (kJudgeCheckPayloadOrder($received, $expected)) {
			$result = $FALSE;
		}
	}

	# prepare & complement payloads to expected packet
	if ($enable_prepare_payloads) {
		unless (kJudgePrepareExpected($received, $expected)) {
			$result = $FALSE;
		}
	}

	return($result);
}

sub kJudgeCheckPayloadOrder($$) {
	my ($received, $expected) = @_;

	my $str = "<TR VALIGN=\"top\">\n";
	$str .= '<TD>' . kCommon::getTimeStamp() . "</TD>\n";
	$str .= '<TD>Checking Payload Order ...</TD>';
	$str .= '</TR>';
	kCommon::prLogHTML($str);

	# Informational Messages outside of an IKE_SA
	my $response = $received->[0]->{'response'};
	my $exchType = $received->[0]->{'exchType'};

	if ($exchType eq 'IKE_SA_INIT' && $response == 1) {
		if ($expected->[0]->{'nexttype'} eq 'N') {
			# omit payload order check
			return($TRUE);
		}
	}

	if ($exchType eq 'IKE_AUTH' && $response == 1) {
		if ($expected->[0]->{'nexttype'} eq 'N') {
			# omit payload order check
			return($TRUE);
		}
	}

	$is_initial_exchanges = $TRUE;

	# get expected message order to comapre with received
	if ($exchType eq 'CREATE_CHILD_SA') {
		$is_initial_exchanges = $FALSE;
		my $sa = get_payload($received, 'SA');
		if (defined($sa)) {
			my $protocol_id = $sa->{proposals}->[0]->{id};
			if ($protocol_id eq 'IKE') {
				$exchType .= '_REKEY_IKE_SA';
			}
		}
	}

	my $order = $message_order->{$exchType}->{$response};

	# setup to check payload order
	foreach my $elm (@{$order}) {
		delete($elm->{checked});
	}

	my ($result, $rcv_order, $checked) = check_payload_order($received, $expected, $order);

	my @tmp = grep {$_ ne '0'} @{$rcv_order};
	if ($result) {
		$str = "<TR VALIGN=\"top\">\n";
		$str .= '<TD></TD><TD>';
		$str .= "<b>OK</b>: Payload Order ('";
		$str .= join("', '", @tmp);
		$str .= "')</TD>";
		$str .= '</TR>';
	}
	else {
		$str = "<TR VALIGN=\"top\">\n";
		$str .= '<TD></TD><TD>';
		$str .= "<font color='#0000ff'><b>NOTE</b></font>: Payload Order ('";
		$str .= join("', '", @tmp);
		$str .= "')</TD>";
		$str .= '</TR>';
	}
	kCommon::prLogHTML($str);

	return($result);
}


sub check_payload_order($$$;$) {
	my ($received, $expected, $order, $order_index) = @_;

	my $result = $TRUE;
	my $num_rec = scalar(@{$received});
	my $num_order = scalar(@{$order});
	my $checked = (defined($order_index)) ? $order_index : 0;
	my $encrypted = $FALSE;

	my @rcv_order = ();
	push(@rcv_order, 'HDR') unless (defined($order_index));

	for (my $i = 0; $i < $num_rec; $i++) {
		my $rcv_type = $received->[$i]->{'nexttype'};
		push(@rcv_order, $rcv_type);

		if ($encrypted) {
			# follow payloads in Encrypted Payload
			$encrypted = $FALSE;

			my $rcv_e = {%{$received->[$i]}}; # cloning
			my $exp_e = {%{$expected->[$i]}}; # cloning

 			$rcv_e->{'nexttype'} = $rcv_e->{'innerType'};
 			$exp_e->{'nexttype'} = $exp_e->{'innerType'};
 			unshift(@{$received->[$i]->{'innerPayloads'}}, $rcv_e);
 			unshift(@{$expected->[$i]->{'innerPayloads'}}, $exp_e);
			my $tmp_order = undef;
 			($result, $tmp_order, $checked) = check_payload_order($received->[$i]->{'innerPayloads'},
									      $expected->[$i]->{'innerPayloads'},
									      $order,
									      $checked);
			push(@rcv_order, @{$tmp_order});
 			shift(@{$received->[$i]->{'innerPayloads'}});
 			shift(@{$expected->[$i]->{'innerPayloads'}});
 			last;
		}

		if ($rcv_type eq '0') { # last
			last;
		}
		elsif ($rcv_type eq 'V') { # Vendor ID can be inserted to any place
			next;
		}
		elsif ($rcv_type eq 'N') {
			$rcv_type .= '(' . $received->[$i + 1]->{type}  . ')';
		}
		elsif ($rcv_type eq 'E') {
			$encrypted = $TRUE;
		}

		# find payload
		my $found = $FALSE;
		for (my $j = $checked; $j < $num_order; $j++) {
			if ($rcv_type eq $order->[$j]->{type}) {
				$found = $TRUE;
				$checked = $j + 1;
				$order->[$j]->{checked} = $TRUE;
				last;
			}
		}

		unless ($found) {
			# may insert the not found payload
		}
	}

	# check remains
	foreach my $elm (@{$order}) {
		if (!$elm->{omittable} && !defined($elm->{checked})) {
			# if the received payloads is not expected, give up comparison.
			my $res = 1;
			for (my $i = 0; $i < scalar(@{$expected}); $i++) {
				my $rcv_payload = $received->[$i];
				my $exp_payload = $expected->[$i];
				unless (defined($rcv_payload) && defined($exp_payload)) {
					$res = 0;
					last;
				}

				if ($rcv_payload->{'nexttype'} ne $exp_payload->{'nexttype'}) {
					$res = 0;
					last;
				}
			}

			if ($res) {
				last;
			}

			$result = $FALSE;
			last;
		}
	}

	return($result, \@rcv_order, $checked);
}

sub kJudgePrepareExpected($$) {
	my ($received, $expected) = @_;

	my $str = "<TR VALIGN=\"top\">\n";
	$str .= '<TD>' . kCommon::getTimeStamp() . "</TD>\n";
	$str .= '<TD>Preparing Expected Packet ...</TD>';
	$str .= '</TR>';
	kCommon::prLogHTML($str);

	# check if there is SA payload
	my $complement = $FALSE;
	my $encrypted = $FALSE;
	foreach my $p0 (@{$received}) {
		my $nexttype = $p0->{'nexttype'};

		if ($encrypted) {
			$nexttype = $p0->{'innerType'};
			foreach my $p1 (@{$p0->{'innerPayloads'}}) {
				if ($nexttype eq 'SA') {
					$complement = $TRUE;
					last;
				}
				$nexttype = $p1->{'nexttype'};
			}
			last;
		}

		$encrypted = $FALSE;

		if ($nexttype eq 'SA') {
			$complement = $TRUE;
			last;
		}

		if ($nexttype eq 'E') {
			$encrypted = $TRUE;
		}
	}

	# if received message does not include SA payload,
	# the message does not need to be complemented any payload.
	unless ($complement) {
		return($TRUE);
	}

	# get expected message order to comapre with received
	my $response = $received->[0]->{response};
	my $exchType = $received->[0]->{exchType};
	if ($exchType eq 'CREATE_CHILD_SA') {
		my $sa = get_payload($received, 'SA');
		if (defined($sa)) {
			my $protocol_id = $sa->{proposals}->[0]->{id};
			if ($protocol_id ne 'IKE') {
				$exchType .= '_REKEY_IKE_SA';
			}
		}
	}

	my $order = $message_order->{$exchType}->{$response};

	my ($result, $val, $added, $modified) = prepare_expected_payloads($received, $expected, $order);
	# fix Next Payload fields
	{
		for (my $i = 0; $i < scalar(@{$expected}); $i++) {
			my $p0 = $expected->[$i];
			my $n0 = $expected->[$i+1];

			if (defined($n0)) {
				$p0->{'nexttype'} = $n0->{'self'};
			} else {
				$p0->{'nexttype'} = '0';
			}

			if ($p0->{'self'} eq 'E') {
				$p0->{'innerType'} = @{$p0->{'innerPayloads'}}[0]->{'self'};

				for (my $j = 0; $j < scalar(@{$p0->{'innerPayloads'}}); $j++) {
					my $p1 = ${$p0->{'innerPayloads'}}[$j];
					my $n1 = ${$p0->{'innerPayloads'}}[$j+1];
					if (defined($n1)) {
						$p1->{'nexttype'} = $n1->{'self'};
					} else {
						$p1->{'nexttype'} = '0';
					}
				}
			}
		}
	}
	#

	$str = "<TR VALIGN=\"top\">\n";
	$str .= '<TD></TD><TD>';

	if (scalar(@{$added}) != 0) {
		$str .= 'OK: Added Payloads:';
		$str .= '<PRE>';
		my $i = 0;
		foreach my $payload (@{$added}) {
			$str .= 'Added#'. $i++ . "\n";
			foreach my $key (keys(%{$payload})) {
				my $value = defined($payload->{$key}) ? $payload->{$key} : 'any';

				# Reformat the value if not printable or deactivate its showing if to long.
				if (!defined($value)) {
					$value = 'undef';
				} elsif ($value !~ m/^[ -~]*$/i) {
					do {
						$value = kIKE::kHelpers::formatHex(uc(unpack('H*', $value)));
					} if (length($value) <= 32);
				} else {
					if (exists($fieldsConvertFunctions{$key})) {
						my $conv = $fieldsConvertFunctions{$key};
						$value = $conv->($value, 0);
					}
				}

				$str .= "\t" . $key . ' = ' . $value . "\n";
			}
		}
		$str .= '</PRE>';
	} else {
		$str .= 'OK: No Added Payload';
		$str .= '<PRE></PRE>';
	}

	if (scalar(@{$modified}) != 0) {
		$str .= 'OK: Modified Payloads:';
		$str .= '<PRE>';
		$str .= '<PRE>';
		my $i = 0;
		foreach my $payload (@{$modified}) {
			$str .= 'Modified#'. $i++ . "\n";
			foreach my $key (keys(%{$payload})) {
				my $value = defined($payload->{$key}) ? $payload->{$key} : 'any';

				# Reformat the value if not printable or deactivate its showing if to long.
				if (!defined($value)) {
					$value = 'undef';
				} elsif ($value !~ m/^[ -~]*$/i) {
					do {
						$value = kIKE::kHelpers::formatHex(uc(unpack('H*', $value)));
					} if (length($value) <= 32);
				} else {
					if (exists($fieldsConvertFunctions{$key})) {
						my $conv = $fieldsConvertFunctions{$key};
						$value = $conv->($value, 0);
					}
				}

				$str .= "\t" . $key . ' = ' . $value . "\n";
			}
		}
		$str .= '</PRE>';
	} else {
		$str .= 'OK: No Modified Payload';
		$str .= '<PRE></PRE>';
	}
	$str .= '</TD>';
	$str .= '</TR>';
	kCommon::prLogHTML($str);

	return($result);
}


my %notificationErrorTypes = (
        UNSUPPORTED_CRITICAL_PAYLOAD => 1,
        1 => 'UNSUPPORTED_CRITICAL_PAYLOAD',
        INVALID_IKE_SPI => 4,
        4 => 'INVALID_IKE_SPI',
        INVALID_MAJOR_VERSION => 5,
        5 => 'INVALID_MAJOR_VERSION',
        INVALID_SYNTAX => 7,
        7 => 'INVALID_SYNTAX',
        INVALID_MESSAGE_ID => 9,
        9 => 'INVALID_MESSAGE_ID',
        INVALID_SPI => 11,
        11 => 'INVALID_SPI',
        NO_PROPOSAL_CHOSEN => 14,
        14 => 'NO_PROPOSAL_CHOSEN',
        INVALID_KE_PAYLOAD => 17,
        17 => 'INVALID_KE_PAYLOAD',
        AUTHENTICATION_FAILED => 24,
        24 => 'AUTHENTICATION_FAILED',
        SINGLE_PAIR_REQUIRED => 34,
        34 => 'SINGLE_PAIR_REQUIRED',
        NO_ADDITIONAL_SAS => 35,
        35 => 'NO_ADDITIONAL_SAS',
        INTERNAL_ADDRESS_FAILURE => 36,
        36 => 'INTERNAL_ADDRESS_FAILURE',
        FAILED_CP_REQUIRED => 37,
        37 => 'FAILED_CP_REQUIRED',
        TS_UNACCEPTABLE => 38,
        38 => 'TS_UNACCEPTABLE',
        INVALID_SELECTORS => 39,
        39 => 'INVALID_SELECTORS',
);
sub prepare_expected_payloads($$$) {
	my ($received, $expected, $order) = @_;

	my $result = $TRUE;
	my $num_rcv = scalar(@{$received});
	my $num_exp = scalar(@{$expected});
	my $encrypted = $FALSE;
	my @added = ();
	my @modified = ();
	my $return_innerType = undef;

	for (my $i = 0; $i < $num_rcv; $i++) {
		my $nexttype_rcv = $received->[$i]->{'nexttype'};
		my $omittable = undef;

		if ($encrypted) {
			# follow payloads in Encrypted Payload
			my $e = undef;
			$encrypted = $FALSE;

			# enable innerPayloads process
			## received
			$e = {%{$received->[$i]}}; # cloning
 			$e->{'nexttype'} = $e->{'innerType'};
 			unshift(@{$received->[$i]->{'innerPayloads'}}, $e);
			## expected
			$e = {%{$expected->[$i]}}; # cloning
 			$e->{'nexttype'} = $e->{'innerType'};
 			unshift(@{$expected->[$i]->{'innerPayloads'}}, $e);

			my $ref_array1 = undef;
			my $ref_array2 = undef;
 			($result, $return_innerType, $ref_array1, $ref_array2) =
				prepare_expected_payloads($received->[$i]->{'innerPayloads'},
							  $expected->[$i]->{'innerPayloads'},
							  $order);
			# updated by return value
			push(@added, @{$ref_array1});
			push(@modified, @{$ref_array2});
			if (defined($return_innerType)) {
				$expected->[$i]->{'modified'} = 'nexttype(' .
					$expected->[$i]->{'innerType'} . ' -> ' .
						$return_innerType . ')';

				$expected->[$i]->{'innerType'} = $return_innerType;
				push(@modified, $expected->[$i]);
			}

			# remove unnecessary payload
 			shift(@{$received->[$i]->{'innerPayloads'}});
 			shift(@{$expected->[$i]->{'innerPayloads'}});
 			last;
		}

		if ($nexttype_rcv eq '0') { # last
			last;
		}
		elsif ($nexttype_rcv eq 'V') {
			$omittable = $TRUE;
		}
		elsif ($nexttype_rcv eq 'N') {
			unless (is_defined_notify_type($received->[$i + 1]->{'type'})) {
				$omittable = $TRUE;
			}
			$nexttype_rcv .= '(' . $received->[$i + 1]->{'type'}  . ')';
		}
		elsif ($nexttype_rcv eq 'E') {
			$encrypted = $TRUE;
		}

		my $nexttype_exp = defined($expected->[$i]->{'nexttype'}) ? $expected->[$i]->{'nexttype'} : '';
		my $notify_type_error = $FALSE;
		if ($nexttype_exp eq 'N') {
			if (defined($expected->[$i + 1]->{'type'})) {
				$nexttype_exp .= '(' . $expected->[$i + 1]->{'type'}  . ')';
				foreach my $key (keys(%notificationErrorTypes)) {
					if ($key eq $expected->[$i + 1]->{'type'}) {
						$notify_type_error = $TRUE;
						last;
					}
				}
			}
		}

		# compare received one with expected one
		if ($nexttype_rcv eq $nexttype_exp) {
			# matched
			next;
		}
		# not matched

		if ($notify_type_error) {
			# not matched, but no need to complement payload
			next;
		}

		# check if omittable or not
		unless ($omittable) {
			foreach my $elm (@{$order}) {
				if ($nexttype_rcv eq $elm->{'type'}) {
					$omittable = $elm->{'omittable'};
					last;
				}
			}
		}

		unless ($omittable) {
			next;
		}

		my $add = {%{$received->[$i + 1]}}; # cloning
		my @types = split(/\(/, $nexttype_rcv); # get own payload type
		$add->{'self'} = shift(@types);

		# move backward
		for (my $j = scalar(@{$expected}) - 1; $j > $i; $j--) {
			$expected->[$j+1] = $expected->[$j];
		}

		# insert clone
		$add->{'nexttype'} = $expected->[$i]->{'nexttype'};
		$add->{'added'} = 1;
		$add->{'inserted'} = $i + 1;
		$expected->[$i + 1] = $add;
		push(@added, $add);
		$num_exp += 1;

		# update Next Payload field in previous payload
		if ($i == 0) {
			# set return value for Encrypted Payload
			$return_innerType = $received->[$i]->{'nexttype'};
		}
		else {
			$expected->[$i]->{'modified'} = 'nexttype(' .
				$expected->[$i]->{'nexttype'} . ' -> ' .
				$received->[$i]->{'nexttype'} . ')';
			$expected->[$i]->{'nexttype'} = $received->[$i]->{'nexttype'};
			push(@modified, $expected->[$i]);
		}
	}

	return($result, $return_innerType, \@added, \@modified);
}

sub convert_Math_BigInt($$) {
	my ($val, $type) = @_;

	$type = 0 unless (defined($type));
	if ($type == 1) {
		$val = '0x' . $val;
		$val = Math::BigInt->new($val);
	}

	$val = Math::BigInt->new($val);
	return($val->as_hex());
}

sub is_defined_notify_type($) {
	my ($type) = @_;

	unless ($type =~ /^[+-]?\d+$/) {
		return($FALSE);
	}

	if (0 <= $type && $type <= 39) {
		return($TRUE);
	}

	if (16384 <= $type && $type <= 16395) {
		return($TRUE);
	}

	return($FALSE);
}

1;
