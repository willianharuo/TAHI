#
# Copyright (C) 1999, 2000, 2001, 2002, 2003 Yokogawa Electric Corporation,
# IPA (Information-technology Promotion Agency, Japan).
# All rights reserved.
# 
# Redistribution and use of this software in source and binary forms, with 
# or without modification, are permitted provided that the following 
# conditions and disclaimer are agreed and accepted by the user:
# 
# 1. Redistributions of source code must retain the above copyright 
# notice, this list of conditions and the following disclaimer.
# 
# 2. Redistributions in binary form must reproduce the above copyright 
# notice, this list of conditions and the following disclaimer in the 
# documentation and/or other materials provided with the distribution.
# 
# 3. Neither the names of the copyrighters, the name of the project which 
# is related to this software (hereinafter referred to as "project") nor 
# the names of the contributors may be used to endorse or promote products 
# derived from this software without specific prior written permission.
# 
# 4. No merchantable use may be permitted without prior written 
# notification to the copyrighters. However, using this software for the 
# purpose of testing or evaluating any products including merchantable 
# products may be permitted without any notification to the copyrighters.
# 
# 
# 
# THIS SOFTWARE IS PROVIDED BY THE COPYRIGHTERS, THE PROJECT AND 
# CONTRIBUTORS "AS IS" AND ANY EXPRESS OR IMPLIED WARRANTIES, INCLUDING 
# BUT NOT LIMITED THE IMPLIED WARRANTIES OF MERCHANTABILITY AND FITNESS 
# FOR A PARTICULAR PURPOSE, ARE DISCLAIMED.  IN NO EVENT SHALL THE 
# COPYRIGHTERS, THE PROJECT OR CONTRIBUTORS BE LIABLE FOR ANY DIRECT, 
# INDIRECT, INCIDENTAL, SPECIAL, EXEMPLARY, OR CONSEQUENTIAL DAMAGES 
# (INCLUDING, BUT NOT LIMITED TO, PROCUREMENT OF SUBSTITUTE GOODS OR 
# SERVICES; LOSS OF USE, DATA, OR PROFITS; OR BUSINESS INTERRUPTION) 
# HOWEVER CAUSED AND ON ANY THEORY OF LIABILITY, WHETHER IN 
# CONTRACT,STRICT LIABILITY, OR TORT (INCLUDING NEGLIGENCE OR OTHERWISE) 
# ARISING IN ANY WAY OUT OF THE USE OF THIS SOFTWARE, EVEN IF ADVISED OF 
# THE POSSIBILITY OF SUCH DAMAGE.
#
# Perl Module for IPv6 Specification Conformance Test
#
# $Name: REL_2_1_1 $
#
# $TAHI: ct/ipsec/IPSEC.pm,v 1.35 2003/05/05 06:06:14 ozoe Exp $
#

########################################################################
package IPSEC;

use Exporter;
@ISA = qw(Exporter);
@EXPORT = qw(
	ipsecExitPass
	ipsecExitIgnore
	ipsecExitNS
	ipsecExitWarn
	ipsecExitHostOnly
	ipsecExitRouterOnly
	ipsecExitFail
	ipsecExitFatal
	ipsecAsyncFail
	ipsecReboot
	ipsecCheckNUT
	ipsecSetSAD
	ipsecSetSADAsync
	ipsecSetSPD
	ipsecSetSPDAsync
	ipsecRemoteAsyncWait
	ipsecClearAll
	ipsecEnable
	ipsecPing2NUT
	ipsecPingFrag2NUT
	ipsecForwardEncap
	ipsecForwardDecap
	getTimeUTC
	getTimeStamp
	);

use V6evalTool;

$remote_debug = "";

#======================================================================
# BEGIN - read ipsecaddr.def
#======================================================================
BEGIN {
	open (FILE, "ipsecaddr.def") || die "Cannot open $!\n";
	while ( <FILE> ) {
		if ( /^#define\s+(\S+)\s+(\S+)/ ) {
			#print  $1 . " " . $2 . "\n";
			$IPsecAddr{$1} = $2;
		}
	}
	close FILE;
}

#======================================================================
# ipsecExitPass()
#======================================================================
sub ipsecExitPass() {
    vLogHTML('OK<BR>');
    exit $V6evalTool::exitPass;
}

