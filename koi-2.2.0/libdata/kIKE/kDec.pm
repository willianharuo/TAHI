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
# $TAHI: koi/libdata/kIKE/kDec.pm,v 0.1 2007/07/09 12:54:00 pierrick Exp $
#
# $Id: kDec.pm,v 1.7 2010/07/22 12:41:17 velo Exp $
#
########################################################################

package kIKE::kDec;

use strict;
use warnings;
use Exporter;
use Math::BigInt;
use kIKE::kConsts;
use kIKE::kEncryptionMaterial;

our @ISA = qw(Exporter kIKE::kConsts);

our @EXPORT = qw(
	kDecIKEHeader
	kDecSecurityAssociationPayload
	kDecSAProposal
	kDecSATransform
	kDecSAAttribute
	kDecKeyExchangePayload
	kDecIdentificationIPayload
	kDecIdentificationRPayload
	kDecCertificatePayload
	kDecCertificateRequestPayload
	kDecAuthenticationPayload
	kDecCalcAuthenticationData
	kDecNoncePayload
	kDecNotifyPayload
	kDecDeletePayload
	kDecVendorIDPayload
	kDecTrafficSelectorIPayload
	kDecTrafficSelectorRPayload
	kDecTSSelector
	kDecEncryptedPayload
	kDecCalcEncryptedPayloadChecksum
	kDecConfigurationPayload
	kDecEAPPayload
);

our $TRUE = $kIKE::kConsts::TRUE;
our $FALSE = $kIKE::kConsts::FALSE;

my $PRINT_GENERIC_PAYLOAD_HEADER = $FALSE; # $TRUE; # 
my $PRINT_PAYLOAD_MORE = $FALSE; # $TRUE; # 
my $PRINT_ID_PAYLOAD = $FALSE; # $TRUE; # 
my $PRINT_SA_PAYLOAD = $FALSE; # $TRUE; # 
my $PRINT_KE_PAYLOAD = $FALSE; # $TRUE; # 
my $PRINT_CERT_PAYLOAD = $FALSE; # $TRUE; # 
my $PRINT_CERTREQ_PAYLOAD = $FALSE; # $TRUE; # 
my $PRINT_AUTH_PAYLOAD = $FALSE; # $TRUE; # 
my $PRINT_NI_PAYLOAD = $FALSE; # $TRUE; # 
my $PRINT_NR_PAYLOAD = $FALSE; # $TRUE; # 
my $PRINT_D_PAYLOAD = $FALSE; # $TRUE; # 
my $PRINT_N_PAYLOAD = $FALSE; # $TRUE; # 
my $PRINT_TS_PAYLOAD = $FALSE; # $TRUE; # 

=pod

=head1 NAME

kIKE::kDec - Message parser provider for IKEv2 test scripts.

=head1 SYNOPSIS

 use kIKE::kDec;
 push @ISA, 'kIKE::kDec';

=head1 METHODS

This package contains subs to parse IKEv2 Messages.

To decode a Message you must start by decoding the IKE Header. You must then
decode every payload using the nexttype value gave by every subs. All these subs
returns a reference to a hash containing at least to keys: C<nexttype> and
C<payloads> which gave the next payload type to decode and the remaining data
to decode. You may use kDecGenericPayloadHeader() function if you didn't
recognize a payload type or if it isn't implemented.

All message generation methods follow the following parameter model:

=over

=item *

The message data to decode, coming form a previous decode except when decoding
IKE Header for which it is the received data.

=item *

Exceptional specific parameters for encryption or verification.

=back

You should be interested by using
L<kParseIKEMessage() function in the kIKE::kIKE module|kIKE::kIKE/kParseIKEMessage()>
to do this work automatically.

=cut

##################################
# Message parsing sub prototypes #
##################################

sub kDecIKEHeader($);
sub kDecGenericPayloadHeader($);
sub kDecSecurityAssociationPayload($);
sub kDecSAProposal($);
sub kDecSATransform($);
sub kDecSAAttribute($);
sub kDecKeyExchangePayload($);
sub kDecIdentificationIPayload($);
sub kDecIdentificationRPayload($);
sub kDecCertificatePayload($);
sub kDecCertificateRequestPayload($);
sub kDecAuthenticationPayload($);
sub kDecCalcAuthenticationData($$$$$$$$);
sub kDecNoncePayload($);
sub kDecNotifyPayload($);
sub kDecDeletePayload($);
sub kDecVendorIDPayload($);
sub kDecTrafficSelectorPayload($);
sub kDecTSSelector($);
sub kDecEncryptedPayload($$$);
sub kDecEncryptedPayloadRaw($);
sub kDecCalcEncryptedPayloadChecksum($$$);
sub kDecConfigurationPayload($);
sub kDecConfigurationAttributes($$);
sub kDecEAPPayload($);

###################
# Implementations #
###################

=pod

=head2 kDecIKEHeader()

Parses an IKE Header and provide data for the next parser.

=head3 Parameters

=over

=item B<Message data>

The IKEv2 message to parse.

=back

=head3 Return value

=over

=item B<Message data>

Hash containing message data by field name.

=over

=item C<initSPI>

Security Parameter Index used by the original initiator of the exchange.
It is in a hex string without prefix or suffix.

=item C<respSPI>

Security Parameter Index used by the original responder of the exchange.
It is in a hex string without prefix or suffix.

=item C<major> / C<minor>

Current IKE version for the message. Major and minor are 4-bits values.

=item C<exchType>

The type of the current exchange. Types are enumerated in RFC4306 section 3.1.
It contains the name of the exchange type if recognized.

=item C<initiator>

This flag indicates if the current message is generated by the original initiator
or not.

=item C<higher>

This flag indicates if the sending node can speak a higher version.

=item C<response>

This flag indicates if the current message is a response or not.

=item C<messID>

This is the ID of the message in the current exchanges sequence.

=item C<nexttype>

