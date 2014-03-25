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
# $Id: kPrint.pm,v 1.5 2010/03/09 05:56:27 velo Exp $
#
########################################################################

package kIKE::kPrint;

use strict;
use warnings;
use Exporter;
use kIKE::kConsts;

our @ISA = qw(Exporter);

our @EXPORT = qw(
	kPrint_IKEv2
);

# global variables
our $TRUE = $kIKE::kConsts::TRUE;
our $FALSE = $kIKE::kConsts::FALSE;

## for kPrint_IKE
our $DUMP = 0;
our $DUMP_STR = '';
our $DEBUG = $FALSE; # $TRUE; # 

my %printFunctions = (
	#HDR => \&kPrintIKEHeader,
	SA => \&kPrintSAPayload,
	KE => \&kPrintKEPayload,
	IDi => \&kPrintIDPayload,
	IDr => \&kPrintIDPayload,
	CERT => \&kPrintCERTPayload,
	CERTREQ => \&kPrintCERTREQPayload,
	AUTH => \&kPrintAUTHPayload,
	'Ni, Nr' => \&kPrintNirPayload,
	N => \&kPrintNPayload,
	D => \&kPrintDPayload,
#	V => \&kPrintVPayload,
	TSi => \&kPrintTSPayload,
	TSr => \&kPrintTSPayload,
	E => \&kPrintEPayload,
	CP => \&kPrintCPPayload,
#	EAP => \&kPrintEPayload,
);


# prototypes
sub kPrint_IKEv2($$);

sub kPrintIKEMessage($;$$);
sub kPrintIKEHeader($$);
sub kPrintGenericPayloadHeader($$$);
sub kPrintSAPayload($$$);
sub kPrintKEPayload($$$);
sub kPrintIDPayload($$$);
sub kPrintCERTPayload($$$);
sub kPrintCERTREQPayload($$$);
sub kPrintAUTHPayload($$$);
sub kPrintNirPayload($$$);
sub kPrintNPayload($$$);
sub kPrintTSPayload($$$);
sub kPrintEPayload($$$);
sub kPrintCPPayload($$$);
sub kPrintUndefinedPayload($$$);

sub kPrintSAProposals($$);
sub kPrintSAProposal($$);
sub kPrintSATransforms($$);
sub kPrintSATransform($$);
sub kPrintSAAttributes($$);
sub kPrintSAAttribute($$);

sub kPrintTSSelectors($$);
sub kPrintTSSelector($$);

sub kPrintCPAttributes($$);
sub kPrintCPAttribute($$);

sub dumpprintraw($$);
sub dumpprintfi($$@);
sub dumpprintf($@);
sub dumpprint($);
sub concat($;$);

# functions
sub kPrint_PrepareLog($$)
{
	my ($log, $explanation) = @_;

	foreach my $elm (@{$log}) {
		unless (ref($elm)) {
			kCommon::kLogHTML($elm);
			next;
		}
		my $str = html_pre_hash($elm, $explanation);
		kCommon::kLogHTML($str);
	}
	return;
}

sub kPrint_JudgeLog2($)
{
	my ($log) = @_;

	foreach my $elm (@{$log}) {
		unless (defined($elm)) {
			next;
		}
		unless (ref($elm)) {
			kCommon::kLogHTML($elm);
			next;
		}
		my $str = html_pre_array($elm);
		kCommon::prLogHTML("<tr VALIGN=\"top\">\n");
		kCommon::prLogHTML("<td></td>\n");
		kCommon::prLogHTML("<td width=\"100%\">$str</td>\n");
		kCommon::prLogHTML("</tr>\n");
	}
	return;
}

sub kPrint_JudgeLog($)
{
	my ($log) = @_;

	my $str = '';
	foreach my $key (sort(keys(%$log))) {
		$str .= '<pre>';
		$str .= substr($key, 2) . "\n";
		$str .= "--------------------\n";
		foreach my $elm (@{$log->{$key}}) {
			if (ref($elm) eq 'HASH') {
				foreach my $key1 (sort(keys(%{$elm}))) {
					$str .= "\n" . substr($key1, 2) ."\n";
					$str .= concat($elm->{$key1}, 1);
				}
				next;
			} elsif (ref($elm) eq 'ARRAY') {
				$str .= concat($elm);
				next;
			}
			$str .= $elm . "\n";
		}
		$str .= '</pre>';
	}
	kCommon::kLogHTML($str);
}


