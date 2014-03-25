#!/usr/bin/perl
#
# $Inpta02$
#
# $TAHI: ct/router-select/ROUTE.pm,v 1.12 2003/04/22 04:21:23 akisada Exp $
#
########################################################################

package ROUTE;

use Exporter;

@ISA = qw(Exporter);
@EXPORT = qw(
	        SendRecv
	        SendRecvRetFrame
	        SendRecvRT1unreach
	        SendRecvRT2unreach
		flushtables
		reboot
		checkNUT
		seqOK
		seqNG
		seqERROR
		seqExitFATAL
		seqExitWARN
		seqTermination
	    );


@NS_LINK0 = qw(
	ns_nut2tn_sourceLLA_targetLLA_optionSLL
	ns_nut2tn_sourceLLA_targetLLA_nooption
	ns_nut2tn_sourceLLA_targetGA_optionSLL
	ns_nut2tn_sourceLLA_targetGA_nooption
	ns_nut2tn_sourceGA_targetLLA_optionSLL
	ns_nut2tn_sourceGA_targetLLA_nooption
	ns_nut2tn_sourceGA_targetGA_optionSLL
	ns_nut2tn_sourceGA_targetGA_nooption
);

@NS_LINK0_RT1 = qw(
	ns_nut2tn_sourceLLA_targetLLA_optionSLL_RT1
	ns_nut2tn_sourceLLA_targetLLA_nooption_RT1
	ns_nut2tn_sourceGA_targetLLA_optionSLL_RT1
	ns_nut2tn_sourceGA_targetLLA_nooption_RT1
);

@NS_LINK0_RT2 = qw(
	ns_nut2tn_sourceLLA_targetLLA_optionSLL_RT2
	ns_nut2tn_sourceLLA_targetLLA_nooption_RT2
	ns_nut2tn_sourceGA_targetLLA_optionSLL_RT2
	ns_nut2tn_sourceGA_targetLLA_nooption_RT2
);

use V6evalTool;

BEGIN { }
END { }

$ON=1;
$OFF=0;

$PASS=$V6evalTool::exitPass;
$WARN=$V6evalTool::exitWarn;
$FAIL=$V6evalTool::exitFail;
$FATAL=$V6evalTool::exitFatal;

$IF_ID_0="Link0";
$IF_ID_1="Link1";

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
$DAD_TRANSMITS=3; 	        # DupAddrDetectTransmits

$MAX_SOLICIT=3;



$ROUTER_LIFE_TIME=3600;      	# sec.
$ROUTER_LIFE_TIME_ZERO=0;      	# sec.
$ROUTER_LIFE_TIME_SHORTER=20;  	# sec.
$ROUTER_LIFE_TIME_LONGER=40;   	# sec.
$ROUTE_LIFE_TIME_SHORTER=20;   	# sec.
$ROUTE_LIFE_TIME_LONGER=40;    	# sec.
$REACHABLE_TIME_SHORT=20;    	# sec.
$NS_LOOP_MAX=5;			# sec.
$WAIT_DADNS=90;      		# sec.
$MORE_WAIT_RS=10;      		# sec.
#$RA_DELAY=5;   	   		# sec
$RA_DELAY=$RETRANS_TIMER*$DAD_TRANSMITS; # sec
$NA_DELAY=3;   	   		# sec
$LOW=3;   	   		# Preference.
$MED=0;   	   		# Preference.
$HIGH=1;   	   		# Preference.
$UNSPEC=2;   	   		# Preference.
$MAXRTINFO=16;     		# Maximum Num of Route Infomation Option

$wait_ns=$RETRANS_TIMER*$MAX_SOLICIT+1; # margin: 1sec.
$wait_reachable=$REACHABLE_TIME*$MAX_RANDOM_FACTOR+1; # margin: 1sec.
$wait_delay=$DELAY_FIRST_PROBE_TIME+1; # margin: 1sec.
$wait_dad=$RETRANS_TIMER*$DAD_TRANSMITS;
$wait_dadns=10;

$wait_address_resolution=$MAX_MULTICAST_SOLICIT*3+2; # margin: 2sec.

