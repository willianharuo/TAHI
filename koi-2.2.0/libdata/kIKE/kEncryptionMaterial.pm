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
# $TAHI: koi/libdata/kIKE/kEncryptionMaterial.pm,v 0.1 2007/07/12 16:26:00 pierrick Exp $
#
# $Id: kEncryptionMaterial.pm,v 1.4 2008/06/03 07:39:59 akisada Exp $
#
########################################################################

package kIKE::kEncryptionMaterial;

use strict;
use warnings;
use kIKE::kConsts;

=pod

=head1 NAME

kIKE::kEncryptionMaterial - An object proving some methods to help to use encryption.

=head1 SYNOPSIS

 use kIKE::kEncryptionMaterial;
 use kIKE::kKeyStream;
 my $keyStream = kIKE::kKeyStream->new($myKey, $myData, &myPrf);
 my $material = kIKE::kEncryptionMaterial();
 
 $material->encr(&myEncr);
 $material->prf(&myPrf);
 $material->integ(&myInteg);
 
 $material->generateIKEMaterial($keyStream, $encrAlg, $prfAlg, $integAlg, %attributes);
 
 my $SK_d = $material->d;
 
 my $crypted = &{$material->encr}($material->ei, $message);

=head1 METHODS

After initialisation, this methods provide some helpers to generate keys from a
specific key-generating stream. You use the needed method to generate what you
need and you can access the generated keys.
You can also set at initialisation-time or after with the proper methods the
subs which will do encryption/decryption, calculate hash, or sign. These subs
can have the prototype you want but keep it mind to be consistent in your choices.
You'll may use anonymous subs to do the work.

=cut

=pod

=head2 new

Initialises a new kIKE::kKeyStream instance.

All the subs that can be passed as reference have no restriction on the prototype
as it is the user that will use these and not this script. It is provided for
convenience.

=head3 Parameters

These parameters are named. The name to use in calls are between parenthesis at
the end of the title line. They can be put in any order.

=over

=item Encryption function (C<encr>)

This is the encryption function that will be used to encrypt messages.

=item Decryption function (C<decr>)

This is the counterpart of the previous sub. It could be useless for some algorithms.

=item Pseudo-random function (C<prf>)

This is the pseudo-random function that will provide some fixed-length data from
a key and some data.

=item Integrity function (C<integ>)

This is the integrity function that will provide a way to compute a checksum.

=item Derivation key (C<d>)

This is the key used as a key to key generation script to derivate new keys from.
It is used only by IKE SA.

=item Initiator authentication (C<ai>)

This is the key used by initiator for its integrity calculation.

=item Responder authentication (C<ar>)

This is the key used by responder for its integrity calculation.

=item Initiator encryption (C<ei>)

This is the key used by initiator for its encryption.

=item Responder encryption (C<er>)

This is the key used by responder for its encryption.

=item Initiator AUTH payload prf key (C<pi>)

This is the key used by initiator for computing the MAC'ed part of the AUTH payload.

=item Responder AUTH payload prf key (C<pr>)

This is the key used by responder for computing the MAC'ed part of the AUTH payload.

=back

=head3 Return value

The created object

=cut

sub new {
	# Get classname.
	my $class = shift;
	# Create the object.
	my $em = bless {}, $class;
	# Initialize the object with the parameters.
	my %param = @_;
	for my $w (qw( encr decr prf integ d ai ar ei er pi pr encr_alg integ_alg prf_alg ni_ctr nr_ctr )) {
		next unless exists $param{$w};
		$em->$w(delete $param{$w});
	}
	die "Unknown parameters to constructor: " . join(", ", keys %param) if %param;
	# Return the object.
	return $em;
}

=pod

=head2 Accessors

The following items are methods used to define or obtain the described value.
The name of these methods are placed between parenthesis in the description title.
These take only one optional argument: the new value.
These always return the current value (after defining it if a new value is specified).
All keys are in binary form.

=over

=item Encryption function (C<encr>)

This is the encryption function that will be used to encrypt messages.

=item Decryption function (C<decr>)

This is the counterpart of the previous sub. It could be useless for some algorithms.

=item Pseudo-random function (C<prf>)

This is the pseudo-random function that will provide some fixed-length data from
a key and some data.

=item Integrity function (C<integ>)

This is the integrity function that will provide a way to compute a checksum.

=item Derivation key (C<d>)

This is the key used as a key to key generation script to derivate new keys from.
It is used only by IKE SA.

=item Initiator authentication (C<ai>)

This is the key used by initiator for its integrity calculation.

=item Responder authentication (C<ar>)

This is the key used by responder for its integrity calculation.

=item Initiator encryption (C<ei>)

This is the key used by initiator for its encryption.

