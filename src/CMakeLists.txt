# NOTE: In vSCode "settings.json", set your settings as:
# - "cmake.sourceDirectory": "${workspaceFolder}/src",
# - "cmake.generator": "Ninja Multi-Config"
cmake_minimum_required(VERSION 3.30)

# Set the C++ standard
set(CMAKE_CXX_STANDARD 17)
set(CMAKE_CXX_STANDARD_REQUIRED True)
set(CMAKE_C_COMPILER $ENV{CC})
set(CMAKE_CXX_COMPILER $ENV{CXX})
#set(CMAKE_RUNTIME_OUTPUT_DIRECTORY ${CMAKE_BINARY_DIR})
set(CMAKE_CONFIGURATION_TYPES Debug Release)
set(CMAKE_BUILD_TYPE Release)
project(MySampleCEFTestApp_Src)
message(STATUS "#################################### ${PROJECT_NAME}")
if("${CMAKE_BINARY_DIR}" STREQUAL "")
    message(FATAL_ERROR "CMAKE_BINARY_DIR is empty. Please specify a valid build directory.")
endif()

if (CMAKE_SOURCE_DIR STREQUAL CMAKE_BINARY_DIR)
    message(FATAL_ERROR "CMake must be run from outside the source directory")
endif()

message(STATUS "SOURCE: ${CMAKE_SOURCE_DIR}")
message(STATUS "DEST (Output): ${CMAKE_BINARY_DIR}")
message(STATUS "CMAKE_RUNTIME_OUTPUT_DIRECTORY: ${CMAKE_RUNTIME_OUTPUT_DIRECTORY}")

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
else()
    execute_process(COMMAND dirname $(which vcpkg) OUTPUT_VARIABLE VCPKG_ROOT OUTPUT_STRIP_TRAILING_WHITESPACE)
    if(VCPKG_ROOT)
        set(VCPKG_ROOT ${VCPKG_ROOT})
    else()
        message(FATAL_ERROR "Unable to locate vcpkg, please install it first")
    endif()
endif()
message(STATUS "VCPKG_ROOT: ${VCPKG_ROOT}")

if(DEFINED ENV{VCPKG_TARGET_TRIPLET})
    set(VCPKG_TARGET_TRIPLET $ENV{VCPKG_TARGET_TRIPLET})
else()
    execute_process(COMMAND dirname $(which vcpkg) OUTPUT_VARIABLE VCPKG_TARGET_TRIPLET OUTPUT_STRIP_TRAILING_WHITESPACE)
    if(VCPKG_TARGET_TRIPLET)
        set(VCPKG_TARGET_TRIPLET ${VCPKG_TARGET_TRIPLET})
    else()
        message(FATAL_ERROR "Unable to locate vcpkg, please install it first")
    endif()
endif()
message(STATUS "VCPKG_TARGET_TRIPLET: ${VCPKG_TARGET_TRIPLET}")

if (CMAKE_SYSTEM_NAME STREQUAL "Linux" OR CMAKE_SYSTEM_NAME STREQUAL "Windows")
    message(STATUS "Configuring for Linux or Windows")
elseif (CMAKE_SYSTEM_NAME STREQUAL "Darwin")
    message(STATUS "Configuring for macOS")
else()
    message(STATUS "Unknown/Unhandled CMAKE_SYSTEM_NAME")
endif()

######################################################
# If we have other custom libraries that needs to be built first and linked as separate library:
set(MY_EXTERNAL_LIB "my_external_lib")

# PROJECT_NAME will be the executable name (i.e. "MySampleCEFTestApp_Src.exe")
# source files relative to THIS CMakeLists.txt file...
set(SOURCES
    ./my_internal_lib.cpp
)

