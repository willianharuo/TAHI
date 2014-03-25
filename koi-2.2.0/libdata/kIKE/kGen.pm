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
# $TAHI: koi/libdata/kIKE/kGen.pm,v 0.1 2007/07/09 09:40:00 pierrick Exp $
#
# $Id: kGen.pm,v 1.7 2010/07/22 12:41:17 velo Exp $
#
########################################################################

package kIKE::kGen;

use strict;
use warnings;
use Exporter;
use Math::BigInt;
use kIKE::kConsts;
use kIKE::kHelpers;
use kIKE::kEncryptionMaterial;
use Crypt::Random qw( makerandom makerandom_octet );
use Crypt::OpenSSL::Random;
use Crypt::OpenSSL::RSA;
use Crypt::OpenSSL::X509;


our @ISA = qw(Exporter kIKE::kConsts);

our @EXPORT = qw (
	kGenIKEv2
	kCalcAuthenticationData

	kGenIKEHeader
	kGenSecurityAssociationPayload
	kGenSAProposal
	kGenSATransform
	kGenSAAttribute
	kGenKeyExchangePayload
	kGenIdentificationPayload
	kGenCertificatePayload
	kGenCertificateRequestPayload
	kGenAuthenticationPayload
	kGenNoncePayload
	kGenNotifyPayload
	kGenDeletePayload
	kGenVendorIDPayload
	kGenTrafficSelectorPayload
	kGenTSSelector
	kGenEncryptedPayload
	kGenEncryptedPayloadChecksum
	kGenEAPPayload
);

our $TRUE = $kIKE::kConsts::TRUE;
our $FALSE = $kIKE::kConsts::FALSE;

=pod

=head1 NAME

kIKE::kGen - Message generation provider for IKEv2 test scripts.

=head1 SYNOPSIS

 use kIKE::kGen;
 push @ISA, 'kIKE::kGen';

=head1 METHODS

This package contains subs to generate IKEv2 Messages. The subs are writen to
help script author not to have to memorize payloads types.

To create a Message you must start from the last payload, not specifying
optional 'next payload' parameters. All these subs returns at least two
values except for the main header, substructure generation and helper subs.
These values are first explained in the kGenGenericPayloadHeader() function.

All message generation methods follow the following parameter model:

=over

=item *

Header & data parameters which are all mandatory.

=item *

Next payload type and data which are all optional. Both must be set if used.

=back

You should be interested by using C<kBuild*> functions in
L<the kIKE::kIKE module|kIKE::kIKE/kBuildIKESecurityAssociationInitializationRequest()>
to do this work automatically.

=cut

#####################################
# Message generation sub prototypes #
#####################################

sub kGenIKEv2($;$$);
sub kEncSecurityAssociationPayload($$);
sub kEncProposalSubstructure($$$);
sub kEncTransformSubstructure($$);
sub kEncKeyExchangePayload($$);
sub kEncIdentificationPayloads($$);
sub kEncIdentificationPayloads_ANY($$);
sub kEncIdentificationPayloads_IPV6_ADDR($$);
sub kEncCertificationPayload($$);
sub kEncCertificationRequestPayload($$);
sub kEncAuthenticationPayload($$);
sub kCalcAuthenticationData($$$$$$$$$);
sub kEncNoncePayload($$);
sub kEncNotifyPayload($$);
sub kEncTrafficSelectorPayload($$);
sub kEncTrafficSelector($);
sub kEncTrafficSelector_ANY($$);
sub kEncTrafficSelector_TS_IPV4_ADDR_RANGE($);
sub kEncTrafficSelector_TS_IPV6_ADDR_RANGE($);
sub kEncEncryptedPayload($$$$$);
sub kEncConfigurationPayload($$);

sub kGenIKEHeader($$$$$$$$$;$$);
sub kGenGenericPayloadHeader($$$$);
sub kGenSecurityAssociationPayload($;$$);
sub kGenSAProposal($$$$$$;$);
sub kGenSATransform($$$;$);
sub kGenSAAttribute($$;$);
sub kGenKeyExchangePayload($$;$$);
sub kGenIdentificationPayload($$$;$$);
sub kGenCertificatePayload($$;$$);
sub kGenCertificateRequestPayload($$;$$);
sub kGenAuthenticationPayload($$$$$$$;$$);
sub kGenNoncePayload(;$$);
sub kGenNotifyPayload($$$$$;$$);
sub kGenDeletePayload($$$$;$$);
sub kGenVendorIDPayload($;$$);
sub kGenTrafficSelectorPayload($$$;$$);
sub kGenTSSelector($$$$$$;$);
sub kGenEncryptedPayload($$;$$);
sub kGenEncryptedPayloadChecksum($$$);
sub kGenEAPPayload($$$$;$$);



my %encodingFunctions = (
	'SA'		=> \&kEncSecurityAssociationPayload,
	'KE'		=> \&kEncKeyExchangePayload,
	'IDi'		=> \&kEncIdentificationPayloads,
	'IDr'		=> \&kEncIdentificationPayloads,
	'CERT'		=> \&kEncCertificationPayload,
	'CERTREQ'	=> \&kEncCertificationRequestPayload,
	'AUTH'		=> \&kEncAuthenticationPayload,
	'Ni, Nr'	=> \&kEncNoncePayload,
	'N'			=> \&kEncNotifyPayload,
	'D'			=> \&kEncDeletePayload,
	'TSi'		=> \&kEncTrafficSelectorPayload,
	'TSr'		=> \&kEncTrafficSelectorPayload,
	'CP'		=> \&kEncConfigurationPayload,
	'UNDEFINED'	=> \&kEncUndefinedPayload,
);



sub
kGenIKEv2($;$$)
{
	my ($def, $material, $is_initiator) = @_;

	my $raw = undef;
	my $self = $def->[0];
	my $next = undef;
	my $plaintext = undef;
	my $enc = undef;
	my $checksum = undef;

	for(my $d = 1; $d <= $#$def; $d ++) {
		if($def->[$d]->{'self'} eq 'E') {
			if(defined($enc)) {
				kCommon::kLogHTML('<FONT COLOR="#ff0000" SIZE="7"><U><B>'.
					'bug: must not reach here.</B></U></FONT>');

				return(undef);
			}

			$enc = $d;
			if (defined($def->[$d]->{'checksum'}) && ($def->[$d]->{'checksum'} !~ /^\s*auto\s*$/i)) {
				$checksum = pack('H*', $def->[$d]->{'checksum'});
			}
			next;
		}

		unless(defined($encodingFunctions{$def->[$d]->{'self'}})) {
			kCommon::kLogHTML('<FONT COLOR="#ff0000" SIZE="7"><U><B>'.
				'bug: must not reach here.</B></U></FONT>');

			return(undef);
		}

		my $nexttype = undef;
		if ($d + 1 <= $#$def) {
			$nexttype = ($def->[$d + 1]->{'self'} eq 'UNDEFINED') ?
					$def->[$d + 1]->{'type'} :
					kPayloadType($def->[$d + 1]->{'self'});
		}
		else {
			$nexttype = 0;
		}

		if(defined($enc)) {
			$plaintext .= &{$encodingFunctions{$def->[$d]->{'self'}}}($def->[$d], $nexttype);
			next;
		}

		$next .= &{$encodingFunctions{$def->[$d]->{'self'}}}($def->[$d], $nexttype);
	}

	if(defined($enc)) {
		my $nexttype = undef;
		if ($enc + 1 <= $#$def) {
			$nexttype = ($def->[$enc + 1]->{'self'} eq 'UNDEFINED') ?
					$def->[$enc + 1]->{'type'} :
					kPayloadType($def->[$enc + 1]->{'self'});
		}
		else {
			$nexttype = 0;
		}

		$next .= kEncEncryptedPayload($def->[$enc], $nexttype, $material, $is_initiator, $plaintext);
	}

	my $initSPI =
		(defined($self->{'initSPI'}) && ($self->{'initSPI'} !~ /^\s*auto\s*$/i))?
			$self->{'initSPI'}:
			0;
	my $respSPI =
		(defined($self->{'respSPI'}) && ($self->{'respSPI'} !~ /^\s*auto\s*$/i))?
			$self->{'respSPI'}:
			0;
	my $nexttype =
		(defined($self->{'nexttype'}) && ($self->{'nexttype'} !~ /^\s*auto\s*$/i))?
			kPayloadType($self->{'nexttype'}):
			defined($next)?
				((($def->[1]->{'self'}) eq 'UNDEFINED') ? $def->[1]->{'type'} :
				 kPayloadType($def->[1]->{'self'})) :
				0;
	my $major =
		(defined($self->{'major'}) && ($self->{'major'} !~ /^\s*auto\s*$/i))?
			$self->{'major'}:
			2;
	my $minor =
		(defined($self->{'minor'}) && ($self->{'minor'} !~ /^\s*auto\s*$/i))?
			$self->{'minor'}:
			0;
	my $exchType =
		(defined($self->{'exchType'}) && ($self->{'exchType'} !~ /^\s*auto\s*$/i))?
			kExchangeType($self->{'exchType'}):
			0;
	my $reserved1 =
		(defined($self->{'reserved1'}) && ($self->{'reserved1'} !~ /^\s*auto\s*$/i))?
			$self->{'reserved1'}:
			0;
	my $response =
		(defined($self->{'response'}) && ($self->{'response'} !~ /^\s*auto\s*$/i))?
			$self->{'response'}:
			0;
	my $higher =
		(defined($self->{'higher'}) && ($self->{'higher'} !~ /^\s*auto\s*$/i))?
			$self->{'higher'}:
			0;
	my $initiator =
		(defined($self->{'initiator'}) && ($self->{'initiator'} !~ /^\s*auto\s*$/i))?
			$self->{'initiator'}:
			0;
	my $reserved2 =
		(defined($self->{'reserved2'}) && ($self->{'reserved2'} !~ /^\s*auto\s*$/i))?
			$self->{'reserved2'}:
			0;
	my $messID =
		(defined($self->{'messID'}) && ($self->{'messID'} !~ /^\s*auto\s*$/i))?
			$self->{'messID'}:
			0;
	my $length =
		(defined($self->{'length'}) && ($self->{'length'} !~ /^\s*auto\s*$/i))?
			$self->{'length'}:
			defined($next)?
				28 + length($next):
				28;

	$raw = pack('H16 H16 C C C C N N',
		$initSPI,
		$respSPI,
		$nexttype,
		$major << 4 | $minor,
		$exchType,
		$reserved1 << 6 | $response << 5 | $higher << 4 | $initiator << 3 | $reserved2,
		$messID,
		$length);

	if(defined($next)) {
		$raw .= $next;
	}

	if (defined($checksum)) {
		$raw = substr($raw, 0, length($raw) - $material->binteg);
		$raw = $raw . $checksum;
	}
	elsif (defined($enc)) {
		$raw = kGenEncryptedPayloadChecksum($material, $is_initiator, $raw);
	}
	return($raw);
}



