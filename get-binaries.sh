#!/bin/bash
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

[ -d bin ] || mkdir bin
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

tar -xv --exclude="Debug" -f "cef_binary_${_CEF_VERSION}_macosarm64.tar.bz2"
tar -xv --exclude="Debug" -f "cef_binary_${_CEF_VERSION}_windows64.tar.bz2"
tar -xv --exclude="Debug" -f "cef_binary_${_CEF_VERSION}_linux64.tar.bz2"

# Remove all the "/Debug" folders and keep only the "/Release" folders - this will also reduce space
# Hopefully, this will not delete/remove LICENSE and README files
find . -type d -name "Debug" -exec rm -rf {} \;

# Rename long file-paths to shorter ones (using symbolic links) and assumes it'll work on all OS
ln -svf cef_binary_${_CEF_VERSION}_macosarm64 cef_macosarm64
ln -svf cef_binary_${_CEF_VERSION}_windows64 cef_windows64
ln -svf cef_binary_${_CEF_VERSION}_linux64 cef_linux64

## show all the binaries we're interested in...
#find . -type f -perm -111      # NOTE: Unfortunately, on Windows, it will force ALL files to be executable (including header files due to NTFS characteristics)
cd ..
echo "macOS:" ; find ./bin/cef_macosarm64/Release/ | grep -v "\.pak\|.lproj"
echo "Windows:" ; find ./bin/cef_windows64/Release/
echo "Linux:" ; find ./bin/cef_linux64/Release/

echo "#!/bin/bash" > .env.local
echo export CEF_VERSION="${_CEF_VERSION}" >> .env.local
echo export CEF_BIN_PATH_MAC="$(pwd)/bin/cef_macosarm64" >> .env.local
echo export CEF_BIN_PATH_WIN="$(pwd)/bin/cef_windows64" >> .env.local
echo export CEF_BIN_PATH_LIN="$(pwd)/bin/cef_linux64" >> .env.local

cat .env.local
source .env.local