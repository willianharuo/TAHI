#!/usr/bin/perl -w
#
# Copyright (C) 2004, 2005, 2006, 2007, 2008, 2009, 2010
# NTT Advanced Technology, Yokogawa Electric Corporation.
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
# $TAHI: koi/libdata/kRemote/kRemote.pm,v 1.8 2006/06/30 07:10:27 akisada Exp $
#
# $Id: kRemote.pm,v 1.4 2008/06/03 07:40:00 akisada Exp $
#

package kRemote;

use Expect;
use Exporter;

@ISA = qw(Exporter);
@EXPORT = qw(
	kRemoteInit
	kRemoteOpen
	kRemoteClose

	kRemoteLogin
	kRemoteSubstituteRoot
	kRemoteSubstituteRootWait
	kRemoteLogout
	kRemoteLogoutWait
	kRemoteLogoutNoWait

	kRemoteReboot
	kRemoteCommand
	kRemoteCommandWait
	kRemoteWriteFile
	kRemoteCopy

	kRemoteOpt

	rOpen
	rClose
	rLogin

	rReboot
);

##
# exported subroutines prototype
##
sub kRemoteInit(;$$);

sub kRemoteOpen();
sub kRemoteClose();

sub kRemoteLogin($);
sub kRemoteSubstituteRoot();
sub kRemoteSubstituteRootWait();
sub kRemoteLogout(;$);
sub kRemoteLogoutWait(;$);
sub kRemoteLogoutNoWait(;$);

sub kRemoteReboot($);
sub kRemoteCommand($$);
sub kRemoteCommandWait($$);
sub kRemoteWriteFile($$;@);
sub kRemoteCopy($$$);

sub rOpen();
sub rClose();
sub rLogin($);
sub rLogout($);
sub rReboot($);


##
# inside used subroutines prototype
##
sub waitCommandPrompt();
sub waitQuestionMark();

sub sendMessage($);
sub sendMessages(@);
sub sendMessagesSync(@);

sub parseArgs();
sub readTnDef($);
sub readNutDef($);

sub isIPAddr($);

sub pr($);
sub prErr($);
sub prErrExit($);



##
# exported subroutines
##
sub kRemoteInit(;$$)
{
	my $_function_ = 'kRemoteInit';

	# parse args
	parseArgs();

	# read tn.def
	my $tn = '/usr/local/koi/etc/tn.def';
	%TnDef = readTnDef($tn);
	if (exists($TnDef{'error'})) {
		prErr("$_function_:\n$TnDef{'error'}\n");
	}

	# check tn.def environment
	my $_command_ = defined($TnDef{'RemoteMethod'})
		? $TnDef{'RemoteMethod'}
		: 'cu';
	unless (exists($remote_cmd{$_command_})) {
		prErrExit("$_function_: ".
			  "undefined \$RemoteMethod($_command_)\n");
	}
	$RemoteMethod = $_command_;

	$RemoteTarget = $TnDef{'RemoteTarget'};
	unless (defined($RemoteTarget)) {
		if ($RemoteMethod eq 'ssh'
		    || $RemoteMethod eq 'telnet') {
			prErrExit("$_function_: ".
				  "RemoteTarget directive was undefined\n");
		}
		elsif ($RemoteMethod eq 'cu') {
			$RemoteTarget = 'cuaa0';
		}
	}

	if (($RemoteMethod eq 'ssh' || $RemoteMethod eq 'telnet')
	    && !isIPAddr($RemoteTarget)) {
		prErrExit("$_function_: ".
			  "$RemoteMethod need IP address\n");
	}

	# read nut.def
	my $nut = '/usr/local/koi/etc/nut.def';
	%NutDef = readNutDef($nut);
	if (exists($NutDef{'error'})) {
		prErr("$_function_:\n$NutDef{'error'}\n");
	}

	# check nut.def environment
	$System = $NutDef{'System'};

	$UserID = $NutDef{'UserID'};
	unless (defined($UserID)) {
		prErrExit("$_function_: ".
			  "UserID directive was undefined\n");
	}

	$UserPassword = $NutDef{'UserPassword'};
	unless (defined($UserPassword)) {
		prErrExit("$_function_: ".
			  "UserPassword directive was undefined\n");
	}

	$RootID = $NutDef{'RootID'};
	unless (defined($RootID)) {
		$RootID = 'root';
	}

	$RootPassword = $NutDef{'RootPassword'};
	unless (defined($RootPassword)) {
		prErrExit("$_function_: ".
			  "RootPassword directive was undefined\n");
	}

	if (exists($NutDef{'LoginPrompt'})) {
		$prompt_login{$System} = $NutDef{'LoginPrompt'};
	}

	if (exists($NutDef{'PasswordPrompt'})) {
		$prompt_password{$System} = $NutDef{'PasswordPrompt'};
	}

	if (exists($NutDef{'EscapePrompt'})) {
		$prompt_escape{$System} = $NutDef{'EscapePrompt'};
	}

	pr("tn.def...\n");
	foreach my $key (sort(keys(%TnDef))) {
		pr("\t$key => $TnDef{$key}\n");
	}
	pr("nut.def...\n");
	foreach my $key (sort(keys(%NutDef))) {
		pr("\t$key => $NutDef{$key}\n");
	}

	# check prompt
	unless (exists($prompt_login{$System})) {
		$prompt_login{$System} = $prompt_login{'default'};
	}

	unless (exists($prompt_password{$System})) {
		$prompt_password{$System} = $prompt_password{'default'};
	}

	unless (exists($prompt_escape{$System})) {
		$prompt_escape{$System} = $prompt_escape{'default'};
	}

	unless (exists($prompt_command{$System})) {
		$prompt_command{$System} = $prompt_command{'default'};
	}

	unless (exists($prompt_command_root{$System})) {
		$prompt_command_root{$System} =
			$prompt_command_root{'default'};
	}
}


