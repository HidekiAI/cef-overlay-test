cmake_minimum_required(VERSION 3.30)

# Set the C++ standard
set(CMAKE_CXX_STANDARD 17)
set(CMAKE_CXX_STANDARD_REQUIRED True)
set(CMAKE_CONFIGURATION_TYPES Debug Release)
set(CMAKE_BUILD_TYPE Release)

set(CMAKE_C_COMPILER $ENV{CC})
set(CMAKE_CXX_COMPILER $ENV{CXX})
project(ProjectRoot)
message(STATUS "#################################### ${CMAKE_SYSTEM_NAME}: ${CMAKE_HOST_SYSTEM_NAME}-${CMAKE_HOST_SYSTEM_VERSION} - ${PROJECT_NAME}")
# Check if CMAKE_C_COMPILER is set
if(NOT CMAKE_C_COMPILER)
    # Find the C compiler
    find_program(CMAKE_C_COMPILER 
      NAMES gcc clang)
    
    # Handle the case where the compiler is not found
    if(NOT CMAKE_C_COMPILER)
        message(FATAL_ERROR "C compiler not found.")
    else()
      message(STATUS "Found C compiler: ${CMAKE_C_COMPILER}")
      set(ENV{CC} ${CMAKE_C_COMPILER})
      set(CC ${CMAKE_C_COMPILER})
    endif()
endif()

# Check if CMAKE_CXX_COMPILER is set
if(NOT CMAKE_CXX_COMPILER)
    # Find the C++ compiler
    find_program(CMAKE_CXX_COMPILER 
      NAMES g++ clang++)
    
    # Handle the case where the compiler is not found
    if(NOT CMAKE_CXX_COMPILER)
        message(FATAL_ERROR "C++ compiler not found.")
    else()
        message(STATUS "Found C++ compiler: ${CMAKE_CXX_COMPILER}")
      set(ENV{CXX} ${CMAKE_CXX_COMPILER})
      set(CXX ${CMAKE_CXX_COMPILER})
    endif()
endif()

if("${CMAKE_BINARY_DIR}" STREQUAL "")
    message(FATAL_ERROR "CMAKE_BINARY_DIR is empty. Please specify a valid build directory.")
endif()

if (CMAKE_SOURCE_DIR STREQUAL CMAKE_BINARY_DIR)
    message(FATAL_ERROR "CMake must be run from outside the source directory")
endif()

#set_property(GLOBAL PROPERTY USE_FOLDERS ON)

# Platform-specific configurations and triplets
# See: https://cmake.org/cmake/help/latest/variable/CMAKE_HOST_SYSTEM_NAME.html#variable:CMAKE_HOST_SYSTEM_NAME
# See also: https://cmake.org/cmake/help/latest/variable/CMAKE_SYSTEM_NAME.html
if(Windows OR WIN32 OR MSYS OR MINGW OR OS_WINDOWS)
    #NOTE: for UCRT64, you use "Windows" instead of "MinGW"
    set(ENV{VCPKG_TARGET_TRIPLET} "x64-windows-static")
    set(VCPKG_TARGET_TRIPLET "x64-mingw-static")

    # Get the environment variable
    if(DEFINED ENV{CEF_BIN_PATH_WIN})
        #set(ENV{CEF_BIN_PATH_WIN} "$ENV{CEF_BIN_PATH_WIN}")
        set(CEF_BIN_PATH_WIN "$ENV{CEF_BIN_PATH_WIN}")
    else()
        message(FATAL_ERROR "CEF_BIN_PATH_WIN environment variable is not set")
    endif()
    set(ENV{CEF_ROOT} ${CMAKE_SOURCE_DIR}/${CEF_BIN_PATH_WIN})
    set(CEF_ROOT ${CMAKE_SOURCE_DIR}/${CEF_BIN_PATH_WIN})
elseif(Linux OR ( UNIX AND NOT APPLE) OR OR_LINUX)
    set(ENV{VCPKG_TARGET_TRIPLET} "x64-linux-static")
    set(VCPKG_TARGET_TRIPLET "x64-linux-static")
    set(CMAKE_INSTALL_PREFIX "/usr/local")

    # Get the environment variable
    if(DEFINED ENV{CEF_BIN_PATH_LIN})
        #set(ENV{CEF_BIN_PATH_LIN} $ENV{CEF_BIN_PATH_LIN})
        set(CEF_BIN_PATH_LIN $ENV{CEF_BIN_PATH_LIN})
    else()
        message(FATAL_ERROR "CEF_BIN_PATH_LIN environment variable is not set")
    endif()
    set(ENV{CEF_ROOT} ${CMAKE_SOURCE_DIR}/${CEF_BIN_PATH_LIN})
    set(CEF_ROOT ${CMAKE_SOURCE_DIR}/${CEF_BIN_PATH_LIN})
