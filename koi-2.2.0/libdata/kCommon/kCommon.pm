#!/usr/bin/perl
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
# $TAHI: koi/libdata/kCommon/kCommon.pm,v 1.113 2006/06/26 01:12:35 akisada Exp $
#
# $Id: kCommon.pm,v 1.10 2010/07/22 12:58:01 velo Exp $
#



package kCommon;

# use strict;
use Exporter;
use File::Basename;
use IO::Socket;

use POSIX ":sys_wait_h";
# <--------------------------- for v6eval ---------------------------- #
use POSIX qw(tmpnam);
use Fcntl;
# ---------------------------- for v6eval ---------------------------> #
use Errno qw(EINTR);
# use kRemote;

use kDNS;

@ISA = qw(Exporter);
@EXPORT = qw(
	kPacket_ConnectSend
	kPacket_Send
	kPacket_Recv
	kPacket_Close
	kPacket_StartRecv
	kPacket_ConnectInfo
	kPacket_DataInfo
	kPacket_Clear
	kPacket_TlsSetup
	kPacket_TlsClear
	kPacket_ParserAttach
	kPacket_ParserDetach

	kInsert

	kRemote
	kRemoteAsync
	kRemoteAsyncWait

	kSleep

	kDump_Common_Error
	kLogHTML
	kPrint_SIP

	handleChildProcess

	vCPP
	vSend
	vRecv
	vCapture
	vStop
	vClear
);



#----------------------------------------------------------------------#
# Function prototypes                                                  #
#----------------------------------------------------------------------#
sub kPacket_ConnectSend($$$$$$$$$$;$);
sub kPacket_Send($$$);
sub kPacket_Recv($$);
sub kPacket_Close($$);
sub kPacket_StartRecv($$$$$$;$);
sub kPacket_ConnectInfo($);
sub kPacket_DataInfo($);
sub kPacket_Clear($$$$);
sub kPacket_TlsSetup($$$$$$$$$$$$);
sub kPacket_TlsClear($);
sub kPacket_ParserAttach($$$$$);


sub PKTSendCMD($$;$);
sub kWriteUnixDomain($$);
sub kReadUnixDomain($);
sub kCheckDataLength($$);


sub kMakeData($$);
sub kMakeConnectSendAck($);
sub kMakeSendAck($);
sub kMakeRecvAck($);
sub kMakeCloseAck($);
sub kMakeListenAck($);
sub kMakeConnInfoAck($);
sub kMakeDataInfoAck($);
sub kMakeClearAck($);


sub kInetPtoN($$);
sub kInetNtoP($$);


sub kInsert($$;$$$);

sub kRemote($;$@);
sub kRemoteAsync($;$@);
sub kRemoteAsyncWait();

sub kSleep($;$);

sub kInit_Common_Error();
sub kReg_Common_Error($$$$);
sub kDump_Common_Error();

sub kPrint_SIP($;$);

sub kLogHTML($;$);

sub kModule_Initialize(;$$);
sub kModule_Terminate(;$);
sub kBoot_SocketIO($$$);

# internal use
sub forkCmd($$);
sub forkCmdWoCheck($$);
sub forkTcpdump();
sub killTcpdump();

sub handleChildProcess();
sub searchPath($$);
sub parseArgs($$);

sub getPacketInfo($$$);
sub dumpPacket($$);
# sub parseCount($);
sub calcTab($$$$);
sub getVersion();
sub prLogSendPacket($$$);
sub printHTMLHeader();
sub printHTMLFooter();
sub printBanner();
sub prLog($;$);
sub prLogHTML($;$);
sub prOut($);
sub pr($);

sub getDateString();
sub getTimeStamp();

sub addMD5($$$);
sub getMD5($);

# <--------------------------- for v6eval ---------------------------- #
sub vCPP(;@);
sub vSend($@);
sub vRecv($$$$@);
sub vCapture($);
sub vStop($);
sub vClear($);
sub getField(@);
sub v6eval_baseArgs();
sub execCmd($;$);
sub execPktctl($$@;$);
sub getChildStatus();
sub getTimeString($);
sub v6eval_initialize();
sub v6eval_terminate();

our %V6TnDef;
our %V6NutDef;
our @V6TnIfs;
our @V6NutIfs;
our @V6TnSos;
our @PktbufPids;
# ---------------------------- for v6eval ---------------------------> #

our @TnIfs;
our @NutIfs;
our @ProcessPids;
our @TcpdumpPids;
$ExecutingPid;
our $PRINT_DEBUG = 0; # 1; # 

# same value at kRemote
$exitPass = 0;		# Pass
$exitNS = 2;		# Not yes Supported
$exitFail = 32;		# Fail
$exitFatal = 64;	# Fatal

my $storedSIG = ();

#----------------------------------------------------------------------#
# kPacket_ConnectSend()                                                #
#----------------------------------------------------------------------#
sub
kPacket_ConnectSend($$$$$$$$$$;$)
{
	my(
		$protocol,
		$frameid,
		$addrfamily,
		$srcaddr,
		$dstaddr,
		$srcport,
		$dstport,
		$datalen,
		$data,
		$interface,
		$flags,
	) = @_;

	my $function = 'kPacket_ConnectSend';
	kInit_Common_Error();

	$SOCKIO_SEQ ++;
	$SOCKIO_SEQ &= 0xffff;


	#--------------------------------------------------------------#
	# $protocol: 'TCP', 'UDP'                                      #
	#--------------------------------------------------------------#
	unless(defined($protocol)) {
		kReg_Common_Error(__FILE__, __LINE__, $function,
				  "protocol must be defined.");

		return(undef);
	}

	unless(defined($sockio_proto{$protocol})) {
		kReg_Common_Error(__FILE__, __LINE__, $function,
				  "unknown protocol -- $protocol");

		return(undef);
	}

	my $_protocol_ = $sockio_proto{$protocol};


	#--------------------------------------------------------------#
	# $frameid: 'NULL', 'DNS', 'SIP'                               #
	#--------------------------------------------------------------#
	unless(defined($frameid)) { $frameid = 'NULL'; }
	unless(defined($sockio_frame{$frameid})) {
		kReg_Common_Error(__FILE__, __LINE__, $function,
				  "unknown frameid -- $frameid");

		return(undef);
	}

	my $_frameid_ = $sockio_frame{$frameid}->{'id'};


	#--------------------------------------------------------------#
	# $addrfamily: 'INET', 'INET6'                                 #
	#--------------------------------------------------------------#
	unless(defined($addrfamily)) {
		kReg_Common_Error(__FILE__, __LINE__, $function,
				  "addrfamily must be defined.");

		return(undef);
	}

	unless(defined($sockio_af{$addrfamily})) {
		kReg_Common_Error(__FILE__, __LINE__, $function,
				  "unknown addrfamily -- $addrfamily");

		return(undef);
	}

	my $_addrfamily_ = $sockio_af{$addrfamily};

	#--------------------------------------------------------------#
	# $srcaddr:                                                    #
	#--------------------------------------------------------------#
	unless(defined($srcaddr)) {
		for( ; ; ) {
			if($_addrfamily_ == 4) {
				$srcaddr = '0.0.0.0';
				last;
			}

			if($_addrfamily_ == 6) {
				$srcaddr = '::';
				last;
			}

			kReg_Common_Error(__FILE__, __LINE__, $function,
					  "unknown addrfamily -- $addrfamily");

			return(undef);
		}
	}

	my $_srcaddr_ = kInetPtoN($_addrfamily_, $srcaddr);

	unless(defined($_srcaddr_)) {
		kReg_Common_Error(__FILE__, __LINE__, $function,
				  "kInetPtoN: failure -- $srcaddr");

		return(undef);
	}


	#--------------------------------------------------------------#
	# $dstaddr:                                                    #
	#--------------------------------------------------------------#
	unless(defined($dstaddr)) {
		kReg_Common_Error(__FILE__, __LINE__, $function,
				  "dstaddr must be defined.");

		return(undef);
	}

	my $_dstaddr_ = kInetPtoN($_addrfamily_, $dstaddr);
	unless(defined($_dstaddr_)) {
		kReg_Common_Error(__FILE__, __LINE__, $function,
				  "kInetPtoN: failure -- $dstaddr");

		return(undef);
	}


	#--------------------------------------------------------------#
	# $srcport:                                                    #
	#--------------------------------------------------------------#
	unless(defined($srcport)) { $srcport = 0; }
	my $_srcport_ = $srcport;


	#--------------------------------------------------------------#
	# $dstport:                                                    #
	#--------------------------------------------------------------#
	unless(defined($dstport)) {
		kReg_Common_Error(__FILE__, __LINE__, $function,
				  "dstport must be defined.");

		return(undef);
	}

	my $_dstport_ = $dstport;


	#--------------------------------------------------------------#
	# $data:                                                       #
	#--------------------------------------------------------------#
	unless(defined($data)) { $data = ''; }
	my $_data_ = $data;


	#--------------------------------------------------------------#
	# $datalen:                                                    #
	#--------------------------------------------------------------#
	unless(defined($datalen)) { $datalen = length($data); }
	my $_datalen_ = $datalen;


	#--------------------------------------------------------------#
	# $interface: 'Link0', 'Link1', ...                            #
	#--------------------------------------------------------------#
	unless(defined($interface)) { $interface = 'Link0'; }

	my $interfaceid = 0;

	if($interface =~ /^\s*Link(\d+)\s*$/) {
		$interfaceid = $1;
	} else {
		kReg_Common_Error(__FILE__, __LINE__, $function,
				  "unknown interface -- $interface");

		return(undef);
	}

	my $_interface_ = $interfaceid;

	#--------------------------------------------------------------#
	# $flags:                                                      #
	#--------------------------------------------------------------#
	my $_flags_ = defined($flags) ? $flags : 0;

	unless($SOCKFD) {
		kReg_Common_Error(__FILE__, __LINE__, $function,
				  "Bad file descriptor");

		return(undef);
	}

	#--------------------------------------------------------------#
	# message construction                                         #
	#--------------------------------------------------------------#
	my $_message_ =
		pack(
			'n4 C2 n',
			$sockio_cmd{'CMD-CONNECT-REQ'},
			$SOCKIO_SEQ,
			$_srcport_,
			$_dstport_,
			$_addrfamily_,
			$_protocol_,
			$_interface_
		);

	$_message_ .= $_srcaddr_;
	$_message_ .= $_dstaddr_;

	$_message_ .=
		pack(
			'n2 N',
		     	$_flags_,
			$_frameid_,
			$_datalen_
		);

	$_message_ .= $_data_;

	my $timestr = getTimeStamp();
	my $srctab = '&nbsp;&nbsp;';
	my $dsttab = '&nbsp;&nbsp;';
	calcTab($srcaddr, $dstaddr, \$srctab, \$dsttab);
	prLog("\n<TR VALIGN=\"TOP\">\n<TD>$timestr</TD><TD>");
	prLog("Connect<br>"
	      . "&nbsp;&nbsp;SrcAddr:${srcaddr}"
	      . "${srctab}SrcPort:${srcport}<br>"
	      . "&nbsp;&nbsp;DstAddr:${dstaddr}"
	      . "${dsttab}DstPort:${dstport}<br>");

	if ($_datalen_ > 0) {
		prOut("try to send...");
	}

	return(PKTSendCMD($SOCKFD, 'CMD-CONNECT-REQ', $_message_));
}


#----------------------------------------------------------------------#
# kPacket_Send()                                                       #
#----------------------------------------------------------------------#
sub
kPacket_Send($$$)
{
	my ($socketid, $datalen, $data) = @_;

	my $function = 'kPacket_Send';
	kInit_Common_Error();

	$SOCKIO_SEQ ++;
	$SOCKIO_SEQ &= 0xffff;

	#--------------------------------------------------------------#
	# $socketid:                                                   #
	#--------------------------------------------------------------#
	unless(defined($socketid)) {
		kReg_Common_Error(__FILE__, __LINE__, $function,
				  "socketid must be defined.");

		return(undef);
	}

	#--------------------------------------------------------------#
	# $data:                                                       #
	#--------------------------------------------------------------#
	unless(defined($data)) { $data = ''; }
	my $_data_ = $data;

	#--------------------------------------------------------------#
	# $socketid:                                                   #
	#--------------------------------------------------------------#
	unless(defined($datalen)) { $datalen = length($data); }
	my $_datalen_ = $datalen;

	unless($SOCKFD) {
		kReg_Common_Error(__FILE__, __LINE__, $function,
				  "Bad file descriptor");

		return(undef);
	}

	my $_reserve_ = 0;
	my $_message_ = pack('n4 N',
			     $sockio_cmd{'CMD-SEND-REQ'},
			     $SOCKIO_SEQ,
			     $socketid,
			     $_reserve_,
			     $_datalen_
			    );
	$_message_ .= $_data_;

	my $timestr = getTimeStamp();
	prLog("<TR VALIGN=\"TOP\">\n<TD>$timestr</TD><TD>");
	prLog("Send<BR>");
	prOut("try to send...");

	return(PKTSendCMD($SOCKFD, 'CMD-SEND-REQ', $_message_));
}



#----------------------------------------------------------------------#
# kPacket_Recv()                                                       #
#----------------------------------------------------------------------#
sub
kPacket_Recv($$)
{
	my ($socketid, $sec) = @_;

	my $function = 'kPacket_Recv';
	kInit_Common_Error();

	$SOCKIO_SEQ ++;
	$SOCKIO_SEQ &= 0xffff;

	#--------------------------------------------------------------#
	# $socketid:                                                   #
	#--------------------------------------------------------------#
	unless(defined($socketid)) {
		kReg_Common_Error(__FILE__, __LINE__, $function,
				  "socketid must be defined.");

		return(undef);
	}

	my $_sec_ = defined($sec)? $sec: 0;

	unless($SOCKFD) {
		kReg_Common_Error(__FILE__, __LINE__, $function,
				  "Bad file descriptor");

		return(undef);
	}

	my $_message_ =
		pack(
			'n4',
			$sockio_cmd{'CMD-READ-REQ'},
			$SOCKIO_SEQ,
			$socketid,
			$_sec_
		);

	my $timestr = getTimeStamp();
	prLog("<TR VALIGN=\"TOP\">\n<TD>$timestr</TD><TD>");
	prLog("Receive<BR>");
	prOut("try to receive...");

	return(PKTSendCMD($SOCKFD, 'CMD-READ-REQ', $_message_));
}



#----------------------------------------------------------------------#
# kPacket_Close()                                                      #
#----------------------------------------------------------------------#
sub
kPacket_Close($$)
{
	my ($socketid, $sec) = @_;

	my $function = 'kPacket_Close';
	kInit_Common_Error();

	$SOCKIO_SEQ ++;
	$SOCKIO_SEQ &= 0xffff;

	#--------------------------------------------------------------#
	# $socketid:                                                   #
	#--------------------------------------------------------------#
	unless(defined($socketid)) {
		kReg_Common_Error(__FILE__, __LINE__, $function,
				  "socketid must be defined.");

		return(undef);
	}

	#--------------------------------------------------------------#
	# $sec:                                                        #
	#--------------------------------------------------------------#
	my $_sec_ = defined($sec) ? $sec : 0;


	unless($SOCKFD) {
		kReg_Common_Error(__FILE__, __LINE__, $function,
				  "Bad file descriptor");

		return(undef);
	}

	my $_message_ = pack('n4',
			     $sockio_cmd{'CMD-CLOSE-REQ'},
			     $SOCKIO_SEQ,
			     $socketid,
			     $_sec_
			    );

	return(PKTSendCMD($SOCKFD, 'CMD-CLOSE-REQ', $_message_));
}



