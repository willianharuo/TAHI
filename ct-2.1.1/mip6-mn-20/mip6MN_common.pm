#
# Copyright (C) 2003 Yokogawa Electric Corporation , 
# INTAP(Interoperability Technology Association for Information 
# Processing, Japan) , IPA (Information-technology Promotion Agency,Japan)
# Copyright (C) IBM Corporation 2003.
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
#    Author: Kazuo Hiekata <hiekata@yamato.ibm.com>
#
#################################################################

package mip6MN_common;
use Exporter;
@ISA = qw(Exporter);

@EXPORT = qw(
	init_mn
	wait_frame_at_link0
	wait_frame_at_linkx
	wait_frame_at_linky
	return_routability_nut1_to_tn
	return_routability_nut2_to_tn
	wait_bu_from_cn_at_linkx
	get_binding_update_value
	createIdDef
	getHomeNonce
	getCareOfNonce
	get_cookie
	
	%pktdesc
);

use V6evalTool;

sub init_mn();
sub wait_frame_at_link0($$);
sub wait_frame_at_linkx($$);
sub wait_frame_at_linky($$);
sub return_routability_nut1_to_tn($$$$);
sub return_routability_nut2_to_tn($$$$);
sub wait_bu_from_cn_at_linkx($$$$$$);
sub get_binding_update_value($$);
sub createIdDef();
sub getHomeNonce($);
sub getCareOfNonce($);

#--------------------------------------------------------------#
# init_mn()                                                    #
#                                                              #
# Notes:                                                       #
#   Reset MN functionality                                     #
#                                                              #
#--------------------------------------------------------------#
sub init_mn() {

	vLogHTML("<B>===== Initialize Mobile Node =====</B><BR>");
	
	# mip6EnableMN.rmt -------------------
	my $IF0_NUT = $V6evalTool::NutDef{Link0_device};
	my $ret = vRemote('mip6EnableMN.rmt',"device=$IF0_NUT",'');
	if($ret != 0) {
		vLogHTML('Cannot Reset Mobile Node Modules<BR>');
		vLogHTML('<FONT COLOR=#FF0000>NG</FONT>');
		exit $V6evalTool::exitFail;
	}
	
	# make packet definitions
	my $cpp = '';
	vCPP($cpp);

	return;
}

#--------------------------------------------------------------#
# wait_frame_at_link0($$)                                      #
#                                                              #
# Notes:                                                       #
#   wait_frame_at_link0($if, $frame)                           #
#                                                              #
#       SUCCESS: return 0                                      #
#       FAILURE: return 1                                      #
#                                                              #
#--------------------------------------------------------------#
sub wait_frame_at_link0($$) {
	my ($if, $frame) = @_;
	my $errcount = 0;

retry:
	if (10 < $errcount) {
		vLogHTML('TN cannot get target frame"<BR>');
		vLogHTML("Clear packet buffer.");
		vRecv($if, 1, 0, 0, );
		return 1;
	}
	
	vCPP("-DBU_LIFETIME=0 ");
	%ret = vRecv($if, 5, 0, 0, $frame,
		dadns_nut0,
		rs,
		);
	
	if ( $ret{recvFrame} eq $frame) {
		if ($frame eq 'bindingupdate_nut0_to_ha0') {
			my ($acknowledge, $homeregistration, $sequencenumber, $lifetime) =
				get_binding_update_value('Frame_Ether.Packet_IPv6.Hdr_MH_BU', \%ret);
				vLogHTML('<B>Lifetime must be 0.</B>') if (! 0 == $lifetime);
			# if ( 1 == $acknowledge ) { # HA must send BA
				my $cpp = '';
				$cpp .= "-DBA_SEQUENCENUMBER=$sequencenumber ";
				vCPP($cpp);
				vSend($if, bindingacknowledgement_ha0_to_nut0);
			# }
		}
		vLogHTML("Clear packet buffer.");
		vRecv($if, 1, 0, 0, );
		return 0;
	} elsif ( $ret{recvFrame} eq 'rs') {
		vSend($if, ra_ha0_to_multi);
		vSend($if, na_ha0lla_to_nut0);
		vSend($if, na_ha0ga_to_nut0);
	} elsif ( $ret{recvFrame} eq 'dadns_nut0') {
		# wait for DAD completion
	} else {
		# in case NCE expires
		if ( 3 == $errcount) {
			vSend($if, ra_ha0_to_multi);
			vSend($if, na_ha0lla_to_nut0);
			vSend($if, na_ha0ga_to_nut0);
		}
	}
	$errcount++;
	goto retry;
}

