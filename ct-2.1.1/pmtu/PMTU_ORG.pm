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
# $TAHI: ct/pmtu/PMTU_ORG.pm,v 1.1 2003/03/26 10:32:32 miyata Exp $

########################################################################
package PMTU_ORG;

use Exporter;
@ISA = qw(Exporter);
@EXPORT = qw(sendFragmentEchoRequest
	     rebootNUT
	     initNUT
	     sendPacketWithMTU
	     checkSizeOfPathMTU
	     pmtuReboot
	     sendPing
	     makeNCE
	     makeNCE_Global
	     sendNA
	     checkNUT
	     pmtuClearNCE
	     pmtuClearGlobalNCE
             );

use V6evalTool;

BEGIN { }
END { }

$ON=1;
$OFF=0;
$remote_debug="";
$TN_GlobalAddr="3ffe:501:ffff:100::1";
$OFFLink_prefix="3ffe:501:ffff:109::";
$OFFLink_prefixlen="64";

$type=$V6evalTool::NutDef{Type};

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


#
#
#
sub rebootNUT() {
    vLogHTML("Reboot the NUT.");
    $ret=vRemote("reboot.rmt","");
    if ($ret > 0) {
	vLog("vRemote reboot.rmt exit $ret");
	exit $V6evalTool::exitFatal;
    }
}

#
# send a few Fragmented Packets
#

sub sendFragmentEchoRequest ($$$) { 
    my (
	$IF,			#interface
	$Frame_name,		#any Frame
	$Frame_log,		#log statement for any Frame
	)=@_;
    my ( $temp_frame, $temp_frame_log);

    
    while (@$Frame_name) {
	$temp_frame=shift(@$Frame_name);
	$temp_frame_log=shift(@$Frame_log);

	vSend($IF,$temp_frame);
    }
    return $V6evalTool::exitPass;
}

#
# send NA
#

sub sendNA (;$) {
    my ( $IF ) =@_;
    $IF=Link0 if (! $IF ) ;

    if ($type eq host) {
	vSend($IF, na);
    }else {
	vSend($IF, na_router);
    }

}

#
# send NA
#

sub sendNA_srcGlobal (;$) {
    my ( $IF ) =@_;
    $IF=Link0 if (! $IF ) ;

    if ($type eq host) {
	vSend($IF, na_srcGlobal);
    }else {
	vSend($IF, na_srcGlobal_router);
    }

}
#
# send NA for Global Address
#

sub sendNA_Global (;$) {
    my ( $IF ) =@_;
    $IF=Link0 if (! $IF ) ;

    if ($type eq host) {
	vSend($IF, na_global);
    }else {
	vSend($IF, na_router_global);
    }

}
#
# send NA for Global Address
#

sub sendNA_srcLocal_Global (;$) {
    my ( $IF ) =@_;
    $IF=Link0 if (! $IF ) ;

    if ($type eq host) {
	vSend($IF, na_srcLocal_global);
    }else {
	vSend($IF, na_srcLocal_router_global);
    }

}
#
# Initialize NUT
#

sub initNUT (;$) {
    my ( $IF ) =@_;
    $IF=Link0 if (! $IF ) ;
    my ($MACAddr, $LLAddr, $Interface);

    $Interface=$V6evalTool::NutDef{Link0_device};
    $TnMACAddr=$V6evalTool::TnDef{Link0_addr};
    $LLAddr=vMAC2LLAddr($TnMACAddr);
    
    vLog("START : initialized NUT for Path MTU test");

    vClear($IF);

    if($type eq router ) {
	vRemote("route.rmt", "cmd=add prefix=default " . 
		"gateway=$LLAddr ". "if=$Interface") &&
		    return $V6evalTool::exitFatal;
    }

    vSend($IF, EchoRequest);

    %ret=vRecv($IF,5,0,0, EchoReply,ns,ns_srcGlobal,);

    if( $ret{recvFrame} eq 'ns' || $ret{recvFrame} eq 'ns_srcGlobal') { 
	if( $ret{recvFrame} eq 'ns' ) {
	    sendNA();
	}elsif( $ret{recvFrame} eq 'ns_srcGlobal' ) {
	    sendNA_srcGlobal();
	}

	%ret=vRecv($IF, 5,0,0,EchoReply);
	if( $ret{status} != 0) {
	    vLog("TN(Router) can not receive Echo Reply from NUT");
	    vClear($IF);
	}else {
	    vLog("TN(Router) receives Echo Reply from NUT");
	}
    }elsif( $ret{recvFrame} eq 'EchoReply') {
	vLog("TN(Router) receives Echo Reply from NUT");
    }else {
	vLog("NUT can not any packets");
	return $V6evalTool::exitFail;
    }

    if($type eq host ) {
	vSend($IF, ra);
	
	#-- this part is for ignoreing NS Packet --
	vLog("Ignore DAD NS");
	vRecv($IF,5,0,0);
    }elsif($type eq router) {
	$ret=makeNCE_Global();
	if( $ret !=0) {
	    vLog("NUT can not make NUT's GlobalAddress NCE!!");
	    return $V6evalTool::exitFail;
	}

    }

    vLog("END : initialized NUT for Path MTU test");
    return $V6evalTool::exitPass;
}


