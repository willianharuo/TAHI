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
# $Id: ISAKMP.pm,v 1.2 2010/07/22 13:23:57 velo Exp $
#
################################################################

package kKINK::ISAKMP;

use strict;
use warnings;

use kKINK::kUtil;

use constant {
};


# subrouttines
sub encode_ISAKMP_Payload($)
{
	my ($packet) = @_;

	my $result = '';
	foreach my $payload (@{$packet}) {
		my $name = $payload->{'_name'};

		if ($name eq 'Security Association Payload') {
			$result .= encode_SA_Payload($payload);
		}
		elsif ($name eq 'Key Exchange Payload') {
			$result .= encode_KE_Payload($payload);
		}
		elsif ($name eq 'Identification Payload') {
			$result .= encode_ID_Payload($payload);
		}
		elsif ($name eq 'Nonce Payload') {
			$result .= encode_NONCE_Payload($payload);
		}
		elsif ($name eq 'Notification Payload') {
			$result .= encode_Notification_Payload($payload);
		}
		elsif ($name eq 'Delete Payload') {
			$result .= encode_Delete_Payload($payload);
		}
		elsif ($name eq 'Unrecognized Payload') {
			$result .= encode_Unrecognized_Payload($payload);
		}
		else {
			printf("dbg: %s: %s: encode_ISAKMP_Payload: invalid payload type\n",
			       __FILE__, __LINE__);
			exit(1);
			# NOTREACHED
		}
	}

	return($result);
}

my %isakmp_decode_functions = (
	'1'	=> \&decode_SA_Payload,
	'4'	=> \&decode_KE_Payload,
	'5'	=> \&decode_Identification_Payload,
	'10'	=> \&decode_Nonce_Payload,
	'11'	=> \&decode_Notification_Payload,
	'12'	=> \&decode_Delete_Payload,
	'255'	=> \&decode_Unrecognized_Payload, # for EN.EN.R.9.1 and SGW.SGW.R.9.1
);

sub decode_ISAKMP_Payload($$)
{
	my ($data, $inner_next_payload) = @_;

	my $quick_mode_payload = [];
	for (my $next_payload = $inner_next_payload; $next_payload != 0; ) {
		my $decode = $isakmp_decode_functions{$next_payload};
		unless (defined($decode)) {
			printf("dbg: %s: %s: kDecKINK_ISAKMP_Payload: unknown NextPayload(%s)\n",
			       __FILE__, __LINE__, $next_payload);
			exit(1);
			# NOTREACHED
		}
		my $payload = &{$decode}($data);
		push(@{$quick_mode_payload}, $payload);

		$next_payload = $payload->{'NextPayload'};
		$data = $payload->{'_remain'};
	}

	return($quick_mode_payload);
}

sub decode_Identification_Payload($)
{
	my ($data) = @_;

	my ($next_payload, $reserved, $payload_length,
	    $id_type, $protocol_id, $port) =
		unpack('C C n C C n', $data);

	my $self = substr($data, 0, $payload_length);
	my $pad_length = align($payload_length, 4) - $payload_length;
	my $pad = substr($data, $payload_length, $pad_length);
	my $remain = substr($data, $payload_length + $pad_length);

	my $id_data = unpack('H*', substr($self, 8));

	my $result = {
		'_name'		=> 'Identification Payload',
		'_self'		=> $self,
		'_pad'		=> $pad,
		'_pad_length'	=> $pad_length,
		'_remain'	=> $remain,

		'NextPayload'	=> $next_payload,
		'RESERVED'	=> $reserved,
		'Payload Length'	=> $payload_length,
		'ID Type'	=> $id_type,
		'Protocol ID'	=> $protocol_id,
		'Port'		=> $port,
		'Identification Data'	=> $id_data,
	};

	return($result);
}

sub decode_KE_Payload($)
{
	my ($data) = @_;

	my ($next_payload, $reserved, $payload_length) =
		unpack('C C n', $data);

	my $self = substr($data, 0, $payload_length);
	my $pad_length = align($payload_length, 4) - $payload_length;
	my $pad = substr($data, $payload_length, $pad_length);
	my $remain = substr($data, $payload_length + $pad_length);

	my $ke_data = unpack('H*', substr($self, 4));

	my $result = {
		'_name'		=> 'Key Exchange Payload',
		'_self'		=> $self,
		'_pad'		=> $pad,
		'_pad_length'	=> $pad_length,
		'_remain'	=> $remain,

		'NextPayload'	=> $next_payload,
		'RESERVED'	=> $reserved,
		'Payload Length'	=> $payload_length,
		'Key Exchange Data'	=> $ke_data,
	};

	return($result);
}

