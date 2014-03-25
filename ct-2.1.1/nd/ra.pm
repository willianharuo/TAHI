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
# $TAHI: ct/nd/ra.pm,v 1.12 2001/10/05 06:39:10 masaxmasa Exp $

package ra;
use Exporter;
@ISA = qw(Exporter);

use 5;
use V6evalTool;
use nd;

@EXPORT = qw(
	     raRecvDefaultRA
	     raRecvMinRA
	     raRecvMaxRA
	     raRecvAnyRA
	     raStopRA
	     raStartDefaultRA
	     raStartDefaultRA2
	     raStartDefaultRA3
	     raStartMinRA
	     raStartMaxRA
	     raIsMarkDefaultRA
	     raIsMarkDefaultRA2
	     );

#
#
#
$markDefaultRA=".default.ra.mark";
$markDefaultRA2=".default.ra2.mark";
$markDefaultRA3=".default.ra3.mark";
$markMinRA=".min.ra.mark";
$markMaxRA=".max.ra.mark";

$defaultRA2minInterval=7;
$defaultRA2maxInterval=10;
$defaultRA2routerLifetime=1800;

$defaultRA3minInterval=1350;
$defaultRA3maxInterval=1800;

$minRAminInterval=7;
$minRAmaxInterval=10;
$minRArouterLifetime=0;
$minRAreachableTime=0;
$minRAretransTimer=0;

$maxRAminInterval=7;
$maxRAmaxInterval=10;
$maxRArouterLifetime=9000;
$maxRAreachableTime=3600000;

$wait_ra=$nd::MIN_DELAY_BETWEEN_RAS * $nd::MAX_FINAL_RTR_ADVERTISEMENTS + 1;

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
sub raRecvDefaultRA($$$$\%)
{
    my($if, $timeout, $recvtime, $count, $rret)=@_;

    $main::pktdesc{RAra_nut2allnode}=
	ndErrmsg("ERROR: Got multicast RA w/o any option");
    $main::pktdesc{RAra_nut2allnode_p}=
	"Got multicast RA w/ Prefix";
    $main::pktdesc{RAra_nut2allnode__p}=
	ndErrmsg("ERROR: Got multicast RA w/ {SLL or MTU}");
    $main::pktdesc{RAra_nut2allnode_sp}=
	"Got multicast RA w/ {SLL and Prefix}";
    $main::pktdesc{RAra_nut2allnode_pm}=
	"Got multicast RA w/ {Prefix and MTU}";
    $main::pktdesc{RAra_nut2allnode_sm}=
	ndErrmsg("ERROR: Got multicast RA w/ {SLL and MTU}");
    $main::pktdesc{RAra_nut2allnode_spm}=
	"Got RA w/ {SLL, Prefix  and MTU}";
    $main::pktdesc{RAra_nut2allnode_any}=
	ndErrmsg("ERROR: Got multicast RA, but unexpected parameters");

    $main::pktdesc{RAra_nut2tn}=
	ndErrmsg("ERROR: Got unicast RA w/o any option");
    $main::pktdesc{RAra_nut2tn_p}=
	"Got RA w/ Prefix";
    $main::pktdesc{RAra_nut2tn__p}=
	ndErrmsg("ERROR: Got unicast RA w/ {SLL or MTU}");
    $main::pktdesc{RAra_nut2tn_sp}=
	"Got unicast RA w/ {SLL and Prefix}";
    $main::pktdesc{RAra_nut2tn_pm}=
	"Got unicast RA w/ {Prefix and MTU}";
    $main::pktdesc{RAra_nut2allnode_sm}=
	ndErrmsg("ERROR: Got unicast RA w/ {SLL and MTU}");
    $main::pktdesc{RAra_nut2tn_spm}=
	"Got unicast RA w/ {SLL, Prefix  and MTU}";
    $main::pktdesc{RAra_nut2tn_any}=
	ndErrmsg("ERROR: Got unicast RA, but unexpected parameters");

    $main::pktdesc{RAns_nut2tnsol_sll}=
	"Got NS w/ SLL";
    $main::pktdesc{RAna_tn2nut_tll}=
	"Send NA w/ TLL";

retry:
    my(%ret)=vRecv($if, $timeout, $recvtime, $count,
		   RAra_nut2allnode,
		   RAra_nut2allnode_p,
		   RAra_nut2allnode__p,
		   RAra_nut2allnode_sp,
		   RAra_nut2allnode_pm,
		   RAra_nut2allnode_sm,
		   RAra_nut2allnode_spm,
		   RAra_nut2allnode_any,

		   RAra_nut2tn,
		   RAra_nut2tn_p,
		   RAra_nut2tn__p,
		   RAra_nut2tn_sp,
		   RAra_nut2tn_pm,
		   RAra_nut2tn_sm,
		   RAra_nut2tn_spm,
		   RAra_nut2tn_any,

		   RAns_nut2tnsol_sll,
	       );
    %$rret=%ret;

    if($ret{status} != 0) {
	vLogHTML("Never got RA<BR>");
	return(0);
    }
    if($ret{recvFrame} eq RAns_nut2tnsol_sll) {
	vSend($if, RAna_tn2nut_tll);
	goto retry;
    }
    if(
       $ret{recvFrame} eq RAra_nut2allnode ||
       $ret{recvFrame} eq RAra_nut2allnode__p ||
       $ret{recvFrame} eq RAra_nut2allnode_sm ||
       $ret{recvFrame} eq RAra_nut2tn ||
       $ret{recvFrame} eq RAra_nut2tn__p ||
       $ret{recvFrame} eq RAra_nut2tn_sm
       ) {
	vLogHTML(ndErrmsg("ERROR: Got RA w/o Prefix option"));
	return(0);
    }
    if($ret{recvFrame} eq RAra_nut2allnode_any ||
       $ret{recvFrame} eq RAra_nut2tn_any) {
	return(0);
    }
    return(1);
}

