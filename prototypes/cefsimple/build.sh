#!/bin/bash
_BUILD_TYPE=${1:-Release}

./get_binaries.sh $_BUILD_TYPE
[ -d build ] || mkdir build

cd build
cmake  -DCMAKE_BUILD_TYPE=$_BUILD_TYPE -G "Unix Makefiles" ..
make all 
make cefsimple
