#!/bin/bash

# NOTE: I could do `uname` to check to see if it's MSYS but it's harmless to define MSYSTEM on Linux and/or macOS so we'll just export it...
_BUILD_TYPE=${1:-Release}
_BUILD_DIR=${2:-build}
_PYTHON3_VRESION=3.11 	# DO NOT change this, it has to match whatever CEF tool uses (and is mentioned on their markdown file)!

# NOTE: The CEF make tools relies HEAVILY on Python 3.11 libraries associted to Google SDK!
#       Another way to put it is that if you have newer version of Python (i.e. 3.13), you're screwed!
#       NOT SO OBVIOUS errors are messages such as when attempting to download from
#       Google Storage (i.e. something of "gs://...") and you get "No module named 'gsutil'"
#       or "No module named 'google'". This is because the Python 3.13 is not compatible with
#       the Google SDK libraries that CEF uses. So, you need to install Python 3.11 and make
#       sure that it's the default Python version.
# python3 --version: Python 3.11.6
_PY_VER=$(python3 --version | grep "${_PYTHON3_VRESION}")
if [ "${_PY_VER}" == "" ] ; then
    echo "Python version: $(python3 --version)"
    echo "Python ${_PYTHON3_VRESION} is not the default Python version (it is strongly depended by Google SDK libraries)... exiting..."
    exit -1
fi

#[ -e bin ] || ./get-binaries.sh ${_BUILD_TYPE}
#[ -e bin ] || ./get-binaries.sh ${_BUILD_TYPE}
./get-binaries.sh ${_BUILD_TYPE}

cat .env.local
source .env.local
uname -a
# `uname -o`: "GNU/Linux", "Msys", "Darwin"
_OS=$(uname -o)

[ -e ${CEF_BIN_PATH_MAC}/Release/libcef.dylib ] || ./get-binaries.sh ${_BUILD_TYPE}

# If CEF_ROOT is not defined after source'ing .env.local, then bail out
if [ "${CEF_ROOT}" == "" ] ; then
    echo "CEF_ROOT is not defined... exiting..."
    exit -1
fi
# verify if CEF_ROOT is valid
if [ ! -d "${CEF_ROOT}" ] ; then
    echo "CEF_ROOT='${CEF_ROOT}' is not a valid directory... exiting..."
    exit -1
fi

# Assume current directory where this 'build.sh' resides is the root of the project
CMAKE_SOURCE_DIR="$(pwd)"

# Set the current source directory to ./src
export CMAKE_CURRENT_SOURCE_DIR=${CMAKE_SOURCE_DIR}/src
if [ ! -d "${CMAKE_CURRENT_SOURCE_DIR}" ] ; then
    echo "Cannot find source directory: ${CMAKE_CURRENT_SOURCE_DIR}... exiting..."
    exit -1
fi

# Ensure the Info.plist.in file is correctly referenced
MAC_INFO_PLIST_IN="${CMAKE_SOURCE_DIR}/src/mac/Info.plist.in"
if [ ! -f "${MAC_INFO_PLIST_IN}" ] ; then
    echo "Cannot find source file: ${MAC_INFO_PLIST_IN}... exiting..."
    exit -1
fi

CMAKE_INCLUDE_PATH="${CEF_ROOT}/include"
set -o nounset                              # Treat unset variables as an error
export CEF_ROOT=${CEF_ROOT}

# NOTE: On MinGW, depending on which script used to open the PTTY, you can end up with following 2 methods:
# - $which clang -> /c/msys64/ucrt64/bin/clang
# - $which clang -> /ming64/bin/clang
export CMAKE_CXX_COMPILER="$(which clang++)"
export CXX="$(which clang++)"
export CMAKE_C_COMPILER="$(which clang)"
export CC="$(which clang)"
export VCPKG_ROOT=$(dirname $(which vcpkg))
export CMAKE_TOOLCHAIN_FILE=$VCPKG_ROOT/scripts/buildsystems/vcpkg.cmake

# See: https://cmake.org/cmake/help/latest/variable/CMAKE_MAKE_PROGRAM.html#variable:CMAKE_MAKE_PROGRAM
# See also: https://cmake.org/cmake/help/latest/guide/user-interaction/index.html
# - Ninja Multi-Config: "Ninja Multi-Config"
# - Unix Makefiles: "Unix Makefiles"
# - Ninja: "Ninja"
# - Visual Studio: "Visual Studio 16 2019"
# - Xcode: "Xcode"
# NOTE: CEF CMakeLists.txt uses "Unix Makefiles" as the ASSUMED generator!  So far, it's been very difficult
# to make it work with "Ninja Multi-Config" or "Xcode" (for macOS). So, we'll stick with "Unix Makefiles" for now.
#_GENERATOR="Ninja Multi-Config"
_GENERATOR="Unix Makefiles"
_GEN_TAG="make"
if [ "$_GENERATOR" == "Ninja Multi-Config" ] ; then
    _GEN_TAG="ninja"
    export CMAKE_MAKE_PROGRAM="$(which ninja)"
    if [ "$CMAKE_MAKE_PROGRAM" == "" ] ; then
	echo "Unable to find 'ninja' in PATH... exiting..."
	exit -1
    fi	
