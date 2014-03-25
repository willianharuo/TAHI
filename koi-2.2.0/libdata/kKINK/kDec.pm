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
# $TAHI: devel-kink/koi/libdata/kKINK/kDec.pm,v 1.9 2009/07/28 04:47:29 doo Exp $
#
# $Id: kDec.pm,v 1.2 2010/07/22 13:23:57 velo Exp $
#
########################################################################

package kKINK::kDec;

use strict;
use warnings;
use Exporter;
use kKINK::kConsts;
use kKINK::ISAKMP;

our @ISA = qw(Exporter);
our @EXPORT = qw(
	kDecKINKPacket
	kDecKINK_ENCRYPT_Payload
);

our $TRUE = $kKINK::kConsts::TRUE;
our $FALSE = $kKINK::kConsts::FALSE;

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

my %decode_functions = (
	'1'	=> \&kDecKINK_AP_REQ_Payload,
	'KINK_AP_REQ'	=> \&kDecKINK_AP_REQ_Payload,
	'2'	=> \&kDecKINK_AP_REP_Payload,
	'KINK_AP_REP'	=> \&kDecKINK_AP_REP_Payload,
	'3'	=> \&kDecKINK_KRB_ERROR_Payload,
	'KINK_KRB_ERROR'	=> \&kDecKINK_KRB_ERROR_Payload,
	'4'	=> \&kDecKINK_TGT_REQ_Payload,
	'KINK_TGT_REQ'	=> \&kDecKINK_TGT_REQ_Payload,
	'5'	=> \&kDecKINK_TGT_REP_Payload,
	'KINK_TGT_REP'	=> \&kDecKINK_TGT_REP_Payload,
	'6'	=> \&kDecKINK_ISAKMP_Payload,
	'KINK_ISAKMP'	=> \&kDecKINK_ISAKMP_Payload,
	'7'	=> \&kDecKINK_ENCRYPT_Payload,
	'KINK_ENCRYPT'	=> \&kDecKINK_ENCRYPT_Payload,
	'8'	=> \&kDecKINK_ERROR_Payload,
	'KINK_ERROR'	=> \&kDecKINK_ERROR_Payload,
);

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


#----------------------------------------------------------------------#
# subroutine prototypes                                                #
#----------------------------------------------------------------------#

sub kDecKINKHeader($);



#----------------------------------------------------------------------#
# subroutine implementation                                            #
#----------------------------------------------------------------------#

=pod

=head2 kDecKINKHeader()

Parses an KINK Header and provide data for the next parser.

=head3 Parameters

=head3 Return value

=cut

sub kDecKINKPacket($)
{
	my ($data) = @_;

	my $header = kDecKINKHeader($data);
	my $remain = $header->{'_remain'};

	for (my $next_payload = $header->{'NextPayload'}; $next_payload != 0; ) {
		my $decode = $decode_functions{$next_payload};
		unless (defined($decode)) {
			printf("dbg: %s: %s: kDecKINKPacket: unknown NextPayload(%s)\n",
			       __FILE__, __LINE__, $next_payload);
			exit(1);
			# NOTREACHED
		}
		my $payload = &{$decode}($remain);
		push(@{$header->{'payloads'}}, $payload);

		$next_payload = $payload->{'NextPayload'};
		$remain = $payload->{'_remain'};
	}

	return($header);
}

=pod

=head2 kDecKINKHeader()

Parses an KINK Header and provide data for the next parser.

=head3 Parameters

=head3 Return value

=cut

sub kDecKINKHeader($)
{
	my ($data) = @_;

	my $self = substr($data, 0, 16);

	my ($type, $version, $length, $doi, $xid, $next_payload, $reserved2, $cksumlen) =
		unpack('C C n N N C C n ', $self);

	my $remain = substr($data, 16, $length - 16);
	my $garbage = substr($data, $length);
	if (length($garbage)) {
		$garbage = unpack('H*', $garbage);
	}

	my $reserved = $version & 0x0f;
	$version = $version >> 4;
	my $ackreq = $reserved2 >> 7;
	$reserved2 = $reserved2 & 0x7f;
	my $cksum = '';
	if ($cksumlen) {
		$cksum = unpack('H*', substr($remain, -$cksumlen));
		$remain = substr($remain, 0, -$cksumlen);
	}

	my $result = {
		'_name'		=> 'KINK Header',
		'_self'		=> $self,
		'_remain'	=> $remain,

		'Type'	=> $type,
		'MjVer'	=> $version,
		'RESERVED'	=> $reserved,
		'Length'	=> $length,
		'DOI'	=> $doi,
		'XID'	=> $xid,
		'NextPayload'	=> $next_payload,
		'ACKREQ'	=> $ackreq,
		'RESERVED2'	=> $reserved2,
		'CksumLen'	=> $cksumlen,
		'payloads'	=> [],
		'Cksum'	=> $cksum,
		'garbage'	=> $garbage,
	};

	return($result);
}

=pod

=head2 kDecKINK_AP_REQ_Payload()

Parses an KINK Header and provide data for the next parser.

=head3 Parameters

=head3 Return value

=cut

sub align($$)
{
	my ($length, $align) = @_;
	return( ($length + ($align - 1)) & ~($align - 1) );
};


sub kDecKINK_AP_REQ_Payload($)
{
	my ($data) = @_;

	my ($next_payload, $reserved, $payload_length, $epoch) =
		unpack('C C n N', $data);

	my $self = substr($data, 0, $payload_length);
	my $pad_length = align($payload_length, 4) - $payload_length;
	my $pad = substr($data, $payload_length, $pad_length);
	my $remain = substr($data, $payload_length + $pad_length);

	my $ap_req = substr($self, 8, $payload_length - 8);
#	my $ap_req_dec = kDecKerberos_AP_REQ($ap_req);

	my $result = {
		'_name'		=> 'KINK_AP_REQ Payload',
		'_self'		=> $self,
		'_pad'		=> $pad,
		'_pad_length'	=> $pad_length,
		'_remain'	=> $remain,

		'NextPayload'	=> $next_payload,
		'RESERVED'	=> $reserved,
		'Payload Length'	=> $payload_length,
		'EPOCH'		=> $epoch,
		'AP-REQ'	=> $ap_req, # AP-REQ binary data
#		'AP-REQ_dec'	=> $ap_req_dec, # decoded AP-REQ data
	};

	return($result);
}

sub is_context($) { return( ($_[0] & 0x80) && !($_[0] & 0x40) ); }

sub kDec_ASN1_Type($$)
{
	my ($data, $offset) = @_;
	my $type = unpack("\@$offset C", $data);
	$offset += 1;
	return($type, $offset);
}
sub kDec_ASN1_Length($$)
{
	my ($data, $offset) = @_;
	my $length = unpack("\@$offset C", $data);
	$offset += 1;
	if ($length & 0x80) {
		my $length_len = $length & 0x7f;
		my @length = unpack("\@$offset C$length_len", $data);
		$offset += $length_len;
		$length = 0;
		foreach my $elm (@length) {
			$length = ($length << 8) + $elm;
		}
	}
	return($length, $offset);
}
sub kDec_ASN1_Value($$$)
{
	my ($data, $offset, $length) = @_;
	my $value = substr($data, $offset, $length);
	$offset += $length;
	return($value, $offset);
}

sub kDec_ASN1_TLV($);
sub kDec_ASN1_TLV($)
{
	my ($data) = @_;

	my $type = undef;
	my $length = undef;
	my $value = undef;
	my $offset = 0;

	($type, $offset) = kDec_ASN1_Type($data, $offset);
	($length, $offset) = kDec_ASN1_Length($data, $offset);
	($value, $offset) = kDec_ASN1_Value($data, $offset, $length);

	if (0) {
		printf("dbg:%s:%s T(%s)  L(%s) V(%s)\n", __FILE__, __LINE__, $type, $length, $value);
	}

	my $_self = substr($data, 0, $offset);
	my $_remain = substr($data, $offset);
	my $result = {
		'_name'		=> (is_context($type)) ? 'CONTEXT' : 'TLV',
		'_type'		=> (is_context($type)) ? 'CONTEXT' : 'TLV',
		'_self'		=> $_self,
		'_remain'	=> $_remain,
		'_index'	=> (is_context($type)) ? $type & 0x1f : undef,
		'Type'		=> $type,
		'Length'	=> $length,
		'Value'		=> $value,
	};
	return($result);
}

use constant {
	'SEQUENCE'	=> 0x10,
	'DEBUG'	=> 0,
};

