#!/usr/bin/perl
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
# $TAHI: ct/mip6-ha-20/MIP6.pm,v 1.34 2003/06/04 07:16:34 akisada Exp $
#
################################################################

my $vrecv_wait = 1;
my $vrecv_loop = 3;

my $retrans_timer = 1;
my $max_multicast_solicit = 3;
my $reachable_time = 30;
my $max_random_factor = 1.5;
my $delay_first_probe_time = 5;
my $max_unicast_solicit = 3;

package MIP6;

use Exporter;
@ISA = qw(Exporter);

@EXPORT = qw(
	$NOT_FLUSH_HA_LIST_DEBUG
	%pktdesc
	%nd
	MIP6_Initialize
	MIP6_CheckReachability
	MIP6_Registration
	MIP6_CheckBindingCache
	MIP6_RegistrationNotHomeSubnet
	MIP6_InvalidDeRegistration
	MIP6_DeRegistration
	MIP6_DeRegistrationHome
	MIP6_CheckNoBindingCacheNotHomeSubnet
	MIP6_CheckNoBindingCacheHomeSubnet
	MIP6_DAD
	MIP6_DAD_Failed
	MIP6_ReverseTunneling
	MIP6_MulticastNA
	MIP6_DHAAD
	MIP6_SendRS
	MIP6_SendRA_HA1
	MIP6_SendRA_HA1_HA2
	MIP6_ProxyND
	MIP6_SendRecv
	MIP6_BE_UnknownType
	MIP6_NoResponse
	MIP6_BU_Piggyback
	MIP6_SendBackDstUnreach4LL
	MIP6_UpdateCoA
	MIP6_InvalidSequence
	MIP6_BU_PiggybackHome
	MIP6_Sleep
	MIP6_Get_Addr
);

use V6evalTool;

################################################################
$NOT_FLUSH_HA_LIST_DEBUG = 1;

################################################################
%pktdesc = (
	'ereq_from_tn_to_nut_global'			=> '    Send Echo Request: CN (LinkX) -&gt; NUT (Link0) (global)',
	'erep_from_nut_to_tn_global'			=> '    Recv Echo Reply: NUT (Link0) -&gt; CN (LinkX) (global)',
	'ereq_from_tn_to_hoa_global'			=> '    Send Echo Request: CN (LinkX) -&gt; MN (Link0) (global)',
	'ereq_from_tn_to_hoa_global_encapsulated'	=> '    Recv Echo Request (encapsulated): HA (Link0) -&gt; MN\' (LinkX) (global)',
	'ereq_from_mn_to_tn_global_encapsulated'	=> '    Send Echo Request (encapsulated): MN (Link0) -&gt; CN (LinkX) (global)',
	'ereq_from_mn_to_tn_global'			=> '    Recv Echo Request: MN (Link0) -&gt; CN (LinkX) (global)',
	'ereq_from_tn_to_hoa_y_global'			=> '    Send Echo Request (forwarded): CN (LinkX) -&gt; MN (LinkY) (global)',
	'ereq_from_tn_to_hoa_0_global'			=> '    Send Echo Request (forwarded): CN (LinkX) -&gt; MN (Link0) (global)',
	'ns_from_nut_to_r0_multicast_global'		=> '    Recv NS: NUT (Link0) -&gt; R0 (Link0) (multicast, global)',
	'ns_from_nut_to_r0_unicast_global'		=> '    Recv NS w/o SLL: NUT (Link0) -&gt; R0 (Link0) (unicast, global)',
	'ns_from_nut_to_r0_unicast_sll_global'		=> '    Recv NS w/ SLL: NUT (Link0) -&gt; R0 (Link0) (unicast, global)',
	'na_from_r0_to_nut_global'			=> '    Send NA: R0 (Link0) -&gt; NUT (Link0) (global)',
	'ns_from_nut_to_mn_multicast_global'		=> '    Recv NS: NUT (Link0) -&gt; MN (Link0) (multicast, global)',
	'ns_from_nut_to_mn_unicast_global'		=> '    Recv NS w/o SLL: NUT (Link0) -&gt; MN (Link0) (unicast, global)',
	'ns_from_nut_to_mn_unicast_sll_global'		=> '    Recv NS w/ SLL: NUT (Link0) -&gt; MN (Link0) (unicast, global)',
	'na_from_mn_to_nut_global'			=> '    Send NA: MN (Link0) -&gt; NUT (Link0) (global)',
	'ra_from_nut'					=> '    Recv RA: NUT (Link0) -&gt; all-nodes multicast address (Link0)',
	'ra_from_ha1'					=> '    Send RA: HA1 (Link0) -&gt; all-nodes multicast address (Link0)',
	'ra_from_ha2'					=> '    Send RA: HA2 (Link0) -&gt; all-nodes multicast address (Link0)',
	'BU'						=> '    Send BU: MN\' (LinkX) -&gt; NUT (Link0) (global)',
	'BU_Invalid_Checksum'				=> '    Send BU (invalid checksum): MN\' (LinkX) -&gt; NUT (Link0) (global)',
	'BU_Piggyback'					=> '    Send BU (piggybacking): MN\' (LinkX) -&gt; NUT (Link0) (global)',
	'ParameterProblem_BU_Piggyback'			=> '    Recv Parameter Problem: NUT (Link0) -&gt; MN\' (LinkX) (global)',
	'MH_ANY'					=> '    Send MH Type=255: MN\' (LinkX) -&gt; NUT (Link0) (global)',
	'BU_Home'					=> '    Send BU: MN (Link0) -&gt; NUT (Link0) (global)',
	'BU_Home_Piggyback'				=> '    Send BU (piggybacking): MN (Link0) -&gt; NUT (Link0) (global)',
	'ParameterProblem_BU_Home_Piggyback'		=> '    Recv Parameter Problem: NUT (Link0) -&gt; MN (Link0) (global)',
	'BA'						=> '    Recv BA: NUT (Link0) -&gt; MN\' (LinkX) (global)',
	'BE_UnknownType'				=> '    Recv BE Status=2: NUT (Link0) -&gt; MN\' (LinkX) (global)',
	'BA_DeReg'					=> '    Recv BA (De-Registration): NUT (Link0) -&gt; MN\' (LinkX) (global)',
	'BA_Home_DeReg'					=> '    Recv BA (De-Registration): NUT (Link0) -&gt; MN (Link0) (global)',
	'dad_linklocal'					=> '    Recv DAD: unspecified address -&gt; MN (link-local) solicited-node multicast address',
	'dad_global'					=> '    Recv DAD: unspecified address -&gt; MN (global) solicited-node multicast address',
	'na_dad_global'					=> '    Send NA (global): MN (Link0) -&gt; all-nodes multicast address (Link0)',
	'na_dad_linklocal'				=> '    Send NA (link-local): MN (Link0) -&gt; all-nodes multicast address (Link0)',
	'multicast_na_global'				=> '    Recv NA (global): NUT (Link0) -&gt; all-nodes multicast address (Link0)',
	'multicast_na_linklocal'			=> '    Recv NA (link-local): NUT (Link0) -&gt; all-nodes multicast address (Link0)',
	'multicast_na_any'				=> '    Recv NA (global): NUT (Link0) -&gt; all-nodes multicast address (Link0)',
	'HAADReq'					=> '    Send HAAD Request: MN\' (LinkX) -&gt; MIP6 HAs anycast address',
	'HAADRep'					=> '    Recv HAAD Reply: HA (Link0) -&gt; MN\' (LinkX)',
	'HAADRepDelete'					=> '    Recv HAAD Reply: HA (Link0) -&gt; MN\' (LinkX)',
	'rs_from_mn'					=> '    Send RS: unspecified address -&gt; all-routers multicast address',
	'proxy_global_ns_dad'				=> '    Send NS: unspecified address -&gt; MN (global) solicited-node multicast address',
	'proxy_global_ns_multi'				=> '    Send NS: CN0 (Link0) -&gt; MN (Link0) (multicast, global)',
	'proxy_global_ns_uni'				=> '    Send NS: CN0 (Link0) -&gt; MN (Link0) (unicast, global)',
	'proxy_link_ns_dad'				=> '    Send NS: unspecified address -&gt; MN (link-local) solicited-node multicast address',
	'proxy_link_ns_multi'				=> '    Send NS: CN0 (Link0) -&gt; MN (Link0) (multicast, link-local)',
	'proxy_link_ns_uni'				=> '    Send NS: CN0 (Link0) -&gt; MN (Link0) (unicast, link-local)',
	'proxy_global_na'				=> '    Recv NA w/ TLL: MN (Link0) -&gt; CN0 (Link0) (global)',
	'proxy_global_na_tll'				=> '    Recv NA w/o TLL: MN (Link0) -&gt; CN0 (Link0) (global)',
	'proxy_link_na'					=> '    Recv NA w/ TLL: MN (Link0) -&gt; CN0 (Link0) (link-local)',
	'proxy_link_na_tll'				=> '    Recv NA w/o TLL: MN (Link0) -&gt; CN0 (Link0) (link-local)',
	'proxy_global_na_dad'				=> '    Recv NA (global): MN (Link0) -&gt; all-nodes multicast address (Link0)',
	'proxy_link_na_dad'				=> '    Recv NA (link-local): MN (Link0) -&gt; all-nodes multicast address (Link0)',
	'MPS'						=> '    Send MPS: MN\' (LinkX) -&gt; NUT (Link0) (global)',
	'MPA'						=> '    Recv MPA: NUT (Link0) -&gt; MN\' (LinkX) (global)',
	'ereq_from_mn_to_nut_bce'			=> '    Send Echo Request: MN\' (LinkX) -&gt; NUT (Link0) (global)',
	'erep_from_nut_to_mn_bce'			=> '    Recv Echo Reply: NUT (Link0) -&gt; MN\' (LinkX) (global)',
	'ereq_from_cn0_to_mn_linklocal'			=> '    Send Echo Request: CN0 (Link0) -&gt; MN (Link0) (link-local)',
	'destination_unreachable_linklocal'		=> '    Recv Destination Unreachable: NUT (Link0) -&gt; CN0 (Link0) (link-local)',
	'destination_unreachable_linklocal_hoplimit_m1'	=> '    Recv Destination Unreachable: NUT (Link0) -&gt; CN0 (Link0) (link-local)',
	'ns_from_nut_to_tn_multicast_linklocal'		=> '    Recv NS: NUT (Link0) -&gt; CN0 (Link0) (multicast, global)',
	'ns_from_nut_to_tn_unicast_linklocal'		=> '    Recv NS w/o SLL: NUT (Link0) -&gt; CN0 (Link0) (unicast, global)',
	'ns_from_nut_to_tn_unicast_sll_linklocal'	=> '    Recv NS w/ SLL: NUT (Link0) -&gt; CN0 (Link0) (unicast, global)',
	'na_from_tn_to_nut_linklocal'			=> '    Send NA: C0 (Link0) -&gt; NUT (Link0) (global)',
	'MLD_Report'					=> '    Recv MLD Report: NUT (Link0) -&gt; MN (link-local) solicited-node multicast address',
	'dummy_for_getaddr'				=> '    Send Dummy Packet for calculating IP addresses',
);

