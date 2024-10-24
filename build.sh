#!/bin/bash

# NOTE: I could do `uname` to check to see if it's MSYS but it's harmless to define MSYSTEM on Linux and/or macOS so we'll just export it...
_BUILD_TYPE=Release
_BUILD_DIR="build"

[ -e bin ] || ./get-binaries.sh ${_BUILD_TYPE}

cat .env.local
source .env.local
uname -a
# `uname -o`: "GNU/Linux", "Msys", "Darwin"
_OS=$(uname -o)

# NOTE: On MinGW, depending on which script used to open the PTTY, you can end up with following 2 methods:
# - $which clang -> /c/msys64/ucrt64/bin/clang
# - $which clang -> /ming64/bin/clang
export CMAKE_CXX_COMPILER="$(which clang++)"
export CXX="$(which clang++)"
export CMAKE_C_COMPILER="$(which clang)"
export CC="$(which clang)"
export VCPKG_ROOT=$(dirname $(which vcpkg))
export CMAKE_TOOLCHAIN_FILE=$VCPKG_ROOT/scripts/buildsystems/vcpkg.cmake
export CMAKE_MAKE_PROGRAM="$(which ninja)"
_GENERATOR="Ninja Multi-Config"
_GENERATOR="Unix Makefiles"

if [ "$VCPKG_ROOT" == "" ] ; then
	echo "Install vcpkg first!" 
	exit -1
fi

echo "##################################"
$CXX --version
cmake --version
vcpkg --version
vcpkg list
echo "##################################"

if [ "${_OS}" == "GNU/Linux" ]; then
    echo "Setting up for Linux..."

    _BUILD_DIR="${_BUILD_DIR}.linux"
    export VCPKG_TARGET_TRIPLET="x64-linux-static"
    export VCPKG_DEFAULT_TRIPLET="x64-linux-static"
    export VCPKG_DEFAULT_HOST_TRIPLET="x64-linux-static"
    export CMAKE_INCLUDE_PATH="${CMAKE_INCLUDE_PATH}:./src:${CEF_BIN_PATH_LIN}/include:."
    export CEF_ROOT=$(pwd)/${CEF_BIN_PATH_LIN}
    export CEF_ROOT=${CEF_BIN_PATH_LIN}
elif [ "${_OS}" == "Msys" ]; then
    export MSYSTEM=CLANG64
    # MSYSTEM: https://www.msys2.org/docs/environments/:
    # - MSYS - gcc (clib: cygwin, libstdc++)
    # - UCRT64 - gcc (clib: ucrt, libstdc++)
    # - CLANG64 - llvm (clib: ucrt, libc++)
    # - MINGW64 - gcc (clib: msvcrt, libstdc++)
    # WARNING: Binaries linked with MSVCRT should not be mixed with UCRT ones because the 
    #          internal structures and data types are different. (More strictly, object 
    #          files or static libraries built for different targets shouldn't be mixed. 
    #          DLLs built for different CRTs can be mixed as long as they don't share CRT 
    #          objects, e.g. FILE*, across DLL boundaries.) Same rule is applied for MSVC 
    #          compiled binaries because MSVC uses UCRT by default (if not changed).
    echo "Setting up for MSYS64/MinGW Windows (via ${MSYSTEM})..."
    if [ ${MSYSTEM} == "UCRT64" ]; then
        export PATH=/c/msys64/ucrt64/bin:$PATH  # prepend ucrt64 search paths first, so $(which) will choose Universal CRT for Windows target
    elif [ ${MSYSTEM} == "MINGW64" ]; then
        export PATH=/c/msys64/ming64/bin:$PATH  # prepend ucrt64 search paths first, so $(which) will choose Universal CRT for Windows target
    elif [ ${MSYSTEM} == "CLANG64" ]; then
        export PATH=/c/msys64/clang64/bin:$PATH  # prepend ucrt64 search paths first, so $(which) will choose Universal CRT for Windows target
    else 
        export PATH=$PATH:/c/msys64:/c/msys64/ucrt64/bin:/ucrt64/bin:/c/msys64/clang64/bin:/clang64/bin
        echo "MSYSTEM is not set... not forcing search paths..."
    fi

    _BUILD_DIR="${_BUILD_DIR}.win.msys"
    #NOTE: for UCRT64, you use "Windows" instead of "MinGW"
    #export VCPKG_TARGET_TRIPLET="x64-mingw-static"
    export VCPKG_TARGET_TRIPLET="x64-windows-static"
    export VCPKG_DEFAULT_TRIPLET="x64-windows-static"
    export VCPKG_DEFAULT_HOST_TRIPLET="x64-windows-static"
    export CMAKE_INCLUDE_PATH="${CMAKE_INCLUDE_PATH}:./src:${CEF_BIN_PATH_WIN}/include:."

    # Without explicit setting of `CC` and `CXX` with FULL PATH INCLUDING ".exe", CMAKE will fail! (serious waste of time!)
    # note that when it means "full paths", it still will take either '/c/msys64/ucrt64/bin/clang++.exe' or '/bin/clang++.exe', all it cares is the ".exe"
    export CXX=$(which clang++.exe)
    export CMAKE_CXX_COMPILER="${CXX}"
    export CC=$(which clang.exe)
    export CMAKE_C_COMPILER="${CC}"

    if [ "$_GENERATOR" == "Ninja Multi-Config" ] ; then
        export CMAKE_MAKE_PROGRAM="$(which ninja.exe)"
    elif [ "$_GENERATOR" == "Unix Makefiles" ]; then
        export CMAKE_MAKE_PROGRAM="$(which make.exe)"
    fi

    export CEF_ROOT=$(pwd)/${CEF_BIN_PATH_WIN}
    export CEF_ROOT=${CEF_BIN_PATH_WIN}
