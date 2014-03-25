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
# $TAHI: ct-dns/dns/DNS.pm,v 1.2 2007/07/18 02:26:17 akisada Exp $
#
########################################################################
package DNS;

use strict;
use kCommon;
use kDNS;
use DNSConfig;
use vars qw(
  $TRUE
  $FALSE
  $OK
  $FAIL
  $SKIP
  $NOTYET
  $INTERR
  $FRAME_ID
  $TN_SV_PORT
  $TN_CL_PORT
  $TN_SIP_PORT
  $NUT_CL_PORT
  $NUT_SV_PORT
  $NUT_IPV4_CL_PORT
  $NUT_IPV4_SV_PORT
  $NUT_IPV6_CL_PORT
  $NUT_IPV6_SV_PORT
  $NUT_USE_IP_VERSION
  $NUT_ADDR_0
  $NUT_IPV4_ADDR_0
  $NUT_IPV6_ADDR_0
  $NUT_ADDR_1
  $NUT_IPV4_ADDR_1
  $NUT_IPV6_ADDR_1
  $NUT_EDNS0_SIZE
  $NUT_EDNS0_UDP_SIZE
  $TN_NET0_NODE0_ADDR
  $TN_NET0_NODE1_ADDR
  $TN_NET0_NODE2_ADDR
  $TN_NET0_NODE3_ADDR
  $TN_NET0_NODE4_ADDR
  $TN_NET0_NODE5_ADDR
  $TN_NET1_NODE1_ADDR
  $TN_NET1_NODE2_ADDR
  $TN_NET1_NODE3_ADDR
  $TN_NET1_NODE4_ADDR
  $TN_NET1_NODE5_ADDR
  $TN_NET1_NODE6_ADDR
  $TN_NET1_NODE7_ADDR
  $TN_NET1_NODE8_ADDR
  $ADDR_FAMILY
  $ADDR_LENGTH
  $ADDR_TYPE
  $JUDGE_OPT_RR
  $JUDGE_NS_AAAA
  $RETRANSMIT_COUNT_CLIENT
  $RETRANSMIT_COUNT_SERVER
  $APP_TYPE
  $DEC_MESSAGE_TYPE
);

#------------------------------#
# Initialize Export Constants  #
#------------------------------#
$FALSE = 0;
$TRUE  = 1;

$OK    = 0;
$NOTYET = 2;
$SKIP = 10;
$FAIL  = 32;
$INTERR = 64;

#$FRAME_ID    = 'NULL'; # 'DNS'; #_
$FRAME_ID = 'DNS';    # 'DNS'; #_

$TN_SV_PORT = 53;
$TN_CL_PORT = 2000;
$TN_SIP_PORT = 5060;

#------------------------------#
# Debug                        #
#------------------------------#
my $DNS_ERR_MSG      = $TRUE;
my $DEBUG_KOI_INFO = $FALSE;

my $DEBUG_PRINT = $TRUE;
my $DEBUG_PRINTF = $TRUE;

#------------------------------#
# Global                       #
#------------------------------#
$JUDGE_OPT_RR = $FALSE;
$JUDGE_NS_AAAA = $TRUE;
#------------------------------#
# Local                        #
#------------------------------#
#my $NgCount = 0;
#------------------------------#
# Hash                         #
#------------------------------#
# child_SocketID->parent_SocketID
my %socketIDHash = ();

# parent_SocketID->ADDR_PROTO
my %proto_hash = ();

#------------------------------#
# Packet                       #
#------------------------------#
my $exp_root_query_0;
my $exp_root_query_1;
my $exp_root_query_2;
################################
# exp_root_query_0             #
################################
$exp_root_query_0->{'header'} = {
        'id'      => undef,
        'qr'      => 0,
        'opcode'  => 0,
        'aa'      => undef,
        'tc'      => 0,
        'rd'      => 0,
        'ra'      => 0,
        'z'       => undef,
        'ad'      => undef,
        'cd'      => undef,
        'rcode'   => 0,
        'qdcount' => 1,
        'ancount' => 0,
        'nscount' => 0,
        'arcount' => undef,
};

$exp_root_query_0->{'question'}->[0] = {
        'qname'  => '',
        'qtype'  => '2',
        'qclass' => 0x0001,
};

################################
# exp_root_query_1             #
################################
$exp_root_query_1->{'header'} = {
        'id'      => undef,
        'qr'      => 0,
        'opcode'  => 0,
        'aa'      => undef,
        'tc'      => 0,
        'rd'      => 0,
        'ra'      => 0,
        'z'       => undef,
        'ad'      => undef,
        'cd'      => undef,
        'rcode'   => 0,
        'qdcount' => 1,
        'ancount' => 0,
        'nscount' => 0,
        'arcount' => undef,
};

$exp_root_query_1->{'question'}->[0] = {
        'qname'  => 'A.ROOT.NET.',
        'qtype'  => 0x001c,
        'qclass' => 0x0001,
};

################################
# exp_root_query_2             #
################################
$exp_root_query_2->{'header'} = {
        'id'      => undef,
        'qr'      => 0,
        'opcode'  => 0,
        'aa'      => undef,
        'tc'      => 0,
        'rd'      => 0,
        'ra'      => 0,
        'z'       => undef,
        'ad'      => undef,
        'cd'      => undef,
        'rcode'   => 0,
        'qdcount' => 1,
        'ancount' => 0,
        'nscount' => 0,
        'arcount' => undef,
};

$exp_root_query_2->{'question'}->[0] = {
        'qname'  => 'NS[1-9].example.*',
        'qtype'  => 0x001c,
        'qclass' => 0x0001,
};

################################
# opt_RR                       #
################################
my $opt_RR = {
        'name'     => '',
        'type'     => 0x0029,    #OPT
        'class'    => undef,
        'rdlength' => 0,
        'rdata'    => undef,
};

################################
# auth_ROOT                    #
################################
my $auth_ROOT = {
        'name'     => '',
        'type'     => 0x0002,
        'class'    => 0x0001,
        'rdlength' => 12,
        'rdata'    => 'A.ROOT.NET.',
};

#------------------------------#
# Functions                    #
#------------------------------#
sub InitDNSConf($);
sub CheckDNSConfig();
# internal use
sub evalExpr($);
sub evalOr($$);
sub evalAnd($$);
sub separateLR($);
# internal use

sub GenDNSMsg($);
sub GenDNSHeader($);
sub GenDNSQuestionSection($);
sub GenDNSAnswerSection($);
sub GenDNSAuthoritySection($);
sub GenDNSAdditionalSection($);

sub DecDNSMsg($);
sub DecDNSHeader($$);
sub DecDNSQuestionSection($$$);
sub DecDNSAnswerSection($$$);
sub DecDNSAuthoritySection($$$);
sub DecDNSAdditionalSection($$$);

sub JudgeDNSHeader($$);
sub JudgeDNSQuestionSection($$);
sub JudgeDNSAnswerSection($$);
sub JudgeDNSAuthoritySection($$);
sub JudgeDNSAdditionalSection($$);
sub JudgeDNSRR($$$);
sub CompareDNSQuestion($$$);
sub CompareDNSRR($$$);

sub DNSStartConnect($$);
sub DNSSend($$$);
sub DNSRecv($$$$);
sub DNSSendRecv($$$$$);
sub DNSCheckConnect($$);

sub Gen_DNS_Name(@);
sub Gen_DNS_RDATA_A(@);
sub Gen_DNS_RDATA_MX($$);
sub Gen_DNS_RDATA_SOA($$$$$$$);
sub Gen_DNS_RDATA_PTR($);
sub Gen_DNS_RDATA_HINFO($$);
sub Gen_DNS_RDATA_WKS($$$);
sub Gen_DNS_RDATA_TXT(@);
sub Gen_DNS_RDATA_AAAA($);
sub Gen_DNS_RDATA_OPT(@);

sub Packet_Clear($$$$);
sub Packet_Close($$);
sub Print_Message($$);
sub JudgeDNSMsg($$);

sub DNSRemote($$);
sub RemoteAsyncWait();

sub RegisKoiSigHandler();

sub DNSExitPass();
sub DNSExitNS();

