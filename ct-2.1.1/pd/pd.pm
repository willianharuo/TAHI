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
# $TAHI: ct/pd/pd.pm,v 1.5 2003/06/04 05:00:32 ozoe Exp $

package pd;
use Exporter;
@ISA = qw(Exporter);

use 5;
use V6evalTool;

@EXPORT = qw(
	     pdGetLinkDev
             pdGetLinkDevs
             pdOptions
             pdLinkUp
             pdLinkDown
             pdStopDHCP6Client
             pdReleaseDHCP6Client
             pdStartNoAsyncDHCP6Client
             pdStartDHCP6Client
             pdStartRapidDHCP6Client
             pdStartInfoReqDHCP6Client
             pdStartDelayedAuthDHCP6Client
             pdStartRecfgKeyAuthDHCP6Client
             pdStartDefaultRA
             pdAsyncWait
             pdRetransmitTimer
	     pdErrmsg
	     pdWarnmsg
             pdReboot
             pdRebootAsync
	     pdPrintSummaryHTML
	     pdSetTimeDUIDLLT
	     pdSetVCPP
             pdCheckRA
             );

#
#################################################
#When NUT does not have correlation in the process of DHCP and RA,
#please set NOASYNC_RA of pd.pm to 1.
$NOASYNC_RA = 0; #default 0
#
$debug=0;
$remote_debug="";
#
#################################################
#
# router constants
$MAX_FINAL_RTR_ADVERTISEMENTS=3;        # times
$MIN_DELAY_BETWEEN_RAS = 3;  # sec.
$wait_ra= $MIN_DELAY_BETWEEN_RAS * $MAX_FINAL_RTR_ADVERTISEMENTS + 1;
$AdvValidLifetime     = 7200; # sec. (2 hours)
$AdvPreferredLifetime = 3600; # sec. (1 hours)
#
#################################################
# Initial value
#
$TIMEOUT = 60;
$DHCPID = 0;
$TYPE = 0;
$HARDWARETYPE = 0;
$TIME = 0;
$LINKLAYERADDRESS = "0:0:0:0:0:0";
$IAID = 0;
#
# DHCP client configuration parameter
$iaid=$IAID;
$domain_name_servers="domain-name-servers";
#
$INITIAL = 0;
#
#24.2. DHCP Message Types
#
$SOLICIT              = 1;
$ADVERTISE            = 2;
$REQUEST              = 3;
$CONFIRM              = 4;
$RENEW                = 5;
$REBIND               = 6;
$REPLY                = 7;
$RELEASE              = 8;
$DECLINE              = 9;
$RECONFIGURE          = 10;
$INFORMATIONREQUEST   = 11;
$RELAYFORW            = 12;
$RELAYREPL            = 13;
#
#5.5. Transmission and Retransmission Parameters
#
#   This section presents a table of values used to describe the message
#   transmission behavior of clients and servers.
#
#      Parameter     Default  Description
#   -------------------------------------
#   SOL_MAX_DELAY     1 sec   Max delay of first Solicit
#   SOL_TIMEOUT       1 sec   Initial Solicit timeout
#   SOL_MAX_RT      120 secs  Max Solicit timeout value
#   REQ_TIMEOUT       1 sec   Initial Request timeout
#   REQ_MAX_RT       30 secs  Max Request timeout value
#   REQ_MAX_RC       10       Max Request retry attempts
#   CNF_MAX_DELAY     1 sec   Max delay of first Confirm
#   CNF_TIMEOUT       1 sec   Initial Confirm timeout
#   CNF_MAX_RT        4 secs  Max Confirm timeout
#   CNF_MAX_RD       10 secs  Max Confirm duration
#   REN_TIMEOUT      10 secs  Initial Renew timeout
#   REN_MAX_RT      600 secs  Max Renew timeout value
#   REB_TIMEOUT      10 secs  Initial Rebind timeout
#   REB_MAX_RT      600 secs  Max Rebind timeout value
#   INF_MAX_DELAY     1 sec   Max delay of first Information-request
#   INF_TIMEOUT       1 sec   Initial Information-request timeout
#   INF_MAX_RT      120 secs  Max Information-request timeout value
#   REL_TIMEOUT       1 sec   Initial Release timeout
#   REL_MAX_RC        5       MAX Release attempts
#   DEC_TIMEOUT       1 sec   Initial Decline timeout
#   DEC_MAX_RC        5       Max Decline attempts
#   REC_TIMEOUT       2 secs  Initial Reconfigure timeout
#   REC_MAX_RC        8       Max Reconfigure attempts
#   HOP_COUNT_LIMIT  32       Max hop count in a Relay-forward message