sub kRemoteOpen()
{
	my $_function_ = 'kRemoteOpen';

	if (defined($expect)) {
		prErr("$_function_: session has already opened.\n");
		return undef;
	}

	# initialize
	my $command = $TnDef{'RemoteMethod'};

	# make command
	if ($command eq 'cu') {
		$command .= " -l $TnDef{'RemoteTarget'}";
	}
	elsif ($command eq 'ssh'
	       || $command eq 'telnet') {
		$command .= " -l $UserID";
		$command .= " $TnDef{'RemoteTarget'}";
	}

	# spawn
	$expect = Expect->spawn("$command\r");
	unless (defined($expect)) {
		prErr("$_function_: cannot spawn $command: $!\n");
		return undef;
	}

	$expect->debug(2) if $EXPECT_DEBUG;
	$expect->log_stdout(1) if $EXPECT_DEBUG;

	return $TRUE;
}


sub kRemoteClose()
{
	$expect->soft_close();
	$expect = undef;
}


sub kRemoteLogin($)
{
	my ($timeout) = @_;

	my $_function_ = 'kRemoteLogin';

	my @match_patterns =
		(
		 [qr/\(yes\/no\)\?/ =>
		  sub { my $self = shift;
			$self->send("yes\n");
			exp_continue; }
		 ],
		 [qr/onnect/ =>
		  sub { my $self = shift;
			$self->send("\n");
			exp_continue; }
		 ],
		 [qr/$prompt_login{$System}/ =>
		  sub {my $self = shift;
		       $self->send("$UserID\n");
		       exp_continue; }
		 ],
		 [qr/$prompt_password{$System}/ =>
		  sub { my $self = shift;
			$self->send("$UserPassword\n");
			exp_continue; }
		 ],
		 '-re', qr"$prompt_command{$System}"
		);

	my $index = $expect->expect($timeout, @match_patterns);
	unless (defined($index)) {
		prErr("$_function_: fail to login.\n");
		return(undef);
	}

	return $TRUE;
}


sub kRemoteLogout(;$)
{
	my ($timeout) = @_;

	sendMessages("exit\r");

	if ($RemoteMethod_ eq 'cu') {
		sendMessages("~.\r");
		sendMessages("~.\r");
		sendMessages("~.\r");
	}
	elsif ($RemoteMethod eq 'ssh') {
		# do nothing
	}

	return $TRUE;
}

