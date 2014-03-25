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
# $TAHI: ct/icmp/Pkt_Too_Big.pm,v 1.1 2003/03/26 07:47:32 masaxmasa Exp $
#----------------------------------------------------------------

package Pkt_Too_Big;

use Exporter;
@ISA = qw(Exporter);
@EXPORT = qw(
		set_routes
		delete_routes
		set_mtu
		mkNCE_Link1
		check_fwd
             );

use V6evalTool;

BEGIN { }
END { }

$remote_debug = "";
$dst = "3ffe:501:ffff:108::1";

#----------------------------------------------------------------
# set routes to NUT
#----------------------------------------------------------------
sub set_routes (;$) {
	$IF = Link0 if ( !$IF );

	my ($lladdr1, $interface1);

	# NUT Link1 interface
	$interface1 = $V6evalTool::NutDef{Link1_device};

	# TN Link1 Link Local Address
	$lladdr1 = vMAC2LLAddr($V6evalTool::TnDef{Link1_addr});

	vClear($IF);

	vRemote("route.rmt", "cmd=add prefix=$dst gateway=$lladdr1 " .
		"if=$interface1") &&
			return($V6evalTool::exitFatal);

	return($V6evalTool::exitPass);
}

#----------------------------------------------------------------
# delete routes to NUT
#----------------------------------------------------------------
sub delete_routes (;$) {
	$IF = Link0 if ( !$IF );

	my ($lladdr1, $interface1);

	# NUT Link1 interface
	$interface1 = $V6evalTool::NutDef{Link1_device};

	# TN Link1 Link Local Address
	$lladdr1 = vMAC2LLAddr($V6evalTool::TnDef{Link1_addr});

	vClear($IF);

	vRemote("route.rmt", "cmd=delete prefix=$dst gateway=$lladdr1 " .
		"if=$interface1") &&
			return($V6evalTool::exitFatal);

	return($V6evalTool::exitPass);
}

#----------------------------------------------------------------
# set routes to NUT
#----------------------------------------------------------------
sub set_mtu ($$) {
	my ($IF, $mtu) = @_;
	my $interface = $IF . "_device";

	vLog("set link mtu of $IF interface to $mtu.");
	vRemote("mtuconfig.rmt", "if=$V6evalTool::NutDef{$interface} mtu=$mtu") &&
		return($V6evalTool::exitFatal);
}

#----------------------------------------------------------------
# make Neighbor Cache Entry Link1
#----------------------------------------------------------------
sub mkNCE_Link1 () {
	my $IF = "Link1";
	
	%main::pktdesc = (
		ns_local_link1			=> 'Receive Neighbor Solicitation (Link1)',
		ns_local_sll_link1		=> 'Receive Neighbor Solicitation (Link1)',
		na_local_link1			=> 'Send Neighbor Advertisement (Link1)',
		echo_request_local_link1	=> 'Send Echo Request (Link1 Link-local address)',
		echo_reply_local_link1		=> 'Receive Echo Reply (Link1 Link-local address)'
	);

	vClear($IF);

	vSend($IF, echo_request_local_link1);

	%ret = vRecv($IF, 5, 0, 0, echo_reply_local_link1, ns_local_link1,
		     ns_local_sll_link1);

	if ($ret{status} != 0) {
		vLog("TN can not receive Echo Reply or ns from NUT");
		return($V6evalTool::exitFail);
	}

	if ($ret{recvFrame} eq 'ns_local_link1' ||
	    $ret{recvFrame} eq 'ns_local_sll_link1') {

		vSend($IF, na_local_link1);

		%ret = vRecv($IF, 5, 0, 0, echo_reply_local_link1);

		if ($ret{status} != 0) {
			vLog("TN can not receive Echo Reply from NUT");
			return($V6evalTool::exitFail);
		}
		else {
			vLog("TN receives Echo Reply from NUT");
		};
	}
	elsif ($ret{recvFrame} eq 'echo_reply_local_link1') {
		vLog("TN receives Echo Reply from NUT");
	};

	return($V6evalTool::exitPass);
}

#----------------------------------------------------------------
# check forwarding
#----------------------------------------------------------------
sub check_fwd() {
	my ($IF0, $IF1);

	$IF0 = "Link0";
	$IF1 = "Link1";

	%main::pktdesc = (
		ns_local_link1		=> 'Receive Neighbor Solicitation (Link1)',
		ns_local_sll_link1	=> 'Receive Neighbor Solicitation (Link1)',
		na_local_link1		=> 'Send Neighbor Advertisement (Link1)',
		ns_local		=> 'Receive Neighbor Solicitation (Link0)',
		ns_local_sll		=> 'Receive Neighbor Solicitation (Link0)',
		na_local		=> 'Send Neighbor Advertisement (Link0)',
		ns_global		=> 'Receive Neighbor Solicitation (Link0)',
		ns_global_sll		=> 'Receive Neighbor Solicitation (Link0)',
		na_global		=> 'Send Neighbor Advertisement (Link0)',
		echo_request_fwd_link0	=> 'Send Echo Request from TN (Link0)',
		echo_request_fwd_link1	=> 'Receive Echo Request (Link1)',
		echo_reply_fwd_link1	=> 'Send Echo Reply from beyond a router (Link1)',
		echo_reply_fwd_link0	=> 'Receive Echo Reply (Link0)'
	);

	vClear($IF0);
	vClear($IF1);

	#---------------------------------
	# sending echo request from link0
	#---------------------------------
	vSend($IF0, echo_request_fwd_link0);

	%ret = vRecv($IF1, 5, 0, 0, echo_request_fwd_link1, ns_local_link1,
		     ns_local_sll_link1);

	if ($ret{status} != 0) {
		vLog("TN can not receive any packets.");
		return($V6evalTool::exitFail);
	}

	if ($ret{recvFrame} eq 'ns_local_link1' ||
	    $ret{recvFrame} eq 'ns_local_sll_link1') {

		vSend($IF1, na_local_link1);
		%ret = vRecv($IF1, 5, 0, 0, echo_request_fwd_link1);

		if ($ret{status} != 0) {
			vLog("TN can not receive Echo Request");
			return($V6evalTool::exitFail);
		}
		else {
			vLog("TN receives Echo Request");
		};
	}
	elsif ($ret{recvFrame} eq 'echo_request_fwd_link1') {
		vLogHTML("TN receives Echo Request");
	};

	vClear($IF0);
	vClear($IF1);

	#---------------------------------
	# sending echo reply from link1
	#---------------------------------
	vSend($IF1, echo_reply_fwd_link1);

again:
	%ret = vRecv($IF0, 5, 0, 0, echo_reply_fwd_link0, ns_global,
		     ns_global_sll, ns_local, ns_local_sll);

	if ($ret{status} != 0) {
		vLog("TN can not receive any packets.");
		return($V6evalTool::exitFail);
	}

	if ($ret{recvFrame} eq 'ns_global' ||
	    $ret{recvFrame} eq 'ns_global_sll' ||
	    $ret{recvFrame} eq 'ns_local' ||
	    $ret{recvFrame} eq 'ns_local_sll') {

		if ($ret{recvFrame} eq 'ns_global' ||
		    $ret{recvFrame} eq 'ns_global_sll') {
			vSend($IF0, na_global);
		}
		else {
			vSend($IF0, na_local);
		}

		goto again;
	}
	elsif ($ret{recvFrame} eq 'echo_reply_fwd_link0') {
		vLogHTML("TN receives Echo Reply");
	};

	return($V6evalTool::exitPass);
}

1;		# return value

########################################################################
__END__