$SOL_MAX_DELAY   =   1;
$SOL_TIMEOUT     =   1;
$SOL_MAX_RT      = 120;
$REQ_TIMEOUT     =   1;
$REQ_MAX_RT      =  30;
$REQ_MAX_RC      =  10;
$CNF_MAX_DELAY   =   1;
$CNF_TIMEOUT     =   1;
$CNF_MAX_RT      =   4;
$CNF_MAX_RD      =  10;
$REN_TIMEOUT     =  10;
$REN_MAX_RT      = 600;
$REB_TIMEOUT     =  10;
$REB_MAX_RT      = 600;
$INF_MAX_DELAY   =   1;
$INF_TIMEOUT     =   1;
$INF_MAX_RT      = 120;
$REL_TIMEOUT     =   1;
$REL_MAX_RC      =   5;
$DEC_TIMEOUT     =   1;
$DEC_MAX_RC      =   5;
$REC_TIMEOUT     =   2;
$REC_MAX_RC      =   8;
$HOP_COUNT_LIMIT =  32;


#
#
#
BEGIN
{}

#
#
#
END
{}

#
#
#
sub pdGetLinkDev()
{
    my(@dev)=();
    foreach(keys(%V6evalTool::NutDef)) {
        if(/^Link1_device$/) {
            my($v)=$V6evalTool::NutDef{$_};
            push(@dev, "link1=$v");
            last;
        }
    }
    @dev;
}

#
#
#
sub pdGetLinkDevs()
{
    my(@dev)=();
    foreach(keys(%V6evalTool::NutDef)) {
        if(/^Link([0-9]+)_device$/) {
            my($v)=$V6evalTool::NutDef{$_};
            push(@dev, "link$1=$v");
        }
    }
    @dev;
}

#
#
#
sub pdOptions(@)
{
    my(@argv) = @_;
    my($v, $lval, $rval);

    foreach(@argv) {
        ($lval, $rval) = split(/=/, $_, 2);
        $rval=1 if $rval =~ /^\s*$/;
        $v='$main::pdOpt_'."$lval".'=\''."$rval".'\'';
        eval($v);       # eval ``$main::pdOpt<LVAL>=<RVAL>''
    }
}

#
#
#
sub pdLinkUp()
{
    my(@links)=pdGetLinkDevs();
    vLogHTML("Link up upstream side I/F of NUT<BR>");
    $ret = vRemoteAsync("dhcp6c.rmt",
            $remote_debug,
            Link,
            up,
            @links,
            );
    if($ret == 0){
       return(1);
    }else{
       vLogHTML("<FONT COLOR=\"#FF0000\">Fail: vRemote error number $ret</FONT>");
       return(0);
    }
}

#
#
#
sub pdLinkDown()
{
    my(@links)=pdGetLinkDevs();
    vLogHTML("Link down upstream side I/F of NUT<BR>");
    $ret = vRemote("dhcp6c.rmt",
            $remote_debug,
            Link,
            down,
            @links,
            );
    if($ret == 0){
       return(1);
    }else{
       vLogHTML("<FONT COLOR=\"#FF0000\">Fail: vRemote error number $ret</FONT>");
       return(0);
    }
}

#
#
#
sub pdStopDHCP6Client()
{
    my(@links)=pdGetLinkDevs();
    vLogHTML("Stop dhcp client process of NUT<BR>");
    $ret = vRemote("dhcp6c.rmt",
            $remote_debug,
            stop,
            @links
            );
    if($ret == 0){
       vSleep($TIMEOUT);
       return(1);
    }else{
       vLogHTML("<FONT COLOR=\"#FF0000\">Fail: vRemote error number $ret</FONT>");
       return(0);
    }
}

#
#
#
sub pdReleaseDHCP6Client()
{
    my(@links)=pdGetLinkDevs();
    vRemoteAsync("dhcp6c.rmt",
            $remote_debug,
            release,
            @links
            ) && return(0);
    return(1);
}

#
#
#
sub pdStartNoAsyncDHCP6Client()
{
    my(@links)=pdGetLinkDevs();

    pdStopDHCP6Client();

    vRemote("dhcp6c.rmt",
            $remote_debug,
            start,
            "iaid=$iaid",
            @links
            ) && return(0);
    return(1);
}

#
#
#
sub pdStartDHCP6Client()
{
    my(@links)=pdGetLinkDevs();

#    pdStopDHCP6Client();

    vLogHTML("Setup and start dhcp client process of NUT<BR>");
    vRemoteAsync("dhcp6c.rmt",
            $remote_debug,
            start,
            "iaid=$iaid",
            @links
            ) && return(0);
    return(1);
}

#
#
#
sub pdStartRapidDHCP6Client()
{
    my(@links)=pdGetLinkDevs();

#    pdStopDHCP6Client();

    vRemoteAsync("dhcp6c.rmt",
            $remote_debug,
            start,
            rapidcommit,
            "iaid=$iaid",
            @links
            ) && return(0);
    return(1);
}

