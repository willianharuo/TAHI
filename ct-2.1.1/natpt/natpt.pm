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
# $TAHI: ct/natpt/natpt.pm,v 1.4 2001/10/11 01:41:46 akisada Exp $
#

package natpt;

use Exporter;
@ISA = qw(Exporter);
@EXPORT = qw(
	        send_recv
		config_natpt 
                add_v4_route
                add_v6_route
		config_host_v4 
		reboot
		checkNUT
	        pingtest_natpt
	    );

use V6evalTool;

BEGIN { }
END { }

$ON=1;
$OFF=0;

$PASS=$V6evalTool::exitPass;
$WARN=$V6evalTool::exitWarn;
$FAIL=$V6evalTool::exitFail;
$FATAL=$V6evalTool::exitFatal;

$IF_ID_0="Link0";
$IF_ID_1="Link1";
$NUT_LINK0_device=$V6evalTool::NutDef{Link0_device};
$NUT_LINK1_device=$V6evalTool::NutDef{Link1_device};

$TN_LINK0_V4_ADDRESS="192.168.0.1";
$NUT_LINK0_V4_ADDRESS="192.168.0.2";
$TN_LINK0_V6_ADDRESS="3ffe:501:ffff:100::1";
$NUT_LINK0_V6_ADDRESS="3ffe:501:ffff:100::2";

$TN_LINK1_V4_ADDRESS="192.168.1.1";
$NUT_LINK1_V4_ADDRESS="192.168.1.2";
$TN_LINK1_V6_ADDRESS="3ffe:501:ffff:101::1";
$NUT_LINK1_V6_ADDRESS="3ffe:501:ffff:101::2";

$type=$V6evalTool::NutDef{Type};

$TN_LINK0_MAC_ADDRESS=$V6evalTool::TnDef{Link0_addr};
$NUT_LINK0_MAC_ADDRESS=$V6evalTool::NutDef{Link0_addr};
$TN_LINK1_MAC_ADDRESS=$V6evalTool::TnDef{Link1_addr};
$NUT_LINK1_MAC_ADDRESS=$V6evalTool::NutDef{Link1_addr};

$TN_LINK0_LINKLOCAL_ADDRESS=vMAC2LLAddr($TN_LINK0_MAC_ADDRESS);
$NUT_LINK0_LINKLOCAL_ADDRESS=vMAC2LLAddr($NUT_LINK0_MAC_ADDRESS);
$TN_LINK1_LINKLOCAL_ADDRESS=vMAC2LLAddr($TN_LINK1_MAC_ADDRESS);
$NUT_LINK1_LINKLOCAL_ADDRESS=vMAC2LLAddr($NUT_LINK1_MAC_ADDRESS);

#
# send locally defined 'ipv4_packet' on link0
# recv locally defined 'ipv6_packet' on link1
#   handle Neighbor Solicitation/Neighbor Advertisement
sub send_recv ($$$@) {
    my($IF, $packet, $IF1, @packet1) = @_;
    my $unexpectCntTotal = 0;
    vSend($IF, $packet) if defined($packet);

recv_start:
    %ret=vRecv($IF1,5,0,0,@packet1, 
	       ns_nut2tn_natpt0, ns_nut2tn_siit0, arp_nut2tn_request);

# First check if we received unexpected packets
    my $unexpectCnt = $ret{recvCount};
    $unexpectCnt-- if($ret{status}==0);
    if($unexpectCnt > 0) {
	vLogHTML("<FONT COLOR=#FF0000>".
		 "Recv $unexpectCnt unexpected packet(s)</FONT><BR>");
	$unexpectCntTotal += $unexpectCnt;
    }

# Then see what else we got
    if ($ret{status} != 0) {
	if (@packet1[0] eq '' && $unexpectCntTotal == 0) {
	    return $V6evalTool::exitPass; # Expected no packets and got none
	} else {
	    goto recv_fail;
	}
    }
    if ($ret{recvFrame} eq 'ns_nut2tn_natpt0') {
	vSend($IF1, na_tn2nut_natpt0);
	goto recv_start;
    }
    if ($ret{recvFrame} eq 'ns_nut2tn_siit0') {
	vSend($IF1, na_tn2nut_siit0);
	goto recv_start;
    }
    if ($ret{recvFrame} eq 'arp_nut2tn_request') {
	vSend($IF1, arp_tn2nut_reply);
	goto recv_start;
    }
    for(my $i=0; @packet1[$i] ne ''; $i++) {
	if ($ret{recvFrame} eq @packet1[$i]) {
	    return $V6evalTool::exitPass; # Got one of the packets expected
	}	
    }
    if($ret{status} == 0) {
	goto recv_fail;
    }
    
# If we end up here, something has failed.
  recv_fail:
    vLogHTML("<FONT COLOR=#FF0000><H3>NG</H3></FONT>");
    return $V6evalTool::exitFail;
}

