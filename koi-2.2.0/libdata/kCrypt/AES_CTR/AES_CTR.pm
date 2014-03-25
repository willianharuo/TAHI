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
# $Id: AES_CTR.pm,v 1.3 2008/06/03 07:39:58 akisada Exp $
#

package kCrypt::AES_CTR;

use vars qw($VERSION) ;
require Exporter;

@ISA = qw(Exporter);

@EXPORT = qw();

BEGIN {
	$VERSION = 0.01;
}

END {
	undef $VERSION;
}

use strict;
use warnings;

use Crypt::Rijndael;
use constant {
	BLOCKSIZE => 128,
};

#      CTRBLK := NONCE || IV || ONE
#      FOR i := 1 to n-1 DO
#        CT[i] := PT[i] XOR AES(CTRBLK)
#        CTRBLK := CTRBLK + 1
#      END
#      CT[n] := PT[n] XOR TRUNC(AES(CTRBLK))

sub new($$$$) {
	my ($proto, $key, $nonce, $iv) = @_;
	my $class = ref($proto) || $proto;
	my $self = {};

	$self->{'algo'} = Crypt::Rijndael->new($key, Crypt::Rijndael::MODE_CBC());

	# set key
	$self->{'key'} = $key;

	# set blocksize
	$self->{'blocksize'} = BLOCKSIZE / 8;

	# set nonce
	$self->{'nonce'} = pack('H*', substr(unpack('H*', $nonce), 0, 8));

	# set iv
	$self->{'iv'} = pack('H*', substr(unpack('H*', $iv), 0, 16));

	# initialize counter
	my $c = 1;
	$self->{'counter'} = init_counter();

	bless ($self, $class);
	return($self);
}

sub init_counter() {
	my $c = 1;
	return(pack('N', $c));
}


sub encrypt($$) {
	my ($self, $string) = @_;
	return(_encrypt($self, $string));
}

sub decrypt($$) {
	my ($self, $string) = @_;
	return(_encrypt($self, $string));
}

sub reset($) {
	my $self = shift;
	$self->{'counter'} = _reginit();
}

sub bencrypt($$) {
	my ($self, $block) = @_;

	my $ctrblk = make_ctrblk($self);
	my $aes_ctrblk = $self->{'algo'}->encrypt($ctrblk);

	if (length($block) < length($aes_ctrblk)) {
		$aes_ctrblk = substr($aes_ctrblk, 0, (length $block));
	}

	my $out = $block ^ $aes_ctrblk;
	increment_counter($self);

	return($out);
}

sub _encrypt($$) {
	my ($self, $string) = @_;

	my $out = undef;
	my $len = length($string);
	for (my $i = 0; $i < $len; $i += $self->{'blocksize'}) {
		$out .=  bencrypt($self, substr($string, $i, $self->{'blocksize'}));
	}

	return($out);
}

sub increment_counter($) {
	my $self = shift;
	my $c = unpack('N', $self->{'counter'});
	$c++;
	$self->{'counter'} = pack('N', $c);
}

sub make_ctrblk($) {
	my $self = shift;
	my $ctrblk = $self->{'nonce'} . $self->{'iv'} . $self->{'counter'};
	return($ctrblk);
}

1;

__END__

