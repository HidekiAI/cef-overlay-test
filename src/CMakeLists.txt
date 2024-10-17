# NOTE: In vSCode "settings.json", set your settings as:
# - "cmake.sourceDirectory": "${workspaceFolder}/src",
# - "cmake.generator": "Ninja Multi-Config"
cmake_minimum_required(VERSION 3.16)

# Set the C++ standard
set(CMAKE_CXX_STANDARD 17)
set(CMAKE_CXX_STANDARD_REQUIRED True)

#set(CMAKE_GENERATOR_PLATFORM x64)

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

project(MySampleCEFApp)

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
if (UNIX)
    message(STATUS "Configuring for Linux (including WSL2)")

    # Get the environment variable
    if(DEFINED ENV{CEF_BIN_PATH_LIN})
        set(CEF_BIN_PATH_LIN $ENV{CEF_BIN_PATH_LIN})
    else()
        message(FATAL_ERROR "CEF_BIN_PATH_LIN environment variable is not set")
    endif()

    # Use the environment variable
    message(STATUS "CEF_BIN_PATH_LIN is set to ${CEF_BIN_PATH_LIN}")

    # append Linux specific source
    list(APPEND SOURCES my_internal_lib.cpp)

    # Include directories based on ${CEF_BIN_PATH_XXX}/include"
    include_directories(${CEF_BIN_PATH_LIN}/include/linux ./ ./src ./include)
    link_directories(${CEF_BIN_PATH_LIN}/Release)

    # add_executable(MyExecutable ${CEF_BIN_PATH_LIN}/some_binary)
    add_executable(${PROJECT_NAME} ${SOURCES})

    # NOTE: it'll compile "my_internal_lib.cpp" as "my_internal_lib.cpp.o"
    target_link_libraries(${PROJECT_NAME} PRIVATE my_external_lib)
elseif (WIN32 OR MSYS OR MINGW)
    message(STATUS "Configuring for Windows")

    # Get the environment variable
    if(DEFINED ENV{CEF_BIN_PATH_WIN})
        set(CEF_BIN_PATH_WIN $ENV{CEF_BIN_PATH_WIN})
    else()
        message(FATAL_ERROR "CEF_BIN_PATH_WIN environment variable is not set")
    endif()

    # Use the environment variable
    message(STATUS "CEF_BIN_PATH_WIN is set to ${CEF_BIN_PATH_WIN}")

    # append Windows specific source
    list(APPEND SOURCES my_internal_lib.cpp)

    # Include directories based on ${CEF_BIN_PATH_XXX}/include"
    include_directories(${CEF_BIN_PATH_WIN}/include/windows ./ ./src ./include)
    link_directories(${CEF_BIN_PATH_WIN}/Release)

    add_executable(${PROJECT_NAME} ${SOURCES})

    # NOTE: it'll compile "my_internal_lib.cpp" as "my_internal_lib.cpp.o"
    target_link_libraries(${PROJECT_NAME} PRIVATE my_external_lib)
elseif (APPLE)
    message(STATUS "Configuring for macOS")

    # Get the environment variable
    if(DEFINED ENV{CEF_BIN_PATH_MAC})
        set(CEF_BIN_PATH_MAC $ENV{CEF_BIN_PATH_MAC})
    else()
        message(FATAL_ERROR "CEF_BIN_PATH_MAC environment variable is not set")
    endif()

    # Use the environment variable
    message(STATUS "CEF_BIN_PATH_MAC is set to ${CEF_BIN_PATH_MAC}")

    # append macOS specific source (OBJCXX)
    list(APPEND SOURCES my_internal_lib.mm)

    # Include directories based on ${CEF_BIN_PATH_XXX}/include"
    include_directories(${CEF_BIN_PATH_MAC}/include/macos ./ ./src ./include)
    link_directories(${CEF_BIN_PATH_MAC}/Release)

    add_executable(${PROJECT_NAME} ${SOURCES})
    #add_executable(HelloWorld hello.mm main.cpp)

    target_link_libraries(${PROJECT_NAME} PRIVATE "-framework Foundation" my_external_lib)
    #target_link_libraries(HelloWorld
    #    "-framework Foundation"
    #)
else()
    message(FATAL_ERROR "Unsupported platform")
endif()
