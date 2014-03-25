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
# $TAHI: koi/libdata/kIKE/kConsts.pm,v 0.1 2007/07/06 13:08:00 pierrick Exp $
#
# $Id: kConsts.pm,v 1.5 2008/10/20 09:09:13 velo Exp $
#
########################################################################

package kIKE::kConsts;

use strict;
use warnings;
use Exporter;

our @ISA = qw(Exporter);

our @EXPORT = qw (
	kExchangeType
	kPayloadType
	kProtocolID
	kTransformType
	kTransformTypeID
	kDHPrime
	kDHGenerator
	kNotifyType
	kCompressionType
	kAttributeType
	kDHPublicValueLength
	kKeySize
	kBlockSize
	kIdentificationType
	kTrafficSelectorType
	kCertificateEncoding
	kAuthenticationMethod
	kConfigurationType
	kConfAttributeType
	kIPProtocolID

	$CONSTS
);

our $TRUE = 1;
our $FALSE = 0;

our $CONSTS = {
	'IKE_SA_SPI_STRLEN'	=> 16,
	'CHILD_SA_SPI_STRLEN'	=> 8,
};

##############
# Prototypes #
##############

sub kExchangeType($);
sub kPayloadType($);
sub kProtocolID($);
sub kTransformType($);
sub kTransformTypeID($$);
sub kDHPrime($);
sub kDHGenerator($);
sub kNotifyType($);
sub kCompressionType($);
sub kAttributeType($);
sub kDHPublicValueLength($);
sub kKeysize($);
sub kBlockSize($);
sub kIdentificationType($);
sub kTrafficSelectorType($);
sub kAuthenticationMethod($);
sub kConfigurationType($);
sub kConfAttributeType($);

=pod

=head1 NAME

kIKE::kConsts - Constant provider for IKEv2 test scripts.

=head1 SYNOPSIS

 use kIKE::kConsts;
 push @ISA, 'kIKE::kConsts';

=head1 METHODS

The subs in this package are to be used to get numeric value of IKEv2 constants
or to get the constant name from its value. They only differ in the destination
enumeration.

=cut

###################
# IKEv2 Constants #
###################

# IKEv2 Exchange types
# RFC4306 3.1
my %exchangeTypes = (
	IKE_SA_INIT => 34,
	34 => 'IKE_SA_INIT',
	IKE_AUTH => 35,
	35 => 'IKE_AUTH',
	CREATE_CHILD_SA => 36,
	36 => 'CREATE_CHILD_SA',
	INFORMATIONAL => 37,
	37 => 'INFORMATIONAL'
);

# IKEv2 Payload types
# RFC4306 3.2
my %payloadTypes = (
	SA => 33,
	33 => 'SA',
	KE => 34,
	34 => 'KE',
	IDi => 35,
	35 => 'IDi',
	IDr => 36,
	36 => 'IDr',
	CERT => 37,
	37 => 'CERT',
	CERTREQ => 38,
	38 => 'CERTREQ',
	AUTH => 39,
	39 => 'AUTH',
	Ni => 40,
	Nr => 40,
	'Ni, Nr' => 40,
	40 => 'Ni, Nr',
	N => 41,
	41 => 'N',
	D => 42,
	42 => 'D',
	V => 43,
	43 => 'V',
	TSi => 44,
	44 => 'TSi',
	TSr => 45,
	45 => 'TSr',
	E => 46,
	46 => 'E',
	CP => 47,
	47 => 'CP',
	EAP => 48,
	48 => 'EAP'
);

# IKEv2 Protocol IDs
# RFC4306 3.3.1
my %protocolIDs = (
	IKE => 1,
	1 => 'IKE',
	AH => 2,
	2 => 'AH',
	ESP => 3,
	3 => 'ESP'
);

# IKEv2 Transform types
# RFC4306 3.3.2
my %transformTypes = (
	ENCR => 1,
	1 => 'ENCR',
	PRF => 2,
	2 => 'PRF',
	INTEG => 3,
	3 => 'INTEG',
	'D-H' => 4,
	4 => 'D-H',
	ESN => 5,
	5 => 'ESN'
);