sub kPrint_IKEv2($$)
{
	my ($data, $dump) = @_;

	unless (defined($dump)) {
		$dump = 0;
	}

	$DUMP = $dump;
	$DUMP_STR = '';

	my $material = kIKE::kIKE::kKeyingMaterial();

	my @decoded = undef;
	my ($initiators_spi, $responders_spi) = unpack('H16 H16', $data);
	if (defined($material) &&
	    $material->{'initiators_spi'} eq $initiators_spi &&
	    $material->{'responders_spi'} eq $responders_spi) {
		@decoded = kIKE::kIKE::kParseIKEMessage($data, $material->{'keying_material'});
	}
	else {
		@decoded = kIKE::kIKE::kParseIKEMessage($data);
		@decoded = @{ kIKE::kHelpers::rebuildStructure(\@decoded) };
	}

	kPrintIKEMessage(\@decoded);

	return($DUMP_STR);
}

# static functions
sub kPrintIKEMessage($;$$)
{
	my ($message, $next_payload_type, $indent) = @_;

	if ($DEBUG) {
		printf("dbg ===> kPrintIKEMessage()\n");
	}

	$indent = 1 unless(defined($indent));

	foreach my $data (@$message) {
		if (!defined($next_payload_type)) {
			kPrintIKEHeader($data, $indent);
			$next_payload_type = $data->{nexttype};
			$indent += 2;
			next;
		}

		my $function = $printFunctions{$next_payload_type};
		unless (defined($function)) {
			kPrintUndefinedPayload($data, $next_payload_type, $indent);
			$next_payload_type = $data->{'nexttype'};
			next;
		}

		&$function($data, $next_payload_type, $indent);
		$next_payload_type = $data->{nexttype};
	}

	return;
}

sub kPrintIKEHeader($$)
{
	my ($data, $indent) = @_;

	if ($DEBUG) {
		printf("dbg ===> kPrintIKEHeader()\n");
	}

	dumpprintfi("Internet Security Association and Key Management Protocol Payload\n", $indent);
	$indent++;
	dumpprintfi("IKE Header\n", $indent);
	$indent++;
	dumpprintfi("IKE_SA Initiator's SPI         = %s\n", $indent,
		   $data->{initSPI});
	dumpprintfi("IKE_SA Responder's SPI         = %s\n", $indent,
		   $data->{respSPI});
	dumpprintfi("Next Payload                   = %s (%s)\n", $indent,
		   kPayloadType($data->{nexttype}), $data->{nexttype});
	dumpprintfi("Major Version                  = %s\n", $indent,
		   $data->{major});
	dumpprintfi("Minor Version                  = %s\n", $indent,
		   $data->{minor});
	dumpprintfi("Exchange Type                  = %s (%s)\n", $indent,
		   kExchangeType($data->{exchType}), $data->{exchType});
	dumpprintfi("Flags                          = %s (0b%08b)\n",
		    $indent,
		   $data->{flags}, $data->{flags});
	$indent++;
	dumpprintfi("Reserved  (XX000000)             = %s\n", $indent,
		   $data->{reserved1});
	dumpprintfi("Response  (00R00000)             = %s\n", $indent,
		   $data->{response});
	dumpprintfi("Version   (000V0000)             = %s\n", $indent,
		   $data->{higher});
	dumpprintfi("Initiator (0000I000)             = %s\n", $indent,
		   $data->{initiator});
	dumpprintfi("Reserved  (00000XXX)             = %s\n", $indent,
		   $data->{reserved2});
	$indent--;
	dumpprintfi("Message ID                     = %s (0x%x)\n", $indent,
		   $data->{messID}, $data->{messID});
	dumpprintfi("Length                         = %s (0x%x)\n", $indent,
		   $data->{length}, $data->{length});

	return;
}

sub kPrintGenericPayloadHeader($$$)
{
	my ($data, $payload_type, $indent) = @_;

	if ($DEBUG) {
		printf("dbg ===> kPrintGenericPayloadHeader() <%s> <%s>\n",
		       ref($data), $data);
	}

	dumpprintfi("%s Payload\n", $indent, $payload_type);
	$indent++;
	dumpprintfi("Next Payload                   = %s (%s)\n", $indent,
		    kPayloadType($data->{nexttype}), $data->{nexttype});
	dumpprintfi("Critical                       = %s\n", $indent,
		    $data->{critical});
	dumpprintfi("Reserved                       = %s\n", $indent,
		    $data->{reserved});
	dumpprintfi("Payload Length                 = %s (0x%x)\n", $indent,
		    $data->{length}, $data->{length});

	return;
}


