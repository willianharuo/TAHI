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
 */
#if !defined(__TcAccept_h__)
#define	__TcAccept_h__	1
#include <sys/time.h>
#include "TgTypes.h"
#include "TgIF.h"
#include "TgServer.h"
#include "TcAgent.h"

struct TcAgent;
struct TgServer;
struct TcSocket;

struct TcAccept:public TcAgent {
private:
	int16_t		conn_;
	int16_t		reqno_;
	trafficInfo 	traffic_;
	struct timeval	stime_;
	int16_t		conn();
	int16_t		reqno();
	uint32_t	scount();
	uint32_t	rcount();
	uint32_t	slen();
	uint32_t	rlen();
	void		setStartTime();
	int		makeTcSocket(TcSocket* s);
	void		report(TcSocket* s);
public:
	TcAccept(int16_t,int16_t,int16_t,CmSocket*,TgServer*);
	void traffic(trafficInfo&);
virtual	~TcAccept();
	int listen();
virtual	int accept();
virtual	int noaccept();
protected:
};
inline void TcAccept::traffic(trafficInfo& v){traffic_=v;}
inline int16_t TcAccept::conn(){return conn_;}
inline int16_t TcAccept::reqno(){return reqno_;}
inline uint32_t TcAccept::scount(){return traffic_.scount();}
inline uint32_t TcAccept::rcount(){return traffic_.rcount();}
inline uint32_t TcAccept::slen(){return traffic_.slen();}
inline uint32_t TcAccept::rlen(){return traffic_.rlen();}
#endif
