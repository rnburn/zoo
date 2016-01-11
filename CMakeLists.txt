cmake_minimum_required(VERSION 3.0)
enable_testing()

project(zoo)

set(CMAKE_CXX_FLAGS "${CMAKE_CXX_FLAGS} -std=c++11 -Wall -Winvalid-pch -H")

function(_pch_make_include_flags _result)
  set(_include_flags "")
  foreach(_dir ${ARGN})
    string(CONCAT _include_flags "${_include_flags} -I${_dir}")
  endforeach()
  set(${_result} ${_include_flags} PARENT_SCOPE)
endfunction()

function(_pch_set_includes _target)
  foreach(_dir ${ARGN})
    target_include_directories(${_target} PUBLIC ${_dir})
  endforeach()
endfunction()

function(_pch_get_stub_basename _result _pch)
  get_filename_component(_pch_directory ${_pch} DIRECTORY)
  set(${_result} ${CMAKE_BINARY_DIR}/pch/${_pch}.stub PARENT_SCOPE)
endfunction()

function(_pch_get_directory _result _pch)
  _pch_get_stub_basename(_pch_basename ${_pch})
  get_filename_component(_directory ${_pch_basename} DIRECTORY)
  set(${_result} ${_directory} PARENT_SCOPE)
endfunction()

function(_pch_make_target _result _pch)
  string(REPLACE "/" "_" _target "_pch_${_pch}")
  set(${_result} ${_target} PARENT_SCOPE)
endfunction()

function(_pch_get_full_path _result _pch)
  get_property(_includes DIRECTORY PROPERTY INCLUDE_DIRECTORIES)
  find_path(_header_path ${_pch} ${_includes})
  set(${_result} "${_header_path}/${_pch}" PARENT_SCOPE)
endfunction()

function(_pch_add_dependency_stub _pch)
  _pch_get_stub_basename(_pch_basename ${_pch})
  set(_stub_source ${_pch_basename}.cpp)
  _pch_make_target(_stub_target ${_pch})
  get_filename_component(_stub_directory ${_pch_basename} DIRECTORY)
  separate_arguments(_command UNIX_COMMAND
    "mkdir -p ${_stub_directory} && \
     printf \\\"#include <${_pch}>\\\\nint main() { return 0; }\\\" > ${_stub_source}")
  add_custom_command(OUTPUT ${_stub_source} COMMAND ${_command})
  add_executable(${_stub_target} EXCLUDE_FROM_ALL ${_stub_source})
endfunction()

function(add_precompiled_header _pch)
  _pch_add_dependency_stub(${_pch})
  _pch_get_directory(_directory ${_pch})
  _pch_make_target(_target ${_pch})

  get_property(_includes DIRECTORY PROPERTY INCLUDE_DIRECTORIES)
  _pch_make_include_flags(_include_flags ${_includes})
  _pch_set_includes(${_target} ${_includes})
  _pch_get_full_path(_full_pch ${_pch})
  set(_output_pch ${_directory}/${_pch}.gch)
  get_filename_component(_output_pch_directory ${_output_pch} DIRECTORY)
  _pch_get_stub_basename(_stub_basename ${_pch})
  set(_update_header_stub ${_stub_basename}.h)
  
  separate_arguments(_build_pch UNIX_COMMAND
    "mkdir -p ${_output_pch_directory} && \
     ${CMAKE_CXX_COMPILER} ${CMAKE_CXX_FLAGS} ${_include_flags} \
     ${_full_pch} -o ${_output_pch}")
  add_custom_command(TARGET ${_target} PRE_BUILD 
    COMMAND ${_build_pch}
    BYPRODUCTS ${_output_pch})
endfunction()

function(use_precompiled_header _target _pch)
  _pch_get_directory(_directory ${_pch})
  set(_output_pch ${_directory}/${_pch}.gch)

  get_property(_sources TARGET ${_target} PROPERTY SOURCES)
  set_source_files_properties(${_sources}
    PROPERTIES OBJECT_DEPENDS ${_output_pch})

  _pch_make_target(_pch_target ${_pch})
  _pch_get_stub_basename(_pch_basename ${_pch})
  add_dependencies(${_target} ${_pch_target})

  _pch_get_directory(_pch_directory ${_pch})
  target_include_directories(${_target} BEFORE
    PUBLIC ${_pch_directory})
endfunction()

include_directories(enclosure/include)
include_directories(wolves/include)
add_subdirectory(wolves)