# IKEv2 Transform IDs by Type
# RFC4306 3.3.2
my %transformTypesIDs = (
	1 => {(
		'0'	=> 'RESERVED',
		'1'	=> 'DES_IV64',
		'2'	=> 'DES',
		'3'	=> '3DES',
		'4'	=> 'RC5',
		'5'	=> 'IDEA',
		'6'	=> 'CAST',
		'7'	=> 'BLOWFISH',
		'8'	=> '3IDEA',
		'9'	=> 'DES_IV32',
		'10'	=> 'RESERVED',
		'11'	=> 'NULL',
		'12'	=> 'AES_CBC',
		'13'	=> 'AES_CTR',
		'14'	=> 'AES-CCM_8',
		'15'	=> 'AES-CCM_12',
		'16'	=> 'AES-CCM_16',
		'18'	=> 'AES-GCM_8',
		'19'	=> 'AES-GCM_12',
		'20'	=> 'AES-GCM_16',
		'21'	=> 'NULL_AUTH_AES_GMAC',
		'RESERVED'	=> '0',
		'DES_IV64'	=> '1',
		'DES'		=> '2',
		'3DES'		=> '3',
		'RC5'		=> '4',
		'IDEA'		=> '5',
		'CAST'		=> '6',
		'BLOWFISH'	=> '7',
		'3IDEA'		=> '8',
		'DES_IV32'	=> '9',
		'NULL'		=> '11',
		'AES_CBC'	=> '12',
		'AES_CTR'	=> '13',
		'AES-CCM_8'	=> '14',
		'AES-CCM_12'	=> '15',
		'AES-CCM_16'	=> '16',
		'AES-GCM_8'	=> '18',
		'AES-GCM_12'	=> '19',
		'AES-GCM_16'	=> '20',
		'NULL_AUTH_AES_GMAC'	=> '21',
	)},
	2 => {(
		'0'	=> 'RESERVED',
		'1'	=> 'HMAC_MD5',
		'2'	=> 'HMAC_SHA1',
		'3'	=> 'HMAC_TIGER',
		'4'	=> 'AES128_XCBC',
		'5'	=> 'HMAC_SHA2_256',
		'6'	=> 'HMAC_SHA2_384',
		'7'	=> 'HMAC_SHA2_512',
		'8'	=> 'AES128_CMAC',
		'RESERVED'	=> '0',
		'HMAC_MD5'	=> '1',
		'HMAC_SHA1'	=> '2',
		'HMAC_TIGER'	=> '3',
		'AES128_XCBC'	=> '4',
		'HMAC_SHA2_256'	=> '5',
		'HMAC_SHA2_384'	=> '6',
		'HMAC_SHA2_512'	=> '7',
		'AES128_CMAC'	=> '8',
	)},
	3 => {(
		'0'	=> 'NONE',
		'1'	=> 'HMAC_MD5_96',
		'2'	=> 'HMAC_SHA1_96',
		'3'	=> 'DES_MAC',
		'4'	=> 'KPDK_MD5',
		'5'	=> 'AES_XCBC_96',
		'6'	=> 'HMAC_MD5_128',
		'7'	=> 'HMAC_SHA1_160',
		'8'	=> 'AES_CMAC_96',
		'9'	=> 'AES_128_GMAC',
		'10'	=> 'AES_192_GMAC',
		'11'	=> 'AES_256_GMAC',
		'12'	=> 'HMAC_SHA2_256_128',
		'13'	=> 'HMAC_SHA2_384_192',
		'14'	=> 'HMAC_SHA2_512_256',
		'NONE'		=> '0',
		'HMAC_MD5_96'	=> '1',
		'HMAC_SHA1_96'	=> '2',
		'HMAC_DES_MAC'	=> '3',
		'HMAC_KPDK_MD5'	=> '4',
		'AES_XCBC_96'	=> '5',
		'HMAC_MD5_128'	=> '6',
		'HMAC_SHA1_160'	=> '7',
		'AES_CMAC_96'	=> '8',
		'AES_128_GMAC'	=> '9',
		'AES_192_GMAC'	=> '10',
		'AES_256_GMAC'	=> '11',
		'HMAC_SHA2_256_128'	=> '12',
		'HMAC_SHA2_384_192'	=> '13',
		'HMAC_SHA2_512_256'	=> '14',
	)},
	4 => {(
		'0'	=> 'NONE',
		'1'	=> '768 MODP Group',
		'2'	=> '1024 MODP Group',
		'5'	=> '1536 MODP Group',
		'14'	=> '2048 MODP Group',
		'15'	=> '3072 MODP Group',
		'16'	=> '4096 MODP Group',
		'17'	=> '6144 MODP Group',
		'18'	=> '8192 MODP Group',
		'19'	=> '256-bit random ECP group',
		'20'	=> '384-bit random ECP group',
		'21'	=> '512-bit random ECP group',
		'22'	=> '1024-bit MODP group with 160-bit prime Order Subgroup',
		'23'	=> '2048-bit MODP group with 224-bit prime Order Subgroup',
		'24'	=> '2048-bit MODP group with 256-bit prime Order Subgroup',
		'25'	=> '192-bit Random ECP Group',
		'26'	=> '224-bit Random ECP Group',
		'NONE'	=> '0',
		'768'	=> '1',
		'1024 MODP Group' => '2',
		'1536 MODP Group' => '5',
		'2048 MODP Group' => '14',
		'3072 MODP Group' => '15',
		'4096 MODP Group' => '16',
		'6144 MODP Group' => '17',
		'8192 MODP Group' => '18',
		'256-bit random ECP group'	=> '19',
		'384-bit random ECP group'	=> '20',
		'512-bit random ECP group'	=> '21',
		'1024-bit MODP group with 160-bit prime Order Subgroup'	=> '22',
		'2048-bit MODP group with 224-bit prime Order Subgroup'	=> '23',
		'2048-bit MODP group with 256-bit prime Order Subgroup'	=> '24',
		'192-bit Random ECP Group'	=> '25',
		'224-bit Random ECP Group'	=> '26',
	)},
	5 => {(
		'No ESN' => 0,
		0 => 'No ESN',
		ESN => 1,
		1 => 'ESN'
	)}
);