sub kDecKerberos_AP_REQ($)
{
	my ($data) = @_;

	my $offset = 0;

	# AP-REQ          ::= [APPLICATION 14] SEQUENCE {
	#         pvno            [0] INTEGER (5),
	#         msg-type        [1] INTEGER (14),
	#         ap-options      [2] APOptions,
	#         ticket          [3] Ticket,
	#         authenticator   [4] EncryptedData -- Authenticator
	# }
	my $result = kDec_ASN1_TLV($data);
	$result->{'_name'} = 'AP-REQ';
	$result->{'_type'} = 'AP-REQ';
	if (DEBUG) {
		my $h = $result;
		printf("%s\n", $h->{'_name'});
		printf("\tType(%s, 0x%02x, 0b%08b) Length(%s, 0x%02x)\n",
		       $h->{'Type'}, $h->{'Type'}, $h->{'Type'}, $h->{'Length'}, $h->{'Length'});
		#printf("\tvalue(%s)\n", unpack('H*', $result->{'Value'}));
	}

	# SEQUENCE
	my $seq = kDec_ASN1_TLV($result->{'Value'});
	$seq->{'_name'} = 'SEQUENCE';
	$seq->{'_type'} = 'SEQUENCE';
	$result->{'Value'} = $seq;
	my $seq_data = $seq->{'Value'};
	my $seq_datalen = length($seq_data);
	my $seq_value = [];
	for (my $seq_offset = 0 ; $seq_offset < $seq_datalen; ) {
		my $seq_elm = kDec_ASN1_TLV(substr($seq_data, $seq_offset));
		$seq_offset += length($seq_elm->{'_self'});

		if (defined($seq_elm->{'_index'}) && $seq_elm->{'_index'} == 0) {
			#         pvno            [0] INTEGER (5),
			my $tmp = kDec_ASN1_TLV($seq_elm->{'Value'});
			$tmp->{'_name'} = 'pvno';
			$tmp->{'_type'} = 'INTEGER';
			$tmp->{'Value'} = unpack('H*', $tmp->{'Value'});
			$seq_elm->{'Value'} = $tmp;
		}
		elsif (defined($seq_elm->{'_index'}) && $seq_elm->{'_index'} == 1) {
			#         msg-type        [1] INTEGER (14),
			my $tmp = kDec_ASN1_TLV($seq_elm->{'Value'});
			$tmp->{'_name'} = 'msg-type';
			$tmp->{'_type'} = 'INTEGER';
			$tmp->{'Value'} = unpack('H*', $tmp->{'Value'});
			$seq_elm->{'Value'} = $tmp;
		}
		elsif (defined($seq_elm->{'_index'}) && $seq_elm->{'_index'} == 2) {
			#         ap-options      [2] APOptions,
			my $tmp = kDec_ASN1_TLV($seq_elm->{'Value'});
			$tmp->{'_name'} = 'ap-options';
			$tmp->{'_type'} = 'APOptions';
			$tmp->{'Value'} = unpack('H*', $tmp->{'Value'});
			$seq_elm->{'Value'} = $tmp;
		}
		elsif (defined($seq_elm->{'_index'}) && $seq_elm->{'_index'} == 3) {
			#         ticket          [3] Ticket,
			#my $tmp = kDec_ASN1_TLV($seq_elm->{'Value'});
			my $tmp = kDecKerberos_Ticket($seq_elm->{'Value'});
			$tmp->{'_name'} = 'ticket';
			$seq_elm->{'Value'} = $tmp;
		}
		elsif (defined($seq_elm->{'_index'}) && $seq_elm->{'_index'} == 4) {
			#         authenticator   [4] EncryptedData -- Authenticator
			#my $tmp = kDec_ASN1_TLV($seq_elm->{'Value'});
			my $tmp = kDecKerberos_EncryptedData($seq_elm->{'Value'});
			$tmp->{'_name'} = 'authenticator';
			$seq_elm->{'Value'} = $tmp;

			foreach my $elm (@{$tmp->{'Value'}}) {
				printf("\t%s, %s\n", $elm->{'Value'}->{'_name'}, $elm->{'Value'}->{'_type'});
			}

			my $decrypted = undef;
			# XXX
			# process crypto
			if (1) {
				# decrypt
				if (0) { #5.1
					use Crypt::Random qw( makerandom makerandom_octet );
					use Crypt::CBC;

					my $max_arg = @{$tmp->{'Value'}} - 1;
					my $auth_cipher = $tmp->{'Value'}->[$max_arg]->{'Value'};
					printf("AUTH CIPHER\n");
					printf("\t%s, %s\n", $auth_cipher->{'_name'}, $auth_cipher->{'Value'});

					my $K = "989d548fa464f8f1d923767aa1feb0d319200779b65bc2c7";
					$K = pack('H*', $K);
					my $S = $auth_cipher->{'Value'};
					$S = pack('H*', $S);
					my $IV = '0000000000000000';
					$IV = pack('H*', $IV);
					printf("K(%s) S(%s) IV(%s)\n", length($K), length($S), length($IV));
					my $padlen = align(length($S), 8) - length($S);
					printf("PADLEN (%s)\n", $padlen);
					for (my $i=0; $i < $padlen; $i++) { $S .= pack('H*', '00'); }
					printf("K(%s) S(%s) IV(%s)\n", length($K), length($S), length($IV));
					my $decrSub = sub {
						my ($K, $S, $IV) = @_;
						my $remainPad = 0;
						my $tripleDES = undef;
						$tripleDES = Crypt::CBC->new(
							-key => $K,
							-cipher => 'DES_EDE3',
							-header => 'none',
							-iv => $IV,
							-literal_key => 1,
							#-padding => sub { return(cbcPadding($_[0], $_[1], $_[2], \$remainPad)); },
						);
						my $ret = $tripleDES->decrypt($S);
						$ret = ($remainPad) ? substr($ret, 0, -$remainPad) : $ret;
					};

					$decrypted = &{$decrSub}($K, $S, $IV);
					printf("DECRYPT\n");
					printf("\t%s %s\n",
					       ref($decrypted) ? ref($decrypted) : 'PRM', unpack('H*', $decrypted));
					printf("\n");
				}
				if (0) { #5.2
					use Crypt::Random qw( makerandom makerandom_octet );
					use Crypt::CBC;

					my $max_arg = @{$tmp->{'Value'}} - 1;
					my $auth_cipher = $tmp->{'Value'}->[$max_arg]->{'Value'};
					printf("AUTH CIPHER\n");
					printf("\t%s, %s\n", $auth_cipher->{'_name'}, $auth_cipher->{'Value'});

					my $K = '5e2c8acb08d3a7b96d37cdad263e7cb552d90e7652803701'; #1
					$K = pack('H*', $K);
					my $S = $auth_cipher->{'Value'};
					$S = pack('H*', $S);
					my $IV = '0000000000000000';
					$IV = pack('H*', $IV);
					printf("K(%s) S(%s) IV(%s)\n", length($K), length($S), length($IV));
					my $padlen = align(length($S), 8) - length($S);
					printf("PADLEN (%s)\n", $padlen);
					for (my $i=0; $i < $padlen; $i++) { $S .= pack('H*', '00'); }
					printf("K(%s) S(%s) IV(%s)\n", length($K), length($S), length($IV));
					my $decrSub = sub {
						my ($K, $S, $IV) = @_;
						my $remainPad = 0;
						my $tripleDES = undef;
						$tripleDES = Crypt::CBC->new(
							-key => $K,
							-cipher => 'DES_EDE3',
							-header => 'none',
							-iv => $IV,
							-literal_key => 1,
							#-padding => sub { return(cbcPadding($_[0], $_[1], $_[2], \$remainPad)); },
						);
						my $ret = $tripleDES->decrypt($S);
						$ret = ($remainPad) ? substr($ret, 0, -$remainPad) : $ret;
					};

					$decrypted = &{$decrSub}($K, $S, $IV);
					printf("DECRYPT\n");
					printf("\t%s %s\n",
					       ref($decrypted) ? ref($decrypted) : 'PRM', unpack('H*', $decrypted));
					printf("\n");
				}
				if (0) { #5.3
					use Crypt::Random qw( makerandom makerandom_octet );
					use Crypt::CBC;

					my $max_arg = @{$tmp->{'Value'}} - 1;
					my $auth_cipher = $tmp->{'Value'}->[$max_arg]->{'Value'};
					printf("AUTH CIPHER\n");
					printf("\t%s, %s\n", $auth_cipher->{'_name'}, $auth_cipher->{'Value'});

					my $K = '68f8a7023b4c3449169e3749ad0d8a85014cd6bf3746ea54'; #2
					$K = pack('H*', $K);
					my $S = $auth_cipher->{'Value'};
					$S = pack('H*', $S);
					my $IV = '0000000000000000';
					$IV = pack('H*', $IV);
					printf("K(%s) S(%s) IV(%s)\n", length($K), length($S), length($IV));
					my $padlen = align(length($S), 8) - length($S);
					printf("PADLEN (%s)\n", $padlen);
					for (my $i=0; $i < $padlen; $i++) { $S .= pack('H*', '00'); }
					printf("K(%s) S(%s) IV(%s)\n", length($K), length($S), length($IV));
					my $decrSub = sub {
						my ($K, $S, $IV) = @_;
						my $remainPad = 0;
						my $tripleDES = undef;
						$tripleDES = Crypt::CBC->new(
							-key => $K,
							-cipher => 'DES_EDE3',
							-header => 'none',
							-iv => $IV,
							-literal_key => 1,
							#-padding => sub { return(cbcPadding($_[0], $_[1], $_[2], \$remainPad)); },
						);
						my $ret = $tripleDES->decrypt($S);
						$ret = ($remainPad) ? substr($ret, 0, -$remainPad) : $ret;
					};

					$decrypted = &{$decrSub}($K, $S, $IV);
					printf("DECRYPT\n");
					printf("\t%s %s\n",
					       ref($decrypted) ? ref($decrypted) : 'PRM', unpack('H*', $decrypted));
					printf("\n");
				}
				if (0) { #5.4
					use Crypt::Random qw( makerandom makerandom_octet );
					use Crypt::CBC;

					my $max_arg = @{$tmp->{'Value'}} - 1;
					my $auth_cipher = $tmp->{'Value'}->[$max_arg]->{'Value'};
					printf("AUTH CIPHER\n");
					printf("\t%s, %s\n", $auth_cipher->{'_name'}, $auth_cipher->{'Value'});

					my $K = '233825ba7a4a02ad8545bf92341a982ca1235e1fea380bc2'; #3
					$K = pack('H*', $K);
					my $S = $auth_cipher->{'Value'};
					$S = pack('H*', $S);
					my $IV = '0000000000000000';
					$IV = pack('H*', $IV);
					printf("K(%s) S(%s) IV(%s)\n", length($K), length($S), length($IV));
					my $padlen = align(length($S), 8) - length($S);
					printf("PADLEN (%s)\n", $padlen);
					for (my $i=0; $i < $padlen; $i++) { $S .= pack('H*', '00'); }
					printf("K(%s) S(%s) IV(%s)\n", length($K), length($S), length($IV));
					my $decrSub = sub {
						my ($K, $S, $IV) = @_;
						my $remainPad = 0;
						my $tripleDES = undef;
						$tripleDES = Crypt::CBC->new(
							-key => $K,
							-cipher => 'DES_EDE3',
							-header => 'none',
							-iv => $IV,
							-literal_key => 1,
							#-padding => sub { return(cbcPadding($_[0], $_[1], $_[2], \$remainPad)); },
						);
						my $ret = $tripleDES->decrypt($S);
						$ret = ($remainPad) ? substr($ret, 0, -$remainPad) : $ret;
					};

					$decrypted = &{$decrSub}($K, $S, $IV);
					printf("DECRYPT\n");
					printf("\t%s %s\n",
					       ref($decrypted) ? ref($decrypted) : 'PRM', unpack('H*', $decrypted));
					printf("\n");

				}
				if (0) { #5.5
					use Crypt::Random qw( makerandom makerandom_octet );
					use Crypt::CBC;

					my $max_arg = @{$tmp->{'Value'}} - 1;
					my $auth_cipher = $tmp->{'Value'}->[$max_arg]->{'Value'};
					printf("AUTH CIPHER\n");
					printf("\t%s, %s\n", $auth_cipher->{'_name'}, $auth_cipher->{'Value'});

					my $K = '5b7f85910d83a11a5b7575f4c7d9408f5ba834a8730b1fa1'; #4
					$K = pack('H*', $K);
					my $S = $auth_cipher->{'Value'};
					$S = pack('H*', $S);
					my $IV = '0000000000000000';
					$IV = pack('H*', $IV);
					printf("K(%s) S(%s) IV(%s)\n", length($K), length($S), length($IV));
					my $padlen = align(length($S), 8) - length($S);
					printf("PADLEN (%s)\n", $padlen);
					for (my $i=0; $i < $padlen; $i++) { $S .= pack('H*', '00'); }
					printf("K(%s) S(%s) IV(%s)\n", length($K), length($S), length($IV));
					my $decrSub = sub {
						my ($K, $S, $IV) = @_;
						my $remainPad = 0;
						my $tripleDES = undef;
						$tripleDES = Crypt::CBC->new(
							-key => $K,
							-cipher => 'DES_EDE3',
							-header => 'none',
							-iv => $IV,
							-literal_key => 1,
							#-padding => sub { return(cbcPadding($_[0], $_[1], $_[2], \$remainPad)); },
						);
						my $ret = $tripleDES->decrypt($S);
						$ret = ($remainPad) ? substr($ret, 0, -$remainPad) : $ret;
					};

					$decrypted = &{$decrSub}($K, $S, $IV);
					printf("DECRYPT\n");
					printf("\t%s %s\n",
					       ref($decrypted) ? ref($decrypted) : 'PRM', unpack('H*', $decrypted));
					printf("\n");

				}
				if (0) { #5.6
					use Crypt::Random qw( makerandom makerandom_octet );
					use Crypt::CBC;

					my $max_arg = @{$tmp->{'Value'}} - 1;
					my $auth_cipher = $tmp->{'Value'}->[$max_arg]->{'Value'};
					printf("AUTH CIPHER\n");
					printf("\t%s, %s\n", $auth_cipher->{'_name'}, $auth_cipher->{'Value'});

					my $K = 'a8fec15b3e49c87052cd1ce646d54a4fec8a64156d70916d';
					$K = pack('H*', $K);
					my $S = $auth_cipher->{'Value'};
					$S = pack('H*', $S);
					my $IV = '0000000000000000';
					$IV = pack('H*', $IV);
					printf("K(%s) S(%s) IV(%s)\n", length($K), length($S), length($IV));
					my $padlen = align(length($S), 8) - length($S);
					printf("PADLEN (%s)\n", $padlen);
					for (my $i=0; $i < $padlen; $i++) { $S .= pack('H*', '00'); }
					printf("K(%s) S(%s) IV(%s)\n", length($K), length($S), length($IV));
					my $decrSub = sub {
						my ($K, $S, $IV) = @_;
						my $remainPad = 0;
						my $tripleDES = undef;
						$tripleDES = Crypt::CBC->new(
							-key => $K,
							-cipher => 'DES_EDE3',
							-header => 'none',
							-iv => $IV,
							-literal_key => 1,
							#-padding => sub { return(cbcPadding($_[0], $_[1], $_[2], \$remainPad)); },
						);
						my $ret = $tripleDES->decrypt($S);
						$ret = ($remainPad) ? substr($ret, 0, -$remainPad) : $ret;
					};

					$decrypted = &{$decrSub}($K, $S, $IV);
					printf("DECRYPT\n");
					printf("\t%s %s\n",
					       ref($decrypted) ? ref($decrypted) : 'PRM', unpack('H*', $decrypted));
					printf("\n");

				}
				if (0) { #5.7
					use Crypt::Random qw( makerandom makerandom_octet );
					use Crypt::CBC;

					my $max_arg = @{$tmp->{'Value'}} - 1;
					my $auth_cipher = $tmp->{'Value'}->[$max_arg]->{'Value'};
					printf("AUTH CIPHER\n");
					printf("\t%s, %s\n", $auth_cipher->{'_name'}, $auth_cipher->{'Value'});

					my $K = '0119b9f7450d34fe979b9b26131a9e588913b69d2c3deaef'; #6
					$K = pack('H*', $K);
					my $S = $auth_cipher->{'Value'};
					$S = pack('H*', $S);
					my $IV = '0000000000000000';
					$IV = pack('H*', $IV);
					printf("K(%s) S(%s) IV(%s)\n", length($K), length($S), length($IV));
					my $padlen = align(length($S), 8) - length($S);
					printf("PADLEN (%s)\n", $padlen);
					for (my $i=0; $i < $padlen; $i++) { $S .= pack('H*', '00'); }
					printf("K(%s) S(%s) IV(%s)\n", length($K), length($S), length($IV));
					my $decrSub = sub {
						my ($K, $S, $IV) = @_;
						my $remainPad = 0;
						my $tripleDES = undef;
						$tripleDES = Crypt::CBC->new(
							-key => $K,
							-cipher => 'DES_EDE3',
							-header => 'none',
							-iv => $IV,
							-literal_key => 1,
							#-padding => sub { return(cbcPadding($_[0], $_[1], $_[2], \$remainPad)); },
						);
						my $ret = $tripleDES->decrypt($S);
						$ret = ($remainPad) ? substr($ret, 0, -$remainPad) : $ret;
					};

					$decrypted = &{$decrSub}($K, $S, $IV);
					printf("DECRYPT\n");
					printf("\t%s %s\n",
					       ref($decrypted) ? ref($decrypted) : 'PRM', unpack('H*', $decrypted));
					printf("\n");

				}
				{ #5.8
					use Crypt::Random qw( makerandom makerandom_octet );
					use Crypt::CBC;

					my $max_arg = @{$tmp->{'Value'}} - 1;
					my $auth_cipher = $tmp->{'Value'}->[$max_arg]->{'Value'};
					printf("AUTH CIPHER\n");
					printf("\t%s, %s\n", $auth_cipher->{'_name'}, $auth_cipher->{'Value'});

					my $K = '3d26b0d5f8ab5816dfbf70259e31da1ca22cf154e34c1931'; #7
					$K = pack('H*', $K);
					my $S = $auth_cipher->{'Value'};
					$S = pack('H*', $S);
					my $IV = '0000000000000000';
					$IV = pack('H*', $IV);
					printf("K(%s) S(%s) IV(%s)\n", length($K), length($S), length($IV));
					my $padlen = align(length($S), 8) - length($S);
					printf("PADLEN (%s)\n", $padlen);
					for (my $i=0; $i < $padlen; $i++) { $S .= pack('H*', '00'); }
					printf("K(%s) S(%s) IV(%s)\n", length($K), length($S), length($IV));
					my $decrSub = sub {
						my ($K, $S, $IV) = @_;
						my $remainPad = 0;
						my $tripleDES = undef;
						$tripleDES = Crypt::CBC->new(
							-key => $K,
							-cipher => 'DES_EDE3',
							-header => 'none',
							-iv => $IV,
							-literal_key => 1,
							-padding => sub { return(cbcPadding($_[0], $_[1], $_[2], \$remainPad)); },
						);
						my $ret = $tripleDES->decrypt($S);
						$ret = ($remainPad) ? substr($ret, 0, -$remainPad) : $ret;
					};

					$decrypted = &{$decrSub}($K, $S, $IV);
					printf("DECRYPT\n");
					printf("\t%s %s\n",
					       ref($decrypted) ? ref($decrypted) : 'PRM', unpack('H*', $decrypted));
					printf("\n");

				}
				{ #5.8
					use Crypt::Random qw( makerandom makerandom_octet );
					use Crypt::CBC;

					my $max_arg = @{$tmp->{'Value'}} - 1;
					my $auth_cipher = $tmp->{'Value'}->[$max_arg]->{'Value'};
					printf("AUTH CIPHER\n");
					printf("\t%s, %s\n", $auth_cipher->{'_name'}, $auth_cipher->{'Value'});

					my $K = 'e5193d62e6895704ab15671080b03e1c7fa780d9f243e0d6';
					$K = pack('H*', $K);
					my $S = $auth_cipher->{'Value'};
					$S = pack('H*', $S);
					my $IV = '0000000000000000';
					$IV = pack('H*', $IV);
					printf("K(%s) S(%s) IV(%s)\n", length($K), length($S), length($IV));
					my $padlen = align(length($S), 8) - length($S);
					printf("PADLEN (%s)\n", $padlen);
					for (my $i=0; $i < $padlen; $i++) { $S .= pack('H*', '00'); }
					printf("K(%s) S(%s) IV(%s)\n", length($K), length($S), length($IV));
					my $decrSub = sub {
						my ($K, $S, $IV) = @_;
						my $remainPad = 0;
						my $tripleDES = undef;
						$tripleDES = Crypt::CBC->new(
							-key => $K,
							-cipher => 'DES_EDE3',
							-header => 'none',
							-iv => $IV,
							-literal_key => 1,
							#-padding => sub { return(cbcPadding($_[0], $_[1], $_[2], \$remainPad)); },
						);
						my $ret = $tripleDES->decrypt($S);
						$ret = ($remainPad) ? substr($ret, 0, -$remainPad) : $ret;
					};

					$decrypted = &{$decrSub}($K, $S, $IV);
					printf("DECRYPT\n");
					printf("\t%s %s\n",
					       ref($decrypted) ? ref($decrypted) : 'PRM', unpack('H*', $decrypted));
					printf("\n");

				}
				{ #5.8
					use Crypt::Random qw( makerandom makerandom_octet );
					use Crypt::CBC;

					my $max_arg = @{$tmp->{'Value'}} - 1;
					my $auth_cipher = $tmp->{'Value'}->[$max_arg]->{'Value'};
					printf("AUTH CIPHER\n");
					printf("\t%s, %s\n", $auth_cipher->{'_name'}, $auth_cipher->{'Value'});

					my $K = '3b6234f146efd085a8b3a2b3c8a815e0ea570416d3435b5e';
					$K = pack('H*', $K);
					my $S = $auth_cipher->{'Value'};
					$S = pack('H*', $S);
					my $IV = '0000000000000000';
					$IV = pack('H*', $IV);
					printf("K(%s) S(%s) IV(%s)\n", length($K), length($S), length($IV));
					my $padlen = align(length($S), 8) - length($S);
					printf("PADLEN (%s)\n", $padlen);
					for (my $i=0; $i < $padlen; $i++) { $S .= pack('H*', '00'); }
					printf("K(%s) S(%s) IV(%s)\n", length($K), length($S), length($IV));
					my $decrSub = sub {
						my ($K, $S, $IV) = @_;
						my $remainPad = 0;
						my $tripleDES = undef;
						$tripleDES = Crypt::CBC->new(
							-key => $K,
							-cipher => 'DES_EDE3',
							-header => 'none',
							-iv => $IV,
							-literal_key => 1,
							#-padding => sub { return(cbcPadding($_[0], $_[1], $_[2], \$remainPad)); },
						);
						my $ret = $tripleDES->decrypt($S);
						$ret = ($remainPad) ? substr($ret, 0, -$remainPad) : $ret;
					};

					$decrypted = &{$decrSub}($K, $S, $IV);
					printf("DECRYPT\n");
					printf("\t%s %s\n",
					       ref($decrypted) ? ref($decrypted) : 'PRM', unpack('H*', $decrypted));
					printf("\n");

				}
				{ #5.8
					use Crypt::Random qw( makerandom makerandom_octet );
					use Crypt::CBC;

					my $max_arg = @{$tmp->{'Value'}} - 1;
					my $auth_cipher = $tmp->{'Value'}->[$max_arg]->{'Value'};
					printf("AUTH CIPHER\n");
					printf("\t%s, %s\n", $auth_cipher->{'_name'}, $auth_cipher->{'Value'});

					my $K = '5e7c02b6a1d9efc1b591b6619746a88579f107c76b583115';
					$K = pack('H*', $K);
					my $S = $auth_cipher->{'Value'};
					$S = pack('H*', $S);
					my $IV = '0000000000000000';
					$IV = pack('H*', $IV);
					printf("K(%s) S(%s) IV(%s)\n", length($K), length($S), length($IV));
					my $padlen = align(length($S), 8) - length($S);
					printf("PADLEN (%s)\n", $padlen);
					for (my $i=0; $i < $padlen; $i++) { $S .= pack('H*', '00'); }
					printf("K(%s) S(%s) IV(%s)\n", length($K), length($S), length($IV));
					my $decrSub = sub {
						my ($K, $S, $IV) = @_;
						my $remainPad = 0;
						my $tripleDES = undef;
						$tripleDES = Crypt::CBC->new(
							-key => $K,
							-cipher => 'DES_EDE3',
							-header => 'none',
							-iv => $IV,
							-literal_key => 1,
							#-padding => sub { return(cbcPadding($_[0], $_[1], $_[2], \$remainPad)); },
						);
						my $ret = $tripleDES->decrypt($S);
						$ret = ($remainPad) ? substr($ret, 0, -$remainPad) : $ret;
					};

					$decrypted = &{$decrSub}($K, $S, $IV);
					printf("DECRYPT\n");
					printf("\t%s %s\n",
					       ref($decrypted) ? ref($decrypted) : 'PRM', unpack('H*', $decrypted));
					printf("\n");

				}
			}
			else {
				# return

			}

			# $decrypted = kDecKerberos_Authenticator($decrypted);
			# $decrypted->{'_name'} = 'authenticator';
			# $tmp->{'Value'}->[2]->{'Value'} = $decrypted;
		}
		else {
			# XXX error
			printf("dbg:%s:%s\n", __FILE__, __LINE__);
			exit(1);
			# NOTREACHED
		}

		push(@{$seq_value}, $seq_elm);
		if (DEBUG && $seq_elm->{'_index'} < 3) {
			my $h = $seq_elm->{'Value'};
			printf("%s\n", $h->{'_name'});
			printf("\tidx(%s) Type(%s, 0x%02x, 0b%08b) Length(%s, 0x%02x) Value(%s)\n",
			       $seq_elm->{'_index'}, $h->{'Type'}, $h->{'Type'}, $h->{'Type'},
			       $h->{'Length'}, $h->{'Length'}, $h->{'Value'});
		}

	}

	$seq->{'Value'} = $seq_value;
	return($result);
}

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
}

