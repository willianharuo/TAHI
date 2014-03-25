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
# $TAHI: koi/libdata/kIKE/kHelpers.pm,v 0.1 2007/07/31 09:01:00 pierrick Exp $
#
# $Id: kHelpers.pm,v 1.3 2008/06/03 07:39:59 akisada Exp $
#
########################################################################

package kIKE::kHelpers;

use strict;
use warnings;
use Exporter;
use Socket;
use Socket6;

our @ISA = qw(Exporter);

our @EXPORT = qw (
	formatHex
	hexDump
	showData
	rebuildStructure
	cloneStructure
	ipaddr_tobin
	ipv6addr_tostr
	ipv4addr_tostr
	get_payload
	as_hex2
);

our $TRUE = $kIKE::kConsts::TRUE;
our $FALSE = $kIKE::kConsts::FALSE;

=pod

=head1 NAME

kIKE::kHelpers - Some helper functions.

=head1 SYNOPSIS

 use kIKE::kHelpers;
 push @ISA, 'kIKE::kHelpers';

=head1 METHODS

The subs in this package provide some functions for helping devlopment.

=cut

##############
# Prototypes #
##############

sub formatHex($);
sub hexDump($);
sub showData($;$$);
sub rebuildStructure($);
sub cloneStructure($);
sub ipaddr_tobin($);
sub ipv6addr_tostr($);
sub ipv4addr_tostr($);
sub get_payload($$);
sub as_hex2($$);

########
# Data #
########

## Regular expressions for formatHex.
##
# Match group of 64 hex digits (32 bytes) for adding new line characters.
my $reHexLineGroup = qr/([0-9A-Z]{64})/ios;
# Match the two last hex digits groups, after applying the tranformation associated with reHexLineGroup.
# It is for adding the last missing new line character.
my $reHexLineGroup2 = qr/(\n[0-9A-Z]{64})([0-9A-Z]{2,64})$/ios;
# Match group of 8 hex digits (4 bytes) for adding white spaces to separate. Not done before a new line.
my $reHexGroup = qr/([0-9A-Z]{8})(?!$)/ios;

###################
# Implementations #
###################

=pod

=head2 formatHex()

Transform the passed hex string to be a little more readable. It separates digits
by group of 8 (4 bytes) and add a line break before every 64 digits (32 bytes).
The last group of digits (remaining of 64 digits), is threated as a whole group.

=head3 Parameters

=over

=item B<Hex string>

The hex string to tranform. If it is not a full hex string, the beheviour is undefined.

=back

=head3 Return value.

=over

=item B<Hex string>

The resultant formatted hex string.

=back

=head3 Example

Instruction:

 print formatHex('AE54F67DEC312EAF900075BCDA6475DEFFAB835477612EFABC89000876');

Outputs:

 AE54F67D EC312EAF 900075BC DA6475DE
 FFAB8354 77612EFA BC890008 76

=cut	

sub formatHex($) {
	# Get the string to format.
	my $hex_data = shift;
	# Applying addition of new line characters.
	$hex_data =~ s/$reHexLineGroup/\n$1/g;
	# Applying addition of a new line character when the last group isn't complete.
	$hex_data =~ s/$reHexLineGroup2/$1\n$2/g;
	# Applying the 32bits separation of hex digits.
	$hex_data =~ s/$reHexGroup/$1 /g;
	# Return the resultant value.
	return $hex_data;
}

=pod

=head2 hexDump()

Print an hex dump to screen. It prints a dump header every 256 bytes and rows of
16 bytes.
Headers include a line break before and every dump lines include a line break after.

=head3 Parameters

=over

=item B<Binary data>

The binary data to dump.

=back

=head3 Return value

No return value.

=cut