sub kPrintSAPayload($$$)
{
	my ($data, $payload_type, $indent) = @_;

	if ($DEBUG) {
		printf("dbg ===> kPrintSAPayload() %s\n", ref($data));
	}

	# print generic header
	kPrintGenericPayloadHeader($data, $payload_type, $indent);

	$indent++;
	my $proposals = $data->{proposals};
	kPrintSAProposals($proposals, $indent);

	return;
}

sub kPrintSAProposals($$)
{
	my ($data, $indent) = @_;

	if ($DEBUG) {
		printf("dbg ===> kPrintSAProposals() %s\n", ref($data));
	}

	foreach my $proposal (@$data) {
		kPrintSAProposal($proposal, $indent);
	}

	return;
}

sub kPrintSAProposal($$)
{
	my ($data, $indent) = @_;

	if ($DEBUG) {
		printf("dbg ===> kPrintSAProposal() %s %s\n", $indent, ref($data));
	}

	dumpprintfi("Proposal #%s\n", $indent,  $data->{number});
	$indent++;
	dumpprintfi("Next Payload                   = %s (%s)\n", $indent,
		    $data->{nexttype},
		    ($data->{nexttype} == 0) ? 'last' : 'Proposal');
	dumpprintfi("RESERVED                       = %s\n", $indent,
		    $data->{reserved});
	dumpprintfi("Proposal Length                = %s\n", $indent,
		    $data->{proposalLen});
	dumpprintfi("Proposal #                     = %s\n", $indent,
		    $data->{number});
	dumpprintfi("Proposal ID                    = %s\n", $indent,
		    $data->{id});
	dumpprintfi("SPI Size                       = %s\n", $indent,
		    $data->{spiSize});
	dumpprintfi("# of Transforms                = %s\n", $indent,
		    $data->{transformCount});
	dumpprintfi("SPI                            = %s\n", $indent,
		    $data->{spi}) if ($data->{spiSize} > 0);

	my $transforms = $data->{transforms};
	kPrintSATransforms($transforms, $indent);

	return;
}

sub kPrintSATransforms($$)
{
	my ($data, $indent) = @_;

	if ($DEBUG) {
		printf("dbg ===> kPrintSAProposals() %s\n", ref($data));
	}

	foreach my $transform (@$data) {
		kPrintSATransform($transform, $indent);
	}

	return;
}

sub kPrintSATransform($$)
{
	my ($data, $indent) = @_;

	if ($DEBUG) {
		printf("dbg ===> kPrintSAProposal() %s\n", ref($data));
	}

 	dumpprintfi("Transfrom\n", $indent);
	$indent++;
	dumpprintfi("Next Payload                     = %s (%s)\n", $indent,
		    $data->{nexttype},
		    ($data->{nexttype} == 0) ? 'last' : 'Transform');
 	dumpprintfi("RESERVED                         = %s\n", $indent,
		    $data->{reserved1});
 	dumpprintfi("Transform Length                 = %s\n", $indent,
		    $data->{transformLen});
 	dumpprintfi("Transform Type                   = %s (%s)\n", $indent,
		    kTransformType($data->{type}), $data->{type});
 	dumpprintfi("RESERVED                         = %s\n", $indent,
		    $data->{reserved2});
 	dumpprintfi("Transform ID                     = %s (%s)\n", $indent,
		    kTransformTypeID(kTransformType($data->{type}), $data->{id}),
		    $data->{id});

	my $attributes = $data->{attributes};
	kPrintSAAttributes($attributes, $indent);

	return;
}

sub kPrintSAAttributes($$)
{
	my ($data, $indent) = @_;

	if ($DEBUG) {
		printf("dbg ===> kPrintSAAttributes() %s\n", ref($data));
	}

	foreach my $attribute (@$data) {
		kPrintSAAttribute($attribute, $indent);
	}

	return;
}