# Diffie-Hellman groups prime (hex)
# RFC4306 Appendix B
# RFC3526
my %dhPrimes = (
	2 => '0x'.
		'ffffffffffffffffc90fdaa22168c234c4c6628b80dc1cd1'.
		'29024e088a67cc74020bbea63b139b22514a08798e3404dd'.
		'ef9519b3cd3a431b302b0a6df25f14374fe1356d6d51c245'.
		'e485b576625e7ec6f44c42e9a637ed6b0bff5cb6f406b7ed'.
		'ee386bfb5a899fa5ae9f24117c4b1fe649286651ece65381'.
		'ffffffffffffffff',
	14 => '0x'.
		'FFFFFFFFFFFFFFFFC90FDAA22168C234C4C6628B80DC1CD1'.
		'29024E088A67CC74020BBEA63B139B22514A08798E3404DD'.
		'EF9519B3CD3A431B302B0A6DF25F14374FE1356D6D51C245'.
		'E485B576625E7EC6F44C42E9A637ED6B0BFF5CB6F406B7ED'.
		'EE386BFB5A899FA5AE9F24117C4B1FE649286651ECE45B3D'.
		'C2007CB8A163BF0598DA48361C55D39A69163FA8FD24CF5F'.
		'83655D23DCA3AD961C62F356208552BB9ED529077096966D'.
		'670C354E4ABC9804F1746C08CA18217C32905E462E36CE3B'.
		'E39E772C180E86039B2783A2EC07A28FB5C55DF06F4C52C9'.
		'DE2BCBF6955817183995497CEA956AE515D2261898FA0510'.
		'15728E5A8AACAA68FFFFFFFFFFFFFFFF'
);

# Diffie-Hellman groups generator
# RFC4306 Appendix B
# RFC3526
my %dhGenerator = (
	2 => 2,
	14 => 2
);

# IKEv2 Notification Types
# RFC4306 3.10.1
my %notificationTypes = (
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
        INITIAL_CONTACT => 16384,
        16384 => 'INITIAL_CONTACT',
        SET_WINDOW_SIZE => 16385,
        16385 => 'SET_WINDOW_SIZE',
        ADDITIONAL_TS_POSSIBLE => 16386,
        16386 => 'ADDITIONAL_TS_POSSIBLE',
        IPCOMP_SUPPORTED => 16387,
        16387 => 'IPCOMP_SUPPORTED',
        NAT_DETECTION_SOURCE_IP => 16388,
        16388 => 'NAT_DETECTION_SOURCE_IP',
        NAT_DETECTION_DESTINATION_IP => 16389,
        16389 => 'NAT_DETECTION_DESTINATION_IP',
        COOKIE => 16390,
        16390 => 'COOKIE',
        USE_TRANSPORT_MODE => 16391,
        16391 => 'USE_TRANSPORT_MODE',
        HTTP_CERT_LOOKUP_SUPPORTED => 16392,
        16392 => 'HTTP_CERT_LOOKUP_SUPPORTED',
        REKEY_SA => 16393,
        16393 => 'REKEY_SA',
        ESP_TFC_PADDING_NOT_SUPPORTED => 16394,
        16394 => 'ESP_TFC_PADDING_NOT_SUPPORTED',
        NON_FIRST_FRAGMENTS_ALSO => 16395,
        16395 => 'NON_FIRST_FRAGMENTS_ALSO'
);

# IKEv2 Compression types
# RFC4306 3.10.1 under IPCOMP_SUPPORTED status notification type.
my %compressionTypes = (
	OUI => 1,
	1 => 'OUI',
	DEFLATE => 2,
	2 => 'DEFLATE',
	LZS => 3,
	3 => 'LZS',
	LZJH => 4,
	4 => 'LZJH'
);