#
#
#
sub pdStartInfoReqDHCP6Client()
{
    my(@links)=pdGetLinkDevs();

    pdStopDHCP6Client();

    vSleep(5);

    vRemote("dhcp6c.rmt",
            $remote_debug,
            start,
            inforeq,
            "requestoptions=$domain_name_servers",
            @links
            ) && return(0);
    return(1);
}

#
#
#
sub pdStartDelayedAuthDHCP6Client()
{
    my(@links)=pdGetLinkDevs();

#    pdStopDHCP6Client();

    vRemoteAsync("dhcp6c.rmt",
            $remote_debug,
            start,
            delay_auth,
            "iaid=$iaid",
            @links
            ) && return(0);
    return(1);
}

#
#
#
sub pdStartRecfgKeyAuthDHCP6Client()
{
    my(@links)=pdGetLinkDevs();

#    pdStopDHCP6Client();

    vRemoteAsync("dhcp6c.rmt",
            $remote_debug,
            start,
            key_auth,
            "iaid=$iaid",
            @links
            ) && return(0);
    return(1);
}

#
# pdAsyncWait() - Wait for asynchronous remote script
#
sub pdAsyncWait() {
    $ret = vRemoteAsyncWait();
    if($ret == 0){
       return(1);
    }else{
       vLogHTML("<FONT COLOR=\"#FF0000\">Fail: vRemoteAsyncWait error number $ret</FONT>");
       return(0);
    }
}


#
#
#
sub pdErrmsg($)
{
    my($msg)=@_;
    "<FONT COLOR=\"#FF0000\">$msg</FONT>";
}

#
#
#
sub pdWarnmsg($)
{
    my($msg)=@_;
    "<FONT COLOR=\"#00FF00\">$msg</FONT>";
}

#
#
#
sub pdReboot()
{
    vRemote("reboot.rmt", $remote_debug) && return 1;
    vLogHTML("Target: Reboot<BR>");
    return 0;
}

#
#
#
sub pdRebootAsync()
{
    vRemote("reboot_async.rmt", $remote_debug) && return 1;
    vLogHTML("Target: Reboot<BR>");
    return 0;
}

#
#
#
sub pdPrintSummaryHTML($\@\%\%$)
{
    my($header, $col, $title, $result, $idx) = @_;
    my($s, $m);

    vLogHTML("<HR>\n<TABLE BORDER=1><CAPTION>$header</CAPTION>\n<TR>");
    vLogHTML("<TH>P/F</TH>");
    foreach(@$col) {
        vLogHTML("<TH>$_</TH>")
    }
    vLogHTML("<TH>JDG</TH>");
    vLogHTML("</TR>\n");

    foreach(0..$idx) {
        vLogHTML("<TR>");
        $m = '*';
        if($$result{$_} == $V6evalTool::exitPass) {
            $m = ' ';
            $s = 'PASS';
        } elsif($$result{$_} == $V6evalTool::exitFail) {
            $s = 'FAIL';
        } elsif ($$result{$_} == $V6evalTool::exitDC) {
            $s = "Don't Care";
        } elsif ($$result{$_} == $V6evalTool::exitNS) {
            $s = 'Not supported';
        } elsif ($$result{$_} == $V6evalTool::exitWarn) {
            $s = 'WARN';
        } else {
            $s = '???';
        }
        if($m eq '*') {
            vLogHTML("<TD><FONT SIZE=\"+3\" COLOR=\"#FF0000\">$m</FONT></TD>");
        } else {
            vLogHTML("<TD><BR></TD>");
        }
        vLogHTML("$$title{$_}");
        vLogHTML("<TD><A HREF=\"#T$_\">$s</A></TD>");
        vLogHTML("</TR>\n");
    }
    vLogHTML("</TABLE>\n");
}

#
#
#
sub pdSetTimeDUIDLLT()
{
    #
    # Time of DUID-LLT (32bit)
    # time is Jan 1, 2000 (UTC), modulo 2^32
    $t64 = time() - 946684800;
    $sid_duid_Time = ($t64 & 0xffffffff);

    print "Server's time of DUID-LLT: $sid_duid_Time\n";

    open(OUT, ">./time.def") || return 1;

    printf OUT "#define SID_DUID_TIME $sid_duid_Time\n";

    close(OUT);
    return 0;
}

