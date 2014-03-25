# Copyright (C) 2006 Yokogawa Electric Corporation.
# All rights reserved.
# 
# Redistribution and use of this software in source and binary
# forms, with or without modification, are permitted provided that
# the following conditions and disclaimer are agreed and accepted
# by the user:
# 
# 1. Redistributions of source code must retain the above copyright
#    notice, this list of conditions and the following disclaimer.
# 
# 2. Redistributions in binary form must reproduce the above copyright
#    notice, this list of conditions and the following disclaimer in
#    the documentation and/or other materials provided with
#    the distribution.
# 
# 3. Neither the names of the copyrighters, the name of the project
#    which is related to this software (hereinafter referred to as
#    "project") nor the names of the contributors may be used to
#    endorse or promote products derived from this software without
#    specific prior written permission.
# 
# 4. No merchantable use may be permitted without prior written
#    notification to the copyrighters.
# 
# 5. The copyrighters, the project and the contributors may prohibit
#    the use of this software at any time.
# 
# THIS SOFTWARE IS PROVIDED BY THE COPYRIGHTERS, THE PROJECT AND
# CONTRIBUTORS "AS IS" AND ANY EXPRESS OR IMPLIED WARRANTIES, INCLUDING
# BUT NOT LIMITED THE IMPLIED WARRANTIES OF MERCHANTABILITY AND FITNESS
# FOR A PARTICULAR PURPOSE, ARE DISCLAIMED.  IN NO EVENT SHALL THE
# COPYRIGHTERS, THE PROJECT OR CONTRIBUTORS BE LIABLE FOR ANY DIRECT,
# INDIRECT, INCIDENTAL, SPECIAL, EXEMPLARY, OR CONSEQUENTIAL DAMAGES
# (INCLUDING, BUT NOT LIMITED TO, PROCUREMENT OF SUBSTITUTE GOODS OR
# SERVICES; LOSS OF USE, DATA, OR PROFITS; OR BUSINESS INTERRUPTION)
# HOWEVER CAUSED AND ON ANY THEORY OF LIABILITY, WHETHER IN CONTRACT,
# STRICT LIABILITY, OR TORT (INCLUDING NEGLIGENCE OR OTHERWISE) ARISING
# IN ANY WAY OUT OF THE USE OF THIS SOFTWARE, EVEN IF ADVISED OF THE
# POSSIBILITY OF SUCH DAMAGE.
#
# Perl Module for DNS Conformance Test
#
# $Name: REL_1_1_1 $
#
# $TAHI: ct-dns/dns/DNSv6eval.pm,v 1.1.1.1 2006/06/02 05:15:40 akisada Exp $
#
########################################################################
package DNSv6eval;

BEGIN {
        push( @INC, '/usr/local/koi/libdata' );
}

END {
}

use Exporter;
use kCommon;
use V6evalTool;

@ISA = qw(Exporter);
@EXPORT = qw(
	vRecvWrapper
	RegistV6evalSigHandler
);


sub
vRecvWrapper($$$$$$@)
{
	my ($ifname, $timeout, $seektime, $count, $addr_family, $cpp, @frames) = @_;
	my %ret = ();

	# Packet descriptions
	%pktdesc = (
		%pktdesc,
		'arp_from_nut'  =>      'Receive Arp request from HOST-1(NUT)',
		'arp_to_nut'    =>      'Receive Arp reply from Router(TN)',
		'na'            =>      'Receive Router Solicitation from HOST-1(NUT)',
# 		'rs_from_nut'   =>      'Receive Router Solicitation from HOST-1(NUT)',
# 		'rs_from_nut_wsll'=>    'Receive Router Solicitation from HOST-1(NUT)',
# 		'ra_to_nut'     =>      'Send Router Advertisement from Router(TN)',
		'ns_multi'      =>      'Receive Neighbor Solicitation from HOST-1(NUT)',
		'ns_multi_llt'  =>      'Receive Neighbor Solicitation from HOST-1(NUT)',
		'ns_uni'        =>      'Receive Neighbor Solicitation from HOST-1(NUT)',
		'ns_uni_sll'    =>      'Receive Neighbor Solicitation from HOST-1(NUT)',
		'ns_uni_tll_sll'=>      'Receive Neighbor Solicitation from HOST-1(NUT)',
		'na'            =>      'Send Neighbor Advertisement(TN)',
		'na_llt'        =>      'Send Neighbor Advertisement(TN)',
		'na_ll_llt'     =>      'Send Neighbor Advertisement(TN)',
	);

	my %nd = ();
	if($addr_family eq 'INET') {
		%nd = (
			'arp_from_nut'  => 'arp_to_nut',
		);
		$cpp .= " -DNUT_ADDR_FAMILY_INET";
	}
	else{
		%nd = (
			'ns_multi'              => 'na',
			'ns_multi_llt'          => 'na_llt',
			'ns_uni'                => 'na',
			'ns_uni_sll'            => 'na',
			'ns_uni_tll_sll'        => 'na_ll_llt',
# 			'rs_from_nut'           => 'ra_to_nut',
# 			'rs_from_nut_wsll'      => 'ra_to_nut',
		);
	}

	if(defined($cpp)){
		vCPP($cpp);
	}

	print "CPP $cpp\n";

	kLogHTML("vRecv3() expects \"@frames\"");

	for( ; ; ) {
		%ret = vRecv3($ifname, $timeout, $seektime, $count, @frames, keys(%nd));

		if($ret{'recvCount'}) {
			my $continue    = 0;

			while(my ($recv, $send) = each(%nd)) {
				if($ret{'recvFrame'} eq $recv) {
					vSend3($ifname, $send);
					kLogHTML("kSend3 sent \"$send\"");
					$continue ++;
				}
			}

			kLogHTML("vRecv3() received \"$ret{'recvFrame'}\"");

			if($continue) {
				next;
			}
		}
		else {
			kLogHTML("vRecv3() could not receive any packets");
		}
		last;
	}

	return(%ret);
}

sub RegistV6evalSigHandler() {
        $SIG{CHLD} = \&V6evalTool::checkChild;
}

1;
