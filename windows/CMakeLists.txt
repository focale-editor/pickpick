cmake_minimum_required(VERSION 3.14)
project(pickpick LANGUAGES CXX)
cmake_policy(VERSION 3.14...3.25)

set(PLUGIN_NAME "pickpick_plugin")

add_library(${PLUGIN_NAME} SHARED
  "include/pickpick/pickpick_plugin_c_api.h"
  "pickpick_plugin_c_api.cpp"
  "pickpick_plugin.cpp"
  "pickpick_plugin.h"
)
apply_standard_settings(${PLUGIN_NAME})
set_target_properties(${PLUGIN_NAME} PROPERTIES CXX_VISIBILITY_PRESET hidden)
target_compile_definitions(${PLUGIN_NAME} PRIVATE
  FLUTTER_PLUGIN_IMPL NOMINMAX _WIN32_WINNT=0x0A00)
target_include_directories(${PLUGIN_NAME} INTERFACE
  "${CMAKE_CURRENT_SOURCE_DIR}/include")
target_link_libraries(${PLUGIN_NAME} PRIVATE
  flutter flutter_wrapper_plugin user32 gdi32 dwmapi)
set(pickpick_bundled_libraries "" PARENT_SCOPE)
