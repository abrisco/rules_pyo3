"""A test that demonstrates rust code being able to interface with runfiles."""

import unittest
from pathlib import Path

from python.runfiles import Runfiles

from pyo3.private.tests.runfiles import reader


def _rlocation(runfiles: Runfiles, rlocationpath: str) -> Path:
    """Look up a runfile and ensure the file exists

    Args:
        runfiles: The runfiles object
        rlocationpath: The runfile key

    Returns:
        The requested runifle.
    """
    runfile = runfiles.Rlocation(rlocationpath)
    if not runfile:
        raise FileNotFoundError(f"Failed to find runfile: {rlocationpath}")
    path = Path(runfile)
    if not path.exists():
        raise FileNotFoundError(f"Runfile does not exist: ({rlocationpath}) {path}")
    return path


class RunfilesTest(unittest.TestCase):
    """Test Class."""

    def test_reader(self) -> None:
        """A test which uses runfile data from rust code."""

        result = reader.read_data()
        self.assertIsInstance(result, str)
        self.assertEqual("La-Li-Lu-Le-Lo", result)

    def test_transitive_runfiles_access(self) -> None:
        """A test which interacts with transitive rust runfiles."""

        runfiles = Runfiles.Create()
        if not runfiles:
            raise EnvironmentError("Failed to locate runfiles.")

        rlocationpath = "rules_pyo3/pyo3/private/tests/runfiles/data.txt"
        data_file = _rlocation(runfiles, rlocationpath)

        self.assertEqual("La-Li-Lu-Le-Lo", data_file.read_text(encoding="utf-8"))
