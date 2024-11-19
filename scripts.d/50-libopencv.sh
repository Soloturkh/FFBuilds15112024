#!/bin/bash

SCRIPT_REPO="https://github.com/opencv/opencv.git"
SCRIPT_COMMIT="4.x"
SCRIPT_TAGFILTER="4.x"

ffbuild_enabled() {
    return 0
}

ffbuild_dockerdl() {
    default_dl .
    git submodule update --init --recursive --depth=1
}

ffbuild_dockerbuild() {
    # Gerekli bağımlılıkların kurulumu
    apt-get update && apt-get install -y --no-install-recommends \
        build-essential cmake pkg-config wget unzip \
        libjpeg-turbo8-dev libpng-dev libtiff-dev \
        libavcodec-dev libavformat-dev libswscale-dev \
        libxvidcore-dev libx264-dev libgtk2.0-dev libatlas-base-dev \
        gfortran python3-dev python3-numpy

    # OpenCV derleme yapılandırması
    local myconf=(
        -D CMAKE_BUILD_TYPE=Release
        -D CMAKE_INSTALL_PREFIX="$FFBUILD_PREFIX"
        -D BUILD_SHARED_LIBS=OFF
        -D BUILD_EXAMPLES=OFF
        -D BUILD_TESTS=OFF
        -D BUILD_PERF_TESTS=OFF
        -D WITH_FFMPEG=ON
        -D WITH_OPENMP=ON
        -D WITH_IPP=OFF
        -D WITH_PROTOBUF=OFF
        -D ENABLE_CXX11=ON
        -D BUILD_PKG_CONFIG=ON
        -D OPENCV_ENABLE_PKG_CONFIG=ON
        -D OPENCV_GENERATE_PKGCONFIG=ON
    )

    export CFLAGS="-I$FFBUILD_PREFIX/include/opencv4"
    export CXXFLAGS="-I$FFBUILD_PREFIX/include/opencv4"
    export LDFLAGS="-L$FFBUILD_PREFIX/lib"

    export CC="${CC/${FFBUILD_CROSS_PREFIX}/}"
    export CXX="${CXX/${FFBUILD_CROSS_PREFIX}/}"
    export AR="${AR/${FFBUILD_CROSS_PREFIX}/}"
    export RANLIB="${RANLIB/${FFBUILD_CROSS_PREFIX}/}"

    mkdir -p build && cd build
    cmake .. "${myconf[@]}"
    make -j$(nproc)
    make install

    # Pkg-config dosyasının oluşturulması
    mkdir -p "$FFBUILD_PREFIX/lib/pkgconfig"
    cat <<EOF >opencv.pc
prefix=$FFBUILD_PREFIX
exec_prefix=\${prefix}
libdir=\${exec_prefix}/lib
includedir=\${prefix}/include

Name: OpenCV
Description: Open Source Computer Vision Library
Version: 4.5.4
Libs: -L\${libdir} -lopencv_core -lopencv_imgproc -lopencv_imgcodecs -lopencv_highgui
Libs.private: -ldl -lm -lpthread -lrt
Cflags: -I\${includedir}
EOF

    cp opencv.pc "$FFBUILD_PREFIX/lib/pkgconfig/opencv4.pc"
}

ffbuild_configure() {
    [[ $TARGET == win* ]] && return 0
    echo --enable-libopencv
}

ffbuild_unconfigure() {
    echo --disable-libopencv
}
