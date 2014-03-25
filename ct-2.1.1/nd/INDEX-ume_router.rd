#
# $Name: REL_2_1_1 $
#
&print:<font size=+1><B>Router Discovery</B></font>
&print:<B>- Receiving RS</B>
./startDefaultRA.seq:/dev/null:::Start to advertise the default RA (please ignore)
./routerRecvRs.seq:./routerRecvRs.def:::Verify that NUT sends RA when NUT received RS
./routerRecvRsInvalid.seq:./routerRecvRsInvalid.def:::Receiving invalid RS
./ncStateByRs4NoNce.seq:./ncStateByRs4NoNce.def:::RS vs. NONCE<br>Receiving RS while correspondent Neighbor Cache Entry is NONCE
./ncStateByRs4Incomplete.seq:./ncStateByRs4Incomplete.def:::RS vs. INCOMPLETE<br>Receiving RS while correspondent Neighbor Cache Entry is NONCE
./ncStateByRs4Reachable.seq:./ncStateByRs4Reachable.def:::RS vs. REACHABLE<br>Receiving RS while correspondent Neighbor Cache Entry is REACHABLE
./ncStateByRs4Stale.seq:./ncStateByRs4Stale.def:::RS vs. STALE<br>Receiving RS while correspondent Neighbor Cache Entry is STALE
./ncStateByRs4Probe.seq:./ncStateByRs4Probe.def:::RS vs. PROBE<br>Receiving RS while correspondent Neighbor Cache Entry is PROBE
#
&print:<B>- Sending RA</B>
./routerSendUnsolRaDefault.seq:./routerSendUnsolRaDefault.def:::Sending Unsolicited RA Intervals (interval = 16sec)
./routerSendUnsolRaDefault2.seq:./routerSendUnsolRaDefault2.def:::Sending Unsolicited RA Intervals (7sec < interval < 10sec)
./routerSendSolRaDefault.seq:./routerSendSolRaDefault.def:::Sending Solicited RA Intervals
./routerSendUnsolRaMin.seq:./routerSendUnsolRaMin.def:::Sending Unsolicited RA (min values)
./routerSendUnsolRaMax.seq:./routerSendUnsolRaMax.def:::Sending Unsolicited RA (max values)
#
&print:<B>- Receiving RA</B>
./routerRecvRa.seq:./routerRecvRa.def:::Verify that NUT ignores RA
./stopRA.seq:/dev/null:::Stop to advertise the RA (please ignore)
# EOF
