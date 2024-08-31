"""# rules_pyo3

Bazel rules for [PyO3](https://pyo3.rs/v0.22.2/).

These rules use the hermetic toolchain infrastructure from [rules_python](https://github.com/bazelbuild/rules_python) to
build PyO3 extension modules to be as reproducible as possible.

## Setup

In order to use `rules_pyo3` it's recommended to first setup your `rules_rust`
and `rules_python`.

Refer to their setup documentation for guidance:
- [rules_rust setup](https://bazelbuild.github.io/rules_rust/#setup)
- [rules_python setup](https://rules-python.readthedocs.io/en/latest/getting-started.html)

### WORKSPACE

Once `rules_rust` and `rules_python` toolchains are all configured, the following
snippet can be used to configure the necessary toolchains for PyO3:

```starlark
load("@bazel_tools//tools/build_defs/repo:http.bzl", "http_archive")

http_archive(
    name = "rules_pyo3",
    #
    # TODO: See release page for integrity and url info:
    #
    # https://github.com/abrisco/rules_pyo3/releases
)

load("@rules_pyo3//pyo3:repositories.bzl", "register_pyo3_toolchains", "rules_pyo3_dependencies")

rules_pyo3_dependencies()

register_pyo3_toolchains()

load("@rules_pyo3//pyo3:repositories_transitive.bzl", "rules_pyo3_transitive_deps")

rules_pyo3_transitive_deps()
```

### Toolchains

Information about each toolchan can be seen below and in the rule's documentation.

| rule | type | mandatory | details |
| --- | --- | --- | --- | 
| [rust_pyo3_toolchain](#rust_pyo3_toolchain) | `@rules_pyo3//pyo3:rust_toolchain_type` | true | Required by the rules to determine what `pyo3` library to link. |
| [pyo3_toolchain](#pyo3_toolchain) | `@rules_pyo3//pyo3:toolchain_type` | false | Used to help build `pyo3`. Users who are building `pyo3` in other ways do not need to set this. | 

## Rules

- [pyo3_extension](#pyo3_extension)
- [pyo3_toolchain](#pyo3_toolchain)
- [rust_pyo3_toolchain](#rust_pyo3_toolchain)

---
---
"""

load(
    "//pyo3/private:pyo3.bzl",
    _pyo3_extension = "pyo3_extension",
)
load(
    "//pyo3/private:pyo3_toolchain.bzl",
    _pyo3_toolchain = "pyo3_toolchain",
    _rust_pyo3_toolchain = "rust_pyo3_toolchain",
)

pyo3_extension = _pyo3_extension
pyo3_toolchain = _pyo3_toolchain
rust_pyo3_toolchain = _rust_pyo3_toolchain