#----------------------------------------------------------------------#
# kPacket_StartRecv()                                                     #
#----------------------------------------------------------------------#
sub
kPacket_StartRecv($$$$$$;$)
{
	my ($protocol,
	    $frameid,
	    $addrfamily,
	    $srcaddr,
	    $srcport,
	    $interface,
	    $flags) = @_;

	my $function = 'kPacket_StartRecv';
	kInit_Common_Error();

	$SOCKIO_SEQ ++;
	$SOCKIO_SEQ &= 0xffff;

	#--------------------------------------------------------------#
	# $protocol: 'TCP', 'UDP'                                      #
	#--------------------------------------------------------------#
	unless(defined($protocol)) {
		kReg_Common_Error(__FILE__, __LINE__, $function,
				  "protocol must be defined.");

		return(undef);
	}

	unless(defined($sockio_proto{$protocol})) {
		kReg_Common_Error(__FILE__, __LINE__, $function,
				  "unknown protocol -- $protocol");

		return(undef);
	}

	my $_protocol_ = $sockio_proto{$protocol};

	#--------------------------------------------------------------#
	# $frameid: 'NULL', 'DNS', 'SIP'                               #
	#--------------------------------------------------------------#
	unless(defined($frameid)) { $frameid = 'NULL'; }
	unless(defined($sockio_frame{$frameid})) {
		kReg_Common_Error(__FILE__, __LINE__, $function,
				  "unknown frameid -- $frameid");

		return(undef);
	}

	my $_frameid_ = $sockio_frame{$frameid}->{'id'};

	#--------------------------------------------------------------#
	# $addrfamily: 'INET', 'INET6'                                 #
	#--------------------------------------------------------------#
	unless(defined($addrfamily)) {
		kReg_Common_Error(__FILE__, __LINE__, $function,
				  "addrfamily must be defined.");

		return(undef);
	}

	unless(defined($sockio_af{$addrfamily})) {
		kReg_Common_Error(__FILE__, __LINE__, $function,
				  "unknown addrfamily -- $addrfamily");

		return(undef);
	}

	my $_addrfamily_ = $sockio_af{$addrfamily};

	#--------------------------------------------------------------#
	# $srcaddr:                                                    #
	#--------------------------------------------------------------#
	unless(defined($srcaddr)) {
		for( ; ; ) {
			if($_addrfamily_ == 4) {
				$srcaddr = '0.0.0.0';
				last;
			}

			if($_addrfamily_ == 6) {
				$srcaddr = '::';
				last;
			}

			kReg_Common_Error(__FILE__, __LINE__, $function,
					  "unknown addrfamily -- $addrfamily");

			return(undef);
		}
	}

	my $_srcaddr_ = kInetPtoN($_addrfamily_, $srcaddr);

	unless(defined($_srcaddr_)) {
		kReg_Common_Error(__FILE__, __LINE__, $function,
				  "kInetPtoN: failure -- $srcaddr");

		return(undef);
	}

	#--------------------------------------------------------------#
	# $srcport:                                                    #
	#--------------------------------------------------------------#
	unless(defined($srcport)) { $srcport = 0; }
	my $_srcport_ = $srcport;

	#--------------------------------------------------------------#
	# $interface: 'Link0', 'Link1', ...                            #
	#--------------------------------------------------------------#
	unless(defined($interface)) { $interface = 'Link0'; }

	my $interfaceid = 0;

	if($interface =~ /^\s*Link(\d+)\s*$/) {
		$interfaceid = $1;
	} else {
		kReg_Common_Error(__FILE__, __LINE__, $function,
				  "unknown interface -- $interface");

		return(undef);
	}

	my $_interface_ = $interfaceid;

	#--------------------------------------------------------------#
	# $flags                                                       #
	#--------------------------------------------------------------#
	my $_flags_ = defined($flags) ? $flags : 0;

	unless($SOCKFD) {
		kReg_Common_Error(__FILE__, __LINE__, $function,
				  "Bad file descriptor");

		return(undef);
	}

	my $_message_ = pack('n4 C2 n',
			     $sockio_cmd{'CMD-LISTEN-REQ'},
			     $SOCKIO_SEQ,
			     $_interface_,
			     $_frameid_,
			     $_addrfamily_,
			     $_protocol_,
			     $_srcport_
			    );

	$_message_ .= $_srcaddr_;

	$_message_ .= pack('n', $_flags_);

	my $timestr = getTimeStamp();
	prLog("<TR VALIGN=\"TOP\">\n<TD>$timestr</TD><TD>");
	prLog("Listen<br>"
	      . "&nbsp;&nbsp;SrcAddr:$srcaddr "
	      . "&nbsp;&nbsp;SrcPort:$srcport<br>");

	return(PKTSendCMD($SOCKFD, 'CMD-LISTEN-REQ', $_message_));
}



#----------------------------------------------------------------------#
# kPacket_ConnectInfo()                                                #
#----------------------------------------------------------------------#
sub
kPacket_ConnectInfo($)
{
	my ($socketid) = @_;

	my $function = 'kPacket_ConnectInfo';
	kInit_Common_Error();

	$SOCKIO_SEQ ++;
	$SOCKIO_SEQ &= 0xffff;

	#--------------------------------------------------------------#
	# $socketid:                                                   #
	#--------------------------------------------------------------#
	unless(defined($socketid)) {
		kReg_Common_Error(__FILE__, __LINE__, $function,
				  "socketid must be defined.");

		return(undef);
	}


	unless($SOCKFD) {
		kReg_Common_Error(__FILE__, __LINE__, $function,
				  "Bad file descriptor");

		return(undef);
	}

	my $_message_ = pack('n3',
			     $sockio_cmd{'CMD-CONNINFO-REQ'},
			     $SOCKIO_SEQ,
			     $socketid
			    );

	return(PKTSendCMD($SOCKFD, 'CMD-CONNINFO-REQ', $_message_));
}



#----------------------------------------------------------------------#
# kPacket_DataInfo()                                                   #
#----------------------------------------------------------------------#
sub
kPacket_DataInfo($)
{
	my ($dataid) = @_;

	my $function = 'kPacket_DataInfo';
	kInit_Common_Error();

	$SOCKIO_SEQ ++;
	$SOCKIO_SEQ &= 0xffff;

	#--------------------------------------------------------------#
	# $dataid:                                                     #
	#--------------------------------------------------------------#
	unless(defined($dataid)) {
		kReg_Common_Error(__FILE__, __LINE__, $function,
				  "dataid must be defined.");

		return(undef);
	}

	unless($SOCKFD) {
		kReg_Common_Error(__FILE__, __LINE__, $function,
				  "Bad file descriptor");

		return(undef);
	}

	my $_message_ = pack('n2 N',
			     $sockio_cmd{'CMD-DATAINFO-REQ'},
			     $SOCKIO_SEQ,
			     $dataid
			    );

	return(PKTSendCMD($SOCKFD, 'CMD-DATAINFO-REQ', $_message_));
}



#----------------------------------------------------------------------#
# kPacket_Clear()                                                      #
#----------------------------------------------------------------------#
sub
kPacket_Clear($$$$)
{
	my ($socketid_flag,
	    $dataid_flag,
	    $socketid,
	    $dataid) = @_;

	my $function = 'kPacket_Clear';
	kInit_Common_Error();

	$SOCKIO_SEQ ++;
	$SOCKIO_SEQ &= 0xffff;

	#--------------------------------------------------------------#
	# $socketid_flag:                                              #
	#--------------------------------------------------------------#
	unless(defined($socketid_flag)) {
		kReg_Common_Error(__FILE__, __LINE__, $function,
				  "socketid_flag must be defined.");

		return(undef);
	}

	#--------------------------------------------------------------#
	# $dataid_flag:                                                #
	#--------------------------------------------------------------#
	unless(defined($dataid_flag)) {
		kReg_Common_Error(__FILE__, __LINE__, $function,
				  "dataid must be defined.");

		return(undef);
	}

	#--------------------------------------------------------------#
	# $socketid:                                                   #
	#--------------------------------------------------------------#
	unless(defined($socketid)) {
		kReg_Common_Error(__FILE__, __LINE__, $function,
				  "socketid must be defined.");

		return(undef);
	}

	#--------------------------------------------------------------#
	# $dataid:                                                     #
	#--------------------------------------------------------------#
	unless(defined($dataid)) {
		kReg_Common_Error(__FILE__, __LINE__, $function,
				  "dataid must be defined.");

		return(undef);
	}


	unless($SOCKFD) {
		kReg_Common_Error(__FILE__, __LINE__, $function,
				  "Bad file descriptor");

		return(undef);
	}

	my $_message_ = pack('n5 N',
			     $sockio_cmd{'CMD-CLEARBUFFER-REQ'},
			     $SOCKIO_SEQ,
			     $socketid_flag,
			     $dataid_flag,
			     $socketid,
			     $dataid
			    );

	my $timestr = getTimeStamp();
	prLog("<TR VALIGN=\"TOP\">\n<TD>$timestr</TD><TD>");
	prLog("Clear Buffer<BR>");

	return(PKTSendCMD($SOCKFD, 'CMD-CLEARBUFFER-REQ', $_message_));
}

#----------------------------------------------------------------------#
# kPacket_TlsSetup()                                                   #
#----------------------------------------------------------------------#
sub
kPacket_TlsSetup($$$$$$$$$$$$)
{
	my ($sessionmode,$initialmode,$ssltimeout,$sslversion,$passwd,$rootpem,$mypem,$dhpem,
	   $nagle,$clientveri,$tmprsa,$encsuit) = @_;

	my $function = 'kPacket_TlsSetup';
	kInit_Common_Error();

	$SOCKIO_SEQ ++;
	$SOCKIO_SEQ &= 0xffff;

	#--------------------------------------------------------------#
	# $sessionmode:                                                #
	#--------------------------------------------------------------#
	if(!defined($sessionmode) || !$sessionmode || $sessionmode =~ /off/i) {
	    $sessionmode=0;
	}
	else{
	    $sessionmode=1;
	}

	if(!defined($initialmode) || !$initialmode || $initialmode =~ /off/i) {
	    $initialmode=0;
	}
	else{
	    $initialmode=1;
	}

	if(!$ssltimeout) {
	    $ssltimeout=0;
	}

	if($sslversion =~ /SSLv2/i) {
	    $sslversion=2;
	}
	elsif($sslversion =~ /SSLv23/i) {
	    $sslversion=23;
	}
	elsif($sslversion =~ /SSLv3/i) {
	    $sslversion=3;
	}
	elsif($sslversion =~ /TLSv1/i) {
	    $sslversion=1;
	}
	else{
	    $sslversion=1;
	}

	if(!$passwd) {
	    $passwd='nutsip';
	}

	if(!defined($nagle) || !$nagle || $nagle =~ /on/i) {
	    $nagle=1;
	}
	else{
	    $nagle=0;
	}
	if(!defined($clientveri) || !$clientveri || $clientveri =~ /on/i) {
	    $clientveri=1;
	}
	else{
	    $clientveri=0;
	}
	if(!defined($tmprsa) || !$tmprsa || $tmprsa =~ /on/i) {
	    $tmprsa=1;
	}
	else{
	    $tmprsa=0;
	}

	unless($SOCKFD) {
		kReg_Common_Error(__FILE__, __LINE__, $function,"Bad file descriptor");
		return(undef);
	}

	my $_message_ = pack('n6 a32 a128 a128 a128 n3 a128',
			     $sockio_cmd{'CMD-TLSSETUP-REQ'},
			     $SOCKIO_SEQ,
			     $sessionmode,
			     $initialmode,
			     $ssltimeout,
			     $sslversion,
			     $passwd,
			     $rootpem,
			     $mypem,
			     $dhpem,
			     $nagle,
			     $clientveri,
			     $tmprsa,
			     $encsuit
			    );

	return(PKTSendCMD($SOCKFD, 'CMD-TLSSETUP-REQ', $_message_));
}

#----------------------------------------------------------------------#
# kPacket_TlsClear()                                                   #
#----------------------------------------------------------------------#
sub
kPacket_TlsClear($)
{
	my ($socketid) = @_;

	my $function = 'kPacket_TlsClear';
	kInit_Common_Error();

	$SOCKIO_SEQ ++;
	$SOCKIO_SEQ &= 0xffff;

	#--------------------------------------------------------------#
	# $sessionmode:                                                #
	#--------------------------------------------------------------#

	unless($SOCKFD) {
		kReg_Common_Error(__FILE__, __LINE__, $function,"Bad file descriptor");
		return(undef);
	}

	my $_message_ = pack('n3',
			     $sockio_cmd{'CMD-TLSCLEAR-REQ'},
			     $SOCKIO_SEQ,
			     $socketid,
			    );

	return(PKTSendCMD($SOCKFD, 'CMD-TLSCLEAR-REQ', $_message_));
}

#----------------------------------------------------------------------#
# kPacket_ParserAttach()                                               #
#----------------------------------------------------------------------#
sub
kPacket_ParserAttach($$$$$)
{
	my ($frame,
	    $parserid,
	    $parsername,
	    $modulepath,
	    $dumpfunc) = @_;

	my $function = 'kPacket_ParserAttach';
	kInit_Common_Error();

	$SOCKIO_SEQ ++;
	$SOCKIO_SEQ &= 0xffff;

	#--------------------------------------------------------------#
	# $parserid:                                              #
	#--------------------------------------------------------------#
	if(!defined($frame) || $sockio_frame{$frame}) {
		kReg_Common_Error(__FILE__, __LINE__, $function,
				  'frameid '.$frame?'already registed':'must be defined');

		return(undef);
	}

	#--------------------------------------------------------------#
	# $parserid:                                              #
	#--------------------------------------------------------------#
	if($parserid < 100) {
		kReg_Common_Error(__FILE__, __LINE__, $function,
				  "parserid must be over 100.");

		return(undef);
	}

	#--------------------------------------------------------------#
	# $parsername:                                                #
	#--------------------------------------------------------------#
	unless(defined($parsername)) {
		kReg_Common_Error(__FILE__, __LINE__, $function,
				  "parsername must be defined.");

		return(undef);
	}

	#--------------------------------------------------------------#
	# $modulepath:                                                   #
	#--------------------------------------------------------------#
	unless(defined($modulepath)) {
		kReg_Common_Error(__FILE__, __LINE__, $function,
				  "modulepath must be defined.");

		return(undef);
	}

	unless($SOCKFD) {
		kReg_Common_Error(__FILE__, __LINE__, $function,
				  "Bad file descriptor");

		return(undef);
	}

	my $_message_ = pack('n4 a64 a128',
			     $sockio_cmd{'CMD-PARSERATTACH-REQ'},
			     $SOCKIO_SEQ,
			     $parserid,
			     0,
			     $parsername,
			     $modulepath,
			    );

	my $result = PKTSendCMD($SOCKFD, 'CMD-PARSERATTACH-REQ', $_message_);

	if($result && $result->{'Result'} eq 0){
		$sockio_frame{$frame}={'id'=>$parserid,'dump'=>$dumpfunc};
	}
	return $result;
}

sub
kPacket_ParserDetach($$)
{
	my ($frame,
	    $parserid) = @_;

	my $function = 'kPacket_ParserDetach';
	kInit_Common_Error();

	$SOCKIO_SEQ ++;
	$SOCKIO_SEQ &= 0xffff;

	#--------------------------------------------------------------#
	# $parserid:                                              #
	#--------------------------------------------------------------#
	if(!defined($frame)) {
		kReg_Common_Error(__FILE__, __LINE__, $function,
				  "parsername must be defined.");

		return(undef);
	}

	#--------------------------------------------------------------#
	# $parserid:                                              #
	#--------------------------------------------------------------#
	if($parserid < 100) {
		kReg_Common_Error(__FILE__, __LINE__, $function,
				  "parserid must be over 100.");

		return(undef);
	}

	unless($SOCKFD) {
		kReg_Common_Error(__FILE__, __LINE__, $function,
				  "Bad file descriptor");

		return(undef);
	}

	my $_message_ = pack('n4 a64 a128',
			     $sockio_cmd{'CMD-PARSERATTACH-REQ'},
			     $SOCKIO_SEQ,
			     $parserid,
			     1,
			     '',
			     '',
			    );

	my $result = PKTSendCMD($SOCKFD, 'CMD-PARSERATTACH-REQ', $_message_);
	$sockio_frame{$frame}='';
	return $result;
}

