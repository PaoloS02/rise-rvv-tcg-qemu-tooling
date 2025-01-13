// An implementation of memcpy using RVV whole register load/store
//
// Copyright (C) 2024 Embecosm Limited
// Contributor: Paolo Savini <paolo.savini@embecosm.com>
// Contributor: Jeremy Bennett <jeremy.bennett@embecosm.com>
//
// SPDX-License-Identifier: GPL-3.0-or-later
//
// This implementation exists solely to benchmark the whole register
// load/store instructions in a real-world context.  It is not anticipated
// that it will ever be used in a real-world context.
//
// From the C standard, the API call is
//
//   void* memcpy (void *dst, const void *src, size_t n)
//
// Note in particular that source and destination may not overlap, and that
// the exact number of bytes are copied.
//
// In this implementation, we copy as much as we can using whole words,
// initially with 8 fields (registers), then with 4 fields, then 2 fields,
// then with a single field and finally using normal vector load/store.
//
// We could clearly do better - the trick would be to start small and get
// bigger!

#include <sys/asm.h>

ENTRY(memcpy)

	mv	a3, a0			// Working copy of dst pointer

	// Main loop copying as much as possible 8 registers at a time.
	csrr	t2, vlenb
	slli	t2, t2, 3		// How many bytes in 8 registers

L(loop8_cpy):
	blt	a2, t2, L(reg4_cpy)	// At least 8 registers worth to do?
	vl8re8.v v0, (a1)		// Load bytes
	add	a1, a1, t2		// Increment src byte pointer
	sub	a2, a2, t2		// Decrement byte count
	vs8r.v	v0, (a3)		// Store bytes
	add	a3, a3, t2		// Increment dst byte pointer
	j	L(loop8_cpy)

	// Do we have enough to copy in 4 registers?
L(reg4_cpy):
	srli	t2, t2, 1		// How many bytes in 4 registers
	blt	a2, t2, L(reg2_cpy)	// 4 registers worth to do?
	vl4re8.v v0, (a1)		// Load bytes
	add	a1, a1, t2		// Increment src byte pointer
	sub	a2, a2, t2		// Decrement byte count
	vs4r.v	v0, (a3)		// Store bytes
	add	a3, a3, t2		// Increment dst byte pointer

	// Do we have enough to copy in 2 registers?
L(reg2_cpy):
	srli	t2, t2, 1		// How many bytes in 2 registers
	blt	a2, t2, L(reg1_cpy)	// 2 registers worth to do
	vl2re8.v v0, (a1)		// Load bytes
	add	a1, a1, t2		// Increment src byte pointer
	sub	a2, a2, t2		// Decrement byte count
	vs2r.v	v0, (a3)		// Store bytes
	add	a3, a3, t2		// Increment dst byte pointer

	// Do we have enough to copy in 1 register?
L(reg1_cpy):
	srli	t2, t2, 1		// How many bytes in 1 register
	blt	a2, t2, L(tail_cpy)	// 1 register worth to do?
	vl1re8.v v0, (a1)		// Load bytes
	add	a1, a1, t2		// Increment src byte pointer
	sub	a2, a2, t2		// Decrement byte count
	vs1r.v	v0, (a3)		// Store bytes
	add	a3, a3, t2		// Increment dst byte pointer

	// Do the rest as a simple copy of a single vector register
L(tail_cpy):
	beq	a2, zero, L(all_done)
	vsetvli t2, a2, e8, m1, ta, ma
	vle8.v	v0, (a1)
	vse8.v	v0, (a3)

L(all_done):
	ret

END(memcpy)
