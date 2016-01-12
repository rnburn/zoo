add_executable(wolves-test test.cpp)
add_test(wolves-test ${CMAKE_CURRENT_BINARY_DIR}/wolves-test)
use_precompiled_header(wolves-test "zoo/wolves/dependency.h")
