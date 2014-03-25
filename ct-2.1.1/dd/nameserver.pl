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
# $TAHI: ct/dd/nameserver.pl,v 1.3 2003/04/22 04:04:45 akisada Exp $
#

$dhcp6c = "/usr/local/v6/sbin/dhcp6c";
$dhcp6c_log = "/var/log/dhcp6.log";
$resolvconf = "/etc/resolv.conf";
$kill = "/usr/bin/killall";
$cat  = "/bin/cat";

@well_known_nameservers = (
	'fec0:0:0:ffff::1',
	'fec0:0:0:ffff::2',
	'fec0:0:0:ffff::3',
);
@search = ();
@nsaddrs = ();

$| = 1;
open(OPEN, "< $dhcp6c_log") || die "$dhcp6c_log not found.";
while (<OPEN>) {
	if (/.*search\[.\] (.*)/) {
		print "$_";
		push(@search, $1);
	}
	if (/.*nameserver\[.\] (.*)/) {
		print "$_";
		push(@nsaddrs, $1);
	}
}

close(OPEN);

if (@nsaddrs) {
	&write_resolv_conf(@nsaddrs);
} else {
	&write_resolv_conf(@well_known_nameservers);
}

system("$kill dhcp6c") && die "can't kill $dhcp6c";
system("$cat /dev/null > $dhcp6c_log") && die "can't create $dhcp6c_log";

exit 0;

sub write_resolv_conf
{
	my @addrs = @_;

	open(OUT, "> $resolvconf") || die "$resolvconf not found";
	foreach (@search) {
		print OUT "search $_\n";
	}
	foreach (@addrs) {
		print OUT "nameserver $_\n";
	}
	close(OUT);
}
