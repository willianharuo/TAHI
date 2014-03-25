#
# Copyright (C) 2003 Yokogawa Electric Corporation, 
# INTAP(Interoperability Technology Association
# for Information Processing, Japan).  All rights reserved.
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
# Perl Module for "Default Address Selection for IPv6" Test
#
# $Name: REL_2_1_1 $
#
# $TAHI: ct/default-addr-select/ADDR_SELECT.pm,v 1.12 2003/05/28 00:20:27 kenta Exp $
#
########################################################################
package ADDR_SELECT;

use Exporter;
@ISA = qw(Exporter);
@EXPORT = qw(
	%pktdesc
	nutReboot
	nutDefaultRouteAdd
	nutIPv6AddrAdd
	nutIPv6AddrAdd_Any
	nutIPv6AddrDelete
	nutIPv6AddrDelete_Any
	nutDeprecatedIPv6AddrAdd
	nutDeprecatedIPv6AddrAdd_Any
	nutAutoConfIPv6AddrAdd
	nutAutoConfIPv6AddrAdd_Any
	nutPing6
	nutPing6_Link0
	nutPing6Async
	nutPing6Async_Link0
	nutPing6AsyncWait
	nutClear
	prefix2G_ADDR_NUT
	nutLLA
	nutInitialize
	nutInitialize_ConfiguredTunnel
	checkNUT_SrcAddr
	checkNUT_SrcAddr_Any
	nutTempAddrEnable
	nutTempAddrDisable
	nutDnsSet
	nutDnsRemove
	nutPing62Dest
	nutPing62Dest_TempAddr
	nutPing62Dest_Dns
	);

use V6evalTool;

%pktdesc = (
	echo_request_DESTINATION2SOURCE1	=> 'NUT <------------------- DefaultRouter : ICMPv6 Echo Request',
	echo_reply_SOURCE12DESTINATION		=> 'NUT -------------------> DefaultRouter : ICMPv6 Echo Reply',
	echo_request_NUT2DESTINATION		=> 'NUT(Expected Source) --> Destination(offLink) : ICMPv6 Echo Request',
	echo_request_NUT2DESTINATION_ON_LINK	=> 'NUT(Expected Source) --> Destination(onLink) : ICMPv6 Echo Request',
	echo_request_NUT2DESTINATION_oneof	=> 'NUT(known Source) -----> Destination(offLink) : ICMPv6 Echo Request',
	echo_request_NUT2DESTINATION_ON_LINK_oneof	=> 'NUT(known Source) -----> Destination(onLink) : ICMPv6 Echo Request',
	echo_request_NUT2DESTINATION_any	=> 'NUT(any Source) -------> Destination(offLink) : ICMPv6 Echo Request',
	echo_request_NUT2DESTINATION_ON_LINK_any	=> 'NUT(any Source) -------> Destination(onLink) : ICMPv6 Echo Request',
	ns_NUT2DEFAULT_ROUTER_SLLA		=> 'NUT(known Source) -----> DefaultRouter : NS with SLLA',
	ns_NUT2DEFAULT_ROUTER_SLLA_any		=> 'NUT(any Source) -------> DefaultRouter : NS with SLLA',
	ns_NUT2DEFAULT_ROUTER_noOPT		=> 'NUT(known Source) -----> DefaultRouter : NS',
	ns_NUT2DEFAULT_ROUTER_noOPT_any		=> 'NUT(any Source) -------> DefaultRouter : NS',
	na_DEFAULT_ROUTER2NUT_TLLA		=> 'NUT <------------------- DefaultRouter : NA with TLLA',
	ns_NUT2DESTINATION_SLLA			=> 'NUT(known Source) -----> Destination(offLink) : NS with SLLA',
	ns_NUT2DESTINATION_SLLA_any		=> 'NUT(any Source) -------> Destination(offLink) : NS with SLLA',
	ns_NUT2DESTINATION_ON_LINK_SLLA		=> 'NUT(known Source) -----> Destination(onLink) : NS with SLLA',
	ns_NUT2DESTINATION_ON_LINK_SLLA_any	=> 'NUT(any Source) -------> Destination(onLink) : NS with SLLA',
	ns_NUT2DESTINATION_noOPT		=> 'NUT(known Source) -----> Destination(offLink) : NS',
	ns_NUT2DESTINATION_noOPT_any		=> 'NUT(any Source) -------> Destination(offLink) : NS',
	ns_NUT2DESTINATION_ON_LINK_noOPT	=> 'NUT(known Source) -----> Destination(onLink) : NS',
	ns_NUT2DESTINATION_ON_LINK_noOPT_any	=> 'NUT(any Source) -------> Destination(onLink) : NS',
	na_DESTINATION_R_2NUT_TLLA		=> 'NUT <------------------- Destination(offLink) : NA with TLLA & no R flag',
	na_DESTINATION2NUT_ON_LINK_TLLA		=> 'NUT <------------------- Destination(onLink) : NA with TLLA & no R flag',
	ns_NUT2DNS_SLLA_any			=> 'NUT(any Source) -------> DNS : NS with SLLA',
	ns_NUT2DNS_noOPT_any			=> 'NUT(any Source) -------> DNS : NS',
	na_DNS2NUT_TLLA				=> 'NUT <------------------- DNS : NA with TLLA',
	ra_DEPRECATED				=> 'NUT <------------------- DefaultRouter : RA with PreferredLifetime=1',
	ra_NORMAL				=> 'NUT <------------------- DefaultRouter : RA',
	dns_question_AAAA			=> 'NUT(known Source) -----> DNS : DNS query question',
	dns_answer_AAAA2			=> 'NUT <------------------- DNS : DNS query answer x2',
	dns_answer_AAAA3			=> 'NUT <------------------- DNS : DNS query answer x3',
	echo_request_LINK0_v4_tn2nut		=> 'NUT <------------------- TN : ICMP Echo Request',
	echo_reply_LINK0_v4_nut2tn		=> 'NUT -------------------> TN : ICMP Echo Reply',
	arp_LINK0_nut2tn_request		=> 'NUT -------------------> TN : ARP Request',
	arp_LINK0_tn2nut_reply			=> 'NUT <------------------- TN : ARP Echo Reply'

);

$TRUE = 1;
$FALSE = 0;
$NUT_IF = $V6evalTool::NutDef{Link0_device};
$NUT_IF2 = $V6evalTool::NutDef{Link1_device};
$IF = 'Link0';
$DST_FQDN= "server.tahi.org";
$C_BLUE = '\"#0000FF\"';
$C_GREEN = '\"#009900\"';

#======================================================================
# nutReboot() - reboot NUT
#======================================================================

$remote_debug = "";

sub nutReboot() {
	vLogHTML("<HR><FONT COLOR=$C_GREEN>--- NUT: Reboot ---</FONT><BR>");
	$ret = vRemote("reboot.rmt", $remote_debug);
	if($ret == 0){
		vLogHTML("<FONT COLOR=$C_GREEN>--- NUT: Reboot: Success ---</FONT><HR>");
		return $TRUE;
	}else{
		vLogHTML("<FONT COLOR=\"#FF0000\">--- NUT: Reboot: Fail :return status = $ret ---</FONT><HR>");
		return $FALSE;
	}
}

#======================================================================
# nutDefaultRouteAdd() - Add IPv6 Default Route in NUT
#                        Default Router = <TN-Link0-LinkLocalAddress>
#======================================================================

