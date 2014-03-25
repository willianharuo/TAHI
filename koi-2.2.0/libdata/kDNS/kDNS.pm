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
# $TAHI: koi/libdata/kDNS/kDNS.pm,v 1.76 2006/06/26 01:12:36 akisada Exp $
#
# $Id: kDNS.pm,v 1.3 2008/06/03 07:39:59 akisada Exp $
#

package kDNS;

# use strict;
use Exporter;
use File::Basename;

@ISA = qw(Exporter);
@EXPORT = qw(
	kDump_DNS_Error

	kGen_DNS_Name
	kDec_DNS_Name

	kGen_DNS_String
	kDec_DNS_String

	kGen_DNS_Header
	kDec_DNS_Header

	kGen_DNS_Question
	kDec_DNS_Question

	kGen_DNS_RR
	kDec_DNS_RR
	kDec_DNS_RR_XYZ

	kGen_DNS_RDATA_A
	kDec_DNS_RDATA_A

	kGen_DNS_RDATA_NS
	kDec_DNS_RDATA_NS

	kGen_DNS_RDATA_MD
	kDec_DNS_RDATA_MD

	kGen_DNS_RDATA_MF
	kDec_DNS_RDATA_MF

	kGen_DNS_RDATA_CNAME
	kDec_DNS_RDATA_CNAME

	kGen_DNS_RDATA_SOA
	kDec_DNS_RDATA_SOA

	kGen_DNS_RDATA_MB
	kDec_DNS_RDATA_MB

	kGen_DNS_RDATA_MG
	kDec_DNS_RDATA_MG

	kGen_DNS_RDATA_MR
	kDec_DNS_RDATA_MR

	kGen_DNS_RDATA_NULL
	kDec_DNS_RDATA_NULL

	kGen_DNS_RDATA_WKS
	kDec_DNS_RDATA_WKS

	kGen_DNS_RDATA_PTR
	kDec_DNS_RDATA_PTR

	kGen_DNS_RDATA_HINFO
	kDec_DNS_RDATA_HINFO

	kGen_DNS_RDATA_MINFO
	kDec_DNS_RDATA_MINFO

	kGen_DNS_RDATA_MX
	kDec_DNS_RDATA_MX

	kGen_DNS_RDATA_TXT
	kDec_DNS_RDATA_TXT

	kGen_DNS_RDATA_SIG
	kDec_DNS_RDATA_SIG

	kGen_DNS_RDATA_KEY
	kDec_DNS_RDATA_KEY

	kGen_DNS_RDATA_AAAA
	kDec_DNS_RDATA_AAAA

	kGen_DNS_RDATA_NXT
	kDec_DNS_RDATA_NXT

	kGen_DNS_RDATA_SRV
	kDec_DNS_RDATA_SRV

	kGen_DNS_RDATA_NAPTR
	kDec_DNS_RDATA_NAPTR

	kGen_DNS_RDATA_OPT
	kDec_DNS_RDATA_OPT

	kGen_DNS_RDATA_OPT_OPTION
	kDec_DNS_RDATA_OPT_OPTION

	kRegistSocketID
	kSwitchFrameID
	kCompileDNSMsg
	kDecompileDNSMsg

	kPrint_DNS
);

sub kInit_DNS_Error();
sub kReg_DNS_Error($$$$);
sub kDump_DNS_Error();

sub kGen_DNS_Name($;$);
sub kDec_DNS_Name($;$);

sub kGen_DNS_String($$);
sub kDec_DNS_String($;$);

sub kGen_DNS_Header($$$$$$$$$$$$$$$);
sub kDec_DNS_Header($;$);

sub kGen_DNS_Question($$$);
sub kDec_DNS_Question($;$);

sub kGen_DNS_RR($$$$$$);
sub kDec_DNS_RR($;$);

sub kGen_DNS_RDATA_A($);		# TYPE: 1
sub kDec_DNS_RDATA_A($;$);

sub kGen_DNS_RDATA_NS($);		# TYPE: 2
sub kDec_DNS_RDATA_NS($;$);

sub kGen_DNS_RDATA_MD($);		# TYPE: 3
sub kDec_DNS_RDATA_MD($;$);

sub kGen_DNS_RDATA_MF($);		# TYPE: 4
sub kDec_DNS_RDATA_MF($;$);

sub kGen_DNS_RDATA_CNAME($);		# TYPE: 5
sub kDec_DNS_RDATA_CNAME($;$);

sub kGen_DNS_RDATA_SOA($$$$$$$);	# TYPE: 6
sub kDec_DNS_RDATA_SOA($;$);

sub kGen_DNS_RDATA_MB($);		# TYPE: 7
sub kDec_DNS_RDATA_MB($;$);

sub kGen_DNS_RDATA_MG($);		# TYPE: 8
sub kDec_DNS_RDATA_MG($;$);

sub kGen_DNS_RDATA_MR($);		# TYPE: 9
sub kDec_DNS_RDATA_MR($;$);

sub kGen_DNS_RDATA_NULL($);		# TYPE: 10
sub kDec_DNS_RDATA_NULL($$;$);

sub kGen_DNS_RDATA_WKS($$$);		# TYPE: 11
sub kDec_DNS_RDATA_WKS($$;$);

sub kGen_DNS_RDATA_PTR($);		# TYPE: 12
sub kDec_DNS_RDATA_PTR($;$);

sub kGen_DNS_RDATA_HINFO($$);		# TYPE: 13
sub kDec_DNS_RDATA_HINFO($;$);

sub kGen_DNS_RDATA_MINFO($$);		# TYPE: 14
sub kDec_DNS_RDATA_MINFO($;$);

sub kGen_DNS_RDATA_MX($$);		# TYPE: 15
sub kDec_DNS_RDATA_MX($;$);

sub kGen_DNS_RDATA_TXT(@);		# TYPE: 16
sub kDec_DNS_RDATA_TXT($$;$);

sub kGen_DNS_RDATA_SIG($$$$$$$$$);	# TYPE: 24
sub kDec_DNS_RDATA_SIG($$;$);

sub kGen_DNS_RDATA_KEY($$$$$$$$$$);	# TYPE: 25
sub kDec_DNS_RDATA_KEY($$;$);

sub kGen_DNS_RDATA_AAAA($);		# TYPE: 28
sub kDec_DNS_RDATA_AAAA($;$);

sub kGen_DNS_RDATA_NXT($$);		# TYPE: 30
sub kDec_DNS_RDATA_NXT($$;$);

sub kGen_DNS_RDATA_SRV($$$$);		# TYPE: 33
sub kDec_DNS_RDATA_SRV($;$);

sub kGen_DNS_RDATA_NAPTR($$$$$$);	# TYPE: 35
sub kDec_DNS_RDATA_NAPTR($;$);

sub kGen_DNS_RDATA_OPT(@);		# TYPE: 41
sub kDec_DNS_RDATA_OPT($$;$);

sub kGen_DNS_RDATA_OPT_OPTION($$$);
sub kDec_DNS_RDATA_OPT_OPTION($;$);

sub kRegistSocketID($$);
sub kSwitchFrameID($$);
sub kCompileDNSMsg($$);
sub kDecompileDNSMsg($$);

sub kPrint_DNS($;$);

# internal use
sub kPrint_Header($;$);
sub kPrint_Question($$;$);
sub kPrint_Answer($$;$);
sub kPrint_Authority($$;$);
sub kPrint_Additional($$;$);
sub kPrint_RR($$;$);
sub kPrint_RDATA($$$;$);
sub kPrint_RDATA_A($;$);
sub kPrint_RDATA_NS($;$);
sub kPrint_RDATA_MD($;$);
sub kPrint_RDATA_MF($;$);
sub kPrint_RDATA_CNAME($;$);
sub kPrint_RDATA_SOA($;$);
sub kPrint_RDATA_MB($;$);
sub kPrint_RDATA_MG($;$);
sub kPrint_RDATA_MR($;$);
sub kPrint_RDATA_NULL($$;$);
sub kPrint_RDATA_WKS($$;$);
sub kPrint_RDATA_PTR($;$);
sub kPrint_RDATA_HINFO($;$);
sub kPrint_RDATA_MINFO($;$);
sub kPrint_RDATA_MX($;$);
sub kPrint_RDATA_TXT($$;$);
sub kPrint_RDATA_SIG($$;$);
sub kPrint_RDATA_KEY($$;$);
sub kPrint_RDATA_AAAA($;$);
sub kPrint_RDATA_NXT($$;$);
sub kPrint_RDATA_SRV($;$);
sub kPrint_RDATA_NAPTR($;$);
sub kPrint_RDATA_OPT($$;$);



#----------------------------------------------------------------------#
# kInit_DNS_Error()                                                    #
#----------------------------------------------------------------------#
sub
kInit_DNS_Error()
{
	@strerror = ();

	return(undef);
}



#----------------------------------------------------------------------#
# kReg_DNS_Error()                                                     #
#----------------------------------------------------------------------#
sub
kReg_DNS_Error($$$$)
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
# kDump_DNS_Error()                                                    #
#----------------------------------------------------------------------#
sub
kDump_DNS_Error()
{
	my $str = undef;

	foreach my $error (@strerror) {
		unless(defined($str)) {
			$str = '';
		}

		$str .= "$error->{'file'}: ";
		$str .= "$error->{'line'}: ";
		$str .= "kDNS::$error->{'function'}(): ";
		$str .= "$error->{'string'}";
		$str .= "\n";
	}

	kInit_DNS_Error();

	return($str);
}



#----------------------------------------------------------------------#
# kGen_DNS_Name()                                                      #
#----------------------------------------------------------------------#
sub
kGen_DNS_Name($;$)
{
	my ($name, $offset) = @_;

	kInit_DNS_Error();

	my $domain_name = '';

	my $_name_ = defined($name)? $name: '.';

	my @names = split(/\./, $_name_);

	foreach my $lavel (@names) {
		my $lavellen = length($lavel);

		$domain_name .= pack('C a*', $lavellen, $lavel);
	}

	if(defined($offset)) {
		$domain_name .= pack('n', 0xc000 | $offset);
	} else {
		$domain_name .= pack('C', 0);
	}

	return($domain_name);
}



#----------------------------------------------------------------------#
# kDec_DNS_Name()                                                      #
#----------------------------------------------------------------------#
sub
kDec_DNS_Name($;$)
{
	my (
		$data,
		$offset
	) = @_;

	my $function = 'kDec_DNS_Name';
	kInit_DNS_Error();

	my $datalen        = length($data);
	my $_offset_       = defined($offset)? $offset: 0;

	my $_compressed_   = undef;
	my $_pointer_      = undef;
	my $_decompressed_ = undef;

	for( ; ; ) {
		if($_offset_ + 1 > $datalen) {
			$_offset_ ++;

			kReg_DNS_Error(__FILE__, __LINE__, $function,
				"\$datalen: $datalen".
					" -- requires $_offset_ bytes.");

			return(undef);
		}

		my $labellen = unpack("\@$_offset_ C", $data);
		$_offset_ ++;

		unless($labellen) {
			last;
		}

		if(($labellen & 0xc0) == 0xc0) {
			if($_offset_ + 1 > $datalen) {
				$_offset_ ++;

				kReg_DNS_Error(__FILE__, __LINE__, $function,
					"\$datalen: $datalen".
					" -- requires $_offset_ bytes.");

				return(undef);
			}

			$_offset_ --;
			$_pointer_  = unpack("\@$_offset_ n", $data);
			$_pointer_ &= 0x3fff;
			$_offset_ += 2;

			my $decompressed = kDec_DNS_Name($data, $_pointer_);

			unless(defined($decompressed)) {
				kReg_DNS_Error(__FILE__, __LINE__, $function,
					"kDec_DNS_Name: decode failure.");

				return(undef);
			}

			$_decompressed_  = $_compressed_;
			$_decompressed_ .=
				defined($decompressed->{'offset'})?
					$decompressed->{'decompressed'}:
						$decompressed->{'compressed'};

			last;
		}

		if($_offset_ + $labellen > $datalen) {
			$_offset_ += $labellen;

			kReg_DNS_Error(__FILE__, __LINE__, $function,
				"\$datalen: $datalen".
					" -- requires $_offset_ bytes.");

			return(undef);
		}

		my $label = substr($data, $_offset_, $labellen);
		unless(defined($_compressed_)) {
			$_compressed_ = '';
		}

		$_compressed_ .= $label;
		$_compressed_ .= '.';

		$_offset_ += $labellen;
	}

	my $_size_ = $_offset_ - $offset;

	return(
		{
			'_size_'       => $_size_,
			'compressed'   => $_compressed_,
			'offset'       => $_pointer_,
			'decompressed' => $_decompressed_
		}
	);
}



#----------------------------------------------------------------------#
# kGen_DNS_String()                                                    #
#----------------------------------------------------------------------#
sub
kGen_DNS_String($$)
{
	my ($length, $string) = @_;

	kInit_DNS_Error();

	my $_string_ = defined($string)? $string: '';
	my $_length_ = defined($length)? $length: length($_string_);

	return(pack('C a*', $_length_, $_string_));
}



#----------------------------------------------------------------------#
# kDec_DNS_String()                                                    #
#----------------------------------------------------------------------#
sub
kDec_DNS_String($;$)
{
	my (
		$data,
		$offset
	) = @_;

	my $function = 'kDec_DNS_String';
	kInit_DNS_Error();

	my $datalen  = length($data);
	my $_offset_ = defined($offset)? $offset: 0;

	my $_string_ = undef;

	if($_offset_ + 1 > $datalen) {
		$_offset_ ++;

		kReg_DNS_Error(__FILE__, __LINE__, $function,
			"\$datalen: $datalen".
				" -- requires $_offset_ bytes.");

		return(undef);
	}

	my $strlen = unpack("\@$_offset_ C", $data);
	$_offset_ ++;

	if($strlen) {
		if($_offset_ + $strlen > $datalen) {
			$_offset_ += $strlen;

			kReg_DNS_Error(__FILE__, __LINE__, $function,
				"\$datalen: $datalen".
					" -- requires $_offset_ bytes.");

			return(undef);
		}

		$_string_ = substr($data, $_offset_, $strlen);
		$_offset_ += $strlen;
	}

	my $_size_ = $_offset_ - $offset;

	return(
		{
			'_size_' => $_size_,
			'length' => $strlen,
			'string' => $_string_
		}
	);
}



