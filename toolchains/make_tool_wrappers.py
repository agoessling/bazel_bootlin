import argparse
import os

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

def main():
  parser = argparse.ArgumentParser(description='Generate wrapper scripts for Bazel toolchains.')
  parser.add_argument('wrapper_directory', help='Directory for wrapper scripts.')

  args = parser.parse_args()

  for arch, buildroot_versions in _TOOLCHAINS.items():
    try:
      os.mkdir(os.path.join(args.wrapper_directory, arch))
    except FileExistsError:
      pass

    for version in buildroot_versions:
      try:
        os.mkdir(os.path.join(args.wrapper_directory, arch, version))
      except FileExistsError:
        pass

      for tool in _TOOLS:
        tool_name = f'{arch}-linux-gnu-{version}-{tool}'
        tool_path = os.path.join(args.wrapper_directory, arch, version, tool_name)
        try:
          os.symlink('../../tool_wrapper.sh', tool_path)
        except FileExistsError:
          pass


if __name__ == '__main__':
  main()