#======================================================================
# ipsecExitIgnore()
#======================================================================
sub ipsecExitIgnore() {
    exit $V6evalTool::exitIgnore;
}

#======================================================================
# ipsecExitNS()
#======================================================================
sub ipsecExitNS() {
    vLogHTML("This test is not supported now<BR>");
    exit $V6evalTool::exitNS;
}

#======================================================================
# ipsecExitWarn()
#======================================================================
sub ipsecExitWarn() {
    vLogHTML('<FONT COLOR="#00FF00">Warn</FONT><BR>');
    exit $V6evalTool::exitWarn;
}

#======================================================================
# ipsecExitHostOnly()
#======================================================================
sub ipsecExitHostOnly() {
    vLogHTML("This test is for the host only<BR>");
    exit $V6evalTool::exitHostOnly;
}

#======================================================================
# ipsecExitRouterOnly()
#======================================================================
sub ipsecExitRouterOnly() {
    vLogHTML("This test is for the router only<BR>");
    exit $V6evalTool::exitRouterOnly;
}

#======================================================================
# ipsecExitFail()
#======================================================================
sub ipsecExitFail() {
    vLogHTML('<FONT COLOR="#FF0000">NG</FONT><BR>');
    exit $V6evalTool::exitFail;
}

#======================================================================
# ipsecExitFatal()
#======================================================================
sub ipsecExitFatal() {
    vLogHTML('<FONT COLOR="#FF0000">Fatal</FONT><BR>');
    exit $V6evalTool::exitFatal;
}

#======================================================================
# ipsecAsyncFail()
#======================================================================
sub ipsecAsyncFail($) {
    my ($msg) = @_;
    vLog($msg);
    vLogHTML('<FONT COLOR="#FF0000">Async Fail</FONT><BR>');
    seqTermination();
#    confess "Sequence Stop" if $debug > 0;
    exit $V6evalTool::exitFail;
}

#======================================================================
# ipsecReboot() - reboot NUT
#======================================================================

sub ipsecReboot() {
	vLogHTML("Target: Reboot");
	$ret = vRemote("reboot.rmt", $remote_debug);
	if ($ret) {
		vLogHTML("Cannot reboot NUT<BR>");
		ipsecExitFatal();
	}
}

#======================================================================
# ipsecCheckNUT() - check NUT
#======================================================================

sub ipsecCheckNUT($) {
	my($require) = @_;

	$type=$V6evalTool::NutDef{Type};
	if($type eq 'host') {
		if ($require eq 'router') {
			ipsecExitRouterOnly();
		}
	}
	elsif($type eq 'router') {
		# a router should run both type test (router-type, host-type)
	}
	else {
		vLogHTML("Unknown NUT type $type : check nut.def<BR>");
		ipsecExitFatal();
	}
}

#======================================================================
# ipsecSetSAD() - set SAD entries
#======================================================================

sub ipsecSetSAD(@) {
	vLogHTML("Target: Set SAD entries: @_");
	$ret = vRemote("ipsecSetSAD.rmt", "@_", $remote_debug);
	if ($ret) {
		vLogHTML("Cannot Set SAD entries: @_ <BR>");
		if ($ret == $V6evalTool::exitNS) {
		    ipsecExitNS();
		}
		else {
		    ipsecExitFail();
		}
	}
}

#======================================================================
# ipsecSetSADAsync() - set SAD entries
#======================================================================

sub ipsecSetSADAsync(@) {
	vLogHTML("Target: Set SAD entries: @_");
	$ret = vRemoteAsync("ipsecSetSAD.rmt", "@_", $remote_debug);
	if ($ret) {
		vLogHTML("Cannot Set SAD entries: @_ <BR>");
		if ($ret == $V6evalTool::exitNS) {
		    ipsecExitNS();
		}
		else {
		    ipsecExitFail();
		}
	}
}

#======================================================================
# ipsecSetSPD() - set SPD entries
#======================================================================

sub ipsecSetSPD(@) {
	vLogHTML("Target: Set SPD entries: @_");
	$ret = vRemote("ipsecSetSPD.rmt", "@_", $remote_debug);
	if ($ret) {
		vLogHTML("Cannot Set SPD entries: @_ <BR>");
		if ($ret == $V6evalTool::exitNS) {
		    ipsecExitNS();
		}
		else {
		    ipsecExitFail();
		}
	}
}