sub decode_Kerberos_KRB_ERROR($)
{
	my ($data) = @_;

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

	# KRB-ERROR
	my $krb_error = kDec_ASN1_TLV($data);
	$krb_error->{'_type'} = 'KRB-ERROR';

	# SEQUENCE
	my $seq = kDec_ASN1_TLV($krb_error->{'Value'});
	$seq->{'_name'} = 'SEQUENCE';
	$seq->{'_type'} = 'SEQUENCE';
	my $seq_data = $seq->{'Value'};
	my $seq_datalen = length($seq_data);
	my $seq_value = [];
	my $seq_elm = undef;
	for (my $seq_offset = 0; $seq_offset < $seq_datalen; ) {
		$seq_elm = kDec_ASN1_TLV(substr($seq_data, $seq_offset));
		$seq_offset += length($seq_elm->{'_self'});

		if (defined($seq_elm->{'_index'}) && $seq_elm->{'_index'} == 0) {
			#         pvno            [0] INTEGER (5),
			my $tmp = kDec_ASN1_TLV($seq_elm->{'Value'});
			$tmp->{'_name'} = 'pvno';
			$tmp->{'_type'} = 'INTEGER';
			$tmp->{'Value'} = unpack('H*', $tmp->{'Value'});
			$seq_elm->{'Value'} = $tmp;
		}
		elsif (defined($seq_elm->{'_index'}) && $seq_elm->{'_index'} == 1) {
			#         msg-type        [1] INTEGER (30),
			my $tmp = kDec_ASN1_TLV($seq_elm->{'Value'});
			$tmp->{'_name'} = 'msg-type';
			$tmp->{'_type'} = 'INTEGER';
			$tmp->{'Value'} = unpack('H*', $tmp->{'Value'});
			$seq_elm->{'Value'} = $tmp;
		}
		elsif (defined($seq_elm->{'_index'}) && $seq_elm->{'_index'} == 2) {
			#         ctime           [2] KerberosTime OPTIONAL,
			my $tmp = kDec_ASN1_TLV($seq_elm->{'Value'});
			$tmp->{'_name'} = 'ctime';
			$tmp->{'_type'} = 'KerberosTime';
			$tmp->{'Value'} = unpack('A*', $tmp->{'Value'});
			$seq_elm->{'Value'} = $tmp;
		}
		elsif (defined($seq_elm->{'_index'}) && $seq_elm->{'_index'} == 3) {
			#         cusec           [3] Microseconds OPTIONAL,
			my $tmp = kDec_ASN1_TLV($seq_elm->{'Value'});
			$tmp->{'_name'} = 'cutime';
			$tmp->{'_type'} = 'Microseconds';
			$tmp->{'Value'} = unpack('H*', $tmp->{'Value'});
			$seq_elm->{'Value'} = $tmp;
		}
		elsif (defined($seq_elm->{'_index'}) && $seq_elm->{'_index'} == 4) {
			#         stime           [4] KerberosTime,
			my $tmp = kDec_ASN1_TLV($seq_elm->{'Value'});
			$tmp->{'_name'} = 'stime';
			$tmp->{'_type'} = 'KerberosTime';
			$tmp->{'Value'} = unpack('A*', $tmp->{'Value'});
			$seq_elm->{'Value'} = $tmp;
		}
		elsif (defined($seq_elm->{'_index'}) && $seq_elm->{'_index'} == 5) {
			#         susec           [5] Microseconds,
			my $tmp = kDec_ASN1_TLV($seq_elm->{'Value'});
			$tmp->{'_name'} = 'susec';
			$tmp->{'_type'} = 'Microseconds';
			$tmp->{'Value'} = unpack('H*', $tmp->{'Value'});
			$seq_elm->{'Value'} = $tmp;
		}
		elsif (defined($seq_elm->{'_index'}) && $seq_elm->{'_index'} == 6) {
			#         error-code      [6] Int32,
			my $tmp = kDec_ASN1_TLV($seq_elm->{'Value'});
			$tmp->{'_name'} = 'error-code';
			$tmp->{'_type'} = 'Int32';
			$tmp->{'Value'} = unpack('H*', $tmp->{'Value'});
			$seq_elm->{'Value'} = $tmp;
		}
		elsif (defined($seq_elm->{'_index'}) && $seq_elm->{'_index'} == 7) {
			#         crealm          [7] Realm OPTIONAL,
			my $tmp = kDec_ASN1_TLV($seq_elm->{'Value'});
			$tmp->{'_name'} = 'crealm';
			$tmp->{'_type'} = 'Realm';
			$tmp->{'Value'} = unpack('A*', $tmp->{'Value'});
			$seq_elm->{'Value'} = $tmp;
		}
		elsif (defined($seq_elm->{'_index'}) && $seq_elm->{'_index'} == 8) {
			#         cname           [8] PrincipalName OPTIONAL,
			my $tmp = kDecKerberos_PrincipalName($seq_elm->{'Value'});
			$tmp->{'_name'} = 'cname';
			$seq_elm->{'Value'} = $tmp;
		}
		elsif (defined($seq_elm->{'_index'}) && $seq_elm->{'_index'} == 9) {
			#         realm           [9] Realm -- service realm --,
			my $tmp = kDec_ASN1_TLV($seq_elm->{'Value'});
			$tmp->{'_name'} = 'realm';
			$tmp->{'_type'} = 'Realm';
			$tmp->{'Value'} = unpack('A*', $tmp->{'Value'});
			$seq_elm->{'Value'} = $tmp;
		}
		elsif (defined($seq_elm->{'_index'}) && $seq_elm->{'_index'} == 10) {
			#         sname           [10] PrincipalName -- service name --,
			my $tmp = kDecKerberos_PrincipalName($seq_elm->{'Value'});
			$tmp->{'_name'} = 'sname';
			$seq_elm->{'Value'} = $tmp;
		}
		elsif (defined($seq_elm->{'_index'}) && $seq_elm->{'_index'} == 11) {
			#         e-text          [11] KerberosString OPTIONAL,
			my $tmp = kDec_ASN1_TLV($seq_elm->{'Value'});
			$tmp->{'_name'} = 'e-text';
			$tmp->{'_type'} = 'KerberosString';
			$tmp->{'Value'} = unpack('A*', $tmp->{'Value'});
			$seq_elm->{'Value'} = $tmp;
		}
		elsif (defined($seq_elm->{'_index'}) && $seq_elm->{'_index'} == 12) {
			#         e-data          [12] OCTET STRING OPTIONAL
			my $tmp = kDec_ASN1_TLV($seq_elm->{'Value'});
			$tmp->{'_type'} = 'OCTET STRING';
			$tmp->{'_name'} = 'e-data';
			$tmp->{'Value'} = unpack('H*', $tmp->{'Value'});
			$seq_elm->{'Value'} = $tmp;
		}
		else {
			# XXX error
			printf("dbg:%s:%s\n", __FILE__, __LINE__);
			exit(1);
			# NOTREACHED
		}

		push(@{$seq_value}, $seq_elm);

		if (1 && $seq_elm->{'_index'} < 13) {
			my $h = $seq_elm->{'Value'};
			printf("%s\n", $h->{'_name'});
			printf("\tidx(%s) Type(%s, 0x%02x, 0b%08b) Length(%s, 0x%02x) Value(%s)\n",
			       $seq_elm->{'_index'}, $h->{'Type'}, $h->{'Type'}, $h->{'Type'},
			       $h->{'Length'}, $h->{'Length'}, $h->{'Value'});
		}
	}

	$seq->{'Value'} = $seq_value;
	$krb_error->{'Value'} = $seq;
	return($krb_error);
}

