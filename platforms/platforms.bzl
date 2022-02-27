load("@bootlin_bazel//toolchains:available_toolchains.bzl", "AVAILABLE_TOOLCHAINS", "ARCH_MAPPING")

def all_platforms():
    for architecture in AVAILABLE_TOOLCHAINS:
        native.platform(
            name = "{0}-linux-gnu".format(architecture),
            constraint_values = [
                "@platforms//cpu:{0}".format(ARCH_MAPPING[architecture]),
                "@platforms//os:linux",
            ],
            visibility = ["//visibility:public"],
        )

        for buildroot_version in AVAILABLE_TOOLCHAINS[architecture]:
            if buildroot_version not in native.existing_rules():
                native.constraint_value(
                    name = buildroot_version,
                    constraint_setting = "@bootlin_bazel//platforms:buildroot_version",
                    visibility = ["//visibility:public"],
                )

            native.platform(
                name = "{0}-linux-gnu-{1}".format(architecture, buildroot_version),
                parents = [":{0}-linux-gnu".format(architecture)],
                constraint_values = [
                    "@bootlin_bazel//platforms:{0}".format(buildroot_version),
                ],
                visibility = ["//visibility:public"],
            )