#
#
#
sub raRecvMinRA($$$$\%)
{
    my($if, $timeout, $recvtime, $count, $rret)=@_;

    $main::pktdesc{RAra_nut2allnode_min}=
	ndErrmsg("ERROR: Got RA w/o any option");
    $main::pktdesc{RAra_nut2allnode_min_p}=
	"Got RA w/ Prefix";
    $main::pktdesc{RAra_nut2allnode_min__p}=
	ndErrmsg("ERROR: Got RA w/ {SLL or MTU}");
    $main::pktdesc{RAra_nut2allnode_min_sp}=
	"Got RA w/ {SLL and Prefix}";
    $main::pktdesc{RAra_nut2allnode_min_pm}=
	"Got RA w/ {Prefix and MTU}";
    $main::pktdesc{RAra_nut2allnode_min_sm}=
	ndErrmsg("ERROR: Got RA w/ {SLL and MTU}");
    $main::pktdesc{RAra_nut2allnode_min_spm}=
	"Got RA w/ {SLL, Prefix  and MTU}";
    $main::pktdesc{RAra_nut2allnode_any}=
	ndErrmsg("ERROR: Got RA, but unexpected parameters");
    my(%ret)=vRecv($if, $timeout, $recvtime, $count,
		   RAra_nut2allnode_min,
		   RAra_nut2allnode_min_p,
		   RAra_nut2allnode_min__p,
		   RAra_nut2allnode_min_sp,
		   RAra_nut2allnode_min_pm,
		   RAra_nut2allnode_min_sm,
		   RAra_nut2allnode_min_spm,
		   RAra_nut2allnode_any,
	       );
    %$rret=%ret;

    if($ret{status} != 0) {
	vLogHTML("Never got RA<BR>");
	return(0);
    }
    if($ret{recvFrame} eq RAra_nut2allnode_min ||
       $ret{recvFrame} eq RAra_nut2allnode_min__p ||
       $ret{recvFrame} eq RAra_nut2allnode_min_sm) {
	vLogHTML(ndErrmsg("ERROR: Got RA w/o Prefix option"));
	return(0);
    }
    if($ret{recvFrame} eq RAra_nut2allnode_any) {
	return(0);
    }
    return(1);
}

#
#
#
sub raRecvMaxRA($$$$\%)
{
    my($if, $timeout, $recvtime, $count, $rret)=@_;

    $main::pktdesc{RAra_nut2allnode_max}=
	ndErrmsg("ERROR: Got RA w/o any option");
    $main::pktdesc{RAra_nut2allnode_max_p}=
	"Got RA w/ Prefix";
    $main::pktdesc{RAra_nut2allnode_max__p}=
	ndErrmsg("ERROR: Got RA w/ {SLL or MTU}");
    $main::pktdesc{RAra_nut2allnode_max_sp}=
	"Got RA w/ {SLL and Prefix}";
    $main::pktdesc{RAra_nut2allnode_max_pm}=
	"Got RA w/ {Prefix and MTU}";
    $main::pktdesc{RAra_nut2allnode_max_sm}=
	ndErrmsg("ERROR: Got RA w/ {SLL and MTU}");
    $main::pktdesc{RAra_nut2allnode_max_spm}=
	"Got RA w/ {SLL, Prefix  and MTU}";
    $main::pktdesc{RAra_nut2allnode_any}=
	ndErrmsg("ERROR: Got RA, but unexpected parameters");
    my(%ret)=vRecv($if, $timeout, $recvtime, $count,
		   RAra_nut2allnode_max,
		   RAra_nut2allnode_max_p,
		   RAra_nut2allnode_max__p,
		   RAra_nut2allnode_max_sp,
		   RAra_nut2allnode_max_pm,
		   RAra_nut2allnode_max_sm,
		   RAra_nut2allnode_max_spm,
		   RAra_nut2allnode_any,
	       );
    %$rret=%ret;

    if($ret{status} != 0) {
	vLogHTML("Never got RA<BR>");
	return(0);
    }
    if($ret{recvFrame} eq RAra_nut2allnode_max ||
       $ret{recvFrame} eq RAra_nut2allnode_max__p ||
       $ret{recvFrame} eq RAra_nut2allnode_max_sm) {
	vLogHTML(ndErrmsg("ERROR: Got RA w/o Prefix option"));
	return(0);
    }
    if($ret{recvFrame} eq RAra_nut2allnode_any) {
	return(0);
    }
    return(1);
}

