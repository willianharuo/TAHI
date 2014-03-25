#! /usr/bin/perl -w
#
# Copyright (C) 1999, 2000, 2001, 2002, 2003, 2004, 2005, 2006, 2007, 2008, 2009
# Yokogawa Electric Corporation.
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
# $TAHI: vel/interop_ph2/make_scenario.pl,v 1.8 2009/03/27 08:40:19 doo Exp $

use POSIX qw(strftime);

BEGIN {
	use constant TRUE => 1;
	use constant FALSE => 0;
	use constant DEBUG => &FALSE # &TRUE; # 
}

END { }

my $configFile = './config.txt';
my @commandFiles = ('./command.FreeBSD.txt',
		    './command.NetBSD.txt',
		    './command.KAME.txt',
		    './command.Linux.txt',
		    './command.USAGI.txt',
		   );
my $destinationDir = strftime "%Y%m%d%H%M%S", localtime;

## YOUR DEVICE
my %logoMap =
	(
	 'ID' => 'LOGO',
	 'LOGO_TYPE' => '',
	 'LOGO_NAME' => '',
	 'LOGO_IF1' => '',
	 'LOGO_IF1_MAC' => '',
	 'LOGO_IF2' => '',
	 'LOGO_IF2_MAC' => '',

	 'LOGO_IF1_EUI-64' => '',
	 'LOGO_IF1_LLA' => '',
	 'LOGO_IF1_PREFIX1_GA' => '',
	 'LOGO_IF1_PREFIX2_GA' => '',
	 'LOGO_IF1_PREFIX3_GA' => '',
	 'LOGO_IF2_EUI-64' => '',
	 'LOGO_IF2_LLA' => '',
	 'LOGO_IF2_PREFIX2_GA' => '',
	);

## TARGET-1
my %tar1Map =
	(
	 'ID' => 'TAR1',
	 'TAR1_NAME' => '',
	 'TAR1_TYPE' => '',
	 'TAR1_IF1' => '',
	 'TAR1_IF1_MAC' => '',
	 'TAR1_IF2' => '',
	 'TAR1_IF2_MAC' => '',
	 'TAR1_IF3' => '',
	 'TAR1_IF3_MAC' => '',
	 'TAR1_IFTG' => '',
	 'TAR1_IFTG_V4_ADDR' => '',

	 'TAR1_IF1_EUI-64' => '',
	 'TAR1_IF1_LLA' => '',
	 'TAR1_IF1_PREFIX1_GA' => '',
	 'TAR1_IF1_PREFIX2_GA' => '',
	 'TAR1_IF1_PREFIX3_GA' => '',
	 'TAR1_IF2_EUI-64' => '',
	 'TAR1_IF2_LLA' => '',
	 'TAR1_IF2_PREFIX1_GA' => '',
	 'TAR1_IF2_PREFIX2_GA' => '',
	 'TAR1_IF2_PREFIX3_GA' => '',
	 'TAR1_IF3_EUI-64' => '',
	 'TAR1_IF3_LLA' => '',
	 'TAR1_IF3_PREFIX1_GA' => '',
	 'TAR1_IF3_PREFIX2_GA' => '',
	 'TAR1_IF3_PREFIX3_GA' => '',
	);
my %tar1CommandMap;

## TARGET-2
my %tar2Map =
	(
	 'ID' => 'TAR2',
	 'TAR2_NAME' => '',
	 'TAR2_TYPE' => '',
	 'TAR2_IF1' => '',
	 'TAR2_IF1_MAC' => '',
	 'TAR2_IF2' => '',
	 'TAR2_IF2_MAC' => '',
	 'TAR2_IF3' => '',
	 'TAR2_IF3_MAC' => '',
	 'TAR2_IFTG' => '',
	 'TAR2_IFTG_V4_ADDR' => '',

	 'TAR2_IF1_EUI-64' => '',
	 'TAR2_IF1_LLA' => '',
	 'TAR2_IF1_PREFIX1_GA' => '',
	 'TAR2_IF1_PREFIX2_GA' => '',
	 'TAR2_IF1_PREFIX3_GA' => '',
	 'TAR2_IF2_EUI-64' => '',
	 'TAR2_IF2_LLA' => '',
	 'TAR2_IF2_PREFIX1_GA' => '',
	 'TAR2_IF2_PREFIX2_GA' => '',
	 'TAR2_IF2_PREFIX3_GA' => '',
	 'TAR2_IF3_EUI-64' => '',
	 'TAR2_IF3_LLA' => '',
	 'TAR2_IF3_PREFIX1_GA' => '',
	 'TAR2_IF3_PREFIX2_GA' => '',
	 'TAR2_IF3_PREFIX3_GA' => '',
	);