sub
kEncSecurityAssociationPayload($$)
{
	my ($self, $next) = @_;

	my $raw = undef;
	my $payload = undef;

	my $proposals =
		(defined($self->{'proposals'}) && ($self->{'proposals'} !~ /^\s*auto\s*$/i))?
			$self->{'proposals'}:
			undef;

	if(defined($proposals)) {
		if(ref($proposals) ne 'ARRAY') {
			kCommon::kLogHTML('<FONT COLOR="#ff0000" SIZE="7"><U><B>'.
				'bug: must not reach here.</B></U></FONT>');

			return(undef);
		}

		for(my $d = 0; $d <= $#$proposals; $d ++) {
			if(ref($proposals->[$d]) ne 'HASH') {
				kCommon::kLogHTML('<FONT COLOR="#ff0000" SIZE="7"><U><B>'.
					'bug: must not reach here.</B></U></FONT>');

				return(undef);
			}
		}

		for(my $d = 0; $d <= $#$proposals; $d ++) {
			$payload .= kEncProposalSubstructure($proposals->[$d], ($d + 1 <= $#$proposals)? 2: 0, $d + 1);
		}
	}

	my $nexttype =
		(defined($self->{'nexttype'}) && ($self->{'nexttype'} !~ /^\s*auto\s*$/i))?
			kPayloadType($self->{'nexttype'}):
			$next;
	my $critical =
		(defined($self->{'critical'}) && ($self->{'critical'} !~ /^\s*auto\s*$/i))?
			$self->{'critical'}:
			0;
	my $reserved =
		(defined($self->{'reserved'}) && ($self->{'reserved'} !~ /^\s*auto\s*$/i))?
			$self->{'reserved'}:
			0;
	my $length =
		(defined($self->{'length'}) && ($self->{'length'} !~ /^\s*auto\s*$/i))?
			$self->{'length'}:
			defined($payload)?
				4 + length($payload):
				4;

	$raw = pack('C C n',
		$nexttype,
		$critical << 7 | $reserved,
		$length);

	if($payload) {
		$raw .= $payload;
	}

	return($raw);
}



sub
kEncProposalSubstructure($$$)
{
	my ($self, $next, $index) = @_;

	my $raw = undef;
	my $transform = undef;
	my $variable = 0;



	my $spi =
		(defined($self->{'spi'}) && ($self->{'spi'} !~ /^\s*auto\s*$/i))?
			pack('H*', $self->{'spi'}):
			undef;
	my $transforms =
		(defined($self->{'transforms'}) && ($self->{'transforms'} !~ /^\s*auto\s*$/i))?
			$self->{'transforms'}:
			undef;

	if(defined($transforms)) {
		if(ref($transforms) ne 'ARRAY') {
			kCommon::kLogHTML('<FONT COLOR="#ff0000" SIZE="7"><U><B>'.
				'bug: must not reach here.</B></U></FONT>');

			return(undef);
		}

		for(my $d = 0; $d <= $#$transforms; $d ++) {
			if(ref($transforms->[$d]) ne 'HASH') {
				kCommon::kLogHTML('<FONT COLOR="#ff0000" SIZE="7"><U><B>'.
					'bug: must not reach here.</B></U></FONT>');

				return(undef);
			}
		}

		for(my $d = 0; $d <= $#$transforms; $d ++) {
			$transform .= kEncTransformSubstructure($transforms->[$d], ($d + 1 <= $#$transforms)? 3: 0);
		}
	}

	if(defined($spi)) {
		$variable += length($spi);
	}

	if(defined($transform)) {
		$variable += length($transform);
	}

	my $nexttype =
		(defined($self->{'nexttype'}) && ($self->{'nexttype'} !~ /^\s*auto\s*$/i))?
			$self->{'nexttype'}:
			$next;
	my $reserved =
		(defined($self->{'reserved'}) && ($self->{'reserved'} !~ /^\s*auto\s*$/i))?
			$self->{'reserved'}:
			0;
	my $proposalLen =
		(defined($self->{'proposalLen'}) && ($self->{'proposalLen'} !~ /^\s*auto\s*$/i))?
			$self->{'proposalLen'}:
			8 + $variable;
	my $number =
		(defined($self->{'number'}) && ($self->{'number'} !~ /^\s*auto\s*$/i))?
			$self->{'number'}:
			$index;
	my $id =
		(defined($self->{'id'}) && ($self->{'id'} !~ /^\s*auto\s*$/i))?
			kProtocolID($self->{'id'}):
			0;
	my $spiSize =
		(defined($self->{'spiSize'}) && ($self->{'spiSize'} !~ /^\s*auto\s*$/i))?
			$self->{'spiSize'}:
			defined($spi)?
				length($spi):
				0;
	my $transformCount =
		(defined($self->{'transformCount'}) && ($self->{'transformCount'} !~ /^\s*auto\s*$/i))?
			$self->{'transformCount'}:
			$#$transforms + 1;

	$raw = pack('C C n C C C C',
		$nexttype,
		$reserved,
		$proposalLen,
		$number,
		$id,
		$spiSize,
		$transformCount);

	if($spi) {
		$raw .= $spi;
	}

	if($transform) {
		$raw .= $transform;
	}

	return($raw);
}



sub
kEncTransformSubstructure($$)
{
	my ($self, $next) = @_;

	my $raw = undef;
	my $attribute = undef;

	my $attributes =
		(defined($self->{'attributes'}) && ($self->{'attributes'} !~ /^\s*auto\s*$/i))?
			$self->{'attributes'}:
			undef;

	if(defined($attributes)) {
		if (ref($attributes) ne 'ARRAY') {
			kCommon::kLogHTML('<FONT COLOR="#ff0000" SIZE="7"><U><B>'.
				'bug: must not reach here. attributes must be ARRAY.</B></U></FONT>');

			return(undef);
		}

		for (my $d = 0; $d <= $#$attributes; $d++) {
			if (ref($attributes->[$d] ne 'HASH')) {
				kCommon::kLogHTML('<FONT COLOR="#ff0000" SIZE="7"><U><B>'.
					'bug: must not reach here.</B></U></FONT>');

				return(undef);
			}
		}

		for (my $d = 0; $d <= $#$attributes; $d++) {
			$attribute .= kEncAttributeSubstructure($attributes->[$d]);
		}
	}


	my $nexttype =
		(defined($self->{'nexttype'}) && ($self->{'nexttype'} !~ /^\s*auto\s*$/i))?
			$self->{'nexttype'}:
			$next;
	my $reserved1 =
		(defined($self->{'reserved1'}) && ($self->{'reserved1'} !~ /^\s*auto\s*$/i))?
			$self->{'reserved1'}:
			0;
	my $transformLen =
		(defined($self->{'transformLen'}) && ($self->{'transformLen'} !~ /^\s*auto\s*$/i))?
			$self->{'transformLentransformLen'}:
			defined($attribute)?
				8 + length($attribute):
				8;
	my $type =
		(defined($self->{'type'}) && ($self->{'type'} !~ /^\s*auto\s*$/i))?
			kTransformType($self->{'type'}):
			0;
	my $reserved2 =
		(defined($self->{'reserved2'}) && ($self->{'reserved2'} !~ /^\s*auto\s*$/i))?
			$self->{'reserved2'}:
			0;
	my $id =
		(defined($self->{'id'}) && ($self->{'id'} !~ /^\s*auto\s*$/i))?
			kTransformTypeID($type, $self->{'id'}):
			0;

	$raw = pack('C C n C C n',
		$nexttype,
		$reserved1,
		$transformLen,
		$type,
		$reserved2,
		$id);

	if(defined($attribute)) {
		$raw .= $attribute;
	}

	return($raw);
}



sub
kEncAttributeSubstructure($)
{
	my ($self) = @_;

	my $raw = undef;

	my $af =
		(defined($self->{'af'}) && ($self->{'af'} !~ /^\s*auto\s*$/i))?
			$self->{'af'}:
			1;

	my $type =
		(defined($self->{'type'}) && ($self->{'type'} !~ /^\s*auto\s*$/i))?
			kAttributeType($self->{'type'}):
			0;

	$type = $type | ($af << 15);

	if ($af) {
		my $value =
			(defined($self->{'value'}) && ($self->{'value'} !~ /^\s*auto\s*$/i))?
				$self->{'value'}:
				0;

		$raw = pack('n n', $type, $value);
	}
	else {
		my $length =
			(defined($self->{'length'}) && ($self->{'length'} !~ /^\s*auto\s*$/i))?
				$self->{'length'}:
				0;
		my $value =
			(defined($self->{'value'}) && ($self->{'value'} !~ /^\s*auto\s*$/i))?
				$self->{'value'}:
				0;

		$raw = pack('n n H*', $type, $length, $value);
	}

	return($raw);
}



sub
kEncKeyExchangePayload($$)
{
	my ($self, $next) = @_;

	my $raw = undef;

	my $nexttype =
		(defined($self->{'nexttype'}) && ($self->{'nexttype'} !~ /^\s*auto\s*$/i))?
			kPayloadType($self->{'nexttype'}):
			$next;
	my $critical =
		(defined($self->{'critical'}) && ($self->{'critical'} !~ /^\s*auto\s*$/i))?
			$self->{'critical'}:
			0;
	my $reserved =
		(defined($self->{'reserved'}) && ($self->{'reserved'} !~ /^\s*auto\s*$/i))?
			$self->{'reserved'}:
			0;
	my $length =
		(defined($self->{'length'}) && ($self->{'length'} !~ /^\s*auto\s*$/i))?
			$self->{'length'}:
			8;
	my $group =
		(defined($self->{'group'}) && ($self->{'group'} !~ /^\s*auto\s*$/i))?
			kTransformTypeID(kTransformType('D-H'), $self->{'group'}):
			0;
	my $reserved1 =
		(defined($self->{'reserved1'}) && ($self->{'reserved1'} !~ /^\s*auto\s*$/i))?
			$self->{'reserved1'}:
			0;
	my $publicKey =
		(defined($self->{'publicKey'}) && ($self->{'publicKey'} !~ /^\s*auto\s*$/i))?
			$self->{'publicKey'}:
			undef;

	if(defined($publicKey)) {
		$length += length($publicKey) / 2;
	}

	$raw = pack('C C n n n',
		$nexttype,
		$critical << 7 | $reserved,
		$length,
		$group,
		$reserved1);

	if(defined($publicKey)) {
		$raw .= pack('H*', $publicKey);
	}

	return($raw);
}



sub
kEncIdentificationPayloads($$)
{
	my ($self, $next) = @_;

	my $raw = undef;

	my $type =
		(defined($self->{'type'}) && ($self->{'type'} !~ /^\s*auto\s*$/i))?
			kIdentificationType($self->{'type'}):
			0;

	if ($type == 1) {	# ID_IPV4_ADDR
		return(kEncIdentificationPayloads_IPV4_ADDR($self, $next));
	}
	elsif ($type == 5) {	# ID_IPV6_ADDR
		return(kEncIdentificationPayloads_IPV6_ADDR($self, $next));
	}

	return(kEncIdentificationPayloads_ANY($self, $next));
}



sub
kEncIdentificationPayloads_ANY($$)
{
	my ($self, $next) = @_;

	my $raw = undef;

	my $nexttype =
		(defined($self->{'nexttype'}) && ($self->{'nexttype'} !~ /^\s*auto\s*$/i))?
			kPayloadType($self->{'nexttype'}):
			$next;
	my $critical =
		(defined($self->{'critical'}) && ($self->{'critical'} !~ /^\s*auto\s*$/i))?
			$self->{'critical'}:
			0;
	my $reserved =
		(defined($self->{'reserved'}) && ($self->{'reserved'} !~ /^\s*auto\s*$/i))?
			$self->{'reserved'}:
			0;
	my $length =
		(defined($self->{'length'}) && ($self->{'length'} !~ /^\s*auto\s*$/i))?
			$self->{'length'}:
			8;
	my $type =
		(defined($self->{'type'}) && ($self->{'type'} !~ /^\s*auto\s*$/i))?
			kIdentificationType($self->{'type'}):
			0;
	my $reserved1 =
		(defined($self->{'reserved1'}) && ($self->{'reserved1'} !~ /^\s*auto\s*$/i))?
			$self->{'reserved1'}:
			0;
	my $value =
		(defined($self->{'value'}) && ($self->{'value'} !~ /^\s*auto\s*$/i))?
			$self->{'value'}:
			undef;

	if(defined($value)) {
		$length += length($value);
	}

	$raw = pack('C C n C C n',
		$nexttype,
		$critical << 7 | $reserved,
		$length,
		$type,
		$reserved1 >> 16 & 0xffff,
		$reserved1 & 0xffff);

	if(defined($value)) {
		$raw .= pack('A*', $value);
	}

	return($raw);
}



sub
kEncIdentificationPayloads_IPV6_ADDR($$)
{
	my ($self, $next) = @_;

	my $raw = undef;

	my $nexttype =
		(defined($self->{'nexttype'}) && ($self->{'nexttype'} !~ /^\s*auto\s*$/i))?
			kPayloadType($self->{'nexttype'}):
			$next;
	my $critical =
		(defined($self->{'critical'}) && ($self->{'critical'} !~ /^\s*auto\s*$/i))?
			$self->{'critical'}:
			0;
	my $reserved =
		(defined($self->{'reserved'}) && ($self->{'reserved'} !~ /^\s*auto\s*$/i))?
			$self->{'reserved'}:
			0;
	my $length =
		(defined($self->{'length'}) && ($self->{'length'} !~ /^\s*auto\s*$/i))?
			$self->{'length'}:
			24;
	my $reserved1 =
		(defined($self->{'reserved1'}) && ($self->{'reserved1'} !~ /^\s*auto\s*$/i))?
			$self->{'reserved1'}:
			0;
	my $value = undef;
	if (defined($self->{'value'}) && ($self->{'value'} !~ /^\s*auto\s*$/i)) {
		$value = ipaddr_tobin($self->{'value'});
		unless (defined($value)) {
			$value = $self->{'value'};
		};
	}
	else {
		$value = ipaddr_tobin('::');
	}

	$raw = pack('C C n C C n',
		$nexttype,
		$critical << 7 | $reserved,
		$length,
		5,
		$reserved1 >> 16 & 0xffff,
		$reserved1 & 0xffff);

	$raw .= $value;

	return($raw);
}



sub
kEncIdentificationPayloads_IPV4_ADDR($$)
{
	my ($self, $next) = @_;

	my $raw = undef;

	my $nexttype =
		(defined($self->{'nexttype'}) && ($self->{'nexttype'} !~ /^\s*auto\s*$/i))?
			kPayloadType($self->{'nexttype'}):
			$next;
	my $critical =
		(defined($self->{'critical'}) && ($self->{'critical'} !~ /^\s*auto\s*$/i))?
			$self->{'critical'}:
			0;
	my $reserved =
		(defined($self->{'reserved'}) && ($self->{'reserved'} !~ /^\s*auto\s*$/i))?
			$self->{'reserved'}:
			0;
	my $length =
		(defined($self->{'length'}) && ($self->{'length'} !~ /^\s*auto\s*$/i))?
			$self->{'length'}:
			12;
	my $reserved1 =
		(defined($self->{'reserved1'}) && ($self->{'reserved1'} !~ /^\s*auto\s*$/i))?
			$self->{'reserved1'}:
			0;
	my $value =
		(defined($self->{'value'}) && ($self->{'value'} !~ /^\s*auto\s*$/i))?
			ipaddr_tobin($self->{'value'}):
			ipaddr_tobin('0.0.0.0');

	$raw = pack('C C n C C n',
		$nexttype,
		$critical << 7 | $reserved,
		$length,
		1,
		$reserved1 >> 16 & 0xffff,
		$reserved1 & 0xffff);

	$raw .= $value;

	return($raw);
}



sub
kEncCertificationPayload($$)
{
	my ($self, $next) = @_;

	my $raw = undef;

	my $nexttype =
		(defined($self->{'nexttype'}) && ($self->{'nexttype'} !~ /^\s*auto\s*$/i))?
			kPayloadType($self->{'nexttype'}):
			$next;
	my $critical =
		(defined($self->{'critical'}) && ($self->{'critical'} !~ /^\s*auto\s*$/i))?
			$self->{'critical'}:
			0;
	my $reserved =
		(defined($self->{'reserved'}) && ($self->{'reserved'} !~ /^\s*auto\s*$/i))?
			$self->{'reserved'}:
			0;
	my $length =
		(defined($self->{'length'}) && ($self->{'length'} !~ /^\s*auto\s*$/i))?
			$self->{'length'}:
			5;
	my $cert_encoding =
		(defined($self->{'cert_encoding'}) && ($self->{'cert_encoding'} !~ /^\s*auto\s*$/i))?
			kCertificateEncoding($self->{'cert_encoding'}):
			0;
	my $cert_data =
		(defined($self->{'cert_data'}) && ($self->{'cert_data'} !~ /^\s*auto\s*$/i))?
			$self->{'cert_data'}:
			undef;

	if(defined($cert_data)) {
		$cert_data = pack('H*', $cert_data);
		$length += length($cert_data);
	}

	$raw = pack('C C n C',
		$nexttype,
		$critical << 7 | $reserved,
		$length,
		$cert_encoding);

	if(defined($cert_data)) {
		$raw .= $cert_data;
	}

	return($raw);
}



sub
kEncCertificationRequestPayload($$)
{
	my ($self, $next) = @_;

	my $raw = undef;

	my $nexttype =
		(defined($self->{'nexttype'}) && ($self->{'nexttype'} !~ /^\s*auto\s*$/i))?
			kPayloadType($self->{'nexttype'}):
			$next;
	my $critical =
		(defined($self->{'critical'}) && ($self->{'critical'} !~ /^\s*auto\s*$/i))?
			$self->{'critical'}:
			0;
	my $reserved =
		(defined($self->{'reserved'}) && ($self->{'reserved'} !~ /^\s*auto\s*$/i))?
			$self->{'reserved'}:
			0;
	my $length =
		(defined($self->{'length'}) && ($self->{'length'} !~ /^\s*auto\s*$/i))?
			$self->{'length'}:
			5;
	my $cert_encoding =
		(defined($self->{'cert_encoding'}) && ($self->{'cert_encoding'} !~ /^\s*auto\s*$/i))?
			kCertificateEncoding($self->{'cert_encoding'}):
			0;
	my $cert_authority =
		(defined($self->{'cert_authority'}) && ($self->{'cert_authority'} !~ /^\s*auto\s*$/i))?
			$self->{'cert_authority'}:
			undef;

	if(defined($cert_authority)) {
		$length += length($cert_authority);
	}

	$raw = pack('C C n C',
		$nexttype,
		$critical << 7 | $reserved,
		$length,
		$cert_encoding);

	if(defined($cert_authority)) {
		$raw .= $cert_authority;
	}

	return($raw);
}



sub
kEncAuthenticationPayload($$)
{
	my ($self, $next) = @_;

	my $raw = undef;

	my $nexttype =
		(defined($self->{'nexttype'}) && ($self->{'nexttype'} !~ /^\s*auto\s*$/i))?
			kPayloadType($self->{'nexttype'}):
			$next;
	my $critical =
		(defined($self->{'critical'}) && ($self->{'critical'} !~ /^\s*auto\s*$/i))?
			$self->{'critical'}:
			0;
	my $reserved =
		(defined($self->{'reserved'}) && ($self->{'reserved'} !~ /^\s*auto\s*$/i))?
			$self->{'reserved'}:
			0;
	my $length =
		(defined($self->{'length'}) && ($self->{'length'} !~ /^\s*auto\s*$/i))?
			$self->{'length'}:
			8;
	my $method =
		(defined($self->{'method'}) && ($self->{'method'} !~ /^\s*auto\s*$/i))?
			kAuthenticationMethod($self->{'method'}):
			0;
	my $reserved1 =
		(defined($self->{'reserved1'}) && ($self->{'reserved1'} !~ /^\s*auto\s*$/i))?
			$self->{'reserved1'}:
			0;
	my $data =
		(defined($self->{'data'}) && ($self->{'data'} !~ /^\s*auto\s*$/i))?
			$self->{'data'}:
			undef;

	if(defined($data)) {
		$length += length($data);
	}

	$raw = pack('C C n C C n',
		$nexttype,
		$critical << 7 | $reserved,
		$length,
		$method,
		$reserved1 >> 16 & 0xffff,
		$reserved1 & 0xffff);

	if(defined($data)) {
		$raw .= $data;
	}

	return($raw);
}



sub pem2str($)
{
	my ($pem) = @_;

	local (*IN);
	if (open(IN, $pem) == 0) {
		kLogHTML(kDump_Common_Error());
		return(undef);
	}
	binmode (IN);

	my $str = '';
	while (<IN>) {
		$str .= $_;
	}

	close(IN);
	return($str);
}


sub
kCalcAuthenticationData($$$$$$$$$)
{
	my ($material, $is_initiator, $self, $privkey, $cert, $ike_sa_init_data, $nonce, $nonce_strlen, $id) = @_;

	my $sk_p = $is_initiator? $material->pi: $material->pr;
	my $id_payload = kEncIdentificationPayloads($id, 0);
	my $id_mac = &{$material->prf}($sk_p, substr($id_payload, 4));
	my $msg_octets = $ike_sa_init_data . pack('H*', kIKE::kHelpers::as_hex2($nonce, $nonce_strlen)) . $id_mac;
	my $method =
		(defined($self->{'method'}) && ($self->{'method'} !~ /^\s*auto\s*$/i))?
		kAuthenticationMethod($self->{'method'}):
		0;

	if ($method == 1) { # RSA DS
		# calculate the hash value of the <msg octets>
		$privkey = pem2str($privkey);
		my $rsa_priv = Crypt::OpenSSL::RSA->new_private_key($privkey);
		my $signature = $rsa_priv->sign($msg_octets);

		# verify signature by public key
		my $x509 = Crypt::OpenSSL::X509->new_from_file($cert);
		my $pubkey = $x509->pubkey();
		my $rsa_pub = Crypt::OpenSSL::RSA->new_public_key($pubkey);
		my $verify = $rsa_pub->verify($msg_octets, $signature);

		return($signature);
	}
	elsif ($method == 2) { # SKMIC
		my $k = &{$material->prf}($privkey, 'Key Pad for IKEv2');
		my $raw = &{$material->prf}($k, $msg_octets);
		return($raw);
	}
	else {
		# XXX
		# used to verify invalid Authentication Method
		my $k = &{$material->prf}($privkey, 'Key Pad for IKEv2');
		my $raw = &{$material->prf}($k, $msg_octets);
		return($raw);
	}

	return(undef);
}



sub
kEncNoncePayload($$)
{
	my ($self, $next) = @_;

	my $raw = undef;

	my $nexttype =
		(defined($self->{'nexttype'}) && ($self->{'nexttype'} !~ /^\s*auto\s*$/i))?
			kPayloadType($self->{'nexttype'}):
			$next;
	my $critical =
		(defined($self->{'critical'}) && ($self->{'critical'} !~ /^\s*auto\s*$/i))?
			$self->{'critical'}:
			0;
	my $reserved =
		(defined($self->{'reserved'}) && ($self->{'reserved'} !~ /^\s*auto\s*$/i))?
			$self->{'reserved'}:
			0;
	my $length =
		(defined($self->{'length'}) && ($self->{'length'} !~ /^\s*auto\s*$/i))?
			$self->{'length'}:
			4;
	my $nonce =
		(defined($self->{'nonce'}) && ($self->{'nonce'} !~ /^\s*auto\s*$/i))?
			$self->{'nonce'}:
			undef;

	if(defined($nonce)) {
		$length += length($nonce) / 2;
	}

	$raw = pack('C C n',
		$nexttype,
		$critical << 7 | $reserved,
		$length);

	if(defined($nonce)) {
		$raw .= pack('H*', $nonce);
	}

	return($raw);
}



sub
kEncNotifyPayload($$)
{
	my ($self, $next) = @_;

	my $raw = undef;

	my $spi =
		(defined($self->{'spi'}) && ($self->{'spi'} !~ /^\s*auto\s*$/i))?
			pack('H*', $self->{'spi'}):
			undef;
	my $data =
		(defined($self->{'data'}) && ($self->{'data'} !~ /^\s*auto\s*$/i))?
			pack('H*', $self->{'data'}):
			undef;
	my $nexttype =
		(defined($self->{'nexttype'}) && ($self->{'nexttype'} !~ /^\s*auto\s*$/i))?
			kPayloadType($self->{'nexttype'}):
			$next;
	my $critical =
		(defined($self->{'critical'}) && ($self->{'critical'} !~ /^\s*auto\s*$/i))?
			$self->{'critical'}:
			0;
	my $reserved =
		(defined($self->{'reserved'}) && ($self->{'reserved'} !~ /^\s*auto\s*$/i))?
			$self->{'reserved'}:
			0;
	my $length =
		(defined($self->{'length'}) && ($self->{'length'} !~ /^\s*auto\s*$/i))?
			$self->{'length'}:
			8;
	my $id =
		(defined($self->{'id'}) && ($self->{'id'} !~ /^\s*auto\s*$/i))?
			$self->{'id'}:
			0;
	my $spiSize =
		(defined($self->{'spiSize'}) && ($self->{'spiSize'} !~ /^\s*auto\s*$/i))?
			$self->{'spiSize'}:
			defined($spi)?
				length($spi):
				0;
	my $type =
		(defined($self->{'type'}) && ($self->{'type'} !~ /^\s*auto\s*$/i))?
			kNotifyType($self->{'type'}):
			0;

	if(defined($spi)) {
		$length += length($spi);
	}

	if(defined($data)) {
		$length += length($data);
	}

	$raw = pack('C C n C C n',
		$nexttype,
		$critical << 7 | $reserved,
		$length,
		$id,
		$spiSize,
		$type);

	if(defined($spi)) {
		$raw .= $spi;
	}

	if(defined($data)) {
		$raw .= $data;
	}

	return($raw);
}



sub
kEncDeletePayload($$)
{
	my ($self, $next) = @_;

	my $raw = undef;

	my $spis = undef;
	if (ref($self->{'spis'}) eq 'ARRAY') {
		$spis = '';
		foreach my $spi (@{$self->{'spis'}}) {
			$spis .= pack('H*', $spi);
		}
		if (length($spis) == 0) {
			$spis = undef;
		}
	}
	else {
		$spis =
			(defined($self->{'spis'}) && ($self->{'spis'} !~ /^\s*auto\s*$/i))?
				pack('H*', $self->{'spis'}):
				undef;
	}

	my $nexttype =
		(defined($self->{'nexttype'}) && ($self->{'nexttype'} !~ /^\s*auto\s*$/i))?
			kPayloadType($self->{'nexttype'}):
			$next;
	my $critical =
		(defined($self->{'critical'}) && ($self->{'critical'} !~ /^\s*auto\s*$/i))?
			$self->{'critical'}:
			0;
	my $reserved =
		(defined($self->{'reserved'}) && ($self->{'reserved'} !~ /^\s*auto\s*$/i))?
			$self->{'reserved'}:
			0;
	my $length =
		(defined($self->{'length'}) && ($self->{'length'} !~ /^\s*auto\s*$/i))?
			$self->{'length'}:
			8;
	my $spiSize =
		(defined($self->{'spiSize'}) && ($self->{'spiSize'} !~ /^\s*auto\s*$/i))?
			$self->{'spiSize'}:
			defined($spis) ?
				4:	# ESP/AH
				0;	# IKE_SA
	my $id =
		(defined($self->{'id'}) && ($self->{'id'} !~ /^\s*auto\s*$/i))?
			kProtocolID($self->{'id'}):
			($spiSize > 0) ?
				kProtocolID('ESP'):
				kProtocolID('IKE');
	my $spiCount =
		(defined($self->{'spiCount'}) && ($self->{'spiCount'} !~ /^\s*auto\s*$/i))?
			$self->{'spiCount'}:
			($spiSize > 0) ?
				((ref($self->{'spis'}) eq 'ARRAY') ?
					scalar(@{$self->{'spis'}}) :
					length($self->{'spis'}) / 8) :
				0;

	if(defined($spis)) {
		$length += length($spis);
	}

	$raw = pack('C C n C C n',
		$nexttype,
		$critical << 7 | $reserved,
		$length,
		$id,
		$spiSize,
		$spiCount);

	if(defined($spis)) {
		$raw .= $spis;
	}

	return($raw);
}



sub
kEncTrafficSelectorPayload($$)
{
	my ($self, $next) = @_;

	my $raw = undef;
	my $selector = undef;

	my $selectors =
		(defined($self->{'selectors'}) && ($self->{'selectors'} !~ /^\s*auto\s*$/i))?
			kPayloadType($self->{'selectors'}):
			undef;

	if(defined($selectors)) {
		if(ref($selectors) ne 'ARRAY') {
			kCommon::kLogHTML('<FONT COLOR="#ff0000" SIZE="7"><U><B>'.
				'bug: must not reach here.</B></U></FONT>');

			return(undef);
		}

		for(my $d = 0; $d <= $#$selectors; $d ++) {
			if(ref($selectors->[$d]) ne 'HASH') {
				kCommon::kLogHTML('<FONT COLOR="#ff0000" SIZE="7"><U><B>'.
					'bug: must not reach here.</B></U></FONT>');

				return(undef);
			}
		}

		for(my $d = 0; $d <= $#$selectors; $d ++) {
			$selector .= kEncTrafficSelector($selectors->[$d]);
		}
	}

	my $nexttype =
		(defined($self->{'nexttype'}) && ($self->{'nexttype'} !~ /^\s*auto\s*$/i))?
			kPayloadType($self->{'nexttype'}):
			$next;
	my $critical =
		(defined($self->{'critical'}) && ($self->{'critical'} !~ /^\s*auto\s*$/i))?
			$self->{'critical'}:
			0;
	my $reserved =
		(defined($self->{'reserved'}) && ($self->{'reserved'} !~ /^\s*auto\s*$/i))?
			$self->{'reserved'}:
			0;
	my $length =
		(defined($self->{'length'}) && ($self->{'length'} !~ /^\s*auto\s*$/i))?
			$self->{'length'}:
			defined($selector)?
				8 + length($selector):
				8;
	my $count =
		(defined($self->{'count'}) && ($self->{'count'} !~ /^\s*auto\s*$/i))?
			$self->{'count'}:
			$#$selectors + 1;
	my $reserved1 =
		(defined($self->{'reserved1'}) && ($self->{'reserved1'} !~ /^\s*auto\s*$/i))?
			$self->{'reserved1'}:
			0;

	$raw = pack('C C n C C n',
		$nexttype,
		$critical << 7 | $reserved,
		$length,
		$count,
		$reserved1 >> 16 & 0xffff,
		$reserved1 & 0xffff);

	if($selector) {
		$raw .= $selector;
	}

	return($raw);
}



sub
kEncTrafficSelector($)
{
	my ($self) = @_;

	my $raw = undef;

	my $type =
		(defined($self->{'type'}) && ($self->{'type'} !~ /^\s*auto\s*$/i))?
			kTrafficSelectorType($self->{'type'}):
			0;

	if($type == 7) {	# TS_IPV4_ADDR_RANGE
		return(kEncTrafficSelector_TS_IPV4_ADDR_RANGE($self));
	}

	if($type == 8) {	# TS_IPV6_ADDR_RANGE
		return(kEncTrafficSelector_TS_IPV6_ADDR_RANGE($self));
	}

	return(kEncTrafficSelector_ANY($self, $type));
}



sub
kEncTrafficSelector_ANY($$)
{
	my ($self, $type) = @_;

	my $raw = undef;

	my $protocol =
		(defined($self->{'protocol'}) && ($self->{'protocol'} !~ /^\s*auto\s*$/i))?
			$self->{'protocol'}:
			0;
	my $selectorLen =
		(defined($self->{'selectorLen'}) && ($self->{'selectorLen'} !~ /^\s*auto\s*$/i))?
			$self->{'selectorLen'}:
			8;
	my $sport =
		(defined($self->{'sport'}) && ($self->{'sport'} !~ /^\s*auto\s*$/i))?
			$self->{'sport'}:
			0;
	my $eport =
		(defined($self->{'eport'}) && ($self->{'eport'} !~ /^\s*auto\s*$/i))?
			$self->{'eport'}:
			0;
	my $saddr =
		(defined($self->{'saddr'}) && ($self->{'saddr'} !~ /^\s*auto\s*$/i))?
			pack('H*', $self->{'saddr'}):
			undef;
	my $eaddr =
		(defined($self->{'eaddr'}) && ($self->{'eaddr'} !~ /^\s*auto\s*$/i))?
			pack('H*', $self->{'eaddr'}):
			undef;

	if($saddr) {
		$selectorLen += length($saddr);
	}

	if($eaddr) {
		$selectorLen += length($eaddr);
	}

	$raw = pack('C C n n n',
		$type,
		$protocol,
		$selectorLen,
		$sport,
		$eport);

	if($saddr) {
		$raw .= $saddr;
	}

	if($eaddr) {
		$raw .= $eaddr;
	}

	return($raw);
}



sub
kEncTrafficSelector_TS_IPV4_ADDR_RANGE($)
{
	my ($self) = @_;

	my $raw = undef;

	my $protocol =
		(defined($self->{'protocol'}) && ($self->{'protocol'} !~ /^\s*auto\s*$/i))?
			$self->{'protocol'}:
			0;
	my $selectorLen =
		(defined($self->{'selectorLen'}) && ($self->{'selectorLen'} !~ /^\s*auto\s*$/i))?
			$self->{'selectorLen'}:
			16;
	my $sport =
		(defined($self->{'sport'}) && ($self->{'sport'} !~ /^\s*auto\s*$/i))?
			$self->{'sport'}:
			0;
	my $eport =
		(defined($self->{'eport'}) && ($self->{'eport'} !~ /^\s*auto\s*$/i))?
			$self->{'eport'}:
			0;
	my $saddr =
		(defined($self->{'saddr'}) && ($self->{'saddr'} !~ /^\s*auto\s*$/i))?
			ipaddr_tobin($self->{'saddr'}):
			ipaddr_tobin('0.0.0.0');
	my $eaddr =
		(defined($self->{'eaddr'}) && ($self->{'eaddr'} !~ /^\s*auto\s*$/i))?
			ipaddr_tobin($self->{'eaddr'}):
			ipaddr_tobin('0.0.0.0');

	$raw = pack('C C n n n',
		7,
		$protocol,
		$selectorLen,
		$sport,
		$eport);

	$raw .= $saddr;
	$raw .= $eaddr;

	return($raw);
}



sub
kEncTrafficSelector_TS_IPV6_ADDR_RANGE($)
{
	my ($self) = @_;

	my $raw = undef;

	my $protocol =
		(defined($self->{'protocol'}) && ($self->{'protocol'} !~ /^\s*auto\s*$/i))?
			$self->{'protocol'}:
			0;
	my $selectorLen =
		(defined($self->{'selectorLen'}) && ($self->{'selectorLen'} !~ /^\s*auto\s*$/i))?
			$self->{'selectorLen'}:
			40;
	my $sport =
		(defined($self->{'sport'}) && ($self->{'sport'} !~ /^\s*auto\s*$/i))?
			$self->{'sport'}:
			0;
	my $eport =
		(defined($self->{'eport'}) && ($self->{'eport'} !~ /^\s*auto\s*$/i))?
			$self->{'eport'}:
			0;
	my $saddr =
		(defined($self->{'saddr'}) && ($self->{'saddr'} !~ /^\s*auto\s*$/i))?
			ipaddr_tobin($self->{'saddr'}):
			ipaddr_tobin('::');
	my $eaddr =
		(defined($self->{'eaddr'}) && ($self->{'eaddr'} !~ /^\s*auto\s*$/i))?
			ipaddr_tobin($self->{'eaddr'}):
			ipaddr_tobin('::');

	$raw = pack('C C n n n',
		8,
		$protocol,
		$selectorLen,
		$sport,
		$eport);

	$raw .= $saddr;
	$raw .= $eaddr;

	return($raw);
}



sub
kEncEncryptedPayload($$$$$)
{
	my ($self, $next, $material, $is_initiator, $plaintext) = @_;

	my $raw = undef;

	my $blockSize = $material->bencr;
	my $iv =
		(defined($self->{'iv'}) && ($self->{'iv'} !~ /^\s*auto\s*$/i))?
			pack('H*', $self->{'iv'}):
			Crypt::Random::makerandom_octet(Length => $blockSize);

	unless(defined($plaintext)) {
		$plaintext = '';
	}

	my $plaintextlen = length($plaintext);
	my $ciphertext = undef;

	if ($material->{'encr_alg'} eq 'AES_CTR') {
		my $key = $is_initiator ? ($material->ei) : ($material->er);
		my $nonce = $is_initiator ? ($material->ni_ctr) : ($material->nr_ctr);
		$ciphertext = &{$material->encr}($key, $plaintext, $nonce, $iv);
	}
	else {
		$ciphertext = &{$material->encr}(
						$is_initiator?
							($material->ei): ($material->er),
						$plaintext, $iv);
	}

	my $nexttype =
		(defined($self->{'nexttype'}) && ($self->{'nexttype'} !~ /^\s*auto\s*$/i))?
			kPayloadType($self->{'nexttype'}):
			$next;
	my $critical =
		(defined($self->{'critical'}) && ($self->{'critical'} !~ /^\s*auto\s*$/i))?
			$self->{'critical'}:
			0;
	my $reserved =
		(defined($self->{'reserved'}) && ($self->{'reserved'} !~ /^\s*auto\s*$/i))?
			$self->{'reserved'}:
			0;
	my $length =
		(defined($self->{'length'}) && ($self->{'length'} !~ /^\s*auto\s*$/i))?
			$self->{'length'}:
			4 + $material->bencr + length($ciphertext) + $material->binteg;
	my $checksum =
		(defined($self->{'checksum'}) && ($self->{'checksum'} !~ /^\s*auto\s*$/i))?
			pack('H*', $self->{'checksum'}):
			("\0" x $material->binteg);

	$raw = pack('C C n',
		$nexttype,
		$critical << 7 | $reserved,
		$length);

	$raw .= $iv;
	$raw .= $ciphertext;
	$raw .= $checksum;

	return($raw);
}



sub
kEncConfigurationPayload($$)
{
	my ($self, $next) = @_;

	my $raw = undef;
	my $attribute = undef;

	my $attributes =
		(defined($self->{'attributes'}) && ($self->{'attributes'} !~ /^\s*auto\s*$/i))?
			$self->{'attributes'}:
			undef;

	unless (defined($attributes)) {
		return(undef);
	}

	unless (ref($attributes) eq 'ARRAY') {
		return(undef);
	}

	for (my $i = 0; $i <= $#$attributes; $i++) {
		$attribute .= kEncConfigurationAttribute($attributes->[$i]);
	}

	my $nexttype =
		(defined($self->{'nexttype'}) && ($self->{'nexttype'} !~ /^\s*auto\s*$/i))?
			kPayloadType($self->{'nexttype'}):
			$next;
	my $critical =
		(defined($self->{'critical'}) && ($self->{'critical'} !~ /^\s*auto\s*$/i))?
			$self->{'critical'}:
			0;
	my $reserved =
		(defined($self->{'reserved'}) && ($self->{'reserved'} !~ /^\s*auto\s*$/i))?
			$self->{'reserved'}:
			0;
	my $length =
		(defined($self->{'length'}) && ($self->{'length'} !~ /^\s*auto\s*$/i))?
			$self->{'length'}:
			defined($attribute)?
				8 + length($attribute):
				8;

	my $cfg_type =
		(defined($self->{'cfg_type'}) && ($self->{'cfg_type'} !~ /^\s*auto\s*$/i))?
			kConfigurationType($self->{'cfg_type'}):
			0;

	my $reserved1 =
		(defined($self->{'reserved1'}) && ($self->{'reserved1'} !~ /^\s*auto\s*$/i))?
			$self->{'reserved1'}:
			0;

	$raw = pack('C C n C C n',
		$nexttype,
		$critical << 7 | $reserved,
		$length,
		$cfg_type,
		$reserved1 >> 16 & 0xffff,
		$reserved1 & 0xffff);

	if (defined($attribute)) {
		$raw .= $attribute;
	}

	return($raw);
}



sub
kEncConfigurationAttribute($)
{
	my ($self) = @_;

	my $raw = undef;

	my $reserved =
		(defined($self->{'reserved'}) && ($self->{'reserved'} !~ /^\s*auto\s*$/i))?
			$self->{'reserved'}:
			0;

	my $type =
		(defined($self->{'attr_type'}) && ($self->{'attr_type'} !~ /^\s*auto\s*$/i))?
			kConfAttributeType($self->{'attr_type'}):
			0;

	my $value =
		(defined($self->{'value'}) && ($self->{'value'} !~ /^\s*auto\s*$/i))?
			$self->{'value'}:
			0;

	my $length = length($value);

	$raw = pack('n n',
		$reserved << 15 | $type,
		$length);
	$raw .= $value;

	return($raw);
}


###################
# Implementations #
###################

=pod

=head2 kGenIKEHeader()

Generates an IKE Header before existing payloads if exists.

=head3 Parameters

=over

=item B<Initiator SPI>

Security Parameter Index used by the original initiator of the exchange.
It has to be formatted as a hex string without prefix or suffix.

=item B<Responder SPI>

Security Parameter Index used by the original responder of the exchange.
It has to be formatted as a hex string without prefix or suffix.

=item B<Major Version> / B<Minor Version>

Current IKE version for the message. Major and minor should be respectively
2 and 0 as of RFC4306.

=item B<Exchange Type>

The type of the current exchange. Types are enumerated in RFC4306 section 3.1.
You can type either value or name of the type.

=item B<Is Initiator>

This flag indicates if the current message is generated by the original initiator
or not.

=item B<Higher Version>

This flag indicates if the sending node can speak a higher version.

=item B<Is Response>

This flag indicates if the current message is a response or not.

=item B<Message ID>

This is the ID of the message in the current exchanges sequence. It must follow rules.

=item B<Next Payload type> (optional)

The type of the next payload. It should come from a call to some payload generation
sub.

=item B<Next Payload data> (optional)

The data of the next payload and followings, It should come from a call to some
payload generation sub.

=back

=head3 Return value

=over

=item B<Message data>

The IKEv2 message generated using all the parameters.

=back

=cut

sub kGenIKEHeader($$$$$$$$$;$$) {
	# Read parameters.
	my ($initSPI, $respSPI, $major, $minor, $exchType, $initiator, $higher, $response, $messID, $nexttype, $nextdata) = @_;
	$nextdata = '' unless $nextdata;
	$nexttype = 0 unless $nexttype;
	# Construct final values.
	my $version = (($major & 7) << 4) | ($minor & 7);
	my $flag = ($response ? 32 : 0) | ($higher ? 16 : 0) | ($initiator ? 8 : 0);
	$exchType = kExchangeType($exchType) if $exchType !~ /^[0-9]+$/;
	$exchType = int($exchType);
	$nexttype = kPayloadType($nexttype) if $nexttype !~ /^[0-9]+$/;
	$nexttype = int($nexttype);
	# Build data and return.
	return pack('H16 H16 C C C C N N', $initSPI, $respSPI, $nexttype, $version, $exchType, $flag, $messID, length($nextdata) + 28) . $nextdata;
}

=pod

=head2 kGenGenericPayloadHeader()

Generates a Generic Payload Header before payload value. 

B<This function is not intended to be called by any programs outside the
library. It may be used only if the user wants to create an invalid payload
or a vendor-specific one.>

=head3 Parameters

=over

=item B<Is Critical>

This flag indicates if it is critical to recognize this payload or not.

=item B<Payload data>

This is the formatted content of the current payload to be created.

=item B<Next Payload type>

The type of the next payload.

=item B<Next Payload data>

The data of the next payload.

=back

=head3 Return value

=over

=item B<Payload data>

Final data for the payload.

=back

=cut

sub kGenGenericPayloadHeader($$$$) {
	# Read parameters.
	my ($critical, $payload, $nexttype, $nextdata) = @_;
	$nextdata = '' unless $nextdata;
	$nexttype = 0 unless $nexttype;
	# Construct final values.
	$critical = ($critical) ? '1' : '0';
	$nexttype = kPayloadType($nexttype) if $nexttype !~ /^[0-9]+$/;
	$nexttype = int($nexttype);
	# Build data and return.
	return pack('C B n', $nexttype, $critical, length($payload) + 4) . $payload . $nextdata;
}

=pod

=head2 kGenSecurityAssociationPayload()

Generates a Security Association Payload before existing payloads if exists.

=head3 Parameters

=over

=item B<Proposals data>

Proposal substructures attached to this payload. This is created by previous
calls to L</kGenSAProposal()>.

=item B<Next Payload type> (optional)

The type of the next payload. It should come from a call to some payload generation
sub.

=item B<Next Payload data> (optional)

The data of the next payload and followings, It should come from a call to some
payload generation sub.

=back

=head3 Return value

=over

=item B<Payload data>

The final data for this payload and the following.

=item B<Payload type>

The type of this payload.

=back

=cut

sub kGenSecurityAssociationPayload($;$$) {
	# Read parameters.
	my ($proposals, $nexttype, $nextdata) = @_;
	# Build data and return.
	return (kGenGenericPayloadHeader(0, $proposals, $nexttype, $nextdata), kPayloadType('SA'));
}

=pod

=head2 kGenSAProposal()

Generates a Proposal substructure before existing one if exists.

=head3 Parameters

=over

=item B<Proposal #>

Sequence number of the proposal in the payload. Starts at 1.

=item B<Protocol ID>

The protocol of the current proposal. Protocol IDs are enumerated in RFC4306
section 3.3.1. You can either specify the name or the value.

=item B<SPI Size>

Security Parameter Index size to tell about related SPIs when rekeying.

=item B<SPI>

Security Parameter Index value. It can be undef or empty if its size is set to 0.
It has to be formatted as a hex string without prefix or suffix.

=item B<Number of transformation>

The count of transformations that are in the encoded transforms data.

=item B<Transforms>

The transforms data. This is create by previous calls to L</kGenSATransform()>.

=item B<Next proposal data> (optional)

Content of the proposals appended to generated one.

=back

=head3 Return value

=over

=item B<Proposal data>

The data of the generated proposal and the following ones.

=back

=cut

sub kGenSAProposal($$$$$$;$) {
	# Read parameters.
	my ($number, $id, $spiSize, $spi, $transformCount, $transforms, $nextdata) = @_;
	$transforms = '' unless $transforms;
	$nextdata = '' unless $nextdata;
	# Construct final values.
	$id = kProtocolID($id) if $id !~ /^[0-9]+$/;
	$id = int($id);
	# Build data and return.
	return pack('C C n C C C C',
		    (length($nextdata) > 0) ? (2) : (0),
		    0,
		    length($transforms) + 8 + $spiSize,
		    $number,
		    $id,
		    $spiSize,
		    $transformCount)
		. (($spiSize > 0) ? (pack('H[' . ($spiSize * 2) . ']', $spi)) : ('')) . $transforms . $nextdata;
}

=pod

=head2 kGenSATransform()

Generates a transform substructure before existing one if exists.

=head3 Parameters

=over

=item B<Transform Type>

The type of the transformation. Transform types are enumerated in RFC4306 section
3.3.2. You can either specify the name or the value.

=item B<Transform ID>

The transform ID for the transform. Transform IDs are enumerated in RFC4306
section 3.3.2. You can either specify the name or the value. For the name, you
MUST remove the part the contains the transform type name and the following underscore.

=item B<Attributes>

The transforms attributs. This is create by previous calls to L</kGenSAAttribute()>.

=item B<Next transform data> (optional)

Content of the transforms appended to generated one.

=back

=head3 Return value

=over

=item B<Transform data>

The data of the generated transform and the following ones.

=back

=cut

sub kGenSATransform($$$;$) {
	# Read parameters.
	my ($type, $id, $attributes, $nextdata) = @_;
	$attributes = '' unless $attributes;
	$nextdata = '' unless $nextdata;
	# Construct final values.
	$type = kTransformType($type) if $type !~ /^[0-9]+$/;
	$type = int($type);
	$id = kTransformTypeID($type, $id) if $id !~ /^[0-9]+$/;
	$id = int($id);
	# Build data and return.
	return pack('C C n C C n', (length($nextdata) > 0) ? (3) : (0), 0, length($attributes) + 8, $type, 0, $id) . $attributes . $nextdata;
}

=pod

=head2 kGenSAAttribute()

Generates an attribute substructure before existing one if exists.

=head3 Parameters

=over

=item C<Attribute type>

The type of the attribute. Attribute types are enumerated in RFC4306 section
3.3.5. You can either specify the name or the value.

=item C<Attribute value>

The value associated to the type. If the value is variable length, it must be a
string containing binary data. If the value is fixed length it must contains an
hex string representing the 2-bytes value.

=item C<Next attribute data>

Content of the attribute appended to this one.

=back

=head3 Return value

=over

=item C<Attribute data>

The data of the generated attribute and the following ones.

=back

=cut

sub kGenSAAttribute($$;$) {
	# Read parameters.
	my ($type, $value, $nextdata) = @_;
	$nextdata = '' unless $nextdata;
	# Construct final values.
	$type = kAttributeType($type) if $type !~ /^[0-9]+$/;
	$type = int($type);
	$value = '' unless $value;
	# Build data and return.
	my $result = pack('n', $type);
	return $result . pack('n', length($value)) . $value . $nextdata if $type & 128;
	return $result . pack('H4', $type, $value) . $nextdata;
}

=pod

=head2 kGenKeyExchangePayload()

Generates a Key Exchange Payload before existing payloads if exists.

=head3 Parameters

=over

=item B<DH Group>

This is the Diffie-Hellman group of the data contained by this payload. Groups
are defined in RFC4306 Appendix B and in RFC3526. You can either enter the
number or the name of DH Group.

=item B<Key Exchange data>

The Diffie-Hellman public key to exchange. This parameter must be a Math::BigInt.

=item B<Next Payload type> (optional)

The type of the next payload. It should come from a call to some payload generation
sub.

=item B<Next Payload data> (optional)

The data of the next payload and followings, It should come from a call to some
payload generation sub.

=back

=head3 Return value

=over

=item B<Payload data>

The final data for this payload and the following.

=item B<Payload type>

The type of this payload.

=back

=cut

# obsolete subroutine
sub kGenKeyExchangePayload($$;$$) {
	# Read parameters.
	my ($group, $value, $nexttype, $nextdata) = @_;
	# Construct final values.
	$group = kTransformTypeID(4, $group) if $group !~ /^[0-9]+$/;
	$group = int($group);
	# Build data and return.
	return (kGenGenericPayloadHeader(0,
					 pack('n n H*', $group, 0, substr($value->as_hex, 2)), # never call as_hex
					 $nexttype,
					 $nextdata),
		kPayloadType('KE'));
}

=pod

=head2 kGenNoncePayload()

Generates a Nonce Payload before existing payload if exists.

=head3 Parameters

=over

=item B<Next Payload type> (optional)

The type of the next payload. It should come from a call to some payload generation
sub.

=item B<Next Payload data> (optional)

The data of the next payload and followings, It should come from a call to some
payload generation sub.

=back

=head3 Return value

=over

=item B<Payload data>

The final data for this payload and the following.

=item B<Payload type>

The type of this payload.

=item B<Nonce value>

The value of the generated nonce for creating this payload. It is randomly created
and contained in a Math::BigInt.

=item B<Nonce length>

The size in bytes of the nonce.

=back

=cut

# obsolete subroutine
sub kGenNoncePayload(;$$) {
	# Read parameters.
	my ($nexttype, $nextdata) = @_;
	# Construct final values.
	my $noncelen = int(rand(240)) + 16;
	my $nonce = Math::BigInt->new(makerandom(Size => ($noncelen * 8), Strength => 0));
	# Build data and return.
	return (kGenGenericPayloadHeader(0,
					 pack('H*', substr($nonce->as_hex, 2)), # never call as_hex
					 $nexttype,
					 $nextdata),
		kPayloadType('Ni, Nr'),
		$nonce, $noncelen);
}

=pod

=head2 kGenNotifyPayload()

Generates a Notify Payload before existing payloads if exists.

=head3 Parameters

=over

=item B<Protocol ID>

The protocol concerned by this notification. Protocol IDs are enumerated in
RFC4306 section 3.3.1 (linked by section 3.10). You can either specify the name
or the value.

=item B<SPI Size>

Security Parameter Index size to tell about related SPIs if applicable.

=item B<Notification Type>

The type of this notification. Notification types are enumerated in RFC4306
section 3.10.1. You can either specify the name or the value.

=item B<SPI>

Security Parameter Index value. It can be undef or empty if its size is set to 0.
It has to be formatted as a hex string without prefix or suffix.

=item B<Notification Data>

The raw data associated to this notification. It is a string containing the data
to send as is.

=item B<Next Payload type> (optional)

The type of the next payload. It should come from a call to some payload generation
sub.

=item B<Next Payload data> (optional)

The data of the next payload and followings, It should come from a call to some
payload generation sub.

=back

=head3 Return value

=over

=item B<Payload data>

The final data for this payload and the following.

=item B<Payload type>

The type of this payload.

=back

=cut

sub kGenNotifyPayload($$$$$;$$) {
	# Read parameters.
	my ($id, $spiSize, $type, $spi, $data, $nexttype, $nextdata) = @_;
	# Construct final values.
	$id = kProtocolID($id) if $id !~ /^[0-9]+$/;
	$id = int($id);
	$type = kNotifyType($type) if $type !~ /^[0-9]+$/;
	$type = int($type);
	$spi = '' unless $spi;
	$data = '' unless $data;
	# Build data and return.
	return (kGenGenericPayloadHeader(0, pack('C C n', $id, $spiSize, $type) . pack('H[' . ($spiSize * 8) . ']', $spi) . $data, $nexttype, $nextdata), 
		kPayloadType('N'));
}

=pod

=head2 kGenEncryptedPayload()

Generates an Encrypted Payloads containing existing payloads in encrypted form.

=head3 Parameters

=over

=item B<Encryption material>

The L<kIKE::kEncryptionMaterial object|kIKE::kEncryptionMaterial> containing
the keys for the targetted IKE_SA used to made encryption.

=item B<Is initiator>

Indicates if the payloads is intended to be used in a message comming from the
original initiator, i.e. the end which started the current IKE_SA (a
rekey changes the original initiator to the one which started rekeying).

=item B<Next Payload type> (optional)

The type of the next payload. It should come from a call to some payload generation
sub.

=item B<Next Payload data> (optional)

The data of the next payload and followings, It should come from a call to some
payload generation sub.

=back

=head3 Return value

=over

=item B<Payload data>

The final data for this payload. However, the checksum have to be computed after
generating the IKE Header.

=item B<Payload type>

The type of this payload.

=back

=cut

sub kGenEncryptedPayload($$;$$) {
	# Read parameters.
	my ($material, $isInit, $nexttype, $nextdata) = @_;
	$nextdata = '' unless $nextdata;
	$nexttype = 0 unless $nexttype;
	# Encrypt inner payloads.
	my $blockSize = $material->bencr;
	my $iv = Crypt::Random::makerandom_octet(Length => $blockSize);
	my $cypher = &{$material->encr}(($isInit) ? ($material->ei) : ($material->er), $nextdata, $iv);
	# Build data and return.
	return (kGenGenericPayloadHeader(0, $iv . $cypher . ("\0" x $material->binteg), $nexttype, ''), kPayloadType('E'));
}

=pod

=head2 kGenEncryptedPayloadChecksum()

Computes the checksum of an IKE message and update the corresponding fields of the
Encrypted Payload.

=head3 Parameters

=over

=item B<Encryption material>

The L<kIKE::kEncryptionMaterial object|kIKE::kEncryptionMaterial> containing the
keys for the targetted IKE_SA used to made encryption.

=item B<Is initiator>

Indicates if the payloads is intended to be used in a message comming from the
original initiator, i.e. the end which started the current IKE_SA (a
rekey changes the original initiator to the one which started rekeying).

=item B<IKE Message>

The message containing an Encrypted payload to be updated with the computed checksum.

=back

=head3 Return value

=over

=item B<Message>

The updated message ready to be sent.

=back

=cut

sub kGenEncryptedPayloadChecksum($$$) {
	# Read parameters.
	my ($material, $isInit, $message) = @_;
	# Construct final values.
	$message = substr($message, 0, length($message) - $material->binteg);
	# Modify data and return.
	return $message . &{$material->integ}(($isInit) ? ($material->ai) : ($material->ar), $message);
}

=pod

=head2 kGenIdentificationPayload()

Generates an Identification Payload (Initiator or Responder) before existing
payloads if exists.

=head3 Parameters

=over

=item B<Identification Type>

The type of the identification data. Identification data types are enumerated in
RFC4306 section 3.5. You can either specify the name or value.

=item B<Identification Data>

The data associated with this identification. It have to be ready to be put in
the payload.

=item B<Is initiator>

Indicates if the payloads is intended to be used in a message comming from the
original initiator, i.e. the end which started the current IKE_SA (a
rekey changes the original initiator to the one which started rekeying).

=item B<Next Payload type> (optional)

The type of the next payload. It should come from a call to some payload generation
sub.

=item B<Next Payload data> (optional)

The data of the next payload and followings, It should come from a call to some
payload generation sub.

=back

=head3 Return value

=over

=item B<Payload data>

The final data for this payload.

=item B<Payload type>

The type of this payload.

=back

=cut

sub kGenIdentificationPayload($$$;$$) {
	# Read parameters.
	my ($type, $value, $isInit, $nexttype, $nextdata) = @_;
	# Construct final values.
	$type = kIdentificationType($type) if $type !~ /^[0-9]+$/;
	$type = int($type);
	# Build data and return.
	return (kGenGenericPayloadHeader(0, pack('C', $type) . ("\0" x 3) . $value, $nexttype, $nextdata), kPayloadType(
		($isInit) ? ('IDi') : ('IDr')
	));
}

=pod

=head2 kGenAuthenticationPayload()

Generates an Authentication Payload before any existing payloads if exists.

=head3 Parameters

=over

=item B<Encryption material>

The L<kIKE::kEncryptionMaterial object|kIKE::kEncryptionMaterial> containing the
keys for the targetted IKE_SA used to made encryption.

=item B<Authentication method>

The method to use to authenticate to the other end. Authentication methods are
enumerated in RFC4306 section 3.8. You can either specify the name or the value.

=item B<Method data>

The data associated with the authentication method in the form it is waited by
this one.

=item B<Is initiator>

Indicates if the payloads is intended to be used in a message comming from the
original initiator, i.e. the end which started the current IKE_SA (a
rekey changes the original initiator to the one which started rekeying).

=item B<Initial IKE_SA_INIT message>

The whole data of the IKE_SA_INIT generated by this side. It is in its ready to
send form.

=item B<Nonce>

The other end nonce as a Math::BigInt.

=item B<Identification payload>

The identification payload for this side. The whole payload as to be gave.
However the general header isn't used. It then can be created inline to avoid
the need of cutting it from the following payloads.

=item B<Next Payload type> (optional)

The type of the next payload. It should come from a call to some payload generation
sub.

=item B<Next Payload data> (optional)

The data of the next payload and followings, It should come from a call to some
payload generation sub.

=back

=head3 Return value

=over

=item B<Payload data>

The final data for this payload.

=item B<Payload type>

The type of this payload.

=back

=cut

# obsolete subroutine
sub kGenAuthenticationPayload($$$$$$$;$$) {
	# Read parameters.
	my ($material, $method, $methoddata, $isInit, $saInitMessage, $nonce, $idPayload, $nexttype, $nextdata) = @_;
	# Construct final values.
	$method = kAuthenticationMethod($method) if $method !~ /^[0-9]+$/;
	$method = int($method);
	my $authData;
	# Compute data to sign.
	my $authKey = ($isInit) ? ($material->pi) : ($material->pr);
	my $macID = &{$material->prf}($authKey, substr($idPayload, 4));
	my $signedData = $saInitMessage . pack('H*', substr($nonce->as_hex, 2)) . $macID; # never call as_hex
	# Compute signature.
	if ($method == 2) {
		my $k = &{$material->prf}($methoddata, "Key Pad for IKEv2");
		$authData = &{$material->prf}($k,
			$signedData);
	}
	else {
		die('Unsupported authentication method: ' . $method);
	}
	# Build data and return.
	return (kGenGenericPayloadHeader(0, pack('C', $method) . ("\0" x 3) . $authData, $nexttype, $nextdata), kPayloadType('AUTH'));
}

=pod

=head2 kGenTrafficSelectorPayload()

Generates a Traffic Selector Payload before existing payloads if exists.

=head3 Parameters

=over

=item B<Count>

The count of traffic selectors in this payload.

=item B<Selectors>

The traffic selectors. This is created by previous calls to L</kGenTSSelector()>.

=item B<Is initiator>

Indicates if the payloads is intended to be used in a message comming from the
original initiator, i.e. the end which started the current IKE_SA (a
rekey changes the original initiator to the one which started rekeying).

=item B<Next Payload type> (optional)

The type of the next payload. It should come from a call to some payload generation
sub.

=item B<Next Payload data> (optional)

The data of the next payload and followings, It should come from a call to some
payload generation sub.

=back

=head3 Return value

=over

=item B<Payload data>

The final data for this payload.

=item B<Payload type>

The type of this payload.

=back

=cut

sub kGenTrafficSelectorPayload($$$;$$) {
	# Read parameters.
	my ($count, $selectors, $isInit, $nexttype, $nextdata) = @_;
	# Build data and return.
	return (kGenGenericPayloadHeader(0, 
		pack('C', $count) . ("\0" x 3) . $selectors, $nexttype, $nextdata), kPayloadType(
			($isInit) ? ('TSi') : ('TSr')
		));
}

=pod

=head2 kGenTSSelector()

Generates a traffic selector substructure before existing one if exists.

=head3 Parameters

=over

=item B<Selector type>

The Traffic Selector type of this Traffic Selector. Types are defined in RFC4306
section 3.13.1. You can use the name (Without 'TS_' prefix) or the value.

=item B<Protocol ID>

The protocol ID matching protocol IDs in the file /etc/protocols on unix systems
or in the file %SYSTEMROOT%\System32\Drivers\etc\protocols on windows NT systems.
Use 0 for any protocol. You can only use the protocol ID value.

=item B<Start Port> B<End Port>

The 'port' range of acceptable values for current protocol. Can have many meanings
for protocols other than TCP and UDP. You can only put a numeric value.

=item B<Start Address> B<End Address>

The address range of acceptable source/destination. It must be in binary form
as used in the protocol headers.

=item B<Next traffic selector data> (optional)

Content of the traffic selector appended to this one.

=back

=head3 Return value

=over

=item B<Traffic Selector data>

The data of the generated traffic selector and the following ones.

=back

=cut

sub kGenTSSelector($$$$$$;$) {
	# Read parameters.
	my ($type, $id, $sport, $eport, $saddr, $eaddr, $next) = @_;
	$next = '' unless $next;
	# Construct final values.
	$type = kTrafficSelectorType($type) if $type !~ /^[0-9]+$/;
	$type = int($type);
	# Build data and return.
	return pack('C C n n n ', $type, $id, 8 + length($saddr) + length($eaddr), $sport, $eport) . $saddr . $eaddr . $next;
}

=pod

=head2 kGenDeletePayload()

Generates a Delete Payload before existing payloads if exists.

=head3 Parameters

=over

=item B<Protocol ID>

The protocol of the deleted SA. Protocol IDs are enumerated in RFC4306
section 3.3.1. You can either specify the name or the value.

=item B<SPI Size>

The size of the Security Parameter Indexes.

=item B<SPI Count>

The count of Security Parameter Index concerned.

=item B<SPIs>

The Security Parameter Index values. It has to be formatted as a hex string
without prefix or suffix. It is the concatenation of all the concerned SPIs.

=item B<Next Payload type> (optional)

The type of the next payload. It should come from a call to some payload generation
sub.

=item B<Next Payload data> (optional)

The data of the next payload and followings, It should come from a call to some
payload generation sub.

=back

=head3 Return value

=over

=item B<Payload data>

The final data for this payload.

=item B<Payload type>

The type of this payload.

=back

=cut

sub kGenDeletePayload($$$$;$$) {
	# Read parameters.
	my ($id, $spiSize, $spiCount, $spis, $nexttype, $nextdata) = @_;
	# Construct final values.
	$id = kProtocolID($id) if $id !~ /^[0-9]+$/;
	$id = int($id);
	# Build data and return.
	return (kGenGenericPayloadHeader(0, 
		pack('C C n H*', $id, $spiSize, $spiCount, $spis), 
			$nexttype, $nextdata), kPayloadType('D'));
}

=pod

=head1 SEE ALSO

Use RFC4306 as reference to understand the format.

=head1 AUTHOR

Pierrick Caillon, <pierrick@64translator.com>, from tahi project.

=cut


sub kGenVendorIDPayload($;$$) {
	my ($vid, $nexttype, $nextdata) = @_;

	return (kGenGenericPayloadHeader(0,
					 pack('H*', substr($vid->as_hex, 2)),
					 $nexttype,
					 $nextdata),
		kPayloadType('V'));
}

sub kGenCertificatePayload($$;$$) {
	# Read parameters.
	my ($cert_encoding, $cert_data, $nexttype, $nextdata) = @_;
	# Build data and return.
	return (kGenGenericPayloadHeader(0,
					 pack('C H*', $cert_encoding, $cert_data),
					 $nexttype,
					 $nextdata),
		kPayloadType('CERT'));
}

sub kGenCertificateRequestPayload($$;$$) {
	# Read parameters.
	my ($cert_encoding, $cert_authority, $nexttype, $nextdata) = @_;
	# Build data and return.
	return (kGenGenericPayloadHeader(0,
					 pack('C H*', $cert_encoding, $cert_authority),
					 $nexttype,
					 $nextdata),
		kPayloadType('CERTREQ'));
}

sub kGenEAPPayload($$$$;$$) {
	# Read parameters.
	my ($code, $id, $type, $data, $nexttype, $nextdata) = @_;
	# Build data and return.
	return (kGenGenericPayloadHeader(0,
					 pack('C C n C H*',
					      $code,
					      $id,
					      4 + length($data)/2 + 1,
					      $type,
					      $data),
					 $nexttype,
					 $nextdata),
		kPayloadType('CERTREQ'));
}

sub kEncUndefinedPayload($$)
{
	my ($self, $next) = @_;

	my $raw = undef;

	my $nexttype =
		(defined($self->{'nexttype'}) && ($self->{'nexttype'} !~ /^\s*auto\s*$/i))?
			kPayloadType($self->{'nexttype'}):
			$next;
	my $critical =
		(defined($self->{'critical'}) && ($self->{'critical'} !~ /^\s*auto\s*$/i))?
			$self->{'critical'}:
			0;
	my $reserved =
		(defined($self->{'reserved'}) && ($self->{'reserved'} !~ /^\s*auto\s*$/i))?
			$self->{'reserved'}:
			0;
	my $data =
		(defined($self->{'data'}) && ($self->{'data'} !~ /^\s*auto\s*$/i))?
			$self->{'data'}:
			'';
	my $length =
		(defined($self->{'length'}) && ($self->{'length'} !~ /^\s*auto\s*$/i))?
			$self->{'length'}:
			4 + length($data);


	$raw = pack('C C n',
		$nexttype,
		$critical << 7 | $reserved,
		$length);

	if (defined($data)) {
		$raw .= pack('H*', $data);
	}

	return($raw);
}


1;
