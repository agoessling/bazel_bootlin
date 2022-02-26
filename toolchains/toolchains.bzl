load("@bazel_tools//tools/build_defs/cc:action_names.bzl", "ACTION_NAMES")
load("@bazel_tools//tools/build_defs/repo:http.bzl", "http_archive")
load("@bazel_tools//tools/cpp:cc_toolchain_config_lib.bzl", "feature", "flag_group", "flag_set",
    "tool_path")

_TOOLCHAINS = {
    'x86-64': ['2021.11-5'],
    'x86-64-core-i7': ['2020.08-1'],
    'aarch64': ['2021.11-1', '2020.08-1'],
}

_TOOLS = [
    'ar',
    'cpp',
    'gcc',
    'gcov',
    'ld',
    'nm',
    'objdump',
    'strip',
]

def bootlin_toolchain_deps(architecture, buildroot_version, sha256):
    if architecture not in _TOOLCHAINS or buildroot_version not in _TOOLCHAINS[architecture]:
      fail("""
Bootlin architecture buildroot version combo ({0}, {1}) not supported.
If required, file an issue here: https://www.github.com/agoessling/bootlin_bazel
""".format(architecture, buildroot_version))

    TOOLCHAIN_BUILD_FILE = """
filegroup(
    name = "all_files",
    srcs = glob(["**"]),
    visibility = ["//visibility:public"],
)"""

    http_archive(
        name = "{0}-linux-gnu-{1}".format(architecture, buildroot_version),
        build_file_content = TOOLCHAIN_BUILD_FILE,
        url = ("https://toolchains.bootlin.com/downloads/releases/toolchains/"
            + "{0}/tarballs/{0}--glibc--stable-{1}.tar.bz2").format(architecture,
                                                                    buildroot_version),
        sha256 = sha256,
        strip_prefix = "{0}--glibc--stable-{1}".format(architecture, buildroot_version),
    )


def _impl_cc_bootlin_toolchain_config(ctx):
    toolchain_name = "{0}-linux-gnu-{1}".format(ctx.attr.architecture, ctx.attr.buildroot_version)

    arch_alt = ctx.attr.architecture
    if (arch_alt.startswith("x86-64")):
      arch_alt = "x86_64"

    sysroot = "external/{0}/{1}-buildroot-linux-gnu/sysroot".format(toolchain_name, arch_alt)

    all_compile_actions = [
        ACTION_NAMES.assemble,
	ACTION_NAMES.c_compile,
	ACTION_NAMES.clif_match,
	ACTION_NAMES.cpp_compile,
	ACTION_NAMES.cpp_header_parsing,
	ACTION_NAMES.cpp_module_codegen,
	ACTION_NAMES.cpp_module_compile,
	ACTION_NAMES.linkstamp_compile,
	ACTION_NAMES.lto_backend,
	ACTION_NAMES.preprocess_assemble,
    ]

    all_link_actions = [
	ACTION_NAMES.cpp_link_executable,
	ACTION_NAMES.cpp_link_dynamic_library,
	ACTION_NAMES.cpp_link_nodeps_dynamic_library,
    ]

    tool_paths = []
    for tool in _TOOLS:
      tool_wrapper = "tool_wrappers/{0}/{1}/{2}-{3}".format(
          ctx.attr.architecture, ctx.attr.buildroot_version, toolchain_name, tool)
      tool_paths.append(tool_path(name = tool, path = tool_wrapper))

    feature_compiler_flags = feature(
        name = "compiler_flags",
        enabled = True,
        flag_sets = [flag_set(
            actions = all_compile_actions,
            flag_groups = [flag_group(flags = [
                "-no-canonical-prefixes",
                "-fno-canonical-system-headers",
                "--sysroot={0}".format(sysroot),
                "-Wno-builtin-macro-redefined",
                "-D__DATE__=\"redacted\"",
                "-D__TIMESTAMP__=\"redacted\"",
                "-D__TIME__=\"redacted\"",
            ])],
        )],
    )

    feature_supports_pic = feature("supports_pic", enabled = True)
    feature_supports_dynamic_linker = feature("supports_dynamic_linker", enabled = True)

    feature_linker_flags = feature(
        name = "linker_flags",
        enabled = True,
        flag_sets = [flag_set(
            actions = all_link_actions,
            flag_groups = [flag_group(flags = [
                # Don't add --sysroot here.  For some reason this confuses the linker.
                "-lstdc++",
            ])],
        )],
    )

    features = [
        feature_compiler_flags,
        feature_linker_flags,
        feature_supports_pic,
        feature_supports_dynamic_linker,
    ]

    return cc_common.create_cc_toolchain_config_info(
        ctx = ctx,
        features = features,
        toolchain_identifier = toolchain_name,
        host_system_name = "local",
        target_system_name = ctx.attr.architecture,
        target_cpu = ctx.attr.architecture,
        target_libc = ctx.attr.architecture,
        compiler = "compiler",
        abi_version = ctx.attr.architecture,
        abi_libc_version = ctx.attr.architecture,
        tool_paths = tool_paths,
    )


cc_bootlin_toolchain_config = rule(
    implementation = _impl_cc_bootlin_toolchain_config,
    attrs = {
        "architecture": attr.string(
            mandatory = True,
            values = _TOOLCHAINS.keys(),
            doc = "Toolchain target architecture."
        ),
        "buildroot_version": attr.string(
            mandatory = True,
            doc = "Toolchain buildroot version."
        ),
    },
    provides = [CcToolchainConfigInfo],
)
