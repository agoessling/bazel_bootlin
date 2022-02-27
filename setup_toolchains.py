import argparse
import os

_AVAILABLE_TOOLCHAINS = {
    "x86-64": {
        "2021.11-5": {
            "sha256": "6fe812add925493ea0841365f1fb7ca17fd9224bab61a731063f7f12f3a621b0",
        },
    },
    "x86-64-core-i7": {
        "2020.08-1": {
            "sha256": "3dd408e857f5c8e579748995477f2783fcf5ad0aac89719ea3c5c75446dfa63c",
        },
    },
    "aarch64": {
        "2021.11-1": {
            "sha256": "dec070196608124fa14c3f192364c5b5b057d7f34651ad58ebb8fc87959c97f7",
        },
        "2020.08-1": {
            "sha256": "8ab7a2f17cb96621b048ab0a872650dd62faa54cd74c961b9902b8c04bff7dd1",
        },
    },
}

_ALL_TOOLS = [
    "ar",
    "cpp",
    "gcc",
    "gcov",
    "ld",
    "nm",
    "objdump",
    "strip",
]

_ARCH_MAPPING = {
    "x86-64-core-i7": "x86_64",
    "x86-64": "x86_64",
    "aarch64": "aarch64",
}


def create_wrappers(wrapper_dir):
  for arch, buildroot_versions in _AVAILABLE_TOOLCHAINS.items():
    try:
      os.mkdir(os.path.join(wrapper_dir, arch))
    except FileExistsError:
      pass

    for version in buildroot_versions:
      try:
        os.mkdir(os.path.join(wrapper_dir, arch, version))
      except FileExistsError:
        pass

      for tool in _ALL_TOOLS:
        tool_name = f'{arch}-linux-gnu-{version}-{tool}'
        tool_path = os.path.join(wrapper_dir, arch, version, tool_name)
        try:
          os.symlink('../../tool_wrapper.sh', tool_path)
        except FileExistsError:
          pass


def write_toolchain_info(filename):
  with open(filename, 'w') as f:
    f.write('AVAILABLE_TOOLCHAINS = {}\n'.format(_AVAILABLE_TOOLCHAINS))
    f.write('ALL_TOOLS = {}\n'.format(_ALL_TOOLS))
    f.write('ARCH_MAPPING = {}\n'.format(_ARCH_MAPPING))


def write_test_script(filename):
  with open(filename, 'w') as f:
    f.write('#!/bin/bash\n')
    f.write('set -e\n')
    f.write('set -o xtrace\n\n')

    for arch, buildroot_versions in _AVAILABLE_TOOLCHAINS.items():
      for version in buildroot_versions:
        platform = '@bazel_bootlin//platforms:{}-linux-gnu-{}'.format(arch, version)
        f.write('bazel build --verbose_failures --platforms={} //test:test_cpp\n'.format(platform))
        f.write('bazel build --verbose_failures --platforms={} //test:test_c\n'.format(platform))


def main():
  parser = argparse.ArgumentParser(description='Generate wrapper scripts for Bazel toolchains.')
  args = parser.parse_args()

  root_dir = os.path.dirname(os.path.realpath(__file__))

  create_wrappers(os.path.join(root_dir, 'toolchains/tool_wrappers'))
  write_toolchain_info(os.path.join(root_dir, 'toolchains/toolchain_info.bzl'))
  write_test_script(os.path.join(root_dir, 'test_build_all.sh'))


if __name__ == '__main__':
  main()
