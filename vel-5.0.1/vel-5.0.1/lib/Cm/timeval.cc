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
 * $TAHI: vel/lib/Cm/timeval.cc,v 1.1.1.1 2005/07/13 01:46:14 doo Exp $
 */
#include "timeval.h"
//IMPLEMENTATION

timeval operator+(const timeval& src1,const timeval& src2) {
	timeval sum;
	sum.tv_sec = src1.tv_sec + src2.tv_sec;
	sum.tv_usec = src1.tv_usec + src2.tv_usec;
	if(sum.tv_usec >= ONE_SECOND) {
		sum.tv_usec -= ONE_SECOND;
		sum.tv_sec++;}
	else if(sum.tv_sec >= 1 && sum.tv_usec < 0) {
		sum.tv_usec += ONE_SECOND;
		sum.tv_sec--;}
	return sum;}

timeval operator-(const timeval& src1,const timeval& src2) {
	timeval delta;
	delta.tv_sec = src1.tv_sec - src2.tv_sec;
	delta.tv_usec = src1.tv_usec - src2.tv_usec;
	if(delta.tv_usec < 0) {
		delta.tv_usec += ONE_SECOND;
		delta.tv_sec--;}
	else if(delta.tv_usec >= ONE_SECOND) {
		delta.tv_usec -= ONE_SECOND;
		delta.tv_sec++;}
	return delta;}

bool operator>(const timeval& src1,const timeval& src2) {
	return (src1.tv_sec>src2.tv_sec)||
		(src1.tv_sec==src2.tv_sec&&src1.tv_usec>src2.tv_usec);}

bool operator>=(const timeval& src1,const timeval& src2) {
	return (src1.tv_sec>src2.tv_sec)||
		(src1.tv_sec==src2.tv_sec&&src1.tv_usec>=src2.tv_usec);}

bool operator<(const timeval& src1,const timeval& src2) {
	return (src1.tv_sec<src2.tv_sec)||
		(src1.tv_sec==src2.tv_sec&&src1.tv_usec<src2.tv_usec);}

bool operator<=(const timeval& src1,const timeval& src2) {
	return (src1.tv_sec<src2.tv_sec)||
		(src1.tv_sec==src2.tv_sec&&src1.tv_usec<=src2.tv_usec);}

bool operator==(const timeval& src1,const timeval& src2) {
	return (src1.tv_sec==src2.tv_sec)&&(src1.tv_usec==src2.tv_usec);}
bool operator!=(const timeval& src1,const timeval& src2) {
	return !(src1==src2);}
