load("@bootlin_bazel//platforms:platforms.bzl", "all_platforms")

constraint_setting(
    name = "buildroot_version",
    visibility = ["//visibility:public"],
)

# Used instead of @platforms//os:linux to ensure native toolchain is not used.
constraint_value(
    name = "bootlin_linux",
    constraint_setting = "@platforms//os:os",
    visibility = ["//visibility:public"],
)

all_platforms()