#--------------------------------------------------------------#
# wait_frame_at_linkx($$)                                      #
#                                                              #
# Notes:                                                       #
#   wait_frame_at_linkx($if, $frame)                           #
#                                                              #
#       SUCCESS: return 0                                      #
#       FAILURE: return 1                                      #
#                                                              #
#--------------------------------------------------------------#
sub wait_frame_at_linkx($$) {
	my ($if, $frame) = @_;
	my $errcount = 0;

retry:
	if (10 < $errcount) {
		vLogHTML('TN cannot get target frame"<BR>');
		vLogHTML("Clear packet buffer.");
		vRecv($if, 1, 0, 0, );
		return 1;
	}
	
	vCPP("-DBU_LIFETIME=any ");
	%ret = vRecv($if, 5, 0, 0, $frame,
		dadns_nut1,
		mobileprefixsolicitation_nut1_to_ha0,
		rs,
		bindingupdate_nut1_to_ha0,
		bindingupdate_nut1_to_ha1,
		haadrequest_nut1_to_ha0,
		);
	
	if ( $ret{recvFrame} eq $frame) {
		if ($frame eq 'bindingupdate_nut1_to_ha0') {
			my ($acknowledge, $homeregistration, $sequencenumber, $lifetime) =
				get_binding_update_value('Frame_Ether.Packet_IPv6.Hdr_MH_BU', \%ret);
			# if ( 1 == $acknowledge ) {
				my $cpp = '';
				$cpp .= "-DBA_SEQUENCENUMBER=$sequencenumber ";
				$lifetime = $lifetime;
				$cpp .= "-DBA_LIFETIME=$lifetime ";
				vCPP($cpp);
				vSend($if, bindingacknowledgement_ha0_to_nut1);
			# }
		} elsif ($frame eq 'bindingupdate_nut1_to_ha1') {
			vLogHTML("start processing BU.<BR>");
			my ($acknowledge, $homeregistration, $sequencenumber, $lifetime) =
				get_binding_update_value('Frame_Ether.Packet_IPv6.Hdr_MH_BU', \%ret);
			# if ( 1 == $acknowledge ) {
				vLogHTML("sending BA.<BR>");
				my $cpp = '';
				$lifetime = $lifetime;
				$cpp .= "-DBA_SEQUENCENUMBER=$sequencenumber ";
				$lifetime = $lifetime - 1;
				$cpp .= "-DBA_LIFETIME=$lifetime ";
				vCPP($cpp);
				vSend($if, bindingacknowledgement_ha1_to_nut1);
			# }
		}
		vLogHTML("Clear packet buffer.");
		vRecv($if, 1, 0, 0, );
		return 0;
	} elsif ( $ret{recvFrame} eq 'dadns_nut1') {
		# wait for DAD completion
	} elsif ( $ret{recvFrame} eq 'mobileprefixsolicitation_nut1_to_ha0') {
		vSend($if,"mobileprefixadvertisement_ha0_to_nut1");
	} elsif ( $ret{recvFrame} eq 'rs') {
		vSend($if, ra_r1_to_multi);
	} elsif ( $ret{recvFrame} eq 'haadrequest_nut1_to_ha0') {
		vSend($if, haadreply_ha0_to_nut1);
	} elsif ( $ret{recvFrame} eq 'bindingupdate_nut1_to_ha0') {
		my ($acknowledge, $homeregistration, $sequencenumber, $lifetime) =
				get_binding_update_value('Frame_Ether.Packet_IPv6.Hdr_MH_BU', \%ret);
		# if ( 1 == $acknowledge ) {
			my $cpp = '';
			$cpp .= "-DBA_SEQUENCENUMBER=$sequencenumber ";
			$lifetime = $lifetime - 1;
			$cpp .= "-DBA_LIFETIME=$lifetime ";
			vCPP($cpp);
			vSend($if, bindingacknowledgement_ha0_to_nut1);
		# }
	} elsif ( $ret{recvFrame} eq 'bindingupdate_nut1_to_ha1') {
		my ($acknowledge, $homeregistration, $sequencenumber, $lifetime) =
				get_binding_update_value('Frame_Ether.Packet_IPv6.Hdr_MH_BU', \%ret);
		if ( 1 == $acknowledge ) {
			my $cpp = '';
			$cpp .= "-DBA_SEQUENCENUMBER=$sequencenumber ";
			$lifetime = $lifetime - 1;
			$cpp .= "-DBA_LIFETIME=$lifetime ";
			vCPP($cpp);
			vSend($if, bindingacknowledgement_ha1_to_nut1);
		}
	} else {
		if ( 3 == $errcount) {
			vSend($if, ra_r1_to_multi);
			vSend($if, na_r1lla_to_nut1);
		}
	}
	$errcount++;
	goto retry;
}

