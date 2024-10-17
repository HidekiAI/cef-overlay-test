cmake_minimum_required(VERSION 3.16)
project(YourProjectName)

# Set the C++ standard
set(CMAKE_CXX_STANDARD 17)
set(CMAKE_CXX_STANDARD_REQUIRED True)

#set(CMAKE_GENERATOR_PLATFORM x64)

# Add the source files
add_subdirectory(src)

# Include directories
include_directories(${PROJECT_SOURCE_DIR}/src ./ ./include)

# Platform-specific configurations and triplets
if(WIN32)
    set(VCPKG_TARGET_TRIPLET "x64-mingw-static")
    target_compile_definitions(YourProjectName PRIVATE -D_WINDOWS)
elseif(APPLE)
    set(VCPKG_TARGET_TRIPLET "x64-mac-static")
    set(CMAKE_MACOSX_RPATH ON)
    set(CMAKE_OSX_DEPLOYMENT_TARGET "10.15")
elseif(UNIX AND NOT APPLE)
    set(VCPKG_TARGET_TRIPLET "x64-linux-static")
    set(CMAKE_INSTALL_PREFIX "/usr/local")
endif()

# Link libraries (if any)
target_link_libraries(YourProjectName PRIVATE your_library)

