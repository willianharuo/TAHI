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
# Perl Module for IPv6 Stateless Address Autoconfiguration Conformance Test
#
# $TAHI: ct/stateless-addrconf/DAD.pm,v 1.84 2003/04/21 05:30:39 akisada Exp $

######################################################################
package DAD;

use Exporter;
@ISA = qw(Exporter);
@EXPORT = qw(seqOK seqNG seqERROR seqExitFATAL seqExitNS seqExitWARN seqWarnCheck seqTermination seqSendWait seqCheckNUTAddrConfigured seqSetDADPkt seqWaitDADNSfromNUT seqConfAddrNUT seqSetDADParam seqInitNUT seqWaitNUTbeReady seqProbeVLT seqSetPktdesc seqRemoteAsyncWait);

use V6evalTool;
use Carp;


BEGIN { }
END { }

#----- constant values
# nothing

#----- test condition
$debug = 0;                #  debug level
$wait_dadna = 5;           #   5[sec]? time between NS and unsolicited NA
$wait_loginprompt = 20;    #  20[sec]  for kame to login prompt available since DAD finish
$wait_shutdown = 10;       #  10[sec]  for kame to shutdown when reboot
$wait_addrconfready = 10;  #  10[sec]? for kame to be ready since beggining of DAD
$wait_dadns{"boot"} = 120; # 120[sec]  for kame to remote reboot
$wait_dadns{"manual"} =30; #  30[sec]  for address config by remote ifconfig
$wait_dadns{"manual_async"} =30; #  30[sec]  for address config by remote ifconfig
$wait_dadns{"ra"}     =5;  #   5[sec]  for address config by RA
$howto_addrconf = "boot";  # How to configure address of NUT? boot,ra,manual
$DupAddrDetectTransmits=1; # NUT Variable: DupAddrDetectTransmits
$RetransTimerSec = 1;      # NUT Variable: RetransTimer/1000 [sec]
$addr_cast_type = "unicast"; # tentative address is "unicast" or "anycast" or "multicast"

#----- Packet name
$dadns_from_NUT         = "dadns_from_NUT"; # DAD NS comming from NUT on DAD
$chkconf_dadns_to_NUT   = "chkconf_dadns_to_NUT";
                                            # DAD NS sends to NUT to check if address is configured
$chkconf_dadna_from_NUT = "chkconf_dadna_from_NUT";
                                            # DAD NA comming from NUT if addrss is configured
$dadpkt_to_NUT          = "dadpkt_to_NUT";  # DAD Packet send to NUT to test DAD
$usolra_to_NUT          = "usolra";         # unsolicited RA for stateless addrconf, send to NUT



#==============================================
# initialize NUT before test
#   seqInitNUT($$)
#   seqInitNUT_DADSuccess($$)
#   seqInitNUT_DADFail($$)
#
#==============================================
sub seqInitNUT($$) {
    my ($IF, $initlist) = @_;
    my ($howto_initNUT, @howto_initNUT);

    vLog("Initialize sequence = $initlist") if $debug > 0;

    @howto_initNUT = split(/,/,$initlist);

    #----- do all init sequence in initlist
    while($howto_initNUT = shift @howto_initNUT) {

	#******************************************************************
	#***Using seqWaitNUTbeReady() for waiting previous reboot is safe.
	#***Using vSleep() is dangerous, it's just only for TAHI Test event
	#***make demo1.
	if ($init_waitprompt eq FALSE) {
	    vSleep(10, "Wait for NUT be Ready (sleep 10sec)"); #Wait login prompt
	}else{
	    seqWaitNUTbeReady(); #Wait login prompt
	}
	#***********************************************************

	#----- Init NUT
	if ($howto_initNUT eq "none") {
	    vLog("No NUT initialization specified.");
	    return;
	}elsif ($howto_initNUT eq "DADSuccess_boot") {
	    vCapture($IF);
	    vLog("Initialize NUT $howto_initNUT: boot NUT and to be state DADFinishSuccess for Link-local address autoconfiguration.");
	    if(seqInitNUT_DADSuccess($IF, "boot") eq 'FAIL') {
		vLogHTML("<FONT COLOR=\"#FF0000\">Initialize NUT $howto_initNUT: Fail</FONT>");
		$initfail++;
	    }
	    seqWaitNUTbeReady();
	    vStop($IF);
	    vClear($IF);
	}elsif ($howto_initNUT eq "DADFail_boot") {
	    vCapture($IF);
	    vLog("Initialize NUT $howto_initNUT: boot NUT and force to be state DADFinishFail for Link-local address autoconfiguration.");
	    if(seqInitNUT_DADFail($IF, "boot") eq 'FAIL') {
		vLogHTML("<FONT COLOR=\"#FF0000\">Initialize NUT $howto_initNUT: Fail</FONT>");
		$initfail++;
	    }
	    seqWaitNUTbeReady();
	    vStop($IF);
	    vClear($IF);
	}elsif ($howto_initNUT eq "ra") {
	    vCapture($IF);
	    vLog("Initialize NUT $howto_initNUT: send the RA to NUT.");
	    if (seqInitNUT_DADSuccess($IF, "ra") eq 'FAIL') {
		seqERROR("Initialize NUT $howto_initNUT: Fail");
	    }
	    vStop($IF);
	    vClear($IF);
	}else{
	    seqERROR("Unknown NUT initialization: $initname");
	}

	vLog("Initialize NUT $howto_initNUT: Success");

    }
}


