cmake_minimum_required(VERSION 3.0)
enable_testing()

project(zoo)

include(precompiled-header.cmake)

set(CMAKE_CXX_FLAGS "${CMAKE_CXX_FLAGS} -std=c++11 -Wall -Winvalid-pch -H")

include_directories(enclosure/include)
include_directories(wolves/include)
add_subdirectory(wolves)
