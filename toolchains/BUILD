load("@bootlin_bazel//toolchains:toolchains.bzl", "bootlin_all_toolchain_defs")

py_binary(
    name = "make_tool_wrappers",
    srcs = ["make_tool_wrappers.py"],
)

filegroup(name = "empty")

filegroup(
    name = "wrappers",
    srcs = glob(["tool_wrappers/**"]),
)

bootlin_all_toolchain_defs()
