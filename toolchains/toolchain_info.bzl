AVAILABLE_TOOLCHAINS = {
    "x86-64": {
        "2021.11-5": {
            "sha256": "6fe812add925493ea0841365f1fb7ca17fd9224bab61a731063f7f12f3a621b0",
            "platform_arch": "x86_64",
            "tool_prefix": "x86_64-buildroot-linux-gnu",
        },
        "2022.08-1": {
            "sha256": "861c1e8ad0a66e4c28e7a1f8319d68080ab0ff8d16a765e65540f1957203a190",
            "platform_arch": "x86_64",
            "tool_prefix": "x86_64-buildroot-linux-gnu",
        },
    },
    "x86-64-core-i7": {
        "2020.08-1": {
            "sha256": "3dd408e857f5c8e579748995477f2783fcf5ad0aac89719ea3c5c75446dfa63c",
            "platform_arch": "x86_64",
            "tool_prefix": "x86_64-buildroot-linux-gnu",
        },
    },
    "aarch64": {
        "2021.11-1": {
            "sha256": "dec070196608124fa14c3f192364c5b5b057d7f34651ad58ebb8fc87959c97f7",
            "platform_arch": "aarch64",
            "tool_prefix": "aarch64-buildroot-linux-gnu",
        },
        "2020.08-1": {
            "sha256": "8ab7a2f17cb96621b048ab0a872650dd62faa54cd74c961b9902b8c04bff7dd1",
            "platform_arch": "aarch64",
            "tool_prefix": "aarch64-buildroot-linux-gnu",
        },
    },
    "armv7-eabihf": {
        "2020.08-1": {
            "sha256": "7b6682603af9a9b5c0e46fd57165723483bb68295e827d14d238e63f33a147a8",
            "platform_arch": "armv7",
            "tool_prefix": "arm-buildroot-linux-gnueabihf",
        },
    },
}

ALL_TOOLS = ["ar", "cpp", "gcc", "gcov", "ld", "nm", "objdump", "strip"]
