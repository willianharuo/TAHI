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
# $TAHI: ct/tunnel/tunnel.pm,v 1.13 2002/07/12 02:31:41 masaxmasa Exp $
########################################################################

package tunnel;

use Exporter;
@ISA = qw(Exporter);
@EXPORT = qw(
		makeNCE_TN_LLA
		makeNCE_TN_GA
		sendRA
		makeARPTable_LINK1
		makeARPTable_LINK0
		config_tunnel 
		config_automatic_tunnel
		config_tunnel_offlink 
		config_another_tunnel 
		config_host_v4 
		config_host_v6 
		config_tunnel_mtu
		config_another_tunnel_mtu
		ping6_nut2tn_offlink_address
		ping6_nut2tn_automatic_address
		reboot
		checkNUT
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
$NUT_TUNNEL_device="0";
$NUT_TUNNEL_device1="1";
$NUT_TUNNEL_prefixlen="64";

$TN_LINK0_V4_ADDRESS="192.168.0.1";
$NUT_LINK0_V4_ADDRESS="192.168.0.2";
$TN_LINK0_V6_ADDRESS="3ffe:501:ffff:100::1";
$NUT_LINK0_V6_TUNNEL_ADDRESS="3ffe:501:ffff:102::100";
$NUT_LINK0_V6_TUNNEL1_ADDRESS="3ffe:501:ffff:102::200";

$TN_LINK1_V4_ADDRESS="192.168.1.1";
$NUT_LINK1_V4_ADDRESS="192.168.1.2";
$TN_LINK1_V6_ADDRESS="3ffe:501:ffff:101::1";
$NUT_LINK1_V6_TUNNEL_ADDRESS="3ffe:501:ffff:103::100";
$NUT_LINK1_V6_TUNNEL1_ADDRESS="3ffe:501:ffff:103::200";

$V4_OFFLINK_ADDRESS="192.168.8.1";
$V4_OFFLINK0_ADDRESS="192.168.7.1";

$OFFLINK_GLOBAL_ADDRESS="3ffe:501:ffff:109:200:ff:fe00:a0a0"; # OFFLINK_GLOBAL_ADDRESS
$OFFLINK1_GLOBAL_ADDRESS="3ffe:501:ffff:108:200:ff:fe00:a0a0"; # OFFLINK1_GLOBAL_ADDRESS
$OFFLINK2_GLOBAL_ADDRESS="3ffe:501:ffff:107:200:ff:fe00:a0a0"; # OFFLINK2_GLOBAL_ADDRESS
$OFFLINK3_GLOBAL_ADDRESS="3ffe:501:ffff:106:200:ff:fe00:a0a0"; # OFFLINK3_GLOBAL_ADDRESS

$OFFLINK_AUTOMATIC_ADDRESS="::192.168.7.1"; # OFFLINK_AUTOMATIC_ADDRESS

$type=$V6evalTool::NutDef{Type};

$TN_LINK0_MAC_ADDRESS=$V6evalTool::TnDef{Link0_addr};
$NUT_LINK0_MAC_ADDRESS=$V6evalTool::NutDef{Link0_addr};
$TN_LINK1_MAC_ADDRESS=$V6evalTool::TnDef{Link1_addr};
$NUT_LINK1_MAC_ADDRESS=$V6evalTool::NutDef{Link1_addr};

$TN_LINK0_LINKLOCAL_ADDRESS=vMAC2LLAddr($TN_LINK0_MAC_ADDRESS);
$NUT_LINK0_LINKLOCAL_ADDRESS=vMAC2LLAddr($NUT_LINK0_MAC_ADDRESS);
$TN_LINK1_LINKLOCAL_ADDRESS=vMAC2LLAddr($TN_LINK1_MAC_ADDRESS);
$NUT_LINK1_LINKLOCAL_ADDRESS=vMAC2LLAddr($NUT_LINK1_MAC_ADDRESS);
          
# node constants
$MAX_MULTICAST_SOLICIT=3;       # times
$MAX_UNICAST_SOLICIT=3;         # times
$MAX_ANYCAST_DELAY_TIME=1;      # sec.
$MAX_NEIGHBOR_ADVERTISEMENT=3;  # times
$REACHABLE_TIME=30;             # sec.
$RETRANS_TIMER=1;               # sec.
$DELAY_FIRST_PROBE_TIME=5;      # sec.
$MIN_RANDOM_FACTOR=0.5;         #
$MAX_RANDOM_FACTOR=1.5;         #

$MAX_SOLICIT=3;

$wait_ns=$RETRANS_TIMER*$MAX_SOLICIT+1; # margin: 1sec.
$wait_reachable=$REACHABLE_TIME*$MAX_RANDOM_FACTOR+1; # margin: 1sec.
$wait_delay=$DELAY_FIRST_PROBE_TIME+1; # margin: 1sec.
$wait_dad=3;

$wait_address_resolution=$MAX_MULTICAST_SOLICIT*3+2; # margin: 2sec.

#
# make Neighber Cache Entry
# In NUT,
#   make NUT's link local address	 

sub makeNCE_TN_LLA () {
        my ( $IF );
        $IF=$IF_ID_0 ;
        
		vClear($IF);

        vSend($IF, echo_request_tn2nut_LLA);

        %ret=vRecv($IF,5,0,0, 
			echo_reply_nut2tn_LLA,
			ns_nut2tn_sourceLLA_targetLLA_nooption,
			ns_nut2tn_sourceLLA_targetLLA_optionSLL,
			ns_nut2tn_sourceGA_targetLLA_nooption,
			ns_nut2tn_sourceGA_targetLLA_optionSLL
			);
        if( $ret{status} !=0) {
                vLogHTML("TN(Router) can not receive Echo Reply or ns from NUT");
                return $FAIL;
        }elsif($ret{recvFrame} eq 'echo_reply_nut2tn_LLA') {
		%ret=vRecv($IF,3,0,0, 
				ns_nut2tn_sourceLLA_targetLLA_nooption,
				ns_nut2tn_sourceLLA_targetLLA_optionSLL,
				ns_nut2tn_sourceGA_targetLLA_nooption,
				ns_nut2tn_sourceGA_targetLLA_optionSLL
				);
        	if( $ret{status} !=0) {
		   $ret{recvFrame}='ns_nut2tn_sourceLLA_targetLLA_optionSLL';
		}
	}	
	
	if($ret{recvFrame} eq 'ns_nut2tn_sourceLLA_targetLLA_nooption' ||
	   $ret{recvFrame} eq 'ns_nut2tn_sourceLLA_targetLLA_optionSLL') {
		vSend($IF, na_tn2nut_sourceLLA_destinationLLA_targetLLA);
	}elsif(
	   $ret{recvFrame} eq 'ns_nut2tn_sourceGA_targetLLA_nooption' ||
	   $ret{recvFrame} eq 'ns_nut2tn_sourceGA_targetLLA_optionSLL') {
		vSend($IF, na_tn2nut_sourceGA_destinationGA_targetLLA);
	}       
	%ret=vRecv($IF, 5,0,0,echo_reply_nut2tn_LLA);
	sendRA();
	return $PASS;
}




sub makeNCE_TN_GA (;$) {
        my ( $IF );
        $IF=$IF_ID_0;
        
		vClear($IF);

        vSend($IF, echo_request_tn2nut_GA);

        %ret=vRecv($IF,5,0,0, 
			echo_reply_nut2tn_GA,
			ns_nut2tn_sourceLLA_targetGA_nooption,
			ns_nut2tn_sourceLLA_targetGA_optionSLL,
			ns_nut2tn_sourceGA_targetGA_nooption,
			ns_nut2tn_sourceGA_targetGA_optionSLL
			);
        if( $ret{status} !=0) {
                vLogHTML("TN(Router) can not receive Echo Reply or ns from NUT");
                return $FAIL;
        }elsif($ret{recvFrame} eq 'echo_reply_nut2tn_GA') {
		%ret=vRecv($IF,3,0,0, 
				ns_nut2tn_sourceLLA_targetGA_nooption,
				ns_nut2tn_sourceLLA_targetGA_optionSLL,
				ns_nut2tn_sourceGA_targetGA_nooption,
				ns_nut2tn_sourceGA_targetGA_optionSLL
				);
        	if( $ret{status} !=0) {
		   $ret{recvFrame}='ns_nut2tn_sourceLLA_targetGA_optionSLL';
		}
	}	
	
	if($ret{recvFrame} eq 'ns_nut2tn_sourceLLA_targetGA_nooption' ||
	   $ret{recvFrame} eq 'ns_nut2tn_sourceLLA_targetGA_optionSLL') {
		vSend($IF, na_tn2nut_sourceLLA_destinationLLA_targetGA);
	}elsif(
	   $ret{recvFrame} eq 'ns_nut2tn_sourceGA_targetGA_nooption' ||
	   $ret{recvFrame} eq 'ns_nut2tn_sourceGA_targetGA_optionSLL') {
		vSend($IF, na_tn2nut_sourceGA_destinationGA_targetGA);
	}       
	%ret=vRecv($IF, 5,0,0,echo_reply_nut2tn_GA);
	return $PASS;
}


sub sendRA (;$) {
	my ( $IF ) =@_;
	$IF=$IF_ID_0 if (! $IF ) ;
	if($type eq host ) {
		vSend($IF, ra);
		#-- this part is for igonoreing NS Packet --
		vSleep(5);
		vClear($IF);
	}
}

sub makeARPTable_LINK1 () {
	my ($IF);
	$IF=$IF_ID_1;

	vClear($IF);

	vSend($IF, echo_request_LINK1_v4_tn2nut);

	%ret=vRecv($IF,5,0,0, 
		arp_LINK1_nut2tn_request,
		echo_reply_LINK1_v4_nut2tn
		);
	if( $ret{status} !=0) {
		vLogHTML("TN(Router) can not receive arp request from NUT");
		return $FAIL;
	}elsif($ret{recvFrame} eq 'arp_LINK1_nut2tn_request') {
		vSend($IF,arp_LINK1_tn2nut_reply);		
		%ret=vRecv($IF,5,0,0, 
			echo_reply_LINK1_v4_nut2tn,
			);

		if ($ret{status} != 0) {
			# re-send echo request
			vSend($IF, echo_request_LINK1_v4_tn2nut);
			%ret = vRecv($IF, 5, 0, 0, echo_reply_LINK1_v4_nut2tn);
		}
		else {
			return $PASS;
		}

		if( $ret{status} !=0) {
			vLogHTML("TN(Router) can not receive echo reply from NUT");
			return $FAIL;
		}else {
			return $PASS;
		}
	}elsif($ret{recvFrame} eq 'echo_reply_LINK1_v4_nut2tn') {
		return $PASS;
	}
}

sub makeARPTable_LINK0 () {
	my ($IF);
	$IF=$IF_ID_0;

	vClear($IF);

	vSend($IF, echo_request_LINK0_v4_tn2nut);

	%ret=vRecv($IF,5,0,0, 
		arp_LINK0_nut2tn_request,
		echo_reply_LINK0_v4_nut2tn
		);
	if( $ret{status} !=0) {
		vLogHTML("TN(Router) can not receive arp request from NUT");
		return $FAIL;
	}elsif($ret{recvFrame} eq 'arp_LINK0_nut2tn_request') {
		vSend($IF,arp_LINK0_tn2nut_reply);		
		%ret=vRecv($IF,5,0,0, 
			echo_reply_LINK0_v4_nut2tn,
			);

		if ($ret{status} != 0) {
			# re-send echo request
			vSend($IF, echo_request_LINK1_v4_tn2nut);
			%ret = vRecv($IF, 5, 0, 0, echo_reply_LINK1_v4_nut2tn);
		}
		else {
			return $PASS;
		}

		if( $ret{status} !=0) {
			vLogHTML("TN(Router) can not receive echo reply from NUT");
			return $FAIL;
		}else {
			return $PASS;
		}
	}elsif($ret{recvFrame} eq 'echo_reply_LINK0_v4_nut2tn') {
		return $PASS;
	}
}

sub config_tunnel ($) {
	my ($IF)= @_;
	my ($NUT_device,$SRC_V4_ADDRESS,$DST_V4_ADDRESS,
		$SRC_V6_ADDRESS,$DST_V6_ADDRESS,);
	
	if ($IF eq "$IF_ID_1") {
		$NUT_device=$NUT_LINK1_device;
		$SRC_V4_ADDRESS=$NUT_LINK1_V4_ADDRESS; 
		$DST_V4_ADDRESS=$TN_LINK1_V4_ADDRESS;
		$SRC_V6_ADDRESS=$NUT_LINK1_V6_TUNNEL_ADDRESS;
		$DST_V6_ADDRESS=$OFFLINK2_GLOBAL_ADDRESS;
	}elsif($IF eq "$IF_ID_0") {
		$NUT_device=$NUT_LINK0_device;
		$SRC_V4_ADDRESS=$NUT_LINK0_V4_ADDRESS; 
		$DST_V4_ADDRESS=$TN_LINK0_V4_ADDRESS;
		$SRC_V6_ADDRESS=$NUT_LINK0_V6_TUNNEL_ADDRESS;
		$DST_V6_ADDRESS=$OFFLINK2_GLOBAL_ADDRESS;
	}else {
		return $FATAL;
	}
		
	vRemote("manualaddrconf.rmt",
					"if=$NUT_device ".
					"addrfamily=inet ".
					"type=delete")
					&& return $FATAL;
	vRemote("manualaddrconf.rmt",
					"if=$NUT_device ".
					"addrfamily=inet ".
					"addr=$SRC_V4_ADDRESS ".
					"type=add")
					&& return $FATAL;

	vRemote("tunnel.rmt","if=$NUT_TUNNEL_device ".
					"prefixlen=$NUT_TUNNEL_prefixlen ".
					"routeprefixlen=64 ".
					"addrfamily=inet6 ".
					"prefix=$OFFLINK_GLOBAL_ADDRESS ".
					"srcaddr=$SRC_V4_ADDRESS ".
					"dstaddr=$DST_V4_ADDRESS ".
					"insrcaddr=$SRC_V6_ADDRESS ".
					"indstaddr=$DST_V6_ADDRESS ")
					&& return $FATAL;
	
	return $PASS;
}

sub config_automatic_tunnel ($) {
	my ($IF)= @_;
	my ($NUT_v4_device,$NUT_v6_device,$SRC_V4_ADDRESS,$SRC_TUNNEL_ADDRESS);
	
	if ($IF eq "$IF_ID_1") {
		$NUT_v4_device=$NUT_LINK1_device;
		if($type eq "host") {
			$NUT_v6_device=$NUT_LINK1_device;
			$SRC_TUNNEL_ADDRESS="::".$NUT_LINK1_V4_ADDRESS; 
		}else {
			$NUT_v6_device=$NUT_LINK0_device;
			$SRC_TUNNEL_ADDRESS="::".$NUT_LINK0_V4_ADDRESS; 
		}
		$SRC_V4_ADDRESS=$NUT_LINK1_V4_ADDRESS; 
	}elsif($IF eq "$IF_ID_0") {
		$NUT_v4_device=$NUT_LINK0_device;
		if($type eq "host") {
			$NUT_v6_device=$NUT_LINK0_device;
			$SRC_TUNNEL_ADDRESS="::".$NUT_LINK0_V4_ADDRESS; 
		}else {
			$NUT_v6_device=$NUT_LINK1_device;
			$SRC_TUNNEL_ADDRESS="::".$NUT_LINK1_V4_ADDRESS; 
		}
		$SRC_V4_ADDRESS=$NUT_LINK0_V4_ADDRESS; 
	}else {
		return $FATAL;
	}
		
	vRemote("manualaddrconf.rmt",
					"if=$NUT_v4_device ".
					"addrfamily=inet ".
					"type=delete")
					&& return $FATAL;

	vRemote("manualaddrconf.rmt",
					"if=$NUT_v4_device ".
					"addrfamily=inet ".
					"addr=$SRC_V4_ADDRESS ".
					"type=add")
					&& return $FATAL;

	vRemote("manualaddrconf.rmt",
					"if=$NUT_v6_device ".
					"addrfamily=inet6 ".
					"len=120 ". 
					"addr=$SRC_TUNNEL_ADDRESS ".
					"type=unicast")
					&& return $FATAL;


	return $PASS;
}

sub config_tunnel_offlink ($) {
	my ($IF)= @_;
	my ($NUT_device,$SRC_V4_ADDRESS,$DST_V4_ADDRESS,
		$SRC_V6_ADDRESS,$DST_V6_ADDRESS,);

	if ($IF eq "$IF_ID_1") {
		$NUT_device=$NUT_LINK1_device;
		$SRC_V4_ADDRESS=$NUT_LINK1_V4_ADDRESS; 
		$DST_V4_ADDRESS=$V4_OFFLINK0_ADDRESS;
		$SRC_V6_ADDRESS=$NUT_LINK1_V6_TUNNEL_ADDRESS;
		$DST_V6_ADDRESS=$OFFLINK2_GLOBAL_ADDRESS;
	}elsif($IF eq "$IF_ID_0") {
		$NUT_device=$NUT_LINK0_device;
		$SRC_V4_ADDRESS=$NUT_LINK0_V4_ADDRESS; 
		$DST_V4_ADDRESS=$V4_OFFLINK0_ADDRESS;
		$SRC_V6_ADDRESS=$NUT_LINK0_V6_TUNNEL_ADDRESS;
		$DST_V6_ADDRESS=$OFFLINK2_GLOBAL_ADDRESS;
	}else {
		return $FATAL;
	}

	vRemote("tunnel.rmt","if=$NUT_TUNNEL_device ".
					"prefixlen=$NUT_TUNNEL_prefixlen ".
					"routeprefixlen=64 ".
					"addrfamily=inet6 ".
					"prefix=$OFFLINK_GLOBAL_ADDRESS ".
					"srcaddr=$SRC_V4_ADDRESS ".
					"dstaddr=$DST_V4_ADDRESS ".
					"insrcaddr=$SRC_V6_ADDRESS ".
					"indstaddr=$DST_V6_ADDRESS ")
					&& return $FATAL;

	return $PASS;
}

sub config_another_tunnel ($) {
	my ($IF)= @_;
	my ($NUT_device,$SRC_V4_ADDRESS,$DST_V4_ADDRESS,
		$SRC_V6_ADDRESS,$DST_V6_ADDRESS,);
	
	if ($IF eq "$IF_ID_1") {
		$NUT_device=$NUT_LINK1_device;
		$SRC_V4_ADDRESS=$NUT_LINK1_V4_ADDRESS; 
		$DST_V4_ADDRESS=$V4_OFFLINK_ADDRESS;
		$SRC_V6_ADDRESS=$NUT_LINK1_V6_TUNNEL1_ADDRESS;
		$DST_V6_ADDRESS=$OFFLINK3_GLOBAL_ADDRESS;
	}elsif($IF eq "$IF_ID_0") {
		$NUT_device=$NUT_LINK0_device;
		$SRC_V4_ADDRESS=$NUT_LINK0_V4_ADDRESS; 
		$DST_V4_ADDRESS=$V4_OFFLINK_ADDRESS;
		$SRC_V6_ADDRESS=$NUT_LINK0_V6_TUNNEL1_ADDRESS;
		$DST_V6_ADDRESS=$OFFLINK3_GLOBAL_ADDRESS;
	}else {
		return $FATAL;
	}
		

	vRemote("tunnel.rmt","if=$NUT_TUNNEL_device1 ".
					"prefixlen=$NUT_TUNNEL_prefixlen ".
					"routeprefixlen=64 ".
					"addrfamily=inet6 ".
					"prefix=$OFFLINK1_GLOBAL_ADDRESS ".
					"srcaddr=$SRC_V4_ADDRESS ".
					"dstaddr=$DST_V4_ADDRESS ".
					"insrcaddr=$SRC_V6_ADDRESS ".
					"indstaddr=$DST_V6_ADDRESS ")
					&& return $FATAL;

	return $PASS;
}



sub config_host_v4 (;$) {
	my ($IF)=@_;
	$IF=$IF_ID_0 if (! $IF);
	
	my ($NUT_device,$NUT_V4_ADDRESS,$TN_V4_ADDRESS);
	
	if ($IF eq "$IF_ID_1") {
		$NUT_device=$NUT_LINK1_device;
		$NUT_V4_ADDRESS=$NUT_LINK1_V4_ADDRESS; 
		$TN_V4_ADDRESS=$TN_LINK1_V4_ADDRESS;
	}elsif($IF eq "$IF_ID_0") {
		$NUT_device=$NUT_LINK0_device;
		$NUT_V4_ADDRESS=$NUT_LINK0_V4_ADDRESS; 
		$TN_V4_ADDRESS=$TN_LINK0_V4_ADDRESS;
	}else {
		return $FATAL;
	}
		
	vRemote("route.rmt",
					"cmd=add ".
					"addrfamily=inet ".
					"prefix=default ".
					"gateway=$TN_V4_ADDRESS ".
					"if=$NUT_device ")
					&& return $FATAL;

	return $PASS;
}

sub config_host_v6 (;$) {
	my ($IF)=@_;
	$IF=$IF_ID_0 if (! $IF);
	
	my ($NUT_device,$NUT_V6_ADDRESS,$TN_V6_ADDRESS);
	
	if ($IF eq "$IF_ID_1") {
		$NUT_device=$NUT_LINK1_device;
		$NUT_V6_ADDRESS=$NUT_LINK1_LINKLOCAL_ADDRESS; 
		$TN_V6_ADDRESS=$TN_LINK1_LINKLOCAL_ADDRESS;
	}elsif($IF eq "$IF_ID_0") {
		$NUT_device=$NUT_LINK0_device;
		$NUT_V6_ADDRESS=$NUT_LINK0_LINKLOCAL_ADDRESS; 
		$TN_V6_ADDRESS=$TN_LINK0_LINKLOCAL_ADDRESS;
	}else {
		return $FATAL;
	}
		
	vRemote("route.rmt",
					"cmd=add ".
					"addrfamily=inet6 ".
					"prefix=default ".
					"gateway=$TN_V6_ADDRESS ".
					"if=$NUT_device ")
					&& return $FATAL;

	return $PASS;
}

sub config_tunnel_mtu ($) {
	my ($NUT_mtu)=@_;
	
	vRemote("mtuconfig.rmt",
					"tunnelif=$NUT_TUNNEL_device ".
					"mtu=$NUT_mtu ")
					&& return $FATAL;

	return $PASS;
}

sub config_another_tunnel_mtu ($) {
	my ($NUT_mtu)=@_;
	
	vRemote("mtuconfig.rmt",
					"tunnelif=$NUT_TUNNEL_device1 ".
					"mtu=$NUT_mtu ")
					&& return $FATAL;

	return $PASS;
}

sub ping6_nut2tn ($) {
	my ($DST_ADDR) = @_;

	vRemote("ping6.rmt",
					"addr=$DST_ADDR ")
					&& return $FATAL;
	return $PASS;
}

sub ping6_nut2tn_offlink_address () {
	ping6_nut2tn($OFFLINK_GLOBAL_ADDRESS);
}

sub ping6_nut2tn_automatic_address () {
	ping6_nut2tn($OFFLINK_AUTOMATIC_ADDRESS);
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