#
#   handle Neighbor Solicitation/Neighbor Advertisement
sub SendRecv ($$$$@) {
    my($IF, $packet, $IF1, @packet1) = @_;
    my $unexpectCntTotal = 0;

    vClear($IF);
    vSend($IF, $packet) if defined($packet);
        
recv_start:
    %ret=vRecv($IF1,3,0,0,@packet1, @NS_LINK0_RT1, @NS_LINK0_RT2);

# First check if we received unexpected packets
    my $unexpectCnt = $ret{recvCount};
    $unexpectCnt-- if($ret{status}==0);
    if($unexpectCnt > 0) {
        vLogHTML("<FONT COLOR=#FF0000>".
                 "Recv $unexpectCnt unexpected packet(s)</FONT><BR>");
        $unexpectCntTotal += $unexpectCnt;
    }

# Then see what else we got
    if ($ret{status} != 0) {
        if (@packet1[0] eq '' && $unexpectCntTotal == 0) {
            return $V6evalTool::exitPass; # Expected no packets and got none
        } else {
            goto recv_fail;
        }
    }
    if ($ret{recvFrame} eq ns_nut2tn_sourceLLA_targetLLA_optionSLL_RT1 || 
	$ret{recvFrame} eq ns_nut2tn_sourceLLA_targetLLA_nooption_RT1) {
        vSend($IF1, na_tn2nut_sourceLLA_destinationLLA_targetLLA_RT1);
        goto recv_start;
    }
    if ($ret{recvFrame} eq ns_nut2tn_sourceLLA_targetGA_optionSLL_RT1 || 
	$ret{recvFrame} eq ns_nut2tn_sourceLLA_targetGA_nooption_RT1) {
        vSend($IF1, na_tn2nut_sourceLLA_destinationLLA_targetGA_RT1);
        goto recv_start;
    }
    if ($ret{recvFrame} eq ns_nut2tn_sourceGA_targetLLA_optionSLL_RT1 || 
	$ret{recvFrame} eq ns_nut2tn_sourceGA_targetLLA_nooption_RT1) {
        vSend($IF1, na_tn2nut_sourceGA_destinationGA_targetLLA_RT1);
        goto recv_start;
    }
    if ($ret{recvFrame} eq ns_nut2tn_sourceGA_targetGA_optionSLL_RT1 || 
	$ret{recvFrame} eq ns_nut2tn_sourceGA_targetGA_nooption_RT1) {
        vSend($IF1, na_tn2nut_sourceGA_destinationGA_targetGA_RT1);
        goto recv_start;
    }

    if ($ret{recvFrame} eq ns_nut2tn_sourceLLA_targetLLA_optionSLL_RT2 || 
	$ret{recvFrame} eq ns_nut2tn_sourceLLA_targetLLA_nooption_RT2) {
        vSend($IF1, na_tn2nut_sourceLLA_destinationLLA_targetLLA_RT2);
        goto recv_start;
    }
    if ($ret{recvFrame} eq ns_nut2tn_sourceLLA_targetGA_optionSLL_RT2 || 
	$ret{recvFrame} eq ns_nut2tn_sourceLLA_targetGA_nooption_RT2) {
        vSend($IF1, na_tn2nut_sourceLLA_destinationLLA_targetGA_RT2);
        goto recv_start;
    }
    if ($ret{recvFrame} eq ns_nut2tn_sourceGA_targetLLA_optionSLL_RT2 || 
	$ret{recvFrame} eq ns_nut2tn_sourceGA_targetLLA_nooption_RT2) {
        vSend($IF1, na_tn2nut_sourceGA_destinationGA_targetLLA_RT2);
        goto recv_start;
    }
    if ($ret{recvFrame} eq ns_nut2tn_sourceGA_targetGA_optionSLL_RT2 || 
	$ret{recvFrame} eq ns_nut2tn_sourceGA_targetGA_nooption_RT2) {
        vSend($IF1, na_tn2nut_sourceGA_destinationGA_targetGA_RT2);
        goto recv_start;
    }

    for(my $i=0; @packet1[$i] ne ''; $i++) {
        if ($ret{recvFrame} eq @packet1[$i]) {
            return $V6evalTool::exitPass; # Got one of the packets expected
        }
    }
    if($ret{status} == 0) {
        goto recv_fail;
    }
   
# If we end up here, something has failed.
  recv_fail:
    return $V6evalTool::exitFail;
}