sub config_natpt ($$$$$$$$) {
	my ($NUT_v6_filter_device, $Filter_Direction_v6,
	    $NUT_NATPT_V6_prefix, $NUT_NATPT_V6_prefixlen, 
	    $NUT_v4_filter_device, $Filter_Direction_v4,
	    $NUT_NATPT_V4_prefix, $NUT_NATPT_V4_prefixlen)
	    = @_;
	
	$Filter_Direction_v6 = "in" if($Filter_Direction_v6 ne "out");
	$Filter_Direction_v4 = "in" if($Filter_Direction_v4 ne "out");

	vRemote("natpt.rmt",
		"if=$NUT_v6_filter_device ".
		"addrfamily=inet6 ".
		"direction=$Filter_Direction_v6 ".
		"dstprefix=$NUT_NATPT_V6_prefix ".
		"dstprefixlen=$NUT_NATPT_V6_prefixlen ".
		"natprefix=0.0.0.0 ".
		"natprefixlen=0 ")
	    && return $FATAL;

	vRemote("natpt.rmt",
		"if=$NUT_v4_filter_device ".
		"addrfamily=inet ".
		"direction=$Filter_Direction_v4 ".
		"dstprefix=$NUT_NATPT_V4_prefix ".
		"dstprefixlen=$NUT_NATPT_V4_prefixlen ".
		"natprefix=$NUT_NATPT_V6_prefix ".
		"natprefixlen=96 ")
	    && return $FATAL;
	
	return $PASS;
}

sub add_v4_route ($$$$) {
	my ($IF, $PREFIX, $PREFIXLEN, $METRIC)=@_;
	
	vRemote("route.rmt",
		"if=$IF ".
		"addrfamily=inet ".
		"prefix=$PREFIX ".
		"prefixlen=$PREFIXLEN ".
		"metric=$METRIC ".
		"cmd=add ")
	    && return $FATAL;

	return $PASS;
}

sub add_v6_route ($$$$) {
	my ($IF, $PREFIX, $PREFIXLEN, $METRIC)=@_;
	
	vRemote("route.rmt",
		"if=$IF ".
		"addrfamily=inet6 ".
		"prefix=$PREFIX ".
		"prefixlen=$PREFIXLEN ".
		"metric=$METRIC ".
		"cmd=add ")
	    && return $FATAL;

	return $PASS;
}

sub config_host_v4 (;$) {
	my ($IF)=@_;
	$IF=$IF_ID_0 if (! $IF);
	
	my ($NUT_device,$NUT_V4_ADDRESS,$TN_V4_ADDRESS);
	
	if ($IF eq $NUT_LINK1_device) {
		$NUT_device=$NUT_LINK1_device;
		$NUT_V4_ADDRESS=$NUT_LINK1_V4_ADDRESS; 
	}elsif($IF eq "$IF_ID_0") {
		$NUT_device=$NUT_LINK0_device;
		$NUT_V4_ADDRESS=$NUT_LINK0_V4_ADDRESS; 
	}else {
		return $FATAL;
	}
		
	vRemote("manualaddrconf.rmt",
		"if=$NUT_device ".
		"addrfamily=inet ".
		"addr=$NUT_V4_ADDRESS ".
		"type=add")
	    && return $FATAL;

	return $PASS;
}