sub nutDefaultRouteAdd() {
	my $ADDR = vMAC2LLAddr($V6evalTool::TnDef{Link0_addr});
	vLogHTML("<HR><FONT COLOR=$C_GREEN>--- NUT: Add IPv6 Default Route ($ADDR) ---</FONT><BR>");
	$ret = vRemote("route.rmt",
		"",
		"prefix=default",
		"cmd=add",
		"addrfamily=inet6",
#		"gateway=$ADDR%$NUT_IF"
#		);
		"gateway=$ADDR",
		"if=$NUT_IF");
	if($ret == 0){
		vLogHTML("<FONT COLOR=$C_GREEN>--- NUT: Add IPv6 Default Route ($ADDR): Success ---</FONT><HR>");
		return $TRUE;
	}else{
		vLogHTML("<FONT COLOR=\"#FF0000\">--- NUT: Add IPv6 Default Route ($ADDR): Fail :return status = $ret ---</FONT><HR>");
		return $FALSE;
	}
}

#======================================================================
# nutIPv6AddrAdd() - Add IPv6 Unicast Address in NUT Link0
#======================================================================

sub nutIPv6AddrAdd($$) {
	my ($ADDR,$PLEN) = @_;
	vLogHTML("<HR><FONT COLOR=$C_GREEN>--- NUT: Add IPv6 Address ($ADDR/$PLEN) ---</FONT><BR>");
	$ret = vRemote("manualaddrconf.rmt",
		"",
		"if=$NUT_IF",
		"addrfamily=inet6",
		"addr=$ADDR",
		"len=$PLEN",
		"type=unicast");
	if($ret){
		vLogHTML("<FONT COLOR=\"#FF0000\">--- NUT: Add IPv6 Address ($ADDR/$PLEN) Fail :return status = $ret ---</FONT><HR>");
		return $FALSE;
	}else{
		vLogHTML("<FONT COLOR=$C_GREEN>--- NUT: Add IPv6 Address ($ADDR/$PLEN) Success ---</FONT><HR>");
		return $TRUE;
	}
}

#======================================================================
# nutIPv6AddrAdd_Any() - Add IPv6 Unicast Address in NUT any Link
#======================================================================

sub nutIPv6AddrAdd_Any($$$) {
	my ($ADDR,$PLEN,$IF_SELECT) = @_;
	vLogHTML("<HR><FONT COLOR=$C_GREEN>--- NUT: Add IPv6 Address ($ADDR/$PLEN $IF_SELECT) ---</FONT><BR>");
	my $IF_SELECTED;
	if($IF_SELECT eq 'Link0'){
		$IF_SELECTED = $NUT_IF;
	}else{
		$IF_SELECTED = $NUT_IF2;
	}
	$ret = vRemote("manualaddrconf.rmt",
		"",
		"if=$IF_SELECTED",
		"addrfamily=inet6",
		"addr=$ADDR",
		"len=$PLEN",
		"type=unicast");
	if($ret){
		vLogHTML("<FONT COLOR=\"#FF0000\">--- NUT: Add IPv6 Address ($ADDR/$PLEN $IF_SELECT) Fail :return status = $ret ---</FONT><HR>");
		return $FALSE;
	}else{
		vLogHTML("<FONT COLOR=$C_GREEN>--- NUT: Add IPv6 Address ($ADDR/$PLEN $IF_SELECT) Success ---</FONT><HR>");
		return $TRUE;
	}
}

#======================================================================
# nutIPv6AddrDelete() - Delete IPv6 Unicast Address in NUT Link0
#======================================================================

sub nutIPv6AddrDelete($$) {
	my ($ADDR,$PLEN) = @_;
	vLogHTML("<HR><FONT COLOR=$C_GREEN>--- NUT: Delete IPv6 Address ($ADDR/$PLEN) ---</FONT><BR>");
	$ret = vRemote("manualaddrconf.rmt",
		"",
		"if=$NUT_IF",
		"addrfamily=inet6",
		"addr=$ADDR",
		"len=$PLEN",
		"type=delete");
	if($ret){
		vLogHTML("<FONT COLOR=\"#FF0000\">--- NUT: Delete IPv6 Address ($ADDR/$PLEN) Fail :return status = $ret ---</FONT><HR>");
		return $FALSE;
	}else{
		vLogHTML("<FONT COLOR=$C_GREEN>--- NUT: Delete IPv6 Address ($ADDR/$PLEN) Success ---</FONT><HR>");
		return $TRUE;
	}
}

#======================================================================
# nutIPv6AddrDelete_Any() - Delete IPv6 Unicast Address in NUT any Link
#======================================================================

sub nutIPv6AddrDelete_Any($$$) {
	my ($ADDR,$PLEN,$IF_SELECT) = @_;
	vLogHTML("<HR><FONT COLOR=$C_GREEN>--- NUT: Delete IPv6 Address ($ADDR/$PLEN $IF) ---</FONT><BR>");
	my $IF_SELECTED;
	if($IF_SELECT eq 'Link0'){
		$IF_SELECTED = $NUT_IF;
	}else{
		$IF_SELECTED = $NUT_IF2;
	}
	$ret = vRemote("manualaddrconf.rmt",
		"",
		"if=$IF_SELECTED",
		"addrfamily=inet6",
		"addr=$ADDR",
		"len=$PLEN",
		"type=delete");
	if($ret){
		vLogHTML("<FONT COLOR=\"#FF0000\">--- NUT: Delete IPv6 Address ($ADDR/$PLEN $IF) Fail :return status = $ret ---</FONT><HR>");
		return $FALSE;
	}else{
		vLogHTML("<FONT COLOR=$C_GREEN>--- NUT: Delete IPv6 Address ($ADDR/$PLEN $IF) Success ---</FONT><HR>");
		return $TRUE;
	}
}

#======================================================================
# nutDeprecatedIPv6AddrAdd() - Add Deprecated IPv6 Address in NUT Link0
#======================================================================
sub nutDeprecatedIPv6AddrAdd($$) {
	my ($G_PREFIX,$CPP) = @_;
	vLogHTML("<HR><FONT COLOR=$C_GREEN>--- NUT: Add Deprecated IPv6 Address ($G_PREFIX + NUT'sEUI64) ---</FONT><BR>");
	vCPP("-DG_PREFIX=\\\"$G_PREFIX\\\"");
	vSend("$IF", 'ra_DEPRECATED');
	vSleep(5);
	
	if($CPP ne ''){
		vCPP($CPP);
	}
	vLogHTML("<HR>");
}

#======================================================================
# nutDeprecatedIPv6AddrAdd_Any() - Add Deprecated IPv6 Address in NUT any Link
#======================================================================
sub nutDeprecatedIPv6AddrAdd_Any($$$) {
	my ($G_PREFIX,$CPP,$IF_SELECT) = @_;
	vLogHTML("<HR><FONT COLOR=$C_GREEN>--- NUT: Add Deprecated IPv6 Address ($G_PREFIX + NUT'sEUI64) at $IF_SELECT ---</FONT><BR>");
	vCPP("-DG_PREFIX=\\\"$G_PREFIX\\\"");
	vSend("$IF_SELECT", 'ra_DEPRECATED');
	vSleep(5);
	if($CPP ne ''){
		vCPP($CPP);
	}
	vLogHTML("<HR>");
}

