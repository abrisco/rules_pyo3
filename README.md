<!-- Generated with Stardoc: http://skydoc.bazel.build -->

# rules_pyo3

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

<a id="pyo3_toolchain"></a>

## pyo3_toolchain

<pre>
pyo3_toolchain(<a href="#pyo3_toolchain-name">name</a>, <a href="#pyo3_toolchain-abi3">abi3</a>, <a href="#pyo3_toolchain-pointer_width">pointer_width</a>, <a href="#pyo3_toolchain-shared">shared</a>)
</pre>

Define a toolchain which generates config data for the [pyo3-build-config](https://pyo3.rs/v0.22.2/building-and-distribution/multiple-python-versions.html?highlight=pyo3-build-config#using-pyo3-build-config) crate.

When using [rules_rust's crate_universe](https://bazelbuild.github.io/rules_rust/crate_universe.html), this data can be plubmed into the target using the following snippet.
```starlark
annotations = {
    "pyo3-build-config": [
        crate.annotation(
            build_script_data = [
                "@rules_pyo3//pyo3:current_pyo3_toolchain",
            ],
            build_script_env = {
                "PYO3_CONFIG_FILE": "$${pwd}/$(PYO3_CONFIG_FILE)",
                "PYO3_PYTHON": "$${pwd}/$(PYO3_PYTHON)",
            },
            build_script_toolchains = [
                "@rules_pyo3//pyo3:current_pyo3_toolchain",
            ],
        ),
    ],
},
```

**ATTRIBUTES**


| Name  | Description | Type | Mandatory | Default |
| :------------- | :------------- | :------------- | :------------- | :------------- |
| <a id="pyo3_toolchain-name"></a>name |  A unique name for this target.   | <a href="https://bazel.build/concepts/labels#target-names">Name</a> | required |  |
| <a id="pyo3_toolchain-abi3"></a>abi3 |  Whether linking against the stable/limited [Python 3 API](https://peps.python.org/pep-0384/). This value should match whether or not `pyo3` was built with the [abi3 feature](https://pyo3.rs/v0.22.2/features.html?highlight=abi3#abi3).   | Boolean | required |  |
| <a id="pyo3_toolchain-pointer_width"></a>pointer_width |  Width in bits of pointers on the target machine. If unset the attributewill default to the detected value for the current configuration.   | Integer | optional |  `0`  |
| <a id="pyo3_toolchain-shared"></a>shared |  Whether link library is shared.   | Boolean | required |  |


<a id="rust_pyo3_toolchain"></a>

## rust_pyo3_toolchain

<pre>
rust_pyo3_toolchain(<a href="#rust_pyo3_toolchain-name">name</a>, <a href="#rust_pyo3_toolchain-pyo3">pyo3</a>, <a href="#rust_pyo3_toolchain-pyo3_stub_gen">pyo3_stub_gen</a>)
</pre>

Define a toolchain for PyO3 Rust dependencies which power internal rules.

This toolchain is how the rules know which version of `pyo3` to link against.

**ATTRIBUTES**


| Name  | Description | Type | Mandatory | Default |
| :------------- | :------------- | :------------- | :------------- | :------------- |
| <a id="rust_pyo3_toolchain-name"></a>name |  A unique name for this target.   | <a href="https://bazel.build/concepts/labels#target-names">Name</a> | required |  |
| <a id="rust_pyo3_toolchain-pyo3"></a>pyo3 |  The PyO3 library.   | <a href="https://bazel.build/concepts/labels">Label</a> | required |  |
| <a id="rust_pyo3_toolchain-pyo3_stub_gen"></a>pyo3_stub_gen |  The pyo3-stub-gen library.   | <a href="https://bazel.build/concepts/labels">Label</a> | optional |  `None`  |


<a id="pyo3_extension"></a>

## pyo3_extension

<pre>
pyo3_extension(<a href="#pyo3_extension-name">name</a>, <a href="#pyo3_extension-srcs">srcs</a>, <a href="#pyo3_extension-aliases">aliases</a>, <a href="#pyo3_extension-compile_data">compile_data</a>, <a href="#pyo3_extension-crate_features">crate_features</a>, <a href="#pyo3_extension-crate_root">crate_root</a>, <a href="#pyo3_extension-data">data</a>, <a href="#pyo3_extension-deps">deps</a>, <a href="#pyo3_extension-edition">edition</a>,
               <a href="#pyo3_extension-imports">imports</a>, <a href="#pyo3_extension-proc_macro_deps">proc_macro_deps</a>, <a href="#pyo3_extension-rustc_env">rustc_env</a>, <a href="#pyo3_extension-rustc_env_files">rustc_env_files</a>, <a href="#pyo3_extension-rustc_flags">rustc_flags</a>, <a href="#pyo3_extension-stubs">stubs</a>, <a href="#pyo3_extension-version">version</a>,
               <a href="#pyo3_extension-kwargs">kwargs</a>)
</pre>

Define a PyO3 python extension module.

This target is consumed just as a `py_library` would be.

[rsl]: https://bazelbuild.github.io/rules_rust/defs.html#rust_shared_library
[pli]: https://bazel.build/reference/be/python#py_binary.imports


**PARAMETERS**


| Name  | Description | Default Value |
| :------------- | :------------- | :------------- |
| <a id="pyo3_extension-name"></a>name |  The name of the target.   |  none |
| <a id="pyo3_extension-srcs"></a>srcs |  List of Rust `.rs` source files used to build the library. For more details see [rust_shared_library][rsl].   |  none |
| <a id="pyo3_extension-aliases"></a>aliases |  Remap crates to a new name or moniker for linkage to this target. For more details see [rust_shared_library][rsl].   |  `{}` |
| <a id="pyo3_extension-compile_data"></a>compile_data |  List of files used by this rule at compile time. For more details see [rust_shared_library][rsl].   |  `[]` |
| <a id="pyo3_extension-crate_features"></a>crate_features |  List of features to enable for this crate. For more details see [rust_shared_library][rsl].   |  `[]` |
| <a id="pyo3_extension-crate_root"></a>crate_root |  The file that will be passed to `rustc` to be used for building this crate. For more details see [rust_shared_library][rsl].   |  `None` |
| <a id="pyo3_extension-data"></a>data |  List of files used by this rule at compile time and runtime. For more details see [rust_shared_library][rsl].   |  `[]` |
| <a id="pyo3_extension-deps"></a>deps |  List of other libraries to be linked to this library target. For more details see [rust_shared_library][rsl].   |  `[]` |
| <a id="pyo3_extension-edition"></a>edition |  The rust edition to use for this crate. Defaults to the edition specified in the rust_toolchain. For more details see [rust_shared_library][rsl].   |  `None` |
| <a id="pyo3_extension-imports"></a>imports |  List of import directories to be added to the `PYTHONPATH`. For more details see [py_library.imports][pli].   |  `[]` |
| <a id="pyo3_extension-proc_macro_deps"></a>proc_macro_deps |  List of `rust_proc_macro` targets used to help build this library target. For more details see [rust_shared_library][rsl].   |  `[]` |
| <a id="pyo3_extension-rustc_env"></a>rustc_env |  Dictionary of additional `"key": "value"` environment variables to set for rustc. For more details see [rust_shared_library][rsl].   |  `{}` |
| <a id="pyo3_extension-rustc_env_files"></a>rustc_env_files |  Files containing additional environment variables to set for rustc. For more details see [rust_shared_library][rsl].   |  `[]` |
| <a id="pyo3_extension-rustc_flags"></a>rustc_flags |  List of compiler flags passed to `rustc`. For more details see [rust_shared_library][rsl].   |  `[]` |
| <a id="pyo3_extension-stubs"></a>stubs |  Whether or not to generate stubs (`.pyi` file) for the module.   |  `True` |
| <a id="pyo3_extension-version"></a>version |  A version to inject in the cargo environment variable. For more details see [rust_shared_library][rsl].   |  `None` |
| <a id="pyo3_extension-kwargs"></a>kwargs |  Additional keyword arguments.   |  none |


