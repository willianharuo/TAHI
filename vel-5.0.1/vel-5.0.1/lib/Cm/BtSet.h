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
 * $TAHI: vel/lib/Cm/BtSet.h,v 1.1.1.1 2005/07/13 01:46:14 doo Exp $
 */
#ifndef _Cm_BtSet_h_
#define	_Cm_BtSet_h_	1
#include "BtArray.h"
struct BtSet:public BtArray {
private:
	u_long noOfElements_;
public:
	BtSet& operator=(const BtSet&);
	BtSet(u_long size=defaultArraySize);
	BtSet(const BtSet &);
	BtSet(ELEMENTS elm,...);
virtual	~BtSet();

virtual	u_long size() const;
virtual	u_long noOfElements() const;
virtual	ELEMENTS add(ELEMENTS o);
virtual	ELEMENTS filter(ELEMENTS o);
virtual	ELEMENTS replace(ELEMENTS o);
virtual	ELEMENTS remove(const ELEMENTS o);
virtual	void deleteContents();
//----------------------------------------------------------------------
// Abstract Element type
virtual	uint32_t hashElement(const ELEMENTS o) const;
virtual	bool isSame(const ELEMENTS c,const ELEMENTS o) const;
//----------------------------------------------------------------------
// GROUP OPERATION
protected:
	ELEMENTS findAt(const ELEMENTS o,u_long& s) const;
	ELEMENTS addIfAbsent(ELEMENTS o,u_long& s);
	void rehash(u_long n);
	void expand();
};
#endif
