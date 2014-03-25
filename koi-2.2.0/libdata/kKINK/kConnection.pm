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
# $TAHI: devel-kink/koi/libdata/kKINK/kConnection.pm,v 1.2 2009/06/23 09:14:02 doo Exp $
#
# $Id: kConnection.pm,v 1.2 2010/07/22 13:23:57 velo Exp $
#
########################################################################

package kKINK::kConnection;

use strict;
use warnings;
use kCommon;

our $TRUE = $kKINK::kConsts::TRUE;
our $FALSE = $kKINK::kConsts::FALSE;

=pod

=head1 NAME

kKINK::kConnection - Connection object encapsulating initialisation and closing.

=head1 SYNOPSIS

 use kKINK::kConnection;

 $connection = kKINK::kConnection->new(
 	$interface,
 	$address_family,
 	$protocol,
 	$frameID,
 	$local_addr,
 	$local_port,
 	$remote_addr,
 	$remote_port);

 $ret = $connection->send($something, $something_length);

 $ret = $connection->recv();

 print $connection->timeout(20);

 $ret = $connection->close();

=head1 METHODS

After initialization, this object provide an easy to use wrapper to the methods
used to communicate by the network.

=cut

=pod

=head2 new()

Initialise a new kKINK::kConnection instance.

=head3 Parameters

=over

=item Interface

The network interface to use for the communication. It is one of the interface
defined in the KOI's configuration file for TN. It is like 'Link0', 'Link1', ...

=item Protocol

The transport layer protocol to use. It can be TCP, UDP or ICMP.

=item frameID

The kind of application protocol to use (special handling in KOI). It can be
NULL, DNS, SIP or IKEv2.

=item Local address & port

The local address and port to bind the connection. One or both can be undef if
the first operation will be a send. The port must be specified in other case.

=item Remote address & port

The remote address and port with which to establish the connexion. It is ignored
when the first operation is receiving and mandatory in the other case.

=item Timeout (optional; default to 12)

Timeout in seconds for the receive and close operations.

=back

=head3 Return value

The created object.

=cut

sub new($$$$$$$;$)
{
	my ($self, $interface, $af, $protocol, $frameID, $saddr, $sport, $daddr, $dport, $timeout) = @_;

	# Create the object.
	bless {
		'interface'	=> $interface,
		'address_family'=> $af,
		'protocol'	=> $protocol,
		'frameID'	=> $frameID,
		'local'		=> [$saddr, $sport],
		'remote'	=> [$daddr, $dport],
		'connected'	=> $FALSE,
		'socketID'	=> undef,
		'recvonly'	=> $FALSE,
		'timeout'	=> ((defined $timeout && $timeout =~ m/^[0-9]+$/) ? ($timeout) : (12))
	}, $self;
}

=pod

=head2 send()

Sends a message on a connection. It establishes the connection if needed.

=head3 Parameters

=over

=item Data

The data to be sent.

=item Data length

The length of the data to be sent.

=back

=head3 Return value

=over

=item Send results

The results of sending the message. It is undef in case of error. It contains the
following keys: Command, RequestNum, Result, DataID, TimeStamp, TimeStamp2.

=back

=cut