sub kPrintSAAttribute($$)
{
	my ($data, $indent) = @_;

	if ($DEBUG) {
		printf("dbg ===> kPrintSAAttriute() %s\n", ref($data));
	}

	$indent++;
 	dumpprintfi("Attribute\n", $indent);
	$indent++;
	dumpprintfi("Attribute Type                   = %s\n", $indent,
		    $data->{type});
	unless ($data->{'af'}) {
		dumpprintfi("Attribute Length                 = %s\n", $indent,
			    $data->{length});
	}
	dumpprintfi("Attribute Value                  = %s\n", $indent,
		    $data->{value});

	return;
}

sub kPrintKEPayload($$$)
{
	my ($data, $payload_type, $indent) = @_;

	if ($DEBUG) {
		printf("dbg ===> kPrintKEPayload() %s\n", ref($data));
	}

	# print generic header
	kPrintGenericPayloadHeader($data, $payload_type, $indent);

	$indent++;

	my $pubkey = $data->{publicKey};
	dumpprintfi("DH Group #                     = %s\n", $indent,
		    $data->{group});
	dumpprintfi("RESERVED                       = %s\n", $indent,
		    $data->{reserved1});
	dumpprintfi("Key Exchange Data              = %s\n", $indent,
		    $pubkey->as_hex);

	return;
}

sub kPrintIDPayload($$$)
{
	my ($data, $payload_type, $indent) = @_;

	if ($DEBUG) {
		printf("dbg ===> kPrintIDiPayload() %s\n", ref($data));
	}

	# print generic header
	kPrintGenericPayloadHeader($data, $payload_type, $indent);

	$indent++;

	dumpprintfi("ID Type                        = %s (%s)\n", $indent,
		    kIdentificationType($data->{'type'}), $data->{'type'});
	dumpprintfi("RESERVED                       = %s\n", $indent,
		    $data->{'reserved1'});
	if ($data->{'type'} eq 'IPV4_ADDR') {
		dumpprintfi("Identification Data            = %s (%s)\n", $indent,
			    unpack('H'. ($data->{'length'} - 8) * 2, $data->{'value'}),
			    kIKE::kHelpers::ipv4addr_tostr($data->{'value'}));
	}
	elsif ($data->{'type'} eq 'IPV6_ADDR') {
		dumpprintfi("Identification Data            = %s (%s)\n", $indent,
			    unpack('H'. ($data->{'length'} - 8) * 2, $data->{'value'}),
			    kIKE::kHelpers::ipv6addr_tostr($data->{'value'}));
	}
	else {
		dumpprintfi("Identification Data            = %s\n", $indent,
			    unpack('A'. ($data->{'length'} - 8) * 2, $data->{'value'}));
	}

	return;
}

sub kPrintCERTPayload($$$)
{
	my ($data, $payload_type, $indent) = @_;

	if ($DEBUG) {
		printf("dbg ===> kPrintICERTPayload() %s\n", ref($data));
	}

	# print generic header
	kPrintGenericPayloadHeader($data, $payload_type, $indent);

	$indent++;

	dumpprintfi("Certificate Encoding           = %s (%s)\n", $indent,
		    kCertificateEncoding($data->{'cert_encoding'}), $data->{'cert_encoding'});
	dumpprintfi("Certificate Data               = %s\n", $indent, $data->{'cert_data'});

	return;
}

sub kPrintCERTREQPayload($$$)
{
	my ($data, $payload_type, $indent) = @_;

	if ($DEBUG) {
		printf("dbg ===> kPrintICERTREQPayload() %s\n", ref($data));
	}

	# print generic header
	kPrintGenericPayloadHeader($data, $payload_type, $indent);

	$indent++;

	dumpprintfi("Certificate Encoding           = %s (%s)\n", $indent,
		    kCertificateEncoding($data->{'cert_encoding'}), $data->{'cert_encoding'});
	dumpprintfi("Certificate Authority          = %s\n", $indent, $data->{'cert_authority'});

	return;
}

sub kPrintAUTHPayload($$$)
{
	my ($data, $payload_type, $indent) = @_;

	if ($DEBUG) {
		printf("dbg ===> kPrintAUTHPayload() %s\n", ref($data));
	}

	# print generic header
	kPrintGenericPayloadHeader($data, $payload_type, $indent);

	$indent++;

	dumpprintfi("Auth Method                    = %s (%s)\n", $indent,
		    kAuthenticationMethod($data->{method}), $data->{method});
	dumpprintfi("RESERVED                       = %s\n", $indent,
		    $data->{reserved1});
	dumpprintfi("Authentication Data            = %s\n", $indent,
		    $data->{data});

	return;
}

