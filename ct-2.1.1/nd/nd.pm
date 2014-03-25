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
# $TAHI: ct/nd/nd.pm,v 1.62 2002/02/27 01:08:28 masaxmasa Exp $

package nd;
use Exporter;
@ISA = qw(Exporter);

use 5;
use V6evalTool;

@EXPORT = qw(
	     ndGetLinkDev
	     ndGetLinkDevs
	     ndOptions
	     ndExpectedLLA
	     ndCachedLLA
	     ndStatus
	     ndStatusNum2Str
	     ndIsReachable
	     ndIsStale
	     ndReboot
	     ndRebootAsync
	     ndClearPrefix
	     ndClearDefr
	     ndClearRoutes
	     nd2NoNce
	     ndNoNce2Incomplete
	     ndNoNce2IncompleteZ
	     ndIncomplete2Reachable
	     ndIncomplete2ReachableZ
	     ndReachable2Stale
	     ndReachable2StaleZ
	     ndStale2Probe
	     ndStale2ProbeZ
	     nd2Incomplete
	     nd2Reachable
	     nd2ReachableZ
	     nd2Stale
	     nd2StaleZ
	     nd2Probe
	     nd2ProbeZ
	     ndNoNce2ReachableByRa
	     ndNoNce2ReachableByRaZ
	     nd2ReachableByRa
	     nd2ReachableByRaZ
	     ndPrintSummary
	     ndPrintSummaryHTML
	     ndInitTimer
	     ndExpireTimer
	     nd2NoNceByPacket
	     ndErrmsg
	     ndWarnmsg
	     );

# router constants
$MAX_INITIAL_RTR_ADVER_INTERVAL=16;	# sec.
$MAX_INITIAL_RTR_ADVERTISEMENTS=3;	# times
$MAX_FINAL_RTR_ADVERTISEMENTS=3;	# times
$MIN_DELAY_BETWEEN_RAS=3;		# sec.
$MAX_RA_DELAY_TIME=0.5;			# sec.

# host constants
$MAX_RTR_SOLICITATION_DELAY=1;	# sec.
$RTR_SOLICITATION_INTERVAL=4;	# sec.
$MAX_RTR_SOLICITATIONS=3;	# times

# node constants
$MAX_MULTICAST_SOLICIT=3;	# times
$MAX_UNICAST_SOLICIT=3;		# times
$MAX_ANYCAST_DELAY_TIME=1;	# sec.
$MAX_NEIGHBOR_ADVERTISEMENT=3;	# times
$REACHABLE_TIME=30;		# sec.
$RETRANS_TIMER=1;		# sec.
$DELAY_FIRST_PROBE_TIME=5;	# sec.
$MIN_RANDOM_FACTOR=0.5;		#
$MAX_RANDOM_FACTOR=1.5;		#

$MAX_SOLICIT=3;

$wait_ns=$RETRANS_TIMER*$MAX_SOLICIT+1;	# margin: 1sec.
if($V6evalTool::NutDef{System} =~ /solaris/) {
    $wait_echo=5;
} else {
    $wait_echo=2;
}
$wait_reachable=$REACHABLE_TIME*$MAX_RANDOM_FACTOR+1; # margin: 1sec.
$wait_delay=$DELAY_FIRST_PROBE_TIME+1; # margin: 1sec.
$wait_dad=3;

$stat_error=0;
$stat_none=1;
$stat_incomplete=2;
$stat_reachable=3;
$stat_stale=4;
$stat_delay=5;
$stat_probe=6;

$debug=0;
$remote_debug="";
$expectedLLA=1;

#
#
#
BEGIN
{
    my(@links, $name, $adrs);

    @links = grep(/^Link[0-9]+$/, keys(%V6evalTool::NutDef));
    foreach(@links) {
	($name, $adrs) = split(/\s/, $V6evalTool::NutDef{$_});
	push(@if_name, $name);
	push(@if_adrs, $adrs);
	#print "name=$name, adrs=$adrs\n";
    }
}

#
#
#
END
{}

#
#
#
sub ndGetLinkDev()
{
    my(@dev)=();
    foreach(keys(%V6evalTool::NutDef)) {
	if(/^Link0_device$/) {
	    my($v)=$V6evalTool::NutDef{$_};
	    push(@dev, "link0=$v");
	    last;
	}
    }
    @dev;
}

#
#
#
sub ndGetLinkDevs()
{
    my(@dev)=();
    foreach(keys(%V6evalTool::NutDef)) {
	if(/^Link([0-9]+)_device$/) {
	    my($v)=$V6evalTool::NutDef{$_};
	    push(@dev, "link$1=$v");
	}
    }
    @dev;
}

#
#
#
sub ndOptions(@)
{
    my(@argv) = @_;
    my($v, $lval, $rval);

    foreach(@argv) {
	($lval, $rval) = split(/=/, $_, 2);
	$rval=1 if $rval =~ /^\s*$/;
	$v='$main::ndOpt_'."$lval".'=\''."$rval".'\'';
	eval($v);	# eval ``$main::ndOpt<LVAL>=<RVAL>''
    }
}

#
#
#
sub ndExpectedLLA()
{
    return($expectedLLA);
}

#
#
#
sub ndCachedLLA($)
{
    my($exp)=@_;
    if($expectedLLA) {
	if($exp eq unchanged) {
	    return(unchanged);
	} else {
	    return(updated);
	}
    } else {
	if($exp eq unchanged) {
	    return(updated);
	} else {
	    return(unchanged);
	}
    }
}