################################################################
%nd = (
	'ns_from_nut_to_r0_multicast_global'	=> 'na_from_r0_to_nut_global',
	'ns_from_nut_to_r0_unicast_global'	=> 'na_from_r0_to_nut_global',
	'ns_from_nut_to_r0_unicast_sll_global'	=> 'na_from_r0_to_nut_global',
	'ra_from_nut'				=> 'ignore',
	'MLD_Report'				=> 'ignore',
	'multicast_na_any'	=> 'ignore',
);

#
# MIP6_Initialize()
#
################################################################

sub MIP6_Initialize($$) {
	my ($Link, $Device) = @_;

	vClear($Link);

	my $mobile_node = '';
	my $home_agent = '';

	if(MIP6_Get_Addr($Link, \$mobile_node, \$home_agent) < 0) {
		return(-1);
	}

	vLogHTML('<BLOCKQUOTE>');
	vLogHTML('<TABLE WIDTH="50%" BORDER>');
	vLogHTML("<TR><TH ALIGN=\"left\">MN address</TH><TD>$mobile_node</TD></TR>");
	vLogHTML("<TR><TH ALIGN=\"left\">HA address</TH><TD>$home_agent</TD></TR>");
	vLogHTML('</TABLE>');
	vLogHTML('</BLOCKQUOTE>');
	vClear($Link);

	vLogHTML('<FONT SIZE="4"><U><B>Initialize target</B></U></FONT><BR>');
	if(vRemote('reboot.rmt', '')) {
		vLogHTML('<FONT COLOR="#FF0000">reboot.rmt: Can\'t reboot</FONT><BR>');
		exit($V6evalTool::exitFatal);
	}

	if(vRemote('rtadvd.rmt', 'start', 'mipv6',
		'maxinterval=60',
		'mininterval=40',
		'raflags=32',
		'rltime=1800',
		'pinfoflags=224',
		"link0=$Device",
		'hapref=10', 'hatime=1800',
		"haaddr=$home_agent", '')
	) {
		vLogHTML('<FONT COLOR="#FF0000">rtadvd.rmt: Can\'t enable RA function</FONT><BR>');
		return(-1);
	}

	if(vRemote('mip6EnableHA.rmt', "device=$Device", '')) {
		vLogHTML('<FONT COLOR="#FF0000">mip6EnableHA.rmt: Can\'t enable HA function</FONT><BR>');
		exit($V6evalTool::exitFatal);
	}

	if(vRemote('route.rmt', 'cmd=add', 'prefix=default', 'gateway=3ffe:501:ffff:100::a0a0')) {
		vLogHTML('<FONT COLOR="#FF0000">route.rmt: Can\'t configure routing table</FONT><BR>');
		exit($V6evalTool::exitFatal);
	}

	vSleep(3);

	return(0);
}

#
# MIP6_CheckReachability()
#
#	chek global reachability
#	chek default router
#
################################################################

