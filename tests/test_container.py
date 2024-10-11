"""Spec tests for container image."""

import pytest

TINI_VERSION = "0.19.0"
PYTHON_VERSIONS = ["3.9", "3.10", "3.11", "3.12", "3.13"]
SLURM_VERSION = "21.08.8"

MARIADB_PORT = 3306
SLURMCTLD_PORT = 6819
SLURMD_PORT = 6817
SLURMDBD_PORT = 6818


def test_tini_is_installed(host):
    cmd = host.run("/tini --version")
    assert TINI_VERSION in cmd.stdout


@pytest.mark.parametrize("version", PYTHON_VERSIONS)
def test_python_is_installed(host, version):
    cmd = host.run(f"pyenv global {version} && python --version")
    assert cmd.stdout.strip().startswith(f"Python {version}")