#======================================================================
# nutAutoConfIPv6AddrAdd() - Add Auto Configuration IPv6 Address in NUT Link0
#======================================================================
sub nutAutoConfIPv6AddrAdd($$) {
	my ($G_PREFIX,$CPP) = @_;
	vLogHTML("<HR><FONT COLOR=$C_GREEN>--- NUT: Add Auto Configuration IPv6 Address ($G_PREFIX + NUT'sEUI64) ---</FONT><BR>");
	vCPP("-DG_PREFIX=\\\"$G_PREFIX\\\"");
	vSend("$IF", 'ra_NORMAL');
	vSleep(5);

	if($CPP ne ''){
		vCPP($CPP);
	}
	vLogHTML("<HR>");
}

#======================================================================
# nutAutoConfIPv6AddrAdd_Any() - Add Auto Configuration IPv6 Address in NUT any Link
#======================================================================
sub nutAutoConfIPv6AddrAdd_Any($$$) {
	my ($G_PREFIX,$CPP,$IF_SELECT) = @_;
	vLogHTML("<HR><FONT COLOR=$C_GREEN>--- NUT: Add Auto Configuration IPv6 Address ($G_PREFIX + NUT'sEUI64) at $IF_SELECT ---</FONT><BR>");
	vCPP("-DG_PREFIX=\\\"$G_PREFIX\\\"");
	vSend("$IF_SELECT", 'ra_NORMAL');
	vSleep(5);
	if($CPP ne ''){
		vCPP($CPP);
	}
	vLogHTML("<HR>");
}

#======================================================================
# nutPing6() - Ping6 from NUT to Destination
#======================================================================
sub nutPing6($) {
	my ($ADDR) = @_;
	vLogHTML("<HR><FONT COLOR=$C_GREEN>--- NUT: Ping6 to $ADDR ---</FONT><BR>");
	$ret = vRemote("showAddr.rmt");
	if($ret != 0){
		vLogHTML("<FONT COLOR=\"#FF0000\">--- NUT: Ping6 to $ADDR: Fail :return status = $ret ---</FONT><HR>");
		return $FALSE;
	}
	$ret = vRemote("ping6.rmt", "", "addr=$ADDR");
	if($ret == 0){
		#vLogHTML("<FONT COLOR=$C_GREEN>--- NUT: Ping6 to $ADDR: Success ---</FONT><HR>");
		return $TRUE;
	}else{
		vLogHTML("<FONT COLOR=\"#FF0000\">--- NUT: Ping6 to $ADDR: Fail :return status = $ret ---</FONT><HR>");
		return $FALSE;
	}
}

#======================================================================
# nutPing6_Link0() - Ping6 from NUT to Destination
#======================================================================
sub nutPing6_Link0($) {
	my ($ADDR) = @_;
	vLogHTML("<HR><FONT COLOR=$C_GREEN>--- NUT: Ping6 to $ADDR %Link0 ---</FONT><BR>");
	$ret = vRemote("showAddr.rmt");
	if($ret != 0){
		vLogHTML("<FONT COLOR=\"#FF0000\">--- NUT: Ping6 to $ADDR %Link0: Fail :return status = $ret ---</FONT><HR>");
		return $FALSE;
	}
	$ret = vRemote("ping6.rmt", "", "if=$NUT_IF", "addr=$ADDR");
	if($ret == 0){
		#vLogHTML("<FONT COLOR=$C_GREEN>--- NUT: Ping6 to $ADDR %Link0: Success ---</FONT><HR>");
		return $TRUE;
	}else{
		vLogHTML("<FONT COLOR=\"#FF0000\">--- NUT: Ping6 to $ADDR %Link0: Fail :return status = $ret ---</FONT><HR>");
		return $FALSE;
	}
}

#======================================================================
# nutPing6Async() - Ping6 from NUT to Destination (Async)
#======================================================================
sub nutPing6Async($) {
	my ($ADDR) = @_;
	vLogHTML("<HR><FONT COLOR=$C_GREEN>--- NUT: Ping6 to $ADDR (Async) ---</FONT><BR>");
	$ret = vRemote("showAddr.rmt");
	if($ret != 0){
		vLogHTML("<FONT COLOR=\"#FF0000\">--- NUT: Ping6 to $ADDR (Async): Fail :return status = $ret ---</FONT><HR>");
		return $FALSE;
	}
	$ret = vRemoteAsync("ping6.rmt", "", "addr=$ADDR");
	if($ret == 0){
		#vLogHTML("<FONT COLOR=$C_GREEN>--- NUT: Ping6 to $ADDR (Async): Success ---</FONT><HR>");
		return $TRUE;
	}else{
		vLogHTML("<FONT COLOR=\"#FF0000\">--- NUT: Ping6 to $ADDR (Async): Fail :return status = $ret ---</FONT><HR>");
		return $FALSE;
	}
}

#======================================================================
# nutPing6Async_Link0() - Ping6 from NUT to Destination (Async)
#======================================================================
sub nutPing6Async_Link0($) {
	my ($ADDR) = @_;
	vLogHTML("<HR><FONT COLOR=$C_GREEN>--- NUT: Ping6 to $ADDR %Link0 (Async) ---</FONT><BR>");
	$ret = vRemote("showAddr.rmt");
	if($ret != 0){
		vLogHTML("<FONT COLOR=\"#FF0000\">--- NUT: Ping6 to $ADDR %Link0 (Async): Fail :return status = $ret ---</FONT><HR>");
		return $FALSE;
	}
	$ret = vRemoteAsync("ping6.rmt", "", "if=$NUT_IF", "addr=$ADDR");
	if($ret == 0){
		#vLogHTML("<FONT COLOR=$C_GREEN>--- NUT: Ping6 to $ADDR %Link0 (Async): Success ---</FONT><HR>");
		return $TRUE;
	}else{
		vLogHTML("<FONT COLOR=\"#FF0000\">--- NUT: Ping6 to $ADDR %Link0 (Async): Fail :return status = $ret ---</FONT><HR>");
		return $FALSE;
	}
}

#======================================================================
# nutPing6AsyncWait() - Wait for asynchronous remote script forked by nutPing6Async()
#======================================================================
sub nutPing6AsyncWait() {
	$ret = vRemoteAsyncWait();
	if($ret == 0){
		return $TRUE;
	}else{
		vLogHTML("<FONT COLOR=\"#FF0000\">--- vRemoteAsyncWait: Fail :return status = $ret ---</FONT><HR>");
		return $FALSE;
	}
}

