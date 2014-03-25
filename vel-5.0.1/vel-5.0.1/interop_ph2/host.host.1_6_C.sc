# Test IP6Interop.1.6 Part C

# scenario
scenario interop {
    setup_cleanup_REF1;
    setup_cleanup_REF2;
    setup_DUMPER;
    setup_cleanup_TEST-TAR-HOST;

    test_TEST-TAR-HOST;

    cleanup_DUMPER;
}

# syncevent
syncevent start_setup setup_cleanup_REF1, setup_cleanup_REF2, setup_DUMPER, setup_cleanup_TEST-TAR-HOST;

syncevent finish_setup setup_cleanup_REF1, setup_cleanup_REF2, cleanup_DUMPER, setup_cleanup_TEST-TAR-HOST, test_TEST-TAR-HOST;

syncevent finish_router_setup setup_cleanup_REF1, setup_cleanup_TEST-TAR-HOST;

syncevent finish_test setup_cleanup_REF1, setup_cleanup_REF2, setup_cleanup_TEST-TAR-HOST, cleanup_DUMPER, test_TEST-TAR-HOST;

# waitevent
waitevent wait_step1 test_TEST-TAR-HOST;
waitevent wait_step2 test_TEST-TAR-HOST;
waitevent wait_step3 test_TEST-TAR-HOST;
waitevent wait_show_topology setup_cleanup_REF1;

# test command
command test_TEST-TAR-HOST TEST-TAR-HOST {
    # Setup
    print "";
    print "BASENAME> Setup";
    print "BASENAME> Bring up the interface on YOUR DEVICE that is connected to Network1.";
    print "BASENAME> Allow time for YOUR DEVICE to perform Stateless Address Autoconfiguration";
    print "BASENAME> and Duplicate Address Detection.";
    print "BASENAME> Press Enter key for continue.";

    wait wait_step1;

    sync finish_setup;
    
    print "";
    print "BASENAME> Step 15 (Spec)";
    print "BASENAME> Transmit 1500 byte ICMPv6 Echo Request from the Link-Local Address";
    print "BASENAME> on YOUR DEVICE to TEST-TAR-HOST_IF1_LLA.";
    print "BASENAME> Save the test result as /tmp/1.6.C.LOGO_NAME.TEST-TAR-HOST_NAME.result";
    print "BASENAME> Press Enter key for continue.";

    wait wait_step2;

    print "";
    print "BASENAME> Step 17 (Spec)";
    print "BASENAME> TEST-TAR-HOST transmits ICMPv6 Echo Request from ";
    print "BASENAME> TEST-TAR-HOST_IF1_LLA to the Link-Local Address on YOUR DEVICE.";
    print "";

    delay 1;
    TEST-TAR-HOST_CMD_CLEAR_NCE_IF1;
    TEST-TAR-HOST_CMD_PRINT_NCE_IF1;
    TEST-TAR-HOST_CMD_CLEAR_NCE_IF2;
    TEST-TAR-HOST_CMD_PRINT_NCE_IF2;
    TEST-TAR-HOST_CMD_CLEAR_NCE_IF3;
    TEST-TAR-HOST_CMD_PRINT_NCE_IF3;
    execute "TEST-TAR-HOST_CMD_PING1_1_6 -I TEST-TAR-HOST_IF1 LOGO_IF1_LLA | tee /root/1.6.C.TEST-TAR-HOST_NAME.LOGO_NAME.result";
    execute "TEST-TAR-HOST_CMD_PING1_1_6 -I TEST-TAR-HOST_IF1 LOGO_IF1_LLA | tee -a /root/1.6.C.TEST-TAR-HOST_NAME.LOGO_NAME.result";
    execute "TEST-TAR-HOST_CMD_PING3_1_6 -I TEST-TAR-HOST_IF1 LOGO_IF1_LLA | tee -a /root/1.6.C.TEST-TAR-HOST_NAME.LOGO_NAME.result";
    delay 1;

    print "";
    print "BASENAME> Step 19 (Spec)";
    print "BASENAME> Transmit 1500 byte ICMPv6 Echo Request from the Global Address";
    print "BASENAME> on YOUR DEVICE to TEST-TAR-HOST_IF1_PREFIX1_GA.";
    print "BASENAME> Append the test result to /tmp/1.6.C.LOGO_NAME.TEST-TAR-HOST_NAME.result";
    print "BASENAME> Press Enter key for continue.";

    wait wait_step3;

    print "";
    print "BASENAME> Step 21 (Spec)";
    print "BASENAME> TEST-TAR-HOST transmits ICMPv6 Echo Request from ";
    print "BASENAME> TEST-TAR-HOST_IF1_PREFIX1_GA to the Global Address on YOUR DEVICE.";
    print "";

    delay 1;
    TEST-TAR-HOST_CMD_CLEAR_NCE_IF1;
    TEST-TAR-HOST_CMD_PRINT_NCE_IF1;
    TEST-TAR-HOST_CMD_CLEAR_NCE_IF2;
    TEST-TAR-HOST_CMD_PRINT_NCE_IF2;
    TEST-TAR-HOST_CMD_CLEAR_NCE_IF3;
    TEST-TAR-HOST_CMD_PRINT_NCE_IF3;
    execute "TEST-TAR-HOST_CMD_PING1_1_6 LOGO_IF1_PREFIX1_GA | tee -a /root/1.6.C.TEST-TAR-HOST_NAME.LOGO_NAME.result";
    execute "TEST-TAR-HOST_CMD_PING1_1_6 LOGO_IF1_PREFIX1_GA | tee -a /root/1.6.C.TEST-TAR-HOST_NAME.LOGO_NAME.result";
    execute "TEST-TAR-HOST_CMD_PING3_1_6 LOGO_IF1_PREFIX1_GA| tee -a /root/1.6.C.TEST-TAR-HOST_NAME.LOGO_NAME.result";
    delay 1;

    sync finish_test;
}


