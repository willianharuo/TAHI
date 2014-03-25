# Test IP6Interop.1.6 Part D

# scenario
scenario interop {
    setup_cleanup_REF1;
    setup_cleanup_REF2;
    setup_DUMPER;
    setup_cleanup_TEST-TAR-ROUTER;

    test_TEST-TAR-ROUTER;

    cleanup_DUMPER;
}

# syncevent
syncevent start_setup setup_cleanup_REF1, setup_cleanup_REF2, setup_DUMPER, setup_cleanup_TEST-TAR-ROUTER;

syncevent finish_setup setup_cleanup_REF1, setup_cleanup_REF2, cleanup_DUMPER, setup_cleanup_TEST-TAR-ROUTER, test_TEST-TAR-ROUTER;

syncevent finish_router_setup test_TEST-TAR-ROUTER, setup_cleanup_REF1, setup_cleanup_REF2, setup_cleanup_TEST-TAR-ROUTER;

syncevent finish_test setup_cleanup_REF1, setup_cleanup_REF2, setup_cleanup_TEST-TAR-ROUTER, cleanup_DUMPER, test_TEST-TAR-ROUTER;

# waitevent
waitevent wait_step1 test_TEST-TAR-ROUTER;
waitevent wait_show_topology setup_cleanup_REF1;
waitevent wait_setup test_TEST-TAR-ROUTER;

# test command
command test_TEST-TAR-ROUTER TEST-TAR-ROUTER {
    sync finish_router_setup;

    sync finish_setup;

    print "";
    print "BASENAME> Step 24 (Spec)";
    print "BASENAME> Allow time for all devices on Network1 to perform Stateless Address";
    print "BASENAME> Autoconfiguration and Duplicate Address Detection.";

    print "";
    print "BASENAME> Step 24 (Spec)";
    print "BASENAME> TEST-TAR-ROUTER transmits ICMPv6 Echo Request to LOGO_IF1_PREFIX1_GA";
    print "BASENAME> Press Enter key for continue.";
    print "";

    wait wait_setup;

    delay 2;
    TEST-TAR-ROUTER_CMD_CLEAR_NCE_IF1;
    TEST-TAR-ROUTER_CMD_PRINT_NCE_IF1;
    TEST-TAR-ROUTER_CMD_CLEAR_NCE_IF2;
    TEST-TAR-ROUTER_CMD_PRINT_NCE_IF2;
    TEST-TAR-ROUTER_CMD_CLEAR_NCE_IF3;
    TEST-TAR-ROUTER_CMD_PRINT_NCE_IF3;
    execute "TEST-TAR-ROUTER_CMD_PING1_1_6 LOGO_IF1_PREFIX1_GA | tee /root/1.6.D.TEST-TAR-ROUTER_NAME.LOGO_NAME.result";
    execute "TEST-TAR-ROUTER_CMD_PING1_1_6 LOGO_IF1_PREFIX1_GA | tee -a /root/1.6.D.TEST-TAR-ROUTER_NAME.LOGO_NAME.result";
    execute "TEST-TAR-ROUTER_CMD_PING3_1_6 LOGO_IF1_PREFIX1_GA | tee -a /root/1.6.D.TEST-TAR-ROUTER_NAME.LOGO_NAME.result";
    delay 2;

    print "";
    print "BASENAME> Step 26 (Spec)";
    print "BASENAME> Transmit 1500 byte ICMPv6 Echo Request to TEST-TAR-ROUTER_IF3_PREFIX3_GA from YOUR DEVICE.";
    print "BASENAME> Save the result as /tmp/1.6.D.LOGO_NAME.TEST-TAR-ROUTER_NAME.result";
    print "Press Enter key for continue.";

    wait wait_step1;
    sync finish_test;
}