sub seqInitNUT_DADSuccess($$) {
    my ($IF, $howto_addrconf_init ) = @_;
    my (%ret);


    #----- keep test condition and packet name
    local ($howto_addrconf,
	   $dadns_from_NUT,
	   $chkconf_dadns_to_NUT,
	   $chkconf_dadna_from_NUT,
	   $dadpkt_to_NUT,
	   $usolra_to_NUT );

    #----- test condition
    $howto_addrconf = $howto_addrconf_init; # How to configure address of NUT?
                                            #     sample: boot, ra, manual=GLOBAL0A0N_UCAST
    
    #----- Set DAD Packet Name for init sequence
    seqSetDADPkt("_init");
    $dadns_from_NUT .= "_ra" if $howto_addrconf eq "ra"; #for init=ra

    #----- Configure Address on NUT
    seqConfAddrNUT($IF);

    #----- wait a DAD NS coming from NUT
    %ret=seqWaitDADNSfromNUT($IF);

    #----- if received frame is a DAD NS
    if( $ret{status} == 0) {
	vLog("TN received the DAD NS sends from NUT.");

	#----- send no packet to NUT
	vLog("TN send no Packet to NUT.");

	#----- wait for NUT to finish DAD
	vSleep($DAD::RetransTimerSec, 
	       "Wait for NUT to finish DAD. ($DAD::RetransTimerSec [sec])");

	#----- check if NUT's address is configured
	#seqWaitNUTbeReady();
	vSleep($DAD::RetransTimerSec);
	if (seqCheckNUTAddrConfigured($IF) eq TRUE) {
	    return 'SUCCESS';
	}else{
	    return 'FAIL';
	}
    }

    #----- if timeout
    if( $ret{status} == 1 ) { #timeout
	vLog("TN received no DAD NS sends from NUT. It seems that NUT doesn't start DAD process.");
	return 'FAIL' if $howto_addrconf ne "ra" ;
	return 'SUCCESS';
    }

    #----- error
    return 'FAIL';
}

sub seqInitNUT_DADFail($$) {
    my ($IF, $howto_addrconf_init ) = @_;
    my (%ret);


    #----- keep test condition and packet name
    local ($howto_addrconf,
	   $dadns_from_NUT,
	   $chkconf_dadns_to_NUT,
	   $chkconf_dadna_from_NUT,
	   $dadpkt_to_NUT,
	   $usolra_to_NUT );

    #----- test condition
    $howto_addrconf = $howto_addrconf_init; # How to configure address of NUT?
                                            #     sample: boot, ra, manual=GLOBAL0A0N_UCAST
    
    #----- Set DAD Packet Name for init sequence
    seqSetDADPkt("_init");
    $dadns_from_NUT .= "_ra" if $howto_addrconf eq "ra"; #for init=ra

    #----- Configure Address on NUT
    seqConfAddrNUT($IF);

    #----- wait a DAD NS coming from NUT
    %ret=seqWaitDADNSfromNUT($IF);

    #----- if received frame is a DAD NS
    if( $ret{status} == 0) {
	vLog("TN received the DAD NS sends from NUT.");

	#----- send a DAD Packet to NUT
	vLog("TN send the DAD Packet($DAD::dadpkt_to_NUT) to NUT to force NUT state DADFinishFail.");
	%ret=vSend($IF, $DAD::dadpkt_to_NUT);
	seqERROR(vErrmsg(%ret)) if $ret{status} != 0 ;

	#----- wait for NUT to finish DAD
	vSleep($DAD::RetransTimerSec, 
	       "Wait for NUT to finish DAD. ($DAD::RetransTimerSec [sec])");

	#----- check if NUT's address is configured
	#seqWaitNUTbeReady();
	vSleep($DAD::RetransTimerSec);
	if (seqCheckNUTAddrConfigured($IF) eq TRUE) {
	    vLog("Although TN send the DAD NS to NUT, NUT assigned the address to the interface.");
	    return 'FAIL';
	}else{
	    return 'SUCCESS';
	}
    }

    #----- if timeout
    if( $ret{status} == 1 ) { #timeout
	vLog("TN received no DAD NS sends from NUT. It seems that NUT doesn't start DAD process.");
	return 'FAIL' if $howto_addrconf ne "ra" ;
	return 'SUCCESS';
    }

    #----- error
    return 'FAIL';
}