#======================================================================
# ping6_Destination2SOURCE1() - send ping6 from DESTINATION to SOURCE1
#======================================================================
sub ping6_Destination2SOURCE1($$) {
	my ($CPP,$IF_SELECT) = @_;
	my $rcv_time = 0;
	vCapture("$IF_SELECT");
	vClear("$IF_SELECT");
	vSend("$IF_SELECT", 'echo_request_DESTINATION2SOURCE1');

	while($TRUE){
                my $CPP_THIS = $CPP;
#		my %ret = vRecv("$IF_SELECT", 5, $rcv_time, 0, 'ns_NUT2DEFAULT_ROUTER_SLLA','ns_NUT2DEFAULT_ROUTER_noOPT','ns_NUT2DESTINATION_SLLA','ns_NUT2DESTINATION_noOPT','echo_reply_SOURCE12DESTINATION');
		my %ret = vRecv("$IF_SELECT", 7, $rcv_time, 0, 'ns_NUT2DEFAULT_ROUTER_SLLA','ns_NUT2DEFAULT_ROUTER_noOPT','ns_NUT2DESTINATION_SLLA','ns_NUT2DESTINATION_noOPT','echo_reply_SOURCE12DESTINATION');

		if($ret{status} == 0) {
			if($ret{recvFrame} eq 'ns_NUT2DEFAULT_ROUTER_SLLA' || $ret{recvFrame} eq 'ns_NUT2DEFAULT_ROUTER_noOPT') {
				$CPP_THIS .= " -DRECEIVE_SOURCE=\\\"$ret{'Frame_Ether.Packet_IPv6.Hdr_IPv6.SourceAddress'}\\\"";
				vCPP($CPP_THIS);
				%ret2 = vSend("$IF_SELECT", 'na_DEFAULT_ROUTER2NUT_TLLA');
				$rcv_time = $ret2{sentTime1};
				
			}elsif($ret{recvFrame} eq 'ns_NUT2DESTINATION_SLLA' || $ret{recvFrame} eq 'ns_NUT2DESTINATION_noOPT') {
				$CPP_THIS .= " -DRECEIVE_SOURCE=\\\"$ret{'Frame_Ether.Packet_IPv6.Hdr_IPv6.SourceAddress'}\\\"";
				vCPP($CPP_THIS);
				%ret2 = vSend("$IF_SELECT", 'na_DESTINATION_R_2NUT_TLLA');
				$rcv_time = $ret2{sentTime1};
				
			}elsif($ret{recvFrame} eq 'echo_reply_SOURCE12DESTINATION') {
#				%ret2 = vRecv("$IF_SELECT", 3, 0, 0, 'ns_NUT2DESTINATION_SLLA','ns_NUT2DESTINATION_noOPT');
				%ret2 = vRecv("$IF_SELECT", 7, $rcv_time, 0, 'ns_NUT2DESTINATION_SLLA','ns_NUT2DESTINATION_noOPT');
				if($ret2{status} == 0) {
					$CPP_THIS .= " -DRECEIVE_SOURCE=\\\"$ret2{'Frame_Ether.Packet_IPv6.Hdr_IPv6.SourceAddress'}\\\"";
					vCPP($CPP_THIS);
					vSend("$IF_SELECT", 'na_DESTINATION_R_2NUT_TLLA');
				}
				return $TRUE;
			}
		}else{ 
			vLogHTML("<FONT COLOR=\"#FF0000\">--- Can not receive Echo Reply or NS from NUT ---</FONT><HR>");
			return $FALSE;
		}
	}
}

#======================================================================
# nutClear() - delete all address in NUT Link0 and Clear prefix list and Clear NDP entries
#======================================================================

sub nutClear($$;$$$$$$) {
	my ($ADDR1,$PLEN1,$ADDR2,$PLEN2,$ADDR3,$PLEN3,$ADDR4,$PLEN4) = @_;
	vLogHTML("<HR><FONT COLOR=$C_GREEN>--- Delete All Source Addresses ---</FONT><BR>");

	$ret = vRemote("clearprefix.rmt", $remote_debug);
	if($ret != 0){
		vLogHTML("<FONT COLOR=\"#FF0000\">--- Delete All Source Addresses and Clear prefix list : Fail ---</FONT><HR>");
		return $FALSE;
	}

	if($ADDR1 ne ''){
		$ret = nutIPv6AddrDelete($ADDR1,$PLEN1);
		if(!$ret){
			vLogHTML("<FONT COLOR=\"#FF0000\">--- Delete All Source Addresses and Clear prefix list : Fail ---</FONT><HR>");
			return $FALSE;
		}
	}
	if($ADDR2 ne ''){
		$ret = nutIPv6AddrDelete($ADDR2,$PLEN2);
		if(!$ret){
			vLogHTML("<FONT COLOR=\"#FF0000\">--- Delete All Source Addresses and Clear prefix list : Fail ---</FONT><HR>");
			return $FALSE;
		}
	}
	if($ADDR3 ne ''){
		$ret = nutIPv6AddrDelete($ADDR3,$PLEN3);
		if(!$ret){
			vLogHTML("<FONT COLOR=\"#FF0000\">--- Delete All Source Addresses and Clear prefix list : Fail ---</FONT><HR>");
			return $FALSE;
		}
	}
	if($ADDR4 ne ''){
		$ret = nutIPv6AddrDelete($ADDR4,$PLEN4);
		if(!$ret){
			vLogHTML("<FONT COLOR=\"#FF0000\">--- Delete All Source Addresses and Clear prefix list : Fail ---</FONT><HR>");
			return $FALSE;
		}
	}

	$ret = vRemote("clearnc.rmt", $remote_debug);
	if($ret != 0){
		vLogHTML("<FONT COLOR=\"#FF0000\">--- Delete All Source Addresses and Clear prefix list : Fail ---</FONT><HR>");
		return $FALSE;
	}

	$ret = vRemote("cleardefr.rmt", $remote_debug);
	if($ret != 0){
		vLogHTML("<FONT COLOR=\"#FF0000\">--- Delete All Source Addresses and Clear prefix list : Fail ---</FONT><HR>");
		return $FALSE;
	}

	vLogHTML("<FONT COLOR=$C_GREEN>--- Delete All Source Addresses and Clear prefix list : Success ---</FONT><HR>");
	return $TRUE;
}

#======================================================================
# prefix2G_ADDR_NUT() - return grobal address (prefix::NUT'sEUI64)
#======================================================================
sub prefix2G_ADDR_NUT($$) {
	my ($prefix,$IF_SELECT) = @_;
	$IF_SELECT .= '_addr';
	my $mac_addr =$V6evalTool::NutDef{$IF_SELECT};
	my (@str, @hex);

	@str=split(/:/,$mac_addr);
	foreach(@str) {
		push @hex,hex($_);
	};
	
	#
	# invert universal/local bit
	@hex[0] ^= 0x02;

	sprintf "%s%02x%02x:%02xff:fe%02x:%02x%02x",$prefix,@hex;
}

#======================================================================
# nutLLA() - return NUT's link local address
#======================================================================
sub nutLLA($) {
	my ($IF_SELECT) = @_;
	$IF_SELECT .= '_addr';
	my $mac_addr =$V6evalTool::NutDef{$IF_SELECT};
	$G_ADDR = vMAC2LLAddr($mac_addr);
	return $G_ADDR;
}

#======================================================================
# nutInitialize() - NUT initialization
#======================================================================

sub nutInitialize() {
	vLogHTML("<HR><FONT COLOR=$C_GREEN>--- NUT Initialization ---</FONT><BR>");
	$ret = nutDefaultRouteAdd();
	if (!$ret) {
		vLogHTML("<FONT COLOR=\"#FF0000\">--- NUT Initialization : Fail ---</FONT><HR>");
		return $FALSE;
	}
	vLogHTML("<FONT COLOR=$C_GREEN>--- NUT Initialization : Success ---</FONT><HR>");
	return $TRUE;
}

#======================================================================
# nutInitialize_ConfiguredTunnel() - NUT initialization for Configured Tunnel
#======================================================================

