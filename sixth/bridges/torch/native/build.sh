#!/bin/bash
# build.sh — compile sixth_torch.cpp into libsixth_torch.dylib
#
# Targets macOS arm64 with Homebrew pytorch 2.5.x.  On other systems
# adjust TORCH_PREFIX and the library names accordingly.
set -e

HERE="$(cd "$(dirname "$0")" && pwd)"
OUT_DIR="$HERE/../../../../build"
mkdir -p "$OUT_DIR"

TORCH_PREFIX="${TORCH_PREFIX:-/opt/homebrew/Cellar/pytorch/2.5.1_4}"
TORCH_INC="$TORCH_PREFIX/libexec/lib/python3.13/site-packages/torch/include"
TORCH_API_INC="$TORCH_INC/torch/csrc/api/include"
TORCH_LIB="${TORCH_LIB:-/opt/homebrew/lib}"

OUT="$OUT_DIR/libsixth_torch.dylib"

echo "Compiling $HERE/sixth_torch.cpp → $OUT"

clang++ \
  -std=c++17 \
  -O2 \
  -fPIC \
  -shared \
  -D_LIBCPP_DISABLE_AVAILABILITY \
  -Wno-invalid-specialization \
  -Wno-deprecated-declarations \
  -I"$TORCH_INC" \
  -I"$TORCH_API_INC" \
  -L"$TORCH_LIB" \
  -ltorch -ltorch_cpu -lc10 \
  -Wl,-rpath,"$TORCH_LIB" \
  -o "$OUT" \
  "$HERE/sixth_torch.cpp"

echo "→ $OUT"
ls -lh "$OUT"
