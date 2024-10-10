#!/bin/bash

_BUILD_TYPE=Release
_BUILD_DIR="build"

[ -e bin ] || ./get-binaries.sh ${_BUILD_TYPE}

cat .env.local
source .env.local
uname -a
# `uname -o`: "GNU/Linux", "Msys", "Darwin"
_OS=$(uname -o)
$(which clang++) --version
export CMAKE_CXX_COMPILER="$(which clang++)"
export CXX="$(which clang++)"
export CMAKE_C_COMPILER="$(which clang)"
export CC="$(which clang)"

_GENERATOR="Ninja Multi-Config"
if [ "${_OS}" == "GNU/Linux" ]; then
    echo "Setting up for Linux..."
    _GENERATOR="Ninja Multi-Config"
    _BUILD_DIR="${_BUILD_DIR}.linux"

elif [ "${_OS}" == "Msys" ]; then
    echo "Setting up for MSYS64/MinGW Windows..."
    _GENERATOR="Ninja Multi-Config"
    _BUILD_DIR="${_BUILD_DIR}.win.msys"

elif [ "${_OS}" == "Darwin" ]; then
    echo "Setting up for macOS..."
    _GENERATOR="Ninja Multi-Config"
    _BUILD_DIR="${_BUILD_DIR}.macos"

else
    echo "Unknown/unsupported OS type: ${_OS}"
    exit -666
fi
[ -e ${_BUILD_DIR} ] || mkdir -p "${_BUILD_DIR}"

#-DCMAKE_CXX_COMPILER:FILEPATH=$(which clang++) \
#-DCMAKE_C_COMPILER:FILEPATH=$(which clang) \
cmake -DCMAKE_BUILD_TYPE_TYPE:STRING=${_BUILD_TYPE}     \
    -DCMAKE_EXPORT_COMPILE_COMMANDS:BOOL=TRUE \
    --no-warn-unused-cli \
    -S ./src \
    -B "${_BUILD_DIR}" \
    -G "${_GENERATOR}"
cd "${_BUILD_DIR}"
ninja