sub kDecKerberos_Ticket($)
{
	my ($data) = @_;

	# Ticket          ::= [APPLICATION 1] SEQUENCE {
	#         tkt-vno         [0] INTEGER (5),
	#         realm           [1] Realm,
	#         sname           [2] PrincipalName,
	#         enc-part        [3] EncryptedData -- EncTicketPart
	# }

	# Ticket
	my $ticket = kDec_ASN1_TLV($data);
	$ticket->{'_type'} = 'Ticket';

	# SEQUENCE
	my $seq = kDec_ASN1_TLV($ticket->{'Value'});
	$seq->{'_name'} = 'SEQUENCE';
	$seq->{'_type'} = 'SEQUENCE';
	my $seq_data = $seq->{'Value'};
	my $seq_datalen = length($seq_data);
	my $seq_value = [];
	my $seq_elm = undef;
	for (my $seq_offset = 0 ; $seq_offset < $seq_datalen; ) {
		$seq_elm = kDec_ASN1_TLV(substr($seq_data, $seq_offset));
		$seq_offset += length($seq_elm->{'_self'});

		if (defined($seq_elm->{'_index'}) && $seq_elm->{'_index'} == 0) {
			#         tkt-vno         [0] INTEGER (5),
			my $tmp = kDec_ASN1_TLV($seq_elm->{'Value'});
			$tmp->{'_name'} = 'tkt-vno';
			$tmp->{'_type'} = 'INTEGER';
			$tmp->{'Value'} = unpack('H*', $tmp->{'Value'});
			$seq_elm->{'Value'} = $tmp;
		}
		elsif (defined($seq_elm->{'_index'}) && $seq_elm->{'_index'} == 1) {
			#         realm           [1] Realm,
			my $tmp = kDec_ASN1_TLV($seq_elm->{'Value'});
			$tmp->{'_name'} = 'realm';
			$tmp->{'_type'} = 'Realm';
			$tmp->{'Value'} = unpack('A*', $tmp->{'Value'});
			$seq_elm->{'Value'} = $tmp;
		}
		elsif (defined($seq_elm->{'_index'}) && $seq_elm->{'_index'} == 2) {
			#         sname           [2] PrincipalName,
			my $tmp = kDecKerberos_PrincipalName($seq_elm->{'Value'});
			$tmp->{'_name'} = 'sname';
			$seq_elm->{'Value'} = $tmp;
		}
		elsif (defined($seq_elm->{'_index'}) && $seq_elm->{'_index'} == 3) {
			#         enc-part        [3] EncryptedData -- EncTicketPart
			my $tmp = kDecKerberos_EncryptedData($seq_elm->{'Value'});
			$tmp->{'_name'} = 'enc-part';
			$seq_elm->{'Value'} = $tmp;

			my $decrypted = undef;
			# XXX
			# process crypto
			if (1) {
				# decrypt
				{ #5.1
					use Crypt::Random qw( makerandom makerandom_octet );
					use Crypt::CBC;

					my $max_arg = @{$tmp->{'Value'}} - 1;
					my $ticket_cipher = $tmp->{'Value'}->[$max_arg]->{'Value'};
					#my $ticket_cipher = $tmp->{'Value'}->[2]->{'Value'};
					printf("TICKET CIPHER\n");
					printf("\t%s, %s\n", $ticket_cipher->{'_name'}, $ticket_cipher->{'Value'});

					#my $K = '5e2c8acb08d3a7b96d37cdad263e7cb552d90e7652803701'; #1
					#my $K = '68f8a7023b4c3449169e3749ad0d8a85014cd6bf3746ea54'; #2
					#my $K = '233825ba7a4a02ad8545bf92341a982ca1235e1fea380bc2'; #3
					#my $K = '5b7f85910d83a11a5b7575f4c7d9408f5ba834a8730b1fa1'; #4
					my $K = 'a8fec15b3e49c87052cd1ce646d54a4fec8a64156d70916d';
					#my $K = '0119b9f7450d34fe979b9b26131a9e588913b69d2c3deaef'; #6
					$K = pack('H*', $K);
					my $S = $ticket_cipher->{'Value'};
					$S = pack('H*', $S);
					my $IV = '0000000000000000';
					$IV = pack('H*', $IV);
					printf("K(%s) S(%s) IV(%s)\n", length($K), length($S), length($IV));
					my $padlen = align(length($S), 8) - length($S);
					printf("PADLEN (%s)\n", $padlen);
					for (my $i=0; $i < $padlen; $i++) { $S .= pack('H*', '00'); }
					printf("K(%s) S(%s) IV(%s)\n", length($K), length($S), length($IV));
					my $decrSub = sub {
						my ($K, $S, $IV) = @_;
						my $remainPad = 0;
						my $tripleDES = undef;
						$tripleDES = Crypt::CBC->new(
							-key => $K,
							-cipher => 'DES_EDE3',
							-header => 'none',
							-iv => $IV,
							-literal_key => 1,
							#-padding => sub { return(cbcPadding($_[0], $_[1], $_[2], \$remainPad)); },
						);
						my $ret = $tripleDES->decrypt($S);
						$ret = ($remainPad) ? substr($ret, 0, -$remainPad) : $ret;
					};

					$decrypted = &{$decrSub}($K, $S, $IV);
					printf("DECRYPT\n");
					printf("\t%s %s\n",
					       ref($decrypted) ? ref($decrypted) : 'PRM', unpack('H*', $decrypted));

				}
			}
			else {
				# return

			}

			$decrypted = kDecKerberos_EncTicketPart($decrypted);
			$decrypted->{'_name'} = 'enc-part';
			$tmp->{'Value'}->[2]->{'Value'} = $decrypted;

			if (0) {
				my $ticket_cipher = $tmp->{'Value'}->[2]->{'Value'};
				printf("TICKET CIPHER\n");
				printf("\t%s, %s\n", $ticket_cipher->{'_name'}, $ticket_cipher->{'Value'});
			}
			if (0) { #5.1
				use Crypt::Random qw( makerandom makerandom_octet );
				use Crypt::CBC;
				my $ticket_cipher = $tmp->{'Value'}->[2]->{'Value'};
				#my $K = '5e2c8acb08d3a7b96d37cdad263e7cb552d90e7652803701';
				#my $K = '5e2c8acb08d3a7b96d37cdad263e7cb552d90e7652803701'; #1
				#my $K = '68f8a7023b4c3449169e3749ad0d8a85014cd6bf3746ea54'; #2
				#my $K = '233825ba7a4a02ad8545bf92341a982ca1235e1fea380bc2'; #3
				#my $K = '5b7f85910d83a11a5b7575f4c7d9408f5ba834a8730b1fa1'; #4
				my $K = 'a8fec15b3e49c87052cd1ce646d54a4fec8a64156d70916d';
				#my $K = '0119b9f7450d34fe979b9b26131a9e588913b69d2c3deaef'; #6
				$K = pack('H*', $K);
				my $S = $ticket_cipher->{'Value'};
				$S = pack('H*', $S);
				my $IV = '0000000000000000';
				$IV = pack('H*', $IV);
				printf("K(%s) S(%s) IV(%s)\n", length($K), length($S), length($IV));
				my $padlen = align(length($S), 8) - length($S);
				printf("PADLEN (%s)\n", $padlen);
				for (my $i=0; $i < $padlen; $i++) {
					$S .= pack('H*', '00');
				}
				printf("K(%s) S(%s) IV(%s)\n", length($K), length($S), length($IV));
				my $decrSub = sub {
					my ($K, $S, $IV) = @_;
					my $remainPad = 0;
					my $tripleDES = undef;
					$tripleDES = Crypt::CBC->new(
						-key => $K,
						-cipher => 'DES_EDE3',
						-header => 'none',
						-iv => $IV,
						-literal_key => 1,
						#-padding => sub { return(cbcPadding($_[0], $_[1], $_[2], \$remainPad)); },
					);
					my $ret = $tripleDES->decrypt($S);
					$ret = ($remainPad) ? substr($ret, 0, -$remainPad) : $ret;
				};
				my $ret = &{$decrSub}($K, $S, $IV);
				printf("DECRYPT\n");
				printf("\t%s\n", unpack('H*', $ret));
			}
			if (0) { #5.2
				use Crypt::Random qw( makerandom makerandom_octet );
				use Crypt::CBC;
				my $ticket_cipher = $tmp->{'Value'}->[2]->{'Value'};
				#my $K = '5e2c8acb08d3a7b96d37cdad263e7cb552d90e7652803701';
				#my $K = '5e2c8acb08d3a7b96d37cdad263e7cb552d90e7652803701'; #1
				#my $K = '68f8a7023b4c3449169e3749ad0d8a85014cd6bf3746ea54'; #2
				#my $K = '233825ba7a4a02ad8545bf92341a982ca1235e1fea380bc2'; #3
				#my $K = '5b7f85910d83a11a5b7575f4c7d9408f5ba834a8730b1fa1'; #4
				my $K = 'a8fec15b3e49c87052cd1ce646d54a4fec8a64156d70916d';
				#my $K = '0119b9f7450d34fe979b9b26131a9e588913b69d2c3deaef'; #6
				$K = pack('H*', $K);
				my $S = $ticket_cipher->{'Value'};
				{
					$S = substr($S, 16);
				}
				$S = pack('H*', $S);
				my $IV = '0000000000000000';
				$IV = pack('H*', $IV);
				printf("K(%s) S(%s) IV(%s)\n", length($K), length($S), length($IV));
				my $padlen = align(length($S), 8) - length($S);
				printf("PADLEN (%s)\n", $padlen);
				for (my $i=0; $i < $padlen; $i++) {
					$S .= pack('H*', '00');
				}
				printf("K(%s) S(%s) IV(%s)\n", length($K), length($S), length($IV));
				my $decrSub = sub {
					my ($K, $S, $IV) = @_;
					my $remainPad = 0;
					my $tripleDES = undef;
					$tripleDES = Crypt::CBC->new(
						-key => $K,
						-cipher => 'DES_EDE3',
						-header => 'none',
						-iv => $IV,
						-literal_key => 1,
						#-padding => sub { return(cbcPadding($_[0], $_[1], $_[2], \$remainPad)); },
					);
					my $ret = $tripleDES->decrypt($S);
					$ret = ($remainPad) ? substr($ret, 0, -$remainPad) : $ret;
				};
				my $ret = &{$decrSub}($K, $S, $IV);
				printf("DECRYPT\n");
				printf("\t%s\n", unpack('H*', $ret));
			}
                }
		else {
			# XXX error
			printf("dbg:%s:%s\n", __FILE__, __LINE__);
			exit(1);
			# NOTREACHED
		}

		push(@{$seq_value}, $seq_elm);

		if (DEBUG && $seq_elm->{'_index'} < 2) {
			my $h = $seq_elm->{'Value'};
			printf("%s\n", $h->{'_name'});
			printf("\tidx(%s) Type(%s, 0x%02x, 0b%08b) Length(%s, 0x%02x) Value(%s)\n",
			       $seq_elm->{'_index'}, $h->{'Type'}, $h->{'Type'}, $h->{'Type'},
			       $h->{'Length'}, $h->{'Length'}, $h->{'Value'});
		}
	}

	$seq->{'Value'} = $seq_value;
	$ticket->{'Value'} = $seq;
	return($ticket);
}

