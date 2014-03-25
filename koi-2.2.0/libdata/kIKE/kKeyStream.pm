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
# $TAHI: koi/libdata/kIKE/kKeyStream.pm,v 0.1 2007/07/11 16:26:00 pierrick Exp $
#
# $Id: kKeyStream.pm,v 1.4 2008/06/03 07:40:00 akisada Exp $
#
########################################################################

package kIKE::kKeyStream;

use strict;
use warnings;
use kIKE::kConsts;

=pod

=head1 NAME

kIKE::kKeyStream - A key generator for IKEv2 called C<prf+> in section 2.13 of RFC4306.

=head1 SYNOPSIS

 use kIKE::kKeyStream;
 my $keyStream = kIKE::kKeyStream->new(&myPrf, $myKey, $myData);
 
 my $algKey = $keyStream->readKey($alg);
 my $algKey2 = $keyStream->readKey($alg2, %algAttributes);

=head1 HOW IT WORKS

The C<prf+> function is defined by these expressions:

 prf+(K, S) = T1 | T2 | T3 | ...
 T1 = prf(K, S | 0x01)
 T2 = prf(K, T1 | S | 0x02)
 ...
 T<n> = prf(K, T<n - 1> | S | <n>)

Where B<K> is some key for the prf, B<S> is some data for the prf, I<n> is an integer
between 2 and 255 inclusives.

The keys are extracted from this stream as if it is a continius stream, there are
no boundaries.

=head1 METHODS

After initialisation, this object provide a method to read a key. You just have to
say the name of the encryption algorithm and its eventual attributes and it tries
to determine the length of the key and extract it.

=cut

=pod

=head2 new()

Initialises a new kIKE::kKeyStream instance.

=head3 Parameters

=over

=item B<pseudo-random function>

The reference to the pseudo-random function to use. Its paremeters should be in
the form: key, data. And they must be binary strings.

=item B<K>

The prf Key. Used as is. It is a binary string.

=item B<S>

The prf data. It isn't used as is, see L</HOW IT WORKS>. It is a binary string.

=back

=head3 Return value

The created object.

=cut

sub new($\&$$) {
	# Get classname.
    my $class = shift;
    # Create the object.
    my $stream = bless {}, $class;
    # Fill the object with parameters and initial values.
    $stream->{prf} = shift;#params: key, data
    $stream->{K} = shift;
    $stream->{S} = shift;
    $stream->{block} = '';
    $stream->{number} = 0;
    $stream->{'last'} = '';
    # Return the object.
    return $stream;
};

=pod

=head2 _readBlock()

Reads a block in the generating stream.

B<This function is not intended to be called by any programs outside the
library. The user MUST call L</ReadKey()>.>

=head3 Parameters

=over

=item B<Size>

Block size in bytes.

=back

=head3 Return value

=over

=item B<Block>

The readed block.

=back

=cut

sub _readBlock($$) {
	# Get the stream object.
	my $stream = shift;
	# Get the neaded size in bytes.
	my $size = shift;
	# Fill the buffer while there is not enough data to get the required size.
	until ($size <= length($stream->{block})) {
		# Increments the block number.
		$stream->{number}++;
		# Generate the block.
		my $newblock = &{$stream->{prf}}($stream->{K}, $stream->{'last'} . $stream->{S} . chr($stream->{number}));
		# Save and append the generated block.
		$stream->{'last'} = $newblock;
		$stream->{block} .= $newblock;
	}
	# Extract the requested block from the buffer.
	my $readed = substr($stream->{block}, 0, $size);
	$stream->{block} = substr($stream->{block}, $size);
	# Return the extracted block.
	return $readed;
}

=pod

=head2 readKey()

Read a key from the generated stream.
Can die.

=head3 Parameters

=over

=item Algorithm

Algorithm name, as defined by RFC4306 section 3.3.2 without the transform type prefix.

=item Attributes (optional)

A hash containing the pairs (type, value) of IKEv2 SA Attributes. It can be
empty if the algorithm doesn't need it.

=back

=head3 Return value

The generated key as a binary string.

=cut

sub readKey($$;\%) {
	my ($stream, $alg, $ref) = @_;

	# Get the available exp_keylen for the algorithm.
	my $exp_keylen = kIKE::kConsts::kKeySize($alg);
	my $proposal_keylen = undef;
	# Check if there are multiple solutions.
	if (ref($exp_keylen) eq 'ARRAY') {
		foreach my $elm (@{$ref}) {
			if ($elm->{'type'} eq 'Key Length') {
				$proposal_keylen = $elm->{'value'};
				if ($alg eq 'AES_CTR') {
					$proposal_keylen += 32;	# nonce for counter block
				}
			}
		}
	}
	else {
		$proposal_keylen = $exp_keylen;
	}
	# Extract and return the requested block.
	return $stream->_readBlock($proposal_keylen / 8);
}

=pod

=head1 SEE ALSO

Use RFC4306 as reference to understand the meaning of the defined values and used algorithm.

=head1 AUTHOR

Pierrick Caillon, <pierrick@64translator.com>, from tahi project.

=cut

1;
