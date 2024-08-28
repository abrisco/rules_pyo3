//! A module for loading runfiles data.

use pyo3::exceptions::PyFileNotFoundError;
use pyo3::prelude::*;
use runfiles::{rlocation, Runfiles};

/// Formats the sum of two numbers as string.
#[pyfunction]
fn read_data() -> PyResult<String> {
    let r = Runfiles::create().unwrap();
    let path = rlocation!(r, "rules_pyo3/pyo3/private/tests/runfiles/data.txt");

    std::fs::read_to_string(path).map_err(|e| PyFileNotFoundError::new_err(e))
}

/// A Python module implemented in Rust. The name of this function must match
/// the `lib.name` setting in the `Cargo.toml`, else Python will not be able to
/// import the module.
#[pymodule]
fn reader(m: &Bound<'_, PyModule>) -> PyResult<()> {
    m.add_function(wrap_pyfunction!(read_data, m)?)?;
    Ok(())
}
