#!/bin/bash

# OpenCV deposu ve versiyon bilgileri
SCRIPT_REPO="https://github.com/opencv/opencv.git"
SCRIPT_CONTRIB_REPO="https://github.com/opencv/opencv_contrib.git"
SCRIPT_COMMIT="5.x"  # OpenCV'nin 5.x sürümünü kullanıyoruz

# Bu fonksiyon tüm hedefler için etkin
ffbuild_enabled() {
    return 0
}

# Gerekli dosyaları indirir
ffbuild_dockerdl() {
    echo "OpenCV kaynak kodu indiriliyor..."
    git clone --depth 1 --branch "$SCRIPT_COMMIT" "$SCRIPT_REPO" opencv
    git clone --depth 1 --branch "$SCRIPT_COMMIT" "$SCRIPT_CONTRIB_REPO" opencv_contrib
    echo "OpenCV indirildi."
}

# OpenCV'yi yapılandırır ve derler
ffbuild_dockerbuild() {
    echo "Bağımlılıklar kuruluyor..."
    apt-get update && apt-get install -y --no-install-recommends \
        build-essential cmake pkg-config wget unzip \
        libjpeg-turbo8-dev libpng-dev libtiff-dev \
        libavcodec-dev libavformat-dev libswscale-dev \
        libxvidcore-dev libx264-dev libgtk-3-dev libatlas-base-dev \
        gfortran python3-dev python3-numpy libfreetype6-dev \
        libharfbuzz-dev libcurl4-openssl-dev libssl-dev && \
        rm -rf /var/lib/apt/lists/*

    echo "OpenCV yapılandırılıyor..."
    local myconf=(
        -D CMAKE_BUILD_TYPE=Release
        -D CMAKE_INSTALL_PREFIX=/usr/local
        -D BUILD_SHARED_LIBS=OFF
        -D BUILD_EXAMPLES=OFF
        -D BUILD_TESTS=OFF
        -D BUILD_PERF_TESTS=OFF
        -D WITH_FFMPEG=ON
        -D WITH_OPENMP=ON
        -D WITH_IPP=OFF
        -D WITH_PROTOBUF=OFF
        -D ENABLE_CXX11=ON
        -D OPENCV_EXTRA_MODULES_PATH="../opencv_contrib/modules"
        -D OPENCV_ENABLE_PKG_CONFIG=ON
        -D OPENCV_GENERATE_PKGCONFIG=ON
    )

    # Hedef platforma göre ek ayarlar
    case "$TARGET" in
        win64|win32)
            myconf+=(
                -D CMAKE_SYSTEM_NAME=Windows
                -D CMAKE_C_COMPILER="$FFBUILD_TOOLCHAIN/gcc"
                -D CMAKE_CXX_COMPILER="$FFBUILD_TOOLCHAIN/g++"
            )
            ;;
        linux64|linuxarm64)
            myconf+=(
                -D CMAKE_SYSTEM_NAME=Linux
                -D CMAKE_C_COMPILER=gcc
                -D CMAKE_CXX_COMPILER=g++
            )
            ;;
        *)
            echo "Bilinmeyen hedef: $TARGET"
            return 1
            ;;
    esac

    # Derleme ayarları
    export CFLAGS="$CFLAGS -fno-strict-aliasing"
    export CXXFLAGS="$CXXFLAGS -fno-strict-aliasing"

    # Yapılandırma ve derleme
    mkdir -p opencv/build
    cd opencv/build
    cmake .. "${myconf[@]}"

    echo "OpenCV derleniyor..."
    make -j$(nproc)
    make install
    echo "OpenCV kurulumu tamamlandı."
}

# Yapılandırma ve devre dışı bırakma işlemleri
ffbuild_configure() {
    [[ $TARGET == win* ]] && return 0
    echo --enable-libopencv
}

ffbuild_unconfigure() {
    echo --disable-libopencv
}