The type of the next payload. It indicate which payload parser is needed after.
It contains the name of the type if recognized.

=item C<payloads>

The data of the next payload and followings, it will have to be provide to the next parser.

=item C<datalen>

The length of the message read from header.

=back

=back

=cut

sub kDecIKEHeader($) {
	# Get data parameter.
	my $data = shift;
	# Extract header and paylaods.
	my $header = substr($data, 0, 28);
	my $payloads = substr($data, 28);
	# Decode fields.
	my ($initSPI, $respSPI, $nexttype, $version, $exchType, $flag, $messID, $datalen) = unpack('H16 H16 C C C C N N', $header);
	# Convert field data.
	$exchType = kExchangeType($exchType);
	$nexttype = kPayloadType($nexttype);
	my $major = ($version >> 4) % 16;
	my $minor = $version % 16;
	my $reserved1 = ($flag & 0xc0);
	my $response = ($flag & 32) ? $TRUE : $FALSE;
	my $higher = ($flag & 16) ? $TRUE : $FALSE;
	my $initiator = ($flag & 8) ? $TRUE : $FALSE;
	my $reserved2 = ($flag & 0x7);
	# Return content.
	return {
		'self' => 'HDR',

		initSPI => $initSPI, 
		respSPI => $respSPI,
		major => $major,
		minor => $minor,
		exchType => $exchType,
		initiator => $initiator,
		higher => $higher,
		response => $response,
		messID => $messID,
		nexttype => $nexttype,
		payloads => $payloads,
		datalen => $datalen,
		flags => $flag,
		reserved1 => $reserved1,
		reserved2 => $reserved2
	};
}

=pod

=head2 kDecGenericPayloadHeader()

Parses a Generic Payload Header.

B<This function is not intended to be called by any programs outside the
library.>

=head3 Parameters

=over

=item B<Payload data>

The remaining message data to recognize payload in.

=back

=head3 Return value

=over

=item B<Header data>

Hash containing these entry:

=over

=item C<nexttype>

The next payload type

=item C<critical>

Critical flag

=item C<payload>

The current payload data, without the general header

=item C<payloads>

The following payloads data.

=item C<paylen>

The length of the current payload, excluding general header

=back

=back

=cut

sub kDecGenericPayloadHeader($) {
	# Get data parameter.
	my $data = shift;
	# Extract header, decode fields and extract inner data.
	my $header = substr($data, 0, 4);
	my ($nexttype, $critical, $paylen) = unpack('C C n', $header);
	my $reserved = $critical & 0x7f;
	$critical = $critical & 0x80;
	my $payload = substr($data, 4, $paylen - 4);
	my $payloads = substr($data, $paylen);
	# Convert field data.
	$nexttype = kPayloadType($nexttype);
	# Return content.
	if ($PRINT_GENERIC_PAYLOAD_HEADER) {
		printf("dbg ===> GENERIC payload header\n");
		printf("\tnexttype = %s\n", $nexttype);
		printf("\tcritical = %s\n", $critical);
		printf("\tpaylen = %s\n", $paylen);
		if ($PRINT_PAYLOAD_MORE) {
			printf("\t\tdatalen = %s\n", length($data));
			printf("\t\tleft = %s\n", length($data) - $paylen);
		}
	}
	return {
		nexttype => $nexttype,
		critical => ($critical) ? $TRUE : $FALSE,
		payload => $payload,
		payloads => $payloads,
		paylen => $paylen - 4,
		reserved => $reserved
	};
}

=pod

=head2 kDecSecurityAssociationPayload()

Parses a Security Association Payload and provide its proposals for parsing.

=head3 Parameters

=over

=item B<Payloads data>

The remaining message data to parse payloads in.

=back

=head3 Return value

=over

=item B<Payload data>

Hash containing payload data by field name.

=over

=item C<nexttype>

The type of the next payload. It indicate which payload parser is needed after.
It contains the name of the type if recognized.

=item C<proposals>

All the proposal substructures attached to this payload to be parsed. It is to
be parsed using L</kDecSAProposal()>.

=item C<payloads>

The following payloads data.

=item C<proposalsLen>

The total length of the proposal substructures.

=back

=back

=cut

sub kDecSecurityAssociationPayload($) {
	# Get data parameter.
	my $data = shift;
	# Decode general header.
	my $info = kDecGenericPayloadHeader($data);
	# Return content.
	if ($PRINT_SA_PAYLOAD) {
		printf("dbg ===> SA payload\n");
		printf("\tpaylen = %s\n", $info->{paylen}) if ($PRINT_PAYLOAD_MORE);
	}
	return {
		'self' => 'SA',

		nexttype => $info->{nexttype},
		proposals => $info->{payload},
		payloads => $info->{payloads},
		proposalsLen => $info->{paylen},
		critical => $info->{critical},
		reserved => $info->{reserved}
	};
}

=pod

=head2 kDecSAProposal()

Parses a Proposal substructure and provide its transform for parsing.

=head3 Parameters

=over

=item B<Proposal data>

The remaining proposals data to parse proposal in.

=back

=head3 Return value

=over

=item B<Proposal data>

Hash containing proposal data by field name.

=over

=item C<number>

Sequence number of the proposal in the payload.

=item C<id>

The protocol of the current proposal. Protocol IDs are enumerated in RFC4306
section 3.3.1. It contains the name of the protocol if recognized.

=item C<spiSize>

Security Parameter Index size telling about related SPIs when rekeying.

=item C<spi>

Security Parameter Index value. It is formatted as a hex string without prefix or suffix.

=item C<transformCount>

The count of transformations that are in the encoded transforms data.

=item C<transforms>

The transforms data. This is to be parsed using L</kDecSATransform()>.

=item C<transformsLen>

The length of all the transforms in this proposal.

=item C<proposalLen>

The length of this proposal.

=item C<nexttype>

The next proposal type. If it is 0, there is no more proposals.