#----------------------------------------------------------------------#
# PKTSendCMD()                                                         #
#----------------------------------------------------------------------#
sub
PKTSendCMD($$;$)
{
	my ($sock, $cmd, $send_msg) = @_;

	my $function = 'PKTSendCMD';

	unless(defined($send_msg)) {
		$send_msg = '';
	}

	unless(exists($sockio_cmd{$cmd})) {
		kReg_Common_Error(__FILE__, __LINE__, $function,
			"\%sockio_cmd: unknown key -- $cmd");

		return(undef);
	}

	my $answer_cmd = $cmd;
	$answer_cmd =~ s/REQ/ANS/g;

	unless(defined(kWriteUnixDomain($sock, $send_msg))) {
		kReg_Common_Error(__FILE__, __LINE__, $function,
			"kWriteUnixDomain: $!");

		return(undef);
	}

	my $recv_msg = kReadUnixDomain($sock);
	unless(defined($recv_msg)) {
		kReg_Common_Error(__FILE__, __LINE__, $function,
			"kReadUnixDomain: failure");

		return(undef);
	}

	for(my $d = 0; ; $d ++) {
		my $bool = kCheckDataLength($answer_cmd, $recv_msg);
		unless(defined($bool)) {
			kReg_Common_Error(__FILE__, __LINE__, $function,
				"kCheckDataLength: failure");

			return(undef);
		}

		if($bool) {
			last;
		}

		my $buf = kReadUnixDomain($sock);

		unless(defined($buf)) {
			kReg_Common_Error(__FILE__, __LINE__, $function,
				"kReadUnixDomain: failure");

			return(undef);
		}

		$recv_msg .= $buf;

		if($d > 2) {
			kReg_Common_Error(__FILE__, __LINE__, $function,
				"data size from socket I/O is too short.");

			return(undef);
		}
	}

	my $result = kMakeData($cmd, $recv_msg);
	unless(defined($result)) {
		kReg_Common_Error(__FILE__, __LINE__, $function,
			"kMakeData: failure");

		return(undef);
	}

	## LOG
	my $timestr = getTimeStamp();
	if($cmd eq 'CMD-CONNECT-REQ') {
		prLog("done<br>");
		prOut("done<br>");

		prLog("&nbsp;&nbsp;connected to "
		      . "SocketID:$result->{'SocketID'}<br>");

		my @data= unpack('n4 C2 n n16 n2 N a*', $send_msg);
		my $datalen = $data[25];
		if ($datalen) {
			prLog("&nbsp;&nbsp;sent to "
			      . "SocketID:$result->{'SocketID'}<br>");
			prLogSendPacket($result->{'SocketID'}, $result->{'DataID'}, $data[26]);
			my $datainfo = kPacket_DataInfo($result->{'DataID'});
			$result->{'Data'} = $datainfo->{'Data'};
		}

		prLog("</TD>\n</TR>\n");
	}
	elsif($cmd eq 'CMD-SEND-REQ') {
		prLog("done<BR>");
		prOut("done<br>");
		prLog("&nbsp;&nbsp;sent to "
		      . "SocketID:$result->{'SocketID'}<br>");

		my @data = unpack('n4 N a*', $send_msg);
		prLogSendPacket($result->{'SocketID'}, $result->{'DataID'}, $data[5]);
		my $datainfo = kPacket_DataInfo($result->{'DataID'});
		$result->{'Data'} = $datainfo->{'Data'};

		prLog("</TD>\n</TR>\n");
	}
	elsif($cmd eq 'CMD-READ-REQ') {
		my $srctab = '&nbsp;&nbsp;';
		my $dsttab = '&nbsp;&nbsp;';
		calcTab($result->{'SrcAddr'}, $result->{'DstAddr'},
			  \$srctab, \$dsttab);
		prLog("&nbsp;&nbsp;SrcAddr:$result->{'SrcAddr'}"
		      . "${srctab}SrcPort:$result->{'SrcPort'}<br>"
		      . "&nbsp;&nbsp;DstAddr:$result->{'DstAddr'}"
		      . "${dsttab}DstPort:$result->{'DstPort'}<br>");
		prLog("done<BR>");
		prOut("done<br>");
		prLog("&nbsp;&nbsp;received from "
		      . "SocketID:$result->{'SocketID'}<br>");

#		my $count = parseCount($PktCount);
		prLog("<A NAME=\"koiPacket${PktCount}\"></A>");
		if ($USE_JAVASCRIPT) {
			prLog("<A HREF=\"#koiPacketDump${PktCount}\" "
			      . "onmouseover=\"popup(${PktCount},event);\""
			      . "onmouseout=\"popdown(${PktCount});\""
			      . ">receive packet \#${PktCount}</A>");
			prLog("<div id=\"pop${PktCount}\" "
			      . "style=\"position:absolute; "
			      . "visibility:hidden;\"></div>");
		}
		else {
			prLog("<A HREF=\"#koiPacketDump${PktCount}\""
			      . ">receive packet \#${PktCount}</A>");
		}
		prLog("<BR>");

		## collect reverse packet log
		$PacketLog .= "<A NAME=\"koiPacketDump${PktCount}\"></A>";
		$PacketLog .= "<A HREF=\"#koiPacket${PktCount}\">";
		$PacketLog .= "packet \#${PktCount} at $timestr</A>\n";
		if ($USE_JAVASCRIPT) {
			$PacketLog .= "<div id=\"koiPacketInfo${PktCount}\">\n";
		}
		$PacketLog .="<pre>";
		# $PacketLog .="<pre style=\"line-height:80%\">";

		## IP Header
		my ($log, $protocol) = getPacketInfo($result->{'SocketID'},
						     $result->{'DataID'},
						     'recv');
		$PacketLog .= $log;

		if (defined($result->{'Data'})) {
			$PacketLog .= dumpPacket($result->{'Data'}, $protocol);
		}
		$PacketLog .= "</pre>\n";
		if ($USE_JAVASCRIPT) {
			$PacketLog .= "</div>\n";
		}
		$PacketLog .= "<hr>\n\n";


		prLog("</TD>\n</TR>\n");

		$PktCount++;
		$RecvPktCount++;
	}
	elsif($cmd eq 'CMD-CLOSE-REQ') {
		prLog("<TR VALIGN=\"TOP\">\n<TD>$timestr</TD><TD>");
		prLog("Close Socket<BR>");
		prLog("</TD>\n</TR>\n");
	}
	elsif($cmd eq 'CMD-LISTEN-REQ') {
		prLog("done<BR>");
		prLog("&nbsp;&nbsp;listening at "
		      . "SocketID:$result->{'SocketID'}<br>");

		prLog("</TD>\n</TR>\n");
	}
	elsif($cmd eq 'CMD-CONNINFO-REQ') {
		# don't need to log
		# prLog("<TR VALIGN=\"TOP\">\n<TD>$timestr</TD><TD>");
		# prLog("Connection Information<BR>");
		# prLog("</TD>\n</TR>\n");
	}
	elsif($cmd eq 'CMD-DATAINFO-REQ') {
		# don't need to log
		# prLog("<TR VALIGN=\"TOP\">\n<TD>$timestr</TD><TD>");
		# prLog("Data Information<BR>");
		# prLog("</TD>\n</TR>\n");
	}
	elsif($cmd eq 'CMD-CLEARBUFFER-REQ') {
		prLog("done<BR>");
		prLog("</TD>\n</TR>\n");
	}
	elsif($cmd eq 'CMD-TLSSETUP-REQ') {
	}
	elsif($cmd eq 'CMD-TLSCLEAR-REQ') {
	}

	$vLogStat = $vLogStatCloseRow;

	return($result);
}

sub prLogSendPacket($$$) {
	my ($socketid, $dataid, $data) = @_;

#	my $count = parseCount($PktCount);
	prLog("<A NAME=\"koiPacket${PktCount}\"></A>");
	if ($USE_JAVASCRIPT) {
		prLog("<A HREF=\"#koiPacketDump${PktCount}\" "
		      . "onmouseover=\"popup(${PktCount},event);\""
		      . "onmouseout=\"popdown(${PktCount});\""
		      . ">send packet \#${PktCount}</A>");
		prLog("<div id=\"pop${PktCount}\" "
		      . "style=\"position:absolute; "
		      . "visibility:hidden;\"></div>");
	} else {
		prLog("<A HREF=\"#koiPacketDump${PktCount}\""
		      . ">send packet \#${PktCount}</A>");
	}
	prLog("<BR>");

	## collect reverse packet log
	my $timestr = getTimeStamp();
	$PacketLog .= "<A NAME=\"koiPacketDump${PktCount}\"></A>";
	$PacketLog .= "<A HREF=\"#koiPacket${PktCount}\">";
	$PacketLog .= "packet \#${PktCount} at $timestr</A>\n";
	if ($USE_JAVASCRIPT) {
		$PacketLog .= "<div id=\"koiPacketInfo${PktCount}\">\n";
	}
	$PacketLog .= "<pre>";
	# $PacketLog .="<pre style=\"line-height:80%\">";

	## IP Header
	my ($log, $conninfo) = getPacketInfo($socketid, $dataid, 'send');
	$PacketLog .= $log;

	$PacketLog .= dumpPacket($data, $conninfo);
	$PacketLog .= "</pre>\n";
	if ($USE_JAVASCRIPT) {
		$PacketLog .= "</div>\n";
	}
	$PacketLog .= "<hr>\n\n";

	$PktCount++;
	$SendPktCount++;

	return;
}

sub getPacketInfo($$$) {
	my ($socketid, $dataid, $direction) = @_;

	my $function = 'getPacketInfo';

	my ($srcaddr, $dstaddr, $srcport, $dstport);
	if ($direction eq 'send') {
		$srcaddr = 'SrcAddr';
		$dstaddr = 'DstAddr';
		$srcport = 'SrcPort';
		$dstport = 'DstPort';
	}
	elsif ($direction eq 'recv') {
		$srcaddr = 'DstAddr';
		$dstaddr = 'SrcAddr';
		$srcport = 'DstPort';
		$dstport = 'SrcPort';
	}
	else {
		kReg_Common_Error(__FILE__, __LINE__, $function,
				  "unknown direction: $direction");
		return undef;
	}

	my $conninfo = kPacket_ConnectInfo($socketid);
	my $result =
	"IP Packet\n".
	"| IP Header\n".
	"| | Version                    = $conninfo->{'AddrType'}\n".
	"| | Source Address             = $conninfo->{$srcaddr}\n".
	"| | Destination Address        = $conninfo->{$dstaddr}\n";

	my $protocol = $conninfo->{'Protocol'};
	if ($protocol == $sockio_proto{'TCP'}) {
		$result .= "| TCP Header\n".
		"| | Source Port                = $conninfo->{$srcport}\n".
		"| | Destination Port           = $conninfo->{$dstport}\n";
	} elsif ($protocol == $sockio_proto{'UDP'}) {
		$result .= "| UDP Header\n".
		"| | Source Port                = $conninfo->{$srcport}\n".
		"| | Destination Port           = $conninfo->{$dstport}\n";
	} elsif ($protocol == $sockio_proto{'ICMP'}) {
		my %icmp_type = undef;
		if ($conninfo->{'AddrType'} eq '4') {
			%icmp_type = %icmpv4_type;
		}
		elsif ($conninfo->{'AddrType'} eq '6') {
			%icmp_type = %icmpv6_type;
		}

		my $datainfo = kPacket_DataInfo($dataid);
		my ($type, $code, $checksum) = unpack('C C n', $datainfo->{'Data'});
		my $offset = 4;

		$result .= "| ICMP Header\n" .
		"| | Type                       = $type (" . $icmp_type{$type} . ")\n" .
		"| | Code                       = $code\n" .
		"| | Checksum                   = 0x" . sprintf('%04x', $checksum) . "\n";

		if (length($datainfo->{'Data'}) > $offset) {
			my $id = unpack('n', substr($datainfo->{'Data'}, $offset, 2));
			$offset += 2;
			$result .=
				"| | Identifier                 = 0x" . sprintf('%04x', $id) . "\n";
		}
		if (length($datainfo->{'Data'}) > $offset) {
			my $seq = unpack('n', substr($datainfo->{'Data'}, $offset, 2));
			$offset += 2;
			$result .=
				"| | Sequence Number            = 0x" . sprintf('%04x', $seq) . "\n";
		}
	}

	return ($result, $conninfo);
}

sub dumpPacket($$) {
	my ($data, $conninfo) = @_;

	my $function = 'dumpPacket';

	if ($conninfo->{'Protocol'} == $sockio_proto{'TCP'}) {
		my $tmp = undef;
		($tmp, $data) = unpack('n a*', $data)
	}

	my $dump = 1;
	my $str = undef;

	if ($conninfo->{'FrameID'} == $sockio_frame{'DNS'}->{'id'}
	    || $conninfo->{'FrameID'} == $sockio_frame{'UDPDNS'}->{'id'}) {
		$str = dumpPacketDNS($data);
	}
	elsif ($conninfo->{'FrameID'} == $sockio_frame{'NULL'}->{'id'}) {
		if ($conninfo->{'Protocol'} eq $sockio_proto{'ICMP'}) {
			dumpPacketICMP($data);
		}
		else {
			$str = dumpPacketNULL($data);
		}
	}
	elsif ($conninfo->{'FrameID'} == $sockio_frame{'IKEv2'}->{'id'}) {
		$str = dumpPacketIKEv2($data);
	}
	elsif ($conninfo->{'FrameID'} == $sockio_frame{'SIP'}->{'id'}) {
		$str = dumpPacketSIP($data);
	}
	elsif ($conninfo->{'FrameID'} == $sockio_frame{'KINK'}->{'id'}) {
		$str = dumpPacketKINK($data);
	}
	elsif ($sockio_frame{$conninfo->{'FrameID'}}->{'dump'}) {
		$str = $sockio_frame{$conninfo->{'FrameID'}}->{'dump'}->($data);
	}
	else {
		kReg_Common_Error(__FILE__, __LINE__, $function,
				  "unknown FrameID ($conninfo->{'FrameID'})");
	}

	return $str;
}


sub dumpPacketIKEv2($) {
	my ($data) = @_;
	my $dump = 1;
	my $result = kIKE::kPrint::kPrint_IKEv2($data, $dump);
	return $result;
}


sub dumpPacketKINK($) {
	my ($data) = @_;
	my $dump = 1;
	#my $result = kKINK::kPrint::kPrint_KINK($data, $dump);
	#return(dumpPacketNULL($data));
	my $result = KINK::KINK_decode($data);
	return($result);
}


sub dumpPacketDNS($) {
	my ($data) = @_;
	my $dump = 1;
	my ($tmp, $result) = kPrint_DNS($data, $dump);
	return $result;
}



sub
dumpPacketNULL($)
{
	my ($data) = @_;

	my $str	= '';
	$str .= "| Payload\n";
	$str .= "| | data                       = ";

	my @array = unpack("C*", $data);

	for(my $d = 0; $d <= $#array; $d ++) {
		for( ; ; ) {
			unless($d % 32) {
				$str .= "\n| |   ";
				last;
			}

			unless($d % 8) {
				$str .= '  ';
				last;
			}

			unless($d % 4) {
				$str .= ' ';
				last;
			}

			last;
		}

		$str .= sprintf("%02x", $array[$d]);
	}

	$str .= "\n";

	return($str);
}



sub dumpPacketSIP($) {
	my ($data) = @_;
	my $dump = 1;
	my $result = kPrint_SIP($data, $dump);
	return $result;
}


sub dumpPacketICMP($) {
	my ($data) = @_;
	return '';
}

##
## SHOULD BE IMPLEMENTED IN kSIP.pm
sub kPrint_SIP($;$) {
	my ($data, $dump) = @_;
	if (defined($dump)) {
		return $data;
	}
	prOut($data . "\n");
}

# sub parseCount($) {
# 	my ($count) = @_;
# 
# 	if ($count % 100 == 11) {
# 		$count = '11th';
# 	} elsif ($count % 100 == 12) {
# 		$count = '12th';
# 	} elsif ($count % 10 == 1) {
# 		$count = "${count}st";
# 	} elsif ($count % 10 == 2) {
# 		$count = "${count}nd";
# 	} elsif ($count % 10 == 3) {
# 		$count = "${count}rd";
# 	} else {
# 		$count = "${count}th";
# 	}
# 
# 	return $count;
# }

sub calcTab($$$$) {
	my ($str1, $str2, $tab1, $tab2) = @_;

	my $diff = length($str1) - length($str2);
	my $tab = '';
	for (my $i=0; $i < abs($diff); $i++) {
		$tab .= '&nbsp;';
	}
	if ($diff < 0) {
		$$tab1 .= $tab;
	}
	else {
		$$tab2 .= $tab;
	}
}


#----------------------------------------------------------------------#
# kWriteUnixDomain()                                                   #
#----------------------------------------------------------------------#
sub
kWriteUnixDomain($$)
{
	my ($sock, $data) = @_;

	return(syswrite($sock, $data, length($data)));
}



#----------------------------------------------------------------------#
# kReadUnixDomain()                                                    #
#----------------------------------------------------------------------#
sub
kReadUnixDomain($)
{
	my ($sock) = @_;
	my $data = '';

	my $function = 'kReadUnixDomain';

	for (;;) {
	       my $ret = sysread($sock, $data, 0xffff);
	       unless(defined($ret)) {
		       if ($! == EINTR) {
			       next;
		       }
		       kReg_Common_Error(__FILE__, __LINE__, $function,
					 "read: $!");

		       return(undef);
	       }

	       return($data);
       }
}



#----------------------------------------------------------------------#
# kCheckDataLength()                                                   #
#----------------------------------------------------------------------#
sub
kCheckDataLength($$)
{
	my ($cmd, $data) = @_;

	my $function = 'kCheckDataLength';

	my $dataLength = length($data);

	unless(defined($sockio_cmdlen{$cmd})) {
		kReg_Common_Error(__FILE__, __LINE__, $function,
			"\%sockio_cmdlen: unknown key -- $cmd");

		return(undef);
	}

	if(defined($sockio_cmdlen{$cmd})) {
		my $length = $sockio_cmdlen{$cmd};

		if(!ref($length)) {
			return($length <= $dataLength);
		} elsif(ref($length) eq 'CODE') {
			$length = $length->($data);
			return($length <= $dataLength);
		}
	}

	return(1);
}


