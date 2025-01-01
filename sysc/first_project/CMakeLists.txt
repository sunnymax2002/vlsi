cmake_minimum_required(VERSION 3.0)

project(FirstSystemCProject)

# Set the SystemC include and library directories
set(SYSTEMC_INCLUDE_DIR $ENV{SYSTEMC_HOME}/include)
set(SYSTEMC_LIBRARY_DIR $ENV{SYSTEMC_HOME}/lib)

# Add the executable
add_executable(first_systemc main.cpp)

# Link against SystemC
target_include_directories(first_systemc PRIVATE ${SYSTEMC_INCLUDE_DIR})
target_link_libraries(first_systemc ${SYSTEMC_LIBRARY_DIR}/libsystemc.so)