#
#
#
sub ndStatus($$\@\@\@\@\@\@\@\@\@)
{
    my(
       $if,
       $seektime,
       $incomplete_ip,
       $probe_ip,
       $reply_ip,
       $ignore_ip,

       $nonce_n,
       $reply_n,
       $ignore_n,

       $stale_sr,
       $ignore_sr
       ) = @_;

    my(%ret, %ret2, $n, $delta);
    my($suspicious)=0;

    vLogHTML("Examine the target's state<BR>");
    vLogHTML("ndStatus: incomplete_ip:@$incomplete_ip<BR>") if $debug;
    vLogHTML("ndStatus: probe_ip:@$probe_ip<BR>") if $debug;
    vLogHTML("ndStatus: reply_ip:@$reply_ip<BR>") if $debug;
    vLogHTML("ndStatus: ignore_ip:@$ignore_ip<BR>") if $debug;

    vLogHTML("ndStatus: nonce_n:@$nonce_n<BR>") if $debug;
    vLogHTML("ndStatus: reply_n:@$reply_n<BR>") if $debug;
    vLogHTML("ndStatus: ignore_n:@$ignore_n<BR>") if $debug;

    vLogHTML("ndStatus: stale_sr:@$stale_sr<BR>") if $debug;
    vLogHTML("ndStatus: ignore_sr:@$ignore_sr<BR>") if $debug;

    # Start capture buffer
    $expectedLLA=1;
    vCapture($if);

    $main::pktdesc{nd_multicast_ns}=
	'Got multicast NS, it was INCOMPLETE state';
    $main::pktdesc{nd_unicast_ns}=
	'Got unicast NS, it was PROBE state';
    $main::pktdesc{nd_unicast_ns_sll}=
	'Got unicast NS, it was PROBE state';
    $main::pktdesc{nd_unicast_ns_to_z}=
	ndErrmsg('ERROR: Got unicast NS, but different LLA, '.
		 'it was PROBE state');
    $main::pktdesc{nd_unicast_ns_sll_to_z}=
	ndErrmsg('ERROR: Got unicast NS, but different LLA, '.
		 'it was PROBE state');

    while(1) {
	vLogHTML("Wait for a NS ($wait_ns sec.)<BR>");
	%ret=vRecv($if, $wait_ns, $seektime, 1,
		   nd_multicast_ns,		# ==> INCOMPLETE
		   nd_unicast_ns,		# ==> PROBE
		   nd_unicast_ns_sll,		# ==> PROBE
		   nd_unicast_ns_to_z,		# ==> PROBE
		   nd_unicast_ns_sll_to_z,	# ==> PROBE
		   @$incomplete_ip,		# ==> INCOMPLETE
		   @$probe_ip,			# ==> PROBE
		   @$reply_ip,			# ==> REACHABLE or STALE
		   @$ignore_ip			# should be ignored
		   );
	if($ret{status} == 0) {
	    if($ret{recvFrame} eq nd_multicast_ns) {
		# Got a multicast NS
		$n = readout($if, $wait_ns);
		return($stat_incomplete);
	    } elsif($ret{recvFrame} eq nd_unicast_ns ||
		    $ret{recvFrame} eq nd_unicast_ns_sll) {
		# Got an unicast NS
		$n = readout($if, $wait_ns);
		return($stat_probe);
	    } elsif($ret{recvFrame} eq nd_unicast_ns_to_z ||
		    $ret{recvFrame} eq nd_unicast_ns_sll_to_z) {
		# Got an unicast NS, but different LLA
		$expectedLLA=0;
		$n = readout($if, $wait_ns);
		return($stat_probe);
	    } else {
		foreach(@$incomplete_ip) {
		    next if $_ ne $ret{recvFrame};
		    vLogHTML("Got $ret{recvFrame}: it was INCOMPLETE<BR>");
		    $n = readout($if, $wait_ns);
		    return($stat_incomplete);
		}
		foreach(@$probe_ip) {
		    next if $_ ne $ret{recvFrame};
		    vLogHTML("Got $ret{recvFrame}: it was PROBE<BR>");
		    $n = readout($if, $wait_ns);
		    return($stat_probe);
		}
		foreach(@$reply_ip) {
		    next if $_ ne $ret{recvFrame};
		    vLogHTML("Got $ret{recvFrame}: ".
			     "it was REACHABLE/STALE<BR>");
		    $suspicious=1;
		    goto reachable_or_stale;
		}
		vLogHTML("Got $ret{recvFrame} to be ignored<BR>");
	    }
	} else {
	    if($ret{recvCount} > 0) {
		# Got unexpected packets
		vLogHTML(ndErrmsg("ERROR: Got unexpected packets<BR>"));
		goto error;
	    }
	    # It is ok to get none of packet.
	    vLogHTML("Timer expired<BR>");
	    last;
	}
    }

    $main::pktdesc{nd_echo_request}=
	'Send echo-request';
    %ret2=vSend($if, nd_echo_request);
    %ret2=vSend($if, nd_echo_request)
	if $V6evalTool::NutDef{System} =~ /solaris/;

    $main::pktdesc{nd_echo_reply}=
	'Got echo-reply, it was REACHABLE/STALE state';
    $main::pktdesc{nd_echo_reply_to_z2}=
	ndErrmsg('ERROR: Got echo-reply, but different LLA, '.
		 'it was REACHABLE/STALE state');
    $main::pktdesc{nd_multicast_ns }=
	'Got multicast NS, it was NONCE state';

    while(1) {
	vLogHTML("Wait for a echo-reply or multicast NS ".
		 "($wait_echo sec.)<BR>");
	%ret=vRecv($if, $wait_echo, $ret2{sentTime1}, 1,
		   nd_echo_reply,		# ==> REACHABLE or STALE
		   nd_echo_reply_to_z2,		# ==> REACHABLE or STALE
		   nd_multicast_ns,		# ==> NONCE
		   @$nonce_n,			# ==> NONCE
		   @$reply_n,			# ==> REACHABLE or STALE
		   @$ignore_n			# should be ignored
		   );
	if($ret{status} != 0) {
	    vLogHTML(ndErrmsg("ERROR: Got unexpected packets<BR>"));
	    goto error;
	}

	if($ret{recvFrame} eq nd_echo_reply) {
	    # Got an echo-reply
	    last;
	} elsif($ret{recvFrame} eq nd_echo_reply_to_z2) {
	    # Got an echo-reply, but different LLA
	    $expectedLLA=0;
	    last;
	} elsif($ret{recvFrame} eq nd_multicast_ns) {
	    # Got a multicast NS
	    $n = readout($if, $wait_ns);
	    return ($stat_none);
	} else {
	    foreach(@$nonce_n) {
		next if $_ ne $ret{rectFrame};
		vLogHTML("Got $ret{recvFrame}: it was NONCE<BR>");
		$n = readout($if, $wait_ns);
		return ($stat_none);
	    }
	    foreach(@$reply_n) {
		next if $_ ne $ret{recvFrame};
		vLogHTML("Got $ret{recvFrame}: it was REACHABLE/STALE<BR>");
		$suspicious=1;
		goto reachable_or_stale;
	    }
	    vLogHTML("Got $ret{recvFrame} to be ignored<BR>");
	    next;
	}
    }

reachable_or_stale:

    $main::pktdesc{nd_unicast_ns}=
	'Got unicast NS, it was STALE';
    $main::pktdesc{nd_unicast_ns_sll}=
	'Got unicast NS, it was STALE';
    $main::pktdesc{nd_unicast_ns_to_z}=
	ndErrmsg('ERROR: Got unicast NS, but different LLA, it was STALE');
    $main::pktdesc{nd_unicast_ns_sll_to_z}=
	ndErrmsg('ERROR: Got unicast NS, but different LLA, it was STALE');

    while(1) {
	vLogHTML("Wait for a NS ($wait_delay sec.)<BR>");
	%ret=vRecv($if, $wait_delay, 0, 1,
		   nd_unicast_ns,		# ==> STALE
		   nd_unicast_ns_sll,		# ==> STALE
		   nd_unicast_ns_to_z,		# ==> STALE
		   nd_unicast_ns_sll_to_z,	# ==> STALE
		   @$stale_sr,			# ==> STALE
		   @$ignore_sr			# should be ignored
		   );
	if($ret{status} == 0) {
	    if($ret{recvFrame} eq nd_unicast_ns ||
	       $ret{recvFrame} eq nd_unicast_ns_sll) {
		# Got a unicast NS
		$n = readout($if, $wait_ns);
		return($stat_stale);
	    } elsif($ret{recvFrame} eq nd_unicast_ns_to_z ||
		    $ret{recvFrame} eq nd_unicast_ns_sll_to_z) {
		# Got a unicast NS, but different LLA
		$expectedLLA=0;
		$n = readout($if, $wait_ns);
		return($stat_stale);
	    } else {
		foreach(@$stale_sr) {
		    next if $_ ne $ret{recvFrame};
		    vLogHTML("Got $ret{recvFrame}: it was STALE<BR>");
		    $n = readout($if, $wait_ns);
		    return($stat_stale);
		}
		# Got another packet to be ignored:
		vLogHTML("Got $ret{recvFrame} packet to be ignored<BR>");
	    }
	} else {
	    if($ret{recvCount} > 0) {
		# Got unexpected packets
		vLogHTML(ndErrmsg("ERROR: Got unexpected packets<BR>"));
		goto error;
	    } else {
		# timeout
		if($suspicious) {
		    vLogHTML("Make sure if NC is STALE or not<BR>");
		    %ret2=vSend($if, nd_echo_request);
		    
		    $main::pktdesc{nd_echo_reply}=
			'Got echo-reply, it was REACHABLE/STALE';
		    $main::pktdesc{nd_echo_reply_to_z2}=
			ndErrmsg('ERROR: Got echo-reply, '.
				 'but different LLA,'.
				 'it was REACHABLE/STALE');
		    %ret=vRecv($if, $wait_echo, $ret2{sentTime1}, 1,
			       nd_echo_reply,		# ==> REACHABLE/STALE
			       nd_echo_reply_to_z2,	# ==> REACHABLE/STALE
			       @$reply_n,		# ==> REACHABLE/STALE
			       );
		    goto error if $ret{status} != 0;
		    if($ret{recvFrame} eq nd_echo_reply_to_z2) {
			$expectedLLA=0;
		    }
		    vLogHTML("Got reply, it was REACHABLE/STALE<BR>");

		    $main::pktdesc{nd_unicast_ns}=
			'Got unicast NS, it was STALE';
		    $main::pktdesc{nd_unicast_ns_sll}=
			'Got unicast NS, it was STALE';
		    $main::pktdesc{nd_unicast_ns_to_z}=
			ndErrmsg('ERROR: Got unicast NS, but different LLA, '.
				 'it was STALE');
		    $main::pktdesc{nd_unicast_ns_sll_to_z}=
			ndErrmsg('ERROR: Got unicast NS, but different LLA, '.
				 'it was STALE');
		    %ret=vRecv($if, $wait_delay, 0, 1,
			       nd_unicast_ns,		# ==> STALE
			       nd_unicast_ns_sll,	# ==> STALE
			       nd_unicast_ns_to_z,	# ==> STALE
			       nd_unicast_ns_sll_to_z,	# ==> STALE
			       @$stale_sr,		# ==> STALE
			       );
		    if($ret{status} == 1) {
			#time out
			vLogHTML("Never got unicast NS, it was REACHABLE<BR>");
			return($stat_reachable);
		    } elsif($ret{status} == 0) {
			if($ret{recvFrame} eq nd_unicast_ns_to_z ||
			   $ret{recvFrame} eq nd_unicast_ns_sll_to_z) {
			    $expectdLLA=0;
			}
			$n = readout($if, $wait_ns);
			return($stat_stale);
		    } else {
			goto error;
		    }
		} else {
		    vLogHTML("Never got unicast NS, it was REACHABLE<BR>");
		    return($stat_reachable);
		}
	    }
	}
    }

error:
    vLogHTML(ndErrmsg("Target was in unknown state<BR>"));
    readout($if, $wait_delay+$wait_ns);
    return($stat_error);
}