#----------------------------------------------------------------------#
# kMakeData()                                                         #
#----------------------------------------------------------------------#
sub
kMakeData($$)
{
	my ($cmd, $data) = @_;

	my $function = 'kMakeData';

	my $result = '';

	if($cmd eq 'CMD-CONNECT-REQ') {
		$result = kMakeConnectSendAck($data);
	} elsif($cmd eq 'CMD-SEND-REQ') {
		$result = kMakeSendAck($data);
	} elsif($cmd eq 'CMD-READ-REQ') {
		$result = kMakeRecvAck($data);
	} elsif($cmd eq 'CMD-CLOSE-REQ') {
		$result = kMakeCloseAck($data);
	} elsif($cmd eq 'CMD-LISTEN-REQ') {
		$result = kMakeListenAck($data);
	} elsif($cmd eq 'CMD-CONNINFO-REQ') {
		$result = kMakeConnInfoAck($data);
	} elsif($cmd eq 'CMD-DATAINFO-REQ') {
		$result = kMakeDataInfoAck($data);
	} elsif($cmd eq 'CMD-CLEARBUFFER-REQ') {
		$result = kMakeClearAck($data);
	} elsif($cmd eq 'CMD-TLSSETUP-REQ') {
		$result = kMakeClearAck($data);
	} elsif($cmd eq 'CMD-TLSCLEAR-REQ') {
		$result = kMakeClearAck($data);
	} elsif($cmd eq 'CMD-PARSERATTACH-REQ') {
		$result = kMakeClearAck($data);
	} else {
		kReg_Common_Error(__FILE__, __LINE__, $function,
			"unknown command -- $cmd");

		return(undef);
	}

	return($result);
}



#----------------------------------------------------------------------#
# kMakeConnectSendAck()                                                #
#----------------------------------------------------------------------#
sub
kMakeConnectSendAck($)
{
	my ($data) = @_;

	my $value  = 0;
	my %result = ();

	my $function = 'kMakeConnectSendAck';

	my $size = 20;
	my $datalen = length($data);
	if($size != $datalen) {
		kReg_Common_Error(__FILE__, __LINE__, $function,
				  "\$datalen: $datalen -- ".
				  "requires just $size byte.");
		return(undef);
	}

	($result{'Command'},
	 $result{'RequestNum'},
	 $result{'Result'},
	 $result{'SocketID'},
	 $result{'DataID'},
	 $result{'TimeStamp'},
	 $result{'TimeStamp2'}) = unpack('n4 N3', $data);

	if ($result{'Result'} != 0) {
		my $val = sprintf("%x", $result{'Result'});
		kReg_Common_Error(__FILE__, __LINE__, $function,
				  "result: $result{'Result'}(0x$val) -- ".
				  "fails.");
		return undef;
	}

	return(\%result);
}



#----------------------------------------------------------------------#
# kMakeSendAck()                                                       #
#----------------------------------------------------------------------#
sub
kMakeSendAck($)
{
	my ($data) = @_;

	my %result = ();

	my $function = 'kMakeSendAck';

	my $size = 20;
	my $datalen = length($data);
	if($size != $datalen) {
		kReg_Common_Error(__FILE__, __LINE__, $function,
				  "\$datalen: $datalen -- ".
				  "requires just $size byte.");
		return(undef);
	}

	($result{'Command'},
	 $result{'RequestNum'},
	 $result{'Result'},
	 $result{'SocketID'},
	 $result{'DataID'},
	 $result{'TimeStamp'},
	 $result{'TimeStamp2'}) = unpack('n4 N3', $data);

	if ($result{'Result'} != 0) {
		my $val = sprintf("%x", $result{'Result'});
		kReg_Common_Error(__FILE__, __LINE__, $function,
				  "result: $result{'Result'}(0x$val) -- ".
				  "fails.");
		return undef;
	}

	return(\%result);
}



#----------------------------------------------------------------------#
# kMakeRecvAck()                                                       #
#----------------------------------------------------------------------#
sub
kMakeRecvAck($)
{
	my ($data) = @_;

	my $value  = 0;
	my %result = ();

	my $function = 'kMakeRecvAck';

	my $size    = 64;
	my $datalen = length($data);
	if($size > $datalen) {
		kReg_Common_Error(__FILE__, __LINE__, $function,
			"\$datalen: $datalen -- ".
			"requires more than $size byte.");

		return(undef);
	}

	($result{'Command'},
	 $result{'RequestNum'},
	 $result{'Result'},
	 $result{'SocketID'},
	 $result{'DataID'},
	 $result{'TimeStamp'},
	 $result{'TimeStamp2'},
	 $result{'SrcPort'},
	 $result{'DstPort'},
	 $result{'AddrType'},
	 $result{'Reserve1'},
	 $result{'Reserve2'},
	 $data
	) = unpack('n4 N3 n2 C2 n a*', $data);

	if ($result{'Result'} != 0) {

		## LOG
		my $conninfo = kPacket_ConnectInfo($result{'SocketID'});
		prLog("&nbsp;&nbsp;Can't receive any packets at"
		      . " SrcAddr:$conninfo->{'SrcAddr'}"
		      . " SrcPort:$conninfo->{'SrcPort'}");

		my $val = sprintf("%x", $result{'Result'});
		kReg_Common_Error(__FILE__, __LINE__, $function,
				  "result: $result{'Result'}(0x$val) -- ".
				  "fails.");
		return undef;
	}

	($value, $data) = unpack('a16 a*', $data);
	$result{'SrcAddr'} = kInetNtoP($result{'AddrType'}, $value);
	unless(defined($result{'SrcAddr'})) {
		kReg_Common_Error(__FILE__, __LINE__, $function,
				  "kInetNtoP: failure");

		return(undef);
	}

	($value, $data) = unpack('a16 a*', $data);
	$result{'DstAddr'} = kInetNtoP($result{'AddrType'}, $value);
	unless(defined($result{'DstAddr'})) {
		kReg_Common_Error(__FILE__, __LINE__, $function,
				  "kInetNtoP: failure");

		return(undef);
	}

	($result{'DataLength'},
	 $result{'Data'}
	) = unpack('N a*', $data);

	if($datalen - $size != $result{'DataLength'}) {
		kReg_Common_Error(__FILE__, __LINE__, $function,
			"\$datalen: $datalen -- requires $size byte.");

		return(undef);
	}

	return(\%result);
}



#----------------------------------------------------------------------#
# kMakeCloseAck()                                                      #
#----------------------------------------------------------------------#
sub
kMakeCloseAck($)
{
	my ($data) = @_;
	my %result = ();

	my $function = 'kMakeCloseAck';

	my $size = 8;
	my $datalen = length($data);
	if($size != $datalen) {
		kReg_Common_Error(__FILE__, __LINE__, $function,
			"\$datalen: $datalen -- ".
			"requires just $size byte.");

		return(undef);
	}

	($result{'Command'},
	 $result{'RequestNum'},
	 $result{'Result'},
	 $result{'SocketID'}) = unpack('n4', $data);

	if ($result{'Result'} != 0) {
		my $val = sprintf("%x", $result{'Result'});
		kReg_Common_Error(__FILE__, __LINE__, $function,
				  "result: $result{'Result'}(0x$val) -- ".
				  "fails.");
		return undef;
	}

	return \%result;
}



#----------------------------------------------------------------------#
# kMakeListenAck()                                                     #
#----------------------------------------------------------------------#
sub
kMakeListenAck($)
{
	my ($data) = @_;
	my %result = ();

	my $function = 'kMakeListenAck';

	my $size = 8;
	my $datalen = length($data);
	if($size != $datalen) {
		kReg_Common_Error(__FILE__, __LINE__, $function,
			"\$datalen: $datalen -- ".
			"requires just $size byte.");

		return(undef);
	}

	($result{'Command'},
	 $result{'RequestNum'},
	 $result{'Result'},
	 $result{'SocketID'}) = unpack('n4', $data);

	if ($result{'Result'} != 0) {
		my $val = sprintf("%x", $result{'Result'});
		kReg_Common_Error(__FILE__, __LINE__, $function,
				  "result: $result{'Result'}(0x$val) -- ".
				  "fails.");
		return undef;
	}

	return \%result;
}



#----------------------------------------------------------------------#
# kMakeConnInfoAck()                                                   #
#----------------------------------------------------------------------#
sub
kMakeConnInfoAck($)
{
	my ($data) = @_;
	my $value = 0;
	my %result = ();

	my $function = 'kMakeConnInfoAck';

#	my $size    = 52;
	my $size    = 64;  # support TLS
	my $datalen = length($data);
	if($size != $datalen) {
		kReg_Common_Error(__FILE__, __LINE__, $function,
			"\$datalen: $datalen -- ".
			"requires just $size byte.");

		return(undef);
	}

	($result{'Command'},
	 $result{'RequestNum'},
	 $result{'Result'},
	 $result{'Protocol'},
	 $result{'Connection'},
	 $result{'AddrType'},
	 $result{'Reserve1'},
	 $result{'Reserve2'},
	 $result{'SrcPort'},
	 $result{'DstPort'},
	 $data
	) = unpack('n3 C4 n3 a*', $data);

	if ($result{'Result'} != 0) {
		my $val = sprintf("%x", $result{'Result'});
		kReg_Common_Error(__FILE__, __LINE__, $function,
				  "result: $result{'Result'}(0x$val) -- ".
				  "fails.");
		return undef;
	}

	($value, $data) = unpack('a16 a*', $data);
	$result{'SrcAddr'} = kInetNtoP($result{'AddrType'}, $value);
	unless(defined($result{'SrcAddr'})) {
		kReg_Common_Error(__FILE__, __LINE__, $function,
				  "kInetNtoP: failure");

		return(undef);
	}

	($value, $data) = unpack('a16 a*', $data);
	$result{'DstAddr'} = kInetNtoP($result{'AddrType'}, $value);
	unless(defined($result{'DstAddr'})) {
		kReg_Common_Error(__FILE__, __LINE__, $function,
				  "kInetNtoP: failure");

		return(undef);
	}

	($result{'FrameID'},
	 $result{'Interface'},
	 $result{'TLSmode'},
	 $result{'TLSssl'},
	 $result{'TLSsession'},
	) = unpack('n2 N3', $data); # support TLS
#	) = unpack('n2', $data);

	return \%result;
}



#----------------------------------------------------------------------#
# kMakeDataInfoAck()                                                   #
#----------------------------------------------------------------------#
sub
kMakeDataInfoAck($)
{
	my ($data) = @_;

	my $value = 0;
	my %result = ();

	my $function = 'kMakeDataInfoAck';

	my $size    = 20;
	my $datalen = length($data);
	if($size > $datalen) {
		kReg_Common_Error(__FILE__, __LINE__, $function,
			"\$datalen: $datalen -- ".
			"requires more than $size byte.");

		return(undef);
	}

	($result{'Command'},
	 $result{'RequestNum'},
	 $result{'Result'},
	 $result{'SocketID'},
	 $result{'TimeStamp'},
	 $result{'TimeStamp2'},
	 $result{'DataLength'},
	 $data
	) = unpack('n4 N3 a*', $data);

	if ($result{'Result'} != 0) {
		my $val = sprintf("%x", $result{'Result'});
		kReg_Common_Error(__FILE__, __LINE__, $function,
				  "result: $result{'Result'}(0x$val) -- ".
				  "fails.");
		return undef;
	}

	if($datalen - $size != $result{'DataLength'}) {
		kReg_Common_Error(__FILE__, __LINE__, $function,
			       "\$datalen: $datalen -- requires $size byte.");

		return(undef);
	}

	$result{'Data'} = $data;

	return \%result;
}



#----------------------------------------------------------------------#
# kMakeClearAck()                                                      #
#----------------------------------------------------------------------#
sub
kMakeClearAck($)
{
	my ($data) = @_;
	my %result = ();

	my $function = 'kMakeClearAck';

	my $size = 6;
	my $datalen = length($data);
	if($size != $datalen) {
		kReg_Common_Error(__FILE__, __LINE__, $function,
				  "\$datalen: $datalen -- ".
				  "requires just $size byte.");
		return undef;
	}

	($result{'Command'},
	 $result{'RequestNum'},
	 $result{'Result'}
	 ) = unpack('n3', $data);

	if ($result{'Result'} != 0) {
		my $val = sprintf("%x", $result{'Result'});
		kReg_Common_Error(__FILE__, __LINE__, $function,
				  "result: $result{'Result'}(0x$val) -- ".
				  "fails.");
		return undef;
	}

	return \%result;
}



#----------------------------------------------------------------------#
# kInetPtoN()                                                          #
#----------------------------------------------------------------------#
sub
kInetPtoN($$)
{
	my ($af, $src) = @_;

	my $function = 'kInetPtoN';

	my @elements = ();
	my $dst      = undef;

	if(($af != 4) && ($af != 6)) {
		kReg_Common_Error(__FILE__, __LINE__, $function,
			"unknown af -- $af");

		return(undef);
	}

	for( ; ; ) {
		if(($af == 4) && ($src =~ /^\s*([0-9\.]+)\s*$/)) {
			@elements = split(/\./, $1);

			for(my $d = scalar(@elements); $d < 16; $d ++) {
				push(@elements, '0');
			}

			$dst = pack('C16', @elements);

			last;
		}

		if(($af == 6) &&
		   ($src =~ /^\s*([0-9A-Za-z:]+)\s*$/)) {
			my ($upper, $lower) = split(/::/, $1);

			my @up  = ();
			my @low = ();

			if(defined($upper)) {
				@up = split(/:/, $upper);
			}

			if(defined($lower)) {
				@low = split(/:/, $lower);
			}

			for(my $d = scalar(@up); $d < 8 - scalar(@low); $d ++) {
				push(@up, '0');
			}

			foreach my $elm (@up, @low) {
				push(@elements, hex($elm));
			}

			$dst = pack('n8', @elements);

			last;
		}

		kReg_Common_Error(__FILE__, __LINE__, $function,
			"No address associated with hostname -- $src");

		return(undef);
	}

	return($dst);
}



