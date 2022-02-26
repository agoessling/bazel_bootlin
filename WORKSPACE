workspace(name = "bootlin_bazel")

load("//toolchains:toolchains.bzl", "bootlin_toolchain_deps")

bootlin_toolchain_deps(
    architecture = "x86-64-core-i7",
    buildroot_version = "2020.08-1",
    sha256 = "3dd408e857f5c8e579748995477f2783fcf5ad0aac89719ea3c5c75446dfa63c",
)

register_toolchains(
    "//toolchains:x86-64-core-i7-linux-gnu-toolchain",
)
