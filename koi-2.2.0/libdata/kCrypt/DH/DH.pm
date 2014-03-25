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
# $Id: DH.pm,v 1.3 2008/06/03 07:39:59 akisada Exp $
#

package kCrypt::DH;

use vars qw($VERSION) ;

BEGIN {
	$VERSION = 0.01;

	no strict refs;
	for my $func (qw( p g pub_key priv_key prime_len )) {
		*$func = sub {
			my $key = shift;
			if (@_) {
				$key->{$func} = _any2bigint(shift);
			}
			my $ret = $key->{$func} || "";
			$ret;
		};
	}
}

END {
	undef $VERSION;
}

use strict;
use warnings;
use Math::BigInt;

use Exporter;
*import = \&Exporter::import;
our @ISA = qw(Exporter);


our $VERSION;

eval {
	require XSLoader;
	XSLoader::load('kCrypt::DH', $VERSION);
};

if ($@) {
	print STDERR "DH.pm: $@\n";
	return(0);
}

sub new
{
	my $self = shift;
	my $dh = bless {}, $self;

	my %param = @_;
	for my $elem (qw( p g pub_key priv_key prime_len)) {
		$dh->$elem('') unless exists $param{$elem};
		$dh->$elem(delete $param{$elem});
	}
	die "Unknown parameters to constructor: " . join(", ", keys(%param)) if %param;
	$dh;
}

sub generate_keys()
{
	my $dh = shift;

	inline_generate_key($dh);
	$dh->pub_key($dh->pub_key);
	$dh;
}

sub compute_secret($)
{
	my $dh = shift;
	my $pub_key = shift;
	my $secret = '';

	inline_compute_key($secret, $pub_key->bstr, $dh);
	return(Math::BigInt->new($secret));
}

sub compute_key($)
{
	my $dh = shift;
	my $pub_key = shift;
	my $secret = '';

	inline_compute_key($secret, $pub_key->bstr, $dh);
	return(Math::BigInt->new($secret));
}

sub _any2bigint
{
	my($value) = @_;
	if (ref $value eq 'Math::BigInt') {
		return $value;
	} elsif (ref $value eq 'Math::Pari') {
		return Math::BigInt->new(Math::Pari::pari2pv($value));
	} elsif (defined $value && !(ref $value)) {
		return Math::BigInt->new($value);
	} elsif (defined $value) {
		die "Unknown parameter type: $value\n";
	}
}

1;