sub MIP6_CheckReachability($) {
	my ($Link) = @_;

	my %ret = ();

	vClear($Link);
	vSend($Link, 'ereq_from_tn_to_nut_global');

	for(my $d = 0; $d < $vrecv_loop; $d ++) {
		my $recv = '';
		my $send = '';

		%ret = vRecv($Link, $vrecv_wait, 0, 0, sort(keys(%nd)), 'erep_from_nut_to_tn_global');

		while(($recv, $send) = each(%nd)) {
			if($ret{'recvFrame'} eq $recv) {
				if($send ne 'ignore') {
					vSend($Link, $send);
				}

				$d --;
				last;
			}
		}

		if($ret{'recvFrame'} eq 'erep_from_nut_to_tn_global') {
			return(0);
		}
	}

	return(-1);
}

#
# MIP6_Registration()
#
################################################################

sub MIP6_Registration($$$$$$) {
	my ($Link, $sn, $a, $h, $l, $lt) = @_;

	my %ret = ();

	my $cpp = '';

	if($sn) {
		$cpp .= "-DSEQ_BU=$sn ";
		$cpp .= "-DSEQ_BA=$sn ";
	}

	if($a) {
		$cpp .= "-DACKNOWLEDGE=$a ";
	}

	if($h) {
		$cpp .= "-DHOMEREGISTRATION=$h ";
	}

	if($l) {
		$cpp .= "-DLINKLOCAL=$l ";
	}

	if($lt) {
		$cpp .= "-DLIFETIME=$lt ";
	}

	vCPP($cpp);

	vClear($Link);
	vSend($Link, 'BU');

	for(my $d = 0; $d < $vrecv_loop; $d ++) {
		my $recv = '';
		my $send = '';

		%ret = vRecv($Link, $vrecv_wait, 0, 0, sort(keys(%nd)), 'BA');

		while(($recv, $send) = each(%nd)) {
			if($ret{'recvFrame'} eq $recv) {
				if($send ne 'ignore') {
					vSend($Link, $send);
				}

				$d --;
				last;
			}
		}

		if($ret{'recvFrame'} eq 'BA') {
			return(0);
		}
	}

	return(-1);
}

#
# MIP6_CheckBindingCache()
#
################################################################

sub MIP6_CheckBindingCache($) {
	my ($Link) = @_;

	my %ret = ();

	vClear($Link);
	vSend($Link, 'ereq_from_tn_to_hoa_global');

	for(my $d = 0; $d < $vrecv_loop; $d ++) {
		my $recv = '';
		my $send = '';

		%ret = vRecv($Link, $vrecv_wait, 0, 0, sort(keys(%nd)), 'ereq_from_tn_to_hoa_global_encapsulated');

		while(($recv, $send) = each(%nd)) {
			if($ret{'recvFrame'} eq $recv) {
				if($send ne 'ignore') {
					vSend($Link, $send);
				}

				$d --;
				last;
			}
		}

		if($ret{'recvFrame'} eq 'ereq_from_tn_to_hoa_global_encapsulated') {
			return(0);
		}
	}

	return(-1);
}

#
# MIP6_DeRegistration()
#
################################################################

sub MIP6_DeRegistration($$$$$$) {
	my ($Link, $sn, $a, $h, $l, $lt) = @_;

	my %ret = ();

	my $cpp = '';

	if($sn) {
		$cpp .= "-DSEQ_BU=$sn ";
		$cpp .= "-DSEQ_BA=$sn ";
	}

	if($a) {
		$cpp .= "-DACKNOWLEDGE=$a ";
	}

	if($h) {
		$cpp .= "-DHOMEREGISTRATION=$h ";
	}

	if($l) {
		$cpp .= "-DLINKLOCAL=$l ";
	}

	if($lt) {
		$cpp .= "-DLIFETIME=$lt ";
	}

	vCPP($cpp);

	vClear($Link);
	vSend($Link, 'BU');

	for(my $d = 0; $d < $vrecv_loop; $d ++) {
		my $recv = '';
		my $send = '';

		%ret = vRecv($Link, $vrecv_wait, 0, 0, sort(keys(%nd)), 'BA_DeReg');

		while(($recv, $send) = each(%nd)) {
			if($ret{'recvFrame'} eq $recv) {
				if($send ne 'ignore') {
					vSend($Link, $send);
				}

				$d --;
				last;
			}
		}

		if($ret{'recvFrame'} eq 'BA_DeReg') {
			return(0);
		}
	}

	return(-1);
}

#
# MIP6_DeRegistrationHome()
#
################################################################

sub MIP6_DeRegistrationHome($$$$$$) {
	my ($Link, $sn, $a, $h, $l, $lt) = @_;

	my %ret = ();

	$nd{'ns_from_nut_to_mn_multicast_global'}	= 'na_from_mn_to_nut_global';
	$nd{'ns_from_nut_to_mn_unicast_global'}		= 'na_from_mn_to_nut_global';
	$nd{'ns_from_nut_to_mn_unicast_sll_global'}	= 'na_from_mn_to_nut_global';

	my $cpp = '';

	if($sn) {
		$cpp .= "-DSEQ_BU=$sn ";
		$cpp .= "-DSEQ_BA=$sn ";
	}

	if($a) {
		$cpp .= "-DACKNOWLEDGE=$a ";
	}

	if($h) {
		$cpp .= "-DHOMEREGISTRATION=$h ";
	}

	if($l) {
		$cpp .= "-DLINKLOCAL=$l ";
	}

	if($lt) {
		$cpp .= "-DLIFETIME=$lt ";
	}

	vCPP($cpp);

	vClear($Link);
	vSend($Link, 'BU_Home');

	for(my $d = 0; $d < $vrecv_loop; $d ++) {
		my $recv = '';
		my $send = '';

		%ret = vRecv($Link, $vrecv_wait, 0, 0, sort(keys(%nd)), 'BA_Home_DeReg');

		while(($recv, $send) = each(%nd)) {
			if($ret{'recvFrame'} eq $recv) {
				if($send ne 'ignore') {
					vSend($Link, $send);
				}

				$d --;
				last;
			}
		}

		if($ret{'recvFrame'} eq 'BA_Home_DeReg') {
			return(0);
		}
	}

	return(-1);
}

#
# MIP6_RegistrationNotHomeSubnet()
#
################################################################

sub MIP6_RegistrationNotHomeSubnet($$$$$$) {
	my ($Link, $sn, $a, $h, $l, $lt) = @_;

	my %ret = ();

	my $cpp .= "-DSTATUS=132 ";
	my $count = 0;

	$pktdesc{'BA'} = '    Recv BA Status=132: NUT (Link0) -&gt; MN\' (LinkX) (global)';

	if($sn) {
		$cpp .= "-DSEQ_BU=$sn ";
		$cpp .= "-DSEQ_BA=$sn ";
	}

	if($a) {
		$cpp .= "-DACKNOWLEDGE=$a ";
	}

	if($h) {
		$cpp .= "-DHOMEREGISTRATION=$h ";
	}

	if($l) {
		$cpp .= "-DLINKLOCAL=$l ";
	}

	if($lt) {
		$cpp .= "-DLIFETIME=$lt ";
	}

	vCPP($cpp);

	vClear($Link);
	vSend($Link, 'BU');

	for(my $d = 0; $d < $vrecv_loop; $d ++) {
		my $recv = '';
		my $send = '';

		%ret = vRecv($Link, $vrecv_wait, 0, 0, sort(keys(%nd)), 'BA');
		$count = $ret{'recvCount'};

		while(($recv, $send) = each(%nd)) {
			if($ret{'recvFrame'} eq $recv) {
				if($send ne 'ignore') {
					vSend($Link, $send);
				}

				$d --;
				$count --;
				last;
			}
		}

		if($ret{'recvFrame'} eq 'BA') {
			return(0);
		}

		if($count) {
			vLogHTML('<FONT COLOR="#FF0000">Recv unexpect packets</FONT><BR>');

			vLogHTML('<FONT COLOR="#FF0000">wait RETRANS_TIMER * MAX_MULTICAST_SOLICIT</FONT><BR>');
			vSleep($retrans_timer * $max_multicast_solicit);

			exit($V6evalTool::exitFail);
		}
	}

	return(-1);
}