#
#
#
sub ndIsReachable($)
{
    my($if)=@_;

    vLogHTML("Examine the target's state<BR>");
    $main::pktdesc{nd_echo_request}='Send echo-request';
    %ret=vSend($if, nd_echo_request);
    %ret=vSend($if, nd_echo_request)
	if $V6evalTool::NutDef{System} =~ /solaris/;

    $main::pktdesc{nd_echo_reply}='Got echo-reply, it was REACHABLE/STALE';
    %ret=vRecv($if, $wait_echo, $ret{sentTime1}, 1, nd_echo_reply);
    if($ret{status} != 0) {
	vLogHTML(ndErrmsg("Never get echo-reply<BR>"));
	goto error;
    }

    $main::pktdesc{nd_unicast_ns}='Got unicast NS: It is STALE';
    $main::pktdesc{nd_unicast_ns_sll}='Got unicast NS: It is STALE';
    %ret=vRecv($if, $wait_delay, 0, 1,
	       nd_unicast_ns,
	       nd_unicast_ns_sll,
	       );
    if($ret{status} == 0) {
	return("STALE");
    }
    vLogHTML("Never get unicast NS: It is REACHABLE<BR>");
    return("REACHABLE");

error:
    vLogHTML(ndErrmsg("It was unknown state<BR>"));
    return("UNKNOWN");
}