# setup command
## REF1(REF1_NAME) runs as router
command setup_cleanup_REF1 REF1 {

    # show topology
    print "This test uses active node as described below.";
    print "";
    print "1.6.C (Host vs Host)";
    print "";
    print "                                    Network 1";
    print "      ------+--------------+-----------+------+-";
    print "            |              |           |      |";
    print "            | 1            |           | 1    +-------------+";
    print "     TG +-----------+      |        +------+                |";
    print " +------| REF-1 (V) |      |        | LOGO |                |";
    print " |      +-----------+      |        +------+                |";
    print " |        (Router)         |         (Host)                 |";
    print " |                         |                                |";
    print " |                         |                                |";
    print " |                         |                                |";
    print " |                         |                                |";
    print " |                         |                                |";
    print " |                         |                                |";
    print " |                         |                                |";
    print " |                         |                                |";
    print " |                         |                                |";
    print " |                         |                                |";
    print " |                         |                                |";
    print " |                         |                                |";
    print " |    TG +----------+ 1    |                                |";
    print " |   +---| TAR* (V) |------+                                |";
    print " |   |   +----------+                                       |";
    print " |   |     (Host)                                           |";
    print " |   |                                                      |";
    print " |   |                                                      |";
    print " |   |                                                      |";
    print " |   |     Network for TG                      +---------+  |";
    print "-+---+----+-------+-                           | dump (V)|--+";
    print "          |       |                            +---------+ 1";
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
    execute "REF1_CMD_IFCONFIG_IF2_DOWN";

    delay 2;
    execute "REF1_CMD_IFCONFIG_IF1_PREFIX1_GA_ADD";
    execute "REF1_CMD_IFCONFIG_IF1_MTU_1280";

    delay 2;
    execute "REF1_CMD_RTADVD_CONF_1_6_C_1";
    execute "REF1_CMD_RTADVD_CONF_1_6_C_2";
    execute "REF1_CMD_RTADVD_CONF_1_6_C_3";
    execute "REF1_CMD_RTADVD_CONF_1_6_C_4";
    execute "REF1_CMD_RTADVD_CONF_1_6_C_5";
    execute "REF1_CMD_RTADVD_CONF_1_6_C_6";
    execute "REF1_CMD_RTADVD_CONF_1_6_C_7";
    execute "REF1_CMD_RTADVD_CONF_1_6_C_8";
    execute "REF1_CMD_RTADVD_CONF_1_6_C_9";

    execute "REF1_CMD_RTADVD_IF1";

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
    execute "REF1_CMD_IFCONFIG_IF1_PREFIX1_GA_DELETE";
}

## REF2(REF2_NAME) is disable
command setup_cleanup_REF2 REF2 {
    sync start_setup;
    execute "REF2_CMD_SYSCTL_NOT_ACCEPT_RA";
    execute "REF2_CMD_SYSCTL_NOT_FORWARDING";
    execute "REF2_CMD_IFCONFIG_IF1_DOWN";
    execute "REF2_CMD_IFCONFIG_IF2_DOWN";
    sync finish_setup;

    sync finish_test;
}

command setup_DUMPER DUMPER {
    delay 5;
    sync start_setup;
    execute "tcpdump -i DUMPER_IF1 -c 10000 -s 0 -w /tmp/1.6.C.LOGO_NAME.TEST-TAR-HOST_NAME.Network1.dump";
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

    delay 2;

    sync finish_setup;

    sync finish_test;
    execute "TEST-TAR-HOST_CMD_IFCONFIG_IF1_DOWN";
    execute "TEST-TAR-HOST_CMD_IFCONFIG_IF1_LLA_DELETE";
    execute "TEST-TAR-HOST_CMD_IFCONFIG_IF1_PREFIX1_GA_DELETE";
    execute "TEST-TAR-HOST_CMD_SYSCTL_NOT_ACCEPT_RA";
    execute "TEST-TAR-HOST_CMD_SYSCTL_NOT_FORWARDING";
    execute "TEST-TAR-HOST_CMD_FLUSH_ROUTE_PREFIX1_IF1";
    execute "TEST-TAR-HOST_CMD_FLUSH_PREFIX_LIST";
}
