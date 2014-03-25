/*
 * Copyright (C) 1999, 2000, 2001, 2002, 2003, 2004, 2005, 2006, 2007, 2008, 2009
 * Yokogawa Electric Corporation.
 * All rights reserved.
 * 
 * Redistribution and use of this software in source and binary
 * forms, with or without modification, are permitted provided that
 * the following conditions and disclaimer are agreed and accepted
 * by the user:
 * 
 * 1. Redistributions of source code must retain the above copyright
 *    notice, this list of conditions and the following disclaimer.
 * 
 * 2. Redistributions in binary form must reproduce the above copyright
 *    notice, this list of conditions and the following disclaimer in
 *    the documentation and/or other materials provided with
 *    the distribution.
 * 
 * 3. Neither the names of the copyrighters, the name of the project
 *    which is related to this software (hereinafter referred to as
 *    "project") nor the names of the contributors may be used to
 *    endorse or promote products derived from this software without
 *    specific prior written permission.
 * 
 * 4. No merchantable use may be permitted without prior written
 *    notification to the copyrighters.
 * 
 * 5. The copyrighters, the project and the contributors may prohibit
 *    the use of this software at any time.
 * 
 * THIS SOFTWARE IS PROVIDED BY THE COPYRIGHTERS, THE PROJECT AND
 * CONTRIBUTORS "AS IS" AND ANY EXPRESS OR IMPLIED WARRANTIES, INCLUDING
 * BUT NOT LIMITED THE IMPLIED WARRANTIES OF MERCHANTABILITY AND FITNESS
 * FOR A PARTICULAR PURPOSE, ARE DISCLAIMED.  IN NO EVENT SHALL THE
 * COPYRIGHTERS, THE PROJECT OR CONTRIBUTORS BE LIABLE FOR ANY DIRECT,
 * INDIRECT, INCIDENTAL, SPECIAL, EXEMPLARY, OR CONSEQUENTIAL DAMAGES
 * (INCLUDING, BUT NOT LIMITED TO, PROCUREMENT OF SUBSTITUTE GOODS OR
 * SERVICES; LOSS OF USE, DATA, OR PROFITS; OR BUSINESS INTERRUPTION)
 * HOWEVER CAUSED AND ON ANY THEORY OF LIABILITY, WHETHER IN CONTRACT,
 * STRICT LIABILITY, OR TORT (INCLUDING NEGLIGENCE OR OTHERWISE) ARISING
 * IN ANY WAY OUT OF THE USE OF THIS SOFTWARE, EVEN IF ADVISED OF THE
 * POSSIBILITY OF SUCH DAMAGE.
 *
 * $TAHI: vel/lib/Cm/CmSocket.h,v 1.1.1.1 2005/07/13 01:46:14 doo Exp $
 */
#ifndef _Cm_CmSocket_h_
#define _Cm_CmSocket_h_	1
/* Interface Definition */
#include <string.h>
#include <sys/types.h>
#include <sys/socket.h>
#include <netdb.h>
#include <sys/un.h>
#include <netinet/in.h>
#include <arpa/inet.h>
#include "CmTypes.h"

#ifndef HAVE_SOCKLEN_T
typedef int socklen_t;
#endif

/* Macro to set link local index to the IPv6 address.  For KAME IPv6
   stack. */
#ifdef __KAME__
#define IN6_LINKLOCAL_IFINDEX(a)  ((a).s6_addr[2] << 8 | (a).s6_addr[3])
#define SET_IN6_LINKLOCAL_IFINDEX(a, i) \
	do { \
		(a).s6_addr[2] = ((i) >> 8) & 0xff; \
		(a).s6_addr[3] = (i) & 0xff; \
	} while (0)
#else
#define IN6_LINKLOCAL_IFINDEX(a)0
#define SET_IN6_LINKLOCAL_IFINDEX(a, i)
#endif /* __KAME__ */

