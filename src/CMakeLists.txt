cmake_minimum_required(VERSION 3.16)
project(MySampleCEFApp)

# Set the C++ standard
set(CMAKE_CXX_STANDARD 17)
set(CMAKE_CXX_STANDARD_REQUIRED ON)

# Set the Objective-C++ standard
set(CMAKE_OBJCXX_STANDARD 17)
set(CMAKE_OBJCXX_STANDARD_REQUIRED ON)

#include_directories(${PROJECT_SOURCE_DIR}/include)

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

    # Source files
    set(SOURCES
        ./main.cpp
        ./mylib.cpp
    )

    # Include directories based on ${CEF_BIN_PATH_XXX}/include"
    include_directories(${CEF_BIN_PATH_LIN}/include/linux)
    link_directories(${CEF_BIN_PATH_LIN}/Release)

    # add_executable(MyExecutable ${CEF_BIN_PATH_LIN}/some_binary)
    add_executable(${PROJECT_NAME} ${SOURCES})

    # NOTE: it'll compile "mylib.cpp" as "mylib.cpp.o"
    target_link_libraries(${PROJECT_NAME} PRIVATE mylib)
elseif (WIN32 OR MSYS OR MINGW)
    # Source files
    set(SOURCES
        ./main.cpp
        ./mylib.cpp
    )

    message(STATUS "Configuring for Windows")

    # Get the environment variable
    if(DEFINED ENV{CEF_BIN_PATH_WIN})
        set(CEF_BIN_PATH_WIN $ENV{CEF_BIN_PATH_WIN})
    else()
        message(FATAL_ERROR "CEF_BIN_PATH_WIN environment variable is not set")
    endif()

    # Use the environment variable
    message(STATUS "CEF_BIN_PATH_WIN is set to ${CEF_BIN_PATH_WIN}")

    # Include directories based on ${CEF_BIN_PATH_XXX}/include"
    include_directories(${CEF_BIN_PATH_WIN}/include/windows)
    link_directories(${CEF_BIN_PATH_WIN}/Release)

    add_executable(${PROJECT_NAME} ${SOURCES})

    # NOTE: it'll compile "mylib.cpp" as "mylib.cpp.o"
    target_link_libraries(${PROJECT_NAME} PRIVATE mylib)
elseif (APPLE)
    # Source files
    set(SOURCES
        ./main.cpp
        ./mylib.mm
    )

    message(STATUS "Configuring for macOS")

    # Get the environment variable
    if(DEFINED ENV{CEF_BIN_PATH_MAC})
        set(CEF_BIN_PATH_MAC $ENV{CEF_BIN_PATH_MAC})
    else()
        message(FATAL_ERROR "CEF_BIN_PATH_MAC environment variable is not set")
    endif()

    # Use the environment variable
    message(STATUS "CEF_BIN_PATH_MAC is set to ${CEF_BIN_PATH_MAC}")

    # Include directories based on ${CEF_BIN_PATH_XXX}/include"
    include_directories(${CEF_BIN_PATH_MAC}/include/macos)
    link_directories(${CEF_BIN_PATH_MAC}/Release)

    add_executable(${PROJECT_NAME} ${SOURCES})
    #add_executable(HelloWorld hello.mm main.cpp)

    target_link_libraries(${PROJECT_NAME} PRIVATE "-framework Foundation" mylib)
    #target_link_libraries(HelloWorld
    #    "-framework Foundation"
    #)
else()
    message(FATAL_ERROR "Unsupported platform")
endif()


