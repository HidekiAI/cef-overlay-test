#!/bin/bash
_BUILD_TYPE=${1:-Release}
if [ -e $(which wget) ]; then
    echo "wget is installed"
else
    echo "wget is not installed"
    echo "Please install wget"
    exit 1
fi

if [ -e $(which tar) ]; then
    echo "tar is installed"
else
    echo "tar is not installed"
    echo "Please install tar"
    exit 1
fi
set -o nounset                              # Treat unset variables as an error

[ -d bin ] || mkdir -p bin
cd bin

#######################################################
_HTTP="https://cef-builds.spotifycdn.com"
_CEF_VERSION="129.0.11+g57354b8+chromium-129.0.6668.90"
#######################################################

#wget https://cef-builds.spotifycdn.com/cef_binary_129.0.11%2Bg57354b8%2Bchromium-129.0.6668.90_macosarm64.tar.bz2
[ -e "cef_binary_${_CEF_VERSION}_macosarm64.tar.bz2" ] || wget "${_HTTP}/cef_binary_${_CEF_VERSION}_macosarm64.tar.bz2"
#wget https://cef-builds.spotifycdn.com/cef_binary_129.0.11%2Bg57354b8%2Bchromium-129.0.6668.90_windows64.tar.bz2
[ -e "cef_binary_${_CEF_VERSION}_windows64.tar.bz2" ] || wget "${_HTTP}/cef_binary_${_CEF_VERSION}_windows64.tar.bz2"
#wget https://cef-builds.spotifycdn.com/cef_binary_129.0.11%2Bg57354b8%2Bchromium-129.0.6668.90_linux64.tar.bz2
[ -e "cef_binary_${_CEF_VERSION}_linux64.tar.bz2" ] || wget "${_HTTP}/cef_binary_${_CEF_VERSION}_linux64.tar.bz2"

[ -e  "cef_binary_${_CEF_VERSION}_macosarm64" ] || tar -xv --exclude="Debug" -f "cef_binary_${_CEF_VERSION}_macosarm64.tar.bz2"
[ -e  "cef_binary_${_CEF_VERSION}_windows64" ] || tar -xv --exclude="Debug" -f "cef_binary_${_CEF_VERSION}_windows64.tar.bz2"
[ -e  "cef_binary_${_CEF_VERSION}_linux64" ] || tar -xv --exclude="Debug" -f "cef_binary_${_CEF_VERSION}_linux64.tar.bz2"

# Remove all the "/Debug" folders and keep only the "/${_BUILD_TYPE}" folders - this will also reduce space
# Hopefully, this will not delete/remove LICENSE and README files
find . -type d -name "Debug" -exec rm -rf {} \;

# Rename long file-paths to shorter ones (using symbolic links) and assumes it'll work on all OS
ln -svf cef_binary_${_CEF_VERSION}_windows64 cef_windows64
ln -svf cef_binary_${_CEF_VERSION}_linux64 cef_linux64
ln -svf cef_binary_${_CEF_VERSION}_macosarm64 cef_macosarm64

# Some dirs commonly used by CMakeLists.txt, mainly when it tries to look for "${CMAKE_SOURCE_DIR}/cef_<platform_os>/cmake" file
# Note that for cef_linux64 and cef_windows64, 
[ ! -e cef_macos64 ] || ln -svf cef_macosarm64 cef_macos64

## show all the binaries we're interested in...
#find . -type f -perm -111      # NOTE: Unfortunately, on Windows, it will force ALL files to be executable (including header files due to NTFS characteristics)
cd ..
echo "macOS:" ; find ./bin/cef_macosarm64/${_BUILD_TYPE}/ | grep -v "\.pak\|.lproj"
echo "Windows:" ; find ./bin/cef_windows64/${_BUILD_TYPE}/
echo "Linux:" ; find ./bin/cef_linux64/${_BUILD_TYPE}/

# NOTE: Do NOT make PATH absolute (i.e. $(pwd)/bin/cef_windows64) because on MinGW (not on Linux)
# CMake's $ENV{CEF_BIN_PATH_WIN} will try to GUESS and wrongly replace absolute paths
# which gets confused on "-I" include paths!
# NOTE: I could do `uname` to check to see if it's MSYS but it's harmless to define MSYSTEM on Linux and/or macOS so we'll just export it...
echo "#!/bin/bash" > .env.local
echo export MSYSTEM=UCRT64 >> .env.local
echo export CEF_VERSION="${_CEF_VERSION}" >> .env.local
echo export CEF_BIN_PATH_MAC="./bin/cef_macosarm64" >> .env.local
echo export CEF_BIN_PATH_WIN="./bin/cef_windows64" >> .env.local
echo export CEF_BIN_PATH_LIN="./bin/cef_linux64" >> .env.local