sub decode_Nonce_Payload($)
{
	my ($data) = @_;

	my ($next_payload, $reserved, $payload_length) =
		unpack('C C n', $data);

	my $self = substr($data, 0, $payload_length);
	my $pad_length = align($payload_length, 4) - $payload_length;
	my $pad = substr($data, $payload_length, $pad_length);
	my $remain = substr($data, $payload_length + $pad_length);

	my $nonce_data = unpack('H*', substr($self, 4));

	my $result = {
		'_name'		=> 'Nonce Payload',
		'_self'		=> $self,
		'_pad'		=> $pad,
		'_pad_length'	=> $pad_length,
		'_remain'	=> $remain,

		'NextPayload'	=> $next_payload,
		'RESERVED'	=> $reserved,
		'Payload Length'	=> $payload_length,
		'Nonce Data'	=> $nonce_data,
	};

	return($result);
}

sub decode_Notification_Payload($)
{
	my ($data) = @_;

	my ($next_payload, $reserved, $payload_length,
	    $doi,
	    $protocol_id, $spi_size, $type,
	    $spi) =
		unpack('C C n N C C n N', $data);
	$spi = sprintf("%08x", $spi);

	my $self = substr($data, 0, $payload_length);
	my $pad_length = align($payload_length, 4) - $payload_length;
	my $pad = substr($data, $payload_length, $pad_length);
	my $remain = substr($data, $payload_length + $pad_length);

	my $notification_data = unpack('H*', substr($self, 16, $payload_length - 16));

	my $result = {
		'_name'		=> 'Notification Payload',
		'_self'		=> $self,
		'_pad'		=> $pad,
		'_pad_length'	=> $pad_length,
		'_remain'	=> $remain,

		'NextPayload'	=> $next_payload,
		'RESERVED'	=> $reserved,
		'Payload Length'	=> $payload_length,
		'DOI'		=> $doi,
		'Protocol-ID'		=> $protocol_id,
		'SPI Size'		=> $spi_size,
		'Notify Message Type'	=> $type,
		'SPI'		=> $spi,
		'Notification Data'	=> $notification_data,
	};

	return($result);
}

sub decode_Delete_Payload($)
{
	my ($data) = @_;

	my ($next_payload, $reserved, $payload_length,
	    $doi,
	    $protocol_id, $spi_size, $num_of_spis) =
		unpack('C C n N C C n', $data);

	my $self = substr($data, 0, $payload_length);
	my $pad_length = align($payload_length, 4) - $payload_length;
	my $pad = substr($data, $payload_length, $pad_length);
	my $remain = substr($data, $payload_length + $pad_length);

	my $spis_data = substr($self, 12, $payload_length - 12);
	my $spis_datalen = length($spis_data);
	my $spis = [];
	for (my $offset = 0; $offset < $spis_datalen; $offset += 4) {
		my $spi = unpack('N', substr($spis_data, $offset, $offset + 4));
		$spi = sprintf("%08x", $spi);
		push(@{$spis}, $spi);
	}

	my $result = {
		'_name'		=> 'Delete Payload',
		'_self'		=> $self,
		'_pad'		=> $pad,
		'_pad_length'	=> $pad_length,
		'_remain'	=> $remain,

		'NextPayload'	=> $next_payload,
		'RESERVED'	=> $reserved,
		'Payload Length'	=> $payload_length,
		'DOI'		=> $doi,
		'Protocol-Id'	=> $protocol_id,
		'SPI Size'	=> $spi_size,
		'# of SPIs'	=> $num_of_spis,
		'SPIs'		=> $spis,
	};

	return($result);
}

sub decode_Unrecognized_Payload($)
{
	my ($data) = @_;

	my ($next_payload, $reserved, $payload_length) =
		unpack('C C n', $data);

	my $self = substr($data, 0, $payload_length);
	my $pad_length = align($payload_length, 4) - $payload_length;
	my $pad = substr($data, $payload_length, $pad_length);
	my $remain = substr($data, $payload_length + $pad_length);

	my $result = {
		'_name'		=> 'Unrecognized Payload',
		'_self'		=> $self,
		'_pad'		=> $pad,
		'_pad_length'	=> $pad_length,
		'_remain'	=> $remain,

		'NextPayload'	=> $next_payload,
		'RESERVED'	=> $reserved,
		'Payload Length'	=> $payload_length,
	};

	return($result);
}