#
#
#
sub ndIsStale()
{
    return 1;
}

#
#
#
sub ndStatusNum2Str($)
{
    my($num)=@_;
    return "NONCE"      if $num == $stat_none;
    return "INCOMPLETE" if $num == $stat_incomplete;
    return "REACHABLE"  if $num == $stat_reachable;
    return "STALE"      if $num == $stat_stale;
    return "DELAY"      if $num == $stat_delay;
    return "PROBE"      if $num == $stat_probe;
    return "ERROR";
}

#
#
#
sub ndReboot()
{
    vRemote("reboot.rmt", $remote_debug) && return 1;
    vLogHTML("Target: Reboot<BR>");
    return 0;
}

#
#
#
sub ndRebootAsync()
{
    vRemote("reboot_async.rmt", $remote_debug) && return 1;
    vLogHTML("Target: Reboot<BR>");
    return 0;
}

#
#
#
sub ndClearPrefix()
{
    my($ifs)="ifs=\'@if_name\'";
    vRemote("clearprefix.rmt", $remote_debug, $ifs) && return 1;
    vLogHTML("Target: Clear Prefix Lists<BR>");
    return 0;
}

#
#
#
sub ndClearDefr()
{
    my($ifs)="ifs=\'@if_name\'";
    vRemote("cleardefr.rmt", $remote_debug, $ifs) && return 1;
    vLogHTML("Target: Clear Default Router List<BR>");
    return 0;
}

#
#
#
sub ndClearRoutes()
{
    vRemote("clearroute.rmt", $remote_debug) && return 1;
    vLogHTML("Target: Clear Routes<BR>");
    return 0;
}

#
#
#
sub nd2NoNce($)
{
    my($if) = @_;
    my($ifs)="ifs=\'@if_name\'";

    if(0) {
	vRemote("clearnc.rmt", $remote_debug, $ifs) && return 1;
	vClear($if);
	vLogHTML("Target: Clear Neighbor Cache Entries<BR>");
	return 0;
    }
    if(0) {
	return nd2NoNceByPacket($if, $wait_reachable);
    }
    incLinkAddr($if);
    updateTnDef();
    return 0
}

#
#
#
sub ndNoNce2Incomplete($)
{
    my($if) = @_;
    my(%ret, %ret2);

    $main::pktdesc{nd_echo_request}='Send echo-request';
    %ret2=vSend($if, nd_echo_request);
    return 1 if $ret{status} != 0;

    $main::pktdesc{nd_multicast_ns}='Got multicast NS, then INCOMPLETE state';
    $main::pktdesc{nd_dad_ns}='Got DAD NS';
    while(1) {
	%ret=vRecv($if, $wait_ns, $ret2{sentTime1}, 1,
		   nd_multicast_ns,
		   nd_dad_ns,
		   );
	if($ret{status} != 0) {
	    vLogHTML(ndErrmsg("ERROR: Never got a multicast NS<BR>"));
	    vLogHTML(vErrmsg(%ret)."<BR>");
	    return 1;
	}
	if($ret{recvFrame} eq nd_multicast_ns) {
	    last;
	} elsif($ret{recvFrame} eq nd_dad_ns) {
	    next;
	}
    }

    vLogHTML("Target: INCOMPLETE state<BR>");
    return 0;
}

#
#
#
sub ndNoNce2IncompleteZ($)
{
    my($if) = @_;
    my(%ret, %ret2);

    $main::pktdesc{nd_echo_request_from_z}='Send echo-request';
    %ret2=vSend($if, nd_echo_request_from_z);
    return 1 if $ret{status} != 0;

    $main::pktdesc{nd_multicast_ns_to_z}='Got multicast NS, then INCOMPLETE state';
    $main::pktdesc{nd_dad_ns}='Got DAD NS';
    while(1) {
	%ret=vRecv($if, $wait_ns, $ret2{sentTime1}, 1,
		   nd_multicast_ns_to_z,
		   nd_dad_ns,
		   );
	if($ret{status} != 0) {
	    vLogHTML(ndErrmsg("ERROR: Never got a multicast NS<BR>"));
	    vLogHTML(vErrmsg(%ret)."<BR>");
	    return 1;
	}
	if($ret{recvFrame} eq nd_multicast_ns_to_z) {
	    last;
	} elsif($ret{recvFrame} eq nd_dad_ns) {
	    next;
	}
    }

    vLogHTML("Target: INCOMPLETE state<BR>");
    return 0;
}

