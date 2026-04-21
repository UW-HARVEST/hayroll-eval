# Test Instructions

These instructions describe the contents of `libmcs_patch/`, which are copied into the fetched upstream `./libmcs` source tree by `fetch_benchmarks.bash`. After that overlay, the patched libmcs checkout is self-contained and the test runner lives at `./libmcs/test_libmcs.bash`.

- Run `./configure`

```
./configure \
    --cross-compile="" \
    --compilation-flags="" \
    --disable-denormal-handling \
    --disable-long-double-procedures \
    --disable-complex-procedures \
    --little-endian
```

- Run `make clean` and then `bear -- make` to generate a `compile_commands.json` file.

- Comment out everything in `libm/include/config.h`. This helps the Pioneer symbolic executor explore different preprocessor defines.

- Run Hayroll `/path/to/hayroll ./compile_commands.json ./hayroll_out`.

- Build the translation output. Note that you need to modify the `[features]` section in the `Cargo.toml` in the `hayroll_out` directory to build with different feature flags.

```
cd ./hayroll_out
cargo build
```

- Run the tests. These tests were adapted from openlibm's test suite and are overlaid into the upstream repository as `./test/`.

```
./test_libmcs.bash
```
