"""Extensions for use with bzlmod."""

load(
    "//toolchains:toolchains.bzl",
    _bootlin_toolchain_deps = "bootlin_toolchain_deps",
)

def _bootlin_toolchain_impl(module_ctx):
    for mod in module_ctx.modules:
        if not mod.is_root:
            fail("Call this function from the root module.")
    for toolchain_attr in mod.tags.toolchain:
        attrs = {"register_toolchain": False}
        attrs.update(
            {k: getattr(toolchain_attr, k) for k in dir(toolchain_attr)}
        )
        _bootlin_toolchain_deps(
            **attrs,
        )

bootlin = module_extension(
    implementation = _bootlin_toolchain_impl,
    tag_classes = {
        "toolchain": tag_class(
            attrs = {
                "architecture": attr.string(
                    doc = "Toolchain target architecture",
                    mandatory = True,
                ),
                "buildroot_version": attr.string(
                    mandatory = True,
                    doc = "Toolchain buildroot version.",
                ),
                "cstdlib": attr.string(
                    doc = "Toolchain cstdlib type",
                    mandatory = True,
                ),
            },
        ),
    },
)