my %tar2CommandMap;

## TARGET-3
my %tar3Map =
	(
	 'ID' => 'TAR3',
	 'TAR3_NAME' => '',
	 'TAR3_TYPE' => '',
	 'TAR3_IF1' => '',
	 'TAR3_IF1_MAC' => '',
	 'TAR3_IF2' => '',
	 'TAR3_IF2_MAC' => '',
	 'TAR3_IF3' => '',
	 'TAR3_IF3_MAC' => '',
	 'TAR3_IFTG' => '',
	 'TAR3_IFTG_V4_ADDR' => '',

	 'TAR3_IF1_EUI-64' => '',
	 'TAR3_IF1_LLA' => '',
	 'TAR3_IF1_PREFIX1_GA' => '',
	 'TAR3_IF1_PREFIX2_GA' => '',
	 'TAR3_IF1_PREFIX3_GA' => '',
	 'TAR3_IF2_EUI-64' => '',
	 'TAR3_IF2_LLA' => '',
	 'TAR3_IF2_PREFIX1_GA' => '',
	 'TAR3_IF2_PREFIX2_GA' => '',
	 'TAR3_IF2_PREFIX3_GA' => '',
	 'TAR3_IF3_EUI-64' => '',
	 'TAR3_IF3_LLA' => '',
	 'TAR3_IF3_PREFIX1_GA' => '',
	 'TAR3_IF3_PREFIX2_GA' => '',
	 'TAR3_IF3_PREFIX3_GA' => '',
	);
my %tar3CommandMap;

## TARGET-4
my %tar4Map =
	(
	 'ID' => 'TAR4',
	 'TAR4_NAME' => '',
	 'TAR4_TYPE' => '',
	 'TAR4_IF1' => '',
	 'TAR4_IF1_MAC' => '',
	 'TAR4_IF2' => '',
	 'TAR4_IF2_MAC' => '',
	 'TAR4_IF3' => '',
	 'TAR4_IF3_MAC' => '',
	 'TAR4_IFTG' => '',
	 'TAR4_IFTG_V4_ADDR' => '',

	 'TAR4_IF1_EUI-64' => '',
	 'TAR4_IF1_LLA' => '',
	 'TAR4_IF1_PREFIX1_GA' => '',
	 'TAR4_IF1_PREFIX2_GA' => '',
	 'TAR4_IF1_PREFIX3_GA' => '',
	 'TAR4_IF2_EUI-64' => '',
	 'TAR4_IF2_LLA' => '',
	 'TAR4_IF2_PREFIX1_GA' => '',
	 'TAR4_IF2_PREFIX2_GA' => '',
	 'TAR4_IF2_PREFIX3_GA' => '',
	 'TAR4_IF3_EUI-64' => '',
	 'TAR4_IF3_LLA' => '',
	 'TAR4_IF3_PREFIX1_GA' => '',
	 'TAR4_IF3_PREFIX2_GA' => '',
	 'TAR4_IF3_PREFIX3_GA' => '',
	);
my %tar4CommandMap;

# ref1
my %ref1Map =
	(
	 'ID' => 'REF1',
	 'REF1_NAME' => '',
	 'REF1_IF1' => '',
	 'REF1_IF1_MAC' => '',
	 'REF1_IF2' => '',
	 'REF1_IF2_MAC' => '',
	 'REF1_IFTG' => '',
	 'REF1_IFTG_V4_ADDR' => '',

	 'REF1_IF1_EUI-64' => '',
	 'REF1_IF1_LLA' => '',
	 'REF1_IF1_PREFIX1_GA' => '',
	 'REF1_IF1_PREFIX2_GA' => '',
	 'REF1_IF1_PREFIX3_GA' => '',
	 'REF1_IF2_EUI-64' => '',
	 'REF1_IF2_LLA' => '',
	 'REF1_IF2_PREFIX1_GA' => '',
	 'REF1_IF2_PREFIX2_GA' => '',
	 'REF1_IF2_PREFIX3_GA' => '',
	);
