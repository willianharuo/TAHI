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
# $Id: AES_XCBC.pm,v 1.3 2008/06/03 07:39:58 akisada Exp $
#

package kCrypt::AES_XCBC;

use vars qw($VERSION) ;
use Exporter;

our @ISA = qw(Exporter);
our @EXPORT = qw(
	aes_xcbc_mac_96
	aes_xcbc_prf_128
);

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

# subroutines
sub aes_xcbc_mac_96($$);
sub aes_xcbc_prf_128($$);
sub _aes_xcbc($$);

sub aes_xcbc_mac_96($$)
{
	my ($key, $message) = @_;
	#   (5)  The authenticator value is the leftmost 96 bits of the 128-bit
	#        E[n].
	return(substr(_aes_xcbc($key, $message), 0, 12));
}

sub aes_xcbc_prf_128($$)
{
	my ($key, $message) = @_;
	return(_aes_xcbc($key, $message));
}

sub _aes_xcbc($$)
{
	my ($key, $message) = @_;

	my $result = undef;
	my $blocksize = BLOCKSIZE / 8;

	#   (1)  Derive 3 128-bit keys (K1, K2 and K3) from the 128-bit secret
	#        key K, as follows:
	#        K1 = 0x01010101010101010101010101010101 encrypted with Key K
	#        K2 = 0x02020202020202020202020202020202 encrypted with Key K
	#        K3 = 0x03030303030303030303030303030303 encrypted with Key K
	my $k1	= '01010101010101010101010101010101';
	my $k2	= '02020202020202020202020202020202';
	my $k3	= '03030303030303030303030303030303';
	$k1	= pack('H*', $k1);
	$k2	= pack('H*', $k2);
	$k3	= pack('H*', $k3);

	my $cipher_secret = Crypt::Rijndael->new($key, Crypt::Rijndael::MODE_CBC());
	$k1 = $cipher_secret->encrypt($k1);
	$k2 = $cipher_secret->encrypt($k2);
	$k3 = $cipher_secret->encrypt($k3);
	my $cipher_k1 = Crypt::Rijndael->new($k1, Crypt::Rijndael::MODE_CBC());

	#   (2)  Define E[0] = 0x00000000000000000000000000000000
	my $e = pack('H*', '00000000000000000000000000000000');

	#   (3)  For each block M[i], where i = 1 ... n-1:
	#        XOR M[i] with E[i-1], then encrypt the result with Key K1,
	#        yielding E[i].
	my $m = $message;
	for (my $i = 0; ; $i++) {
		if (length($m) < $blocksize + 1) {
			last;
		}

		my $mi = substr($m, 0, $blocksize);
		$m = substr($m, $blocksize);

		$e = $mi ^ $e;
		$e = $cipher_k1->encrypt($e);
	}

	#   (4)  For block M[n]:
	if (length($m) == $blocksize) {
		#      a)  If the blocksize of M[n] is 128 bits:
		#          XOR M[n] with E[n-1] and Key K2, then encrypt the result with
		#          Key K1, yielding E[n].
		$m = $m ^ $e ^ $k2;
		$result = $cipher_k1->encrypt($m);
	}
	else {
		#      b)  If the blocksize of M[n] is less than 128 bits:
		#
		#         i)  Pad M[n] with a single "1" bit, followed by the number of
		#             "0" bits (possibly none) required to increase M[n]'s
		#             blocksize to 128 bits.
		$m .= pack('H*', '80');
		my $pad = pack('H*', '00');
		my $len = length($m);
		for (my $i = $len; $i < $blocksize; $i++) {
			$m .= $pad;
		}

		#         ii) XOR M[n] with E[n-1] and Key K3, then encrypt the result
		#             with Key K1, yielding E[n].

		$m = $m ^ $e ^ $k3;
		$result = $cipher_k1->encrypt($m);
	}

	return($result);
}

1;
__END__