#==============================================
# Wait NUT be Ready
#
#  wait NUT become Ready for test.
#  when NUT's login prompt is ready, NUT is
#  ready for test.
#==============================================
sub seqWaitNUTbeReady(;$) {
    my ($nostop) = @_;
    my ($rret);

    if ($remotepass eq "rpass") { # no remote control
	vSleep($wait_addrconfready, 
	       "Wait for NUT becomes ready (sleep $wait_addrconfready [sec]).");
    }else{
	vLog("Wait for NUT becomes ready (wait for login prompt).");
	$rret=vRemote("loginout.rmt","","timeout=$wait_loginprompt");
	vLog("loginout.rmt returned status $rret") if $debug > 0;

	if ($rret > 0 ) {
	    ### This retry is adhoc but important, because of critical
	    ### condition of login process on NUT when DAD failed.
	    vLog("vRemote loginout.rmt exit $rret ... retry.");
	    $rret=vRemote("loginout.rmt","","timeout=$wait_loginprompt");
	    vLog("loginout.rmt returned status $rret") if $debug > 0;
	    if ($rret > 0 && $nostop ne 'NOSTOP') {
		seqERROR("vRemote loginout.rmt exit $rret");
	    }
	}
    }

}


#==============================================
#  Wait for asynchronous remote script
#  forked by vRemoteAsync()
#==============================================
sub seqRemoteAsyncWait() {
    my $ret = vRemoteAsyncWait();
    seqERROR("vRemoteAsyncWait failed :return status = $ret") if $ret != 0;
}

#==============================================
# set DAD Parameters
#
#   set parameters by .seq arguments info
#==============================================
sub seqSetDADParam($) {
    my($seqdebugopt) = @_;

    ($howto_addrconf, $manual_addr) = split(/\+/, $howto_addrconf);
                                                 # split "manual+_GLOBAL0A0N_UCAST"
    $manual_addr = "_LLOCAL0A0N_UCAST" unless defined($manual_addr);

    seqSetDADPkt();

    $sd = $seqdebugopt;

    $wait_dadns{"boot"} = 3 if $sd =~ /q/;       # quick timeout to wait reboot
    $remotepass  = "rpass" if $sd =~ /R/;        # pass remote control (vRemote()),
                                                 #        on manual configuration.
    $init_waitprompt = "FALSE" if $sd =~ /P/;    # Using vSleep() than seqWaitNUTbeReady()
                                                 #       for waiting previous reboot,
                                                 #       it's just only for TAHI Test event
                                                 #       make demo1.
    if ($sd =~/([0-9])/) {
	$debug = $1; #debug level
    }
}


#==============================================
# set DAD Packets name
#
#   set packetnames for DAD test
#     $trail = ''      means set packetname for test NUT
#              '_init' means set packetname for init NUT
#==============================================
sub seqSetDADPkt(;$) {
    my($trail) = @_;

    $dadns_from_NUT         = "dadns_from_NUT$trail";        # DAD NS comming from NUT on DAD
    $chkconf_dadns_to_NUT   = "chkconf_dadns_to_NUT$trail";  # DAD NS sends to NUT to check if address is configured
    $chkconf_dadna_from_NUT = "chkconf_dadna_from_NUT$trail";# DAD NA comming from NUT if addrss is configured
    $dadpkt_to_NUT          = "dadpkt_to_NUT$trail";         # DAD Packet send to NUT to test DAD
    $usolra_to_NUT          = "usolra$trail";                # unsolicited RA for stateless addrconf, send to NUT

    $chkconf_dadna_from_NUT .= "_rf1" if $V6evalTool::NutDef{Type} eq "router" ;
}


#==============================================
# get address configuration info for ifconfig
#
#   get from stdaddr.def (but not supported now)
#==============================================
sub seqGetAddrConfInfo($) {
    my($addrname) = @_;   #addrname sample : "_GLOBAL0A0N_UCAST"

    if ($addrname eq "_GLOBAL0A0N_UCAST") {
	return ("3ffe:501:ffff:100:200:ff:fe00:a0a0",
		64,
		"unicast" );
    }
    if ($addrname eq "_GLOBAL0A0N_ACAST") {
	return ("3ffe:501:ffff:100:200:ff:fe00:a0a0",
		64,
		"anycast" );
    }
    if ($addrname eq "_LLOCAL0A0N_UCAST") {
	return ("FE80::200:ff:fe00:a0a0",
		64,
		"unicast" );
    }
    if ($addrname eq "_LLOCAL0A0N_ACAST") {
	return ("FE80::200:ff:fe00:a0a0",
		64,
		"anycast" );
    }

}


