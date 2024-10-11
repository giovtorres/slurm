#!/bin/bash
set -ex -o pipefail

source "${HOME}/.bashrc"
PYTHON_VERSION=$1

pyenv install -v $PYTHON_VERSION
pyenv global $PYTHON_VERSION
pip install Cython pytest