#----------------------------------------------------------------------#
# kGen_DNS_Header()                                                    #
#----------------------------------------------------------------------#
sub
kGen_DNS_Header($$$$$$$$$$$$$$$)
{
	my ($id, $qr, $opcode, $aa, $tc, $rd, $ra, $z, $ad, $cd, $rcode,
		$qdcount, $ancount, $nscount, $arcount) = @_;

	kInit_DNS_Error();

	my $_id_      = defined($id)?      $id:      0;
	my $_qr_      = defined($qr)?      $qr:      0;
	my $_opcode_  = defined($opcode)?  $opcode:  0;
	my $_aa_      = defined($aa)?      $aa:      0;
	my $_tc_      = defined($tc)?      $tc:      0;
	my $_rd_      = defined($rd)?      $rd:      0;
	my $_ra_      = defined($ra)?      $ra:      0;
	my $_z_       = defined($z)?       $z:       0;
	my $_ad_      = defined($ad)?      $ad:      0;
	my $_cd_      = defined($cd)?      $cd:      0;
	my $_rcode_   = defined($rcode)?   $rcode:   0;
	my $_qdcount_ = defined($qdcount)? $qdcount: 0;
	my $_ancount_ = defined($ancount)? $ancount: 0;
	my $_nscount_ = defined($nscount)? $nscount: 0;
	my $_arcount_ = defined($arcount)? $arcount: 0;

	my $_byte2_ =
		$_qr_     << 7  |
		$_opcode_ << 3  |
		$_aa_     << 2  |
		$_tc_     << 1  |
		$_rd_;

	my $_byte3_ =
		$_ra_     << 7  |
		$_z_      << 6  |
		$_ad_     << 5  |
		$_cd_     << 4  |
		$_rcode_;

	return(pack('n C2 n4', $_id_, $_byte2_, $_byte3_,
		$_qdcount_, $_ancount_, $_nscount_, $_arcount_));
}



#----------------------------------------------------------------------#
# kDec_DNS_Header()                                                    #
#----------------------------------------------------------------------#
sub
kDec_DNS_Header($;$)
{
	my ($data, $offset) = @_;

	my $function = 'kDec_DNS_Header';
	kInit_DNS_Error();

	my $size = 12;

	my $datalen = length($data);
	my $_offset_ = defined($offset)? $offset: 0;

	if($_offset_ + $size > $datalen) {
		kReg_DNS_Error(__FILE__, __LINE__, $function,
			"\$datalen: $datalen -- requires $size bytes.");

		return(undef);
	}

	my @member = unpack("\@$_offset_ n C2 n4", $data);

	my $id      =  $member[0];

	my $qr      = ($member[1] >> 7) & 0x1;
	my $opcode  = ($member[1] >> 3) & 0xf;
	my $aa      = ($member[1] >> 2) & 0x1;
	my $tc      = ($member[1] >> 1) & 0x1;
	my $rd      =  $member[1]       & 0x1;

	my $ra      = ($member[2] >> 7) & 0x1;
	my $z       = ($member[2] >> 6) & 0x1;
	my $ad      = ($member[2] >> 5) & 0x1;
	my $cd      = ($member[2] >> 4) & 0x1;
	my $rcode   =  $member[2]       & 0xf;

	my $qdcount =  $member[3];
	my $ancount =  $member[4];
	my $nscount =  $member[5];
	my $arcount =  $member[6];

	return(
		{
			'_size_'  => $size,
			'id'      => $id,
			'qr'      => $qr,
			'opcode'  => $opcode,
			'aa'      => $aa,
			'tc'      => $tc,
			'rd'      => $rd,
			'ra'      => $ra,
			'z'       => $z,
			'ad'      => $ad,
			'cd'      => $cd,
			'rcode'   => $rcode,
			'qdcount' => $qdcount,
			'ancount' => $ancount,
			'nscount' => $nscount,
			'arcount' => $arcount
		}
	);
}



#----------------------------------------------------------------------#
# kGen_DNS_Question()                                                  #
#----------------------------------------------------------------------#
sub
kGen_DNS_Question($$$)
{
	my ($qname, $qtype, $qclass) = @_;

	kInit_DNS_Error();

	my $_qname_  = defined($qname)?  $qname:  kGen_DNS_Name(undef);
	my $_qtype_  = defined($qtype)?  $qtype:  0;
	my $_qclass_ = defined($qclass)? $qclass: 0;

	return($_qname_. pack('n2', $_qtype_, $_qclass_));
}



#----------------------------------------------------------------------#
# kDec_DNS_Question()                                                  #
#----------------------------------------------------------------------#
sub
kDec_DNS_Question($;$)
{
	my ($data, $offset) = @_;

	my $function = 'kDec_DNS_Question';
	kInit_DNS_Error();

	my $datalen  = length($data);
	my $_offset_ = defined($offset)? $offset: 0;

	my $_qname_  = kDec_DNS_Name($data, $_offset_);
	unless(defined($_qname_)) {
		kReg_DNS_Error(__FILE__, __LINE__, $function,
			"QNAME: decode failure.");

		return(undef);
	}

	my $_size_ = $_qname_->{'_size_'};
	$_offset_ += $_size_;

	$_size_   += 4;	# QTYPE(2) + QCLASS(2)

	if($datalen - $_offset_ < 4) {
		kReg_DNS_Error(__FILE__, __LINE__, $function,
			"\$datalen: $datalen -- requires $_size_ bytes.");

		return(undef);
	}

	my @member   = unpack("\@$_offset_ n2", $data);
	my $_qtype_  = $member[0];
	my $_qclass_ = $member[1];

	return(
		{
			'_size_' => $_size_,
			'qname'  => $_qname_,
			'qtype'  => $_qtype_,
			'qclass' => $_qclass_
		}
	);
}



#----------------------------------------------------------------------#
# kGen_DNS_RR()                                                        #
#----------------------------------------------------------------------#
sub
kGen_DNS_RR($$$$$$)
{
	my ($name, $type, $class, $ttl, $rdlength, $rdata) = @_;

	my $function = 'kGen_DNS_RR';
	kInit_DNS_Error();

	my $_name_      = defined($name)?     $name:     kGen_DNS_Name(undef);
	my $_type_      = defined($type)?     $type:     0;
	my $_class_     = defined($class)?    $class:    0;
	my $_ttl_       = defined($ttl)?      $ttl:      0;
	my $_rdata_     = defined($rdata)?    $rdata:    '';
	my $_rdlength_  = defined($rdlength)? $rdlength: length($rdata);

	my $_rr_  = $_name_;
	   $_rr_ .= pack('n2 N n', $_type_, $_class_, $_ttl_, $_rdlength_);
	   $_rr_ .= $_rdata_;

	return($_rr_);
}



#----------------------------------------------------------------------#
# kDec_DNS_RR()                                                        #
#----------------------------------------------------------------------#
sub
kDec_DNS_RR($;$)
{
	my ($data, $offset) = @_;

	my $function = 'kDec_DNS_RR';
	kInit_DNS_Error();

	my $datalen  = length($data);
	my $_offset_ = defined($offset)? $offset: 0;

	my $_name_   = kDec_DNS_Name($data, $_offset_);
	unless(defined($_name_)) {
		kReg_DNS_Error(__FILE__, __LINE__, $function,
			"NAME: decode failure.");

		return(undef);
	}

	my $_size_ = $_name_->{'_size_'};
	$_offset_ += $_size_;

	$_size_   += 10;	# TYPE(2) + CLASS(2) + TTL(4) + RDLENGTH(2)

	if($datalen - $_offset_ < 10) {
		kReg_DNS_Error(__FILE__, __LINE__, $function,
			"\$datalen: $datalen -- requires $_size_ bytes.");

		return(undef);
	}

	my @member     = unpack("\@$_offset_ n2 N n", $data);
	my $_type_     = $member[0];
	my $_class_    = $member[1];
	my $_ttl_      = $member[2];
	my $_rdlength_ = $member[3];

	$_offset_ += 10;
	$_size_   += $_rdlength_;

	my $_rdata_    =
		$_rdlength_? unpack("\@$_offset_ a$_rdlength_", $data): 0;

	return(
		{
			'_size_'   => $_size_,
			'name'     => $_name_,
			'type'     => $_type_,
			'class'    => $_class_,
			'ttl'      => $_ttl_,
			'rdlength' => $_rdlength_,
			'rdata'    => $_rdata_
		}
	);
}



#----------------------------------------------------------------------#
# kDec_DNS_RR_XYZ()                                                    #
#----------------------------------------------------------------------#
sub
kDec_DNS_RR_XYZ($;$)
{
	my ($data, $offset) = @_;

	my $function = 'kDec_DNS_RR_XYZ';
	kInit_DNS_Error();

	my $datalen  = length($data);
	my $_offset_ = defined($offset)? $offset: 0;

	my $_name_   = kDec_DNS_Name($data, $_offset_);
	unless(defined($_name_)) {
		kReg_DNS_Error(__FILE__, __LINE__, $function,
			"NAME: decode failure.");

		return(undef);
	}

	my $_size_ = $_name_->{'_size_'};
	$_offset_ += $_size_;

	$_size_   += 10;	# TYPE(2) + CLASS(2) + TTL(4) + RDLENGTH(2)

	if($datalen - $_offset_ < 10) {
		kReg_DNS_Error(__FILE__, __LINE__, $function,
			"\$datalen: $datalen -- requires $_size_ bytes.");

		return(undef);
	}

	my @member     = unpack("\@$_offset_ n2 N n", $data);
	my $_type_     = $member[0];
	my $_class_    = $member[1];
	my $_ttl_      = $member[2];
	my $_rdlength_ = $member[3];

	$_offset_ += 10;
	$_size_   += $_rdlength_;

	my $_rdata_ = kDec_RDATA($_type_, $data, $_offset_, $_rdlength_);

	return(
		{
			'_size_'   => $_size_,
			'name'     => $_name_,
			'type'     => $_type_,
			'class'    => $_class_,
			'ttl'      => $_ttl_,
			'rdlength' => $_rdlength_,
			'rdata'    => $_rdata_
		}
	);
}



#----------------------------------------------------------------------#
# kGen_DNS_RDATA_A()                                                   #
#----------------------------------------------------------------------#
sub
kGen_DNS_RDATA_A($)
{
	my ($address) = @_;

	kInit_DNS_Error();

        my $_address_ = defined($address)? $address: '0.0.0.0';

	if($_address_ =~ /^\s*([0-9\.]+)\s*$/) {
		my @elements = split(/\./, $1);

		$_rdata_ = pack('C4', @elements);
	} else {
	        return(undef);
	}

        return($_rdata_);
}



#----------------------------------------------------------------------#
# kDec_DNS_RDATA_A()                                                   #
#----------------------------------------------------------------------#
sub
kDec_DNS_RDATA_A($;$)
{
	my ($data, $offset) = @_;

	my $function = 'kDec_DNS_RDATA_A';
	kInit_DNS_Error();

	my $datalen  = length($data);
	my $_offset_ = defined($offset)? $offset: 0;

	my $size = 4;
	if($_offset_ + $size > $datalen) {
		kReg_DNS_Error(__FILE__, __LINE__, $function,
			"\$data -- requires $size bytes.");

		return(undef);
	}

	my @elements = unpack("\@$_offset_ C4", $data);
	my $_address_ = sprintf('%d.%d.%d.%d',
		$elements[0], $elements[1],
		$elements[2], $elements[3]);

	return(
		{
			'_size_'  => $size,
			'address' => $_address_
		}
	);
}



#----------------------------------------------------------------------#
# kGen_DNS_RDATA_NS()                                                  #
#----------------------------------------------------------------------#
sub
kGen_DNS_RDATA_NS($)
{
	my ($nsdname) = @_;
	return($nsdname);
}



#----------------------------------------------------------------------#
# kDec_DNS_RDATA_NS()                                                  #
#----------------------------------------------------------------------#
sub
kDec_DNS_RDATA_NS($;$)
{
	my ($data, $offset) = @_;

	my $function = 'kDec_DNS_RDATA_NS';
	kInit_DNS_Error();

	my $_offset_ = defined($offset)? $offset: 0;

	my $_nsdname_ = kDec_DNS_Name($data, $_offset_);
	unless(defined($_nsdname_)) {
		kReg_DNS_Error(__FILE__, __LINE__, $function,
			"NSDNAME: decode failure.");

		return(undef);
	}

	return(
		{
			'_size_'  => $_nsdname_->{'_size_'},
			'nsdname' => $_nsdname_
		}
	);
}



#----------------------------------------------------------------------#
# kGen_DNS_RDATA_MD()                                                  #
#----------------------------------------------------------------------#
sub
kGen_DNS_RDATA_MD($)
{
	my ($madname) = @_;
	return($madname);
}



#----------------------------------------------------------------------#
# kDec_DNS_RDATA_MD()                                                  #
#----------------------------------------------------------------------#
sub
kDec_DNS_RDATA_MD($;$)
{
	my ($data, $offset) = @_;

	my $function = 'kDec_DNS_RDATA_MD';
	kInit_DNS_Error();

	my $_offset_ = defined($offset)? $offset: 0;

	my $_madname_ = kDec_DNS_Name($data, $_offset_);
	unless(defined($_madname_)) {
		kReg_DNS_Error(__FILE__, __LINE__, $function,
			"NSDNAME: decode failure.");

		return(undef);
	}

	return(
		{
			'_size_'  => $_madname_->{'_size_'},
			'madname' => $_madname_
		}
	);
}