sub
kRemoteLogoutWait(;$)
{
	my ($timeout) = @_;

	my $_function_ = 'kRemoteLogoutWait';

	if($RemoteMethod eq 'cu') {
		return($TRUE);
	}

	unless(defined($expect)) {
		prErr("$_function_: no Expect object\n");
		return(undef);
	}

	unless(defined($prompt_command{$System})) {
		prErr("$_function_: undefied type $System\n");
		return(undef);
	}

	sendMessagesSync("\r");

	unless(defined(waitCommandPrompt())) {
		prErr("$_function_: waitCommandPrompt() failure\n");
		return(undef);
	}

	sendMessages("exit\r");

	waitCommandPrompt();

	return($TRUE);
}



sub
kRemoteLogoutNoWait(;$)
{
	my ($timeout) = @_;

	my $_function_ = 'kRemoteLogoutNoWait';

	unless(defined($expect)) {
		prErr("$_function_: no Expect object\n");
		return(undef);
	}

	unless(defined($prompt_command{$System})) {
		prErr("$_function_: undefied type $System\n");
		return(undef);
	}

	sendMessagesSync("\r");

	unless(defined(waitCommandPrompt())) {
		prErr("$_function_: waitCommandPrompt() failure\n");
		return(undef);
	}

	sendMessages("exit\r");

	if($RemoteMethod_ eq 'cu') {
		sendMessages("~.\r");
		sendMessages("~.\r");
		sendMessages("~.\r");
	} elsif ($RemoteMethod eq 'ssh') {
		# do nothing
	}

	return($TRUE);
}



sub kRemoteReboot($)
{
	my ($timeout) = @_;

	my $_function_ = 'kRemoteReboot';

	my $ret;
	$ret = kRemoteSubstituteRoot();
	unless (defined($ret)) {
		prErr("$_function_: fail to substitue root");
		return(undef);
	}

	sendMessagesSync("shutdown -r now\r");

	# stop substituting user id
	sendMessages("exit\r");

	return $TRUE;
}


sub kRemoteCommand($$)
{
	my ($command, $timeout) = @_;

	my $_function_ = 'rCommand';

	unless (defined($expect)) {
		prErr("$_function_: no Expect object\n");
		return undef;
	}

	unless (defined($prompt_command{$System})) {
		prErr("$_function_: undefied type $System\n");
		return undef;
	}

	# get command prompt
	waitCommandPrompt();

	sendMessagesSync("$command\r");

	return 1;
}



sub
kRemoteCommandWait($$)
{
	my ($command, $timeout) = @_;

	my $_function_ = 'kRemoteCommandWait';

	sendMessagesSync("\r");

	unless(defined(kRemoteCommand($command, $timeout))) {
		prErr("$_function_: kRemoteCommand() failure\n");
		return(undef);
	}

	unless(defined(waitCommandPrompt())) {
		prErr("$_function_: waitCommandPrompt() failure\n");
		return undef;
	}

	return 1;
}



sub
kRemoteWriteFile($$;@)
{
	my ($file, $timeout, @lines) = @_;

	my $_function_ = 'kRemoteWriteFile';

	unless(defined($expect)) {
		prErr("$_function_: no Expect object\n");
		return(undef);
	}

	unless(defined($prompt_command{$System})) {
		prErr("$_function_: undefied type $System\n");
		return(undef);
	}

	unless(defined(sendMessagesSync("\r"))) {
		prErr("$_function_: sendMessagesSync() failure\n");
		return(undef);
	}

	unless(defined(waitCommandPrompt())) {
		prErr("$_function_: waitCommandPrompt() failure\n");
		return(undef);
	}

	unless(defined(sendMessagesSync("cat > $file << EOF\r"))) {
		prErr("$_function_: sendMessagesSync() failure\n");
		return(undef);
	}

	foreach my $line (@lines) {
		unless(defined(waitQuestionMark())) {
			prErr("$_function_: waitQuestionMark() failure\n");
			return(undef);
		}

		unless(defined(sendMessagesSync("$line\r"))) {
			prErr("$_function_: sendMessagesSync() failure\n");
			return(undef);
		}
	}

	unless(defined(waitQuestionMark())) {
		prErr("$_function_: waitQuestionMark() failure\n");
		return(undef);
	}

	unless(defined(sendMessagesSync("EOF\r"))) {
		prErr("$_function_: sendMessagesSync() failure\n");
		return(undef);
	}

	unless(defined(waitCommandPrompt())) {
		prErr("$_function_: waitCommandPrompt() failure\n");
		return(undef);
	}

	unless(defined(sendMessagesSync("cat -n $file\r"))) {
		prErr("$_function_: sendMessagesSync() failure\n");
		return(undef);
	}

	unless(defined(waitCommandPrompt())) {
		prErr("$_function_: waitCommandPrompt() failure\n");
		return(undef);
	}

	return(1);
}



