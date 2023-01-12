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

def bootlin_toolchain_deps(architecture, buildroot_version):
    if (architecture not in AVAILABLE_TOOLCHAINS or
        buildroot_version not in AVAILABLE_TOOLCHAINS[architecture]):
        fail("""
Bootlin architecture and buildroot version combo ({0}, {1}) not supported.
If required, file an issue here: https://github.com/agoessling/bazel_bootlin/issues
""".format(architecture, buildroot_version))

    TOOLCHAIN_BUILD_FILE = """
filegroup(
    name = "all_files",
    srcs = glob(["**"]),
    visibility = ["//visibility:public"],
)"""

    toolchain_name = "{0}-linux-gnu-{1}".format(architecture, buildroot_version)

    http_archive(
        name = toolchain_name,
        build_file_content = TOOLCHAIN_BUILD_FILE,
        url = ("https://toolchains.bootlin.com/downloads/releases/toolchains/" +
               "{0}/tarballs/{0}--glibc--stable-{1}.tar.bz2").format(
            architecture,
            buildroot_version,
        ),
        sha256 = AVAILABLE_TOOLCHAINS[architecture][buildroot_version]["sha256"],
        strip_prefix = "{0}--glibc--stable-{1}".format(architecture, buildroot_version),
    )

    native.register_toolchains(
        "@bazel_bootlin//toolchains:{0}_toolchain".format(toolchain_name),
    )

def bootlin_all_toolchain_deps():
    for architecture in AVAILABLE_TOOLCHAINS:
        for buildroot_version in AVAILABLE_TOOLCHAINS[architecture]:
            bootlin_toolchain_deps(architecture, buildroot_version)

def bootlin_toolchain_defs(architecture, buildroot_version):
    toolchain_name = "{0}-linux-gnu-{1}".format(architecture, buildroot_version)

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
                AVAILABLE_TOOLCHAINS[architecture][buildroot_version]["platform_arch"],
            ),
            "@platforms//os:linux",
            "@bazel_bootlin//platforms:{0}".format(buildroot_version),
        ],
        toolchain = "{0}_cc_toolchain".format(toolchain_name),
        toolchain_type = "@bazel_tools//tools/cpp:toolchain_type",
    )

def bootlin_all_toolchain_defs():
    for architecture in AVAILABLE_TOOLCHAINS:
        for buildroot_version in AVAILABLE_TOOLCHAINS[architecture]:
            bootlin_toolchain_defs(architecture, buildroot_version)

def _impl_cc_bootlin_toolchain_config(ctx):
    """Generic implementation for toolchains provided by Bootlin built from buildroot.

    Flags and features were crafted to be aligned with the native starlark implementations here:
    https://github.com/bazelbuild/rules_cc/blob/main/cc/private/toolchain/unix_cc_toolchain_config.bzl
    https://github.com/bazelbuild/rules_cc/blob/main/cc/private/toolchain/unix_cc_configure.bzl
    """
    toolchain_name = "{0}-linux-gnu-{1}".format(ctx.attr.architecture, ctx.attr.buildroot_version)

    sysroot = "external/{0}/{1}/sysroot".format(
        ctx.attr.buildroot_base or toolchain_name,
        AVAILABLE_TOOLCHAINS[ctx.attr.architecture][ctx.attr.buildroot_version]["tool_prefix"],
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
        tool_wrapper = "tool_wrappers/{0}/{1}/{2}-{3}".format(
            ctx.attr.architecture,
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
                flag_groups = [
                    flag_group(
                        flags = [
                            "-std=c++17",
                        ] + ctx.attr.extra_cxxflags,
                    ),
                ],
            ),
        ],
    )

    rpaths = []
    if ctx.attr.bazel_output_base and ctx.attr.sysroot_ld:
        abs_sysroot = "{output_base}/{sysroot}".format(
            output_base = ctx.attr.bazel_output_base,
            sysroot = sysroot,
        )

        rpaths = [
            flag.format(abs_sysroot = abs_sysroot)
            for flag in [
                "-Wl,--rpath={abs_sysroot}/lib",
                "-Wl,--rpath={abs_sysroot}/usr/lib",
            ]
        ] + [
            "-Wl,--dynamic-linker={output_base}/{sysroot_ld}".format(
                output_base = ctx.attr.bazel_output_base,
                sysroot_ld = ctx.attr.sysroot_ld.files.to_list()[0].path,
            ),
        ]

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
                    "-lstdc++",
                    "-lm",
                ] + rpaths + ctx.attr.extra_ldflags)],
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
        "buildroot_base": attr.string(
            default = "",
            doc = "Workspace naming containing toolchain buildroot.",
        ),
        "bazel_output_base": attr.string(
            default = "",
            doc = "Absolute path used as a prefix for linker rpaths if provided.",
        ),
        "sysroot_ld": attr.label(
            doc = "Replacement for system dynamic linker.",
        ),
        "extra_cxxflags": attr.string_list(
            default = [],
            doc = "Additional flags used for C++ compile actions.",
        ),
        "extra_ldflags": attr.string_list(
            default = [],
            doc = "Additional flags used for link actions.",
        ),
    },
    provides = [CcToolchainConfigInfo],
)