sub decode_SA_Payload($)
{
	my ($data) = @_;

	my ($next_payload, $reserved, $payload_length, $doi, $situation) =
		unpack('C C n N N', $data);

	my $self = substr($data, 0, $payload_length);
	my $pad_length = align($payload_length, 4) - $payload_length;
	my $pad = substr($data, $payload_length, $pad_length);
	my $remain = substr($data, $payload_length + $pad_length);

	my $proposals = substr($self, 12, $payload_length - 12);
	$proposals = decode_Proposals($proposals);

	my $result = {
		'_name'		=> 'Security Association Payload',
		'_self'		=> $self,
		'_pad'		=> $pad,
		'_pad_length'	=> $pad_length,
		'_remain'	=> $remain,

		'NextPayload'	=> $next_payload,
		'RESERVED'	=> $reserved,
		'Payload Length'	=> $payload_length,
		'DOI'		=> $doi,
		'Situation'	=> $situation,
		'Proposals'	=> $proposals,
	};

	return($result);
}

sub decode_Proposals($)
{
	my ($data) = @_;

	my $result = [];
	my $remain = $data;
	my $prev = undef;

	for ( ; ; ) {
		unless ($remain) {
			last;
		}
		my $proposal = decode_Proposal_Payload($remain);

		if (!defined($prev) ||
		    $prev->{'Proposal #'} != $proposal->{'Proposal #'}) {
			push(@{$result}, [$proposal]);
		}
		elsif ($prev->{'Proposal #'} == $proposal->{'Proposal #'}) {
			push(@{$result->[$proposal->{'Proposal #'}]}, $proposal);
		}
		else {
			printf("dbg: %s: %s: decode_Proposals: cannot sort proposal\n",
			       __FILE__, __LINE__);
			exit(1);
		}

		$remain = $proposal->{'_remain'};
	}

	return($result);
}

sub decode_Proposal_Payload($)
{
	my ($data) = @_;

	my ($next_payload, $reserved, $payload_length,
	    $proposal_number, $protocol_id, $spi_size, $num_of_transforms,
	    $spi) =
		unpack('C C n C C C C N', $data);
	$spi = sprintf("%08x", $spi);

	my $self = substr($data, 0, $payload_length);
	my $pad_length = align($payload_length, 4) - $payload_length;
	my $pad = substr($data, $payload_length, $pad_length);
	my $remain = substr($data, $payload_length + $pad_length);

	my $transforms = substr($self, 12, $payload_length - 12);
	$transforms = decode_Transforms($transforms);

	my $result = {
		'_name'		=> 'Proposal Payload',
		'_self'		=> $self,
		'_pad'		=> $pad,
		'_pad_length'	=> $pad_length,
		'_remain'	=> $remain,

		'NextPayload'	=> $next_payload,
		'RESERVED'	=> $reserved,
		'Payload Length'	=> $payload_length,
		'Proposal #'		=> $proposal_number,
		'Protocol-Id'		=> $protocol_id,
		'SPI Size'		=> $spi_size,
		'# of Transforms'	=> $num_of_transforms,
		'SPI'		=> $spi,
		'Transforms'	=> $transforms,
	};

	return($result);
}

sub decode_Transforms($)
{
	my ($data) = @_;

	my $result = [];
	my $remain = $data;
	my $prev = undef;

	for ( ; ; ) {
		unless ($remain) {
			last;
		}
		my $transform = decode_Transform_Payload($remain);

		push(@{$result}, $transform);
		$remain = $transform->{'_remain'};
	}

	return($result);
}

sub decode_Transform_Payload($)
{
	my ($data) = @_;

	my ($next_payload, $reserved, $payload_length,
	    $transform_number, $transform_id, $reserved2) =
		unpack('C C n C C n', $data);

	my $self = substr($data, 0, $payload_length);
	my $pad_length = align($payload_length, 4) - $payload_length;
	my $pad = substr($data, $payload_length, $pad_length);
	my $remain = substr($data, $payload_length + $pad_length);

	my $attributes = substr($self, 8, $payload_length - 8);
	$attributes = decode_SA_Attributes($attributes);

	my $result = {
		'_name'		=> 'Transform Payload',
		'_self'		=> $self,
		'_pad'		=> $pad,
		'_pad_length'	=> $pad_length,
		'_remain'	=> $remain,

		'NextPayload'	=> $next_payload,
		'RESERVED'	=> $reserved,
		'Payload Length'	=> $payload_length,
		'Transform #'		=> $transform_number,
		'Transform-Id'		=> $transform_id,
		'RESERVED2'	=> $reserved2,
		'SA Attributes'	=> $attributes,
	};

	return($result);
}