sub SendRecvRT1unreach ($$$$@) {
    my($IF, $packet, $IF1, @packet1) = @_;
    my $unexpectCntTotal = 0;
    my $loopcount = -1;


    vClear($IF);
    vSend($IF, $packet) if defined($packet);
        
recv_start:
    $loopcount += 1;
    %ret=vRecv($IF1,10,0,0,@packet1, @NS_LINK0_RT1, @NS_LINK0_RT2);

# First check if we received unexpected packets
    my $unexpectCnt = $ret{recvCount};
    $unexpectCnt-- if($ret{status}==0);
    if($unexpectCnt > 0) {
        vLogHTML("<FONT COLOR=#FF0000>".
                 "Recv $unexpectCnt unexpected packet(s)</FONT><BR>");
        $unexpectCntTotal += $unexpectCnt;
    }
    if($loopcount > $ROUTE::NS_LOOP_MAX) {
	vLog("Too many NS received : $loopcount");
  	goto recv_fail;
    }

# Then see what else we got
    if ($ret{status} != 0) {
        if (@packet1[0] eq '' && $unexpectCntTotal == 0) {
            return $V6evalTool::exitPass; # Expected no packets and got none
        } else {
            goto recv_fail;
        }
    }
    if ($ret{recvFrame} eq ns_nut2tn_sourceLLA_targetLLA_optionSLL_RT1 || 
	$ret{recvFrame} eq ns_nut2tn_sourceLLA_targetLLA_nooption_RT1) {
        goto recv_start;
    }
    if ($ret{recvFrame} eq ns_nut2tn_sourceLLA_targetGA_optionSLL_RT1 || 
	$ret{recvFrame} eq ns_nut2tn_sourceLLA_targetGA_nooption_RT1) {
        goto recv_start;
    }
    if ($ret{recvFrame} eq ns_nut2tn_sourceGA_targetLLA_optionSLL_RT1 || 
	$ret{recvFrame} eq ns_nut2tn_sourceGA_targetLLA_nooption_RT1) {
        goto recv_start;
    }
    if ($ret{recvFrame} eq ns_nut2tn_sourceGA_targetGA_optionSLL_RT1 || 
	$ret{recvFrame} eq ns_nut2tn_sourceGA_targetGA_nooption_RT1) {
        goto recv_start;
    }

    if ($ret{recvFrame} eq ns_nut2tn_sourceLLA_targetLLA_optionSLL_RT2 || 
	$ret{recvFrame} eq ns_nut2tn_sourceLLA_targetLLA_nooption_RT2) {
        vSend($IF1, na_tn2nut_sourceLLA_destinationLLA_targetLLA_RT2);
        goto recv_start;
    }
    if ($ret{recvFrame} eq ns_nut2tn_sourceLLA_targetGA_optionSLL_RT2 || 
	$ret{recvFrame} eq ns_nut2tn_sourceLLA_targetGA_nooption_RT2) {
        vSend($IF1, na_tn2nut_sourceLLA_destinationLLA_targetGA_RT2);
        goto recv_start;
    }
    if ($ret{recvFrame} eq ns_nut2tn_sourceGA_targetLLA_optionSLL_RT2 || 
	$ret{recvFrame} eq ns_nut2tn_sourceGA_targetLLA_nooption_RT2) {
        vSend($IF1, na_tn2nut_sourceGA_destinationGA_targetLLA_RT2);
        goto recv_start;
    }
    if ($ret{recvFrame} eq ns_nut2tn_sourceGA_targetGA_optionSLL_RT2 || 
	$ret{recvFrame} eq ns_nut2tn_sourceGA_targetGA_nooption_RT2) {
        vSend($IF1, na_tn2nut_sourceGA_destinationGA_targetGA_RT2);
        goto recv_start;
    }

    for(my $i=0; @packet1[$i] ne ''; $i++) {
        if ($ret{recvFrame} eq @packet1[$i]) {
            return $V6evalTool::exitPass; # Got one of the packets expected
        }
    }
    if($ret{status} == 0) {
        goto recv_fail;
    }
   
# If we end up here, something has failed.
  recv_fail:
    return $V6evalTool::exitFail;
}