#----------------------------------------------------------------------#
# kInetNtoP()                                                          #
#----------------------------------------------------------------------#
sub
kInetNtoP($$)
{
	my ($af, $src) = @_;

	my $function = 'kInetNtoP';

	my @elements = ();
	my $dst = undef;

	for( ; ; ) {
		if($af == 4) {
			@elements = unpack('C4', $src);

			$dst = sprintf('%d.%d.%d.%d',
				$elements[0], $elements[1],
				$elements[2], $elements[3]);

			last;
		}

		if($af == 6) {
			my $size = 16;
			if(length($src) != $size) {
				kReg_Common_Error(__FILE__, __LINE__, $function,
					"\$src -- requires $size bytes.");

				return(undef);
			}

			@elements = unpack('n8', $src);

			my $abbr     = 0;
			my $compress = 0;
			my $cont     = 0;

			for(my $d = 1; $d < $#elements; $d ++) {
				if(!$abbr && !$elements[$d]) {
					$abbr ++;
					$compress ++;
				}

				if($elements[$d]) {
					$compress = 0;
					$cont     = 0;
				}

				if($compress) {
					unless($cont) {
						$dst .= ':';
						$cont ++;
					}

					next;
				}

				$dst .= sprintf(':%x', $elements[$d]);
			}

			$dst .= ':';

			unless(!$elements[0] && ($dst =~ /^::/)) {
				$dst = sprintf('%x%s', $elements[0], $dst);
			}

			unless(!$elements[$#elements] && ($dst =~ /::$/)) {
				$dst .= sprintf('%x', $elements[$#elements]);
			}

			last;
		}

		kReg_Common_Error(__FILE__, __LINE__, $function,
				  "unknown af -- $af");

		return(undef);
	}

	return($dst);
}



#----------------------------------------------------------------------#
# kInsert()                                                            #
#----------------------------------------------------------------------#
sub
kInsert($$;$$$)
{
	my ($base, $insert, $whence, $offset, $size) = @_;

	my $function = 'kInsert';

	my $_top_    = '';
	my $_middle_ = '';
	my $_bottom_ = '';

	my $_baselen_   = length($base);
	my $_insertlen_ = length($insert);

	unless(defined($whence)) {
		$whence = $_baselen_;
	}

	unless(defined($offset)) {
		$offset = 0;
	}

	unless(defined($size)) {
		$size = $_insertlen_ - $offset;
	}

	if(($whence < 0) || ($whence > $_baselen_)) {
		kReg_Common_Error(__FILE__, __LINE__, $function,
			"\$whence: invalid range -- $whence");
		return(undef);
	}

	if(($offset < 0) || ($offset > $_insertlen_)) {
		kReg_Common_Error(__FILE__, __LINE__, $function,
			"\$offset: invalid range -- $offset");
		return(undef);
	}

	if(($size   < 0) || ($size   > $_insertlen_)) {
		kReg_Common_Error(__FILE__, __LINE__, $function,
			"\$size: invalid range -- $size");
		return(undef);
	}

	if($offset + $size > $_insertlen_) {
		kReg_Common_Error(__FILE__, __LINE__, $function,
			"\$offset + \$size: invalid range -- $offset + $size");
		return(undef);
	}

	if($whence) {
		$_top_ = substr($base, 0, $whence);
	}

	if($size) {
		$_middle_ = substr($insert, $offset, $size);
	}

	if($_baselen_ - $whence) {
		$_bottom_ = substr($base, $whence, $_baselen_ - $whence);
	}

	return($_top_. $_middle_. $_bottom_);
}



#----------------------------------------------------------------------#
# kInit_Common_Error()                                                 #
#----------------------------------------------------------------------#
sub
kInit_Common_Error()
{
	@strerror = ();

	return(undef);
}



#----------------------------------------------------------------------#
# kReg_Common_Error()                                                  #
#----------------------------------------------------------------------#
sub
kReg_Common_Error($$$$)
{
	my ($file, $line, $function, $string) = @_;

	my $basename = basename($file);

	push(
		@strerror,
		{
			'file'     => $basename,
			'line'     => $line,
			'function' => $function,
			'string'   => $string
		}
	);

	return(undef);
}



#----------------------------------------------------------------------#
# kDump_Common_Error()                                                 #
#----------------------------------------------------------------------#
sub
kDump_Common_Error()
{
	my $str = undef;

	foreach my $error (@strerror) {
		unless(defined($str)) {
			$str = '';
		}

		$str .= "$error->{'file'}: ";
		$str .= "$error->{'line'}: ";
		$str .= "kCommon::$error->{'function'}(): ";
		$str .= "$error->{'string'}";
		$str .= "\n";
	}

	kInit_Common_Error();

	return($str);
}



#----------------------------------------------------------------------#
# parseArgs()                                                          #
# internal use                                                         #
#----------------------------------------------------------------------#
sub parseArgs($$)
{
	my ($seqname, $seqdir) = @_;


	use Getopt::Long;
	$Getopt::Long::ignorecase=undef;
	my $optStat =
		GetOptions("tn|TnDef=s",
			   "nut|NutDef=s",
			   "pkt|PktDef=s",
			   "l|LogLevel=i",
			   "ti|TestTitle=s",
			   "log|LogFile=s",
			   "h|Help",
			   "trace",   # for debug, output trace 
			   "keepImd", # for debug, keep intermidiate file
			   "v|VLog",  # print STDOUT log file
			   "nostd|NoStd",
			   "root|KoiRoot=s",
			   "remote=s",
			   "cpp=s",
			# <----------------------- for v6eval ------------------------ #
			   "v6eval",
			   "v6eval_root|V6Root=s",
			   "v6eval_tn|V6TnDefPath=s",
			   "v6eval_nut|V6NutDefPath=s",
			   "v6eval_cpp=s",
			# ------------------------ for v6eval -----------------------> #
			  );

	# XXX
# 	if( $opt_h || !$optStat ) {
# 		printUsage();
# 	}

	$KoiRoot = $opt_root || $ENV{KOIROOT} || "/usr/local/koi/" ;
	$NoStd	= $opt_nostd	? $opt_nostd	: 0;
	$VLog	= $opt_v     ? $opt_v	: 0;
	$Trace	    = ($opt_trace==1);
	$KeepImd    = ($opt_keepImd==1);
	$TnDef	= $opt_tn    ? $opt_tn	: "tn.def";
	$TnDef	= searchPath("${seqdir}:./:${KoiRoot}/etc/", $TnDef);
	$NutDef = $opt_nut   ? $opt_nut : "nut.def";
	$NutDef	 = searchPath("${seqdir}:./:${KoiRoot}/etc/", $NutDef);
	$TestTitle= $opt_ti   ? $opt_ti : "${seqname}";
	$LogFile= $opt_log   ? $opt_log : "${seqdir}${seqname}.log";
	$LogLevel   = $opt_l	 ? $opt_l   : 1;
	$DbgLevel   = $opt_d	 ? $opt_d   : 0;
	$RemoteOption = $opt_remote || "";
	$CppOption = $opt_cpp || "";
	# <--------------------------- for v6eval ---------------------------- #
	$V6Root	= $opt_v6eval_root || $ENV{'V6EVALROOT'} || '/usr/local/v6eval/';
	$V6ToolDir	= "$V6Root/bin";
	$V6SocketPath	= "/tmp";
	$V6TnDefPath	= $opt_v6eval_tn? $opt_v6eval_tn: 'tn.def';
	$V6TnDefPath	= searchPath("${seqdir}:./:${V6Root}/etc/", $V6TnDefPath);
	$V6NutDefPath	= $opt_v6eval_nut? $opt_v6eval_nut: 'nut.def';
	$V6NutDefPath	= searchPath("${seqdir}:./:${V6Root}/etc/", $V6NutDefPath);
	$V6CppOption	= $opt_v6eval_cpp || '';
	$PktDef	= $opt_pkt? $opt_pkt: "${SeqDir}packet.def";
	# ---------------------------- for v6eval ---------------------------> #

}


#----------------------------------------------------------------------#
# kModule_Initialize()                                                 #
#----------------------------------------------------------------------#
local(*LOG);
sub
kModule_Initialize(;$$)
{
	my ($path, $protocol) = @_;

	my $function = 'kModule_Initialize';

	$SIG{CHLD} = \&handleChildProcess;

	unless(defined($path)) {
		$path = $DEFAULT_SOCKET_PATH;
	}

	unless(defined($protocol)) {
		$protocol = SOCK_STREAM;
	}

	my $prog     = $DEFAULT_SOCKIO_PATH;
	my ($seqname, $seqdir, $seqsuffix) = fileparse($0, '.seq');
	$SeqDir	= $seqdir;
	my $progname = basename($prog);

	kInit_Common_Error();
	if(-e $path) {
#		kReg_Common_Error(__FILE__, __LINE__, $function,
#			"make sure to terminate $progname and remove $path");
#
#		my $strderror = kDump_Common_Error();
#
#		if(defined($strderror)) {
#			die "$strderror";
#			# NOTREACHED
#		}
#
#		die '';
#		# NOTREACHED
		unlink($path);
	}

	# parse argments
	$SeqFile = $0;
	$CommandLine = "$SeqFile @ARGV";
	my @storedARGV = @ARGV;
	parseArgs($seqname, $seqdir);
	if(defined($ENV{'V6EVAL_WITH_KOI'})) {
		@ARGV = @storedARGV;
	}

	# read environment
	readEnv();

	foreach my $key (keys %TnDef) {
		if ($key =~ /^Link[0-9]$/) {
			push(@TnIfs, $key);
		}
	}

	foreach my $key (keys %NutDef) {
		if ($key =~ /^Link[0-9]$/) {
			push(@NutIfs, $key);
		}
	}

	getVersion();

	# open log file
	unless (open(LOG, ">$LogFile")) {
		kReg_Common_Error(__FILE__, __LINE__, $function,
				  "Can not create $LogFile for logging ($!)");
		die '';
	}

	# print HTML header
	printHTMLHeader();

        prLog("<BODY BGCOLOR=\"#F0F0F0\">");

	# print banner
	printBanner();

	# prepare to print Test Sequence
	prLog("\n<HR><H1>Test Sequence Execution Log</H1>");
	prLog("<TABLE BORDER=1>");
	my $timestamp=getTimeStamp();
	prLog("<TR><TD>$timestamp</TD><TD>Start</TD></TR>");
	$vLogStat=$vLogStatCloseRow;

	kInit_Common_Error();
	$SOCKETIO_PID = kBoot_SocketIO($prog, $path, $protocol);
	unless(defined($SOCKETIO_PID)) {
		kReg_Common_Error(__FILE__, __LINE__, $function,
			"kBoot_SocketIO: failure");

		my $strderror = kDump_Common_Error();

		if(defined($strderror)) {
			die "$strderror";
			# NOTREACHED
		}

		die '';
		# NOTREACHED
	}

	# <----------------------- for v6eval ------------------------ #
	if(defined($opt_v6eval) && $opt_v6eval) {
		v6eval_initialize();
	}
	# ------------------------ for v6eval -----------------------> #

	# for remote function
	$ChildPid = undef;
	$ChildStatus = undef;
	$REMOTE_ASYNC_STATE = undef;

	# fork tcpdump
	forkTcpdump();

	# XXX: should use defined()? have to know return value of new()
	kInit_Common_Error();
	unless(($SOCKFD =
		IO::Socket::UNIX->new('Type' => $protocol, 'Peer' => $path))) {

		kReg_Common_Error(__FILE__, __LINE__, $function,
			"$! -- Type: $protocol, Peer: $path");

		my $strderror = kDump_Common_Error();

		if(defined($strderror)) {
			die "$strderror";
			# NOTREACHED
		}

		die '';
		# NOTREACHED
	}

	$SOCKFD->autoflush(1);

	return;
}


sub printHTMLHeader()
{
        prLog("<!DOCTYPE HTML PUBLIC \"-//W3C//DTD HTML 4.0//EN\""
	      . "\"http://www.w3c.org/TR/REC-html40/strict.dtd\">");
        prLog("<HTML>\n<HEAD>");
        prLog("<TITLE>IPv6 Conformance Test Report</TITLE>");
        prLog("<META NAME=\"GENERATOR\" "
	      . "CONTENT=\"TAHI IPv6 Conformance Test Kit\">");

	if ($USE_JAVASCRIPT) {
		print LOG <<ECHO;
<script type="text/javascript">

var packets = new Array();

var POP_ID_PREFIX = "pop";
var PACKET_INFO_PREFIX = "koiPacketInfo";

var COLOR_BG = "#ffdddd";

var WINDOW_HEIGHT = 300;
var WINDOW_WIDTH = 300;
var OFFSET_HEIGHT = 5;
var OFFSET_WIDTH = 20;

var IE = false;
var FF = false;
var NN4 = false;
if (document.all) {
	IE = true;
}
else if (document.getElementById) {
	FF = true;
}
else if (document.layers) {
	NN4 = true;
}

function popup(id, event) {
	var header, footer, pos_x, pos_y, str;

	if (NN4) {
		return;
	}

	header = '<div style="';
	// header += 'width:' + WINDOW_WIDTH + ';';
	header += 'background-color:' + COLOR_BG + ';';
	header += 'border-width:3pt;';
	header += 'border-style:solid;';
	header += 'border-color:' + COLOR_BG + ';';
	//header += 'padding:0;'
	//header += 'margin:0;';
	header += '">';

	footer = '</div>';

	str = header;
	str += '<pre style="line-height:90%">';
	str += getPacket(id);
	str += '</pre>';
	str += footer;

	key = POP_ID_PREFIX + id;

	if (IE) {
		pos_x = document.body.scrollLeft+event.clientX;
		pos_y = document.body.scrollTop+event.clientY;
		document.all(key).style.pixelLeft = pos_x+OFFSET_WIDTH;
		document.all(key).style.pixelTop = pos_y+OFFSET_HEIGHT;
		document.all(key).innerHTML = str;
		document.all(key).style.visibility = 'visible';
	}
	else if (FF) {
		pos_x = event.pageX;
		pos_y = event.pageY;
		document.getElementById(key).style.left = pos_x+OFFSET_WIDTH + 'px';
		document.getElementById(key).style.top = pos_y+OFFSET_HEIGHT + 'px';
		document.getElementById(key).innerHTML = str;
		document.getElementById(key).style.visibility = 'visible';
	}
	else if (NN4) {
		pos_x = event.pageX;
		pos_y = event.pageY;
		document.layers[key].moveTo(pos_x+OFFSET_WIDTH, pos_y+OFFSET_HEIGHT);
		document.layers[key].document.open();
		document.layers[key].document.write(str);
		document.layers[key].document.close();
		document.layers[key].visibility = 'show';
	}
}

function popdown(id) {
	key = POP_ID_PREFIX + id;
	if (IE) {
		document.all(key).style.visibility = "hidden";
	}
	else if (FF) {
		document.getElementById(key).style.visibility = "hidden";
	}
	else if (NN4) {
		document.layers[key].visibility = "hidden";
	}
}

function getPacket(id) {
	if (packets[id]) {
		return packets[id];
	}

	var str = getInnerHTML(PACKET_INFO_PREFIX + id);
	str = trimTag(str, 'pre');
	packets[id] = str;
	return str;
}

function getInnerHTML(id) {
	if (IE) {
		return document.all(id).innerHTML;
	}
	else if (FF) {
		return document.getElementById(id).innerHTML;
	}
}

function trimTag(str, tagName) {
	var index = str.indexOf('<' + tagName);
	index = str.indexOf('>', index + 1);

	var lastIndex = str.lastIndexOf('</' + tagName + '>');
	lastIndex = (lastIndex < 0) ? str.length : lastIndex;

	return str.substring(index + 1, lastIndex);
}

</script>
ECHO
	}

        prLog("</HEAD>\n");

}


sub printHTMLFooter()
{
	prLog("</BODY>\n</HTML>");
}


sub getVersion() {
	my $dummy;

	($dummy, $ToolVersion) = ('$Name: REL_2_2_0 $' =~ /\$(Name): (.*) \$/ );
	if (!$ToolVersion){
		$ToolVersion=	'undefined';
	}
	if (defined($TestVersion)) { # it should be defined in *.seq file.
		($dummy, $TestVersion) =
			($TestVersion =~ /\$(Name): (.*) \$/  );
	}
	else {
		$TestVersion=	'undefined';
	}
}

sub printBanner()
{
	my $datestr = getDateString();

	# print test information
	prLog("<H1>Test Information</H1>");
	prLog("<TABLE BORDER=1>");
	prLog("<TR><TD>Title</TD><TD>$TestTitle</TD></TR>");
	prLog("<TR><TD>CommandLine</TD><TD>$CommandLine</TD></TR>");
	# <----------------------- for v6eval ------------------------ #
	prLog("<TR><TD>Script</TD><TD><A HREF=\"${SeqFile}\">${SeqFile}</A></TD></TR>");
	if(defined($opt_pkt)) {
		prLog("<TR><TD>Packet</TD><TD><A HREF=\"${opt_pkt}\">${opt_pkt}</A></TD></TR>");
	}
	# ------------------------ for v6eval -----------------------> #
	prLog("<TR><TD>TestVersion</TD><TD>$TestVersion</TD></TR>");
	prLog("<TR><TD>ToolVersion</TD><TD>$ToolVersion</TD></TR>");
	prLog("<TR><TD>Start</TD><TD>$datestr</TD></TR>");
	prLog("<TR><TD>Tn</TD><TD>$TnDef</TD></TR>");
	prLog("<TR><TD>Nu</TD><TD>$NutDef</TD></TR>");

	prLog("</TABLE>");
}

sub prLog($;$)
{
	my ($message,	# message for logging
	    $level	# log level, this will be compared with the 
			# outer level specifid by '-l' arguments
	   ) = @_;

	unless (defined($level)) {
		$level = 0;  # default 0;
	}

        #prTrace("LOG $level $LogLevel");
        if ($level<=$LogLevel) {
		print LOG "$message\n";
	}
	if ($VLog && $level<=$LogLevel) {
		prOut "$message\n";
	}
}


sub prLogHTML($;$)
{
	my ($message,	# message for logging
	    $level	# log level, this will be compared with the 
			# outer level specifid by '-l' arguments
	   ) = @_;

	unless (defined($level)) {
		$level = 0;
	}

        #prTrace("LOG $level $LogLevel");
        if ($level<=$LogLevel) {
		print LOG "$message";
	}
	if ($VLog && $level<=$LogLevel) {
		prOut "$message";
	}
}


sub prOut($)
{
	my ($message) = @_;
	$message = HTML2TXT($message);
	print STDOUT "$message";
}

sub prErr($)
{
	my ($message) = @_;
	prLogHTML("<FONT COLOR=\"#FF0000\">!!! $message</FONT><BR>");
	$message = HTML2TXT($message);
	print STDERR "$message";
}

sub prErrExit($)
{
	my ($message) = @_;
	my $file = __FILE__;
	prErr("$file: $message");

	$! = 64, die "";
}


sub prDebug($)
{
	my ($message) = @_;

	print STDOUT "$message" if $PRINT_DEBUG;
}


sub pr($)
{
	my ($message) = @_;

	print STDOUT "$message";
}

sub getDateString() {
	my ($sec, $min, $hour, $day, $mon, $year) = localtime;
	my $datestr = sprintf('%02d/%02d/%02d %02d:%02d:%02d',
			      $year+1900, $mon+1, $day, $hour, $min, $sec);
	return $datestr;
}

sub getTimeStamp() {
	my ($sec,$min,$hour) = localtime;
	my $timestr = sprintf('%02d:%02d:%02d', $hour, $min, $sec);
	return $timestr;
}

sub HTML2TXT($) {
	my (
	    $message # HTML message
	   ) = @_;
	$message =~ s/<BR>/\n/g;
	$message =~ s/<\/TR>/\n/g;
	$message =~ s/<\/TD>/  /g;
	$message =~ s/<[^>]*>//g;
	$message =~ s/&lt\;/</g;
	$message =~ s/&gt\;/>/g;
	$message =~ s/\n+$//g;
	$message .= "\n";
	return $message;
}


sub addMD5($$$) {
	my($seq, $def, $log) = @_;

	my @md5 = ();

	local(*LOG);

	if (defined($seq)) {
		push(@md5, getMD5($seq));
	}
	if (defined($def)) {
		push(@md5, getMD5($def));
	}
	if (defined($log)) {
		push(@md5, getMD5($log));
	}

	unless(open(LOG, ">> $log")) {
		return;
	}

	foreach my $value (@md5) {
		print LOG "<!-- $value -->\n";
	}

	close(LOG);

	return;
}

sub getMD5($) {
	my ($file) = @_;

	use Digest::MD5;

	local(*FILE);

	unless(open(FILE, $file)) {
		return('');
	}

	my $ctx = Digest::MD5->new;
	$ctx->addfile(*FILE);
	my $digest = $ctx->hexdigest;

	close(FILE);

	return($digest);
}

#----------------------------------------------------------------------#
# kLogHTML()                                                           #
#----------------------------------------------------------------------#
sub
kLogHTML($;$)
{
	my ($message, $error) = @_;

	if ($vLogStat==$vLogStatCloseRow) {
		my $str = ($error) ? getTimeStamp() : '<br>';
		prLog("<TR><TD>${str}</TD><TD>");
		$vLogStat=$vLogStatOpenRow;
	}

	prLogHTML($message);
	if ($VLog == 0) {
		prOut "$message";
	}
}

#----------------------------------------------------------------------#
# kModule_Terminate()                                                  #
#----------------------------------------------------------------------#
sub
kModule_Terminate(;$)
{
	my ($path) = @_;

	my $function = 'kModule_Terminate';

	# collect child process generated by kRemoteAsync() explicitly
	kRemoteAsyncWait();

	unless(defined($path)) {
		$path = $DEFAULT_SOCKET_PATH;
	}

	close($SOCKFD);

	# <----------------------- for v6eval ------------------------ #
	if(defined($opt_v6eval) && $opt_v6eval) {
		v6eval_terminate();
	}
	# ------------------------ for v6eval -----------------------> #

	kInit_Common_Error();

#	$SIG{CHLD} = 'IGNORE';
	unless(kill('TERM', $SOCKETIO_PID)) {
		kReg_Common_Error(__FILE__, __LINE__, $function,
			"kill: $SOCKETIO_PID: $!");

		my $strderror = kDump_Common_Error();

		if(defined($strderror)) {
			die "$strderror";
			# NOTREACHED
		}

		die '';
		# NOTREACHED
	}

	killTcpdump();

	if(-e $path) {
		unlink($path);
	}

	prLog("</TABLE>\n");

	prLog("<HR><H1>Packet Reverse Log</H1>");
	prLog("<UL>\n$PacketLog</UL>\n");

	printHTMLFooter();
	close(LOG);

	# add sequence file md5 value and log file md5 value to log file
	addMD5($SeqFile, undef, $LogFile);

	return;
}



#----------------------------------------------------------------------#
# kBoot_SocketIO()                                                     #
#----------------------------------------------------------------------#
sub
kBoot_SocketIO($$$)
{
	my ($prog, $path, $protocol) = @_;

	my $function = 'kBoot_SocketIO';

	local (*READHANDLE, *WRITEHANDLE);

	pipe(READHANDLE, WRITEHANDLE);

	my $pid = fork();

	unless(defined($pid)) {
		kReg_Common_Error(__FILE__, __LINE__, $function, "fork: $!");
		return(undef);
	}

	unless($pid) {
		# child process
		close(READHANDLE);

		unless(defined(open(STDOUT, ">&WRITEHANDLE"))) {
			print("exit: open: $!");
			exit(-1);
		}

		exec("$prog -p $path");
	}

	# parent process
	close(WRITEHANDLE);

	while(<READHANDLE>) {
		chomp;

		if($_ =~ /^([^:]+):\s*(.*)$/) {
			my $level   = $1;
			my $message = $2;

			if(($level eq 'pipe') &&
				($message =~ /^(\S+\s+)+ready$/)) {

				last;
			}

			if($level eq 'error') {
				kReg_Common_Error(__FILE__, __LINE__,
					$function, "$message");
				next;
			}

			if($level eq 'exit') {
				kReg_Common_Error(__FILE__, __LINE__,
					$function, "$message");
				close(READHANDLE);

				return(undef);
			}
		}
	}

	close(READHANDLE);

	return($pid);
}


#--------------------------------------------------#
# internal-used subroutines                        #
#--------------------------------------------------#
sub readEnv()
{
	my $_function_ = 'readEnv';

	# read tn.def
	my $tn = '/usr/local/koi/etc/tn.def';
	%TnDef = readTnDef($tn);
	if (exists($TnDef{'error'})) {
		prErr("$_function_:\n$TnDef{'error'}\n");
	}

	# read nut.def
	my $nut = '/usr/local/koi/etc/nut.def';
	%NutDef = readNutDef($nut);
	if (exists($NutDef{'error'})) {
		prErr("$_function_:\n$NutDef{'error'}\n");
	}

	# <----------------------- for v6eval ------------------------ #
	if(defined($opt_v6eval) && $opt_v6eval) {
		%V6TnDef = readTnDef($V6TnDefPath);
		if(exists($V6TnDef{'error'})) {
			prErr("$_function_: $V6TnDef{'error'}\n");
		}

		%V6NutDef = readNutDef($V6NutDefPath);
		if(exists($V6NutDef{'error'})) {
			prErr("$_function_: $V6NutDef{'error'}\n");
		}
	}
	# ------------------------ for v6eval -----------------------> #
}


sub readTnDef($)
{
	my ($tn) = @_;

	my $_function_ = 'readTnDef';

	my %TmpTnDef	= ();

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
		if ( /^(\S+)\s+(.*)/ ) {
			$name = $1;
			$value = $2;
			$TmpTnDef{$name} = $value;
		}

		if (/^(RemoteTarget)\s+(.*)/
		    || /^(RemoteMethod)\s+(.*)/) {
		    #prLog("<TR><TD>$name</TD><TD>$value</TD></TR>");
		}
		# <----------------------- for v6eval ------------------------ #
		elsif(defined($opt_v6eval) && $opt_v6eval &&
		      (/^(Link[0-9]+)\s+(\S+)\s+(([0-9a-fA-F]{1,2}:){5}[0-9a-fA-F]{1,2})/)) {
			push(@V6TnIfs, $1);
			push(@V6TnSos, $2);
			$TmpTnDef{$1."_device"}	= $2;
			$TmpTnDef{$1."_addr"}	= $3;
		}
		elsif(defined($opt_v6eval) && $opt_v6eval &&
		      (/^(RemoteDevice)\s+(\S+)/   ||
		       /^(RemoteDebug)\s+(\S+)/    ||
		       /^(RemoteIntDebug)\s+(\S+)/ ||
		       /^(RemoteLog)\s+(\S+)/      ||
		       /^(RemoteSpeed)\s+(\S+)/    ||
		       /^(RemoteLogout)\s+(\S+)/   ||
		       /^(RemoteCuPath)\s+(\S+)/   ||
		       /^(filter)\s+(\S+)/)) {
			#prLog("<TR><TD>$name</TD><TD>$value</TD></TR>");
		}
		# ------------------------ for v6eval -----------------------> #
		elsif (/^(Link[0-9]+)\s+(\S+)/) {
			$TmpTnDef{$name."_device"} = $value;
		}
		else {
			$TmpTnDef{'error'} .= "$tn line $i : unknown directive $_\n";
		}

		$i++;
	}

	close FILE;

	return %TmpTnDef;
}

sub readNutDef($)
{
	my ($nut) = @_;

	my $_function_ = 'readNutDef';

	my %TmpNutDef    = ();

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
			$TmpNutDef{$name} = $value;
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
			$TmpNutDef{$name} = $value;
		}
		elsif ($name eq 'UserPrompt') {
			$prompt_command{$TmpNutDef{'System'}} = $value;
		}
		elsif ($name eq 'RootPrompt') {
			$prompt_command_root{$TmpNutDef{'System'}} = $value;
		}
		elsif ($name eq 'LoginPrompt') {
			$prompt_login{$TmpNutDef{'System'}} = $value;
		}
		elsif ($name eq 'PasswordPrompt') {
			$prompt_password{$TmpNutDef{'System'}} = $value;
		}
		elsif ($name eq 'EscapePrompt') {
			$prompt_escape{$TmpNutDef{'System'}} = $value;
		}
		# <----------------------- for v6eval ------------------------ #
		elsif(defined($opt_v6eval) && $opt_v6eval &&
		      (/^(Link[0-9]+)\s+(\S+)\s+(([0-9a-fA-F]{1,2}:){5}[0-9a-fA-F]{1,2})/)) {
			push(@V6NutIfs, $1);
			$TmpNutDef{$1."_device"}	= $2;
			$TmpNutDef{$1."_addr"}	= $3;
		}
		elsif(defined($opt_v6eval) && $opt_v6eval &&
		      (/^(User)\s+(\S+)/   ||
		       /^(Password)\s+(\S+)/)) {
			#prLog("<TR><TD>$name</TD><TD>$value</TD></TR>");
		}
		# ------------------------ for v6eval -----------------------> #
		elsif (/^(Link[0-9]+)\s+(\S+)/) {
			$TmpNutDef{$name."_device"} = $value;
		}
		else {
			$TmpNutDef{'error'} .= "$nut line $i : unknown directive $_\n";
		}

		$i++;
	}

	close FILE;

	return %TmpNutDef;
}