sub nutInitialize_ConfiguredTunnel($$$$) {
	my ($IPv4_ROUTER,$TUN_SRC,$TUN_END,$TUN_PREFIX) = @_;
	vLogHTML("<HR><FONT COLOR=$C_GREEN>--- NUT Initialization for Configured Tunnel ---</FONT><BR>");

	$ret = vRemote("manualaddrconf.rmt",
		"",
		"if=$NUT_IF",
		"addrfamily=inet",
		"addr=$TUN_SRC",
		"type=add");
	if($ret){
		vLogHTML("<FONT COLOR=\"#FF0000\">--- NUT Initialization for Configured Tunnel : Fail :return status = $ret ---</FONT><HR>");
		return $FALSE;
	}

	$ret = vRemote("route.rmt",
		"",
		"prefix=default",
		"cmd=add",
		"addrfamily=inet",
		"gateway=$IPv4_ROUTER",
		"if=$NUT_IF");
	if($ret){
		vLogHTML("<FONT COLOR=\"#FF0000\">--- NUT Initialization for Configured Tunnel : Fail :return status = $ret ---</FONT><HR>");
		return $FALSE;
	}

#	$ret = vRemote("tunnel.rmt","if=$NUT_IF ".
#		"prefixlen=64 ".
#		"routeprefixlen=64 ".
#		"addrfamily=inet6 ".
#		"prefix=$TUN_PREFIX ".
#		"srcaddr=$TUN_SRC ".
#		"dstaddr=$TUN_END ".
#		"insrcaddr=$TUNv6_SOURCE ".
#		"indstaddr=$TUN_PREFIX ");
	$ret = vRemote("tunnel.rmt",
		"prefixlen=64 ".
		"routeprefixlen=64",
		"addrfamily=inet6",
		"prefix=$TUN_PREFIX",
		"srcaddr=$TUN_SRC",
		"dstaddr=$TUN_END",
		"if=0");
	if($ret){
		vLogHTML("<FONT COLOR=\"#FF0000\">--- NUT Initialization for Configured Tunnel : Fail :return status = $ret ---</FONT><HR>");
		return $FALSE;
	}

	#====== make arp table #======
	vCapture($IF);
	vClear("$IF");
	vSend($IF, echo_request_LINK0_v4_tn2nut);
	%ret=vRecv($IF,5,0,0, 
		arp_LINK0_nut2tn_request,
		echo_reply_LINK0_v4_nut2tn
		);
	if( $ret{status} !=0) {
		vLogHTML("<FONT COLOR=\"#FF0000\">--- NUT Initialization for Configured Tunnel : Fail :return status = $ret ---</FONT><HR>");
		return $FALSE;
	}elsif($ret{recvFrame} eq 'arp_LINK0_nut2tn_request') {
		vSend($IF,arp_LINK0_tn2nut_reply);		
		%ret=vRecv($IF,5,0,0, 
			echo_reply_LINK0_v4_nut2tn,
			);

		if ($ret{status} != 0) {
			# re-send echo request
			vSend($IF, echo_request_LINK0_v4_tn2nut);
			%ret = vRecv($IF, 5, 0, 0, echo_reply_LINK1_v4_nut2tn);
			if( $ret{status} !=0) {
		vLogHTML("<FONT COLOR=\"#FF0000\">--- NUT Initialization for Configured Tunnel : Fail :return status = $ret ---</FONT><HR>");
				return $FALSE;
			}
		}
	}elsif($ret{recvFrame} eq 'echo_reply_LINK0_v4_nut2tn') {
		#return $PASS;
	}

	vLogHTML("<FONT COLOR=$C_GREEN>--- NUT Initialization for Configured Tunnel : Success ---</FONT><HR>");
	return $TRUE;
}

#======================================================================
# checkNUT_SrcAddr() - check All source address in NUT
#                      ping6 to All source address in NUT
#======================================================================

sub checkNUT_SrcAddr($$$;$$$$$$) {
	my ($CPP_ORG,$CHECK_SRC1,$CHECK_DST1,$CHECK_SRC2,$CHECK_DST2,$CHECK_SRC3,$CHECK_DST3,$CHECK_SRC4,$CHECK_DST4) = @_;
	vLogHTML("<HR><FONT COLOR=$C_GREEN>--- Check Source Addresses ($CHECK_SRC1, $CHECK_SRC2, $CHECK_SRC3, $CHECK_SRC4) ---</FONT><BR>");

	if($CHECK_SRC1 ne ''){
		$CPP = "-DSOURCE1=\\\"$CHECK_SRC1\\\" -DDESTINATION=\\\"$CHECK_DST1\\\"";
		vCPP($CPP);
		$ret = ping6_Destination2SOURCE1($CPP,$IF);
		if(!$ret){
			vLogHTML("<FONT COLOR=\"#FF0000\">--- Check Source Addresses : Fail ---<BR>--- One of Source Address is not set up exactly ---</FONT><HR>");
			return $FALSE;
		}
	}
	if($CHECK_SRC2 ne ''){
		$CPP = "-DSOURCE1=\\\"$CHECK_SRC2\\\" -DDESTINATION=\\\"$CHECK_DST2\\\"";
		vCPP($CPP);
		$ret = ping6_Destination2SOURCE1($CPP,$IF);
		if(!$ret){
			vLogHTML("<FONT COLOR=\"#FF0000\">--- Check Source Addresses : Fail ---<BR>--- One of Source Address is not set up exactly ---</FONT><HR>");
			return $FALSE;
		}
	}
	if($CHECK_SRC3 ne ''){
		$CPP = "-DSOURCE1=\\\"$CHECK_SRC3\\\" -DDESTINATION=\\\"$CHECK_DST3\\\"";
		vCPP($CPP);
		$ret = ping6_Destination2SOURCE1($CPP,$IF);
		if(!$ret){
			vLogHTML("<FONT COLOR=\"#FF0000\">--- Check Source Addresses : Fail ---<BR>--- One of Source Address is not set up exactly ---</FONT><HR>");
			return $FALSE;
		}
	}
	if($CHECK_SRC4 ne ''){
		$CPP = "-DSOURCE1=\\\"$CHECK_SRC4\\\" -DDESTINATION=\\\"$CHECK_DST4\\\"";
		vCPP($CPP);
		$ret = ping6_Destination2SOURCE1($CPP,$IF);
		if(!$ret){
			vLogHTML("<FONT COLOR=\"#FF0000\">--- Check Source Addresses : Fail ---<BR>--- One of Source Address is not set up exactly ---</FONT><HR>");
			return $FALSE;
		}
	}

	if($CPP_ORG ne ''){
		vCPP($CPP_ORG);
	}

	vLogHTML("<FONT COLOR=$C_GREEN>--- Check Source Addresses ($CHECK_SRC1 $CHECK_SRC2 $CHECK_SRC3 $CHECK_SRC4) : Success ---</FONT><HR>");
	return $TRUE;
}

#======================================================================
# checkNUT_SrcAddr_Any() - check source address in NUT any Link
#                          ping6 to source address in NUT any Link
#======================================================================

sub checkNUT_SrcAddr_Any($$$$) {
	my ($CPP_ORG,$CHECK_SRC1,$CHECK_DST1,$IF_SELECT) = @_;
	vLogHTML("<HR><FONT COLOR=$C_GREEN>--- Check Source Addresses ($CHECK_SRC1) ---</FONT><BR>");

	if($CHECK_SRC1 ne ''){
		$CPP = "-DSOURCE1=\\\"$CHECK_SRC1\\\" -DDESTINATION=\\\"$CHECK_DST1\\\"";
		vCPP($CPP);
		$ret = ping6_Destination2SOURCE1($CPP,$IF_SELECT);
		if(!$ret){
			vLogHTML("<FONT COLOR=\"#FF0000\">--- Check Source Addresses : Fail ---<BR>--- One of Source Address is not set up exactly ---</FONT><HR>");
			return $FALSE;
		}
	}

	if($CPP_ORG ne ''){
		vCPP($CPP_ORG);
	}

	vLogHTML("<FONT COLOR=$C_GREEN>--- Check Source Addresses ($CHECK_SRC1) : Success ---</FONT><HR>");
	return $TRUE;
}