=item C<nextdata>

The following proposals.

=back

=back

=cut

sub kDecSAProposal($) {
	# Get data parameter.
	my $data = shift;
	# Extract header, decode fields and extract inner data.
	my ($nexttype, $res1, $totalLen, $number, $id, $spiSize, $transformCount) = unpack('C C n C C C C', $data);
	my $spi = substr($data, 8, $spiSize);
	my $transforms = substr($data, 8 + $spiSize, $totalLen - 8 - $spiSize);
	my $nextdata = substr($data, $totalLen);
	# Convert field data.
	$id = kProtocolID($id);
	$spi = unpack('H[' . ($spiSize * 2) . ']', $spi) if ($spiSize > 0);
	# Return content.
	if ($PRINT_SA_PAYLOAD) {
		printf("dbg ===> SA Proposal\n");
		printf("\t\t0 or 2\t= %s\n", $nexttype);
		printf("\t\tRESERVED\t= %s\n", $res1);
		printf("\t\tProp Len\t= %s\n", $totalLen);
		printf("\t\tProposal #\t= %s\n", $number);
		printf("\t\tProposal ID\t= %s\n", $id);
		printf("\t\tSPI Size\t= %s\n", $spiSize);
		printf("\t\t# of Transforms\t= %s\n", $transformCount);
		printf("\t\tSPI\t= %s\n", $spi) if ($spiSize > 0);
	}
	return {
		'self' => 'P',

		number => $number,
		id => $id,
		spiSize => $spiSize,
		spi => $spi,
		transformCount => $transformCount,
		transforms => $transforms,
		transformsLen => $totalLen - 8 - $spiSize,
		proposalLen => $totalLen,
		nexttype => $nexttype,
		nextdata => $nextdata,
		reserved =>$res1,
	};
}

=pod

=head2 kDecSATransform()

Parses a transform substructure.

=head3 Parameters

=over

=item B<Transform data>

The remaining transforms data to parse transform in.

=back

=head3 Return value

=over

=item B<Transform data>

Hash containing transform data by field name.

=over

=item C<type>

The type of the transformation. Transform types are enumerated in RFC4306 section
3.3.2. It contains the name of the type if recognized.

=item C<id>

The transform ID for the transform. Transform IDs are enumerated in RFC4306
section 3.3.2. It contains the name of the id in current type if recognized.
The name isn't prefixed with the type name and an underscore caracter.

=item C<attributes>

The transform's attributs. This is to be parsed with L</kDecSAAttribute()>.

=item C<attributesLen>

The length of transform's attributes.

=item C<transformLen>

The length of this transform

=item C<nexttype>

The next transform type. If it is 0, there are no more transform.

=item C<nextdata>

The following transforms.

=back

=back

=cut

sub kDecSATransform($) {
	# Get data parameter.
	my $data = shift;
	# Extract header, decode fields and extract inner data.
	my $header = substr($data, 0, 8);
	my ($nexttype, $res1, $totalLen, $type, $res2, $id) = unpack('C C n C C n', $data);
	my $attributes = substr($data, 8, $totalLen - 8);
	my $nextdata = substr($data, $totalLen);
	# Convert field data.
	$id = kTransformTypeID($type, $id);
	$type = kTransformType($type);
	# Return content.
	if ($PRINT_SA_PAYLOAD) {
		printf("dbg ===> SA Transform\n");
		printf("\t\t0 or 3\t= %s\n", $nexttype);
		printf("\t\tRESERVED\t= %s\n", $res1);
		printf("\t\tTransform Len\t= %s\n", $totalLen);
		printf("\t\tTransform Type\t= %s\n", $type);
		printf("\t\tRESERVED\t= %s\n", $res2);
		printf("\t\tTransform ID\t= %s\n", $id);
	}
	return {
		'self' => 'T',

		type => $type,
		id => $id,
		attributes => $attributes,
		attributesLen => $totalLen - 8,
		transformLen => $totalLen,
		nexttype => $nexttype,
		nextdata => $nextdata,
		reserved1 => $res1,
		reserved2 => $res2
	};
}

=pod

=head2 kDecSAAttribute()

Parses an attribute substructure.

=head3 Parameters

=over

=item B<Transform data>

The remaining transforms data to parse transform in.

=back

=head3 Return value

=over

=item B<Attribute data>

Hash containing attribute data by field name.

=over

=item C<type>

The type of the attribute. Attribute types are enumerated in RFC4306 section
3.3.5. It contains the name of the type if recognized.

=item C<value>

The value associated to the type. If the value is variable length, it is a
string containing binary data. If the value is fixed length it contains an
hex string representing the 2-bytes value.

=item C<nextdata>

The following attributes.

=back

=back

=cut

sub kDecSAAttribute($) {
	# Get data parameter.
	my $data = shift;
	# Decode type.
	my $type = unpack('n', substr($data, 0, 2));
	my $value;
	my $nextdata;
	my $length = undef;
	# Extract value and remaining data.
	if ($type & 0x8000) {
		$value = unpack('n', substr($data, 2, 2)); # Decode value too.
		$nextdata = substr($data, 4);
	}
	else {
		$length = unpack('n', substr($data, 2, 2));
		$value = substr($data, 4, $length);
		$nextdata = substr($data, 4 + $length);
	}
	my $af = $type & 0x8000;
	$af = $af >> 15;
	# Convert field data.
	$type = kAttributeType($type & 0x7fff);
	# Return content.
	if ($PRINT_SA_PAYLOAD) {
		printf("dbg ===> Transform Attribute\n");
		printf("\t\tAF\t= %s\n", $type);
		printf("\t\tAttribute Type\t= %s\n", $type);
		printf("\t\tAttribute Length\t= %s\n", $length) if (defined($length));
		printf("\t\tAttribute Value\t= %s\n", $value);
	}
	return {
		'self' => 'SA Attr',

		af => $af,
		type => $type,
		length => $length,
		value => $value,
		nextdata => $nextdata
	};
}

