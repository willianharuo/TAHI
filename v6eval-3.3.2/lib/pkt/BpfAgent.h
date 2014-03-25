/*
 * Copyright (C) 1999, 2000, 2001, 2002, 2003, 2004, 2005, 2006, 2007, 2008, 2009, 2010, 2011
 * Yokogawa Electric Corporation, YDC Corporation,
 * IPA (Information-technology Promotion Agency, Japan).
 * All rights reserved.
 * 
 * Redistribution and use of this software in source and binary forms, with 
 * or without modification, are permitted provided that the following 
 * conditions and disclaimer are agreed and accepted by the user:
 * 
 * 1. Redistributions of source code must retain the above copyright 
 * notice, this list of conditions and the following disclaimer.
 * 
 * 2. Redistributions in binary form must reproduce the above copyright 
 * notice, this list of conditions and the following disclaimer in the 
 * documentation and/or other materials provided with the distribution.
 * 
 * 3. Neither the names of the copyrighters, the name of the project which 
 * is related to this software (hereinafter referred to as "project") nor 
 * the names of the contributors may be used to endorse or promote products 
 * derived from this software without specific prior written permission.
 * 
 * 4. No merchantable use may be permitted without prior written 
 * notification to the copyrighters. However, using this software for the 
 * purpose of testing or evaluating any products including merchantable 
 * products may be permitted without any notification to the copyrighters.
 * 
 * 
 * 
 * THIS SOFTWARE IS PROVIDED BY THE COPYRIGHTERS, THE PROJECT AND 
 * CONTRIBUTORS "AS IS" AND ANY EXPRESS OR IMPLIED WARRANTIES, INCLUDING 
 * BUT NOT LIMITED THE IMPLIED WARRANTIES OF MERCHANTABILITY AND FITNESS 
 * FOR A PARTICULAR PURPOSE, ARE DISCLAIMED.  IN NO EVENT SHALL THE 
 * COPYRIGHTERS, THE PROJECT OR CONTRIBUTORS BE LIABLE FOR ANY DIRECT, 
 * INDIRECT, INCIDENTAL, SPECIAL, EXEMPLARY, OR CONSEQUENTIAL DAMAGES 
 * (INCLUDING, BUT NOT LIMITED TO, PROCUREMENT OF SUBSTITUTE GOODS OR 
 * SERVICES; LOSS OF USE, DATA, OR PROFITS; OR BUSINESS INTERRUPTION) 
 * HOWEVER CAUSED AND ON ANY THEORY OF LIABILITY, WHETHER IN 
 * CONTRACT,STRICT LIABILITY, OR TORT (INCLUDING NEGLIGENCE OR OTHERWISE) 
 * ARISING IN ANY WAY OUT OF THE USE OF THIS SOFTWARE, EVEN IF ADVISED OF 
 * THE POSSIBILITY OF SUCH DAMAGE.
 *
 * $TAHI: v6eval/lib/pkt/BpfAgent.h,v 1.15 2005/07/21 01:53:22 akisada Exp $
 */
#if !defined(__BpfAgent_h__)
#define	__BpfAgent_h__	1
#include "Bpfilter.h"
#include "CmAgent.h"
#include "Ringbuf.h"
#include "bufStat.h"
#include "PktQueue.h"
struct BpfAgent:public CmAgent {
private:
	Bpfilter filter_;
	caddr_t buffer_;
	Ringbuf *rbuf;
	enum eRunStat {eRun_,eStop_} runStat_;
	PktFIFO fifo;
inline enum eRunStat runStat() const {return runStat_;}
public:
inline	const Bpfilter& filter() const;
inline	int fileDesc() const;
	BpfAgent(CSTR,int32_t =4096);
	int receive(int);
	int nonblock_receive(int);
virtual int readydata(char *,int32_t);
	int write(caddr_t, uint32_t);
	int read(caddr_t, uint32_t);
	int readn(caddr_t, uint32_t);
	bufStat stat() const;
	timeval* ReceiveTimeOfOldestData() const;
inline  uint32_t maxdatasize() const;
inline  void setNowrapMode();
inline  void setWrapMode();
inline  void capture() {runStat_ = eRun_; filter_.flush();};
inline  void stop() {runStat_ = eStop_;};
	void clear();
inline  uint32_t getDLT();
};
inline const Bpfilter& BpfAgent::filter() const {return filter_;}
inline int BpfAgent::fileDesc() const {return filter().fileDesc();}
inline void BpfAgent::setNowrapMode(){ rbuf->setNowrapMode(); };
inline void BpfAgent::setWrapMode(){ rbuf->setWrapMode(); };
inline uint32_t BpfAgent::getDLT(){ return filter().getDLT(); };
inline uint32_t BpfAgent::maxdatasize() const { return filter_.bufferSize(); };
#endif
