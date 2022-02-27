AVAILABLE_TOOLCHAINS = {
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

ALL_TOOLS = [
    "ar",
    "cpp",
    "gcc",
    "gcov",
    "ld",
    "nm",
    "objdump",
    "strip",
]

ARCH_MAPPING = {
    "x86-64-core-i7": "x86_64",
    "x86-64": "x86_64",
    "aarch64": "aarch64",
}