elseif(Darwin OR APPLE OR OS_MAC)
    set(ENV{VCPKG_TARGET_TRIPLET} "x64-mac-static")
    set(VCPKG_TARGET_TRIPLET "x64-mac-static")
    set(CMAKE_MACOSX_RPATH ON)
    set(CMAKE_OSX_DEPLOYMENT_TARGET "10.15")

    # Get the environment variable
    if(DEFINED ENV{CEF_BIN_PATH_MAC})
        #set(ENV{CEF_BIN_PATH_MAC} $ENV{CEF_BIN_PATH_MAC})
        set(CEF_BIN_PATH_MAC $ENV{CEF_BIN_PATH_MAC})
    else()
        message(FATAL_ERROR "CEF_BIN_PATH_MAC environment variable is not set")
    endif()
    set(ENV{CEF_ROOT} ${CMAKE_SOURCE_DIR}/${CEF_BIN_PATH_MAC})
    set(CEF_ROOT ${CMAKE_SOURCE_DIR}/${CEF_BIN_PATH_MAC})
else()
    message(FATAL_ERROR "Unsupported platform")
endif()

# Check if the C and C++ compilers are set in the environment variables
if(DEFINED ENV{CC} AND NOT CMAKE_C_COMPILER)
    set(ENV{CMAKE_C_COMPILER} $ENV{CC})
    set(CMAKE_C_COMPILER $ENV{CC})
else()
    # dynamically determine full paths of `clang` via `$(which clang)` command
    #execute_process( COMMAND which clang OUTPUT_VARIABLE CLANG_PATH OUTPUT_STRIP_TRAILING_WHITESPACE)
    find_program(CLANG_PATH NAMES clang)
    if(CLANG_PATH)
        set(ENV{CMAKE_C_COMPILER} ${CLANG_PATH})
        set(CMAKE_C_COMPILER ${CLANG_PATH})
        set(ENV{CC} ${CLANG_PATH})
        set(CC ${CLANG_PATH})
        #message(WARNING "CC environment variable is not set, defaulting to clang at ${CLANG_PATH}")
    else()
        message(FATAL_ERROR "CC environment variable is not set and clang not found in PATH")
    endif()
endif()
message(STATUS "ENV{CC} set to '$ENV{CC}' -> '${CMAKE_C_COMPILER}'")

if(DEFINED ENV{CXX} AND NOT CMAKE_CXX_COMPILER)
    set(ENV{CMAKE_CXX_COMPILER} $ENV{CXX})
    set(CMAKE_CXX_COMPILER $ENV{CXX})
else()
    # dynamically determine full paths of `clang++` via `$(which clang++)` command
    #execute_process( COMMAND which clang++ OUTPUT_VARIABLE CLANGXX_PATH OUTPUT_STRIP_TRAILING_WHITESPACE)
    find_program(CLANGXX_PATH NAMES clang++)
    if(CLANGXX_PATH)
        set(ENV{CMAKE_CXX_COMPILER} ${CLANGXX_PATH})
        set(CMAKE_CXX_COMPILER ${CLANGXX_PATH})
        set(ENV{CXX} ${CLANGXX_PATH})
        set(CXX ${CLANGXX_PATH})
        #message(WARNING "CXX environment variable is not set, defaulting to clang++ at ${CLANGXX_PATH}")
    else()
        message(FATAL_ERROR "CXX environment variable is not set and clang++ not found in PATH")
    endif()
endif()
message(STATUS "ENV{CXX} set to '$ENV{CXX}' -> '${CMAKE_CXX_COMPILER}'")

if(DEFINED ENV{CMAKE_MAKE_PROGRAM})
    set(CMAKE_MAKE_PROGRAM $ENV{CMAKE_MAKE_PROGRAM})
else()
    # dynamically determine full paths of `clang` via `$(which clang)` command
    #execute_process( COMMAND which ninja OUTPUT_VARIABLE NINJA_PATH OUTPUT_STRIP_TRAILING_WHITESPACE)
    find_program(NINJA_PATH NAMES ninja)
    if(NINJA_PATH)
        set(ENV{CMAKE_MAKE_PROGRAM} ${NINJA_PATH})
        set(CMAKE_MAKE_PROGRAM ${NINJA_PATH})
        #message(WARNING "CC environment variable is not set, defaulting to clang at ${CLANG_PATH}")
    else()
        message(FATAL_ERROR "Unable to locate paths to 'ninja' build (make) took")
    endif()
endif()
message(STATUS "Make tool: '${CMAKE_MAKE_PROGRAM}'")

# Find the vcpkg executable
find_program(VCPKG_EXECUTABLE NAMES vcpkg)
if(NOT VCPKG_EXECUTABLE)
    message(FATAL_ERROR "vcpkg executable not found.")
else()
    message(STATUS "Found vcpkg: ${VCPKG_EXECUTABLE}")

    # Determine the directory where vcpkg is located
    get_filename_component(VCPKG_ROOT "${VCPKG_EXECUTABLE}" DIRECTORY)

    # Set the VCPKG_ROOT environment variable if it's not already set
    if(NOT DEFINED ENV{VCPKG_ROOT} AND DEFINED VCPKG_ROOT)
        set(ENV{VCPKG_ROOT} ${VCPKG_ROOT})
    endif()
