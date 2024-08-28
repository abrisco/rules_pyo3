"""Bazel pyo3 rules"""

load("@bazel_skylib//lib:paths.bzl", "paths")
load("@rules_python//python:defs.bzl", "PyInfo")
load("@rules_rust//rust:defs.bzl", "rust_common", "rust_shared_library")
load(":pyo3_toolchain.bzl", "PYO3_TOOLCHAIN")

def _get_imports(ctx, imports):
    """Determine the import paths from a target's `imports` attribute.

    Args:
        ctx (ctx): The rule's context object.
        imports (list): A list of import paths.

    Returns:
        depset: A set of the resolved import paths.
    """
    workspace_name = ctx.label.workspace_name
    if not workspace_name:
        workspace_name = ctx.workspace_name

    import_root = "{}/{}".format(workspace_name, ctx.label.package).rstrip("/")

    result = [workspace_name]
    for import_str in imports:
        import_str = ctx.expand_make_variables("imports", import_str, {})
        if import_str.startswith("/"):
            continue

        # To prevent "escaping" out of the runfiles tree, we normalize
        # the path and ensure it doesn't have up-level references.
        import_path = paths.normalize("{}/{}".format(import_root, import_str))
        if import_path.startswith("../") or import_path == "..":
            fail("Path '{}' references a path above the execution root".format(
                import_str,
            ))
        result.append(import_path)

    return depset(result)

def _py_pyo3_library_impl(ctx):
    files = []

    extension = ctx.attr.extension[rust_common.test_crate_info].crate.output
    is_windows = extension.basename.endswith(".dll")

    # https://pyo3.rs/v0.22.2/building-and-distribution#manual-builds
    ext = ctx.actions.declare_file("{}{}".format(
        ctx.label.name,
        ".pyd" if is_windows else ".so",
    ))
    ctx.actions.symlink(
        output = ext,
        target_file = extension,
    )
    files.append(ext)

    return [
        DefaultInfo(
            files = depset([ext]),
            runfiles = ctx.runfiles(files = files),
        ),
        PyInfo(
            imports = _get_imports(ctx, ctx.attr.imports),
            transitive_sources = depset(),
        ),
        coverage_common.instrumented_files_info(
            ctx,
            dependency_attributes = ["extension"],
        ),
    ]

py_pyo3_library = rule(
    doc = "Define a Python library for a PyO3 extension.",
    implementation = _py_pyo3_library_impl,
    attrs = {
        "extension": attr.label(
            doc = "The PyO3 library.",
            cfg = "target",
            # `rust_shared_library` does not provide `CrateInfo` but
            # does contain `TestCrateInfo` which wraps the data we need.
            providers = [rust_common.test_crate_info],
            mandatory = True,
        ),
        "imports": attr.string_list(
            doc = "List of import directories to be added to the `PYTHONPATH`.",
        ),
    },
    toolchains = [PYO3_TOOLCHAIN],
)

def pyo3_extension(
        name,
        srcs,
        aliases = {},
        compile_data = [],
        crate_features = [],
        crate_root = None,
        data = [],
        deps = [],
        edition = None,
        imports = [],
        proc_macro_deps = [],
        rustc_env = {},
        rustc_env_files = [],
        rustc_flags = [],
        version = None,
        **kwargs):
    """Define a PyO3 python extension module.

    This target is consumed just as a `py_library` would be.

    [rsl]: https://bazelbuild.github.io/rules_rust/defs.html#rust_shared_library
    [pli]: https://bazel.build/reference/be/python#py_binary.imports

    Args:
        name (str): The name of the target.
        srcs (list): List of Rust `.rs` source files used to build the library.
            For more details see [rust_shared_library][rsl].
        aliases (dict, optional): Remap crates to a new name or moniker for linkage to this target.
            For more details see [rust_shared_library][rsl].
        compile_data (list, optional): List of files used by this rule at compile time.
            For more details see [rust_shared_library][rsl].
        crate_features (list, optional): List of features to enable for this crate.
            For more details see [rust_shared_library][rsl].
        crate_root (Label, optional): The file that will be passed to `rustc` to be used for building this crate.
            For more details see [rust_shared_library][rsl].
        data (list, optional): List of files used by this rule at compile time and runtime.
            For more details see [rust_shared_library][rsl].
        deps (list, optional): List of other libraries to be linked to this library target.
            For more details see [rust_shared_library][rsl].
        edition (str, optional): The rust edition to use for this crate. Defaults to the edition specified in the rust_toolchain.
            For more details see [rust_shared_library][rsl].
        imports (list, optional): List of import directories to be added to the `PYTHONPATH`.
            For more details see [py_library.imports][pli].
        proc_macro_deps (list, optional): List of `rust_proc_macro` targets used to help build this library target.
            For more details see [rust_shared_library][rsl].
        rustc_env (dict, optional): Dictionary of additional `"key": "value"` environment variables to set for rustc.
            For more details see [rust_shared_library][rsl].
        rustc_env_files (list, optional): Files containing additional environment variables to set for rustc.
            For more details see [rust_shared_library][rsl].
        rustc_flags (list, optional): List of compiler flags passed to `rustc`.
            For more details see [rust_shared_library][rsl].
        version (str, optional): A version to inject in the cargo environment variable.
            For more details see [rust_shared_library][rsl].
        **kwargs (dict): Additional keyword arguments.
    """
    tags = kwargs.pop("tags", [])
    visibility = kwargs.pop("visibility", [])

    lib_kwargs = dict(
        aliases = aliases,
        compile_data = compile_data,
        crate_features = crate_features,
        crate_name = name,
        data = data,
        edition = edition,
        proc_macro_deps = proc_macro_deps,
        rustc_env = rustc_env,
        rustc_env_files = rustc_env_files,
        rustc_flags = rustc_flags,
        tags = depset(tags + ["manual"]).to_list(),
        version = version,
        **kwargs
    )

    rust_shared_library(
        name = name + "_shared",
        crate_root = crate_root,
        srcs = srcs,
        deps = [
            "//pyo3/private:current_rust_pyo3_toolchain",
            "@rules_python//python/cc:current_py_cc_libs",
        ] + deps,
        **lib_kwargs
    )

    py_pyo3_library(
        name = name,
        extension = name + "_shared",
        imports = imports,
        tags = tags,
        visibility = visibility,
        **kwargs
    )