#======================================================================
# nutTempAddrEnable() - NUT enable temporary address
#======================================================================
sub nutTempAddrEnable() {
	vLogHTML("<HR><FONT COLOR=$C_GREEN>--- NUT enable temporary address ---</FONT><BR>");
	$ret = vRemote("useTempAddr.rmt","","useTempAddr=enable");
	if ($ret != 0) {
		vLogHTML("<FONT COLOR=\"#FF0000\">--- NUT enable temporary address : Fail :return status = $ret ---</FONT><HR>");
		return $FALSE;
	}
	
	vLogHTML("<FONT COLOR=$C_GREEN>--- NUT enable temporary address : Success ---</FONT><HR>");
	return $TRUE;
}

#======================================================================
# nutTempAddrDisable() - NUT disable temporary address
#======================================================================
sub nutTempAddrDisable() {
	vLogHTML("<HR><FONT COLOR=$C_GREEN>--- NUT disable temporary address ---</FONT><BR>");
	$ret = vRemote("useTempAddr.rmt","","useTempAddr=disable");
	if ($ret != 0) {
		vLogHTML("<FONT COLOR=\"#FF0000\">--- NUT disable temporary address : Fail :return status = $ret ---</FONT><HR>");
		return $FALSE;
	}
	
	vLogHTML("<FONT COLOR=$C_GREEN>--- NUT disable temporary address : Success ---</FONT><HR>");
	return $TRUE;
}

#======================================================================
# nutDnsSet() - NUT set DNS
#======================================================================
sub nutDnsSet($) {
	my ($DNS_ADDR) = @_;
	vLogHTML("<HR><FONT COLOR=$C_GREEN>--- NUT set DNS ($DNS_ADDR) ---</FONT><BR>");
	$ret = vRemote("setDNS.rmt","","useDNS=enable","dnsAddr=$DNS_ADDR");
	if ($ret != 0) {
		vLogHTML("<FONT COLOR=\"#FF0000\">--- NUT set DNS ($DNS_ADDR) : Fail :return status = $ret ---</FONT><HR>");
		return $FALSE;
	}
	
	vLogHTML("<FONT COLOR=$C_GREEN>--- NUT set DNS ($DNS_ADDR) : Success ---</FONT><HR>");
	return $TRUE;
}

#======================================================================
# nutDnsRemove() - NUT remove DNS
#======================================================================
sub nutDnsRemove() {
	vLogHTML("<HR><FONT COLOR=$C_GREEN>--- NUT remove DNS ---</FONT><BR>");
	$ret = vRemote("setDNS.rmt","","useDNS=disable","useDNS=''");
	if ($ret != 0) {
		vLogHTML("<FONT COLOR=\"#FF0000\">--- NUT remove DNS : Fail :return status = $ret ---</FONT><HR>");
		return $FALSE;
	}
	
	vLogHTML("<FONT COLOR=$C_GREEN>--- NUT remove DNS : Success ---</FONT><HR>");
	return $TRUE;
}

#======================================================================
# nutPing62Dest() - ping6 NUT to DESTNATION
#======================================================================
sub nutPing62Dest($$$;$) {
	my ($CPP,$SEND_DEST,$ON_LINK,$NO_IF) = @_;
	my $rcv_time = 0;

	if($ON_LINK == $TRUE){
		$NS_SLLA = 'ns_NUT2DESTINATION_ON_LINK_SLLA';
		$NS_noOPT = 'ns_NUT2DESTINATION_ON_LINK_noOPT';
		$NA_TLLA = 'na_DESTINATION2NUT_ON_LINK_TLLA';
		$PING6 = 'echo_request_NUT2DESTINATION_ON_LINK';
	}else{
		$NS_SLLA = 'ns_NUT2DESTINATION_SLLA';
		$NS_noOPT = 'ns_NUT2DESTINATION_noOPT';
		$NA_TLLA = 'na_DESTINATION_R_2NUT_TLLA';
		$PING6 = 'echo_request_NUT2DESTINATION';
	}

	#====== Check : Send ping6 to DESTINATION #======
	vCapture($IF);
	vClear("$IF");

	if($NO_IF == $TRUE){
		nutPing6Async($SEND_DEST) || exit $V6evalTool::exitFatal;
	}else{
		nutPing6Async_Link0($SEND_DEST) || exit $V6evalTool::exitFatal;
	}

	while($TRUE){
                my $CPP_THIS = $CPP;
		my %ret = vRecv("$IF", 10, $rcv_time, 0, 'ns_NUT2DEFAULT_ROUTER_SLLA','ns_NUT2DEFAULT_ROUTER_noOPT', $NS_SLLA,$NS_noOPT,$PING6);

		if($ret{status} == 0) {
			if($ret{recvFrame} eq 'ns_NUT2DEFAULT_ROUTER_SLLA' || $ret{recvFrame} eq 'ns_NUT2DEFAULT_ROUTER_noOPT') {
				$CPP_THIS .= " -DRECEIVE_SOURCE=\\\"$ret{'Frame_Ether.Packet_IPv6.Hdr_IPv6.SourceAddress'}\\\"";
				vCPP($CPP_THIS);
				%ret2 = vSend("$IF", 'na_DEFAULT_ROUTER2NUT_TLLA');
				$rcv_time = $ret2{sentTime1};
				
			}elsif($ret{recvFrame} eq $NS_SLLA || $ret{recvFrame} eq $NS_noOPT) {
				$CPP_THIS .= " -DRECEIVE_SOURCE=\\\"$ret{'Frame_Ether.Packet_IPv6.Hdr_IPv6.SourceAddress'}\\\"";
				vCPP($CPP_THIS);
				%ret2 = vSend("$IF", $NA_TLLA);
				$rcv_time = $ret2{sentTime1};
			}elsif($ret{recvFrame} eq $PING6) {
				nutPing6AsyncWait() || exit $V6evalTool::exitFatal;
				return $TRUE;
			}
		}else{ 
			vLogHTML('<FONT COLOR="#FF0000">#### No response from NUT, Configuration Problem ? ####</FONT><BR>');
			nutPing6AsyncWait() || exit $V6evalTool::exitFatal;
			return $FALSE;
		}
	}
}

