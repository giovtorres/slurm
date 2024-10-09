"""Pytest fixtures."""

import subprocess
import time

import pytest
import testinfra


@pytest.fixture(scope="session")
def host(request):
    subprocess.run(["docker", "build", "--platform=linux/amd64", "-t", "slurm-docker:test", "."])

    docker_id = (
        subprocess.check_output(
            [
                "docker",
                "run",
                "--platform=linux/amd64",
                "-d",
                "-it",
                "-h",
                "slurmctl",
                "--cap-add",
                "sys_admin",
                "slurm-docker:test",
            ]
        )
        .decode()
        .strip()
    )

    # time.sleep(15)  # FIXME: add wait_for_logs()

    yield testinfra.get_host(f"docker://{docker_id}")

    subprocess.run(["docker", "rm", "-f", docker_id])

