#
# $Name: REL_2_1_1 $
#
# $TAHI: ct/nd/INDEX-ume.rd,v 1.4 2003/06/11 09:00:00 akisada Exp $
# INDEX file for ume
#
&print:<font size=+1><B>Router Discovery</B></font>
&print:<B>- Sending RS</B>
./hostSendRs.seq:./hostSendRs.def:::Sending RS
./hostSendRsAfterUnsolicitedRa.seq:./hostSendRsAfterUnsolicitedRa.def:::Sending RS after receiving unsolicited RA
./hostSendRsAfterSolicitedRa.seq:./hostSendRsAfterSolicitedRa.def:::Not sending RS after receiving solicited RA
#
&print:<B>- Receiving RS</B>
./hostRecvRs.seq:./hostRecvRs.def:::Ignoring RS
#
&print:<B>- Receiving RA</B>
./hostRecvRaRFlag.seq:./hostRecvRaRFlag.def:::Verify IsRouter flag when Receiving RA
./hostRecvRas.seq:./hostRecvRas.def:::Receiving multiple RAs #1
./hostRecvRas2.seq:./hostRecvRas2.def:::Receiving multiple RAs #2
./hostRecvRaInvalid.seq:./hostRecvRaInvalid.def:::Ignoring invalid RAs
./hostRecvRaReachableTime.seq:./hostRecvRaReachableTime.def:::ReachableTime vs BaseReachableTime<br>Verify ReachableTime when receiving RA with ReachableTime
./hostRecvRaRLifetime0.seq:./hostRecvRaRLifetime0.def:::Verify RouterLifetime when receiving RA with RouterLifetime=0
./hostRecvRaRLifetimeN.seq:./hostRecvRaRLifetimeN.def:::Verify RouterLifetime when receiving RA with RouterLifetime=5
./hostRecvRaNHD.seq:./hostRecvRaNHD.def:::Verify Next-hop Determination
./hostRecvRaURD.seq:./hostRecvRaURD.def:::Verify Unreachability Detection
./ncStateByRa4Nonce.seq:./ncStateByRa4Nonce.def:::RA vs NONCE<br>Receiving RA while correspondent Neighbor Cache Entry is NONE
./ncStateByRa4Incomplete.seq:./ncStateByRa4Incomplete.def:::RA vs INCOMPLETE<br>Receiving RA while correspondent Neighbor Cache Entry is INCOMPLETE
./ncStateByRa4Reachable.seq:./ncStateByRa4Reachable.def:::RA vs REACHABLE<br>Receiving RA while correspondent Neighbor Cache Entry is REACHABLE
./ncStateByRa4Stale.seq:./ncStateByRa4Stale.def:::RA vs STALE<br>Receiving RA while correspondent Neighbor Cache Entry is STALE
./ncStateByRa4Probe.seq:./ncStateByRa4Probe.def:::RA vs PROBE<br>Receiving RA while correspondent Neighbor Cache Entry is PROBE
# EOF