#------------------------------#
# InitDNSConf                  #
#------------------------------#
sub InitDNSConf($) {

        my $NET0_NODE0_IPV4_ADDR = '192.168.0.1';
        my $NET0_NODE2_IPV4_ADDR = '192.168.0.20';
        my $NET0_NODE3_IPV4_ADDR = '192.168.0.30';
        my $NET0_NODE4_IPV4_ADDR = '192.168.0.31';
        my $NET0_NODE5_IPV4_ADDR = '192.168.0.32';
        my $NET1_NODE1_IPV4_ADDR = '192.168.1.10';
        my $NET1_NODE2_IPV4_ADDR = '192.168.1.20';
        my $NET1_NODE3_IPV4_ADDR = '192.168.1.30';
        my $NET1_NODE4_IPV4_ADDR = '192.168.1.40';
        my $NET1_NODE5_IPV4_ADDR = '192.168.1.50';
        my $NET1_NODE6_IPV4_ADDR = '192.168.1.60';
        my $NET1_NODE7_IPV4_ADDR = '192.168.1.70';
        my $NET1_NODE8_IPV4_ADDR = '192.168.1.41';

        my $NET0_NODE0_IPV6_ADDR = '3ffe:501:ffff:100::1';
        my $NET0_NODE2_IPV6_ADDR = '3ffe:501:ffff:100::20';
        my $NET0_NODE3_IPV6_ADDR = '3ffe:501:ffff:100::30';
        my $NET0_NODE4_IPV6_ADDR = '3ffe:501:ffff:100::31';
        my $NET0_NODE5_IPV6_ADDR = '3ffe:501:ffff:100::32';
        my $NET1_NODE1_IPV6_ADDR = '3ffe:501:ffff:101::10';
        my $NET1_NODE2_IPV6_ADDR = '3ffe:501:ffff:101::20';
        my $NET1_NODE3_IPV6_ADDR = '3ffe:501:ffff:101::30';
        my $NET1_NODE4_IPV6_ADDR = '3ffe:501:ffff:101::40';
        my $NET1_NODE5_IPV6_ADDR = '3ffe:501:ffff:101::50';
        my $NET1_NODE6_IPV6_ADDR = '3ffe:501:ffff:101::60';
        my $NET1_NODE7_IPV6_ADDR = '3ffe:501:ffff:101::70';
        my $NET1_NODE8_IPV6_ADDR = '3ffe:501:ffff:101::41';

        my $ADDR_FAMILY_IPV4 = 'INET';
        my $ADDR_FAMILY_IPV6 = 'INET6';

        if ( $NUT_USE_IP_VERSION == 4 ) {
                $NUT_ADDR_0         = $NUT_IPV4_ADDR_0;
                $NUT_ADDR_1         = $NUT_IPV4_ADDR_1;
                $NUT_SV_PORT        = $NUT_IPV4_SV_PORT;
                $NUT_CL_PORT        = $NUT_IPV4_CL_PORT;
                $TN_NET0_NODE0_ADDR = $NET0_NODE0_IPV4_ADDR;
                $TN_NET0_NODE2_ADDR = $NET0_NODE2_IPV4_ADDR;
                $TN_NET0_NODE3_ADDR = $NET0_NODE3_IPV4_ADDR;
                $TN_NET0_NODE4_ADDR = $NET0_NODE4_IPV4_ADDR;
                $TN_NET0_NODE5_ADDR = $NET0_NODE5_IPV4_ADDR;
                $TN_NET1_NODE1_ADDR = $NET1_NODE1_IPV4_ADDR;
                $TN_NET1_NODE2_ADDR = $NET1_NODE2_IPV4_ADDR;
                $TN_NET1_NODE3_ADDR = $NET1_NODE3_IPV4_ADDR;
                $TN_NET1_NODE4_ADDR = $NET1_NODE4_IPV4_ADDR;
                $TN_NET1_NODE5_ADDR = $NET1_NODE5_IPV4_ADDR;
                $TN_NET1_NODE6_ADDR = $NET1_NODE6_IPV4_ADDR;
                $TN_NET1_NODE7_ADDR = $NET1_NODE7_IPV4_ADDR;
                $TN_NET1_NODE8_ADDR = $NET1_NODE8_IPV4_ADDR;
                $ADDR_FAMILY        = $ADDR_FAMILY_IPV4;
                $ADDR_LENGTH        = 4;
                $ADDR_TYPE          = 0x0001;
        } else {
                $NUT_ADDR_0         = $NUT_IPV6_ADDR_0;
                $NUT_ADDR_1         = $NUT_IPV6_ADDR_1;
                $NUT_SV_PORT        = $NUT_IPV6_SV_PORT;
                $NUT_CL_PORT        = $NUT_IPV6_CL_PORT;
                $TN_NET0_NODE0_ADDR = $NET0_NODE0_IPV6_ADDR;
                $TN_NET0_NODE2_ADDR = $NET0_NODE2_IPV6_ADDR;
                $TN_NET0_NODE3_ADDR = $NET0_NODE3_IPV6_ADDR;
                $TN_NET0_NODE4_ADDR = $NET0_NODE4_IPV6_ADDR;
                $TN_NET0_NODE5_ADDR = $NET0_NODE5_IPV6_ADDR;
                $TN_NET1_NODE1_ADDR = $NET1_NODE1_IPV6_ADDR;
                $TN_NET1_NODE2_ADDR = $NET1_NODE2_IPV6_ADDR;
                $TN_NET1_NODE3_ADDR = $NET1_NODE3_IPV6_ADDR;
                $TN_NET1_NODE4_ADDR = $NET1_NODE4_IPV6_ADDR;
                $TN_NET1_NODE5_ADDR = $NET1_NODE5_IPV6_ADDR;
                $TN_NET1_NODE6_ADDR = $NET1_NODE6_IPV6_ADDR;
                $TN_NET1_NODE7_ADDR = $NET1_NODE7_IPV6_ADDR;
                $TN_NET1_NODE8_ADDR = $NET1_NODE8_IPV6_ADDR;
                $ADDR_FAMILY        = $ADDR_FAMILY_IPV6;
                $ADDR_LENGTH        = 16;
                $ADDR_TYPE          = 0x001c;
        }

	$NUT_EDNS0_UDP_SIZE = defined($NUT_EDNS0_SIZE)? $NUT_EDNS0_SIZE: 1024;
}

#------------------------------#
# CheckDNSConfig               #
#------------------------------#
sub CheckDNSConfig() {
	my ($test_type);
	foreach my $elem (@ARGV) {
		unless ($elem =~ /\S+=\S+/) {
			next;
		}

		if ($elem =~ /^test_type=(\S+)/) {
			$test_type = $1;
			next;
		}

		if ($elem =~ /^support=(\S+)/) {
			my $value = evalExpr($1);
			unless ($value) {
				DNSExitNS();
			}
		}

		if ($elem =~ /^app_type=(\S+)/) {
			my $value = evalExpr($1);
			unless ($value) {
				DNSExitNS();
			}
		}
	}
}

sub evalExpr($) {
	my ($expr) = @_;

	# trim '...'
	if ($expr =~ /^'(.+?)'/) {
		$expr = $1;
	}

	# trim (...)
	while (index($expr, '(') == 0) {
		my $lastIndex = -1;
		for ( ; ; ) {
			my $tmp;
			if (($tmp = index($expr, ')', $lastIndex+1)) >= 0) {
				$lastIndex = $tmp;
				next;
			}

			last;
		}

		$expr = substr($expr, 1, $lastIndex-1);
	}

	unless ($expr =~ /([&|\|])/) {
		my $value = eval('$DNSConfig::' . $expr);
		if ($expr =~ /REQ_/) {
			if ($value) {
				$APP_TYPE = $expr;
			}
			elsif (!defined($APP_TYPE)) {
				$APP_TYPE = 'none';
			}
		}
		return $value;
	}

	my ($lhs, $op, $rhs) = separateLR($expr);
	unless (defined($lhs) && defined($op) && defined($rhs)) {
		return undef;
	}

	my $return = undef;
	if ($op eq '&') {
		$return = evalAnd($lhs, $rhs);
	}
	elsif ($op eq '|') {
		$return = evalOr($lhs, $rhs);
	}

	return $return;
}

sub evalOr($$) {
	my ($lhs, $rhs) = @_;

	my $lval = evalExpr($lhs);
	my $rval = evalExpr($rhs);

	unless (defined($lval) && defined($rval)) {
		return undef;
	}

	return ($lval || $rval);
}

sub evalAnd($$) {
	my ($lhs, $rhs) = @_;

	my $lval = evalExpr($lhs);
	my $rval = evalExpr($rhs);

	unless (defined($lval) && defined($rval)) {
		return undef;
	}

	return ($lval && $rval);
}

sub separateLR($) {
	my ($expr) = @_;

	my $lhs = undef;
	my $op  = undef;
	my $rhs = undef;

	if ($expr =~ /(.+?)\s*([&|\|])\s*(.+)/) {
		$lhs = $1;
		$op  = $2;
		$rhs = $3;
	}

	return ($lhs, $op, $rhs);
}


#------------------------------#
# GenDNSMsg                    #
#------------------------------#
sub GenDNSMsg($) {
        my ($msg) = @_;

        # dns header
        my $data = GenDNSHeader( $msg->{'header'} );

        # question section
        $data .= GenDNSQuestionSection( $msg->{'question'} );

        # answer section
        $data .= GenDNSAnswerSection( $msg->{'answer'} );

        # authority section
        $data .= GenDNSAuthoritySection( $msg->{'authority'} );

        # additional section
        $data .= GenDNSAdditionalSection( $msg->{'additional'} );

        return $data;
}

sub GenDNSHeader($) {
        my ($header) = @_;
        my $data = kGen_DNS_Header(
                $header->{'id'},      $header->{'qr'},
                $header->{'opcode'},  $header->{'aa'},
                $header->{'tc'},      $header->{'rd'},
                $header->{'ra'},      $header->{'z'},
                $header->{'ad'},      $header->{'cd'},
                $header->{'rcode'},   $header->{'qdcount'},
                $header->{'ancount'}, $header->{'nscount'},
                $header->{'arcount'}
        );

        unless ($data) {
                my $strerror = kDump_DNS_Error();
                if ( defined($strerror) ) {
                        Debug_Print("$strerror");
                }

                return undef;
        }

        return $data;
}

sub GenDNSQuestionSection($) {
        my ($questions) = @_;

        my $data = '';

        foreach my $question (@$questions) {

                my $tmp .=
                  kGen_DNS_Question( $question->{'qname'}, $question->{'qtype'},
                        $question->{'qclass'} );

                unless ( defined($tmp) ) {
                        my $strerror = kDump_DNS_Error();

                        if ( defined($strerror) ) {
                                Debug_Print("$strerror");
                        }

                        return undef;
                }

                $data .= $tmp;
        }

        return $data;
}

sub GenDNSAnswerSection($) {
        my ($answers) = @_;

        my $data = '';
        foreach my $answer (@$answers) {
                my $tmp = kGen_DNS_RR(
                        $answer->{'name'},     $answer->{'type'},
                        $answer->{'class'},    $answer->{'ttl'},
                        $answer->{'rdlength'}, $answer->{'rdata'},
                );

                my $strerror = kDump_DNS_Error();

                if ( defined($strerror) ) {
                        Debug_Print("$strerror");
                }

                $data .= $tmp;
        }

        return $data;
}

sub GenDNSAuthoritySection($) {
        my ($authorities) = @_;

        my $data = '';
        foreach my $authority (@$authorities) {
                my $tmp = kGen_DNS_RR(
                        $authority->{'name'},     $authority->{'type'},
                        $authority->{'class'},    $authority->{'ttl'},
                        $authority->{'rdlength'}, $authority->{'rdata'},
                );

                my $strerror = kDump_DNS_Error();

                if ( defined($strerror) ) {
                        Debug_Print("$strerror");
                }

                $data .= $tmp;
        }

        return $data;
}

sub GenDNSAdditionalSection($) {
        my ($additionals) = @_;

        my $data = '';
        foreach my $additional (@$additionals) {
                my $tmp = kGen_DNS_RR(
                        $additional->{'name'},     $additional->{'type'},
                        $additional->{'class'},    $additional->{'ttl'},
                        $additional->{'rdlength'}, $additional->{'rdata'},
                );

                my $strerror = kDump_DNS_Error();

                if ( defined($strerror) ) {
                        Debug_Print("$strerror");
                }

                $data .= $tmp;
        }

        return $data;
}

#------------------------------#
# DecDNSMsg                    #
#------------------------------#
sub DecDNSMsg($) {
        my ($data) = @_;

        my $_size_  = 0;
        my $offset  = 0;
        my $_total_ = length($data) - $offset;
        my %message = ();

        #--- Header section ---------------#
        my $header = DecDNSHeader( $data, $offset );

        unless ( defined($header) ) {
                my $strerror = kDump_DNS_Error();

                if ( defined($strerror) ) {
                        Debug_Print("$strerror");
                }

                return (undef);
        }

        $message{'header'}      = $header;
        $message{'header_size'} = $header->{'_size_'};
        $offset += $header->{'_size_'};
        $_size_ += $header->{'_size_'};

        my $qdcount = $header->{'qdcount'};
        my $ancount = $header->{'ancount'};
        my $nscount = $header->{'nscount'};
        my $arcount = $header->{'arcount'};

        #--- Question section -------------#
        my ( $question_size, $question ) =
          DecDNSQuestionSection( $qdcount, $data, $offset );

        unless ( defined($question) ) {
                my $strerror = kDump_DNS_Error();

                if ( defined($strerror) ) {
                        Debug_Print("$strerror");
                }

                return (undef);
        }

        $message{'question_size'} = $question_size;
        $message{'question'}      = $question;
        $offset += $question_size;
        $_size_ += $question_size;

        #--- Answer section ---------------#
        my ( $answer_size, $answer ) =
          DecDNSAnswerSection( $ancount, $data, $offset );

        unless ( defined($answer) ) {
                my $strerror = kDump_DNS_Error();

                if ( defined($strerror) ) {
                        Debug_Print("$strerror");
                }

                return (undef);
        }

        $message{'answer_size'} = $answer_size;
        $message{'answer'}      = $answer;
        $offset += $answer_size;
        $_size_ += $answer_size;

        #--- Authority section ------------#
        my ( $authority_size, $authority ) =
          DecDNSAuthoritySection( $nscount, $data, $offset );

        unless ( defined($authority) ) {
                my $strerror = kDump_DNS_Error();

                if ( defined($strerror) ) {
                        Debug_Print("$strerror");
                }

                return (undef);
        }

        $message{'authority_size'} = $authority_size;
        $message{'authority'}      = $authority;
        $offset += $authority_size;
        $_size_ += $authority_size;

        #--- Additional section -----------#
        my ( $additional_size, $additional ) =
          DecDNSAdditionalSection( $arcount, $data, $offset );

        unless ( defined($additional) ) {
                my $strerror = kDump_DNS_Error();

                if ( defined($strerror) ) {
                        Debug_Print("$strerror");
                }

                return (undef);
        }

        $message{'additional_size'} = $additional_size;
        $message{'additional'}      = $additional;
        $offset += $additional_size;
        $_size_ += $additional_size;

        if ( $_size_ != $_total_ ) {

                # XXX
                Debug_Printf( "datalen mismatch %d <=> %d\n",
                        $_total_, $_size_ );
                return (undef);
        }

        return \%message;
}