sub SendRecvRT2unreach ($$$$@) {
    my($IF, $packet, $IF1, @packet1) = @_;
    my $unexpectCntTotal = 0;
    my $loopcount = -1;

    vClear($IF);
    vSend($IF, $packet) if defined($packet);
        
recv_start:
    $loopcount += 1;
    %ret=vRecv($IF1,10,0,0,@packet1, @NS_LINK0_RT1, @NS_LINK0_RT2);

# First check if we received unexpected packets
    my $unexpectCnt = $ret{recvCount};
    $unexpectCnt-- if($ret{status}==0);
    if($unexpectCnt > 0) {
        vLogHTML("<FONT COLOR=#FF0000>".
                 "Recv $unexpectCnt unexpected packet(s)</FONT><BR>");
        $unexpectCntTotal += $unexpectCnt;
    }
    if($loopcount > $ROUTE::NS_LOOP_MAX) {
	vLog("Too many NS received : $loopcount");
  	goto recv_fail;
    }

# Then see what else we got
    if ($ret{status} != 0) {
        if (@packet1[0] eq '' && $unexpectCntTotal == 0) {
            return $V6evalTool::exitPass; # Expected no packets and got none
        } else {
            goto recv_fail;
        }
    }
    if ($ret{recvFrame} eq ns_nut2tn_sourceLLA_targetLLA_optionSLL_RT1 || 
	$ret{recvFrame} eq ns_nut2tn_sourceLLA_targetLLA_nooption_RT1) {
        vSend($IF1, na_tn2nut_sourceLLA_destinationLLA_targetLLA_RT1);
        goto recv_start;
    }
    if ($ret{recvFrame} eq ns_nut2tn_sourceLLA_targetGA_optionSLL_RT1 || 
	$ret{recvFrame} eq ns_nut2tn_sourceLLA_targetGA_nooption_RT1) {
        vSend($IF1, na_tn2nut_sourceLLA_destinationLLA_targetGA_RT1);
        goto recv_start;
    }
    if ($ret{recvFrame} eq ns_nut2tn_sourceGA_targetLLA_optionSLL_RT1 || 
	$ret{recvFrame} eq ns_nut2tn_sourceGA_targetLLA_nooption_RT1) {
        vSend($IF1, na_tn2nut_sourceGA_destinationGA_targetLLA_RT1);
        goto recv_start;
    }
    if ($ret{recvFrame} eq ns_nut2tn_sourceGA_targetGA_optionSLL_RT1 || 
	$ret{recvFrame} eq ns_nut2tn_sourceGA_targetGA_nooption_RT1) {
        vSend($IF1, na_tn2nut_sourceGA_destinationGA_targetGA_RT1);
        goto recv_start;
    }

    if ($ret{recvFrame} eq ns_nut2tn_sourceLLA_targetLLA_optionSLL_RT2 || 
	$ret{recvFrame} eq ns_nut2tn_sourceLLA_targetLLA_nooption_RT2) {
        goto recv_start;
    }
    if ($ret{recvFrame} eq ns_nut2tn_sourceLLA_targetGA_optionSLL_RT2 || 
	$ret{recvFrame} eq ns_nut2tn_sourceLLA_targetGA_nooption_RT2) {
        goto recv_start;
    }
    if ($ret{recvFrame} eq ns_nut2tn_sourceGA_targetLLA_optionSLL_RT2 || 
	$ret{recvFrame} eq ns_nut2tn_sourceGA_targetLLA_nooption_RT2) {
        goto recv_start;
    }
    if ($ret{recvFrame} eq ns_nut2tn_sourceGA_targetGA_optionSLL_RT2 || 
	$ret{recvFrame} eq ns_nut2tn_sourceGA_targetGA_nooption_RT2) {
        goto recv_start;
    }

    for(my $i=0; @packet1[$i] ne ''; $i++) {
        if ($ret{recvFrame} eq @packet1[$i]) {
            return $V6evalTool::exitPass; # Got one of the packets expected
        }
    }
    if($ret{status} == 0) {
        goto recv_fail;
    }
   
# If we end up here, something has failed.
  recv_fail:
    return $V6evalTool::exitFail;
}




