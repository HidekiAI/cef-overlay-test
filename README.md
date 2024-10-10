# cef-overlay-test

A test-prototype to get (and understand) Linux, WIndows, and MacOS to render invisible (frameless) CEF via CMake for cross-compilations

- [CEF repository](https://bitbucket.org/chromiumembedded/cef/src/master/)
- Unsure what LICENSE CEF is (their LICENSE.txt was a bit to concise) so making this MIT LICENSE
- Because the github version seems to be Linux biased (I'm not 100% sure, but their Python script even does `lsb_release` which is hard to fake (i.e. write my own `lsb_release.sh` for Windows and MacOS)) so we'll be using the [SpotifyCDN](https://cef-builds.spotifycdn.com/index.html) version which you can download post-compiled binaries for [MacOS ARM64](https://cef-builds.spotifycdn.com/index.html#macosarm64) (and Windows x86_64) to save time compiling them.  All you need are the "Standard" binary for each (target) platform.
- C++ Documentations at [Chromium Embedded Framework (CEF) Documentation](https://cef-builds.spotifycdn.com/docs/129.0/index.html) - at the time of the writing, it was/is at build '129.0.1+g463bda9+chromium-129.0.6668.12'
- [CEF Forum](https://magpcss.org/ceforum/index.php)
-
- [CefBrowserHost::CreateBrowser](https://cef-builds.spotifycdn.com/docs/106.1/classCefBrowserHost.html#:~:text=Create%20a%20new%20browser%20using%20the%20window%20parameters)

## Goals

To lean and test-compile (and run) CEF (basically starting off with cefsample and cef-client) in frameless and titleless with simple "Hello World" as overlay on Linux, Windows, and MacOS.

## Technical Issues

- Turns out I have to `clang++`  (`g++`) using C++ 17 (via `-std=c++17`) so that compiling (and linking) will succeed
- For both Linux and Windows, because the GUI (GTK and WinForm respectively) are based on C/C++ library, there are no bridge/proxy from C++ to platform-native GUI libraries
  - For MacOS on the other hand, the platform-native GUI is based on Objective-C libraries, in which you'd have to have Objective-C compiler reference (`static`) function-methods in C++ and link it.  If you've ever done any InterOp'ing in C# (actually, .NET) to native C++, or have tried to access GTK3 and/or WinForm from Rust in which you had to run `bindgen` to create wrapper methods of C/C++ libraries to Rust, you're already familiar with this practice.
- I am using `cmake` (`CMakeLists.txt`) to support cross-compile and multiple-platform, and have used [this as base](https://stackoverflow.com/questions/20962869/cmakelists-txt-for-an-objective-c-project) starting point.
  - I am not using XCode project (it's based on mixing CPP and OBJCXX)

## Setup and Install

### Build Prerequisite

Due to not knowing what platform you're on, as well as unaware whether you're using `apt` (Debian hybrids - Linux), `pacman` (Arch, SuSE, MSys64/MinGW - Windows), or even `brew` (MacOS), you'll have to manually install it yourself.  What you need are the following:

- `clang` and `llvm` so that `g++` is generic on all platform - note that you'll have about 3 choices on Windows, chose MSYS64 (not the other 2).  What is most important is that you make sure to install the version that supports C++17 because of MacOS GUI (Cocoa relies heavily on C++ `templates` defined in C++17 and above)
- `cmake` and `ninja` - again, for portable.  Optionally you can install `GNU make` but I will yield towards `ninja`
- Other Unix/Linux/BSD related CLI tools:
  - `tar` - to untar binaries from spotifycdn
  - `wget` - if you prefer `cURL`, you'll have to modify `build.sh` manually/yourself
  - `bash` - I don't wish to write 2 scripts, one for `bash` and one for `zsh`, so on MacOS, you'll have to install `bash` yourself (I use commands such as `uname -a`, `source`, `-e ||`, etc)
- XCode - you'll need the whole SDK'ish (I don't know what to call it, I'm still learning) package so that you can have Objective-C++ to consume/link the C++

### `bash` and other Unix/Linux CLI commands

One issue about this project is that (as mentioned above), I am *VERY* `bash` (Linux CLI command) biased.  You *MUST* make sure one way or another, for even VSCode to be able to access `bash` because you will see logics even in `CMakeLists.txt` (`cmake`) build logic like this:

```cmake
# Check if the C and C++ compilers are set in the environment variables
if(DEFINED ENV{CC})
    set(CMAKE_C_COMPILER $ENV{CC})
else()
    execute_process(COMMAND which clang OUTPUT_VARIABLE CLANG_PATH OUTPUT_STRIP_TRAILING_WHITESPACE)
    if(CLANG_PATH)
        set(CMAKE_C_COMPILER ${CLANG_PATH})
        message(WARNING "CC environment variable is not set, defaulting to clang at ${CLANG_PATH}")
    else()
        message(FATAL_ERROR "CC environment variable is not set and clang not found in PATH")
    endif()
endif()

if(DEFINED ENV{CXX})
    set(CMAKE_CXX_COMPILER $ENV{CXX})
else()
    execute_process(COMMAND which clang++ OUTPUT_VARIABLE CLANGXX_PATH OUTPUT_STRIP_TRAILING_WHITESPACE)
    if(CLANGXX_PATH)
        set(CMAKE_CXX_COMPILER ${CLANGXX_PATH})
        message(WARNING "CXX environment variable is not set, defaulting to clang++ at ${CLANGXX_PATH}")
    else()
        message(FATAL_ERROR "CXX environment variable is not set and clang++ not found in PATH")
    endif()
endif()
```

This IMHO is better than hard-coding paths depending on different OS.  By doing `which clang++` (or `which g++`) to get clang and clang++ paths (i.e. `/usr/bin/g++`, `/c/msys/mingw64/usr/bin/g++`, `/mingw64/bin/clang`, etc) dynamically, we do not have to hard code the paths.  Even just testing on Linux, not all distros will place `gcc` in same directory (i.e. `/bin/gcc`, `/usr/bin/gcc`, `$HOME/bin/gcc`, `/opt/bin/gcc`, etc).  Screw that, just do `export CXX="$(which clang++)"` during build-time and dynamically determine it...

### Building

Use `build.sh`; I try to `echo` warnings/errors in the shell script when I cannot find `wget` or other CLI packages that is possibly optional on MacOS, as well as listing ahead on the [Prerequisite](#prerequisite) above, but there may be times where I've preinstalled it and have forgotten about it.
