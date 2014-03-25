# Test IP6Interop.1.5

# scenario
scenario interop {
    setup_cleanup_REF1;
    setup_cleanup_REF2;
    setup_DUMPER;
    setup_cleanup_TEST-TAR-HOST;

    test_TEST-TAR-HOST;
    test_REF2;

    cleanup_DUMPER;
}

# syncevent
syncevent start_setup setup_cleanup_REF1, setup_cleanup_REF2, setup_DUMPER, setup_cleanup_TEST-TAR-HOST;

syncevent finish_setup setup_cleanup_REF1, setup_cleanup_REF2, cleanup_DUMPER, setup_cleanup_TEST-TAR-HOST, test_TEST-TAR-HOST, test_REF2;

syncevent finish_router_setup test_TEST-TAR-HOST, test_REF2, setup_cleanup_REF1, setup_cleanup_REF2, setup_cleanup_TEST-TAR-HOST;

syncevent finish_test setup_cleanup_REF1, setup_cleanup_REF2, setup_cleanup_TEST-TAR-HOST, cleanup_DUMPER, test_TEST-TAR-HOST, test_REF2;

syncevent sync_step2 test_TEST-TAR-HOST, test_REF2;

# waitevent
waitevent wait_step1 test_TEST-TAR-HOST;
waitevent wait_step2 test_TEST-TAR-HOST;
waitevent wait_show_topology setup_cleanup_REF1;


# test command
command test_TEST-TAR-HOST TEST-TAR-HOST {
    # Step 1
    print "";
    print "BASENAME> Setup 1/2 (Spec)";
    print "BASENAME> Configure YOUR DEVICE to trasnmit Router Advertisements to";
    print "BASENAME> only Network 1.";
    print "BASENAME> Press Enter key for continue.";

    wait wait_step1;

    sync finish_router_setup;

    # Step 2
    print "";
    print "BASENAME> Setup 2/2 (Spec)";
    print "BASENAME> Configure a static route on YOUR DEVICE indicating REF1_IF1_LLA";
    print "BASENAME> as the next hop for Netowrk 2.";
    print "BASENAME> Press Enter key for continue.";

    wait wait_step2;

    sync finish_setup;

    sync sync_step2;

    sync finish_test;
}

command test_REF2 REF2 {
    sync finish_router_setup;

    sync finish_setup;

    sync sync_step2;

    print "";
    print "BASENAME> Step 1 (Spec)";
    print "BASENAME> REF2 transmits ICMPv6 Echo Request to the Global Address of the YOUR DEVICE.";
    print "";

    delay 1;
    execute "/bin/sh -c ping6 -c 1 TEST-TAR-HOST_IF1_PREFIX1_GA | tee /tmp/1.5.REF.TEST-TAR-HOST_NAME.result";
    delay 2;

    print "";
    print "BASENAME> Step 4 (Spec)";
    print "BASENAME> REF2 transmits ICMPv6 Echo Request to the Global Address of the YOUR DEVICE.";
    print "";

    execute "/bin/sh -c ping6 -c 5 TEST-TAR-HOST_IF1_PREFIX1_GA | tee -a /tmp/1.5.REF.TEST-TAR-HOST_NAME.result";

    delay 2;

    sync finish_test;
}


# setup command
## REF1(REF1_NAME) runs as router
command setup_cleanup_REF1 REF1 {

    # show topology
    print "This test uses active node as described below.";
    print "";
    print "1.5 (Router vs Host)";
    print "";
    print "                                    Network 1";
    print "      ------+--------------+-----------+------+-";
    print "            |              |           |      |";
    print "            | 1            |           | 1    +-------------+";
    print "     TG +-----------+      |        +------+                |";
    print " +------| REF-1 (V) |      |        | LOGO | (Router)       |";
    print " |      +-----------+      |        +------+                |";
    print " |          | 2            |                                |";
    print " |          |              |        Network 2               |";
    print " |    ------+------+-------------------+-----+--            |";
    print " |                 |       |                 |              |";
    print " |               1 |       |                 +------+       |";
    print " |       TG +----------+   |                        |       |";
    print " | +--------| REF-2 (V)|   |                        |       |";
    print " | |        +----------+   |                        |       |";
    print " | |                       |                        |       |";
    print " | |                       |                        |       |";
    print " | |                       |                        |       |";
    print " | |                       |                        |       |";
    print " | |                       |                        |       |";
    print " | |  TG +----------+ 1    |                        |       |";
    print " | | +---| TAR* (V) |------+                        |       |";
    print " | | |   +----------+                               |       |";
    print " | | |     (Host)                                   |       |";
    print " | | |                                              |       |";
    print " | | |                                              |       |";
    print " | | |                                              | 2     |";
    print " | | |     Network for TG                      +---------+  |";
    print "-+-+-+----+-------+-                           | dump (V)|--+";
    print "          |       |                            +---------+ 1";
    print "       TG |       |                                 | TG";
    print "    +---------+   +---------------------------------+";
    print "    | vel mgr |";
    print "    +---------+";
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
    execute "REF1_CMD_RTADVD_CONF_1_5_1";
    execute "REF1_CMD_RTADVD_CONF_1_5_2";
    execute "REF1_CMD_RTADVD_CONF_1_5_3";
    execute "REF1_CMD_RTADVD_CONF_1_5_4";
    execute "REF1_CMD_RTADVD_CONF_1_5_5";
    execute "REF1_CMD_RTADVD_CONF_1_5_6";
    execute "REF1_CMD_RTADVD_CONF_1_5_7";
    execute "REF1_CMD_RTADVD_CONF_1_5_8";

    execute "REF1_CMD_RTADVD_IF2";

    delay 2;
    execute "REF1_CMD_IFCONFIG_IF1_PREFIX2_GA_DELETE";
    delay 2;

    sync finish_router_setup;

    sync finish_setup;

    sync finish_test;

    execute "REF1_CMD_STOP_RTADVD";
    execute "REF1_CMD_RM_RTADVD_PID";
    execute "REF1_CMD_SYSCTL_NOT_ACCEPT_RA";
    execute "REF1_CMD_SYSCTL_NOT_FORWARDING";
    REF1_CMD_CLEAR_NCE_IF1;
    REF1_CMD_PRINT_NCE_IF1;
    REF1_CMD_CLEAR_NCE_IF2;
    REF1_CMD_PRINT_NCE_IF2;
    execute "REF1_CMD_IFCONFIG_IF1_DOWN";
    execute "REF1_CMD_IFCONFIG_IF2_DOWN";
}

