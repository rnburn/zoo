function(_pch_write_target_flags _filename _target)
  set(_include_directories "$<TARGET_PROPERTY:${_target},INCLUDE_DIRECTORIES>")
  set(_compile_definitions "$<TARGET_PROPERTY:${_target},COMPILE_DEFINITIONS>")
  set(_compile_flags "$<TARGET_PROPERTY:${_target},COMPILE_FLAGS>")
  set(_compile_options "$<TARGET_PROPERTY:${_target},COMPILE_OPTIONS>")
  set(_include_directories "$<$<BOOL:${_include_directories}>:\
                            -I$<JOIN:${_include_directories},\n-I>\n>")
  set(_compile_definitions "$<$<BOOL:${_compile_definitions}>:\
                            -D$<JOIN:${_compile_definitions},\n-D>\n>")
  set(_compile_flags 
    "$<$<BOOL:${_compile_flags}>:$<JOIN:${_compile_flags},\n>\n>")
  set(_compile_options 
    "$<$<BOOL:${_compile_options}>:$<JOIN:${_compile_options},\n>\n>")
  file(GENERATE OUTPUT ${_filename} CONTENT 
    "${CMAKE_CXX_FLAGS}\n${_compile_definitions}${_include_directories}\
     ${_compile_flags}${_compile_options}\n")
endfunction()

function(_pch_get_directory _result _target)
  set(${_result} ${CMAKE_BINARY_DIR}/pch/${_target} PARENT_SCOPE)
endfunction()

function(_pch_get_stub_source _result _target)
  _pch_get_directory(_directory ${_target})
  set(${_result} ${_directory}/stub.cpp PARENT_SCOPE)
endfunction()

function(_pch_get_pch_target _result _target)
  set(${_result} _pch_${_target} PARENT_SCOPE)
endfunction()

function(_pch_get_full_header_path _result _header)
  get_property(_includes DIRECTORY PROPERTY INCLUDE_DIRECTORIES)
  find_path(_header_path ${_header} ${_includes})
  set(${_result} ${_header_path}/${_header} PARENT_SCOPE)
endfunction()

function(_pch_get_full_pch_path _result _target _header)
  if("${CMAKE_CXX_COMPILER_ID}" STREQUAL "Clang")
    set(_suffix ".pch")
  elseif("${CMAKE_CXX_COMPILER_ID}" STREQUAL "GNU")
    set(_suffix ".gch")
  else()
    error("${CMAKE_CXX_COMPILER_ID} is not supported")
  endif()
  _pch_get_directory(_directory ${_target})
  set(${_result} ${_directory}/include/${_header}${_suffix} PARENT_SCOPE)
endfunction()

function(_pch_add_dependency_stub _target _header)
  _pch_get_pch_target(_pch_target ${_target})
  _pch_get_directory(_directory ${_target})
  _pch_get_stub_source(_source ${_target})
  separate_arguments(_command UNIX_COMMAND
    "mkdir -p ${_directory} && \
     printf \\\"#include <${_header}>\\\\nint main() { return 0; }\\\" 
        > ${_source}")
  add_custom_command(OUTPUT ${_source} COMMAND ${_command})
  add_executable(${_pch_target} EXCLUDE_FROM_ALL ${_source})
  set_target_properties(${_pch_target}
    PROPERTIES RUNTIME_OUTPUT_DIRECTORY ${_directory})
endfunction()

function(_pch_add_pch _target _header)
  _pch_add_dependency_stub(${_target} ${_header})
  _pch_get_directory(_directory ${_target})


  _pch_get_pch_target(_pch_target ${_target})
  _pch_get_full_header_path(_full_header_path ${_header})
  _pch_get_full_pch_path(_pch ${_target} ${_header})
  set(_flags_file ${_directory}/compile_flags.txt)
  _pch_write_target_flags(${_flags_file} ${_target})

  separate_arguments(_build_pch UNIX_COMMAND
    "mkdir -p `dirname ${_pch}` && \
    sed -i s/-include-pch.*// ${_flags_file} && \
     ${CMAKE_CXX_COMPILER} @${_flags_file} \
     -x c++-header -o ${_pch} ${_full_header_path}")

  add_custom_command(TARGET ${_pch_target} PRE_BUILD 
    COMMAND ${_build_pch} BYPRODUCTS ${_pch})
endfunction()

function(use_precompiled_header _target _header)
  _pch_add_pch(${_target} ${_header})

  _pch_get_full_pch_path(_pch ${_target} ${_header})
  _pch_get_pch_target(_pch_target ${_target})
  add_dependencies(${_target} ${_pch_target})

  get_property(_sources TARGET ${_target} PROPERTY SOURCES)
  set_source_files_properties(${_sources}
    PROPERTIES OBJECT_DEPENDS ${_pch})

  _pch_get_directory(_directory ${_target})
  target_include_directories(${_target} BEFORE PUBLIC ${_directory}/include)

  if("${CMAKE_CXX_COMPILER_ID}" STREQUAL "Clang")
    set_target_properties(${_target}
      PROPERTIES COMPILE_FLAGS "-include-pch ${_pch}")
  endif()
endfunction()