#
# checkSizeOfPathMTU
#

sub checkSizeOfPathMTU ($$;$) {
    my (
	$subName,		#Name for makeing Packet Name
	$reference_packet_log,
	$IF
	)=@_;

    $IF=Link0 if (! $IF);
    vLog("Start :  check size of Path MTU in NUT");

    #
    # frame name for smaller 
    #
    $smaller_1st="frag_smaller_1st_" . $subName;
    $smaller_2nd="frag_smaller_2nd_" . $subName;
    $smaller_reply_1st="receive_smaller_reply_" . $subName;
    # for log 	
    $smaller_log=$reference_packet_log->{smaller_send_log};

    
    #
    # frame name for even
    #
    $even_1st="frag_even_1st_" . $subName;
    $even_2nd="frag_even_2nd_" . $subName;
    $even_reply_1st="receive_even_reply_" . $subName;
    # for log 	
    $even_log=$reference_packet_log->{even_send_log};
    
    #
    # frame name for bigger
    #
    $bigger_1st="frag_bigger_1st_" . $subName;
    $bigger_2nd="frag_bigger_2nd_" . $subName;
    $bigger_reply_1st="frag_bigger_reply_1st_" . $subName;
    $bigger_reply_2nd="frag_bigger_reply_2nd_" . $subName;
    # for log 	
    $bigger_log=$reference_packet_log->{bigger_send_log};



    #-- TN send two fragmented packets  
    # Orignal Packet size is cheking MTU - 1
    #

    sendFragmentEchoRequest($IF,
			    [$smaller_1st,$smaller_2nd],
			    $smaller_log
			    );

    %ret=vRecv($IF,5,0,0,$smaller_reply_1st);
    if( $ret{status} !=0) {
	vLog("Can not receive smaller Echo Reply !!");
	return $V6evalTool::exitFail;
    }
    vLog("Send Fragmented smaller Echo Request ");

    #-- TN send two packets  
    # Orignal Packet size is cheking MTU + 0
    #
    
    sendFragmentEchoRequest($IF,
			    [$even_1st,$even_2nd],
			    $even_log
			    );

    %ret=vRecv($IF,5,0,0,$even_reply_1st);
    if( $ret{status} !=0) {
	vLog("Can not receive even Echo Reply !!");
	return $V6evalTool::exitFail;
    }
    vLog("Send Fragmented even Echo Request ");

    #-- TN send two packets  
    # Orignal Packet size is cheking MTU + 1
    #
    
    sendFragmentEchoRequest($IF,
			    [$bigger_1st,$bigger_2nd],
			    $bigger_log
			    );

    %ret=vRecv($IF,5,0,1,$bigger_reply_1st,$bigger_reply_2nd);
    if( $ret{status} !=0) {
	vLog("Can not receive bigger Echo Reply !!");
	return $V6evalTool::exitFail;
    }

    if($ret{recvFrame} eq $bigger_reply_1st) {
	%ret=vRecv($IF,5,0,1,$bigger_reply_2nd);
	if( $ret{status} !=0) {
	    vLog("Can not receive bigger Echo Reply !!");
	    return $V6evalTool::exitFail;
	}
    }elsif($ret{recvFrame} eq $bigger_reply_2nd) {
	%ret=vRecv($IF,5,0,1,$bigger_reply_1st);
	if( $ret{status} !=0) {
	    vLog("Can not receive bigger Echo Reply !!");
	    return $V6evalTool::exitFail;
	}
    }

    vLog("Send Fragmented bigger Echo Request ");

    return $V6evalTool::exitPass;
}