=pod

=head2 kDecKeyExchangePayload()

Parses a Key Exchange Payload.

=head3 Parameters

=over

=item B<Payloads data>

The remaining message data to parse payloads in.

=back

=head3 Return value

=over

=item B<Payload data>

Hash containing payload data by field name.

=over

=item C<group>

This is the Diffie-Hellman group of the data contained by this payload. Groups
are defined in RFC4306 Appendix B and in RFC3526. It contains the group number.

=item C<publicKey>

The exchanged Diffie-Hellman public key. This is a Math::BigInt.

=item C<nexttype>

The type of the next payload. It indicate which payload parser is needed after.
It contains the name of the type if recognized.

=item C<payloads>

The following payloads data.

=back

=back

=cut

sub kDecKeyExchangePayload($) {
	# Get data parameter.
	my $data = shift;
	# Decode general header.
	my $info = kDecGenericPayloadHeader($data);
	my ($nexttype, $payload, $payloads, $paylen) = ($info->{nexttype}, $info->{payload}, $info->{payloads}, $info->{paylen});
	# Decode fields.
	my ($group, $res1, $publicKey) = unpack('n n H*', $payload);
	# Return content.
	return {
		'self' => 'KE',

		group => $group,
		publicKey => Math::BigInt->new('0x' . $publicKey),
		keyLen => $paylen - 4,
		nexttype => $nexttype,
		payloads => $payloads,
		critical => $info->{critical},
		reserved => $info->{reserved},
		reserved1 => $res1
	};
}

=pod

=head2 kDecNoncePayload()

Parses a Nonce Payload.

=head3 Parameters

=over

=item B<Payloads data>

The remaining message data to parse payloads in.

=back

=head3 Return value

=over

=item B<Payload data>

Hash containing payload data by field name.

=over

=item C<nexttype>

The type of the next payload. It indicate which payload parser is needed after.
It contains the name of the type if recognized.

=item C<nonce>

The value of the readed nonce data in a Math::BigInt.

=item C<payloads>

The following payloads data.

=item C<nonceLen>

The length in bytes of the nonce.

=back

=back

=cut

sub kDecNoncePayload($) {
	# Get data parameter.
	my $data = shift;
	# Decode general header.
	my $info = kDecGenericPayloadHeader($data);
	# Return content.
	return {
		'self' => 'Ni, Nr',

		nexttype => $info->{nexttype},
		nonce => Math::BigInt->new('0x' . unpack('H*', $info->{payload})),
		payloads => $info->{payloads},
		nonceLen => $info->{paylen},
		critical => $info->{critical},
		reserved => $info->{reserved}
	};
}

=pod

=head2 kDecNotifyPayload()

Parses a Notify Payload.

=head3 Parameters

=over

=item B<Payloads data>

The remaining message data to parse payloads in.

=back

=head3 Return value

=over

=item B<Payload data>

Hash containing payload data by field name.

=over

=item C<id>

The protocol concerned by this notification. Protocol IDs are enumerated in
RFC4306 section 3.3.1 (linked by section 3.10). It contains the name of the
protocol if recognized.

=item C<spiSize>

Security Parameter Index size to tell about related SPIs if applicable.

=item C<type>

The type of this notification. Notification types are enumerated in RFC4306
section 3.10.1. It contains the name of the type if recognized.

=item C<spi>

Security Parameter Index value. It is a hex string without prefix or suffix.

=item C<data>

The raw data associated to this notification. It is a string containing the data
to sended as is.

=item C<nexttype>

The type of the next payload. It indicate which payload parser is needed after.
It contains the name of the type if recognized.

=item C<payloads>

The following payloads data.

=back

=back

=cut

sub kDecNotifyPayload($) {
	# Get data parameter.
	my $data = shift;
	# Decode general header.
	my $info = kDecGenericPayloadHeader($data);
	my ($nexttype, $payload, $payloads, $paylen) = ($info->{nexttype}, $info->{payload}, $info->{payloads}, $info->{paylen});
	# Extract header and inner data.
	my $header = substr($payload, 0, 4);
	my $values = substr($payload, 4);
	# Decode fields.
	my ($id, $spiSize, $type) = unpack('C C n', $header);
	my ($spi) = unpack('H[' . ($spiSize * 8) . ']', $values);
	my $ndata = substr($values, $spiSize);
	$ndata = unpack ('H*', $ndata);
	# Convert field data.
	$id = kProtocolID($id);
	$type = kNotifyType($type);
	# Return content.
	if ($PRINT_N_PAYLOAD) {
		printf("dbg ===> N payload\n");
		printf("\tpaylen = %s\n", $paylen) if ($PRINT_PAYLOAD_MORE);
		printf("\tProto ID\t= %s\n", $id);
		printf("\tSPI Size\t= %s\n", $spiSize);
		printf("\tN Msg Type\t= %s\n", $type);
		printf("\tSPI\t= %s\n", $spi) if ($spiSize);
		my $left = $paylen - 4 - $spiSize;
		printf("\t\tleft\t= %s\n", $left) if ($PRINT_PAYLOAD_MORE);
		if ($left > 0) {
			my $tmpl = 'H'. ($paylen - 4) * 8; # paylen - GENRIC - ID
			printf("\tN Data\t= %s\n", unpack($tmpl, substr($values, $spiSize)));
		}
	}
	return {
		'self' => 'N',

		id => $id,
		type => $type,
		spiSize => $spiSize,
		spi => $spi,
		data => $ndata,
		nexttype => $nexttype,
		payloads => $payloads,
		paylen => $paylen,
		critical => $info->{critical},
		reserved => $info->{reserved}
	};
}

=pod

=head2 kDecEncryptedPayload()

Parses an encrypted payloads and decrypt inner payloads.

=head3 Parameters

=over

=item B<payloads data>

