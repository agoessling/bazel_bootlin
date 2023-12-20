import argparse
import os

_AVAILABLE_TOOLCHAINS = {
    'x86-64': {
        'glibc': {
          '2021.11-5': {
              'sha256': '6fe812add925493ea0841365f1fb7ca17fd9224bab61a731063f7f12f3a621b0',
              'platform_arch': 'x86_64',
              'tool_prefix': 'x86_64-buildroot-linux-gnu',
          },
          '2022.08-1': {
              'sha256': '861c1e8ad0a66e4c28e7a1f8319d68080ab0ff8d16a765e65540f1957203a190',
              'platform_arch': 'x86_64',
              'tool_prefix': 'x86_64-buildroot-linux-gnu',
          },
        },
    },
    'x86-64-core-i7': {
        'glibc': {
          '2020.08-1': {
              'sha256': '3dd408e857f5c8e579748995477f2783fcf5ad0aac89719ea3c5c75446dfa63c',
              'platform_arch': 'x86_64',
              'tool_prefix': 'x86_64-buildroot-linux-gnu',
          },
        },
    },
    'aarch64': {
        'glibc': {
          '2021.11-1': {
              'sha256': 'dec070196608124fa14c3f192364c5b5b057d7f34651ad58ebb8fc87959c97f7',
              'platform_arch': 'aarch64',
              'tool_prefix': 'aarch64-buildroot-linux-gnu',
          },
          '2020.08-1': {
              'sha256': '8ab7a2f17cb96621b048ab0a872650dd62faa54cd74c961b9902b8c04bff7dd1',
              'platform_arch': 'aarch64',
              'tool_prefix': 'aarch64-buildroot-linux-gnu',
          },
        },
        'musl': {
            '2021.11-1': {
                'sha256': '6919b4cf04b8c5628a2a93bcf4b05e1143ab15dfb4bc2acde02a2e3c075bf041',
                'platform_arch': 'aarch64',
                'tool_prefix': 'aarch64-buildroot-linux-musl',
            },
        },
    },
    'armv7-eabihf': {
        'glibc': {
          '2020.08-1': {
              'sha256': '7b6682603af9a9b5c0e46fd57165723483bb68295e827d14d238e63f33a147a8',
              'platform_arch': 'armv7',
              'tool_prefix': 'arm-buildroot-linux-gnueabihf',
          },
        },
    },
}

_ALL_TOOLS = {
    'ar': {
        'buildroot_name': 'ar'
    },
    'cpp': {
        'buildroot_name': 'cpp.br_real'
    },
    'gcc': {
        'buildroot_name': 'gcc.br_real'
    },
    'gcov': {
        'buildroot_name': 'gcov'
    },
    'ld': {
        'buildroot_name': 'ld'
    },
    'nm': {
        'buildroot_name': 'nm'
    },
    'objdump': {
        'buildroot_name': 'objdump'
    },
    'strip': {
        'buildroot_name': 'strip'
    },
}


def create_wrappers(wrapper_dir):
  for arch, cstdlibs in _AVAILABLE_TOOLCHAINS.items():
    try:
      os.mkdir(os.path.join(wrapper_dir, arch))
    except FileExistsError:
      pass

    for cstdlib, buildroot_versions in cstdlibs.items():
      try:
        os.mkdir(os.path.join(wrapper_dir, arch, cstdlib))
      except FileExistsError:
        pass

      for version, version_info in buildroot_versions.items():
        try:
          os.mkdir(os.path.join(wrapper_dir, arch, cstdlib, version))
        except FileExistsError:
          pass

        for tool, tool_info in _ALL_TOOLS.items():
          toolchain_name = f'{arch}-linux-{cstdlib}-{version}'
          wrapper_name = f'{toolchain_name}-{tool}'
          actual_tool_name = f'{version_info["tool_prefix"]}-{tool_info["buildroot_name"]}'
          wrapper_path = os.path.join(wrapper_dir, arch, cstdlib, version, wrapper_name)

          with open(wrapper_path, 'w') as f:
            f.write('#!/bin/bash\n')
            # Uses buildroot's ".br_real" wrapper to allow -no-canonical-prefix,
            # -fno-canonical-system-headers, and --sysroot to correctly work (using relative paths).
            f.write(f'exec external/{toolchain_name}/bin/{actual_tool_name} $@\n')

          os.chmod(wrapper_path, 0o777)


def write_toolchain_info(filename):
  with open(filename, 'w') as f:
    f.write(f'AVAILABLE_TOOLCHAINS = {_AVAILABLE_TOOLCHAINS}\n')
    f.write(f'ALL_TOOLS = {list(_ALL_TOOLS)}\n')


def write_test_script(filename):
  with open(filename, 'w') as f:
    f.write('#!/bin/bash\n')
    f.write('set -e\n')
    f.write('set -o xtrace\n\n')

    for arch, cstdlibs in _AVAILABLE_TOOLCHAINS.items():
      for cstdlib, buildroot_versions in cstdlibs.items():
        for version in buildroot_versions:
          platform = f'@bazel_bootlin//platforms:{arch}-linux-{cstdlib}-{version}'
          f.write(f'bazel build --verbose_failures --platforms={platform} //test:test_cpp\n')
          f.write(f'bazel build --verbose_failures --platforms={platform} //test:test_c\n')

  os.chmod(filename, 0o777)


def main():
  parser = argparse.ArgumentParser(description='Generate wrapper scripts for Bazel toolchains.')
  args = parser.parse_args()

  root_dir = os.path.dirname(os.path.realpath(__file__))

  create_wrappers(os.path.join(root_dir, 'toolchains/tool_wrappers'))
  write_toolchain_info(os.path.join(root_dir, 'toolchains/toolchain_info.bzl'))
  write_test_script(os.path.join(root_dir, 'test_build_all.sh'))


if __name__ == '__main__':
  main()
