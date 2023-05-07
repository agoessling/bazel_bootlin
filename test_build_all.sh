#!/bin/bash
set -e
set -o xtrace

bazel build --verbose_failures --platforms=@bazel_bootlin//platforms:x86-64-linux-gnu-2021.11-5 //test:test_cpp
bazel build --verbose_failures --platforms=@bazel_bootlin//platforms:x86-64-linux-gnu-2021.11-5 //test:test_c
bazel build --verbose_failures --platforms=@bazel_bootlin//platforms:x86-64-linux-gnu-2022.08-1 //test:test_cpp
bazel build --verbose_failures --platforms=@bazel_bootlin//platforms:x86-64-linux-gnu-2022.08-1 //test:test_c
bazel build --verbose_failures --platforms=@bazel_bootlin//platforms:x86-64-core-i7-linux-gnu-2020.08-1 //test:test_cpp
bazel build --verbose_failures --platforms=@bazel_bootlin//platforms:x86-64-core-i7-linux-gnu-2020.08-1 //test:test_c
bazel build --verbose_failures --platforms=@bazel_bootlin//platforms:aarch64-linux-gnu-2021.11-1 //test:test_cpp
bazel build --verbose_failures --platforms=@bazel_bootlin//platforms:aarch64-linux-gnu-2021.11-1 //test:test_c
bazel build --verbose_failures --platforms=@bazel_bootlin//platforms:aarch64-linux-gnu-2020.08-1 //test:test_cpp
bazel build --verbose_failures --platforms=@bazel_bootlin//platforms:aarch64-linux-gnu-2020.08-1 //test:test_c
bazel build --verbose_failures --platforms=@bazel_bootlin//platforms:armv7-eabihf-linux-gnu-2020.08-1 //test:test_cpp
bazel build --verbose_failures --platforms=@bazel_bootlin//platforms:armv7-eabihf-linux-gnu-2020.08-1 //test:test_c
