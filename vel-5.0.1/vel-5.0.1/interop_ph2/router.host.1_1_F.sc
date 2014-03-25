# Test IP6Interop.1.1 Part F

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

syncevent finish_router_setup test_TEST-TAR-HOST, setup_cleanup_REF1, setup_cleanup_TEST-TAR-HOST;

syncevent finish_test setup_cleanup_REF1, setup_cleanup_REF2, setup_cleanup_TEST-TAR-HOST, cleanup_DUMPER, test_TEST-TAR-HOST;

# waitevnet
waitevent wait_setup test_TEST-TAR-HOST;
waitevent wait_step1 test_TEST-TAR-HOST;
waitevent wait_show_topology setup_cleanup_REF1;


# test command
command test_TEST-TAR-HOST TEST-TAR-HOST {
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

    # Step 22
    print "";
    print "BASENAME> Step 22 (Spec)";
    print "BASENAME> TEST-TAR-HOST transmits ICMPv6 Echo Request.";
    print "";

    TEST-TAR-HOST_CMD_CLEAR_NCE_IF1;
    TEST-TAR-HOST_CMD_PRINT_NCE_IF1;
    TEST-TAR-HOST_CMD_CLEAR_NCE_IF2;
    TEST-TAR-HOST_CMD_PRINT_NCE_IF2;
    TEST-TAR-HOST_CMD_CLEAR_NCE_IF3;
    TEST-TAR-HOST_CMD_PRINT_NCE_IF3;
    execute "/bin/sh -c ping6 -c 5 -I TEST-TAR-HOST_IF1 ff02::1 | tee /root/1.1.F.TEST-TAR-HOST_NAME.LOGO_NAME.result";
    
    delay 3;

    # Step 24
    print "";
    print "BASENAME> Step 24 (Spec)";
    print "BASENAME> Transmit ICMPv6 Echo Request from YOUR DEVICE to";
    print "BASENAME> the All Nodes multicast address (FF02::1) and Save the command";
    print "BASENAME> result log as /tmp/1.1.F.LOGO_NAME.TEST-TAR-HOST_NAME.result.";
    print "BASENAME> Press Enter key for continue.";

    wait wait_step1;

    print "";
    print "BASENAME> Step 26 (Spec)";
    print "BASENAME> TEST-TAR-HOST transmits ICMPv6 Echo Request to the All Routers ";
    print "BASENAME> multicast address (FF02::2)";
    print "";

    TEST-TAR-HOST_CMD_CLEAR_NCE_IF1;
    TEST-TAR-HOST_CMD_PRINT_NCE_IF1;
    TEST-TAR-HOST_CMD_CLEAR_NCE_IF2;
    TEST-TAR-HOST_CMD_PRINT_NCE_IF2;
    TEST-TAR-HOST_CMD_CLEAR_NCE_IF3;
    TEST-TAR-HOST_CMD_PRINT_NCE_IF3;
    execute "/bin/sh -c ping6 -c 5 -I TEST-TAR-HOST_IF1 ff02::2 | tee -a /root/1.1.F.TEST-TAR-HOST_NAME.LOGO_NAME.result";

    delay 5;
    sync finish_test;
}

# setup command
## REF1(REF1_NAME) runs as router
command setup_cleanup_REF1 REF1 {

    # show topology
    print "This test uses active node as described below.";
    print "";
    print "1.1.DEF (Router vs Host)";
    print "";
    print "                                    Network 1";
    print "      ---------------------+-----------+------+-";
    print "                           |           |      |";
    print "                           |           | 1    +-------------+";
    print "                           |        +------+                |";
    print "                           |        | LOGO |                |";
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
    print "     |     (Host)                                           |";
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
    execute "tcpdump -i DUMPER_IF1 -c 10000 -s 0 -w /tmp/1.1.F.LOGO_NAME.TEST-TAR-HOST_NAME.Network1.dump";
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