sub kPrintNirPayload($$$)
{
	my ($data, $payload_type, $indent) = @_;

	if ($DEBUG) {
		printf("dbg ===> kPrintNirPayload() %s\n", ref($data));
	}

	# print generic header
	kPrintGenericPayloadHeader($data, $payload_type, $indent);

	$indent++;

	my $nonce = $data->{'nonce'};
	unless ($data->{'length'} > 4) {
		return;
	}

	$nonce = kIKE::kHelpers::as_hex2($nonce, ($data->{'length'} - 4) * 2);
	dumpprintfi("Nonce Data                     = %s\n", $indent,
		    $nonce);

	return;
}

sub kPrintNPayload($$$)
{
	my ($data, $payload_type, $indent) = @_;

	if ($DEBUG) {
		printf("dbg ===> kPrintNPayload() %s\n", ref($data));
	}

	# print generic header
	kPrintGenericPayloadHeader($data, $payload_type, $indent);

	$indent++;

	dumpprintfi("Protocol ID                    = %s (%s)\n", $indent,
		    $data->{'id'},
		    (kProtocolID($data->{'id'}) == 0) ? 'no relation' : kProtocolID($data->{'id'}));
	dumpprintfi("SPI Size                       = %s\n", $indent,
		    $data->{'spiSize'});
	dumpprintfi("Notify Message Type            = %s (%s)\n", $indent,
		    kNotifyType($data->{'type'}), $data->{'type'});
	dumpprintfi("SPI                            = %s\n", $indent,
		    $data->{'spi'}) if ($data->{'spiSize'} > 0);
	dumpprintfi("Notification Data              = %s,%s\n", $indent,
		    $data->{'data'}, length($data->{'data'})) if (defined($data->{'data'}) && length($data->{'data'}) > 0);

	return;
}

sub kPrintDPayload($$$)
{
	my ($data, $payload_type, $indent) = @_;

	if ($DEBUG) {
		printf("dbg ===> kPrintDPayload() %s\n", ref($data));
	}

	# print generic header
	kPrintGenericPayloadHeader($data, $payload_type, $indent);

	$indent++;

	dumpprintfi("Protocol ID                    = %s (%s)\n", $indent,
		    $data->{'id'},
		    (kProtocolID($data->{'id'}) == 0) ? 'no relation' : kProtocolID($data->{'id'}));
	dumpprintfi("SPI Size                       = %s\n", $indent,
		    $data->{'spiSize'});
	dumpprintfi("# of SPIs                      = %s\n", $indent,
		    $data->{'spiCount'});
	if ($data->{'spiSize'} > 0) {
		my $spis = $data->{'spis'};
		my $spi = undef;
		my $i = 0;
		while (($spi = substr($spis, $i * 8, 8))) {
			dumpprintfi("SPI #%d                        = %s\n", $indent,
				    $i++, $spi);
		}
	}

	return;
}

sub kPrintTSPayload($$$)
{
	my ($data, $payload_type, $indent) = @_;

	if ($DEBUG) {
		printf("dbg ===> kPrintTSPayload() %s\n", ref($data));
	}

	# print generic header
	kPrintGenericPayloadHeader($data, $payload_type, $indent);

	$indent++;

	# 
	dumpprintfi("Number of TSs                  = %s\n", $indent,
		    $data->{count});
	dumpprintfi("RESERVED                       = %s\n", $indent,
		    $data->{reserved1});

	my $tss = $data->{selectors};
	kPrintTSSelectors($tss, $indent);

	return;
}

sub kPrintTSSelectors($$)
{
	my ($data, $indent) = @_;

	if ($DEBUG) {
		printf("dbg ===> kPrintTSSelectors() %s\n", ref($data));
	}

	foreach my $ts (@$data) {
		kPrintTSSelector($ts, $indent);
	}

	return;
}