sub send($$$;$)
{
	my ($conn, $data, $datalen, $material) = @_;

	my $ret = undef;
	if ($conn->{'recvonly'}) {
		return($ret);
	}

	if ($conn->{'connected'}) {
		# register keying material
		#kIKE::kIKE::kRegisterKeyingMaterial($material);

		$ret = kPacket_Send($conn->{'socketID'}, $datalen, $data);
		if (defined($ret)) {
			undef $ret->{'SocketID'};
			#$ret = kIKE::kHelpers::rebuildStructure($ret);
		}

		# unregister keying material
		#kIKE::kIKE::kUnregisterKeyingMaterial();

		return($ret);
	}

	$ret = kPacket_ConnectSend(
		$conn->{'protocol'},		# protocol (TCP|UDP|ICMP)
		$conn->{'frameID'},		# frameid (NULL|DNS|SIP|IKEv2)
		$conn->{'address_family'},	# addrfamily (INET|INET6)
		$conn->{'local'}->[0],		# srcaddr [undef] 0.0.0.0 or :: is used
		$conn->{'remote'}->[0],		# dstaddr
		$conn->{'local'}->[1],		# srcport	[undef] 0 is used
		$conn->{'remote'}->[1],		# $dstport
		$datalen,			# $datalen
		$data,				# $data
		$conn->{'interface'}		# $interface (Link0|Link1|...)
						# flags
	);
	if (defined($ret)) {
		# Get SocketID and set the connection to established.
		$conn->{'socketID'} = $ret->{'SocketID'};
		$conn->{'connected'} = $TRUE;
		undef($ret->{'SocketID'});
		#$ret = kIKE::kHelpers::rebuildStructure($ret);
	}

	return($ret);
}

=pod

=head2 listen()

Prepares reception of a message from the network. It establishes the connection.
Only recv can be call after this call.

=head3 Parameters

No parameter.

=head3 Return value

=item Preparation results

The results of preparing reception of a message. It is undef in case of error. It contains
the following keys: Command, RequestNum, Result.

=back

=cut

sub listen($)
{
	my $conn = shift;
	my $ret = undef;

	unless ($conn->{'connected'}) {
		return($ret);
	}

	# Start to listen for messages.
	$ret = kPacket_StartRecv(
				$conn->{'protocol'}, 		# protocol (TCP|UDP|ICMP)
				$conn->{'frameID'},		# frameid (NULL|DNS|SIP|IKEv2)
				$conn->{'address_family'},	# addrfamily (INET|INET6)
				$conn->{'local'}->[0],		# srcaddr [undef] 0.0.0.0 or :: is used
				$conn->{'local'}->[1],		# srcport	[undef] 0 is used
				$conn->{'interface'}		# $interface (Link0|Link1|...)
								# flags
				);
	if (defined($ret)) {
		# Get SocketID and set the connection as established.
		$conn->{'socketID'} = $ret->{'SocketID'};
		$conn->{'connected'} = $TRUE;
		$conn->{'recvonly'} = $TRUE;
		undef($ret->{'SocketID'});
		#$ret = kIKE::kHelpers::rebuildStructure($ret);
	}

	return($ret);
}

=pod

=head2 recv()

Receives a message from the network. It establishes the connection if needed.

=head3 Parameters

No parameter.

=head3 Return value

=over

=item Receive results

The results of receiving a message. It is undef in case of error. It contains
the following keys: Command, RequestNum, Result, DataID, TimeStamp, TimeStamp2, 
SrcPort, DstPort, AddrType, Reserve1, Reserve2, SrcAddr, DstAddr, DataLength, 
Data.

=back

=cut

