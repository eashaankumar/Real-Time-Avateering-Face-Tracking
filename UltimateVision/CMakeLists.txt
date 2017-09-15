cmake_minimum_required(VERSION 2.8)


project(ultimate_vision)

#add_subdirectory(src)
set(ALL_SOURCES 
	src/main.cpp)

#Exe
add_executable(${PROJECT_NAME} ${ALL_SOURCES})

target_link_libraries(${PROJECT_NAME} PUBLIC "C:/Users/Eashaan Kumar/Documents/MyCppCode/DestBuild/Debug/dest.lib")
target_include_directories(${PROJECT_NAME} PUBLIC "C:/Users/Eashaan Kumar/Documents/MyCppCode/dest-0.8/inc")
target_include_directories(${PROJECT_NAME} PUBLIC "C:/Users/Eashaan Kumar/Documents/MyCppCode/DestBuild")

#Eigen
find_package(Eigen3 REQUIRED)
message(STATUS ${EIGEN3_INCLUDE_DIRS})
target_include_directories(${PROJECT_NAME} PUBLIC ${EIGEN3_INCLUDE_DIRS})

#flat_buffers
target_include_directories(${PROJECT_NAME} PUBLIC "C:/Users/Eashaan Kumar/Documents/MyCppCode/dest-0.8/ext")

#opencv
#set(OpenCV_INCLUDE_DIRS "C:/opencv3/sources/include")
find_package(OpenCV REQUIRED COMPONENTS calib3d core features2d flann highgui imgcodecs imgproc ml objdetect photo shape stitching superres video videoio videostab)
message(STATUS "OpenCV library status:")
message(STATUS "    version: ${OpenCV_VERSION}")
message(STATUS "    libraries: ${OpenCV_LIBS}")
message(STATUS "    include path: ${OpenCV_INCLUDE_DIRS}")
target_include_directories(${PROJECT_NAME} PUBLIC ${OpenCV_INCLUDE_DIRS})
target_link_libraries(${PROJECT_NAME} PUBLIC ${OpenCV_LIBS})