sub DecDNSHeader($$) {
        my ( $data, $offset ) = @_;

        my $header = kDec_DNS_Header( $data, $offset );
        unless ( defined($header) ) {
                return undef;
        }
        return $header;
}

sub DecDNSQuestionSection($$$) {
        my ( $qdcount, $data, $offset ) = @_;

        my @section = ();
        my $size    = 0;
        for ( my $i = 0 ; $i < $qdcount ; $i++ ) {
                my $question = kDec_DNS_Question( $data, $offset + $size );

                unless ( defined($question) ) {
                        return undef;
                }

                $size += $question->{'_size_'};
                push( @section, $question );
        }

        return ( $size, \@section );
}

sub DecDNSAnswerSection($$$) {
        my ( $ancount, $data, $offset ) = @_;

        my @section = ();
        my $size    = 0;
        for ( my $i = 0 ; $i < $ancount ; $i++ ) {
                my $answer = kDec_DNS_RR_XYZ( $data, $offset + $size );

                unless ( defined($answer) ) {
                        return undef;
                }

                $size += $answer->{'_size_'};
                push( @section, $answer );
        }

        return ( $size, \@section );
}

sub DecDNSAuthoritySection($$$) {
        my ( $nscount, $data, $offset ) = @_;

        my @section = ();
        my $size    = 0;
        for ( my $i = 0 ; $i < $nscount ; $i++ ) {

                my $authority = kDec_DNS_RR_XYZ( $data, $offset + $size );

                unless ( defined($authority) ) {
                        return undef;
                }
                $size += $authority->{'_size_'};
                push( @section, $authority );
        }

        return ( $size, \@section );
}

sub DecDNSAdditionalSection($$$) {
        my ( $arcount, $data, $offset ) = @_;

        my @section = ();
        my $size    = 0;
        for ( my $i = 0 ; $i < $arcount ; $i++ ) {
                my $addional = kDec_DNS_RR_XYZ( $data, $offset + $size );

                unless ( defined($addional) ) {
                        return undef;
                }

                $size += $addional->{'_size_'};
                push( @section, $addional );
        }

        return ( $size, \@section );
}

#------------------------------#
# JudgeDNSHeader               #
#------------------------------#
sub JudgeDNSHeader($$) {
        my ( $recv_header, $exp_header ) = @_;

        my $result = $TRUE;
	my $printbuf = "<pre>";
	$printbuf .= "Header Section\n";
#	$NgCount = 0;
        foreach my $key ( keys(%$recv_header) ) {
                my $answer = $exp_header->{$key};
                unless ( defined($answer) ) {
                        next;
                }

                if ( $recv_header->{$key} =~ m/^$answer$/ ) {
                        $printbuf .= "<b>OK</b>\t$key: " . "(rcv:$recv_header->{$key}, exp:$answer)\n";
                } else {
			$printbuf .= '<font color="red"><b>';
                        $printbuf .= "NG</b></font>\t$key: " . "(rcv:$recv_header->{$key}, exp:$answer)\n";
#			$NgCount++;
                        $result = undef;
                }
        }
#	if($result && $NgCount > 0){
#		 $printbuf .= "<font color=\"gray\"><b>NG status can be ignored</b></font>\n";
#	}
	$printbuf .= "</pre>";
	Debug_Print($printbuf);
        return $result;
}

#------------------------------#
# JudgeDNSQuestionSection      #
#------------------------------#
sub JudgeDNSQuestionSection($$) {
        my (
                $recv_qsec,    # question section
                $exp_qsec      # question section
        ) = @_;

        my $result = $TRUE;

	my $printbuf = "<pre>";
	$printbuf .= "Question Section\n";

	my $count_loop = 0;
        foreach my $exp_question (@$exp_qsec) {

                my $cmp_result = $FALSE;
#		$NgCount = 0;
		my $pbuf_ok = '';
		my $pbuf_ng = '';
		my $count_ok = 0;
		my $count_ng = 0;		

                foreach my $recv_question (@$recv_qsec) {
			my $pbuf_local = '';
                        if (CompareDNSQuestion($recv_question, $exp_question,\$pbuf_local))
                        {
                                $cmp_result = $TRUE;
				if( $count_ok > 0 ){
					$pbuf_ok .= "\t------------------------\n";
				}
				$pbuf_ok .= $pbuf_local;
				$count_ok++;
                                last;

                        }else{
				if( $count_ng > 0){
					$pbuf_ng .= "\t------------------------\n";
				}
				$pbuf_ng .= $pbuf_local;
				$count_ng++;
			}
                }

                unless ($cmp_result) {
                        $result = undef;
                }
		if($count_loop > 0){
			$printbuf .= "\t------------------------\n";
		}
		if($cmp_result){
			$printbuf .= $pbuf_ok;
		}else{
			$printbuf .= $pbuf_ng;
		}
		$count_loop++;
        }
#	if($result && $NgCount > 0){
#		$printbuf .= "<font color=\"gray\"><b>NG status can be ignored</b></font>\n";
#	}
	$printbuf .= "</pre>";
	Debug_Print($printbuf);
        return $result;
}

#------------------------------#
# JudgeDNSAnswerSection        #
#------------------------------#
sub JudgeDNSAnswerSection($$) {
        my ( $recv, $exp ) = @_;
        return JudgeDNSRR( $recv, $exp ,"Answer Section");
}

#------------------------------#
# JudgeDNSAuthoritySection     #
#------------------------------#
sub JudgeDNSAuthoritySection($$) {
        my ( $recv, $exp ) = @_;
        return JudgeDNSRR( $recv, $exp ,"Authority Section");
}

#------------------------------#
# JudgeDNSAdditionalSection    #
#------------------------------#
sub JudgeDNSAdditionalSection($$) {
        my ( $recv, $exp ) = @_;
        return JudgeDNSRR( $recv, $exp ,"Additional Section");
}

#------------------------------#
# JudgeDNSRR                   #
#------------------------------#
sub JudgeDNSRR($$$) {
        my (
	    $recv_rrs,    # RRs
	    $exp_rrs,     # RRs
	    $section_str
        ) = @_;

        my $result    = $TRUE;
#	$NgCount = 0;
        my %judgeHash = ();
	my $count_loop = 0;
	my $printbuf = "<pre>";

	$printbuf .= "$section_str\n";
	
        foreach my $recv_rr (@$recv_rrs) {

                my $cmp_result = $FALSE;
                my $i          = 0;
		my $pbuf_ok = '';
		my $pbuf_ng = '';
		my $count_ok = 0;
		my $count_ng = 0;

                foreach my $exp_rr (@$exp_rrs) {
			my $pbuf_local = '';
                        unless ( defined( $judgeHash{$i} ) ) {

				my $ret =  CompareDNSRR( $recv_rr, $exp_rr,\$pbuf_local );
                                if ($ret) {
                                        $cmp_result = $TRUE;
                                        $judgeHash{$i} = 1;
					if($count_ok > 0){
						$pbuf_ok .= "\t------------------------\n";
					}
					$pbuf_ok .= $pbuf_local;
					$count_ok++;
                                        last;
                                }else{
					if($count_ng > 0){
						$pbuf_ng .= "\t------------------------\n";
					}
					$pbuf_ng .= $pbuf_local;
					$count_ng++;
				}
                        }
                        $i++;
                }
		if($count_loop > 0){
			$printbuf .= "\t------------------------\n";
		}
		if($cmp_result){
			$printbuf .= $pbuf_ok;

		}else{
			$printbuf .= $pbuf_ng;
		}

                unless ($cmp_result) {
                        if ($JUDGE_OPT_RR) {
                                $result = undef;
                        } else {
                                #ignore OPT_RR,auth_ROOT
                                $DEBUG_PRINT = $FALSE;
                                my $ignore_flag = $FALSE;
				my $pbuf_ignore = '';
                                foreach my $ignore_auth ( $opt_RR, $auth_ROOT )
                                {
                                        if (
                                                CompareDNSRR(
                                                        $recv_rr, $ignore_auth,\$pbuf_ignore
                                                )
                                          )
                                        {
                                                $ignore_flag = $TRUE;
                                                last;
                                        }
                                }
                                if ( $ignore_flag == $FALSE ) {
                                        $result = undef;
                                }
                                $DEBUG_PRINT = $TRUE;
                        }
                }
	        $count_loop++;
        }
#	if($result && $NgCount > 0){
#		$printbuf .= "<font color=\"gray\"><b>NG status can be ignored</b></font>\n";
#	}
	$printbuf .= "</pre>";
	Debug_Print($printbuf) 	if($printbuf =~ /:/);
        return $result;
}

#------------------------------#
# CompareDNSQuestion           #
#------------------------------#
sub CompareDNSQuestion($$$) {
        my (
                $target,     # just one question
                $expected,    # just one question
	        $pbuf_ref
        ) = @_;

        my $result = $TRUE;

        foreach my $key ( keys(%$expected) ) {
                my $exp_value = $expected->{$key};

                unless ( defined($exp_value) ) {
                        next;
                }

                my $target_value;

                #in question section,qname is never treated as pointer.
                if ( $key eq 'qname' ) {
                        $target_value =
                            $target->{$key}->{'offset'}
                          ? $target->{$key}->{'decompressed'}
                          : $target->{$key}->{'compressed'};
                } else {
                        $target_value = $target->{$key};
                }

                #------------------------------------#
                # not distinguish capital from small #
                #------------------------------------#
                if ( $target_value =~ m/^$exp_value$/i ) {
                        $$pbuf_ref .= "<b>OK</b>\t$key: " . "(rcv:$target_value, exp:$exp_value)\n";
                } else {
			$$pbuf_ref .= '<font color="red"><b>';
                        $$pbuf_ref .= "NG</b></font>\t$key: " . "(rcv:$target_value, exp:$exp_value)\n";
#			$NgCount++;
                        $result = $FALSE;
                }
        }

        return $result;
}