#==============================================
# Configure Address on NUT
#==============================================
sub seqConfAddrNUT($) {
    my ($IF) = @_;
    my ($rret, $NUTif, $NUTaddr, $NUTprfxlen, $NUTaddrtype);

    $time_startreboot = time();  #reboot start time

    if ($howto_addrconf eq "boot") {
        #----- reboot NUT 
	if ($remotepass eq "rpass") {
	    vLog("Pass Remote boot process. ");
	    vLog("Please reboot NUT manually, and press ^D key. ");
	    $foo=<STDIN>;
	}else{
	    #*** reboot_async.rmt timeout must be 5 becouse
	    #*** of quick return. So wait for login prompt
	    #*** before reboot_async.rmt .
	    #*** (quick patch for make demo1)
	    seqWaitNUTbeReady(); # wait for logint prompt
	    vLog("Remote boot NUT. ");
	    $rret=vRemote("reboot_async.rmt","","timeout=5");
	    vLog("reboot_async.rmt returned status $rret") if $debug > 0;
	    seqERROR("vRemote reboot_async.rmt exit $rret") if $rret > 0;
	    vSleep($wait_shutdown, "wait $wait_shutdown [sec] for shutdown NUT.") if $wait_shutdown > 0;
	}
	return;
    }

    if ($howto_addrconf eq "manual" || $howto_addrconf eq "manual_async") {
        #----- addrconf by ifconfig
	if ($remotepass eq "rpass") {
	    vLog("Pass Remote manual address configuration process. ");
	    vLog("Please configure the address manually on NUT, and press ^D key. ");
	    $foo=<STDIN>;
	}else{
	    vLog("Remote manual address configuration for NUT. ");
	    ($NUTif) =   split(/\s+/,$V6evalTool::NutDef{$IF});
	    ($NUTaddr, $NUTprfxlen, $NUTaddrtype) = seqGetAddrConfInfo($manual_addr);
	    $addr_cast_type = "anycast" if $NUTaddrtype =~ /anycast/;

	    vLog("config $NUTif $manual_addr: $NUTaddr prefixlen $NUTprfxlen $NUTaddrtype");
	    if ($howto_addrconf eq "manual_async") {
		$rret=vRemoteAsync("manualaddrconf.rmt","",
				   "if=$NUTif addr=$NUTaddr len=$NUTprfxlen type=$NUTaddrtype");
	    }else{
		$rret=vRemote("manualaddrconf.rmt","",
			      "if=$NUTif addr=$NUTaddr len=$NUTprfxlen type=$NUTaddrtype");
	    }
	    vLog("manualaddrconf.rmt returned status $rret") if $debug > 0;
	    if ($rret > 0) {
		if ($rret == $V6evalTool::exitNS) {
		    seqExitNS();
		}
		else {
		    seqERROR("vRemote or vRemoteAsync manualaddrconf.rmt exit $rret");
		}
	    }
	}
	return;
    }

    if ($howto_addrconf eq "ra") {
        #----- stateless addrconf by RA
	vLog("Stateless address configuration by sending RA to NUT. ");
	%ret=vSend($IF, $usolra_to_NUT);
	return %ret;
    }

    if ($howto_addrconf eq "none") {
	return;
    }

    seqERROR("Unknown addrconf type '$howto_addrconf'"); #exit

}


#==============================================
# wait a DAD NS comming from NUT
#==============================================
sub seqWaitDADNSfromNUT($) {
    my ($IF) = @_;
    my ($timeout, %ret);

    $timeout = $wait_dadns{$howto_addrconf};

    vLog("TN waits a DAD NS sent from NUT ($timeout [sec]): $dadns_from_NUT");
    %ret=vRecv($IF,$timeout,0,0, $dadns_from_NUT, dadns_any_from_NUT, dadns_sll_any_from_NUT);
    vLog("Received packet count=$ret{recvCount}");

    if ($ret{status}==0 && $ret{recvFrame} ne $dadns_from_NUT) {
	vLogHTML("<FONT COLOR=\"#FF0000\">TN received irregular DAD NS.</FONT>");
	$iregdadns = 1;
    }

    return %ret;
}