#--------------------------------------------------------------#
# wait_frame_at_linky($$)                                      #
#                                                              #
# Notes:                                                       #
#   wait_frame_at_linky($if, $frame)                           #
#                                                              #
#       SUCCESS: return 0                                      #
#       FAILURE: return 1                                      #
#                                                              #
#--------------------------------------------------------------#
sub wait_frame_at_linky($$) {
	my ($if, $frame) = @_;
	my $errcount = 0;

retry:
	if (10 < $errcount) {
		vLogHTML('TN cannot get target frame"<BR>');
		vLogHTML("Clear packet buffer.");
		vRecv($if, 1, 0, 0, );
		return 1;
	}
	
	vCPP("-DBU_LIFETIME=any ");
	%ret = vRecv($if, 5, 0, 0, $frame,
		dadns_nut2,
		mobileprefixsolicitation_nut2_to_ha0,
		rs,
		bindingupdate_nut2_to_ha0,
		bindingupdate_nut2_to_ha1,
		haadrequest_nut2_to_ha0,
		);
	
	if ( $ret{recvFrame} eq $frame) {
		if ($frame eq 'bindingupdate_nut2_to_ha0') {
			my ($acknowledge, $homeregistration, $sequencenumber, $lifetime) =
				get_binding_update_value('Frame_Ether.Packet_IPv6.Hdr_MH_BU', \%ret);
			# if ( 1 == $acknowledge ) {
				my $cpp = '';
				$cpp .= "-DBA_SEQUENCENUMBER=$sequencenumber ";
				$lifetime = $lifetime - 1;
				$cpp .= "-DBA_LIFETIME=$lifetime ";
				vCPP($cpp);
				vSend($if, bindingacknowledgement_ha0_to_nut2);
			# }
		} elsif ($frame eq 'bindingupdate_nut2_to_ha1') {
			my ($acknowledge, $homeregistration, $sequencenumber, $lifetime) =
				get_binding_update_value('Frame_Ether.Packet_IPv6.Hdr_MH_BU', \%ret);
			# if ( 1 == $acknowledge ) {
				$lifetime = $lifetime - 1;
				my $cpp = '';
				$cpp .= "-DBA_SEQUENCENUMBER=$sequencenumber ";
				$lifetime = $lifetime - 1;
				$cpp .= "-DBA_LIFETIME=$lifetime ";
				vCPP($cpp);
				vSend($if, bindingacknowledgement_ha1_to_nut2);
			# }
		}
		vLogHTML("Clear packet buffer.");
		vRecv($if, 1, 0, 0, );
		return 0;
	} elsif ( $ret{recvFrame} eq 'dadns_nut2') {
		# wait for DAD completion
	} elsif ( $ret{recvFrame} eq 'mobileprefixsolicitation_nut2_to_ha0') {
		vSend($if,"mobileprefixadvertisement_ha0_to_nut2");
	} elsif ( $ret{recvFrame} eq 'rs') {
		vSend($if, ra_r2_to_multi);
	} elsif ($ret{recvFrame} eq 'haadrequest_nut2_to_ha0') {
		vSend($IF0, haadreply_ha0_to_nut2);
	} elsif ( $ret{recvFrame} eq 'bindingupdate_nut2_to_ha0') {
		my ($acknowledge, $homeregistration, $sequencenumber, $lifetime) =
				get_binding_update_value('Frame_Ether.Packet_IPv6.Hdr_MH_BU', \%ret);
		if ( 1 == $acknowledge ) {
			my $cpp = '';
			$cpp .= "-DBA_SEQUENCENUMBER=$sequencenumber ";
			$lifetime = $lifetime - 1;
			$cpp .= "-DBA_LIFETIME=$lifetime ";
			vCPP($cpp);
			vSend($if, bindingacknowledgement_ha0_to_nut2);
		}
	} elsif ( $ret{recvFrame} eq 'bindingupdate_nut2_to_ha1') {
		my ($acknowledge, $homeregistration, $sequencenumber, $lifetime) =
				get_binding_update_value('Frame_Ether.Packet_IPv6.Hdr_MH_BU', \%ret);
		if ( 1 == $acknowledge ) {
			my $cpp = '';
			$cpp .= "-DBA_SEQUENCENUMBER=$sequencenumber ";
			$lifetime = $lifetime - 1;
			$cpp .= "-DBA_LIFETIME=$lifetime ";
			vCPP($cpp);
			vSend($if, bindingacknowledgement_ha1_to_nut2);
		}
	} else {
		if ( 3 == $errcount) {
			vSend($if, ra_r2_to_multi);
			vSend($if, na_r2lla_to_nut2);
		}
	}
	$errcount++;
	goto retry;
}
#--------------------------------------------------------------#
# return_routability_nut1_to_tn                                #
#    ($if, $kcn, $home_nonce_index, $careof_nonce_index)       #
#                                                              #
# Notes:                                                       #
#       return (ret, hot_cookie, cot_cookie)                   #
#       SUCCESS: ret=0                                         #
#       FAILURE: ret=1                                         #
#--------------------------------------------------------------#
sub return_routability_nut1_to_tn($$$$) {
	
	my ($if, $kcn, $home_nonce_index, $careof_nonce_index) = @_;
	my $check_hoti = 0;
	my $check_coti = 0;
	my $check_echo = 0;
	my $errcount = 0;
	my $hot_cookie;
	my $cot_cookie;
	my $home_nonce = getHomeNonce($home_nonce_index);
	my $careof_nonce = getCareOfNonce($careof_nonce_index);

retry:
	if (5 < $errcount) {
		if ((1 == $check_hoti) && (1 == $check_coti) ) {
			return (2, $hot_cookie, $cot_cookie);
		}
		vLogHTML('TN cannot get HOTI, COTI Message or Echo Reply."<BR>');
		return (1, "00000000", "00000000");
	}	
	
	%ret = vRecv($if, 5, 0, 0,
			hoti_nut1_to_ha0,
			coti_nut1_to_tn,
			echoreply_rev_tun_nut1_to_tn,
			rs);
			
	if(0 == $ret{status}) {
		# got tunneled Echo Reply
		if ( $ret{recvFrame} eq echoreply_rev_tun_nut1_to_tn) {
			$check_echo = 1;	
			vLogHTML("<B>Got tunneled echo reply.<BR></B>");
		}
		# got HOTI Message from NUT1
		if ( $ret{recvFrame} eq hoti_nut1_to_ha0) {
			$check_hoti = 1;
			$hot_cookie = get_cookie('Frame_Ether.Packet_IPv6.Packet_IPv6', \%ret);
			# print src/dst addresses
			vLogHTML("source address = $ret{\"Frame_Ether\.Packet_IPv6\.Hdr_IPv6\.SourceAddress\"}<BR>");
			vLogHTML("destination address = $ret{\"Frame_Ether\.Packet_IPv6\.Hdr_IPv6\.DestinationAddress\"}<BR>");
			my $cpp = '';
			$cpp .= "-DHOT_NONCE_INDEX=$home_nonce_index ";
			$cpp .= "-DHOT_NONCE=\\\"$home_nonce\\\" ";
			$cpp .= "-DHOT_HOTCOOKIE=\\\"$hot_cookie\\\" ";
			$cpp .= "-DKCN=\\\"$kcn\\\" ";
			vCPP($cpp);
			my %hot = vSend($if, hot_tn_to_nut1_via_ha0);
			if(defined($hot{"Frame_Ether.Packet_IPv6.Packet_IPv6.Hdr_MH_HoT"})) {
				vLogHTML('<B>Sending HoT</B><BR>');
				vLogHTML("home init cookie = ".$hot{"Frame_Ether.Packet_IPv6.Packet_IPv6.Hdr_MH_HoT.InitCookie"}."<BR>");
				vLogHTML("home keygen token = ".$hot{"Frame_Ether.Packet_IPv6.Packet_IPv6.Hdr_MH_HoT.KeygenNonce"}."<BR>");
				vLogHTML("home nonce index = ".$hot{"Frame_Ether.Packet_IPv6.Packet_IPv6.Hdr_MH_HoT.Index"}."<BR>");
				vLogHTML("* home nonce = $home_nonce<BR>");
				vLogHTML("* Kcn = $kcn<BR>");
				# print src/dst addresses
				vLogHTML("source address = $hot{\"Frame_Ether\.Packet_IPv6\.Hdr_IPv6\.SourceAddress\"}<BR>");
				vLogHTML("destination address = $hot{\"Frame_Ether\.Packet_IPv6\.Hdr_IPv6\.DestinationAddress\"}<BR>");
			}
		}
		# got COTI Message from NUT1
		if ( $ret{recvFrame} eq coti_nut1_to_tn) {
			$check_coti = 1;
			$cot_cookie = get_cookie('Frame_Ether.Packet_IPv6', \%ret);
			# print src/dst addresses
			vLogHTML("source address = $ret{\"Frame_Ether\.Packet_IPv6\.Hdr_IPv6\.SourceAddress\"}<BR>");
			vLogHTML("destination address = $ret{\"Frame_Ether\.Packet_IPv6\.Hdr_IPv6\.DestinationAddress\"}<BR>");
			my $cpp = '';
			$cpp .= "-DCOT_NONCE_INDEX=$careof_nonce_index ";
			$cpp .= "-DCOT_NONCE=\\\"$careof_nonce\\\" ";
			$cpp .= "-DCOT_COTCOOKIE=\\\"$cot_cookie\\\" ";
			$cpp .= "-DKCN=\\\"$kcn\\\" ";
			vCPP($cpp);
			my %cot = vSend($if, cot_tn_to_nut1);
			if(defined($cot{"Frame_Ether.Packet_IPv6.Hdr_MH_CoT"})) {
				vLogHTML('<B>Sending CoT</B><BR>');
				vLogHTML("care-of init cookie = ".$cot{"Frame_Ether.Packet_IPv6.Hdr_MH_CoT.InitCookie"}."<BR>");
				vLogHTML("care-of keygen token = ".$cot{"Frame_Ether.Packet_IPv6.Hdr_MH_CoT.KeygenNonce"}."<BR>");
				vLogHTML("care-of nonce index = ".$cot{"Frame_Ether.Packet_IPv6.Hdr_MH_CoT.Index"}."<BR>");
				vLogHTML("* care-of nonce = $careof_nonce<BR>");
				vLogHTML("* Kcn = $kcn<BR>");
				# print src/dst addresses
				vLogHTML("source address = $cot{\"Frame_Ether\.Packet_IPv6\.Hdr_IPv6\.SourceAddress\"}<BR>");
				vLogHTML("destination address = $cot{\"Frame_Ether\.Packet_IPv6\.Hdr_IPv6\.DestinationAddress\"}<BR>");
			}
		}
		if ( $ret{recvFrame} eq rs)  {
			vSend($if, ra_r1_to_multi);
			vSend($if, na_r1lla_to_nut1);
		}
	}
	
	if ((1 == $check_hoti) && (1 == $check_coti) && (1 == $check_echo)) {
		vLogHTML("Return Routability Procedure completed.<BR>");
		return (0, $hot_cookie, $cot_cookie);
	}
	
	$errcount++;
	goto retry;
}
#--------------------------------------------------------------#
# return_routability_nut2_to_tn                                #
#    ($if, $kcn, $home_nonce_index, $careof_nonce_index)       #
#                                                              #
# Notes:                                                       #
#       return (ret, hot_cookie, cot_cookie)                   #
#       SUCCESS: ret=0                                         #
#       FAILURE: ret=1                                         #
#--------------------------------------------------------------#
sub return_routability_nut2_to_tn($$$$) {
	
	my ($if, $kcn, $home_nonce_index, $careof_nonce_index) = @_;
	my $check_hoti = 0;
	my $check_coti = 0;
	my $check_echo = 0;
	my $errcount = 0;
	my $hot_cookie;
	my $cot_cookie;
	my $home_nonce = getHomeNonce($home_nonce_index);
	my $careof_nonce = getCareOfNonce($careof_nonce_index);

retry:
	if (5 < $errcount) {
		if ((1 == $check_hoti) && (1 == $check_coti) ) {
			return (2, $hot_cookie, $cot_cookie);
		}
		vLogHTML('TN cannot get HOTI, COTI Message or Echo Reply."<BR>');
		return (1, "00000000", "00000000");
	}	
	
	%ret = vRecv($if, 5, 0, 0,
			hoti_nut2_to_ha0,
			coti_nut2_to_tn,
			echoreply_rev_tun_nut2_to_tn,
			rs);
			
	if(0 == $ret{status}) {
		# got tunneled Echo Reply
		if ( $ret{recvFrame} eq echoreply_rev_tun_nut2_to_tn) {
			$check_echo = 1;
			vLogHTML("<B>Got tunneled echo reply.<BR></B>");
		}
		# got HOTI Message from NUT2
		if ( $ret{recvFrame} eq hoti_nut2_to_ha0) {
			$check_hoti = 1;
			$hot_cookie = get_cookie('Frame_Ether.Packet_IPv6.Packet_IPv6', \%ret);
			# print src/dst addresses
			vLogHTML("source address = $ret{\"Frame_Ether\.Packet_IPv6\.Hdr_IPv6\.SourceAddress\"}<BR>");
			vLogHTML("destination address = $ret{\"Frame_Ether\.Packet_IPv6\.Hdr_IPv6\.DestinationAddress\"}<BR>");
			my $cpp = '';
			$cpp .= "-DHOT_NONCE_INDEX=$home_nonce_index ";
			$cpp .= "-DHOT_NONCE=\\\"$home_nonce\\\" ";
			$cpp .= "-DHOT_HOTCOOKIE=\\\"$hot_cookie\\\" ";
			$cpp .= "-DKCN=\\\"$kcn\\\" ";
			vCPP($cpp);
			my %hot = vSend($if, hot_tn_to_nut2_via_ha0);
			if(defined($hot{"Frame_Ether.Packet_IPv6.Packet_IPv6.Hdr_MH_HoT"})) {
				vLogHTML('<B>Sending HoT</B><BR>');
				vLogHTML("home init cookie = ".$hot{"Frame_Ether.Packet_IPv6.Packet_IPv6.Hdr_MH_HoT.InitCookie"}."<BR>");
				vLogHTML("home keygen token = ".$hot{"Frame_Ether.Packet_IPv6.Packet_IPv6.Hdr_MH_HoT.KeygenNonce"}."<BR>");
				vLogHTML("home nonce index = ".$hot{"Frame_Ether.Packet_IPv6.Packet_IPv6.Hdr_MH_HoT.Index"}."<BR>");
				vLogHTML("* home nonce = $home_nonce<BR>");
				vLogHTML("* Kcn = $kcn<BR>");
				# print src/dst addresses
				vLogHTML("source address = $hot{\"Frame_Ether\.Packet_IPv6\.Hdr_IPv6\.SourceAddress\"}<BR>");
				vLogHTML("destination address = $hot{\"Frame_Ether\.Packet_IPv6\.Hdr_IPv6\.DestinationAddress\"}<BR>");
			}
		}
		# got COTI Message from NUT1
		if ( $ret{recvFrame} eq coti_nut2_to_tn) {
			$check_coti = 1;
			$cot_cookie = get_cookie('Frame_Ether.Packet_IPv6', \%ret);
			# print src/dst addresses
			vLogHTML("source address = $ret{\"Frame_Ether\.Packet_IPv6\.Hdr_IPv6\.SourceAddress\"}<BR>");
			vLogHTML("destination address = $ret{\"Frame_Ether\.Packet_IPv6\.Hdr_IPv6\.DestinationAddress\"}<BR>");
			my $cpp = '';
			$cpp .= "-DCOT_NONCE_INDEX=$careof_nonce_index ";
			$cpp .= "-DCOT_NONCE=\\\"$careof_nonce\\\" ";
			$cpp .= "-DCOT_COTCOOKIE=\\\"$cot_cookie\\\" ";
			$cpp .= "-DKCN=\\\"$kcn\\\" ";
			vCPP($cpp);
			my %cot = vSend($if, cot_tn_to_nut2);
			if(defined($cot{"Frame_Ether.Packet_IPv6.Hdr_MH_CoT"})) {
				vLogHTML('<B>Sending CoT</B><BR>');
				vLogHTML("care-of init cookie = ".$cot{"Frame_Ether.Packet_IPv6.Hdr_MH_CoT.InitCookie"}."<BR>");
				vLogHTML("care-of keygen token = ".$cot{"Frame_Ether.Packet_IPv6.Hdr_MH_CoT.KeygenNonce"}."<BR>");
				vLogHTML("care-of nonce index = ".$cot{"Frame_Ether.Packet_IPv6.Hdr_MH_CoT.Index"}."<BR>");
				vLogHTML("* care-of nonce = $careof_nonce<BR>");
				vLogHTML("* Kcn = $kcn<BR>");
				# print src/dst addresses
				vLogHTML("source address = $cot{\"Frame_Ether\.Packet_IPv6\.Hdr_IPv6\.SourceAddress\"}<BR>");
				vLogHTML("destination address = $cot{\"Frame_Ether\.Packet_IPv6\.Hdr_IPv6\.DestinationAddress\"}<BR>");
			}
		}
		if ( $ret{recvFrame} eq rs)  {
			vSend($if, ra_r2_to_multi);
			vSend($if, na_r2lla_to_nut2);
		}
	}
	
	if ((1 == $check_hoti) && (1 == $check_coti) && (1 == $check_echo)) {
		vLogHTML("Return Routability Procedure completed.<BR>");
		return (0, $hot_cookie, $cot_cookie);
	}
	
	$errcount++;
	goto retry;
}
#--------------------------------------------------------------#
# wait_bu_from_cn_at_linkx                                     #
#    ($if, $kcn, $home_nonce_index, $careof_nonce_index,       #
#         $hot_cookie, $cot_cookie)                            #
# Notes:                                                       #
#       return (ret)                                           #
#       SUCCESS: ret=0                                         #
#       FAILURE: ret=1                                         #
#--------------------------------------------------------------#
sub wait_bu_from_cn_at_linkx($$$$$$) {

	my ($if, $kcn, $home_nonce_index, $careof_nonce_index, 
		$hot_cookie, $cot_cookie) = @_;
	my $home_nonce = getHomeNonce($home_nonce_index);
	my $careof_nonce = getCareOfNonce($careof_nonce_index);
	my $n = 0;
	my $cpp = '';
	
	# wait for Binding Update from TN
	vSend($if, ra_r1_to_multi);
	vSend($if, na_r1lla_to_nut1);

	$cpp .= "-DHOT_NONCE_INDEX=$home_nonce_index ";
	$cpp .= "-DHOT_NONCE=\\\"$home_nonce\\\" ";
	$cpp .= "-DHOT_HOTCOOKIE=\\\"$hot_cookie\\\" ";
	$cpp .= "-DCOT_NONCE_INDEX=$careof_nonce_index ";
	$cpp .= "-DCOT_NONCE=\\\"$careof_nonce\\\" ";
	$cpp .= "-DCOT_COTCOOKIE=\\\"$cot_cookie\\\" ";
	$cpp .= "-DKCN=\\\"$kcn\\\" ";
	vCPP($cpp);

	for (my $n=0; $n < 5; $n++){
		%ret = vRecv($if, 5, 0, 0, bindingupdate_nut1_to_tn);
		if( $ret{recvFrame} eq 'bindingupdate_nut1_to_tn') {
			vLogHTML("TN received Binding Update(w/HAO) from NUT1.<BR>");
			get_binding_update_value('Frame_Ether.Packet_IPv6.Hdr_MH_BU', \%ret);
			return 0;
		}
		vSend($if, ra_r1_to_multi);
		vSend($if, na_r1lla_to_nut1);
		if (4 == $n) {
			vLogHTML('<FONT COLOR="#FF0000">TN could not get Binding Update from NUT.</FONT><BR>');
		}
	}
	return 1;
}
#--------------------------------------------------------------#
# wait_bu_from_cn_at_linky                                     #
#    ($if, $kcn, $home_nonce_index, $careof_nonce_index,       #
#         $hot_cookie, $cot_cookie)                            #
# Notes:                                                       #
#       return (ret)                                           #
#       SUCCESS: ret=0                                         #
#       FAILURE: ret=1                                         #
#--------------------------------------------------------------#
sub wait_bu_from_cn_at_linky($$$$$$) {

	my ($if, $kcn, $home_nonce_index, $careof_nonce_index, 
		$hot_cookie, $cot_cookie) = @_;
	my $home_nonce = getHomeNonce($home_nonce_index);
	my $careof_nonce = getCareOfNonce($careof_nonce_index);
	my $n = 0;
	my $cpp = '';
	
	# wait for Binding Update from TN
	vSend($if, ra_r2_to_multi);
	vSend($if, na_r2lla_to_nut2);

	$cpp .= "-DHOT_NONCE_INDEX=$home_nonce_index ";
	$cpp .= "-DHOT_NONCE=\\\"$home_nonce\\\" ";
	$cpp .= "-DHOT_HOTCOOKIE=\\\"$hot_cookie\\\" ";
	$cpp .= "-DCOT_NONCE_INDEX=$careof_nonce_index ";
	$cpp .= "-DCOT_NONCE=\\\"$careof_nonce\\\" ";
	$cpp .= "-DCOT_COTCOOKIE=\\\"$cot_cookie\\\" ";
	$cpp .= "-DKCN=\\\"$kcn\\\" ";
	vCPP($cpp);

	for (my $n=0; $n < 5; $n++){
		%ret = vRecv($if, 5, 0, 0, bindingupdate_nut2_to_tn);
		if( $ret{recvFrame} eq 'bindingupdate_nut2_to_tn') {
			vLogHTML("TN received Binding Update(w/HAO) from NUT1.<BR>");
			get_binding_update_value('Frame_Ether.Packet_IPv6.Hdr_MH_BU', \%ret);
			return 0;
		}
		vSend($if, ra_r2_to_multi);
		vSend($if, na_r2lla_to_nut1);
		if (4 == $n) {
			vLogHTML('<FONT COLOR="#FF0000">TN could not get Binding Update from NUT.</FONT><BR>');
		}
	}
	return 1;
}
#--------------------------------------------------------------#
# get_cookie($$)                                               #
#                                                              #
# Notes:                                                       #
#    return HoTCookie | CoTCookie                              #
#                                                              #
#--------------------------------------------------------------#
sub get_cookie($$) {
	my ($base, $ref) = @_;
	my $ret;
		
	# found HoTI Message (id-18)
	if(defined($$ref{"$base\.Hdr_MH_HoTI\.HoTCookie"})) {
		vLogHTML('<B>got HoTI</B><BR>');
		vLogHTML("HoT cookie = $$ref{\"$base\.Hdr_MH_HoTI\.HoTCookie\"}<BR>");
		return $$ref{"$base\.Hdr_MH_HoTI\.HoTCookie"};
	}
	
	# found CoTI Message (id-18)
	if(defined($$ref{"$base\.Hdr_MH_CoTI\.CoTCookie"})) {
		vLogHTML('<B>got CoTI</B><BR>');
		vLogHTML("CoT cookie = $$ref{\"$base\.Hdr_MH_CoTI\.CoTCookie\"}<BR>");
		return $$ref{"$base\.Hdr_MH_CoTI\.CoTCookie"};
	}

	# found HoTI Message (id-19)
	if(defined($$ref{"$base\.Hdr_MH_HoTI\.InitCookie"})) {
		vLogHTML('<B>got HoTI</B><BR>');
		vLogHTML("home init cookie = $$ref{\"$base\.Hdr_MH_HoTI\.InitCookie\"}<BR>");
		return $$ref{"$base\.Hdr_MH_HoTI\.InitCookie"};
	}
	
	# found CoTI Message (id-19)
	if(defined($$ref{"$base\.Hdr_MH_CoTI\.InitCookie"})) {
		vLogHTML('<B>got CoTI</B><BR>');
		vLogHTML("care-of init cookie = $$ref{\"$base\.Hdr_MH_CoTI\.InitCookie\"}<BR>");
		return $$ref{"$base\.Hdr_MH_CoTI\.InitCookie"};
	}

	vLogHTML("Cannot get cookie.<BR>");
	exit $V6evalTool::exitFail;
}
#--------------------------------------------------------------#
# get_binding_update_value($base, $ref)                        #
#                                                              #
# Notes:                                                       #
#    return my ($acknowledge, $homeregistration,               #
#               $sequencenumber, $lifetime)                    #
#                                                              #
#--------------------------------------------------------------#
sub get_binding_update_value($$) {
	my ($base, $ref) = @_;

	my $acknowledge = 0;
	my $homeregistration = 0;
	my $sequencenumber = 0;
	my $lifetime = 0;
	
	vLogHTML('<B>got Binding Update</B><BR>');
	if(defined($$ref{"$base\.AFlag"})) {
		$acknowledge = $$ref{'Frame_Ether.Packet_IPv6.Hdr_MH_BU.AFlag'};
		vLogHTML("AFlag = $acknowledge<BR>");
	} else {
		vLogHTML("Cannot find AFlag.<BR>");
	}

	if(defined($$ref{"$base\.HFlag"})) {
		$homeregistration = $$ref{'Frame_Ether.Packet_IPv6.Hdr_MH_BU.HFlag'};
		vLogHTML("HFlag = $homeregistration<BR>");
	} else {
		vLogHTML("Cannot find HFlag.<BR>");
	}

	if(defined($$ref{"$base\.SequenceNumber"})) {
		$sequencenumber = $$ref{'Frame_Ether.Packet_IPv6.Hdr_MH_BU.SequenceNumber'};
		vLogHTML("SequenceNumber = $sequencenumber<BR>");
	} else {
		vLogHTML("Cannot parse BindingUpdate.<BR>");
	}

	if(defined($$ref{"$base\.Lifetime"})) {
		$lifetime = $$ref{'Frame_Ether.Packet_IPv6.Hdr_MH_BU.Lifetime'};
		vLogHTML("Lifetime = $lifetime<BR>");
	} else {
		vLogHTML("Cannot parse BindingUpdate.<BR>");
	}
	
	if(defined($$ref{"$base\.Opt_MH_NonceIndices\.HoNonceIndex"})) {
		my $hononceindex = $$ref{'Frame_Ether.Packet_IPv6.Hdr_MH_BU.Opt_MH_NonceIndices.HoNonceIndex'};
		vLogHTML("Home Nonce Index = $hononceindex<BR>");
	}
	
	if(defined($$ref{"$base\.Opt_MH_NonceIndices\.CoNonceIndex"})) {
		my $cononceindex = $$ref{'Frame_Ether.Packet_IPv6.Hdr_MH_BU.Opt_MH_NonceIndices.CoNonceIndex'};
		vLogHTML("Care-of Nonce Index = $cononceindex<BR>");
	}
	
	if(defined($$ref{"$base\.Opt_MH_BindingAuthData\.Authenticator"})) {
		my $authdata = $$ref{'Frame_Ether.Packet_IPv6.Hdr_MH_BU.Opt_MH_BindingAuthData.Authenticator'};
		vLogHTML("Authenticator = $authdata<BR>");
	}
	
	return($acknowledge, $homeregistration, $sequencenumber, $lifetime);
}
#--------------------------------------------------------------#
# getHomeNonce($)                                              #
#                                                              #
# Notes:                                                       #
#    input nonce index                                         #
#    return home nonce                                         #
#                                                              #
#--------------------------------------------------------------#
sub getHomeNonce($) {
    my ($nonceindex) = @_;
    my $nonce = 10000 - (15 * $nonceindex);
    return $nonce;
}
#--------------------------------------------------------------#
# getCareOfNonce($)                                            #
#                                                              #
# Notes:                                                       #
#    input nonce index                                         #
#    return home nonce                                         #
#                                                              #
#--------------------------------------------------------------#
sub getCareOfNonce($) {
    my ($nonceindex) = @_;
    my $nonce = 10000 - (14 * $nonceindex);
    return $nonce;
}
#--------------------------------------------------------------#
# createIdDef()                                                #
#                                                              #
# Notes:                                                       #
#    create unique Fragment ID and write to ./ID.def           #
#                                                              #
#--------------------------------------------------------------#
sub createIdDef() {
	sleep 1;				# make time unique
	$id = time & 0x00000fff;		# use lower 12 bit
	open(OUT, ">./ID.def") || return 1;

	# Fragment ID (32bit)

	printf OUT "#define FRAG_ID   0x0%07x\n", $id;
	printf OUT "#define FRAG_ID_A 0xa%07x\n", $id;
	printf OUT "#define FRAG_ID_B 0xb%07x\n", $id;

	# Echo Request ID (16bit)

	printf OUT "#define REQ_ID   0x0%03x\n", $id;
	printf OUT "#define REQ_ID_A 0xa%03x\n", $id;
	printf OUT "#define REQ_ID_B 0xb%03x\n", $id;

	# Echo Request Sequence No. (16bit)

	printf OUT "#define SEQ_NO   0x00\n", $id;
	printf OUT "#define SEQ_NO_A 0x0a\n", $id;
	printf OUT "#define SEQ_NO_B 0x0b\n", $id;

	close(OUT);
	return 0;
}
#--------------------------------------------------------------#
# Packet Description
#--------------------------------------------------------------#
%pktdesc = (
	rs					=> '    Receive RS: NUT --> Multicast',
	ra_ha0_to_multi		=> '    Send RA: HA0 --> NUT0(multicast)',
	ra_ha1_to_multi		=> '    Send RA: HA1 --> NUT0(multicast)',
	ra_ha2_to_multi		=> '    Send RA: HA2 --> NUT1(multicast)',
	ra_ha0_to_multi_opthainfo	=> '    Send RA: HA0 --> NUT0(multicast, hainfo option)',
	ra_ha1_to_multi_opthainfo	=> '    Send RA: HA1 --> NUT0(multicast, hainfo option)',
	ra_ha2_to_multi_opthainfo	=> '    Send RA: HA2 --> NUT1(multicast, hainfo option)',
	ra_r1_to_multi		=> '    Send RA: R1 --> NUT1(multicast)',
	ra_r2_to_multi		=> '    Send RA: R2 --> NUT2(multicast)',
	ra_delete_ha0_to_multi	=> '    Send RA(Hbit=0): HA0 --> NUT0(multicast)',
	ra_delete_ha1_to_multi	=> '    Send RA(Hbit=0): HA1 --> NUT0(multicast)',
	ra_delete_ha2_to_multi	=> '    Send RA(Hbit=0): HA2 --> NUT1(multicast)',
	
	dadns_nut0 	=> '    Receive DAD NS(Link-Local): NUT0 --> multicast',
	dadns_nut1 	=> '    Receive DAD NS(Link-Local): NUT1 --> multicast',
	dadns_nut2 	=> '    Receive DAD NS(Link-Local): NUT2 --> multicast',
	
	na_ha0lla_to_nut0	=> '    Send NA(Link-Local): HA0 --> NUT0',
	na_ha0llataga_to_nut0	=> '    Send NA(Link-Local, TA Global): HA0 --> NUT0',
	na_ha0ga_to_nut0	=> '    Send NA(Global): HA0 --> NUT0',
	na_ha1lla_to_nut0	=> '    Send NA(Link-Local): HA0 --> NUT0',
	na_ha2lla_to_nut1	=> '    Send NA(Link-Local): HA2 --> NUT1',
	na_r1lla_to_nut1	=> '    Send NA(Link-Local): R1 --> NUT1',
	na_r2lla_to_nut2	=> '    Send NA(Link-Local): R2 --> NUT2',
	
	na_nut0ga_to_multi	=> '    Send NA(Global): NUT0 --> multicast',
	
	echorequest_tn_to_nut0			=> '    Send Echo Request: TN --> NUT0',
	echorequest_tn_to_nut1			=> '    Send Echo Request: TN --> NUT1',
	echorequest_tn_to_nut2			=> '    Send Echo Request: TN --> NUT2',
	echorequest_tunnel_tn_to_nut1	=> '    Send Echo Request: TN --> NUT1 (out: HA0->NUT1, in: TN->NUT0)',
	echorequest_tunnel_tn_to_nut2	=> '    Send Echo Request: TN --> NUT2 (out: HA0->NUT2, in: TN->NUT0)',
	echorequest_rh_tn_to_nut1		=> '    Send Echo Request: TN --> NUT1 (RH: NUT0))',
	echorequest_rh_tn_to_nut2		=> '    Send Echo Request: TN --> NUT2 (RH: NUT0)',
	echorequest_tunnel_tn_to_nut1to2_ha0 => '    Send Echo Request: TN --> NUT2 (out: HA0->NUT2, in: TN->NUT1(RH))',
	echorequest_tunnel_tn_to_nut1to2_ha2 => '    Send Echo Request: TN --> NUT2 (out: HA2->NUT2, in: TN->NUT1(RH))',
	
	echorequest_binack_ha0_to_nut1 => '    Send Echo Request: HA0 --> NUT1 (w/ Binding Acknowledgement)',
	
	echoreply_nut0_to_tn			=> '    Receive Echo Reply: NUT0 --> TN',
	echoreply_nut1_to_tn			=> '    Receive Echo Reply: NUT1 --> TN',
	echoreply_nut2_to_tn			=> '    Receive Echo Reply: NUT2 --> TN',
	echoreply_update_nut1_to_tn		=> '    Receive Echo Reply(w/ Binding Update): NUT1 --> TN',
	echoreply_update_nut2_to_tn		=> '    Receive Echo Reply(w/ Binding Update): NUT2 --> TN',
	echoreply_opt_home_nut1_to_tn	=> '    Receive Echo Reply(w/ Opt HomeAddress): NUT1 --> TN',
	echoreply_opt_home_nut2_to_tn	=> '    Receive Echo Reply(w/ Opt HomeAddress): NUT2 --> TN',
	echoreply_rev_tun_nut1_to_tn	=> '    Receive Echo Reply: NUT1 --> TN  (out: NUT1->HA0, in: HA0->TN)',
	echoreply_rev_tun_nut2_to_tn	=> '    Receive Echo Reply: NUT2 --> TN  (out: NUT2->HA0, in: HA0->TN)',
	
	echoreply_nut0_to_ha1			=> '    Receive Echo Reply: NUT0 --> HA1',
	
	bindingupdate_nut0_to_ha0		=> '    Receive Binding Update: NUT0 --> HA0',
	bindingupdate_nut1_to_ha0		=> '    Receive Binding Update: NUT1 --> HA0',
	bindingupdate_nut1_to_ha1		=> '    Receive Binding Update: NUT1 --> HA1',
	bindingupdate_nut1_to_tn		=> '    Receive Binding Update: NUT1 --> TN',
	bindingupdate_nut2_to_ha0		=> '    Receive Binding Update: NUT2 --> HA0',
	bindingupdate_nut2_to_ha1		=> '    Receive Binding Update: NUT2 --> HA1',
	bindingupdate_nut2_to_tn		=> '    Receive Binding Update: NUT2 --> TN',
	bindingupdate_to_ha0			=> '    Receive Binding Update: any --> HA0',
	bindingupdate_to_ha2			=> '    Receive Binding Update: any --> HA2',
	bindingupdate_nut1_to_ha0_uniqid => '    Receive Binding Update: NUT1 --> HA0(w/ UniqueIdentifier)',
	bindingupdate_nut1_to_tn_uniqid => '    Receive Binding Update: NUT1 --> TN(w/ UniqueIdentifier)',
	bindingupdate_nut2_to_ha2		=> '    Receive Binding Update: NUT2 --> HA2 (HomeAddress:NUT1)',
	
	bindingacknowledgement_ha0_to_nut0	=> '    Send Binding Acknowledgement: HA0 --> NUT0',
	bindingacknowledgement_ha0_to_nut1	=> '    Send Binding Acknowledgement: HA0 --> NUT1',
	bindingacknowledgement_ha0_to_nut2	=> '    Send Binding Acknowledgement: HA0 --> NUT2',
	bindingacknowledgement_ha1_to_nut1	=> '    Send Binding Acknowledgement: HA1 --> NUT1',
	bindingacknowledgement_ha1_to_nut2	=> '    Send Binding Acknowledgement: HA1 --> NUT2',
	bindingacknowledgement_ha2_to_nut2	=> '    Send Binding Acknowledgement: HA2 --> NUT2 (HomeAddress:NUT1)',
	
	bindingrequest_tn_to_nut1			=> '    Send Binding Refresh Requests: TN --> NUT1',
	
	hoti_nut1_to_ha0	=> '    Receive Home Test Init: NUT1 --> HA0',
	coti_nut1_to_tn		=> '    Receive Care-of Test Init: NUT1 --> TN',
	hoti_nut2_to_ha0	=> '    Receive Home Test Init: NUT2 --> HA0',
	coti_nut2_to_tn		=> '    Receive Care-of Test Init: NUT2 --> TN',
	
	hot_tn_to_nut1_via_ha0		=> '    Send Home Test: TN --> HA0 ==> NUT1',
	cot_tn_to_nut1		=> '    Send Care-of Test: TN --> NUT1',
	
	bindingerror_ha0_to_nut1	=>  '    Send Binding Error: HA0 --> NUT1',
	
	mobileprefixsolicitation_nut1_to_ha0	=> '    Receive Mobile Prefix Solicitation: NUT1 --> HA0',
	mobileprefixadvertisement_ha0_to_nut1	=> '    Send Mobile Prefix Advertisement: HA0 --> NUT1',
	mobileprefixadvertisement_ha1_to_nut1	=> '    Send Mobile Prefix Advertisement: HA1 --> NUT1',
	mobileprefixadvertisement_ha2_to_nut0	=> '    Send Mobile Prefix Advertisement: HA2 --> NUT0',
	mobileprefixadvertisement_bindingreq_ha0_to_nut1	=> '    Send Mobile Prefix Advertisement: HA0 --> NUT1(w/ Binding Request)',

	echorequest_tunnel_tn_to_nut1_frag	=>	'    Send Echo Request Fragment: HA0 --> NUT1(out: HA0->NUT1, in: TN->NUT0)',
);