#------------------------------#
# CompareDNSRR                 #
#------------------------------#
sub CompareDNSRR($$$) {
        my (
                $target,     # just one resource record
                $expected,    # just one resource record
	        $pbuf_ref
        ) = @_;

        my $result = $TRUE;

        foreach my $key ('type','name','class','ttl','rdlength','rdata' ) {

                my $exp_value = $expected->{$key};

                unless ( defined($exp_value) ) {
                        next;
                }

                my $target_value;
                if ( $key eq 'name' ) {
                        my $ret =
                          CompareCompressedValue( 'name', $target, $expected,$pbuf_ref);
                        if ( $ret == $FALSE ) {
                                $result = $FALSE;
				last;
                        }
                        next;
                } elsif ( $key eq 'rdata' ) {
                        my $ret =
                          CompareRDATA( $target->{'type'}, 
					$target->{'rdata'},
					$expected->{'rdata'},
					$pbuf_ref
				      );
                        if ( $ret == $FALSE ) {
                                $result = $FALSE;
				last;
                        }
                        next;
                } else {
                        $target_value = $target->{$key};
                }
                if ( CompareValue( $key, $target_value, $exp_value,$pbuf_ref ) == $FALSE )
                {
                        $result = $FALSE;
			last;
                }
        }

        return $result;
}

#------------------------------#
# CompareRDATA                 #
#------------------------------#
sub CompareRDATA($$$$) {
        my ( $type, $target_ref, $expected_ref,$pbuf_ref) = @_;

        unless ( defined($target_ref) && defined($expected_ref) ) {
                my $strerror = kDump_DNS_Error();

                if ( defined($strerror) ) {
                        print("$strerror");
                }

                return ($FALSE);
        }

        if ( $type == 1 ) {    # A
                return CompareRDATA_A( $target_ref, $expected_ref,$pbuf_ref );
        } elsif ( $type == 2 ) {    # NS
                return CompareRDATA_NS( $target_ref, $expected_ref,$pbuf_ref  );
        } elsif ( $type == 5 ) {    # CNAME
                return CompareRDATA_CNAME( $target_ref, $expected_ref ,$pbuf_ref );
        } elsif ( $type == 6 ) {    # SOA
                return CompareRDATA_SOA( $target_ref, $expected_ref ,$pbuf_ref );
        } elsif ( $type == 7 ) {    # MB
                return CompareRDATA_MB( $target_ref, $expected_ref ,$pbuf_ref );
        } elsif ( $type == 8 ) {    # MG
                return CompareRDATA_MG( $target_ref, $expected_ref ,$pbuf_ref );
        } elsif ( $type == 9 ) {    # MR
                return CompareRDATA_MR( $target_ref, $expected_ref ,$pbuf_ref );
        } elsif ( $type == 11 ) {    # WKS
                return CompareRDATA_WKS( $target_ref, $expected_ref ,$pbuf_ref );
        } elsif ( $type == 12 ) {    # PTR
                return CompareRDATA_PTR( $target_ref, $expected_ref ,$pbuf_ref );
        } elsif ( $type == 13 ) {    # HINFO
                return CompareRDATA_HINFO( $target_ref, $expected_ref ,$pbuf_ref );
        } elsif ( $type == 14 ) {    # MINFO
                return CompareRDATA_MINFO( $target_ref, $expected_ref ,$pbuf_ref );
        } elsif ( $type == 15 ) {    # MX
                return CompareRDATA_MX( $target_ref, $expected_ref ,$pbuf_ref );
        } elsif ( $type == 16 ) {    # TXT
                return CompareRDATA_TXT( $target_ref, $expected_ref ,$pbuf_ref );
        } elsif ( $type == 24 ) {    # SIG
                return CompareRDATA_SIG( $target_ref, $expected_ref ,$pbuf_ref );
        } elsif ( $type == 25 ) {    # KEY
                return CompareRDATA_KEY( $target_ref, $expected_ref ,$pbuf_ref );
        } elsif ( $type == 28 ) {    # AAAA
                return CompareRDATA_AAAA( $target_ref, $expected_ref ,$pbuf_ref );
        } elsif ( $type == 30 ) {    # NXT
                return CompareRDATA_NXT( $target_ref, $expected_ref ,$pbuf_ref );
        } elsif ( $type == 33 ) {    # SRV
                return CompareRDATA_SRV( $target_ref, $expected_ref ,$pbuf_ref );
        } elsif ( $type == 35 ) {    # NAPTR
                return CompareRDATA_NAPTR( $target_ref, $expected_ref ,$pbuf_ref );
        } elsif ( $type == 41 ) {    # OPT
                return CompareRDATA_OPT( $target_ref, $expected_ref ,$pbuf_ref );
        } else {
                $pbuf_ref .= "NG\tCompareRDATA:UNKNOWN type type=$type\n";
                return undef;
        }
}

#------------------------------#
# CompareValue                 #
#------------------------------#
sub CompareValue($$$$) {
        my ( $key, $target_value, $exp_value ,$pbuf_ref) = @_;

        #------------------------------------#
        # not distinguish capital from small #
        #------------------------------------#
        if ( $target_value =~ m/^$exp_value$/i ) {
		if($DEBUG_PRINT == $TRUE){
			$$pbuf_ref .= "<b>OK</b>\t$key: " . "(rcv:$target_value, exp:$exp_value)\n";
		}
                return $TRUE;
        } else {
		if($DEBUG_PRINT == $TRUE){
			$$pbuf_ref .= '<font color="red"><b>';
			$$pbuf_ref .= "NG</b></font>\t$key: " . "(rcv:$target_value, exp:$exp_value)\n";
#			$NgCount++;
		}
                return $FALSE;
        }
}

#------------------------------#
# CompareCompressedValue       #
#------------------------------#
sub CompareCompressedValue($$$$) {
        my ( $key, $target_ref, $expected_ref,$pbuf_ref ) = @_;

        my $target_compressed   = $target_ref->{$key}->{'compressed'};
        my $target_pointer      = $target_ref->{$key}->{'offset'};
        my $target_decompressed = $target_ref->{$key}->{'decompressed'};

        if ( ( ref $expected_ref ) eq 'HASH' ) {
                if ( ( ref $expected_ref->{$key} ) eq 'HASH' ) {
                        my $exp_compressed =
                          $expected_ref->{$key}->{'compressed'};
                        my $exp_pointer = $expected_ref->{$key}->{'offset'};
                        my $exp_decompressed =
                          $expected_ref->{$key}->{'decompressed'};
                        my $result = $TRUE;
                        if ( defined($target_pointer) ) {
                                $result = CompareValue(
                                        "${key}(compressed)",
                                        $target_compressed,
                                        $exp_compressed,$pbuf_ref
                                );
                                if ( $result == $FALSE ) {
                                        $result = $FALSE;
                                }
                                $result =
                                  CompareValue( "${key}(pointer)",
                                        $target_pointer, $exp_pointer,$pbuf_ref );
                                if ( $result == $FALSE ) {
                                        $result = $FALSE;
                                }
                                return $result;
                        } else {
                                return CompareValue( "$key", $target_compressed,
                                        $exp_compressed,$pbuf_ref );
                        }
                } else {
                        if ( defined($target_pointer) ) {
                                return CompareValue( "$key",
                                        $target_decompressed,
                                        $expected_ref->{$key},$pbuf_ref );
                        } else {
                                return CompareValue( "$key", $target_compressed,
                                        $expected_ref->{$key},$pbuf_ref );
                        }
                }
        } else {
                if ( defined($target_pointer) ) {
                        return CompareValue( "$key", $target_decompressed,
                                $expected_ref,$pbuf_ref );
                } else {
                        return CompareValue( "$key", $target_compressed,
                                $expected_ref,$pbuf_ref );
                }
        }

}

#------------------------------#
# DNSStartConnect()            #
#------------------------------#
sub DNSStartConnect($$) {
        my ( $dns_param_ref, $dns_session_ref ) = @_;
        my $dns_session_config_ref = $dns_param_ref->{'dns_session_config'};
        my $session_num            = scalar @$dns_session_config_ref;
        my $ret                    = undef;
        my %hash                   = ();
        for ( my $i = 0 ; $i < $session_num ; $i++ ) {

                my $ret = $FALSE;
                if (
                        (
                                $dns_session_config_ref->[$i]->{'TN_ADDR_PORT'}
                                eq $TN_SV_PORT
                        )
                        || (
                                defined(
                                        $dns_session_config_ref->[$i]
                                          ->{'MODE_LISTEN'}
                                )
                        )
                  )
                {
                        for ( my $j = 0 ; $j < $i ; $j++ ) {
                                $ret = CompareConfig(
                                        $dns_session_config_ref->[$i],
                                        $dns_session_config_ref->[$j]
                                );
                                if ( $ret == $TRUE ) {
                                        $dns_session_ref->[$i]->{'socket_ref'}
                                          ->{'SocketID'} = $hash{$j};
                                        last;
                                }
                        }
                        if ( $ret == $FALSE ) {
                                $ret = __DNSStartRecv(
                                        $dns_session_ref->[$i],
                                        $dns_session_config_ref->[$i]
                                );
                                $hash{$i} =
                                  $dns_session_ref->[$i]->{'socket_ref'}
                                  ->{'SocketID'};
                        }
                } else {
                        $ret = __DNSStartSend(
                                $dns_session_ref->[$i],
                                $dns_session_config_ref->[$i]
                        );
                }
                unless ( defined($ret) ) {
                        return $ret;    #undef
                }
        }
}

sub CompareConfig($$) {
        my ( $configA, $configB ) = @_;
        if ( ( scalar( keys %$configA ) ) != ( scalar( keys %$configB ) ) ) {
                return $FALSE;
        }
        foreach my $key ( keys %$configA ) {
                if ( $configA->{$key} ne $configB->{$key} ) {
                        return $FALSE;
                }
        }
        return $TRUE;
}