#======================================================================
# ipsecSetSPDAsync() - set SPD entries
#======================================================================

sub ipsecSetSPDAsync(@) {
	vLogHTML("Target: Set SPD entries: @_");
	$ret = vRemoteAsync("ipsecSetSPD.rmt", "@_", $remote_debug);
	if ($ret) {
		vLogHTML("Cannot Set SPD entries: @_ <BR>");
		if ($ret == $V6evalTool::exitNS) {
		    ipsecExitNS();
		}
		else {
		    ipsecExitFail();
		}
	}
}

#==============================================
#  Wait for asynchronous remote script
#  forked by vRemoteAsync()
#==============================================
sub ipsecRemoteAsyncWait() {
    my $ret = vRemoteAsyncWait();
    ipsecAsyncFail("vRemoteAsyncWait failed :return status = $ret") if $ret != 0;
}

#======================================================================
# ipsecClearAll() - clear all SAD and SPD entries
#======================================================================

sub ipsecClearAll() {
	vLogHTML("Target: Clear all SAD and SPD entries");
	$ret = vRemote("ipsecClearAll.rmt", $remote_debug);
	if ($ret) {
		vLogHTML("Cannot Clear all SAD and SPD entries<BR>");
		if ($ret == $V6evalTool::exitNS) {
		    ipsecExitNS();
		}
		else {
		    ipsecExitFail();
		}
	}
}

#======================================================================
# ipsecEnable() - Enable and start IPsec function
#======================================================================

sub ipsecEnable() {
	vLogHTML("Target: Enable and start IPsec function");
	$ret = vRemote("ipsecEnable.rmt", $remote_debug);
	if ($ret) {
		vLogHTML("Cannot start IPsec<BR>");
		if ($ret == $V6evalTool::exitNS) {
		    ipsecExitNS();
		}
		else {
		    ipsecExitFail();
		}
	}
}

########################################################################
#       Get time string
#
#       If more detailed format is required, you may switch to use
#       prepared perl modlue.
#-----------------------------------------------------------------------
sub getTimeUTC() {
        my $sec = time;
        my $timestr = sprintf('%16d', $sec);
        $timestr;
}

sub getTimeStamp() {
        my ($sec,$min,$hour) = localtime;
        my $timestr = sprintf('%02d:%02d:%02d', $hour, $min, $sec);
        $timestr;
}

