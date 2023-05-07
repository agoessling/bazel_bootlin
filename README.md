# bazel_bootlin

Provides hermetic [Bazel](https://bazel.build/) C/C++ toolchains based on
[Buildroot](https://buildroot.org/) toolchains provided by
[Bootlin](https://toolchains.bootlin.com/).

## Usage

### WORKSPACE

To incorporate `bazel_bootlin` toolchains into your project, copy the following into your
`WORKSPACE` file.

```Starlark
load("@bazel_tools//tools/build_defs/repo:http.bzl", "http_archive")

http_archive(
    name = "bazel_bootlin",
    # See release page for latest version url and sha.
)

load("@bazel_bootlin//toolchains:toolchains.bzl", "bootlin_all_toolchain_deps")

bootlin_all_toolchain_deps()
```

This will bring all of the available toolchains (and their associated
[`platform`](https://bazel.build/docs/platforms) definitions) into your project.  The toolchains will
only be downloaded when actually utilized, but if you prefer, you can only import a specific
toolchain:

```Starlark
load("@bazel_bootlin//toolchains:toolchains.bzl", "bootlin_toolchain_deps")

bootlin_toolchain_deps(
    architecture = "x86-64-core-i7",
    buildroot_version = "2020.08-1",
)
```

* `architecture` - refers to the [architecture
  string](https://toolchains.bootlin.com/toolchains.html) used by Bootlin.
* `buildroot_version` - refers to the [Buildroot version
  string](https://toolchains.bootlin.com/releases_x86-64-core-i7.html#:~:text=i7%2D%2Dglibc%2D%2Dstable%2D-,2021.11%2D1,-Download%20sha256)
used by Bootlin.

### Available Toolchains

Currently `bazel_bootlin` only provides the "glibc--stable" version of the following Bootlin
toolchains:

| Architecture | Buildroot Version |
| --- | --- |
| `x86-64` | `2022.08-1`, `2021.11-5` |
| `x86-64-core-i7` | `2020.08-1` |
| `aarch64` | `2021.11-1`, `2020.08-1` |
| `armv7-eabihf` | `2020.08-1` |

This list is easily expanded.  If a toolchain of interest isn't available feel free to submit and
[issue](https://github.com/agoessling/bazel_bootlin/issues), or alternatively take a look at
`_AVAILABLE_TOOLCHAINS` in [`setup_toolchains.py`](setup_toolchains.py) and create a pull request.
Don't forget to actually run `setup_toolchains.py` after adding a toolchain and before submitting a
PR:

```Shell
bazel run //:setup_toolchains
```

### Platforms

`bazel_bootlin` defines a different [`platform`](https://bazel.build/docs/platforms) for each
toolchain that is included.  The platforms specify `constraint_value` for the canonical
`@platforms//os:os` and `@platforms//cpu:cpu` `constraint_setting`:

```Starlark
platform(
    name = "{architecture}-linux-gnu-{buildroot_version}",
    constraint_values = [
        "@platforms//cpu:{architecture}",
        "@platforms//os:linux",
        "@bazel_bootlin//platforms:{buildroot_version}",
    ],
)
```

Specifying one of these platforms will cause Bazel to use the corresponding toolchain during build.

### Building With Toolchain

In order to enable toolchain selection via platforms, Bazel requires a special flag along with the
target platform:

```Shell
bazel build --incompatible_enable_cc_toolchain_resolution --platforms=@bazel_bootlin//platforms:{architecture}-linux-gnu-{buildroot_version} //...
```

The ergonomics can be improved by placing the flags in a
[`.bazelrc`](https://bazel.build/docs/bazelrc) file:

```Shell
build --incompatible_enable_cc_toolchain_resolution
build --platforms=@bazel_bootlin//platforms:{architecture}-linux-gnu-{buildroot_version}
```

Then a simple `bazel build //...` will utilize the desired toolchain.