#------------------------------#
# __DNSStartSend               #
#------------------------------#
sub __DNSStartSend($$) {
        my ( $dns_session_ref, $dns_session_config_ref ) = @_;

        #------------------------------#
        # kPacket_ConnectSend()        #
        #------------------------------#
	my $app_frame = $dns_session_config_ref->{'TN_ADDR_FRAME'};
	if(defined($app_frame)){
		$FRAME_ID = $app_frame;
	}else{
		$FRAME_ID =
			kSwitchFrameID( $dns_session_config_ref->{'TN_ADDR_PROTO'}, 'DNS' );

	}
        my $ret = undef;
        if ( defined( $dns_session_config_ref->{'MODE_BROADCAST'} ) ) {
                $ret = kPacket_ConnectSend(
                        $dns_session_config_ref->{'TN_ADDR_PROTO'},
                        $FRAME_ID,
                        $dns_session_config_ref->{'TN_ADDR_FAMILY'},
                        $dns_session_config_ref->{'TN_ADDR'},
                        $dns_session_config_ref->{'NUT_ADDR'},
                        $dns_session_config_ref->{'TN_ADDR_PORT'},
                        $dns_session_config_ref->{'NUT_ADDR_PORT'},
                        undef,                                      #datalen
                        undef,                                      #data
                        $dns_session_config_ref->{'TN_INTERFACE'},  #LINK0 LINK1
                        1
                );
        } else {
                $ret = kPacket_ConnectSend(
                        $dns_session_config_ref->{'TN_ADDR_PROTO'},
                        $FRAME_ID,
                        $dns_session_config_ref->{'TN_ADDR_FAMILY'},
                        $dns_session_config_ref->{'TN_ADDR'},
                        $dns_session_config_ref->{'NUT_ADDR'},
                        $dns_session_config_ref->{'TN_ADDR_PORT'},
                        $dns_session_config_ref->{'NUT_ADDR_PORT'},
                        undef,                                      #datalen
                        undef,                                      #data
                        $dns_session_config_ref->{'TN_INTERFACE'}   #LINK0 LINK1
                );
        }
        unless ( defined($ret) ) {
                if ( defined($DNS_ERR_MSG) ) {
                        Debug_Print("Error:DNSStartSend:kPacket_ConnectSend\n");
                }

                return $ret;                                        #undef
        }
        $dns_session_ref->{'socket_ref'} = $ret;

        kRegistSocketID( $ret->{'SocketID'},
                $dns_session_config_ref->{'TN_ADDR_PROTO'} );
        return $TRUE;
}

#------------------------------#
# __DNSStartRecv                 #
#------------------------------#
sub __DNSStartRecv($$) {
        my ( $dns_session_ref, $dns_session_config_ref ) = @_;

        #------------------------------#
        # kPacket_StartRecv()          #
        #------------------------------#
	my $app_frame = $dns_session_config_ref->{'TN_ADDR_FRAME'};
	if(defined($app_frame)){
		$FRAME_ID = $app_frame;
	}else{
		$FRAME_ID =
			kSwitchFrameID( $dns_session_config_ref->{'TN_ADDR_PROTO'}, 'DNS' );
	}

         my $ret = kPacket_StartRecv(
                 $dns_session_config_ref->{'TN_ADDR_PROTO'},
                 $FRAME_ID,
                 $dns_session_config_ref->{'TN_ADDR_FAMILY'},
                 $dns_session_config_ref->{'TN_ADDR'},
                 $dns_session_config_ref->{'TN_ADDR_PORT'},
                $dns_session_config_ref->{'TN_INTERFACE'}
         );
         unless ( defined($ret) ) {
                 if ( defined($DNS_ERR_MSG) ) {
                         Debug_Print("Error:DNSStartRecv:kPacket_StartRecv\n");
                 }
                 return $ret;    #undef
         }

        if ($DEBUG_KOI_INFO) {
                Debug_Print(
                        "kPacket_StartRecv: Command:    $ret->{'Command'}\n");
                Debug_Print(
                        "kPacket_StartRecv: RequestNum: $ret->{'RequestNum'}\n"
                );
                Debug_Print(
                        "kPacket_StartRecv: Result:     $ret->{'Result'}\n");
                Debug_Print(
                        "kPacket_StartRecv: SocketID:   $ret->{'SocketID'}\n");
        }
        $dns_session_ref->{'socket_ref'} = $ret;

        #save TN_ADDR_PROTO to hash for child
        $proto_hash{ $ret->{'SocketID'} } =
          $dns_session_config_ref->{'TN_ADDR_PROTO'};

        kRegistSocketID( $ret->{'SocketID'},
                $dns_session_config_ref->{'TN_ADDR_PROTO'} );

        return $TRUE;
}

sub DNSCheckConnect($$) {
        my ( $time_out, $socket_ref ) = @_;
        my $ret             = undef;
        my $socketid        = $socket_ref->{'SocketID'};
        my $decoded_dns_msg = undef;

        $ret = kPacket_Recv( $socketid, $time_out );
        unless ( defined($ret) ) {
                if ( defined($DNS_ERR_MSG) ) {
                        Debug_Print("Error:DNSCheckConnect:kPacket_Recv\n");
                }
                return $ret;    #undef
        }
        return $ret->{'SocketID'};
}

#------------------------------#
# __DNSRecv                    #
#------------------------------#

sub __DNSRecv($$$) {
        my ( $time_out, $socket_ref, $one_session_ref ) = @_;

        #------------------------------#
        # kPacket_Recv()               #
        #------------------------------#

        my $ret             = undef;
        my $socketid        = $socket_ref->{'SocketID'};
        my $decoded_dns_msg = undef;

        while (1) {
		
                $ret = kPacket_Recv( $socketid, $time_out );

                unless ( defined($ret) ) {
                        if ( defined($DNS_ERR_MSG) ) {
                                Debug_Print("Error:__DNSRecv:kPacket_Recv\n");
                        }
                        return $ret;    #undef
                }
		
		my $parentID = $socketIDHash{ $ret->{'SocketID'} };
		
		#regist SocketID of child
                if ( defined($parentID) ) {
                        kRegistSocketID( $ret->{'SocketID'},
					 $proto_hash{$parentID} );
                }

                $ret->{'Data'} = kDecompileDNSMsg( $socketid, $ret->{'Data'} );

                if ($DEBUG_KOI_INFO) {
                        Debug_Print(
                                "kPacket_Recv: Command:    $ret->{'Command'}\n"
                        );
                        Debug_Print(
                                "kPacket_Recv: RequestNum: $ret->{'RequestNum'}\n"
                        );
                        Debug_Print(
                                "kPacket_Recv: Result:     $ret->{'Result'}\n");
                        Debug_Print(
                                "kPacket_Recv: SocketID:   $ret->{'SocketID'}\n"
                        );
                        Debug_Print(
                                "kPacket_Recv: DataID:     $ret->{'DataID'}\n");
                        Debug_Print(
                                "kPacket_Recv: TimeStamp:  $ret->{'TimeStamp'}\n"
                        );
                        Debug_Print(
                                "kPacket_Recv: TimeStamp2: $ret->{'TimeStamp2'}\n"
                        );
                        Debug_Print(
                                "kPacket_Recv: SrcPort:    $ret->{'SrcPort'}\n"
                        );
                        Debug_Print(
                                "kPacket_Recv: DstPort:    $ret->{'DstPort'}\n"
                        );
                        Debug_Print(
                                "kPacket_Recv: AddrType:   $ret->{'AddrType'}\n"
                        );
                        Debug_Print(
                                "kPacket_Recv: Reserve1:   $ret->{'Reserve1'}\n"
                        );
                        Debug_Print(
                                "kPacket_Recv: Reserve2:   $ret->{'Reserve2'}\n"
                        );
                        Debug_Print(
                                "kPacket_Recv: SrcAddr:    $ret->{'SrcAddr'}\n"
                        );
                        Debug_Print(
                                "kPacket_Recv: DstAddr:    $ret->{'DstAddr'}\n"
                        );
                        Debug_Print(
                                "kPacket_Recv: DataLength: $ret->{'DataLength'}\n"
                        );

                        my $data = unpack( 'H*', $ret->{'Data'} );
                        Debug_Print("kPacket_Recv: Data:       $data\n");
                }

                #overwrite
                if ( $socket_ref->{'SocketID'} != $ret->{'SocketID'} ) {

                        $socketIDHash{ $ret->{'SocketID'} } = $socket_ref->{'SocketID'};
                        $socket_ref->{'SocketID'} = $ret->{'SocketID'};
                        $socketid = $ret->{'SocketID'};
                }
                my $offset = 0;
		if($DEBUG_KOI_INFO){
			if ($DEC_MESSAGE_TYPE eq 'SIP'){
				kPrint_SIP( $ret->{'Data'});
			}
			else{
				kPrint_DNS( $ret->{'Data'}, $offset );
			}
		}
                #decode and push data
                my @ret_array = ();
		if ($DEC_MESSAGE_TYPE eq 'SIP'){
                	$decoded_dns_msg = undef;
                        last;
		}
		else{
                	$decoded_dns_msg = DecDNSMsg( $ret->{'Data'} );
		}

		unless (checkRootQuery($socketid, $decoded_dns_msg)) {
                        last;
                }
        }    #while

        if ( defined( $one_session_ref->{'dec_dns_msg'} ) ) {
                push( @{ $one_session_ref->{'dec_dns_msg'} },
                        $decoded_dns_msg );
        } else {
                $one_session_ref->{'dec_dns_msg'}->[0] = $decoded_dns_msg;
        }
        if ( defined( $one_session_ref->{'raw_dns_msg'} ) ) {
                push( @{ $one_session_ref->{'raw_dns_msg'} },
                        $ret->{'Data'} );
        } else {
                $one_session_ref->{'raw_dns_msg'}->[0] = $ret->{'Data'};
        }

        return $TRUE;
}

#------------------------------#
# checkRootQuery()             #
#------------------------------#
sub checkRootQuery($$) {
        my ( $socketid, $recv_data ) = @_;
	my @ignorelist = (
			  $exp_root_query_0,
			  $exp_root_query_1,
			 );

	push(@ignorelist,$exp_root_query_2) if($JUDGE_NS_AAAA);

	my $ret = undef;
	$DEBUG_PRINT = $FALSE;
	foreach my $packet (@ignorelist){
		$ret = JudgeDNSMsg( $recv_data, $packet );
		if ($ret) {
			# packet match
			kLogHTML("This test does not focus "
				. "the previous packet.<br>\n"
				. "Skip.\n");
			return $ret;
		}
        }
        $DEBUG_PRINT = $TRUE;
        return ($ret);
}

#------------------------------#
# __DNSSend                    #
#------------------------------#
sub __DNSSend($$) {
        my ( $socketid_new, $gen_dns_msg_ref ) = @_;
        my $ret = undef;

        my $socketid =
          defined( $socketIDHash{$socketid_new} )
          ? $socketIDHash{$socketid_new}
          : $socketid_new;

        unless ( ( ref $gen_dns_msg_ref ) eq 'ARRAY' ) {
                if ( defined($DNS_ERR_MSG) ) {
                        Debug_Print("Error:__DNSSend:Can't get gen_dns_msg\n");
                }
                return $ret;    #undef
        }

        for ( my $i = 0 ; $i < scalar @{$gen_dns_msg_ref} ; $i++ ) {
                my $data   = GenDNSMsg( $gen_dns_msg_ref->[$i] );
                my $offset = 0;
		if($DEBUG_KOI_INFO){
			kPrint_DNS( $data, $offset );
		}
                $data = kCompileDNSMsg( $socketid, $data );

		#------------------------------#
		# kPacket_Send()               #
		#------------------------------#
		
                my $ret = kPacket_Send( $socketid_new, length($data), $data );
		
                unless ( defined($ret) ) {
                        if ( defined($DNS_ERR_MSG) ) {
                                Debug_Print("Error:DNSSend:kPacket_Send\n");
                        }
                        return $ret;    #undef
                }

                if ($DEBUG_KOI_INFO) {
                        Debug_Printf( "kPacket_Send: Command:    0x%x\n",
                                $ret->{'Command'} );
                        Debug_Printf( "kPacket_Send: RequestNum: 0x%x\n",
                                $ret->{'RequestNum'} );
                        Debug_Printf( "kPacket_Send: Result:     0x%x\n",
                                $ret->{'Result'} );
                        Debug_Printf( "kPacket_Send: SocketID:   0x%x\n",
                                $ret->{'SocketID'} );
                        Debug_Printf( "kPacket_Send: DataID:     0x%x\n",
                                $ret->{'DataID'} );
                        Debug_Printf( "kPacket_Send: TimeStamp:  0x%x\n",
                                $ret->{'TimeStamp'} );
                        Debug_Printf( "kPacket_Send: TimeStamp2: 0x%x\n",
                                $ret->{'TimeStamp2'} );
                        Debug_Printf("\n");
                }

        }    #for

        return $TRUE;
}