sub hexDump($) {
	# Get the binary data.
	my $data = shift;
	# Process each characters.
	for (my $i = 0; $i < length($data);) {
		# Show block header every 256 bytes (16 lines).
		if (($i % 256) == 0) {
			printf("\n       /0 /1 /2 /3 /4 /5 /6 /7 - /8 /9/ A /B /C /D /E /F   0123456789ABCDEF\n");
		}
		# Show the current line position.
		printf("%04X :", $i);
		# Initialize hex and binary view.
		my $lhs = "";
		my $rhs = "";
		# Extract the next 16 bytes maximum.
		my $buf = substr($data, $i, 16);
		# Process each characters in the buffer.
		foreach my $k ($buf =~ m/./gs) 	{
			# Add a separation in the hex string after 8 characters.
			if (($i % 16) == 8) {
				$lhs .= ' -';
			}
		    # Add the hex value of the character to the hex string.
		    $lhs .= sprintf(" %02X", ord($k));
			# Add the binary value to the binary string. Control code and extended values are replaced by dots.
		    if ($k =~ m/[ -~]/)
		    {
		        $rhs .= $k;
		    }
		    else
		    {
		        $rhs .= ".";
		    }
		    # Increment the position in the data.
		    $i++;
		}
		# Show the generated line.
		printf("%-52s %s\n", $lhs, $rhs);
	}
}

=pod

=head2 showHashData()

Dumps of hash data. Calls L</showData()> to recursively dump the structure.

B<This function is not intended to be called by any programs outside the
library. Please use L</showData()> instead.>

=head3 Parameters

=over

=item B<Hash>

A reference to the hash to show.

=item B<Indent>

The indentation text to show before the entry's data.

=back

=head3 Return value

No return value.

=cut

sub showHashData($;$) {
	# Get the hash.
	my %hash = %{shift()};
	# Get identation.
	my $indent = shift;
	# Process all keys to be shown.
	foreach my $key (keys %hash) {
		showData($hash{$key}, $indent, $key . ' => ');
	}
}


=pod

=head2 showArrayData()

Dumps of array data. Calls L</showData()> to recursively dump the structure.

B<This function is not intended to be called by any programs outside the
library. Please use L</showData()> instead.>

=head3 Parameters

=over

=item B<Array>

A reference to the array to show.

=item B<Indent>

The indentation text to show before the entry's data.

=back

=head3 Return value

No return value.

=cut

sub showArrayData($;$) {
	# Get the array.
	my @list = @{shift()};
	# Get indentation.
	my $indent = shift;
	# Process each array entry to be shown, ignoring non existant.
	for(my $i = 0; $i < scalar(@list); ++$i) {
		showData($list[$i], $indent, $i . ": ") unless exists $list[$i];
	}
}

=pod

=head2 showObjectData()

Dumps of object data. Calls L</showData()> to recursively dump the structure.

B<This function is not intended to be called by any programs outside the
library. Please use L</showData()> instead.>

=head3 Parameters

=over

=item B<Array>

The object to show.

=item B<Indent>

The indentation text to show before the entry's data.

=back

=head3 Return value

No return value.

=cut

sub showObjectData($;$) {
	# Get the object.
	my $obj = shift;
	# Get indentation.
	my $indent = shift;
	# Process each values in the object to be shown.
	foreach my $key (keys %{$obj}) {
		showData($obj->{$key}, $indent, $key . ' => ');
	}
}

=pod

=head2 showData()

Dumps a data structure to the screen. It must not have circular dependancy. The
output is human readable. All the types are recognized.
This method use recusive calls.

The data for CODE, GLOB and LVALUE isn't read. only recognition is shown.

=head3 Parameters

=over

=item B<Value>

The value to dump. Must be a reference for arrays and hash.

=item B<Indent>

The identation level. It use tabs for indentation.

=item B<Value prefix>

A string to show in front of the dumped value.

=back

=head3 Return value

No return value.

=cut