The remaining message data to parse payloads in.

=item B<Encryption material>

The L<kIKE::kEncryptionMaterial object|kIKE::kEncryptionMaterial> containing the
keys for the targetted IKE_SA used to made encryption.

=item B<Is initiator>

Indicates if the payloads is intended to be used in a message comming from the
original initiator, i.e. the end which started the current IKE_SA (a
rekey changes the original initiator to the one which started rekeying).

=back

=head3 Return value

=over

=item B<Payload data>

Hash containing payload data by field name

=over

=item C<checksum>

Checksum of the whole message. Have to be checked against computed value.

=item C<nexttype>

The type of the next payload. It indicate which payload parser is needed after.
It contains the name of the type if recognized.

=item C<payloads>

The following payloads data.

=back

=back

=cut

sub kDecEncryptedPayload($$$) {
	# Read parameters.
	my ($data, $material, $is_initiator) = @_;

	unless (defined($material)) {
		return(kDecEncryptedPayloadRaw($data));
	}

	# Decode general header.
	my $info = kDecGenericPayloadHeader($data);
	my ($nexttype, $payload, $payloads, $paylen) = ($info->{nexttype}, $info->{payload}, $info->{payloads}, $info->{paylen});

	# Extract inner data.
	my $blockSize = $material->bencr;
	my $iv = substr($payload, 0, $blockSize);
	my $cypher = substr($payload, $blockSize, -$material->binteg);
	my $checksum = substr($payload, -$material->binteg);
	# Decypher payloads
	if ($material->{'encr_alg'} eq 'AES_CTR') {
		my $key = ($is_initiator) ? $material->ei : $material->er;
		my $nonce = ($is_initiator) ? $material->ni_ctr : $material->nr_ctr;
		$payloads = &{$material->decr}($key, $cypher, $nonce, $iv);
	}
	else {
		$payloads = &{$material->decr}(($is_initiator) ? ($material->ei) : ($material->er), $cypher, $iv);
	}
	# Return content.
	return {
		'self' => 'E',

		checksum => $checksum,
		nexttype => $nexttype,
		payloads => $payloads,
		iv => $iv,
		enc_paylen => $paylen + 4, # add Generic Header
		critical => $info->{critical},
		reserved => $info->{reserved}
	};
}

=pod

=head2 kDecEncryptedPayloadRaw()

Parses an raw encrypted payloads;

=head3 Parameters

=over

=item B<payloads data>

The remaining message data to parse payloads in.

=back

=head3 Return value

=over

=item B<Payload data>

Hash containing payload data by field name

=over

=item C<nexttype>

The type of the next payload. It indicate which payload parser is needed after.
It contains the name of the type if recognized.

=item C<payloads>

The following payloads data.

=back

=back

=cut


sub kDecEncryptedPayloadRaw($) {
	# Read parameters.
	my ($data) = @_;

	# Decode general header.
	my $info = kDecGenericPayloadHeader($data);
	my ($nexttype, $payload, $payloads, $paylen) = ($info->{nexttype}, $info->{payload}, $info->{payloads}, $info->{paylen});

	return {
		'self' => 'E',

		nexttype => $nexttype,
		payloads => $payloads,
		enc_data => $payload,
		enc_paylen => $paylen + 4, # add Generic Header
		critical => $info->{critical},
		reserved => $info->{reserved}
	};
}


=pod

=head2 kDecCalcEncryptedPayloadChecksum()

Computes the checksum for the designated message. It is intended to be compared
with the extracted checksum of the message.

=head3 Parameters

=over

=item B<Encryption material>

The L<kIKE::kEncryptionMaterial object|kIKE::kEncryptionMaterial> containing the
keys for the targetted IKE_SA used to made encryption.

=item B<Is initiator>

Indicates if the payloads is intended to be used in a message comming from the
original initiator, i.e. the end which started the current IKE_SA (a
rekey changes the original initiator to the one which started rekeying).

=item B<Message>

The IKE message containing an encrypted payload for which to compute checksum.

=back

=head3 Return value

=over

=item B<Checksum>

The computed checksum of the message.

=back

=cut

sub kDecCalcEncryptedPayloadChecksum($$$) {
	# Read parameters.
	my ($material, $is_initiator, $message) = @_;
	$message = substr($message, 0, length($message) - $material->binteg);
	# Return checksum.
	return &{$material->integ}(($is_initiator) ? ($material->ai) : ($material->ar), $message);
}


=pod

=head2 kDecIdentificationPayload()

Parses an Identification Payload (Initiator or Responder).

=head3 Parameters

=over

=item B<Payloads data>

The remaining message data to parse payloads in.

=back

=head3 Return value

=over

=item B<Payload data>

Hash containing payload data by field name.

=over

=item C<type>

The type of the identification data. Identification data types are enumerated in
RFC4306 section 3.5. This contains the name of the type if it has been recognized.

=item C<value>

The data associated with this identification.

=item C<nexttype>

The type of the next payload. It indicates which payload parser is needed after.
It contains the name of the type if recognized.

=item C<payloads>

The following payloads data.

=back

=back

=cut

sub kDecIdentificationIPayload($)
{
	my ($data) = @_;
	my $ret = kDecIdentificationPayload($data);
	$ret->{'self'} = 'IDi';
	return($ret);
}

sub kDecIdentificationRPayload($)
{
	my ($data) = @_;
	my $ret = kDecIdentificationPayload($data);
	$ret->{'self'} = 'IDr';
	return($ret);
}