# setup command
## REF1(REF1_NAME) runs as router
command setup_cleanup_REF1 REF1 {

    # show topology
    print "This test uses active node as described below.";
    print "";
    print "1.6.D (Host vs Router)";
    print "";
    print "                                    Network 1";
    print "      ------+--------------------------+------+-";
    print "            |                          |      |";
    print "            | 1                        | 1    +-------------+";
    print "     TG +-----------+               +------+                |";
    print " +------| REF-1 (V) |               | LOGO | (Host)         |";
    print " |      +-----------+               +------+                |";
    print " |          | 2                                             |";
    print " |          |                       Network 2               |";
    print " |    ------+------+-------------------------+--            |";
    print " |                 |                         |              |";
    print " |               1 |                         +------+       |";
    print " |       TG +----------+                            |       |";
    print " | +--------| REF-2 (V)|                            |       |";
    print " | |        +----------+                            |       |";
    print " | |             2 |                                |       |";
    print " | |               |                Network 3       |       |";
    print " | |  ------+------+------------------------+---    |       |";
    print " | |        |                               |       |       |";
    print " | |        | 3                             |       |       |";
    print " | |  TG +----------+                       |       |       |";
    print " | | +---| TAR* (V) |                       |       |       |";
    print " | | |   +----------+                       |       |       |";
    print " | | |     (Router)                         |       |       |";
    print " | | |                                      |       |       |";
    print " | | |                                      |       |       |";
    print " | | |                                      |       | 2     |";
    print " | | |     Network for TG                   |  +---------+  |";
    print "-+-+-+----+-------+-                        +--| dump (V)|--+";
    print "          |       |                          3 +---------+ 1";
    print "       TG |       |                                 | TG";
    print "    +---------+   +---------------------------------+";
    print "    | vel mgr |";
    print "    +---------+";
    print "";
    print "(V) means vel agent is running.";
    print "";
    print "BASENAME> Press Enter key to start test.";
    wait wait_show_topology;
    #

    sync start_setup;

    execute "REF1_CMD_SYSCTL_NOT_ACCEPT_RA";
    execute "REF1_CMD_SYSCTL_FORWARDING";
    execute "REF1_CMD_IFCONFIG_IF1_UP";
    execute "REF1_CMD_IFCONFIG_IF2_UP";

    delay 2;
    execute "REF1_CMD_IFCONFIG_IF1_PREFIX1_GA_ADD";
    execute "REF1_CMD_IFCONFIG_IF2_PREFIX2_GA_ADD";

    delay 2;
    execute "REF1_CMD_IFCONFIG_IF1_MTU_1500";
    execute "REF1_CMD_IFCONFIG_IF2_MTU_1280";

    delay 2;
    execute "REF1_CMD_RTADVD_CONF_1_6_D1_1";
    execute "REF1_CMD_RTADVD_CONF_1_6_D1_2";
    execute "REF1_CMD_RTADVD_CONF_1_6_D1_3";
    execute "REF1_CMD_RTADVD_CONF_1_6_D1_4";
    execute "REF1_CMD_RTADVD_CONF_1_6_D1_5";
    execute "REF1_CMD_RTADVD_CONF_1_6_D1_6";
    execute "REF1_CMD_RTADVD_CONF_1_6_D1_7";
    execute "REF1_CMD_RTADVD_CONF_1_6_D1_8";
    execute "REF1_CMD_RTADVD_CONF_1_6_D1_9";
    execute "REF1_CMD_RTADVD_CONF_1_6_D1_A";
    execute "REF1_CMD_RTADVD_CONF_1_6_D1_B";
    execute "REF1_CMD_RTADVD_CONF_1_6_D1_C";
    execute "REF1_CMD_RTADVD_CONF_1_6_D1_D";
    execute "REF1_CMD_RTADVD_CONF_1_6_D1_E";
    execute "REF1_CMD_RTADVD_CONF_1_6_D1_F";
    execute "REF1_CMD_RTADVD_CONF_1_6_D1_G";

    execute "REF1_CMD_RTADVD_IFS_1_2";

    sync finish_router_setup;

    delay 2;
    execute "REF1_CMD_1_6_D1_ADD_ROUTE";
    delay 2;

    sync finish_setup;

    sync finish_test;
    execute "REF1_CMD_STOP_RTADVD";
    execute "REF1_CMD_RM_RTADVD_PID";
    execute "REF1_CMD_IFCONFIG_IF1_DOWN";
    execute "REF1_CMD_IFCONFIG_IF1_LLA_DELETE";
    execute "REF1_CMD_IFCONFIG_IF1_PREFIX1_GA_DELETE";
    execute "REF1_CMD_IFCONFIG_IF2_DOWN";
    execute "REF1_CMD_IFCONFIG_IF2_LLA_DELETE";
    execute "REF1_CMD_IFCONFIG_IF2_PREFIX2_GA_DELETE";
    execute "REF1_CMD_SYSCTL_NOT_ACCEPT_RA";
    execute "REF1_CMD_SYSCTL_NOT_FORWARDING";
    execute "REF1_CMD_FLUSH_ROUTE_PREFIX1_IF1";
    execute "REF1_CMD_FLUSH_ROUTE_PREFIX2_IF2";
    execute "REF1_CMD_FLUSH_ROUTE_STATIC_PREFIX1";
    execute "REF1_CMD_FLUSH_ROUTE_STATIC_PREFIX2";
    execute "REF1_CMD_FLUSH_ROUTE_STATIC_PREFIX3";
    execute "REF1_CMD_FLUSH_PREFIX_LIST";
    REF1_CMD_CLEAR_NCE_IF1;
    REF1_CMD_PRINT_NCE_IF1;
    REF1_CMD_CLEAR_NCE_IF2;
    REF1_CMD_PRINT_NCE_IF2;
}