#
#
#
sub ndIncomplete2Reachable($)
{
    my($if) = @_;
    my(%ret, %ret2, $i);

    $main::pktdesc{nd_unicast_na_rSO_tll}='Send unicast NA(rSO) w/ TLL';
    %ret2=vSend($if, nd_unicast_na_rSO_tll);
    return 1 if $ret{status} != 0;

    $main::pktdesc{nd_multicast_ns}=
	'<FONT COLOR="#FF0000">WARNING: Got multicast NS, but ignore</FONT>';
    $main::pktdesc{nd_echo_reply}=
	'Got echo-reply, then REACHABLE state';
    for($i=0; $i<$MAX_MULTICAST_SOLICIT; $i++) {
	%ret=vRecv($if, $wait_echo, $ret2{sentTime1}, 1, 
		   nd_multicast_ns,
		   nd_echo_reply
		   );
	if($ret{status} != 0) {
	    vLogHTML(ndErrmsg("ERROR: Never got an echo_reply<BR>"));
	    vLogHTML(vErrmsg(%ret)."<BR>");
	    return 1;
	}
	next if $ret{recvFrame} eq nd_multicast_ns;
	last;
    }
    if($i == $MAX_MULTICAST_SOLICIT) {
	vLogHTML(ndErrmsg("ERROR: Too many multicast NS<BR>"));
	return 1 if $debug == 0;
    }

    vLogHTML("Target: REACHABLE state<BR>");
    vSleep(1);
    return 0;
}

#
#
#
sub ndIncomplete2ReachableZ($)
{
    my($if) = @_;
    my(%ret, %ret2, $i);

    $main::pktdesc{nd_unicast_na_rSO_tll_from_z}='Send unicast NA(rSO) w/ TLL'.
	'(but diff. LLA)';
    %ret2=vSend($if, nd_unicast_na_rSO_tll_from_z);
    return 1 if $ret{status} != 0;

    $main::pktdesc{nd_multicast_ns_to_z}=
	'<FONT COLOR="#FF0000">WARNING: Got multicast NS, but ignore</FONT>';
    $main::pktdesc{nd_echo_reply_to_z}=
	'Got echo-reply, then REACHABLE state';
    for($i=0; $i<$MAX_MULTICAST_SOLICIT; $i++) {
	%ret=vRecv($if, $wait_echo, $ret2{sentTime1}, 1, 
		   nd_multicast_ns_to_z,
		   nd_echo_reply_to_z
		   );
	if($ret{status} != 0) {
	    vLogHTML(ndErrmsg("ERROR: Never got an echo_reply<BR>"));
	    vLogHTML(vErrmsg(%ret)."<BR>");
	    return 1;
	}
	next if $ret{recvFrame} eq nd_multicast_ns_to_z;
	last;
    }
    if($i == $MAX_MULTICAST_SOLICIT) {
	vLogHTML(ndErrmsg("ERROR: Too many multicast NS<BR>"));
	return 1 if $debug == 0;
    }

    vLogHTML("Target: REACHABLE state<BR>");
    vSleep(1);
    return 0;
}

#
#
#
sub ndReachable2Stale()
{
    vSleep($wait_reachable);
    vLogHTML("Target: STALE state<BR>");
    return 0;
}

#
#
#
sub ndReachable2StaleZ()
{
    vSleep($wait_reachable);
    vLogHTML("Target: STALE state<BR>");
    return 0;
}

#
#
#
sub ndStale2Probe($)
{
    my($if) = @_;

    $main::pktdesc{nd_echo_request}='Send echo-request';
    %ret=vSend($if, nd_echo_request);
    %ret=vSend($if, nd_echo_request)
	if $V6evalTool::NutDef{System} =~ /solaris/;

    $main::pktdesc{nd_echo_reply}='Got echo-reply, then DELAY->PROBE state';
    %ret=vRecv($if, $wait_echo, $ret{sentTime1}, 1, nd_echo_reply);
    if($ret{status} != 0) {
	vLogHTML(ndErrmsg("ERROR: Never got an echo_reply<BR>"));
	vLogHTML(vErrmsg(%ret)."<BR>");
	return 1;
    }

    $main::pktdesc{nd_unicast_ns}='Got unicast NS, then PROBE state';
    $main::pktdesc{nd_unicast_ns_sll}='Got unicast NS, then PROBE state';
    %ret=vRecv($if, $wait_ns+$wait_delay, 0, 1,
	       nd_unicast_ns,
	       nd_unicast_ns_sll);
    if($ret{status} != 0) {
	vLogHTML(ndErrmsg("ERROR: Never got an unicast NS<BR>"));
	vLogHTML(vErrmsg(%ret)."<BR>");
	return 1;
    }

    vLogHTML("Target: PROBE state<BR>");
    return 0;
}

#
#
#
sub ndStale2ProbeZ($)
{
    my($if) = @_;

    $main::pktdesc{nd_echo_request_from_z}='Send echo-request';
    %ret=vSend($if, nd_echo_request_from_z);
    %ret=vSend($if, nd_echo_request_from_z)
	if $V6evalTool::NutDef{System} =~ /solaris/;

    $main::pktdesc{nd_echo_reply_to_z}='Got echo-reply, then DELAY->PROBE state';
    %ret=vRecv($if, $wait_echo, $ret{sentTime1}, 1, nd_echo_reply_to_z);
    if($ret{status} != 0) {
	vLogHTML(ndErrmsg("ERROR: Never got an echo_reply<BR>"));
	vLogHTML(vErrmsg(%ret)."<BR>");
	return 1;
    }

    $main::pktdesc{nd_unicast_ns_to_z}='Got unicast NS, then PROBE state';
    $main::pktdesc{nd_unicast_ns_sll_to_z}='Got unicast NS, then PROBE state';
    %ret=vRecv($if, $wait_ns+$wait_delay, 0, 1,
	       nd_unicast_ns_to_z,
	       nd_unicast_ns_sll_to_z);
    if($ret{status} != 0) {
	vLogHTML(ndErrmsg("ERROR: Never got an unicast NS<BR>"));
	vLogHTML(vErrmsg(%ret)."<BR>");
	return 1;
    }

    vLogHTML("Target: PROBE state<BR>");
    return 0;
}

#
#
#
sub nd2Incomplete($)
{
    my($if) = @_;

    return 1 if nd2NoNce($if) != 0;
    return ndNoNce2Incomplete($if);
}

#
#
#
sub nd2IncompleteZ($)
{
    my($if) = @_;

    return 1 if nd2NoNce($if) != 0;
    return ndNoNce2IncompleteZ($if);
}