my %dhPublicValueLength = (
	'2'	=> '1024',
	'5'	=> '1536',
	'14'	=> '2048',
	'15'	=> '3072',
	'16'	=> '4096',
	'17'	=> '6144',
	'18'	=> '8192',
	'1024 MODP Group' => '1024',
	'1536 MODP Group' => '1536',
	'2048 MODP Group' => '2048',
	'3072 MODP Group' => '3072',
	'4096 MODP Group' => '4096',
	'6144 MODP Group' => '6144',
	'8192 MODP Group' => '8192',
);

# Key size for encryption algorithms, pseudo random functions and integrity algorithms
# The sizes are in bits.
my %keySizes = (
	'3DES'		=> 192,			# ENCR_3DES
	'AES_CBC'	=> [ 128, 192, 256 ],	# ENCR_AES_CBC
	'AES_CTR'	=> [ 128, 192, 256 ],	# ENCR_AES_CTR
	'HMAC_SHA1'	=> 160,			# PRF_HMAC_SHA
	'AES128_XCBC'	=> 128,			# PRF_AES128_XCBC
	'HMAC_SHA1_96'	=> 160,			# AUTH_HMAC_SHA1_96
	'AES_XCBC_96'	=> 128,			# AUTH_AES_XCBC_96
);

# IKEv2 Attributes Types
# RFC4306 3.3.5
my %attributeTypes = (
	'Key Length' => 14,
	14 => 'Key Length'
);

# Block sizes for encryptions algorithms and integrity algorithm.
# The sizes are in bytes.
my %blockSizes = (
	'3DES' => 8,
	AES_CTR => 16,
	AES_CBC => 16,
	HMAC_SHA1_96 => 12,
	AES_XCBC_96 => 12
);

# IKEv2 Identification Types
# RFC4306 3.5
my %identificationTypes = (
	IPV4_ADDR => 1,
	1 => 'IPV4_ADDR',
	FQDN => 2,
	2 => 'FQDN',
	RFC822_ADDR => 3,
	3 => 'RFC822_ADDR',
	IPV6_ADDR => 5,
	5 => 'IPV6_ADDR',
	DER_ASN1_DN => 9,
	9 => 'DER_ASN1_DN',
	DER_ASN1_GN => 10,
	10 => 'DER_ASN1_GN',
	KEY_ID => 11,
	11 => 'KEY_ID'
);

# IKEv2 Traffic Selector Types
# RFC4306 3.13.1
my %trafficSelectorTypes = (
	IPV4_ADDR_RANGE => 7,
	7 => 'IPV4_ADDR_RANGE',
	IPV6_ADDR_RANGE => 8,
	8 => 'IPV6_ADDR_RANGE'
);

# IKEv2 Authentication methods
# RFC4306 3.8
my %authenticationMethods = (
	'RSA Digital Signature' => 1,
	RSA_DS => 1,
	RSA => 1,
	1 => 'RSA_DS',
	'Shared Key Message Integrity Code' => 2,
	SK_MIC => 2,
	SK => 2,
	2 => 'SK_MIC',
	'DSS Digital Signature' => 3,
	DSS_DS => 3,
	DSS => 3,
	3 => 'DSS_DSS'
);


# IKEv2 Certificate Encoding Types
# RFC4306 3.6
my %certificateEncodings = (
	'RESERVED' => '0',
	'PKCS #7 wrapped X.509 certificate' => '1',
	'PGP Certificate' => '2',
	'DNS Signed Key' => '3',
	'X.509 Certificate - Signature' => '4',
	'Kerberos Token' => '6',
	'Certificate Revocation List (CRL)' => '7',
	'Authority Revocation List (ARL)' => '8',
	'SPKI Certificate' => '9',
	'X.509 Certificate - Attribute' => '10',
	'Raw RSA Key' => '11',
	'Hash and URL of X.509 certificate' => '12',
	'Hash and URL of X.509 bundle' => '13',
	'0' => 'RESERVED',
	'1' => 'PKCS #7 wrapped X.509 certificate',
	'2' => 'PGP Certificate',
	'3' => 'DNS Signed Key',
	'4' => 'X.509 Certificate - Signature',
	'6' => 'Kerberos Token',
	'7' => 'Certificate Revocation List (CRL)',
	'8' => 'Authority Revocation List (ARL)',
	'9' => 'SPKI Certificate',
	'10' => 'X.509 Certificate - Attribute',
	'11' => 'Raw RSA Key',
	'12' => 'Hash and URL of X.509 certificate',
	'13' => 'Hash and URL of X.509 bundle',
);

