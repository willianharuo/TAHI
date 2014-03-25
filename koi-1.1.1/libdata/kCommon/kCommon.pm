#!/usr/bin/perl
#
# Copyright (C) 1999, 2000, 2001, 2002, 2003, 2004, 2005, 2006, 2007
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
# $TAHI: koi/libdata/kCommon/kCommon.pm,v 1.113 2006/06/26 01:12:35 akisada Exp $
#



package kCommon;

# use strict;
use Exporter;
use File::Basename;
use IO::Socket;

use POSIX ":sys_wait_h";
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

	kInsert

	kRemote
	kRemoteAsync
	kRemoteAsyncWait

	kDump_Common_Error
	kLogHTML
	kPrint_SIP

	handleChildProcess
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

sub getPacketInfo($$);
sub dumpPacket($$);
sub parseCount($);
sub calcTab($$$$);
sub getVersion();
sub prLogSendPacket($$);
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

	my $_frameid_ = $sockio_frame{$frameid};


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

	my $_frameid_ = $sockio_frame{$frameid};

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
			prLogSendPacket($result->{'SocketID'}, $data[26]);
		}

		prLog("</TD>\n</TR>\n");
	}
	elsif($cmd eq 'CMD-SEND-REQ') {
		prLog("done<BR>");
		prOut("done<br>");
		prLog("&nbsp;&nbsp;sent to "
		      . "SocketID:$result->{'SocketID'}<br>");

		my @data = unpack('n4 N a*', $send_msg);
		prLogSendPacket($result->{'SocketID'}, $data[5]);

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

		my $count = parseCount($PktCount);
		prLog("<A NAME=\"koiPacket${PktCount}\"></A>");
		if ($USE_JAVASCRIPT) {
			prLog("<A HREF=\"#koiPacketDump${PktCount}\" "
			      . "onmouseover=\"popup(${PktCount},event);\""
			      . "onmouseout=\"popdown(${PktCount});\""
			      . ">receive $count packet</A>");
			prLog("<div id=\"pop${PktCount}\" "
			      . "style=\"position:absolute; "
			      . "visibility:hidden;\"></div>");
		}
		else {
			prLog("<A HREF=\"#koiPacketDump${PktCount}\""
			      . ">receive $count packet</A>");
		}
		prLog("<BR>");

		## collect reverse packet log
		$PacketLog .= "<A NAME=\"koiPacketDump${PktCount}\"></A>";
		$PacketLog .= "<A HREF=\"#koiPacket${PktCount}\">";
		$PacketLog .= "$count packet at $timestr</A>\n";
		if ($USE_JAVASCRIPT) {
			$PacketLog .= "<div id=\"koiPacketInfo${PktCount}\">\n";
		}
		$PacketLog .="<pre>";
		# $PacketLog .="<pre style=\"line-height:80%\">";

		## IP Header
		my ($log, $protocol) = getPacketInfo($result->{'SocketID'},
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

	$vLogStat = $vLogStatCloseRow;

	return($result);
}

sub prLogSendPacket($$) {
	my ($socketid, $data) = @_;

	my $count = parseCount($PktCount);
	prLog("<A NAME=\"koiPacket${PktCount}\"></A>");
	if ($USE_JAVASCRIPT) {
		prLog("<A HREF=\"#koiPacketDump${PktCount}\" "
		      . "onmouseover=\"popup(${PktCount},event);\""
		      . "onmouseout=\"popdown(${PktCount});\""
		      . ">send $count packet</A>");
		prLog("<div id=\"pop${PktCount}\" "
		      . "style=\"position:absolute; "
		      . "visibility:hidden;\"></div>");
	} else {
		prLog("<A HREF=\"#koiPacketDump${PktCount}\""
		      . ">send $count packet</A>");
	}
	prLog("<BR>");

	## collect reverse packet log
	my $timestr = getTimeStamp();
	$PacketLog .= "<A NAME=\"koiPacketDump${PktCount}\"></A>";
	$PacketLog .= "<A HREF=\"#koiPacket${PktCount}\">";
	$PacketLog .= "$count packet at $timestr</A>\n";
	if ($USE_JAVASCRIPT) {
		$PacketLog .= "<div id=\"koiPacketInfo${PktCount}\">\n";
	}
	$PacketLog .= "<pre>";
	# $PacketLog .="<pre style=\"line-height:80%\">";

	## IP Header
	my ($log, $conninfo) = getPacketInfo($socketid, 'send');
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

sub getPacketInfo($$) {
	my ($socketid, $direction) = @_;

	my $function = 'getPacketInfo';

	my $srcaddr, $dstaddr, $srcport, $dstport;
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
		$result .= "| ICMP Header\n";
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
	if ($conninfo->{'FrameID'} == $sockio_frame{'DNS'}
	    || $conninfo->{'FrameID'} == $sockio_frame{'UDPDNS'}) {
		$str = dumpPacketDNS($data);
	}
	elsif ($conninfo->{'FrameID'} == $sockio_frame{'NULL'}) {
		$str = dumpPacketNULL($data);
	}
	elsif ($conninfo->{'FrameID'} == $sockio_frame{'IKEv2'}) {
		$str = dumpPacketNULL($data);
	}
	elsif ($conninfo->{'FrameID'} == $sockio_frame{'SIP'}) {
		$str = dumpPacketSIP($data);
	}
	else {
		kReg_Common_Error(__FILE__, __LINE__, $function,
				  "unknown FrameID ($conninfo->{'FrameID'})");
	}

	return $str;
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
	$str .= $data;
	$str .= "\n";

	return($str);
}



sub dumpPacketSIP($) {
	my ($data) = @_;
	my $dump = 1;
	my $result = kPrint_SIP($data, $dump);
	return $result;
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

sub parseCount($) {
	my ($count) = @_;

	if ($count % 100 == 11) {
		$count = '11th';
	} elsif ($count % 100 == 12) {
		$count = '12th';
	} elsif ($count % 10 == 1) {
		$count = "${count}st";
	} elsif ($count % 10 == 2) {
		$count = "${count}nd";
	} elsif ($count % 10 == 3) {
		$count = "${count}rd";
	} else {
		$count = "${count}th";
	}

	return $count;
}

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

	my $ret = sysread($sock, $data, 0xffff);
	unless(defined($ret)) {
		kReg_Common_Error(__FILE__, __LINE__, $function,
			"read: $!");

		return(undef);
	}

	return($data);
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

	my $size    = 52;
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
	 $result{'Interface'}
	) = unpack('n2', $data);

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

	unless(defined($path)) {
		$path = $DEFAULT_SOCKET_PATH;
	}

	unless(defined($protocol)) {
		$protocol = SOCK_STREAM;
	}

	my $prog     = $DEFAULT_SOCKIO_PATH;
	my ($seqname, $seqdir, $seqsuffix) = fileparse($0, '.seq');
	my $progname = basename($prog);

	kInit_Common_Error();
	if(-e $path) {
		kReg_Common_Error(__FILE__, __LINE__, $function,
			"make sure to terminate $progname and remove $path");

		my $strderror = kDump_Common_Error();

		if(defined($strderror)) {
			die "$strderror";
			# NOTREACHED
		}

		die '';
		# NOTREACHED
	}

	# parse argments
	$CommandLine = "$0 @ARGV";
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

	# for remote function
	$ChildPid = undef;
	$ChildStatus = undef;
	$REMOTE_ASYNC_STATE = undef;

	# fork tcpdump
	forkTcpdump();

	$SIG{CHLD} = \&handleChildProcess;

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

	($dummy, $ToolVersion) = ('$Name: REL_1_1_1 $' =~ /\$(Name): (.*) \$/ );
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
	if ($CommandLine =~ /^(\S+)\s+/) {
		$SeqFile = $1;
	}
	else {
		$SeqFile = undef;
	}
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

	kInit_Common_Error();

	$SIG{CHLD} = 'IGNORE';
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
		if ( /^(\S+)\s+(.*)/ ) {
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
			$TnDef{'error'} .= "$tn line $i : unknown directive $_\n";
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

		elsif (/^(Link[0-9]+)\s+(\S+)/) {
			$NutDef{$name."_device"} = $value;
		}
		else {
			$NutDef{'error'} .= "$nut line $i : unknown directive $_\n";
		}

		$i++;
	}

	close FILE;

	return %NutDef;
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
			my $cmd = "$dumpCmd -i $if -w $LogFile.$ifname.dump ";
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
		prDebug("Exiting... sending SIGTERM to $_");
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
	}

	if ( grep {$ChildPid==$_} @TcpdumpPids) {
		my $pid;
		for (1..scalar(@TcpdumpPids)) {
			$pid=shift(@TcpdumpPids);
			if ($pid==$ChildPid) {
				prErr("tcpdump died pid=$ChildPid status=$status");
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

	if ($vLogStat = $vLogStatOpenRow) {
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
	$DEFAULT_SOCKET_PATH	= "/tmp/koid.socket.$$";
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
		'CMD-CLEARBUFFER-ANS'	=> 0x8108
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
		'CMD-CONNINFO-ANS'	=> 52,
		'CMD-DATAINFO-ANS'	=>
			sub {
				my ($msg) = @_;
				if(length($msg) < 20) {
					return(20);
				}

				my $datalen = unpack("\@16 N \@*", $msg);

				return(20 + $datalen);
			},
		'CMD-CLEARBUFFER-ANS'	=> 6
	);

	%sockio_proto		= (
		'TCP'	=> 1,
		'UDP'	=> 2,
		'ICMP'	=> 3,
	);

	# XXX: Why ICMP isn't here???
	%sockio_frame		= (
		'NULL'	=> 2,
		'DNS'	=> 3,
		'UDPDNS'	=> 6,
		'IKEv2'	=> 5,
		'SIP'	=> 1
	);

	%sockio_af		= (
		'INET'	=> 4,
		'INET6'	=> 6
	);

	if(!defined($SIG{'CHLD'})) {
# 		$SIG{'CHLD'}	= \&sigchld;
		$SIG{'CHLD'}	= 'IGNORE';
	}

	our %TnDef;
	our %NutDef;
	kModule_Initialize();
}



#----------------------------------------------------------------------#
# END()                                                                #
#----------------------------------------------------------------------#
END
{
	my $status = $?;

	kModule_Terminate();

	undef %sockio_af;
	undef %sockio_frame;
	undef %sockio_proto;
	undef %sockio_cmdlen;
	undef %sockio_cmd;
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
