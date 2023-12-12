// SPDX-License-Identifier: GPL-2.0
/*  Copyright(c) 2016-20 Intel Corporation. */

#include <stddef.h>
#include "defines.h"

/*
 * Data buffer spanning two pages that will be placed first in .data
 * segment. Even if not used internally the second page is needed by
 * external test manipulating page permissions.
 */
static uint8_t encl_buffer[8192] = { 1 };

/*
 * Unmeasured data buffer in enclave for testing purposes. This is allocated in
 * a separate .unmeasured section, so as to allow the LinuxSelftestEnclave
 * loader to recognize this as such and mark it as _unmeasured_ SGX memory for
 * Pandora symbolic exploration. Allows testing vulnerabilities where
 * unmeasured enclave memory is accessed before secure initialization.
 */
extern volatile uint8_t unmeasured_encl_buffer[100];

volatile uint8_t non_exec_data_buffer[10] = { 0xc3 /* x86 ret instruction */ };

// sgx_is_outside_enclave()
// Parameters:
//      addr - the start address of the buffer
//      size - the size of the buffer
// Return Value:
//      1 - the buffer is strictly outside the enclave
//      0 - the whole buffer or part of the buffer is not outside the enclave,
//          or the buffer is wrap around
//
extern char* __enclave_start, __enclave_end;
int sgx_is_outside_enclave(const void *addr, size_t size)
{
    size_t start = (size_t)addr;
    size_t end = 0;
    size_t enclave_start = (size_t) &__enclave_start;
    size_t enclave_end = (size_t) &__enclave_end - 1;
    // the enclave range is [enclave_start, enclave_end] inclusively

    if(size > 0)
    {
        end = start + size - 1;
    }
    else
    {
        end = start;
    }
    if( (start <= end) && ((end < enclave_start) || (start > enclave_end)) )
    {
        return 1;
    }
    return 0;
}

static void *memcpy(void *dest, const void *src, size_t n)
{
	size_t i;

	for (i = 0; i < n; i++) {
		((char *)dest)[i] = ((char *)src)[i];
    }

	return dest;
}

static void do_encl_op_put_to_buf(void *op)
{
	struct encl_op_put_to_buf *op2 = op;

        #if FIX_SANITIZATION >= 2
            if (!sgx_is_outside_enclave(op2, sizeof(*op2)))
                return;
        #endif
	memcpy(&encl_buffer[0], &op2->value, 8);
}

static void do_encl_op_get_from_buf(void *op)
{
	struct encl_op_get_from_buf *op2 = op;

        #if FIX_SANITIZATION >= 2
            if (!sgx_is_outside_enclave(op2, sizeof(*op2)))
                return;
        #endif

	memcpy(&op2->value, &encl_buffer[0], 8);
}

static void do_encl_op_put_to_addr(void *_op)
{
	struct encl_op_put_to_addr *op = _op;

    #if FIX_SANITIZATION >= 2
        if (!sgx_is_outside_enclave(op, sizeof(*op)))
            return;
    #endif


    volatile void* ptr = (void*) op->addr;
    #if FIX_SANITIZATION >= 3
        if (!sgx_is_outside_enclave((void*) ptr, 8))
            return;
    #endif

	memcpy((void*) ptr, &op->value, 8);
}

static void do_encl_op_get_from_addr(void *_op)
{
	struct encl_op_get_from_addr *op = _op;

        #if FIX_SANITIZATION >= 2
            if (!sgx_is_outside_enclave(op, sizeof(*op)))
                return;
        #endif
        #if FIX_SANITIZATION == 3
            /* TOCTOU */
            if (!sgx_is_outside_enclave((void*) op->addr, 8))
                return;
        #endif
        #if FIX_SANITIZATION >= 4
            volatile void* ptr = (void*) op->addr;
            if (!sgx_is_outside_enclave((void*) ptr, 8))
                return;
            memcpy(&op->value, (void*) ptr, 8);
        #else
            memcpy(&op->value, (void*) op->addr, 8);
        #endif
}

