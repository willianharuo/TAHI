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
# $TAHI: koi/libdata/kIKE/kIKE.pm,v 0.1 2007/07/10 15:09:00 pierrick Exp $
#
# $Id: kIKE.pm,v 1.8 2010/07/22 12:41:17 velo Exp $
#
########################################################################

package kIKE::kIKE;

use strict;
use warnings;
use Exporter;
use Math::BigInt;
use Crypt::Random qw( makerandom makerandom_octet );
use Crypt::CBC;
use Digest::HMAC_SHA1 qw(hmac_sha1 hmac_sha1_hex);
use kIKE::kHelpers;
use kIKE::kConsts;
use kIKE::kGen;
use kIKE::kDec;
use kIKE::kKeyStream;
use kIKE::kEncryptionMaterial;
use kIKE::kPrint;

use kCrypt::AES_CTR;
use kCrypt::AES_XCBC;


our @ISA = qw(Exporter kIKE::kConsts kIKE::kGen kIKE::kDec);

our @EXPORT = qw(
	kBuildIKEv2
	kBuildIKESecurityAssociationInitializationRequest
	kBuildIKESecurityAssociationInitializationResponse
	kGenDHPublicKey
	kComputeDHSharedSecret
	kPrepareIKEEncryption
	kParseIKEMessage
	kParseIKESecurityAssociationInitializationRequest
	kParseIKESecurityAssociationInitializationResponse
	kBuildSecurityAssociationPayload
	kParseSecurityAssociationPayload
	kParseTrafficSelectorPayload
	kBuildTrafficSelectorPayload
	kBuildIKEAuthenticationRequest
	kBuildIKEAuthenticationResponse
	kParseIKEAuthenticationRequest
	kParseIKEAuthenticationResponse
	kPrepareSAEncryption
	kBuildCreateChildSecurityAssociationRequest
	kBuildCreateChildSecurityAssociationResponse
	kBuildRekeyIKESecurityAssociationRequest
	kBuildRekeyIKESecurityAssociationResponse
	kParseCreateChildSecurityAssociationRequest
	kParseCreateChildSecurityAssociationResponse
	kBuildInformationalRequest
	kBuildInformationalResponse
	kParseInformationalRequest
	kParseInformationalResponse

	kRegisterKeyingMaterial
	kUnregisterKeyingMaterial
);

our $TRUE = $kIKE::kConsts::TRUE;
our $FALSE = $kIKE::kConsts::FALSE;

=pod

=head1 NAME

kIKE::kIKE - Whole message building and parsing provider for IKEv2 test scripts.

=head1 SYNOPSIS

 use kIKE::kIKE;
 push @ISA, 'kIKE::kIKE';

=head1 PROPOSAL LIST FORMAT

The list of proposals to put in an SA payload. A reference to an
C<array of Proposal structure> described after in priority order. Acceptable
data for the values are in the same format as asked in
L<kGenSecurityAssociationPayload() function in the kIKE::kGen module|kIKE::kGen/kGenSecurityAssociationPayload()>
and
L<kDecSecurityAssociationPayload() function in the kIKE::kDec module|kIKE::kDec/kDecSecurityAssociationPayload()>
and related.

C<Proposal> is a hash containing the following elements:

=over

=item C<spi> (optional)

The protocol SPI to use.
If specified it must be a hex string with any prefix or suffix.

=item C<number> (optional)

The proposal number.
If specified in one proposal, it has to be specified in all proposals.

=item C<id>

The protocol ID concerning this proposal (IKE/AH/ESP).

=item C<transforms>

A reference to an C<Array of Transform structure>.

=back

C<Transform> is a hash containing the following elements:

=over

=item C<type>

The transformation type of this transform (C<ENCR>/C<INTEG>/...).

=item C<id>

The transformation id of this transform. The value depends on the type.

=item C<attributes>

A reference to an C<Array of Attribute structure>.

=back

C<Attribute> is a hash containing the following elements:

=over

=item C<type>

The type of this attribute.

=item C<value>

The value of this attribute. If the attribute is variable-length it must be the
binary data in a string. If it is not, it must be the hex string representing
the 2-bytes value.

=back

=head1 TRAFFIC SELECTOR LIST FORMAT

The list of traffic selectors to put in a TSi/TSr payload. A reference to an
C<array of Traffic Selector structure> described after. Acceptable data for
the values are in the same format as asked in 
L<the kGenTSSelector() function in the kIKE::kGen module|kIKE::kGen/kGenTSSelector()>
and
L<the kDecTSSelector() function in the kIKE::kDec module|kIKE::kDec/kDecTSSelector()>.

C<Traffic Selector> is a hash containing the following elements:

=over

=item C<type>

The Traffic Selector type of this Traffic Selector.

=item C<protocol>

The Internet protocol ID.

=item C<sport> C<eport>

The 'port' range of acceptable values for current protocol.

=item C<saddr> C<eaddr>

The address range of acceptable source/destination.

=back

=head1 METHODS

This package contains subs to build and parse whole IKEv2 Messages.

=cut

##############
# Prototypes #
##############

sub kBuildIKEv2($;$$);
sub kBuildIKESecurityAssociationInitializationCommon($$$\@$$;$);
sub kBuildIKESecurityAssociationInitializationRequest($\@$$;$);
sub kBuildIKESecurityAssociationInitializationResponse($$\@$$;$);
sub kGenDHPublicKey($);
sub kComputeDHSharedSecret($$);
sub kPrepareIKEEncryption($$$$$$$$$$$;$);
sub getPrfSub($);
sub cbcPadding($$$;$);
sub getEncrSub($;$);
sub getIntegSub($);
sub kParseIKEMessage($;$);
sub kParsePayloads($$$;$);
sub kParseIKESecurityAssociationInitializationCommon($$);
sub kParseIKESecurityAssociationInitializationRequest($);
sub kParseIKESecurityAssociationInitializationResponse($);
sub kParseAnyPayload($$$;$);
sub kBuildSecurityAssociationPayload($;$$);
sub kParseSecurityAssociationPayload($);
sub kParseTrafficSelectorPayload($);
sub kBuildTrafficSelectorPayload($$;$$);
sub kBuildIKEAuthenticationCommon($$$$$$$$$$$$$$$;%);
sub kBuildIKEAuthenticationRequest($$$$$$$$$$$$$$;%);
sub kBuildIKEAuthenticationResponse($$$$$$$$$$$$$$;%);
sub kParseIKEAuthenticationCommon($$);
sub kParseIKEAuthenticationRequest($);
sub kParseIKEAuthenticationResponse($);
sub kPrepareSAEncryption($$$$$$$;$);
sub kBuildCreateChildSecurityAssociationCommon($$$$$$$$$$;$);
sub kBuildCreateChildSecurityAssociationRequest($$$$$$$$$$);
sub kBuildCreateChildSecurityAssociationResponse($$$$$$$$$$);
sub kBuildRekeyIKESecurityAssociationRequest($$$$$$$);
sub kBuildRekeyIKESecurityAssociationResponse($$$$$$$);
sub kParseCreateChildSecurityAssociationCommon($);
sub kParseCreateChildSecurityAssociationRequest($);
sub kParseCreateChildSecurityAssociationResponse($);
sub kBuildInformationalCommon($$$$$$;%);
sub kBuildInformationalRequest($$$$$;%);
sub kBuildInformationalResponse($$$$$;%);
sub kParseInformationalCommon($);
sub kParseInformationalRequest($);
sub kParseInformationalResponse($);

########
# Data #
########

# Hash of reference to subs for payload parsing.
my %decodingFunctions = (
	SA => \&kParseSecurityAssociationPayload,
	KE => \&kDecKeyExchangePayload,
	IDi => \&kDecIdentificationIPayload,
	IDr => \&kDecIdentificationRPayload,
	CERT => \&kDecCertificatePayload,
	CERTREQ => \&kDecCertificateRequestPayload,
	AUTH => \&kDecAuthenticationPayload,
	'Ni, Nr' => \&kDecNoncePayload,
	N => \&kDecNotifyPayload,
	D => \&kDecDeletePayload,
	V => \&kDecVendorIDPayload,
	TSi => \&kDecTrafficSelectorIPayload,
	TSr => \&kDecTrafficSelectorRPayload,
	E => \&kDecEncryptedPayload,
	CP => \&kDecConfigurationPayload,
	EAP => \&kDecEAPPayload,
);



sub
kBuildIKEv2($;$$)
{
	my ($def, $material, $is_initiator) = @_;

	if(ref($def) ne 'ARRAY') {
		kCommon::kLogHTML('<FONT COLOR="#ff0000" SIZE="7"><U><B>'.
			'bug: must not reach here.</B></U></FONT>');

		return(undef);
	}

	if($#$def < 0) {
		kCommon::kLogHTML('<FONT COLOR="#ff0000" SIZE="7"><U><B>'.
			'bug: must not reach here.</B></U></FONT>');

		return(undef);
	}

	for(my $d = 0; $d <= $#$def; $d ++) {
		if(ref($def->[$d]) ne 'HASH') {
			kCommon::kLogHTML('<FONT COLOR="#ff0000" SIZE="7"><U><B>'.
				'bug: must not reach here.</B></U></FONT>');

			return(undef);
		}

		unless(exists($def->[$d]->{'self'})) {
			kCommon::kLogHTML('<FONT COLOR="#ff0000" SIZE="7"><U><B>'.
				'bug: must not reach here.</B></U></FONT>');

			return(undef);
		}
	}

	if($def->[0]->{'self'} ne 'HDR') {
		kCommon::kLogHTML('<FONT COLOR="#ff0000" SIZE="7"><U><B>'.
			'bug: must not reach here.</B></U></FONT>');

		return(undef);
	}

	return(kGenIKEv2($def, $material, $is_initiator));
}



###################
# Implementations #
###################

=pod

=head2 kBuildIKESecurityAssociationInitializationCommon()

Builds IKE_SA_INIT message.

B<This function is not intended to be called by any programs outside the
library. Please use one of 
L</kBuildIKESecurityAssociationInitializationRequest()> and
L</kBuildIKESecurityAssociationInitializationResponse()> instead.>

=head3 Parameters

=over

=item B<Initiator SPI>

The SPI for the initiator. It has to be a 16-digit hex string without prefix nor suffix.

=item B<Responder SPI>

The SPI for the responder. It has to be a 16-digit hex string without prefix nor suffix.

=item B<Request>

Flag indicating if the generated IKE_SA_INIT message is for a request or a
response. The request comes with no doubt from the original initiator and
the reponse from the original responder. It is implicit to the usage of this message.

=item B<Proposal list>

See L</PROPOSAL LIST FORMAT>.

=item B<Message ID>

ID of this message. Must be 0. Provided for easier reading of calling scripts.

=item B<D-H Group>

The Diffie-Hellman group to use in the KE payload.

=item B<Cookie> (optional)

The cookie to send if needed.

=back

=head3 Return value

=over

=item C<Message data>

The string containing the binary data of the message.

=item C<Nonce>

The nonce generated for this message. It is a Math::BigInt.

=item C<Nonce length>

The length of the nonce, in bytes.

=item C<Diffie-Hellman>

The Crypt::DH containing the generated Diffie-Hellman data.

=back

=cut

sub kBuildIKESecurityAssociationInitializationCommon($$$\@$$;$) {
	# Read parameters.
	my ($initSPI, $respSPI, $request, $proposalsRef, $messID, $group, $cookie) = @_;
	# Define variables.
	my $paydata;
	my $paytype;
	my $nonce;
	my $len;
	my $dh;
	my $key;
	my $proposal;
	
	# Generate the public key.
	($dh, $key) = kGenDHPublicKey($group);
	# Generate the nonce and its paylaod.
	($paydata, $paytype, $nonce, $len) = kGenNoncePayload();
	# Generate the KE payload.
	($paydata, $paytype) = kGenKeyExchangePayload($group, $key, $paytype, $paydata);
	# Generate the SA payload.
	($paydata, $paytype) = kBuildSecurityAssociationPayload($proposalsRef, $paytype, $paydata);
	# Generate Cookie.
	($paydata, $paytype) = kGenNotifyPayload(0, 0, 'COOKIE', '', $cookie, $paytype, $paydata) if $cookie;
	# Generate header and return result.
	return (kGenIKEHeader(
		$initSPI, $respSPI, 	2, 0, 'IKE_SA_INIT',
		$request ? 1 : 0, 0, $request ? 0 : 1,
		$messID, $paytype, $paydata
	), $nonce, $len, $dh);
}

=pod

=head2 kBuildIKESecurityAssociationInitializationRequest()

Builds IKE_SA_INIT Request message.

=head3 Parameters

=over

=item B<Initiator SPI>

The SPI for the initiator. It has to be a 16-digit hex string without prefix nor suffix.

=item B<Proposal list>

See L</PROPOSAL LIST FORMAT>.

=item B<Message ID>

ID of this message. Must be 0. Provided for easier reading of calling scripts.

=item B<D-H Group>

The Diffie-Hellman group to use in the KE payload.

=item B<Cookie> (optional)

The cookie to send if needed.

=back

=head3 Return value

=over

=item C<Message data>

The string containing the binary data of the message.

=item C<Nonce>

The nonce generated for this message. It is a Math::BigInt.

=item C<Nonce length>

The length of the nonce, in bytes.

=item C<Diffie-Hellman>

The Crypt::DH containing the generated Diffie-Hellman data.

=back

=cut

sub kBuildIKESecurityAssociationInitializationRequest($\@$$;$) {
	# Read parameters.
	my ($initSPI, $proposals, $messID, $group, $cookie) = @_;

	# Call common building function.
	kBuildIKESecurityAssociationInitializationCommon(kIKE::kHelpers::as_hex2($initSPI, $CONSTS->{'IKE_SA_SPI_STRLEN'}),
							 '0000000000000000',
							 $TRUE,
							 @{$proposals},
							 $messID,
							 $group,
							 $cookie);
}

