#!/bin/bash

[ -d build ] || mkdir build
[ -d Release ] || ln -sv ../../bin/cef_macosarm64/Release

cd build
cmake ..
make all