## REF2(REF2_NAME) runs as router
command setup_cleanup_REF2 REF2 {
    sync start_setup;

    execute "REF2_CMD_SYSCTL_NOT_ACCEPT_RA";
    execute "REF2_CMD_SYSCTL_FORWARDING";
    execute "REF2_CMD_IFCONFIG_IF1_UP";
    execute "REF2_CMD_IFCONFIG_IF2_UP";

    delay 2;
    execute "REF2_CMD_IFCONFIG_IF1_PREFIX2_GA_ADD";
    execute "REF2_CMD_IFCONFIG_IF2_PREFIX3_GA_ADD";

    delay 2;
    execute "REF2_CMD_IFCONFIG_IF1_MTU_1280";
    execute "REF2_CMD_IFCONFIG_IF2_MTU_1500";

    delay 2;
    execute "REF2_CMD_RTADVD_CONF_1_6_D2_1";
    execute "REF2_CMD_RTADVD_CONF_1_6_D2_2";
    execute "REF2_CMD_RTADVD_CONF_1_6_D2_3";
    execute "REF2_CMD_RTADVD_CONF_1_6_D2_4";
    execute "REF2_CMD_RTADVD_CONF_1_6_D2_5";
    execute "REF2_CMD_RTADVD_CONF_1_6_D2_6";
    execute "REF2_CMD_RTADVD_CONF_1_6_D2_7";
    execute "REF2_CMD_RTADVD_CONF_1_6_D2_8";
    execute "REF2_CMD_RTADVD_CONF_1_6_D2_9";
    execute "REF2_CMD_RTADVD_CONF_1_6_D2_A";
    execute "REF2_CMD_RTADVD_CONF_1_6_D2_B";
    execute "REF2_CMD_RTADVD_CONF_1_6_D2_C";
    execute "REF2_CMD_RTADVD_CONF_1_6_D2_D";
    execute "REF2_CMD_RTADVD_CONF_1_6_D2_E";
    execute "REF2_CMD_RTADVD_CONF_1_6_D2_F";
    execute "REF2_CMD_RTADVD_CONF_1_6_D2_G";

    execute "REF2_CMD_RTADVD_IFS_1_2";

    sync finish_router_setup;

    delay 2;
    execute "REF2_CMD_1_6_D2_ADD_ROUTE";
    delay 2;

    sync finish_setup;

    sync finish_test;
    execute "REF2_CMD_STOP_RTADVD";
    execute "REF2_CMD_RM_RTADVD_PID";
    execute "REF2_CMD_IFCONFIG_IF1_DOWN";
    execute "REF2_CMD_IFCONFIG_IF1_LLA_DELETE";
    execute "REF2_CMD_IFCONFIG_IF1_PREFIX2_GA_DELETE";
    execute "REF2_CMD_IFCONFIG_IF2_DOWN";
    execute "REF2_CMD_IFCONFIG_IF2_LLA_DELETE";
    execute "REF2_CMD_IFCONFIG_IF2_PREFIX3_GA_DELETE";
    execute "REF2_CMD_SYSCTL_NOT_ACCEPT_RA";
    execute "REF2_CMD_SYSCTL_NOT_FORWARDING";
    execute "REF2_CMD_FLUSH_ROUTE_PREFIX2_IF1";
    execute "REF2_CMD_FLUSH_ROUTE_PREFIX3_IF2";
    execute "REF2_CMD_FLUSH_PREFIX_LIST";
    execute "REF2_CMD_FLUSH_ROUTE_STATIC_PREFIX1";
    execute "REF2_CMD_FLUSH_ROUTE_STATIC_PREFIX2";
    execute "REF2_CMD_FLUSH_ROUTE_STATIC_PREFIX3";
    REF2_CMD_CLEAR_NCE_IF1;
    REF2_CMD_PRINT_NCE_IF1;
    REF2_CMD_CLEAR_NCE_IF2;
    REF2_CMD_PRINT_NCE_IF2;
}