# Collect all .cc files in the src/browser directory
file(GLOB_RECURSE BROWSER_WIN_SOURCES browser/*_win.*)
file(GLOB_RECURSE BROWSER_LIN_SOURCES browser/*_gtk.*)
file(GLOB_RECURSE BROWSER_MAC_SOURCES browser/*_mac.*)
file(GLOB_RECURSE COMMON_SOURCES common/*.cc)
file(GLOB_RECURSE COMMON_HEADERS common/*.h)
file(GLOB_RECURSE RENDERER_SOURCES renderer/*.cc)
file(GLOB_RECURSE RENDERER_HEADERS renderer/*.h)
file(GLOB_RECURSE RESOURCES_SOURCES resources/*.cc)
file(GLOB_RECURSE RESOURCES_HEADERS resources/*.h)

######################################################

# Platform-specific settings - have to first check for MSYS/MinGW or else it'll think it's UNIX type
if(Windows OR WIN32 OR MSYS OR MINGW OR OS_WINDOWS)
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
    list(APPEND SOURCES 
            ./testapp_win.cpp
    )

    #target_compile_definitions(${PROJECT_NAME} PRIVATE -D_WINDOWS)
    file(GLOB_RECURSE WIN_SOURCES win/*.cc)
    file(GLOB_RECURSE WIN_HEADERS win/*.h)
elseif(Linux OR ( UNIX AND NOT APPLE) OR OR_LINUX)
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
    list(APPEND SOURCES 
            ./testapp_lin.cpp
    )
elseif(Darwin OR APPLE OR OS_MAC)
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
    list(APPEND SOURCES 
	    my_internal_lib.mm
            ./testapp_mac.mm
    )

    file(GLOB_RECURSE MAC_SOURCES mac/*.cc)
    file(GLOB_RECURSE MAC_HEADERS mac/*.h)
else()
    message(FATAL_ERROR "Unsupported platform")
endif()

list(APPEND CMAKE_MODULE_PATH ${CEF_ROOT}/cmake)

# Include directories based on ${CEF_BIN_PATH_XXX}/include"
include_directories(${CEF_ROOT} ${CEF_ROOT}/include ./ ./src ./include)
link_directories(
    ${CEF_ROOT}/Release 
    ./Release 
    ${CMAKE_BINARY_DIR}/lib 
    ${CMAKE_BINARY_DIR}/bin)


# Note: link_directories() is for link-time usage, while CMAKE_LIBRARY_PATH is for cmake to search for packages
message(STATUS "INCLUDE paths: ${CMAKE_INCLUDE_PATH}")
message(STATUS "Package library paths: ${CMAKE_LIBRARY_PATH}")
message(STATUS "VCPKG triplet: ${VCPKG_TARGET_TRIPLET}")
message(STATUS "CEF_ROOT: ${CEF_ROOT}")

#######################################################
## Group target contents by directory.
#macro(SET_SOURCE_GROUPS srcs)
#    foreach(FILE ${srcs}) 
#        # Get the absolute directory path.
#        get_filename_component(ABS_FILE "${FILE}" ABSOLUTE)
#        get_filename_component(PARENT_DIR "${ABS_FILE}" DIRECTORY)
#
#        # Remove the common directory prefix. What remains in the group.
#        string(REPLACE "${CMAKE_SOURCE_DIR}/src/" "" GROUP "${PARENT_DIR}")
#
#        # Convert to Windows slashes.
#        string(REPLACE "/" "\\" GROUP "${GROUP}")
#
#        source_group("${GROUP}" FILES "${FILE}")
#    endforeach()
#endmacro()

######################################################
# If we have other custom libraries that needs to be built first and linked as separate library:
add_library( ${MY_EXTERNAL_LIB} STATIC 
    my_external_lib.cpp 
    my_external_lib.h)
## Set the output directories for your targets (has to be set AFTER add_library() call)
#set_target_properties( ${MY_EXTERNAL_LIB} PROPERTIES 
#    ARCHIVE_OUTPUT_DIRECTORY ${CMAKE_BINARY_DIR}/lib
#    LIBRARY_OUTPUT_DIRECTORY ${CMAKE_BINARY_DIR}/lib
#    RUNTIME_OUTPUT_DIRECTORY ${CMAKE_BINARY_DIR}
#)

add_executable( 
    ${PROJECT_NAME} ${SOURCES} 
    ${COMMON_SOURCES} ${COMMON_HEADERS} 
    ${BROWSER_MAC_SOURCES}
    ${RENDERER_SOURCES} ${RENDERER_HEADERS} 
    ${RESOURCES_SOURCES} ${RESOURCES_HEADERS}
    ) 

if(Windows OR WIN32 OR MSYS OR MINGW OR OS_WINDOWS)
    # NOTE: if you declare explicitly (i.e. 'libcef.lib'), CMake will auto-relace with '-lcef' for 'libcef.lib'
    #target_link_libraries(${PROJECT_NAME} PRIVATE ${MY_EXTERNAL_LIB} libcef.lib)
    target_link_libraries(${PROJECT_NAME} PRIVATE 
        stdc++
        ${MY_EXTERNAL_LIB} 
        libcef_dll_wrapper.a
        cef)
    target_compile_definitions(${PROJECT_NAME} PRIVATE -D_WINDOWS)
elseif(Linux OR ( UNIX AND NOT APPLE) OR OR_LINUX)
    # NOTE: it'll compile "my_internal_lib.cpp" as "my_internal_lib.cpp.o"
    target_link_libraries(${PROJECT_NAME} PRIVATE 
        -static-libstdc++
        ${MY_EXTERNAL_LIB} 
        libcef_dll_wrapper.a
        cef)
elseif(Darwin OR APPLE OR OS_MAC)
    target_link_libraries(${PROJECT_NAME} PRIVATE 
        c++
        "-framework Foundation" 
        "-framework AppKit" 
        "-framework Cocoa" 
        ${MY_EXTERNAL_LIB} 
        libcef.dylib
        libcef_dll_wrapper.a
        )
    #target_link_libraries(HelloWorld
    #    "-framework Foundation"
    #)
endif()
######################################################

message(STATUS "#################################### ${PROJECT_NAME} done")