# IKEv2 Configuration Types
# RFC4306 1.15
my %configurationTypes = (
	'RESERVED'	=> 0,
	'0'		=> 'RESERVED',
	'CFG_REQUEST'	=> 1,
	'1'		=> 'CFG_REQUEST',
	'CFG_REPLY'	=> 2,
	'2'		=> 'CFG_REPLY',
	'CFG_SET'	=> 3,
	'3'		=> 'CFG_SET',
	'CFG_ACK'	=> 4,
	'4'		=> 'CFG_ACK',
);

# IKEv2 Configuration Attriute Types
# RFC4306 3.15.1
my %configurationAttibuteTypes = (
	'RESERVED'			=> 0,
	'0'				=> 'RESERVED',
	'INTERNAL_IP4_ADDRESS'		=> 1,
	'1'				=> 'INTERNAL_IP4_ADDRESS',
	'INTERNAL_IP4_NETMASK'		=> 2,
	'2'				=> 'INTERNAL_IP4_NETMASK',
	'INTERNAL_IP4_DNS'		=> 3,
	'3'				=> 'INTERNAL_IP4_DNS',
	'INTERNAL_IP4_NBNS'		=> 4,
	'4'				=> 'INTERNAL_IP4_NBNS',
	'INTERNAL_ADDRESS_EXPIRY'	=> 5,
	'5'				=> 'INTERNAL_ADDRESS_EXPIRY',
	'INTERNAL_IP4_DHCP'		=> 6,
	'6'				=> 'INTERNAL_IP4_DHCP',
	'APPLICATION_VERSION'		=> 7,
	'7'				=> 'APPLICATION_VERSION',
	'INTERNAL_IP6_ADDRESS'		=> 8,
	'8'				=> 'INTERNAL_IP6_ADDRESS',
	'RESERVED'			=> 9,
	'9'				=> 'RESERVED',
	'INTERNAL_IP6_DNS'		=> 10,
	'10'				=> 'INTERNAL_IP6_DNS',
	'INTERNAL_IP6_NBNS'		=> 11,
	'11'				=> 'INTERNAL_IP6_NBNS',
	'INTERNAL_IP6_DHCP'		=> 12,
	'12'				=> 'INTERNAL_IP6_DHCP',
	'INTERNAL_IP4_SUBNET'		=> 13,
	'13'				=> 'INTERNAL_IP4_SUBNET',
	'SUPPORTED_ATRIBUTES'		=> 14,
	'14'				=> 'SUPPORTED_ATRIBUTES',
	'INTERNAL_IP6_SUBNET'		=> 15,
	'15'				=> 'INTERNAL_IP6_SUBNET',
);

my %ipProtocolIDs = (
	'any'		=> '0',
	'0'		=> 'any',
	'icmp'		=> '1',
	'1'		=> 'icmp',
	'tcp'		=> '6',
	'6'		=> 'tcp',
	'udp'		=> '17',
	'17'		=> 'udp',
	'ipv6-icmp'	=> '58',
	'58'		=> 'ipv6-icmp',
);

#####################
# Constants getters #
#####################

=pod

=head2 kExchangeType()

This sub has a unique parameter called C<type>. This parameter takes the name
of an IKEv2 Exchange Type as defined by RFC4306 section 3.1. It can also takes the value
corresponding to this name.

If C<type> is a string containing the name, the sub returns the corresponding
value. If it is the value, it returns the name.

If C<type> isn't recognized, the sub returns C<type>.

=cut

sub kExchangeType($) {
	my $type = shift;
	$exchangeTypes{$type} or $type;
}

=pod

=head2 kPayloadType()

This sub has a unique parameter called C<type>. This parameter takes the name
of an IKEv2 Payload Type as defined by RFC4306 section 3.2. It can also takes the value
corresponding to this name.

If C<type> is a string containing the name, the sub returns the corresponding
value. If it is the value, it returns the name.

If C<type> isn't recognized, the sub returns C<type>.

=cut

sub kPayloadType($) {
	my $type = shift;
	$payloadTypes{$type} or $type;
}

=pod

=head2 kProtocolID()

This sub has a unique parameter called C<id>. This parameter takes the name
of an IKEv2 Protocol ID as defined by RFC4306 3.3.1 for Security Association proposals. 
It can also takes the value corresponding to this name.

If C<id> is a string containing the name, the sub returns the corresponding
value. If it is the value, it returns the name.

If C<id> isn't recognized, the sub returns C<id>.

=cut

sub kProtocolID($) {
	my $id = shift;
	$protocolIDs{$id} or $id;
}

=pod

=head2 kTransformType()

This sub has a unique parameter called C<type>. This parameter takes the name
of an IKEv2 Transform Type as defined by RFC4306 for Security Association transforms. 
It can also takes the value corresponding to this name.

