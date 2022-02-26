load("//toolchains:toolchains.bzl", "cc_bootlin_toolchain_config")

py_binary(
    name = "make_tool_wrappers",
    srcs = ["make_tool_wrappers.py"],
)

filegroup(name = "empty")

filegroup(
    name = "wrappers",
    srcs = glob(["tool_wrappers/**"]),
)

filegroup(
    name = "all_files",
    srcs = [
        "@x86-64-core-i7-linux-gnu-2020.08-1//:all_files",
        ":wrappers",
    ],
)

platform(
    name = "x86-64-linux-gnu",
    constraint_values = [
        "@platforms//cpu:x86_64",
        "@platforms//os:linux",
    ],
)

cc_bootlin_toolchain_config(
    name = "config",
    architecture = "x86-64-core-i7",
    buildroot_version = "2020.08-1",
)

cc_toolchain(
    name = "x86-64-core-i7-toolchain",
    toolchain_identifier = "x86-64-core-i7-linux-gnu-2020.08-1",
    toolchain_config = ":config",
    all_files = ":all_files",
    compiler_files = ":all_files",
    dwp_files = ":empty",
    linker_files = ":all_files",
    objcopy_files = ":empty",
    strip_files = ":empty",
)

toolchain(
    name = "x86-64-core-i7-linux-gnu-toolchain",
    exec_compatible_with = [
        "@platforms//cpu:x86_64",
        "@platforms//os:linux",
    ],
    target_compatible_with = [
        "@platforms//cpu:x86_64",
        "@platforms//os:linux",
    ],
    toolchain = ":x86-64-core-i7-toolchain",
    toolchain_type = "@bazel_tools//tools/cpp:toolchain_type",
)