sub kRemoteCopy($$$)
{
	my ($from, $to, $timeout) = @_;

	my $_function_ = 'kRemoteCopy';

	my $_command_ = defined($RemoteMethod)
		? $remote_copy_cmd{$RemoteMethod}
		: $remote_copy_cmd{'cu'};

	unless (defined($_command_)) {
		prErr("$_function_: undefind command($_command_)\n");
		return undef;
	}

	# XXX
	# process for logining already
	if ($_command_ eq 'scp') {
		$_command_ .= " $from $UserID\@$RemoteTarget:$to";

		$expect = Expect->spawn("$_command_");
		unless (defined($expect)) {
			prErr("$_function_: cannot spawn $_command_: $!\n");
			return undef;
		}

		my @match_patterns =
			(
			 [qr/\(yes\/no\)\?/ =>
			  sub { my $self = shift;
				$self->send("yes\n");
				exp_continue; }
			 ],
			 [qr/$prompt_login{$System}/ =>
			  sub {my $self = shift;
			       $self->send("$UserID\n");
			       exp_continue; }
			 ],
			 [qr/$prompt_password{$System}/ =>
			  sub { my $self = shift;
				$self->send("$UserPassword\n");
				exp_continue; }
			 ],
			);

		my $index = $expect->expect($timeout, @match_patterns);
		unless (defined($index)) {
			prErr("$_function_: fail to copy.\n");
			return(undef);
		}

		pr("$_function_: Copying completed\n");
	}
	elsif ($_command_ eq 'cu') {
		sendMessages("~p");
		sendMessages("$from $to\r");
		my $index = waitCommandPrompt();
		unless (defined($index)) {
			prErr("$_function_: Never sync with copy...\n");
			return undef;
		}

		# it's important if prompt pattern is ``^(>|#) ''
		sendMessages("\r");
		$index = waitCommandPrompt();
		unless (defined($index)) {
			prErr("$_function_: Never sync with copy......\n");
			return undef;
		}

		pr("$_function_: Copying completed\n");
	}

	return $TRUE;
}


##
# inside used subroutines
##
sub parseArgs()
{
	my $_function_ = 'parseArgs';

	my($v, $lval, $rval);
	while ($v = shift(@ARGV)) {
		($lval, $rval) = split(/=/, $v, 2);
		if ($rval =~ /^\s*$/) {
			$rval = 1;
		}

		$kRemoteOpt{$lval} = $rval;
	}
}


sub readTnDef($)
{
	my ($tn) = @_;

	my $_function_ = 'readTnDef';

	unless (open(FILE, "$tn")) {
		prErrExit("$_function_: can not open $tn\n");
	}

	my $i = 1;
	while (<FILE>) {
		if (/^\s*$/ || /^#/) {
			next; # skip comment
		}

		chomp;
		my $name;
		my $value;
		if ( /^(\S+)\s+(\S+)/ ) {
			$name = $1;
			$value = $2;
			$TnDef{$name} = $value;
		}

		if (/^(RemoteTarget)\s+(.*)/
		    || /^(RemoteMethod)\s+(.*)/) {
		    #prLog("<TR><TD>$name</TD><TD>$value</TD></TR>");
		}
		elsif (/^(Link[0-9]+)\s+(\S+)/) {
			$TnDef{$name."_device"} = $value;
		}
		else {
			$TnDef{'error'} .= "line $i : unknown directive $_\n";
		}

		$i++;
	}

	close FILE;

	return %TnDef;
}

