"""PyO3 Toolchains"""

load("@rules_rust//rust:defs.bzl", "rust_common")

PYO3_TOOLCHAIN = str(Label("//pyo3:toolchain_type"))

RUST_PYO3_TOOLCHAIN = str(Label("//pyo3:rust_toolchain_type"))

PY_IMPLEMENTATIONS = {
    "cpython": "CPython",
    "graalpy": "GraalVM",
    "graalvm": "GraalVM",
    "pypy": "PyPy",
}

def _pyo3_toolchain_impl(ctx):
    py_toolchain = ctx.toolchains["@rules_python//python:toolchain_type"]

    py_runtime = py_toolchain.py3_runtime
    if py_runtime.interpreter:
        interpreter = py_runtime.interpreter.path
    else:
        interpreter = py_runtime.interpreter_path

    version_info = py_runtime.interpreter_version_info
    version = "{}.{}".format(
        version_info.major,
        version_info.minor,
    )

    py_cc_toolchain = ctx.toolchains["@rules_python//python/cc:toolchain_type"].py_cc_toolchain

    libs = []
    for linker_input in py_cc_toolchain.libs.providers_map["CcInfo"].linking_context.linker_inputs.to_list():
        for library in linker_input.libraries:
            if library.dynamic_library:
                libs.append(library.dynamic_library)
            if library.static_library:
                libs.append(library.static_library)

    # Shared is determined by whether or not any shared librares were detected in the `py_cc_toolchain`.
    shared_exts = (".dll", ".so", ".dylib")

    root_lib = None
    for lib in libs:
        if not root_lib:
            root_lib = lib
            continue

        if ctx.attr.shared:
            if lib.basename.endswith(shared_exts) and not root_lib.basename.endswith(shared_exts):
                root_lib = lib
        elif not lib.basename.endswith(shared_exts) and root_lib.basename.endswith(shared_exts):
            root_lib = lib

    lib_dir = root_lib.dirname
    if root_lib.basename.endswith((".lib", ".dll")):
        lib_name, _, _ = root_lib.basename.rpartition(".")
    else:
        lib_name = "python{}".format(version)

    implementation = PY_IMPLEMENTATIONS[py_runtime.implementation_name.lower()]

    defaults = ctx.attr._defaults[platform_common.ToolchainInfo]

    pointer_width = defaults.pointer_width
    if ctx.attr.pointer_width:
        pointer_width = ctx.attr.pointer_width

    pyo3_config_file = ctx.actions.declare_file("{}/pyo3-build-config.txt".format(ctx.label.name))
    ctx.actions.expand_template(
        template = ctx.file._build_config_template,
        output = pyo3_config_file,
        substitutions = {
            "{ABI3}": str(ctx.attr.abi3).lower(),
            "{EXECUTABLE}": interpreter,
            "{IMPLEMENTATION}": implementation,
            "{LIB_DIR}": lib_dir,
            "{LIB_NAME}": lib_name,
            "{POINTER_WIDTH}": str(pointer_width),
            "{SHARED}": str(ctx.attr.shared).lower(),
            "{VERSION}": version,
        },
    )

    make_variable_info = platform_common.TemplateVariableInfo({
        "PYO3_CONFIG_FILE": pyo3_config_file.path,
        "PYO3_PYTHON": interpreter,
    })

    return [
        platform_common.ToolchainInfo(
            pyo3_config_file = pyo3_config_file,
            make_variable_info = make_variable_info,
            python_libs = depset(libs),
        ),
        make_variable_info,
        DefaultInfo(
            files = depset([pyo3_config_file]),
        ),
    ]

pyo3_toolchain = rule(
    doc = """\
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
""",
    implementation = _pyo3_toolchain_impl,
    attrs = {
        "abi3": attr.bool(
            doc = (
                "Whether linking against the stable/limited [Python 3 API](https://peps.python.org/pep-0384/). " +
                "This value should match whether or not `pyo3` was built with the " +
                "[abi3 feature](https://pyo3.rs/v0.22.2/features.html?highlight=abi3#abi3)."
            ),
            mandatory = True,
        ),
        "pointer_width": attr.int(
            doc = (
                "Width in bits of pointers on the target machine. If unset the attribute" +
                "will default to the detected value for the current configuration."
            ),
            values = [32, 64],
        ),
        "shared": attr.bool(
            doc = "Whether link library is shared.",
            mandatory = True,
        ),
        "_build_config_template": attr.label(
            allow_single_file = True,
            default = Label("//pyo3/private:pyo3_build_config.txt"),
        ),
        "_defaults": attr.label(
            default = Label("//pyo3/private:pyo3_toolchain_defaults"),
        ),
    },
    toolchains = [
        "@rules_python//python/cc:toolchain_type",
        "@rules_python//python:toolchain_type",
    ],
)

def _pyo3_toolchain_defaults_impl(ctx):
    return [platform_common.ToolchainInfo(
        pointer_width = ctx.attr.pointer_width,
    )]

pyo3_toolchain_defaults = rule(
    doc = "A rule for specifying default values for `pyo3_toolchain` based on the current configuration.",
    implementation = _pyo3_toolchain_defaults_impl,
    attrs = {
        "pointer_width": attr.int(
            doc = "See `pyo3_toolchain.pointer_width`.",
            values = [32, 64],
            mandatory = True,
        ),
    },
)

def _current_pyo3_toolchain_impl(ctx):
    toolchain = ctx.toolchains[PYO3_TOOLCHAIN]
    return [
        toolchain.make_variable_info,
        DefaultInfo(
            files = depset([toolchain.pyo3_config_file], transitive = [toolchain.python_libs]),
        ),
    ]

current_pyo3_toolchain = rule(
    doc = "A rule for accessing the `pyo3_toolchain` from the current configuration.",
    implementation = _current_pyo3_toolchain_impl,
    toolchains = [PYO3_TOOLCHAIN],
)

def _rust_pyo3_toolchain_impl(ctx):
    return [
        platform_common.ToolchainInfo(
            pyo3 = ctx.attr.pyo3,
        ),
    ]

rust_pyo3_toolchain = rule(
    doc = """\
Define a toolchain for PyO3 Rust dependencies which power internal rules.

This toolchain is how the rules know which version of `pyo3` to link against.
""",
    implementation = _rust_pyo3_toolchain_impl,
    attrs = {
        "pyo3": attr.label(
            doc = "The PyO3 library.",
            providers = [[rust_common.crate_info], [rust_common.crate_group_info]],
            mandatory = True,
        ),
    },
)

def _current_rust_pyo3_toolchain_impl(ctx):
    toolchain = ctx.toolchains[RUST_PYO3_TOOLCHAIN]
    target = toolchain.pyo3

    providers = []

    # TODO: Remove this hack when we can just pass the input target's
    # DefaultInfo provider through. Until then, we need to construct
    # a new DefaultInfo provider with the files from the input target's
    # provider.
    providers.append(
        DefaultInfo(
            files = target[DefaultInfo].files,
            runfiles = target[DefaultInfo].default_runfiles,
        ),
    )

    if rust_common.crate_info in target:
        providers.append(target[rust_common.crate_info])

    if rust_common.dep_info in target:
        providers.append(target[rust_common.dep_info])

    if rust_common.crate_group_info in target:
        providers.append(target[rust_common.crate_group_info])

    return providers

current_rust_pyo3_toolchain = rule(
    doc = "A rule for accessing the `rust_pyo3_toolchain.pyo3` library from the current configuration.",
    implementation = _current_rust_pyo3_toolchain_impl,
    toolchains = [RUST_PYO3_TOOLCHAIN],
)