If C<type> is a string containing the name, the sub returns the corresponding
value. If it is the value, it returns the name.

If C<type> isn't recognized, the sub returns C<type>.

=cut

sub kTransformType($) {
	my $type = shift;
	$transformTypes{$type} or $type;
}

=pod

=head2 kTransformTypeID()

This sub has two parameters called C<type> and C<id>. The first parameter takes
the name or value of an IKEv2 Transform Type as defined by RFC4306 for Security
Association transforms. The second parameter takes the name of an IKEv2 Transform
ID in the space of the specified Transform Type. The name is without the Transform
Type prefix (i.e. ENCR_DES from Type 1 ENCR becomes DES). This parameter can
also take the corresponding value.

If C<id> is a string containing the name, the sub returns the corresponding
value. If it is the value, it returns the name.

If C<type> isn't recognized as a name or a value, the sub returns C<id>.
If C<id> isn't recognized, the sub returns C<id>.

=cut

sub kTransformTypeID($$) {
	my $type = shift;
	my $id = shift;
	my $IDs = $transformTypesIDs{$type} or $transformTypesIDs{$transformTypes{$type}} or undef;
	$IDs->{$id};
}

=pod

=head2 kDHPrime()

This sub has a unique parameter called C<dh>. This parameter takes the number
of an Diffie-Hellman Group as defined by IANA.

This sub returns the prime number of the specified group in a hex string beginning
with C<'0x'>;

If C<dh> isn't recognized, the sub returns undef.

=cut

sub kDHPrime($) {
	my $dh = shift;
	$dhPrimes{$dh} or undef;
}

=pod

=head2 kDHGenerator()

This sub has a unique parameter called C<dh>. This parameter takes the number
of an Diffie-Hellman Group as defined by IANA.

This sub returns the generator of the specified group as a normal integer;

If C<dh> isn't recognized, the sub returns undef.

=cut

sub kDHGenerator($) {
	my $dh = shift;
	$dhGenerator{$dh} or undef;
}

=pod

=head2 kNotifyType()

This sub has a unique parameter called C<type>. This parameter takes the name of
an IKE Notify Message Type as defined by RFC4306 for Notify Payload. It can also
take the value corresponding to this name.

If C<type> is a string containing the name, the sub returns the corresponding
value. If it is the value, it returns the name.

If C<type> isn't recognized, the sub returns C<type>.

=cut

sub kNotifyType($) {
	my $type = shift;
	$notificationTypes{$type} or $type;
}

=pod

=head2 kCompressionType()

This sub has a unique parameter called C<type>. This parameter takes the name of
an IKE Notify Message Type as defined by RFC4306 for Notify Payload in
IPCOMP_SUPPORTED status message. It can also take the value corresponding to
this name.

If C<type> is a string containing the name, the sub returns the corresponding
value. If it is the value, it returns the name.

If C<type> isn't recognized, the sub returns C<type>.

=cut

sub kCompressionType($) {
	my $type = shift;
	$compressionTypes{$type} or $type;
}

=pod

=head2 kAttributeType()

This sub has a unique parameter called C<type>. This parameter takes the name
of an IKEv2 Attribute Type as defined by RFC4306 for Security Association
attributes. It can also takes the value corresponding to this name.

If C<type> is a string containing the name, the sub returns the corresponding
value. If it is the value, it returns the name.

If C<type> isn't recognized, the sub returns C<type>.

=cut

sub kAttributeType($) {
	my $type = shift;
	$attributeTypes{$type} or $type;
}

=pod

=head2 kKeySize()

This sub has a unique parameter called C<algorithm>. This parameter takes the name
of a cryptographic algorithm.

This subs returns the key length associated to the algorithm or the acceptable
key lengths for the algorithm as a reference to an array of integers. If the
algorithm isn't recognized, it returns 0;

=cut

sub kDHPublicValueLength($) {
	my $group = shift;
	$dhPublicValueLength{$group} or 0;
}

sub kKeySize($) {
	my $algorithm = shift;
	$keySizes{$algorithm} or 0;
}

=pod

=head2 kBlockSize()

This sub has a unique parameter called C<algorithm>. This parameter takes the name
of a cryptographic algorithm.

This subs returns the block length associated to the algorithm. If the
algorithm isn't recognized, it returns 0;

=cut

sub kBlockSize($) {
	my $algorithm = shift;
	$blockSizes{$algorithm} or 0;
}

=pod

=head2 kIdentificationType()

This sub has a unique parameter called C<type>. This parameter takes the name
of an IKEv2 Identification Type as defined by RFC4306. It can also takes the
value corresponding to this name. The name is without the 'ID_' prefix.