struct CmSockAddr {
private:
	uint16_t alloc_;
	uint16_t length_;
	sockaddr* addr_;
public:
	CmSockAddr(int l,const sockaddr* s=0);
virtual	~CmSockAddr();
//----------------------------------------------------------------------
// SOCKADDR AREA MANUPULATION
public:
	int length() const;
	sockaddr* sockAddr() const;
static	int initSocket(sockaddr*,size_t,int);
	CmSockAddr* socketArea(int l,const sockaddr* s=0);
protected:
	sockaddr_in* inetAddr() const;
	sockaddr_in6* inet6Addr() const;
	sockaddr_un* unixAddr() const;
//----------------------------------------------------------------------
// ATTRIBUTE MANUPULATION
public:
	u_short family() const;
	u_short service() const;
	const in_addr address() const;
protected:
	bool family(u_short);
	bool service(u_short);
	bool address(const in_addr& anAddr);
	int alloc() const;
//----------------------------------------------------------------------
// FOR DICITIONARY SERVICES
public:
	uint32_t hash() const;
	bool isEqual(const CmSockAddr* o) const;
	int compare(const CmSockAddr* o) const;
virtual void print() const;
};
inline int CmSockAddr::alloc() const {return alloc_;}
inline int CmSockAddr::length() const {return length_;}
inline sockaddr* CmSockAddr::sockAddr() const {return addr_;}

struct SocketSet;
//======================================================================
struct CmSocket:public CmSockAddr {
private:
	int fileDesc_;
	int syserrno_;
static	SocketSet* bindedSockets_;
//----------------------------------------------------------------------
// Construction/Destruction
// Instance is created by InetSocket/UnixSocket static functions.
// InetSocket/UnixSocket provide general peterns of socket creation.
//----------------------------------------------------------------------
public:
	CmSocket(int l,const sockaddr* s=0,int fd=-1);
virtual	~CmSocket();
//----------------------------------------------------------------------
// General usage of functions.
// 1. Stream Listen
//	1) Create Instance with service,serivce and/or host,pathname.
//	2) listen() it.
//	3) if selected, then accept() to create same class of instance.
//	4) send/receive with created object.
// 2. Stream Connection
//	the connection side can be managed either from or to side.
//	1) Create Instance with service,serivce and/or host,pathname,
//	   which you want to connect to.
//	2) connect() it.
//	3) send/receive.
//   ...
//	1) Create Instance with service,serivce and/or host,pathname,
//	   which you want to connect from.
//	2) connect(to) it.
//	3) send/receive.
// 3. Datagram send
//	1) Create Instance.
//	2) socket() it.
//	3) Create Instance of sendto.
//	4) send.
// 4. Datagram receive
//	1) Create Instance to receive.
//	2) bind() it.
//	3) Create Instance of from.
//	4) receive.
//----------------------------------------------------------------------
// BASIC OPERATION
public:
	int listen(int aBacklog=5);
	CmSocket* accept();
virtual	int connect(CmSockAddr* to=0);
	int bind(bool reuse=true);
virtual	int socket()=0;
virtual	CmSocket* close();
virtual	int receive(STR buf,int len)=0;
virtual	int send(CSTR buf,int len)=0;
virtual	int sendAll(CSTR buf,int len);
virtual	int recvAll(STR buf,int len);
//----------------------------------------------------------------------
// portability to datagram socket
virtual	int recvfrom(STR,int,CmSockAddr*);
virtual	int sendto(CSTR,int,CmSockAddr*);
//----------------------------------------------------------------------
// OPTIONAL OPERATIONS
public:
	CmSockAddr* getsockname();
	CmSockAddr* getpeername();
	bool nonBlocking(int =1);
	bool setReuseAddrOpt(bool=true);

// velo add #ifdef @20050615
// SEE CmSocket.cc
#ifdef __FreeBSD__
	bool setReusePortOpt(bool=true);
#endif /* __FreeBSD__ */