sub kDecIdentificationPayload($) {
	# Get data parameter.
	my $data = shift;
	# Decode general header.
	my $info = kDecGenericPayloadHeader($data);
	my ($nexttype, $payload, $payloads, $paylen) = ($info->{nexttype}, $info->{payload}, $info->{payloads}, $info->{paylen});
	# Decode and extracting fields.
	my $type = unpack('C C3', substr($payload, 0, 1));
	my ($res0, $res1, $res2) = unpack('C3', substr($payload, 1, 3));
	my $reserved1 = ($res0 << 16) | ($res1 << 8) | ($res2);
	my $value = substr($payload, 4);
	# Convert field data.
	$type = kIdentificationType($type);
	# Return content.
	if ($PRINT_ID_PAYLOAD) {
		printf("dbg ===> IDr payload\n");
		printf("\tpaylen = %s\n", $paylen) if ($PRINT_PAYLOAD_MORE);
		printf("\tID Type\t= %s\n", $type);
		my $tmpl = 'H'. ($paylen - 4) * 8;
		printf("\tID data\t= %s\n", unpack($tmpl, $value));
	}
	return {
		type => $type,
		value => $value,
		nexttype => $nexttype,
		payloads => $payloads,
		critical => $info->{critical},
		reserved => $info->{reserved},
		reserved1 => $reserved1,
	};
}

=pod

=head2 kDecAuthenticationPayload()

Parses an Authentication Payload.

=head3 Parameters

=over

=item B<Payloads data>

The remaining message data to parse payloads in.

=back

=head3 Return value

=over

=item B<Payload data>

Hash containing payload data by field name.

=over

=item C<method>

The method used to authenticate to the other end. Authentication methods are
enumerated in RFC4306 section 3.8. This contains the method name if recognized.

=item C<data>

The data associated with the authentication method provided by the other end.

=item C<nexttype>

The type of the next payload. It indicates which payload parser is needed after.
It contains the name of the type if recognized.

=item C<payloads>

The following payloads data.

=back

=back

=cut

# 3.8 2.15 C3.1
sub kDecAuthenticationPayload($) {
	# Get data parameter.
	my $data = shift;
	# Decode general header.
	my $info = kDecGenericPayloadHeader($data);
	my ($nexttype, $payload, $payloads, $paylen) = ($info->{nexttype}, $info->{payload}, $info->{payloads}, $info->{paylen});
	# Decode fields.
	my $method = unpack('C', substr($payload, 0, 1));
	my ($res0, $res1, $res2) = unpack('C3', substr($payload, 1, 3));
	my $reserved1 = ($res0 << 16) | ($res1 << 8) | ($res2);
	my $methodData = substr($payload, 4);
	$methodData = unpack('H*', $methodData);
	# Convert field data.
	$method = kAuthenticationMethod($method);
	# Return content.
	if ($PRINT_AUTH_PAYLOAD) {
		printf("dbg ===> AUTH payload\n");
		printf("\tpaylen = %s\n", $paylen) if ($PRINT_PAYLOAD_MORE);
		printf("\tAuth Method\t= %s\n", $method);
		my $tmpl = 'H'. ($paylen - 4) * 8;
		printf("\tAuth Data\t= %s\n", unpack($tmpl, $methodData));
	}
	return {
		'self' => 'AUTH',

		method => $method,
		data => $methodData,
		nexttype => $nexttype,
		payloads => $payloads,
		critical => $info->{critical},
		reserved => $info->{reserved},
		reserved1 => $reserved1,
	};
}

=pod

=head2 kDecCalcAuthenticationData()

Computes authentication data for comparison.

=head3 Parameters

=over

=item B<Encryption material>

The L<kIKE::kEncryptionMaterial object|kIKE::kEncryptionMaterial> containing the
keys for the targetted IKE_SA used to made encryption.

=item B<Authentication method>

The method to use to authenticates to the other end. Authentication methods are
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

=back

=head3 Return value

=over

=item B<Authentication data>

The authentication data as expected in payloads.

=back

=cut

# 3.8 2.15 C3.1
sub kDecCalcAuthenticationData($$$$$$$$) {
	# Read parameters.
	my ($material, $method, $methoddata, $is_initiator, $saInitMessage, $nonce, $nonce_strlen, $id, $nexttype, $nextdata) = @_;
	# Construct final values.
	$method = kAuthenticationMethod($method) if $method !~ /^[0-9]+$/;
	$method = int($method);
	my $authData;
	# Compute data to sign.
	my $authKey = ($is_initiator) ? ($material->pi) : ($material->pr);
	my $idPayload = pack('C C C C', kIdentificationType($id->{'type'}), 0, 0, 0);
	$idPayload .= $id->{'value'};
	my $macID = &{$material->prf}($authKey, $id);
	my $signedData = $saInitMessage . pack('H*', kIKE::kHelpers::as_hex2($nonce, $nonce_strlen)) . $macID;

	# Compute signature
	if ($method == 1) {
		$authData = &{$material->prf}($methoddata, $signedData);
	}
	elsif ($method == 2) {
		my $k = &{$material->prf}($methoddata, "Key Pad for IKEv2");
		$authData = &{$material->prf}($k,
			$signedData);
	}
	else {
		die('Unsupported authentication method: ' . $method);
	}
	# Return auth data.
	return $authData;
}

=pod

=head2 kDecTrafficSelectorPayload()

Parses a Traffic Selector Payload and provides its traffic selector substructures.

=head3 Parameters

=over

=item B<Payloads data>

The remaining message data to parse payloads in.

=back

=head3 Return value

=over

=item B<Payload data>

Hash containing payload data by field name.

=over

=item C<count>

The count of traffic selectors in this payload.

=item C<selectors>

All the traffic selector substructures attached to this payload to be parsed. It
have to be parsed using L</kDecTSSelector()>.

=item C<nexttype>

The type of the next payload. It indicates which payload parser is needed after.
It contains the name of the type if recognized.

=item C<payloads>

The following payloads data.

=back

=back

=cut

sub kDecTrafficSelectorIPayload($)
{
	my ($data) = @_;
	my $ret = kDecTrafficSelectorPayload($data);
	$ret->{'self'} = 'TSi';
	return($ret);
}