=pod

=head2 kBuildIKESecurityAssociationInitializationResponse()

Builds IKE_SA_INIT Response message.

=head3 Parameters

=over

=item B<Initiator SPI>

The SPI for the initiator. It has to be a 16-digit hex string without prefix nor suffix.

=item B<Responder SPI>

The SPI for the initiator. It has to be a 16-digit hex string without prefix nor suffix.

=item B<Proposal list>

See L</PROPOSAL LIST FORMAT>.

=item B<Message ID>

ID of this message. Must be 0. Provided for easier reading of calling scripts.

=item B<D-H Group>

The Diffie-Hellman group to use in the KE payload.

=item B<Cookie> (optional)

The cookie to send if needed.

=back

=head3 Return value

=over

=item C<Message data>

The string containing the binary data of the message.

=item C<Nonce>

The nonce generated for this message. It is a Math::BigInt.

=item C<Nonce length>

The length of the nonce, in bytes.

=item C<Diffie-Hellman>

The Crypt::DH containing the generated Diffie-Hellman data.

=back

=cut

sub kBuildIKESecurityAssociationInitializationResponse($$\@$$;$) {
	# Read parameters.
	my ($initSPI, $respSPI, $proposals, $messID, $group, $cookie) = @_;
	# Call common building function.
	kBuildIKESecurityAssociationInitializationCommon($initSPI,
		$respSPI, $FALSE, @{$proposals}, $messID, $group, $cookie);
}

=pod

=head2 kGenDHPublicKey()

Prepares Diffie-Hellman exchange. Creates the DH object and generate a random
value to use as my secret.

=head3 Parameters

=over

=item B<D-H Group>

This is the desired Diffie-Hellman group. Groups are defined in RFC4306
Appendix B and in RFC3526. You can either enter the number or the name of DH Group.

=back

=head3 Return value

=over

=item B<DH object>

This is the Crypt::DH object containing the key data. It is used to create the
shared secret after receiving the other hand public key.

=item B<Public key>

This is the Public key extracted from DH object and saved as a Math::BigInt for
sending it directly.

=back

=cut

sub kGenDHPublicKey($) {
	# Read group.
	my $group = shift;
	# Get public parameters.
	my $prime = kDHPrime($group);
	my $gen = kDHGenerator($group);
	# Initialize container.
	my $dh = kCrypt::DH->new(p => $prime, g => $gen);
	# Generate keys.
	$dh->generate_keys;
	# Return result.
	return ($dh, $dh->pub_key);
}

=pod

=head2 kComputeDHSharedSecret()

Finalizes Diffie-Hellman exchange. Computes the shared secret from the other-end public key.

=head3 Parameters

=over

=item B<Crypt::DH object>

This is the Crypt::DH object returned when creating the Diffie-Hellman values.

=item B<Other public key>

This is the other end public key with which we'll be able to generate the shared secret.

=back

=head3 Return value

=over

=item B<Shared secret>

The shared secret to use in the computation of the SKEYSEED.

=back

=cut

sub kComputeDHSharedSecret($$) {
	# Read parameters
	my ($dh, $otherPublic) = @_;
	# Return computed secret.
	return $dh->compute_key($otherPublic);
}

=pod

=head2 kPrepareIKEEncryption()

Generates the encryption material for IKE Security Association to use in encryption.
It can also generate the materials for a rekey.

Internaly computes the SKEYSEED using one of these two formula:

When creating: SKEYSEED = prf(Ni | Nr, g^ir)

When rekeying: SKEYSEED = old_prf(SK_d, g^ir | Ni | Nr)

=head3 Parameters

=over

=item B<Encryption algorithm>

The name of the encryption algorithm to use in this material. See
L<constants|kIKE::kConsts/kTransformTypeID()> for available values.

=item B<Encryption algorithm attributes>

An array containing Security Association Attributes for encryption algorithm
as given by the
L<function kDecSAAttribute in kIKE::kDec module|kIKE::kDec/kDecSAAttribute()>.

=item B<Integrity algorithm>

The name of the integrity check algorithm to use in this material. See
L<constants|kIKE::kConsts/kTransformTypeID()> for available values.

=item B<Integrity algorithm attributes>

An array containing Security Association Attributes for integrity check
algorithm as given by the
L<function kDecSAAttribute in kIKE::kDec module|kIKE::kDec/kDecSAAttribute()>.

=item B<Pseudo-random function>

The name of the pseudo-random function to use in this material. See
L<constants|kIKE::kConsts/kTransformTypeID()> for available values.

=item B<Pseudo-random function attributes>

An array containing Security Association Attributes for pseudo-random function
as given by the
L<function kDecSAAttribute in kIKE::kDec module|kIKE::kDec/kDecSAAttribute()>.

=item B<Initiator nonce>

Nonce from the initiator of the exchange. It must be a hex string without any
prefix or suffix.

=item B<Responder nonce>

Same as B<Initiator nonce> for reponder.

=item B<Diffie-Hellman Shared Secret>

The Diffie-Hellman shared secret computed from the Diffie-Hellman exchange. Same
format as nonces.

=item B<SPIi>

Initiator SPI. Same format as nonces.

=item B<SPIr>

Responder SPI. idem.

=item B<Old Material> (used only for rekeying)

The encryption material that will be renewed. It is used only when rekeying.
It is optional when not rekeying.

=back

=head3 Return value

=over

=item B<Encryption Material>

The encryption material object created from the given information.

=back

=cut

sub kPrepareIKEEncryption($$$$$$$$$$$;$) {
	# Read parameters.
	my ($encr, $encrAttrs, $integ, $integAttrs, $prf, $prfAttrs, $ni, $nr, $dh, $spii, $spir, $oldMaterial) = @_;
	# Convert hex data to binary.

	$ni = pack('H*', $ni);
	$nr = pack('H*', $nr);
	$dh = pack('H*', $dh);
	$spii = pack('H*', $spii);
	$spir = pack('H*', $spir);
	my $sKeySeed;

	# Compute SKEYSEED.
	undef $oldMaterial if (ref $oldMaterial ne 'kIKE::kEncryptionMaterial');
	if (defined $oldMaterial) {
		# rekeying
		my $k = $oldMaterial->d;
		my $s = (defined($dh) ? ($dh) : ('')) . $ni . $nr;

		my $prfSeed = getPrfSub($prf);
		$sKeySeed = &$prfSeed($k, $s);
	}
	else {
		# generating keying material
		my $k = undef;
		my $s = $dh;

		if ($prf eq 'AES128_XCBC') {
			# AUTH_AES128_XCBC algorithm needs fixed key length
			# The length is 128 bits
			$k = substr($ni, 0, 8) . substr($nr, 0, 8);
		}
		else {
			$k = $ni . $nr;
		}

		my $prfSeed = getPrfSub($prf);
		$sKeySeed = &$prfSeed($k, $s);
	}

	# Create key stream.
	my $keyStream = kIKE::kKeyStream->new(
		getPrfSub($prf),
		$sKeySeed,
		$ni . $nr . $spii . $spir
	);

	# Create material.
	my %keymat_args = (
		'encr_alg'	=> $encr,
		'integ_alg'	=> $integ,
		'prf_alg'	=> $prf,
	);
	my $material = kIKE::kEncryptionMaterial->new(%keymat_args);
	my %attrs = (
			$encr => $encrAttrs,
			$integ => $integAttrs,
			$prf => $prfAttrs
	);

	# Extract keys.
	if (not defined $oldMaterial) {
		$material->generateIKEMaterial($keyStream, $encr, $prf, $integ, \%attrs);
	}
	else {
		$material->generateRekeyedIKEMaterial($keyStream, $encr, $prf, $integ, \%attrs);
	}

	# Generate cryptographic functions and associate.
	my ($encrSub, $decrSub) = getEncrSub($encr, $encrAttrs);
	my $prfSub = getPrfSub($prf);
	my $integSub = getIntegSub($integ);
	$material->encr($encrSub);
	$material->decr($decrSub);
	$material->prf($prfSub);
	$material->integ($integSub);

	# Return generated material.
	return $material;
}

=pod

=head2 getPrfSub()

Generates wrappers for Pseudo-random functions.

B<This function is not intended to be called by any programs outside the
library.>

=head3 Parameters

=over

=item B<Pseudo-random function>

The name of the pseudo-random function as defined in RFC4306 3.3.2 without 'PRF_' prefix.

=back

=head3 Return value

=over

=item B<Prf sub>

The sub that will do the calculation as abinary string and taking two
parameters the key and the data in this order which have to be coded the same way.

=back

=cut

sub getPrfSub($) {
	# Get prf algorithm.
	my $prf = shift;
	my $prfSub;
	# Select and define prf wrapping function.
	if ($prf eq 'HMAC_SHA1') {
		$prfSub = sub {
			my ($K, $S) = @_;
			return hmac_sha1($S, $K);
		};
	}
	elsif ($prf eq 'AES128_XCBC') {
		$prfSub = sub {
			my ($K, $S) = @_;
			return(aes_xcbc_prf_128($K, $S));
		};
	}
	# Unsupported prf case.
	else {
		die ('Cannot generate prf wrapper sub: Unknown prf (' . $prf . ').');
	}
	# Return defined function.
	return $prfSub;
}

=pod

=head2 cbcPadding()

Computes padding for encryption and remove the padding for decryption.

B<This function is not intended to be called directly by any programs outside
the library.>

=head3 Parameters

=over

=item B<Data block>

=item B<Block size>

=item B<Direction>

Supported values: 'e', 'd'.

=item B<Remaining Padding length> (optional)

A reference to the scalar that will receive the remaining padding length to renove.

=back

=head3 Return value

=over

=item B<Resultant block>

=back

=cut

sub cbcPadding($$$;$) {
	# Read parameters.
	my ($block, $blockSize, $direction, $refRemainingPad) = @_;
	# Select direction.
	if ($direction eq 'e') { # Encryption
		# Computing padding length.
		my $padLen = $blockSize - length($block) - 1;
		# Generate and return padded block.
		return $block . ($padLen ? Crypt::Random::makerandom_octet(Length => $padLen) : '') . pack('C', $padLen);
	}
	elsif ($direction eq 'd') { # Decryption
		# Extract padding length
		my $padLen = unpack('C', substr($block, -1)) + 1;
		# Act with definition of the reference to save the remaining pad length.
		if ((defined $refRemainingPad) && (ref($refRemainingPad) eq 'SCALAR')) {
			# Inform caller about remaining pad to remove if more than one block.
			$$refRemainingPad = 0;
			if ($padLen > $blockSize) {
				$$refRemainingPad = $padLen - $blockSize;
				$padLen = $blockSize;
			}
		}
		else {
			$padLen = $blockSize if $padLen > $blockSize;
		}
		# Remove padding and return result.
		return substr($block, 0, $blockSize - $padLen);
	}
	# Should not be reached.
	return '';
};


=pod

=head2 getEncrSub()

Generates wrappers for encryption adn decryption functions.

B<This function is not intended to be called by any programs outside the
library.>

=head3 Parameters

=over

=item B<Encryption algorithm>

The name of the encryption algorithm as defined in RFC4306 3.3.2 without 'ENCR_' prefix.

=back

=head3 Return value

=over

=item B<Encryption sub>

The sub that will encrypt as binary data and taking two parameters
the key, the "plaintext" and IV in this order which have all to be binary strings.

=item B<Decryption sub>

The sub that will decrypt as binary data and taking two parameters
the key, the "cyphertext" and IV in this order which have all to be binary strings.

=back

=cut

sub getEncrSub($;$) {
	# Get encryption algorithm and parameters.
	my ($encr, $keyLength) = @_;
	my $encrSub;
	my $decrSub;
	# Select and define encryption and decryption wrapping functions.
	if ($encr eq '3DES') { #DES-EDE3-CBC
		$encrSub = sub {
			my ($K, $S, $IV) = @_;
			my $tripleDES = Crypt::CBC->new(
				-key => $K,
				-cipher	=> 'DES_EDE3',
				-header	=> 'none',
				-iv => $IV,
				-literal_key => 1,
				-padding => \&cbcPadding,
			);
			return $tripleDES->encrypt($S);
		};
		$decrSub = sub {
			my ($K, $S, $IV) = @_;
			my $remainPad = 0;
			my $tripleDES = Crypt::CBC->new(
				-key => $K,
				-cipher	=> 'DES_EDE3',
				-header	=> 'none',
				-iv => $IV,
				-literal_key => 1,
				-padding => sub { return cbcPadding $_[0], $_[1], $_[2], \$remainPad; },
			);
			my $ret = $tripleDES->decrypt($S);
			return ($remainPad) ? substr($ret, 0, -$remainPad) : $ret;
		};
	}
	elsif ($encr eq 'AES_CBC') {
		$encrSub = sub {
			my ($K, $S, $IV) = @_;
			my $aes_cbc = Crypt::CBC->new(
				-key		=> $K,
				-keysize	=> length($K),
				-cipher		=> 'Rijndael',
				-header		=> 'none',
				-iv		=> $IV,
				-literal_key	=> 1,
				-padding	=> \&cbcPadding,
			);
			return($aes_cbc->encrypt($S));
		};
		$decrSub = sub {
			my ($K, $S, $IV) = @_;
			my $remainPad = 0;
			my $aes_cbc = Crypt::CBC->new(
				-key		=> $K,
				-keysize	=> length($K),
				-cipher		=> 'Rijndael',
				-header		=> 'none',
				-iv		=> $IV,
				-literal_key	=> 1,
				-padding	=> sub { return(cbcPadding($_[0], $_[1], $_[2], \&remainPad)); },
			);
			my $ret = $aes_cbc->decrypt($S);
			return($remainPad ? substr($ret, 0, -$remainPad) : $ret);
		};
	}
	elsif ($encr eq 'AES_CTR') {
		$encrSub = sub {
			my ($K, $S, $NONCE, $IV) = @_;
			my $aes_ctr = kCrypt::AES_CTR->new($K, $NONCE, $IV);
			return($aes_ctr->encrypt($S));
		};
		$decrSub = sub {
			my ($K, $S, $NONCE, $IV) = @_;
			my $aes_ctr = kCrypt::AES_CTR->new($K, $NONCE, $IV);
			return($aes_ctr->decrypt($S));
		};
	}
	elsif ($encr eq 'NULL') {
		$encrSub = sub {
			my ($K, $S, $IV) = @_;
			return($S);
		};
		$decrSub = sub {
			my ($K, $S, $IV) = @_;
			return($S);
		};
	}
	# Unsupported algorithm case.
	else {
		die ('Cannot generate encryption wrapper sub: Unknown encryption (' . $encr . ').');
	}
	# Return defined functions.
	return ($encrSub, $decrSub);
}