sub forkCmd($$)
{
	my ($cmd,		# command string
	    $log		# log file
	   ) = @_;

	my $function = 'forkCmd';

	my $pid;
	my $arg0 = split ' ' ,$cmd;

	pipe PIN,COUT;
	unless (defined($pid = fork())) {
		kReg_Common_Error(__FILE__, __LINE__, $function,
				  "Fork failed for <$cmd>");
		exit(1);
	}
	unless( $pid ) {	# child process
		# should close if any explicit open files exit
		close(PIN);
		open(STDOUT, ">&COUT");
		open(STDERR, ">>$log");
		exec "$cmd";
		print COUT "err:Exec fail for $arg0 ($!)\n";
		print STDERR "err:Exec fail for $arg0 ($!)\n";
		# prErrExit("Exec failed for <$opt>");
		prErrExit("Exec failed for <$cmd>");
		kReg_Common_Error(__FILE__, __LINE__, $function,
				  "Exec failed for <$cmd>");
		exit(1);
	}

	close(COUT);
	pr("forkCmd()... $cmd\n");

	my $ready = 0;
	while ( <PIN> ) {	# wait until socket ready
		chomp;
		($type, $line) = /^(\w\w\w):(.*)$/;
		if ($_ eq 'std: ready') {
			$ready = 1;
			last;
		} elsif ($type eq 'err') {
			pr("$line");
		}
	}
	close(PIN);

	unless ($ready) {
		prErr("Could not get ready response from <$arg0>");
		kReg_Common_Error(__FILE__, __LINE__, $function,
				  "Could not get ready response from <$arg0>");
		exit(1);
	}

	return $pid;
}


sub forkCmdWoCheck($$)
{
	my ($cmd,		# command string
	    $log		# log file
	   ) = @_;

	my $function = 'forkCmdWoCheck';

	my $pid;
	my $arg0 = split ' ' ,$cmd;

	pipe PIN,COUT;
	unless (defined($pid = fork())) {
		prErr("Fork failed for <$cmd>");
	}
	unless( $pid ) {	# child process
		# should close if any explicit open files exit
		close(PIN);
		open(STDOUT, ">&COUT");
		open(STDERR, ">>$log");
		exec "$cmd";
		print COUT "err:Exec fail for $arg0 ($!)\n";
		print STDERR "err:Exec fail for $arg0 ($!)\n";
		# prErrExit("Exec failed for <$opt>");
		prErrExit("Exec failed for <$cmd>");
	}

	close(COUT);

# 	while ( <PIN> ) {	# wait until socket ready
# 		chomp;
# 		my ($type, $line) = /^(\w\w\w):(.*)$/;
# 		if ($type eq 'err') {
# 			close(PIN);
# 			prErrExit("$line");
# 		}
# 	}

	close(PIN);
	pr("forkCmdWoCheck()... $cmd\n");

	return $pid;
}


sub forkTcpdump()
{
	my $dumpCmd = "tcpdump -n -s 2000 -x -e";
	my $log;
	foreach my $ifname (@TnIfs) {
		if ( grep {$ifname eq $_} @NutIfs ) {
			# run tcpdump
			my $if = $TnDef{$ifname."_device"};
			my ($basename, $dirname) = fileparse($LogFile);
			$basename =~ s/\./_/g;
			my $pcapfile = $dirname . $basename . '_' . $ifname;
			my $cmd = "$dumpCmd ".
				"-i $if ".
				"-w $pcapfile.pcap ";
			push(@TcpdumpPids, forkCmdWoCheck($cmd, '/dev/null') );
			# push(@TcpdumpPids, forkCmd($cmd, '/dev/null') );
		}
	}

	if (@TcpdumpPids == 0) {
		prErr("No interface to use commonly\n".
		      "TN : @TnIfs\nNUT: @NutIfs");
	}

}

sub killTcpdump()
{
	foreach (@ProcessPids) {
		prDebug("Exiting... sending SIGTERM to $_");
		my $ret = kill('TERM', $_);
		unless ($ret) {
			prOut("Error in killing process pid=$_");
		}
	}

	sleep 1;
	foreach (@TcpdumpPids) {
		prDebug("Exiting... sending SIGINT to $_");
		my $ret = kill('INT', $_);
		unless ($ret) {
			prOut("Error in killing tcpdump pid=$_");
		}
	}

}

sub handleChildProcess()
{
	$ChildPid = wait;
	$ChildStatus = $?;

	my ($status) = sprintf("0x%08x", $ChildStatus);

	my $i = 0;
	foreach my $elem (@ProcessPids) {
		if ($ChildPid == $elem) {
			splice(@ProcessPids, $i, 1);
			last;
		}
		$i++;
	}

        if ($ChildPid == $ExecutingPid_krasync) {
		# kRemoteAsync() finished
                $ExecutingPid_krasync = 0;
		# save child pid for kRemoteAsync()
		$ChildPid_krasync = $ChildPid;
		# save child status for kRemoteAsync()
		$ChildStatus_krasync = $ChildStatus;
		$ChildPid = 0;
		return;
        }

	if ($ChildPid == $ExecutingPid) {
		$ExecutingPid = 0;
		return;
	}

	if(!($CLEANUP) && ($ChildPid == $SOCKETIO_PID)) {
		prErrExit("koid died pid=$ChildPid status=$status");
	}

	# <----------------------- for v6eval ------------------------ #
        if(defined($opt_v6eval) && $opt_v6eval &&
	   !($CLEANUP) && (grep {$ChildPid == $_} @PktbufPids)) {
		my $pid	= 0;
		for (1..scalar(@PktbufPids)) {
			$pid	= shift(@PktbufPids);
			if($pid == $ChildPid) {
				prErrExit("pktbuf died pid=$ChildPid status=$status");
			}
			push(@PktbufPids, $pid);
		}
	}
	# ------------------------ for v6eval -----------------------> #

	if (!($CLEANUP) && (grep {$ChildPid==$_} @TcpdumpPids)) {
		my $pid;
		for (1..scalar(@TcpdumpPids)) {
			$pid=shift(@TcpdumpPids);
			if ($pid==$ChildPid) {
				prErrExit("tcpdump died pid=$ChildPid status=$status");
			}
			push(@TcpdumpPids,$pid);
		}
	}

}


sub searchPath($$)
{
	my($path,           # path
	   $filename        # filename for search
	  ) = @_;

	my $function = 'searchPath';

        my $fullname = "";
        if ($filename =~ m!.*/.+!) {
                $fullname = $filename;
        }

        my @paths = split(/:/,($path));
        foreach (@paths) {
                my $tmpname = $_ . "/" . $filename;
                #my $tmpname = $_ .  $filename;
                if ($fullname eq "") {
                        $fullname = $tmpname if (-r $tmpname);
                }
        }

	if ($fullname eq "") {
		kReg_Common_Error(__FILE__, __LINE__, $function,
				  "$filename don't exist in the path"
				  ."or cannot read in ``$path''\n");
		return undef;
	}

        return $fullname;
}

