package DNSConfig;
################################################################
# BEGIN - read ike_packet.def                                  #
################################################################
BEGIN {
        use Exporter;
        use vars qw(@ISA @EXPORT);
        @ISA    = qw(Exporter);
        @EXPORT = qw(
          $NUT_USE_IP_VERSION
          $NUT_IPV4_ADDR_0
          $NUT_IPV4_ADDR_1
          $NUT_IPV4_SV_PORT
          $NUT_IPV4_CL_PORT
          $NUT_IPV6_ADDR_0
          $NUT_IPV6_ADDR_1
          $NUT_IPV6_SV_PORT
          $NUT_IPV6_CL_PORT
          $NUT_EDNS0_SIZE
          $TN_CL1_IPV4_ADDR
          $TN_CL1_IPV6_ADDR
          $TN_CL2_IPV4_ADDR
          $TN_CL2_IPV6_ADDR
          $TN_SV1_IPV4_ADDR
          $TN_SV1_IPV6_ADDR
          $TN_SV2_IPV4_ADDR
          $TN_SV2_IPV6_ADDR
          $TN_SV3_IPV4_ADDR
          $TN_SV3_IPV6_ADDR
          $RETRANSMIT_COUNT_CLIENT
          $RETRANSMIT_COUNT_SERVER
          $SUPPORT_IPV4
          $SUPPORT_IPV6
          $TYPE_AAAA_SUPPORT
          $CLIENT_CACHING_SUPPORT
          $RECURSIVE_SUPPORT
        );
}

END {
}
#################################
# NUT Configuration
#################################
$NUT_USE_IP_VERSION = '6';    # 4: IPv4, 6: IPv6

$NUT_IPV4_ADDR_0    = '192.168.0.10';
$NUT_IPV4_ADDR_1    = '192.168.0.11';
$NUT_IPV4_SV_PORT = '53';
$NUT_IPV4_CL_PORT = '2000';

$NUT_IPV6_ADDR_0    = '3ffe:501:ffff:100::10';
$NUT_IPV6_ADDR_1    = '3ffe:501:ffff:100::11';
$NUT_IPV6_SV_PORT = '53';
$NUT_IPV6_CL_PORT = '2000';

$NUT_EDNS0_SIZE	= '1024';

$RETRANSMIT_COUNT_CLIENT        = '3';
###bind
$RETRANSMIT_COUNT_SERVER = '4';
###djbdns
#$RETRANSMIT_COUNT_SERVER = '3';


#======================================#
# NUT Support function Check list      #
#======================================#

# AAAA
$SUPPORT_AAAA		= 1;

# EDNS0
$SUPPORT_EDNS0		= 1;

# SRV
$SUPPORT_SRV		= 1;

# NAPTR
$SUPPORT_NAPTR		= 1;

# ENUM
$SUPPORT_ENUM		= 1;

# URI
$SUPPORT_URI		= 1;

# URN
$SUPPORT_URN		= 1;

# cache
$SUPPORT_CLIENT_CACHING	= 1;

# Recursive
$SUPPORT_CLIENT_RECURSIVE	= 1;

# LIMIT TTL
$SUPPORT_LIMIT_TTL	= 1;

#======================================#
# NUT Support Application Check List   #
#======================================#

# SIP
$REQ_SIP	= 1;

# HTTP
$REQ_HTTP	= 1;

# THTTP
$REQ_THTTP	= 1;

# RCDS
$REQ_RCDS	= 1;

# STATUS
$REQ_STATUS	= 1;

# IQUERY
$REQ_IQUERY	= 1;

1;