=pod

=head2 getIntegSub()

Generates wrappers for integrity functions.

B<This function is not intended to be called by any programs outside the
library.>

=head3 Parameters

=over

=item B<Integrity algorithm>

The name of the integrity algorithm as defined in RFC4306 3.3.2 without 'AUTH_' prefix.

=back

=head3 Return value

=over

=item B<Integrity sub>

The sub that will do the calculation as a binary string and taking two
parameters the key and the data in this order which have all to be binary strings.

=back

=cut

sub getIntegSub($) {
	# Get integrity algorithm.
	my $integ = shift;
	my $integSub;
	# Select and define integrity wrapper function.
	if ($integ eq 'HMAC_SHA1_96') {
		$integSub = sub {
			my ($K, $S) = @_;
			return substr(hmac_sha1($S, $K), 0, 12);
		};
	}
	elsif ($integ eq 'AES_XCBC_96') {
		$integSub = sub {
			my ($K, $S) = @_;
			return(aes_xcbc_mac_96($K, $S));
		};
	}
	elsif ($integ eq 'NONE') {
		printf("select INTEG_NONE\n");
		return(undef);
	}
	# Unsupported algorithm case.
	else {
		die ('Cannot generate integrity wrapper sub: Unknown integrity (' . $integ . ').');
	}
	# Return defined function.
	return $integSub;
}

=pod

=head2 kParseIKEMessage()

Parses any IKE Message and provide a representation of it.

=head3 Parameters

=over

=item B<Message data>

The content of the IKE Message.

=item B<Encryption material> (optional)

The L<kIKE::kEncryptionMaterial object|kIKE::kEncryptionMaterial> containing
encryption information for the corresponding IKE security association. User
may have to first L<decrypt the IKE Header|kIKE::kDec/kDecIKEHeader> alone to
get the SPI associated to the encryption channel.

=back

=head3 Return value

=over

=item B<Message content>

The content of the IKE message by field. It is made of an array of payloads
starting with the IKE Header. Each entry is a hash containing the data. See
L<kDecIKEHeader in kIKE::kDec module|kIKE::kDec/kDecIKEHeader> for the data
contained in the IKE Header hash (except payloads key) and see
L<kParsePayloads function|/kParsePayloads()> for the format of each payload.

=back

=cut

sub kParseIKEMessage($;$) {
	# Read parameters.
	my ($data, $material) = @_;
	# Decode header.
	my $header = kDecIKEHeader($data);
	# Adapt result.
	$header->{length} = $header->{datalen};
	undef $header->{datalen};
	my $payloads = $header->{payloads};
	undef $header->{payloads};
	# Process payloads.
	my @payloads = kParsePayloads($payloads, $header->{nexttype}, $header->{initiator}, $material);
	# Add header in payloads' offset.
	foreach my $entry (@payloads) {
		$entry->{offset} += 28; # 28: size of IKE header
	}
	# Rebuild and return decoded data.
#	return @{kIKE::kHelpers::rebuildStructure({$header, @payloads})};
	my @array = ($header, @payloads);
	return @{kIKE::kHelpers::rebuildStructure(\@array)};
}

=pod

=head2 kParsePayloads()

Parses a payloads from a partial IKE message starting on the boundary of a payload.
It provide a representation of the payloads in this data.

B<This function is not intended to be called by any programs outside the
library. Please consider parsing the entire message using
L</kParseIKEMessage()>.>

=head3 Parameters

=over

=item B<Message data>

The partial message data to parse.

=item B<First payload type>

The payload type of the first payload in the message data. Can be an unknow
value to force skipping.

=item B<Encryption Material> (optional)

The L<kIKE::kEncryptionMaterial object|kIKE::kEncryptionMaterial> containing
encryption information for the corresponding IKE security association.

=back

=head3 Return value

=over

=item B<Payloads content>

The payloads content's array. Each entry is a hash containing a least the
following keys: nexttype, offset, length, critical. Offset is from the start of
the provided data. In addition to this information, each key provided by the
C<kDec*> function from L<the kIKE::kDec module|kIKE::kDec> is used except for the
C<payloads> key which is removed and use for the next payloads. When the
payload have substructures, it is a C<kParse*> function defined in this file
that is called an make it the good way.

=back

=cut

sub kParsePayloads($$$;$) {
	# Read parameters.
	my ($payloads, $nexttype, $isInit, $material) = @_;
	# Initialize result.
	my @result = ();
	my $offset = 0;
	# Run while there is a following payload.
	while ($nexttype) {
		# Process current payload.
		my $payload = kParseAnyPayload($payloads, $nexttype, $isInit, $material);
		# Define common values.
		$payload->{critical} = 0 unless exists $payload->{critical};
		$payload->{offset} = $offset;
		$payload->{length} = length($payloads) - length($payload->{payloads});
		# Move forward to the next payload.
		$nexttype = $payload->{nexttype};
		$offset += $payload->{length};
		$payloads = $payload->{payloads};
		undef $payload->{payloads};
		# Save payload.
		push @result, $payload;
	}
	# Return processed payloads list.
	return @result;
}

=pod

=head2 kParseIKESecurityAssociationInitializationCommon()

Parses an IKE_SA_INIT message.

B<This function is not intended to be called by any programs outside the
library. Please use one of 
L</kParseIKESecurityAssociationInitializationRequest()> and
L</kParseIKESecurityAssociationInitializationResponse()> instead.>

=head3 Parameters

=over

=item B<Parsed message>

The parsed message data comming form a call to L</kParseIKEMessage>.
The message content is supposed to be valid.

=item B<Request>

Indicates if the parsed message is a request or not (not guessed).

=item B<Diffie-Hellman parameters> (optional in request)

The Crypt::DH object to use.

=back

=head3 Return Value

=over

=item B<Message data>

Hash containing these entry:

=over

=item C<spi>

SPI for the other side.

=item C<nonce>

Other side's nonce.

=item C<nonceLen>

The length of the nonce.

=item C<secret> (not given in request)

Diffie-Hellman shared secret.

=item C<public>

Diffie-Hellman public value.

=item C<protocols>

Array of proposal protocols.

=item C<sequence>

Array of proposal sequence number.

=item C<encr>

Array of Encryption algorithm name.

=item C<encrAttr>

Array of Encryption algorithm attributes.

=item C<integ>

Array of Integrity check algorithm.

=item C<integAttr>

Array of Integrity check algorithm attributes.

=item C<prf>

Array of Pseudo-random function.

=item C<prfAttr>

Array of Pseudo-random function attributes.

=back

NB: All arrays are in the same order.

=back

=cut

sub kParseIKESecurityAssociationInitializationCommon($$) {
	# Read parameters.
	my ($message, $isRequest) = @_;
	# Read remote SPI.
	my $distSPI = (not $isRequest) ? ($message->[0]->{respSPI}) : ($message->[0]->{initSPI});
	my $messID = $message->[0]->{messID};
	# Discover payloads location.
	my $saIndex = 1;
	$saIndex++ while (($message->[$saIndex - 1]->{nexttype} ne 'SA') && (scalar(@{$message}) > $saIndex));
	my $keIndex = 1;
	$keIndex++ while (($message->[$keIndex - 1]->{nexttype} ne 'KE') && (scalar(@{$message}) > $keIndex));
	my $nonceIndex = 1;
	$nonceIndex++ while (($message->[$nonceIndex - 1]->{nexttype} ne 'Ni, Nr') && (scalar(@{$message}) > $nonceIndex));
	my $cookieIndex = undef;
	for (my $i = 0; $i < scalar(@{$message}); $i++) {
		unless ($message->[$i]->{'nexttype'} eq 'N') {
			next;
		}
		unless (defined($message->[$i + 1])) {
			next;
		}
		if ($message->[$i + 1]->{'type'} eq 'COOKIE') {
			$cookieIndex = $i + 1;
		}
	}

	# check if message included payloads other than Notify payload
	if ($saIndex == scalar(@{$message}) || $keIndex == scalar(@{$message})) {
		# includes only Notify payload
		my $cookie = $message->[$cookieIndex]->{'data'} if (defined($cookieIndex));
		my $result = {
			'spi'		=> $distSPI,
			'messID'	=> $messID,
		};
		$result->{'cookie'} = $cookie if (defined($cookieIndex));
		return($result);
	}

	# Get simple values.
	my $nonce = $message->[$nonceIndex]->{nonce};
	my $noncelen = $message->[$nonceIndex]->{nonceLen};
	my $publicKey = $message->[$keIndex]->{publicKey};
	my $dh_group = $message->[$keIndex]->{group};
	my $cookie = $message->[$cookieIndex]->{'data'} if (defined($cookieIndex));

	# Get SA proposals
	my @proposals = @{$message->[$saIndex]->{proposals}};
	# Define extraction function creator.
	my $createExtractSub = sub {
		my ($type, $field, @proposals) = @_;
		my $extractSub = sub {
			my @transforms = @{$_->{transforms}};
			foreach my $transform (@transforms) {
				if ($transform->{type} eq $type) {
					return $transform->{$field};
				}
			}
		};
		return $extractSub;
	};
	# Extract arrays of proposals elements.
	my @protocols = map { $_->{id}; } @proposals;
	my @sequence = map { $_->{number}; } @proposals;
	my @encr = map { &{&{$createExtractSub}('ENCR', 'id')}($_) } @proposals;
	my @encrAttr = map { &{&{$createExtractSub}('ENCR', 'attributes')}($_) } @proposals;
	my @integ = map { &{&{$createExtractSub}('INTEG', 'id')}($_) } @proposals;
	my @integAttr = map { &{&{$createExtractSub}('INTEG', 'attributes')}($_) } @proposals;
	my @prf = map { &{&{$createExtractSub}('PRF', 'id')}($_) } @proposals;
	my @prfAttr = map { &{&{$createExtractSub}('PRF', 'attributes')}($_) } @proposals;
	# Return extracted content.
	my $result = {
		spi => $distSPI,
		messID => $messID,
		nonce => $nonce,
		nonceLen => $noncelen,
		dh_group => $dh_group,
		public => $publicKey,
		protocol => \@protocols,
		sequence => \@sequence,
		encr => \@encr,
		encrAttr => \@encrAttr,
		integ => \@integ,
		integAttr => \@integAttr,
		prf => \@prf,
		prfAttr => \@prfAttr
	};
	return $result;
}

=pod

=head2 kParseIKESecurityAssociationInitializationRequest()

Parses an IKE_SA_INIT Request.

=head3 Parameters

=over

=item B<Parsed message>

The parsed message data comming form a call to L</kParseIKEMessage()>. The message
content is supposed to be valid.

=back

=head3 Return Value

=over

=item B<Message data>

Hash containing these entry:

=over

=item C<spi>

Initiator's SPI.

=item C<nonce>

Initiator's nonce.

=item C<nonceLen>

The length of the nonce.

=item C<secret>

Diffie-Hellman shared secret.

=item C<protocols>

Array of proposal protocols.

=item C<sequence>

Array of proposal sequence number.

=item C<encr>

Array of Encryption algorithm name.

=item C<encrAttr>

Array of Encryption algorithm attributes.

=item C<integ>

Array of Integrity check algorithm.

=item C<integAttr>

Array of Integrity check algorithm attributes.

=item C<prf>

Array of Pseudo-random function.

=item C<prfAttr>

Array of Pseudo-random function attributes.

=back

All array entries are associated. One index give the data from one proposal.

=back

=cut

sub kParseIKESecurityAssociationInitializationRequest($) {
	# Call common parsing function.
	my $ret = kParseIKESecurityAssociationInitializationCommon(shift, $TRUE);
	# Extract only the first proposal from proposals' data.
	foreach my $key qw(protocol sequence encr encrAttr integ integAttr prf prfAttr) {
		if (ref $ret->{$key} eq 'ARRAY') {
			$ret->{$key} = $ret->{$key}->[0];
		}
	}
	return $ret;
}

=pod

=head2 kParseIKESecurityAssociationInitializationResponse()

Parses an IKE_SA_INIT Reply.

=head3 Parameters

=over

=item B<Parsed message>

The parsed message data comming form a call to L</kParseIKEMessage()>. The message
content is supposed to be valid.

=item B<Diffie-Hellman parameters>

The Crypt::DH object to use to compute secret.

=back

=head3 Return Value

=over

=item B<Message data>

Hash containing these entry:

=over

=item C<spi>

Responder's SPI.

=item C<nonce>

Responder's nonce.

=item C<nonceLen>

The length of the nonce.

=item C<secret>

Diffie-Hellman shared secret.

=item C<protocols>

Proposal protocol.

=item C<sequence>

Proposal sequence number.

=item C<encr>

Encryption algorithm name.

=item C<encrAttr>

