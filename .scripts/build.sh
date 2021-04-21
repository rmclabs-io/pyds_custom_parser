#!/usr/bin/env bash
apt-get update \
  && apt-get install -y --no-install-recommends \
      build-essential \
      python3-venv \
      libgstreamer-plugins-base1.0-dev \
      python3-dev \
      python3-pip

python3 -m pip install --upgrade pip wheel setuptools

python3 -m pip wheel \
  --no-deps \
  --no-input \
  .
