load("@bazel_tools//tools/build_defs/cc:action_names.bzl", "ACTION_NAMES")
load("@bazel_tools//tools/build_defs/repo:http.bzl", "http_archive")
load(
    "@bazel_tools//tools/cpp:cc_toolchain_config_lib.bzl",
    "feature",
    "flag_group",
    "flag_set",
    "tool_path",
    "with_feature_set",
)
load(
    "@bazel_bootlin//toolchains:toolchain_info.bzl",
    "ALL_TOOLS",
    "AVAILABLE_TOOLCHAINS",
)

def bootlin_toolchain_deps(architecture, cstdlib, buildroot_version):
    if (architecture not in AVAILABLE_TOOLCHAINS or
        cstdlib not in AVAILABLE_TOOLCHAINS[architecture] or
        buildroot_version not in AVAILABLE_TOOLCHAINS[architecture][cstdlib]):
        fail("""
Bootlin architecture and buildroot version combo ({0}, {1}, {2}) not supported.
If required, file an issue here: https://github.com/agoessling/bazel_bootlin/issues
""".format(architecture, cstdlib, buildroot_version))

    TOOLCHAIN_BUILD_FILE = """
filegroup(
    name = "all_files",
    srcs = glob(["**"]),
    visibility = ["//visibility:public"],
)"""

    toolchain_name = "{0}-linux-{1}-{2}".format(architecture, cstdlib, buildroot_version)

    http_archive(
        name = toolchain_name,
        build_file_content = TOOLCHAIN_BUILD_FILE,
        url = ("https://toolchains.bootlin.com/downloads/releases/toolchains/" +
               "{0}/tarballs/{0}--{1}--stable-{2}.tar.bz2").format(
            architecture,
            cstdlib,
            buildroot_version,
        ),
        sha256 = AVAILABLE_TOOLCHAINS[architecture][cstdlib][buildroot_version]["sha256"],
        strip_prefix = "{0}--{1}--stable-{2}".format(architecture, cstdlib, buildroot_version),
    )

    native.register_toolchains(
        "@bazel_bootlin//toolchains:{0}_toolchain".format(toolchain_name),
    )

def bootlin_all_toolchain_deps():
    for architecture in AVAILABLE_TOOLCHAINS:
        for cstdlib in AVAILABLE_TOOLCHAINS[architecture]:
            for buildroot_version in AVAILABLE_TOOLCHAINS[architecture][cstdlib]:
                bootlin_toolchain_deps(architecture, cstdlib, buildroot_version)

def bootlin_toolchain_defs(architecture, cstdlib, buildroot_version):
    toolchain_name = "{0}-linux-{1}-{2}".format(architecture, cstdlib, buildroot_version)

    native.filegroup(
        name = "{0}_all_files".format(toolchain_name),
        srcs = [
            "@{0}//:all_files".format(toolchain_name),
            "@bazel_bootlin//toolchains:wrappers",
        ],
    )

    cc_bootlin_toolchain_config(
        name = "{0}_toolchain_config".format(toolchain_name),
        architecture = architecture,
        buildroot_version = buildroot_version,
        cstdlib = cstdlib,
    )

    native.cc_toolchain(
        name = "{0}_cc_toolchain".format(toolchain_name),
        toolchain_config = ":{0}_toolchain_config".format(toolchain_name),
        all_files = ":{0}_all_files".format(toolchain_name),
        ar_files = ":{0}_all_files".format(toolchain_name),
        compiler_files = ":{0}_all_files".format(toolchain_name),
        dwp_files = "@bazel_bootlin//toolchains:empty",
        linker_files = ":{0}_all_files".format(toolchain_name),
        objcopy_files = "@bazel_bootlin//toolchains:empty",
        strip_files = "@bazel_bootlin//toolchains:empty",
    )

    native.toolchain(
        name = "{0}_toolchain".format(toolchain_name),
        exec_compatible_with = [
            "@platforms//cpu:x86_64",
            "@platforms//os:linux",
        ],
        target_compatible_with = [
            "@platforms//cpu:{0}".format(
                AVAILABLE_TOOLCHAINS[architecture][cstdlib][buildroot_version]["platform_arch"],
            ),
            "@platforms//os:linux",
            "@bazel_bootlin//platforms:{0}".format(buildroot_version),
        ],
        toolchain = "{0}_cc_toolchain".format(toolchain_name),
        toolchain_type = "@bazel_tools//tools/cpp:toolchain_type",
    )

def bootlin_all_toolchain_defs():
    for architecture in AVAILABLE_TOOLCHAINS:
        for cstdlib in AVAILABLE_TOOLCHAINS[architecture]:
            for buildroot_version in AVAILABLE_TOOLCHAINS[architecture][cstdlib]:
                bootlin_toolchain_defs(architecture, cstdlib, buildroot_version)

