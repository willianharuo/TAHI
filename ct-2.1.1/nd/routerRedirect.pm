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
# $TAHI: ct/nd/routerRedirect.pm,v 1.8 2001/12/18 10:51:04 nov Exp $

package routerRedirect;
use Exporter;
@ISA = qw(Exporter);

use 5;
use V6evalTool;
use nd;

@EXPORT = qw(
	     rrdSetRdEnv
	     rrdSetRdEnv2
	     rrdClearRdEnv
	     rrdClearRdEnv2
	     );

#
$wait_ns=$nd::RETRANS_TIMER * $nd::MAX_MULTICAST_SOLICIT;
$wait_dad=2;

#
$global_prefix1="3ffe:501:ffff:100";
$global_prefix2="3ffe:501:ffff:108";
$global_prefix3="3ffe:501:ffff:109";

$nut_mac="200:ff:fe00:a0a0";
$nut_global2="$global_prefix2".":"."$nut_mac";

$router1_mac="200:ff:fe00:a1a1";
$router1_link="fe80::$router1_mac";
$router1_global1="$global_prefix1".":"."$router1_mac";

$host2_mac="200:ff:fe00:a2a2";
$host2_link="fe80::"."$host2_mac";
$host2_global2="$global_prefix2".":"."$host2_mac";

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
sub rrdSetRdEnv($)
{
    my($if)=@_;
    $dev=$V6evalTool::NutDef{$if."_device"};
    if($dev eq "") {
	vLogHTML(ndErrmsg("$if: Can not find a device name<BR>"));
	goto error;
    }

    #
    vCapture($if);

    #
    vLogHTML("$nut_global2; Assign a global address<BR>");
    vRemote("manualaddrconf.rmt",
	    "if=$dev",
	    "addr=$nut_global2",
	    "len=64",
	    "type=unicast"
	    )
	&& goto error;

    #
    $main::pktdesc{RRDmulticast_ns_unspec2nutsolnode_g2}="Got DAD NS";
    vRecv($if, $wait_dad, 0, 0, RRDmulticast_ns_unspec2nutsolnode_g2);

    #
    vLogHTML("$router1_link; Add the a route to router1<BR>");
    vRemote("route.rmt",
	    "cmd=add",
#	    "prefix=default",
	    "prefix=$global_prefix3"."::",
	    "prefixlen=64",
	    "gateway=$router1_link",
	    "if=$dev"
	    )
	&& goto error;

    #
    vLog("Wait for DAD NSs if any");
    $main::pktdesc{RRDmulticast_ns_nut2ronesolnode_sll}="Got multicast NS";
    vRecv($if, $wait_ns, 0, 0, RRDmulticast_ns_nut2ronesolnode_sll);

    vLog("Send a solicited NA. It is ok if the NS has no effect");
    $main::pktdesc{RRDunicast_na_rone2nut_RSO_tll}="Send NA";
    vSend($if, RRDunicast_na_rone2nut_RSO_tll);

    #
    return(1);

error:
    return(0);
}

#
#
#
sub rrdSetRdEnv2($)
{
    my($if)=@_;
    $dev=$V6evalTool::NutDef{$if."_device"};
    if($dev eq "") {
	vLogHTML(ndErrmsg("$if: Can not find a device name<BR>"));
	goto error;
    }

    #
    vCapture($if);

    #
    vLogHTML("$nut_global2; Assign a global address<BR>");
    vRemote("manualaddrconf.rmt",
	    "if=$dev",
	    "addr=$nut_global2",
	    "len=64",
	    "type=unicast"
	    )
	&& goto error;

    #
    $main::pktdesc{RRDmulticast_ns_unspec2nutsolnode_g2}="Got DAD NS";
    vRecv($if, $wait_dad, 0, 0, RRDmulticast_ns_unspec2nutsolnode_g2);

    #
    vLogHTML("$router1_global1; Add a route to router1<BR>");
    vRemote("route.rmt",
	    "cmd=add",
#	    "prefix=default",
	    "prefix=$global_prefix3"."::",
	    "prefixlen=64",
	    "gateway=$router1_global1",
	    "if=$dev"
	    )
	&& goto error;

    #
    vLog("Wait for DAD NSs if any");
    $main::pktdesc{RRDmulticast_ns_nut2ronesolnode_sll_g1}="Got multicast NS";
    vRecv($if, $wait_ns, 0, 0, RRDmulticast_ns_nut2ronesolnode_sll_g1);

    vLog("Send a solicited NA. It is ok if the NS has no effect");
    $main::pktdesc{RRDunicast_na_rone2nut_RSO_tll_g1}="Send NA";
    vSend($if, RRDunicast_na_rone2nut_RSO_tll_g1);

    #
    return(1);

error:
    return(0);
}

#
#
#
sub rrdClearRdEnv($)
{
    my($if)=@_;
    $dev=$V6evalTool::NutDef{$if."_device"};
    if($dev eq "") {
	vLogHTML(ndErrmsg("$if: Can not find a device name<BR>"));
	goto error;
    }

    #
    vLogHTML("$nut_global2; Delete a global address<BR>");
    vRemote("manualaddrconf.rmt",
	    "if=$dev",
	    "addr=$nut_global2",
	    "len=64",
	    "type=delete"
	    )
	&& goto error;

    #
    vLogHTML("$router1_link; Delete a route to router1<BR>");
    vRemote("route.rmt",
	    "cmd=delete",
#	    "prefix=default",
	    "prefix=$global_prefix3"."::",
	    "prefixlen=64",
	    "gateway=$router1_link",
	    "if=$dev"
	    )
	&& goto error;

    #
    return(1);

error:
    return(0);
}

#
#
#
sub rrdClearRdEnv2($)
{
    my($if)=@_;
    $dev=$V6evalTool::NutDef{$if."_device"};
    if($dev eq "") {
	vLogHTML(ndErrmsg("$if: Can not find a device name<BR>"));
	goto error;
    }

    #
    vLogHTML("$nut_global2; Delete a global address<BR>");
    vRemote("manualaddrconf.rmt",
	    "if=$dev",
	    "addr=$nut_global2",
	    "len=64",
	    "type=delete"
	    )
	&& goto error;

    #
    vLogHTML("$router1_global1; Delete a route to router1<BR>");
    vRemote("route.rmt",
	    "cmd=delete",
#	    "prefix=default",
	    "prefix=$global_prefix3"."::",
	    "prefixlen=64",
	    "gateway=$router1_global1",
	    "if=$dev"
	    )
	&& goto error;

    #
    return(1);

error:
    return(0);
}

########################################################################
1;
__END__
########################################################################