sub kDecKerberos_EncTicketPart($)
{
	my ($data) = @_;

	# -- Encrypted part of ticket
	# EncTicketPart   ::= [APPLICATION 3] SEQUENCE {
	#         flags                   [0] TicketFlags,
	#         key                     [1] EncryptionKey,
	#         crealm                  [2] Realm,
	#         cname                   [3] PrincipalName,
	#         transited               [4] TransitedEncoding,
	#         authtime                [5] KerberosTime,
	#         starttime               [6] KerberosTime OPTIONAL,
	#         endtime                 [7] KerberosTime,
	#         renew-till              [8] KerberosTime OPTIONAL,
	#         caddr                   [9] HostAddresses OPTIONAL,
	#         authorization-data      [10] AuthorizationData OPTIONAL
	# }

	# EncTicketPart
	$data = substr($data, 8);
	my $enc_ticket = kDec_ASN1_TLV($data);
	$enc_ticket->{'_type'} = 'EncTicketPart';

	# SEQUENCE
	my $seq = kDec_ASN1_TLV($enc_ticket->{'Value'});
	$seq->{'_name'} = 'SEQUENCE';
	$seq->{'_type'} = 'SEQUENCE';
	my $seq_data = $seq->{'Value'};
	my $seq_datalen = length($seq_data);
	my $seq_value = [];
	my $seq_elm = undef;
	for (my $seq_offset = 0 ; $seq_offset < $seq_datalen; ) {
		$seq_elm = kDec_ASN1_TLV(substr($seq_data, $seq_offset));
		$seq_offset += length($seq_elm->{'_self'});

		if (defined($seq_elm->{'_index'}) && $seq_elm->{'_index'} == 0) {
			#         flags                   [0] TicketFlags,
			my $tmp = kDec_ASN1_TLV($seq_elm->{'Value'});
			$tmp->{'_name'} = 'flags';
			$tmp->{'_type'} = 'TicketFlags';
			$tmp->{'Value'} = unpack('H*', $tmp->{'Value'});
			$seq_elm->{'Value'} = $tmp;
		}
		elsif (defined($seq_elm->{'_index'}) && $seq_elm->{'_index'} == 1) {
			#         key                     [1] EncryptionKey,
			my $tmp = kDecKerberos_EncryptionKey($seq_elm->{'Value'});
			$tmp->{'_name'} = 'key';
			$seq_elm->{'Value'} = $tmp;
		}
		elsif (defined($seq_elm->{'_index'}) && $seq_elm->{'_index'} == 2) {
			#         crealm                  [2] Realm,
			my $tmp = kDec_ASN1_TLV($seq_elm->{'Value'});
			$tmp->{'_name'} = 'crealm';
			$tmp->{'_type'} = 'Realm';
			$tmp->{'Value'} = unpack('H*', $tmp->{'Value'});
			$seq_elm->{'Value'} = $tmp;
		}
		elsif (defined($seq_elm->{'_index'}) && $seq_elm->{'_index'} == 3) {
			#         cname                   [3] PrincipalName,
			my $tmp = kDecKerberos_PrincipalName($seq_elm->{'Value'});
			$tmp->{'_name'} = 'cname';
			$seq_elm->{'Value'} = $tmp;
		}
		elsif (defined($seq_elm->{'_index'}) && $seq_elm->{'_index'} == 4) {
			#         transited               [4] TransitedEncoding,
			my $tmp = kDec_ASN1_TLV($seq_elm->{'Value'});
			$tmp->{'_name'} = 'transited';
			$tmp->{'_type'} = 'TransitedEncoding';
			$tmp->{'Value'} = unpack('H*', $tmp->{'Value'});
			$seq_elm->{'Value'} = $tmp;
		}
		elsif (defined($seq_elm->{'_index'}) && $seq_elm->{'_index'} == 5) {
			#         authtime                [5] KerberosTime,
			my $tmp = kDec_ASN1_TLV($seq_elm->{'Value'});
			$tmp->{'_name'} = 'authtime';
			$tmp->{'_type'} = 'KerberosTime';
			$tmp->{'Value'} = unpack('A*', $tmp->{'Value'});
			$seq_elm->{'Value'} = $tmp;
		}
		elsif (defined($seq_elm->{'_index'}) && $seq_elm->{'_index'} == 6) {
			#         starttime               [6] KerberosTime OPTIONAL,
			my $tmp = kDec_ASN1_TLV($seq_elm->{'Value'});
			$tmp->{'_name'} = 'starttime';
			$tmp->{'_type'} = 'KerberosTime';
			$tmp->{'Value'} = unpack('A*', $tmp->{'Value'});
			$seq_elm->{'Value'} = $tmp;
		}
		elsif (defined($seq_elm->{'_index'}) && $seq_elm->{'_index'} == 7) {
			#         endtime                 [7] KerberosTime,
			my $tmp = kDec_ASN1_TLV($seq_elm->{'Value'});
			$tmp->{'_name'} = 'endtime';
			$tmp->{'_type'} = 'KerberosTime';
			$tmp->{'Value'} = unpack('A*', $tmp->{'Value'});
			$seq_elm->{'Value'} = $tmp;
		}
		elsif (defined($seq_elm->{'_index'}) && $seq_elm->{'_index'} == 8) {
			#         renew-till              [8] KerberosTime OPTIONAL,
			my $tmp = kDec_ASN1_TLV($seq_elm->{'Value'});
			$tmp->{'_name'} = 'renew-till';
			$tmp->{'_type'} = 'KerberosTime';
			$tmp->{'Value'} = unpack('A*', $tmp->{'Value'});
			$seq_elm->{'Value'} = $tmp;
		}
		elsif (defined($seq_elm->{'_index'}) && $seq_elm->{'_index'} == 9) {
			#         caddr                   [9] HostAddresses OPTIONAL,
			#my $tmp = kDec_ASN1_TLV($seq_elm->{'Value'});
			my $tmp = kDecKerberos_HostAddresses($seq_elm->{'Value'});
			$tmp->{'_name'} = 'caddr';
			#$tmp->{'_type'} = 'HostAddresses';
			#$tmp->{'Value'} = unpack('H*', $tmp->{'Value'});
			$seq_elm->{'Value'} = $tmp;
		}
		elsif (defined($seq_elm->{'_index'}) && $seq_elm->{'_index'} == 10) {
			#         authorization-data      [10] AuthorizationData OPTIONAL
			my $tmp = kDec_ASN1_TLV($seq_elm->{'Value'});
			$tmp->{'_name'} = 'authorization-data';
			$tmp->{'_type'} = 'AuthorizationData';
			$tmp->{'Value'} = unpack('H*', $tmp->{'Value'});
			$seq_elm->{'Value'} = $tmp;
		}
		else {
			# XXX error
			printf("dbg:%s:%s index(%s)\n", __FILE__, __LINE__, 
			       defined($seq_elm->{'_index'}) ? $seq_elm->{'_index'} : '?');
			exit(1);
			# NOTREACHED
		}

		push(@{$seq_value}, $seq_elm);

		if (1 && $seq_elm->{'_index'} < 11) {
			my $h = $seq_elm->{'Value'};
			printf("%s\n", $h->{'_name'});
			printf("\tidx(%s) Type(%s, 0x%02x, 0b%08b) Length(%s, 0x%02x) Value(%s)\n",
			       $seq_elm->{'_index'}, $h->{'Type'}, $h->{'Type'}, $h->{'Type'},
			       $h->{'Length'}, $h->{'Length'}, $h->{'Value'});
		}
	}

	$seq->{'Value'} = $seq_value;
	$enc_ticket->{'Value'} = $seq;
	return($enc_ticket);
}