sub reboot () {
	vLogHTML("Remote boot NUT. ");
	$ret=vRemote("reboot.rmt","");
	if ($ret > 0) {
		vLog("vRemote reboot.rmt exit $ret");
		exit $FATAL;
	}

	return $V6evalTool::exitIgnore;
}

#
# check NUT type, host or router
#

sub checkNUT ($) {
	my ($scripttype)=@_;

	if($scripttype eq 'hostrouter') {
		return;
	}elsif($scripttype eq 'host' && $type eq 'host') {
		return;
	}elsif($scripttype eq 'router' && $type eq 'router') {
		return;
	}elsif($scripttype eq 'host' && $type eq 'router') {
		vLogHTML("This test is for the host!!<BR>");
		exit $V6evalTool::exitHostOnly;
	}elsif($scripttype eq 'router' && $type eq 'host') {
		vLogHTML("This test is for the router!!<BR>");
		exit $V6evalTool::exitRouterOnly;
	}else {
		vLogHTML("Unknown NUT Type $type - check nut.def<BR>");
		exit $V6evalTool::exitFatal;
	}
}

sub pingtest_natpt() {
# Interface 
    $IF="Link0";
    $IF1="Link1";
    vCapture($IF);
    vCapture($IF1);
    
%pktdesc = (
  echo_request_nut2tn_natpt         => 'Send V6 Echo Request on Link0',
  echo_request_v4_nut2tn_df         => 'Recv V4 Echo Request on Link1',
  echo_reply_v4_tn2nut_df           => 'Send V4 Echo Reply on Link1',
  echo_reply_nut2tn_natpt           => 'Recv V6 Echo Reply on Link0',
  echo_request_nut2tn_natpt_frag    => 'Send V6 Echo Request on Link0',
  echo_request_v4_nut2tn            => 'Recv V4 Echo Request on Link1',
  echo_reply_v4_tn2nut              => 'Send V4 Echo Reply on Link1',
  echo_reply_nut2tn_natpt_frag      => 'Recv V6 Echo Reply on Link0',

  arp_nut2tn_request => 'Recv ARP request on Link1 (TN IPv4addr)',
  arp_tn2nut_reply   => 'Send ARP reply on Link1 (TN IPv4addr)',
  ns_nut2tn_natpt0   => 'Recv Neighbor Solicitation on Link0 (NAT-PT V6addr)',
  na_tn2nut_natpt0   => 'Send Neighbor Advertisement on Link0 (NAT-PT V6addr)',
);

    # Print out the configuration
    vRemote("confdump.rmt") && return $FATAL;

    $result = $V6evalTool::exitPass;
    $result += send_recv($IF, 'echo_request_tn2nut_natpt', 
			 $IF1, 'echo_request_v4_nut2tn_df');
    $result += send_recv($IF1, 'echo_reply_v4_tn2nut_df', 
			 $IF, 'echo_reply_nut2tn_natpt');
    $result += send_recv($IF, 'echo_request_tn2nut_natpt_frag', 
			 $IF1, 'echo_request_v4_nut2tn');
    $result += send_recv($IF1, 'echo_reply_v4_tn2nut', 
			 $IF, 'echo_reply_nut2tn_natpt_frag');
    
    if($result == $V6evalTool::exitPass) {
	vLogHTML("<H3>OK</H3>");
	exit $V6evalTool::exitPass;
    }
    
  error:
    vLogHTML("<FONT COLOR=#FF0000><H3>NG</H3></FONT>");
    exit $V6evalTool::exitFail;
}