	bool setDebugOpt(bool=true);
	int socketType(int aType,int aProtocol=0);
//----------------------------------------------------------------------
// broadcast return broadcast sockaddr_in for ifreq.
// broadcasts return all broadcasts sockaddr_in for system.
public:
	sockaddr_in* broadcast(struct ifreq* p);
	int broadcasts(sockaddr_in* *b);
//----------------------------------------------------------------------
// ATTRIBUTE MANUPULATION
public:
inline	int fileDesc() const;
inline	int syserrno() const;
virtual	bool retryError() const;	
public:
virtual	void printPeers() const;
//----------------------------------------------------------------------
// PRIVATE MEMBER: You do not need to look below.
protected:
inline	int myFD() const;
	CmSocket* fileDesc(int aFD);
virtual	int sysError(CSTR aFunc);
virtual	CmSocket* create(int,const sockaddr*,int=-1)=0;
virtual	CmSocket* accept(int,const sockaddr*,int=-1);
static	SocketSet* bindedSockets();
	void clearBind();
static	void clearBinds();
};
inline int CmSocket::fileDesc() const {return fileDesc_;}
inline int CmSocket::syserrno() const {return syserrno_;}
inline int CmSocket::myFD() const {return fileDesc();}
inline CmSocket* CmSocket::fileDesc(int aFD) {fileDesc_=aFD; return this;}

//======================================================================
// Stream Specific Functions
struct CmStream:public CmSocket {
private:
	CmSockAddr* self_;
	CmSockAddr* peer_;
public:
	CmStream(int l,const sockaddr* s=0,int fd=-1);
	CmStream(const sockaddr_in&,int fd=-1);
	CmStream(const sockaddr_in6&,int fd=-1);
	CmSockAddr* self() const;
	CmSockAddr* peer() const;
virtual	int socket();
virtual	CmSocket* create(int,const sockaddr*,int=-1);
virtual	CmSocket* accept(int,const sockaddr*,int=-1);
virtual	int connect(CmSockAddr* to=0);
virtual	int receive(STR buf,int len);
virtual	int send(CSTR buf,int len);
virtual	int sendAll(CSTR buf,int len);
virtual	int recvAll(STR buf,int len);
virtual void print() const;
virtual	void printPeers() const;
private:
	void self(CmSockAddr*);
	void peer(CmSockAddr*);
};
inline CmSockAddr* CmStream::self() const {return self_;}
inline CmSockAddr* CmStream::peer() const {return peer_;}
inline void CmStream::self(CmSockAddr* s) {self_=s;}
inline void CmStream::peer(CmSockAddr* s) {peer_=s;}

//======================================================================
// Datagram Specific Functions
// Datagram Socket can be used with connect and send/receive,
// and can be specified the receiver when sending or can be given
// the sender when receiving.
struct CmDgram:public CmSocket {
	CmDgram(int l,const sockaddr* s=0,int fd=-1);
	CmDgram(const sockaddr_in&,int fd=-1);
	CmDgram(const sockaddr_in6&,int fd=-1);
virtual	int socket();
virtual	CmSocket* create(int,const sockaddr*,int=-1);
virtual	int receive(STR,int);
virtual	int recvfrom(STR,int,CmSockAddr*);
virtual	int send(CSTR,int);
virtual	int sendto(CSTR,int,CmSockAddr*);
virtual int sendfrom(CSTR,int,CmSocket*);
virtual void print() const;
};

//======================================================================
// Raw Specific Functions
struct CmRaw:public CmDgram {
	CmRaw(int l,const sockaddr* s=0,int fd=-1);
virtual	int socket();
virtual	CmSocket* create(int,const sockaddr*,int=-1);
virtual void print() const;
};
	
//======================================================================
// for Unix Domain Socket
//	It can be stream/datagram and any address or pathname.
struct UnixSocket {
static CmSocket* stream();
static CmSocket* stream(CSTR aName);
static CmDgram* datagram();
static CmDgram* datagram(CSTR aName);
static int initSocket(sockaddr_un& un);
static int service(sockaddr_un& un,CSTR serv);
};

