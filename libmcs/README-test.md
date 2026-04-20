# Test Instructions

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

- Run Hayroll `/path/to/hayroll ./compile_commands.json ./hayroll_output`.

- Build the translation output. Note that you need to modify the `[features]` section in the `Cargo.toml` in the `hayroll_output` directory to build with different feature flags.

```
cd ./hayroll_output
cargo build
```

- Run the tests. These tests were adapted from openlibm's test suite.

```
cd ./test
./all.bash
```
