function(_pch_make_include_flags _result)
  set(_include_flags "")
  foreach(_dir ${ARGN})
    string(CONCAT _include_flags "${_include_flags} -I${_dir}")
  endforeach()
  set(${_result} ${_include_flags} PARENT_SCOPE)
endfunction()

function(_pch_get_stub_source _result _header)
  set(${_result} ${CMAKE_BINARY_DIR}/pch/${_header}_stub.cpp PARENT_SCOPE)
endfunction()

function(_pch_get_directory _result _header)
  _pch_get_stub_source(_stub_source ${_header})
  get_filename_component(_directory ${_stub_source} DIRECTORY)
  set(${_result} ${_directory} PARENT_SCOPE)
endfunction()

function(_pch_get_target _result _header)
  string(REPLACE "/" "_" _target "_pch_${_header}")
  set(${_result} ${_target} PARENT_SCOPE)
endfunction()

function(_pch_get_full_header_path _result _header)
  get_property(_includes DIRECTORY PROPERTY INCLUDE_DIRECTORIES)
  find_path(_header_path ${_header} ${_includes})
  set(${_result} ${_header_path}/${_header} PARENT_SCOPE)
endfunction()

function(_pch_get_full_pch_path _result _header)
  if("${CMAKE_CXX_COMPILER_ID}" STREQUAL "Clang")
    set(_suffix ".pch")
  elseif("${CMAKE_CXX_COMPILER_ID}" STREQUAL "GNU")
    set(_suffix ".gch")
  else()
    error("${CMAKE_CXX_COMPILER_ID} is not supported")
  endif()
  _pch_get_directory(_directory ${_header})
  set(${_result} ${_directory}/include/${_header}${_suffix} PARENT_SCOPE)
endfunction()

function(_pch_add_dependency_stub _header)
  _pch_get_stub_source(_source ${_header})
  _pch_get_target(_target ${_header})
  _pch_get_directory(_directory ${_header})
  separate_arguments(_command UNIX_COMMAND
    "mkdir -p ${_directory} && \
     printf \\\"#include <${_header}>\\\\nint main() { return 0; }\\\" 
        > ${_source}")
  add_custom_command(OUTPUT ${_source} COMMAND ${_command})
  add_executable(${_target} EXCLUDE_FROM_ALL ${_source})
  set_target_properties(${_target}
    PROPERTIES RUNTIME_OUTPUT_DIRECTORY ${_directory})
endfunction()

function(add_precompiled_header _header)
  _pch_add_dependency_stub(${_header})
  _pch_get_directory(_directory ${_header})
  _pch_get_target(_target ${_header})

  get_property(_includes DIRECTORY PROPERTY INCLUDE_DIRECTORIES)
  _pch_make_include_flags(_include_flags ${_includes})
  target_include_directories(${_target} PUBLIC ${_includes})
  _pch_get_full_header_path(_full_header_path ${_header})
  _pch_get_full_pch_path(_pch ${_header})
  
  separate_arguments(_build_pch UNIX_COMMAND
    "mkdir -p `dirname ${_pch}` && \
     ${CMAKE_CXX_COMPILER} ${CMAKE_CXX_FLAGS} ${_include_flags} \
     ${_full_header_path} -o ${_pch}")
  add_custom_command(TARGET ${_target} PRE_BUILD 
    COMMAND ${_build_pch} BYPRODUCTS ${_pch})
endfunction()

function(use_precompiled_header _target _header)
  _pch_get_full_pch_path(_pch ${_header})

  get_property(_sources TARGET ${_target} PROPERTY SOURCES)
  set_source_files_properties(${_sources}
    PROPERTIES OBJECT_DEPENDS ${_pch})

  _pch_get_target(_pch_target ${_header})
  add_dependencies(${_target} ${_pch_target})

  _pch_get_directory(_directory ${_header})
  target_include_directories(${_target} BEFORE PUBLIC ${_directory}/include)

  if("${CMAKE_CXX_COMPILER_ID}" STREQUAL "Clang")
    set_target_properties(${_target} 
      PROPERTIES COMPILE_FLAGS "-include-pch ${_pch}")
  endif()
endfunction()