my %ref1CommandMap;

# ref2
my %ref2Map =
	(
	 'ID' => 'REF2',
	 'REF2_NAME' => '',
	 'REF2_IF1' => '',
	 'REF2_IF1_MAC' => '',
	 'REF2_IF2' => '',
	 'REF2_IF2_MAC' => '',
	 'REF2_IFTG' => '',
	 'REF2_IFTG_V4_ADDR' => '',

	 'REF2_IF1_EUI-64' => '',
	 'REF2_IF1_LLA' => '',
	 'REF2_IF1_PREFIX1_GA' => '',
	 'REF2_IF1_PREFIX2_GA' => '',
	 'REF2_IF1_PREFIX3_GA' => '',
	 'REF2_IF2_EUI-64' => '',
	 'REF2_IF2_LLA' => '',
	 'REF2_IF2_PREFIX1_GA' => '',
	 'REF2_IF2_PREFIX2_GA' => '',
	 'REF2_IF2_PREFIX3_GA' => '',
	);
my %ref2CommandMap;

my %dumperMap =
	(
	 'ID' => 'DUMPER',
	 'DUMPER_NAME' => '',
	 'DUMPER_IF1' => '',
	 'DUMPER_IF2' => '',
	 'DUMPER_IF3' => '',
	 'DUMPER_IFTG' => '',
	 'DUMPER_IFTG_V4_ADDR' => '',
	);
my %dumperCommandMap;

##
my %nodeMap =
	(
	 'TAR1' => \%tar1Map,
	 'TAR2' => \%tar2Map,
	 'TAR3' => \%tar3Map,
	 'TAR4' => \%tar4Map,
	 'LOGO'  => \%logoMap,
	 'DUMPER' => \%dumperMap,
	 'REF1' => \%ref1Map,
	 'REF2' => \%ref2Map,
	);

my %nodeCommandMap =
	(
	 'TAR1' => \%tar1CommandMap,
	 'TAR2' => \%tar2CommandMap,
	 'TAR3' => \%tar3CommandMap,
	 'TAR4' => \%tar4CommandMap,
	 'DUMPER' => \%dumperCommandMap,
	 'REF1' => \%ref1CommandMap,
	 'REF2' => \%ref2CommandMap,
	);

##
my %miscMap =
	(
	 'PREFIX1' => '',
	 'PREFIX2' => '',
	 'PREFIX3' => '',
	 'BASENAME' => 'vel mgr',
	 'DUP_ADDR' => '',
	);

sub main();

sub configure();
sub registToNodeMap($);
sub generateAddress($);
sub mac2eui64($);
sub allocateTargetMap($);

sub makeScenario();
sub makeHostScenario($$);
sub makeRouterScenario($$);
sub makeEnvironment();
sub makeCollectionScript();
sub makeTestScript();
sub makeDirectory($);

sub readCommand();
sub readConfiguration();
sub readPrefixFiles($);
sub readDirectory($);

sub replaceScript($$);
sub replaceNodeName($$);
sub replaceCommand();
sub replaceKeyword();
sub replaceMisc();


main();
exit 0;
# UNREACHABLE

sub main() {
	readConfiguration();
	readCommand();
	configure();
	makeScenario();
	makeTestScript();
	makeEnvironment();
	makeCollectionScript();
}