#
#DHCPv6 spec
#14. Reliability of Client Initiated Message Exchanges
#
#      RT     Retransmission timeout
#      IRT    Initial retransmission time
#      MRC    Maximum retransmission count
#      MRT    Maximum retransmission time
#      MRD    Maximum retransmission duration
#      RAND   Randomization factor between -0.1 and +0.1
#
sub pdRetransmitTimer($$$)
{
    my($IRT, $MRT, $RT) = @_;

    $maxRAND = 0.1;

    if ($RT == 0){
#   RT for the first message transmission is based on IRT:
#   RT = $IRT + $RAND * $IRT;
        $maxRT = $IRT + $maxRAND * $IRT;
    }
    else{
#   RT for each subsequent message transmission is based on the previous
#   value of RT: RT = 2 * $RTprev + $RAND * $RTprev;
        $maxRT = 2 * $RT + $maxRAND * $RT;
    }

#      MRT specifies an upper bound on the value of RT (disregarding the
#      randomization added by the use of RAND). If MRT has a value of 0,
#      there is no upper limit on the value of RT. Otherwise:
#      if ($RT > $MRT){
#         $RT = $MRT + $RAND * $MRT;
#      }

    if ($MRT != 0){
        if ($maxRT > $MRT){
            $maxRT = $MRT + $maxRAND * $MRT;
        }
    }
    return($maxRT);
}
#
# 
#
sub pdSetVCPP($$$$$@@\%)
{
    my ($dhcpmsgtyp,
        $delegateprefix,
        $preferredlifetime,
        $validlifetime,
        $maxcount,
        @sidtime,
        @sidlinkaddr,  ## This is dummy
        %ret)=@_;      ## This is dummy

    my (
	$cid_duid_type,
	$cid_duid_Hardwaretype,
	$cid_duid_time,
	$cid_duid_linklayeraddress,
	@sid_duid_time,
	@sid_duid_linklayeraddress,
	$VCPP
	);

    foreach($count = 0; $count < $maxcount; $count++){
       	$sid_duid_time[$count]             = $sidtime[$count];
        $sid_duid_linklayeraddress[$count] = $sidtime[$maxcount+$count];
        if($count == 0){
           print "SID_DUID_TIME : $sid_duid_time[$count], SID_DUID_LinkLayerAddress : $sid_duid_linklayeraddress[$count]\n" if $debug;
	}else{
	   print "SID_DUID_TIME$count: $sid_duid_time[$count], SID_DUID_LinkLayerAddress$count: $sid_duid_linklayeraddress[$count]\n" if $debug;
	}
    }

    foreach($count = 2*$maxcount ; $count < $#sidtime; $count+=2){
        $ret{$sidtime[$count]} = $sidtime[$count+1];
    }

    if($dhcpmsgtyp eq $INITIAL){
        $dhcp_id                   = $DHCPID;
        $cid_duid_type             = $TYPE;
        $cid_duid_hardwaretype     = $HARDWARETYPE;
        $cid_duid_time             = $TIME;
        $cid_duid_linklayeraddress = $LINKLAYERADDRESS;
        $iaid                      = $IAID;
    }
    elsif($dhcpmsgtyp eq $REPLY){
	$DHCPTYPE="Frame_Ether.Packet_IPv6.Upp_UDP.Udp_DHCPv6_Reply";
        $dhcp_id                   = $DHCPID;
        $iaid                      = $ret{$DHCPTYPE . '.Opt_DHCPv6_IA_PD.Identifier'};
	if($ret{$DHCPTYPE . '.Opt_DHCPv6_CID.DHCPv6_DUID_LLT_Ether.Type'}){
        	$cid_duid_type             = $ret{$DHCPTYPE . '.Opt_DHCPv6_CID.DHCPv6_DUID_LLT_Ether.Type'};
	        $cid_duid_hardwaretype     = $ret{$DHCPTYPE . '.Opt_DHCPv6_CID.DHCPv6_DUID_LLT_Ether.HardwareType'};
		$cid_duid_time             = $ret{$DHCPTYPE . '.Opt_DHCPv6_CID.DHCPv6_DUID_LLT_Ether.Time'};
		$cid_duid_linklayeraddress = $ret{$DHCPTYPE . '.Opt_DHCPv6_CID.DHCPv6_DUID_LLT_Ether.LinkLayerAddress'};
	}
	elsif($ret{$DHCPTYPE . '.Opt_DHCPv6_CID.DHCPv6_DUID_LL_Ether.Type'}){
		$cid_duid_type  = $ret{$DHCPTYPE . '.Opt_DHCPv6_CID.DHCPv6_DUID_LL_Ether.Type'};
		$cid_duid_hardwaretype     = $ret{$DHCPTYPE . '.Opt_DHCPv6_CID.DHCPv6_DUID_LL_Ether.HardwareType'};
		$cid_duid_time             = $TIME;
		$cid_duid_linklayeraddress = $ret{$DHCPTYPE . '.Opt_DHCPv6_CID.DHCPv6_DUID_LL_Ether.LinkLayerAddress'};
	}
    }
    elsif($dhcpmsgtyp eq $ADVERTISE){
	$DHCPTYPE="Frame_Ether.Packet_IPv6.Upp_UDP.Udp_DHCPv6_Advertise";
        $dhcp_id                   = $ret{$DHCPTYPE . '.Identifier'};
        $iaid                      = $ret{$DHCPTYPE . '.Opt_DHCPv6_IA_PD.Identifier'};
	if($ret{$DHCPTYPE . '.Opt_DHCPv6_CID.DHCPv6_DUID_LLT_Ether.Type'}){
		$cid_duid_type             = $ret{$DHCPTYPE . '.Opt_DHCPv6_CID.DHCPv6_DUID_LLT_Ether.Type'};
		$cid_duid_hardwaretype     = $ret{$DHCPTYPE . '.Opt_DHCPv6_CID.DHCPv6_DUID_LLT_Ether.HardwareType'};
		$cid_duid_time             = $ret{$DHCPTYPE . '.Opt_DHCPv6_CID.DHCPv6_DUID_LLT_Ether.Time'};
		$cid_duid_linklayeraddress = $ret{$DHCPTYPE . '.Opt_DHCPv6_CID.DHCPv6_DUID_LLT_Ether.LinkLayerAddress'};
	}
	elsif($ret{$DHCPTYPE . '.Opt_DHCPv6_CID.DHCPv6_DUID_LL_Ether.Type'}){
		$cid_duid_type  = $ret{$DHCPTYPE . '.Opt_DHCPv6_CID.DHCPv6_DUID_LL_Ether.Type'};
		$cid_duid_hardwaretype     = $ret{$DHCPTYPE . '.Opt_DHCPv6_CID.DHCPv6_DUID_LL_Ether.HardwareType'};
		$cid_duid_time             = $TIME;
		$cid_duid_linklayeraddress = $ret{$DHCPTYPE . '.Opt_DHCPv6_CID.DHCPv6_DUID_LL_Ether.LinkLayerAddress'};
	}
    }
    elsif($dhcpmsgtyp eq $SOLICIT){
	$DHCPTYPE="Frame_Ether.Packet_IPv6.Upp_UDP.Udp_DHCPv6_Solicit";
        $dhcp_id                   = $ret{$DHCPTYPE . '.Identifier'};
        $iaid                      = $ret{$DHCPTYPE . '.Opt_DHCPv6_IA_PD.Identifier'};
	if($ret{$DHCPTYPE . '.Opt_DHCPv6_CID.DHCPv6_DUID_LLT_Ether.Type'}){
		$cid_duid_type  = $ret{$DHCPTYPE . '.Opt_DHCPv6_CID.DHCPv6_DUID_LLT_Ether.Type'};
		$cid_duid_hardwaretype     = $ret{$DHCPTYPE . '.Opt_DHCPv6_CID.DHCPv6_DUID_LLT_Ether.HardwareType'};
		$cid_duid_time             = $ret{$DHCPTYPE . '.Opt_DHCPv6_CID.DHCPv6_DUID_LLT_Ether.Time'};
		$cid_duid_linklayeraddress = $ret{$DHCPTYPE . '.Opt_DHCPv6_CID.DHCPv6_DUID_LLT_Ether.LinkLayerAddress'};
	}
	elsif($ret{$DHCPTYPE . '.Opt_DHCPv6_CID.DHCPv6_DUID_LL_Ether.Type'}){
		$cid_duid_type  = $ret{$DHCPTYPE . '.Opt_DHCPv6_CID.DHCPv6_DUID_LL_Ether.Type'};
		$cid_duid_hardwaretype     = $ret{$DHCPTYPE . '.Opt_DHCPv6_CID.DHCPv6_DUID_LL_Ether.HardwareType'};
		$cid_duid_time             = $TIME;
		$cid_duid_linklayeraddress = $ret{$DHCPTYPE . '.Opt_DHCPv6_CID.DHCPv6_DUID_LL_Ether.LinkLayerAddress'};
	}
    }
    elsif($dhcpmsgtyp eq $INFORMATIONREQUEST){
	$DHCPTYPE="Frame_Ether.Packet_IPv6.Upp_UDP.Udp_DHCPv6_InformationRequest";
        $dhcp_id                   = $ret{$DHCPTYPE . '.Identifier'};
        $iaid                      = $IAID;
	if($ret{$DHCPTYPE . '.Opt_DHCPv6_CID.DHCPv6_DUID_LLT_Ether.Type'}){
		$cid_duid_type             = $ret{$DHCPTYPE . '.Opt_DHCPv6_CID.DHCPv6_DUID_LLT_Ether.Type'};
		$cid_duid_hardwaretype     = $ret{$DHCPTYPE . '.Opt_DHCPv6_CID.DHCPv6_DUID_LLT_Ether.HardwareType'};
		$cid_duid_time             = $ret{$DHCPTYPE . '.Opt_DHCPv6_CID.DHCPv6_DUID_LLT_Ether.Time'};
		$cid_duid_linklayeraddress = $ret{$DHCPTYPE . '.Opt_DHCPv6_CID.DHCPv6_DUID_LLT_Ether.LinkLayerAddress'};
	}
	elsif($ret{$DHCPTYPE . '.Opt_DHCPv6_CID.DHCPv6_DUID_LL_Ether.Type'}){
		$cid_duid_type  = $ret{$DHCPTYPE . '.Opt_DHCPv6_CID.DHCPv6_DUID_LL_Ether.Type'};
		$cid_duid_hardwaretype     = $ret{$DHCPTYPE . '.Opt_DHCPv6_CID.DHCPv6_DUID_LL_Ether.HardwareType'};
		$cid_duid_time             = $TIME;
		$cid_duid_linklayeraddress = $ret{$DHCPTYPE . '.Opt_DHCPv6_CID.DHCPv6_DUID_LL_Ether.LinkLayerAddress'};
	}
    }
    elsif($dhcpmsgtyp eq $REBIND){
	$DHCPTYPE="Frame_Ether.Packet_IPv6.Upp_UDP.Udp_DHCPv6_Rebind";
        $dhcp_id                   = $ret{$DHCPTYPE . '.Identifier'};
        $iaid                      = $ret{$DHCPTYPE . '.Opt_DHCPv6_IA_PD.Identifier'};
	if($ret{$DHCPTYPE . '.Opt_DHCPv6_CID.DHCPv6_DUID_LLT_Ether.Type'}){
		$cid_duid_type             = $ret{$DHCPTYPE . '.Opt_DHCPv6_CID.DHCPv6_DUID_LLT_Ether.Type'};
		$cid_duid_hardwaretype     = $ret{$DHCPTYPE . '.Opt_DHCPv6_CID.DHCPv6_DUID_LLT_Ether.HardwareType'};
		$cid_duid_time             = $ret{$DHCPTYPE . '.Opt_DHCPv6_CID.DHCPv6_DUID_LLT_Ether.Time'};
		$cid_duid_linklayeraddress = $ret{$DHCPTYPE . '.Opt_DHCPv6_CID.DHCPv6_DUID_LLT_Ether.LinkLayerAddress'};
	}
	elsif($ret{$DHCPTYPE . '.Opt_DHCPv6_CID.DHCPv6_DUID_LL_Ether.Type'}){
		$cid_duid_type  = $ret{$DHCPTYPE . '.Opt_DHCPv6_CID.DHCPv6_DUID_LL_Ether.Type'};
		$cid_duid_hardwaretype     = $ret{$DHCPTYPE . '.Opt_DHCPv6_CID.DHCPv6_DUID_LL_Ether.HardwareType'};
		$cid_duid_time             = $TIME;
		$cid_duid_linklayeraddress = $ret{$DHCPTYPE . '.Opt_DHCPv6_CID.DHCPv6_DUID_LL_Ether.LinkLayerAddress'};
	}
    }
    else{
        if($dhcpmsgtyp eq $REQUEST){
	   $DHCPTYPE="Frame_Ether.Packet_IPv6.Upp_UDP.Udp_DHCPv6_Request";
        }
        elsif($dhcpmsgtyp eq $RENEW){
	   $DHCPTYPE="Frame_Ether.Packet_IPv6.Upp_UDP.Udp_DHCPv6_Renew";
        }
        elsif($dhcpmsgtyp eq $RELEASE){
	   $DHCPTYPE="Frame_Ether.Packet_IPv6.Upp_UDP.Udp_DHCPv6_Release";
        }
        $dhcp_id                   = $ret{$DHCPTYPE . '.Identifier'};
        $iaid                      = $ret{$DHCPTYPE . '.Opt_DHCPv6_IA_PD.Identifier'};
	if($ret{$DHCPTYPE . '.Opt_DHCPv6_CID.DHCPv6_DUID_LLT_Ether.Type'}){
		$cid_duid_type             = $ret{$DHCPTYPE . '.Opt_DHCPv6_CID.DHCPv6_DUID_LLT_Ether.Type'};
		$cid_duid_hardwaretype     = $ret{$DHCPTYPE . '.Opt_DHCPv6_CID.DHCPv6_DUID_LLT_Ether.HardwareType'};
		$cid_duid_time             = $ret{$DHCPTYPE . '.Opt_DHCPv6_CID.DHCPv6_DUID_LLT_Ether.Time'};
		$cid_duid_linklayeraddress = $ret{$DHCPTYPE . '.Opt_DHCPv6_CID.DHCPv6_DUID_LLT_Ether.LinkLayerAddress'};
	}
	elsif($ret{$DHCPTYPE . '.Opt_DHCPv6_CID.DHCPv6_DUID_LL_Ether.Type'}){
		$cid_duid_type  = $ret{$DHCPTYPE . '.Opt_DHCPv6_CID.DHCPv6_DUID_LL_Ether.Type'};
		$cid_duid_hardwaretype     = $ret{$DHCPTYPE . '.Opt_DHCPv6_CID.DHCPv6_DUID_LL_Ether.HardwareType'};
		$cid_duid_time             = $TIME;
		$cid_duid_linklayeraddress = $ret{$DHCPTYPE . '.Opt_DHCPv6_CID.DHCPv6_DUID_LL_Ether.LinkLayerAddress'};
	}
        $sid_duid_time[0]             = $ret{$DHCPTYPE . '.Opt_DHCPv6_SID.DHCPv6_DUID_LLT_Ether.Time'};
        $sid_duid_linklayeraddress[0] = $ret{$DHCPTYPE . '.Opt_DHCPv6_SID.DHCPv6_DUID_LLT_Ether.LinkLayerAddress'};
    }

    $prefer = $preferredlifetime; 
    $valid  = $validlifetime;
    $t1 = $prefer*0.5;
    $t2 = $prefer*0.8;

    $VCPP  ="-DDHCP_ID=$dhcp_id -DCID_DUID_TYPE=$cid_duid_type ";
    $VCPP .="-DCID_DUID_HARDWARETYPE=$cid_duid_hardwaretype ";
    $VCPP .="-DCID_DUID_TIME=$cid_duid_time ";
    $VCPP .="-DCID_DUID_LINKLAYERADDRESS=\\\"$cid_duid_linklayeraddress\\\" ";
    $VCPP .="-DIAID=$iaid ";
    $VCPP .="-DCONTACTTIME_T1=$t1 ";
    $VCPP .="-DCONTACTTIME_T2=$t2 ";
    $VCPP .="-DADVPREFERREDLIFETIME=$prefer ";
    $VCPP .="-DADVVALIDLIFETIME=$valid ";
    $VCPP .="-DDELEGATEPREFIX=\\\"$delegateprefix\\\" ";
    foreach($count = 0; $count < $maxcount; $count++){
        if($count == 0){
	    $VCPP .="-DSID_DUID_TIME=$sid_duid_time[$count] ";
	    $VCPP .="-DSID_DUID_LINKLAYERADDRESS=\\\"$sid_duid_linklayeraddress[$count]\\\" ";
	    $VCPP .="-DTNMACADDR=\\\"$sid_duid_linklayeraddress[$count]\\\" ";
	}
	else{
	    $VCPP .="-DSID_DUID_TIME$count=$sid_duid_time[$count] ";
	    $VCPP .="-DSID_DUID_LINKLAYERADDRESS$count=\\\"$sid_duid_linklayeraddress[$count]\\\" ";
	    $VCPP .="-DTNMACADDR$count=\\\"$sid_duid_linklayeraddress[$count]\\\" ";
	}
    }
    
    print "VCPP: $VCPP\n" if $debug;

    return($VCPP);
}

 
#
#
#
sub pdCheckRA($$%)
{
    my ($delegateprefix, $validlifetime, %ret)=@_;
    my (
	$ra_prefix_len,
	$ra_prefix,
	$ra_vlifetime
	);

    $ra = "Frame_Ether.Packet_IPv6.ICMPv6_RA.Opt_ICMPv6_Prefix";
    $DELEGATEDPREFIXLEN=48;

    $i="";
    $b=0;
    $count=0;
    $lcount=0;
    $ncount=0;

    chop($delegateprefix);
    chomp($delegateprefix);

    foreach $i (%ret){ 
        if ($i eq $ra){
            $ra_prefix_len{$b} = $ret{$ra . '.PrefixLength'};
            $ra_prefix{$b}     = $ret{$ra . '.Prefix'};
            $ra_vlifetime{$b}  = $ret{$ra . '.ValidLifetime'};
            vLogHTML("Received prefix is $ra_prefix{$b} and validlifetime is $ra_vlifetime{$b}.<BR>");
            if ($ra_prefix{$b} =~ /$delegateprefix/){
                if ($ra_vlifetime{$b} <= $validlifetime) {
                    if ($ra_prefix_len{$b} > $DELEGATEDPREFIXLEN) {
                        vLogHTML("Prefix $ra_prefix{$b}'s ValidLifetime is less than $validlifetime.<BR>") if $debug;
                        vLogHTML("Prefix length is longer than $DELEGATEDPREFIXLEN.<BR>") if $debug;
                    }else{
                        vLogHTML("Prefix length should be longer than $DELEGATEDPREFIXLEN.<BR>") if $debug;
                        $count +=1;
                    }
                }
                else{
                    vLogHTML("Received prefix $ra_prefix{$b} has invalid ValidLifetime .<BR>") if $debug;
                    $lcount +=1;
                    if ($ra_prefix_len{$b} > $DELEGATEDPREFIXLEN) {
                        vLogHTML("Prefix length is longer than $DELEGATEDPREFIXLEN.<BR>") if $debug;
                    }else{
                        vLogHTML("Prefix length should be longer than $DELEGATEDPREFIXLEN.<BR>") if $debug;
                        $count +=1;
                    }
                } 
                $ncount +=1;
            }else{
                vLogHTML("N/A: Received prefix $ra_prefix{$b} may be old one.<BR>");
            } 
            $b +=2;
        }elsif($i eq "$ra$b"){
            $ra_prefix_len{$b} = $ret{$ra . "$b" . '.PrefixLength'};
            $ra_prefix{$b}     = $ret{$ra . "$b" . '.Prefix'};
            $ra_vlifetime{$b}  = $ret{$ra . "$b" . '.ValidLifetime'};
            vLogHTML("Received number $b prefix is $ra_prefix{$b} and validlifetime is $ra_vlifetime{$b}.<BR>");
            if ($ra_prefix{$b} =~ /$delegateprefix/)
            {
                if ($ra_vlifetime{$b} <= $validlifetime) {
                    if ($ra_prefix_len{$b} > $DELEGATEDPREFIXLEN) {
                        vLogHTML("Prefix $ra_prefix{$b}'s ValidLifetime is less than $validlifetime.<BR>") if $debug;
                        vLogHTML("Prefix length is longer than $DELEGATEDPREFIXLEN.<BR>") if $debug;
                    }else{
                        vLogHTML("Prefix length should be longer than $DELEGATEDPREFIXLEN.<BR>") if $debug;
                        $count +=1;
                    }
                }
                else{
                    vLogHTML("Received prefix $ra_prefix{$b} has invalid ValidLifetime .<BR>") if $debug;
                    $lcount +=1;
                    if ($ra_prefix_len{$b} > $DELEGATEDPREFIXLEN) {
                        vLogHTML("Prefix length is longer than $DELEGATEDPREFIXLEN.<BR>") if $debug;
                    }else{
                        vLogHTML("Prefix length should be longer than $DELEGATEDPREFIXLEN.<BR>") if $debug;
                        $count +=1;
                    }
                } 
                $ncount +=1;
            }else{
                vLogHTML("N/A: Received number $b prefix $ra_prefix{$b} may be old one.<BR>");
            } 
            $b ++;
        }
    }
    if ( $ncount != 0){
        if ( $lcount == 0){ ## Prefix ValidLifetime is valid 
            if( $count == 0) {
               return(0); ## Prefix Length is valid
            }else{
               return(2); ## Prefix Length is invalid
            }
        }
        else{ ## Prefix ValidLifetime is invalid
            if( $count == 0) {
               return(1); ## Prefix Length is valid
            }else{
               return(3); ## Prefix Length is invalid
            }
        }
    }
    else{ ## Prefix is not much
        return(-1);
    }
}

