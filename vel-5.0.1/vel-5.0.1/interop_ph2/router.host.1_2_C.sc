# Test IP6Interop.1.2 Part C

# scenario
scenario interop {
    setup_cleanup_REF1;
    setup_cleanup_REF2;
    setup_DUMPER;
    setup_cleanup_TEST-TAR-HOST;

    test_TEST-TAR-HOST;
    test_REF1;

    cleanup_DUMPER;
}

# syncevent
syncevent start_setup setup_cleanup_REF1, setup_cleanup_REF2, setup_DUMPER, setup_cleanup_TEST-TAR-HOST;

syncevent finish_setup setup_cleanup_REF1, setup_cleanup_REF2, cleanup_DUMPER, setup_cleanup_TEST-TAR-HOST, test_TEST-TAR-HOST;

syncevent finish_router_setup test_TEST-TAR-HOST, setup_cleanup_REF1, setup_cleanup_TEST-TAR-HOST;

syncevent finish_test setup_cleanup_REF1, setup_cleanup_REF2, setup_cleanup_TEST-TAR-HOST, cleanup_DUMPER, test_TEST-TAR-HOST, test_REF1;


syncevent sync_step4 test_TEST-TAR-HOST, test_REF1;
syncevent sync_step4_finish test_TEST-TAR-HOST, test_REF1;
syncevent sync_step4_rev test_TEST-TAR-HOST, test_REF1;
syncevent sync_step4_rev_finish test_TEST-TAR-HOST, test_REF1;

# waitevnet
waitevent wait_setup test_TEST-TAR-HOST;
waitevent wait_step1 test_TEST-TAR-HOST;
waitevent wait_step2 test_TEST-TAR-HOST;
waitevent wait_step3 test_TEST-TAR-HOST;
waitevent wait_step1_rev test_TEST-TAR-HOST;
waitevent wait_step2_rev test_TEST-TAR-HOST;
waitevent wait_step3_rev test_TEST-TAR-HOST;
waitevent wait_show_topology setup_cleanup_REF1;


# test command
command test_TEST-TAR-HOST TEST-TAR-HOST {
    sync finish_router_setup;

    sync finish_setup;

    # Step 1
    print "";
    print "BASENAME> Step 20 (Spec)";
    print "BASENAME> Disable YOUR DEVICE interface connected to Network1.";
    print "BASENAME> Press Enter key for continue.";
    wait wait_step1;

    # Step 2
    print "";
    print "BASENAME> Step 21 1/2 (Spec)";
    print "BASENAME> Enable YOUR DEVICE interface on Network1.";
    print "BASENAME> Press Enter key for continue.";
    wait wait_step2;

    print "";
    print "BASENAME> Step 21 2/2 (Spec)";
    print "BASENAME> TEST-TAR-HOST enables interface on Network1.";

    delay 1;
    execute "TEST-TAR-HOST_CMD_SYSCTL_NOT_FORWARDING";
    execute "TEST-TAR-HOST_CMD_SYSCTL_ACCEPT_RA";
    execute "TEST-TAR-HOST_CMD_IFCONFIG_IF1_UP";
    execute "TEST-TAR-HOST_CMD_IFCONFIG_IF2_DOWN";
    delay 5;

    # Step 3
    print "";
    print "BASENAME> Step 22";
    print "BASENAME> Allow time for all devices on Network1 to perform Stateless Address";
    print "BASENAME> Autoconfiguration and Duplicate Address Detection.";
    print "BASENAME> Press Enter key for continue.";
    wait wait_step3;

    # Step 4
    sync sync_step4;

    sync sync_step4_finish;

    execute "TEST-TAR-HOST_CMD_IFCONFIG_IF1_DOWN";
    execute "TEST-TAR-HOST_CMD_IFCONFIG_IF1_LLA_DELETE";
    execute "TEST-TAR-HOST_CMD_IFCONFIG_IF1_PREFIX1_GA_DELETE";
    execute "TEST-TAR-HOST_CMD_SYSCTL_NOT_ACCEPT_RA";
    execute "TEST-TAR-HOST_CMD_SYSCTL_NOT_FORWARDING";
    execute "TEST-TAR-HOST_CMD_FLUSH_ROUTE_PREFIX1_IF1";
    execute "TEST-TAR-HOST_CMD_FLUSH_PREFIX_LIST";

    print "";
    print "BASENAME> Step 23 and 24 (Spec)";
    print "BASENAME> Transmitting ICMPv6 Echo Request finished.";

    # Step 1 reverse
    print "";
    print "BASENAME> Step 20 reverse (Spec)";
    print "BASENAME> Disable YOUR DEVICE interface connected to Network1.";
    print "BASENAME> Press Enter key for continue.";
    wait wait_step1_rev;

    # Step 2 reverse
    print "";
    print "BASENAME> Step 21 1/2 reverse (Spec)";
    print "BASENAME> TEST-TAR-HOST enables interface on Network1.";

    delay 1;
    execute "TEST-TAR-HOST_CMD_SYSCTL_NOT_FORWARDING";
    execute "TEST-TAR-HOST_CMD_SYSCTL_ACCEPT_RA";
    execute "TEST-TAR-HOST_CMD_IFCONFIG_IF1_UP";
    execute "TEST-TAR-HOST_CMD_IFCONFIG_IF2_DOWN";
    delay 5;

    print "";
    print "BASENAME> Step 21 2/2 reverse (Spec)";
    print "BASENAME> Enable YOUR DEVICE interface on Network1.";
    print "BASENAME> Press Enter key for continue.";
    wait wait_step2_rev;

    # Step 3 reverse
    print "";
    print "BASENAME> Step 22 reverse (Spec)";
    print "BASENAME> Allow time for all devices on Network1 to perform Stateless Address";
    print "BASENAME> Autoconfiguration and Duplicate Address Detection.";
    print "BASENAME> Press Enter key for continue.";
    wait wait_step3_rev;

    # Step 4
    sync sync_step4_rev;
    sync sync_step4_rev_finish;
    print "";
    print "BASENAME> Step 23 and 24 reverse (Spec)";
    print "BASENAME> Transmitting ICMPv6 Echo Request finished.";

    sync finish_test;
}

