// SPDX-License-Identifier: GPL-2.0
/*  Copyright(c) 2016-20 Intel Corporation. */

#include <stddef.h>
/**
 * Very simple example of an enclave that receives a single
 * pointer and dereferences it.
 * Useful to test untrusted pointers detection.
*/
void encl_body(int *rdi,  void *rsi)
{
	int i = *rdi;
	// deref the pointer
	*rdi = 5;
	// restore pointer
	*rdi = i;
}