sub SendRecvRetFrame ($$$$$@) {
    my($Frame, $IF, $packet, $IF1, @packet1) = @_;
    my $unexpectCntTotal = 0;

    vClear($IF);
    vSend($IF, $packet) if defined($packet);
        
recv_start:
    %ret=vRecv($IF1,3,0,0,@packet1, @NS_LINK0_RT1, @NS_LINK0_RT2);

# First check if we received unexpected packets
    my $unexpectCnt = $ret{recvCount};
    $unexpectCnt-- if($ret{status}==0);
    if($unexpectCnt > 0) {
        vLogHTML("<FONT COLOR=#FF0000>".
                 "Recv $unexpectCnt unexpected packet(s)</FONT><BR>");
        $unexpectCntTotal += $unexpectCnt;
    }

# Then see what else we got
    if ($ret{status} != 0) {
        if (@packet1[0] eq '' && $unexpectCntTotal == 0) {
            return $V6evalTool::exitPass; # Expected no packets and got none
        } else {
            goto recv_fail;
        }
    }
    if ($ret{recvFrame} eq ns_nut2tn_sourceLLA_targetLLA_optionSLL_RT1 || 
	$ret{recvFrame} eq ns_nut2tn_sourceLLA_targetLLA_nooption_RT1) {
        vSend($IF1, na_tn2nut_sourceLLA_destinationLLA_targetLLA_RT1);
        goto recv_start;
    }
    if ($ret{recvFrame} eq ns_nut2tn_sourceLLA_targetGA_optionSLL_RT1 || 
	$ret{recvFrame} eq ns_nut2tn_sourceLLA_targetGA_nooption_RT1) {
        vSend($IF1, na_tn2nut_sourceLLA_destinationLLA_targetGA_RT1);
        goto recv_start;
    }
    if ($ret{recvFrame} eq ns_nut2tn_sourceGA_targetLLA_optionSLL_RT1 || 
	$ret{recvFrame} eq ns_nut2tn_sourceGA_targetLLA_nooption_RT1) {
        vSend($IF1, na_tn2nut_sourceGA_destinationGA_targetLLA_RT1);
        goto recv_start;
    }
    if ($ret{recvFrame} eq ns_nut2tn_sourceGA_targetGA_optionSLL_RT1 || 
	$ret{recvFrame} eq ns_nut2tn_sourceGA_targetGA_nooption_RT1) {
        vSend($IF1, na_tn2nut_sourceGA_destinationGA_targetGA_RT1);
        goto recv_start;
    }

    if ($ret{recvFrame} eq ns_nut2tn_sourceLLA_targetLLA_optionSLL_RT2 || 
	$ret{recvFrame} eq ns_nut2tn_sourceLLA_targetLLA_nooption_RT2) {
        vSend($IF1, na_tn2nut_sourceLLA_destinationLLA_targetLLA_RT2);
        goto recv_start;
    }
    if ($ret{recvFrame} eq ns_nut2tn_sourceLLA_targetGA_optionSLL_RT2 || 
	$ret{recvFrame} eq ns_nut2tn_sourceLLA_targetGA_nooption_RT2) {
        vSend($IF1, na_tn2nut_sourceLLA_destinationLLA_targetGA_RT2);
        goto recv_start;
    }
    if ($ret{recvFrame} eq ns_nut2tn_sourceGA_targetLLA_optionSLL_RT2 || 
	$ret{recvFrame} eq ns_nut2tn_sourceGA_targetLLA_nooption_RT2) {
        vSend($IF1, na_tn2nut_sourceGA_destinationGA_targetLLA_RT2);
        goto recv_start;
    }
    if ($ret{recvFrame} eq ns_nut2tn_sourceGA_targetGA_optionSLL_RT2 || 
	$ret{recvFrame} eq ns_nut2tn_sourceGA_targetGA_nooption_RT2) {
        vSend($IF1, na_tn2nut_sourceGA_destinationGA_targetGA_RT2);
        goto recv_start;
    }

    for(my $i=0; @packet1[$i] ne ''; $i++) {
        if ($ret{recvFrame} eq @packet1[$i]) {
            $$Frame = $ret{recvFrame};
            return $V6evalTool::exitPass; # Got one of the packets expected
        }
    }
    if($ret{status} == 0) {
        goto recv_fail;
    }
   
# If we end up here, something has failed.
  recv_fail:
    return $V6evalTool::exitFail;
}