#
#
#
sub pdStopRA()
{
    vLogHTML("Stop router advertisement process of NUT<BR>");
    vRemote("rtadvd.rmt",
            $remote_debug,
            stop,
            ) && return(1);
    vSleep($wait_ra, "Wait $wait_ra sec to ignore RAs w/ RouterLifetime=0");
    return(0);
}

#
#
#
sub pdStartDefaultRA()
{
    my(@links)=pdGetLinkDev();

    $system=$V6evalTool::NutDef{System};
    if($system eq "cisco-ios") {
        vLogHTML("This function doesn't need for the cisco-ios<BR>");
        return(1);
    }

    pdStopRA();

    vLogHTML("Start router advertisement process of NUT<BR>");
    vRemote("rtadvd.rmt",
            $remote_debug,
            start,
            @links
            ) && return(0); 
    return(1);
}


########################################################################
1;
__END__
########################################################################

=head1 NAME

=begin html
<PRE>
  <A HREF="./pd.pm">pd.pm</A> - utility functions for IPv6 Prefix Options for DHCPv6 test
</PRE>

=end html

=head1 SYNOPSIS

  pdReboot()

=head1 DESCRIPTION

  pdReboot() - reboot target

    This routine calls vRemote("reboot.rmt") simply.

=head1 SEE ALSO

  perldoc V6EvalTool
  perldoc V6Remote

=cut