#
# MIP6_InvalidDeRegistration()
#
################################################################

sub MIP6_InvalidDeRegistration($$$$$$) {
	my ($Link, $sn, $a, $h, $l, $lt) = @_;

	my %ret = ();

	my $cpp .= "-DSTATUS=133 ";
	my $count = 0;

	$pktdesc{'BA'} = '    Recv BA Status=133: NUT (Link0) -&gt; MN\' (LinkX) (global)';

	if($sn) {
		$cpp .= "-DSEQ_BU=$sn ";
		$cpp .= "-DSEQ_BA=$sn ";
	}

	if($a) {
		$cpp .= "-DACKNOWLEDGE=$a ";
	}

	if($h) {
		$cpp .= "-DHOMEREGISTRATION=$h ";
	}

	if($l) {
		$cpp .= "-DLINKLOCAL=$l ";
	}

	if($lt) {
		$cpp .= "-DLIFETIME=$lt ";
	}

	vCPP($cpp);

	vClear($Link);
	vSend($Link, 'BU');

	for(my $d = 0; $d < $vrecv_loop; $d ++) {
		my $recv = '';
		my $send = '';

		%ret = vRecv($Link, $vrecv_wait, 0, 0, sort(keys(%nd)), 'BA');
		$count = $ret{'recvCount'};

		while(($recv, $send) = each(%nd)) {
			if($ret{'recvFrame'} eq $recv) {
				if($send ne 'ignore') {
					vSend($Link, $send);
				}

				$d --;
				$count --;
				last;
			}
		}

		if($ret{'recvFrame'} eq 'BA') {
			return(0);
		}

		if($count) {
			vLogHTML('<FONT COLOR="#FF0000">Recv unexpect packets</FONT><BR>');

			vLogHTML('<FONT COLOR="#FF0000">wait RETRANS_TIMER * MAX_MULTICAST_SOLICIT</FONT><BR>');
			vSleep($retrans_timer * $max_multicast_solicit);

			exit($V6evalTool::exitFail);
		}
	}

	return(-1);
}

#
# MIP6_CheckNoBindingCacheNotHomeSubnet()
#
################################################################

sub MIP6_CheckNoBindingCacheNotHomeSubnet($) {
	my ($Link) = @_;

	my %ret = ();

	$pktdesc{'ereq_from_tn_to_hoa_global'} = '    Send Echo Request: CN (LinkX) -&gt; MN (LinkY) (global)';

	vClear($Link);
	vSend($Link, 'ereq_from_tn_to_hoa_global');

	for(my $d = 0; $d < $vrecv_loop; $d ++) {
		my $recv = '';
		my $send = '';

		%ret = vRecv($Link, $vrecv_wait, 0, 0, sort(keys(%nd)), 'ereq_from_tn_to_hoa_y_global');

		while(($recv, $send) = each(%nd)) {
			if($ret{'recvFrame'} eq $recv) {
				if($send ne 'ignore') {
					vSend($Link, $send);
				}

				$d --;
				last;
			}
		}

		if($ret{'recvFrame'} eq 'ereq_from_tn_to_hoa_y_global') {
			return(0);
		}
	}

	return(-1);
}

#
# MIP6_CheckNoBindingCacheHomeSubnet()
#
################################################################

sub MIP6_CheckNoBindingCacheHomeSubnet($) {
	my ($Link) = @_;

	my %ret = ();

	$nd{'ns_from_nut_to_mn_multicast_global'}	= 'na_from_mn_to_nut_global';
	$nd{'ns_from_nut_to_mn_unicast_global'}		= 'na_from_mn_to_nut_global';
	$nd{'ns_from_nut_to_mn_unicast_sll_global'}	= 'na_from_mn_to_nut_global';

	vClear($Link);
	vSend($Link, 'ereq_from_tn_to_hoa_global');

	for(my $d = 0; $d < $vrecv_loop; $d ++) {
		my $recv = '';
		my $send = '';

		%ret = vRecv($Link, $vrecv_wait, 0, 0, sort(keys(%nd)), 'ereq_from_tn_to_hoa_0_global');

		while(($recv, $send) = each(%nd)) {
			if($ret{'recvFrame'} eq $recv) {
				if($send ne 'ignore') {
					vSend($Link, $send);
				}

				$d --;
				last;
			}
		}

		if($ret{'recvFrame'} eq 'ereq_from_tn_to_hoa_0_global') {
			return(0);
		}
	}

	return(-1);
}

#
# MIP6_DAD()
#
################################################################

sub MIP6_DAD($$$$$$) {
	my ($Link, $sn, $a, $h, $l, $lt) = @_;

	my %ret = ();

	my $cpp = '';

	my $got_dad_linklocal = 0;
	my $got_dad_global = 0;

	if($sn) {
		$cpp .= "-DSEQ_BU=$sn ";
		$cpp .= "-DSEQ_BA=$sn ";
	}

	if($a) {
		$cpp .= "-DACKNOWLEDGE=$a ";
	}

	if($h) {
		$cpp .= "-DHOMEREGISTRATION=$h ";
	}

	if($l) {
		$cpp .= "-DLINKLOCAL=$l ";
	}

	if($lt) {
		$cpp .= "-DLIFETIME=$lt ";
	}

	vCPP($cpp);

	vClear($Link);
	vSend($Link, 'BU');

	for(my $d = 0; $d < $vrecv_loop; $d ++) {
		my $recv = '';
		my $send = '';

		%ret = vRecv($Link, $vrecv_wait, 0, 0, sort(keys(%nd)), 'BA', 'dad_linklocal', 'dad_global');

		while(($recv, $send) = each(%nd)) {
			if($ret{'recvFrame'} eq $recv) {
				if($send ne 'ignore') {
					vSend($Link, $send);
				}

				$d --;
				last;
			}
		}

		if($ret{'recvFrame'} eq 'dad_global') {
			$got_dad_global ++;
			$d --;
			next;
		}

		if($ret{'recvFrame'} eq 'dad_linklocal') {
			$got_dad_linklocal ++;
			$d --;
			next;
		}

		if($ret{'recvFrame'} eq 'BA') {
			if(($got_dad_global == 0) && ($got_dad_linklocal != 0)) {
				return(0);
			}

			if(($got_dad_global == 0) && ($got_dad_linklocal == 0)) {
				vLogHTML('Can\'t get any DAD<BR>');
				exit($V6evalTool::exitFail);
			}

			if($l) {
				if(($got_dad_global != 0) && ($got_dad_linklocal != 0)) {
					return(0);
				}
			} else {
				if(($got_dad_global != 0) && ($got_dad_linklocal == 0)) {
					return(0);
				}
			}

			vLogHTML('Can\'t get DAD for expected scope<BR>');
			exit($V6evalTool::exitFail);
		}
	}

	return(-1);
}