#
# sendPacketWithMTU
#

$nosend=0;
$sendTooBig=1;
$sendRA=2;
$sendTooBigOnly=3;

sub sendPacketWithMTU ($$;$) {
    my (
	$subName,	    #Name for makeing Packet Name
	$sendTooBigorRA,
	$IF
	)=@_;

    $IF=Link0 if (! $IF);
    vLog("Start :  send Packet with MTU");

    my ($TooBigMesg,$EchoRequest,$EchoReply);

    # frame name for TooBigMessage
    $TooBigMesg="icmp6_TooBigMesg_" . $subName;
    $EchoRequest="EchoRequest_" . $subName;
    $EchoReply="EchoReply_" . $subName;

    # frame name for RA
    $RA="RA_" . $subName;


    if($sendTooBigorRA == $sendTooBig) {
	vSend($IF,$EchoRequest);
	
	%ret=vRecv($IF,5,0,0,$EchoReply);
	if( $ret{status} != 0) {
	    vLog("Can not receive Echo Reply from NUT!!");
	    return $V6evalTool::exitFail;
	}

	vSend($IF,$TooBigMesg);
    }
    elsif($sendTooBigorRA == $sendRA) {
	vSend($IF,$RA);
    }
    elsif($sendTooBigorRA == $sendTooBigOnly) {
	vSend($IF,$TooBigMesg);
    }

    return $V6evalTool::exitPass;
}


#
# make Neighber Cache Entry
#

sub makeNCE (;$) {
    my ( $IF ) =@_;
    $IF=Link0 if (! $IF ) ;
    
    vLog("Start: make NCE ");

    vClear($IF);

    vSend($IF, EchoRequest);

    %ret=vRecv($IF,5,0,0, EchoReply,ns,ns_srcGlobal);
    if( $ret{status} !=0) {
	vLog("TN(Router) can not receive Echo Reply or ns from NUT");
	vLog(vErrmsg(%ret));
	return $V6evalTool::exitFail;
    }
    if($ret{recvFrame} eq 'ns' || $ret{recvFrame} eq 'ns_srcGlobal') {
	if( $ret{recvFrame} eq 'ns') {
	    sendNA();
	}elsif( $ret{recvFrame} eq 'ns_srcGlobal') {
	    sendNA_srcGlobal();
	}	
	%ret=vRecv($IF, 5,0,0,EchoReply);
	if( $ret{status} != 0) {
	    vLog("TN(Router) can not receive Echo Reply from NUT");
	    vClear($IF);
	}else {
	    vLog("TN(Router) receives Echo Reply from NUT");
	}
    }elsif( $ret{recvFrame} eq 'EchoReply') {
	vLog("TN(Router) receives Echo Reply from NUT");
    }

    if($type eq host ) {
	vSend($IF, ra);
	#-- this part is for ignoreing NS Packet --
	vLog("Ignore DAD NS");
	vRecv($IF,5,0,0);
    }elsif($type eq router) {
	$ret=makeNCE_Global();
	if( $ret !=0) {
	    vLog("NUT can not make NUT's GlobalAddress NCE!!");
	    return $V6evalTool::exitFail;
	}

    }

    vLog("End: make NCE ");
    return $V6evalTool::exitPass;
}


#
# make Neighber Cache Entry for Global Address
#

sub makeNCE_Global (;$) {
    my ( $IF ) =@_;
    $IF=Link0 if (! $IF ) ;
    
    vLog("Start: make GlobalNCE ");

    vClear($IF);
    
    vSend($IF, EchoRequest_tn2nut_global);
    
    %ret=vRecv($IF,5,0,0, EchoReply_nut2tn_global,ns_global,
	       ns_srcGlobal_global);
    if( $ret{status} !=0) {
	vLog("TN(Router) can not receive Echo Reply or ns from NUT");
	vLog(vErrmsg(%ret));
	return $V6evalTool::exitFail;
    }
    if( $ret{recvFrame} eq 'ns_global' ||
       $ret{recvFrame} eq 'ns_srcGlobal_global') {
	if( $ret{recvFrame} eq 'ns_global') {
	    sendNA_srcLocal_Global();
	}elsif( $ret{recvFrame} eq 'ns_srcGlobal_global') {
	    sendNA_Global();
	}
	
	%ret=vRecv($IF, 5,0,0,EchoReply_nut2tn_global);
	if( $ret{status} != 0) {
	    vLog("TN(Router) can not receive Echo Reply from NUT");
	    vClear($IF);
	}else {
	    vLog("TN(Router) receives Echo Reply from NUT");
	}
    }elsif( $ret{recvFrame} eq 'EchoReply_nut2tn_global') {
	vLog("TN(Router) receives Echo Reply from NUT");
	sendNA_Global();
    }

    vLog("End : make GlobalNCE ");
    return $V6evalTool::exitPass;
}