#------------------------------#
# DNSRecv                      #
#------------------------------#
sub DNSRecv($$$$) {
        my ( $receive_count, $time_out, $socket_ref, $one_session_ref ) = @_;

        my $ret = undef;
        for ( my $i = 0 ; $i < $receive_count ; $i++ ) {
                $ret = __DNSRecv( $time_out, $socket_ref, $one_session_ref );

                unless ( defined($ret) ) {
                        if ( defined($DNS_ERR_MSG) ) {
                                Debug_Print("Error:DNSRecv:__DNSRecv\n");
                        }
                        return $ret;    #undef
                }
        }    #recv
        return $TRUE;
}

#------------------------------#
# DNSSend                      #
#------------------------------#
sub DNSSend($$$) {
        my ( $send_count, $socket_ref, $one_session_ref ) = @_;

#	my $socketid = defined($socket_ref->{'SocketIDSend'}) ? $socket_ref->{'SocketIDSend'} : $socket_ref->{'SocketID'};
        my $socketid = $socket_ref->{'SocketID'};

        #send
        for ( my $j = 0 ; $j < $send_count ; $j++ ) {
                my $ret =
                  __DNSSend( $socketid, $one_session_ref->{'gen_dns_msg'} );
                unless ( defined($ret) ) {
                        if ( defined($DNS_ERR_MSG) ) {
                                Debug_Print("Error:DNSSend:DNSSend\n");
                        }
                        return $ret;    #undef
                }

        }    #send

        return $TRUE;
}

#------------------------------#
# DNSSendRecv                  #
#------------------------------#
sub DNSSendRecv($$$$$) {
        my ( $send_count, $receive_count, $time_out, $socket_ref,
                $one_session_ref )
          = @_;
        my $ret      = undef;
        my $socketid = $socket_ref->{'SocketID'};
        for ( my $i = 0 ; $i < $receive_count ; $i++ ) {

                #send
                for ( my $j = 0 ; $j < $send_count ; $j++ ) {
                        $ret = undef;
                        $ret =
                          __DNSSend( $socketid,
                                $one_session_ref->{'gen_dns_msg'} );
                        unless ( defined($ret) ) {
                                if ( defined($DNS_ERR_MSG) ) {
                                        Debug_Print(
                                                "ERROR: Can't send DNS message\n"
                                        );
                                }
                                return $ret;    #undef
                        }

                }    #send

                my @dec_dns_msg = $one_session_ref->{'dec_dns_msg'};
                $ret = undef;
                $ret = __DNSRecv( $time_out, $socket_ref, $one_session_ref );

                unless ( defined($ret) ) {
                        if ( defined($DNS_ERR_MSG) ) {
                                Debug_Print(
                                        "ERROR: Can't receive DNS message\n");
                        }
                        return $ret;    #undef
                }

        }    #recv
        return $TRUE;
}

#------------------------------#
# Gen_DNS_Name                 #
#------------------------------#
sub Gen_DNS_Name(@) {
        my ( $name, $offset ) = @_;
        if ( defined($offset) ) {
                return kGen_DNS_Name( $name, $offset );
        } else {
                return kGen_DNS_Name($name);
        }
}

#------------------------------#
# Gen_DNS_RDATA_A              #
#------------------------------#
sub Gen_DNS_RDATA_A(@) {
        my ($address) = @_;
        if ( $address =~ /:/ ) {
                return kGen_DNS_RDATA_AAAA($address);
        }
        return kGen_DNS_RDATA_A($address);
}

#------------------------------#
# Gen_DNS_RDATA_MX             #
#------------------------------#
sub Gen_DNS_RDATA_MX($$) {
        my ( $preference, $exchange ) = @_;
        return kGen_DNS_RDATA_MX( $preference, $exchange );
}

#------------------------------#
# Gen_DNS_RDATA_SOA            #
#------------------------------#
sub Gen_DNS_RDATA_SOA($$$$$$$) {
        my ( $mnane, $rname, $serial, $refresh, $retry, $expire, $minimum ) =
          @_;
        return kGen_DNS_RDATA_SOA(
                $mnane, $rname,  $serial, $refresh,
                $retry, $expire, $minimum
        );
}

#------------------------------#
# Gen_DNS_RDATA_PTR            #
#------------------------------#
sub Gen_DNS_RDATA_PTR($) {
        my ($ptrdname) = @_;
        return kGen_DNS_RDATA_PTR($ptrdname);
}

#------------------------------#
# Gen_DNS_RDATA_HINFO          #
#------------------------------#
sub Gen_DNS_RDATA_HINFO($$) {
        my ( $cpu, $os ) = @_;
        return kGen_DNS_RDATA_HINFO( $cpu, $os );
}

#------------------------------#
# Gen_DNS_RDATA_WKS            #
#------------------------------#
sub Gen_DNS_RDATA_WKS($$$) {
        my ( $address, $protocol, $bitmap ) = @_;
        return kGen_DNS_RDATA_WKS( $address, $protocol, $bitmap );
}

#------------------------------#
# Gen_DNS_RDATA_TXT            #
#------------------------------#
sub Gen_DNS_RDATA_TXT(@) {
        my @args = @_;
        return kGen_DNS_RDATA_TXT(@args);
}

#------------------------------#
# Gen_DNS_RDATA_AAAA           #
#------------------------------#
sub Gen_DNS_RDATA_AAAA($) {
        my ($address) = @_;
        return kGen_DNS_RDATA_AAAA($address);
}

#------------------------------#
# Gen_DNS_RDATA_OPT            #
#------------------------------#
sub Gen_DNS_RDATA_OPT(@) {
        my @args = @_;
        return kGen_DNS_RDATA_OPT(@args);
}

#------------------------------#
# Gen_DNS_RDATA_SRV            #
#------------------------------#
sub Gen_DNS_RDATA_SRV($$$$) {
        my ( $priority, $weight, $port, $target ) = @_;
        return kGen_DNS_RDATA_SRV( $priority, $weight, $port, $target );
}

#------------------------------#
# Gen_DNS_RDATA_NAPTR          #
#------------------------------#
sub Gen_DNS_RDATA_NAPTR($$$$$$){
        my ($order, $preference, $flags, $services, $regexp, $replacement) = @_;
        return kGen_DNS_RDATA_NAPTR($order, $preference, $flags, $services, $regexp, $replacement);
}

#------------------------------#
# Packet_Clear                 #
#------------------------------#
sub Packet_Clear($$$$) {
        my ( $socketid_flag, $dataid_flag, $socketid, $dataid ) = @_;
        return kPacket_Clear( $socketid_flag, $dataid_flag, $socketid,
                $dataid );
}

#------------------------------#
# Packet_Close                 #
#------------------------------#
sub Packet_Close($$) {
        my ( $socketid, $sec ) = @_;
        return kPacket_Close( $socketid, $sec );
}

#------------------------------#
# Debug_Print                  #
#------------------------------#
sub Debug_Print($) {
        my ($str) = @_;
        if ( $DEBUG_PRINT == $TRUE ) {
		my $error = ($str =~ /ERROR:/) ? 1 : 0;
                kLogHTML($str, $error);
        }
}

#------------------------------#
# Debug_Printf                 #
#------------------------------#
sub Debug_Printf(@) {
        my @array = @_;
        if ( $DEBUG_PRINTF == $TRUE ) {
                kLogHTML( sprintf( shift @array, @array ) );
        }
}

#------------------------------#
# Print_Message                #
#------------------------------#
sub Print_Message($$) {
        my ( $line, $str_ref ) = @_;
        my $num = scalar @$str_ref;
        print( $line x 50 . "\n" );
	my $str = '<pre>';
        for ( my $i = 0 ; $i < $num ; $i++ ) {
                $str .= $str_ref->[$i];
        }
	$str .= '</pre>';
        Debug_Print($str);
	print( $line x 50 . "\n" );
}

#------------------------------#
# JudgeDNSMsg                  #
#------------------------------#
sub JudgeDNSMsg($$) {

        my ( $recv_data, $exp_data ) = @_;
        my $ret                 = undef;
        my %auth_add_check_hash = ();

        my $header = $recv_data->{'header'};
        unless ( defined($header) ) {
                Debug_Print("ERROR: Can't receive Header Section\n");
                return $ret;    #undef
        }

        unless ( JudgeDNSHeader( $header, $exp_data->{'header'} ) ) {
                return $ret;
        }

        my $qdcount = $recv_data->{'header'}->{'qdcount'};
        my $ancount = $recv_data->{'header'}->{'ancount'};
        my $nscount = $recv_data->{'header'}->{'nscount'};
        my $arcount = $recv_data->{'header'}->{'arcount'};
        my $exp_qdcount = $exp_data->{'header'}->{'qdcount'};
        my $exp_ancount = $exp_data->{'header'}->{'ancount'};
        my $exp_nscount = $exp_data->{'header'}->{'nscount'};
        my $exp_arcount = $exp_data->{'header'}->{'arcount'};

        if ( $qdcount > 0 ) {
                my $questions = $recv_data->{'question'};
                unless ( defined($questions) ) {
                        Debug_Print("ERROR: Can't receive Question Section\n");
                        return $ret;
                }

                unless (
                        JudgeDNSQuestionSection(
                                $questions, $exp_data->{'question'}
                        )
                  )
                {
                        return $ret;
                }
        }

        my $current_qtype = 0;

        if ( $ancount > 0 && defined($exp_ancount)) {
                my $answer = $recv_data->{'answer'};
                unless ( defined($answer) ) {
                        Debug_Print("ERROR: Can't receive Answer Section\n");
                        return $ret;
                }

                #save current type
                $current_qtype = $answer->[0]->{'type'};

                unless ( JudgeDNSAnswerSection( $answer, $exp_data->{'answer'} )){
                        return $ret;
                }
        }

        if ( $nscount > 0 ) {
                my $authority = $recv_data->{'authority'};
                unless ( defined($authority) ) {
                        Debug_Print("ERROR: Can't receive Authority Section\n");
                        return ($ret);
                }

                #save nsdname
                foreach my $auth_rr (@$authority) {
                        my $auth_nsd_ref = $auth_rr->{'rdata'}->{'nsdname'};
                        my $auth_nsdname =
                            $auth_nsd_ref->{'offset'}
                          ? $auth_nsd_ref->{'decompressed'}
                          : $auth_nsd_ref->{'compressed'};
                        if ( defined($auth_nsdname) ) {
                                $auth_add_check_hash{$auth_nsdname} = 1;
                        }
                }
                unless (JudgeDNSAuthoritySection($authority, $exp_data->{'authority'})){
                        return ($ret);
                }
        }

        if ( $arcount > 0 ) {
                my $additional = $recv_data->{'additional'};
                unless ( defined($additional) ) {
                        Debug_Print("ERROR: Can't receive Additional Section\n");
                        return ($ret);
                }

                #judge additional section
                if ( $current_qtype == 1 ) {
                        foreach my $add_rr (@$additional) {
                                my $add_name =
                                    $add_rr->{'name'}->{'offset'}
                                  ? $add_rr->{'name'}->{'decompressed'}
                                  : $add_rr->{'name'}->{'compressed'};
                                if ( defined($add_name) ) {
                                        unless ( $auth_add_check_hash{$add_name}){
                                                Debug_Print(
							    "ERROR: Corresponding Authority Section doesn't exist\n"
                                                );
                                                return ($ret);
                                        }
                                }
                        }
                }
                unless (
                        JudgeDNSAdditionalSection(
                                $additional, $exp_data->{'additional'}
                        )
                  )
                {
                        return ($ret);
                }

        }

        return 1;

}