#
# MIP6_DAD_Failed()
#
################################################################

sub MIP6_DAD_Failed($$$$$$) {
	my ($Link, $sn, $a, $h, $l, $lt) = @_;

	my %ret = ();

	my $cpp .= "-DSTATUS=134 ";

	$pktdesc{'BA'} = '    Recv BA Status=134: NUT (Link0) -&gt; MN\' (LinkX) (global)';

	my $got_dad = 0;
	my $got_ba = 0;

	my %dad = (
		'dad_global'	=> 'na_dad_global',
		'dad_linklocal'	=> 'na_dad_linklocal',
	);

	if($sn) {
		$cpp .= "-DSEQ_BU=$sn ";
		$cpp .= "-DSEQ_BA=$sn ";
	}

	if($a) {
		$cpp .= "-DACKNOWLEDGE=$a ";
	}

	if($h) {
		$cpp .= "-DHOMEREGISTRATION=$h ";
	}

	if($l) {
		$cpp .= "-DLINKLOCAL=$l ";
	}

	if($lt) {
		$cpp .= "-DLIFETIME=$lt ";
	}

	vCPP($cpp);

	vClear($Link);
	vSend($Link, 'BU');

	for(my $d = 0; $d < $vrecv_loop; $d ++) {
		my $recv = '';
		my $send = '';

		%ret = vRecv($Link, $vrecv_wait, 0, 0, sort(keys(%nd)), sort(keys(%dad)), 'BA');

		while(($recv, $send) = each(%nd)) {
			if($ret{'recvFrame'} eq $recv) {
				if($send ne 'ignore') {
					vSend($Link, $send);
				}

				$d --;
				last;
			}
		}

		while(($recv, $send) = each(%dad)) {
			if($ret{'recvFrame'} eq $recv) {
				vSend($Link, $send);

				$got_dad ++;

				$d --;
				last;
			}
		}

		if($ret{'recvFrame'} eq 'BA') {
			$got_ba ++;
			last;
		}
	}

	unless($got_dad) {
		vLogHTML('Can\'t get any DAD<BR>');
		exit($V6evalTool::exitFail);
	}

	unless($got_ba) {
		return(-1);
	}

	return(0);
}

#
# MIP6_ReverseTunneling()
#
################################################################

sub MIP6_ReverseTunneling($) {
	my ($Link) = @_;

	my %ret = ();

	vClear($Link);
	vSend($Link, 'ereq_from_mn_to_tn_global_encapsulated');

	for(my $d = 0; $d < $vrecv_loop; $d ++) {
		my $recv = '';
		my $send = '';

		%ret = vRecv($Link, $vrecv_wait, 0, 0, sort(keys(%nd)), 'ereq_from_mn_to_tn_global');

		while(($recv, $send) = each(%nd)) {
			if($ret{'recvFrame'} eq $recv) {
				if($send ne 'ignore') {
					vSend($Link, $send);
				}

				$d --;
				last;
			}
		}

		if($ret{'recvFrame'} eq 'ereq_from_mn_to_tn_global') {
			return(0);
		}
	}

	return(-1);
}

#
# MIP6_MulticastNA()
#
################################################################

sub MIP6_MulticastNA($$$$$$) {
	my ($Link, $sn, $a, $h, $l, $lt) = @_;

	my %ret = ();

	my $cpp = '';

	my $got_na_linklocal = 0;
	my $got_na_global = 0;
	my $got_ba = 0;

	if($sn) {
		$cpp .= "-DSEQ_BU=$sn ";
		$cpp .= "-DSEQ_BA=$sn ";
	}

	if($a) {
		$cpp .= "-DACKNOWLEDGE=$a ";
	}

	if($h) {
		$cpp .= "-DHOMEREGISTRATION=$h ";
	}

	if($l) {
		$cpp .= "-DLINKLOCAL=$l ";
	}

	if($lt) {
		$cpp .= "-DLIFETIME=$lt ";
	}

	vCPP($cpp);

	delete($nd{'multicast_na_any'});

	vClear($Link);
	vSend($Link, 'BU');

	for(my $d = 0; $d < $vrecv_loop; $d ++) {
		my $recv = '';
		my $send = '';

		%ret = vRecv($Link, $vrecv_wait, 0, 0, sort(keys(%nd)), 'BA', 'multicast_na_linklocal', 'multicast_na_global');

		while(($recv, $send) = each(%nd)) {
			if($ret{'recvFrame'} eq $recv) {
				if($send ne 'ignore') {
					vSend($Link, $send);
				}

				$d --;
				last;
			}
		}

		if($ret{'recvFrame'} eq 'multicast_na_global') {
			$got_na_global ++;
			$d --;
			next;
		}

		if($ret{'recvFrame'} eq 'multicast_na_linklocal') {
			$got_na_linklocal ++;
			$d --;
			next;
		}

		if($ret{'recvFrame'} eq 'BA') {
			$got_ba ++;
			$d --;
			next;
		}
	}

	if(($got_na_global == 0) && ($got_na_linklocal == 0)) {
		vLogHTML('Can\'t get any multicast NA<BR>');
		exit($V6evalTool::exitFail);
	}

#	if($got_ba) {
		if($l) {
			if(($got_na_global != 0) && ($got_na_linklocal != 0)) {
				return(0);
			}
		} else {
			if(($got_na_global != 0) && ($got_na_linklocal == 0)) {
				return(0);
			}
		}

		vLogHTML('Can\'t get multicast NA for expected scope<BR>');
		exit($V6evalTool::exitFail);
#	}

	return(-1);
}

#
# MIP6_DHAAD()
#
################################################################

sub MIP6_DHAAD($$$) {
	my ($Link, $vsend, $vrecv) = @_;

	my %ret = ();

	vClear($Link);
	vSend($Link, $vsend);

	for(my $d = 0; $d < $vrecv_loop; $d ++) {
		my $recv = '';
		my $send = '';

		%ret = vRecv($Link, $vrecv_wait, 0, 0, sort(keys(%nd)), $vrecv);

		while(($recv, $send) = each(%nd)) {
			if($ret{'recvFrame'} eq $recv) {
				if($send ne 'ignore') {
					vSend($Link, $send);
				}

				$d --;
				last;
			}
		}

		if($ret{'recvFrame'} eq $vrecv) {
			return(0);
		}
	}

	return(-1);
}

#
# MIP6_SendRA_HA1()
#
################################################################