#----------------------------------------------------------------------#
# kRemote()                                                            #
#----------------------------------------------------------------------#
sub kRemote($;$@)
{
	my ($fname,	# remote file name
	    $opts,	# options
	    @args,	# variable args
	   ) = @_;

	my $function = 'kRemote';
	kInit_Common_Error();

	my $koidir = '/usr/local/koi';
	my $rpath = './';
	$rpath .= ":$ENV{PATH}";
	$rpath .= ":./remotes/$NutDef{System}/" if $NutDef{System};
	$rpath .= ":$koidir/bin/remotes/$NutDef{System}/" if $NutDef{System};
	$rpath .= ":$koidir/bin/remotes/unknown/";

	my $cmd	 = searchPath($rpath, $fname);
	$cmd .= " $opts @args";

	if ($vLogStat == $vLogStatOpenRow) {
		prLog("</TD>\n</TR>");
	}

	my $timestr = getTimeStamp();

	prLogHTML("<TR VALIGN=\"TOP\"><TD>$timestr</TD>\n");
	prLogHTML("<TD width=\"100%\">\nkRemote($fname) ``$cmd''<br>\n");

        if ($REMOTE_ASYNC_STATE eq 'RUNNING') {
		kReg_Common_Error(__FILE__, __LINE__, $function,
				  "RemoteAsync process already exists:".
				  "pid=$pid_krasync");
		return undef;
        }

	pipe PIN,COUT;
	$ChildPid = 0;

	unless (defined($ExecutingPid = $pid = fork())) {
		kReg_Common_Error(__FILE__, __LINE__, $function,
				  "fork failed for <$cmd>");
		return undef;
	}

	push(@ProcessPids, $pid);

	unless ($pid) { # child process
		open(STDOUT, ">&COUT");
		open(STDERR, ">&COUT");
		close(PIN);
		# close(STDIN);
		# should close if any explicit open files exit
		exec "$cmd";
		kReg_Common_Error(__FILE__, __LINE__, $function,
				  "exec failed for <$cmd>");
		return undef;
	}

	close(COUT);
	prLog("kRemote()... $cmd\n");
	prLogHTML("<PRE>");

	my $stdout = '';
	while (<PIN>) {
		$stdout .= $_;
		chomp;
		prOut("$_");
		s/\r//g;
		s/&/&amp;/g;
		s/"/&quot;/g;
		s/</&lt;/g;
		s/>/&gt;/g;
		prLog("$_");
	}
	close(PIN);

	while ($ChildPid == 0) {};

	my $status = $ChildStatus;
	if ($ChildPid != $pid) {
		kReg_Common_Error(__FILE__, __LINE__, $function,
				  "unknown child died $pid $ChildPid "
				  . "(status=$status)!!");
		return undef;
	}

	if ($status & 0xff) {	# died by signal
		kReg_Common_Error(__FILE__, __LINE__, $function,
				  "Catch signal <$cmd>");
		return undef;
	}

 	my $rc = ($status >> 8);
	if ($rc == $exitNS) {
		$_ = "NUT($NutDef{System}) does not support the functionality";
		prLog($_);
		prOut($_);
		exit($exitNS);
	}

	prLog("</PRE>\n</TD></TR>\n");
	$vLogStat = $vLogStatCloseRow;
	return $rc;
}


sub kRemoteAsync($;$@)
{
	my ($fname,	# remote file name
	    $opts,	# options
	    @args,	# variable args
	   ) = @_;

	my $function = 'kRemote';
	kInit_Common_Error();

	my $koidir = '/usr/local/koi';
	my $rpath = "./";
	$rpath .= ":$ENV{PATH}";
	$rpath .= ":./remotes/$NutDef{System}/" if $NutDef{System};
	$rpath .= ":$koidir/bin/remotes/$NutDef{System}/" if $NutDef{System};
	$rpath .= ":$koidir/bin/remotes/unknown/";

	my $cmd	 = searchPath($rpath, $fname);
	$cmd .= " $opts @args";

	if ($vLogStat == $vLogStatOpenRow) {
		prLog("</TD>\n</TR>");
	}

	my $timestr = getTimeStamp();

	prLogHTML("<TR VALIGN=\"TOP\"><TD>$timestr</TD>\n");
	prLogHTML("<TD width=\"100%\">\nkRemoteAsync($fname) ``$cmd''<br>\n");

        if ($REMOTE_ASYNC_STATE eq 'RUNNING') {
		kReg_Common_Error(__FILE__, __LINE__, $function,
				  "RemoteAsync process already exists:".
				  "pid=$pid_krasync");
		return undef;
        }

	$REMOTE_ASYNC_STATE = 'RUNNING';

	pipe PIN_KRASYNC,COUT_KRASYNC;

	unless (defined($ExecutingPid_krasync = $pid_krasync = fork())) {
		kReg_Common_Error(__FILE__, __LINE__, $function,
				  "fork failed for <$cmd>");
		return undef;
	}

 	push(@ProcessPids, $pid_krasync);

	unless ($pid_krasync) {		# child process
		open(STDOUT, ">&COUT_KRASYNC");
		open(STDERR, ">&COUT_KRASYNC");
		close(PIN_KRASYNC);
		# close(STDIN);
		# should close if any explicit open files exit
		sleep 3;
		exec "$cmd";
 		kReg_Common_Error(__FILE__, __LINE__, $function,
				  "exec failed for <$cmd>");
		return undef;
	}

	close(COUT_KRASYNC);

	prLog("kRemoteAsync()... $cmd<br>\n");

        prLog("<A NAME=\"kRemoteAsync$pid_krasync\"></A>");
        prLog("<A HREF=\"#kRemoteAsyncWait$pid_krasync\">Link to remote control log</A>");

	prLog("</TD>\n</TR>\n");
	$vLogStat = $vLogStatCloseRow;

	return 0;
}

sub kRemoteAsyncWait()
{
	if ($REMOTE_ASYNC_STATE ne 'RUNNING') {
		kReg_Common_Error(__FILE__, __LINE__, $function,
				  "kRemoteAsync() called "
				  . "without kRemoteAsync()");
		return undef;
	}

	if ($vLogStat == $vLogStatOpenRow) {
		prLog("</TD>\n</TR>\n");
	}

	my $timestr = getTimeStamp();
	prLogHTML("<TR VALIGN=\"TOP\"><TD>$timestr</TD>\n");
	prLogHTML("<TD>\nkRemoteAsyncWait()\n");

	$REMOTE_ASYNC_STATE = undef;

	prLogHTML("<PRE>");
	prLog("<A NAME=\"kRemoteAsyncWait$pid_krasync\"></A>");
	prLog("<A HREF=\"#kRemoteAsync$pid_krasync\">"
	      . "Link to remote control start point</A>");

	$stdout = '';
	while (<PIN_KRASYNC>) {
		$stdout .= $_;
		chomp;
		prOut("$_");
		s/\r//g;
		s/&/&amp;/g;
		s/"/&quot;/g;
		s/</&lt;/g;
		s/>/&gt;/g;
		prLog("$_");
	}
	close(PIN_KRASYNC);

	while ($ExecutingPid_krasync) {};

	my $status = $ChildStatus_krasync;
	if ($ChildPid_krasync != $pid_krasync) {
		kReg_Common_Error(__FILE__, __LINE__, $function,
				  "Unknown child died $pid_krasync "
				  . "$ChildPid_krasync (status=$status)!!");
		return undef;
	}

 	my $rc = ($status >> 8);
	if ($rc == $exitNS) {
		$_ = "NUT($NutDef{System}) does not support the functionality";
		prLog($_);
		prOut($_);
		exit $exitNS;
	}

	prLog("</PRE>\n</TD></TR>\n");
	$vLogStat = $vLogStatCloseRow;
	return $rc;
}

sub kSleep($;$)
{
	my ($seconds, $msg) = @_;

	unless (defined($msg)) {
		$msg = 'Sleep ' . $seconds . ' secs';
	}

	my $timestr = getTimeStamp();
	prLog("</TD></TR>\n") if($vLogStat==$vLogStatOpenRow);
        prLog("<TR VALIGN=\"TOP\">\n<TD>$timestr</TD>\n<TD>$msg\n</TD></TR>");
        $vLogStat=$vLogStatCloseRow;
        prOut("$msg\n");
        sleep $seconds;

	return;
}


# #----------------------------------------------------------------------#
# # sigchld()                                                            #
# #----------------------------------------------------------------------#
# sub
# sigchld()
# {
# 	waitpid($SOCKETIO_PID, 0);
# 
# 	return;
# }



# <--------------------------- for v6eval ---------------------------- #
sub
vCPP(;@)
{
	my (@opts) = @_;

	my $PktCompiler	= "cc -E -x c-header";
	my $baseopt	= "-I./ -I$V6Root/include/";
	my $deffile	= $PktDef;

	prDebug("vCPP($deffile)");
	prDebug("\$NoStd is $NoStd");
	if(!$NoStd) {
		my $includepath	= searchPath("./:$V6Root/include/", 'std.def');  
		$baseopt	.= " -include $includepath"
	}

	if(!$PktImd){   
		if($KeepImd){
			$PktImd = '/tmp/' . basename($deffile) . '.i';
		} else { 
			$PktImd = tmpnam();

			do {
				$PktImd = tmpnam();
			} until sysopen(FH, $PktImd, O_RDWR|O_CREAT|O_EXCL);

			close FH;
		}
	}

	my $cmd = "$PktCompiler $baseopt @opts $deffile > $PktImd";

	prDebug("Creating Intermediate file: $cmd");

	my ($sts) = execCmd($cmd);
	if($sts != 0) { 
		prErrExit("$cmd failed status:$sts\n");
	}
}



sub
vSend($@)
{
	my ($ifname, @frames)	= @_;

	my %ret = ();

	my $timestr = getTimeStamp();

	if($vLogStat == $vLogStatOpenRow){
		prLog("</TD>\n");
		prLog("</TR>\n");
	}

	prLog("<TR VALIGN=\"top\">");
	prLog("<TD>$timestr</TD>");
	prLog("<TD>vSend($ifname,@frames)<BR>");

	my $cmd = "$V6ToolDir/pktsend $V6BaseArgs -i $ifname @frames";

	my $fCnt = 0;

	my ($status, @lines)	= execCmd($cmd);

	%ret = getField(@lines);
	$ret{'status'}	= $status;

	my @pktrevers = ();

	foreach(@lines){
		if($_ =~ /^\s*(\d+\.\d+)$/) {
			$fCnt ++;
			$ret{"sentTime${fCnt}"} = $1;
		} else {
			$pktrevers[$fCnt + 1] .= "$_\n";
		}
	}

	for(my $i = 1; $i <= $fCnt; $i ++) {
		$_ = $frames[$i - 1];
		if($main::pktdesc{$_}){
			$msg = "$main::pktdesc{$_}";
		} else {
			$msg = "send $_";
		}

		prOut(HTML2TXT($msg));

		prLog("<A NAME=\"vSend${vSendPKT}\"></A>");

		my $script	= "<A HREF=\"#vSendPKT${vSendPKT}\"";
		if($USE_JAVASCRIPT) {
			$script	.= " onmouseover=\"popup(${PktCount},event);\"";
			$script .= " onmouseout=\"popdown(${PktCount});\"";
		}
		$script	.= ">$msg</A><BR>";
		prLog($script);

		if($USE_JAVASCRIPT) {
			prLog("<DIV ID=\"pop${PktCount}\" "
				. "style=\"position:absolute; "
				. "visibility:hidden;\"></DIV>");
		}

		my $senttime = getTimeString($ret{"sentTime${i}"});

		$PacketLog .="<A NAME=\"vSendPKT${vSendPKT}\"></A>\n";
		$PacketLog .="<A HREF=\"#vSend${vSendPKT}\">$msg at $senttime</A>\n";
		if($USE_JAVASCRIPT) {
			$PacketLog .= "<DIV ID=\"koiPacketInfo${PktCount}\">\n";
		}
		$PacketLog .="<PRE STYLE=\"line-height:70%\">";

		my $Xpktrevers = $pktrevers[$i];

		$Xpktrevers =~ s/&/&amp;/g;
		$Xpktrevers =~ s/"/&quot;/g;
		$Xpktrevers =~ s/</&lt;/g;
		$Xpktrevers =~ s/>/&gt;/g;

		$PacketLog .=$Xpktrevers;

		$PacketLog .="</PRE>\n";
		if($USE_JAVASCRIPT) {
			$PacketLog .= "</DIV>\n";
		}
		$PacketLog .="<HR>\n";

		$vSendPKT ++;
		$PktCount ++;
	}

	if($ret{status}){
		prErrExit("vSend() return status=$ret{status}\n");
	}

	prLog("</TD>");
	prLog("</TR>\n");
	$vLogStat = $vLogStatCloseRow;

	return(%ret);
}



sub
vRecv($$$$@)
{
	my ($ifname, $timeout, $seektime, $count, @frames) = @_;

	my $cmd  = "$V6ToolDir/pktrecv $V6BaseArgs -x";

	if($ifname) {
		$cmd .= " -i $ifname";
	}

	if($timeout >= 0) {
		$cmd .= " -e $timeout";
	}

	if($seektime) {
		$cmd .= " -s $seektime";
	}

	if($count) {
		$cmd .= " -c $count";
	}

	$cmd .= " @frames";

	my $timestr = getTimeStamp();

	if($vLogStat == $vLogStatOpenRow){
		prLog("</TD>");
		prLog("</TR>\n");
	}

	prLog("<TR VALIGN=\"top\">");
	prLog("<TD>$timestr</TD>");
	prLog("<TD>vRecv($ifname,@frames)". 
		" timeout:$timeout cntLimit:$count seektime:$seektime<BR>");

	my $fCnt = 0;

	my ($status, @lines) = execCmd($cmd);

	my %ret = getField(@lines);
	$ret{'status'} = $status;

	my @pktrevers	= ();

	foreach(@lines){
		if($_ =~ /^\s*(\d+\.\d+)\s+(\S*)$/ ) {
			$fCnt ++;
			$ret{"recvTime${fCnt}"} = $1;
			$ret{'recvFrame'}   = $2;
		} elsif($_ =~ /^hex:([0-9a-zA-Z]+)$/ ) {
			$ret{'recvHexDump'}	= $1;
		} else {
			$pktrevers[$fCnt + 1] .= "$_\n";
		}
	}

	if($ret{'recvFrame'} eq '-') {
		undef($ret{'recvFrame'});
	}

	$ret{'recvCount'} = $fCnt;

	for(my $i = 1; $i <= $fCnt; $i ++){
		my $recvtime = getTimeString($ret{"recvTime${i}"});

		if(($i != $fCnt) || ($ret{'status'})) {
			prLog("<A NAME=\"vRecv${vRecvPKT}\"></A>");

			my $msg	= '';
			if(@frames){
				$msg	= "recv unexpect packet at $recvtime";
			} else {
				$msg	= "recv a packet at $recvtime";
			}

			my $script = "<A HREF=\"#vRecvPKT${vRecvPKT}\"";
			if($USE_JAVASCRIPT) {
				$script .= " onmouseover=\"popup(${PktCount},event);\"";
				$script .= " onmouseout=\"popdown(${PktCount});\"";
			}
			$script .= ">$msg</A><BR>";
			prLog($script);

			if($USE_JAVASCRIPT) {
				prLog("<DIV ID=\"pop${PktCount}\" "
					. "style=\"position:absolute; "
					. "visibility:hidden;\"></DIV>");
			}
		}

		$PacketLog .= "<A NAME=\"vRecvPKT${vRecvPKT}\"></A>\n";
		$PacketLog .= "<A HREF=\"#vRecv${vRecvPKT}\">Recv at $recvtime</A>\n";
		if($USE_JAVASCRIPT) {
			$PacketLog .= "<DIV ID=\"koiPacketInfo${PktCount}\">\n";
		}
		$PacketLog .= "<PRE STYLE=\"line-height:70%\">";

		my $Xpktrevers = $pktrevers[$i];

		$Xpktrevers =~ s/&/&amp;/g;
		$Xpktrevers =~ s/"/&quot;/g;
		$Xpktrevers =~ s/</&lt;/g;
		$Xpktrevers =~ s/>/&gt;/g;

		$PacketLog .= $Xpktrevers;

		$PacketLog .= "</PRE>\n";
		if($USE_JAVASCRIPT) {
			$PacketLog .= "</DIV>\n";
		}
		$PacketLog .= "<HR>\n";

		$vRecvPKT ++;
		$PktCount ++;
	}

	if($ret{'status'} >= 3) {
		prErrExit("vRecv() return status=$ret{status}\n");
	}

	if($ret{'status'}){
		prLog("vRecv() return status=$ret{status}");
	} else {
		$_ = $ret{'recvFrame'};

		$vRecvPKT --;
		$PktCount --;

		my $msg	= '';
		if($main::pktdesc{$_}){
			$msg = "$main::pktdesc{$_}";
		} else {
			$msg = "recv $_";
		}

		prOut(HTML2TXT($msg));
		prLog("<A NAME=\"vRecv${vRecvPKT}\"></A>");

		my $script	= "<A HREF=\"#vRecvPKT${vRecvPKT}\"";
		if($USE_JAVASCRIPT) {
			$script .= " onmouseover=\"popup(${PktCount},event);\"";
			$script .= " onmouseout=\"popdown(${PktCount});\"";
		}
		$script	.= ">$msg</A><BR>";
		prLog($script);

		if($USE_JAVASCRIPT) {
			prLog("<DIV ID=\"pop${PktCount}\" "
				. "style=\"position:absolute; "
				. "visibility:hidden;\"></DIV>");
		}

		$vRecvPKT ++;
		$PktCount ++;
	}

	prLog("</TD>");
	prLog("</TR>\n");
	$vLogStat = $vLogStatCloseRow;

	return(%ret);
}