sub decode_SA_Attributes($)
{
	my ($data) = @_;

	my $result = [];
	my $remain = $data;
	my $prev = undef;

	for ( ; ; ) {
		unless ($remain) {
			last;
		}
		my $attribute = decode_SA_Attribute($remain);

		push(@{$result}, $attribute);
		$remain = $attribute->{'_remain'};
	}

	return($result);
}

sub decode_SA_Attribute($)
{
	my ($data) = @_;

	my $attr_type  = unpack('n', $data);
	my $af = ($attr_type & 0x8000) >> 15;
	$attr_type = ($attr_type & 0x7fff);

	if ($af) {
		my $attr_value = unpack('n', substr($data, 2, 2));
		my $self = substr($data, 0, 4);
		my $pad_length = 0;
		my $pad = 0;
		my $remain = substr($data, 4);
		my $result = {
			'_name'		=> 'SA Attribute',
			'_self'		=> $self,
			'_pad'		=> $pad,
			'_pad_length'	=> $pad_length,
			'_remain'	=> $remain,

			'AF'	=> $af,
			'Attribute Type'	=> $attr_type,
			'Attribute Value'	=> $attr_value,
		};

		return($result);
	}
	else {
		my $attr_length = unpack('n', substr($data, 2, 2));
		my $attr_value = substr($data, 2, $attr_length);
		my $self = substr($data, 0, 4 + $attr_length);
		my $pad_length = 0;
		my $pad = 0;
		my $remain = substr($data, 4 + $attr_length);
		my $result = {
			'_name'		=> 'SA Attribute',
			'_self'		=> $self,
			'_pad'		=> $pad,
			'_pad_length'	=> $pad_length,
			'_remain'	=> $remain,

			'AF'	=> $af,
			'Attribute Type'	=> $attr_type,
			'Attribute Length'	=> $attr_length,
			'Attribute Value'	=> $attr_value,
		};

		return($result);
	}
}



#----------------------------------------------------------------------#
# encode subroutines                                                   #
#----------------------------------------------------------------------#
# encode_SA_Payload
#   Only Payload Length field is automatically filled when the value specify 'auto'.
sub encode_SA_Payload($)
{
	my ($packet) = @_;

	my $key = undef;
	my $result = undef;

	$key = 'NextPayload';
	unless (defined($packet->{$key})) {
		printf("dbg: %s: %s: encode_SA_Payload: invalid %s\n",
			__FILE__, __LINE__, $key);
		exit(1);
		# NOTREACHED
	}
	my $next_payload = $packet->{$key};

	$key = 'RESERVED';
	unless (defined($packet->{$key})) {
		printf("dbg: %s: %s: encode_SA_Payload: invalid %s\n",
			__FILE__, __LINE__, $key);
		exit(1);
		# NOTREACHED
	}
	my $reserved = $packet->{$key};

	$key = 'DOI';
	unless (defined($packet->{$key})) {
		printf("dbg: %s: %s: encode_SA_Payload: invalid %s\n",
			__FILE__, __LINE__, $key);
		exit(1);
		# NOTREACHED
	}
	my $doi = $packet->{$key};

	$key = 'Situation';
	unless (defined($packet->{$key})) {
		printf("dbg: %s: %s: encode_SA_Payload: invalid %s\n",
			__FILE__, __LINE__, $key);
		exit(1);
		# NOTREACHED
	}
	my $situation = $packet->{$key};

	# Proposal Payload
	my $proposals = '';
	foreach my $p1 (@{$packet->{'Proposals'}}) {
		foreach my $p2 (@{$p1}) {
			# loop for same Proposal # group
			$proposals .= encode_Proposal_Payload($p2);
		}
	}

	$key = 'Payload Length';
	unless (defined($packet->{$key})) {
		printf("dbg: %s: %s: encode_SA_Payload: invalid %s\n",
			__FILE__, __LINE__, $key);
		exit(1);
		# NOTREACHED
	}
	my $length = ($packet->{$key} eq 'auto') ? 12 + length($proposals) : $packet->{$key};

	$result = pack('C C n N N',
		       $next_payload,
		       $reserved,
		       $length,
		       $doi,
		       $situation);
	$result .= $proposals;

	return($result);
}

