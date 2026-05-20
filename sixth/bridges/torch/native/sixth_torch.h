// sixth_torch.h — plain C ABI exposing a tiny subset of libtorch
// for use by Racket FFI.  Compiled into libsixth_torch.dylib.
//
// All functions take/return either primitive types or opaque tensor
// handles (st_tensor*).  Lifetime is explicit: callers must call
// st_tensor_free on every handle.

#ifndef SIXTH_TORCH_H
#define SIXTH_TORCH_H

#ifdef __cplusplus
extern "C" {
#endif

#include <stddef.h>
#include <stdint.h>

typedef struct st_tensor st_tensor;

// ---- versioning / sanity ----
const char* st_version(void);   // libtorch version string

// ---- construction ----
// Each constructor returns a freshly heap-allocated handle.  Caller owns it.
st_tensor* st_zeros1(int64_t n);                     // shape (n,)
st_tensor* st_ones1(int64_t n);                      // shape (n,)
st_tensor* st_zeros2(int64_t rows, int64_t cols);    // shape (rows, cols)
st_tensor* st_from_floats(const float* data, int64_t n);  // copy n floats
st_tensor* st_from_int64(const int64_t* data, int64_t n); // copy n ints
st_tensor* st_arange(int64_t end);                   // 0..end-1 as int64
st_tensor* st_clone(const st_tensor* t);

// ---- destruction ----
void st_tensor_free(st_tensor* t);

// ---- shape / dtype ----
int64_t st_ndim(const st_tensor* t);
int64_t st_size(const st_tensor* t, int64_t dim);
int64_t st_numel(const st_tensor* t);
int     st_dtype_code(const st_tensor* t);   // 0=float32, 1=int64, -1=other

// ---- element access ----
float   st_item_float(const st_tensor* t);
int64_t st_item_int64(const st_tensor* t);
float   st_get1_float(const st_tensor* t, int64_t i);
int64_t st_get1_int64(const st_tensor* t, int64_t i);
void    st_set1_float(st_tensor* t, int64_t i, float v);
void    st_set1_int64(st_tensor* t, int64_t i, int64_t v);

// ---- arithmetic (returns fresh tensor) ----
st_tensor* st_add(const st_tensor* a, const st_tensor* b);
st_tensor* st_sub(const st_tensor* a, const st_tensor* b);
st_tensor* st_mul(const st_tensor* a, const st_tensor* b);
st_tensor* st_div(const st_tensor* a, const st_tensor* b);
st_tensor* st_matmul(const st_tensor* a, const st_tensor* b);
st_tensor* st_sum(const st_tensor* a);              // scalar tensor
st_tensor* st_relu(const st_tensor* a);
st_tensor* st_sigmoid(const st_tensor* a);
st_tensor* st_neg(const st_tensor* a);

// ---- scalar arithmetic (returns fresh tensor) ----
st_tensor* st_mul_scalar(const st_tensor* a, float v);
st_tensor* st_add_scalar(const st_tensor* a, float v);
st_tensor* st_sub_scalar(const st_tensor* a, float v);
st_tensor* st_pow2(const st_tensor* a);             // element-wise a*a

// ---- 2D ----
st_tensor* st_from_floats_2d(const float* data, int64_t rows, int64_t cols);
float      st_get2_float(const st_tensor* t, int64_t i, int64_t j);
void       st_set2_float(st_tensor* t, int64_t i, int64_t j, float v);

// ---- indexing that preserves gradient flow ----
st_tensor* st_index1(const st_tensor* t, int64_t i);   // returns t[i] as 0-D tensor

// ---- autograd ----
void       st_set_requires_grad(st_tensor* t, int flag);
int        st_requires_grad(const st_tensor* t);
void       st_backward(st_tensor* loss);
st_tensor* st_grad(const st_tensor* t);             // returns NULL if no grad

// ---- printing (debug) ----
void st_print(const st_tensor* t);

#ifdef __cplusplus
}  // extern "C"
#endif

#endif  // SIXTH_TORCH_H