endif()
message(STATUS "VCPKG_ROOT: ${VCPKG_ROOT} (ENV: $ENV{VCPKG_ROOT})")
if (NOT DEFINED ENV{VCPKG_ROOT} OR NOT VCPKG_ROOT)
    message(FATAL_ERROR "VCPKG_ROOT environment variable is not set")
endif()

# Configure build directories has to be set BEFORE add_subdirectories() so that the output binaries are placed in the correct directories
# This is so that you don't have to do `set_target_properties( ${MY_EXTERNAL_LIB} PROPERTIES ... )` for each library
set(CMAKE_RUNTIME_OUTPUT_DIRECTORY ${CMAKE_BINARY_DIR}/bin)
set(CMAKE_ARCHIVE_OUTPUT_DIRECTORY ${CMAKE_BINARY_DIR}/lib)
set(CMAKE_LIBRARY_OUTPUT_DIRECTORY ${CMAKE_BINARY_DIR}/lib)

message(STATUS "CMAKE_SOURCE_DIR: ${CMAKE_SOURCE_DIR}")
message(STATUS "CMAKE_BINARY_DIR (OUTPUT): ${CMAKE_BINARY_DIR}")
message(STATUS "CMAKE_RUNTIME_OUTPUT_DIRECTORY: ${CMAKE_RUNTIME_OUTPUT_DIRECTORY}")
message(STATUS "CMAKE_ARCHIVE_OUTPUT_DIRECTORY: ${CMAKE_ARCHIVE_OUTPUT_DIRECTORY}")
message(STATUS "CMAKE_LIBRARY_OUTPUT_DIRECTORY: ${CMAKE_LIBRARY_OUTPUT_DIRECTORY}")
message(STATUS "CEF_ROOT dir: ${CEF_ROOT}")
message(STATUS "VCPKG_ROOT: ${VCPKG_ROOT}")

# Add the directory containing your custom modules
list(APPEND CMAKE_MODULE_PATH 
  "${CEF_ROOT}/cmake"
  "./cmake"
  "${CMAKE_BINARY_DIR}/cmake"
  )

# Include directories
include_directories(${CMAKE_SOURCE_DIR}/src ./ ./include ${CEF_ROOT}/include)

# Process the template file
configure_file(
    ${CEF_ROOT}/cmake/FindCEF.cmake
    ${CMAKE_BINARY_DIR}/FindCEF.cmake
    @ONLY
)
include(FindCEF)


# Link libraries (if any)
#target_link_libraries(${PROJECT_NAME} PRIVATE your_library)

configure_file(
    ${CMAKE_SOURCE_DIR}/src/CMakeLists.txt.in
    ${CMAKE_BINARY_DIR}/CMakeLists.txt
    @ONLY
)

# Add config include and link-lib paths (for config, not for compilation/linking), it should be FULL PATH
# Read the current value of the environment variable
if(DEFINED ENV{CMAKE_INCLUDE_PATH})
    set(CURRENT_INCLUDE_PATH $ENV{CMAKE_INCLUDE_PATH})
else()
    set(CURRENT_INCLUDE_PATH "")
endif()
# Append the new paths to the current value
set(NEW_INCLUDE_PATH "${CURRENT_INCLUDE_PATH}:${CMAKE_SOURCE_DIR}/include:${CMAKE_BINARY_DIR}/include:${CEF_ROOT}/include")
# Set the updated environment variable
set(ENV{CMAKE_INCLUDE_PATH} ${NEW_INCLUDE_PATH})

if(DEFINED ENV{CMAKE_LIBRARY_PATH})
    set(CURRENT_LIBRARY_PATH $ENV{CMAKE_LIBRARY_PATH})
else()
    set(CURRENT_LIBRARY_PATH "")
endif()
set(NEW_LIBRARY_PATH "${CURRENT_LIBRARY_PATH}:${CMAKE_SOURCE_DIR}/lib:${CMAKE_BINARY_DIR}/lib:${CEF_ROOT}/lib")
set(ENV{CMAKE_LIBRARY_PATH} ${NEW_LIBRARY_PATH})
message(STATUS "INCLUDE paths: '${CMAKE_INCLUDE_PATH}' (for config, not compile, ENV: $ENV{CMAKE_INCLUDE_PATH})")
message(STATUS "Package library paths: '${CMAKE_LIBRARY_PATH}' (used for config, not for link, ENV: $ENV{CMAKE_LIBRARY_PATH})")
message(STATUS "VCPKG triplet: ${VCPKG_TARGET_TRIPLET} (ENV: $ENV{VCPKG_TARGET_TRIPLET})")
message(STATUS "CEF_ROOT: ${CEF_ROOT} (ENV: $ENV{CEF_ROOT})")

# Finally, add the source files with all the configurations and ENV variables set...
# It is NOT a typo to add ${CMAKE_BINARY_DIR}/src instead of ${CMAKE_SOURCE_DIR}/src, this prevents
# the "CMakeFiles" directories from being created in the source directory!
add_subdirectory(./src ${CMAKE_BINARY_DIR}/src)

message(STATUS "#################################### ${PROJECT_NAME} done")
