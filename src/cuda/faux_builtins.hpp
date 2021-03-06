#pragma once
#ifndef CUDA_FAUX_BUILTINS_HPP_
#define CUDA_FAUX_BUILTINS_HPP_

#ifdef __CUDA_ARCH__
#error "This code should only be used as a replacement for builtins available on nVIDIA GPU devices"
#endif

/*
 * The idea in this file is for nvcc-compiled - and even gcc-compiled host-side code -
 * to be able to supposedly use CUDA device-side builtins (see on_device/builtins.cuh),
 * so that on the host side, semantically-valid but possibly slow replacements are used -
 * hopefully only used in compilation and never called - while on the host-side we get
 * the real deal. see functors.hpp for an example of such use.
 *
 *These functions should all be host-only.
 *
 */

#include "cuda/syntax_replacement.h"
#include "util/builtins.hpp"

namespace faux_builtins {

template <typename T>
inline int population_count(T x) { return ::util::builtins::population_count(x); }

// These will absolutely never be used on CPUs, since they're meaningless there -
// so we'll have dummy implementations, just so things compile
inline unsigned warp_ballot     (int cond) { return 0; }
inline int all_in_warp_satisfy  (int cond) { return 0; }
inline int any_in_warp_satisfies(int cond) { return 0; }

template <typename T>
inline int find_first_set(T x) { return ::util::builtins::population_count(x); }

template <typename T>
inline int count_leading_zeros(T x)
{
	return ::util::builtins::count_leading_zeros(x);
}

// Not really a CPU builtin, but CUDA GPUs have it, so we include an implementation

// Slow? Perhaps break down by bytes and use a lookup table?
template <typename T>
inline unsigned bit_reverse(T x) {
	T result = 0;
	constexpr auto num_bits = sizeof(T) * CHAR_BIT;
	for(unsigned bit_index = 0 ; bit_index < num_bits; bit_index++) {
		T source_mask = 1 << bit_index;
		T target_mask = 1 << (num_bits - bit_index - 1);
		result |= target_mask * (x & source_mask);
	}
	return result;
}

template <typename T>
inline T minimum(T x, T y) { return x <= y ? x : y; }

template <typename T>
inline T maximum(T x, T y) { return x >= y ? y : x; }

} // namespace faux_builtins

#endif /* CUDA_FAUX_BUILTINS_HPP_ */