#
#
#
sub nd2Reachable($)
{
    my($if) = @_;

    return 1 if nd2Incomplete($if) != 0;
    return ndIncomplete2Reachable($if);
}

#
#
#
sub nd2ReachableZ($)
{
    my($if) = @_;

    return 1 if nd2IncompleteZ($if) != 0;
    return ndIncomplete2ReachableZ($if);
}

#
#
#
sub nd2Stale($)
{
    my($if) = @_;

    return 1 if nd2Reachable($if) != 0;
    return ndReachable2Stale();
}

#
#
#
sub nd2StaleZ($)
{
    my($if) = @_;

    return 1 if nd2ReachableZ($if) != 0;
    return ndReachable2StaleZ();
}

#
#
#
sub nd2Probe($)
{
    my($if) = @_;

    return 1 if nd2Stale($if) != 0;
    return ndStale2Probe($if);
}

#
#
#
sub nd2ProbeZ($)
{
    my($if) = @_;

    return 1 if nd2StaleZ($if) != 0;
    return ndStale2ProbeZ($if);
}

#
#
#
sub ndNoNce2ReachableByRa($)
{
    my($if)=@_;

    vLogHTML("ndNoNce2ReachableByRa: Send unsolicited RA w/ SLL<BR>")
	if $debug;
    $main::pktdesc{nd_unsol_ra_sll}='Send RA w/ SLL, then STALE state';
    %ret=vSend($if, nd_unsol_ra_sll);
    return 1 if $ret{status} != 0;
    vLogHTML("Target: STALE state<BR>");

    vLogHTML("ndNoNce2ReachableByRa: Ignore DAD packets for $wait_dad sec<BR>")
	if $debug;
    vRecv($IF, $wait_dad, 0, 0);

    vLogHTML("ndNoNce2ReachableByRa: Send RSO NA w/ TLL<BR>")
	if $debug;
    $main::pktdesc{nd_unicast_na_RSO_tll}='Send NA(RSO) w/ TLL'.
	', then REACHABLE state';
    %ret=vSend($if, nd_unicast_na_RSO_tll);
    return 1 if $ret{status} != 0;
    vLogHTML("Target: REACHABLE state w/ IsRouter flag<BR>");

    return 0;
}

sub ndNoNce2ReachableByRaZ($)
{
    my($if)=@_;

    vLogHTML("ndNoNce2ReachableByRaZ: Send unsolicited RA w/ SLL<BR>")
	if $debug;
    $main::pktdesc{nd_unsol_ra_sll_from_z}='Send RA w/ SLL(but diff LLA)'.
	', then STALE state';
    %ret=vSend($if, nd_unsol_ra_sll_from_z);
    return 1 if $ret{status} != 0;
    vLogHTML("Target: STALE state<BR>");

    vLogHTML("ndNoNce2ReachableByRaZ: Ignore DAD packets for $wait_dad sec<BR>")
	if $debug;
    vRecv($IF, $wait_dad, 0, 0);

    vLogHTML("ndNoNce2ReachableByRaZ: Send RSO NA w/ TLL<BR>")
	if $debug;
    $main::pktdesc{nd_unicast_na_RSO_tll_from_z}='Send NA(RSO) w/ TLL'.
	', then REACHABLE state';
    %ret=vSend($if, nd_unicast_na_RSO_tll_from_z);
    return 1 if $ret{status} != 0;
    vLogHTML("Target: REACHABLE state w/ IsRouter flag<BR>");

    return 0;
}

#
#
#
sub nd2ReachableByRa($)
{
    my($if)=@_;
#    return 1 if nd2NoNce($if) != 0;
    return ndNoNce2ReachableByRa($if);
}

#
#
#
sub nd2ReachableByRaZ($)
{
    my($if)=@_;
#    return 1 if nd2NoNce($if) != 0;
    return ndNoNce2ReachableByRaZ($if);
}

#
#
#
sub ndPrintSummary(\%\%$)
{
    my($title, $result, $idx) = @_;
    my($s, $m);

    vLogHTML('-' x 75 ."<BR>");
    foreach(0..$idx) {
	$m = '*';
	if($$result{$_} == $V6evalTool::exitPass) {
	    $m = ' ';
	    $s = 'PASS';
	} elsif($$result{$_} == $V6evalTool::exitFail) {
	    $s = 'FAIL';
	} elsif ($$result{$_} == $V6evalTool::exitDC) {
	    $s = "Don't Care";
	} elsif ($$result{$_} == $V6evalTool::exitNS) {
	    $s = 'Not supported';
	} elsif ($$result{$_} == $V6evalTool::exitWarn) {
	    $s = 'WARN';
	} else {
	    $s = '???';
	}
	vLogHTML(sprintf("%s%-65s %s<BR>", $m, $$title{$_}, $s));
    }
    vLogHTML('-' x 75 . "<BR>");
}

#
#
#
sub ndPrintSummaryHTML($\@\%\%$)
{
    my($header, $col, $title, $result, $idx) = @_;
    my($s, $m);

    vLogHTML("<HR>\n<TABLE BORDER=1><CAPTION>$header</CAPTION>\n<TR>");
    vLogHTML("<TH>P/F</TH>");
    foreach(@$col) {
	vLogHTML("<TH>$_</TH>")
    }
    vLogHTML("<TH>JDG</TH>");
    vLogHTML("</TR>\n");

    foreach(0..$idx) {
	vLogHTML("<TR>");
	$m = '*';
	if($$result{$_} == $V6evalTool::exitPass) {
	    $m = ' ';
	    $s = 'PASS';
	} elsif($$result{$_} == $V6evalTool::exitFail) {
	    $s = 'FAIL';
	} elsif ($$result{$_} == $V6evalTool::exitDC) {
	    $s = "Don't Care";
	} elsif ($$result{$_} == $V6evalTool::exitNS) {
	    $s = 'Not supported';
	} elsif ($$result{$_} == $V6evalTool::exitWarn) {
	    $s = 'WARN';
	} else {
	    $s = '???';
	}
	if($m eq '*') {
	    vLogHTML("<TD><FONT SIZE=\"+3\" COLOR=\"#FF0000\">$m</FONT></TD>");
	} else {
	    vLogHTML("<TD><BR></TD>");
	}
	vLogHTML("$$title{$_}");
	vLogHTML("<TD><A HREF=\"#T$_\">$s</A></TD>");
	vLogHTML("</TR>\n");
    }
    vLogHTML("</TABLE>\n");
}

