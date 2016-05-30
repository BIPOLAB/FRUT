# Copyright (c) 2016 Alain Martin
#
# Permission is hereby granted, free of charge, to any person obtaining a copy
# of this software and associated documentation files (the "Software"), to deal
# in the Software without restriction, including without limitation the rights
# to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
# copies of the Software, and to permit persons to whom the Software is
# furnished to do so, subject to the following conditions:
#
# The above copyright notice and this permission notice shall be included in all
# copies or substantial portions of the Software.
#
# THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
# IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
# FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
# AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
# LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
# OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE
# SOFTWARE.


function(jucer_project_begin project_name)

  project(${project_name})
  set(JUCER_PROJECT_NAME ${project_name} PARENT_SCOPE)

endfunction()


function(jucer_project_files)

  list(APPEND JUCER_PROJECT_SOURCES ${ARGN})
  set(JUCER_PROJECT_SOURCES ${JUCER_PROJECT_SOURCES} PARENT_SCOPE)

endfunction()


function(jucer_project_module module_name PATH_TAG module_path)

  list(APPEND JUCER_PROJECT_MODULES ${module_name})
  set(JUCER_PROJECT_MODULES ${JUCER_PROJECT_MODULES} PARENT_SCOPE)

  list(APPEND JUCER_PROJECT_INCLUDE_DIRS "${module_path}")
  set(JUCER_PROJECT_INCLUDE_DIRS ${JUCER_PROJECT_INCLUDE_DIRS} PARENT_SCOPE)

  set(module_header_file "${module_path}/${module_name}/${module_name}.h")

  file(STRINGS "${module_header_file}" osx_frameworks_line REGEX "OSXFrameworks:")
  string(REPLACE "OSXFrameworks:" "" osx_frameworks_line "${osx_frameworks_line}")
  string(REPLACE " " ";" osx_frameworks "${osx_frameworks_line}")
  list(APPEND JUCER_PROJECT_OSX_FRAMEWORKS ${osx_frameworks})
  set(JUCER_PROJECT_OSX_FRAMEWORKS ${JUCER_PROJECT_OSX_FRAMEWORKS} PARENT_SCOPE)

endfunction()


function(jucer_project_end)

  foreach(module_name ${JUCER_PROJECT_MODULES})
    string(CONCAT module_available_defines
      "${module_available_defines}"
      "#define JUCE_MODULE_AVAILABLE_${module_name} 1\n"
    )
  endforeach()
  configure_file("${JUCE.cmake_ROOT}/cmake/AppConfig.h" "JuceLibraryCode/AppConfig.h")

  foreach(module_name ${JUCER_PROJECT_MODULES})
    string(CONCAT modules_includes
      "${modules_includes}"
      "#include <${module_name}/${module_name}.h>\n"
    )
  endforeach()
  configure_file("${JUCE.cmake_ROOT}/cmake/JuceHeader.h" "JuceLibraryCode/JuceHeader.h")

  foreach(module_name ${JUCER_PROJECT_MODULES})
    if(APPLE)
      set(extension "mm")
    else()
      set(extension "cpp")
    endif()
    configure_file("${JUCE.cmake_ROOT}/cmake/ModuleWrapper.cpp"
      "JuceLibraryCode/${module_name}.${extension}")
    list(APPEND modules_sources
      "${CMAKE_CURRENT_BINARY_DIR}/JuceLibraryCode/${module_name}.${extension}")
  endforeach()

  add_executable(${JUCER_PROJECT_NAME} WIN32 MACOSX_BUNDLE
    ${JUCER_PROJECT_SOURCES}
    ${modules_sources}
  )

  target_include_directories(${JUCER_PROJECT_NAME} PRIVATE
    "${CMAKE_CURRENT_BINARY_DIR}/JuceLibraryCode"
    ${JUCER_PROJECT_INCLUDE_DIRS}
  )

  if(APPLE)
    target_compile_options(${JUCER_PROJECT_NAME} PRIVATE -std=c++11)
    target_compile_definitions(${JUCER_PROJECT_NAME} PRIVATE
      $<$<CONFIG:Debug>:_DEBUG>
    )

    list(REMOVE_DUPLICATES JUCER_PROJECT_OSX_FRAMEWORKS)
    foreach(framework_name ${JUCER_PROJECT_OSX_FRAMEWORKS})
      find_library(${framework_name}_framework ${framework_name})
      target_link_libraries(${JUCER_PROJECT_NAME}
        "${${framework_name}_framework}"
      )
    endforeach()
  endif()

endfunction()
