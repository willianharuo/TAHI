# Test IP6Interop.1.3 Part B

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

syncevent sync_step2 test_TEST-TAR-HOST, test_REF1;
syncevent sync_step2_finish test_TEST-TAR-HOST, test_REF1;

# waitevent
waitevent wait_step1 test_TEST-TAR-HOST;
waitevent wait_step2 test_TEST-TAR-HOST;
waitevent wait_show_topology setup_cleanup_REF1;


# test command
command test_TEST-TAR-HOST TEST-TAR-HOST {
    sync finish_router_setup;

    sync finish_setup;

    print "";
    print "BASENAME> Step 4.1 (Spec)";
    print "BASENAME> Configure YOUR DEVICE to transmit Router Advertisement";
    print "BASENAME> with two Prefixes (valid lifetime > 0)";
    print "BASENAME> Press Enter key for continue.";

    wait wait_step1;

    print "";
    print "BASENAME> Step 4.2 (Spec)";
    print "BASENAME> Allow time for TAR-Host1 to perform Stateless Address Autoconfiguration";
    print "BASENAME> and Duplicate Address Detection.";
    print "BASENAME> Press Enter key for continue.";

    wait wait_step2;

    sync sync_step2;

    print "";
    print "BASENAME> Step 5 (Spec)";
    print "BASENAME> REF1 transmits ICMPv6 Echo Request to the Prefix1 Global Address of the YOUR DEVICE.";
    print "";

    delay 2;

    print "";
    print "BASENAME> Step 7 (Spec)";
    print "BASENAME> REF1 transmits ICMPv6 Echo Request to the Prefix2 Global Address of the YOUR DEVICE.";
    print "";

    sync sync_step2_finish;

    sync finish_test;
}

command test_REF1 REF1 {
    sync sync_step2;
    delay 2;

    execute "/bin/sh -c ping6 -c 5 TEST-TAR-HOST_IF1_PREFIX1_GA | tee /tmp/1.3.B.REF.TEST-TAR-HOST_NAME.result";

    delay 2;

    execute "/bin/sh -c ping6 -c 5 TEST-TAR-HOST_IF1_PREFIX2_GA | tee -a /tmp/1.3.B.REF.TEST-TAR-HOST_NAME.result";

    delay 2;

    sync sync_step2_finish;

    sync finish_test;
}

# setup command
## REF1(REF1_NAME) runs as host
command setup_cleanup_REF1 REF1 {

    # show topology
    print "This test uses active node as described below.";
    print "";
    print "1.3.ABC (Router vs Host)";
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
    execute "REF1_CMD_RTSOL_IF1";

    delay 2;

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
    execute "tcpdump -i DUMPER_IF1 -c 10000 -s 0 -w /tmp/1.3.B.LOGO_NAME.TEST-TAR-HOST_NAME.Network1.dump";
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