sub readNutDef($)
{
	my ($nut) = @_;

	my $_function_ = 'readNutDef';

	unless (open(FILE, "$nut")) {
		prErrExit("$_function_: can not open $nut\n");
	}

	my $i = 1;
	while (<FILE>) {
		if (/^\s*$/ || /^#/) {
			next; # skip comment
		}

		chomp;
		my $name;
		my $value;
		if ( /^(\S+)\s+(.*)/ ) {
			$name = $1;
			$value = $2;

			$NutDef{$name} = $value;
		}

		if ($name eq 'System'
		    || $name eq 'TargetName'
		    || $name eq 'HostName'
		    || $name eq 'Type') {
		    #prLog("<TR><TD>$name</TD><TD>$value</TD></TR>");
		}
		elsif ($name eq 'UserID'
		       || $name eq 'UserPassword'
		       || $name eq 'RootID'
		       || $name eq 'RootPassword') {
			$NutDef{$name} = $value;
		}
		elsif ($name eq 'UserPrompt') {
			$prompt_command{$NutDef{'System'}} = $value;
		}
		elsif ($name eq 'RootPrompt') {
			$prompt_command_root{$NutDef{'System'}} = $value;
		}
		elsif ($name eq 'LoginPrompt') {
			$prompt_login{$NutDef{'System'}} = $value;
		}
		elsif ($name eq 'PasswordPrompt') {
			$prompt_password{$NutDef{'System'}} = $value;
		}
		elsif ($name eq 'EscapePrompt') {
			$prompt_escape{$NutDef{'System'}} = $value;
		}
		elsif (/^(Link[0-9]+)\s+(\S+)/) {
			$TnDef{$name."_device"} = $value;
		}
		else {
			$NutDef{'error'} .= "line $i : unknown directive $_\n";
		}

		$i++;
	}

	close FILE;

	return %NutDef;
}


sub kRemoteSubstituteRoot()
{
	if ($RemoteMethod eq 'cu') {
		return $TRUE;
	}

	# substitute user id
	sendMessagesSync("su\r");
	my @match_patterns =
		(
		 [qr/\(yes\/no\)\?/ =>
		  sub { my $self = shift;
			$self->send("yes\n");
			exp_continue; }
		 ],
		 [qr/$prompt_login{$System}/ =>
		  sub {my $self = shift;
		       $self->send("$UserID\n");
		       exp_continue; }
		 ],
		 [qr/$prompt_password{$System}/ =>
		  sub { my $self = shift;
			$self->send("$RootPassword\n");
			exp_continue; }
		 ],
		 '-re', qr"$prompt_command_root{$System}"
		);

	my $index = $expect->expect($timeout, @match_patterns);

	unless (defined($index)) {
		return(undef);
	}

	return $TRUE;
}


sub
kRemoteSubstituteRootWait()
{
	my $_function_ = 'kRemoteSubstituteRootWait';

	if($RemoteMethod eq 'cu') {
		return($TRUE);
	}

	sendMessagesSync("\r");

	unless(defined(waitCommandPrompt())) {
		prErr("$_function_: waitCommandPrompt() failure\n");
		return(undef);
	}

	# substitute user id
	sendMessagesSync("su\r");

	my @match_patterns =
		(
		 [qr/\(yes\/no\)\?/ =>
		  sub { my $self = shift;
			$self->send("yes\n");
			exp_continue; }
		 ],
		 [qr/$prompt_login{$System}/ =>
		  sub {my $self = shift;
		       $self->send("$UserID\n");
		       exp_continue; }
		 ],
		 [qr/$prompt_password{$System}/ =>
		  sub { my $self = shift;
			$self->send("$RootPassword\n");
			exp_continue; }
		 ],
		 '-re', qr"$prompt_command_root{$System}"
		);

	my $index = $expect->expect($timeout, @match_patterns);
	unless(defined($index)) {
		return(undef);
	}

#	unless(defined(waitCommandPrompt())) {
#		prErr("$_function_: waitCommandPrompt() failure\n");
#		return(undef);
#	}

	return($TRUE);
}


sub sendMessage($)
{
	my ($message) = @_;

	if ($SendSpeed == 0) {
		$expect->send($message);
	}
	else {
		$expect->send_slow($SendSpeed, $message);
	}
}


sub sendMessages(@)
{
	my (@strings) = @_;

	foreach (@strings) {
		sendMessage($_);
		# don't wait for echo back
	}
}


