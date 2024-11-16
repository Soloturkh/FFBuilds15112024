#!/bin/bash

SCRIPT_REPO="https://github.com/opencv/opencv.git"
SCRIPT_COMMIT="4.x"
SCRIPT_REPO_CONTRIB="https://github.com/opencv/opencv_contrib.git"

ffbuild_enabled() {
    return 0
}

ffbuild_dockerdl() {
    echo "Cloning OpenCV repositories..."
    git clone --depth=1 -b "$SCRIPT_COMMIT" "$SCRIPT_REPO" opencv
    git clone --depth=1 -b "$SCRIPT_COMMIT" "$SCRIPT_REPO_CONTRIB" opencv_contrib
}

ffbuild_dockerbuild() {
    echo "Building OpenCV..."
    cd opencv
    mkdir -p build && cd build

    cmake -DCMAKE_TOOLCHAIN_FILE="$FFBUILD_CMAKE_TOOLCHAIN" \
          -DCMAKE_BUILD_TYPE=Release \
          -DCMAKE_INSTALL_PREFIX="$FFBUILD_PREFIX" \
          -DBUILD_SHARED_LIBS=OFF \
          -DBUILD_EXAMPLES=OFF \
          -DBUILD_TESTS=OFF \
          -DBUILD_PERF_TESTS=OFF \
          -DWITH_FFMPEG=ON \
          -DWITH_OPENMP=ON \
          -DWITH_IPP=OFF \
          -DWITH_PROTOBUF=OFF \
          -DOPENCV_EXTRA_MODULES_PATH="../opencv_contrib/modules" \
          -DENABLE_CXX11=ON \
          ..

    make -j$(nproc)
    make install

    # pkg-config dosyasını güncelle
    echo "Libs.private: -lm -lpthread -ldl -lz" >> "$FFBUILD_PREFIX"/lib/pkgconfig/opencv4.pc
    echo "Cflags.private: -DOPENCV_STATIC" >> "$FFBUILD_PREFIX"/lib/pkgconfig/opencv4.pc
}

ffbuild_configure() {
    echo --enable-libopencv
}

ffbuild_unconfigure() {
    echo --disable-libopencv
}