#======================================================================
# ($retstat, %ret) = ipsecPing2NUT() - emulate ping to NUT
#
#  $retstat : return status
#    'GOT_REPLY' ping to NUT successfully
#    'NO_REPLY'  echo request ignored by NUT
#    'ERROR'     found something failure
#  %ret : status of last vRecv()
#======================================================================
sub ipsecPing2NUT($$$;$$) {
    my ($IF,
	$echo_request_to_nut,     # "echo_request"
	$echo_reply_from_nut_s,   # "echo_reply1 echo_reply2 ..."
	$ns_from_nut,             # "ns target address global"
	$na_to_nut,               # "na target address global"
	$ns_from_nut_linkaddr,    # "ns target address link-local"
	$na_to_nut_linkaddr       # "na target address link-local"
	) = @_;
    my ($retstat,    # return status 1
	%ret);       # return status 2 (last vRecv())
    my (@echo_reply_from_nut_s) = split(/\s+/, $echo_reply_from_nut_s);

    ## set default packet name
    $ns_from_nut = 'ns_to_router'   unless defined $ns_from_nut;
    $na_to_nut   = 'na_from_router' unless defined $na_to_nut;
    $ns_from_nut_linkaddr = 'ns_to_router_linkaddr'   unless defined $ns_from_nut_linkaddr;
    $na_to_nut_linkaddr   = 'na_from_router_linkaddr' unless defined $na_to_nut_linkaddr;

    ## send echo request to NUT
    vSend($IF, $echo_request_to_nut);

    ## receive echo reply or ns from NUT
    %ret = vRecv($IF, 6, 0, 0, $ns_from_nut_linkaddr, $ns_from_nut, @echo_reply_from_nut_s);
    if ($ret{status} != 0) {
	$retstat = 'NO_REPLY';
	return ($retstat, %ret);
    }
    if ($ret{recvFrame} eq $ns_from_nut) {
	vSend($IF, $na_to_nut);
	%ret = vRecv($IF, 5, 0, 0, @echo_reply_from_nut_s);
	if ($ret{status} != 0) {
	    $retstat = 'ERROR';
	    return ($retstat, %ret);
	}
    }
    if ($ret{recvFrame} eq $ns_from_nut_linkaddr) {
	vSend($IF, $na_to_nut_linkaddr);
	%ret = vRecv($IF, 5, 0, 0, @echo_reply_from_nut_s);
	if ($ret{status} != 0) {
	    $retstat = 'ERROR';
	    return ($retstat, %ret);
	}
    }

    ## received packet is echo reply
    ## if NC state is PROBE, force NC to be REACHABLE
    %ret = vRecv($IF, 6, 0, 0, $ns_from_nut_linkaddr, $ns_from_nut);
    if ($ret{recvFrame} eq $ns_from_nut) {
	vSend($IF, $na_to_nut);
	vLogHTML("NC about Router was PROBE state, but now it's REACHABLE.");
	%ret = vRecv($IF, 6, 0, 0, $ns_from_nut);
	%ret = vRecv($IF, 6, 0, 0, $ns_from_nut);
    }
    if ($ret{recvFrame} eq $ns_from_nut_linkaddr) {
	vSend($IF, $na_to_nut_linkaddr);
	vLogHTML("NC about Router was PROBE state, but now it's REACHABLE.");
	%ret = vRecv($IF, 6, 0, 0, $ns_from_nut_linkaddr);
	%ret = vRecv($IF, 6, 0, 0, $ns_from_nut_linkaddr);
    }

    $retstat = 'GOT_REPLY';
    return ($retstat, %ret);
}

#======================================================================
# ($retstat, %ret) = ipsecPingFrag2NUT() - emulate ping to NUT (Fragment)
#
#  $retstat : return status
#    'GOT_REPLY' ping to NUT successfully
#    'ERROR'     found something failure
#  %ret : status of last vRecv()
#======================================================================
sub ipsecPingFrag2NUT($$$$$) {
    my ($IF,
	$echo_request_to_nut_1st,
	$echo_request_to_nut_2nd,
	$echo_reply_from_nut_1st,
	$echo_reply_from_nut_2nd,
	) = @_;
    my ($retstat,    # return status 1
	%ret);       # return status 2 (last vRecv())

    ## send echo request to NUT
    vSend($IF, $echo_request_to_nut_1st);
    vSend($IF, $echo_request_to_nut_2nd);

    ## receive echo reply or ns from NUT
    %ret = vRecv($IF, 5, 0, 0, $echo_reply_from_nut_1st, $echo_reply_from_nut_2nd);
    if ($ret{status} == 0 && $ret{recvFrame} eq $echo_reply_from_nut_1st) {
	%ret = vRecv($IF, 5, 0, 0, $echo_reply_from_nut_2nd);
	if ($ret{status} == 0 && $ret{recvFrame} eq $echo_reply_from_nut_2nd) {
	    $retstat = 'GOT_REPLY';
	    return ($retstat, %ret);
	}
    }
    if ($ret{status} == 0 && $ret{recvFrame} eq $echo_reply_from_nut_2nd) {
	%ret = vRecv($IF, 5, 0, 0, $echo_reply_from_nut_1st);
	if ($ret{status} == 0 && $ret{recvFrame} eq $echo_reply_from_nut_1st) {
	    $retstat = 'GOT_REPLY';
	    return ($retstat, %ret);
	}
    }
    $retstat = 'ERROR';
    return ($retstat, %ret);
}