#======================================================================
# nutPing62Dest_TempAddr() - ping6 NUT to DESTNATION
#======================================================================
sub nutPing62Dest_TempAddr($$$;$) {
	my ($CPP,$SEND_DEST,$ON_LINK,$NO_IF) = @_;
	my $rcv_time = 0;

	if($ON_LINK == $TRUE){
		$NS_SLLA = 'ns_NUT2DESTINATION_ON_LINK_SLLA_any';
		$NS_noOPT = 'ns_NUT2DESTINATION_ON_LINK_noOPT_any';
		$NA_TLLA = 'na_DESTINATION2NUT_ON_LINK_TLLA';
		$PING6_UNEXP = 'echo_request_NUT2DESTINATION_ON_LINK_oneof';
		$PING6_ANY = 'echo_request_NUT2DESTINATION_ON_LINK_any';
	}else{
		$NS_SLLA = 'ns_NUT2DESTINATION_SLLA_any';
		$NS_noOPT = 'ns_NUT2DESTINATION_noOPT_any';
		$NA_TLLA = 'na_DESTINATION_R_2NUT_TLLA';
		$PING6_UNEXP = 'echo_request_NUT2DESTINATION_oneof';
		$PING6_ANY = 'echo_request_NUT2DESTINATION_any';
	}

	#====== Check : Send ping6 to DESTINATION #======
	vCapture($IF);
	vClear("$IF");

	if($NO_IF == $TRUE){
		nutPing6Async($SEND_DEST) || exit $V6evalTool::exitFatal;
	}else{
		nutPing6Async_Link0($SEND_DEST) || exit $V6evalTool::exitFatal;
	}

	while($TRUE){
		my $CPP_THIS = $CPP;
		my %ret = vRecv("$IF", 10, $rcv_time, 0, 'ns_NUT2DEFAULT_ROUTER_SLLA_any','ns_NUT2DEFAULT_ROUTER_noOPT_any', $NS_SLLA,$NS_noOPT,$PING6_UNEXP,$PING6_ANY);

		if($ret{status} == 0) {
			if($ret{recvFrame} eq 'ns_NUT2DEFAULT_ROUTER_SLLA_any' || $ret{recvFrame} eq 'ns_NUT2DEFAULT_ROUTER_noOPT_any') {
				$CPP_THIS .= " -DRECEIVE_SOURCE=\\\"$ret{'Frame_Ether.Packet_IPv6.Hdr_IPv6.SourceAddress'}\\\"";
				vCPP($CPP_THIS);
				%ret2 = vSend("$IF", 'na_DEFAULT_ROUTER2NUT_TLLA');
				$rcv_time = $ret2{sentTime1};
				
			}elsif($ret{recvFrame} eq $NS_SLLA || $ret{recvFrame} eq $NS_noOPT) {
				$CPP_THIS .= " -DRECEIVE_SOURCE=\\\"$ret{'Frame_Ether.Packet_IPv6.Hdr_IPv6.SourceAddress'}\\\"";
				vCPP($CPP_THIS);
				%ret2 = vSend("$IF", $NA_TLLA);
				$rcv_time = $ret2{sentTime1};
				
			}elsif($ret{recvFrame} eq $PING6_UNEXP) {
				vLogHTML("<FONT COLOR=\"#FF0000\">#### SourceAddress is not expected one ####</FONT><BR>");
				nutPing6AsyncWait() || exit $V6evalTool::exitFatal;
				return $FALSE;
			}elsif($ret{recvFrame} eq $PING6_ANY) {
				my $RESULT_ADDR = $ret{'Frame_Ether.Packet_IPv6.Hdr_IPv6.SourceAddress'};
				vLogHTML("<FONT COLOR=\"#0000FF\">#### Probably $RESULT_ADDR is temporary address. ####</FONT><BR>");
				nutPing6AsyncWait() || exit $V6evalTool::exitFatal;
				return $TRUE;
			}
		}else{ 
			vLogHTML('<FONT COLOR="#FF0000">#### No response from NUT, Configuration Problem ? ####</FONT><BR>');
			nutPing6AsyncWait() || exit $V6evalTool::exitFatal;
			return $FALSE;
		}
	}
}

#======================================================================
# nutPing62Dest_Dns() - ping6 NUT to DESTNATION
#======================================================================
sub nutPing62Dest_Dns($$$;$) {
	my ($CPP,$ANS_NUM,$ON_LINK,$NO_IF) = @_;
	my $rcv_time = 0;

	if($ON_LINK == $TRUE){
		$NS_SLLA = 'ns_NUT2DESTINATION_ON_LINK_SLLA';
		$NS_noOPT = 'ns_NUT2DESTINATION_ON_LINK_noOPT';
		$NA_TLLA = 'na_DESTINATION2NUT_ON_LINK_TLLA';
		$PING6 = 'echo_request_NUT2DESTINATION_ON_LINK';
	}else{
		$NS_SLLA = 'ns_NUT2DESTINATION_SLLA';
		$NS_noOPT = 'ns_NUT2DESTINATION_noOPT';
		$NA_TLLA = 'na_DESTINATION_R_2NUT_TLLA';
		$PING6 = 'echo_request_NUT2DESTINATION';
	}

	#====== Check : Send ping6 to DESTINATION #======
	vCapture($IF);
	vClear("$IF");

	if($NO_IF == $TRUE){
		nutPing6Async($DST_FQDN) || exit $V6evalTool::exitFatal;
	}else{
		nutPing6Async_Link0($DST_FQDN) || exit $V6evalTool::exitFatal;
	}
	while($TRUE){
                my $CPP_THIS = $CPP;
		my %ret = vRecv("$IF", 10, $rcv_time, 0, 'ns_NUT2DEFAULT_ROUTER_SLLA','ns_NUT2DEFAULT_ROUTER_noOPT', 'dns_question_AAAA', $NS_SLLA,$NS_noOPT,$PING6,'ns_NUT2DNS_SLLA_any','ns_NUT2DNS_noOPT_any');

		if($ret{status} == 0) {
			if($ret{recvFrame} eq 'ns_NUT2DEFAULT_ROUTER_SLLA' || $ret{recvFrame} eq 'ns_NUT2DEFAULT_ROUTER_noOPT') {
				$CPP_THIS .= " -DRECEIVE_SOURCE=\\\"$ret{'Frame_Ether.Packet_IPv6.Hdr_IPv6.SourceAddress'}\\\"";
				vCPP($CPP_THIS);
				%ret2 = vSend("$IF", 'na_DEFAULT_ROUTER2NUT_TLLA');
				$rcv_time = $ret2{sentTime1};
				
			}elsif($ret{recvFrame} eq 'dns_question_AAAA') {
				$CPP_THIS .= " -DRECEIVE_SOURCE=\\\"$ret{'Frame_Ether.Packet_IPv6.Hdr_IPv6.SourceAddress'}\\\" -DSOURCE_PORT=$ret{'Frame_Ether.Packet_IPv6.Upp_UDP.Hdr_UDP.SourcePort'} -DDNS_ID=$ret{'Frame_Ether.Packet_IPv6.Upp_UDP.Udp_DNS.Identifier'}";
				vCPP($CPP_THIS);
				if($ANS_NUM == 3){
					%ret2 = vSend("$IF", 'dns_answer_AAAA3');
				}else{
					%ret2 = vSend("$IF", 'dns_answer_AAAA2');
				}
				$rcv_time = $ret2{sentTime1};
			}elsif($ret{recvFrame} eq $NS_SLLA || $ret{recvFrame} eq $NS_noOPT) {
				$CPP_THIS .= " -DRECEIVE_SOURCE=\\\"$ret{'Frame_Ether.Packet_IPv6.Hdr_IPv6.SourceAddress'}\\\"";
				vCPP($CPP_THIS);
				%ret2 = vSend("$IF", $NA_TLLA);
				$rcv_time = $ret2{sentTime1};
			}elsif($ret{recvFrame} eq $PING6) {
				nutPing6AsyncWait() || exit $V6evalTool::exitFatal;
				return $TRUE;
			}elsif($ret{recvFrame} eq 'ns_NUT2DNS_SLLA_any' || $ret{recvFrame} eq 'ns_NUT2DNS_noOPT_any') {
				$CPP_THIS .= " -DRECEIVE_SOURCE=\\\"$ret{'Frame_Ether.Packet_IPv6.Hdr_IPv6.SourceAddress'}\\\"";
				vCPP($CPP_THIS);
				%ret2 = vSend("$IF", 'na_DNS2NUT_TLLA');
				$rcv_time = $ret2{sentTime1};
			}
		}else{ 
			vLogHTML('<FONT COLOR="#FF0000">#### No response from NUT, Configuration Problem ? ####</FONT><BR>');
			nutPing6AsyncWait() || exit $V6evalTool::exitFatal;
			return $FALSE;
		}
	}
}

1;

########################################################################
__END__

=head1 NAME

  ADDR_SELECT.pm - utility functions for "Default Address Selection for IPv6" test