elif [ "${_OS}" == "Darwin" ]; then
    echo "Setting up for macOS..."
    _BUILD_DIR="${_BUILD_DIR}.macos"
    export VCPKG_TARGET_TRIPLET="x64-mac-static"
    export VCPKG_DEFAULT_TRIPLET="x64-mac-static"
    export VCPKG_DEFAULT_HOST_TRIPLET="x64-mac-static"
    export CMAKE_INCLUDE_PATH="${CMAKE_INCLUDE_PATH}:./src:${CEF_BIN_PATH_MAC}/include:."
    export CEF_ROOT=$(pwd)/${CEF_BIN_PATH_MAC}
    export CEF_ROOT=${CEF_BIN_PATH_MAC}
else
    echo "Unknown/unsupported OS type: ${_OS}"
    exit -666
fi
_FOUND=$( vcpkg help triplet | grep "$VCPKG_TARGET_TRIPLET" )
if [ "${_FOUND}" == "" ] ; then echo "Unable to find VCPKG_TARGET_TRIPLET='$VCPKG_TARGET_TRIPLET'" ; fi
[ -e ${_BUILD_DIR} ] || mkdir -p "${_BUILD_DIR}"
export | sort | grep --color=auto "CMAKE\|VCPKG\|CXX\|CC\|CEF"

cmake --log-level DEBUG \
    -DCMAKE_BUILD_TYPE:STRING=${_BUILD_TYPE}     \
    -DCXX:STRING=${CXX}     \
    -DCMAKE_CXX_COMPILER:STRING=${CMAKE_CXX_COMPILER} 	\
    -DCC:STRING=${CC}   \
    -DCMAKE_C_COMPILER:STRING=${CMAKE_C_COMPILER} 	\
    -DCMAKE_EXPORT_COMPILE_COMMANDS:BOOL=TRUE \
    -DCMAKE_TOOLCHAIN_FILE:STRING=${CMAKE_TOOLCHAIN_FILE} \
    -DVCPKG_TARGET_TRIPLET:STRING=${VCPKG_TARGET_TRIPLET} 	\
    -DVCPKG_ROOT:STRING=${VCPKG_ROOT} 	\
    -DCMAKE_INCLUDE_PATH:STRING=${CMAKE_INCLUDE_PATH}   \
    -DCEF_ROOT:STRING=${CEF_ROOT}   \
    --no-warn-unused-cli \
    -DCMAKE_MAKE_PROGRAM:STRING=${CMAKE_MAKE_PROGRAM}   \
    -G "${_GENERATOR}"  \
    -B "${_BUILD_DIR}" \
    -S .
_RET=$?

if [ $_RET -ne 0 ]; then
    echo "CMake failed with error code: ${_RET}"
    exit ${_RET}
fi
echo "Switching to ${_BUILD_DIR} to ninja-make..."
# cd ${_BUILD_DIR}
# ninja
cmake --build "${_BUILD_DIR}" --config ${_BUILD_TYPE} 
_RET=$?

exit ${_RET}