sub kPrintTSSelector($$)
{
	my ($data, $indent) = @_;

	if ($DEBUG) {
		printf("dbg ===> kPrintTSSelector() %s\n", ref($data));
	}

	dumpprintfi("Traffic Selector\n", $indent);
	$indent++;
	dumpprintfi("TS Type                        = %s (%s)\n", $indent,
		    kTrafficSelectorType($data->{'type'}), $data->{'type'});
	dumpprintfi("IP Protocol ID                 = %s (%s)\n", $indent,
		    $data->{'protocol'}, kIPProtocolID($data->{'protocol'}));
	dumpprintfi("Selector Length                = %s\n", $indent,
		    $data->{'selectorLen'});
	dumpprintfi("Start Port                     = %s\n", $indent,
		    $data->{'sport'});
	dumpprintfi("End Port                       = %s\n", $indent,
		    $data->{'eport'});
	my $format = ($data->{'type'} eq 'IPV6_ADDR_RANGE') ? 'H32' : 'H8';
	dumpprintfi("Starting Address               = %s\n", $indent,
		    unpack($format, $data->{'saddr'}));
	dumpprintfi("Ending Address                 = %s\n", $indent,
		    unpack($format, $data->{'eaddr'}));

	return;
}

sub kPrintEPayload($$$)
{
	my ($data, $payload_type, $indent) = @_;

	if ($DEBUG) {
		printf("dbg ===> kPrintEPayload() %s\n", ref($data));
	}

	# print generic header
	dumpprintfi("%s Payload\n", $indent, $payload_type);
	$indent++;
	dumpprintfi("Next Payload                   = %s (%s)\n", $indent,
		    kPayloadType($data->{innerType}), $data->{innerType});
	dumpprintfi("Critical                       = %s\n", $indent,
		    $data->{critical});
	dumpprintfi("Reserved                       = %s\n", $indent,
		    $data->{reserved});
	dumpprintfi("Payload Length                 = %s (0x%x)\n", $indent,
		    $data->{enc_paylen}, $data->{enc_paylen});

	unless (defined($data->{iv})) {
		# impossible to decrypt
		$indent++;
		dumpprintfi("Raw Data\n", $indent);
		$indent++;
		dumpprintraw($data->{enc_data}, $indent);
		return;
	}

	# possible to decrypt
	dumpprintfi("Initialization Vector          = %s\n", $indent,
		    unpack('H'. (2 * length($data->{iv})), $data->{iv}));

	dumpprintfi("Encrypted IKE Payloads\n", $indent);
	$indent++;
	# print encrypted IKE payloads
	kPrintIKEMessage($data->{innerPayloads}, $data->{innerType}, $indent);

	$indent--;
	dumpprintfi("Integrity Checksum Data        = %s\n", $indent,
		    unpack('H'. (2 * length($data->{checksum})),
			   $data->{checksum}));

	return;
}

sub kPrintCPPayload($$$)
{
	my ($data, $payload_type, $indent) = @_;

	if ($DEBUG) {
		printf("dbg ===> kPrintCPPayload() %s\n", ref($data));
	}

	# print generic header
	kPrintGenericPayloadHeader($data, $payload_type, $indent);

	$indent++;

	#
	dumpprintfi("CFG Type                       = %s (%s)\n", $indent,
		    kConfigurationType($data->{'cfg_type'}), $data->{'cfg_type'});
	dumpprintfi("RESERVED                       = %s\n", $indent,
		    $data->{'reserved1'});

	my $attributes = $data->{'attributes'};
	kPrintCPAttributes($attributes, $indent);

	return;
}

sub kPrintCPAttributes($$)
{
	my ($attributes, $indent) = @_;

	if ($DEBUG) {
		printf("dbg ===> kPrintCPAttributes()\n");
	}

	foreach my $attribute (@{$attributes}) {
		kPrintCPAttribute($attribute, $indent);
	}

	return;
}

sub kPrintCPAttribute($$)
{
	my ($data, $indent) = @_;

	if ($DEBUG) {
		printf("dbg ===> kPrintCPAttribute()\n");
	}

	dumpprintfi("Configuraiton Attribute\n", $indent);
	$indent++;
	dumpprintfi("RESERVED                       = %s\n", $indent,
		    $data->{'reserved'});
	dumpprintfi("Attribute Type                 = %s (%s)\n", $indent,
		    kConfAttributeType($data->{'attr_type'}), $data->{'attr_type'});
	dumpprintfi("Length                         = %s\n", $indent,
		    $data->{'length'});
	if ($data->{'length'} > 0) {
		dumpprintfi("Value                          = %s\n", $indent,
			    $data->{'value'});
	}

	return;
}

