# NOTE: In vSCode "settings.json", set your settings as:
# - "cmake.sourceDirectory": "${workspaceFolder}/src",
# - "cmake.generator": "Ninja Multi-Config"
cmake_minimum_required(VERSION 3.16)

# Set the C++ standard
set(CMAKE_CXX_STANDARD 17)
set(CMAKE_CXX_STANDARD_REQUIRED True)
set(CMAKE_C_COMPILER $ENV{CC})
set(CMAKE_CXX_COMPILER $ENV{CXX})
project(MySampleCEFTestApp_Src)
message(STATUS "#################################### ${PROJECT_NAME}")

# Check if the C and C++ compilers are set in the environment variables
if(DEFINED ENV{CC})
    set(CMAKE_C_COMPILER $ENV{CC})
else()
    # dynamically determine full paths of `clang` via `$(which clang)` command
    execute_process(COMMAND which clang OUTPUT_VARIABLE CLANG_PATH OUTPUT_STRIP_TRAILING_WHITESPACE)

    if(CLANG_PATH)
        set(CMAKE_C_COMPILER ${CLANG_PATH})
        #message(WARNING "CC environment variable is not set, defaulting to clang at ${CLANG_PATH}")
    else()
        message(FATAL_ERROR "CC environment variable is not set and clang not found in PATH")
    endif()
endif()
message(STATUS "ENV{CC} set to '$ENV{CC}' -> '${CMAKE_C_COMPILER}'")

if(DEFINED ENV{CXX})
    set(CMAKE_CXX_COMPILER $ENV{CXX})
else()
    # dynamically determine full paths of `clang++` via `$(which clang++)` command
    execute_process(COMMAND which clang++ OUTPUT_VARIABLE CLANGXX_PATH OUTPUT_STRIP_TRAILING_WHITESPACE)

    if(CLANGXX_PATH)
        set(CMAKE_CXX_COMPILER ${CLANGXX_PATH})
        #message(WARNING "CXX environment variable is not set, defaulting to clang++ at ${CLANGXX_PATH}")
    else()
        message(FATAL_ERROR "CXX environment variable is not set and clang++ not found in PATH")
    endif()
endif()
message(STATUS "ENV{CXX} set to '$ENV{CXX}' -> '${CMAKE_CXX_COMPILER}'")

if(DEFINED ENV{VCPKG_ROOT})
    set(VCPKG_ROOT $ENV{VCPKG_ROOT})
    set(VCPKG_TARGET_TRIPLET $ENV{VCPKG_TARGET_TRIPLET})
else()
    execute_process(COMMAND dirname $(which vcpkg) OUTPUT_VARIABLE VCPKG_ROOT OUTPUT_STRIP_TRAILING_WHITESPACE)
    if(VCPKG_ROOT)
        set(VCPKG_ROOT ${VCPKG_ROOT})
    else()
        message(FATAL_ERROR "Unable to locate vcpkg, please install it first")
    endif()
endif()
message(STATUS "VCPKG_ROOT: ${VCPKG_ROOT}")

if (CMAKE_SYSTEM_NAME STREQUAL "Linux" OR CMAKE_SYSTEM_NAME STREQUAL "Windows")
    message(STATUS "Configuring for Linux or Windows")
elseif (CMAKE_SYSTEM_NAME STREQUAL "Darwin")
    message(STATUS "Configuring for macOS")
else()
    message(STATUS "Unknown/Unhandled CMAKE_SYSTEM_NAME")
endif()

#include_directories(${PROJECT_SOURCE_DIR}/include)

# If we have other custom libraries that needs to be built first and linked as separate library:
add_library(my_external_lib STATIC my_external_lib.cpp my_external_lib.h)

# Source files (shared by ALL platforms)
set(SOURCES
    ./main.cpp
)

# Platform-specific settings - have to first check for MSYS/MinGW or else it'll think it's UNIX type
if (WIN32 OR MSYS OR MINGW)
    message(STATUS "Configuring for Windows")

    # Get the environment variable
    if(DEFINED ENV{CEF_BIN_PATH_WIN})
        set(CEF_BIN_PATH_WIN "$ENV{CEF_BIN_PATH_WIN}")
    else()
        message(FATAL_ERROR "CEF_BIN_PATH_WIN environment variable is not set")
    endif()
    set(CEF_ROOT ${CMAKE_SOURCE_DIR}/${CEF_BIN_PATH_WIN})

    # Use the environment variable
    message(STATUS "CEF_BIN_PATH_WIN is set to '${CEF_BIN_PATH_WIN}' ($ENV{CEF_BIN_PATH_WIN})")

    # append Windows specific source
    list(APPEND SOURCES my_internal_lib.cpp)
    list(APPEND CMAKE_MODULE_PATH ${CMAKE_SOURCE_DIR}/${CEF_BIN_PATH_WIN}/cmake)

    # Include directories based on ${CEF_BIN_PATH_XXX}/include"
    include_directories(${CMAKE_SOURCE_DIR}/${CEF_BIN_PATH_WIN} ../${CEF_BIN_PATH_WIN} ${CEF_BIN_PATH_WIN}/include ./ ./src ./include)
    link_directories(${CMAKE_SOURCE_DIR}/${CEF_BIN_PATH_WIN}/Release ../${CEF_BIN_PATH_WIN}/Release ${CEF_BIN_PATH_WIN}/Release ./Release)

    add_executable(${PROJECT_NAME} ${SOURCES})

    # NOTE: if you declare explicitly (i.e. 'libcef.lib'), CMake will auto-relace with '-lcef' for 'libcef.lib'
    target_link_libraries(${PROJECT_NAME} PRIVATE my_external_lib libcef.lib)
    target_compile_definitions(${PROJECT_NAME} PRIVATE -D_WINDOWS)