#------------------------------#
# CompareRDATA_A               #
#------------------------------#
sub CompareRDATA_A($$$) {
        my ( $target_ref, $expected_ref,$pbuf_ref ) = @_;

        if ( ( ref $expected_ref ) eq 'HASH' ) {
                return CompareValue(
                        'address',
                        $target_ref->{'address'},
                        $expected_ref->{'address'},$pbuf_ref
                );
        } else {
                return CompareValue( 'address', $target_ref->{'address'},
                        $expected_ref,$pbuf_ref );
        }
}

#------------------------------#
# CompareRDATA_NS              #
#------------------------------#
sub CompareRDATA_NS($$$) {
        my ( $target_ref, $expected_ref,$pbuf_ref ) = @_;
        return CompareCompressedValue( 'nsdname', $target_ref, $expected_ref,$pbuf_ref );
}

#------------------------------#
# CompareRDATA_CNAME           #
#------------------------------#
sub CompareRDATA_CNAME($$$) {
        my ( $target_ref, $expected_ref,$pbuf_ref ) = @_;
        return CompareCompressedValue( 'cname', $target_ref, $expected_ref,$pbuf_ref );
}

#------------------------------#
# CompareRDATA_SOA             #
#------------------------------#
sub CompareRDATA_SOA($$$) {
        my ( $target_ref, $expected_ref,$pbuf_ref ) = @_;
        my $return   = $TRUE;
        my %soa_hash = (
                'mname'   => 1,
                'rname'   => 1,
                'serial'  => 0,
                'refresh' => 0,
                'retry'   => 0,
                'expire'  => 0,
                'minimum' => 0,
        );
        my $result;
        unless ( ( ref $expected_ref ) eq ( ref $target_ref ) ) {
                return $FALSE;
        }
        foreach my $key ( keys %soa_hash ) {
                if ( $soa_hash{$key} > 0 ) {
                        $result =
                          CompareCompressedValue( $key, $target_ref,
                                $expected_ref,$pbuf_ref );
                } else {
                        $result =
                          CompareValue( $key, $target_ref->{$key},
                                $expected_ref->{$key},$pbuf_ref );
                }
                if ( $result == $FALSE ) {
                        $return = $FALSE;
                }
        }
        return $return;
}

#------------------------------#
# CompareRDATA_MB              #
#------------------------------#
sub CompareRDATA_MB($$$) {
        my ( $target_ref, $expected_ref,$pbuf_ref ) = @_;
        return CompareCompressedValue( 'madname', $target_ref, $expected_ref,$pbuf_ref );
}

#------------------------------#
# CompareRDATA_MG              #
#------------------------------#
sub CompareRDATA_MG($$$) {
        my ( $target_ref, $expected_ref,$pbuf_ref ) = @_;
        return CompareCompressedValue( 'mgmname', $target_ref, $expected_ref,$pbuf_ref );
}

#------------------------------#
# CompareRDATA_MR              #
#------------------------------#
sub CompareRDATA_MR($$$) {
        my ( $target_ref, $expected_ref,$pbuf_ref ) = @_;
        return CompareCompressedValue( 'newname', $target_ref, $expected_ref,$pbuf_ref );
}

#------------------------------#
# CompareRDATA_WKS             #
#------------------------------#
sub CompareRDATA_WKS($$$) {
        my ( $target_ref, $expected_ref,$pbuf_ref ) = @_;
        my $return = $TRUE;
        if (
                CompareValue(
                        'address', $target_ref->{'address'},
                        $expected_ref->{'address'},$pbuf_ref
                ) == $FALSE
          )
        {
                $return = $FALSE;
        }
        if (
                CompareValue(
                        'protocol',
                        $target_ref->{'protocol'},
                        $expected_ref->{'protocol'},$pbuf_ref
                ) == $FALSE
          )
        {
                $return = $FALSE;
        }
        if (
                CompareValue(
                        'bitmap',
                        unpack( "B*", $target_ref->{'bitmap'} ),
                        $expected_ref->{'bitmap'},$pbuf_ref
                ) == $FALSE
          )
        {
                $return = $FALSE;
        }

        return $return;
}

#------------------------------#
# CompareRDATA_PTR             #
#------------------------------#
sub CompareRDATA_PTR($$$) {
        my ( $target_ref, $expected_ref,$pbuf_ref ) = @_;
        return CompareCompressedValue( 'ptrdname', $target_ref, $expected_ref ,$pbuf_ref);
}

#------------------------------#
# CompareRDATA_HINFO           #
#------------------------------#
sub CompareRDATA_HINFO($$$) {
        my ( $target_ref, $expected_ref,$pbuf_ref ) = @_;
        my $return = $TRUE;
        my $result = undef;
        if ( ( ref $expected_ref->{'cpu'} ) eq 'HASH' ) {
                $result = CompareValue(
                        'cpu',
                        $target_ref->{'cpu'}->{'string'},
                        $expected_ref->{'cpu'}->{'string'},$pbuf_ref
                );
        } else {
                $result = CompareValue(
                        'cpu',
                        $target_ref->{'cpu'}->{'string'},
                        $expected_ref->{'cpu'},$pbuf_ref
                );
        }
        if ( $result = $FALSE ) {
                $return = $FALSE;
        }
        if ( ( ref $expected_ref->{'os'} ) eq 'HASH' ) {
                $result = CompareValue(
                        'os',
                        $target_ref->{'os'}->{'string'},
                        $expected_ref->{'os'}->{'string'},$pbuf_ref
                );
        } else {
                $result = CompareValue( 'os', $target_ref->{'os'}->{'string'},
                        $expected_ref->{'os'},$pbuf_ref );
        }
        if ( $result = $FALSE ) {
                $return = $FALSE;
        }
        return $return;
}

#------------------------------#
# CompareRDATA_MINFO           #
#------------------------------#
sub CompareRDATA_MINFO($$$) {
        my ( $target_ref, $expected_ref,$pbuf_ref ) = @_;
        my $return = $TRUE;
        if ( CompareCompressedValue( 'rmailbx', $target_ref, $expected_ref,$pbuf_ref )
                == $FALSE )
        {
                $return = $FALSE;
        }
        if ( CompareCompressedValue( 'emailbx', $target_ref, $expected_ref,$pbuf_ref )
                == $FALSE )
        {
                $return = $FALSE;
        }
        return $return;
}

#------------------------------#
# CompareRDATA_MX              #
#------------------------------#
sub CompareRDATA_MX($$$) {
        my ( $target_ref, $expected_ref,$pbuf_ref ) = @_;
        my $return = $TRUE;
        if (
                CompareCompressedValue(
                        'exchange', $target_ref, $expected_ref,$pbuf_ref
                ) == $FALSE
          )
        {
                $return = $FALSE;
        }
        if (
                CompareValue(
                        'preference',
                        $target_ref->{'preference'},
                        $expected_ref->{'preference'},$pbuf_ref
                ) == $FALSE
          )
        {
                $return = $FALSE;
        }
        return $return;
}

#------------------------------#
# CompareRDATA_TXT             #
#------------------------------#
sub CompareRDATA_TXT($$$) {
        my ( $target_ref, $expected_ref,$pbuf_ref ) = @_;
        my $return         = $TRUE;
        my @expected_array = undef;
        if ( ( ref $expected_ref ) eq 'HASH' ) {
                @expected_array = $expected_ref->{'texts'};
        } else {
                @expected_array = $expected_ref;
        }
        my $result = undef;
        for ( my $i = 0 ; $i <= $#expected_array ; $i++ ) {
                if ( ( ref $expected_array[$i] ) eq 'HASH' ) {
                        $result = CompareValue(
                                'text',
                                $target_ref->{'texts'}[$i]->{'string'},
                                $expected_array[$i]->{'string'},$pbuf_ref
                        );
                } else {
                        $result =
                          CompareValue( 'text',
                                $target_ref->{'texts'}[$i]->{'string'},
                                $expected_array[$i],$pbuf_ref );
                }
                if ( $result == $FALSE ) {
                        $return = $FALSE;
                }
        }
        return $return;
}

#------------------------------#
# CompareRDATA_SIG             #
#------------------------------#
sub CompareRDATA_SIG($$$) {
        my ( $target_ref, $expected_ref,$pbuf_ref ) = @_;
        my $return = $TRUE;
        if ( CompareCompressedValue( 'name', $target_ref, $expected_ref,$pbuf_ref ) ==
                $FALSE )
        {
                $return = $FALSE;
        }
        if (
                CompareValue(
                        'signature',
                        unpack(
                                "B*", pack( "H*", $target_ref->{'signature'} )
                        ),
                        $expected_ref->{'signature'},$pbuf_ref
                ) == $FALSE
          )
        {
                $return = $FALSE;
        }
        foreach my $key (
                'type',       'algorighm', 'labels', 'ttl',
                'expiration', 'inception', 'tag'
          )
        {
                if (
                        CompareValue(
                                $key, $target_ref->{$key},
                                $expected_ref->{$key},$pbuf_ref
                        ) == $FALSE
                  )
                {
                        $return = $FALSE;
                }
        }
        return $return;
}

#------------------------------#
# CompareRDATA_KEY             #
#------------------------------#
sub CompareRDATA_KEY($$$) {
        my ( $target_ref, $expected_ref,$pbuf_ref ) = @_;
        my $return   = $TRUE;
        my %key_hash = (
                'pubkey'    => 1,
                'keytype'   => 0,
                'reserved1' => 0,
                'extension' => 0,
                'reserved2' => 0,
                'nametype'  => 0,
                'reserved3' => 0,
                'signatory' => 0,
                'protocol'  => 0,
                'algorighm' => 0,
        );
        my $result;
        foreach my $key ( keys %key_hash ) {
                if ( $key_hash{$key} > 0 ) {
                        $result =
                          CompareCompressedValue( $key, $target_ref,
                                $expected_ref,$pbuf_ref );
                } else {
                        $result =
                          CompareValue( $key, $target_ref->{$key},
                                $expected_ref->{$key},$pbuf_ref );
                }
                if ( $result == $FALSE ) {
                        $return = $FALSE;
                }
        }
        return $return;
}