#
sub encode_Proposal_Payload($)
{
	my ($packet) = @_;

	my $key = undef;
	my $result = undef;

	$key = 'NextPayload';
	unless (defined($packet->{$key})) {
		printf("dbg: %s: %s: encode_Proposal_Payload: invalid %s\n",
			__FILE__, __LINE__, $key);
		exit(1);
		# NOTREACHED
	}
	my $next_payload = $packet->{$key};

	$key = 'RESERVED';
	unless (defined($packet->{$key})) {
		printf("dbg: %s: %s: encode_Proposal_Payload: invalid %s\n",
			__FILE__, __LINE__, $key);
		exit(1);
		# NOTREACHED
	}
	my $reserved = $packet->{$key};

	$key = 'Proposal #';
	unless (defined($packet->{$key})) {
		printf("dbg: %s: %s: encode_Proposal_Payload: invalid %s\n",
			__FILE__, __LINE__, $key);
		exit(1);
		# NOTREACHED
	}
	my $proposal_number = $packet->{$key};

	$key = 'Protocol-Id';
	unless (defined($packet->{$key})) {
		printf("dbg: %s: %s: encode_Proposal_Payload: invalid %s\n",
			__FILE__, __LINE__, $key);
		exit(1);
		# NOTREACHED
	}
	my $protocol_id = $packet->{$key};

	$key = 'SPI Size';
	unless (defined($packet->{$key})) {
		printf("dbg: %s: %s: encode_Proposal_Payload: invalid %s\n",
			__FILE__, __LINE__, $key);
		exit(1);
		# NOTREACHED
	}
	my $spi_size = $packet->{$key};

	$key = '# of Transforms';
	unless (defined($packet->{$key})) {
		printf("dbg: %s: %s: encode_Proposal_Payload: invalid %s\n",
			__FILE__, __LINE__, $key);
		exit(1);
		# NOTREACHED
	}
	my $num_of_transforms = $packet->{$key};

	$key = 'SPI';
	unless (defined($packet->{$key})) {
		printf("dbg: %s: %s: encode_Proposal_Payload: invalid %s\n",
			__FILE__, __LINE__, $key);
		exit(1);
	}
	my $spi = $packet->{$key};
	$spi = pack('H*', $spi);

	# Transform Payload
	my $transforms = '';
	foreach my $transform (@{$packet->{'Transforms'}}) {
		$transforms .= encode_Transform_Payload($transform);
	}

	$key = 'Payload Length';
	my $length = ($packet->{$key} eq 'auto') ? 12 + length($transforms) : $packet->{$key};

	$result = pack('C C n C C C C',
		       $next_payload,
		       $reserved,
		       $length,
		       $proposal_number,
		       $protocol_id,
		       $spi_size,
		       $num_of_transforms);
	$result .= $spi;
	$result .= $transforms;

	return($result);
}

#
sub encode_Transform_Payload($)
{
	my ($packet) = @_;

	my $key = undef;
	my $result = undef;

	$key = 'NextPayload';
	unless (defined($packet->{$key})) {
		printf("dbg: %s: %s: encode_T_Payload: invalid %s\n",
			__FILE__, __LINE__, $key);
		exit(1);
		# NOTREACHED
	}
	my $next_payload = $packet->{$key};

	$key = 'RESERVED';
	unless (defined($packet->{$key})) {
		printf("dbg: %s: %s: encode_T_Payload: invalid %s\n",
			__FILE__, __LINE__, $key);
		exit(1);
		# NOTREACHED
	}
	my $reserved = $packet->{$key};

	$key = 'Transform #';
	unless (defined($packet->{$key})) {
		printf("dbg: %s: %s: encode_T_Payload: invalid %s\n",
			__FILE__, __LINE__, $key);
		exit(1);
		# NOTREACHED
	}
	my $transform_number = $packet->{$key};

	$key = 'Transform-Id';
	unless (defined($packet->{$key})) {
		printf("dbg: %s: %s: encode_T_Payload: invalid %s\n",
			__FILE__, __LINE__, $key);
		exit(1);
		# NOTREACHED
	}
	my $transform_id = $packet->{$key};

	$key = 'RESERVED2';
	unless (defined($packet->{$key})) {
		printf("dbg: %s: %s: encode_T_Payload: invalid %s\n",
			__FILE__, __LINE__, $key);
		exit(1);
		# NOTREACHED
	}
	my $reserved2 = $packet->{$key};

	# SA Attributes
	my $attributes = '';
	foreach my $attribute (@{$packet->{'SA Attributes'}}) {
		$attributes .= encode_SA_Attribute($attribute);
	}

	$key = 'Payload Length';
	my $length = ($packet->{$key} eq 'auto') ? 8 + length($attributes) : $packet->{$key};

	$result = pack('C C n C C n',
		       $next_payload,
		       $reserved,
		       $length,
		       $transform_number,
		       $transform_id,
		       $reserved2);
	$result .= $attributes;

	return($result);
}