def _impl_cc_bootlin_toolchain_config(ctx):
    """Generic implementation for toolchains provided by Bootlin built from buildroot.

    Flags and features were crafted to be aligned with the native starlark implementations here:
    https://github.com/bazelbuild/rules_cc/blob/main/cc/private/toolchain/unix_cc_toolchain_config.bzl
    https://github.com/bazelbuild/rules_cc/blob/main/cc/private/toolchain/unix_cc_configure.bzl
    """
    toolchain_name = "{0}-linux-{1}-{2}".format(ctx.attr.architecture, ctx.attr.cstdlib, ctx.attr.buildroot_version)

    sysroot = "external/{0}/{1}/sysroot".format(
        toolchain_name,
        AVAILABLE_TOOLCHAINS[ctx.attr.architecture][ctx.attr.cstdlib][ctx.attr.buildroot_version]["tool_prefix"],
    )

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

    all_cpp_compile_actions = [
        ACTION_NAMES.clif_match,
        ACTION_NAMES.cpp_compile,
        ACTION_NAMES.cpp_header_parsing,
        ACTION_NAMES.cpp_module_codegen,
        ACTION_NAMES.cpp_module_compile,
        ACTION_NAMES.linkstamp_compile,
        ACTION_NAMES.lto_backend,
    ]

    all_link_actions = [
        ACTION_NAMES.cpp_link_executable,
        ACTION_NAMES.cpp_link_dynamic_library,
        ACTION_NAMES.cpp_link_nodeps_dynamic_library,
    ]

    tool_paths = []
    for tool in ALL_TOOLS:
        tool_wrapper = "tool_wrappers/{0}/{1}/{2}/{3}-{4}".format(
            ctx.attr.architecture,
            ctx.attr.cstdlib,
            ctx.attr.buildroot_version,
            toolchain_name,
            tool,
        )
        tool_paths.append(tool_path(name = tool, path = tool_wrapper))

    feature_compiler_flags = feature(
        name = "compiler_flags",
        enabled = True,
        flag_sets = [
            flag_set(
                actions = all_compile_actions,
                flag_groups = [flag_group(flags = [
                    "-U_FORTIFY_SOURCE",
                    "-fstack-protector",
                    "-Wall",
                    "-Wunused-but-set-parameter",
                    "-Wno-free-nonheap-object",
                    "-fno-omit-frame-pointer",
                    "-fdiagnostics-color",
                    "-no-canonical-prefixes",
                    "-fno-canonical-system-headers",
                    "--sysroot={0}".format(sysroot),
                    "-Wno-builtin-macro-redefined",
                    "-D__DATE__=\"redacted\"",
                    "-D__TIMESTAMP__=\"redacted\"",
                    "-D__TIME__=\"redacted\"",
                ])],
            ),
            flag_set(
                actions = all_cpp_compile_actions,
                flag_groups = [flag_group(flags = [
                    "-std=c++17",
                ])],
            ),
        ],
    )

    feature_linker_flags = feature(
        name = "linker_flags",
        enabled = True,
        flag_sets = [
            flag_set(
                actions = all_link_actions,
                flag_groups = [flag_group(flags = [
                    # Don't add --sysroot here.  For some reason this confuses the linker.
                    "-Wl,-no-as-needed",
                    "-Wl,-z,relro,-z,now",
                    "-pass-exit-codes",
                    "-lm",
                ])],
            ),
            flag_set(
                actions = all_link_actions,
                flag_groups = [flag_group(flags = [
                    "-Wl,--gc-sections",
                ])],
                with_features = [with_feature_set(features = ["opt"])],
            ),
        ],
    )

    feature_opt = feature(
        name = "opt",
        flag_sets = [flag_set(
            actions = all_compile_actions,
            flag_groups = [flag_group(flags = [
                "-g0",
                "-O2",
                "-DNDEBUG",
                "-ffunction-sections",
                "-fdata-sections",
            ])],
        )],
    )

    feature_dbg = feature(
        name = "dbg",
        flag_sets = [flag_set(
            actions = all_compile_actions,
            flag_groups = [flag_group(flags = [
                "-g",
            ])],
        )],
    )

    feature_supports_pic = feature("supports_pic", enabled = True)
    feature_supports_dynamic_linker = feature("supports_dynamic_linker", enabled = True)

    features = [
        feature_compiler_flags,
        feature_linker_flags,
        feature_opt,
        feature_dbg,
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
            doc = "Toolchain target architecture.",
        ),
        "buildroot_version": attr.string(
            mandatory = True,
            doc = "Toolchain buildroot version.",
        ),
        "cstdlib": attr.string(
            mandatory = True,
            doc = "Toolchain cstlib type i.e. glibc, musl, etc...",
        ),
    },
    provides = [CcToolchainConfigInfo],
)