sub kDecTrafficSelectorRPayload($)
{
	my ($data) = @_;
	my $ret = kDecTrafficSelectorPayload($data);
	$ret->{'self'} = 'TSr';
	return($ret);
}

sub kDecTrafficSelectorPayload($) {
	my $data = shift;

	my $info = kDecGenericPayloadHeader($data);
	my $nexttype = $info->{'nexttype'};
	my $payload = $info->{'payload'};
	my $payloads  = $info->{'payloads'};
	my $paylen = $info->{'paylen'};


	my $count = unpack('C', substr($payload, 0, 1));
	my ($res0, $res1, $res2) = unpack('C3', substr($payload, 1, 3));
	my $reserved1 = ($res0 << 16) | ($res1 << 8) | ($res2);
	my $ts_data = substr($payload, 4);

	my $selectors = [];
	for (my $i = 0; ($i < $count) && (length($ts_data) > 8); $i++) {
		my $selector = kDecTSSelector($ts_data);
		$ts_data = $selector->{'nextdata'};
		undef $selector->{'nextdata'};

		push(@{$selectors}, $selector);
	}

	if ($PRINT_TS_PAYLOAD) {
		printf("dbg ===> TS payload\n");
		printf("\tpaylen\t= %s\n", $paylen) if ($PRINT_PAYLOAD_MORE);
		printf("\t# of TSs\t= %s\n", $count);
	}
	return {
		count => $count,
		selectors => $selectors,
		nexttype => $nexttype,
		payloads => $payloads,
		critical => $info->{critical},
		reserved => $info->{reserved},
		reserved1 => $reserved1,
	};
}

=pod

=head2 kDecTSSelector()

Parses a traffic selector substructure.

=head3 Parameters

=over

=item B<Traffic selector data>

The remaining traffic selector data to parse traffic selector in.

=back

=head3 Return value

=over

=item B<Traffic selector data>

Hash containing traffic selector data by field name.

=over

=item C<type>

The Traffic Selector type of this Traffic Selector. Types are defined in RFC4306
section 3.13.1. This contains the name if recognized. In this case, the fields
C<sport>, C<eport>, C<saddr> and C<eaddr> are provided. In other cases the field
C<data> is provided.

=item C<protocol>

The protocol ID matching protocol IDs in the file /etc/protocols on unix systems
or in the file %SYSTEMROOT%\System32\Drivers\etc\protocols on windows NT systems.
Use 0 for any protocol. It is the protocol number.

=item C<sport> C<eport>

The 'port' range of acceptable values for current protocol. Can have many meanings
for protocols other than TCP and UDP. Numeric values

=item C<saddr> C<eaddr>

The address range of acceptable source/destination. This is in binary form
as used in the protocol headers.

=item C<data>

The content of C<sport>, C<eport>, C<saddr> and C<eaddr> when there sizes aren't
known because of an unknown selector type. No transformation applied.

=item C<nextdata>

The following traffic selector.

=back

=back

=cut

sub kDecTSSelector($) {
	# Get data parameter.
	my $data = shift;
	my $header = substr($data, 0, 4);
	# Decode fields.
	my ($type, $id, $length) = unpack('C C n', $header);
	my $selectors = substr($data, $length);
	$data = substr($data, 4, $length - 4);
	# Convert field data.
	$type = kTrafficSelectorType($type);
	if (($type !~ m/^[0-9]+$/) && (
		($type eq 'IPV6_ADDR_RANGE') || ($type eq 'IPV4_ADDR_RANGE'))) {
		my ($sport, $eport) = unpack('n n', substr($data, 0, 4));
		$data = substr($data, 4);
		my $saddr = substr($data, 0, length($data) / 2);
		my $eaddr = substr($data, length($data) / 2);
		# Return content.
		if ($PRINT_TS_PAYLOAD) {
			printf("dbg ===> TS\n");
			printf("\t\tTS Type\t= %s\n", $type);
			printf("\t\tIP Proto ID\t= %s\n", $id);
			printf("\t\tlen\t= %s\n", $length);
			printf("\t\tsport\t= %s\n", $sport);
			printf("\t\teport\t= %s\n", $eport);
			if ($type eq 'IPV6_ADDR_RANGE') {
				printf("\t\tsaddr\t= %s\n", unpack('H32', $saddr));
				printf("\t\teaddr\t= %s\n", unpack('H32', $eaddr));
			}
			elsif ($type eq 'IPV4_ADDR_RANGE') {
				printf("\t\tsaddr\t= %s\n", unpack('H8', $saddr));
				printf("\t\teaddr\t= %s\n", unpack('H8', $eaddr));
			}
		}
		return {
			'self' => 'TS',

			type => $type,
			protocol => $id,
			sport => $sport,
			eport => $eport,
			saddr => $saddr,
			eaddr => $eaddr,
			nextdata => $selectors,
			selectorLen => $length
		};
	}
	else {
		# Return content.
		return {
			'self' => 'TS',

			type => $type,
			protocol => $id,
			data => $data,
			nextdata => $selectors
		};
	}
}

=pod

=head2 kDecDeletePayload()

Parses a Delete Payload.

=head3 Parameters

=over

=item B<Payloads data>

The remaining message data to parse payloads in.

=back

=head3 Return value

=over

=item B<Payload data>

Hash containing payload data by field name.

=over

=item C<id>

The protocol of the deleted SA. Protocol IDs are enumerated in RFC4306
section 3.3.1. It contains the name of the protocol if recognized.

=item C<spiSize>

The size of the Security Parameter Indexes.

=item C<spiCount>

The count of Security Parameter Index concerned.

=item C<spis>

The Security Parameter Index values. It has to be formatted as a hex string
without prefix or suffix. It is the concatenation of all the concerned SPIs.

=item C<nexttype>

The next proposal type. If it is 0, there is no more proposals.

=item C<nextdata>

The following proposals.

=back

=back

=cut