=item Responder encryption (C<er>)

This is the key used by responder for its encryption.

=item Initiator AUTH payload prf key (C<pi>)

This is the key used by initiator for computing the MAC'ed part of the AUTH payload.

=item Responder AUTH payload prf key (C<pr>)

This is the key used by responder for computing the MAC'ed part of the AUTH payload.

=item Encryption block size (C<bencr>)

This is the block size of the encryption algorithm. (readonly)

=item Integrity block size (C<binteg>)

This is the block size of the integrity algorithm. (readonly)

=back

=cut

BEGIN {
    no strict 'refs';
	# This create the accessors for provided data.
    for my $meth (qw( encr decr prf integ d ai ar ei er pi pr encr_alg integ_alg prf_alg ni_ctr nr_ctr )) {
        *$meth = sub {
        		# Get the material object.
            my $em = shift;
            # Set the value if specified.
            if (@_) {
                $em->{$meth} = shift;
            }
            # Return the current value.
            $em->{$meth} || undef;
        };
    }
    # This create the accessors for constant data.
    for my $meth (qw( bencr binteg )) {
        *$meth = sub {
	        	# Get the material object.
            my $em = shift;
            # Return the value.
            $em->{$meth} || undef;
        };
    }
}

=pod

=head2 generateIKEMaterial()

Generates material for use with an IKE SA.

=head3 Parameters

=over

=item B<Key Stream>

It is the kIKE::kKeyStream to use to create the keys.

=item B<Encryption algorithm>

It is the name of the encryption algorithm as defined by RFC4306 section 3.3.2
without the C<ENCR_> prefix.

=item B<Pseudo-random function>

It is the name of the pseudo-random function as defined by RFC4306 section 3.3.2
without the C<PRF_> prefix.

=item B<Integrity algorithm>

It is the name of the integrity algorithm as defined by RFC4306 section 3.3.2
without the C<AUTH_> prefix.

=item B<Attributes association>

This is the hash of the hash of the IKEv2 SA Attribute type and value key pairs.
The main hash key is the name of the concerned item.

=back

=cut

sub generateIKEMaterial($$$$$\%) {
	# Read the parameters.
	my ($em, $stream, $encr, $prf, $integ, $associationRef) = @_;
	# Make the association hash valid.
	my %association = %{$associationRef};
	$association{$encr} = {} unless exists $association{$encr};
	$association{$integ} = {} unless exists $association{$integ};
	$association{$prf} = {} unless exists $association{$prf};

	# Extract all the keys.
	$em->d($stream->readKey($prf, $association{$prf}));

	$em->ai($stream->readKey($integ, $association{$integ}));
	$em->ar($stream->readKey($integ, $association{$integ}));

	$em->ei($stream->readKey($encr, $association{$encr}));
	if ($em->encr_alg eq 'AES_CTR') {
		$em->ni_ctr(substr($em->ei, 16, 4));
		$em->ei(substr($em->ei, 0, 16));
	}

	$em->er($stream->readKey($encr, $association{$encr}));
	if ($em->encr_alg eq 'AES_CTR') {
		$em->nr_ctr(substr($em->er, 16, 4));
		$em->er(substr($em->er, 0, 16));
	}

	$em->pi($stream->readKey($prf, $association{$prf}));
	$em->pr($stream->readKey($prf, $association{$prf}));

	printf("dbg ===> ai(%s, )\n", length($em->ai));
	printf("dbg ===> ar(%s, )\n", length($em->ar));
	printf("dbg ===> ei(%s, )\n", length($em->ei));
	printf("dbg ===> er(%s, )\n", length($em->er));
	printf("dbg ===> pi(%s, )\n", length($em->pi));
	printf("dbg ===> pr(%s, )\n", length($em->pr));

	# Define constants.
	$em->{bencr} = kIKE::kConsts::kBlockSize($encr);
	$em->{binteg} = kIKE::kConsts::kBlockSize($integ);
}

=pod

=head2 generateRekeyedIKEMaterial()

Generates material for use with a rekeyed IKE SA.

=head3 Parameters

=over

=item B<Key Stream>

It is the kIKE::kKeyStream to use to create the keys.

=item B<Encryption algorithm>

It is the name of the encryption algorithm as defined by RFC4306 section 3.3.2
without the C<ENCR_> prefix.

=item B<Pseudo-random function>

It is the name of the pseudo-random function as defined by RFC4306 section 3.3.2
without the C<PRF_> prefix.

=item B<Integrity algorithm>

It is the name of the integrity algorithm as defined by RFC4306 section 3.3.2
without the C<AUTH_> prefix.

=item B<Attributes association>

This is the hash of the hash of the IKEv2 SA Attribute type and value key pairs.
The main hash key is the name of the concerned item.

