#!/usr/bin/env bash
# Containerized build environment setup, shared by the smoke and release jobs.
# Run inside an ubuntu:26.04 container with the repository mounted at /src.
set -euo pipefail

# The ubuntu:26.04 image already enables universe; enable it defensively
# in case the base image changes to a narrower component set.
if grep -q '^Components:' /etc/apt/sources.list.d/ubuntu.sources; then
  sed -i 's/^\(Components:.*\)\bmain\b/\1main universe/' \
    /etc/apt/sources.list.d/ubuntu.sources
  sed -i 's/universe universe/universe/g' /etc/apt/sources.list.d/ubuntu.sources
fi
apt-get update -qq
DEBIAN_FRONTEND=noninteractive apt-get install -y -qq \
  build-essential debhelper cmake extra-cmake-modules \
  qt6-base-dev qt6-tools-dev libkf6networkmanagerqt-dev \
  libkf6config-bin kubuntu-settings-desktop \
  xvfb imagemagick file >/dev/null

echo 'Build environment ready'
