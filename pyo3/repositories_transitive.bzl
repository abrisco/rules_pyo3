"""pyo3 transitive dependencies"""

load("//pyo3/3rdparty/crates:crates.bzl", "crate_repositories")

# buildifier: disable=unnamed-macro
def rules_pyo3_transitive_deps():
    """Defines pyo3 transitive dependencies"""
    crate_repositories()