=head1 SYNOPSIS

  nutReboot
  nutDefaultRouteAdd
  nutIPv6AddrAdd
  nutIPv6AddrAdd_Any
  nutIPv6AddrDelete
  nutIPv6AddrDelete_Any
  nutDeprecatedIPv6AddrAdd
  nutDeprecatedIPv6AddrAdd_Any
  nutAutoConfIPv6AddrAdd
  nutAutoConfIPv6AddrAdd_Any
  nutPing6
  nutPing6_Link0
  nutPing6Async
  nutPing6Async_Link0
  nutPing6AsyncWait
  nutClear
  prefix2G_ADDR_NUT
  nutLLA
  nutInitialize
  nutInitialize_ConfiguredTunnel
  checkNUT_SrcAddr
  checkNUT_SrcAddr_Any
  nutTempAddrEnable
  nutTempAddrDisable
  nutDnsSet
  nutDnsRemove
  nutPing62Dest
  nutPing62Dest_TempAddr
  nutPing62Dest_Dns

=head1 DESCRIPTION

  #nutReboot() - reboot NUT

    This routine calls vRemote("reboot.rmt") simply.

  #nutDefaultRouteAdd() - Add IPv6 Default Route in NUT

    route.rmt wrapper method.
    
    (FreeBSD)
    route add -inet6  default <TN-Link0-LinkLocalAddress>%<NUT-Link0>

  #nutIPv6AddrAdd($ADDR,$PLEN) - Add IPv6 Unicast Address in NUT Link0

    manualaddrconf.rmt wrapper method.
    
    (FreeBSD)
    ifconfig <NUT-Link0> inet6 <$ADDR> prefixlen <$PLEN> alias

  #nutIPv6AddrAdd_Any($ADDR,$PLEN,$IF) - Add IPv6 Unicast Address in NUT any Link

    manualaddrconf.rmt wrapper method.
    
    (FreeBSD)
    ifconfig <$IF> inet6 <$ADDR> prefixlen <$PLEN> alias

  #nutIPv6AddrDelete($ADDR,$PLEN) - Delete IPv6 Unicast Address in NUT Link0

    manualaddrconf.rmt wrapper method.
    
    (FreeBSD)
    ifconfig <NUT-Link0> inet6 <$ADDR> prefixlen <$PLEN> delete

  #nutIPv6AddrDelete_Any($ADDR,$PLEN,$IF) - Delete IPv6 Unicast Address in NUT any Link

    manualaddrconf.rmt wrapper method.
    
    (FreeBSD)
    ifconfig <$IF> inet6 <$ADDR> prefixlen <$PLEN> delete

  #nutDeprecatedIPv6AddrAdd($G_PREFIX,$CPP) - Add Deprecated IPv6 Address in NUT Link0

    Send 'ra_DEPRECATED' packet simply.

  #nutDeprecatedIPv6AddrAdd($G_PREFIX,$CPP) - Add Deprecated IPv6 Address in NUT Link0

    Send 'ra_DEPRECATED' packet simply.

  #nutDeprecatedIPv6AddrAdd_Any($G_PREFIX,$CPP,$IF) - Add Deprecated IPv6 Address in NUT any Link

    Send 'ra_DEPRECATED' packet simply.

  #nutAutoConfIPv6AddrAdd($G_PREFIX,$CPP) - Add IPv6 Address in NUT Link0 by RA

    Send 'ra_NORMAL' packet simply.

  #nutAutoConfIPv6AddrAdd_Any($G_PREFIX,$CPP,$IF) - Add IPv6 Address in NUT  any Link by RA

    Send 'ra_NORMAL' packet simply.

  #nutPing6($ADDR) - Ping6 from NUT

    ping6.rmt wrapper method.
    
    (FreeBSD)
    ping6 -n -c 1 -i 1 -h 64 -s 2 -p 00 <$ADDR>

  #nutPing6_Link0($ADDR) - Ping6 from NUT

    ping6.rmt wrapper method.
    
    (FreeBSD)
    ping6 -n -c 1 -i 1 -h 64 -s 2 -p 00 -I <NUT-Link0> <$ADDR>


  #nutPing6Async($ADDR) - Ping6 from NUT

    ping6.rmt wrapper method.
    * use vRemoteAsync()
    
    (FreeBSD)
    ping6 -n -c 1 -i 1 -h 64 -s 2 -p 00 <$ADDR>

  #nutPing6Async_Link0($ADDR) - Ping6 from NUT

    ping6.rmt wrapper method.
    * use vRemoteAsync()
    
    (FreeBSD)
    ping6 -n -c 1 -i 1 -h 64 -s 2 -p 00 -I <NUT-Link0> <$ADDR>

  #nutPing6AsyncWait($ADDR) -

    vRemoteAsyncWait() wrapper method.

  #ping6_Destination2SOURCE1($CPP,$IF) - internal subroutine

  #nutClear($ADDR1,$PLEN1, ; $ADDR2,$PLEN2,$ADDR3,$PLEN3,$ADDR4,$PLEN4) - delete all address & NCE in NUT Link0

    Call nutIPv6AddrDelete($ADDR1,$PLEN1) , nutIPv6AddrDelete($ADDR2,$PLEN2),...  simply
    and Call clearprefix.rmt & clearnc.rmt & cleardefr.rmt simply.

  #prefix2G_ADDR_NUT($G_PREFIX,$IF_SELECT) - return grobal address ($G_PREFIX::NUT'sEUI64)

  #nutLLA($IF_SELECT) - return link local address (NUT's LLA)

  #nutInitialize() - NUT initialization
  
    Call nutDefaultRouteAdd() simply

  #nutInitialize_ConfiguredTunnel($IPv4_ROUTER,$TUN_SRC,$TUN_END,$TUN_PREFIX) - NUT initialization ConfiguredTunnel

  #checkNUT_SrcAddr($CPP_ORG,$CHECK_SRC1,$CHECK_DST1 ; $CHECK_SRC2,$CHECK_DST2,$CHECK_SRC3,$CHECK_DST3,$CHECK_SRC4,$CHECK_DST4) - check All source address in NUT
     
     Send ping6 from CHECK_DST1 to CHECK_SRC1,
     Send ping6 from CHECK_DST2 to CHECK_SRC2,
     Send ping6 from CHECK_DST3 to CHECK_SRC3,
     Send ping6 from CHECK_DST4 to CHECK_SRC4
     
     return true(1) : ping6 success
     return false(0) : One of ping6 fail

  # checkNUT_SrcAddr_Any($CPP_ORG,$CHECK_SRC1,$CHECK_DST1,$IF_SELECT) - check source address in NUT any Link

     Send ping6 from CHECK_DST1 to CHECK_SRC1($IF_SELECT)

     return true(1) : ping6 success
     return false(0) : ping6 fail

  #nutTempAddrEnable() - NUT enable temporary address

  #nutTempAddrDisable() - NUT disable temporary address

  #nutDnsSet($DNS_ADDR) - NUT set DNS(server=$DNS_ADDR)

  #nutDnsRemove() - NUT remove DNS

  #nutPing62Dest() - ping6 NUT to DESTNATION

  #nutPing62Dest_TempAddr() - ping6 NUT to DESTNATION

  #nutPing62Dest_Dns() - ping6 NUT to DESTNATION

=head1 SEE ALSO

=begin html
  <A HREF="./ADDR_SELECT.pm">ADDR_SELECT.pm</A>

=end html

  perldoc V6EvalTool
  perldoc V6Remote

=cut