Encryption algorithm attributes.

=item C<integ>

Integrity check algorithm.

=item C<integAttr>

Integrity check algorithm attributes.

=item C<prf>

Pseudo-random function.

=item C<prfAttr>

Pseudo-random function attributes.

=back

=back

=cut

sub kParseIKESecurityAssociationInitializationResponse($) {
	# Call common parsing function.
	my $ret = kParseIKESecurityAssociationInitializationCommon($_[0], $FALSE);
	# Extract only the first proposal from proposals' data.
	foreach my $key qw(protocol sequence encr encrAttr integ integAttr prf prfAttr) {
		if (ref $ret->{$key} eq 'ARRAY') {
			$ret->{$key} = $ret->{$key}->[0];
		}
	}
	return $ret;
}

=pod

=head2 kParseAnyPayload()

Dispatches payload parsing to the associated function or to the default one.
Special handling for the encrypted payload is done.

B<This function is not intended to be called by any programs outside the
library. Please consider parsing the entire message using
L</kParseIKEMessage()>.>

=head3 Parameters

=over

=item B<Payload data>

The payload data to parse. Also contain following payloads if exists.

=item B<Payload type>

The type of the payload to parse.

=item B<Is Initiator> (optional)

Flag indicating if the message come from initiator or responder.

=item B<Encryption Material> (optional)

Encryption material used to decrypt Encrypted Payload.

=back

=head3 Return value

The result of the call to the kDec or kParse method used to recognize the payload.

=cut

sub kParseAnyPayload($$$;$) {
	# Read parameters.
	my ($payload, $type, $isInit, $material) = @_;
	# Check for existance of a specific fonction to parse the payload.
	if (exists $decodingFunctions{$type}) { # Exists
		# Convert payload number to its name if necessary.
		$type = kPayloadType($type) if $type =~ m/^\d+$/ ;
		# Check for the Encrypted Payload.
		if (($type !~ m/^\d+$/) && ($type eq 'E')) { # It is.
			# Decode and decrypt the payload
			$payload = &{$decodingFunctions{$type}}($payload, $material, $isInit);
			# Decode the inner payloads.
			if (defined($material)) {
				$payload->{innerPayloads} = [
					kParsePayloads($payload->{payloads},
						       $payload->{nexttype},
						       $isInit, $material)
				];
			}
			# Define the inner and next payload types.
			$payload->{innerType} = $payload->{nexttype};
			$payload->{nexttype} = 0;
		}
		else { # It isn't, any other decodable.
			# Decode the payload.
			$payload = &{$decodingFunctions{$type}}($payload);
		}
	}
	else { # Not exists.
		# Decode the generic payload header and keep it as is.
		$payload = kIKE::kDec::kDecGenericPayloadHeader($payload);
	}
	# Return decoded payload.
	return $payload;
}

=pod

=head2 kBuildSecurityAssociationPayload()

Constructs a Security Association Payload and all its substructures.

=head3 Parameters

=over

=item B<Proposals list>

See L</PROPOSAL LIST FORMAT>.

=item B<Payload data> (optional)

The content of the following payloads to append.

=item B<Payload type> (optional)

The type of the first following payload.

=back

=head3 Return value

=over

=item B<Payload data>

The final data for this payload and the following.

=item B<Payload type>

The type of this payload.

=back

=cut

sub kBuildSecurityAssociationPayload($;$$) {
	# Read parameters.
	my ($proposalsList, $paytype, $paydata) = @_;
	# Dereference the proposal list.
	my @proposals = @{$proposalsList};
	my $proposal = '';
	# Process each proposal in the list form the last one.
	for (my $propIndex = scalar(@proposals) - 1; $propIndex >= 0; $propIndex--) {
		my $transform = '';
		# Dereference the transformation list.
		my @transforms = @{$proposals[$propIndex]->{transforms}};
		# Process each transform from the last one.
		for (my $transIndex = scalar(@transforms) - 1; $transIndex >= 0; $transIndex--) {
			my $attribute;
			# Dereference attributes list.
			my @attributes = @{$transforms[$transIndex]->{attributes}};
			# Process each attribute from the last one.
			for (my $attrIndex = scalar(@attributes) - 1; $attrIndex >=0; $attrIndex--) {
				# Generate the attribute.
				$attribute = kGenSAAttribute(
					$attributes[$attrIndex]->{type}, 
					$attributes[$attrIndex]->{value},
					$attribute
				);
			}
			# Generate the transform.
			$transform = kGenSATransform(
				$transforms[$transIndex]->{type},
				$transforms[$transIndex]->{id},
				$attribute,
				$transform
			);
		}
		# Define default value for number and spi.
		my $number = $propIndex + 1;
		my $spi = '';
		# Read the number and spi value if defined.
		$number = $proposals[$propIndex]->{number}
			if exists($proposals[$propIndex]->{number}) && defined($proposals[$propIndex]->{number});
		$spi = $proposals[$propIndex]->{spi}
			if exists($proposals[$propIndex]->{spi}) && defined($proposals[$propIndex]->{spi});
		# Compute spi size.
		my $spiSize = length($spi) / 2;
		# Generate the proposal.
		$proposal = kGenSAProposal(
			$number,
			$proposals[$propIndex]->{id},
			$spiSize, $spi,
			scalar(@{$proposals[$propIndex]->{transforms}}),
			$transform,
			$proposal
		);
	}
	# Generate and return the payload.
	return kGenSecurityAssociationPayload($proposal, $paytype, $paydata);
}

=pod

=head2 kParseSecurityAssociationPayload()

Parses a Security Association Payload with all its substructures.

=head3 Parameters

=over

=item B<Payload data>

The payload data. Can contain next payloads.

=back

=head3 Return value

The representation of the payload and its substructures as defined in 
L</PROPOSAL LIST FORMAT>.

=cut

sub kParseSecurityAssociationPayload($) {
	# Read parameter and decode it.
	my $SA = kDecSecurityAssociationPayload(shift);
	# Extract the proposals data from the decoded payload.
	my $proposals = $SA->{proposals};
	undef $SA->{proposals};
	return $SA if ($SA->{proposalsLen} < 4);
	my @propList = ();
	my $proposal;
	my $proposal_nexttype	= 0;
	# Process the proposals while the pseudo header doesn't indicates the last one.
	do {
		# Decode the proposal.
		$proposal = kDecSAProposal($proposals);
		# Extract the next proposals
		$proposals = $proposal->{nextdata};
		undef $proposal->{nextdata};
		# Extract the transforms
		my $transforms = $proposal->{transforms};
		$proposal_nexttype = $proposal->{nexttype};
		undef $proposal->{transforms};
		#undef $proposal->{nexttype}; # XXX: need to undef?
		my @transList = ();
		my $transform;
		my $transform_nexttype	= 0;
		# Process transforms if there is at least one.
		if ($proposal->{transformCount} > 0 ) {
			# Process transforms while the pseudo header doesn't indicates the end.
			do {
				# Decode the transformation.
				$transform = kDecSATransform($transforms);
				# Extract the next transformations
				$transforms = $transform->{nextdata};
				undef $transform->{nextdata};
				# Extract attributes.
				my $attributes = $transform->{attributes};
				$transform_nexttype = $transform->{nexttype};
				undef $transform->{attributes};
				#undef $transform->{nexttype}; # XXX: need to undef?
				my @attrList = ();
				my $attribute;
				# Process attributes while there is data to process.
				while (length ($attributes) > 0) {
					# Decode the attribute.
					$attribute = kDecSAAttribute($attributes);
					# Extract the next attributes.
					$attributes = $attribute->{nextdata};
					undef $attribute->{nextdata};
					# Save the attribute.
					push @attrList, $attribute;
				}
				# Save the transform with its decoded attributes.
				$transform->{attributes} = \@attrList;
				push @transList, $transform;
			}
			while ($transform_nexttype);
		}
		# Save the proposal with its decoded transforms.
		$proposal->{transforms} = \@transList;
		push @propList, $proposal;
	}
	while ($proposal_nexttype);
	# Return the payload with its decoded proposals.
	$SA->{proposals} = \@propList;
	return $SA;
}

=pod

=head2 kBuildTrafficSelectorPayload()

Constructs a Traffic Selector Payload and its selectors.

=head3 Parameters

=over

=item B<Selectors list>

See L</TRAFFIC SELECTOR LIST FORMAT>.

=item B<Is initiator>

Indicates if this payload is for the initiator or for the responder.

=item B<Payload data> (optional)

The content of the following payloads to append.

=item B<Payload type> (optional)

The type of the first following payload.

=back

=head3 Return value

=over

=item B<Payload data>

The final data for this payload and the following.

=item B<Payload type>

The type of this payload.

=back

=cut

sub kBuildTrafficSelectorPayload($$;$$) {
	# Read parameters
	my ($selectorsList, $isInit, $paytype, $paydata) = @_;
	# Dereference selectors list.
	my @selectors = @{$selectorsList};
	my $selector = '';
	# Process each selector from the last one.
	for (my $selectorIndex = scalar(@selectors) - 1; $selectorIndex >= 0; $selectorIndex--) {
		# Generate the selector.
		$selector = kGenTSSelector(
			$selectors[$selectorIndex]->{type},
			$selectors[$selectorIndex]->{protocol},
			$selectors[$selectorIndex]->{sport},
			$selectors[$selectorIndex]->{eport},
			$selectors[$selectorIndex]->{saddr},
			$selectors[$selectorIndex]->{eaddr},
			$selector
		);
	}
	# Generate and return the payload.
	return kGenTrafficSelectorPayload(scalar(@selectors), $selector, $isInit, $paytype, $paydata);
}

=pod

=head2 kBuildIKEAuthenticationCommon()

Builds an IKE_AUTH Message.

B<This function is not intended to be called by any programs outside the
library. Please use on of L</kBuildIKEAuthenticationRequest()> and
L</kBuildIKEAuthenticationResponse()> instead.>

=head3 Parameters

=over

=item B<Initiator SPI>

The SPI for the initiator. It has to be a 16-digit hex string without prefix nor suffix.

=item B<Responder SPI>

The SPI for the initiator. It has to be a 16-digit hex string without prefix nor suffix.

=item B<Request>

Flag indicating if the generated IKE_SA_INIT message is for a request or a
response. The request comes with no doubt from the original initiator and
the reponse from the original responder. It is implicit to the usage of this message.

=item B<Proposal list>

See L</PROPOSAL LIST FORMAT>.

=item B<Message ID>

ID of this message, should be one (1) or more.

=item B<Identification method>

Method used for identification.

=item B<Identification data>

Data for the identification method.

=item B<Authentication method>

Method used for authentication.

=item B<Authentication data>

Data used for authentication.

=item B<First message>

IKE_SA_INIT Message data from this side.

=item B<Other side nonce>

Nonce comming from the other side.

=item B<Traffic Selector Initiator>

See L</TRAFFIC SELECTOR FORMAT>. This one is for initiator.

=item B<Traffic Selector Responder>

See L</TRAFFIC SELECTOR FORMAT>. This one is for responder.

=item B<Notifications>

Hash of requested notification payloads associating id to data.

=item B<Encryption material>

The material for encryption.

=item B<Optional payloads>

Hash of optional payloads.

=over

=item C<IDr> (initiator only)

The original responder request identity. An array providing method followed by data.

=item C<CP>

The configuration payload. Format not yet defined.
TODO: Define the format.

=back

=back

=head3 Return value

=over

=item B<Message data>

The string containing the binary data of the message.

=back

=cut

