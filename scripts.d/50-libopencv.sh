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
        -DCMAKE_BUILD_TYPE=Release
        -DCMAKE_INSTALL_PREFIX="$FFBUILD_PREFIX"
        -DBUILD_SHARED_LIBS=OFF
        -DBUILD_EXAMPLES=OFF
        -DBUILD_TESTS=OFF
        -DBUILD_PERF_TESTS=OFF
        -DWITH_FFMPEG=ON
        -DWITH_OPENMP=ON
        -DWITH_IPP=OFF
        -DWITH_PROTOBUF=OFF
        -DENABLE_CXX11=ON
        -DBUILD_PKG_CONFIG=ON
        -DOPENCV_ENABLE_PKG_CONFIG=ON  # pkg-config desteğini etkinleştiriyoruz
        -DOPENCV_GENERATE_PKGCONFIG=ON  # opencv.pc dosyasının oluşturulmasını sağlıyoruz
        -DCMAKE_TOOLCHAIN_FILE="$FFBUILD_CMAKE_TOOLCHAIN"
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

    # OpenCV için pkg-config desteği ekliyoruz
    echo "prefix=$FFBUILD_PREFIX" > "$FFBUILD_PREFIX/lib/pkgconfig/opencv.pc"
    echo "exec_prefix=\${prefix}" >> "$FFBUILD_PREFIX/lib/pkgconfig/opencv.pc"
    echo "libdir=\${exec_prefix}/lib" >> "$FFBUILD_PREFIX/lib/pkgconfig/opencv.pc"
    echo "includedir=\${prefix}/include" >> "$FFBUILD_PREFIX/lib/pkgconfig/opencv.pc"
    echo >> "$FFBUILD_PREFIX/lib/pkgconfig/opencv.pc"
    echo "Name: OpenCV" >> "$FFBUILD_PREFIX/lib/pkgconfig/opencv.pc"
    echo "Description: OpenCV - Open Source Computer Vision Library" >> "$FFBUILD_PREFIX/lib/pkgconfig/opencv.pc"
    echo "Version: 9999" >> "$FFBUILD_PREFIX/lib/pkgconfig/opencv.pc"
    echo "Cflags: -I\${includedir}" >> "$FFBUILD_PREFIX/lib/pkgconfig/opencv.pc"
    
    # Platform bazlı linkleme ayarları
    if [[ $TARGET == linux* ]]; then
        echo "Libs: -L\${libdir} -lopencv_core -lopencv_imgproc -lopencv_highgui" >> "$FFBUILD_PREFIX/lib/pkgconfig/opencv.pc"
    elif [[ $TARGET == win* ]]; then
        echo "Libs: -L\${libdir} -lopencv_core -lopencv_imgproc -lopencv_highgui" >> "$FFBUILD_PREFIX/lib/pkgconfig/opencv.pc"
        echo "Libs.private: -l:opencv_core.a -l:opencv_imgproc.a -l:opencv_highgui.a" >> "$FFBUILD_PREFIX/lib/pkgconfig/opencv.pc"
    fi
    
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