#
#
#
sub raRecvAnyRA($$$$\%)
{
    my($if, $timeout, $recvtime, $count, $rret)=@_;

    $main::pktdesc{RAra_nut2allnode_any}=
	"Got multicast RA";
    $main::pktdesc{RAra_nut2tn_any}=
	"Got unicast RA";

    my(%ret)=vRecv($if, $timeout, $recvtime, $count,
		   RAra_nut2allnode_any,
		   RAra_nut2tn_any,
	       );
    %$rret=%ret;
    if($ret{status} != 0) {
	vLogHTML("Never got RA<BR>");
	return(0);
    }
    return(1);
}

#
#
#
sub raStopRA()
{
    vRemote("rtadvd.rmt",
	    $remote_debug,
	    stop,
	    ) && return(0);
    vSleep($wait_ra, "Wait $wait_ra sec to ignore RAs w/ RouterLifetime=0");
    _clearMark();
    return(1);
}

#
#
#
sub raStartDefaultRA()
{
    my(@links)=ndGetLinkDev();

    raStopRA();

    vRemote("rtadvd.rmt",
	    $remote_debug,
	    start,
	    @links
	    ) && return(0);
    _mkMark($markDefaultRA);
    return(1);
}

#
#
#
sub raStartDefaultRA2()
{
    my(@links)=ndGetLinkDev();

    raStopRA();

    vRemote("rtadvd.rmt",
	    $remote_debug,
	    start,
	    "mininterval=$defaultRA2minInterval",
	    "maxinterval=$defaultRA2maxInterval",
	    "rltime=$defaultRA2routerLifetime",
	    @links
	    ) && return(0);
    _mkMark($markDefaultRA2);
    return(1);
}

#
#
#
sub raStartDefaultRA3()
{
    my(@links)=ndGetLinkDev();

    raStopRA();

    vRemote("rtadvd.rmt",
	    $remote_debug,
	    start,
	    "mininterval=$defaultRA3minInterval",
	    "maxinterval=$defaultRA3maxInterval",
	    @links
	    ) && return(0);
    _mkMark($markDefaultRA3);
    return(1);
}

#
#
#
sub raStartMinRA()
{
    my(@links)=ndGetLinkDev();

    raStopRA();

    vRemote("rtadvd.rmt",
	    $remote_debug,
	    start,
	    "mininterval=$minRAminInterval",
	    "maxinterval=$minRAmaxInterval",
	    "rltime=$minRArouterLifetime",
	    "rtime=$minRAreachableTime",
	    "retrans=$minRAretransTimer",
	    @links
	    ) && return(0);
    _mkMark($markMinRA);
    return(1);
}

#
#
#
sub raStartMaxRA()
{
    my(@links)=ndGetLinkDev();

    raStopRA();

    vRemote("rtadvd.rmt",
	    $remote_debug,
	    start,
	    "mininterval=$maxRAminInterval",
	    "maxinterval=$maxRAmaxInterval",
	    "rltime=$maxRArouterLifetime",
	    "rtime=$maxRAreachableTime",
	    @links
	    ) && return(0);
    _mkMark($markMaxRA);
    return(1);
}

#
#
#
sub raIsMarkDefaultRA()
{
    _isMark($markDefaultRA);
}

#
#
#
sub raIsMarkDefaultRA2()
{
    _isMark($markDefaultRA2);
}

########################################################################

sub _clearMark()
{
    system("rm -f .*.mark");
}

sub _mkMark($)
{
    my($mark)=@_;
    _clearMark();
    if(open(F, "> $mark") == 0) {
	print STDERR "$mark: $!\n";
	exit $V6evalTool::exitFatal
    }
    print F "$mark";
    close(F);
}

sub _isMark($)
{
    my($mark)=@_;
    return(1) if -e $mark;
    return(0);
}

########################################################################
1;
__END__
########################################################################