sub
vCapture($)
{
	my ($ifname) = @_;
	execPktctl('Start Capturing Packets', $ifname, 'capture');
	return(0);
}



sub
vStop($)
{
	my ($ifname) = @_;
	execPktctl('Stop Capturing Packets', $ifname, 'stop');
	return(0);
}



sub
vClear($)
{
	my ($ifname) = @_;
	execPktctl('Clear Captured Packets', $ifname, 'clear');
	return(0);
}



sub
getField(@)
{
	my (@lines) = @_;

	my %rc = ();
	my @Struct = ();
	my $Xmember = '';

	foreach(@lines) {
		if($_ =~ /^\s*((\|\s)*)(\S*)\s*\(\S*\)/) {
			$Xmember = '';

			my $block = $3;
			if($block eq 'Frame_Ether') {
				%rc = ();
				@Struct = ();
			}

			my $curDepth = length($1)/2;
			while($#Struct >= $curDepth) {
				pop(@Struct);
			}

			push(@Struct, $block);

			my $xstruct = join('.', @Struct);

			unless(defined($rc{"$xstruct#"})) {
				$rc{"$xstruct#"} = 0;
			}

			my $num = ++ $rc{"$xstruct#"};

			if($num > 1) {
				pop(@Struct);
				$block .= "$num";
				push(@Struct, $block);
			}

			pop(@Struct);

			if($#Struct >= 0) {
				my $name = join('.', @Struct);
				if(defined($rc{"$name"})) {
					$rc{"$name"} .= " ";
				}

				$rc{"$name"} .= "$block";
			}

			push(@Struct, $block);
		} elsif($_ =~ /^\s*((\|\s)+)(\S+)\s+=\s+(.*)$/) {
			my $name = $3;

			my $curDepth = length($1)/2;
			while($#Struct >= $curDepth) {
				pop(@Struct);
			}

			my $member = join('.', @Struct);
			$member .= ".$name";

			unless(defined($rc{"$member#"})) {
				$rc{"$member#"} = 0;
			}

			$rc{"$member#"}++;

			if($rc{"$member#"} > 1) {
				$name .= "_$rc{\"$member#\"}"
			}

			$member  = join('.', @Struct);
			$member .= ".$name";

			$xstruct = join('.', @Struct);
			if(defined($rc{"$xstruct"})) {
				$rc{"$xstruct"} .= ' ';
			}

			$rc{"$xstruct"} .= "$name";

			my $Xdata = $4;

			if($Xdata =~ /^(.*)\s+calc\(.*\)$/) {
				$Xdata = $1;
			}

			if($Xdata =~ /^[0-9a-fA-F]{8}\s([0-9a-fA-F]{8}\s{1,2})*[0-9a-fA-F]{1,8}$/) {
				$Xdata =~ s/\s//g;
			}

			$rc{"$member"} = $Xdata;

			$Xmember = $member;
		} elsif($_ =~ /^\s*((\|\s)+)\s{2}(.*)$/) {
			my $Xdata = $3;

			if($Xdata =~ /^[0-9a-fA-F]{8}\s([0-9a-fA-F]{8}\s{1,2})*[0-9a-fA-F]{1,8}$/) {
				$Xdata =~ s/\s//g;
			} else {
				$Xdata .= "\n";
			}

			if(($Xmember ne '') && (defined($rc{$Xmember}))) {
				$rc{$Xmember} .= $Xdata;
			}
		} elsif($_ =~ /^\s{2}(.*)$/) {
			my $Xdata = $1;

			if($Xdata =~ /^[0-9a-fA-F]{8}\s([0-9a-fA-F]{8}\s{1,2})*[0-9a-fA-F]{1,8}$/) {
				$Xdata =~ s/\s//g;
			} else {
				$Xdata .= "\n";
			}

			if(($Xmember ne '') && (defined($rc{$Xmember}))) {
				$rc{$Xmember} .= $Xdata;
			}
		} else {
		}
	}

	return(%rc);
}



sub
v6eval_baseArgs()
{
	$V6BaseArgs = "-t $V6TnDefPath -n $V6NutDefPath -p $PktImd -l$LogLevel";

	if(defined($ENV{'V6EVALOPT'})) {
		$V6BaseArgs .= " $ENV{'V6EVALOPT'}";
	}

	return;
}



sub
execCmd($;$)
{
	my ($cmd, $std_redirect) = @_;

	my $type	= 0;
	my $line	= 0;
	my $pid	= 0;
	my $localExecutingPid	= 0;

	my @ret = ();

	pipe PIN, COUT;

	$ChildPid	= 0;
	unless(defined($ExecutingPid = $localExecutingPid = fork)) {
		$localExecutingPid = 0;
		prErrExit("Fork failed for <$cmd>");
	}

	unless($localExecutingPid) {	# Child Process
		open(STDOUT, ">&COUT");
		open(STDERR, ">&COUT");
		close(PIN);
		close(STDIN);

		exec "$cmd;";
	}

	$pid = $localExecutingPid;
	close(COUT);
	prDebug("execCmd()... $cmd");

	while(<PIN>) {
		chomp;
		my $allmsg = $_;
		my ($type, $line) = /^(\w\w\w):(.*)$/;
		if($type eq 'log') {
			push(@ret, $line);
			prDebug("execCmd()ret... log:$line");
		} elsif($type eq 'err') {
			prErr("$line");
		} elsif($type eq 'std') {
			$std_redirect? prOut($line): push(@ret, $line);
			prDebug("execCmd()ret... std:$line");
		} elsif($type eq 'hex') {
			push(@ret, $allmsg);
		}else {
			prLog("  dbg: $allmsg", 100);
		}
	}

	close(PIN);

	while($ChildPid == 0) {};

	my $status = getChildStatus();

	if($ChildPid != $pid) {
		prErrExit("Unknown child died $pid $ChildPid (status=$status)!!");
	}

	if($status & 0xff) {
		prErrExit("Catch signal <$cmd>");
	}

	unshift(@ret, ($status>>8));

	return(@ret);
}



sub
execPktctl($$@;$)
{
	my ($funcname, $ifname, @arg) = @_;

	my $cmd	= "$V6ToolDir/pktctl -t $V6TnDefPath";

	if($ifname) {
		$cmd	.= " -i $ifname"
	}

	$cmd	.= " @arg";

	my $timestr	= getTimeStamp();
	if($vLogStat == $vLogStatOpenRow) {
		prLog("</TD>");
		prLog("</TR>\n");
	}

	prLog("<TR VALIGN=\"TOP\">");
	prLog("<TD>$timestr</TD>");
	prLog("<TD>$funcname ($ifname)<BR>");
	prOut("$funcname ($ifname)");

	my @ret = execCmd($cmd, ($funcname eq 'vDump'));

	if($ret[0]) {
		prErrExit("$funcname($ifname) return status=$ret[0]\n");
	}

	prLog("</TD>");
	prLog("</TR>\n");

	$vLogStat = $vLogStatCloseRow;

	return(@ret);
}



sub
getChildStatus()
{
	return($ChildStatus);
}



sub
getTimeString($)
{
	my ($epoch) = @_;

	my ($sec,$min,$hour) = localtime($epoch);
	my $timestr = sprintf('%02d:%02d:%02d', $hour, $min, $sec);
	return($timestr);
}



sub
v6eval_initialize()
{
	my $soname	= '';
	foreach $soname (@V6TnSos) {
		prDebug("TN : unlink $V6SocketPath/$soname");
		unlink("$V6SocketPath/$soname");
	}

	my $cmdBase = "$V6ToolDir/pktbuf -t $V6TnDefPath -i ";

	my $ifname	= '';
	my $log	= '';
	foreach $ifname (@V6TnIfs) {
		if( grep {$ifname eq $_} @V6NutIfs ){
			my $cmd	= "$cmdBase $ifname";
			$log	= "/tmp/pktbuf_$ifname.log";

			push(@PktbufPids, forkCmd($cmd, $log));
		}
	}

	if(@PktbufPids == 0) {
		prErrExit(
			"No interface to use commonly\n".
			"TN : @V6TnIfs\n".
			"NUT: @V6NutIfs");
	}

	vCPP($V6CppOption);

	v6eval_baseArgs();

	return;
}



sub
v6eval_terminate()
{
	my $pid	= 0;
	foreach $pid (@PktbufPids) {
		prDebug("Exiting... sending SIGTERM to $pid");

		unless(kill('TERM', $pid)) {
			prOut("Error in killing process pid=$pid");
		}
	}

	if($KeepImd) {
		prOut("Keep packet ImdFile <$PktImd>");
	} else {
		unlink("$PktImd");
	}

	my $soname	= '';
	foreach $soname (@V6TnSos) {
		prDebug("TN : unlink $V6SocketPath/$soname");
		unlink("$V6SocketPath/$soname");
	}

	return;
}
# ---------------------------- for v6eval ---------------------------> #



#----------------------------------------------------------------------#
# BEGIN()                                                              #
#----------------------------------------------------------------------#
BEGIN
{
	%storedSIG = %SIG;

	foreach my $key (keys(%SIG)) {
		$SIG{$key} = 'DEFAULT';
	}

	$| = 1;
	$VERSION		= 1.00;
#	$DEFAULT_SOCKET_PATH	= "/tmp/koid.socket.$$";
	$DEFAULT_SOCKET_PATH	= "/tmp/koid.socket";
	$DEFAULT_SOCKIO_PATH	= '/usr/local/koi/bin/koid';
	$SOCKETIO_PID		= 0;
	$SOCKFD			= 0;
	$SOCKIO_SEQ		= 0;
	@strerror		= ();

	$SendPktCount = 1;	# the number of sent packet
	$RecvPktCount = 1;	# the number of received packet
	$PktCount = 1;	# the number of received packet
	$PacketLog = '';

	$USE_JAVASCRIPT = 1; # 0; # 
	$CLEANUP	= 0;

	%sockio_cmd		= (
		'CMD-CONNECT-REQ'	=> 0x0101,
		'CMD-CONNECT-ANS'	=> 0x8101,
		'CMD-SEND-REQ'		=> 0x0102,
		'CMD-SEND-ANS'		=> 0x8102,
		'CMD-READ-REQ'		=> 0x0103,
		'CMD-READ-ANS'		=> 0x8103,
		'CMD-CLOSE-REQ'		=> 0x0104,
		'CMD-CLOSE-ANS'		=> 0x8104,
		'CMD-LISTEN-REQ'	=> 0x0105,
		'CMD-LISTEN-ANS'	=> 0x8105,
		'CMD-CONNINFO-REQ'	=> 0x0106,
		'CMD-CONNINFO-ANS'	=> 0x8106,
		'CMD-DATAINFO-REQ'	=> 0x0107,
		'CMD-DATAINFO-ANS'	=> 0x8107,
		'CMD-CLEARBUFFER-REQ'	=> 0x0108,
		'CMD-CLEARBUFFER-ANS'	=> 0x8108,
		'CMD-TLSSETUP-REQ'	=> 0x0109,
		'CMD-TLSSETUP-ANS'	=> 0x8109,
		'CMD-TLSCLEAR-REQ'	=> 0x010A,
		'CMD-TLSCLEAR-ANS'	=> 0x810A,
		'CMD-PARSERATTACH-REQ'	=> 0x010B,
		'CMD-PARSERATTACH-ANS'	=> 0x810B,
	);

	%sockio_cmdlen = (
		'CMD-CONNECT-ANS'	=> 20,
		'CMD-SEND-ANS'		=> 20,
		'CMD-READ-ANS'		=>
			sub
			{
				my ($msg) = @_;

				if(length($msg) < 64) {
					return(64);
				}

				my $datalen = unpack("\@60 N \@*", $msg);

				return(64 + $datalen);
			},
		'CMD-CLOSE-ANS'		=> 8,
		'CMD-LISTEN-ANS'	=> 8,
#		'CMD-CONNINFO-ANS'	=> 52, # koid
		'CMD-CONNINFO-ANS'	=> 64, # support TLS
		'CMD-DATAINFO-ANS'	=>
			sub {
				my ($msg) = @_;
				if(length($msg) < 20) {
					return(20);
				}

				my $datalen = unpack("\@16 N \@*", $msg);

				return(20 + $datalen);
			},
		'CMD-CLEARBUFFER-ANS'	=> 6,
		'CMD-TLSSETUP-ANS'	=> 6,
		'CMD-TLSCLEAR-ANS'	=> 6,
		'CMD-PARSERATTACH-ANS'	=> 6,
	);

	%sockio_proto		= (
		'TCP'	=> 1,
		'UDP'	=> 2,
		'ICMP'	=> 3,
		'TLS'	=> 4,
	);

	# XXX: Why ICMP isn't here???
	%sockio_frame		= (
		'NULL'	=> {'id'=>2},
		'DNS'	=> {'id'=>3},
		'UDPDNS'	=> {'id'=>6},
		'IKEv2'	=> {'id'=>5},
		'SIP'	=> {'id'=>1},
		'KINK'  => {'id'=>7},
	);

	%sockio_af		= (
		'INET'	=> 4,
		'INET6'	=> 6
	);

	%sockio_error		= (
		0x8101		=>'Timeout',
		0x8102		=>'Invalid parameters',
		0x8103		=>'Invalid socketID',
		0x8104		=>'System call error',
		0x8105		=>'Other error',
		0x8106		=>'TLS no initialize',
		'TIMEOUT'	=> 0x8101,
		'INVAID-PARAM'	=> 0x8102,
		'INVALID-SOCKID'=> 0x8103,
		'SYSCALL'	=> 0x8104,
		'OTHER'		=> 0x8105,
		'TLS-NOINIT'	=> 0x8106,
	);

	our %icmpv4_type	= (
		'0'	=> 'Echo Reply',
		'3'	=> 'Destination Unreachable',
		'8'	=> 'Echo Request',
	);

	our %icmpv6_type	= (
		'1'	=> 'Destination Unreachable',
		'2'	=> 'Packet Too Big',
		'3'	=> 'Time Exceeded',
		'4'	=> 'Parameter Problem',

		'128'	=> 'Echo Request',
		'129'	=> 'Echo Reply',

		'200'	=> 'Private Experimentation',
		'201'	=> 'Private Experimentation',
	);

# 	if(!defined($SIG{'CHLD'})) {
# # 		$SIG{'CHLD'}	= \&sigchld;
# 		$SIG{'CHLD'}	= 'IGNORE';
# 	}

	our %TnDef;
	our %NutDef;
	# <----------------------- for v6eval ------------------------ #
	%V6TnDef	= ();
	%V6NutDef	= ();
	@V6TnIfs	= ();
	@V6NutIfs	= ();
	@PktbufPids	= ();
	$vSendPKT	= 0;
	$vRecvPKT	= 0;
	# ------------------------ for v6eval -----------------------> #
	$vLogStatCloseRow	= 0;	# const 
	$vLogStatOpenRow	= 1;	# const
	$vLogStat = $vLogStatCloseRow;
	kModule_Initialize();
}



#----------------------------------------------------------------------#
# END()                                                                #
#----------------------------------------------------------------------#
END
{
	my $status = $?;

	$CLEANUP	= 1;
	kModule_Terminate();

	undef %sockio_af;
	undef %sockio_frame;
	undef %sockio_proto;
	undef %sockio_cmdlen;
	undef %sockio_cmd;
	undef %icmpv6_type;
	undef @strerror;
	undef $SOCKIO_SEQ;
	undef $SOCKFD;
	undef $SOCKETIO_PID;
	undef $DEFAULT_SOCKIO_PATH;
	undef $DEFAULT_SOCKET_PATH;
	undef $VERSION;

	foreach my $key (keys(%SIG)) {
		$SIG{$key} = 'DEFAULT';
	}

	%SIG = %storedSIG;

	$? = $status;
}

1;
