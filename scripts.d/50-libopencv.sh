#!/bin/bash

SCRIPT_REPO="https://github.com/opencv/opencv.git"
SCRIPT_COMMIT="5.x"
SCRIPT_TAGFILTER="5.x"

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
	echo "Bağımlılıklar kuruluyor..."
	apt-get update && apt-get install -y --no-install-recommends \
			build-essential cmake pkg-config wget unzip \
			libjpeg-turbo8-dev libpng-dev libtiff-dev \
			libavcodec-dev libavformat-dev libswscale-dev \
			libxvidcore-dev libx264-dev libgtk-3-dev libatlas-base-dev \
			gfortran python3-dev python3-numpy libfreetype6-dev \
			libharfbuzz-dev libcurl4-openssl-dev libssl-dev && \
			rm -rf /var/lib/apt/lists/*
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
    case "$TARGET" in
        win64|win32)
            myconf+=(
                -DCMAKE_SYSTEM_NAME=Windows
                -DCMAKE_C_COMPILER="$FFBUILD_TOOLCHAIN/gcc"
                -DCMAKE_CXX_COMPILER="$FFBUILD_TOOLCHAIN/g++"
            )
            ;;
        linux64|linuxarm64)
            myconf+=(
                -DCMAKE_SYSTEM_NAME=Linux
                -DCMAKE_C_COMPILER="$FFBUILD_TOOLCHAIN/gcc"
                -DCMAKE_CXX_COMPILER="$FFBUILD_TOOLCHAIN/g++"
            )
            ;;
        *)
            echo "Unknown target: $TARGET"
            return 1
            ;;
    esac

    # Derleme ayarları
    export CFLAGS="$CFLAGS -fno-strict-aliasing"
    export CXXFLAGS="$CXXFLAGS -fno-strict-aliasing"

    # OpenCV derleme için uygun C ve C++ derleyicilerini ayarlayalım
    export CC="${CC/${FFBUILD_CROSS_PREFIX}/}"
    export CXX="${CXX/${FFBUILD_CROSS_PREFIX}/}"
    export AR="${AR/${FFBUILD_CROSS_PREFIX}/}"
    export RANLIB="${RANLIB/${FFBUILD_CROSS_PREFIX}/}"

    # OpenCV için pkg-config desteği ekliyoruz
    PKG_CONFIG_PATH="$FFBUILD_PREFIX/lib/pkgconfig"
    mkdir -p "$PKG_CONFIG_PATH"
    cat > "$PKG_CONFIG_PATH/opencv.pc" <<EOF
prefix=$FFBUILD_PREFIX
exec_prefix=\${prefix}
libdir=\${exec_prefix}/lib
includedir=\${prefix}/include

Name: OpenCV
Description: OpenCV - Open Source Computer Vision Library
Version: 5.x
Cflags: -I\${includedir}
Libs: -L\${libdir} -lopencv_core -lopencv_imgproc -lopencv_highgui
EOF

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