#==============================================
# check if NUT's address is configured
#==============================================
sub seqCheckNUTAddrConfigured($) {
    my ($IF) = @_;
    my (%retsw1, $dad_ns, $dad_na);

    vLog("Check if NUT's address is configured");
    %retsw1 = seqSendWait($IF,
			  "DAD NS from TN to NUT:", $chkconf_dadns_to_NUT,
			  "DAD NA from NUT:", $wait_dadna,0, $chkconf_dadna_from_NUT, chkconf_dadna_any_from_NUT, chkconf_dadna_notll_any_from_NUT);
    if ($retsw1{status}==0) {
	vLog("NUT assigned the address to the interface.");
	if ($retsw1{recvFrame} ne $chkconf_dadna_from_NUT) {
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



#==============================================================================
#  seqProbeVLT() probe lifetime of the configured address
#      $IF:  interface
#      $check_interval: address lifetime check interval [sec]
#      $@vltlist      : check by which valid lifetime the address configured
#                       (vlt1, vlt2, vlt3, ...) [sec]
#      return (waitsec to wait invalid ,  index No. in @vltlist)
#
#==============================================================================
sub seqProbeVLT($$@) {
    my ($IF, $check_interval, @vltlist) = @_;
    my ($waitsec, $total_waitsec, $max_total_waitsec, @vlsort, %vlt_index) = ();
    my ($i, $vlt) = ();

    @vltsort = sort {$a <=> $b} @vltlist;
    $max_total_waitsec = $vltsort[@vltsort-1];

    $i = 0;
    while($vlt = shift(@vltlist)) {
	$vlt_index{$vlt} = $i++; 
    }

    while(1) {
	$waitsec = $check_interval;
	vSleep($waitsec, "Wait $waitsec [sec] to spend NUT's address lifetime.");
	$total_waitsec += $waitsec;
	vLog("$total_waitsec [sec] spent since last address configuration.");

	if (seqCheckNUTAddrConfigured($IF) eq TRUE) {
	    vLog("The address is configured (valid).");
	    if ($total_waitsec >= $max_total_waitsec) {
		vLog("But the address must be invalid.");
		return ($total_waitsec, -1 );  #NG
	    }
	}else{
	    vLog("The address is not configured, becomes invalid.");
	    $ge_vlt = 0;
	    $lt_vlt = shift(@vltsort);

	    if ($ge_vlt <= $total_waitsec && $total_waitsec <  $lt_vlt) {
		vLog("But the address must be valid.");
		return ($total_waitsec, -1 );  #NG
	    }

	    while(1) {
		$ge_vlt = $lt_vlt;
		$lt_vlt = shift(@vltsort);
		return ($total_waitsec, $vlt_index{$ge_vlt} ) unless defined $lt_vlt;
		if ($ge_vlt <= $total_waitsec && $total_waitsec <  $lt_vlt) {
		    return ($total_waitsec, $vlt_index{$ge_vlt} );  #OK
		}
	    }
	}
    }
}

#==============================================================================
#  seqSetPktdesc() Set %main::pktdesc with packet.def.pktdesc file
#
#   packet.def.pktdesc file is perl script which "require" from sequence script.
#
#   ------------------------------------------------------------------------
#    vLog("Reading GLOBAL0_valRA.def.pktdesc") if $debug > 0;
#    require "BASIC.def.pktdesc";
#    $main::pktdesc{usolra}         = "send valid RA";
#    ...
#    1;
#    #end
#   ------------------------------------------------------------------------
#==============================================================================
sub seqSetPktdesc() {
    my ($line, $pktdesc_file, $frame_name, $description);
    $pktdesc_file = $V6evalTool::PktDef . '.pktdesc'; # packet.def.pktdesc file
    vLog("Setting \%pktdesc with $pktdesc_file file") if $debug > 0;

    if( -e $pktdesc_file) {
	require "$pktdesc_file";
    }else{
	vLog("$pktdesc_file file not found.") if $debug > 0;
    }
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
	vLog("Note: There is an irregular DAD NS.");
	$iregdadns=0; $wc++;
    }	
    if ($iregdadna > 0) {
	vLog("Note: There is an irregular DAD NA.");
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
    confess "Sequence Stop" if $debug > 0;
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


=head1 NAME

DAD and Address configuration test sequences
     -- test for IPv6 Stateless Address Autoconfiguration

  DADSendNS_DADPostSendNS.seq, DADFail_DADPostSendNS.seq, DADSuccess_DADPostSendNS.seq,
  DADFail_DADPreSendNS.seq, ADDRCONFFail.seq, ADDRCONFSuccess.seq,
  ADDRSTATE_reset_VLT, ADDRSTATE_not_reset_VLT, ADDRSTATE_pkt_receiving, ADDRSTATE_src_select,
  ADDRSTATE_sameprfxes_order

=head1 SYNOPSIS

  DADSendNS_DADPostSendNS.seq [-tooloption ...] -pkt <packetdef>
     [addrconf=<addrconfname>] [init=<initname>,<initname>...] [sd=<sdopt>]
  DADFail_DADPostSendNS.seq [-tooloption ...] -pkt <packetdef>
     [addrconf=<addrconfname>] [init=<initname>,<initname>...] [sd=<sdopt>]
  DADSuccess_DADPostSendNS.seq [-tooloption ...] -pkt <packetdef>
     [addrconf=<addrconfname>] [init=<initname>,<initname>...] [send=<sendname>] [sd=<sdopt>]
  DADFail_DADPreSendNS.seq [-tooloption ...] -pkt <packetdef>
     [addrconf=<addrconfname>] [init=<initname>,<initname>...] [sd=<sdopt>]
  ADDRCONFFail.seq [-tooloption ...] -pkt <packet.def>
     [addrconf=<addrconfname>] [init=<initname>,<initname>...] [sd=<sdopt>]
  ADDRCONFSuccess.seq [-tooloption ...] -pkt <packetdef>
     [addrconf=<addrconfname>] [init=<initname>,<initname>...] [sd=<sdopt>]

  ADDRSTATE_pkt_receiving.seq [-tooloption ...] -pkt <packetdef>
     [addrconf=<addrconfname>] [init=<initname>,<initname>...] [sd=<sdopt>]
  ADDRSTATE_src_select.seq [-tooloption ...] -pkt <packetdef>
     waitsec=<waitsec> [init=<initname>,<initname>...] [sd=<sdopt>]

=begin html
  <PRE>
     about waitsec: see  <A HREF="ADDRSTATE_src_select.html">ADDRSTATE_src_select.seq</A>
  </PRE>

=end html

  ADDRSTATE_reset_VLT.seq [-tooloption ...] -pkt <packetdef>
     [sequence=<usolra-1>,<waitsec>,<usolra-2>] [init=<initname>,<initname>...] [sd=<sdopt>]
  ADDRSTATE_not_reset_VLT.seq [-tooloption ...] -pkt <packetdef>
     [sequence=<usolra-1>,<waitsec>,<usolra-2>] [init=<initname>,<initname>...] [sd=<sdopt>]
     <usolra-1,2>  : send RA <usolra-1,2> to NUT ; usolra_vlt(30|60|90|120)
     <waitsec>     : wait NN [sec]; waitNN

=begin html
  <PRE>
     about usolra-1,2 and waitsec: see  <A HREF="ADDRSTATE_reset_VLT.html">ADDRSTATE_reset_VLT.seq</A>
  </PRE>

=end html

  ADDRSTATE_sameprfxes_order.seq [-tooloption ...] -pkt <packetdef>
     [init=<initname>,<initname>...] [sd=<sdopt>]



=head1 DESCRIPTION

  This is a set of conformance test for IPv6 Stateless Address
  Autoconfiguration that is based upon RFC2462 and RFC2461.


=begin html
  <PRE>
  Tests are listed in <A HREF="index.html">index.html</A> .
  Test coverage and How to run the tests for stateless-addrconf are
  described in <A HREF="00README">00README</A>:
  Eache tests are defined by the following test sequences and packet definition files. 
  Combinations of these sequence and packet definition for each tests are defined in
      <A HREF="INDEX_hostrouter">INDEX_hostrouter</A>:  tests for a host and a router
      <A HREF="INDEX_host">INDEX_host</A>:        tests for a host
      <A HREF="INDEX_router">INDEX_router</A>:      tests for a router
  
  <A HREF="DADSendNS_DADPostSendNS.html">DADSendNS_DADPostSendNS.seq</A>
      - check if NUT performs DAD process
  <A HREF="DADFail_DADPostSendNS.html">DADFail_DADPostSendNS.seq</A>
      - check if NUT detect address duplication in state DADPostSendNS(after sending out first DAD NS)
  <A HREF="DADSuccess_DADPostSendNS.html">DADSuccess_DADPostSendNS.seq</A>
      - check if NUT does not detect address duplication in state DADPostSendNS(after sending out first DAD NS)
  <A HREF="DADFail_DADPreSendNS.html">DADFail_DADPreSendNS.seq</A>
      - check if NUT detect address duplication in state DADPreSendNS(before sending out first DAD NS)
  <A HREF="ADDRCONFFail.html">ADDRCONFFail.seq</A>
       - check if address is not configured
  <A HREF="ADDRCONFSuccess.html">ADDRCONFSuccess.seq</A>
       - check if address is configured
  <A HREF="ADDRSTATE_reset_VLT.html">ADDRSTATE_reset_VLT.seq</A>
       - check if ValidLifetime is reset by RA with same prefix
  <A HREF="ADDRSTATE_not_reset_VLT.html">ADDRSTATE_not_reset_VLT.seq</A>
       - check if ValidLifetime is not reset by RA with same prefix
  <A HREF="ADDRSTATE_pkt_receiving.html">ADDRSTATE_pkt_receiving.seq</A>
       - check packet receiving and address lifetime expiry
  <A HREF="ADDRSTATE_src_select.html">ADDRSTATE_src_select.seq</A>
       - check src address selection and address lifetime expiry
  <A HREF="ADDRSTATE_sameprfxes_order.html">ADDRSTATE_sameprfxes_order.seq</A>
       - probe PrefixOptions processing order of same prefix in one RA
  </PRE>

=end html


=head2 Parameters

 -tooloption: See perldoc V6evalTool.pm, perldoc V6evalRemote.pm

 <packetdef>: mandatory
    LLOCAL*.def : testing address is a Link-local address
    GLOBAL*.def : testing address is a Global address

 <addrconfname>: default is 'boot'
    boot : reboot NUT and verify DAD process
    ra   : send RA to NUT and verify DAD process
    manual+<addressname>:
           configure address manually (ifconfig if bsd) and verify DAD process
    manual_async+<addressname>:
           same as above, using asynchronous manual configuration.

 <initname>: default is 'none'
    none            : no initialization before test
    DADSuccess_boot : reboot NUT and make to be state DAD Success before test
    DADFail_boot    : reboot NUT and force to be state DAD Fail before test
    ra              : send RA to NUT before test

 <sendname>: default is 'send'
    none  : send no packet when NUT performs DAD process
    send  : send packet when NUT performs DAD process

 <sdopt>: default is empty
    sequence debug options
    q : quick timeout when waiting boot. 
    R : pass remote control.

=head2 Outline of test sequence

  Test sequence scripts described here have a similar outline of following 
  4 phases. (except DADFail_DADPreSendNS.seq)

  1. Initialization phase
     Initialize NUT. (init=none or DADSuccess_boot or DADFail_boot or ra)

  2. Addrconf phase
     Configure address of NUT (addrconf=boot or manual or ra).

  3. DAD phase
     Wait for DAD NS to be sent from NUT.
     Send DAD Packet to NUT if needed (for DAD test).

  4. Check phase
     Check if NUT's address is configured or not configured for address
     configuration test,  or check address state and lifetime for address
     lifetime expiry test.

=head2 Initialization phase

   Sequence parameter init=<initname> specifies how to initialize NUT before test.

    <initname>
    none            : no initialization before test
    DADSuccess_boot : reboot NUT and make to be state DAD Success before test
    DADFail_boot    : reboot NUT and force to be state DAD Fail before test
    ra              : send RA to NUT before test

    Multiple <initname> is available, such as init=DADSuccess_boot,ra which means
    reboot NUT and configure Global or Site-local address with unsolicited RA.

    The following shows init sequences for each <initname>.
    Packet name appeared in sequences: see "Packet definition file".

B<init=DADSuccess_boot and init=DADFail_boot>

B< Init sequence>

  TN(or X)	             NUT
  ------------------------------
  Login to NUT from TN and reboot NUT.

  Wait for DAD NS to be sent from NUT
  <=== Judgement #1: DAD NS ====
        name: dadns_from_NUT_init
        TargetAddress: NUT's Link-local address

  ==== Action #1: DAD NS ====>
        name: dadpkt_to_NUT_init
        TargetAddress: NUT's Link-local address

  Wait for NUT to finish DAD. (sleep $RetransTimerSec [sec])

  Check if NUT's address is configured or not configured.
  ==== Action #2: DAD NS ====>
        name: chkconf_dadns_to_NUT_init
        TargetAddress: NUT's Link-local address

  <=== Judgement #2: DAD NA ====
        name: chkconf_dadna_from_NUT_init (or chkconf_dadna_from_NUT_rf1_init if NUT is a Router)
        TargetAddress: NUT's Link-local address

B< Action and Judgement>

  Action #1.
    When init=DADFail_boot, send DAD NS immediately (within $RetransTimerSec [sec]) to NUT 
    to be DAD fail on NUT stateless Link-local address autoconfiguration .
    Otherwise (init=DADSuccess_boot) send no packet so NUT configure Link-local address.

  Judgement #2.
    When init=DADFail_boot, DAD NA does not come. Otherwise (init=DADSuccess_boot) DAD NA come.

B<init=ra>

  Send Unsolicited RA to configure address of NUT.
  Packet name appeared in sequences: see "Packet definition file".

B< Init sequence>

  TN(or X)	             NUT
  ------------------------------
  Send Unsolicited RA to configure address of NUT.
  ==== Action #1: Unsolicited RA ===>
        name: usolra_init

  Note: usolra_init is not defined in BASIC_init.def, define in each packet definition file.


=head2 Addrconf phase

   Sequence parameter addrconf=<addrconfname> specifies how to configure address on NUT for test.

 <addrconfname>
    boot : reboot NUT to configure Link-local address.
    ra   : send RA to NUT to configure address with prefixes in RA.
    manual+<addressname>:
           configure address manually (ifconfig if BSD).
    manual_async+<addressname>:
           same as above, using asynchronous manual configuration.

    The following shows addrconf sequences for each <addrconfname>.
    Packet names appeared in addrconf sequence are defined in packet def file
    specified by -pkt option. 
    Default packets are defined in "BASIC.def" file which is included by packet
    def file. "BASIC.def" is defined by "DAD.def" which includes packet definition
    macros. 

B<addrconf=boot>

    Login to NUT from TN and reboot NUT to configure Link-local address on NUT.
    The test sequence assumes that stateless Link-local address auto configuration
    will be done on system rebooting process. You may set appropriate value to
    $wait_dadns{"boot"} variable in DAD.pm, which is a time[sec] to wait address
    auto configuration since reboot command issued; default 120[sec].

    The test sequence uses rRebootAsync remote command to reboot NUT.
    See vRemote() in perldoc V6evalTool and rRebootAsync in perldoc V6evalRemote.

B<addrconf=manual+E<lt>addressnameE<gt>>

    Login to NUT from TN and configure address on NUT manually.
    The following addressname is available. It is as same as defined name in stdaddr.def
    (See std.def in perldoc V6evalTool.pm)

    <addressname>           address                             prefixlen  type
    _GLOBAL0A0N_UCAST  3ffe:501:ffff:100:200:ff:fe00:a0a0	64     unicast
    _GLOBAL0A0N_ACAST  3ffe:501:ffff:100:200:ff:fe00:a0a0	64     anycast
    _LLOCAL0A0N_UCAST  FE80::200:ff:fe00:a0a0			64     unicast
    _LLOCAL0A0N_ACAST  FE80::200:ff:fe00:a0a0			64     anycast

B<addrconf=manual_async+E<lt>addressnameE<gt>>

    Same as addrconf=manual but using asynchronous manual configuration.

    If you use addrconf=manual_async, the test sequence will be as the
    following. The DAD NS packet will be received at the point of mark"*".

      [test sequence]  [manualaddrconf.rmt]
            |
       vRemoteAsync()------->+
            |                |
          vRecv()            | manual address configuration
            |                | on NUT
            * <=== DAD NS ===|
            |                |
     vRemoteAsyncWait()<-----+
            |
            V

    If you use addrconf=manual, the test sequence will be as the following. 
    The DAD NS packet will be received at the point of mark"*".

      [test sequence]  [manualaddrconf.rmt]
            |
         vRemote()---------->+
                             | manual address configuration
              <=== DAD NS ===| on NUT
                             |
            +<---------------+
         vRecv()*
            |
            V

    The difference of receiving point "*" of DAD NS has an influence on
    timing critical tests which will forcing address duplication.
    You should use addrconf=manual_async for such tests.

B<addrconf=ra>

    Send Unsolicited RA to configure address of NUT.
    Packet name appeared in sequences: see "Packet definition file".

B< Addrconf sequence>

  TN(or X)	             NUT
  ------------------------------
  Send Unsolicited RA to configure address of NUT.
  ==== Action #1: Unsolicited RA ===>
        name: usolra


=head2 DAD phase

     Wait for DAD NS to be sent from NUT.
     Send DAD Packet to NUT if needed (for DAD test).
     Packet name appeared in sequences: see "Packet definition file".

B< DAD phase sequence>

  TN(or X)	             NUT
  ------------------------------
  TN waits for a DAD NS sent from NUT
  <=== Judgement #1: DAD NS ====
        name: dadns_from_NUT

  Immediately (within $RetransTimerSec [sec]) send DAD Packet to test detecting address duplication.
  ==== Action #1: DAD NS ====>
        name: dadpkt_to_NUT

  Wait for NUT to finish DAD. (sleep $RetransTimerSec [sec])

B< Action and Judgement>

  Action #1 is available in DAD test (DADFail_DADPostSendNS.seq, DADSuccess_DADPostSendNS.seq,
  DADFail_DADPreSendNS.seq) except for DADSendNS_DADPostSendNS.seq.
  It's not available in ADDRCONF test (ADDRCONFSuccess.seq, ADDRCONFFail.seq).


=head2 Check phase

  Check if NUT's address is configured or not configured.
  Packet name appeared in sequences: see "Packet definition file".

B< Check phase sequence>

  TN(or X)	             NUT
  ------------------------------
  ==== Action #1: DAD NS ====>
        name: chkconf_dadns_to_NUT

  <=== Judgement #1: DAD NA ====
        name: chkconf_dadna_from_NUT (or chkconf_dadna_from_NUT_rf1 if NUT is a Router)

B< Action and Judgement>

  In DADSendNS_DADPostSendNS.seq, DADSuccess_DADPostSendNS.seq, ADDRCONFSuccess.seq:
    Action #1. 
       Check if NUT's address is configured
    Judgement #1.
       DAD NA come from NUT because NUT does not detect address duplication and
       address is configured.

  In DADFail_DADPostSendNS.seq, DADFail_DADPreSendNS.seq, ADDRCONFFail.seq:
    Action #1. 
       Check if NUT's address is not configured
    Judgement #1.
       DAD NA does not come because NUT detect address duplicated and address is not
       configured.


=head2 Packet definition file

  Packet name described above is defined in <packetdef> file.

   <packetdef>     description
    LLOCAL*.def : testing address is a Link-local address
    GLOBAL*.def : testing address is a Global address

  Packet name appeared in each phase is same in all test scripts.
  The following shows description and location of each packet definition. 
  Packets are defined by macros in DAD.def file.

  <packetdef> file
    -------------------------------------------------------------------------------------
     [name]                     [description]
     include "BASIC_init.def" : Packets appeared in Initialization phase
     include "BASIC.def"      : Packets appeared in Addrconf,DAD,Check phase
     dadpkt_to_NUT            : DAD Packet (DAD NS or NA) send to NUT to test DAD
                                appeared in DAD phase
     usolra                   : RA appeared in Addrconf phase
     usolra_init              : RA appeared in Initialization phase
    -------------------------------------------------------------------------------------

  BASIC_init.def file
    -------------------------------------------------------------------------------------
     [name]                        [description]
     DADV6ADDR_init              : v6 Tentative address for DAD on initialization phase
     dadns_from_NUT_init         : DAD NS coming from NUT on DAD on initialization phase
     dadpkt_to_NUT_init          : DAD Packet send to NUT to test DAD on initialization phase
     chkconf_dadns_to_NUT_init   : DAD NS sends to NUT to check if address is configured
                                   on initialization phase
     chkconf_dadna_from_NUT_init : DAD NA coming from NUT if address is configured on
                                   initialization phase
     chkconf_dadna_from_NUT_init_rf1 : for Router test on initialization phase
    -------------------------------------------------------------------------------------

  BASIC.def file
    -------------------------------------------------------------------------------------
     [name]                   [description]
     DADV6ADDR              : v6 Tentative address for DAD
     dadns_from_NUT         : DAD NS coming from NUT on DAD
     chkconf_dadns_to_NUT   : DAD NS sends to NUT to check if address is configured
     chkconf_dadna_from_NUT : DAD NA coming from NUT if address is configured
     chkconf_dadna_from_NUT_rf1 : for Router test
    -------------------------------------------------------------------------------------

=head1 Known Bugs

 Some tests may results in FAIL if RemoteSpeed > 0 in tn.def file.

=head1 See also

 perldoc V6evalTool.pm, perldoc V6evalRemote.pm:

=begin html
<PRE>
 <A HREF="00README">00README</A>:
    Test coverage and How to run the tests for stateless-addrconf.
 <A HREF="DAD.pm">DAD.pm</A>:
    Sequence library for stateless-addrconf test.
 <A HREF="DAD.def">DAD.def</A>:
    Packet definition macro library for stateless-addrconf test.
 <A HREF="BASIC.def">BASIC.def</A>:
    Default packet definition for testing NUT.
 <A HREF="BASIC_init.def">BASIC_init.def</A>:
    Default packet definition for initialization of NUT.
 
</PRE>

=end html

=cut