sub kDecDeletePayload($) {
	# Get data parameter.
	my $data = shift;
	# Decode general header.
	my $info = kDecGenericPayloadHeader($data);
	my ($nexttype, $payload, $payloads, $paylen) = ($info->{nexttype}, $info->{payload}, $info->{payloads}, $info->{paylen});
	# Decode fields.
	my ($id, $spiSize, $spiCount, $spis) = unpack('C C n H*', $payload);
	# Convert field data.
	$id = kProtocolID($id);
	# Return content.
	return {
		'self' => 'D',

		payloads => $payloads,
		id => $id,
		spiSize => $spiSize,
		spiCount => $spiCount,
		spis => $spis,
		nexttype => $nexttype,
		nextdata => $payloads,
		critical => $info->{critical},
		reserved => $info->{reserved}
	};
}

=pod

=head1 SEE ALSO

Use RFC4306 as reference to understand the format.

=head1 AUTHOR

Pierrick Caillon, <pierrick@64translator.com>, from tahi project.

=cut


sub kDecVendorIDPayload($) {
	my ($data) = @_;

	# Decode general header.
	my $info = kDecGenericPayloadHeader($data);
	my ($nexttype, $payload, $payloads, $paylen) =
		($info->{nexttype}, $info->{payload}, $info->{payloads}, $info->{paylen});

	# Decode fields.
	my $vid = Math::BigInt->new('0x' . unpack('H*', $info->{payload}));

	return {
		'self' => 'V',

		nexttype => $nexttype,
		critical => $info->{critical},
		reserved => $info->{reserved},
		vendorID => $vid,
		payloads => $payloads,
	};
}

sub kDecCertificatePayload($) {
	my ($data) = @_;

	# Decode general header.
	my $info = kDecGenericPayloadHeader($data);
	my ($nexttype, $payload, $payloads, $paylen) =
		($info->{nexttype}, $info->{payload}, $info->{payloads}, $info->{paylen});

	# Decode fields.
	my ($cert_encoding, $cert_data) = unpack('C H*', $info->{payload});

	# convert data
	$cert_encoding = kCertificateEncoding($cert_encoding);

	return {
		'self' => 'CERT',

		nexttype => $nexttype,
		critical => $info->{critical},
		reserved => $info->{reserved},
		cert_encoding => $cert_encoding,
		cert_data => $cert_data,
		payloads => $payloads,
	};
}

sub kDecCertificateRequestPayload($) {
	my ($data) = @_;

	# Decode general header.
	my $info = kDecGenericPayloadHeader($data);
	my ($nexttype, $payload, $payloads, $paylen) =
		($info->{nexttype}, $info->{payload}, $info->{payloads}, $info->{paylen});

	# Decode fields.
	my ($cert_encoding, $cert_auth) = unpack('C H*', $info->{payload});

	# convert data
	$cert_encoding = kCertificateEncoding($cert_encoding);

	return {
		'self' => 'CERTREQ',

		nexttype => $nexttype,
		critical => $info->{critical},
		reserved => $info->{reserved},
		cert_encoding => $cert_encoding,
		cert_authority => $cert_auth,
		payloads => $payloads,
	};
}

sub kDecEAPPayload($) {
	my ($data) = @_;

	# Decode general header.
	my $info = kDecGenericPayloadHeader($data);
	my ($nexttype, $payload, $payloads, $paylen) =
		($info->{nexttype}, $info->{payload}, $info->{payloads}, $info->{paylen});

	# Decode fields.
	my ($code, $id, $eapmsg_length) = unpack('C C n', $info->{payload});
	my ($type, $type_data) = unpack('C H*', substr($info->{payload}, 4, $paylen - 4));

	return {
		'self' => 'EAP',

		nexttype => $nexttype,
		critical => $info->{critical},
		reserved => $info->{reserved},
		code => $code,
		id => $id,
		eapmsg_length => $eapmsg_length,
		type => $type,
		data => $type_data,
		payloads => $payloads,
	};
}

sub kDecConfigurationPayload($) {
	my ($data) = @_;

	# Decode general header.
	my $info = kDecGenericPayloadHeader($data);
	my ($nexttype, $payload, $payloads, $paylen) =
		($info->{nexttype}, $info->{payload}, $info->{payloads}, $info->{paylen});

	# Decode fields.
	my $cfg_type = unpack('C', substr($payload, 0, 1));
	my ($res0, $res1, $res2) = unpack('C3', substr($payload, 1, 3));
	my $reserved1 = ($res0 << 16) | ($res1 << 8) | ($res2);
	my $attributes = substr($payload, 4);

	$attributes = kDecConfigurationAttributes($attributes, $paylen);

	# convert data
	$cfg_type = kConfigurationType($cfg_type);

	return {
		'self' => 'CP',

		'nexttype' => $nexttype,
		'critical' => $info->{'critical'},
		'reserved' => $info->{'reserved'},
		'payloads' => $payloads,
		'cfg_type' => $cfg_type,
		'reserved1' => $reserved1,
		'attributes' => $attributes,
	};
}

sub kDecConfigurationAttributes($$) {
	my ($data, $paylen) = @_;

	my @result = ();

	for (my $offset = 0; $paylen - $offset - 8 >= 0; ) {
		my ($attr_type, $length) = unpack('n n ', substr($data, $offset, $offset + 4));
		my $reserved = $attr_type & 0x8000;
		$reserved = $reserved >> 15;
		$attr_type = $attr_type & 0x7fff;
		$offset += 4;

		my $value = unpack('H*', substr($data, $offset, $length * 2));
		$offset += $length * 2;

		# convert data
		$attr_type = kConfAttributeType($attr_type);

		my $attr = {
			'self' => 'CP Attr',

			'reserved'	=> $reserved,
			'attr_type'	=> $attr_type,
			'length'	=> $length,
			'value'		=> $value,
		};
		push(@result, $attr);
	}

	my $n = scalar(@result);
	return(\@result);
}


1;
