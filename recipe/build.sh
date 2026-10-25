#!/usr/bin/env bash
set -euxo pipefail

# The repo checkout itself (the recipe has no source section)
SRC="$(cd "$RECIPE_DIR/.." && pwd)"

# The conda compiler activation exports the host preprocessor, which leaks into
# the target library configures (libgcc, libstdc++) and makes them detect host
# glibc headers (e.g. sys/mman.h) that newlib doesn't have. Let each configure
# fall back to "$CC -E" with its own compiler instead.
unset CPP CXXCPP

# Reuse host compilations across rebuilds. Each rattler-build run uses a new
# timestamped work dir, so make paths under the repo relative for cache hits.
export CCACHE_DIR="${CCACHE_DIR:-$SRC/.ccache}"
export CCACHE_BASEDIR="$SRC"
export CCACHE_COMPILERCHECK=content
export CC="ccache $CC" CXX="ccache $CXX"

# about.license_file is looked up in the work dir
cp "$SRC/LICENSE" "$SRC_DIR/LICENSE"

mkdir -p build && cd build
"$SRC/configure" \
    --prefix="$PREFIX" \
    --with-arch="$TC_ARCH" --with-abi="$TC_ABI" \
    --enable-multilib \
    --enable-strip \
    --disable-gdb
make -j"${CPU_COUNT}"