## REF2(REF2_NAME) runs as host
command setup_cleanup_REF2 REF2 {
    sync start_setup;

    sync finish_router_setup;

    execute "REF2_CMD_SYSCTL_ACCEPT_RA";
    execute "REF2_CMD_SYSCTL_NOT_FORWARDING";
    execute "REF2_CMD_IFCONFIG_IF1_UP";
    execute "REF2_CMD_IFCONFIG_IF2_DOWN";
    execute "REF2_CMD_RTSOL_IF1";

    delay 2;

    sync finish_setup;

    sync finish_test;

    execute "REF2_CMD_SYSCTL_NOT_ACCEPT_RA";
    execute "REF2_CMD_SYSCTL_NOT_FORWARDING";
    REF2_CMD_CLEAR_NCE_IF1;
    REF2_CMD_PRINT_NCE_IF1;
    REF2_CMD_CLEAR_NCE_IF2;
    REF2_CMD_PRINT_NCE_IF2;
    execute "REF2_CMD_IFCONFIG_IF1_DOWN";
    execute "REF2_CMD_IFCONFIG_IF2_DOWN";
    execute "REF2_CMD_IFCONFIG_IF1_PREFIX2_GA_DELETE";
}

command setup_DUMPER DUMPER {
    delay 5;
    sync start_setup;
    execute "/bin/sh -c /usr/sbin/tcpdump -i DUMPER_IF1 -c 10000 -s 0 -w /tmp/1.5.LOGO_NAME.TEST-TAR-HOST_NAME.Network1.dump&";
    execute "/bin/sh -c /usr/sbin/tcpdump -i DUMPER_IF2 -c 10000 -s 0 -w /tmp/1.5.LOGO_NAME.TEST-TAR-HOST_NAME.Network2.dump&";
}

command cleanup_DUMPER DUMPER {
    delay 10;
    sync finish_setup;
    sync finish_test;
    delay 5;
    execute "killall tcpdump";
}

## TEST-TAR-HOST_TYPE(TEST-TAR-HOST_NAME)
command setup_cleanup_TEST-TAR-HOST TEST-TAR-HOST {
    sync start_setup;

    sync finish_router_setup;

    execute "TEST-TAR-HOST_CMD_SYSCTL_NOT_FORWARDING";
    execute "TEST-TAR-HOST_CMD_SYSCTL_ACCEPT_RA";
    execute "TEST-TAR-HOST_CMD_IFCONFIG_IF1_UP";
    execute "TEST-TAR-HOST_CMD_IFCONFIG_IF2_DOWN";
    execute "TEST-TAR-HOST_CMD_RTSOL_IF1";

    delay 5;

    sync finish_setup;

    sync finish_test;
    execute "TEST-TAR-HOST_CMD_IFCONFIG_IF1_DOWN";
    execute "TEST-TAR-HOST_CMD_IFCONFIG_IF1_LLA_DELETE";
    execute "TEST-TAR-HOST_CMD_IFCONFIG_IF1_PREFIX1_GA_DELETE";
    execute "TEST-TAR-HOST_CMD_IFCONFIG_IF2_DOWN";
    execute "TEST-TAR-HOST_CMD_SYSCTL_NOT_ACCEPT_RA";
    execute "TEST-TAR-HOST_CMD_SYSCTL_NOT_FORWARDING";
    execute "TEST-TAR-HOST_CMD_FLUSH_ROUTE_PREFIX1_IF1";
    execute "TEST-TAR-HOST_CMD_FLUSH_ROUTE_PREFIX2_IF1";
    execute "TEST-TAR-HOST_CMD_FLUSH_ROUTE_REDIRECT";
    execute "TEST-TAR-HOST_CMD_FLUSH_PREFIX_LIST";
}