sub kPrintUndefinedPayload($$$)
{
	my ($data, $payload_type, $indent) = @_;

	if ($DEBUG) {
		printf("dbg ===> kPrintUndefinedPayload() %s\n", ref($data));
	}

	dumpprintfi("UNDEFINED Payload (type(%s))\n", $indent, $payload_type);
	$indent++;
	dumpprintfi("Next Payload                   = %s (%s)\n", $indent,
		    kPayloadType($data->{nexttype}), $data->{nexttype});
	dumpprintfi("Critical                       = %s\n", $indent,
		    $data->{critical});
	dumpprintfi("Reserved                       = %s\n", $indent,
		    $data->{reserved});
	dumpprintfi("Payload Length                 = %s (0x%x)\n", $indent,
		    $data->{length}, $data->{length});

	return;
}


sub concat($;$)
{
	my ($arrayref, $indent) = @_;

	unless (defined($indent)) {
		$indent = 0;
	}

	my @array = @{$arrayref};
	my $str = "--------------------\n";
	foreach my $elm (@array) {
		if (ref($elm) eq 'ARRAY') {
			$str .= concat($elm, $indent++);
			next;
		}
		$str .= $elm . "\n";
	}

	return($str);
}

sub indent($) {
	my ($indent) = @_;

	my $str = '';
	while ($indent-- > 0) { $str .= '| '; }
	return($str);
}

sub dumpprintraw($$) {
	my ($data, $indent) = @_;

	my $prefix = indent($indent);
	my $str = $prefix;

	my @array = unpack("C*", $data);
	for (my $i = 0; $i <= $#array; ) {
		$str .= sprintf("%02x", $array[$i++]);
		unless ($i % 32) {
			$str .= "\n". $prefix;
			next;
		}
		unless ($i % 8) {
			$str .= '  ';
			next;
		}
		unless ($i % 4) {
			$str .= ' ';
			next;
		}
	}
	$str .= "\n";

	dumpprint($str);

	return;
}

sub dumpprintfi($$@) {
	my ($format, $indent, @args) = @_;

	$format = indent($indent) . $format;
	dumpprintf($format, @args);
}

sub dumpprintf($@) {
	my ($format, @args) = @_;

	my $str = sprintf($format, @args);
	dumpprint($str);
}

sub dumpprint($) {
	my ($str) = @_;

	if ($DUMP) {
		$DUMP_STR .= $str;
	}
	else {
		print($str);
	}
}

sub dumprawdata($)
{
	my ($data) = @_;

	my $str	= '';
	$str .= "| IKE raw data\n";
	$str .= "| | data                       = ";

	my @array = unpack("C*", $data);

	for(my $d = 0; $d <= $#array; $d ++) {
		for( ; ; ) {
			unless($d % 32) {
				$str .= "\n| |   ";
				last;
			}

			unless($d % 8) {
				$str .= '  ';
				last;
			}

			unless($d % 4) {
				$str .= ' ';
				last;
			}

			last;
		}

		$str .= sprintf("%02x", $array[$d]);
	}

	$str .= "\n";

	return($str);
}

sub html_bold($)
{
	my ($str) = @_;
	return('<b>' . $str . '</b>');
}

sub html_pre_array($;$)
{
	my ($log, $explanation) = @_;

	my $str = '<pre>';
	$str .= $explanation if (defined($explanation));
	$str .= "\n";
	foreach my $elm (@{$log}) {
		#debug("kPrint_Payload: $elm\n");
		$str .= $elm . "\n";
	}
	$str .= '</pre>';

	return($str);
}

sub html_pre_hash($;$)
{
	my ($log, $explanation) = @_;

	my $str = '<pre>';
	$str .= $explanation if (defined($explanation));
	$str .= "\n";
	foreach my $key (keys(%{$log})) {
		my $value = $log->{$key};
		if ($value !~ m/^[ -~]*$/i) {
			do {
				$value = kIKE::kHelpers::formatHex(uc(unpack('H*', $value)));
			} if (length($value) <= 32);
		}
		$str .= "\t" . $key ." = " . $value . "\n";
	}
	$str .= '</pre>';

	return($str);
}


1;