#------------------------------#
# CompareRDATA_AAAA            #
#------------------------------#
sub CompareRDATA_AAAA($$$) {
        my ( $target_ref, $expected_ref,$pbuf_ref ) = @_;
        return CompareRDATA_A( $target_ref, $expected_ref,$pbuf_ref );
}

#------------------------------#
# CompareRDATA_NXT             #
#------------------------------#
sub CompareRDATA_NXT($$$) {
        my ( $target_ref, $expected_ref,$pbuf_ref ) = @_;
        my $return = $TRUE;
        if ( CompareCompressedValue( 'next', $target_ref, $expected_ref,$pbuf_ref ) ==
                $FALSE )
        {
                $return = $FALSE;
        }
        if (
                CompareValue(
                        'bitmap',
                        unpack( "H*", $target_ref->{'bitmap'} ),
                        $expected_ref->{'bitmap'},$pbuf_ref
                ) == $FALSE
          )
        {
                $return = $FALSE;
        }
        return $return;
}

#------------------------------#
# CompareRDATA_SRV             #
#------------------------------#
sub CompareRDATA_SRV($$$) {
        my ( $target_ref, $expected_ref,$pbuf_ref ) = @_;
        my $return   = $TRUE;
        my %srv_hash = (
                'target'   => 1,
                'priority' => 0,
                'weight'   => 0,
                'port'     => 0,
        );
        my $result;

        unless ( ( ref $expected_ref ) eq ( ref $target_ref ) ) {
                return $FALSE;
        }

        foreach my $key ( keys %srv_hash ) {
                if ( $srv_hash{$key} > 0 ) {
                        $result =
                          CompareCompressedValue( $key, $target_ref,
                                $expected_ref,$pbuf_ref );
                } else {
                        $result =
                          CompareValue( $key, $target_ref->{$key},
                                $expected_ref->{$key},$pbuf_ref );
                }
                if ( $result == $FALSE ) {
                        $return = $FALSE;
                }
        }
        return $return;
}

#------------------------------#
# CompareRDATA_NAPTR           #
#------------------------------#
sub CompareRDATA_NAPTR($$$) {
        my ( $target_ref, $expected_ref,$pbuf_ref ) = @_;
        my $return = $TRUE;

        unless ( ( ref $expected_ref ) eq ( ref $target_ref ) ) {
                return $FALSE;
        }
        if (
                CompareCompressedValue( 'replacement', $target_ref,
                        $expected_ref,$pbuf_ref ) == $FALSE
          )
        {
                $return = $FALSE;
        }
        if (
                CompareValue(
                        'preference',
                        $target_ref->{'preference'},
                        $expected_ref->{'preference'},$pbuf_ref
                ) == $FALSE
          )
        {
                $return = $FALSE;
        }

        foreach my $key ( 'flags', 'services', 'regexp' ) {
                my $result = undef;
                if ( ( ref $expected_ref->{$key} ) eq 'HASH' ) {
                        $result = CompareValue(
                                $key,
                                $target_ref->{$key}->{'string'},
                                $expected_ref->{$key}->{'string'},$pbuf_ref
                        );
                } else {
                        $result =
                          CompareValue( $key, $target_ref->{$key}->{'string'},
                                $expected_ref->{$key},$pbuf_ref );
                }
                if ( $result == $FALSE ) {
                        $return = $FALSE;
                }
        }
        return $return;
}

#------------------------------#
# CompareRDATA_OPT             #
#------------------------------#
sub CompareRDATA_OPT($$$) {
        my ( $target_ref, $expected_ref,$pbuf_ref ) = @_;
        my $return       = $TRUE;
        my @target_array = undef;

        if ( ( ref $target_ref ) eq 'HASH' ) {
                @target_array = @{ $target_ref->{'options'} };
        }
        my @expected_array = undef;
        if ( ( ref $expected_ref ) eq 'HASH' ) {
                @expected_array = @{ $expected_ref->{'options'} };
        } elsif ( ( ref $expected_ref ) eq 'ARRAY' ) {
                @expected_array = @$expected_ref;
        }
        my $result = undef;
	if($#expected_array >= 0 && $#target_array > 0){
		if ( $#expected_array != $#target_array ) {
			Debug_Print("NG\tOPT size: "
				    . "(rcv:$#target_array, exp:$#expected_array)\n" );
			return $FALSE;
		}
	}
        for ( my $i = 0 ; $i <= $#expected_array ; $i++ ) {
                $result = CompareValue(
                        'code',
                        $target_array[$i]->{'code'},
                        $expected_array[$i]->{'code'},$pbuf_ref
                );
                if ( $result == $FALSE ) {
                        $return = $FALSE;
                }
                $result = CompareValue(
                        'length',
                        $target_array[$i]->{'length'},
                        $expected_array[$i]->{'length'},$pbuf_ref
                );
                if ( $result == $FALSE ) {
                        $return = $FALSE;
                }
                $result = CompareValue(
                        'data',
                        $target_array[$i]->{'data'},
                        $expected_array[$i]->{'data'},$pbuf_ref
                );
                if ( $result == $FALSE ) {
                        $return = $FALSE;
                }
        }
        return $return;
}

################################################################
# DNSRemote()
################################################################
sub DNSRemote($$){
        my ($remote_file,$config_ref) = @_;

	my $ret = undef;
	my @argument = ();
	foreach my $argkey (keys %{$config_ref}){
		push(@argument ,"$argkey=$config_ref->{$argkey}");
	}

	$ret = undef;
	
	if(defined($config_ref->{'ModeRemoteAsync'})){
		$ret = kRemoteAsync("$remote_file","",@argument);
	}else{
		$ret = kRemote("$remote_file","",@argument);
	}
	
	if($ret != 0){
		return undef;
	}
	return $ret;
}

################################################################
# RemoteAsyncWait()
################################################################
sub RemoteAsyncWait(){
	return kRemoteAsyncWait();
}

################################################################
# RegistKoiSigHandler()
################################################################
sub RegistKoiSigHandler() {
	$SIG{CHLD} = \&kCommon::handleChildProcess;
}

################################################################
# DNSExitPass()
################################################################
sub DNSExitPass() {
        kLogHTML('OK');
        exit 1;
}

################################################################
# DNSExit()
################################################################
sub DNSExit($) {
        my ($status) = @_;
        my $status_hash = {
                     $OK => 'PASS',
		     $NOTYET => 'Not yet supported',
                     $SKIP => 'SKIP',
                     $FAIL => 'FAIL',
                     $INTERR => 'internal error',
                     };
        
        kLogHTML('<font color="green"><b>' . $status_hash->{$status} . '</b></font>');
        exit $status;
}

################################################################
# DNSExitNS()
################################################################
sub DNSExitNS() {
        kLogHTML('Not yet supported');
	exit 2;
}

################################################################
# BEGIN                                                        #
################################################################
BEGIN {
        push( @INC, '/usr/local/koi/libdata' );
        use Exporter;
        use vars qw(@ISA @EXPORT);
        @ISA    = qw(Exporter);
        @EXPORT = qw(
          $TRUE
          $FALSE
          $OK
          $FAIL
          $SKIP
          $NOTYET
          $INTERR
          $DEBUG_KOI_INFO
          $LOG_HANDLE
          $NUT_ADDR_0
          $NUT_ADDR_1
          $NUT_SV_PORT
          $NUT_CL_PORT
          $NUT_EDNS0_UDP_SIZE
          $TN_NET0_NODE0_ADDR
          $TN_NET0_NODE1_ADDR
          $TN_NET0_NODE2_ADDR
          $TN_NET0_NODE3_ADDR
          $TN_NET0_NODE4_ADDR
          $TN_NET0_NODE5_ADDR
          $TN_NET1_NODE1_ADDR
          $TN_NET1_NODE2_ADDR
          $TN_NET1_NODE3_ADDR
          $TN_NET1_NODE4_ADDR
          $TN_NET1_NODE5_ADDR
          $TN_NET1_NODE6_ADDR
          $TN_NET1_NODE7_ADDR
          $TN_NET1_NODE8_ADDR
          $TN_SV_PORT
          $TN_CL_PORT
          $TN_SIP_PORT
          $ADDR_FAMILY
          $ADDR_LENGTH
          $ADDR_TYPE
          $JUDGE_OPT_RR
          $JUDGE_NS_AAAA
          $RETRANSMIT_COUNT_CLIENT
          $RETRANSMIT_COUNT_SERVER
          $APP_TYPE
	  $DEC_MESSAGE_TYPE
          DNSExitPass
          InitDNSConf
          GenDNSMsg
          GenDNSHeader
          GenDNSQuestionSection
          GenDNSAnswerSection
          GenDNSAuthoritySection
          GenDNSAdditionalSection
          DecDNSMsg
          DecDNSHeader
          DecDNSQuestionSection
          DecDNSAnswerSection
          DecDNSAuthoritySection
          DecDNSAdditionalSection
          JudgeDNSHeader
          JudgeDNSQuestionSection
          JudgeDNSAnswerSection
          JudgeDNSAuthoritySection
          JudgeDNSAdditionalSection
          JudgeDNSRR
          DNSStartConnect
          __DNSStartSend
          DNSSend
          DNSRecv
          DNSSendRecv
          DNSCheckConnect
          Packet_Clear
          Packet_Close
          Gen_DNS_Name
          Gen_DNS_RDATA_A
          Gen_DNS_RDATA_MX
          Gen_DNS_RDATA_SOA
          Gen_DNS_RDATA_PTR
          Gen_DNS_RDATA_HINFO
          Gen_DNS_RDATA_WKS
          Gen_DNS_RDATA_TXT
          Gen_DNS_RDATA_AAAA
          Gen_DNS_RDATA_OPT
          Gen_DNS_RDATA_SRV
          Gen_DNS_RDATA_NAPTR
          Debug_Print
          Debug_Printf
          Print_Message
          JudgeDNSMsg
          DNSRemote
          DNSExit
          RemoteAsyncWait
	  RegistKoiSigHandler
        );

	InitDNSConf("void");

	$APP_TYPE = undef;
	# XYZ $DEC_MESSAGE_TYPE paremeter is temporary.
	$DEC_MESSAGE_TYPE = undef;

	CheckDNSConfig();
}

################################################################
# END                                                          #
################################################################
END {
}

1;

__END__
########################################################################

=head1 NAME

=begin html
<PRE>
	<A HREF="./DNS.pm">DNS.pm</A> - utility functions for DNS test
</PRE>

=end html

=head1 SYNOPSIS


=head1 DESCRIPTION

	DNSExitPass() - return status code

=cut