#
#
#
sub ndInitTimer() {
    require 'sys/syscall.ph';

    $TIMEVAL_T = "LL";
    $TimerDone = $TimerStart = pack($TIMEVAL_T, ());
    syscall( &SYS_gettimeofday, $TimerStart, 0) != -1
	or return 1;
    @TimerStart = unpack($TIMEVAL_T, $TimerStart);
}

#
#
#
sub ndExpireTimer($) {
    my($timeout)=@_;
    syscall( &SYS_gettimeofday, $TimerDone, 0) != -1
	or return 1;
    @TimerDone  = unpack($TIMEVAL_T, $TimerDone);
    my $x = $TimerDone[0] - $TimerStart[0];
    print STDERR "timer$TimerDone[0] - $TimerStart[0] = $x < $timeout\n"
	if $debug;
    return 0 if ($TimerDone[0] - $TimerStart[0]) >= $timeout;
    return 1;
}

#
#	Start
#	  |                                          multicast NS
#	  |                                          unicast NS
#	wait (RETRANS_TIMER * MAX_MULTICAST_SOLICIT) ----> Done
#	  |
#	  |<---- (A)
#	  |
#	send echo_request
#	  |
#	  |                                          multicast NS
#	wait (RETRANS_TIMER * MAX_MULTICAST_SOLICIT) ----> Done
#	  |
#	  |                           unicast NS
#	wait (DELAY_FIRST_PROBE_TIME) ----> Done
#	  |
#	  |
#	wait (REACHABLE_TIME * MAX_RANDOM_FACTOR)
#	  |
#	  |
#	goto (A)
#
sub nd2NoNceByPacket($$)
{
    my($if, $reachable_time)=@_;
    my($max)=$MAX_MULTICAST_SOLICIT*3;
    my(%ret, $i);

    $main::pktdesc{nd_echo_request}=
	'Send echo-request';
    $main::pktdesc{nd_multicast_ns}=
	'Got multicast NS, then INCOMPLETE state';
    $main::pktdesc{nd_unicast_ns}=
	'Got unicast NS, then PROBE state';
    $main::pktdesc{nd_unicast_ns_sll}=
	'Got unicast NS, then PROBE state';
    $main::pktdesc{nd_unicast_ns_to_z}=
	'Got unicast NS, then PROBE state';
    $main::pktdesc{nd_unicast_ns_sll_to_z}=
	'Got unicast NS, then PROBE state';
    $main::pktdesc{nd_echo_reply}=
	'Got echo-reply, then REACHABLE/DELAY state';
    $main::pktdesc{nd_echo_reply_to_z2}=
	'Got echo-reply, then REACHABLE/DELAY state';

    %ret=vRecv($if, $wait_ns, 0, 1,
	       nd_multicast_ns,
	       nd_unicast_ns,
	       nd_unicast_ns_sll,
	       nd_unicast_ns_to_z,
	       nd_unicast_ns_sll_to_z,
	       );
    if($ret{status} == 0) {
	goto found_multi if($ret{recvFrame} eq nd_multicast_ns);
	goto found_uni;
    }

    for($i=0; $i<2; $i++) {

	%ret=vSend($if, nd_echo_request);
	%ret=vSend($if, nd_echo_request)
	    if $V6evalTool::NutDef{System} =~ /solaris/;

        %ret=vRecv($if, $wait_ns, $ret{sentTime1}, 1,
		   nd_echo_reply,
		   nd_echo_reply_to_z2,
		   nd_multicast_ns,
		   );
        goto found_multi
	    if $ret{status} == 0 && $ret{recvFrame} eq nd_multicast_ns;
        goto error
	    if $ret{status} != 0;

	%ret=vRecv($if, $wait_delay, 0, 1,
		   nd_unicast_ns,
		   nd_unicast_ns_sll,
		   nd_unicast_ns_to_z,
		   nd_unicast_ns_sll_to_z,
		   );
	goto found_uni if $ret{status} == 0;
	vLogHTML("Then REACHABLE<BR>");

	if($i == 0) {
	    vLogHTML("wait for STALE ($reachable_time sec)<BR>");
	    vSleep($reachable_time);
	}
    }
    goto error;

  found_multi:
    $main::pktdesc{nd_unicast_ns}=
	ndErrmsg('ERROR: Why NUT sent unicast NS?');
    $main::pktdesc{nd_unicast_ns_sll}=
	ndErrmsg('ERROR: Why NUT sent unicast NS?');
    $main::pktdesc{nd_unicast_ns_to_z}=
	ndErrmsg('ERROR: Why NUT sent unicast NS?');
    $main::pktdesc{nd_unicast_ns_sll_to_z}=
	ndErrmsg('ERROR: Why NUT sent unicast NS?');
    for($i=0; $i<$max; $i++) {
	%ret=vRecv($if, $RETRANS_TIMER*2, 0, 1,
		   nd_multicast_ns,
		   nd_unicast_ns,
		   nd_unicast_ns_sll,
		   nd_unicast_ns_to_z,
		   nd_unicast_ns_sll_to_z,
		   );
	last if $ret{status} == 1; # time out
	next if $ret{status} == 0;
	goto error;
    }
    if($i == $max) {
	vLogHTML(ndErrmsg("ERROR: Too many unicast/multicast NSs ".
			  "(> $max)<BR>"));
	goto error if $debug == 0;
    }
    vLogHTML("Clear NC[TN]<BR>");
    goto end;

  found_uni:
    $main::pktdesc{nd_multicast_ns}=
	ndErrmsg('ERROR: Why NUT sent multicast NS?');
    for($i=0; $i<$max; $i++) {
	%ret=vRecv($if, $RETRANS_TIMER*2, 0, 1,
		   nd_multicast_ns,
		   nd_unicast_ns,
		   nd_unicast_ns_sll,
		   nd_unicast_ns_to_z,
		   nd_unicast_ns_sll_to_z,
		   );
	last if $ret{status} == 1; # time out
	next if $ret{status} == 0;
	goto error;
    }
    if($i == $max) {
	vLogHTML(ndErrmsg("ERROR: Too many unicast/multicast NSs ".
			  "(> $max)<BR>"));
	goto error if $debug == 0;
    }
    vLogHTML("Clear NC[TN]<BR>");
    goto end;

  end:
    $main::pktdesc{nd_unicast_ns}=
	'Got unicast NS';
    $main::pktdesc{nd_unicast_ns_sll}=
	'Got unicast NS';
    $main::pktdesc{nd_unicast_ns_to_z}=
	'Got unicast NS';
    $main::pktdesc{nd_unicast_ns_sll_to_z}=
	'Got unicast NS';
    $main::pktdesc{nd_multicast_ns}=
	'Got multicast NS';
    return 0;

  error:
    vLogHTML(vErrmsg(%ret)."<BR>");
    return 1;

}

