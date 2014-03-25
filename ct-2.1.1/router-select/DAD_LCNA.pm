#!/usr/bin/perl
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
# $TAHI: ct/router-select/DAD_LCNA.pm,v 1.4 2003/04/22 04:26:44 akisada Exp $
# $TINY: DAD_LCNA.pm,v 1.11 2002/03/05 03:04:54 masaxmasa Exp $
# 
# Perl Module for IPv6 Stateless Address Autoconfiguration Conformance Test
# 
######################################################################
package DAD_LCNA;

use Exporter;
@ISA = qw(Exporter);
@EXPORT = qw(
	seqOK 
	seqNG 
	seqERROR 
	seqExitFATAL 
	seqExitNS 
	seqExitWARN 
	seqWarnCheck 
	seqTermination 
	seqSendWait 
	seqCheckNUTAddrConfigured 
	seqCheckNUTAddrConfiguredDAD
	seqCheckNUTAddrConfiguredGA
	seqCheckNUTAddrConfiguredGADAD
);

use V6evalTool;
use Carp;


BEGIN { }
END { }

#----- constant values
# nothing

#----- test condition
$debug = 0;                #  debug level
$wait_dadna = 5;           #   5[sec]? time between NS and DAD NA
$wait_solna = 5;           #   5[sec]? time between NS and solicited NA
$wait_rs    = 5;           #   5[sec]? time since sending RA to DADNS for Global
$wait_loginprompt = 20;    #  20[sec]  for kame to login prompt available since DAD finish
$wait_shutdown = 10;       #  10[sec]  for kame to shutdown when reboot
$wait_addrconfready = 10;  #  10[sec]? for kame to be ready since beggining of DAD
$wait_dadns{"reboot"} = 130; # 120[sec]  for kame to remote reboot
#$wait_dadns{"reboot"} = 180; # 120[sec]  for kame to remote reboot
#$wait_dadns{"boot"} = 120; # 120[sec]  for kame to remote reboot
$wait_dadns{"manual"} =30; #  30[sec]  for address config by remote ifconfig
$wait_dadns{"manual_async"} =30; #  30[sec]  for address config by remote ifconfig
$wait_dadns{"ra"}     =5;  #   5[sec]  for address config by RA
$howto_addrconf = "boot";  # How to configure address of NUT? boot,ra,manual
$DupAddrDetectTransmits=1; # NUT Variable: DupAddrDetectTransmits
$DADTransmitsGA= "ANY";    # NUT Variable: DupAddrDetectTransmits for GA and SLA
$RetransTimerSec = 1;      # NUT Variable: RetransTimer/1000 [sec]
$addr_cast_type = "unicast"; # tentative address is "unicast" or "anycast" or "multicast"



#==============================================
# check if NUT's address is configured
#==============================================
sub seqCheckNUTAddrConfiguredDAD($) {
    my ($IF) = @_;
    my (%retsw1, $dad_ns, $dad_na);

    vLog("Check if NUT's address is configured");
    %retsw1 = seqSendWait($IF,
	"DAD NS from TN to NUT:", DADNS_from_TN_SameTgt,
	"DAD NA from NUT:", $wait_dadna,0, 
	DADNA_from_NUT, DADNA_from_NUT_woTLL);

    if ($retsw1{status}==0) {
	vLog("NUT assigned the address to the interface.");
	if ($retsw1{recvFrame} ne DADNA_from_NUT) {
	    vLogHTML("<FONT COLOR=\"#FF0000\">TN received irregular DAD NA.</FONT>");
	    $iregdadna = 1;
	}
	return TRUE;
    }
    elsif($retsw1{status}==1) { #timeout
	vLog("NUT's address is not configured.");
	return FALSE;
    }
    else {
	seqERROR("seqCheckNUTAddrConfiguredDAD: Cannot reach here!"); #exit
    }

}
	
#==============================================
# check if NUT's address is configured
#==============================================
sub seqCheckNUTAddrConfigured($) {
    my ($IF) = @_;
    my (%retsw1, $dad_ns, $dad_na);

    vLog("Check if NUT's address is configured");
    %retsw1 = seqSendWait($IF,
		"NS from TN to NUT:", SOLNS_from_TN_SameTgt,
		"NA from NUT:", $wait_solna,0, NA_from_NUT, NA_from_NUT_woTLL);
    if ($retsw1{status}==0) {
	vLog("NUT assigned the address to the interface.");
	if ($retsw1{recvFrame} ne NA_from_NUT) {
	    vLogHTML("<FONT COLOR=\"#FF0000\">TN received irregular DAD NA.</FONT>");
	    $iregdadna = 1;
	}
	return TRUE;
    }
    elsif($retsw1{status}==1) { #timeout
	vLog("NUT's address is not configured.");
	return FALSE;
    }
    else {
	seqERROR("seqCheckNUTAddrConfigured: Cannot reach here!"); #exit
    }

}
	
