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
# $TAHI: ct/dd/dd.pm,v 1.3 2003/04/22 04:04:45 akisada Exp $
#

package dd;
use Exporter;
@ISA = qw(Exporter);

use 5;
use V6evalTool;

@EXPORT = qw(
	     ddGetLinkDev
             ddGetLinkDevs
             ddOptions
             ddStopDHCP6Client
             ddSetDHCP6Client
             ddStartDHCP6Client
             ddSetInfoReqDHCP6Client
             ddStartInfoReqDHCP6Client
             ddPing
             ddAsyncWait
             ddRetransmitTimer
	     ddErrmsg
	     ddWarnmsg
             ddReboot
             ddRebootAsync
	     ddPrintSummaryHTML
	     ddSetTimeDUIDLLT
	     ddSetVCPP
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
# Initial value
# 
$wait_dadns = 130;         # 120[sec]  for kame to remote reboot
$wait_rs    = 5;           #   5[sec]? time since sending RA to DADNS for Global
$wait_dadns_ra = 5;        #   5[sec]  for address config by RA
$RetransTimerSec = 1;      # NUT Variable: RetransTimer/1000 [sec]
#
# Router constants
$AdvValidLifetime     = 7200; # sec. (2 hours)
$AdvPreferredLifetime = 3600; # sec. (1 hours)
#
# DHCP parametor
$TIMEOUT = 60;
#
# DHCP client configuration parameter
$DHCPID = 0;
$TYPE = 0;
$HARDWARETYPE = 0;
$TIME = 0;
$LINKLAYERADDRESS = "0:0:0:0:0:0";
$IAID = 0;
#
$iaid=$IAID;
$domain_name_servers="domain-name-servers";
#
$INITIAL = 0;
#
$FEM_UDP="Frame_Ether.Packet_IPv6.Upp_UDP";
$FEM_SRC_ADDR="Frame_Ether.Packet_IPv6.Hdr_IPv6.SourceAddress";
$FEM_DST_ADDR="Frame_Ether.Packet_IPv6.Hdr_IPv6.DestinationAddress";
$FEM_ICMP="Frame_Ether.Packet_IPv6.ICMPv6_EchoRequest";
$FEM_NS_TGTADDR="Frame_Ether.Packet_IPv6.ICMPv6_NS.TargetAddress";
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
#DNS retry counter and timeouts
#RFC 1536            Common DNS Implementation Errors        October 1993
#A GOOD IMPLEMENTATION:
#
#   BIND (we looked at versions 4.8.3 and 4.9) implements a good
#   retransmission algorithm which solves or limits all of these
#   problems.  The Berkeley stub-resolver queries servers at an interval
#   that starts at the greater of 4 seconds and 5 seconds divided by the
#   number of servers the resolver queries. The resolver cycles through
#   servers and at the end of a cycle, backs off the time out
#   exponentially.
#
#   The Berkeley full-service resolver (built in with the program
#   "named") starts with a time-out equal to the greater of 4 seconds and
#   two times the round-trip time estimate of the server.  The time-out
#   is backed off with each cycle, exponentially, to a ceiling value of
#   45 seconds.
#
#FIXES:
#
#      a. Estimate round-trip times or set a reasonably high initial
#         time-out.
#
#      b. Back-off timeout periods exponentially.
#
#      c. Yet another fundamental though difficult fix is to send the
#         client an acknowledgement of a query, with a round-trip time
#         estimate.
#

#======================================================================
# BEGIN - read dd_addr.def
#======================================================================
BEGIN {
        open (FILE, "dd_addr.def") || die "Cannot open $!\n";
        while ( <FILE> ) {
                if ( /^#define\s+(\S+)\s+(\S+)/ ) {
                        #print  $1 . " " . $2 . "\n";
                        $DNS{$1} = $2;
                }
        }
        close FILE;
}

#
#
#
END
{}

#
#
#
sub ddGetLinkDev()
{
    my(@dev)=();
    foreach(keys(%V6evalTool::NutDef)) {
        if(/^Link0_device$/) {
            my($v)=$V6evalTool::NutDef{$_};
            push(@dev, "if=$v");
            last;
        }
    }
    @dev;
}

#
#
#
sub ddGetLinkDevs()
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
sub ddOptions(@)
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
sub ddStopDHCP6Client()
{
    vLogHTML("Stop dhcp client process of NUT<BR>");
    $ret = vRemote("dhcp6c.rmt",
            $remote_debug,
            stop,
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
sub ddSetDHCP6Client()
{
    my(@links)=ddGetLinkDevs();

    vRemote("dhcp6c.rmt",
            $remote_debug,
            set,
            "iaid=$iaid",
            @links
            ) && return(0);

    return(1);
}

#
#
#
sub ddStartDHCP6Client()
{
    my(@links)=ddGetLinkDevs();

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
sub ddSetInfoReqDHCP6Client()
{
    my(@links)=ddGetLinkDevs();

    vRemote("dhcp6c.rmt",
            $remote_debug,
            set,
            inforeq,
            "requestoptions=$domain_name_servers",
            @links
            ) && return(0);
    return(1);
}

#
#
#
sub ddStartInfoReqDHCP6Client()
{
    my(@links)=ddGetLinkDevs();

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
# Ping6 from NUT to the host address
#
sub ddPing($)
{
    my($ping_dst_addr)=@_;
    my($link)=ddGetLinkDev();

    vRemoteAsync("ping6.rmt",
            "",
            "$link addr=$ping_dst_addr"
            );
    if($ret == 0){
       return(1);
    }else{
       vLogHTML("<FONT COLOR=\"#FF0000\">Fail: vRemoteAsync error number $ret</FONT>");
       return(0);
    }
}


#
# ddAsyncWait() - Wait for asynchronous remote script
#
sub ddAsyncWait() {
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
sub ddErrmsg($)
{
    my($msg)=@_;
    "<FONT COLOR=\"#FF0000\">$msg</FONT>";
}

#
#
#
sub ddWarnmsg($)
{
    my($msg)=@_;
    "<FONT COLOR=\"#00FF00\">$msg</FONT>";
}

#
#
#
sub ddReboot()
{
    vRemote("reboot.rmt", $remote_debug) && return 1;
    vLogHTML("Target: Reboot<BR>");
    return 0;
}

#
#
#
sub ddRebootAsync()
{
    vRemote("reboot_async.rmt", $remote_debug) && return 1;
    vLogHTML("Target: Reboot<BR>");
    return 0;
}

#
#
#
sub ddPrintSummaryHTML($\@\%\%$)
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
sub ddSetTimeDUIDLLT()
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
sub ddRetransmitTimer($$$)
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
sub ddSetVCPP($$$$@@\%)
{
    my ($dhcpmsgtyp,
        $dnsservers,
        $domainlist,
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

    $VCPP  ="-DDHCP_ID=$dhcp_id -DCID_DUID_TYPE=$cid_duid_type ";
    $VCPP .="-DCID_DUID_HARDWARETYPE=$cid_duid_hardwaretype ";
    $VCPP .="-DCID_DUID_TIME=$cid_duid_time ";
    $VCPP .="-DCID_DUID_LINKLAYERADDRESS=\\\"$cid_duid_linklayeraddress\\\" ";
##    $VCPP .="-DIAID=$iaid ";
##    $VCPP .="-DCONTACTTIME_T1=$t1 ";
##    $VCPP .="-DCONTACTTIME_T2=$t2 ";
##    $VCPP .="-DADVPREFERREDLIFETIME=$prefer ";
##    $VCPP .="-DADVVALIDLIFETIME=$valid ";
##    $VCPP .="-DDELEGATEPREFIX=\\\"$delegateprefix\\\" ";
    if($dnsservers){
      $VCPP .="-DDNS_SRV_ADDR=\\\"$dnsservers\\\" ";
    }
    if($domainlist){
      $VCPP .="-DDNS_DNS_SEARCHLIST=\\\"$domainlist\\\" ";
    }
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

########################################################################
1;
__END__
########################################################################

=head1 NAME

=begin html
<PRE>
  <A HREF="./dd.pm">dd.pm</A> - utility functions for DNS Discovery test
</PRE>

=end html

=head1 SYNOPSIS

  ddReboot()

=head1 DESCRIPTION

  ddReboot() - reboot target

    This routine calls vRemote("reboot.rmt") simply.

=head1 SEE ALSO

  perldoc V6EvalTool
  perldoc V6Remote

=cut


