load("@bazel_bootlin//toolchains:toolchain_info.bzl", "AVAILABLE_TOOLCHAINS")

def all_platforms():
    for architecture in AVAILABLE_TOOLCHAINS:
        for buildroot_version in AVAILABLE_TOOLCHAINS[architecture]:
            if buildroot_version not in native.existing_rules():
                native.constraint_value(
                    name = buildroot_version,
                    constraint_setting = "@bazel_bootlin//platforms:buildroot_version",
                    visibility = ["//visibility:public"],
                )

            native.platform(
                name = "{0}-linux-gnu-{1}".format(architecture, buildroot_version),
                constraint_values = [
                    "@platforms//cpu:{0}".format(AVAILABLE_TOOLCHAINS[architecture][buildroot_version]['platform_arch']),
                    "@platforms//os:linux",
                    "@bazel_bootlin//platforms:{0}".format(buildroot_version),
                ],
                visibility = ["//visibility:public"],
            )