# 
sub readConfiguration() {
	local (*INPUT);
	unless (open(INPUT, $configFile)) {
		print STDERR "open: $configFile: $!";
		return (&FALSE);
	}

	for (my $number = 1; <INPUT>; $number ++) {
		chomp;
		my $line = $_;

		# processing comment
		if($line =~ /^([^#]*)#.*$/) {
			$line = $1;
		}
		# processing empty line
		if($line =~ /^\s*$/) {
			next;
		}

		registToNodeMap($line);
	}
	close(INPUT);
}

# 
sub registToNodeMap($) {
	my ($line) = @_;

	if ($line =~ /^\s*(\S+)\s+(\S+)\s*$/) {
		my $key		= $1;
		my $value	= $2;

		if (exists $miscMap{$key}) {
			$miscMap{$key} = $value;
			return (&TRUE);
		}

		my $target;
		if ($key =~ /([A-Z0-9\-]+)_.*/) {
			$target = $1;
		}
		else {
			print STDERR "invalid key was defind: $key :$!";
			return (&FALSE);
		}

		unless (exists $nodeMap{$target}->{$key}) {
			print STDERR "target map doesn't have key: $key :$!";
			return (&FALSE);
		}

		$nodeMap{$target}->{$key} = $value;
		if ($key =~ /\w*NAME/ && $target ne 'LOGO') {
			$nodeCommandMap{$target}->{$key} = $value;
		}
	}

	return (&TRUE)
}

# 
sub configure() {
	foreach my $node (keys(%nodeMap)) {
		if ($node eq 'DUMPER') {
			next;
		}

		generateAddress($node);
	}
}

# 
sub generateAddress($) {
	my ($node) = @_;

	my @ifList = ('IF1', 'IF2', 'IF3',);
	my %scopeMap = ('LLA' => 'fe80::',
			'PREFIX1_GA' => $miscMap{'PREFIX1'}.':',
			'PREFIX2_GA' => $miscMap{'PREFIX2'}.':',
			'PREFIX3_GA' => $miscMap{'PREFIX3'}.':',
		       );

	foreach my $if (@ifList) {
		# generate EUI-64
		my $eui64 = $node.'_'.$if.'_EUI-64';
		my $mac = $node.'_'.$if.'_MAC';

		unless (exists $nodeMap{$node}->{$mac}) {
			next;
		}
		unless (exists $nodeMap{$node}->{$eui64}) {
			next;
		}

		$nodeMap{$node}->{$eui64} = mac2eui64($nodeMap{$node}->{$mac});

		# generate LLA and GA
		foreach my $scope (keys(%scopeMap)) {
			my $address = $node.'_'.$if.'_'.$scope;

			unless (exists $nodeMap{$node}->{$address}) {
				next;
			}

			$nodeMap{$node}->{$address} = $scopeMap{$scope}.$nodeMap{$node}->{$eui64};
		}
	}
}

# 
sub mac2eui64($) {
	my ($mac) = @_;

	my @bytesList = split(/:/, $mac);

	my $result = sprintf "%02x", hex(shift(@bytesList)) ^ 0x2;

	my $i = 0;
	foreach my $bytes (@bytesList) {
		my $delim = ($i == 2) ? 'ff:fe' : '';
		$delim .= (($i++ % 2) == 0) ? '' : ':';
		$result = join($delim, $result, $bytes)
	}
	return $result;
}

# 
sub readCommand() {
	foreach my $node (keys(%nodeCommandMap)) {
		my $commandFile = "./command.$nodeCommandMap{$node}->{$node.'_NAME'}.txt";

		local (*INPUT);
		unless (open(INPUT, $commandFile)) {
			print STDERR "open $commandFile: $!";
			return (&FALSE);
		}

		for (my $number=1; <INPUT>; $number ++) {
			chomp;
			my $line = $_;

			# processing comment
			if ($line =~ /^#/) {
				next;
			}
			# processing empty line
			if ($line =~ /^\s*$/) {
				next;
			}

			if ($line =~ /^\s*(\S+)\s+(.+)$/) {
				my $key = $1;
				my $value = $2;

				$value =~ s/MY/$node/g;
				$nodeCommandMap{$node}->{$node.'_'.$key} = $value;
			}
		}

		close(INPUT);
	}
	return (&TRUE);
}

sub makeScenario() {
	## 
	my %targetMap = (
					 'TARHost1' => '',
					 'TARHost2' => '',
					 'TARRouter1' => '',
					 'TARRouter2' => '',
					);

	unless (allocateTargetMap(\%targetMap)) {
		return (&FALSE);
	}

	unless (makeDirectory($destinationDir)) {
		return(&FALSE);
	}

	## set TEST TARGET
	$| = &TRUE;
	foreach my $target (sort(keys(%targetMap))) {
		my $key = $targetMap{$target}->{'ID'}.'_TYPE';
		if ($targetMap{$target}->{$key} eq 'host') {
			makeHostScenario($target, \%targetMap);
		}
		elsif ($targetMap{$target}->{$key} eq 'router') {
			makeRouterScenario($target, \%targetMap);
		}
	}
	$| = &FALSE;
}

sub allocateTargetMap($) {
	my ($targetMap) = @_;

	my $numHost = 0, $numRouter = 0;
	foreach my $node (sort(keys(%nodeMap))) {
		unless ($node =~ /TAR\d/) {
			next;
		}

		my $targetType = $nodeMap{$node}->{$node.'_TYPE'};
		my $target;
		if ($targetType eq 'host') {
			if (++$numHost gt 2) {
				print STDERR "the number of TYPE=host is just two. $numHost\n";
				return (&FALSE);
			}
			$target = 'TARHost'.$numHost;
		} elsif ($targetType eq 'router') {
			if (++$numRouter gt 2) {
				print STDERR "the number of TYPE=router is just two. $numRouter\n";
				return (&FALSE);
			}
			$target = 'TARRouter'.$numRouter;
		} else {
			print STDERR "the number of TYPE=router is just two.\n";
			return (&FALSE);
		}

		$targetMap->{$target} = $nodeMap{$node};
	}

	return (&TRUE);
}

## 
sub makeHostScenario($$) {
	my ($target, $targetMap) = @_;
	my %nodeNameMap = ('TEST-TAR-HOST' => $target,
					   'NOTEST-TAR-HOST' => '',
					   'NOTEST-TAR-ROUTER1' => '',
					   'NOTEST-TAR-ROUTER2' => '');

	my $numRouter = 0;
	foreach my $tar (sort(keys(%$targetMap))) {
		if ($targetMap->{$target} eq $targetMap->{$tar}) {
			next;
		}

		my $type = $targetMap->{$tar}->{$targetMap->{$tar}->{'ID'}.'_TYPE'};
		if ($type eq 'host') {
			$nodeNameMap{'NOTEST-TAR-HOST'} = $tar;
		} else {
			$numRouter++;
			$nodeNameMap{"NOTEST-TAR-ROUTER$numRouter"} = $tar;
		}
	}

	my $sourcePrefix = "$logoMap{'LOGO_TYPE'}.host.";
	my $files = readPrefixFiles($sourcePrefix);
	my $id = $targetMap->{$target}->{'ID'};
	my $name = $nodeMap{$id}->{$id.'_NAME'};
	my $dir = "$destinationDir/host.$name";
	print "host.$name (".@$files." tests): ";
	unless (makeDirectory($dir)) {
		return (&FALSE);
	}

	open(PERL, ">replace.pl") || die;
	print PERL ("\$dir = shift(\@ARGV); foreach (\@ARGV) {\n");
	print PERL ("\topen(IN, \"<\$_\") or next;\n");
	print PERL ("\topen(OUT, \">\$dir/\$_\") or next;\n");
	print PERL ("\twhile(<IN>) {\n");
	print PERL ("\t\t", replaceNodeName(\%nodeNameMap, $targetMap));
	print PERL ("\t\t", replaceCommand());
	print PERL ("\t\t", replaceKeyword());
	print PERL ("\t\t", replaceMisc());
	print PERL ("\t\tprint OUT;\n");
	print PERL ("\t}\n");
	print PERL ("\tclose(IN); close(OUT);\n");
	print PERL ("}\n");
	print PERL ("exit(0);\n");
	close(PERL);

	system('perl', 'replace.pl', $dir, @$files);

	print "done\n";
	unlink("replace.pl");

	return (&TRUE);
}

## 
sub makeRouterScenario($$) {
	my ($target, $targetMap) = @_;
	my %nodeNameMap = ('TEST-TAR-ROUTER' => $target,
					   'NOTEST-TAR-ROUTER' => '',
					   'NOTEST-TAR-HOST1' => '',
					   'NOTEST-TAR-HOST2' => '',
					  );

	my $numHost = 0;
	foreach my $tar (sort(keys(%$targetMap))) {
		if ($targetMap->{$target} eq $targetMap->{$tar}) {
			next;
		}

		my $type = $targetMap->{$tar}->{$targetMap->{$tar}->{'ID'}.'_TYPE'};
		if ($type eq 'host') {
			$numHost++;
			$nodeNameMap{"NOTEST-TAR-HOST$numHost"} = $tar;
		} else {
			$nodeNameMap{'NOTEST-TAR-ROUTER'} = $tar;
		}
	}

	my $sourcePrefix = "$logoMap{'LOGO_TYPE'}.router.";
	my $files = readPrefixFiles($sourcePrefix);
	my $id = $targetMap->{$target}->{'ID'};
	my $name = $nodeMap{$id}->{$id.'_NAME'};
	my $dir = "$destinationDir/router.$name";
	print "router.$name (".@$files." tests): ";
	unless (makeDirectory($dir)) {
		return (&FALSE);
	}

	open(PERL, ">replace.pl") || die;
	print PERL ("\$dir = shift(\@ARGV); foreach (\@ARGV) {\n");
	print PERL ("\topen(IN, \"<\$_\") or next;\n");
	print PERL ("\topen(OUT, \">\$dir/\$_\") or next;\n");
	print PERL ("\twhile(<IN>) {\n");
	print PERL ("\t\t", replaceNodeName(\%nodeNameMap, $targetMap));
	print PERL ("\t\t", replaceCommand());
	print PERL ("\t\t", replaceKeyword());
	print PERL ("\t\t", replaceMisc());
	print PERL ("\t\tprint OUT;\n");
	print PERL ("\t}\n");
	print PERL ("\tclose(IN); close(OUT);\n");
	print PERL ("}\n");
	print PERL ("exit(0);\n");
	close(PERL);

	system('perl', 'replace.pl', $dir, @$files);
	print "done\n";
	unlink("replace.pl");

	return (&TRUE);
}

# 
sub makeDirectory($) {
	my ($dir) = @_;
	unless (mkdir($dir, 0755)) {
		print STDERR "$dir: $!\n";
		return(&FALSE);
	}
	return(&TRUE);
}

#
sub readPrefixFiles($) {
	my ($prefix) = @_;
	my $files = readDirectory('.');
	my @result;
	foreach my $file (@$files) {
		if($file =~ /^$prefix.*$/) {
			push @result, $file;
		}
	}
	return \@result;
}
#
sub readDirectory($) {
	my ($dir) = @_;
	opendir(DIR, $dir) || die "can't opendir $dir: $!";

	my @result;
	while (defined($file = readdir(DIR))) {
		if ($file eq '.' || $file eq '..') {
			next;
		}
		push @result, $file;
	}
    closedir DIR;
	return \@result;
}

##
sub replaceScript($$) {
	my ($key, $value) = @_;
	$key =~ s/([\\\/])/\\$1/g;
	$value =~ s/([\\\/])/\\$1/g;
	return "s/$key/$value/g;\n";
}

sub replaceNodeName($$) {
	my ($nodeNameMap, $targetMap) = @_;
	my @x = ();
	foreach my $key (sort(keys(%$nodeNameMap))) {
                push(@x, replaceScript($key, $targetMap->{$nodeNameMap->{$key}}->{'ID'}));
	}
	return @x;
}

sub replaceCommand() {
	my @x = ();
	foreach my $node (keys(%nodeCommandMap)) {
		my $map = $nodeCommandMap{$node};
		foreach my $key (keys(%$map)) {
			push(@x, replaceScript($key, $map->{$key}));
		}
	}
	return @x;
}

##
sub replaceKeyword() {
	my @x = ();
	foreach my $node (keys(%nodeMap)) {
		my $map = $nodeMap{$node};
		foreach my $key (sort {$b cmp $a} (keys(%$map))) {
			push(@x, replaceScript($key, $map->{$key}));
		}
	}
	return @x;
}

##
sub replaceMisc() {
	my @x = ();
	foreach my $key (keys(%miscMap)) {
		push(@x, replaceScript($key, $miscMap{$key}));
	}
	return @x;
}

# 
sub makeEnvironment() {
	local (*OUTPUT);

	my $outputFile = "> $destinationDir/environment.def";
	unless (open(OUTPUT, $outputFile)) {
		print STDERR "open: $outputFile: $!";
		return (&FALSE);
	}

	# TAR1
	print(OUTPUT "host $tar1Map{'ID'} {\n");
	## interface loopback
    print(OUTPUT "    interface lo0 {\n");
	print(OUTPUT "        ipv4 v4loop     \"127.0.0.1\";\n");
	print(OUTPUT "        ipv6 v6loop     \"::1\";\n");
	print(OUTPUT "        ipv6 v6linkloop \"fe80::1\";\n");
	print(OUTPUT "    }\n\n");
	## interface for tg
	print(OUTPUT "    interface $tar1Map{'TAR1_IFTG'} {\n");
	print(OUTPUT "        ipv4 v4$tar1Map{'TAR1_IFTG'} \"$tar1Map{'TAR1_IFTG_V4_ADDR'}\";\n");
	print(OUTPUT "    }\n\n");
	## tgagent
	print(OUTPUT "    tgagent v4$tar1Map{'TAR1_IFTG'} 20001;\n}\n\n");

	# TAR2
	print(OUTPUT "host $tar2Map{'ID'} {\n");
	## interface loopback
    print(OUTPUT "    interface lo0 {\n");
	print(OUTPUT "        ipv4 v4loop     \"127.0.0.1\";\n");
	print(OUTPUT "        ipv6 v6loop     \"::1\";\n");
	print(OUTPUT "        ipv6 v6linkloop \"fe80::1\";\n");
	print(OUTPUT "    }\n\n");
	## interface for tg
	print(OUTPUT "    interface $tar2Map{'TAR2_IFTG'} {\n");
	print(OUTPUT "        ipv4 v4$tar2Map{'TAR2_IFTG'} \"$tar2Map{'TAR2_IFTG_V4_ADDR'}\";\n");
	print(OUTPUT "    }\n\n");
	## tgagent
	print(OUTPUT "    tgagent v4$tar2Map{'TAR2_IFTG'} 20001;\n}\n\n");

	# TAR3
	print(OUTPUT "host $tar3Map{'ID'} {\n");
	## interface loopback
    print(OUTPUT "    interface lo0 {\n");
	print(OUTPUT "        ipv4 v4loop     \"127.0.0.1\";\n");
	print(OUTPUT "        ipv6 v6loop     \"::1\";\n");
	print(OUTPUT "        ipv6 v6linkloop \"fe80::1\";\n");
	print(OUTPUT "    }\n\n");
	## interface for tg
	print(OUTPUT "    interface $tar3Map{'TAR3_IFTG'} {\n");
	print(OUTPUT "        ipv4 v4$tar3Map{'TAR3_IFTG'} \"$tar3Map{'TAR3_IFTG_V4_ADDR'}\";\n");
	print(OUTPUT "    }\n\n");
	## tgagent
	print(OUTPUT "    tgagent v4$tar3Map{'TAR3_IFTG'} 20001;\n}\n\n");

	# TAR4
	print(OUTPUT "host $tar4Map{'ID'} {\n");
	## interface loopback
    print(OUTPUT "    interface lo0 {\n");
	print(OUTPUT "        ipv4 v4loop     \"127.0.0.1\";\n");
	print(OUTPUT "        ipv6 v6loop     \"::1\";\n");
	print(OUTPUT "        ipv6 v6linkloop \"fe80::1\";\n");
	print(OUTPUT "    }\n\n");
	## interface for tg
	print(OUTPUT "    interface $tar4Map{'TAR4_IFTG'} {\n");
	print(OUTPUT "        ipv4 v4$tar4Map{'TAR4_IFTG'} \"$tar4Map{'TAR4_IFTG_V4_ADDR'}\";\n");
	print(OUTPUT "    }\n\n");
	## tgagent
	print(OUTPUT "    tgagent v4$tar4Map{'TAR4_IFTG'} 20001;\n}\n\n");

	# REF1
	print(OUTPUT "host $ref1Map{'ID'} {\n");
	## interface loopback
    print(OUTPUT "    interface lo0 {\n");
	print(OUTPUT "        ipv4 v4loop     \"127.0.0.1\";\n");
	print(OUTPUT "        ipv6 v6loop     \"::1\";\n");
	print(OUTPUT "        ipv6 v6linkloop \"fe80::1\";\n");
	print(OUTPUT "    }\n\n");
	## interface for tg
	print(OUTPUT "    interface $ref1Map{'REF1_IFTG'} {\n");
	print(OUTPUT "        ipv4 v4$ref1Map{'REF1_IFTG'} \"$ref1Map{'REF1_IFTG_V4_ADDR'}\";\n");
	print(OUTPUT "    }\n\n");
	## tgagent
	print(OUTPUT "    tgagent v4$ref1Map{'REF1_IFTG'} 20001;\n}\n\n");

	# REF2
	print(OUTPUT "host $ref2Map{'ID'} {\n");
	## interface loopback
    print(OUTPUT "    interface lo0 {\n");
	print(OUTPUT "        ipv4 v4loop     \"127.0.0.1\";\n");
	print(OUTPUT "        ipv6 v6loop     \"::1\";\n");
	print(OUTPUT "        ipv6 v6linkloop \"fe80::1\";\n");
	print(OUTPUT "    }\n\n");
	## interface for tg
	print(OUTPUT "    interface $ref2Map{'REF2_IFTG'} {\n");
	print(OUTPUT "        ipv4 v4$ref2Map{'REF2_IFTG'} \"$ref2Map{'REF2_IFTG_V4_ADDR'}\";\n");
	print(OUTPUT "    }\n\n");
	## tgagent
	print(OUTPUT "    tgagent v4$ref2Map{'REF2_IFTG'} 20001;\n}\n\n");

	# DUMPER
	print(OUTPUT "host $dumperMap{'ID'} {\n");
	## interface loopback
    print(OUTPUT "    interface lo0 {\n");
	print(OUTPUT "        ipv4 v4loop     \"127.0.0.1\";\n");
	print(OUTPUT "        ipv6 v6loop     \"::1\";\n");
	print(OUTPUT "        ipv6 v6linkloop \"fe80::1\";\n");
	print(OUTPUT "    }\n\n");
	## interface for tg
	print(OUTPUT "    interface $dumperMap{'DUMPER_IFTG'} {\n");
	print(OUTPUT "        ipv4 v4$dumperMap{'DUMPER_IFTG'} \"$dumperMap{'DUMPER_IFTG_V4_ADDR'}\";\n");
	print(OUTPUT "    }\n\n");
	## tgagent
	print(OUTPUT "    tgagent v4$dumperMap{'DUMPER_IFTG'} 20001;\n}\n\n");

	close (OUTPUT);
	return (&TRUE);
}

#
sub makeCollectionScript() {
	@tgAddrList = ($tar1Map{'TAR1_IFTG_V4_ADDR'},
				   $tar2Map{'TAR2_IFTG_V4_ADDR'},
				   $tar3Map{'TAR3_IFTG_V4_ADDR'},
				   $tar4Map{'TAR4_IFTG_V4_ADDR'},
				   $ref1Map{'REF1_IFTG_V4_ADDR'},
				   $ref2Map{'REF2_IFTG_V4_ADDR'},
				   $dumperMap{'DUMPER_IFTG_V4_ADDR'},
				   );

	local(*OUTPUT);
	my $outputFile = "> $destinationDir/collect_result.sh";
	unless (open(OUTPUT, $outputFile)) {
		print STDERR "open: $outputFile: $!";
		return (&FALSE);
	}
	print(OUTPUT "#!/bin/sh\n");

	foreach my $addr (@tgAddrList) {
		print(OUTPUT 'scp -r $1@');
		print(OUTPUT "$addr:/tmp/1.* .\n");
	}

	close(OUTPUT);
	my $mode = 0755;
	chmod $mode, "$destinationDir/collect_result.sh";
	return (&TRUE);
}

# 
sub makeTestScript() {
	local(*OUTPUT);
	my $testDirs = readDirectory($destinationDir);
	foreach my $dir (@$testDirs) {
		my $outputFile = "> $destinationDir/test.$dir.sh";
		unless (open(OUTPUT, $outputFile)) {
			print STDERR "open: $outputFile: $!";
			return (&FALSE);
		}
		print(OUTPUT "#!/bin/sh\n");

		my $tests = readDirectory("$destinationDir/$dir");
		foreach my $test (@$tests) {
			print(OUTPUT "velm -e environment.def -s $dir/$test interop\n");
		}
		close (OUTPUT);
	}

	my $outputFile = "> $destinationDir/test.sh";
	my $mode = 0755;
	unless (open(OUTPUT, $outputFile)) {
		print STDERR "open: $outputFile: $!";
		return (&FALSE);
	}
	chmod $mode, "$destinationDir/test.sh";
	print(OUTPUT "#!/bin/sh\n");
	foreach my $dir (@$testDirs) {
		print(OUTPUT "./test.$dir.sh\n");
		chmod $mode, "$destinationDir/test.$dir.sh";
	}
	close(OUTPUT);

	return (&TRUE);
}