sub MIP6_SendRA_HA1($$$) {
	my ($Link, $preference, $lifetime) = @_;

	my %ret = ();
	my $cpp = '';

	if($preference != 0) {
		$cpp .= "-DHA1_PREF=$preference ";
	}

	if($lifetime != 0) {
		$cpp .= "-DHA1_LIFETIME=$lifetime ";
	}

	vCPP($cpp);

	vClear($Link);

	for(my $d = 0; $d < $vrecv_loop; $d ++) {
		vSend($Link, 'rs_from_mn', 'ra_from_ha1');

		my $recv = '';
		my $send = '';

		%ret = vRecv($Link, $vrecv_wait, 0, 0, sort(keys(%nd)));

		while(($recv, $send) = each(%nd)) {
			if($ret{'recvFrame'} eq $recv) {
				if($send ne 'ignore') {
					vSend($Link, $send);
					$d --;
				}

				last;
			}
		}
	}

	return;
}

#
# MIP6_SendRS()
#
################################################################

sub MIP6_SendRS($) {
	my ($Link) = @_;

	my %ret = ();

	vCPP($cpp);

	vClear($Link);

	for(my $d = 0; $d < $vrecv_loop; $d ++) {
		vSend($Link, 'rs_from_mn');

		my $recv = '';
		my $send = '';

		%ret = vRecv($Link, $vrecv_wait, 0, 0, sort(keys(%nd)));

		while(($recv, $send) = each(%nd)) {
			if($ret{'recvFrame'} eq $recv) {
				if($send ne 'ignore') {
					vSend($Link, $send);
					$d --;
				}

				last;
			}
		}
	}

	return;
}

#
# MIP6_SendRA_HA1_HA2()
#
################################################################

sub MIP6_SendRA_HA1_HA2($$$$$) {
	my ($Link, $preference1, $lifetime1, $preference2, $lifetime2) = @_;

	my %ret = ();
	my $cpp = '';

	if($preference1 != 0) {
		$cpp .= "-DHA1_PREF=$preference1 ";
	}

	if($lifetime1 != 0) {
		$cpp .= "-DHA1_LIFETIME=$lifetime1 ";
	}

	if($preference2 != 0) {
		$cpp .= "-DHA2_PREF=$preference2 ";
	}

	if($lifetime2 != 0) {
		$cpp .= "-DHA2_LIFETIME=$lifetime2 ";
	}

	vCPP($cpp);

	vClear($Link);

	for(my $d = 0; $d < $vrecv_loop; $d ++) {
		vSend($Link, 'rs_from_mn', 'ra_from_ha1', 'ra_from_ha2');

		my $recv = '';
		my $send = '';

		%ret = vRecv($Link, $vrecv_wait, 0, 0, sort(keys(%nd)));

		while(($recv, $send) = each(%nd)) {
			if($ret{'recvFrame'} eq $recv) {
				if($send ne 'ignore') {
					vSend($Link, $send);
					$d --;
				}

				last;
			}
		}
	}

	return;
}

#
# MIP6_ProxyND()
#
################################################################

sub MIP6_ProxyND($$) {
	my ($Link, $l) = @_;

	my %result = ();
	my $got_fail = 0;

	my $bool_linklocal = 0;

	if($l) {
		$bool_linklocal ++;
	}

	delete($nd{'multicast_na_any'});

	vLogHTML('<B><A NAME="SUBTEST1">1. Multicast NS (global)<B> <A HREF="#SUMMARY">summary</A><BR>');
	$result{'1. Multicast NS (global)'}     = MIP6_SendRecv($Link, 1,               'proxy_global_ns_multi', 'proxy_global_na_tll');
#	MIP6_Sleep();

	vLogHTML('<B><A NAME="SUBTEST2">2. Multicast NS (link-local)<B> <A HREF="#SUMMARY">summary</A><BR>');
	$result{'2. Multicast NS (link-local)'} = MIP6_SendRecv($Link, $bool_linklocal, 'proxy_link_ns_multi',   'proxy_link_na_tll');
#	MIP6_Sleep();

	vLogHTML('<B><A NAME="SUBTEST3">3. Unicast NS (global)<B> <A HREF="#SUMMARY">summary</A><BR>');
	$result{'3. Unicast NS (global)'}       = MIP6_SendRecv($Link, 1,               'proxy_global_ns_uni',   'proxy_global_na', 'proxy_global_na_tll');
#	MIP6_Sleep();

	vLogHTML('<B><A NAME="SUBTEST4">4. Unicast NS (link-local)<B> <A HREF="#SUMMARY">summary</A><BR>');
	$result{'4. Unicast NS (link-local)'}   = MIP6_SendRecv($Link, $bool_linklocal, 'proxy_link_ns_uni',     'proxy_link_na', 'proxy_link_na_tll');
#	MIP6_Sleep();

	vLogHTML('<B><A NAME="SUBTEST5">5. DAD (global)<B> <A HREF="#SUMMARY">summary</A><BR>');
	$result{'5. DAD (global)'}              = MIP6_SendRecv($Link, 1,               'proxy_global_ns_dad',   'proxy_global_na_dad');
#	MIP6_Sleep();

	vLogHTML('<B><A NAME="SUBTEST6">6. DAD (link-local)<B> <A HREF="#SUMMARY">summary</A><BR>');
	$result{'6. DAD (link-local)'}          = MIP6_SendRecv($Link, $bool_linklocal, 'proxy_link_ns_dad',     'proxy_link_na_dad');
	MIP6_Sleep();

	my $step = 1;
	vLogHTML('<A NAME="SUMMARY">');
	vLogHTML('<TABLE BORDER>');
	for $title (sort(keys(%result))) {
		my $code = '<B>PASS</B>';

		if($result{$title} < 0) {
			$code = '<B><FONT COLOR="#FF0000">FAIL</FONT></B>';
			$got_fail ++;
		}

		vLogHTML('<TR>');
		vLogHTML("<TD ALIGN=\"left\">$title</TD>");
		vLogHTML("<TD ALIGN=\"right\">$code</TD>");
		vLogHTML("<TD ALIGN=\"center\"><A HREF=\"#SUBTEST$step\">reference</A></TD>");
		vLogHTML('</TR>');

		$step ++;
	}
	vLogHTML('</TABLE>');

	if($got_fail) {
		return(-1);
	}

	return(0);
}

#
# MIP6_SendRecv()
#
################################################################

sub MIP6_SendRecv($$$@) {
	my ($Link, $bool, $vsend, @vrecv) = @_;

	my %ret = ();

	vClear($Link);
	vSend($Link, $vsend);

	for(my $d = 0; $d < $vrecv_loop; $d ++) {
		my $recv = '';
		my $send = '';

		%ret = vRecv($Link, $vrecv_wait, 0, 0, sort(keys(%nd)), @vrecv);

		while(($recv, $send) = each(%nd)) {
			if($ret{'recvFrame'} eq $recv) {
				if($send ne 'ignore') {
					vSend($Link, $send);
					$d --;
				}

				last;
			}
		}

		for(my $d = 0; $d <= $#vrecv; $d ++) {
			if($ret{'recvFrame'} eq $vrecv[$d]) {
				if($bool) {
					return(0);
				} else {
					return(-1);
				}
			}
		}
	}

	if($bool) {
		return(-1);
	} else {
		return(0);
	}
}

#
# MIP6_BE_UnknownType()
#
################################################################