#
#
#
sub ndErrmsg($)
{
    my($msg)=@_;
    "<FONT COLOR=\"#FF0000\">$msg</FONT>";
}

#
#
#
sub ndWarnmsg($)
{
    my($msg)=@_;
    "<FONT COLOR=\"#00FF00\">$msg</FONT>";
}

########################################################################

#
#
#
sub readout($$)
{
    my($if, $timeout) = @_;
    my(%ret);

    $timeout *= 2
	if $V6evalTool::NutDef{System} =~ /solaris/; # patch for solaris
    %ret=vRecv($if, $timeout, 0, 0);
    vLogHTML("$ret{recvCount} packet(s) were thrown away<BR>") if $debug;
    $ret{recvCount};
}

#
#
#
sub updateTnDef()
{
    if(open(FILE, "> tn.def") == 0) {
	vLogHTML("updateTnDef: ./tn.def: $!<BR>");
	exit $V6evalTool::exitFatal;
    }
    foreach(keys(%V6evalTool::TnDef)) {
	if(/_device$/ || /_addr$/ || /^s*$/) {
	    next;
	}
	print FILE "$_ $V6evalTool::TnDef{$_}\n";
	print "updateTnDef: $_ $V6evalTool::TnDef{$_}\n";
    }
    close(FILE);
}

#
#
#
sub incLinkAddr($)
{
    my($if)=@_;
    my($mac)=$V6evalTool::TnDef{$if."_addr"};
    my($newmac)=incMac($mac);
    vLogHTML("New LLA of TN: $newmac<BR>");
    $V6evalTool::TnDef{$if."_addr"}=$newmac;
    $V6evalTool::TnDef{$if}=$V6evalTool::TnDef{$if."_device"}.
	" ".$V6evalTool::TnDef{$if."_addr"};
}

#
#
#
sub incMac($)
{
    my($hex)=@_;
    my($max)=hex(ffffff);
    my($mask)=$max+1;
    my($offset)=128;

    my(@hex)=split(/:/, $hex);
    my($uhex)="$hex[0]$hex[1]$hex[2]";
    my($lhex)="$hex[3]$hex[4]$hex[5]";

    my($udec)=hex($uhex);
    my($ldec)=hex($lhex);
    $ldec++;

    if($ldec > $max) {
	$ldec%=$mask;
	$udec++;
	if($udec > $max) {
	    $udec%=$mask;
	}
    }

    if(($udec==0 && $ldec==0) ||
       ($udec==$max && $ldec==$max)) {
	$udec=0;
	$ldec=$offset;
    }

    my($uhex2)=sprintf("%06x", $udec);
    my($lhex2)=sprintf("%06x", $ldec);

    my(@uhex2)=split(//, $uhex2);
    my(@lhex2)=split(//, $lhex2);

    my($hex3)="$uhex2[0]$uhex2[1]:$uhex2[2]$uhex2[3]:$uhex2[4]$uhex2[5]:".
	"$lhex2[0]$lhex2[1]:$lhex2[2]$lhex2[3]:$lhex2[4]$lhex2[5]";
    return($hex3);
}

########################################################################
1;

########################################################################
__END__

=head1 NAME

  ndStatus - Examining neighbor cache state

=head1 DESCRIPTION

  Start
    |
    |		Got a packet specified by @ignore_ip
    |<--------------------------------------------+
    |                                             |
  Wait (RETRANS_TIMER * MAX_*CAST_SOLICIT) -------+
    |
    |	Got a multicast NS
    |	or a packet specified by @incomplete_ip
    +---------------------------> [INCOMPLETE]
    |
    |	Got an unicast NS
    |	or a packet specified by @probe_ip
    +---------------------------> [PROBE]
    |
    |	Got otherwise
    +---------------------------> [ERROR]
    |
    |	Got a packet specified by @reply_ip
    +---------------------------> <reachable_or_stale>
    |
    | Timeout
    |
  Send an echo-request
    |
    |
    |		Got a packet specified by @ignore_n
    |<--------------------------------------------+
    |                                             |
  Wait (2 sec) -----------------------------------+
    |
    |	Got a multicast NS
    |	or a packet specified by @nonce_n
    +---------------------------> [NONCE]
    |
    |	Got otherwise, timeout
    +---------------------------> [ERROR]
    |
    | Got an echo-reply
    |
    |
    + <-------------------------- <reachable_or_stale>
    |
    |		Got a packet specified by @ignore_sr
    |<--------------------------------------------+
    |                                             |
  Wait (DELAY_FIRST_PROBE_TIME)-------------------+
    |
    |	Got an unicast NS
    |	or a packet specified by @stale_sr
    +---------------------------> [STALE]
    |
    |	Got otherwise
    +---------------------------> [ERROR]
    |
    | Timeout
    |
  [REACHABLE]

=cut
