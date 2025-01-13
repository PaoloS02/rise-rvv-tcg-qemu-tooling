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
	// Do we have enough to copy in 1 register?
L(cpy_loop):
	ble	a2, zero, L(all_done)
	vl8re64.v v0, (a1)		// Load bytes
	add	a1, a1, t2		// Increment src byte pointer
	sub	a2, a2, t2		// Decrement byte count
	vs8r.v	v0, (a3)		// Store bytes
	add	a3, a3, t2		// Increment dst byte pointer
	j	L(cpy_loop)

L(all_done):
	ret

END(memcpy)