sub kBuildIKEAuthenticationCommon($$$$$$$$$$$$$$$;%) {
	# Read parameters.
	my (
		$initSPI, $respSPI, $request, $proposals, $messageID,
		$idMethod, $idData,
		$authMethod, $authData, $firstMessage, $otherNonce,
		$tsInit, $tsResp,
		$notificationsRef, $material, %optionals
	) = @_;
	# Prepare variables.
	my $paydata;
	my $paytype;
	my %notifications = %{$notificationsRef};

	# Generate TS payload for responder
	($paydata, $paytype) = kBuildTrafficSelectorPayload(	$tsResp, 0);
	# Generate TS payload for initiator
	($paydata, $paytype) = kBuildTrafficSelectorPayload($tsInit, 1, $paytype, $paydata);
	# Generate SA payload.
	($paydata, $paytype) = kBuildSecurityAssociationPayload($proposals, $paytype, $paydata);
	# Generate N payload for NON_FIRST_FRAGMENT_ALSO if defined.
	($paydata, $paytype) = kGenNotifyPayload(0, 0, 'NON_FIRST_FRAGMENT_ALSO', '', '', $paytype, $paydata) if exists $notifications{NON_FIRST_FRAGMENT_ALSO};
	# Generate N payload for ESP_TFC_PADDING_NOT_SUPPORTED if defined.
	($paydata, $paytype) = kGenNotifyPayload(0, 0, 'ESP_TFC_PADDING_NOT_SUPPORTED', '', '', $paytype, $paydata) if exists $notifications{ESP_TFC_PADDING_NOT_SUPPORTED};
	# Generate N payload for USE_TRANSPORT_MODE if defined.
	($paydata, $paytype) = kGenNotifyPayload(0, 0, 'USE_TRANSPORT_MODE', '', '', $paytype, $paydata) if exists $notifications{USE_TRANSPORT_MODE};
	# Generate N payload(s) for IPCOMP_SUPPORTED if defined.
	if (exists $notifications{IPCOMP_SUPPORTED}) {
		# Check if we have one or multiple instances to create.
		if (ref $notifications{IPCOMP_SUPPORTED} eq 'ARRAY') { # Multiple
			# Dereference data array.
			my @ipcomp = @{$notifications{IPCOMP_SUPPORTED}};
			# Process each data from the last.
			for (my $i = scalar(@ipcomp) - 1; $i >= 0; --$i) {
				# Generate N payload for IPCOMP_SUPPORTED.
				($paydata, $paytype) = kGenNotifyPayload(
					0, 0, 'IPCOMP_SUPPORTED', '', $ipcomp[$i], $paytype, $paydata);
			}
		}
		else { # Unique
			# Generate N payload for IPCOMP_SUPPORTED.
			($paydata, $paytype) = kGenNotifyPayload(
				0, 0, 'IPCOMP_SUPPORTED', '', $notifications{IPCOMP_SUPPORTED}, $paytype, $paydata) 
		}
	}
	# TODO: CP payload
	# Generate AUTH payload, includes a temporary ID payload.
	($paydata, $paytype) = kGenAuthenticationPayload($material, $authMethod, $authData, $request,
		$firstMessage, $otherNonce, 	(kGenIdentificationPayload($idMethod, $idData, $request))[0],
		$paytype, $paydata);
	# Generate IDr payload if specified and we are in a request.
	($paydata, $paytype) = kGenIdentificationPayload($optionals{IDr}->[0], $optionals{IDr}->[1], 0, $paytype, $paydata) if defined($optionals{IDr}) && $request;
	# Generate N payload for HTTP_CERT_LOOKUP_SUPPORTED if defined.
	($paydata, $paytype) = kGenNotifyPayload(0, 0, 'HTTP_CERT_LOOKUP_SUPPORTED', '', '', $paytype, $paydata) if exists $notifications{HTTP_CERT_LOOKUP_SUPPORTED};
	# Generate N payload for INITIAL_CONTACT if defined.
	($paydata, $paytype) = kGenNotifyPayload(0, 0, 'INITIAL_CONTACT', '', '', $paytype, $paydata) if exists $notifications{INITIAL_CONTACT};
	# Generate ID payload.
	($paydata, $paytype) = kGenIdentificationPayload($idMethod, $idData, $request, $paytype, $paydata);
	# Generate Encrypted payload.
	($paydata, $paytype) = kGenEncryptedPayload($material, $request, $paytype, $paydata);
	# Generate header.
	($paydata) = kGenIKEHeader(
		$initSPI, $respSPI, 2, 0, 'IKE_AUTH',
		$request ? 1 : 0, 0, $request ? 0 : 1,
		$messageID, $paytype, $paydata
	);
	# Compute the checksum and return the resulting message.
	return kGenEncryptedPayloadChecksum($material, $request, $paydata);
}

=pod

=head2 kBuildIKEAuthenticationRequest()

Builds an IKE_AUTH Request.

=head3 Parameters

=over

=item B<Initiator SPI>

The SPI for the initiator. It has to be a 16-digit hex string without prefix nor suffix.

=item B<Responder SPI>

The SPI for the initiator. It has to be a 16-digit hex string without prefix nor suffix.

=item B<Proposal list>

See L</PROPOSAL LIST FORMAT>.

=item B<Message ID>

ID of this message, should be one (1) or more.

=item B<Identification method>

Method used for identification.

=item B<Identification data>

Data for the identification method.

=item B<Authentication method>

Method used for authentication.

=item B<Authentication data>

Data used for authentication.

=item B<First message>

IKE_SA_INIT Message data from this side.

=item B<Other side nonce>

Nonce comming from the other side.

=item B<Traffic Selector Initiator>

See L</TRAFFIC SELECTOR FORMAT>. This one is for initiator.

=item B<Traffic Selector Responder>

See L</TRAFFIC SELECTOR FORMAT>. This one is for responder.

=item B<Notifications>

Hash of requested notification payloads associating id to data.

=item B<Encryption material>

The material for encryption.

=item B<Optional payloads>

Hash of optional payloads.

=over

=item C<IDr>

The original responder request identity. An array providing method followed by data.

=item C<CP>

The configuration payload. Format not yet defined.
TODO: Define the format.

=back

=back

=head3 Return value

=over

=item B<Message data>

The string containing the binary data of the message.

=back

=cut

sub kBuildIKEAuthenticationRequest($$$$$$$$$$$$$$;%) {
	# Read parameters.
	my (
		$initSPI, $respSPI, $proposals, $messageID,
		$idMethod, $idData,
		$authMethod, $authData, $firstMessage, $otherNonce,
		$tsInit, $tsResp,
		$notificationsRef, $material, %optionals
	) = @_;
	# Call common building function.
	kBuildIKEAuthenticationCommon(
		$initSPI, $respSPI, $TRUE, $proposals, $messageID,
		$idMethod, $idData,
		$authMethod, $authData, $firstMessage, $otherNonce,
		$tsInit, $tsResp,
		$notificationsRef, $material, %optionals
	);
}

=pod

=head2 kBuildIKEAuthenticationResponse()

Builds an IKE_AUTH Request.

=head3 Parameters

=over

=item B<Initiator SPI>

The SPI for the initiator. It has to be a 16-digit hex string without prefix nor suffix.

=item B<Responder SPI>

The SPI for the initiator. It has to be a 16-digit hex string without prefix nor suffix.

=item B<Proposal list>

See L</PROPOSAL LIST FORMAT>.

=item B<Message ID>

ID of this message, should be one (1) or more.

=item B<Identification method>

Method used for identification.

=item B<Identification data>

Data for the identification method.

=item B<Authentication method>

Method used for authentication.

=item B<Authentication data>

Data used for authentication.

=item B<First message>

IKE_SA_INIT Message data from this side.

=item B<Other side nonce>

Nonce comming from the other side.

=item B<Traffic Selector Initiator>

See L</TRAFFIC SELECTOR FORMAT>. This one is for initiator.

=item B<Traffic Selector Responder>

See L</TRAFFIC SELECTOR FORMAT>. This one is for responder.

=item B<Notifications>

Hash of requested notification payloads associating id to data.

=item B<Encryption material>

The material for encryption.

=item B<Optional payloads>

Hash of optional payloads.

=over

=item C<IDr>

The original responder request identity. An array providing method followed by data.

=item C<CP>

The configuration payload. Format not yet defined.
TODO: Define the format.

=back

=back

=head3 Return value

=over

=item B<Message data>

The string containing the binary data of the message.

=back

=cut

sub kBuildIKEAuthenticationResponse($$$$$$$$$$$$$$;%) {
	# Read parameters.
	my (
		$initSPI, $respSPI, $proposals, $messageID,
		$idMethod, $idData,
		$authMethod, $authData, $firstMessage, $otherNonce,
		$tsInit, $tsResp,
		$notificationsRef, $material, %optionals
	) = @_;
	# Call common building function.
	kBuildIKEAuthenticationCommon(
		$initSPI, $respSPI, $FALSE, $proposals, $messageID,
		$idMethod, $idData,
		$authMethod, $authData, $firstMessage, $otherNonce,
		$tsInit, $tsResp,
		$notificationsRef, $material, %optionals
	);
}

=pod

=head2 kParseIKEAuthenticationCommon()

Parses an IKE_SA_INIT Request.

B<This function is not intended to be called by any programs outside the
library. Please use one of L</kParseIKEAuthenticationRequest()> and
L</kParseIKEAuthenticationResponse()> instead.>

=head3 Parameters

=over

=item B<Parsed message>

The parsed message data comming form a call to L</kParseIKEMessage()>. The message
content is supposed to be valid.

=item B<Request>

Flag indicating if the message is a request or not. (Not guessed)

=back

=head3 Return Value

=over

=item B<Message data>

Hash containing these entry:

=over

=item C<protocols>

Array of proposal protocols.

=item C<sequence>

Array of proposal sequence number.

=item C<spi>

Array of spi.

=item C<encr>

Array of Encryption algorithm name.

=item C<encrAttr>

Array of Encryption algorithm attributes.

=item C<integ>

Array of Integrity check algorithm.

=item C<integAttr>

Array of Integrity check algorithm attributes.

=item C<prf>

Array of Pseudo-random function.

=item C<prfAttr>

Array of Pseudo-random function attributes.

=item C<initSelectors>

Array of Traffic Selectors for initiator.

=item C<respSelectors>

Array of Traffic Selectors for responder.

=item C<notify>

Hash of notification type associated with their payloads.

=item C<identity>

Remote host identity.

=back

All array entries are associated. One index give the data from one proposal.
It doesn't applies to key that don't refers to proposals.

=back

=cut

sub kParseIKEAuthenticationCommon($$) {
	# Read parameters.
	my ($message, $isRequest) = @_;
	# Search for encrypted payload.
	my $messID = $message->[0]->{messID};
	my $eIndex = 1;
	$eIndex++ while (($message->[$eIndex - 1]->{nexttype} ne 'E') && (scalar(@{$message}) > $eIndex));
	my $iv = undef;
	my $icv = undef;

	# Enter in the encrypted payload.
	my @payloads = undef;
	if ($eIndex < scalar(@{$message})) {
		$iv = $message->[$eIndex]->{'iv'};
		$icv = $message->[$eIndex]->{'checksum'};
		@payloads = @{$message->[$eIndex]->{'innerPayloads'}};
		unshift @payloads,
			{
				'nexttype' => $message->[$eIndex]->{'innerType'},
			};
	}
	else {
		@payloads = @{$message};
	}

	# Discover payloads location.
	my $saIndex = 1;
	$saIndex++ while (($payloads[$saIndex - 1]->{nexttype} ne 'SA') && (scalar(@payloads) > $saIndex));
	my $idIndex = 1;
	if ($isRequest) {
		$idIndex++ while (($payloads[$idIndex - 1]->{nexttype} ne 'IDi') && (scalar(@payloads) > $idIndex));
	}
	else {
		$idIndex++ while (($payloads[$idIndex - 1]->{nexttype} ne 'IDr') && (scalar(@payloads) > $idIndex));
	}
	my $tsiIndex = 1;
	$tsiIndex++ while (($payloads[$tsiIndex - 1]->{nexttype} ne 'TSi') && (scalar(@payloads) > $tsiIndex));
	my $tsrIndex = 1;
	$tsrIndex++ while (($payloads[$tsrIndex - 1]->{nexttype} ne 'TSr') && (scalar(@payloads) > $tsrIndex));

	# check if message included payloads other than Notify payload
	my $num = scalar(@payloads);
	if ($saIndex == $num  ||
	    $idIndex == $num  ||
	    $tsiIndex == $num ||
	    $tsrIndex == $num) {
		# includes only Notify payload
		my $result = {
			'messID'	=> $messID,
		};
		return($result);
	}

	# Get SA proposals
	my @proposals = @{$payloads[$saIndex]->{proposals}};
	# Define extraction function creator.
	my $createExtractSub = sub {
		my ($type, $field, @proposals) = @_;
		my $extractSub = sub {
			my @transforms = @{$_->{transforms}};
			foreach my $transform (@transforms) {
				if ($transform->{type} eq $type) {
					return $transform->{$field};
				}
			}
		};
		return $extractSub;
	};
	# Extract arrays of proposals elements
	my @protocols = map { $_->{id}; } @proposals;
	my @sequence = map { $_->{number}; } @proposals;
	my @spi = map { $_->{spi}; } @proposals;
	my @encr = map { &{&{$createExtractSub}('ENCR', 'id')}($_) } @proposals;
	my @encrAttr = map { &{&{$createExtractSub}('ENCR', 'attributes')}($_) } @proposals;
	my @integ = map { &{&{$createExtractSub}('INTEG', 'id')}($_) } @proposals;
	my @integAttr = map { &{&{$createExtractSub}('INTEG', 'attributes')}($_) } @proposals;
	my @prf = map { &{&{$createExtractSub}('PRF', 'id')}($_) } @proposals;
	my @prfAttr = map { &{&{$createExtractSub}('PRF', 'attributes')}($_) } @proposals;
	my @esn = map { &{&{$createExtractSub}('ESN', 'id')}($_) } @proposals;
	my @esnAttr = map { &{&{$createExtractSub}('ESN', 'attributes')}($_) } @proposals;
	# Extract traffic selectors.
	my $initSelectors = $payloads[$tsiIndex]->{selectors};
	my $respSelectors = $payloads[$tsrIndex]->{selectors};
	# Extract identity.
	my $identity = [ $payloads[$idIndex]->{type}, $payloads[$idIndex]->{value} ];
	# Build the notify hash.
	my $index = 1;
	my $notify = {};
	while (scalar(@payloads) > $index) {
		if ($payloads[$index - 1]->{nexttype} eq 'N') {
			$notify->{$payloads[$index]->{type}} = $payloads[$index];
		}

		$index ++;
	}
	# Return extracted content.
	return {
		protocol => \@protocols,
		sequence => \@sequence,
		spi => \@spi,
		encr => \@encr,
		encrAttr => \@encrAttr,
		integ => \@integ,
		integAttr => \@integAttr,
		prf => \@prf,
		prfAttr => \@prfAttr,
		esn => \@esn,
		esnAttr => \@esnAttr,
		initSelectors => $initSelectors,
		respSelectors => $respSelectors,
		identity => $identity,
		notify => $notify,
		'proposals' => \@proposals,
		'messID'	=> $messID,
		'iv'		=> $iv,
		'icv'		=> $icv,
	};
}

=pod

=head2 kParseIKEAuthenticationRequest()

Parses an IKE_SA_INIT Request.

=head3 Parameters

=over

=item B<Parsed message>

The parsed message data comming form a call to L</kParseIKEMessage()>. The message
content is supposed to be valid.

=back

=head3 Return Value

=over

=item B<Message data>

Hash containing these entry:

=over

=item C<protocols>

Array of proposal protocols.

=item C<sequence>

Array of proposal sequence number.

=item C<spi>

Array of spi.

=item C<encr>

Array of Encryption algorithm name.

=item C<encrAttr>

Array of Encryption algorithm attributes.

=item C<integ>

Array of Integrity check algorithm.

