#
# $Name: REL_2_1_1 $
#
&print:<B>2.  Router Discovery</B>
&print:<B>2.1.  Sending RS (Host Only)</B>
./hostSendRs.seq:./hostSendRs.def:::Sending RS;
./hostSendRsAfterUnsolicitedRa.seq:./hostSendRsAfterUnsolicitedRa.def:::Sending RS after receiving unsolicited RA
./hostSendRsAfterSolicitedRa.seq:./hostSendRsAfterSolicitedRa.def:::Not sending RS after receiving solicited RA
#
&print:<B>2.2.  Receiving RS (Host Only)</B>
./hostRecvRs.seq:./hostRecvRs.def:::Ignoring RS;
#
&print:<B>2.3.  Sending RA (Host Only)</B>
#
&print:<B>2.4.  Receiving RA (Host Only)</B>
./hostRecvRaRFlag.seq:./hostRecvRaRFlag.def:::RA set IsRouter flag
./hostRecvRas.seq:./hostRecvRas.def:::Receiving multiple RAs #1
./hostRecvRas2.seq:./hostRecvRas2.def:::Receiving multiple RAs #2
./hostRecvRaInvalid.seq:./hostRecvRaInvalid.def:::Ignoring invalid RAs
./hostRecvRaReachableTime.seq:./hostRecvRaReachableTime.def:::ReachableTime vs BaseReachableTime
./hostRecvRaRLifetime0.seq:./hostRecvRaRLifetime0.def:::RouterLifetime=0
./hostRecvRaRLifetimeN.seq:./hostRecvRaRLifetimeN.def:::RouterLifetime=5
./hostRecvRaNHD.seq:./hostRecvRaNHD.def:::Next-hop Determination
./hostRecvRaURD.seq:./hostRecvRaURD.def:::The Default Router List vs Unreachability Detection
./ncStateByRa4Nonce.seq:./ncStateByRa4Nonce.def:::RA vs NONCE
./ncStateByRa4Incomplete.seq:./ncStateByRa4Incomplete.def:::RA vs INCOMPLETE
./ncStateByRa4Reachable.seq:./ncStateByRa4Reachable.def:::RA vs REACHABLE
./ncStateByRa4Stale.seq:./ncStateByRa4Stale.def:::RA vs STALE
./ncStateByRa4Probe.seq:./ncStateByRa4Probe.def:::RA vs PROBE
&print:See Also
&print:Tests about MTU option are covered by <A HREF="../pmtu/index.html">Path MTU Discovery</A>.
&print:Tests about A flag (Prefix option) are covered by <A HREF="../stateless-addrconf/index.html">Stateless Address Autoconf</A>.
&print:Tests about Preferred Lifetime (Prefix option) are covered by <A HREF="../stateless-addrconf/index.html">Stateless Address Autoconf</A>.
&print:Tests about Valid Lifetime (Prefix option) are covered by <A HREF="../stateless-addrconf/index.html">Stateless Address Autoconf</A>.
&print:Tests about Preferred Lifetime (Prefix option) are covered by <A HREF="../stateless-addrconf/index.html">Stateless Address Autoconf</A>.
&print:Tests about Prefix Length (Prefix option) are covered by <A HREF="../stateless-addrconf/index.html">Stateless Address Autoconf</A>.
&print:Tests about Prefix Address (Prefix option) are covered by <A HREF="../stateless-addrconf/index.html">Stateless Address Autoconf</A>.
#
&print:<B>2.5.  Sending RS (Router Only)</B>
#
&print:<B>2.6.  Receiving RS (Router Only)</B>
./startDefaultRA.seq:/dev/null:::Start to advertise the default RA
./routerRecvRs.seq:./routerRecvRs.def:::Receiving RS vs Sending RA
./routerRecvRsInvalid.seq:./routerRecvRsInvalid.def:::Invalid RS vs NC
./ncStateByRs4NoNce.seq:./ncStateByRs4NoNce.def:::RS vs. NONCE
./ncStateByRs4Incomplete.seq:./ncStateByRs4Incomplete.def:::RS vs. INCOMPLETE
./ncStateByRs4Reachable.seq:./ncStateByRs4Reachable.def:::RS vs. REACHABLE
./ncStateByRs4Stale.seq:./ncStateByRs4Stale.def:::RS vs. STALE
./ncStateByRs4Probe.seq:./ncStateByRs4Probe.def:::RS vs. PROBE
#
&print:<B>2.7.  Sending RA (Router Only)</B>
./routerSendUnsolRaDefault.seq:./routerSendUnsolRaDefault.def:::Sending Unsolicited RA Intervals (interval = 16sec)
./routerSendUnsolRaDefault2.seq:./routerSendUnsolRaDefault2.def:::Sending Unsolicited RA Intervals (7sec < interval < 10sec)
./routerSendSolRaDefault.seq:./routerSendSolRaDefault.def:::Sending Solicited RA Intervals
./routerSendUnsolRaMin.seq:./routerSendUnsolRaMin.def:::Sending Unsolicited RA (min values)
./routerSendUnsolRaMax.seq:./routerSendUnsolRaMax.def:::Sending Unsolicited RA (max values)
#
&print:<B>2.8.  Receiving RA (Router Only)</B>
./routerRecvRa.seq:./routerRecvRa.def:::Ignoring RA
./stopRA.seq:/dev/null:::Stop to advertise the RA
# EOF