#
sub encode_SA_Attribute($)
{
	my ($packet) = @_;

	my $key = undef;
	my $result = undef;

	$key = 'AF';
	my $af = defined($packet->{$key}) ? $packet->{$key} : 1;

	$key = 'Attribute Type';
	unless (defined($packet->{$key})) {
		printf("dbg: %s: %s: encode_SA_Attribute: invalid %s\n",
		       __FILE__, __LINE__, $key);
		exit(1);
		# NOTREACHED
	}
	my $type = $packet->{$key};

	$key = 'Attribute Value';
	unless (defined($packet->{$key})) {
		printf("dbg: %s: %s: encode_SA_Attribute: invalid %s\n",
		       __FILE__, __LINE__, $key);
		exit(1);
		# NOTREACHED
	}
	my $value = $packet->{$key};

	if ($af) {
		$result = pack('n n',
			       $af << 15 | $type,
			       $value);
	}
	else {
		$key = 'Attribute Length';
		unless (defined($packet->{$key})) {
			printf("dbg: %s: %s: encode_SA_Attribute: invalid %s\n",
			       __FILE__, __LINE__, $key);
			exit(1);
			# NOTREACHED
		}
		my $length = $packet->{$key};
		$result = pack('n n H*',
			       $af << 15 | $type,
			       $length,
			       $value);
	}

	return($result);
}

#
sub encode_KE_Payload($)
{
	my ($packet) = @_;

	my $key = undef;
	my $result = undef;

	$key = 'NextPayload';
	unless (defined($packet->{$key})) {
		printf("dbg: %s: %s: encode_KE_Payload: invalid %s\n",
			__FILE__, __LINE__, $key);
		exit(1);
		# NOTREACHED
	}
	my $next_payload = $packet->{$key};

	$key = 'RESERVED';
	unless (defined($packet->{$key})) {
		printf("dbg: %s: %s: encode_KE_Payload: invalid %s\n",
			__FILE__, __LINE__, $key);
		exit(1);
		# NOTREACHED
	}
	my $reserved = $packet->{$key};

	$key = 'Key Exchange Data';
	unless (defined($packet->{$key})) {
		printf("dbg: %s: %s: encode_KE_Payload: invalid %s\n",
			__FILE__, __LINE__, $key);
		exit(1);
		# NOTREACHED
	}
	my $ke_data = $packet->{$key};
	$ke_data = pack('H*', $ke_data);

	$key = 'Payload Length';
	my $length = ($packet->{$key} eq 'auto') ? 4 + length($ke_data) : $packet->{$key};

	$result = pack('C C n',
		       $next_payload,
		       $reserved,
		       $length);
	$result .= $ke_data;

	return($result);
}

#
sub encode_ID_Payload($)
{
	my ($packet) = @_;

	my $key = undef;
	my $result = undef;

	$key = 'NextPayload';
	unless (defined($packet->{$key})) {
		printf("dbg: %s: %s: encode_ID_Payload: invalid %s\n",
			__FILE__, __LINE__, $key);
		exit(1);
		# NOTREACHED
	}
	my $next_payload = $packet->{$key};

	$key = 'RESERVED';
	unless (defined($packet->{$key})) {
		printf("dbg: %s: %s: encode_ID_Payload: invalid %s\n",
			__FILE__, __LINE__, $key);
		exit(1);
		# NOTREACHED
	}
	my $reserved = $packet->{$key};

	$key = 'ID Type';
	unless (defined($packet->{$key})) {
		printf("dbg: %s: %s: encode_ID_Payload: invalid %s\n",
			__FILE__, __LINE__, $key);
		exit(1);
		# NOTREACHED
	}
	my $id_type = $packet->{$key};

	$key = 'Protocol ID';
	unless (defined($packet->{$key})) {
		printf("dbg: %s: %s: encode_ID_Payload: invalid %s\n",
			__FILE__, __LINE__, $key);
		exit(1);
		# NOTREACHED
	}
	my $protocol_id = $packet->{$key};

	$key = 'Port';
	unless (defined($packet->{$key})) {
		printf("dbg: %s: %s: encode_ID_Payload: invalid %s\n",
			__FILE__, __LINE__, $key);
		exit(1);
		# NOTREACHED
	}
	my $port = $packet->{$key};

	$key = 'Identification Data';
	unless (defined($packet->{$key})) {
		printf("dbg: %s: %s: encode_ID_Payload: invalid %s\n",
			__FILE__, __LINE__, $key);
		exit(1);
		# NOTREACHED
	}
	my $id_data = $packet->{$key};

	if ($id_type == 5) {
		# ID_IPV6_ADDR
		$id_data = ipaddr_tobin($id_data);
	}
	elsif ($id_type == 6) {
		# ID_IPV6_ADDR_SUBNET
		$id_data = ipaddr_tobin($id_data);
		$key = 'Identification Data2';
		unless (defined($packet->{$key})) {
			printf("dbg: %s: %s: encode_ID_Payload: need second value for ID_IPV6_ADDR_SUBNET\n",
			       __FILE__, __LINE__, $key);
			exit(1);
			# NOTREACHED
		}
		$id_data .= ipaddr_tobin($packet->{$key});
	}
	else {
		printf("dbg: %s: %s: encode_ID_Payload: invalid %s\n",
			__FILE__, __LINE__, $key);
		exit(1);
		# NOTREACHED
	}

	$key = 'Payload Length';
	my $length = ($packet->{$key} eq 'auto') ? 8 + length($id_data) : $packet->{$key};

	$result = pack('C C n C C n',
		       $next_payload,
		       $reserved,
		       $length,
		       $id_type,
		       $protocol_id,
		       $port);
	$result .= $id_data;

	return($result);
}

