#!/usr/bin/env bash
set -euo pipefail

cd "$(dirname "$(readlink -f "$0")")"

echo "=================================================="
echo " Build baidu-free-transfer (Linux, onefile)"
echo "=================================================="
echo

PYTHON="${PYTHON:-python3}"
if ! command -v "$PYTHON" >/dev/null 2>&1; then
    echo "[ERROR] $PYTHON not found. Install Python 3.7+ first." >&2
    exit 1
fi

VENV_DIR=".venv"
VENV_PY="$VENV_DIR/bin/python"

echo "[1/3] Using $("$PYTHON" --version 2>&1)"
echo "      Removing old virtual environment $VENV_DIR ..."
rm -rf "$VENV_DIR"
echo "      Creating virtual environment $VENV_DIR ..."
if ! "$PYTHON" -m venv "$VENV_DIR"; then
    echo "[ERROR] Failed to create the virtual environment." >&2
    echo "        On Debian/Ubuntu install the python3-venv package first." >&2
    exit 1
fi

echo "[2/3] Installing dependencies ..."
"$VENV_PY" -m pip install --upgrade pip
"$VENV_PY" -m pip install -r requirements.txt pyinstaller

echo "[3/3] Building dist/baidutransfer ..."
PYINSTALLER_ARGS=(--noconfirm --clean --onefile --console --name baidutransfer --paths .)
if [ "${STRIP:-1}" = "1" ] && command -v strip >/dev/null 2>&1; then
    echo "      Stripping binaries (set STRIP=0 to disable)"
    PYINSTALLER_ARGS+=(--strip)
fi
"$VENV_PY" -m PyInstaller "${PYINSTALLER_ARGS[@]}" baidutransfer/__main__.py

if [ ! -x "dist/baidutransfer" ]; then
    echo "[ERROR] Build finished but dist/baidutransfer was not found." >&2
    exit 1
fi

echo
echo "Build succeeded:"
echo "  $(pwd)/dist/baidutransfer"
echo
echo "Note: the binary links against this machine's glibc. If it must run"
echo "on older distributions, build it inside an older container/VM."