=item C<integAttr>

Array of Integrity check algorithm attributes.

=item C<prf>

Array of Pseudo-random function.

=item C<prfAttr>

Array of Pseudo-random function attributes.

=item C<initSelectors>

Array of Traffic Selectors for initiator.

=item C<respSelectors>

Array of Traffic Selectors for responder.

=item C<notify>

Hash of notification type associated with their payloads.

=item C<identity>

Remote host identity.

=back

All array entries are associated. One index give the data from one proposal.
It doesn't applies to key that don't refers to proposals.

=back

=cut

sub kParseIKEAuthenticationRequest($) {
	# Call common parsing function.
	return kParseIKEAuthenticationCommon(shift, $TRUE);
}

=pod

=head2 kParseIKEAuthenticationResponse()

Parses an IKE_AUTH Reply.

=head3 Parameters

=over

=item B<Parsed message>

The parsed message data comming form a call to L</kParseIKEMessage()>. The message
content is supposed to be valid.

=back

=head3 Return Value

=over

=item B<Message data>

Hash containing these entry:

=over

=item C<protocols>

Proposal protocol.

=item C<sequence>

Proposal sequence number.

=item C<spi>

Proposal spi.

=item C<encr>

Encryption algorithm name.

=item C<encrAttr>

Encryption algorithm attributes.

=item C<integ>

Integrity check algorithm.

=item C<integAttr>

Integrity check algorithm attributes.

=item C<prf>

Pseudo-random function.

=item C<prfAttr>

Pseudo-random function attributes.

=item C<initSelectors>

Array of Traffic Selectors for initiator.

=item C<respSelectors>

Array of Traffic Selectors for responder.

=item C<notify>

Hash of notification type associated with their payloads.

=item C<identity>

Remote host identity.

=back

=back

=cut

sub kParseIKEAuthenticationResponse($) {
	# Call common parsing function
	my $ret = kParseIKEAuthenticationCommon($_[0], $FALSE);
	# Extract only the first proposal from proposals' data.
	foreach my $key qw(protocol sequence spi encr encrAttr integ integAttr prf prfAttr esn esnAttr) {
		if (ref $ret->{$key} eq 'ARRAY') {
			$ret->{$key} = $ret->{$key}->[0];
		}
	}
	return $ret;
}

=pod

=head2 kPrepareSAEncryption()

Generates the encryption material for a Child Security Association to use in encryption.
It can also generate the materials for a rekey.

=head3 Parameters

=over

=item B<Encryption algorithm>

The name of the encryption algorithm to use in this material. See
L<constants|kIKE::kConsts/kTransformTypeID()> for available values.

It can evaluate to false if the other is specified.

=item B<Encryption algorithm attributes>

An array containing Security Association Attributes for encryption algorithm
as given by the
L<function kDecSAAttribute in kIKE::kDec module|kIKE::kDec/kDecSAAttribute()>.

Not used if the previous parameter evaluates to false.

=item B<Integrity algorithm>

The name of the integrity check algorithm to use in this material. See
L<constants|kIKE::kConsts/kTransformTypeID()> for available values.

It can evaluate to false if the other is specified.

=item B<Integrity algorithm attributes>

An array containing Security Association Attributes for integrity check
algorithm as given by the
L<function kDecSAAttribute in kIKE::kDec module|kIKE::kDec/kDecSAAttribute()>.

Not used if the previous parameter evaluates to false.

=item B<Initiator nonce>

Nonce from the initiator of the exchange. It must be a hex string without any
prefix or suffix.

=item B<Responder nonce>

Same as B<Initiator nonce> for reponder.

=item B<IKE Material>

The encryption material of the IKE SA.

=item B<Diffie-Hellman Shared Secret> (optional)

The Diffie-Hellman shared secret computed from the Diffie-Hellman exchange. Same
format as nonces.

=back

=head3 Return value

=over

=item B<Encryption Material>

The encryption material object created from the given information.

=back

=cut

sub kPrepareSAEncryption($$$$$$$;$) {
	# Read parameters.
	my ($encr, $encrAttrs, $integ, $integAttrs, $ni, $nr, $ikeMaterial, $dh) = @_;
	# Convert hex data to binary.
	$dh = '' unless $dh;
	$dh = pack('H*', $dh);
	$ni = pack('H*', $ni);
	$nr = pack('H*', $nr);
	# Create key stream.
	my $keyStream = kIKE::kKeyStream->new(
		$ikeMaterial->prf,
		$ikeMaterial->d,
		$dh . $ni . $nr
	);

	# Create material.
	my %keymat_args = (
		'encr_alg'	=> $encr,
		'integ_alg'	=> $integ,
	);
	my $material = kIKE::kEncryptionMaterial->new(%keymat_args);
	my %attrs = (
		$encr	=> $encrAttrs,
		$integ	=> $integAttrs,
	);

	# Extract keys.
	$material->generateChildMaterial($keyStream, $encr, $integ, \%attrs);
	# Generate cryptographic functions and associate.
	if ($encr) {
		my ($encrSub, $decrSub) = getEncrSub($encr, $encrAttrs);
		$material->encr($encrSub);
		$material->decr($decrSub);
	}
	if ($integ) {
		my $integSub = getIntegSub($integ);
		$material->integ($integSub);
	}
	# Return generated material.
	return $material;
}

=pod

=head2 kBuildCreateChildSecurityAssociationCommon()

Builds a CREATE_CHILD_SA Message.

B<This function is not intended to be called by any programs outside the
library. Please use one of L</kBuildCreateChildSecurityAssociationRequest()>,
L</kBuildCreateChildSecurityAssociationResponse()>,
L</kBuildRekeyIKESecurityAssociationRequest()> and
L</kBuildRekeyIKESecurityAssociationResponse()> instead.>

=head3 Parameters

=over

=item B<Initiator SPI>

The SPI for the initiator. It has to be a 16-digit hex string without prefix nor suffix.

=item B<Responder SPI>

The SPI for the initiator. It has to be a 16-digit hex string without prefix nor suffix.

=item B<Initiator>

Flag indicating if the generated CREATE_CHILD_SA message is from the original
initiator or responder. It is implicit to the usage of this message.

=item B<Request>

Flag indicating if the generated CREATE_CHILD_SA message is for a request or a
response. It is implicit to the usage of this message.

=item B<Proposal list>

See L</PROPOSAL LIST FORMAT>.

=item B<Message ID>

ID of this message, should be more than 1.

=item B<Traffic Selector Initiator>

See L</TRAFFIC SELECTOR FORMAT>. This one is for initiator.

=item B<Traffic Selector Responder>

See L</TRAFFIC SELECTOR FORMAT>. This one is for responder.

=item B<Diffie-Hellman Group>

The Diffie-Hellman group to use in the KE payload. C<undef> if not used.

=item B<Encryption material>

The material for encryption.

=item B<Notifications> (optional)

Hash of requested notification payloads associating id to data.

=back

=head3 Return value

=over

=item B<Message data>

The string containing the binary data of the message.

=item C<Nonce>

The nonce generated for this message. It is a Math::BigInt.

=item C<Nonce length>

The length of the nonce, in bytes.

=item C<Diffie-Hellman>

The Crypt::DH containing the generated Diffie-Hellman data. Not defined if no
DH exchange requested.

=back

=cut

sub kBuildCreateChildSecurityAssociationCommon($$$$$$$$$$;$) {
	my ($initSPI, $respSPI, $isInit, $isRequest,
		$proposals, $messageID, $tsInit, $tsResp,
		$group, $material,
		$notificationsRef) = @_;
	# Prepare variables.
	my $useDH = defined $group;
	my $paydata = '';
	my $paytype = 0;
	my $dh;
	my $key;
	my $nonce;
	my $len;
	my %notifications = %{$notificationsRef};

	# Generate the public key.
	($dh, $key) = kGenDHPublicKey($group) if $useDH;
	if ((defined $tsResp) && (defined $tsInit)) {
		# Generate N payload for ADDITIONAL_TS_POSSIBLE if defined.
		($paydata, $paytype) = kGenNotifyPayload(0, 0, 'ADDITIONAL_TS_POSSIBLE', '', '') if exists $notifications{ADDITIONAL_TS_POSSIBLE};
		# Generate TS payload for responder
		($paydata, $paytype) = kBuildTrafficSelectorPayload(	$tsResp, 0, $paytype, $paydata);
		# Generate TS payload for initiator
		($paydata, $paytype) = kBuildTrafficSelectorPayload($tsInit, 1, $paytype, $paydata);
	}
	# Generate the KE payload if needed.
	($paydata, $paytype) = kGenKeyExchangePayload($group, $key, $paytype, $paydata) if $useDH;
	# Generate the nonce and its paylaod.
	($paydata, $paytype, $nonce, $len) = kGenNoncePayload($paytype, $paydata);
	# Generate SA payload.
	($paydata, $paytype) = kBuildSecurityAssociationPayload($proposals, $paytype, $paydata);
	if ((defined $tsResp) && (defined $tsInit)) {
		# Generate N payload for NON_FIRST_FRAGMENT_ALSO if defined.
		($paydata, $paytype) = kGenNotifyPayload(0, 0, 'NON_FIRST_FRAGMENT_ALSO', '', '', $paytype, $paydata) if exists $notifications{NON_FIRST_FRAGMENT_ALSO};
		# Generate N payload for ESP_TFC_PADDING_NOT_SUPPORTED if defined.
		($paydata, $paytype) = kGenNotifyPayload(0, 0, 'ESP_TFC_PADDING_NOT_SUPPORTED', '', '', $paytype, $paydata) if exists $notifications{ESP_TFC_PADDING_NOT_SUPPORTED};
		# Generate N payload for USE_TRANSPORT_MODE if defined.
		($paydata, $paytype) = kGenNotifyPayload(0, 0, 'USE_TRANSPORT_MODE', '', '', $paytype, $paydata) if exists $notifications{USE_TRANSPORT_MODE};
		# Generate N payload(s) for IPCOMP_SUPPORTED if defined.
		if (exists $notifications{IPCOMP_SUPPORTED}) {
			# Check if we have one or multiple instances to create.
			if (ref $notifications{IPCOMP_SUPPORTED} eq 'ARRAY') { # Multiple
				# Dereference data array.
				my @ipcomp = @{$notifications{IPCOMP_SUPPORTED}};
				# Process each data from the last.
				for (my $i = scalar(@ipcomp) - 1; $i >= 0; --$i) {
					# Generate N payload for IPCOMP_SUPPORTED.
					($paydata, $paytype) = kGenNotifyPayload(
						0, 0, 'IPCOMP_SUPPORTED', '', $ipcomp[$i], $paytype, $paydata);
				}
			}
			else { # Unique
				# Generate N payload for IPCOMP_SUPPORTED.
				($paydata, $paytype) = kGenNotifyPayload(
					0, 0, 'IPCOMP_SUPPORTED', '', $notifications{IPCOMP_SUPPORTED}, $paytype, $paydata) 
			}
		}
		# Generate N payload for REKEY_SA if defined.
		($paydata, $paytype) = kGenNotifyPayload(0, 0, 'REKEY_SA', $notifications{REKEY_SA}, '', $paytype, $paydata) if exists $notifications{REKEY_SA} && $isRequest;
	}
	# Generate Encrypted payload.
	($paydata, $paytype) = kGenEncryptedPayload($material, $isInit, $paytype, $paydata);
	# Generate header.
	($paydata) = kGenIKEHeader(
		$initSPI, $respSPI, 2, 0, 'CREATE_CHILD_SA',
		$isInit ? 1 : 0, 0, $isRequest ? 0 : 1,
		$messageID, $paytype, $paydata
	);
	# Compute the checksum and return the resulting message.
	return (kGenEncryptedPayloadChecksum($material, $isInit, $paydata), $nonce, $len, $dh);
}

=pod

=head2 kBuildCreateChildSecurityAssociationRequest()

Builds a CREATE_CHILD_SA Request.

=head3 Parameters

=over

=item B<Initiator SPI>

The SPI for the initiator. It has to be a 16-digit hex string without prefix nor suffix.

=item B<Responder SPI>

The SPI for the initiator. It has to be a 16-digit hex string without prefix nor suffix.

=item B<Initiator>

Flag indicating if the generated CREATE_CHILD_SA message is from the original
initiator or responder. It is implicit to the usage of this message.

=item B<Proposal list>

See L</PROPOSAL LIST FORMAT>.

=item B<Message ID>

ID of this message, should be more than 1.

=item B<Traffic Selector Initiator>

See L</TRAFFIC SELECTOR FORMAT>. This one is for initiator.

=item B<Traffic Selector Responder>

See L</TRAFFIC SELECTOR FORMAT>. This one is for responder.

=item B<Diffie-Hellman Group>

The Diffie-Hellman group to use in the KE payload. C<undef> if not used.

=item B<Encryption material>

The material for encryption.

=item B<Notifications>

Hash of requested notification payloads associating id to data.

=back

=head3 Return value

=over

=item B<Message data>

The string containing the binary data of the message.

=item C<Nonce>

The nonce generated for this message. It is a Math::BigInt.

=item C<Nonce length>

The length of the nonce, in bytes.

=item C<Diffie-Hellman>

The Crypt::DH containing the generated Diffie-Hellman data. Not defined if no
DH exchange requested.

=back

=cut

sub kBuildCreateChildSecurityAssociationRequest($$$$$$$$$$) {
	# Read parameters
	my ($initSPI, $respSPI, $isInit, 
		$proposalsRef, $messageID, $tsInit, $tsResp,
		$group, $material,
		$notify) = @_;
	# Call common building function.
	return(kBuildCreateChildSecurityAssociationCommon(
		$initSPI, $respSPI, $isInit, 1,
		$proposalsRef, $messageID, $tsInit, $tsResp,
		$group, $material,
		$notify));
}