sub kDecKerberos_EncryptionKey($)
{
	my ($data) = @_;

	# EncryptionKey   ::= SEQUENCE {
	#         keytype         [0] Int32 -- actually encryption type --,
	#         keyvalue        [1] OCTET STRING
	# }

	# SEQUENCE
	my $result = kDec_ASN1_TLV($data);
	$result->{'_name'} = 'SEQUENCE';
	$result->{'_type'} = 'EncryptionKey';

	my $seq_data = $result->{'Value'};
	my $seq_datalen = length($seq_data);
	my $seq_value = [];
	my $seq_elm = undef;
	for (my $seq_offset = 0 ; $seq_offset < $seq_datalen; ) {
		$seq_elm = kDec_ASN1_TLV(substr($seq_data, $seq_offset));
		$seq_offset += length($seq_elm->{'_self'});

		if (defined($seq_elm->{'_index'}) && $seq_elm->{'_index'} == 0) {
			#         keytype         [0] Int32 -- actually encryption type --,
			my $tmp = kDec_ASN1_TLV($seq_elm->{'Value'});
			$tmp->{'_name'} = 'keytype';
			$tmp->{'_type'} = 'Int32';
			$tmp->{'Value'} = unpack('H*', $tmp->{'Value'});
			$seq_elm->{'Value'} = $tmp;
		}
		elsif (defined($seq_elm->{'_index'}) && $seq_elm->{'_index'} == 1) {
			#         keyvalue        [1] OCTET STRING
			my $tmp = kDec_ASN1_TLV($seq_elm->{'Value'});
			$tmp->{'_type'} = 'OCTET STRING';
			$tmp->{'_name'} = 'keyvalue';
			$tmp->{'Value'} = unpack('H*', $tmp->{'Value'});
			$seq_elm->{'Value'} = $tmp;
		}
		else {
			# XXX error
			printf("dbg:%s:%s\n", __FILE__, __LINE__);
			exit(1);
			# NOTREACHED
		}

		push(@{$seq_value}, $seq_elm);

		if (1 && $seq_elm->{'_index'} < 2) {
			my $h = $seq_elm->{'Value'};
			printf("%s\n", $h->{'_name'});
			printf("\tidx(%s) Type(%s, 0x%02x, 0b%08b) Length(%s, 0x%02x) Value(%s)\n",
			       $seq_elm->{'_index'}, $h->{'Type'}, $h->{'Type'}, $h->{'Type'},
			       $h->{'Length'}, $h->{'Length'}, $h->{'Value'});
		}
	}

	$result->{'Value'} = $seq_value;
	return($result);
}