elif [ "$_GENERATOR" == "Unix Makefiles" ]; then
    _GEN_TAG="make"
    export CMAKE_MAKE_PROGRAM="$(which make)"
    if [ "$CMAKE_MAKE_PROGRAM" == "" ] ; then
	echo "Unable to find 'make' in PATH... exiting..."
	exit -1
    fi
elif [ "$_GENERATOR" == "Xcode" ]; then
    _GEN_TAG="xcode"
    export CMAKE_MAKE_PROGRAM="$(which xcode)"
    if [ "$CMAKE_MAKE_PROGRAM" == "" ] ; then
    echo "Unable to find 'make' in PATH... exiting..."
    exit -1
    fi
else
    echo "Unknown/unsupported generator: '${_GENERATOR}'... exiting..."
    exit -1
fi
echo "CMAKE_MAKE_PROGRAM='${CMAKE_MAKE_PROGRAM}' (for generator: '${_GENERATOR}')"

if [ "$VCPKG_ROOT" == "" ] ; then
	echo "Install vcpkg first!" 
	exit -1
fi

vcpkg install \
    vcpkg-tool-ninja \
    vcpkg-cmake vcpkg-cmake-config vcpkg-cmake-get-vars    
echo "##################################"
$CXX --version
cmake --version
vcpkg --version
vcpkg list
echo "##################################"

if [ "${_OS}" == "GNU/Linux" ]; then
    echo "Setting up for Linux..."

    _BUILD_DIR="${_BUILD_DIR}.linux.${_BUILD_TYPE}.${_GEN_TAG}"
    export VCPKG_TARGET_TRIPLET="x64-linux-static"
    export VCPKG_DEFAULT_TRIPLET="x64-linux-static"
    export VCPKG_DEFAULT_HOST_TRIPLET="x64-linux-static"
    export CMAKE_INCLUDE_PATH="${CMAKE_INCLUDE_PATH}:./src:${CEF_BIN_PATH_LIN}/include:."
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

    _BUILD_DIR="${_BUILD_DIR}.win.msys.${_BUILD_TYPE}.${_GEN_TAG}"
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
elif [ "${_OS}" == "Darwin" ]; then
    echo "Setting up for macOS..."
    _BUILD_DIR="${_BUILD_DIR}.macos.${_BUILD_TYPE}.${_GEN_TAG}"
    export VCPKG_TARGET_TRIPLET="arm64-osx-dynamic"
    export VCPKG_DEFAULT_TRIPLET="arm64-osx-dynamic"
    export VCPKG_DEFAULT_HOST_TRIPLET="arm64-osx-dynamic"
    export CMAKE_INCLUDE_PATH="${CMAKE_INCLUDE_PATH}:./src:${CEF_BIN_PATH_MAC}/include:."

    # we're using Xcode for build engine/generator
    #_GENERATOR="Xcode"
    #export CMAKE_MAKE_PROGRAM="$(which make)"
else
    echo "Unknown/unsupported OS type: ${_OS}"
    exit -666
fi
echo "# Checking if VCPKG_TARGET_TRIPLET='${VCPKG_TARGET_TRIPLET}' is valid..."
_FOUND=$( vcpkg help triplet | grep "$VCPKG_TARGET_TRIPLET" )
if [ "${_FOUND}" == "" ] ; then echo "Unable to find VCPKG_TARGET_TRIPLET='$VCPKG_TARGET_TRIPLET'" ; fi

echo "##################################"
[ -e ${_BUILD_DIR} ] || mkdir -p "${_BUILD_DIR}"
export | sort | grep --color=auto "CMAKE\|VCPKG\|CXX\|CC\|CEF"
echo "##################################"

# NOTE: In order to get cmake to work with "Visual Studio 17" generator, you need to not only install MS BuildTools and install the Windows version of CMake (NOT Cygwin or MinGW)
# Linux: cmake -G "Unix Makefiles" -DCMAKE_BUILD_TYPE=Release ..
# Windows: cmake -G "Visual Studio 17" -A x64 ..
# macOS: cmake -G "Xcode" -DPROJECT_ARCH="arm64" ..
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
    -S "${CMAKE_SOURCE_DIR}"
_RET=$?

if [ $_RET -ne 0 ]; then
    echo "CMake failed with error code: ${_RET}"
    exit ${_RET}
fi
echo "Switching to ${_BUILD_DIR} to ninja-make..."
cmake --build "${_BUILD_DIR}" --config ${_BUILD_TYPE} 
_RET=$?

exit ${_RET}