#----------------------------------------------------------------------#
# kGen_DNS_RDATA_MF()                                                  #
#----------------------------------------------------------------------#
sub
kGen_DNS_RDATA_MF($)
{
	my ($madname) = @_;
	return($madname);
}



#----------------------------------------------------------------------#
# kDec_DNS_RDATA_MF()                                                  #
#----------------------------------------------------------------------#
sub
kDec_DNS_RDATA_MF($;$)
{
	my ($data, $offset) = @_;

	my $function = 'kDec_DNS_RDATA_MF';
	kInit_DNS_Error();

	my $_offset_ = defined($offset)? $offset: 0;

	my $_madname_ = kDec_DNS_Name($data, $_offset_);
	unless(defined($_madname_)) {
		kReg_DNS_Error(__FILE__, __LINE__, $function,
			"NSDNAME: decode failure.");

		return(undef);
	}

	return(
		{
			'_size_'  => $_madname_->{'_size_'},
			'madname' => $_madname_
		}
	);
}



#----------------------------------------------------------------------#
# kGen_DNS_RDATA_CNAME()                                               #
#----------------------------------------------------------------------#
sub
kGen_DNS_RDATA_CNAME($)
{
	my ($cname) = @_;
	return($cname);
}



#----------------------------------------------------------------------#
# kDec_DNS_RDATA_CNAME()                                               #
#----------------------------------------------------------------------#
sub
kDec_DNS_RDATA_CNAME($;$)
{
	my ($data, $offset) = @_;

	my $function = 'kDec_DNS_RDATA_CNAME';
	kInit_DNS_Error();

	my $_offset_ = defined($offset)? $offset: 0;

	my $_cname_ = kDec_DNS_Name($data, $_offset_);
	unless(defined($_cname_)) {
		kReg_DNS_Error(__FILE__, __LINE__, $function,
			"NSDNAME: decode failure.");

		return(undef);
	}

	return(
		{
			'_size_' => $_cname_->{'_size_'},
			'cname'  => $_cname_
		}
	);
}



#----------------------------------------------------------------------#
# kGen_DNS_RDATA_SOA()                                                 #
#----------------------------------------------------------------------#
sub
kGen_DNS_RDATA_SOA($$$$$$$)
{
	my ($mname, $rname, $serial, $refresh, $retry, $expire, $minimum) = @_;

#	return($mname. $rname.
#		pack('N5', $serial, $refresh, $retry, $expire, $minimum));
	return(pack('a* a* N5',
		$mname, $rname, $serial, $refresh, $retry, $expire, $minimum));
}



#----------------------------------------------------------------------#
# kDec_DNS_RDATA_SOA()                                                 #
#----------------------------------------------------------------------#
sub
kDec_DNS_RDATA_SOA($;$)
{

	my ($data, $offset) = @_;

	my $function = 'kDec_DNS_RDATA_SOA';
	kInit_DNS_Error();

	my $datalen = length($data);
	my $_offset_ = defined($offset) ? $offset : 0;

	my $_mname_ = kDec_DNS_Name($data, $_offset_);
	unless(defined($_mname_)) {
		kReg_DNS_Error(__FILE__, __LINE__, $function,
			"MNAME: decode failure.");

		return(undef);
	}

	$_offset_ += $_mname_->{'_size_'};

	my $_rname_ = kDec_DNS_Name($data, $_offset_);
	unless(defined($_rname_)) {
		kReg_DNS_Error(__FILE__, __LINE__, $function,
			"RNAME: decode failure.");

		return(undef);
	}
	$_offset_ += $_rname_->{'_size_'};

	my $fixedsize = 20;
	if($_offset_ + $fixedsize > $datalen) {
		kReg_DNS_Error(__FILE__, __LINE__, $function,
			"\$data -- requires $fixedsize bytes.");

		return(undef);
	}

	my ($_serial_,
	    $_refresh_,
	    $_retry_,
	    $_expire_,
	    $_minimum_) = unpack("\@$_offset_ N5", $data);

	my $_size_ = $_mname_->{'_size_'} + $_rname_->{'_size_'} + $fixedsize;
	return(
		{
			'_size_'  => $_size_,
			'mname'   => $_mname_,
			'rname'   => $_rname_,
			'serial'  => $_serial_,
			'refresh' => $_refresh_,
			'retry'   => $_retry_,
			'expire'  => $_expire_,
			'minimum' => $_minimum_,
		}
	);

}



#----------------------------------------------------------------------#
# kGen_DNS_RDATA_MB()                                                  #
#----------------------------------------------------------------------#
sub
kGen_DNS_RDATA_MB($)
{
	my ($madname) = @_;
	return($madname);
}



#----------------------------------------------------------------------#
# kDec_DNS_RDATA_MB()                                                  #
#----------------------------------------------------------------------#
sub
kDec_DNS_RDATA_MB($;$)
{
	my ($data, $offset) = @_;

	my $function = 'kDec_DNS_RDATA_MB';
	kInit_DNS_Error();

	my $_offset_ = defined($offset) ? $offset : 0;

	my $_madname_ = kDec_DNS_Name($data, $_offset_);
	unless (defined($_madname_)) {
		kReg_DNS_Error(__FILE__, __LINE__, $function,
			       "MADNAME: decode failure.");
		return(undef);
	}

	my $_size_ = $_madname_->{'_size_'};
	return(
		{
			'_size_'  => $_size_,
			'madname'   => $_madname_
		}
	);
}



#----------------------------------------------------------------------#
# kGen_DNS_RDATA_MG()                                                  #
#----------------------------------------------------------------------#
sub
kGen_DNS_RDATA_MG($)
{
	my ($mgmname) = @_;
	return($mgmname);
}



#----------------------------------------------------------------------#
# kDec_DNS_RDATA_MG()                                                  #
#----------------------------------------------------------------------#
sub
kDec_DNS_RDATA_MG($;$)
{
	my ($data, $offset) = @_;

	my $function = 'kDec_DNS_RDATA_MG';
	kInit_DNS_Error();

	my $_offset_ = defined($offset) ? $offset : 0;

	my $_mgmname_ = kDec_DNS_Name($data, $_offset_);
	unless (defined($_mgmname_)) {
		kReg_DNS_Error(__FILE__, __LINE__, $function,
			       "MGMNAME: decode failure.");
		return(undef);
	}

	my $_size_ = $_mgmname_->{'_size_'};
	return(
		{
			'_size_'  => $_size_,
			'mgmname'   => $_mgmname_
		}
	);
}



#----------------------------------------------------------------------#
# kGen_DNS_RDATA_MR()                                                  #
#----------------------------------------------------------------------#
sub
kGen_DNS_RDATA_MR($)
{
	my ($newname) = @_;
	return($newname);
}



#----------------------------------------------------------------------#
# kDec_DNS_RDATA_MR()                                                  #
#----------------------------------------------------------------------#
sub
kDec_DNS_RDATA_MR($;$)
{
	my ($data, $offset) = @_;

	my $function = 'kDec_DNS_RDATA_MR';
	kInit_DNS_Error();

	my $_offset_ = defined($offset) ? $offset : 0;

	my $_newname_ = kDec_DNS_Name($data, $_offset_);
	unless (defined($_newname_)) {
		kReg_DNS_Error(__FILE__, __LINE__, $function,
			       "NEWNAME: decode failure.");
		return(undef);
	}

	my $_size_ = $_newname_->{'_size_'};
	return(
		{
			'_size_'  => $_size_,
			'newname'   => $_newname_
		}
	);
}



#----------------------------------------------------------------------#
# kGen_DNS_RDATA_NULL()                                                #
#----------------------------------------------------------------------#
sub
kGen_DNS_RDATA_NULL($)
{
	my ($data) = @_;
	return($data);
}



#----------------------------------------------------------------------#
# kDec_DNS_RDATA_NULL()                                                #
#----------------------------------------------------------------------#
sub
kDec_DNS_RDATA_NULL($$;$)
{
	my ($data, $rdlength, $offset) = @_;

	my $function = 'kDec_DNS_RDATA_NULL';
	kInit_DNS_Error();

	my $datalen = length($data);
	my $_offset_ = defined($offset) ? $offset : 0;

	if ($_offset_ + $rdlength > $datalen) {
		my $size = $_offset_ + $rdlength;
		kReg_DNS_Error(__FILE__, __LINE__, $function,
			       "\$data -- requires more than $size bytes.");
		return(undef);
	}

	my $_nulldata_ = unpack("\@$_offset_ a$rdlength", $data);

	return(
		{
			'_size_' => $rdlength,
			'data'   => $_nulldata_
		}
	);
}



#----------------------------------------------------------------------#
# kGen_DNS_RDATA_WKS()                                                 #
#----------------------------------------------------------------------#
sub
kGen_DNS_RDATA_WKS($$$)
{
	my ($address, $protocol, $bitmap) = @_;

	my @elements = split(/\./, $address);

	$_address_ = pack('C4', @elements);

	return(pack('a* C B*', $_address_, $protocol, $bitmap));
}



#----------------------------------------------------------------------#
# kDec_DNS_RDATA_WKS()                                                 #
#----------------------------------------------------------------------#
sub
kDec_DNS_RDATA_WKS($$;$)
{
	my ($data, $rdlength, $offset) = @_;

	my $function = 'kDec_DNS_RDATA_WKS';
	kInit_DNS_Error();

	my $_offset_ = defined($offset)? $offset : 0;

	my $fixedsize = 5;
	my $_bitmaplength_ = $rdlength - $fixedsize;

	my @elements = unpack("\@$_offset_ C4 C a$_bitmaplength_", $data);
	my $_address_ = sprintf('%d.%d.%d.%d',
				$elements[0], $elements[1],
				$elements[2], $elements[3]);
	my $_protocol_ = $elements[4];
	my $_data_ = $elements[5];

	return(
		{
			'_size_'  => $rdlength,
			'address' => $_address_,
			'protocol' => $_protocol_,
			'bitmap'   => $_data_
		}
	);
}



#----------------------------------------------------------------------#
# kGen_DNS_RDATA_PTR()                                                 #
#----------------------------------------------------------------------#
sub
kGen_DNS_RDATA_PTR($)
{
	my ($ptrdname) = @_;
	return($ptrdname);
}



#----------------------------------------------------------------------#
# kDec_DNS_RDATA_PTR()                                                 #
#----------------------------------------------------------------------#
sub
kDec_DNS_RDATA_PTR($;$)
{
	my ($data, $offset) = @_;

	my $function = 'kDec_DNS_RDATA_PTR';
	kInit_DNS_Error();

	my $_offset_ = defined($offset) ? $offset : 0;

	my $_ptrdname_ = kDec_DNS_Name($data, $_offset_);
	unless (defined($_ptrdname_)) {
		kReg_DNS_Error(__FILE__, __LINE__, $function,
			       "PTRDNAME: decode failure.");
		return(undef);
	}

	my $_size_ = $_ptrdname_->{'_size_'};
	return(
		{
			'_size_'  => $_size_,
			'ptrdname' => $_ptrdname_,
		}
	);
}



#----------------------------------------------------------------------#
# kGen_DNS_RDATA_HINFO()                                               #
#----------------------------------------------------------------------#
sub
kGen_DNS_RDATA_HINFO($$)
{
	my ($cpu, $os) = @_;

	my $ret = "";
        if (length($cpu) > 0) {
                $ret .= pack("C", length($cpu));
                $ret .= $cpu;
        }
        if (length($os) > 0) {
                $ret .= pack("C", length($os));
                $ret .= $os;
        }

        return $ret;
}



#----------------------------------------------------------------------#
# kDec_DNS_RDATA_HINFO()                                               #
#----------------------------------------------------------------------#
sub
kDec_DNS_RDATA_HINFO($;$)
{
	my ($data, $offset) = @_;

	my $function = 'kDec_DNS_RDATA_HINFO';
	kInit_DNS_Error();

	my $_offset_ = defined($offset) ? $offset : 0;

	my $_cpu_ = kDec_DNS_String($data, $_offset_);
	unless (defined($_cpu_)) {
		kReg_DNS_Error(__FILE__, __LINE__, $function,
			       "CPU: decode failure.");
		return(undef);
	}
	$_offset_ += $_cpu_->{'_size_'};

	my $_os_ = kDec_DNS_String($data, $_offset_);
	unless (defined($_os_)) {
		kReg_DNS_Error(__FILE__, __LINE__, $function,
			       "OS: decode failure.");
		return(undef);
	}

	my $_size_ = $_cpu_->{'_size_'} + $_os_->{'_size_'};
	return(
		{
			'_size_'  => $_size_,
			'cpu'     => $_cpu_,
			'os' => $_os_,
		}
	);

}



#----------------------------------------------------------------------#
# kGen_DNS_RDATA_MINFO()                                               #
#----------------------------------------------------------------------#
sub
kGen_DNS_RDATA_MINFO($$)
{
	my ($rmailbx, $emailbx) = @_;
	return($rmailbx. $emailbx);
}



#----------------------------------------------------------------------#
# kDec_DNS_RDATA_MINFO()                                               #
#----------------------------------------------------------------------#
sub
kDec_DNS_RDATA_MINFO($;$)
{
	my ($data, $offset) = @_;

	my $function = 'kDec_DNS_RDATA_MINFO';
	kInit_DNS_Error();

	my $_offset_ = defined($offset) ? $offset : 0;

	my $_rmailbx_ = kDec_DNS_Name($data, $_offset_);
	unless (defined($_rmailbx_)) {
		kReg_DNS_Error(__FILE__, __LINE__, $function,
			       "RMAILBX: decode failure.");
		return(undef);
	}
	$_offset_ += $_rmailbx_->{'_size_'};

	my $_emailbx_ = kDec_DNS_Name($data, $_offset_);
	unless (defined($_emailbx_)) {
		kReg_DNS_Error(__FILE__, __LINE__, $function,
			       "EMAILBX: decode failure.");
		return(undef);
	}

	my $_size_ = $_rmailbx_->{'_size_'} + $_emailbx_->{'_size_'};
	return(
	       {
			'_size_'  => $_size_,
			'rmailbx' => $_rmailbx_,
			'emailbx' => $_emailbx_,
		}
	);

}