sub kDecKerberos_HostAddress($)
{
	my ($data) = @_;

	# HostAddress     ::= SEQUENCE  {
	#         addr-type       [0] Int32,
	#         address         [1] OCTET STRING
	# }

	# SEQUENCE
	my $result = kDec_ASN1_TLV($data);
	$result->{'_name'} = 'SEQUENCE';
	$result->{'_type'} = 'HostAddress';

	my $seq_data = $result->{'Value'};
	my $seq_datalen = length($seq_data);
	my $seq_value = [];
	my $seq_elm = undef;
	for (my $seq_offset = 0 ; $seq_offset < $seq_datalen; ) {
		$seq_elm = kDec_ASN1_TLV(substr($seq_data, $seq_offset));
		$seq_offset += length($seq_elm->{'_self'});

		if (defined($seq_elm->{'_index'}) && $seq_elm->{'_index'} == 0) {
			#         addr-type       [0] Int32,
			my $tmp = kDec_ASN1_TLV($seq_elm->{'Value'});
			$tmp->{'_name'} = 'addr-type';
			$tmp->{'_type'} = 'Int32';
			$tmp->{'Value'} = unpack('H*', $tmp->{'Value'});
			$seq_elm->{'Value'} = $tmp;
		}
		elsif (defined($seq_elm->{'_index'}) && $seq_elm->{'_index'} == 1) {
			#         address         [1] OCTET STRING
			my $tmp = kDec_ASN1_TLV($seq_elm->{'Value'});
			$tmp->{'_type'} = 'OCTET STRING';
			$tmp->{'_name'} = 'address';
			$tmp->{'Value'} = unpack('H*', $tmp->{'Value'});
			$seq_elm->{'Value'} = $tmp;
		}

		else {
			# XXX error
			printf("dbg:%s:%s\n", __FILE__, __LINE__);
			exit(1);
			# NOTREACHED
		}

		push(@{$seq_value}, $seq_elm);

		if (1 && $seq_elm->{'_index'} < 2) {
			my $h = $seq_elm->{'Value'};
			printf("%s\n", $h->{'_name'});
			printf("\tidx(%s) Type(%s, 0x%02x, 0b%08b) Length(%s, 0x%02x) Value(%s)\n",
			       $seq_elm->{'_index'}, $h->{'Type'}, $h->{'Type'}, $h->{'Type'},
			       $h->{'Length'}, $h->{'Length'}, $h->{'Value'});
		}
	}

	$result->{'Value'} = $seq_value;
	return($result);
}

sub kDecKerberos_HostAddresses($)
{
	my ($data) = @_;

	# HostAddresses   -- NOTE: subtly different from rfc1510,
	#                 -- but has a value mapping and encodes the same
	# 			::= SEQUENCE OF HostAddress
	# }

	# SEQUENCE
	my $result = kDec_ASN1_TLV($data);
	$result->{'_name'} = 'SEQUENCE';
	$result->{'_type'} = 'HostAddresses';

	my $seq_data = $result->{'Value'};
	my $seq_datalen = length($seq_data);
	my $seq_value = [];
	my $seq_elm = undef;
	for (my $seq_offset = 0 ; $seq_offset < $seq_datalen; ) {
		$seq_elm = kDecKerberos_HostAddress(substr($seq_data, $seq_offset));
		$seq_offset += length($seq_elm->{'_self'});
		$seq_elm->{'_name'} = 'HostAddress';
		push(@{$seq_value}, $seq_elm);
	}

	$result->{'Value'} = $seq_value;
	return($result);
}

sub kDecKerberos_PrincipalName($)
{
	my ($data) = @_;
	# PrincipalName   ::= SEQUENCE {
	#         name-type       [0] Int32,
	#         name-string     [1] SEQUENCE OF KerberosString
	# }

	# SEQUENCE
	my $result = kDec_ASN1_TLV($data);
	$result->{'_name'} = 'SEQUENCE';
	$result->{'_type'} = 'PrincipalName';

	my $seq_data = $result->{'Value'};
	my $seq_datalen = length($seq_data);
	my $seq_value = [];
	my $seq_elm = undef;
	for (my $seq_offset = 0 ; $seq_offset < $seq_datalen; ) {
		$seq_elm = kDec_ASN1_TLV(substr($seq_data, $seq_offset));
		$seq_offset += length($seq_elm->{'_self'});

		if (defined($seq_elm->{'_index'}) && $seq_elm->{'_index'} == 0) {
			#         name-type       [0] Int32,
			my $tmp = kDec_ASN1_TLV($seq_elm->{'Value'});
			$tmp->{'_name'} = 'name-type';
			$tmp->{'_type'} = 'Int32';
			$tmp->{'Value'} = unpack('H*', $tmp->{'Value'});
			$seq_elm->{'Value'} = $tmp;
		}
		elsif (defined($seq_elm->{'_index'}) && $seq_elm->{'_index'} == 1) {
			#         name-string     [1] SEQUENCE OF KerberosString
			#my $tmp = kDec_ASN1_TLV($seq_elm->{'Value'});
			my $tmp = kDecKerberos_SEQ_KerberosString($seq_elm->{'Value'});
			$tmp->{'_name'} = 'name-string';
			$seq_elm->{'Value'} = $tmp;
		}
		else {
			# XXX error
			printf("dbg:%s:%s\n", __FILE__, __LINE__);
			exit(1);
			# NOTREACHED
		}

		push(@{$seq_value}, $seq_elm);

		if (DEBUG) {
			my $h = $seq_elm->{'Value'};
			printf("%s\n", $h->{'_name'});
			printf("\tidx(%s) Type(%s, 0x%02x, 0b%08b) Length(%s, 0x%02x) Value(%s)\n",
			       $seq_elm->{'_index'}, $h->{'Type'}, $h->{'Type'}, $h->{'Type'},
			       $h->{'Length'}, $h->{'Length'}, $h->{'Value'});
		}
	}

	$result->{'Value'} = $seq_value;
	return($result);
}

sub kDecKerberos_SEQ_KerberosString($)
{
	my ($data) = @_;
	# SEQUENCE
	my $result = kDec_ASN1_TLV($data);
	$result->{'_name'} = 'SEQUENCE OF';
	$result->{'_type'} = 'SEQUENCE OF';
	my $seq_data = $result->{'Value'};
	my $seq_datalen = length($seq_data);
	my $seq_value = [];
	my $seq_elm = undef;
	for (my $seq_offset = 0 ; $seq_offset < $seq_datalen; ) {
		$seq_elm = kDec_ASN1_TLV(substr($seq_data, $seq_offset));
		$seq_offset += length($seq_elm->{'_self'});
		$seq_elm->{'_name'} = 'KerberosString';
		$seq_elm->{'_type'} = 'KerberosString';
		$seq_elm->{'Value'} = unpack('A*', $seq_elm->{'Value'});
		push(@{$seq_value}, $seq_elm);

		if (DEBUG) {
			my $h = $seq_elm;
			printf("%s\n", $h->{'_name'});
			printf("\tType(%s, 0x%02x, 0b%08b) Length(%s, 0x%02x) Value(%s)\n",
			       $h->{'Type'}, $h->{'Type'}, $h->{'Type'},
			       $h->{'Length'}, $h->{'Length'}, $h->{'Value'});
		}
	}

	$result->{'Value'} = $seq_value;
	return($result);
}