sub showData($;$$) {
	# Get the value.
	my $value = shift;
	# Get indentation.
	my $indent = shift;
	$indent = '' unless $indent;
	# Get prefix fior entries.
	my $valPre = shift;
	$valPre = '' unless $valPre;
	# NB: All values are prefixed with indentation and prefix.
	# Select the type of the value.
	if (not defined $value) { # Not defined.
		# Show undef.
		print $indent . $valPre . 'undef' . "\n";
	}
	elsif (ref $value eq 'HASH') { # A hash.
		# Show the hash enclosed by braces.
		print $indent . $valPre . "{\n";
		showHashData($value, $indent . '	');
		print $indent . "}\n";
	}
	elsif (ref $value eq 'ARRAY') { # An array.
		# Show the array enclosed by square brackets.
		print $indent . $valPre . "[\n";
		showArrayData($value, $indent . '	');
		print $indent . "]\n";
	}
	elsif (ref $value eq 'Math::BigInt') { # A bigint object.
		# Show the hex string representing the object.
		print $indent . $valPre . '(BigInt)' . formatHex(uc(substr($value->as_hex, 2))) . "\n";
	}
	elsif (ref $value eq 'SCALAR') { # A scalar.
		# Call itself with dereference of the SCALAR, adding 'ref ' to the prefix.
		showData($$value, $indent, $valPre . 'ref ');
	}
	elsif (ref $value eq 'CODE') { # A function.
		# Show a dummy text indicating the function.
		print $indent . $valPre . '(some code)' . "\n";
	}
	elsif (ref $value eq 'REF') { # A reference.
		# Call itself with dereference of the REF, adding 'ref ' to the prefix.
		showData($$value, $indent, $valPre . 'ref ');
	}
	elsif (ref $value eq 'GLOB') { # A glob.
		# Show a dummy text indicating the glob.
		print $indent . $valPre . '(symbol table entry)' . "\n";
	}
	elsif (ref $value eq 'LVALUE') { # A lvalue.
		# Show a dummy text indicating the lvalue.
		print $indent . $valPre . '(lvalue)' . "\n";
	}
	elsif (ref $value ne '') { # Any object.
		# Show the object enclosed by braces.
		print $indent . $valPre . (ref $value) . "{\n";
		showObjectData($value, $indent . '	');
		print $indent . "}\n";
	}
	else { # A value.
		# Show the value if it contains neither control code nor extended characters.
		if ($value =~ m/^[\t\n\r -~]*$/i) {
			print $indent . $valPre . $value . "\n";
		}
		else {
			# Show the formatted hex string for the binary value if less than or equal to 8 bytes long.
			print $indent . $valPre . formatHex(uc(unpack('H*', $value))) . "\n"
				if length($value) <= 8;
			# Show the hex dump of the binary value if more than 8 bytes long.
			do {
				print $indent . $valPre;
				hexDump($value);
				print "\n"
			} if length($value) > 8;
		}
	}
}

=pod

=head2 rebuildStructure()

Rebuild some structure composed of hash and tables to remove every undefined keys.
Doesn't overwrite the existing structure. Other data are kept as this. Multiple
reference levels are deencapsulated to be rebuild. The final data is the same
as the original without undefined keys.

=head3 Parameters

=over

=item B<Value>

The data structure to be rebuild. If you want to pass an array or a hash, it must
be passed as reference.

=back

=head3 Return value

=over

=item B<Rebuilt Value>

The rebuild value in the same type as the source.

=back

=cut

sub rebuildStructure($) {
	# Get the value.
	my $value = shift;
	# Select the type of the value.
	if (not defined $value) { # Not defined.
		return;
	}
	elsif (!(ref $value)) {
		return $value;
	}
	elsif (ref $value eq 'HASH') { # A hash.
		# Recreate the hash skipping undefined keys.
		my $rebuilded = {};
		foreach my $key (keys %{$value}) {
			next unless defined $value->{$key};
			# Recreate the value associated to the key.
			$rebuilded->{$key} = rebuildStructure($value->{$key});
		}
		# Return recreated hash.
		return $rebuilded;
	}
	elsif (ref $value eq 'ARRAY') { # An array.
		# Recreate the array skipping undefined entries.
		my $array = [];
		my $count = scalar(@{$value});
		for (my $i = 0; $i < $count; $i++) {
			next unless defined $value->[$i];
			# Recreate the value associated to the index.
			$array->[$i] = rebuildStructure($value->[$i]);
		}
		# Return the recreated array.
		return $array;
	}
	elsif (ref $value eq 'REF') { # A reference.
		# Rebuild the dereferenced value of the reference.
		my $deref = rebuildStructure($$value);
		# Return a reference to the rebuilded value.
		return \$deref;
	}
	elsif ((ref $value ne 'SCALAR') && (ref $value ne 'CODE') &&
		   (ref $value ne 'GLOB') && (ref $value ne 'LVALUE')) { # Any object.
		# Recreate the object, not skipping undefined entries.
		my $rebuilded = {};
		foreach my $key (keys %{$value}) {
			# Rebuild the value associated to the key.
			$rebuilded->{$key} = rebuildStructure($value->{$key});
		}
		# Mark the hash as an object.
		bless $rebuilded, ref $value;
		# Return the rebuilded object.
		return $rebuilded;
	}
	else { # Anything else
		# Return as is. (It will mainly be scalars or special type.)
		return $value;
	}
}


=pod

=head2 cloneStructure()

