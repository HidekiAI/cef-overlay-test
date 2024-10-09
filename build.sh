#!/bin/bash

[ -e bin ] || ./get-binaries.sh
[ -e build ] || mkdir -p build

cat .env.local
source .env.local

cmake -DCMAKE_BUILD_TYPE:STRING=Debug \
    -DCMAKE_EXPORT_COMPILE_COMMANDS:BOOL=TRUE \
    -DCMAKE_C_COMPILER:FILEPATH=$(which clang) \
    -DCMAKE_CXX_COMPILER:FILEPATH=$(which clang++) \
    --no-warn-unused-cli \
    -S./src \
    -B./build \
    -G "Ninja"
cd build
make