#======================================================================
# ($retstat, %ret) = ipsecForwardEncap() - Forwarding packet with Encap.
#
#  $retstat : return status
#    'GOT_PACKET' got encapsulated packet from NUT successfully
#    'NO_PACKET'  no packet from NUT
#    'ERROR'     found something failure
#  %ret : status of last vRecv()
#======================================================================
sub ipsecForwardEncap($$$$;$$) {
    my ($IF_to_nut,		  # I/F for send to NUT
	$IF_from_nut,		  # I/F for recv from NUT
	$packet_to_nut,           # packet to NUT (before encapsulation)
	$packet_from_nut_s,       # packet(s) from NUT (after encapsulation)
	$ns_from_nut,             # "ns"
	$na_to_nut                # "na"
	) = @_;
    my ($retstat,    # return status 1
	%ret);       # return status 2 (last vRecv())
    my (@packet_from_nut_s) = split(/\s+/, $packet_from_nut_s);

    ## set default packet name
    $ns_from_nut = 'ns_to_router'   unless defined $ns_from_nut;
    $na_to_nut   = 'na_from_router' unless defined $na_to_nut;

    ## send packet to NUT
    vSend($IF_to_nut, $packet_to_nut);

    ## receive packet or ns from NUT
    %ret = vRecv($IF_from_nut, 6, 0, 0, $ns_from_nut, @packet_from_nut_s);
    if ($ret{status} != 0) {
	$retstat = 'NO_PACKET';
	return ($retstat, %ret);
    }
    if ($ret{recvFrame} eq $ns_from_nut) {
	vSend($IF_from_nut, $na_to_nut);
	%ret = vRecv($IF_from_nut, 5, 0, 0, @packet_from_nut_s);
	if ($ret{status} != 0) {
	    $retstat = 'ERROR';
	    return ($retstat, %ret);
	}
    }

    ## received packet is not ns
    ## if NC state is PROBE, force NC to be REACHABLE
    %ret = vRecv($IF_from_nut, 6, 0, 0, $ns_from_nut);
    if ($ret{recvFrame} eq $ns_from_nut) {
	vSend($IF_from_nut, $na_to_nut);
	vLogHTML("NC about Router was PROBE state, but now it's REACHABLE.");
	%ret = vRecv($IF_from_nut, 6, 0, 0, $ns_from_nut);
	%ret = vRecv($IF_from_nut, 6, 0, 0, $ns_from_nut);
    }

    $retstat = 'GOT_PACKET';
    return ($retstat, %ret);
}

#======================================================================
# ($retstat, %ret) = ipsecForwardDecap() - Forwarding packet with Decap.
#
#  $retstat : return status
#    'GOT_PACKET' got decapsulated packet from NUT successfully
#    'NO_PACKET'  no packet from NUT
#    'ERROR'     found something failure
#  %ret : status of last vRecv()
#======================================================================
sub ipsecForwardDecap($$$$;$$) {
    my ($IF_to_nut,		  # I/F for send to NUT
	$IF_from_nut,		  # I/F for recv from NUT
	$packet_to_nut,           # packet to NUT (before encapsulation)
	$packet_from_nut_s,       # packet(s) from NUT (after encapsulation)
	$ns_from_nut,             # "ns"
	$na_to_nut                # "na"
	) = @_;
    my ($retstat,    # return status 1
	%ret);       # return status 2 (last vRecv())
    my (@packet_from_nut_s) = split(/\s+/, $packet_from_nut_s);

    ## set default packet name
    $ns_from_nut = 'ns_to_host1_net1'   unless defined $ns_from_nut;
    $na_to_nut   = 'na_from_host1_net1' unless defined $na_to_nut;

    ## send packet to NUT
    vSend($IF_to_nut, $packet_to_nut);

    ## receive packet or ns from NUT
    %ret = vRecv($IF_from_nut, 6, 0, 0, $ns_from_nut, @packet_from_nut_s);
    if ($ret{status} != 0) {
	$retstat = 'NO_PACKET';
	return ($retstat, %ret);
    }
    if ($ret{recvFrame} eq $ns_from_nut) {
	vSend($IF_from_nut, $na_to_nut);
	%ret = vRecv($IF_from_nut, 5, 0, 0, @packet_from_nut_s);
	if ($ret{status} != 0) {
	    $retstat = 'ERROR';
	    return ($retstat, %ret);
	}
    }

    ## received packet is not ns
    ## if NC state is PROBE, force NC to be REACHABLE
    %ret = vRecv($IF_from_nut, 6, 0, 0, $ns_from_nut);
    if ($ret{recvFrame} eq $ns_from_nut) {
	vSend($IF_from_nut, $na_to_nut);
	vLogHTML("NC about HOST1_NET3 was PROBE state, but now it's REACHABLE.");
	%ret = vRecv($IF_from_nut, 6, 0, 0, $ns_from_nut);
	%ret = vRecv($IF_from_nut, 6, 0, 0, $ns_from_nut);
    }

    $retstat = 'GOT_PACKET';
    return ($retstat, %ret);
}