sub MIP6_BE_UnknownType($) {
	my ($Link) = @_;

	my %ret = ();
	my $got_be = 0;
	my $count = 0;

	vClear($Link);

	vSend($Link, 'MH_ANY');

	for(my $d = 0; $d < $vrecv_loop; $d ++) {
		my $recv = '';
		my $send = '';

		%ret = vRecv($Link, $vrecv_wait, 0, 0, sort(keys(%nd)), 'BE_UnknownType');
		$count = $ret{'recvCount'};

		while(($recv, $send) = each(%nd)) {
			if($ret{'recvFrame'} eq $recv) {
				if($send ne 'ignore') {
					vSend($Link, $send);
				}

				$d --;
				$count --;
				last;
			}
		}

		if($ret{'recvFrame'} eq 'BE_UnknownType') {
			$got_be ++;
			$count --;
		}

		if($count) {
			vLogHTML('<FONT COLOR="#FF0000">Recv unexpect packets</FONT><BR>');

			vLogHTML('<FONT COLOR="#FF0000">wait RETRANS_TIMER * MAX_MULTICAST_SOLICIT</FONT><BR>');
			vSleep($retrans_timer * $max_multicast_solicit);

			exit($V6evalTool::exitFail);
		}

		if($got_be) {
			last;
		}
	}

	unless($got_be) {
		return(-1);
	}

	for(my $d = 0; $d < $vrecv_loop; $d ++) {
		my $recv = '';
		my $send = '';

		%ret = vRecv($Link, $vrecv_wait, 0, 0, sort(keys(%nd)));
		$count = $ret{'recvCount'};

		while(($recv, $send) = each(%nd)) {
			if($ret{'recvFrame'} eq $recv) {
				if($send ne 'ignore') {
					vSend($Link, $send);
				}

				$d --;
				$count --;
				last;
			}
		}

		if($count) {
			vLogHTML('<FONT COLOR="#FF0000">Recv unexpect packets</FONT><BR>');

			vLogHTML('<FONT COLOR="#FF0000">wait RETRANS_TIMER * MAX_MULTICAST_SOLICIT</FONT><BR>');
			vSleep($retrans_timer * $max_multicast_solicit);

			exit($V6evalTool::exitFail);
		}
	}

	return(0);
}

#
# MIP6_NoResponse()
#
################################################################

sub MIP6_NoResponse($$) {
	my ($Link, $vsend) = @_;

	my %ret = ();
	my $count = 0;

	vClear($Link);

	vSend($Link, $vsend);

	for(my $d = 0; $d < $vrecv_loop; $d ++) {
		my $recv = '';
		my $send = '';

		%ret = vRecv($Link, $vrecv_wait, 0, 0, sort(keys(%nd)));
		$count = $ret{'recvCount'};

		while(($recv, $send) = each(%nd)) {
			if($ret{'recvFrame'} eq $recv) {
				if($send ne 'ignore') {
					vSend($Link, $send);
				}

				$d --;
				$count --;
				last;
			}
		}

		if($count) {
			return(-1);
		}
	}

	return(0);
}

#
# MIP6_BU_Piggyback()
#
################################################################

sub MIP6_BU_Piggyback($) {
	my ($Link) = @_;

	my %ret = ();
	my $got_pp = 0;
	my $count = 0;

	vClear($Link);

	vSend($Link, 'BU_Piggyback');

	for(my $d = 0; $d < $vrecv_loop; $d ++) {
		my $recv = '';
		my $send = '';

		%ret = vRecv($Link, $vrecv_wait, 0, 0, sort(keys(%nd)), 'ParameterProblem_BU_Piggyback');
		$count = $ret{'recvCount'};

		while(($recv, $send) = each(%nd)) {
			if($ret{'recvFrame'} eq $recv) {
				if($send ne 'ignore') {
					vSend($Link, $send);
				}

				$d --;
				$count --;
				last;
			}
		}

		if($ret{'recvFrame'} eq 'ParameterProblem_BU_Piggyback') {
			$got_pp ++;
			$count --;
		}

		if($count) {
			vLogHTML('<FONT COLOR="#FF0000">Recv unexpect packets</FONT><BR>');

			vLogHTML('<FONT COLOR="#FF0000">wait RETRANS_TIMER * MAX_MULTICAST_SOLICIT</FONT><BR>');
			vSleep($retrans_timer * $max_multicast_solicit);

			exit($V6evalTool::exitFail);
		}

		if($got_pp) {
			last;
		}
	}

	unless($got_pp) {
		return(-1);
	}

	for(my $d = 0; $d < $vrecv_loop; $d ++) {
		my $recv = '';
		my $send = '';

		%ret = vRecv($Link, $vrecv_wait, 0, 0, sort(keys(%nd)));
		$count = $ret{'recvCount'};

		while(($recv, $send) = each(%nd)) {
			if($ret{'recvFrame'} eq $recv) {
				if($send ne 'ignore') {
					vSend($Link, $send);
				}

				$d --;
				$count --;
				last;
			}
		}

		if($count) {
			vLogHTML('<FONT COLOR="#FF0000">Recv unexpect packets</FONT><BR>');

			vLogHTML('<FONT COLOR="#FF0000">wait RETRANS_TIMER * MAX_MULTICAST_SOLICIT</FONT><BR>');
			vSleep($retrans_timer * $max_multicast_solicit);

			exit($V6evalTool::exitFail);
		}
	}

	return(0);
}

#
# MIP6_SendBackDstUnreach4LL()
#
################################################################

sub MIP6_SendBackDstUnreach4LL($) {
	my ($Link) = @_;

	my %ret = ();
	my $got_du = 0;
	my $count = 0;

	vClear($Link);

	vSend($Link, 'ereq_from_cn0_to_mn_linklocal');

	for(my $d = 0; $d < $vrecv_loop; $d ++) {
		my $recv = '';
		my $send = '';

		%ret = vRecv($Link, $vrecv_wait, 0, 0, sort(keys(%nd)),
			'destination_unreachable_linklocal', 'destination_unreachable_linklocal_hoplimit_m1');

		$count = $ret{'recvCount'};

		while(($recv, $send) = each(%nd)) {
			if($ret{'recvFrame'} eq $recv) {
				if($send ne 'ignore') {
					vSend($Link, $send);
				}

				$d --;
				$count --;
				last;
			}
		}

		if(($ret{'recvFrame'} eq 'destination_unreachable_linklocal') ||
		   ($ret{'recvFrame'} eq 'destination_unreachable_linklocal_hoplimit_m1')) {
			$got_du ++;
			$count --;
		}

		if($count) {
			vLogHTML('<FONT COLOR="#FF0000">Recv unexpect packets</FONT><BR>');
			exit($V6evalTool::exitFail);
		}

		if($got_du) {
			last;
		}
	}

	unless($got_du) {
		return(-1);
	}

	for(my $d = 0; $d < $vrecv_loop; $d ++) {
		my $recv = '';
		my $send = '';

		%ret = vRecv($Link, $vrecv_wait, 0, 0, sort(keys(%nd)));
		$count = $ret{'recvCount'};

		while(($recv, $send) = each(%nd)) {
			if($ret{'recvFrame'} eq $recv) {
				if($send ne 'ignore') {
					vSend($Link, $send);
				}

				$d --;
				$count --;
				last;
			}
		}

		if($count) {
			vLogHTML('<FONT COLOR="#FF0000">Recv unexpect packets</FONT><BR>');
			exit($V6evalTool::exitFail);
		}
	}

	return(0);
}

