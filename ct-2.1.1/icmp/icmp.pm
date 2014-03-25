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
# $TAHI: ct/icmp/icmp.pm,v 1.7 2003/03/26 07:47:34 masaxmasa Exp $
#-----------------------------------------------------------------

package icmp;

use Exporter;
@ISA = qw(Exporter);
@EXPORT = qw(
		mkNCE_Link
		mkNCE_Global
		sendRA
		createIdDef
		checkNUT
	    );

use V6evalTool;

BEGIN { }
END { }

$type = $V6evalTool::NutDef{Type};

#-----------------------------------------------------------------
# node constants
#-----------------------------------------------------------------
$MAX_MULTICAST_SOLICIT = 3;		# times
$MAX_ANYCAST_DELAY_TIME = 1;		# sec.

$wait_address_resolution = $MAX_MULTICAST_SOLICIT * 3 + 2;	# margin: 2sec.


#-----------------------------------------------------------------
# make Neighbor Cache Entry
# In NUT,
#   make TN's link local address	 
#-----------------------------------------------------------------
sub mkNCE_Link (;$) {
	my ($IF) = @_;
	$IF = Link0 if (!$IF) ;

	%main::pktdesc = (
	    ns_local			=> 'Receive Neighbor Solicitation',
	    ns_local_sll		=> 'Receive Neighbor Solicitation',
	    na_local			=> 'Send Neighbor Advertisement',
	    echo_request_link_local	=> 'Send Echo Request (Link-local address)',
	    echo_reply_link_local	=> 'Receive Echo Reply (Link-local address)',
	);
        
	vSend($IF, echo_request_link_local);

	%ret = vRecv($IF, 5, 0, 0, echo_reply_link_local,
		     ns_local, ns_local_sll);

	if ($ret{status} != 0) {
		vLog("TN can not receive Echo Reply or NS from NUT");
	}
	elsif ($ret{recvFrame} eq 'echo_reply_link_local') {
		return $V6evalTool::exitPass;
	}
	elsif ($ret{recvFrame} eq 'ns_local' ||
	       $ret{recvFrame} eq 'ns_local_sll') {
		vSend($IF, na_local);

		%ret = vRecv($IF, 5, 0, 0, echo_reply_link_local);

		if ($ret{status} != 0) {
			vLog("TN can not receive Echo Reply from NUT");
		}
		elsif ($ret{recvFrame} eq 'echo_reply_link_local') {
			return($V6evalTool::exitPass);
		}
		else {
			vLog("TN received an expected packet from NUT");
		};
	};

	return($V6evalTool::exitFail);
}


#-----------------------------------------------------------------
# make Neighbor Cache Entry
# In NUT,
#   make TN's global local address	 
#-----------------------------------------------------------------
sub mkNCE_Global (;$) {
	my ($IF) = @_;
	$IF = Link0 if (!$IF) ;
        
	%main::pktdesc = (
	    ns_global			=> 'Receive Neighbor Solicitation',
	    ns_global_sll		=> 'Receive Neighbor Solicitation',
	    na_global			=> 'Send Neighbor Advertisement',
	    ns_global_from_local	=> 'Receive Neighbor Solicitation',
	    ns_global_sll_from_local	=> 'Receive Neighbor Solicitation',
	    na_global_to_local		=> 'Send Neighbor Advertisement',
	    echo_request_global		=> 'Send Echo Request (Global address)',
	    echo_reply_global		=> 'Receive Echo Reply (Global address)',
	);

	vSend($IF, echo_request_global);

	%ret = vRecv($IF, 5, 0, 0, echo_reply_global, ns_global, ns_global_sll);

	if ($ret{status} != 0) {
		vLog("TN can not receive Echo Reply or NS from NUT");
	}
	elsif ($ret{recvFrame} eq 'echo_reply_global') {
		return $V6evalTool::exitPass;
	}
	elsif ($ret{recvFrame} eq 'ns_global' ||
	       $ret{recvFrame} eq 'ns_global_sll' ||
	       $ret{recvFrame} eq 'ns_global_from_local' ||
	       $ret{recvFrame} eq 'ns_global_sll_from_local') {

		if ($ret{recvFrame} eq 'ns_global' ||
		    $ret{recvFrame} eq 'ns_global_sll') {
			vSend($IF, na_global);
		}
		else {
			vSend($IF, na_global_to_local);
		};

		%ret = vRecv($IF, 5, 0, 0, echo_reply_global);

		if ($ret{status}) {
			vLog("TN can not receive Echo Reply from NUT");
		}
		elsif ($ret{recvFrame} eq 'echo_reply_global') {
			return($V6evalTool::exitPass);
		}
		else {
			vLog("TN received an expected packet from NUT");
		};
	};

	return($V6evalTool::exitFail);
}


#-----------------------------------------------------------------
# send RA
#-----------------------------------------------------------------
sub sendRA (;$) {
	my($IF) = @_;

	$IF = "Link0" if (!$IF) ;

	$main::pktdesc{ra} = 'Send Router Advertisement';

	if($type eq host) {
		vSend($IF, ra);
		#-- this part is for ignoring NS Packet --
		vSleep(5);
		vClear($IF);
	};
}


#-----------------------------------------------------------------
# createIdDef() - create unique Fragment ID and write to ./ID.def
#-----------------------------------------------------------------
sub createIdDef() {
	sleep 1;				# make time unique
	$id = time & 0x00000fff;		# use lower 12 bit
	open(OUT, ">./ID.def") || return 1;

	# Fragment ID (32bit)

	printf OUT "#define FRAG_ID     0x0%07x\n", $id;
	printf OUT "#define FRAG_ID_T   0xf%07x\n", $id;

	# Echo Request ID (16bit)

	printf OUT "#define REQ_ID     0x0%03x\n", $id;
	printf OUT "#define REQ_ID_T   0xf%03x\n", $id;

	# Echo Request Sequence No. (16bit)

	printf OUT "#define SEQ_NO     0x00\n", $id;
	printf OUT "#define SEQ_NO_T   0x0f\n", $id;

	close(OUT);
	return(0);
}

#-----------------------------------------------------------------
# checkNUT() - check NUT type, host or router
#-----------------------------------------------------------------
sub checkNUT($) {
	my ($ntype) = @_;

	if ($ntype eq 'hostrouter') {
		return;
	}
	elsif ($ntype eq 'host' && $type eq 'host') {
		return;
	}
	elsif ($ntype eq 'router' && $type eq 'router') {
		return;
	}
	elsif ($ntype eq 'host' && $type eq 'router') {
		vLogHTML("This test is for a host implimentation.");
		exit($V6evalTool::exitHostOnly);
	}
	elsif ($ntype eq 'router' && $type eq 'host') {
		vLogHTML("This test is for a router implimentation.");
		exit($V6evalTool::exitRouterOnly);
	}
	else {
		vLogHTML("Unknown NUT type $type - check nut.def<br>");
		exit($V6evalTool::exitFatal);
	}
}
