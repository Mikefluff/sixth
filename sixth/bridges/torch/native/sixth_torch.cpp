// sixth_torch.cpp — C++ implementation wrapping libtorch behind a
// plain C ABI declared in sixth_torch.h.  Built into libsixth_torch.dylib.
//
// Tensors are heap-allocated torch::Tensor wrapped in struct st_tensor.
// Lifetime is explicit: every st_tensor* returned by a constructor must
// be released with st_tensor_free.

#include "sixth_torch.h"

#include <torch/torch.h>
#include <cstdio>
#include <cstring>
#include <string>

struct st_tensor {
  torch::Tensor t;
  explicit st_tensor(torch::Tensor x) : t(std::move(x)) {}
};

static std::string g_version_buf;

extern "C" const char* st_version(void) {
  if (g_version_buf.empty()) {
    g_version_buf = std::string("libtorch ") + TORCH_VERSION;
  }
  return g_version_buf.c_str();
}

// ---- construction ----

extern "C" st_tensor* st_zeros1(int64_t n) {
  return new st_tensor(torch::zeros({n}, torch::kFloat32));
}

extern "C" st_tensor* st_ones1(int64_t n) {
  return new st_tensor(torch::ones({n}, torch::kFloat32));
}

extern "C" st_tensor* st_zeros2(int64_t rows, int64_t cols) {
  return new st_tensor(torch::zeros({rows, cols}, torch::kFloat32));
}

extern "C" st_tensor* st_from_floats(const float* data, int64_t n) {
  auto t = torch::from_blob(const_cast<float*>(data), {n}, torch::kFloat32).clone();
  return new st_tensor(t);
}

extern "C" st_tensor* st_from_int64(const int64_t* data, int64_t n) {
  auto t = torch::from_blob(const_cast<int64_t*>(data), {n}, torch::kInt64).clone();
  return new st_tensor(t);
}

extern "C" st_tensor* st_arange(int64_t end) {
  return new st_tensor(torch::arange(end, torch::kInt64));
}

extern "C" st_tensor* st_clone(const st_tensor* t) {
  return new st_tensor(t->t.clone());
}

// ---- destruction ----

extern "C" void st_tensor_free(st_tensor* t) {
  delete t;
}

// ---- shape / dtype ----

extern "C" int64_t st_ndim(const st_tensor* t) {
  return t->t.dim();
}

extern "C" int64_t st_size(const st_tensor* t, int64_t dim) {
  return t->t.size(dim);
}

extern "C" int64_t st_numel(const st_tensor* t) {
  return t->t.numel();
}

extern "C" int st_dtype_code(const st_tensor* t) {
  auto dt = t->t.scalar_type();
  if (dt == torch::kFloat32) return 0;
  if (dt == torch::kInt64)   return 1;
  return -1;
}

// ---- element access ----

extern "C" float st_item_float(const st_tensor* t) {
  return t->t.item<float>();
}

extern "C" int64_t st_item_int64(const st_tensor* t) {
  return t->t.item<int64_t>();
}

extern "C" float st_get1_float(const st_tensor* t, int64_t i) {
  return t->t[i].item<float>();
}

extern "C" int64_t st_get1_int64(const st_tensor* t, int64_t i) {
  return t->t[i].item<int64_t>();
}

extern "C" void st_set1_float(st_tensor* t, int64_t i, float v) {
  t->t[i] = v;
}

extern "C" void st_set1_int64(st_tensor* t, int64_t i, int64_t v) {
  t->t[i] = v;
}

// ---- arithmetic ----

extern "C" st_tensor* st_add(const st_tensor* a, const st_tensor* b) {
  return new st_tensor(a->t + b->t);
}

extern "C" st_tensor* st_sub(const st_tensor* a, const st_tensor* b) {
  return new st_tensor(a->t - b->t);
}

extern "C" st_tensor* st_mul(const st_tensor* a, const st_tensor* b) {
  return new st_tensor(a->t * b->t);
}

extern "C" st_tensor* st_div(const st_tensor* a, const st_tensor* b) {
  return new st_tensor(a->t / b->t);
}

extern "C" st_tensor* st_matmul(const st_tensor* a, const st_tensor* b) {
  return new st_tensor(torch::matmul(a->t, b->t));
}

extern "C" st_tensor* st_sum(const st_tensor* a) {
  return new st_tensor(a->t.sum());
}

extern "C" st_tensor* st_relu(const st_tensor* a) {
  return new st_tensor(torch::relu(a->t));
}

extern "C" st_tensor* st_sigmoid(const st_tensor* a) {
  return new st_tensor(torch::sigmoid(a->t));
}

extern "C" st_tensor* st_neg(const st_tensor* a) {
  return new st_tensor(-a->t);
}

// ---- scalar arithmetic ----

extern "C" st_tensor* st_mul_scalar(const st_tensor* a, float v) {
  return new st_tensor(a->t * v);
}

extern "C" st_tensor* st_add_scalar(const st_tensor* a, float v) {
  return new st_tensor(a->t + v);
}

extern "C" st_tensor* st_sub_scalar(const st_tensor* a, float v) {
  return new st_tensor(a->t - v);
}

extern "C" st_tensor* st_pow2(const st_tensor* a) {
  return new st_tensor(a->t * a->t);
}

// ---- 2D ----

extern "C" st_tensor* st_from_floats_2d(const float* data, int64_t rows, int64_t cols) {
  auto t = torch::from_blob(const_cast<float*>(data), {rows, cols}, torch::kFloat32).clone();
  return new st_tensor(t);
}

extern "C" float st_get2_float(const st_tensor* t, int64_t i, int64_t j) {
  return t->t[i][j].item<float>();
}

extern "C" void st_set2_float(st_tensor* t, int64_t i, int64_t j, float v) {
  t->t[i][j] = v;
}

// ---- indexing preserving gradient ----

extern "C" st_tensor* st_index1(const st_tensor* t, int64_t i) {
  return new st_tensor(t->t[i]);
}

// ---- autograd ----

extern "C" void st_set_requires_grad(st_tensor* t, int flag) {
  t->t.set_requires_grad(flag != 0);
}

extern "C" int st_requires_grad(const st_tensor* t) {
  return t->t.requires_grad() ? 1 : 0;
}

extern "C" void st_backward(st_tensor* loss) {
  loss->t.backward();
}

extern "C" st_tensor* st_grad(const st_tensor* t) {
  if (!t->t.grad().defined()) return nullptr;
  return new st_tensor(t->t.grad());
}

// ---- printing ----

extern "C" void st_print(const st_tensor* t) {
  std::cout << t->t << std::endl;
}
