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
# $TAHI: ct/nd/hostRedirect.pm,v 1.7 2002/02/27 01:08:26 masaxmasa Exp $

package hostRedirect;
use Exporter;
@ISA = qw(Exporter);

use 5;
use V6evalTool;
use nd;

@EXPORT = qw(
	     rd2NoNce
	     rd2Incomplete
	     rd2Reachable
	     rd2ReachableZ
	     rd2Stale
	     rd2StaleZ
	     rd2Probe
	     rd2ProbeZ
	     rdClear
	     );

#
$wait_probe=$nd::RETRANS_TIMER * $nd::MAX_UNICAST_SOLICIT;

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
sub rd2NoNce($)
{
    my($if)=@_;

#    return 1 if ndClearPrefix() != 0;
#    return 1 if ndClearDefr() != 0;
#    return 1 if ndClearRoutes() != 0;
    return 1 if nd2NoNce($if) != 0;
    vLogHTML("Target: NONCE state<BR>");

    vLogHTML("Set default router whose state is REACHABLE<BR>");
    $main::pktdesc{RDra_rone2allnode_sll}='R1 sends RA w/ SLL'.
	', then STALE state';
    $main::pktdesc{RDunicast_na_rone2nut_RSO_tll}='R1 sends NA(RSO) w/ TLL'.
	', then REACHABLE state';
    %ret=vSend($if, RDra_rone2allnode_sll, RDunicast_na_rone2nut_RSO_tll);
    if($ret{status} != 0) {
	vLogHTML(vErrmsg(%ret)."<BR>");
	return 1;
    }

    vLogHTML("Wait for DAD NS<BR>");
    vRecv($if, $wait_probe, 0, 0);

    return 0
}

#
#
#
sub rd2Incomplete($)
{
    my($if)=@_;
    return 1 if rd2NoNce($if) != 0;
    return ndNoNce2Incomplete($if);
}

#
#
#
sub rd2Reachable($)
{
    my($if)=@_;
    return 1 if rd2NoNce($if) != 0;
    return ndNoNce2ReachableByRa($if);
}

#
#
#
sub rd2ReachableZ($)
{
    my($if)=@_;
    return 1 if rd2NoNce($if) != 0;
    return ndNoNce2ReachableByRaZ($if);
}

#
#
#
sub rd2Stale($)
{
    my($if)=@_;
    return 1 if rd2Reachable($if) != 0;
    return ndReachable2Stale();
}

#
#
#
sub rd2StaleZ($)
{
    my($if)=@_;
    return 1 if rd2ReachableZ($if) != 0;
    return ndReachable2StaleZ();
}

#
#
#
sub rd2Probe($)
{
    my($if)=@_;
    return 1 if rd2Stale($if) != 0;
    return ndStale2Probe($if);
}

#
#
#
sub rd2ProbeZ($)
{
    my($if)=@_;
    return 1 if rd2StaleZ($if) != 0;
    return ndStale2ProbeZ($if);
}

#
#
#
sub rdClear($)
{
    my($if)=@_;
    $main::pktdesc{RDra_rone2allnode_clrrtr}=
	"Clear R1 from the Default Router List";
    $main::pktdesc{RDra_tn2allnode_clrrtr}=
	"Clear TN from the Default Router List";
    vSend($if, 
	  RDra_rone2allnode_clrrtr, 
	  RDra_tn2allnode_clrrtr
	  );
}

########################################################################
1;
__END__
########################################################################
