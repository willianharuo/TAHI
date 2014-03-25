#
# Copyright (C) 2002, 2003 Yokogawa Electric Corporation, 
# INTAP(Interoperability Technology Association for Information 
# Processing, Japan), IPA (Information-technology Promotion Agency, Japan).
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
# $TINY: PMTU.pm,v 1.4 2002/03/05 02:59:09 masaxmasa Exp $
# 

########################################################################
package PMTU;

use Exporter;
@ISA = qw(Exporter);
@EXPORT = qw(rebootNUT
	     initNUT
	     sendNA
	     flushtables
             );

use V6evalTool;

BEGIN { }
END { }

$ON=1;
$OFF=0;
$remote_debug="";
$TN_GlobalAddr="3ffe:501:ffff:109::1";
$OFFLink_prefix="3ffe:501:ffff:109::";
$OFFLink_prefixlen="64";
$pxlen="64";
$DSTpxlen="64";
$DSTpx="default";
$NUTPREFIX="3ffe:501:ffff:100::";
$DEFROUTE="fe80::200:ff:fe00:a0a0";

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

$LCNA_RESULTS="./lcna_results";  # Test results to make summary lcna tests


#
# Reboot the NUT
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
# Initialize the NUT
#
sub initNUT() {
    vLogHTML("Initialize the NUT.");

    $if_nut = $V6evalTool::NutDef{Link0_device};
    
    
    $IF = Link0;
    
    
    #======================================================================
    # Check NUT Global Address
    
    %status = vSend($IF, addr_check_pkt);
    
    $nutaddr = $status{"Frame_Ether.Packet_IPv6.Hdr_IPv6.DestinationAddress"};
    $defroute = $status{"Frame_Ether.Packet_IPv6.Hdr_IPv6.SourceAddress"};
    
    
    $ret = vRemote(
    	'manualaddrconf.rmt',
    	"if=$if_nut",
    	"addr=$nutaddr",
    	"len=$pxlen",
    	'type=unicast'
    );
    
    if ($ret) {
    	vLogHTML('<FONT COLOR="#FF0000">NG</FONT>');
    	exit $V6evalTool::exitFatal;
    }
    
    $ret = vRemote(
    	'route.rmt',
    	'cmd=add',
    	"if=$if_nut",
    	"prefix=$DSTpx",
    	"prefixlen=$DSTpxlen",
    	"gateway=$defroute",
    );
    
    if ($ret) {
    	vLogHTML('<FONT COLOR="#FF0000">NG</FONT>');
    	exit $V6evalTool::exitFatal;
    }
    
# Wait to finish DAD
    vSleep(10);
    
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


sub flushtables ($) {
	my ( $targettype ) = @_ ;
	my ( $rret );

	if( $targettype eq "kame-freebsd" ){
		$rret=vRemote("cleardefr.rmt","","timeout=5");
		vLog("cleardefr.rmt returned status $rret");
 
		$rret=vRemote("clearroute.rmt","","timeout=5");
		vLog("clearroute.rmt returned status $rret");

		$rret=vRemote("clearnc.rmt","","timeout=5");
		vLog("clearnc.rmt returned status $rret");

		$rret=vRemote("clearprefix.rmt","","timeout=5");
		vLog("clearprefix.rmt returned status $rret");

	}else{
		rebootNUT();
		vLog("OK! Let's go ahead!");

	} 
	return $V6evalTool::exitIgnore;
}

1;		# return value

########################################################################
__END__

=head1 NAME

	PMTU.pm - functions for Path MTU test

=head1 DESCRIPTION

	sub routine for Path MTU test

=cut