sub kDecKerberos_EncryptedData($)
{
	my ($data) = @_;

	# EncryptedData   ::= SEQUENCE {
	#         etype   [0] Int32 -- EncryptionType --,
	#         kvno    [1] UInt32 OPTIONAL,
	#         cipher  [2] OCTET STRING -- ciphertext
	# }

	# SEQUENCE
	my $result = kDec_ASN1_TLV($data);
	$result->{'_name'} = 'SEQUENCE';
	$result->{'_type'} = 'EncryptedData';
	if (DEBUG) {
		my $h = $result;
		printf("%s\n", $h->{'_name'});
		printf("\tType(%s, 0x%02x, 0b%08b) Length(%s, 0x%02x)\n",
		       $h->{'Type'}, $h->{'Type'}, $h->{'Type'}, $h->{'Length'}, $h->{'Length'});
	}

	my $seq_data = $result->{'Value'};
	my $seq_datalen = length($seq_data);
	my $seq_value = [];
	my $seq_elm = undef;
	for (my $seq_offset = 0 ; $seq_offset < $seq_datalen; ) {
		$seq_elm = kDec_ASN1_TLV(substr($seq_data, $seq_offset));
		$seq_offset += length($seq_elm->{'_self'});

		if (defined($seq_elm->{'_index'}) && $seq_elm->{'_index'} == 0) {
			#         etype   [0] Int32 -- EncryptionType --,
			my $tmp = kDec_ASN1_TLV($seq_elm->{'Value'});
			$tmp->{'_name'} = 'etype';
			$tmp->{'_type'} = 'Int32';
			$tmp->{'Value'} = unpack('H*', $tmp->{'Value'});
			$seq_elm->{'Value'} = $tmp;
		}
		elsif (defined($seq_elm->{'_index'}) && $seq_elm->{'_index'} == 1) {
			#         kvno    [1] UInt32 OPTIONAL,
			my $tmp = kDec_ASN1_TLV($seq_elm->{'Value'});
			$tmp->{'_name'} = 'kvno';
			$tmp->{'_type'} = 'UInt32';
			$tmp->{'Value'} = unpack('H*', $tmp->{'Value'});
			$seq_elm->{'Value'} = $tmp;
		}
		elsif (defined($seq_elm->{'_index'}) && $seq_elm->{'_index'} == 2) {
			#         cipher  [2] OCTET STRING -- ciphertext
			my $tmp = kDec_ASN1_TLV($seq_elm->{'Value'});
			$tmp->{'_type'} = 'OCTET STRING';
			$tmp->{'_name'} = 'cipher';
			$tmp->{'Value'} = unpack('H*', $tmp->{'Value'});
			$seq_elm->{'Value'} = $tmp;
		}
		else {
			# XXX error
			printf("dbg:%s:%s\n", __FILE__, __LINE__);
			exit(1);
			# NOTREACHED
		}

		push(@{$seq_value}, $seq_elm);

		if (DEBUG) {
			my $h = $seq_elm->{'Value'};
			printf("%s\n", $h->{'_name'});
			printf("\tidx(%s) Type(%s, 0x%02x, 0b%08b) Length(%s, 0x%02x) Value(%s)\n",
			       $seq_elm->{'_index'}, $h->{'Type'}, $h->{'Type'}, $h->{'Type'},
			       $h->{'Length'}, $h->{'Length'}, $h->{'Value'});
		}
	}

	$result->{'Value'} = $seq_value;
	return($result);
}


=pod

=head2 kDecKINK_ENCRYPT_Payload()

Parses an KINK Header and provide data for the next parser.

=head3 Parameters

=head3 Return value

=cut

sub kDecKINK_AP_REP_Payload($)
{
	my ($data) = @_;

	my ($next_payload, $reserved, $payload_length, $epoch) =
		unpack('C C n N', $data);

	my $self = substr($data, 0, $payload_length);
	my $pad_length = align($payload_length, 4) - $payload_length;
	my $pad = substr($data, $payload_length, $pad_length);
	my $remain = substr($data, $payload_length + $pad_length);

	my $ap_rep = substr($self, 8, $payload_length - 8);
#	my $ap_rep_dec = kDecKerberos_AP_REP($ap_rep);

	my $result = {
		'_name'		=> 'KINK_AP_REP Payload',
		'_self'		=> $self,
		'_pad'		=> $pad,
		'_pad_length'	=> $pad_length,
		'_remain'	=> $remain,

		'NextPayload'	=> $next_payload,
		'RESERVED'	=> $reserved,
		'Payload Length'	=> $payload_length,
		'EPOCH'		=> $epoch,
		'AP-REP'	=> $ap_rep,
#		'AP-REP_dec'	=> $ap_rep_dec,
	};

	return($result);
}


sub kDecKINK_KRB_ERROR_Payload($)
{
	my ($data) = @_;

	my ($next_payload, $reserved, $payload_length) =
		unpack('C C n', $data);

	my $self = substr($data, 0, $payload_length);
	my $pad_length = align($payload_length, 4) - $payload_length;
	my $pad = substr($data, $payload_length, $pad_length);
	my $remain = substr($data, $payload_length + $pad_length);

	my $krb_error = substr($self, 4, $payload_length - 4);
	$krb_error = decode_Kerberos_KRB_ERROR($krb_error);

	my $result = {
		'_name'		=> 'KINK_KRB_ERROR Payload',
		'_self'		=> $self,
		'_pad'		=> $pad,
		'_pad_length'	=> $pad_length,
		'_remain'	=> $remain,

		'NextPayload'	=> $next_payload,
		'RESERVED'	=> $reserved,
		'Payload Length'	=> $payload_length,
		'KRB-ERROR'	=> $krb_error,
	};

	return($result);
}

sub kDecKINK_TGT_REQ_Payload($)
{
	my ($data) = @_;

	my ($next_payload, $reserved, $payload_length) =
		unpack('C C n', $data);

	my $self = substr($data, 0, $payload_length);
	my $pad_length = align($payload_length, 4) - $payload_length;
	my $pad = substr($data, $payload_length, $pad_length);
	my $remain = substr($data, $payload_length + $pad_length);

	my $princ_name = substr($self, 4);
	$princ_name = unpack('H*', substr($princ_name, 0 , 2)) . substr($princ_name, 2);

	my $result = {
		'_name'		=> 'KINK_TGT_REQ Payload',
		'_self'		=> $self,
		'_pad'		=> $pad,
		'_pad_length'	=> $pad_length,
		'_remain'	=> $remain,

		'NextPayload'	=> $next_payload,
		'RESERVED'	=> $reserved,
		'Payload Length'	=> $payload_length,
		'PrincName'	=> $princ_name,
	};

	return($result);
}

sub kDecKINK_TGT_REP_Payload($)
{
	my ($data) = @_;

	my ($next_payload, $reserved, $payload_length) =
		unpack('C C n', $data);

	my $self = substr($data, 0, $payload_length);
	my $pad_length = align($payload_length, 4) - $payload_length;
	my $pad = substr($data, $payload_length, $pad_length);
	my $remain = substr($data, $payload_length + $pad_length);

	my $tgt = substr($self, 4);

	my $result = {
		'_name'		=> 'KINK_TGT_REP Payload',
		'_self'		=> $self,
		'_pad'		=> $pad,
		'_pad_length'	=> $pad_length,
		'_remain'	=> $remain,

		'NextPayload'	=> $next_payload,
		'RESERVED'	=> $reserved,
		'Payload Length'	=> $payload_length,
		'TGT'		=> $tgt,
	};

	return($result);
}

sub kDecKINK_ISAKMP_Payload($)
{
	my ($data) = @_;

	my ($next_payload, $reserved, $payload_length, $inner_next_payload, $version, $reserved2) =
		unpack('C C n C C n', $data);

	my $self = substr($data, 0, $payload_length);
	my $pad_length = align($payload_length, 4) - $payload_length;
	my $pad = substr($data, $payload_length, $pad_length);
	my $remain = substr($data, $payload_length + $pad_length);

	my $qmmaj = 0xf & ($version >> 4);
	my $qmmin = 0xf & $version;
	my $quick_mode_payload_data = substr($self, 8, $payload_length - 8);
	my $quick_mode_payload = kKINK::ISAKMP::decode_ISAKMP_Payload($quick_mode_payload_data, $inner_next_payload);

	my $result = {
		'_name'		=> 'KINK_ISAKMP Payload',
		'_self'		=> $self,
		'_pad'		=> $pad,
		'_pad_length'	=> $pad_length,
		'_remain'	=> $remain,

		'NextPayload'	=> $next_payload,
		'RESERVED'	=> $reserved,
		'Payload Length'	=> $payload_length,
		'InnerNextPayload'	=> $inner_next_payload,
		'QMMaj'		=> $qmmaj,
		'QMMin'		=> $qmmin,
		'RESERVED2'	=> $reserved2,
		'Quick Mode Payloads'	=> $quick_mode_payload,
	};

	return($result);
}

sub kDecKINK_ENCRYPT_Payload($;$)
{
	my ($data, $plain) = @_;

	my $next_payload = undef;
	my $reserved = undef;
	my $payload_length = undef;
	my $inner_next_payload = undef;
	my $reserved2 = undef;

	if ($plain) {
		my $tmp = undef;
		($next_payload, $reserved, $payload_length, $inner_next_payload, $tmp, $reserved2) =
			unpack('C C n C C n', $data);
		$reserved2 = ($tmp << 16) + $reserved2;
		# XXX: 28 depends on algorithms
		$payload_length -= 28;
	}
	else {
		($next_payload, $reserved, $payload_length) =
			unpack('C C n', $data);
	}

	my $self = substr($data, 0, $payload_length);
	my $pad_length = align($payload_length, 4) - $payload_length;
	my $pad = substr($data, $payload_length, $pad_length);
	my $remain = substr($data, $payload_length + $pad_length);

	my $encrypted = undef;
	unless ($plain) {
		$encrypted = substr($self, 4);
	}

	my $payloads = [];
	my $payload_data = substr($self, 8, $payload_length - 8);
	if ($plain) {
		for (my $next_payload = $inner_next_payload; $next_payload != 0; ) {
			my $decode = $decode_functions{$next_payload};
			unless (defined($decode)) {
				printf("dbg: %s: %s: kDecKINK_ENCRYPT_Payload: unknown NextPayload(%s)\n",
				       __FILE__, __LINE__, $next_payload);
				exit(1);
				# NOTREACHED
			}
			my $payload = &{$decode}($payload_data);
			push(@{$payloads}, $payload);

			$next_payload = $payload->{'NextPayload'};
			$payload_data = $payload->{'_remain'};
		}
	}

	my $result = {
		'_name'		=> 'KINK_ENCRYPT Payload',
		'_self'		=> $self,
		'_pad'		=> $pad,
		'_pad_length'	=> $pad_length,
		'_remain'	=> $remain,
		'_encrypted'	=> $encrypted,

		'NextPayload'	=> $next_payload,
		'RESERVED'	=> $reserved,
		'Payload Length'	=> $payload_length,
		'InnerNextPayload'	=> $inner_next_payload,
		'RESERVED2'	=> $reserved2,
		'Payload'	=> $payloads,
	};

	return($result);
}

sub kDecKINK_ERROR_Payload($)
{
	my ($data) = @_;

	my ($next_payload, $reserved, $payload_length, $error_code) =
		unpack('C C n N', $data);

	my $self = substr($data, 0, $payload_length);
	my $pad_length = align($payload_length, 4) - $payload_length;
	my $pad = substr($data, $payload_length, $pad_length);
	my $remain = substr($data, $payload_length + $pad_length);

	my $result = {
		'_name'		=> 'KINK_ERROR Payload',
		'_self'		=> $self,
		'_pad'		=> $pad,
		'_pad_length'	=> $pad_length,
		'_remain'	=> $remain,

		'NextPayload'	=> $next_payload,
		'RESERVED'	=> $reserved,
		'Payload Length'	=> $payload_length,
		'ErrorCode'	=> $error_code,
	};

	return($result);
}

1;