#
# MIP6_UpdateCoA()
#
################################################################
sub MIP6_UpdateCoA($$) {
	my ($file, $define) = @_;

	unless(defined(open(WORK, ">$file"))) {
		vLogHTML('<FONT COLOR="#FF0000">Can\'t update CoA</FONT><BR>');
		exit($V6evalTool::exitFatal);
	}

	print WORK "#define CAREOFADDR\t$define\n";

	close(WORK);

	vCPP('');

	return;
}

#
# MIP6_InvalidSequence()
#
################################################################

sub MIP6_InvalidSequence($$$$$$$) {
	my ($Link, $sn0, $sn1, $a, $h, $l, $lt) = @_;

	$pktdesc{'BA'} = '    Recv BA Status=135: NUT (Link0) -&gt; MN\'\' (LinkY) (global)';

	my %ret = ();

	my $cpp = '';

	if($sn0) {
		$cpp .= "-DSEQ_BA=$sn0 ";
	}

	if($sn1) {
		$cpp .= "-DSEQ_BU=$sn1 ";
	}

	if($a) {
		$cpp .= "-DACKNOWLEDGE=$a ";
	}

	if($h) {
		$cpp .= "-DHOMEREGISTRATION=$h ";
	}

	if($l) {
		$cpp .= "-DLINKLOCAL=$l ";
	}

	if($lt) {
		$cpp .= "-DLIFETIME=$lt ";
	}

	$cpp .= "-DSTATUS=135 ";

	vCPP($cpp);

	vClear($Link);
	vSend($Link, 'BU');

	for(my $d = 0; $d < $vrecv_loop; $d ++) {
		my $recv = '';
		my $send = '';

		%ret = vRecv($Link, $vrecv_wait, 0, 0, sort(keys(%nd)), 'BA');

		while(($recv, $send) = each(%nd)) {
			if($ret{'recvFrame'} eq $recv) {
				if($send ne 'ignore') {
					vSend($Link, $send);
				}

				$d --;
				last;
			}
		}

		if($ret{'recvFrame'} eq 'BA') {
			return(0);
		}
	}

	return(-1);
}

#
# MIP6_BU_PiggybackHome()
#
################################################################

sub MIP6_BU_PiggybackHome($$$$$$) {
	my ($Link, $sn, $a, $h, $l, $lt) = @_;

	my %ret = ();
	my $got_pp = 0;
	my $count = 0;

	$nd{'ns_from_nut_to_mn_multicast_global'}	= 'na_from_mn_to_nut_global';
	$nd{'ns_from_nut_to_mn_unicast_global'}		= 'na_from_mn_to_nut_global';
	$nd{'ns_from_nut_to_mn_unicast_sll_global'}	= 'na_from_mn_to_nut_global';

	my $cpp = '';

	if($sn) {
		$cpp .= "-DSEQ_BU=$sn ";
		$cpp .= "-DSEQ_BA=$sn ";
	}

	if($a) {
		$cpp .= "-DACKNOWLEDGE=$a ";
	}

	if($h) {
		$cpp .= "-DHOMEREGISTRATION=$h ";
	}

	if($l) {
		$cpp .= "-DLINKLOCAL=$l ";
	}

	if($lt) {
		$cpp .= "-DLIFETIME=$lt ";
	}

	vCPP($cpp);

	vClear($Link);
	vSend($Link, 'BU_Home_Piggyback');

	for(my $d = 0; $d < $vrecv_loop; $d ++) {
		my $recv = '';
		my $send = '';

		%ret = vRecv($Link, $vrecv_wait, 0, 0, sort(keys(%nd)), 'ParameterProblem_BU_Home_Piggyback');
		$count = $ret{'recvCount'};

		while(($recv, $send) = each(%nd)) {
			if($ret{'recvFrame'} eq $recv) {
				if($send ne 'ignore') {
					vSend($Link, $send);
				}

				$d --;
				$count --;
				last;
			}
		}

		if($ret{'recvFrame'} eq 'ParameterProblem_BU_Home_Piggyback') {
			$got_pp ++;
			$count --;
		}

		if($count) {
			vLogHTML('<FONT COLOR="#FF0000">Recv unexpect packets</FONT><BR>');
			exit($V6evalTool::exitFail);
		}

		if($got_pp) {
			last;
		}
	}

	unless($got_pp) {
		return(-1);
	}

	for(my $d = 0; $d < $vrecv_loop; $d ++) {
		my $recv = '';
		my $send = '';

		%ret = vRecv($Link, $vrecv_wait, 0, 0, sort(keys(%nd)));
		$count = $ret{'recvCount'};

		while(($recv, $send) = each(%nd)) {
			if($ret{'recvFrame'} eq $recv) {
				if($send ne 'ignore') {
					vSend($Link, $send);
				}

				$d --;
				$count --;
				last;
			}
		}

		if($count) {
			vLogHTML('<FONT COLOR="#FF0000">Recv unexpect packets</FONT><BR>');
			exit($V6evalTool::exitFail);
		}
	}

	return(0);
}

#
# MIP6_Sleep()
#
# TODO:
#    It is too long time for waiting.
#    BCE may expire.
#
#    It needs to separate each proxy ND tests.
#    Is it a better way to solve this?
#
################################################################

sub MIP6_Sleep() {
	vLogHTML('<FONT COLOR="#FF0000">wait REACHABLE_TIME * MAX_RANDOM_FACTOR</FONT><BR>');
	vSleep($reachable_time * $max_random_factor);

#	vLogHTML('<FONT COLOR="#FF0000">wait DELAY_FIRST_PROBE_TIME</FONT><BR>');
#	vSleep($delay_first_probe_time);

#	vLogHTML('<FONT COLOR="#FF0000">wait RETRANS_TIMER * MAX_UNICAST_SOLICIT</FONT><BR>');
#	vSleep($retrans_timer * $max_unicast_solicit);

	return;
}

sub MIP6_Get_Addr($$$) {
	my ($Link, $mobile_node, $home_agent) = @_;

	vLogHTML('<FONT SIZE="4"><U><B>Calculate MN and HA address</B></U></FONT><BR>');
	vClear($Link);

	my %ret = vSend($Link, 'dummy_for_getaddr');

	unless(defined($ret{'Frame_Ether.Packet_IPv6.Hdr_IPv6.SourceAddress'})) {
		vLogHTML('<FONT COLOR="#FF0000">shuldn\'t reach here</FONT><BR>');
		exit($V6evalTool::exitFatal);
	}

	unless(defined($ret{'Frame_Ether.Packet_IPv6.Hdr_IPv6.DestinationAddress'})) {
		vLogHTML('<FONT COLOR="#FF0000">shuldn\'t reach here</FONT><BR>');
		exit($V6evalTool::exitFatal);
	}

	$$mobile_node	= $ret{'Frame_Ether.Packet_IPv6.Hdr_IPv6.SourceAddress'};
	$$home_agent	= $ret{'Frame_Ether.Packet_IPv6.Hdr_IPv6.DestinationAddress'};

	return(0);
}