//======================================================================
// for Inet Domain Socket
//	It can be stream/datagram and any address or service
//	with/without hostname/ipaddress.
struct InetSocket {
static int getService(CSTR serv);
//----------------------------------------------------------------------
// defaultService is used for debugging.
// The priority of port number as follow.
//	debug environment->defined on system->default value
static int defaultService(CSTR serv,CSTR debug,int def);
static int initSocket(sockaddr_in& in);
static int initSocket(sockaddr_in6& in);
static int service(sockaddr_in& in,int serv);
static int service(sockaddr_in6& in,int serv);
static int serviceAddress(sockaddr_in& in,int serv,const in_addr& anAddr);
static int serviceAddress(sockaddr_in6& in,int serv,const in6_addr& anAddr);
static sockaddr_in* serviceHost4(int serv,CSTR aHost,int&);
#ifdef __FreeBSD__
static sockaddr_in6* serviceHost6(int serv,CSTR aHost,int&);
#endif /* __FreeBSD__ */
static sockaddr* serviceHost(int serv,CSTR aHost,int&);
static CSTR myHostname();
static const in_addr myIpAddress();
//----------------------------------------------------------------------
static CmSocket* stream();
static CmSocket* stream6();
static CmDgram* datagram();
static CmDgram* datagram6();
static CmSocket* stream(int serv);
static CmSocket* stream6(int serv);
static CmDgram* datagram(int serv);
static CmDgram* datagram6(int serv);
static CmSocket* stream(CSTR s);
static CmSocket* stream6(CSTR s);
static CmDgram* datagram(CSTR s);
static CmDgram* datagram6(CSTR s);
static CmSocket* stream(int serv,const in_addr& anAddr);
static CmDgram* datagram(int serv,const in_addr& anAddr);
static CmSocket* stream(int serv,const in6_addr& anAddr);
static CmDgram* datagram(int serv,const in6_addr& anAddr);
static CmSocket* stream(CSTR s,const in_addr& anAddr);
static CmDgram* datagram(CSTR s,const in_addr& anAddr);
static CmSocket* stream(CSTR s,const in6_addr& anAddr);
static CmDgram* datagram(CSTR s,const in6_addr& anAddr);
static CmSocket* stream(int serv,CSTR aHost);
static CmDgram* datagram(int serv,CSTR aHost);
static CmSocket* stream(CSTR s,CSTR aHost);
static CmDgram* datagram(CSTR s,CSTR aHost);
};

//----------------------------------------------------------------------
inline CmSocket* InetSocket::stream(CSTR s) {
	return stream(getService(s));}
inline CmSocket* InetSocket::stream6(CSTR s) {
	return stream(getService(s));}
inline CmDgram* InetSocket::datagram(CSTR s) {
	return datagram(getService(s));}
inline CmDgram* InetSocket::datagram6(CSTR s) {
	return datagram(getService(s));}

//----------------------------------------------------------------------
inline CmSocket* InetSocket::stream(CSTR s,CSTR aHost) {
	return stream(getService(s),aHost);}
inline CmDgram* InetSocket::datagram(CSTR s,CSTR aHost) {
	return datagram(getService(s),aHost);}

//----------------------------------------------------------------------
inline CmSocket* InetSocket::stream(CSTR s,const in_addr& anAddr) {
	return stream(getService(s),anAddr);}
inline CmSocket* InetSocket::stream(CSTR s,const in6_addr& anAddr) {
	return stream(getService(s),anAddr);}
inline CmDgram* InetSocket::datagram(CSTR s,const in_addr& anAddr) {
	return datagram(getService(s),anAddr);}
inline CmDgram* InetSocket::datagram(CSTR s,const in6_addr& anAddr) {
	return datagram(getService(s),anAddr);}

//----------------------------------------------------------------------
inline bool operator==(const in_addr& a,const in_addr& b) {
	return a.s_addr==b.s_addr;}

#include "CmCltn.h"
interfaceCmSet(SocketSet,CmSocket);

#ifndef DBGFLAGS
// avoid warning of compilation
//     gcc version 3.3.1 [FreeBSD]
//     warning: array subscript has type `char'
#define DBGFLAGS(c)	(dbgFlags[(int)(c)])
#endif	// DBGFLAGS
#endif