If C<type> is a string containing the name, the sub returns the corresponding
value. If it is the value, it returns the name.

If C<type> isn't recognized, the sub returns C<type>.

=cut

sub kIdentificationType($) {
	my $type = shift;
	$identificationTypes{$type} or $type;
}

=pod

=head2 kTrafficSelectorType()

This sub has a unique parameter called C<type>. This parameter takes the name
of an IKEv2 Traffic Selector Type as defined by RFC4306. It can also takes the
value corresponding to this name. The name is without the 'TS_' prefix.

If C<type> is a string containing the name, the sub returns the corresponding
value. If it is the value, it returns the name.

If C<type> isn't recognized, the sub returns C<type>.

=cut

sub kTrafficSelectorType($) {
	my $type = shift;
	$trafficSelectorTypes{$type} or $type;
}

=pod

=head2 kAuthenticationMethod()

This sub has a unique parameter called C<method>. This parameter takes the name
of an IKEv2 Authentication method as defined by RFC4306. It can also takes the
value corresponding to this name. The name exists in full text, in initial letters
only with an underscore between some parts, and in some short form. The returned
name is the initial form.

If C<method> is a string containing the name, the sub returns the corresponding
value. If it is the value, it returns the name.

If C<method> isn't recognized, the sub returns C<method>.

=cut

sub kAuthenticationMethod($) {
	my $method = shift;
	$authenticationMethods{$method} or $method;
}


sub kCertificateEncoding($) {
	my $cert_encoding = shift;
	$certificateEncodings{$cert_encoding} or $cert_encoding;
}


sub kConfigurationType($) {
	my $type = shift;
	$configurationTypes{$type} or $type;

}


sub kConfAttributeType($) {
	my $type = shift;
	$configurationAttibuteTypes{$type} or $type;
}


sub kIPProtocolID($) {
	my $id = shift;
	$ipProtocolIDs{$id} or $id;
}


###########################
# Constants documentation #
###########################

=pod

=head1 CONSTANTS VALUES

Here are all the defined constants value that are found in RFCs. If one constant
have multiple names for one value, the name that is given by reverse search is
marked as 'Main' between brackets.

=head2 IKEv2 Exchange types

References: RFC4306 3.1

=over

=item *

IKE_SA_INIT = 34

=item *

IKE_AUTH = 35

=item *

CREATE_CHILD_SA = 36

=item *

INFORMATIONAL = 37

=back

=head2 IKEv2 Payload types

References: RFC4306 3.2

=over

=item *

SA = 33

=item *

KE = 34

=item *

IDi = 35

=item *

IDr = 36

=item *

CERT = 37

=item *

CERTREQ = 38

=item *

AUTH = 39

=item *

Nr = 40

Ni = 40

Ni, Nr = 40 (Main)

=item *

N = 41

=item *

D = 42

=item *

V = 43

=item *

TSi = 44

=item *

TSr = 45

=item *

E = 46

=item *

CP = 47

=item *

EAP = 48

=back

=head2 IKEv2 Protocol IDs

References: RFC4306 3.3.1

=over

=item *

IKE = 1

=item *

AH = 2

=item *

ESP = 3

=back

=head2 IKEv2 Transform types

References: RFC4306 3.3.2

=over

=item *

ENCR = 1

=item *

PRF = 2

=item *

INTEG = 3

=item *

D-H = 4

=item *

ESN = 5

=back

=head2 IKEv2 Transform IDs, ENCR

References: RFC4306 3.3.2

=over

=item *

3DES = 3

=item *

NULL = 11

=item *

AES_CBC = 12

=item *

AES_CTR = 13

=back

=head2 IKEv2 Transform IDs, PRF

References: RFC4306 3.3.2

=over

=item *

HMAC_SHA1 = 2

=item *

AES128_XCBC = 4

=back

=head2 IKEv2 Transform IDs, INTEG

References: RFC4306 3.3.2

=over

=item *

HMAC_SHA1_96 = 2

=item *

AES_XCBC_96 = 5

=back

=head2 IKEv2 Transform IDs, D-H

References: RFC4306 3.3.2

=over

=item *

1024 MODP Group = 2

=item *

2048 MODP Group = 14

=back

=head2 IKEv2 Transform IDs, ESN

References: RFC4306 3.3.2

=over

=item *

No ESN = 0

=item *

ESN = 1

=back

=head2 Diffie-Hellman groups prime (hex)

References: RFC4306 Appendix B; RFC3526

=over

=item *