static void do_encl_op_get_from_unmeasured(void *_op)
{
	struct encl_op_get_from_addr *op = _op;

        #if FIX_SANITIZATION >= 2
            if (!sgx_is_outside_enclave(op, sizeof(*op)))
                return;
        #endif

        #if FIX_SANITIZATION >= 4
            *((uint64_t*) unmeasured_encl_buffer) = 0x0;
        #elif FIX_SANITIZATION >= 3
            *((uint32_t*) unmeasured_encl_buffer) = 0x1;
        #endif

        /* 
         * Craft the src pointer address by adding the unmeasured, potentially
         * attacker-tainted (i.e., partially uninitialized) 64-bit value to a
         * valid in-enclave base pointer
         */
        uint64_t *src = (uint64_t*) &encl_buffer[0];
        uint64_t offset = *((uint64_t*) unmeasured_encl_buffer);
        op->value = src[offset];
}

static void do_encl_op_nop(void *_op)
{

}

typedef void (*fct_ptr_t)(void);

static void do_encl_op_call_addr(void *_op)
{
    struct encl_op_call_addr *op = _op;

    #if FIX_SANITIZATION >= 2
        if (!sgx_is_outside_enclave(op, sizeof(*op)))
            return;
    #endif

    volatile fct_ptr_t fun_ptr = (fct_ptr_t) op->addr;

    #if FIX_SANITIZATION >= 4
        if (fun_ptr != (fct_ptr_t) do_encl_op_nop)
            return;
    #elif FIX_SANITIZATION >= 3
        if (!sgx_is_outside_enclave((void*) fun_ptr, 8))
            return;
    #endif
    
    fun_ptr();
}

static void do_encl_op_call_unmeasured(void *_op)
{
    volatile fct_ptr_t fun_ptr = (fct_ptr_t) unmeasured_encl_buffer;
    int i, len = 0;

    #if FIX_SANITIZATION >= 4
        len = 20;
    #elif FIX_SANITIZATION >= 2
        len = 10;
    #endif
    for (i=0; i < len; i++)
    {
        unmeasured_encl_buffer[i] = 0x90; /* x86 nop instruction */
        unmeasured_encl_buffer[len] = 0xc3; /* x86 ret instruction */
    }

    fun_ptr();
}

static void do_encl_op_call_non_exec(void *_op)
{
    #if FIX_SANITIZATION < 4
        volatile fct_ptr_t fun_ptr = (fct_ptr_t) non_exec_data_buffer;
        fun_ptr();
    #endif
}

void encl_body(void *rdi,  void *rsi)
{
    const void (*encl_op_array[ENCL_OP_MAX])(void *) = {
    	do_encl_op_put_to_buf,
    	do_encl_op_get_from_buf,
    	do_encl_op_put_to_addr,
    	do_encl_op_get_from_addr,
    	do_encl_op_get_from_unmeasured,
    	do_encl_op_nop,
    	do_encl_op_call_addr,
    	do_encl_op_call_unmeasured,
    	do_encl_op_call_non_exec,
    };
    
    struct encl_op_header *op = (struct encl_op_header *)rdi;
    
    /* 1. check if the argument struct header lies entirely outside */
    #if FIX_SANITIZATION >= 1
        /* NOTE: this is necessary but not sufficient (as subsequent
         * operations will dereference further offsets) */
        if (!sgx_is_outside_enclave(op, sizeof(struct encl_op_header)))
            return;
    #endif

    /* 2. copy the untrusted array idx inside the enclave to protect against TOCTOU attacks */
    #if FIX_SANITIZATION >= 2
        volatile uint64_t op_type = op->type;
    #else
        #define op_type (op->type)
    #endif

    if (op_type < ENCL_OP_MAX)
    {
        (*(encl_op_array[op_type] + (size_t) &__enclave_start))(op);
    }
}