1;
########################################################################
__END__

=head1 NAME

IPSEC.pm - utility functions for IPsec test

=head1 SYNOPSIS

=begin html
<PRE>
use <A HREF="./IPSEC.pm">IPSEC</A>;
</PRE>

=end html

=head1 DESCRIPTION

This module contains methods to test IPsec.

=head2 Functions

=over

=item ipsecExitPass()

Output 'OK' to log and exit (exit code is Pass).

=item ipsecExitIgnore()

Output no message and Exit (exit code is Ignore).

=item ipsecExitNS()

Output 'This test is not supported now' to log and Exit (exit code is NS).

=item ipsecExitWarn()

Output 'Warn' (color is green) to log and Exit (exit code is Warn).

=item ipsecExitHostOnly()

Output 'This test is for the host only' to log and Exit (exit code is HostOnly).

=item ipsecExitRouterOnly()

Output 'This test is for the router only' to log and Exit (exit code is HostOnly).

=item ipsecExitFail()

Output 'NG' (color is red) to log and Exit (exit code is Fail).

=item ipsecExitFatal()

Output 'Fatal' (color is red) to log and Exit (exit code is Fatal).

=item ipsecReboot()

Reboot the target.

This function calls 'reboot.rmt' simply.

=item ipsecCheckNUT($require)

Check NUT type in 'nut.def'.
Parameter $require is one of 'host' or  'router'.

If 'Type' in nut.def does not match to $require, 
output message and exit (HostOnly, RouterOnly or Fatal).

=item ipsecSetSAD(@params)

Set SAD (Security Association Database) entry.

This function calls 'ipsecSetSAD.rmt' with @params simply.
If remote command fails, output message and exit (Fail).

=item ipsecSetSADAsync(@params)

Same function as the above.
But set SAD (Security Association Database) entry asynchronously.

=item ipsecSetSPD(@params)

Set SPD (Security Policy Database) entry.

This function calls 'ipsecSetSPD.rmt' with @params simply.
If remote command fails, output message and exit (Fail).

=item ipsecSetSPDAsync(@params)

Same function as the above.
But set SPD (Security Policy Database) entry asynchronously.

=item ipsecClearAll()

Clear all SAD and SPD entries.

This function calls 'ipsecClearAll.rmt' simply.
If remote command fails, output message and exit (Fail).

=item ipsecEnable()

Enable and start IPsec function.

This function calls 'ipsecEnable.rmt' simply.
If remote command fails, output message and exit (Fail).

=item ipsecPing2NUT($IF, $req, $rep [,$ns, $na])

Emulate Ping to NUT.

Send $req to NUT and wait $rep from NUT.

If NS is received from NUT, send NA to NUT and wait $rep again.

=item ipsecPingFrag2NUT($IF, $req1st, $req2nd, $rep1st, $rep2nd)

Emulate Fragmented Ping to NUT.

Send $req1st and $req2nd to NUT and wait $rep1st and $rep2nd from NUT.

=item ipsecForwardEncap($IFs, $IFr, $p1, $p2 [, $ns, $na])

Check packet forwarding with encapsulation.

Send $p1 to NUT's $IFs and wait $p2 from NUT's $IFr.

If NS is received from NUT, send NA to NUT and wait $p2 again.

=item ipsecForwardDecap($IFs, $IFr, $p1, $p2 [, $ns, $na])

Check packet forwarding with decapsulation.

Send $p1 to NUT's $IFs and wait $p2 from NUT's $IFr.

If NS is received from NUT, send NA to NUT and wait $p2 again.

=back

=head1 SEE ALSO

  perldoc V6EvalTool
  perldoc V6Remote
  perldoc /usr/local/v6eval/bin/manual/ipsecSetSAD.rmt
  perldoc /usr/local/v6eval/bin/manual/ipsecSetSPD.rmt
  perldoc /usr/local/v6eval/bin/manual/ipsecClearAll.rmt
  perldoc /usr/local/v6eval/bin/manual/ipsecEnable.rmt


=cut