#==============================================
# check if NUT's address is configured
#==============================================
sub seqCheckNUTAddrConfiguredGADAD($$@) {
    my ($IF,$Frame_Send,@Frame_Recv) = @_;
    my (%retsw1, $dad_ns, $dad_na);

    vLog("Check if NUT's address is configured");
    %retsw1 = seqSendWait($IF,
	"DAD NS from TN to NUT:", $Frame_Send,
	"DAD NA from NUT:", $wait_dadna,0, @Frame_Recv);
    if ($retsw1{status}==0) {
	vLog("NUT assigned the address to the interface.");
	return TRUE;
    }
    elsif($retsw1{status}==1) { #timeout
	vLog("NUT's address is not configured.");
	return FALSE;
    }
    else {
	seqERROR("seqCheckNUTAddrConfiguredGA: Cannot reach here!"); #exit
    }

}

#==============================================
# check if NUT's address is configured
#==============================================
sub seqCheckNUTAddrConfiguredGA($$@) {
    my ($IF,$Frame_Send,@Frame_Recv) = @_;
    my (%retsw1);

    vLog("Check if NUT's address is configured");
    %retsw1 = seqSendWait($IF,
	"NS from TN to NUT:", $Frame_Send,
	"NA from NUT:", $wait_solna,0, @Frame_Recv);
    if ($retsw1{status}==0) {
	vLog("NUT assigned the address to the interface.");
	return TRUE;
    }
    elsif($retsw1{status}==1) { #timeout
	vLog("NUT's address is not configured.");
	return FALSE;
    }
    else {
	seqERROR("seqCheckNUTAddrConfiguredGA: Cannot reach here!"); #exit
    }

}

#==============================================
# send a frame and wait frames
#==============================================
sub seqSendWait ($$$$$$@) {
    my ($IF,
	$msg_send,     # string, send frame description sample: "DAD NS from TN to NUT:"
	$frame_send,   # send framename in packet.def file
	$msg_wait,     # string, wait frame description sample: "DAD NS from NUT:"
	$timeout,      # int [sec], wait timeout for vRecv()
	$count,        # int, wait packet cout for vRecv()
	@frame_wait    # wait framenames in packet.def file
	) = @_;
    my (%ret, $frames_wait);

    vLog("Send $msg_send $frame_send");
    %ret=vSend($IF, $frame_send);
    seqERROR(vErrmsg(%ret)) if $ret{status} != 0 ;

    $frames_wait = join(',',@frame_wait);
    vLog("Wait $msg_wait $frames_wait");
    %ret=vRecv($IF,$timeout,$ret{sentTime1},$count, @frame_wait);
    vLog("Received packet count=$ret{recvCount}");
    if($ret{status}==0) {
	vLog("Received $msg_wait $ret{recvFrame}");
    }elsif($ret{status}==1) {
	vLog("Wait $msg_wait timeout");
    }
    return %ret;
    
}


#=================================================
# Test Termination
#=================================================
sub seqTermination() {
    &$main::term_handler if defined $main::term_handler;
}

#=================================================
# Fail Check before exit OK
#=================================================
sub seqWarnCheck() {
    my($wc);
    $wc = 0;
    if ($initfail == 1) {
	vLog("Note: There is a failure in initialization phase.");
	$initfail=0; $wc++;
    } elsif ($initfail > 1) {
	vLog("Note: There are $initfail failures in initialization phase.");
	$initfail=0;  $wc++;
    }
    if ($iregdadns > 0) {
	vLog("Note: There is a irregular DAD NS.");
	$iregdadns=0; $wc++;
    }	
    if ($iregdadna > 0) {
	vLog("Note: There is a irregular DAD NA.");
	$iregdadna=0; $wc++;
    }	

    if ($wc > 0) {
	return WARN;
    }else{
	return OK;
    }

}

#=================================================
# sequence exit OK
#=================================================
sub seqOK() {
    seqExitWARN() if seqWarnCheck() eq 'WARN';
    vLog(OK);
    seqTermination();
    vLog("*** EOT ***");
    exit $V6evalTool::exitPass;
}

#=================================================
# sequence exit NG
#=================================================
sub seqNG() {
    seqWarnCheck();
    vLog(NG);
    seqTermination();
    vLog("*** EOT ***");
    exit $V6evalTool::exitFail;
}

#=================================================
# sequence exit ERROR with error message
#=================================================
sub seqERROR($) {
    my ($msg) = @_;
    vLog($msg);
    vLog(ERROR);
    seqTermination();
    vLog("*** EOT ***");
    exit $V6evalTool::exitFail;

}

sub seqExitFATAL() {
    vLog("FATAL ERROR, NUT fall into strange state.");
    seqTermination();
    vLog("*** EOT ***");
    exit $V6evalTool::exitFATAL;
}

sub seqExitNS() {
    vLog("Not yet supported");
    seqTermination();
    vLog("*** EOT ***");
    exit $V6evalTool::exitNS;
}

sub seqExitWARN() {
    seqWarnCheck();
    vLog(WARN);
    seqTermination();
    vLog("*** EOT ***");
    exit $V6evalTool::exitWarn;
}

1;
###end
######################################################################
__END__

