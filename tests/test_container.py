"""Spec tests for container image."""

import pytest

TINI_VERSION = "0.19.0"
PYTHON_VERSIONS = ["3.6.15", "3.7.12", "3.8.12", "3.9.9", "3.10.0"]
SLURM_VERSION = "21.08.8"

MARIADB_PORT = 3306
SLURMCTLD_PORT = 6819
SLURMD_PORT = 6817
SLURMDBD_PORT = 6818


def test_tini_is_installed(host):
    cmd = host.run("/tini --version")
    assert TINI_VERSION in cmd.stdout