=pod

=head2 kBuildCreateChildSecurityAssociationResponse()

Builds a CREATE_CHILD_SA Response.

=head3 Parameters

=over

=item B<Initiator SPI>

The SPI for the initiator. It has to be a 16-digit hex string without prefix nor suffix.

=item B<Responder SPI>

The SPI for the initiator. It has to be a 16-digit hex string without prefix nor suffix.

=item B<Initiator>

Flag indicating if the generated CREATE_CHILD_SA message is from the original
initiator or responder. It is implicit to the usage of this message.

=item B<Proposal list>

See L</PROPOSAL LIST FORMAT>.

=item B<Message ID>

ID of this message, should be more than 1.

=item B<Traffic Selector Initiator>

See L</TRAFFIC SELECTOR FORMAT>. This one is for initiator.

=item B<Traffic Selector Responder>

See L</TRAFFIC SELECTOR FORMAT>. This one is for responder.

=item B<Diffie-Hellman Group>

The Diffie-Hellman group to use in the KE payload. C<undef> if not used.

=item B<Encryption material>

The material for encryption.

=item B<Notifications>

Hash of requested notification payloads associating id to data.

=back

=head3 Return value

=over

=item B<Message data>

The string containing the binary data of the message.

=item C<Nonce>

The nonce generated for this message. It is a Math::BigInt.

=item C<Nonce length>

The length of the nonce, in bytes.

=item C<Diffie-Hellman>

The Crypt::DH containing the generated Diffie-Hellman data. Not defined if no
DH exchange requested.

=back

=cut

sub kBuildCreateChildSecurityAssociationResponse($$$$$$$$$$) {
	# Read parameters
	my ($initSPI, $respSPI, $isInit,
		$proposalsRef, $messageID, $tsInit, $tsResp,
		$group, $material,
		$notify) = @_;
	# Call common building function.
	kBuildCreateChildSecurityAssociationCommon(
		$initSPI, $respSPI, $isInit, 0,
		$proposalsRef, $messageID, $tsInit, $tsResp,
		$group, $material,
		$notify);
}

=pod

=head2 kBuildRekeyIKESecurityAssociationRequest()

Builds a CREATE_CHILD_SA Request for rekeying the IKE_SA.

=head3 Parameters

=over

=item B<Initiator SPI>

The SPI for the initiator. It has to be a 16-digit hex string without prefix nor suffix.

=item B<Responder SPI>

The SPI for the initiator. It has to be a 16-digit hex string without prefix nor suffix.

=item B<Initiator>

Flag indicating if the generated CREATE_CHILD_SA message is from the original
initiator or responder. It is implicit to the usage of this message.

=item B<Proposal list>

See L</PROPOSAL LIST FORMAT>.

=item B<Message ID>

ID of this message, should be more than 1.

=item B<Diffie-Hellman Group>

The Diffie-Hellman group to use in the KE payload. C<undef> if not used.

=item B<Encryption material>

The material for encryption.

=back

=head3 Return value

=over

=item B<Message data>

The string containing the binary data of the message.

=item C<Nonce>

The nonce generated for this message. It is a Math::BigInt.

=item C<Nonce length>

The length of the nonce, in bytes.

=item C<Diffie-Hellman>

The Crypt::DH containing the generated Diffie-Hellman data. Not defined if no
DH exchange requested.

=back

=cut

sub kBuildRekeyIKESecurityAssociationRequest($$$$$$$) {
	# Read parameters
	my ($initSPI, $respSPI, $isInit, $proposalsRef, $messageID,
		$group, $material) = @_;
	# Call common building function.
	kBuildCreateChildSecurityAssociationCommon(
		$initSPI, $respSPI, $isInit, 1,
		$proposalsRef, $messageID, undef, undef,
		$group, $material);
}

=pod

=head2 kBuildRekeyIKESecurityAssociationResponse()

Builds a CREATE_CHILD_SA Response for rekeying the IKE_SA.

=head3 Parameters

=over

=item B<Initiator SPI>

The SPI for the initiator. It has to be a 16-digit hex string without prefix nor suffix.

=item B<Responder SPI>

The SPI for the initiator. It has to be a 16-digit hex string without prefix nor suffix.

=item B<Initiator>

Flag indicating if the generated CREATE_CHILD_SA message is from the original
initiator or responder. It is implicit to the usage of this message.

=item B<Proposal list>

See L</PROPOSAL LIST FORMAT>.

=item B<Message ID>

ID of this message, should be more than 1.

=item B<Diffie-Hellman Group>

The Diffie-Hellman group to use in the KE payload. C<undef> if not used.

=item B<Encryption material>

The material for encryption.

=back

=head3 Return value

=over

=item B<Message data>

The string containing the binary data of the message.

=item C<Nonce>

The nonce generated for this message. It is a Math::BigInt.

=item C<Nonce length>

The length of the nonce, in bytes.

=item C<Diffie-Hellman>

The Crypt::DH containing the generated Diffie-Hellman data. Not defined if no
DH exchange requested.

=back

=cut

sub kBuildRekeyIKESecurityAssociationResponse($$$$$$$) {
	# Read parameters
	my ($initSPI, $respSPI, $isInit, $proposalsRef, $messageID,
		$group, $material) = @_;
	# Call common building function.
	kBuildCreateChildSecurityAssociationCommon(
		$initSPI, $respSPI, $isInit, 0,
		$proposalsRef, $messageID, undef, undef,
		$group, $material);
}

=pod

=head2 kParseCreateChildSecurityAssociationCommon()

Parses a CREATE_CHILD_SA Message.

B<This function is not intended to be called by any programs outside the
library. Please use one of L</kParseCreateChildSecurityAssociationRequest()> and
L</kParseCreateChildSecurityAssociationResponse()> instead.>

=head3 Parameters

=over

=item B<Parsed message>

The parsed message data comming form a call to L</kParseIKEMessage()>. The message
content is supposed to be valid.

=item B<Diffie-Hellman parameters> (optional)

The Crypt::DH object to use.

=back

=head3 Return Value

=over

=item B<Message data>

Hash containing these entry:

=over

=item C<nonce>

Other side's nonce.

=item C<nonceLen>

The length of the nonce.

=item C<secret> (not given when no KE payload and no DH object)

Diffie-Hellman shared secret.

=item C<public> (not given when no KE payload)

Diffie-Hellman public value.

=item C<protocols>

Array of proposal protocols.

=item C<sequence>

Array of proposal sequence number.

=item C<spi>

Array of spi.

=item C<encr>

Array of Encryption algorithm name.

=item C<encrAttr>

Array of Encryption algorithm attributes.

=item C<integ>

Array of Integrity check algorithm.

=item C<integAttr>

Array of Integrity check algorithm attributes.

=item C<prf>

Array of Pseudo-random function.

=item C<prfAttr>

Array of Pseudo-random function attributes.

=item C<initSelectors> (undef if no TSi)

Array of Traffic Selectors for initiator.

=item C<respSelectors> (undef if no TSr)

Array of Traffic Selectors for responder.

=item C<notify>

Hash of notification type associated with their payloads.

=back

All array entries are associated. One index give the data from one proposal.
It doesn't applies to key that don't refers to proposals.

=back

=cut

sub kParseCreateChildSecurityAssociationCommon($) {
	# Read parameters.
	my ($message) = @_;
	# Search for encrypted payload.
	my $messID = $message->[0]->{messID};
	my $eIndex = 1;
	$eIndex++ while (($message->[$eIndex - 1]->{nexttype} ne 'E') && (scalar(@{$message}) > $eIndex));

	# Enter in the encrypted payload.
	my @payloads = undef;
	if ($eIndex < scalar(@{$message})) {
		@payloads = @{$message->[$eIndex]->{'innerPayloads'}};
		unshift @payloads,
			{
				'nexttype' => $message->[$eIndex]->{'innerType'},
			};
	}
	else {
		@payloads = @{$message};
	}

	# Discover payloads location.
	my $saIndex = 1;
	$saIndex++ while (($payloads[$saIndex - 1]->{nexttype} ne 'SA') && (scalar(@payloads) > $saIndex));
	my $tsiIndex = 1;
	$tsiIndex++ while (($payloads[$tsiIndex - 1]->{nexttype} ne 'TSi') && (scalar(@payloads) > $tsiIndex));
	my $tsrIndex = 1;
	$tsrIndex++ while (($payloads[$tsrIndex - 1]->{nexttype} ne 'TSr') && (scalar(@payloads) > $tsrIndex));
	my $keIndex = 1;
	$keIndex++ while (($payloads[$keIndex - 1]->{nexttype} ne 'KE') && (scalar(@payloads) > $keIndex));
	my $nonceIndex = 1;
	$nonceIndex++ while (($payloads[$nonceIndex - 1]->{nexttype} ne 'Ni, Nr') && (scalar(@payloads) > $nonceIndex));

	# check if message included payloads other than Notify payload
	my $num = scalar(@payloads);
	if ($saIndex == $num  ||
	    $nonceIndex == $num) {
		# includes only Notify payload
		my $result = {
			'messID'	=> $messID,
		};
		return($result);
	}

	# Get simple values.
	my $nonce = $payloads[$nonceIndex]->{nonce};
	my $noncelen = $payloads[$nonceIndex]->{nonceLen};
	my $publicKey = $payloads[$keIndex]->{publicKey} if scalar(@payloads) > $keIndex;
	# Get SA proposals
	my @proposals = @{$payloads[$saIndex]->{proposals}};
	# Define extraction function creator.
	my $createExtractSub = sub {
		my ($type, $field, @proposals) = @_;
		my $extractSub = sub {
			my @transforms = @{$_->{transforms}};
			foreach my $transform (@transforms) {
				if ($transform->{type} eq $type) {
					return $transform->{$field};
				}
			}
		};
		return $extractSub;
	};
	# Extract arrays of proposals elements
	my @protocols = map { $_->{id}; } @proposals;
	my @sequence = map { $_->{number}; } @proposals;
	my @spi = map { $_->{spi}; } @proposals;
	my @encr = map { &{&{$createExtractSub}('ENCR', 'id')}($_) } @proposals;
	my @encrAttr = map { &{&{$createExtractSub}('ENCR', 'attributes')}($_) } @proposals;
	my @integ = map { &{&{$createExtractSub}('INTEG', 'id')}($_) } @proposals;
	my @integAttr = map { &{&{$createExtractSub}('INTEG', 'attributes')}($_) } @proposals;
	my @prf = map { &{&{$createExtractSub}('PRF', 'id')}($_) } @proposals;
	my @prfAttr = map { &{&{$createExtractSub}('PRF', 'attributes')}($_) } @proposals;
	# Extract traffic selectors.
	my $initSelectors = undef;
	$initSelectors = $payloads[$tsiIndex]->{selectors} if scalar(@payloads) > $tsiIndex;
	my $respSelectors = undef;
	$respSelectors = $payloads[$tsrIndex]->{selectors} if scalar(@payloads) > $tsrIndex;
	# Build the notify hash.
	my $index = 1;
	my $notify = {};
	while (scalar(@payloads) > $index) {
		if ($payloads[$index - 1]->{nexttype} eq 'N') {
			$notify->{$payloads[$index]->{type}} = $payloads[$index];
		}

		$index++;
	}
	# Return extracted content.
	my $result = {
		nonce => $nonce,
		nonceLen => $noncelen,
		protocol => \@protocols,
		sequence => \@sequence,
		spi => \@spi,
		encr => \@encr,
		encrAttr => \@encrAttr,
		integ => \@integ,
		integAttr => \@integAttr,
		prf => \@prf,
		prfAttr => \@prfAttr,
		initSelectors => $initSelectors,
		respSelectors => $respSelectors,
		notify => $notify,
		'proposals'	=> \@proposals,
		'messID'	=> $messID,
	};
	$result->{public} = $publicKey if scalar(@payloads) > $keIndex;
	return $result;
}

=pod

=head2 kParseCreateChildSecurityAssociationRequest()

Parses a CREATE_CHILD_SA Request.

=head3 Parameters

=over

=item B<Parsed message>

The parsed message data comming form a call to L</kParseIKEMessage()>. The message
content is supposed to be valid.

=back

=head3 Return Value

=over

=item B<Message data>

Hash containing these entry:

=over

=item C<nonce>

Other side's nonce.

=item C<nonceLen>

The length of the nonce.

=item C<public> (not given when no KE payload)

Diffie-Hellman public value.

=item C<protocols>

Array of proposal protocols.

=item C<sequence>

Array of proposal sequence number.

=item C<spi>

Array of spi.

=item C<encr>

Array of Encryption algorithm name.

=item C<encrAttr>

Array of Encryption algorithm attributes.

=item C<integ>

Array of Integrity check algorithm.

=item C<integAttr>

Array of Integrity check algorithm attributes.

=item C<prf>

Array of Pseudo-random function.

=item C<prfAttr>

Array of Pseudo-random function attributes.

=item C<initSelectors> (undef if no TSi)

Array of Traffic Selectors for initiator.

=item C<respSelectors> (undef if no TSr)

Array of Traffic Selectors for responder.

=item C<notify>

Hash of notification type associated with their payloads.

=back

All array entries are associated. One index give the data from one proposal.
It doesn't applies to key that don't refers to proposals.

=back

=cut

sub kParseCreateChildSecurityAssociationRequest($) {
	# Call common parsing function.
	return kParseCreateChildSecurityAssociationCommon(shift);
}

=pod

=head2 kParseCreateChildSecurityAssociationResponse()

Parses a CREATE_CHILD_SA Response.

=head3 Parameters

=over

=item B<Parsed message>

The parsed message data comming form a call to L</kParseIKEMessage()>. The message
content is supposed to be valid.

=item B<Diffie-Hellman parameters> (optional)