#----------------------------------------------------------------------#
# kGen_DNS_RDATA_MX()                                                  #
#----------------------------------------------------------------------#
sub
kGen_DNS_RDATA_MX($$)
{
	my ($preference, $exchange) = @_;

	my $_mx_ = pack('n a*', $preference, $exchange);

	return($_mx_);
}



#----------------------------------------------------------------------#
# kDec_DNS_RDATA_MX()                                                  #
#----------------------------------------------------------------------#
sub
kDec_DNS_RDATA_MX($;$)
{
	my ($data, $offset) = @_;

	my $function = 'kDec_DNS_RDATA_MX';
	kInit_DNS_Error();

	my $_offset_ = defined($offset) ? $offset : 0;

	my $fixedsize = 2;
	my $_preference_ = unpack("\@$_offset_ n", $data);
	$_offset_ += $fixedsize;

	my $_exchange_ = kDec_DNS_Name($data, $_offset_);
	unless (defined($_exchange_)) {
		kReg_DNS_Error(__FILE__, __LINE__, $function,
			       "EXCHANGE: decode failure.");
		return(undef);
	}

	my $_size_ = $_exchange_->{'_size_'} + $fixedsize;

	return(
		{
			'_size_'  => $_size_,
			'preference' => $_preference_,
			'exchange'   => $_exchange_,
		}
	);

}



#----------------------------------------------------------------------#
# kGen_DNS_RDATA_TXT()                                                 #
#----------------------------------------------------------------------#
sub
kGen_DNS_RDATA_TXT(@)
{
	my (@texts) = @_;

	my $_txt_ = '';

	foreach my $txt (@texts) {
		if (length($txt) > 0) {
			$_txt_ .= pack("C", length($txt));
			$_txt_ .= $txt;
		}
	}

	return($_txt_);
}



#----------------------------------------------------------------------#
# kDec_DNS_RDATA_TXT()                                                 #
#----------------------------------------------------------------------#
sub
kDec_DNS_RDATA_TXT($$;$)
{
	my ($data, $rdlength, $offset) = @_;

	my $function = 'kDec_DNS_RDATA_TXT';
	kInit_DNS_Error();

	my $_offset_ = defined($offset) ? $offset : 0;

	my @_texts_= ();
	my $_size_ = 0;
	for ( ; $_size_ < $rdlength; ) {
		my $_text_ = kDec_DNS_String($data, $_offset_);
		unless (defined($_text_)) {
			kReg_DNS_Error(__FILE__, __LINE__, $function,
				"TXT-DATA: decode failure.");
			return(undef);
		}

		push(@_texts_, $_text_);

		$_size_   += $_text_->{'_size_'};
		$_offset_ += $_text_->{'_size_'};
	}

	return(
		{
			'_size_'  => $_size_,
			'texts'   => [ @_texts_ ]
		}
	);
}



#----------------------------------------------------------------------#
# kGen_DNS_RDATA_SIG()                                                 #
#----------------------------------------------------------------------#
sub
kGen_DNS_RDATA_SIG($$$$$$$$$)
{
	my ($type, $algorithm, $labels, $ttl, $expiration,
		$inception, $tag, $name, $signature) = @_;

	return(
		pack(
			'n C2 N3 n a* a*',
			$type,
			$algorithm,
			$labels,
			$ttl,
			$expiration,
			$inception,
			$tag,
			$name,
			$signature
		)
	);
}



#----------------------------------------------------------------------#
# kDec_DNS_RDATA_SIG()                                                 #
#----------------------------------------------------------------------#
sub
kDec_DNS_RDATA_SIG($$;$)
{
	my ($data, $rdlength, $offset) = @_;

	my $function = 'kDec_DNS_RDATA_SIG';
	kInit_DNS_Error();

	my $_offset_ = defined($offset) ? $offset : 0;

	my $fixedsize = 18;
	my ($_type_,		# n
	    $_algorithm_,	# C
	    $_labels_,		# C
	    $_ttl_,		# N
	    $_expiration_,	# N
	    $_inception_,	# N
	    $_tag_		# n
	   ) = unpack("\@$_offset_ n C2 N3 n", $data);

	$_offset_ += $fixedsize;

	my $_name_ = kDec_DNS_Name($data, $_offset_);
	unless (defined($_name_)) {
		kReg_DNS_Error(__FILE__, __LINE__, $function,
			       "NAME: decode failure.");
		return(undef);
	}

	$_offset_ += $_name_->{'_size_'};

	my $_siglength_ = $rdlength - $fixedsize - $_name_->{'_size_'};
	my $_signature_ = unpack("\@$_offset_ a$_siglength_", $data);

	my $_size_ = $fixedsize + $_name_->{'_size_'} + $_siglength_;
	return(
		{
			'_size_'	=> $_size_,
			'type'		=> $_type_,
			'algorithm'	=> $_algorithm_,
			'labels'	=> $_labels_,
			'ttl'		=> $_ttl_,
			'expiration'	=> $_expiration_,
			'inception'	=> $_inception_,
			'tag'		=> $_tag_,
			'name'		=> $_name_,
			'signature'	=> $_signature_,
		}
	);
}



#----------------------------------------------------------------------#
# kGen_DNS_RDATA_KEY()                                                 #
#----------------------------------------------------------------------#
sub
kGen_DNS_RDATA_KEY($$$$$$$$$$)
{
	my ($keytype, $reserved1, $extension, $reserved2, $nametype,
		$reserved3, $signatory, $protocol, $algorithm, $pubkey) = @_;

	my $_keytype_   = $keytype   << 6;
	my $_reserved1_ = $reserved1 << 5;
	my $_extension_ = $extension << 4;
	my $_reserved2_ = $reserved2 << 2;
	my $_nametype_  = $nametype;

	my $byte0 =
		$_keytype_   |
		$_reserved1_ |
		$_extension_ |
		$_reserved2_ |
		$_nametype_;

	my $_reserved3_ = $reserved3 << 4;
	my $_signatory_ = $signatory;

	my $byte1 = $_reserved3_ | $_signatory_;

	return(
		pack(
			'C4 a*',
			$byte0,
			$byte1,
			$protocol,
			$algorithm,
			$pubkey
		)
	);
}



#----------------------------------------------------------------------#
# kDec_DNS_RDATA_KEY()                                                 #
#----------------------------------------------------------------------#
sub
kDec_DNS_RDATA_KEY($$;$)
{
	my ($data, $lentgh, $offset) = @_;

	my $function = 'kDec_DNS_RDATA_KEY';
	kInit_DNS_Error();

	my $_offset_ = defined($offset) ? $offset : 0;

	my $fixedsize = 4;
        my $_pubkeylen_ = $lentgh - $fixedsize;

	my ($_flags_,		# n
	    $_protocol_,	# C
	    $_algorithm_,	# C
            $_pubkey_
	   ) = unpack("\@$_offset_ n C2 a$_pubkeylen_", $data);

	my $_keytype_   = ($_flags_ >> 14) & 0x3;
	my $_reserved1_ = ($_flags_ >> 13) & 0x1;
	my $_extension_ = ($_flags_ >> 12) & 0x1;
	my $_reserved2_ = ($_flags_ >> 10) & 0x3;
	my $_nametype_  = ($_flags_ >>  8) & 0x3;
	my $_reserved3_ = ($_flags_ >>  4) & 0xf;
	my $_signatory_ = $_flags_         & 0xf;

	my $_size_ = $fixedsize + length($_pubkey_);

	return(
		{
			'_size_'	=> $_size_,
			'keytype'	=> $_keytype_,
			'reserved1'	=> $_reserved1_,
			'extension'	=> $_extension_,
			'reserved2'	=> $_reserved2_,
			'nametype'	=> $_nametype_,
			'reserved3'	=> $_reserved3_,
			'signatory'	=> $_signatory_,
			'protocol'	=> $_protocol_,
			'algorithm'	=> $_algorithm_,
			'pubkey'	=> $_pubkey_,
		}
	);
}



#----------------------------------------------------------------------#
# kGen_DNS_RDATA_AAAA()                                                #
#----------------------------------------------------------------------#
sub
kGen_DNS_RDATA_AAAA($)
{
	my ($address) = @_;
	my @elements = ();

	kInit_DNS_Error();

        my $_address_ = defined($address)? $address: '::';

	if($_address_ =~ /^\s*([0-9A-Za-z:]+)\s*$/) {
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

		$_rdata_ = pack('n8', @elements);
	} else {
		return(undef);
	}

        return($_rdata_);
}



