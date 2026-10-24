#!/usr/bin/env bash
# Setup script for the agent-platform-eval cloud environment on the repo
# sbiondolillo/platform-eval-sample. Runs as root before Claude Code starts,
# and the result is cached as a filesystem snapshot when it finishes in under
# about five minutes. The default image has no .NET SDK, so this installs the
# one the factory's global.json pins, rolled forward to the newest 10.0 patch,
# to the same path the factory's sandbox image and the lab's runner VM use.
set -euo pipefail
SDK_VERSION="10.0.402"
INSTALL_DIR="/usr/share/dotnet"
if [ ! -d "$INSTALL_DIR/sdk/$SDK_VERSION" ]; then
  curl -fsSL https://dot.net/v1/dotnet-install.sh -o /tmp/dotnet-install.sh
  bash /tmp/dotnet-install.sh --version "$SDK_VERSION" --install-dir "$INSTALL_DIR"
  rm -f /tmp/dotnet-install.sh
fi
ln -sf "$INSTALL_DIR/dotnet" /usr/bin/dotnet
export DOTNET_CLI_TELEMETRY_OPTOUT=1 DOTNET_NOLOGO=1
dotnet --version