cat .env.local
source .env.local

# NOTE: According to "https://github.com/chromelyapps/Chromely/blob/master/Documents/cef_binaries_download.md", I have to 
# do the following for macOS target:
# >> Rename file \${_BUILD_TYPE}\Chromium Embedded Framework.framework\Chromium Embedded Framework to libcef.dylib
[ -e ${CEF_BIN_PATH_MAC}/${_BUILD_TYPE}/libcef.dylib ] || cp "${CEF_BIN_PATH_MAC}/${_BUILD_TYPE}/Chromium Embedded Framework.framework/Chromium Embedded Framework" ${CEF_BIN_PATH_MAC}/${_BUILD_TYPE}/libcef.dylib

uname -a
# `uname -o`: "GNU/Linux", "Msys", "Darwin"
_OS=$(uname -o)

# Finally, we NEED "cef_wrapper_dll" for the "cefclient" to work
pushd .
if [ "${_OS}" == "GNU/Linux" ]; then
    CEF_ROOT=$(pwd)/${CEF_BIN_PATH_LIN}	
    cd ${CEF_ROOT}
    echo "Setting up for Linux..."
    _TARGET="libcef_dll_wrapper.a"
    # Look for "${CEF_BIN_PATH_LIN}/build/libcef_dll_wrapper/libcef_dll_wrapper.a"
    if ! [ -e "build/libcef_dll_wrapper/${_TARGET}" ]; then
        [ -e build ] || mkdir build
        cmake -G "Unix Makefiles" -B build -S .
	_RET=$?

	cmake --build build --config ${_BUILD_TYPE}
	_RET=$?

        find . -name "${_TARGET}" -exec cp {} ${_BUILD_TYPE}/ \;
    else
	echo "Already built: ${_TARGET}"
	ls -lAh "build/libcef_dll_wrapper/${_TARGET}"
    fi
elif [ "${_OS}" == "Msys" ]; then
    CEF_ROOT=$(pwd)/${CEF_BIN_PATH_WIN}	
    cd ${CEF_ROOT}
    export MSYSTEM=CLANG64
    echo "Setting up for MSYS64/MinGW Windows (via ${MSYSTEM})..."
    # NOTE: CEF is Visual Studios/MSBuild based so maybe it's ".lib" instead?
    _TARGET="libcef_dll_wrapper.a"
    # Look for "${CEF_BIN_PATH_WIN}/build/libcef_dll_wrapper/libcef_dll_wrapper.lib"
    if ! [ -e "build/libcef_dll_wrapper/${_TARGET}" ]; then
        [ -e build ] || mkdir build
        cmake -G "Unix Makefiles" -B build -S .
	_RET=$?

	cmake --build build --config ${_BUILD_TYPE}
	_RET=$?

        find . -name "${_TARGET}" -exec cp {} ${_BUILD_TYPE}/ \;
    else
	echo "Already built: ${_TARGET}"
	ls -lAh "build/libcef_dll_wrapper/${_TARGET}"
    fi
elif [ "${_OS}" == "Darwin" ]; then
    CEF_ROOT=$(pwd)/${CEF_BIN_PATH_MAC}	
    cd ${CEF_ROOT}
    echo "Setting up for macOS..."
    _TARGET="libcef_dll_wrapper.a"
    # Look for "${CEF_BIN_PATH_MAC}/build/libcef_dll_wrapper/libcef_dll_wrapper.a"
    if ! [ -e "build/libcef_dll_wrapper/${_TARGET}" ]; then
        cmake -G "Unix Makefiles" -B build -S .
	_RET=$?

	cmake --build build --config ${_BUILD_TYPE}
	_RET=$?

        find . -name "${_TARGET}" -exec cp {} ${_BUILD_TYPE}/ \;
    else
	echo "Already built: ${_TARGET}"
	ls -lAh "build/libcef_dll_wrapper/${_TARGET}"
    fi
else
    echo "Unknown/unsupported OS type: ${_OS}"
    exit -666
fi
popd

echo export CEF_ROOT="${CEF_ROOT}" >> .env.local
