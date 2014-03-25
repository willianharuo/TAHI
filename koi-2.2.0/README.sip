


README

                                                           2006/03/20
                                                         TAHI Project

[Terminology]

Tester Node (TN)
	A tester node for the conformance tests.

Node Under Test (NUT)
	A testee node for the conformance tests.

Network Under Test
	The network where the conformance tests are executed.

Tester Interface
	The network interface of TN
	hooked up to the Network Under Test.

Interface Under Test
	The network interface of NUT
	hooked up to the Network Under Test.


----------------------------------------------------------------------
[Prerequisites]

Prerequisites for TN:

    - koi-sip supports
        FreeBSD/i386 5.4-RELEASE  or higher

    - IPv6 Conformance Test Platform "v6eval"
      (You can download it from the following URL:
         http://www.tahi.org/release/ )
    
    - SIP Conformance Test Tool "sip-ct"
      (You can download it from the following URL:
         http://cert.v6pc.jp/sip-ipv6/)
    
  ### koi-sip doesn't make sense when it is used alone. ###
  ### It is used with v6eval and sip-ct.                ###

    - OpenSSL 0.9.7 or higher
      (If your system doesn't include it, y
       you can download it from the following URL:
         http://www.openssl.org/ )

----------------------------------------------------------------------
[Installation]

	koi-sip needs the following perl modules:
		- Expect
		- Digest-MD5

		% su
		# (cd /usr/ports/lang/p5-Expect && make install)
		# (cd /usr/ports/security/p5-Digest-MD5 && make install)

	koi-sip is installed the following commands:

		% tar xvfz koi-sip-X.X.X.tar.gz
		% cd koi-sip-X.X.X
		% make
		% su
		# make install
        # make -f Makefile.cert install

	In default setting, koi-sip files are installed to /usr/local/koi-sip/ .


----------------------------------------------------------------------
[Customizing tn.def]

		# cd /usr/local/koi-sip/etc
		# vi tn.def

		sample: /usr/local/koi-sip/etc/tn.def
		======================================================
		RemoteMethod	cu
		RemoteTarget	cuaa0
		Link0       fxp0     aa:aa:aa:aa:aa:aa
		======================================================

    'Link0' specifies TN's interface name which was connected to 
    Network Under Test and its MAC address.

----------------------------------------------------------------------
[Customizing nut.def]

		# cd /usr/local/koi-sip/etc
		# vi nut.def

		sample: /usr/local/koi-sip/etc/nut.def
		======================================================
		System      manual
		Link0       em0      bb:bb:bb:bb:bb:bb
		======================================================

    'Link0' specifies dummy interface name and its MAC address.
    (Interface name in nut.def is used in remote test using ssh or 
     serial line, but sip-ct doesn't support it.)



About how to perform SIP conformance test using koi-sip, 
please refer to the reference manual which is included in "sip-ct" .
