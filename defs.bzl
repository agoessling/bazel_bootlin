"""
Defines a bootlin_toolchain rule to allow toolchain customization.
"""

load(
    "@bazel_bootlin//toolchains:toolchain_info.bzl",
    "ALL_TOOLS",
    "AVAILABLE_TOOLCHAINS",
)

def _bootlin_toolchain_impl(rctx):
    architecture = rctx.attr.architecture
    buildroot_version = rctx.attr.buildroot_version
    platform_arch = AVAILABLE_TOOLCHAINS[architecture][buildroot_version]["platform_arch"]

    rctx.download_and_extract(
        url = ("https://toolchains.bootlin.com/downloads/releases/toolchains/" +
               "{0}/tarballs/{0}--glibc--stable-{1}.tar.bz2").format(
            architecture,
            buildroot_version,
        ),
        sha256 = AVAILABLE_TOOLCHAINS[architecture][buildroot_version]["sha256"],
        stripPrefix = "{0}--glibc--stable-{1}".format(architecture, buildroot_version),
    )

    for tool in ALL_TOOLS:
        buildroot_tool = (
            "{}.br_real".format(tool) if tool in ["cpp", "gcc"] else tool
        )

        rctx.file(
            "tool_wrappers/{0}/{1}/{0}-linux-gnu-{1}-{2}".format(
                architecture,
                buildroot_version,
                tool,
            ),
            content = """
#!/usr/bin/env bash
exec external/{0}/bin/{1}-buildroot-linux-gnu-{2} $@
""".format(
                rctx.attr.name,
                platform_arch,
                buildroot_tool,
            ),
        )

    as_string = lambda args: (
        "[{}]".format(", ".join(
            [
                "'{}'".format(arg)
                for arg in args
            ],
        ))
    )

    bazel_output_base = str(rctx.path(".")).removesuffix("/external/{}".format(rctx.attr.name))
    template = Label("//toolchains:BUILD.toolchain.tpl")

    rctx.template(
        "BUILD.bazel",
        template,
        {
            "{bazel_output_base}": bazel_output_base,
            "{toolchain_workspace}": rctx.attr.name,
            "{bootlin_workspace}": template.workspace_name,
            "{architecture}": architecture,
            "{buildroot_version}": buildroot_version,
            "{platform_arch}": platform_arch,
            "{extra_cxxflags}": as_string(rctx.attr.extra_cxxflags),
            "{extra_ldflags}": as_string(rctx.attr.extra_ldflags),
        },
    )

bootlin_toolchain = repository_rule(
    attrs = {
        "architecture": attr.string(
            mandatory = True,
        ),
        "buildroot_version": attr.string(
            mandatory = True,
        ),
        "extra_cxxflags": attr.string_list(
            default = [],
            doc = "Additional flags used for C++ compile actions.",
        ),
        "extra_ldflags": attr.string_list(
            default = [],
            doc = "Additional flags used for link actions.",
        ),
        "extra_toolchain_constraints": attr.string_list(
            default = [],  # TODO
            doc = "Additional platform constraints beyond `cpu` and `os`.",
        ),
    },
    local = True,
    configure = True,
    implementation = _bootlin_toolchain_impl,
)