Clone some structure composed of hash and tables.

=head3 Parameters

=over

=item B<Value>

The data structure to be duplicated. If you want to pass an array or a hash, it must
be passed as reference.

=back

=head3 Return value

=over

=item B<Duplicated Value>

The duplicated value in the same type as the source.

=back

=cut

sub cloneStructure($) {
	# Get the value.
	my $value = shift;
	# Select the type of the value.
	if (not defined $value) { # Not defined.
		return;
	}
	elsif (!(ref $value)) {
		return $value;
	}
	elsif (ref $value eq 'HASH') { # A hash.
		# Create a new hash containing the same data.
		my $rebuilded = {};
		foreach my $key (keys %{$value}) {
			# Clone the value associated to the key.
			$rebuilded->{$key} = cloneStructure($value->{$key});
		}
		# Return the clone.
		return $rebuilded;
	}
	elsif (ref $value eq 'ARRAY') { # An array.
		# Create a new array containing the same data.
		my $array = [];
		my $count = scalar(@{$value});
		for (my $i = 0; $i < $count; $i++) {
			# Clone the value associated to the index.
			$array->[$i] = cloneStructure($value->[$i]);
		}
		# Return the clone.
		return $array;
	}
	elsif (ref $value eq 'REF') { # A reference.
		# Create a clone of the dereferenced value.
		my $deref = cloneStructure($$value);
		# Return a referenceto the clone.
		return \$deref;
	}
	elsif ((ref $value ne 'SCALAR') && (ref $value ne 'CODE') &&
		   (ref $value ne 'GLOB') && (ref $value ne 'LVALUE')) { # Any object.
		# Create a copy of the object.
		my $rebuilded = {};
		foreach my $key (keys %{$value}) {
			# Clone the value associated to the key.
			$rebuilded->{$key} = cloneStructure($value->{$key});
		}
		# Mark the hash as an object.
		bless $rebuilded, ref $value;
		# Return the cloned object.
		return $rebuilded;
	}
	else { # Any other value.
		# Return as is.
		return $value;
	}
}


sub ipaddr_tobin($)
{
	my ($address) = @_;

	my $serv = '500';
	my $family = AF_UNSPEC;
	my $socktype = SOCK_DGRAM;
	my $protocol = 0;
	my $flags = AI_NUMERICHOST | AI_NUMERICSERV;
	my @res = getaddrinfo($address, $serv, $family, $socktype, $protocol, $flags);
	while (scalar(@res) >= 5) {
		my ($family, $socktype, $proto, $saddr, $canonname) = splice @res, 0, 5;

		my $addr = undef;
		my $port = undef;

		if ($family == AF_INET) {
			($port, $addr) = unpack_sockaddr_in($saddr);
		}
		elsif ($family == AF_INET6) {
			($port, $addr) = unpack_sockaddr_in6($saddr);
		}
		else {
			next;
		}

		return($addr);
	}

	return(undef);
}


sub ipv6addr_tostr($) {
	my ($address) = @_;

	return(inet_ntop(AF_INET6, $address));
}


sub ipv4addr_tostr($) {
	my ($address) = @_;

	return(inet_ntop(AF_INET, $address));
}


sub get_payload($$) {
	my ($payloads, $payload_type) = @_;

	if ($payload_type eq 'HDR') {
		return($payloads->[0]);
	}

	my $nexttype = '';
	foreach my $payload (@{$payloads}) {
		if ($nexttype eq $payload_type) {
			return($payload);
		}

		if ($nexttype eq 'E') {
			my $e = undef;
			$e = {%{$payload}};
			$e->{nexttype} = $e->{innerType};
			unshift(@{$payload->{innerPayloads}}, $e);
			my $p = get_payload($payload->{innerPayloads}, $payload_type);
			shift(@{$payload->{innerPayloads}});
			return($p) if (defined($p));
		}
		$nexttype = $payload->{nexttype};
	}
	return(undef);
}


# 
sub as_hex2($$)
{
	my ($bn, $length) = @_;

	my $value = substr($bn->as_hex, 2);
	my $len = length($value);
	while ($len++ < $length) {
		$value = '0' . $value;
	}
	return($value);
}



=pod

=head1 SEE ALSO

(Nothing to see)

=head1 AUTHOR

Pierrick Caillon, <pierrick@64translator.com>, from tahi project.

=cut

1;