command setup_DUMPER DUMPER {
    delay 5;
    sync start_setup;
    execute "/bin/sh -c /usr/sbin/tcpdump -i DUMPER_IF1 -c 10000 -s 0 -w /tmp/1.6.D.LOGO_NAME.TEST-TAR-ROUTER_NAME.Network1.dump&";
    execute "/bin/sh -c /usr/sbin/tcpdump -i DUMPER_IF2 -c 10000 -s 0 -w /tmp/1.6.D.LOGO_NAME.TEST-TAR-ROUTER_NAME.Network2.dump&";
    execute "/bin/sh -c /usr/sbin/tcpdump -i DUMPER_IF3 -c 10000 -s 0 -w /tmp/1.6.D.LOGO_NAME.TEST-TAR-ROUTER_NAME.Network3.dump&";
}

command cleanup_DUMPER DUMPER {
    delay 10;
    sync finish_setup;
    sync finish_test;
    delay 5;
    execute "killall tcpdump";
}

## TEST-TAR-ROUTER_TYPE(TEST-TAR-ROUTER_NAME)
command setup_cleanup_TEST-TAR-ROUTER TEST-TAR-ROUTER {
    sync start_setup;

    execute "TEST-TAR-ROUTER_CMD_SYSCTL_NOT_ACCEPT_RA";
    execute "TEST-TAR-ROUTER_CMD_SYSCTL_FORWARDING";
    execute "TEST-TAR-ROUTER_CMD_IFCONFIG_IF1_DOWN";
    execute "TEST-TAR-ROUTER_CMD_IFCONFIG_IF2_DOWN";
    execute "TEST-TAR-ROUTER_CMD_IFCONFIG_IF3_UP";

    delay 2;
    execute "TEST-TAR-ROUTER_CMD_IFCONFIG_IF3_PREFIX3_GA_ADD";

    delay 2;
    execute "TEST-TAR-ROUTER_CMD_IFCONFIG_IF3_MTU_1500";

    delay 2;
    execute "TEST-TAR-ROUTER_CMD_RTADVD_CONF_1_6_D3_1";
    execute "TEST-TAR-ROUTER_CMD_RTADVD_CONF_1_6_D3_2";
    execute "TEST-TAR-ROUTER_CMD_RTADVD_CONF_1_6_D3_3";
    execute "TEST-TAR-ROUTER_CMD_RTADVD_CONF_1_6_D3_4";
    execute "TEST-TAR-ROUTER_CMD_RTADVD_CONF_1_6_D3_5";
    execute "TEST-TAR-ROUTER_CMD_RTADVD_CONF_1_6_D3_6";
    execute "TEST-TAR-ROUTER_CMD_RTADVD_CONF_1_6_D3_7";
    execute "TEST-TAR-ROUTER_CMD_RTADVD_CONF_1_6_D3_8";

    execute "TEST-TAR-ROUTER_CMD_RTADVD_IF3";

    sync finish_router_setup;

    delay 10;
    execute "TEST-TAR-ROUTER_CMD_1_6_D3_ADD_ROUTE";
    delay 2;

    sync finish_setup;

    sync finish_test;
    execute "TEST-TAR-ROUTER_CMD_STOP_RTADVD";
    execute "TEST-TAR-ROUTER_CMD_RM_RTADVD_PID";
    execute "TEST-TAR-ROUTER_CMD_IFCONFIG_IF1_DOWN";
    execute "TEST-TAR-ROUTER_CMD_IFCONFIG_IF2_DOWN";
    execute "TEST-TAR-ROUTER_CMD_IFCONFIG_IF3_DOWN";
    execute "TEST-TAR-ROUTER_CMD_IFCONFIG_IF3_LLA_DELETE";
    execute "TEST-TAR-ROUTER_CMD_IFCONFIG_IF3_PREFIX3_GA_DELETE";
    execute "TEST-TAR-ROUTER_CMD_SYSCTL_NOT_ACCEPT_RA";
    execute "TEST-TAR-ROUTER_CMD_SYSCTL_NOT_FORWARDING";
    execute "TEST-TAR-ROUTER_CMD_FLUSH_ROUTE_PREFIX1_IF3";
    execute "TEST-TAR-ROUTER_CMD_FLUSH_PREFIX_LIST";
}