#
sub encode_NONCE_Payload($)
{
	my ($packet) = @_;

	my $key = undef;
	my $result = undef;

	$key = 'NextPayload';
	unless (defined($packet->{$key})) {
		printf("dbg: %s: %s: encode_NONCE_Payload: invalid %s\n",
			__FILE__, __LINE__, $key);
		exit(1);
		# NOTREACHED
	}
	my $next_payload = $packet->{$key};

	$key = 'RESERVED';
	unless (defined($packet->{$key})) {
		printf("dbg: %s: %s: encode_NONCE_Payload: invalid %s\n",
			__FILE__, __LINE__, $key);
		exit(1);
		# NOTREACHED
	}
	my $reserved = $packet->{$key};

	$key = 'Nonce Data';
	unless (defined($packet->{$key})) {
		printf("dbg: %s: %s: encode_NONCE_Payload: invalid %s\n",
			__FILE__, __LINE__, $key);
		exit(1);
		# NOTREACHED
	}
	my $nonce = $packet->{$key};
	$nonce = pack('H*', $nonce);

	$key = 'Payload Length';
	my $length = ($packet->{$key} eq 'auto') ? 4 + length($nonce) : $packet->{$key};

	$result = pack('C C n',
		       $next_payload,
		       $reserved,
		       $length);
	$result .= $nonce;

	return($result);
}

#
sub encode_Notification_Payload($)
{
	my ($packet) = @_;

	my $key = undef;
	my $result = undef;

	$key = 'NextPayload';
	unless (defined($packet->{$key})) {
		printf("dbg: %s: %s: encode_Notification_Payload: invalid %s\n",
			__FILE__, __LINE__, $key);
		exit(1);
		# NOTREACHED
	}
	my $next_payload = $packet->{$key};

	$key = 'RESERVED';
	unless (defined($packet->{$key})) {
		printf("dbg: %s: %s: encode_Notification_Payload: invalid %s\n",
			__FILE__, __LINE__, $key);
		exit(1);
		# NOTREACHED
	}
	my $reserved = $packet->{$key};

	$key = 'DOI';
	unless (defined($packet->{$key})) {
		printf("dbg: %s: %s: encode_Notification_Payload: invalid %s\n",
			__FILE__, __LINE__, $key);
		exit(1);
		# NOTREACHED
	}
	my $doi = $packet->{$key};

	$key = 'Protocol-ID';
	unless (defined($packet->{$key})) {
		printf("dbg: %s: %s: encode_Notification_Payload: invalid %s\n",
			__FILE__, __LINE__, $key);
		exit(1);
		# NOTREACHED
	}
	my $protocol_id = $packet->{$key};

	$key = 'SPI Size';
	unless (defined($packet->{$key})) {
		printf("dbg: %s: %s: encode_Notification_Payload: invalid %s\n",
			__FILE__, __LINE__, $key);
		exit(1);
		# NOTREACHED
	}
	my $spi_size = $packet->{$key};

	$key = 'Notify Message Type';
	unless (defined($packet->{$key})) {
		printf("dbg: %s: %s: encode_Notification_Payload: invalid %s\n",
			__FILE__, __LINE__, $key);
		exit(1);
		# NOTREACHED
	}
	my $type = $packet->{$key};

	$key = 'SPI';
	unless (defined($packet->{$key})) {
		printf("dbg: %s: %s: encode_Notification_Payload: invalid %s\n",
			__FILE__, __LINE__, $key);
		exit(1);
		# NOTREACHED
	}
	my $spi = $packet->{$key};

	$key = 'Notification Data';
	unless (defined($packet->{$key})) {
		printf("dbg: %s: %s: encode_Notification_Payload: invalid %s\n",
			__FILE__, __LINE__, $key);
		exit(1);
		# NOTREACHED
	}
	my $data = pack('H*', $packet->{$key});

	$key = 'Payload Length';
	my $length = ($packet->{$key} eq 'auto') ? 16 + length($data) : $packet->{$key};

	$result = pack('C C n N C C n N',
		       $next_payload, $reserved, $length,
		       $doi,
		       $protocol_id, $spi_size, $type,
		       $spi);
	$result .= $data;

	return($result);
}