2 = 0xffffffffffffffffc90fdaa22168c234c4c6628b80dc1cd129024e088a67cc74020bbea63b139b22514a08798e3404ddef9519b3cd3a431b302b0a6df25f14374fe1356d6d51c245e485b576625e7ec6f44c42e9a637ed6b0bff5cb6f406b7edee386bfb5a899fa5ae9f24117c4b1fe649286651ece65381ffffffffffffffff

=item *

14 = 0xFFFFFFFFFFFFFFFFC90FDAA22168C234C4C6628B80DC1CD129024E088A67CC74020BBEA63B139B22514A08798E3404DDEF9519B3CD3A431B302B0A6DF25F14374FE1356D6D51C245E485B576625E7EC6F44C42E9A637ED6B0BFF5CB6F406B7EDEE386BFB5A899FA5AE9F24117C4B1FE649286651ECE45B3DC2007CB8A163BF0598DA48361C55D39A69163FA8FD24CF5F83655D23DCA3AD961C62F356208552BB9ED529077096966D670C354E4ABC9804F1746C08CA18217C32905E462E36CE3BE39E772C180E86039B2783A2EC07A28FB5C55DF06F4C52C9DE2BCBF6955817183995497CEA956AE515D2261898FA051015728E5A8AACAA68FFFFFFFFFFFFFFFF

=back

=head2 Diffie-Hellman groups generator

References: RFC4306 Appendix B; RFC3526

=over

=item *

2 = 2

=item *

14 = 2

=back

=head2 IKEv2 Notification Types

References: RFC4306 3.10.1

=over

=item *

UNSUPPORTED_CRITICAL_PAYLOAD = 1

=item *

INVALID_IKE_SPI = 4

=item *

INVALID_MAJOR_VERSION = 5

=item *

INVALID_SYNTAX = 7

=item *

INVALID_MESSAGE_ID = 9

=item *

INVALID_SPI = 11

=item *

NO_PROPOSAL_CHOSEN = 14

=item *

INVALID_KE_PAYLOAD = 17

=item *

AUTHENTICATION_FAILED = 24

=item *

SINGLE_PAIR_REQUIRED = 34

=item *

NO_ADDITIONAL_SAS = 35

=item *

INTERNAL_ADDRESS_FAILURE = 36

=item *

FAILED_CP_REQUIRED = 37

=item *

TS_UNACCEPTABLE = 38

=item *

INVALID_SELECTORS = 39

=item *

INITIAL_CONTACT = 16384

=item *

SET_WINDOW_SIZE = 16385

=item *

ADDITIONAL_TS_POSSIBLE = 16386

=item *

IPCOMP_SUPPORTED = 16387

=item *

NAT_DETECTION_SOURCE_IP = 16388

=item *

NAT_DETECTION_DESTINATION_IP = 16389

=item *

COOKIE = 16390

=item *

USE_TRANSPORT_MODE = 16391

=item *

HTTP_CERT_LOOKUP_SUPPORTED = 16392

=item *

REKEY_SA = 16393

=item *

ESP_TFC_PADDING_NOT_SUPPORTED = 16394

=item *

NON_FIRST_FRAGMENTS_ALSO = 16395

=back

=head2 IKEv2 Compression types

References: RFC4306 3.10.1 under IPCOMP_SUPPORTED status notification type.

=over

=item *

OUI = 1

=item *

DEFLATE = 2

=item *

LZS = 3

=item *

LZJH = 4

=back

=head2 IKEv2 Attributes Types

References: RFC4306 3.3.5

=over

=item *

Key Length = 14

=back

=head2 IKEv2 Identification Types

References: RFC4306 3.5

=over

=item *

IPV4_ADDR = 1

=item *

FQDN = 2

=item *

RFC822_ADDR = 3

=item *

IPV6_ADDR = 5

=item *

DER_ASN1_DN = 9

=item *

DER_ASN1_GN = 10

=item *

KEY_ID = 11

=back

=head2 IKEv2 Traffic Selector Types

References: RFC4306 3.13.1

=over

=item *

IPV4_ADDR_RANGE = 7

=item *

IPV6_ADDR_RANGE = 8

=back

=head2 IKEv2 Authentication methods

References: RFC4306 3.8

=over

=item *

RSA = 1

RSA_DS = 1 (Main)

RSA Digital Signature = 1

=item *

SK = 2

SK_MIC = 2 (Main)

Shared Key Message Integrity Code = 2

=item *

DSS = 3

DSS_DS = 3 (Main)

DSS Digital Signature = 3

=back

=head1 SEE ALSO

Use RFC4306 as reference to understand the meaning of the defined values.

See RFC3526 to get information about Diffie-Hellman groups.

See documentation about algorithms for the key and block sizes for cryptographic algorithms.

=head1 AUTHOR

Pierrick Caillon, <pierrick@64translator.com>, from tahi project.

=cut

1;
