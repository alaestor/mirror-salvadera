cmake_minimum_required(VERSION 3.30)
project(example_hw_qt VERSION 0.1.0 LANGUAGES CXX)
string(TOLOWER ${PROJECT_NAME} EXE_NAME)

###
### SETUP
###

set(CMAKE_CXX_STANDARD 23)
set(CMAKE_CXX_STANDARD_REQUIRED ON)
set(CMAKE_INCLUDE_CURRENT_DIR ON)
set(CMAKE_RUNTIME_OUTPUT_DIRECTORY "${CMAKE_SOURCE_DIR}/build/bin")
set(SRC_DIR "${CMAKE_SOURCE_DIR}")
set(GEN_DIR "${CMAKE_SOURCE_DIR}/build/cppfront_generated")

set(CMAKE_CXX_FLAGS "${CMAKE_CXX_FLAGS} -Wall -Wextra -Wpedantic -Os -fno-rtti")
set(CPPFRONT_FLAGS "-fno-rtti") # https://hsutter.github.io/cppfront/cppfront/options/

set(CMAKE_AUTOUIC ON)
set(CMAKE_AUTOMOC ON)
set(CMAKE_AUTORCC ON)

find_package(Qt6 REQUIRED COMPONENTS Widgets)

###
### COMPILE SOURCES
###

# Transpile cpp2 -> cpp
file(MAKE_DIRECTORY ${GEN_DIR})
file(GLOB CPP2_FILES "${SRC_DIR}/*.cpp2")
foreach(CPP2_FILE ${CPP2_FILES})
  get_filename_component(CPP2_FILE_NAME ${CPP2_FILE} NAME_WE)
  set(CPP_FILE "${GEN_DIR}/${CPP2_FILE_NAME}.cpp")
  add_custom_command(
    OUTPUT ${CPP_FILE}
    COMMAND cppfront ${CPPFRONT_FLAGS} ${CPP2_FILE} -o ${CPP_FILE}
    DEPENDS ${CPP2_FILE}
    COMMENT "Transpiling ${CPP2_FILE}"
  )
  list(APPEND GENERATED_CPP_FILES ${CPP_FILE})
endforeach()

# Combine lists of generated and non-generated cpp files
file(GLOB OTHER_CPP_FILES "${SRC_DIR}/*.cpp")
list(APPEND CPP_SOURCES ${GENERATED_CPP_FILES} ${OTHER_CPP_FILES})

###
### LINK
###

qt_add_executable(${EXE_NAME} MANUAL_FINALIZATION ${CPP_SOURCES})

target_link_libraries(${EXE_NAME}
  PRIVATE
  Qt${QT_VERSION_MAJOR}::Core
  Qt${QT_VERSION_MAJOR}::Widgets
)

qt_finalize_executable(${EXE_NAME})
