#!/bin/bash

SCRIPT_REPO="https://github.com/opencv/opencv.git"
SCRIPT_COMMIT="4.x"
SCRIPT_TAGFILTER="4.x"

ffbuild_enabled() {
    # Burada özel bir kontrol yapılmaz, her hedefe uygun destek sağlanır.
    return 0
}

ffbuild_dockerdl() {
    # Gerekli dosyaların indirilmesi için komut
    default_dl .
    echo "git submodule update --init --recursive --depth=1"
}

ffbuild_dockerbuild() {
    # OpenCV için yapılandırma seçeneklerini belirleyelim
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
        -D OPENCV_ENABLE_PKG_CONFIG=ON  # pkg-config desteğini etkinleştiriyoruz
        -D OPENCV_GENERATE_PKGCONFIG=ON  # opencv.pc dosyasının oluşturulmasını sağlıyoruz
        -D CMAKE_TOOLCHAIN_FILE="$FFBUILD_CMAKE_TOOLCHAIN"
    )

    # Platform bazlı hedef yapılandırmaları ekleyelim
    if [[ $TARGET == win64 ]]; then
        myconf+=(
            -DCMAKE_SYSTEM_NAME=Windows
            -DCMAKE_C_COMPILER="$FFBUILD_TOOLCHAIN/gcc"
            -DCMAKE_CXX_COMPILER="$FFBUILD_TOOLCHAIN/g++"
        )
    elif [[ $TARGET == win32 ]]; then
        myconf+=(
            -DCMAKE_SYSTEM_NAME=Windows
            -DCMAKE_C_COMPILER="$FFBUILD_TOOLCHAIN/gcc"
            -DCMAKE_CXX_COMPILER="$FFBUILD_TOOLCHAIN/g++"
        )
    elif [[ $TARGET == linux64 ]]; then
        myconf+=(
            -DCMAKE_SYSTEM_NAME=Linux
            -DCMAKE_C_COMPILER="$FFBUILD_TOOLCHAIN/gcc"
            -DCMAKE_CXX_COMPILER="$FFBUILD_TOOLCHAIN/g++"
        )
    elif [[ $TARGET == linuxarm64 ]]; then
        myconf+=(
            -DCMAKE_SYSTEM_NAME=Linux
            -DCMAKE_C_COMPILER="$FFBUILD_TOOLCHAIN/gcc"
            -DCMAKE_CXX_COMPILER="$FFBUILD_TOOLCHAIN/g++"
        )
    else
        echo "Unknown target: $TARGET"
        return -1
    fi

    # Derleme ayarları
    export CFLAGS="$CFLAGS -fno-strict-aliasing"
    export CXXFLAGS="$CXXFLAGS -fno-strict-aliasing"

    # OpenCV derleme için uygun C ve C++ derleyicilerini ayarlayalım
    export CC="${CC/${FFBUILD_CROSS_PREFIX}/}"
    export CXX="${CXX/${FFBUILD_CROSS_PREFIX}/}"
    export AR="${AR/${FFBUILD_CROSS_PREFIX}/}"
    export RANLIB="${RANLIB/${FFBUILD_CROSS_PREFIX}/}"

    # Build dizini oluştur
    mkdir -p build
    cd build

    # CMake ile yapılandırma işlemi
    cmake .. "${myconf[@]}"

    # Derleme ve yükleme işlemleri
    make -j$(nproc)
    make install
}

ffbuild_configure() {
    # win* hedefleri için libopencv'yi etkinleştir
    [[ $TARGET == win* ]] && return 0
    echo --enable-libopencv
}

ffbuild_unconfigure() {
    echo --disable-libopencv
}
