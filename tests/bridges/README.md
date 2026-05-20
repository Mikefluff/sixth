# tests/bridges/

Tests for the optional libtorch-FFI bridges.

**Currently empty.** The `sixth/bridges/torch/` Racket-FFI bridges
(shadow / diff / nn) are advertised in the top-level README but the
test harness `torch-test.rkt` has not yet been ported from the
chibi-Scheme legacy tree.

`scripts/verify.sh` checks for the file `tests/bridges/torch-test.rkt`
and reports `ffi optional: n/a` when absent — the regression gate
does not block on the absence. When the bridge tests land, drop
`torch-test.rkt` in this directory and `make verify` picks it up
automatically.

The Makefile target `test-bridges` is currently a no-op shim that
references the missing file; it will start working when the test
file appears.