=back

=cut

sub generateRekeyedIKEMaterial($$$$$\%) {
	# Read the parameters.
	my ($em, $stream, $encr, $prf, $integ, $associationRef) = @_;
	# Make the association hash valid.
	my %association = %{$associationRef};
	$association{$encr} = {} unless exists $association{$encr};
	$association{$integ} = {} unless exists $association{$integ};
	$association{$prf} = {} unless exists $association{$prf};
	# Extract all the keys.
	$em->{d} = $stream->readKey($prf, $association{$prf});
	$em->{ai} = $stream->readKey($integ, $association{$integ});
	$em->{ar} = $stream->readKey($integ, $association{$integ});
	$em->{ei} = $stream->readKey($encr, $association{$encr});
	$em->{er} = $stream->readKey($encr, $association{$encr});
	# Define constants.
	$em->{bencr} = kIKE::kConsts::kBlockSize($encr);
	$em->{binteg} = kIKE::kConsts::kBlockSize($integ);
}

=pod

=head2 generateChildMaterial()

Generates material for use with a CHILD SA.

=head3 Parameters

=over

=item B<Key Stream>

It is the kIKE::kKeyStream to use to create the keys.

=item B<Encryption algorithm>

It is the name of the encryption algorithm as defined by RFC4306 section 3.3.2
without the C<ENCR_> prefix. Can be a value avaluating to false if the other algorithm
is specified.

=item B<Integrity algorithm>

It is the name of the integrity algorithm as defined by RFC4306 section 3.3.2
without the C<AUTH_> prefix. Can be a value avaluating to false if the other algorithm
is specified.

=item B<Attributes association>

This is the hash of the hash of the IKEv2 SA Attribute type and value key pairs.
The main hash key is the name of the concerned item.

=back

=cut

sub generateChildMaterial($$$$\%) {
	# Read the parameters.
	my ($em, $stream, $encr, $integ, $associationRef) = @_;
	my %association = %{$associationRef};

	if ($encr) {
		# Make the association hash entry valid.
		$association{$encr} = {} unless exists $association{$encr};
		# Extract encryption keys.
		$em->{ei} = $stream->readKey($encr, $association{$encr});
		# Define encryption constants.
		$em->{bencr} = kIKE::kConsts::kBlockSize($encr);
	}
	if ($integ) {
		# Make the association hash entry valid.
		$association{$integ} = {} unless exists $association{$integ};
		# Extract integrity keys.
		$em->{ai} = $stream->readKey($integ, $association{$integ});
		# Define integrity constants.
		$em->{binteg} = kIKE::kConsts::kBlockSize($integ);
	}
	if ($encr) {
		# Make the association hash entry valid.
		$association{$encr} = {} unless exists $association{$encr};
		# Extract encryption keys.
		$em->{er} = $stream->readKey($encr, $association{$encr});
		# Define encryption constants.
		$em->{bencr} = kIKE::kConsts::kBlockSize($encr);
	}
	if ($integ) {
		# Make the association hash entry valid.
		$association{$integ} = {} unless exists $association{$integ};
		# Extract integrity keys.
		$em->{ar} = $stream->readKey($integ, $association{$integ});
		# Define integrity constants.
		$em->{binteg} = kIKE::kConsts::kBlockSize($integ);
	}
}

=pod

=head2 generateRekeyedChildMaterial()

Generates material for use with a rekeyed CHILD SA.

=head3 Parameters

=over

=item B<Key Stream>

It is the kIKE::kKeyStream to use to create the keys.

=item B<Encryption algorithm>

It is the name of the encryption algorithm as defined by RFC4306 section 3.3.2
without the C<ENCR_> prefix. Can be a value avaluating to false if the other algorithm
is specified.

=item B<Integrity algorithm>

It is the name of the integrity algorithm as defined by RFC4306 section 3.3.2
without the C<AUTH_> prefix. Can be a value avaluating to false if the other algorithm
is specified.

=item B<Attributes association>

This is the hash of the hash of the IKEv2 SA Attribute type and value key pairs.
The main hash key is the name of the concerned item.

=back

=cut

sub generateRekeyedChildMaterial($$$$\%) {
	# Read the parameters.
	my ($em, $stream, $encr, $integ, $associationRef) = @_;
	my %association = %{$associationRef};
	# Call the generateChildMaterial function (equal code).
	$em->generateChildMaterial($stream, $encr, $integ, %association);
}

=pod

=head1 SEE ALSO

Use RFC4306 as reference to understand the meaning of the defined values and used algorithm.

=head1 AUTHOR

Pierrick Caillon, <pierrick@64translator.com>, from tahi project.

=cut

1;