sub pmtuReboot() {
    vRemote("reboot.rmt",$remote_debug) && return $V6evalTool::exitFatal;
    vLog("Target: Reboot");
    return $V6evalTool::exitPass;
}

sub pmtuClearNCE(;$)
{
    my($IF)=@_;
    $IF=Link0 if (! $IF ) ;
    my(%ret, $i);

    vClear($IF);

    vCapture($IF);
    %ret=vRecv($IF, $wait_ns, 0, 1,
               pmtu_multicast_ns,
               pmtu_unicast_ns,
               pmtu_unicast_ns_sll,
               pmtu_unicast_ns_to_z,
               pmtu_unicast_ns_sll_to_z,
               );
    goto found if $ret{status} == 0;

    for($i=0; $i<2; $i++) {

        vSend($IF, pmtu_echo_request);

        %ret=vRecv($IF, $wait_ns, 0, 1,
                   pmtu_echo_reply,
                   pmtu_echo_reply_to_z2,
                   pmtu_multicast_ns,
                   );
        goto found
	    if $ret{status} == 0 &&$ret{recvFrame} eq pmtu_multicast_ns;
        goto error if $ret{status} != 0;

        %ret=vRecv($IF, $wait_delay, 0, 1,
                   pmtu_unicast_ns,
                   pmtu_unicast_ns_sll,
                   pmtu_unicast_ns_to_z,
                   pmtu_unicast_ns_sll_to_z,
                   );
        goto found if $ret{status} == 0;

        if($i == 0) {
            vSleep($wait_reachable);
        }
    }

  error:
    vLog(vErrmsg(%ret));
    return 1;

  found:
    vLog("Clear TN's link-local Address NCE");
    readout($IF, $wait_ns);
    return 0;
}

sub pmtuClearGlobalNCE(;$)
{
    my($IF)=@_;
    $IF=Link0 if (! $IF ) ;
    my(%ret, $i);

    if($type ne router) {
	return V6evalTool::exitPass;
    }

    vClear($IF);

    vCapture($IF);
    %ret=vRecv($IF, $wait_ns, 0, 1,
               pmtu_multicast_global_ns,
               pmtu_unicast_global_ns,
               pmtu_unicast_global_ns_sll,
               pmtu_unicast_global_ns_to_z,
               pmtu_unicast_global_ns_sll_to_z,
               );
    goto found if $ret{status} == 0;

    for($i=0; $i<2; $i++) {

        vSend($IF, pmtu_global_echo_request);

        %ret=vRecv($IF, $wait_ns, 0, 1,
                   pmtu_global_echo_reply,
                   pmtu_global_echo_reply_to_z2,
                   pmtu_multicast_global_ns,
                   );
        goto found
	    if $ret{status} == 0 &&
		$ret{recvFrame} eq pmtu_multicast_global_ns;
        goto error if $ret{status} != 0;

        %ret=vRecv($IF, $wait_delay, 0, 1,
                   pmtu_unicast_global_ns,
                   pmtu_unicast_global_ns_sll,
                   pmtu_unicast_global_ns_to_z,
                   pmtu_unicast_global_ns_sll_to_z,
                   );
        goto found if $ret{status} == 0;

        if($i == 0) {
            vSleep($wait_reachable);
        }
    }

  error:
    vLog(vErrmsg(%ret));
    return 1;

  found:
    vLog("Clear TN's Global Address NCE");
    readout($IF, $wait_ns);
    return 0;
}

sub readout($$)
{
    my($IF, $timeout) = @_;
    $IF=Link0 if (! $IF ) ;
    my(%ret);
    %ret=vRecv($IF, $timeout, 0, null);
    $ret{recvCount};
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


1;		# return value

########################################################################
__END__

=head1 NAME

	PMTU.pm - functions for Path MTU test

=head1 DESCRIPTION

	sub routine for Path MTU test

=cut
