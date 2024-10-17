#!/bin/bash

_BUILD_TYPE=Release
_BUILD_DIR="build"

[ -e bin ] || ./get-binaries.sh ${_BUILD_TYPE}

cat .env.local
source .env.local
uname -a
# `uname -o`: "GNU/Linux", "Msys", "Darwin"
_OS=$(uname -o)

# NOTE: On MinGW, depending on which script used to open the PTTY, you can end up with following 2 methods:
# - $which clang -> /c/msys64/mingw64/bin/clang
# - $which clang -> /ming264/bin/clang
export CMAKE_CXX_COMPILER="$(which clang++)"
export CXX="$(which clang++)"
export CMAKE_C_COMPILER="$(which clang)"
export CC="$(which clang)"
export VCPKG_ROOT=$(dirname $(which vcpkg))
export CMAKE_TOOLCHAIN_FILE=$VCPKG_ROOT/scripts/buildsystems/vcpkg.cmake

if [ "$VCPKG_ROOT" == "" ] ; then
	echo "Install vcpkg first!" 
	exit -1
fi

echo "##################################"
$CXX --version
cmake --version
vcpkg --version
echo "##################################"

_GENERATOR="Ninja Multi-Config"
if [ "${_OS}" == "GNU/Linux" ]; then
    echo "Setting up for Linux..."
    _GENERATOR="Ninja Multi-Config"
    _BUILD_DIR="${_BUILD_DIR}.linux"
    export VCPKG_TARGET_TRIPLET="x64-linux-static"
    export VCPKG_DEFAULT_TRIPLET="x64-linux-static"
    export VCPKG_DEFAULT_HOST_TRIPLET="x64-linux-static"
elif [ "${_OS}" == "Msys" ]; then
    echo "Setting up for MSYS64/MinGW Windows..."
    _GENERATOR="Ninja Multi-Config"
    _BUILD_DIR="${_BUILD_DIR}.win.msys"
    export VCPKG_TARGET_TRIPLET="x64-mingw-static"
    export VCPKG_DEFAULT_TRIPLET="x64-mingw-static"
    export VCPKG_DEFAULT_HOST_TRIPLET="x64-mingw-static"
    export PATH=$PATH:/c/msys64:/c/msys64/mingw64/bin:/mingw64/bin

    # Without explicit setting of `CC` and `CXX` with FULL PATH INCLUDING ".exe", you will fail!
    export CC=/c/msys64/mingw64/bin/clang.exe
    export CXX=/c/msys64/mingw64/bin/clang++.exe

elif [ "${_OS}" == "Darwin" ]; then
    echo "Setting up for macOS..."
    _GENERATOR="Ninja Multi-Config"
    _BUILD_DIR="${_BUILD_DIR}.macos"
    export VCPKG_TARGET_TRIPLET="x64-mac-static"
    export VCPKG_DEFAULT_TRIPLET="x64-mac-static"
    export VCPKG_DEFAULT_HOST_TRIPLET="x64-mac-static"
else
    echo "Unknown/unsupported OS type: ${_OS}"
    exit -666
fi
[ -e ${_BUILD_DIR} ] || mkdir -p "${_BUILD_DIR}"

cmake \
-DCMAKE_BUILD_TYPE:STRING=${_BUILD_TYPE}     \
    -DCMAKE_EXPORT_COMPILE_COMMANDS:BOOL=TRUE \
    -DCMAKE_TOOLCHAIN_FILE:STRING=${CMAKE_TOOLCHAIN_FILE} \
    -DVCPKG_TARGET_TRIPLET:STRING=${VCPKG_TARGET_TRIPLET} 	\
    -DCMAKE_CXX_COMPILER:STRING=${CMAKE_CXX_COMPILER} 	\
    -DCMAKE_C_COMPILER:STRING=${CMAKE_C_COMPILER} 	\
    -DVCPKG_ROOT:STRING=${VCPKG_ROOT} 	\
    --no-warn-unused-cli \
    -S "./src" \
    -B "${_BUILD_DIR}" \
    -G "${_GENERATOR}"
echo

echo "Switching to ${_BUILD_DIR} to ninja..."
cd "${_BUILD_DIR}"
ninja
