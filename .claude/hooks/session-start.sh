#!/bin/bash
# Prepara REA (Reverse Engineer Anything) con Ghidra en sesiones cloud de Claude Code.
set -euo pipefail

if [ "${CLAUDE_CODE_REMOTE:-}" != "true" ]; then
  exit 0
fi

REA_VERSION="6.5.0"
GHIDRA_VERSION="12.1.4"
GHIDRA_BUILD_DATE="20260921"
GHIDRA_SHA256="ddac49f903da9d5bac833e5cc79395098b9c33cfd3279be5f31bd00387d2d4db"
GHIDRA_DIR="/opt/ghidra_${GHIDRA_VERSION}_PUBLIC"
GHIDRA_URL="https://github.com/NationalSecurityAgency/ghidra/releases/download/Ghidra_${GHIDRA_VERSION}_build/ghidra_${GHIDRA_VERSION}_PUBLIC_${GHIDRA_BUILD_DATE}.zip"

# CLI de REA (también lo usa .mcp.json vía npx).
if [ "$(rea --version 2>/dev/null || true)" != "$REA_VERSION" ]; then
  npm install --global "rea-agents@${REA_VERSION}"
fi

# JDK 21 completo (Ghidra 12.1 lo exige) y ps de procps (supervisor de procesos de REA).
if ! command -v javac >/dev/null 2>&1 || ! command -v ps >/dev/null 2>&1; then
  apt-get update -qq
  DEBIAN_FRONTEND=noninteractive apt-get install -y -qq openjdk-21-jdk-headless procps
fi
JAVA_HOME="$(dirname "$(dirname "$(readlink -f "$(command -v javac)")")")"

# Ghidra.
if [ ! -x "$GHIDRA_DIR/support/analyzeHeadless" ]; then
  tmp="$(mktemp -d)"
  trap 'rm -rf "$tmp"' EXIT
  curl -sSL --fail -o "$tmp/ghidra.zip" "$GHIDRA_URL"
  echo "$GHIDRA_SHA256  $tmp/ghidra.zip" | sha256sum -c --quiet -
  unzip -q "$tmp/ghidra.zip" -d /opt
fi

if [ -n "${CLAUDE_ENV_FILE:-}" ]; then
  {
    echo "export GHIDRA_INSTALL_DIR=\"$GHIDRA_DIR\""
    echo "export JAVA_HOME=\"$JAVA_HOME\""
  } >> "$CLAUDE_ENV_FILE"
fi
