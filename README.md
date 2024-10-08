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