#----------------------------------------------------------------------#
# kDec_DNS_RDATA_AAAA()                                                #
#----------------------------------------------------------------------#
sub
kDec_DNS_RDATA_AAAA($;$)
{
	my ($data, $offset) = @_;

	my $function = 'kDec_DNS_RDATA_AAAA';
	kInit_DNS_Error();

	my $datalen  = length($data);
	my $_offset_ = defined($offset)? $offset: 0;

	my $size = 16;
	if($_offset_ + $size > $datalen) {
		kReg_DNS_Error(__FILE__, __LINE__, $function,
			"\$data -- requires $size bytes.");

		return(undef);
	}

	my @elements = unpack("\@$_offset_ n8", $data);

	my $_address_ = '';
	my $abbr      = 0;
	my $compress  = 0;
	my $cont      = 0;

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
				$_address_ .= ':';
				$cont ++;
			}

			next;
		}

		$_address_ .= sprintf(':%x', $elements[$d]);
	}

	$_address_ .= ':';

	unless(!$elements[0] && ($_address_ =~ /^::/)) {
		$_address_ = sprintf('%x%s', $elements[0], $_address_);
	}

	unless(!$elements[$#elements] && ($_address_ =~ /::$/)) {
		$_address_ .= sprintf('%x', $elements[$#elements]);
	}

	return(
		{
			'_size_'  => $size,
			'address' => $_address_
		}
	);
}



#----------------------------------------------------------------------#
# kGen_DNS_RDATA_NXT()                                                 #
#----------------------------------------------------------------------#
sub
kGen_DNS_RDATA_NXT($$)
{
	my ($next, $bitmap) = @_;
	return($next. $bitmap);
}



#----------------------------------------------------------------------#
# kDec_DNS_RDATA_NXT()                                                 #
#----------------------------------------------------------------------#
sub
kDec_DNS_RDATA_NXT($$;$)
{
	my ($data, $rdlength, $offset) = @_;

	my $function = 'kDec_DNS_RDATA_NXT';
	kInit_DNS_Error();

	my $_offset_ = defined($offset) ? $offset : 0;

	my $_next_ = kDec_DNS_Name($data, $_offset_);
	unless (defined($_next_)) {
		kReg_DNS_Error(__FILE__, __LINE__, $function,
			       "NEXT: decode failure.");
		return(undef);
	}

	$_offset_ += $_next_->{'_size_'};

	my $_bitmaplength_ = $rdlength - $_next_->{'_size_'};
	my $_bitmap_ = unpack("\@$_offset_ a$_bitmaplength_", $data);

	my $_size_ = $_next_->{'_size_'} + $_bitmaplength_;
	return(
		{
			'_size_'	=> $_size_,
			'next'		=> $_next_,
			'bitmap'	=> $_bitmap_,
		}
	);
}



#----------------------------------------------------------------------#
# kGen_DNS_RDATA_SRV()                                                 #
#----------------------------------------------------------------------#
sub
kGen_DNS_RDATA_SRV($$$$)
{
	my ($priority, $weight, $port, $target) = @_;
	return(pack('n3 a*', $priority, $weight, $port, $target));
}



#----------------------------------------------------------------------#
# kDec_DNS_RDATA_SRV()                                                 #
#----------------------------------------------------------------------#
sub
kDec_DNS_RDATA_SRV($;$)
{
	my ($data, $offset) = @_;

	my $function = 'kDec_DNS_RDATA_SRV';
	kInit_DNS_Error();

	my $_offset_ = defined($offset) ? $offset : 0;

	my $fixedsize = 6;

	my ($_priority_,
	    $_weight_,
	    $_port_
	   ) = unpack("\@$_offset_ n3", $data);

	$_offset_ += $fixedsize;

	my $_target_ = kDec_DNS_Name($data, $_offset_);
	unless (defined($_target_)) {
		kReg_DNS_Error(__FILE__, __LINE__, $function,
			       "TARGET: decode failure.");
		return(undef);
	}

	my $_size_ = $fixedsize + $_target_->{'_size_'};

	return(
		{
			'_size_'	=> $_size_,
			'priority'	=> $_priority_,
			'weight'	=> $_weight_,
			'port'		=> $_port_,
			'target'	=> $_target_,
		}
	);
}



#----------------------------------------------------------------------#
# kGen_DNS_RDATA_NAPTR()                                               #
#----------------------------------------------------------------------#
sub
kGen_DNS_RDATA_NAPTR($$$$$$)
{
	my ($order, $preference, $flags,
	    $services, $regexp, $replacement) = @_;

	my $len_flags = length($flags);
	my $len_services = length($services);
	my $len_regexp = length($regexp);

	return(pack('n2 C a* C a* C a* a*',
		    $order, $preference,	# n2
		    $len_flags, $flags,		# C a*
		    $len_services, $services,	# C a*
		    $len_regexp, $regexp,	# C a*
		    $replacement));		# a*
}



#----------------------------------------------------------------------#
# kDec_DNS_RDATA_NAPTR()                                               #
#----------------------------------------------------------------------#
sub
kDec_DNS_RDATA_NAPTR($;$)
{
	my ($data, $offset) = @_;

	my $function = 'kDec_DNS_RDATA_NAPTR';
	kInit_DNS_Error();

	my $_offset_ = defined($offset) ? $offset : 0;

	my $fixedsize = 4;
	my ($_order_,
	    $_preference_
	   ) = unpack("\@$_offset_ n2", $data);

	$_offset_ += $fixedsize;

	my $_flags_ = kDec_DNS_String($data, $_offset_);
	unless (defined($_flags_)) {
		kReg_DNS_Error(__FILE__, __LINE__, $function,
			       "FLAGS: decode failure.");
		return(undef);
	}
	$_offset_ += $_flags_->{'_size_'};

	my $_services_ = kDec_DNS_String($data, $_offset_);
	unless (defined($_services_)) {
		kReg_DNS_Error(__FILE__, __LINE__, $function,
			       "SERVICES: decode failure.");
		return(undef);
	}
	$_offset_ += $_services_->{'_size_'};

	my $_regexp_ = kDec_DNS_String($data, $_offset_);
	unless (defined($_regexp_)) {
		kReg_DNS_Error(__FILE__, __LINE__, $function,
			       "REGEXP: decode failure.");
		return(undef);
	}
	$_offset_ += $_regexp_->{'_size_'};

	my $_replacement_ = kDec_DNS_Name($data, $_offset_);
	unless (defined($_replacement_)) {
		kReg_DNS_Error(__FILE__, __LINE__, $function,
			       "REPLACEMENT: decode failure.");
		return(undef);
	}

	my $_size_ = $fixedsize + $_flags_->{'_size_'}
		+ $_services_->{'_size_'} + $_regexp_->{'_size_'}
		+ $_replacement_->{'_size_'};

	return(
		{
			'_size_'	=> $_size_,
			'order'		=> $_order_,
			'preference'	=> $_preference_,
			'flags'		=> $_flags_,
			'services'	=> $_services_,
			'regexp'	=> $_regexp_,
			'replacement'	=> $_replacement_,
		}
	);
}



#----------------------------------------------------------------------#
# kGen_DNS_RDATA_OPT()                                                 #
#----------------------------------------------------------------------#
sub
kGen_DNS_RDATA_OPT(@)
{
	my (@options) = @_;

	my $_option_ = '';

	foreach my $option (@options) {
		$_option_ .= $option;
	}

	return($_option_);
}



#----------------------------------------------------------------------#
# kDec_DNS_RDATA_OPT()                                                 #
#----------------------------------------------------------------------#
sub
kDec_DNS_RDATA_OPT($$;$)
{
	my ($data, $rdlength, $offset) = @_;

	my $function = 'kDec_DNS_RDATA_OPT';
	kInit_DNS_Error();

	my $datalen = length($data);
	my $_offset_ = defined($offset) ? $offset : 0;

	my @_options_= ();
	my $_size_ = 0;
	my $_attrlength_ = 4;
	for ( ; $_size_ < $rdlength; ) {
		if ($_offset_ + $_attrlength_ > $datalen) {
			my $size = $_offset_ + $_optlength_;
			kReg_DNS_Error(__FILE__, __LINE__, $function,
				       "\$data -- requires more $size bytes ".
				       "for attribute.");

			return(undef);
		}

		my ($_optcode_,
		    $_optlength_
		   ) = unpack("\@$_offset_ n2", $data);

		$_size_ += $_attrlength_;
		$_offset_ += $_attrlength_;

		if ($_offset_ + $_optlength_ > $datalen) {
			my $size = $_offset_ + $_optlength_;
			kReg_DNS_Error(__FILE__, __LINE__, $function,
				       "\$data -- requires more $size bytes ".
				       "for value.");

			return(undef);
		}

		my $_optdata_ = unpack("\@$_offset_ a$_optlength_", $data);

		$_size_ += $_optlength_;
		$_offset_ += $_optlength_;
		my $_declength_ = $_attrlength_ + $_optlength_;

		my $_option_ = {'_size_' => $_declength_,
				'code'   => $_optcode_,
				'length' => $_optlength_,
				'data'   => $_optdata_
			       };

		push(@_options_, $_option_);
	}

	if ($#_options_ == 0) {
		kReg_DNS_Error(__FILE__, __LINE__, $function,
			       "OPTION: decode failure.");
		return(undef);
	}

	return(
		{
			'_size_'  => $_size_,
			'options' => \@_options_,
		}
	);
}



#----------------------------------------------------------------------#
# kGen_DNS_RDATA_OPT_OPTION()                                          #
#----------------------------------------------------------------------#
sub
kGen_DNS_RDATA_OPT_OPTION($$$)
{
	my ($code, $length, $data) = @_;

	my $_length_ = defined($length)? $length: length($data);

	return(pack('n2 a*', $code, $_length_, $data));
}



#----------------------------------------------------------------------#
# kDec_DNS_RDATA_OPT_OPTION()                                          #
#----------------------------------------------------------------------#
sub
kDec_DNS_RDATA_OPT_OPTION($;$)
{
	my ($data, $offset) = @_;

	my $function = 'kDec_DNS_RDATA_OPT_OPTION';
	kInit_DNS_Error();

	my $datalen = length($data);
	my $_offset_ = defined($offset) ? $offset : 0;
	my $_attrlength_ = 4;

	if ($_offset_ + $_attrlength_ > $datalen) {
		my $size = $_offset_ + $_optlength_;
		kReg_DNS_Error(__FILE__, __LINE__, $function,
			       "\$data -- requires more $size bytes ".
			       "for attribute.");

		return(undef);
	}

	my ($_optcode_,
	    $_optlength_
	   ) = unpack("\@$_offset_ n2", $data);

	$_offset_ += $_attrlength_;

	if ($_offset_ + $_optlength_ > $datalen) {
		my $size = $_offset_ + $_optlength_;
		kReg_DNS_Error(__FILE__, __LINE__, $function,
			       "\$data -- requires more $size bytes ".
			       "for data.");
		return(undef);
	}

	my $_optdata_ = unpack("\@$_offset_ a$_optlength_", $data);

	my $_size_ = $_attrlength_ + $_optlength_;
	return(
		{
			'_size_' => $_size_,
			'code'   => $_optcode_,
			'length' => $_optlength_,
			'data'   => $_optdata_
		}
	);
}


#----------------------------------------------------------------------#
# kRegistSocketID()                                                    #
#----------------------------------------------------------------------#
my %protocolMap = ( );

sub
kRegistSocketID($$)
{
	my ($socketID, $protocol) = @_;

	$protocolMap{"$socketID"} = $protocol;
	return;
}


#----------------------------------------------------------------------#
# kSwitchFrameID()                                                     #
#----------------------------------------------------------------------#
sub
kSwitchFrameID($$)
{
	my ($protocol, $frameid) = @_;

	my $function = 'kSwitchFrameID';

	# frameid check
	unless ($frameid eq 'DNS') {
		kReg_DNS_Error(__FILE__, __LINE__, $function,
			       "\$frameid: $frameid -- invalid frameid");
		return(undef);
	}

	# protocol check
	if ($protocol eq 'UDP') {
		return 'UDPDNS';
	}
	elsif ($protocol eq 'TCP') {
		return 'DNS';
	}
	else {
		kReg_DNS_Error(__FILE__, __LINE__, $function,
			       "\$protocol: $protocol -- invalid protocol");
		return(undef);
	}
}


#----------------------------------------------------------------------#
# kCompileDNSMsg()                                                     #
#----------------------------------------------------------------------#
sub
kCompileDNSMsg($$)
{
	my ($socketID, $data) = @_;

	my $function = 'kCompileDNSMsg';
	my $protocol = $protocolMap{"$socketID"};

	unless (defined($protocol)) {
		kReg_DNS_Error(__FILE__, __LINE__, $function,
			       "use unregisted SocketID($socketid)");
		return undef;
	}

	if ($protocol eq 'UDP') {
		return $data;
	}

	my $prefix_tcp = pack('n', length($data));
	$data = $prefix_tcp . $data;

	return $data;
}


#----------------------------------------------------------------------#
# kDecompileDNSMsg()                                                   #
#----------------------------------------------------------------------#
sub
kDecompileDNSMsg($$)
{
	my ($socketID, $data) = @_;

	my $function = 'kDecompileDNSMsg';
	my $protocol = $protocolMap{"$socketID"};

	unless (defined($protocol)) {
		kReg_DNS_Error(__FILE__, __LINE__, $function,
			       "use unregisted SocketID($socketid)");
		return undef;
	}

	if ($protocol eq 'UDP') {
		return $data;
	}

	$data = unpack("\@2 a*", $data);
	return $data;
}


#----------------------------------------------------------------------#
# kPrint_DNS()                                                         #
#----------------------------------------------------------------------#
our $DUMP = 0;
our $DUMP_STR = '';

sub
kPrint_DNS($;$)
{
	my ($data, $dump) = @_;

	kInit_DNS_Error();


	unless (defined($dump)) {
		$dump = 0;
	}

	$DUMP = $dump;
	$DUMP_STR = '';

	my $_size_ = 0;
	my $offset = 0;
	my $_total_ = length($data) - $offset;
	dumpprintf("| DNS Data                      (%d bytes)\n", $_total_);

	#--- Header section ---------------#
	my $header = kPrint_Header($data, $offset);

	unless(defined($header)) {
		my $strerror = kDump_DNS_Error();

		if(defined($strerror)) {
			print("$strerror");
		}

		return(undef);
	}

	$offset += $header->{'_size_'};
	$_size_ += $header->{'_size_'};

	my $qdcount = $header->{'_qdcount_'};
	my $ancount = $header->{'_ancount_'};
	my $nscount = $header->{'_nscount_'};
	my $arcount = $header->{'_arcount_'};

	#--- Question section -------------#
	my $question = kPrint_Question($qdcount, $data, $offset);

	unless(defined($question)) {
		my $strerror = kDump_DNS_Error();

		if(defined($strerror)) {
			print("$strerror");
		}

		return(undef);
	}

	$offset += $question->{'_size_'};
	$_size_ += $question->{'_size_'};

	#--- Answer section ---------------#
	my $answer = kPrint_Answer($ancount, $data, $offset);

	unless(defined($answer)) {
		my $strerror = kDump_DNS_Error();

		if(defined($strerror)) {
			print("$strerror");
		}

		return(undef);
	}

	$offset += $answer->{'_size_'};
	$_size_ += $answer->{'_size_'};

	#--- Authority section ------------#
	my $authority = kPrint_Authority($nscount, $data, $offset);

	unless(defined($authority)) {
		my $strerror = kDump_DNS_Error();

		if(defined($strerror)) {
			print("$strerror");
		}

		return(undef);
	}

	$offset += $authority->{'_size_'};
	$_size_ += $authority->{'_size_'};

	#--- Additional section -----------#
	my $additional = kPrint_Additional($arcount, $data, $offset);

	unless(defined($additional)) {
		my $strerror = kDump_DNS_Error();

		if(defined($strerror)) {
			print("$strerror");
		}

		return(undef);
	}

	$offset += $additional->{'_size_'};
	$_size_ += $additional->{'_size_'};

	if($_size_ != $_total_) {
		# XXX
		printf("datalen mismatch %d <=> %d\n", $_total_, $_size_);
		return(undef);
	}

	return({'_size_' => $_size_}, $DUMP_STR);
}



#----------------------------------------------------------------------#
# kPrint_Header()                                                      #
#----------------------------------------------------------------------#
sub
kPrint_Header($;$)
{
	my ($data, $offset) = @_;

	my $function = 'kPrint_Header';

	my $header = kDec_DNS_Header($data, $offset);

	unless(defined($header)) {
		my $strerror = kDump_DNS_Error();

		if(defined($strerror)) {
			print("$strerror");
		}

		return(undef);
	}

	my $qdcount = $header->{'qdcount'};
	my $ancount = $header->{'ancount'};
	my $nscount = $header->{'nscount'};
	my $arcount = $header->{'arcount'};

	dumpprintf("| | Header section              (%d bytes)\n",
		$header->{'_size_'});

	dumpprintf("| | | id                             = %u (0x%04x)\n",
		$header->{'id'}, $header->{'id'});

	dumpprintf("| | | qr                             = %s\n",
		$header->{'qr'}? 'response': 'query');

	dumpprintf("| | | opcode                         = %d (0x%02x)\n",
		$header->{'opcode'}, $header->{'opcode'});

	dumpprintf("| | | aa                             = %s\n",
		$header->{'aa'}? 'true': 'false');

	dumpprintf("| | | tc                             = %s\n",
		$header->{'tc'}? 'true': 'false');

	dumpprintf("| | | rd                             = %s\n",
		$header->{'rd'}? 'true': 'false');

	dumpprintf("| | | ra                             = %s\n",
		$header->{'ra'}? 'true': 'false');

	dumpprintf("| | | z                              = %d (0x%02x)\n",
		$header->{'z'}, $header->{'z'});

	dumpprintf("| | | ad                             = %s\n",
		$header->{'ad'}? 'true': 'false');

	dumpprintf("| | | cd                             = %s\n",
		$header->{'cd'}? 'true': 'false');

	dumpprintf("| | | rcode                          = %d (0x%02x)\n",
		$header->{'rcode'}, $header->{'rcode'});

	dumpprintf("| | | qdcount                        = %d\n", $qdcount);
	dumpprintf("| | | ancount                        = %d\n", $ancount);
	dumpprintf("| | | nscount                        = %d\n", $nscount);
	dumpprintf("| | | arcount                        = %d\n", $arcount);

	return(
		{
			'_size_'	=> $header->{'_size_'},
			'_qdcount_'	=> $qdcount,
			'_ancount_'	=> $ancount,
			'_nscount_'	=> $nscount,
			'_arcount_'	=> $arcount
		}
	);
}



#----------------------------------------------------------------------#
# kPrint_Question()                                                    #
#----------------------------------------------------------------------#
sub
kPrint_Question($$;$)
{
	my ($qdcount, $data, $offset) = @_;

	my $function = 'kPrint_Question';
	my $_size_   = 0;

	dumpprintf("| | Question section\n");

	for(my $d = 0; $d < $qdcount; $d ++) {
		my $question = kDec_DNS_Question($data, $offset);

		unless(defined($question)) {
			my $strerror = kDump_DNS_Error();

			if(defined($strerror)) {
				print "$strerror";
			}

			return(undef);
		}

		my $compressed   = $question->{'qname'}->{'compressed'};
		my $pointer      = $question->{'qname'}->{'offset'};
		my $decompressed = $question->{'qname'}->{'decompressed'};

		$offset += $question->{'_size_'};
		$_size_ += $question->{'_size_'};

		dumpprintf("| | | question[%d]                  (%d bytes)\n",
			$d, $question->{'_size_'});

		if(defined($pointer)) {
			dumpprintf("| | | | qname                         ".
					" = %s (%s, offset: %d)\n",
				$decompressed,
				defined($compressed)? $compressed: 'undef',
				$pointer
			);
		} else {
			dumpprint("| | | | qname                         ".
				" = $compressed\n");
		}

		dumpprintf("| | | | qtype                          = %u (0x%04x)\n",
			$question->{'qtype'}, $question->{'qtype'});
		dumpprintf("| | | | qclass                         = %u (0x%04x)\n",
			$question->{'qclass'}, $question->{'qclass'});
	}

	return(
		{
			'_size_'	=> $_size_
		}
	);
}



#----------------------------------------------------------------------#
# kPrint_Answer()                                                      #
#----------------------------------------------------------------------#
sub
kPrint_Answer($$;$)
{
	my ($ancount, $data, $offset) = @_;

	my $function = 'kPrint_Answer';
	my $_size_   = 0;

	dumpprintf("| | Answer section\n");

	for(my $d = 0; $d < $ancount; $d ++) {
		my $rr = kPrint_RR($d, $data, $offset);

		$offset += $rr->{'_size_'};
		$_size_ += $rr->{'_size_'};
	}

	return(
		{
			'_size_'	=> $_size_
		}
	);
}



#----------------------------------------------------------------------#
# kPrint_Authority()                                                   #
#----------------------------------------------------------------------#
sub
kPrint_Authority($$;$)
{
	my ($nscount, $data, $offset) = @_;

	my $function = 'kPrint_Authority';
	my $_size_   = 0;

	dumpprintf("| | Authority section\n");

	for(my $d = 0; $d < $nscount; $d ++) {
		my $rr = kPrint_RR($d, $data, $offset);

		$offset += $rr->{'_size_'};
		$_size_ += $rr->{'_size_'};
	}

	return({'_size_' => $_size_});
}



#----------------------------------------------------------------------#
# kPrint_Additional()                                                  #
#----------------------------------------------------------------------#
sub
kPrint_Additional($$;$)
{
	my ($arcount, $data, $offset) = @_;

	my $function = 'kPrint_Additional';
	my $_size_   = 0;

	dumpprintf("| | Additional section\n");

	for(my $d = 0; $d < $arcount; $d ++) {
		my $rr = kPrint_RR($d, $data, $offset);

		$offset += $rr->{'_size_'};
		$_size_ += $rr->{'_size_'};
	}

	return({ '_size_' => $_size_ });
}



#----------------------------------------------------------------------#
# kPrint_RR()                                                          #
#----------------------------------------------------------------------#
sub
kPrint_RR($$;$)
{
	my ($count, $data, $offset) = @_;

	my $function = 'kPrint_RR';

	my $rr = kDec_DNS_RR($data, $offset);

	unless(defined($rr)) {
		my $strerror = kDump_DNS_Error();

		if(defined($strerror)) {
			print "$strerror";
		}

		return(undef);
	}

	my $_size_  = $rr->{'_size_'};
	   $offset += $_size_;

	dumpprintf("| | | Resource record[%d]           (%d bytes)\n",
		$count, $_size_);

	my $compressed   = $rr->{'name'}->{'compressed'};
	my $pointer      = $rr->{'name'}->{'offset'};
	my $decompressed = $rr->{'name'}->{'decompressed'};

	if(defined($pointer)) {
		dumpprintf("| | | | name                          ".
				" = %s (%s, offset: %d)\n",
			$decompressed,
			defined($compressed)? $compressed: 'undef',
			$pointer
		);
	} else {
		unless (defined($compressed)) {
			dumpprint("| | | | name                           = &lt;Root&gt;\n");
		}
		else {
			dumpprint("| | | | name                           = $compressed\n");
		}
	}

	if ($rr->{'type'} == 41) { # OPT
		dumpprintf("| | | | type                           = %u (0x%04x)\n",
			$rr->{'type'}, $rr->{'type'});
		dumpprintf("| | | | UDP payload                    = %u (0x%04x)\n",
			$rr->{'class'}, $rr->{'class'});
		dumpprintf("| | | | Higher bits in extended RCODE  = %d (0x%02x)\n",
			($rr->{'ttl'} >> 24) & 0xff, ($rr->{'ttl'} >> 8));
		dumpprintf("| | | | EDNS0 version                  = %d (0x%02x)\n",
			($rr->{'ttl'} >> 16) & 0xff, ($rr->{'ttl'} >> 16));
		dumpprintf("| | | | Z                              = %d (0x%04x)\n",
			$rr->{'ttl'} & 0xffff, $rr->{'ttl'} & 0xffff);
		dumpprintf("| | | | rdlength                       = %d\n",
			$rr->{'rdlength'});
	}
	else {
		dumpprintf("| | | | type                           = %u (0x%04x)\n",
			$rr->{'type'}, $rr->{'type'});
		dumpprintf("| | | | class                          = %u (0x%04x)\n",
			$rr->{'class'}, $rr->{'class'});
		dumpprintf("| | | | ttl                            = %d (0x%08x)\n",
			$rr->{'ttl'}, $rr->{'ttl'});
		dumpprintf("| | | | rdlength                       = %d\n",
			$rr->{'rdlength'});
	}



	my $rdata = kPrint_RDATA($rr->{'type'}, $data,
		$rr->{'rdlength'}, $offset - $rr->{'rdlength'});

	unless(defined($rdata)) {
		my $strerror = kDump_DNS_Error();

		if(defined($strerror)) {
			print "$strerror";
		}

		return(undef);
	}

	return({'_size_' => $_size_});
}



#----------------------------------------------------------------------#
# kPrint_RDATA()                                                       #
#----------------------------------------------------------------------#
sub
kPrint_RDATA($$$;$)
{
	my ($type, $data, $length, $offset) = @_;

	my $_size_ = $length;

	my $function = 'kPrint_RDATA';

	if ($_size_ == 0) {
		# if rdlength is zero, rdata is not decoded
		dumpprintf("| | | | RDATA                         (%d bytes)\n", $_size_);
		dumpprintf("| | | | | no RDATA\n");
		return({'_size_' => $_size_});
	}

	if($type ==  1) { return(kPrint_RDATA_A    ($data,          $offset)); }
	if($type ==  2) { return(kPrint_RDATA_NS   ($data,          $offset)); }
	if($type ==  3) { return(kPrint_RDATA_MD   ($data,          $offset)); }
	if($type ==  4) { return(kPrint_RDATA_MF   ($data,          $offset)); }
	if($type ==  5) { return(kPrint_RDATA_CNAME($data,          $offset)); }
	if($type ==  6) { return(kPrint_RDATA_SOA  ($data,          $offset)); }
	if($type ==  7) { return(kPrint_RDATA_MB   ($data,          $offset)); }
	if($type ==  8) { return(kPrint_RDATA_MG   ($data,          $offset)); }
	if($type ==  9) { return(kPrint_RDATA_MR   ($data,          $offset)); }
	if($type == 10) { return(kPrint_RDATA_NULL ($data, $length, $offset)); }
	if($type == 11) { return(kPrint_RDATA_WKS  ($data, $length, $offset)); }
	if($type == 12) { return(kPrint_RDATA_PTR  ($data,          $offset)); }
	if($type == 13) { return(kPrint_RDATA_HINFO($data,          $offset)); }
	if($type == 14) { return(kPrint_RDATA_MINFO($data,          $offset)); }
	if($type == 15) { return(kPrint_RDATA_MX   ($data,          $offset)); }
	if($type == 16) { return(kPrint_RDATA_TXT  ($data, $length, $offset)); }
	if($type == 24) { return(kPrint_RDATA_SIG  ($data, $length, $offset)); }
	if($type == 25) { return(kPrint_RDATA_KEY  ($data, $length, $offset)); }
	if($type == 28) { return(kPrint_RDATA_AAAA ($data,          $offset)); }
	if($type == 30) { return(kPrint_RDATA_NXT  ($data, $length, $offset)); }
	if($type == 33) { return(kPrint_RDATA_SRV  ($data,          $offset)); }
	if($type == 35) { return(kPrint_RDATA_NAPTR($data,          $offset)); }
	if($type == 41) { return(kPrint_RDATA_OPT  ($data, $length, $offset)); }

	dumpprintf("| | | | | rdata                          = %s\n",
		unpack('H*', substr($data, $offset, $length)));

	return({'_size_' => $_size_});
}



#----------------------------------------------------------------------#
# kPrint_RDATA_A()                                                     #
#----------------------------------------------------------------------#
sub
kPrint_RDATA_A($;$)
{
	my ($data, $offset) = @_;

	my $rdata = kDec_DNS_RDATA_A($data, $offset);

	unless(defined($rdata)) {
		my $strerror = kDump_DNS_Error();

		if(defined($strerror)) {
			print "$strerror";
		}

		return(undef);
	}

	my $_size_ = $rdata->{'_size_'};

	dumpprintf("| | | | A RDATA                       (%d bytes)\n", $_size_);
	dumpprintf("| | | | | address                        = %s\n",
		$rdata->{'address'});

	return({'_size_' => $_size_});
}



#----------------------------------------------------------------------#
# kPrint_RDATA_NS()                                                    #
#----------------------------------------------------------------------#
sub
kPrint_RDATA_NS($;$)
{
	my ($data, $offset) = @_;

	my $rdata = kDec_DNS_RDATA_NS($data, $offset);

	unless(defined($rdata)) {
		my $strerror = kDump_DNS_Error();

		if(defined($strerror)) {
			print "$strerror";
		}

		return(undef);
	}

	my $_size_ = $rdata->{'_size_'};

	dumpprintf("| | | | NS RDATA                      (%d bytes)\n", $_size_);

	my $compressed   = $rdata->{'nsdname'}->{'compressed'};
	my $pointer      = $rdata->{'nsdname'}->{'offset'};
	my $decompressed = $rdata->{'nsdname'}->{'decompressed'};

	if(defined($pointer)) {
		dumpprintf("| | | | | nsdname                       ".
				" = %s (%s, offset: %d)\n",
			$decompressed,
			defined($compressed)? $compressed: 'undef',
			$pointer
		);
	} else {
		dumpprint("| | | | | nsdname                       ".
			" = $compressed\n");
	}

	return({'_size_' => $_size_});
}



#----------------------------------------------------------------------#
# kPrint_RDATA_MD()                                                    #
#----------------------------------------------------------------------#
sub
kPrint_RDATA_MD($;$)
{
	my ($data, $offset) = @_;

	my $rdata = kDec_DNS_RDATA_MD($data, $offset);

	unless(defined($rdata)) {
		my $strerror = kDump_DNS_Error();

		if(defined($strerror)) {
			print "$strerror";
		}

		return(undef);
	}

	my $_size_ = $rdata->{'_size_'};

	dumpprintf("| | | | MD RDATA                      (%d bytes)\n", $_size_);

	my $compressed   = $rdata->{'madname'}->{'compressed'};
	my $pointer      = $rdata->{'madname'}->{'offset'};
	my $decompressed = $rdata->{'madname'}->{'decompressed'};

	if(defined($pointer)) {
		dumpprintf("| | | | | madname                       ".
				" = %s (%s, offset: %d)\n",
			$decompressed,
			defined($compressed)? $compressed: 'undef',
			$pointer
		);
	} else {
		dumpprint("| | | | | madname                       ".
			" = $compressed\n");
	}

	return({'_size_' => $_size_});
}



#----------------------------------------------------------------------#
# kPrint_RDATA_MF()                                                    #
#----------------------------------------------------------------------#
sub
kPrint_RDATA_MF($;$)
{
	my ($data, $offset) = @_;

	my $rdata = kDec_DNS_RDATA_MF($data, $offset);

	unless(defined($rdata)) {
		my $strerror = kDump_DNS_Error();

		if(defined($strerror)) {
			print "$strerror";
		}

		return(undef);
	}

	my $_size_ = $rdata->{'_size_'};

	dumpprintf("| | | | MF RDATA                      (%d bytes)\n", $_size_);

	my $compressed   = $rdata->{'madname'}->{'compressed'};
	my $pointer      = $rdata->{'madname'}->{'offset'};
	my $decompressed = $rdata->{'madname'}->{'decompressed'};

	if(defined($pointer)) {
		dumpprintf("| | | | | madname                       ".
				" = %s (%s, offset: %d)\n",
			$decompressed,
			defined($compressed)? $compressed: 'undef',
			$pointer
		);
	} else {
		dumpprint("| | | | | madname                       ".
			" = $compressed\n");
	}

	return({'_size_' => $_size_});
}



#----------------------------------------------------------------------#
# kPrint_RDATA_CNAME()                                                 #
#----------------------------------------------------------------------#
sub
kPrint_RDATA_CNAME($;$)
{
	my ($data, $offset) = @_;

	my $rdata = kDec_DNS_RDATA_CNAME($data, $offset);

	unless(defined($rdata)) {
		my $strerror = kDump_DNS_Error();

		if(defined($strerror)) {
			print "$strerror";
		}

		return(undef);
	}

	my $_size_ = $rdata->{'_size_'};

	dumpprintf("| | | | CNAME RDATA                   (%d bytes)\n", $_size_);

	my $compressed   = $rdata->{'cname'}->{'compressed'};
	my $pointer      = $rdata->{'cname'}->{'offset'};
	my $decompressed = $rdata->{'cname'}->{'decompressed'};

	if(defined($pointer)) {
		dumpprintf("| | | | | cname                         ".
				" = %s (%s, offset: %d)\n",
			$decompressed,
			defined($compressed)? $compressed: 'undef',
			$pointer
		);
	} else {
		dumpprint("| | | | | cname                         ".
			" = $compressed\n");
	}

	return({'_size_' => $_size_});
}



#----------------------------------------------------------------------#
# kPrint_RDATA_SOA()                                                   #
#----------------------------------------------------------------------#
sub
kPrint_RDATA_SOA($;$)
{
	my ($data, $offset) = @_;

	my $rdata = kDec_DNS_RDATA_SOA($data, $offset);

	unless(defined($rdata)) {
		my $strerror = kDump_DNS_Error();

		if(defined($strerror)) {
			print "$strerror";
		}

		return(undef);
	}

	my $_size_ = $rdata->{'_size_'};

	dumpprintf("| | | | SOA RDATA                     (%d bytes)\n", $_size_);

	my $mname_compressed   = $rdata->{'mname'}->{'compressed'};
	my $mname_pointer      = $rdata->{'mname'}->{'offset'};
	my $mname_decompressed = $rdata->{'mname'}->{'decompressed'};

	if(defined($mname_pointer)) {
		dumpprintf("| | | | | mname                         ".
				" = %s (%s, offset: %d)\n",
			$mname_decompressed,
			defined($mname_compressed)? $mname_compressed: 'undef',
			$mname_pointer
		);
	} else {
		dumpprint("| | | | | mname                         ".
			" = $mname_compressed\n");
	}

	my $rname_compressed   = $rdata->{'rname'}->{'compressed'};
	my $rname_pointer      = $rdata->{'rname'}->{'offset'};
	my $rname_decompressed = $rdata->{'rname'}->{'decompressed'};

	if(defined($rname_pointer)) {
		dumpprintf("| | | | | rname                         ".
				" = %s (%s, offset: %d)\n",
			$rname_decompressed,
			defined($rname_compressed)? $rname_compressed: 'undef',
			$rname_pointer
		);
	} else {
		dumpprint("| | | | | rname                         ".
			" = $rname_compressed\n");
	}

	dumpprintf("| | | | | serial                         = %d (0x%08x)\n",
		$rdata->{'serial'}, $rdata->{'serial'});
	dumpprintf("| | | | | refresh                        = %d (0x%08x)\n",
		$rdata->{'refresh'}, $rdata->{'refresh'});
	dumpprintf("| | | | | retry                          = %d (0x%08x)\n",
		$rdata->{'retry'}, $rdata->{'retry'});
	dumpprintf("| | | | | expire                         = %d (0x%08x)\n",
		$rdata->{'expire'}, $rdata->{'expire'});
	dumpprintf("| | | | | minimum                        = %d (0x%08x)\n",
		$rdata->{'minimum'}, $rdata->{'minimum'});

	return({'_size_' => $_size_});
}



#----------------------------------------------------------------------#
# kPrint_RDATA_MB()                                                    #
#----------------------------------------------------------------------#
sub
kPrint_RDATA_MB($;$)
{
	my ($data, $offset) = @_;

	my $rdata = kDec_DNS_RDATA_MB($data, $offset);

	unless(defined($rdata)) {
		my $strerror = kDump_DNS_Error();

		if(defined($strerror)) {
			print "$strerror";
		}

		return(undef);
	}

	my $_size_ = $rdata->{'_size_'};

	dumpprintf("| | | | MB RDATA                      (%d bytes)\n", $_size_);

	my $compressed   = $rdata->{'madname'}->{'compressed'};
	my $pointer      = $rdata->{'madname'}->{'offset'};
	my $decompressed = $rdata->{'madname'}->{'decompressed'};

	if(defined($pointer)) {
		dumpprintf("| | | | | madname                       ".
				" = %s (%s, offset: %d)\n",
			$decompressed,
			defined($compressed)? $compressed: 'undef',
			$pointer
		);
	} else {
		dumpprint("| | | | | madname                       ".
			" = $compressed\n");
	}

	return({'_size_' => $_size_});
}



#----------------------------------------------------------------------#
# kPrint_RDATA_MG()                                                    #
#----------------------------------------------------------------------#
sub
kPrint_RDATA_MG($;$)
{
	my ($data, $offset) = @_;

	my $rdata = kDec_DNS_RDATA_MG($data, $offset);

	unless(defined($rdata)) {
		my $strerror = kDump_DNS_Error();

		if(defined($strerror)) {
			print "$strerror";
		}

		return(undef);
	}

	my $_size_ = $rdata->{'_size_'};

	dumpprintf("| | | | MG RDATA                      (%d bytes)\n", $_size_);

	my $compressed   = $rdata->{'mgmname'}->{'compressed'};
	my $pointer      = $rdata->{'mgmname'}->{'offset'};
	my $decompressed = $rdata->{'mgmname'}->{'decompressed'};

	if(defined($pointer)) {
		dumpprintf("| | | | | mgmname                       ".
				" = %s (%s, offset: %d)\n",
			$decompressed,
			defined($compressed)? $compressed: 'undef',
			$pointer
		);
	} else {
		dumpprint("| | | | | mgmname                       ".
			" = $compressed\n");
	}

	return({'_size_' => $_size_});
}



#----------------------------------------------------------------------#
# kPrint_RDATA_MR()                                                    #
#----------------------------------------------------------------------#
sub
kPrint_RDATA_MR($;$)
{
	my ($data, $offset) = @_;

	my $rdata = kDec_DNS_RDATA_MR($data, $offset);

	unless(defined($rdata)) {
		my $strerror = kDump_DNS_Error();

		if(defined($strerror)) {
			print "$strerror";
		}

		return(undef);
	}

	my $_size_ = $rdata->{'_size_'};

	dumpprintf("| | | | MR RDATA                      (%d bytes)\n", $_size_);

	my $compressed   = $rdata->{'newname'}->{'compressed'};
	my $pointer      = $rdata->{'newname'}->{'offset'};
	my $decompressed = $rdata->{'newname'}->{'decompressed'};

	if(defined($pointer)) {
		dumpprintf("| | | | | newname                       ".
				" = %s (%s, offset: %d)\n",
			$decompressed,
			defined($compressed)? $compressed: 'undef',
			$pointer
		);
	} else {
		dumpprint("| | | | | newname                       ".
			" = $compressed\n");
	}

	return({'_size_' => $_size_});
}



#----------------------------------------------------------------------#
# kPrint_RDATA_NULL()                                                  #
#----------------------------------------------------------------------#
sub
kPrint_RDATA_NULL($$;$)
{
	my ($data, $length, $offset) = @_;

	my $rdata = kDec_DNS_RDATA_NULL($data, $length, $offset);

	unless(defined($rdata)) {
		my $strerror = kDump_DNS_Error();

		if(defined($strerror)) {
			print "$strerror";
		}

		return(undef);
	}

	my $_size_ = $rdata->{'_size_'};

	dumpprintf("| | | | NULL RDATA                    (%d bytes)\n", $_size_);

	dumpprintf("| | | | | data                           = %s\n",
		unpack('H*', $rdata->{'data'}));

	return({'_size_' => $_size_});
}



#----------------------------------------------------------------------#
# kPrint_RDATA_WKS()                                                   #
#----------------------------------------------------------------------#
sub
kPrint_RDATA_WKS($$;$)
{
	my ($data, $length, $offset) = @_;

	my $rdata = kDec_DNS_RDATA_WKS($data, $length, $offset);

	unless(defined($rdata)) {
		my $strerror = kDump_DNS_Error();

		if(defined($strerror)) {
			print "$strerror";
		}

		return(undef);
	}

	my $_size_ = $rdata->{'_size_'};

	dumpprintf("| | | | WKS RDATA                     (%d bytes)\n", $_size_);

	dumpprintf("| | | | | address                        = %s\n",
		$rdata->{'address'});
	dumpprintf("| | | | | protocol                       = %d (0x%02x)\n",
		$rdata->{'protocol'}, $rdata->{'protocol'});
	dumpprintf("| | | | | bitmap                         = %s\n",
		unpack('B*', $rdata->{'bitmap'}));

	return({'_size_' => $_size_});
}



#----------------------------------------------------------------------#
# kPrint_RDATA_PTR()                                                   #
#----------------------------------------------------------------------#
sub
kPrint_RDATA_PTR($;$)
{
	my ($data, $offset) = @_;

	my $rdata = kDec_DNS_RDATA_PTR($data, $offset);

	unless(defined($rdata)) {
		my $strerror = kDump_DNS_Error();

		if(defined($strerror)) {
			print "$strerror";
		}

		return(undef);
	}

	my $_size_ = $rdata->{'_size_'};

	dumpprintf("| | | | PTR RDATA                     (%d bytes)\n", $_size_);

	my $compressed   = $rdata->{'ptrdname'}->{'compressed'};
	my $pointer      = $rdata->{'ptrdname'}->{'offset'};
	my $decompressed = $rdata->{'ptrdname'}->{'decompressed'};

	if(defined($pointer)) {
		dumpprintf("| | | | | ptrdname                      ".
				" = %s (%s, offset: %d)\n",
			$decompressed,
			defined($compressed)? $compressed: 'undef',
			$pointer
		);
	} else {
		dumpprint("| | | | | ptrdname                      ".
			" = $compressed\n");
	}

	return({'_size_' => $_size_});
}



#----------------------------------------------------------------------#
# kPrint_RDATA_HINFO()                                                 #
#----------------------------------------------------------------------#
sub
kPrint_RDATA_HINFO($;$)
{
	my ($data, $offset) = @_;

	my $rdata = kDec_DNS_RDATA_HINFO($data, $offset);

	unless(defined($rdata)) {
		my $strerror = kDump_DNS_Error();

		if(defined($strerror)) {
			print "$strerror";
		}

		return(undef);
	}

	my $_size_ = $rdata->{'_size_'};

	dumpprintf("| | | | HINFO RDATA                   (%d bytes)\n", $_size_);

	dumpprint("| | | | | cpu                           ".
		" = $rdata->{'cpu'}->{'string'}\n");
	dumpprint("| | | | | os                            ".
		" = $rdata->{'os'}->{'string'}\n");

	return({'_size_' => $_size_});
}



#----------------------------------------------------------------------#
# kPrint_RDATA_MINFO()                                                 #
#----------------------------------------------------------------------#
sub
kPrint_RDATA_MINFO($;$)
{
	my ($data, $offset) = @_;

	my $rdata = kDec_DNS_RDATA_MINFO($data, $offset);

	unless(defined($rdata)) {
		my $strerror = kDump_DNS_Error();

		if(defined($strerror)) {
			print "$strerror";
		}

		return(undef);
	}

	my $_size_ = $rdata->{'_size_'};

	dumpprintf("| | | | MINFO RDATA                   (%d bytes)\n", $_size_);

	my $rmailbx_compressed   = $rdata->{'rmailbx'}->{'compressed'};
	my $rmailbx_pointer      = $rdata->{'rmailbx'}->{'offset'};
	my $rmailbx_decompressed = $rdata->{'rmailbx'}->{'decompressed'};

	if(defined($rmailbx_pointer)) {
		dumpprintf("| | | | | rmailbx                       ".
				" = %s (%s, offset: %d)\n",
			$rmailbx_decompressed,
			defined($rmailbx_compressed)?
				$rmailbx_compressed: 'undef',
			$rmailbx_pointer
		);
	} else {
		dumpprint("| | | | | rmailbx                       ".
			" = $rmailbx_compressed\n");
	}

	my $emailbx_compressed   = $rdata->{'emailbx'}->{'compressed'};
	my $emailbx_pointer      = $rdata->{'emailbx'}->{'offset'};
	my $emailbx_decompressed = $rdata->{'emailbx'}->{'decompressed'};

	if(defined($emailbx_pointer)) {
		dumpprintf("| | | | | emailbx                       ".
				" = %s (%s, offset: %d)\n",
			$emailbx_decompressed,
			defined($emailbx_compressed)?
				$emailbx_compressed: 'undef',
			$emailbx_pointer
		);
	} else {
		dumpprint("| | | | | emailbx                       ".
			" = $emailbx_compressed\n");
	}

	return({'_size_' => $_size_});
}



#----------------------------------------------------------------------#
# kPrint_RDATA_MX()                                                    #
#----------------------------------------------------------------------#
sub
kPrint_RDATA_MX($;$)
{
	my ($data, $offset) = @_;

	my $rdata = kDec_DNS_RDATA_MX($data, $offset);

	unless(defined($rdata)) {
		my $strerror = kDump_DNS_Error();

		if(defined($strerror)) {
			print "$strerror";
		}

		return(undef);
	}

	my $_size_ = $rdata->{'_size_'};

	dumpprintf("| | | | MX RDATA                      (%d bytes)\n", $_size_);

	dumpprintf("| | | | | preference                    ".
			" = %u (0x%04x)\n",
		$rdata->{'preference'}, $rdata->{'preference'});

	my $compressed   = $rdata->{'exchange'}->{'compressed'};
	my $pointer      = $rdata->{'exchange'}->{'offset'};
	my $decompressed = $rdata->{'exchange'}->{'decompressed'};

	if(defined($pointer)) {
		dumpprintf("| | | | | exchange                      ".
				" = %s (%s, offset: %d)\n",
			$decompressed,
			defined($compressed)?
				$compressed: 'undef',
			$pointer
		);
	} else {
		dumpprint("| | | | | exchange                      ".
			" = $compressed\n");
	}

	return({'_size_' => $_size_});
}



#----------------------------------------------------------------------#
# kPrint_RDATA_TXT()                                                   #
#----------------------------------------------------------------------#
sub
kPrint_RDATA_TXT($$;$)
{
	my ($data, $length, $offset) = @_;

	my $rdata = kDec_DNS_RDATA_TXT($data, $length, $offset);

	unless(defined($rdata)) {
		my $strerror = kDump_DNS_Error();

		if(defined($strerror)) {
			print "$strerror";
		}

		return(undef);
	}

	my $_size_ = $rdata->{'_size_'};

	dumpprintf("| | | | TXT RDATA                     (%d bytes)\n", $_size_);

	my $reference = $rdata->{'texts'};

	foreach my $text (@$reference) {
		dumpprint("| | | | | text                          ".
			" = $text->{'string'}\n");
	}

	return({'_size_' => $_size_});
}



#----------------------------------------------------------------------#
# kPrint_RDATA_SIG()                                                   #
#----------------------------------------------------------------------#
sub
kPrint_RDATA_SIG($$;$)
{
	my ($data, $length, $offset) = @_;

	my $rdata = kDec_DNS_RDATA_SIG($data, $length, $offset);

	unless(defined($rdata)) {
		my $strerror = kDump_DNS_Error();

		if(defined($strerror)) {
			print "$strerror";
		}

		return(undef);
	}

	my $_size_ = $rdata->{'_size_'};

	dumpprintf("| | | | SIG RDATA                     (%d bytes)\n", $_size_);

	dumpprintf("| | | | | type                           = %u (0x%04x)\n",
		$rdata->{'type'}, $rdata->{'type'});
	dumpprintf("| | | | | algorithm                      = %u (0x%04x)\n",
		$rdata->{'algorithm'}, $rdata->{'algorithm'});
	dumpprintf("| | | | | labels                         = %u (0x%04x)\n",
		$rdata->{'labels'}, $rdata->{'labels'});
	dumpprintf("| | | | | ttl                            = %u (0x%04x)\n",
		$rdata->{'ttl'}, $rdata->{'ttl'});
	dumpprintf("| | | | | expiration                     = %u (0x%04x)\n",
		$rdata->{'expiration'}, $rdata->{'expiration'});
	dumpprintf("| | | | | inception                      = %u (0x%04x)\n",
		$rdata->{'inception'}, $rdata->{'inception'});
	dumpprintf("| | | | | tag                            = %u (0x%04x)\n",
		$rdata->{'tag'}, $rdata->{'tag'});

	my $compressed   = $rdata->{'name'}->{'compressed'};
	my $pointer      = $rdata->{'name'}->{'offset'};
	my $decompressed = $rdata->{'name'}->{'decompressed'};

	if(defined($pointer)) {
		dumpprintf("| | | | | name                          ".
				" = %s (%s, offset: %d)\n",
			$decompressed,
			defined($compressed)?
				$compressed: 'undef',
			$pointer
		);
	} else {
		dumpprint("| | | | | name                          ".
			" = $compressed\n");
	}

	dumpprintf("| | | | | signature                      = %s\n",
		$rdata->{'signature'});

	return({'_size_' => $_size_});
}



#----------------------------------------------------------------------#
# kPrint_RDATA_KEY()                                                   #
#----------------------------------------------------------------------#
sub
kPrint_RDATA_KEY($$;$)
{
	my ($data, $length, $offset) = @_;

	my $rdata = kDec_DNS_RDATA_KEY($data, $length, $offset);

	unless(defined($rdata)) {
		my $strerror = kDump_DNS_Error();

		if(defined($strerror)) {
			print "$strerror";
		}

		return(undef);
	}

	my $_size_ = $rdata->{'_size_'};

	dumpprintf("| | | | KEY RDATA                     (%d bytes)\n", $_size_);

	dumpprintf("| | | | | keytype                        = %d\n",
		$rdata->{'keytype'});
	dumpprintf("| | | | | reserved1                      = %d\n",
		$rdata->{'reserved1'});
	dumpprintf("| | | | | extension                      = %d\n",
		$rdata->{'extension'});
	dumpprintf("| | | | | reserved2                      = %d\n",
		$rdata->{'reserved2'});
	dumpprintf("| | | | | nametype                       = %d\n",
		$rdata->{'nametype'});
	dumpprintf("| | | | | reserved3                      = %d\n",
		$rdata->{'reserved3'});
	dumpprintf("| | | | | signatory                      = %d\n",
		$rdata->{'signatory'});
	dumpprintf("| | | | | protocol                       = %d\n",
		$rdata->{'protocol'});
	dumpprintf("| | | | | algorithm                      = %d\n",
		$rdata->{'algorithm'});
	dumpprintf("| | | | | pubkey                         = %s\n",
		$rdata->{'pubkey'});

	return({'_size_' => $_size_});
}



#----------------------------------------------------------------------#
# kPrint_RDATA_AAAA()                                                  #
#----------------------------------------------------------------------#
sub
kPrint_RDATA_AAAA($;$)
{
	my ($data, $offset) = @_;

	my $rdata = kDec_DNS_RDATA_AAAA($data, $offset);

	unless(defined($rdata)) {
		my $strerror = kDump_DNS_Error();

		if(defined($strerror)) {
			print "$strerror";
		}

		return(undef);
	}

	my $_size_ = $rdata->{'_size_'};

	dumpprintf("| | | | AAAA RDATA                    (%d bytes)\n", $_size_);

	dumpprintf("| | | | | address                       ".
		" = %s\n", $rdata->{'address'});

	return({'_size_' => $_size_});
}



#----------------------------------------------------------------------#
# kPrint_RDATA_NXT()                                                   #
#----------------------------------------------------------------------#
sub
kPrint_RDATA_NXT($$;$)
{
	my ($data, $length, $offset) = @_;

	my $rdata = kDec_DNS_RDATA_NXT($data, $length, $offset);

	unless(defined($rdata)) {
		my $strerror = kDump_DNS_Error();

		if(defined($strerror)) {
			print "$strerror";
		}

		return(undef);
	}

	my $_size_ = $rdata->{'_size_'};

	dumpprintf("| | | | NXT RDATA                     (%d bytes)\n", $_size_);

	my $compressed   = $rdata->{'next'}->{'compressed'};
	my $pointer      = $rdata->{'next'}->{'offset'};
	my $decompressed = $rdata->{'next'}->{'decompressed'};

	if(defined($pointer)) {
		dumpprintf("| | | | | next                          ".
				" = %s (%s, offset: %d)\n",
			$decompressed,
			defined($compressed)?
				$compressed: 'undef',
			$pointer
		);
	} else {
		dumpprint("| | | | | next                          ".
			" = $compressed\n");
	}

	dumpprintf("| | | | | bitmap                        ".
		" = %s\n", $rdata->{'bitmap'});

	return({'_size_' => $_size_});
}



#----------------------------------------------------------------------#
# kPrint_RDATA_SRV()                                                   #
#----------------------------------------------------------------------#
sub
kPrint_RDATA_SRV($;$)
{
	my ($data, $offset) = @_;

	my $rdata = kDec_DNS_RDATA_SRV($data, $offset);

	unless(defined($rdata)) {
		my $strerror = kDump_DNS_Error();

		if(defined($strerror)) {
			print "$strerror";
		}

		return(undef);
	}

	my $_size_ = $rdata->{'_size_'};

	dumpprintf("| | | | SRV RDATA                     (%d bytes)\n", $_size_);

	dumpprintf("| | | | | priority                       = %u (0x%04x)\n",
		$rdata->{'priority'}, $rdata->{'priority'});
	dumpprintf("| | | | | weight                         = %u (0x%04x)\n",
		$rdata->{'weight'}, $rdata->{'weight'});
	dumpprintf("| | | | | port                           = %u (0x%04x)\n",
		$rdata->{'port'}, $rdata->{'port'});

	my $compressed   = $rdata->{'target'}->{'compressed'};
	my $pointer      = $rdata->{'target'}->{'offset'};
	my $decompressed = $rdata->{'target'}->{'decompressed'};

	if(defined($pointer)) {
		dumpprintf("| | | | | target                        ".
				" = %s (%s, offset: %d)\n",
			$decompressed,
			defined($compressed)?
				$compressed: 'undef',
			$pointer
		);
	} else {
		dumpprint("| | | | | target                        ".
			" = $compressed\n");
	}

	return({'_size_' => $_size_});
}



#----------------------------------------------------------------------#
# kPrint_RDATA_NAPTR()                                                 #
#----------------------------------------------------------------------#
sub
kPrint_RDATA_NAPTR($;$)
{
	my ($data, $offset) = @_;

	my $rdata = kDec_DNS_RDATA_NAPTR($data, $offset);

	unless(defined($rdata)) {
		my $strerror = kDump_DNS_Error();

		if(defined($strerror)) {
			print "$strerror";
		}

		return(undef);
	}

	my $_size_ = $rdata->{'_size_'};

	dumpprintf("| | | | NAPTR RDATA                   (%d bytes)\n", $_size_);

	dumpprintf("| | | | | order                          = %u (0x%04x)\n",
		$rdata->{'order'}, $rdata->{'order'});
	dumpprintf("| | | | | preference                     = %u (0x%04x)\n",
		$rdata->{'preference'}, $rdata->{'preference'});
	dumpprintf("| | | | | flags                          = %s\n",
		$rdata->{'flags'}->{'string'});
	dumpprintf("| | | | | services                       = %s\n",
		$rdata->{'services'}->{'string'});
	dumpprintf("| | | | | regexp                         = %s\n",
		$rdata->{'regexp'}->{'string'});

	my $compressed   = $rdata->{'replacement'}->{'compressed'};
	my $pointer      = $rdata->{'replacement'}->{'offset'};
	my $decompressed = $rdata->{'replacement'}->{'decompressed'};

	if(defined($pointer)) {
		dumpprintf("| | | | | replacement                   ".
				" = %s (%s, offset: %d)\n",
			$decompressed,
			defined($compressed)?
				$compressed: 'undef',
			$pointer
		);
	} else {
		dumpprint("| | | | | replacement                   ".
			" = $compressed\n");
	}

	return({'_size_' => $_size_});
}



#----------------------------------------------------------------------#
# kPrint_RDATA_OPT()                                                   #
#----------------------------------------------------------------------#
sub
kPrint_RDATA_OPT($$;$)
{
	my ($data, $length, $offset) = @_;

	my $rdata = kDec_DNS_RDATA_OPT($data, $length, $offset);

	unless(defined($rdata)) {
		my $strerror = kDump_DNS_Error();

		if(defined($strerror)) {
			print "$strerror";
		}

		return(undef);
	}

	my $_size_ = $rdata->{'_size_'};

	dumpprintf("| | | | OPT RDATA                     (%d bytes)\n", $_size_);

	my $reference = $rdata->{'options'};

	for(my $d = 0; $d <= $#$reference; $d ++) { 
		dumpprintf("| | | | | option[%d]                    (%d bytes)\n",
			$d, $$reference[$d]->{'_size_'});

		dumpprintf("| | | | | | code                          ".
			" = %d\n",   $$reference[$d]->{'code'});
		dumpprintf("| | | | | | length                        ".
			" = %d\n", $$reference[$d]->{'length'});
		dumpprintf("| | | | | | data                          ".
			" = %s\n",   $$reference[$d]->{'data'});
	}

	return({'_size_' => $_size_});
}

sub dumpprintf($@) {
	my ($format, @args) = @_;

	my $str = sprintf($format, @args);
	dumpprint($str);
}

sub dumpprint($) {
	my ($str) = @_;

	if ($DUMP) {
		$DUMP_STR .= $str;
	}
	else {
		print($str);
	}
}


######################
# kDec_RDATA
#####################
sub kDec_RDATA($$$$)
{
	my ($type, $data, $offset, $length) = @_;

	my $rdata = undef;

	if ($type == 1) {	# A
		return(kDec_DNS_RDATA_A($data, $offset));
	}
	elsif ($type == 2) {	# NS
		return(kDec_DNS_RDATA_NS($data,$offset));
	}
	elsif ($type == 5) {	# CNAME
		return(kDec_DNS_RDATA_CNAME($data, $offset));
	}
	elsif ($type == 6) {	# SOA
		return(kDec_DNS_RDATA_SOA($data, $offset));
	}
	elsif ($type == 7) {	# MB
		return(kDec_DNS_RDATA_MB($data, $offset));
	}
	elsif ($type == 8) {	# MG
		return(kDec_DNS_RDATA_MG($data, $offset));
	}
	elsif ($type == 9) {	# MR
		return(kDec_DNS_RDATA_MR($data, $offset));
	}
	elsif ($type == 11) {	# WKS
		return(kDec_DNS_RDATA_WKS($data, $length, $offset));
	}
	elsif ($type == 12) {	# PTR
		return(kDec_DNS_RDATA_PTR($data, $offset));
	}
	elsif ($type == 13) {	# HINFO
		return(kDec_DNS_RDATA_HINFO($data, $offset));
	}
	elsif ($type == 14) {	# MINFO
		return(kDec_DNS_RDATA_MINFO($data, $offset));
	}
	elsif ($type == 15) {	# MX
		return(kDec_DNS_RDATA_MX($data, $offset));
	}
	elsif ($type == 16) {	# TXT
		return(kDec_DNS_RDATA_TXT($data, $length, $offset));
	}
	elsif ($type == 24) {	# SIG
		return(kDec_DNS_RDATA_SIG($data, $length, $offset));
	}
	elsif ($type == 25) {	# KEY
		return(kDec_DNS_RDATA_KEY($data, $offset));
	}
	elsif ($type == 28) {	# AAAA
		return(kDec_DNS_RDATA_AAAA($data, $offset));
	}
	elsif ($type == 30) {	# NXT
		return(kDec_DNS_RDATA_NXT($data, $length, $offset));
	}
	elsif ($type == 33) {	# SRV
		return(kDec_DNS_RDATA_SRV($data, $offset));
	}
	elsif ($type == 35) {	# NAPTR
		return(kDec_DNS_RDATA_NAPTR($data, $offset));
	}
	elsif ($type == 41) {	# OPT
		return(kDec_DNS_RDATA_OPT($data, $length, $offset));
	}
	else {
		return(unpack('H*', substr($data, $offset, $length)));
	}
}


#----------------------------------------------------------------------#
# BEGIN()                                                              #
#----------------------------------------------------------------------#
BEGIN
{
	$VERSION  = 1.00;
	@strerror = ();
}



#----------------------------------------------------------------------#
# END()                                                                #
#----------------------------------------------------------------------#
END
{
	undef @strerror;
	undef $VERSION;
}

1;