sub sendMessagesSync(@)
{
	my (@strings) = @_;

	my $timeout = 5;
	my $_function_ = 'sendMessagesSync';

	foreach (@strings) {
		sendMessage($_);

		# wait for echo back
		my $ret = $expect->expect($timeout, "$_");
		unless (defined($ret)) {
			prErr("$_function_: never got $_");
		}
		else {
			pr("$_function_: got echo back of $_\n");
		}
#		sleep(1);
	}
}


sub waitCommandPrompt()
{
	my $i;
	my $retry = 5;
	for ($i=0; ; $i++) {
		my $ret = $expect->expect($timeout,
					  '-re', qr"$prompt_command{$System}",
					  '-re', qr"$prompt_command_root{$System}");
		if (defined($ret)) {
			pr("$_function_: got command prompt");
			last;
		}

		if ($i >= $retry) {
			prErr("$_function_: never got command prompt\n");
			return undef;
		}

		sendMessages("\r");
	}

	return $TRUE;
}



sub
waitQuestionMark()
{
	my $_function_ = 'waitQuestionMark';

	my $i;
	my $retry = 5;

	for($i=0; ; $i++) {
		my $ret = $expect->expect($timeout,
					  '-re', qr"$prompt_escape{$System}");
		if(defined($ret)) {
			pr("$_function_: got command prompt");
			last;
		}

		if ($i >= $retry) {
			prErr("$_function_: never got command prompt\n");
			return(undef);
		}

		sendMessages("\r");
	}

	return($TRUE);
}



sub isIPAddr($)
{
	my ($addr) = @_;
	if ($addr =~ /^(::ffff:)?\d+\.\d+\.\d+\.\d+$/o) {
		return $TRUE;
	}
	elsif ($addr =~ /^[0-9a-f:]+[%\w]*$/o) {
		return $TRUE;
	}
	else {
		return undef;
	}
}

sub pr($)
{
	my ($message) = @_;

	print STDOUT "$message" if $PRINT_DEBUG;
}

sub prErr($)
{
	my ($message) = @_;

	# prLogHTML("<FONT COLOR=\"#FF0000\">!!! $message</FONT><BR>");
	# $message = HTML2TXT($message);

	print STDERR "$message";
}


sub prErrExit($)
{
	my ($message) = @_;

	prErr($message);
	$! = $InternalErr, die "";
}


##
# V6EvalRemote.pm
##
sub rOpen() { return kRemoteOpen(); }
sub rClose() { return kRemoteClose(); }
sub rLogin($) { return kRemoteLogin(@_); }
sub rLogout($) { return kRemoteLogout(@_); }
sub rReboot($) { return kRemoteReboot(@_); }


BEGIN {
	use constant TRUE => 1;
	use constant FALSE => 0;
	$TRUE = &TRUE;
	$FALSE = &FALSE;

	$PRINT_DEBUG = $FALSE; # $TRUE; # 
	$EXPECT_DEBUG = $FALSE; # $TRUE; # 
	$VERSION  = 1.00;

	##
	# global variables
	##
	$exitPass	= 0;		# Pass
	$exitNS	= 2;		# Not yes Supported
	$exitFail	= 32;		# Fail
	$exitFatal	= 64;	# Fatal

	$expect	= undef;

	$System	= 'default';

	##
	# global variables defined by users
	##
	$UserID = 'tester';
	$UserPassword = 'koi';
	$RootID = 'root';
	$RootPassword = 'koi';

	$RemoteMethod = undef;
	$RemoteTarget = undef;

	$SendSpeed = 0;

	$timeout = 5;

	# variables depending on NUT
	%prompt_login = (
		'default' => '^[L|l]ogin:',
	);

	%prompt_password = (
		'default' => '^[P|p]assword:',
	);

	%prompt_escape = (
		'default' => '\?',
	);

	%prompt_command = (
		'default' => '[$#>:] $',
	);

	%prompt_command_root = (
		'default' => '[$#>:] $',
	);

	# XXX
	# use subroutin reference to make command automatically?
	%remote_cmd = (
		'cu'	=> 'cu',
		'serial'	=> 'cu',
		'telnet'	=> 'telnet',
		'ssh'	=> 'ssh',
	);

	%remote_copy_cmd = (
		'cu'	=> 'cu',
		'serial'	=> 'cu',
		'telnet'	=> 'telnet',
		'ssh'	=> 'scp',
	);

	%kRemoteOpt	= ();

	kRemoteInit();
}

1;