sub recv($;$)
{
	my ($conn, $material) = @_;
	my $ret = undef;

	if ($conn->{'protocol'} eq 'ICMP' &&
	    !$conn->{'connected'} &&
	    defined($conn->{'local'}->[0]) &&
	    $conn->{'local'}->[0] ne '::' &&
	    $conn->{'local'}->[0] ne '0.0.0.0') {
		$ret = kPacket_ConnectSend(
				$conn->{'protocol'},	# protocol (TCP|UDP|ICMP)
				$conn->{'frameID'},	# frameid (NULL|DNS|SIP|IKEv2)
				$conn->{'address_family'},	# addrfamily (INET|INET6)
				$conn->{'local'}->[0],	# srcaddr [undef] 0.0.0.0 or :: is used
				$conn->{'remote'}->[0],	# dstaddr
				$conn->{'local'}->[1],	# srcport	[undef] 0 is used
				$conn->{'remote'}->[1],	# $dstport
				0,			# $datalen
				'',			# $data
				$conn->{'interface'}	# $interface (Link0|Link1|...)
							# flags
				);
		if (defined($ret)) {
			# Get SocketID and set the connection to established.
			$conn->{'socketID'} = $ret->{'SocketID'};
			$conn->{'connected'} = $TRUE;
			undef($ret->{'SocketID'});
		}
	}

	if ($conn->{'connected'}) { # Connected
		# register keying material
		#kIKE::kIKE::kRegisterKeyingMaterial($material);

		# Receive the packet, waiting only a fixed amount of time.
		$ret = kPacket_Recv($conn->{'socketID'}, $conn->{'timeout'});
		if (defined $ret) {
			# Get the new SocketID if this call was marked recvonly (meaning comming from listen).
			$conn->{'socketID'} = $ret->{'SocketID'} if $conn->{'recvonly'};
			# Unmark recvonly flag.
			$conn->{'recvonly'} = $FALSE;
			undef($ret->{'SocketID'});
			#$ret = kIKE::kHelpers::rebuildStructure($ret);
		}

		# unregister keying material
		#kIKE::kIKE::kUnregisterKeyingMaterial();

		return($ret);
	}

	# Start to listen for an incoming packet.
	$ret = kPacket_StartRecv(
		$conn->{'protocol'},		# protocol (TCP|UDP|ICMP)
		$conn->{'frameID'},		# frameid (NULL|DNS|SIP|IKEv2)
		$conn->{'address_family'},	# addrfamily (INET|INET6)
		$conn->{'local'}->[0],		# srcaddr [undef] 0.0.0.0 or :: is used
		$conn->{'local'}->[1],		# srcport	[undef] 0 is used
		$conn->{'interface'}		# $interface (Link0|Link1|...)
						# flags
	);

	# register keying material
	#kIKE::kIKE::kRegisterKeyingMaterial($material);

	if (defined($ret)) {
		# Save the intermediate SocketID.
		my $SocketID = $ret->{'SocketID'};
		# Receive the packet, waiting only a fixed amount of time.
		$ret = kPacket_Recv($SocketID, $conn->{'timeout'});
		if (defined($ret)) {
			# Get SocketID and set the connection as established.
			$conn->{'socketID'} = $ret->{'SocketID'};
			$conn->{'connected'} = $TRUE;
			undef($ret->{'SocketID'});
			#$ret = kIKE::kHelpers::rebuildStructure($ret);
		}
	}

	# unregister keying material
	#kIKE::kIKE::kUnregisterKeyingMaterial();

	return($ret);
}

=pod

=head2 close()

Closes the current connection. It can be re-established after closure.

=head3 Parameters

No parameter.

=head3 Return value

=over

=item Close results

The result of the close operation. It is undef in case of error. It contains the
following keys: Command, RequestNum, Result.

=back

=cut

sub close()
{
	my $conn = shift;
	my $ret = undef;

	unless ($conn->{'connected'}) {
		$ret = $TRUE;
		return($ret);
	}

	$ret = kPacket_Close($conn->{'socketID'}, $conn->{'timeout'});
	if (defined($ret)) {
		# Forget the SocketID and unmark flags.
		undef($conn->{'socketID'});
		$conn->{'connected'} = $FALSE;
		$conn->{'recvonly'} = $FALSE;
		undef($ret->{'SocketID'});
		#$ret = kIKE::kHelpers::rebuildStructure($ret);
	}
	return($ret);
}


sub timeout($;$) {
	my ($conn, $timeout) = @_;
	if (defined $timeout && $timeout =~ m/^[0-9]+$/) {
		$conn->{timeout} = $timeout;
	}
	return $conn->{timeout};
}

=pod

=head1 SEE ALSO

KOI documentation.

=head1 AUTHOR

Hiroki Endo <Hiroki.Endou@jp.yokogawa.com> from TAHI project.

=cut

1;
