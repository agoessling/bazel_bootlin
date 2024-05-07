#!/bin/bash
set -e
set -o xtrace

bazel build --verbose_failures --platforms=@bazel_bootlin//platforms:x86-64-linux-glibc-2021.11-5 //test:test_cpp
bazel build --verbose_failures --platforms=@bazel_bootlin//platforms:x86-64-linux-glibc-2021.11-5 //test:test_c
bazel build --verbose_failures --platforms=@bazel_bootlin//platforms:x86-64-linux-glibc-2022.08-1 //test:test_cpp
bazel build --verbose_failures --platforms=@bazel_bootlin//platforms:x86-64-linux-glibc-2022.08-1 //test:test_c
bazel build --verbose_failures --platforms=@bazel_bootlin//platforms:x86-64-core-i7-linux-glibc-2020.08-1 //test:test_cpp
bazel build --verbose_failures --platforms=@bazel_bootlin//platforms:x86-64-core-i7-linux-glibc-2020.08-1 //test:test_c
bazel build --verbose_failures --platforms=@bazel_bootlin//platforms:aarch64-linux-glibc-2021.11-1 //test:test_cpp
bazel build --verbose_failures --platforms=@bazel_bootlin//platforms:aarch64-linux-glibc-2021.11-1 //test:test_c
bazel build --verbose_failures --platforms=@bazel_bootlin//platforms:aarch64-linux-glibc-2020.08-1 //test:test_cpp
bazel build --verbose_failures --platforms=@bazel_bootlin//platforms:aarch64-linux-glibc-2020.08-1 //test:test_c
bazel build --verbose_failures --platforms=@bazel_bootlin//platforms:aarch64-linux-musl-2021.11-1 //test:test_cpp
bazel build --verbose_failures --platforms=@bazel_bootlin//platforms:aarch64-linux-musl-2021.11-1 //test:test_c
bazel build --verbose_failures --platforms=@bazel_bootlin//platforms:armv7-eabihf-linux-glibc-2020.08-1 //test:test_cpp
bazel build --verbose_failures --platforms=@bazel_bootlin//platforms:armv7-eabihf-linux-glibc-2020.08-1 //test:test_c
bazel build --verbose_failures --platforms=@bazel_bootlin//platforms:riscv64-lp64d-linux-glibc-2024.02-1 //test:test_cpp
bazel build --verbose_failures --platforms=@bazel_bootlin//platforms:riscv64-lp64d-linux-glibc-2024.02-1 //test:test_c
