# Test IP6Interop.1.1 Part G

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

syncevent finish_router_setup test_TEST-TAR-ROUTER, setup_cleanup_REF1, setup_cleanup_TEST-TAR-ROUTER;

syncevent finish_test setup_cleanup_REF1, setup_cleanup_REF2, setup_cleanup_TEST-TAR-ROUTER, cleanup_DUMPER, test_TEST-TAR-ROUTER;

# waitevnet
waitevent wait_setup test_TEST-TAR-ROUTER;
waitevent wait_step1 test_TEST-TAR-ROUTER;
waitevent wait_show_topology setup_cleanup_REF1;


# test command
command test_TEST-TAR-ROUTER TEST-TAR-ROUTER {
    sync finish_router_setup;

    sync finish_setup;

    # Setup 1
    print "";
    print "BASENAME> Setup";
    print "BASENAME> You can initialize YOUR DEVICE.";
    print "BASENAME> Allow time for all devices to perform stateless address";
    print "BASENAME> autoconfiguration and Duplicate Address Detection.";
    print "BASENAME> Press Enter key for continue.";

    wait wait_setup;

    # Step 27
    print "";
    print "BASENAME> Step 27 (Spec)";
    print "BASENAME> Transmit ICMPv6 Echo Request from YOUR DEVICE to TEST-TAR-ROUTER";
    print "BASENAME> Link-Local Address TEST-TAR-ROUTER_IF1_LLA and Save the command ";
    print "BASENAME> result log as /tmp/1.1.G.LOGO_NAME.TEST-TAR-ROUTER_NAME.result.";
    print "BASENAME> Press Enter key for continue.";

    wait wait_step1;

    # Step 29
    print "";
    print "BASENAME> Step 29 (Spec)";
    TEST-TAR-ROUTER_CMD_CLEAR_NCE_IF1;
    TEST-TAR-ROUTER_CMD_PRINT_NCE_IF1;
    TEST-TAR-ROUTER_CMD_CLEAR_NCE_IF2;
    TEST-TAR-ROUTER_CMD_PRINT_NCE_IF2;
    TEST-TAR-ROUTER_CMD_CLEAR_NCE_IF3;
    TEST-TAR-ROUTER_CMD_PRINT_NCE_IF3;
    execute "/bin/sh -c ping6 -c 5 -I TEST-TAR-ROUTER_IF1 LOGO_IF1_LLA | tee /root/1.1.G.TEST-TAR-ROUTER_NAME.LOGO_NAME.result";
    
    delay 5;
    sync finish_test;
}

# setup command
## REF1(REF1_NAME) runs as router
command setup_cleanup_REF1 REF1 {

    # show topology
    print "This test uses active node as described below.";
    print "";
    print "1.1.GHI (Router vs Router)";
    print "";
    print "                                    Network 1";
    print "      ---------------------+-----------+------+-";
    print "                           |           |      |";
    print "                           |           | 1    +-------------+";
    print "                           |        +------+                |";
    print "                           |        | LOGO | (Router)       |";
    print "                           |        +------+                |";
    print "                           |                                |";
    print "                           |                                |";
    print "                           |                                |";
    print "                           |                                |";
    print "                           |                                |";
    print "                           |                                |";
    print "                           |                                |";
    print "                           |                                |";
    print "                           |                                |";
    print "                           |                                |";
    print "                           |                                |";
    print "                           |                                |";
    print "                           |                                |";
    print "      TG +----------+ 1    |                                |";
    print "     +---| TAR* (V) |------+                                |";
    print "     |   +----------+                                       |";
    print "     |     (Router)                                         |";
    print "     |                                                      |";
    print "     |                                                      |";
    print "     |                                                      |";
    print "     |     Network for TG                      +---------+  |";
    print "-----+----+-------+-                           | dump (V)|--+";
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
    execute "REF1_CMD_SYSCTL_NOT_FORWARDING";
    execute "REF1_CMD_IFCONFIG_IF1_DOWN";
    execute "REF1_CMD_IFCONFIG_IF2_DOWN";

    delay 2;

    sync finish_router_setup;

    sync finish_setup;

    sync finish_test;
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
    execute "tcpdump -i DUMPER_IF1 -c 10000 -s 0 -w /tmp/1.1.G.LOGO_NAME.TEST-TAR-ROUTER_NAME.Network1.dump";
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
    execute "TEST-TAR-ROUTER_CMD_IFCONFIG_IF1_UP";
    execute "TEST-TAR-ROUTER_CMD_IFCONFIG_IF2_DOWN";

    delay 2;
    execute "TEST-TAR-ROUTER_CMD_IFCONFIG_IF1_PREFIX1_GA_ADD";

    delay 2;
    execute "TEST-TAR-ROUTER_CMD_RTADVD_CONF_GENERIC_1";
    execute "TEST-TAR-ROUTER_CMD_RTADVD_CONF_GENERIC_2";
    execute "TEST-TAR-ROUTER_CMD_RTADVD_CONF_GENERIC_3";
    execute "TEST-TAR-ROUTER_CMD_RTADVD_CONF_GENERIC_4";
    execute "TEST-TAR-ROUTER_CMD_RTADVD_CONF_GENERIC_5";
    execute "TEST-TAR-ROUTER_CMD_RTADVD_CONF_GENERIC_6";
    execute "TEST-TAR-ROUTER_CMD_RTADVD_CONF_GENERIC_7";
    execute "TEST-TAR-ROUTER_CMD_RTADVD_CONF_GENERIC_8";

    execute "TEST-TAR-ROUTER_CMD_RTADVD_IF1";

    sync finish_router_setup;

    sync finish_setup;

    sync finish_test;
    execute "TEST-TAR-ROUTER_CMD_STOP_RTADVD";
    execute "TEST-TAR-ROUTER_CMD_RM_RTADVD_PID";
    execute "TEST-TAR-ROUTER_CMD_IFCONFIG_IF1_DOWN";
    execute "TEST-TAR-ROUTER_CMD_IFCONFIG_IF1_LLA_DELETE";
    execute "TEST-TAR-ROUTER_CMD_IFCONFIG_IF1_PREFIX1_GA_DELETE";
    execute "TEST-TAR-ROUTER_CMD_SYSCTL_NOT_ACCEPT_RA";
    execute "TEST-TAR-ROUTER_CMD_SYSCTL_NOT_FORWARDING";
    execute "TEST-TAR-ROUTER_CMD_FLUSH_ROUTE_PREFIX1_IF1";
    execute "TEST-TAR-ROUTER_CMD_FLUSH_PREFIX_LIST";
}