The Crypt::DH object to use.

=back

=head3 Return Value

=over

=item B<Message data>

Hash containing these entry:

=over

=item C<nonce>

Other side's nonce.

=item C<nonceLen>

The length of the nonce.

=item C<secret> (not given when no KE payload and no DH object)

Diffie-Hellman shared secret.

=item C<public> (not given when no KE payload)

Diffie-Hellman public value.

=item C<protocols>

Proposal protocol.

=item C<sequence>

Proposal sequence number.

=item C<spi>

Proposal spi.

=item C<encr>

Encryption algorithm name.

=item C<encrAttr>

Encryption algorithm attributes.

=item C<integ>

Integrity check algorithm.

=item C<integAttr>

Integrity check algorithm attributes.

=item C<prf>

Pseudo-random function.

=item C<prfAttr>

Pseudo-random function attributes.

=item C<initSelectors> (undef if no TSi)

Array of Traffic Selectors for initiator.

=item C<respSelectors> (undef if no TSr)

Array of Traffic Selectors for responder.

=item C<notify>

Hash of notification type associated with their payloads.

=back

=back

=cut

sub kParseCreateChildSecurityAssociationResponse($) {
	# Call common parsing function.
	my $ret = kParseCreateChildSecurityAssociationCommon($_[0]);
	# Extract only the first proposal from proposals' data.
	foreach my $key qw(protocol sequence spi encr encrAttr integ integAttr prf prfAttr) {
		if (ref $ret->{$key} eq 'ARRAY') {
			$ret->{$key} = $ret->{$key}->[0];
		}
	}
	return $ret;
}

=pod

=head2 kBuildInformationalCommon()

Builds an INFORMATIONAL Message.

B<This function is not intended to be called by any programs outside the
library. Please use one of L</kBuildInformationalRequest()> and
L</kBuildInformationalResponse()> instead.>

=head3 Parameters

=over

=item B<Initiator SPI>

The SPI for the initiator. It has to be a 16-digit hex string without prefix nor suffix.

=item B<Responder SPI>

The SPI for the initiator. It has to be a 16-digit hex string without prefix nor suffix.

=item B<Initiator>

Flag indicating if the generated INFORMATIONAL message is from the original
initiator or responder. It is implicit to the usage of this message.

=item B<Request>

Flag indicating if the generated INFORMATIONAL message is for a request or a
response. It is implicit to the usage of this message.

=item B<Message ID>

ID of this message, should be more than 1.

=item B<Payloads>

Hash of contained payloads by type.

=over

=item C<N>

An array of hash containing the keys C<id>, C<spiSize>, C<type>, C<spi> and
C<data> as defined in the returned hash of 
<the function kDecNotifyPayload() in the kIKE::kDec module|kIKE::kDec/kDecNotifyPayload()>.

=item C<D>

A hash doing mapping from Protocol IDs to arrays of SPIs of the corresponding
protocol to delete. Protocol IDs are enumerated in RFC4306 section 3.3.1 and can
either be the name or the value.

=item C<CP>

Not yet defined.
TODO: Define.

=back

=back

=head3 Return value

=over

=item B<Message data>

The string containing the binary data of the message.

=back

=cut

sub kBuildInformationalCommon($$$$$$;%) {
	my ($initSPI, $respSPI, $isInit, $isRequest,
		$messageID, $material, %payloads) = @_;
	# Prepare variables.
	my $paydata = '';
	my $paytype = 0;

	# TODO: CP payload
	# Generating Delete payloads.
	if ((exists $payloads{D}) && (defined $payloads{D})) {
		foreach my $id (keys %{$payloads{D}}) {
			next if scalar(@{$payloads{D}->{$id}}) == 0;
			# Generate Delete payload.
			($paydata, $paytype) = kGenDeletePayload($id, 
				length($payloads{D}->{$id}->[0]), 
				scalar(@{$payloads{D}->{$id}}), 
				join('', @{$payloads{D}->{$id}}), $paytype, $paydata);
		}
	}
	# Generating Notify payloads.
	if ((exists $payloads{N}) && (defined $payloads{N})) {
		my @notifies = @{$payloads{N}};
		for (my $i = scalar(@notifies) - 1; $i >= 0; --$i) {
			# Generate Notify payload.
			($paydata, $paytype) = kGenNotifyPayload(
				$notifies[$i]->{id}, 
				$notifies[$i]->{spiSize},
				$notifies[$i]->{type}, 
				$notifies[$i]->{spi}, 
				$notifies[$i]->{data}, $paytype, $paydata);
		}
	}
	# Generate Encrypted payload.
	($paydata, $paytype) = kGenEncryptedPayload($material, $isInit, $paytype, $paydata);
	# Generate header.
	($paydata) = kGenIKEHeader(
		$initSPI, $respSPI, 2, 0, 'INFORMATIONAL',
		$isInit ? 1 : 0, 0, $isRequest ? 0 : 1,
		$messageID, $paytype, $paydata
	);
	# Compute the checksum and return the resulting message.
	return kGenEncryptedPayloadChecksum($material, $isInit, $paydata);
}

=pod

=head2 kBuildInformationalRequest()

Builds an INFORMATIONAL Request.

=head3 Parameters

=over

=item B<Initiator SPI>

The SPI for the initiator. It has to be a 16-digit hex string without prefix nor suffix.

=item B<Responder SPI>

The SPI for the initiator. It has to be a 16-digit hex string without prefix nor suffix.

=item B<Initiator>

Flag indicating if the generated INFORMATIONAL message is from the original
initiator or responder. It is implicit to the usage of this message.

=item B<Message ID>

ID of this message, should be more than 1.

=item B<Payloads>

Hash of contained payloads by type.

=over

=item C<N>

An array of hash containing the keys C<id>, C<spiSize>, C<type>, C<spi> and
C<data> as defined in the returned hash of 
<the function kDecNotifyPayload() in the kIKE::kDec module|kIKE::kDec/kDecNotifyPayload()>.

=item C<D>

A hash doing mapping from Protocol IDs to arrays of SPIs of the corresponding
protocol to delete. Protocol IDs are enumerated in RFC4306 section 3.3.1 and can
either be the name or the value.

=item C<CP>

Not yet defined.
TODO: Define.

=back

=back

=head3 Return value

=over

=item B<Message data>

The string containing the binary data of the message.

=back

=cut

sub kBuildInformationalRequest($$$$$;%) {
	# Read parameters.
	my ($initSPI, $respSPI, $isInit, 
		$messageID, $material, %payloads) = @_;
	# Call common building function.
	return kBuildInformationalCommon(
		$initSPI, $respSPI, $isInit, 1,
		$messageID, $material, %payloads);
}

=pod

=head2 kBuildInformationalResponse()

Builds an INFORMATIONAL Response.

=head3 Parameters

=over

=item B<Initiator SPI>

The SPI for the initiator. It has to be a 16-digit hex string without prefix nor suffix.

=item B<Responder SPI>

The SPI for the initiator. It has to be a 16-digit hex string without prefix nor suffix.

=item B<Initiator>

Flag indicating if the generated INFORMATIONAL message is from the original
initiator or responder. It is implicit to the usage of this message.

=item B<Message ID>

ID of this message, should be more than 1.

=item B<Payloads>

Hash of contained payloads by type.

=over

=item C<N>

An array of hash containing the keys C<id>, C<spiSize>, C<type>, C<spi> and
C<data> as defined in the returned hash of 
<the function kDecNotifyPayload() in the kIKE::kDec module|kIKE::kDec/kDecNotifyPayload()>.

=item C<D>

A hash doing mapping from Protocol IDs to arrays of SPIs of the corresponding
protocol to delete. Protocol IDs are enumerated in RFC4306 section 3.3.1 and can
either be the name or the value.

=item C<CP>

Not yet defined.
TODO: Define.

=back

=back

=head3 Return value

=over

=item B<Message data>

The string containing the binary data of the message.

=back

=cut

sub kBuildInformationalResponse($$$$$;%) {
	# Read parameters.
	my ($initSPI, $respSPI, $isInit, 
		$messageID, $material, %payloads) = @_;
	# Call common building function.
	return kBuildInformationalCommon(
		$initSPI, $respSPI, $isInit, 0,
		$messageID, $material, %payloads);
}

=pod

=head2 kParseInformationalCommon()

Parses a INFORMATIONAL Message.

B<This function is not intended to be called by any programs outside the
library. Please use one of L</kParseInformationalRequest()> and
L</kParseInformationalResponse()> instead.>

=head3 Parameters

=over

=item B<Parsed message>

The parsed message data comming form a call to L</kParseIKEMessage()>. The message
content is supposed to be valid.

=back

=head3 Return Value

=over

=item B<Message data>

Hash containing these entry:

=over

=item C<N>

An array of hash containing the keys C<id>, C<spiSize>, C<type>, C<spi> and
C<data> as defined in the returned hash of 
<the function kDecNotifyPayload() in the kIKE::kDec module|kIKE::kDec/kDecNotifyPayload()>.

=item C<D>

A hash doing mapping from Protocol IDs to arrays of SPIs of the corresponding
protocol to delete. Protocol IDs are enumerated in RFC4306 section 3.3.1 and is
the name if possible.

=item C<CP>

Not yet defined.
TODO: Define.

=back

=back

=cut

sub kParseInformationalCommon($) {
	# Read parameters.
	my ($message) = @_;
	# Search for encrypted payload.
	my $messID = $message->[0]->{messID};
	my $eIndex = 1;
	$eIndex++ while (($message->[$eIndex - 1]->{nexttype} ne 'E') && (scalar(@{$message}) > $eIndex));

	# Enter in the encrypted payload.
	my @payloads = undef;
	if ($eIndex < scalar(@{$message})) {
		@payloads = @{$message->[$eIndex]->{'innerPayloads'}};
		unshift @payloads,
			{
				'nexttype' => $message->[$eIndex]->{'innerType'},
			};
	}
	else {
		@payloads = @{$message};
	}

	# Discover payloads location.
	my $cpIndex = 1;
	$cpIndex++ while (($payloads[$cpIndex - 1]->{nexttype} ne 'CP') && (scalar(@payloads) > $cpIndex));
	# Build the notify array.
	my $index = 1;
	my @N = ();
	while (scalar(@payloads) > $index++) {
		if ($payloads[$index - 1]->{nexttype} eq 'N') {
			push @N, $payloads[$index];
		}
	}
	# Build the notify hash.
	$index = 1;
	my %D = ();
	while (scalar(@payloads) > $index++) {
		if ($payloads[$index - 1]->{nexttype} eq 'D') {
			my $payload = $payloads[$index];
			$D{$payload->{id}} = () unless defined $D{$payload->{id}};
			my $dest = $D{$payload->{id}};
			my $spis = $payload->{spis};
			my $size = $payload->{spiSize} * 2;
			my $count = $payload->{spiCount};
			for (my $i = 0; $i < $count; ++$i) {
				push @{$dest}, substr($spis, $i * $size, $size);
			}
		}
	}
	# TODO: Retrive CP and transform. ($cpIndex)
	my $CP = {};
	# Return extracted content.
	return {
		N => \@N,
		D => \%D,
		CP => $CP,
		'messID'	=> $messID
	};
}

=pod

=head2 kParseInformationalRequest()

Parses a INFORMATIONAL Request.

=head3 Parameters

=over

=item B<Parsed message>

The parsed message data comming form a call to L</kParseIKEMessage()>. The message
content is supposed to be valid.

=back

=head3 Return Value

=over

=item B<Message data>

Hash containing these entry:

=over

=item C<N>

An array of hash containing the keys C<id>, C<spiSize>, C<type>, C<spi> and
C<data> as defined in the returned hash of 
<the function kDecNotifyPayload() in the kIKE::kDec module|kIKE::kDec/kDecNotifyPayload()>.

=item C<D>

A hash doing mapping from Protocol IDs to arrays of SPIs of the corresponding
protocol to delete. Protocol IDs are enumerated in RFC4306 section 3.3.1 and is
the name if possible.

=item C<CP>

Not yet defined.
TODO: Define.

=back

=back

=cut

sub kParseInformationalRequest($) {
	# Call common parsing function.
	kParseInformationalCommon($_[0]);
}

=pod

=head2 kParseInformationalResponse()

Parses a INFORMATIONAL Response.

=head3 Parameters

=over

=item B<Parsed message>

The parsed message data comming form a call to L</kParseIKEMessage()>. The message
content is supposed to be valid.

=back

=head3 Return Value

=over

=item B<Message data>

Hash containing these entry:

=over

=item C<N>

An array of hash containing the keys C<id>, C<spiSize>, C<type>, C<spi> and
C<data> as defined in the returned hash of 
<the function kDecNotifyPayload() in the kIKE::kDec module|kIKE::kDec/kDecNotifyPayload()>.

=item C<D>

A hash doing mapping from Protocol IDs to arrays of SPIs of the corresponding
protocol to delete. Protocol IDs are enumerated in RFC4306 section 3.3.1 and is
the name if possible.

=item C<CP>

Not yet defined.
TODO: Define.

=back

=back

=cut

sub kParseInformationalResponse($) {
	# Call common parsing function.
	kParseInformationalCommon($_[0]);
}


# TODO: Check the kParse*Common/Request/Response for the extraction of the
# possible CP payload in the message.

=pod

=head1 SEE ALSO

Use RFC4306 as reference to understand the format.

=head1 AUTHOR

Pierrick Caillon, <pierrick@64translator.com>, from tahi project.

=cut


my $keying_material = undef;

sub kKeyingMaterial()
{
	return($keying_material);
}

sub kRegisterKeyingMaterial($)
{
	my ($material) = @_;
	$keying_material = $material;
	return;
}

sub kUnregisterKeyingMaterial()
{
	$keying_material = undef;
}


1;