elseif (UNIX AND NOT APPLE)
    message(STATUS "Configuring for Linux (including WSL2)")

    # Get the environment variable
    if(DEFINED ENV{CEF_BIN_PATH_LIN})
        set(CEF_BIN_PATH_LIN $ENV{CEF_BIN_PATH_LIN})
    else()
        message(FATAL_ERROR "CEF_BIN_PATH_LIN environment variable is not set")
    endif()
    set(CEF_ROOT ${CMAKE_SOURCE_DIR}/${CEF_BIN_PATH_LIN})

    # Use the environment variable
    message(STATUS "CEF_BIN_PATH_LIN is set to '${CEF_BIN_PATH_LIN}' ($ENV{CEF_BIN_PATH_LIN})")

    # append Linux specific source
    list(APPEND SOURCES my_internal_lib.cpp)
    list(APPEND CMAKE_MODULE_PATH ${CMAKE_SOURCE_DIR}/${CEF_BIN_PATH_LIN}/cmake)

    # Include directories based on ${CEF_BIN_PATH_XXX}/include"
    include_directories(${CMAKE_SOURCE_DIR}/${CEF_BIN_PATH_LIN} ../${CEF_BIN_PATH_LIN} ${CEF_BIN_PATH_LIN}/include ./ ./src ./include)
    link_directories(${CMAKE_SOURCE_DIR}/${CEF_BIN_PATH_LIN}/Release ../${CEF_BIN_PATH_LIN}/Release ${CEF_BIN_PATH_LIN}/Release ./Release)

    # add_executable(MyExecutable ${CEF_BIN_PATH_LIN}/some_binary)
    add_executable(${PROJECT_NAME} ${SOURCES})

    # NOTE: it'll compile "my_internal_lib.cpp" as "my_internal_lib.cpp.o"
    target_link_libraries(${PROJECT_NAME} PRIVATE my_external_lib libcef.lib)
elseif (APPLE)
    message(STATUS "Configuring for macOS")

    # Get the environment variable
    if(DEFINED ENV{CEF_BIN_PATH_MAC})
        set(CEF_BIN_PATH_MAC $ENV{CEF_BIN_PATH_MAC})
    else()
        message(FATAL_ERROR "CEF_BIN_PATH_MAC environment variable is not set")
    endif()
    set(CEF_ROOT ${CMAKE_SOURCE_DIR}/${CEF_BIN_PATH_MAC})

    # Use the environment variable
    message(STATUS "CEF_BIN_PATH_MAC is set to '${CEF_BIN_PATH_MAC}' ($ENV{CEF_BIN_PATH_MAC})")

    # append macOS specific source (OBJCXX)
    list(APPEND SOURCES my_internal_lib.mm)
    list(APPEND CMAKE_MODULE_PATH ${CMAKE_SOURCE_DIR}/${CEF_BIN_PATH_MAC}/cmake)

    # Include directories based on ${CEF_BIN_PATH_XXX}/include"
    include_directories(${CMAKE_SOURCE_DIR}/${CEF_BIN_PATH_MAC} ../${CEF_BIN_PATH_MAC} ${CEF_BIN_PATH_MAC}/include ./ ./src ./include)
    link_directories(${CMAKE_SOURCE_DIR}/${CEF_BIN_PATH_MAC}/Release ../${CEF_BIN_PATH_MAC}/Release ${CEF_BIN_PATH_MAC}/Release ./Release)

    add_executable(${PROJECT_NAME} ${SOURCES})
    #add_executable(HelloWorld hello.mm main.cpp)

    target_link_libraries(${PROJECT_NAME} PRIVATE "-framework Foundation" my_external_lib libcef.dylib)
    #target_link_libraries(HelloWorld
    #    "-framework Foundation"
    #)
else()
    message(FATAL_ERROR "Unsupported platform")
endif()

message(STATUS "INCLUDE paths: ${CMAKE_INCLUDE_PATH}")
message(STATUS "LINK paths: ${CMAKE_LIBRARY_PATH}")
message(STATUS "VCPKG: ${VCPKG_TARGET_TRIPLET}")
message(STATUS "CEF_ROOT: ${CEF_ROOT}")