command test_REF1 REF1 {
    sync sync_step4;

    REF1_CMD_CLEAR_NCE_IF1;
    REF1_CMD_PRINT_NCE_IF1;
    REF1_CMD_CLEAR_NCE_IF2;
    REF1_CMD_PRINT_NCE_IF2;

    delay 2;
    print "";
    print "BASENAME> REF1 transmits ICMPv6 Echo Request to LOGO_IF1_LLA.";
    print "";
    execute "/bin/sh -c ping6 -c 5 -I REF1_IF1 TEST-TAR-HOST_IF1_LLA | tee /tmp/1.2.C.REF.TEST-TAR-HOST_NAME.result";
    execute "/bin/sh -c ping6 -c 5 -I REF1_IF1 LOGO_IF1_LLA | tee /tmp/1.2.C.REF.LOGO_NAME.result";
    delay 2;

    sync sync_step4_finish;
    execute "REF1_CMD_IFCONFIG_IF1_DOWN";
    execute "REF1_CMD_IFCONFIG_IF1_LLA_DELETE";
    execute "REF1_CMD_IFCONFIG_IF1_UP";
    sync sync_step4_rev;

    REF1_CMD_CLEAR_NCE_IF1;
    REF1_CMD_PRINT_NCE_IF1;
    REF1_CMD_CLEAR_NCE_IF2;
    REF1_CMD_PRINT_NCE_IF2;

    delay 2;
    print "";
    print "BASENAME> REF1 transmits ICMPv6 Echo Request to TEST-TAR-HOST_IF1_LLA.";
    print "";
    execute "/bin/sh -c ping6 -c 5 -I REF1_IF1 TEST-TAR-HOST_IF1_LLA | tee -a /tmp/1.2.C.REF.TEST-TAR-HOST_NAME.result";
    execute "/bin/sh -c ping6 -c 5 -I REF1_IF1 LOGO_IF1_LLA | tee -a /tmp/1.2.C.REF.LOGO_NAME.result";
    delay 2;

    sync sync_step4_rev_finish;
    sync finish_test;
}

# setup command
## REF1(REF1_NAME) runs as host
command setup_cleanup_REF1 REF1 {

    # show topology
    print "This test uses active node as described below.";
    print "";
    print "1.2.CD (Router vs Host)";
    print "";
    print "                                    Network 1";
    print "      ------+--------------+-----------+------+-";
    print "            |              |           |      |";
    print "            | 1            |           | 1    +-------------+";
    print "     TG +-----------+      |        +------+                |";
    print " +------| REF-1 (V) |      |        | LOGO |                |";
    print " |      +-----------+      |        +------+                |";
    print " |        (Host)           |        (Router)                |";
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

    sync finish_router_setup;

    execute "REF1_CMD_SYSCTL_ACCEPT_RA";
    execute "REF1_CMD_SYSCTL_NOT_FORWARDING";
    execute "REF1_CMD_IFCONFIG_IF1_UP";
    execute "REF1_CMD_IFCONFIG_IF2_DOWN";

    sync finish_setup;

    sync finish_test;

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
    execute "tcpdump -i DUMPER_IF1 -c 10000 -s 0 -w /tmp/1.2.C.LOGO_NAME.TEST-TAR-HOST_NAME.Network1.dump";
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

    sync finish_setup;

    sync finish_test;
}
