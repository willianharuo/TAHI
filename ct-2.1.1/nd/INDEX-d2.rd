#
# $Name: REL_2_1_1 $
#
&print:2.  Router Discovery
&print:2.1.  Sending RS (Host Only)
&#./hostSendRs.seq:./hostSendRs.def:::Sending RS;
&#./hostSendRsAfterUnsolicitedRa.seq:./hostSendRsAfterUnsolicitedRa.def:::Sending RS after receiving unsolicited RA
&#./hostSendRsAfterSolicitedRa.seq:./hostSendRsAfterSolicitedRa.def:::Not sending RS after receiving solicited RA
#
&print:2.2.  Receiving RS (Host Only)
&#./hostRecvRs.seq:./hostRecvRs.def:::Ignoring RS;
#
&print:2.3.  Sending RA (Host Only)
#
&print:2.4.  Receiving RA (Host Only)
&#./hostRecvRaRFlag.seq:./hostRecvRaRFlag.def:::RA set IsRouter flag
&#./hostRecvRas.seq:./hostRecvRas.def:::Receiving multiple RAs #1
&#./hostRecvRas2.seq:./hostRecvRas2.def:::Receiving multiple RAs #2
&#./hostRecvRaInvalid.seq:./hostRecvRaInvalid.def:::Ingnoring invalid RAs
&#./hostRecvRaReachableTime.seq:./hostRecvRaReachableTime.def:::ReachableTIme vs BaseReachableTime
&#./hostRecvRaRLifetime0.seq:./hostRecvRaRLifetime0.def:::RouterLifetime=0
&#./hostRecvRaRLifetimeN.seq:./hostRecvRaRLifetimeN.def:::RouterLifetime=5
&#./hostRecvRaNHD.seq:./hostRecvRaNHD.def:::Next-hop Determination
&#./hostRecvRaURD.seq:./hostRecvRaURD.def:::The Default Router List vs Unreachability Detection
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
&print:2.5.  Sending RS (Router Only)
#
&print:2.6.  Receiving RS (Router Only)
#
&print:2.7.  Sending RA (Router Only)
#
&print:2.8.  Receiving RA (Router Only)
# EOF