sub flushtables ($) {
	my ( $targettype ) = @_ ;
	my ( $rret );

#	if( $targettype eq "freebsd-i386" || $targettype eq "usagi-i386" ){
	if( $targettype eq "freebsd-i386" ){
		$rret=vRemote("cleardefr.rmt","","timeout=5");
		vLog("cleardefr.rmt returned status $rret");
 
		$rret=vRemote("clearroute.rmt","","timeout=5");
		vLog("clearroute.rmt returned status $rret");

		$rret=vRemote("clearnc.rmt","","timeout=5");
		vLog("clearnc.rmt returned status $rret");

		$rret=vRemote("clearprefix.rmt","","timeout=5");
		vLog("clearprefix.rmt returned status $rret");

	}else{
		reboot();
#		$ret=vRemote("reboot_async.rmt","","timeout=5");
#
#		
#		#---------------------------------------
#		#----- LLA PHASE
#		#----- Wait DAD NS from NUT or timeout
#		#---------------------------------------
#		vLog("TN wait DAD NS(DADNS_from_NUT) from NUT for $ROUTE::WAIT_DADNS [sec],");
#
#		%ret=vRecv($IF,$WAIT_DADNS,0,0,DADNS_from_NUT);
#		if ($ret{status} != 0){
#		    vLog("TN wait DAD NS from NUT for $wait_dadns, but NUT had not transmit DAD NS");
#		    seqNG();
#		}
#
#		vLog("TN received DAD NS from NUT.");
#
#
#
#		#---------------------------------------
#		#----- Wait RS from NUT or timeout
#		#---------------------------------------
#
#		%ret=vRecv($IF,$MORE_WAIT_RS,0,0,RS_from_NUT);
#		if ($ret{status} != 0){
#		    vLog("TN wait RS from NUT for $MORE_WAIT_RS, but NUT had not transmit RS");
#		    seqNG();
#		}

		vLog("OK! Let's go ahead!");

	} 
	return $V6evalTool::exitIgnore;
}

sub sendRA (;$) {
	my ( $IF ) =@_;
	$IF=$IF_ID_0 if (! $IF ) ;
	if($type eq host ) {
		vSend($IF, ra);
		#-- this part is for igonoreing NS Packet --
		vSleep(5);
		vClear($IF);
	}
}

sub reboot () {
	vLogHTML("Remote boot NUT. ");
	$ret=vRemote("reboot.rmt","");
	if ($ret > 0) {
		vLog("vRemote reboot.rmt exit $ret");
		exit $FATAL;
	}

	return $V6evalTool::exitIgnore;
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

#=================================================
# sequence exit OK
#=================================================
sub seqOK() {
    vLog(OK);
    seqTermination();
    vLog("*** EOT ***");
    exit $V6evalTool::exitPass;
}

#=================================================
# sequence exit NG
#=================================================
sub seqNG() {
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

sub seqExitWARN() {
    vLog(WARN);
    seqTermination();
    vLog("*** EOT ***");
    exit $V6evalTool::exitWarn;
}

#=================================================
# Test Termination
#=================================================
sub seqTermination() {
    &$main::term_handler if defined $main::term_handler;
}