#
sub encode_Delete_Payload($)
{
	my ($packet) = @_;

	my $key = undef;
	my $result = undef;

	$key = 'NextPayload';
	unless (defined($packet->{$key})) {
		printf("dbg: %s: %s: encode_Delete_Payload: invalid %s\n",
			__FILE__, __LINE__, $key);
		exit(1);
		# NOTREACHED
	}
	my $next_payload = $packet->{$key};

	$key = 'RESERVED';
	unless (defined($packet->{$key})) {
		printf("dbg: %s: %s: encode_Delete_Payload: invalid %s\n",
			__FILE__, __LINE__, $key);
		exit(1);
		# NOTREACHED
	}
	my $reserved = $packet->{$key};

	$key = 'DOI';
	unless (defined($packet->{$key})) {
		printf("dbg: %s: %s: encode_Delete_Payload: invalid %s\n",
			__FILE__, __LINE__, $key);
		exit(1);
		# NOTREACHED
	}
	my $doi = defined($packet->{$key}) ? $packet->{$key} : 1;

	$key = 'Protocol-Id';
	unless (defined($packet->{$key})) {
		printf("dbg: %s: %s: encode_Delete_Payload: invalid %s\n",
			__FILE__, __LINE__, $key);
		exit(1);
		# NOTREACHED
	}
	my $protocol_id = $packet->{$key};

	$key = 'SPI Size';
	unless (defined($packet->{$key})) {
		printf("dbg: %s: %s: encode_Delete_Payload: invalid %s\n",
			__FILE__, __LINE__, $key);
		exit(1);
		# NOTREACHED
	}
	my $spi_size = $packet->{$key};

	$key = '# of SPIs';
	unless (defined($packet->{$key})) {
		printf("dbg: %s: %s: encode_Delete_Payload: invalid %s\n",
			__FILE__, __LINE__, $key);
		exit(1);
		# NOTREACHED
	}
	my $num_of_spis = $packet->{$key};

	$key = 'SPIs';
	unless (defined($packet->{$key})) {
		printf("dbg: %s: %s: encode_Delete_Payload: invalid %s\n",
			__FILE__, __LINE__, $key);
		exit(1);
		# NOTREACHED
	}
	my $spis = '';
	foreach my $spi (@{$packet->{$key}}) {
		$spis = pack('H*', $spi);
	}

	$key = 'Payload Length';
	my $length = ($packet->{$key} eq 'auto') ? 12 + length($spis) : $packet->{$key};

	$result = pack('C C n N C C n',
		       $next_payload,
		       $reserved,
		       $length,
		       $doi,
		       $protocol_id,
		       $spi_size,
		       $num_of_spis
		      );
	$result .= $spis;

	return($result);
}

#
sub encode_Unrecognized_Payload($)
{
	my ($packet) = @_;

	my $key = undef;
	my $result = undef;

	$key = 'NextPayload';
	unless (defined($packet->{$key})) {
		printf("dbg: %s: %s: encode_Unrecognized_Payload: invalid %s\n",
			__FILE__, __LINE__, $key);
		exit(1);
		# NOTREACHED
	}
	my $next_payload = $packet->{$key};

	$key = 'RESERVED';
	unless (defined($packet->{$key})) {
		printf("dbg: %s: %s: encode_Delete_Payload: invalid %s\n",
			__FILE__, __LINE__, $key);
		exit(1);
		# NOTREACHED
	}
	my $reserved = $packet->{$key};

	$key = 'Payload Length';
	my $length = ($packet->{$key} eq 'auto') ? 4 : $packet->{$key};

	$result = pack('C C n',
		       $next_payload,
		       $reserved,
		       $length);

	return($result);
}


#----------------------------------------------------------------------#
# decode subroutines                                                   #
#----------------------------------------------------------------------#



1;

