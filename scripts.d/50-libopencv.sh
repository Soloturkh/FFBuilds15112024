#!/bin/bash

# OpenCV deposu ve versiyon bilgileri
SCRIPT_REPO="https://github.com/opencv/opencv.git"
SCRIPT_COMMIT="5.x"  # OpenCV'nin 5.x sürümünü kullanıyoruz
SCRIPT_TAGFILTER="5.x"

# Bu fonksiyon tüm hedefler için etkin
ffbuild_enabled() {
    return 0
}

# Gerekli dosyaları indirir
ffbuild_dockerdl() {
    git clone --depth 1 --branch "$SCRIPT_COMMIT" "$SCRIPT_REPO" opencv
    git -C opencv submodule update --init --recursive --depth=1
}

# OpenCV'yi yapılandırır ve derler
ffbuild_dockerbuild() {
    # OpenCV için gerekli bağımlılıkları kur
    apt-get update && apt-get install -y --no-install-recommends \
        build-essential cmake pkg-config wget unzip \
        libjpeg-turbo8-dev libpng-dev libtiff-dev \
        libavcodec-dev libavformat-dev libswscale-dev \
        libxvidcore-dev libx264-dev libgtk2.0-dev libatlas-base-dev \
        gfortran python3-dev python3-numpy libfreetype6-dev \
        libharfbuzz-dev libcurl4-openssl-dev libssl-dev && \
        rm -rf /var/lib/apt/lists/*

    # OpenCV'nin yapılandırması için ayarları tanımla
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
                -D CMAKE_C_COMPILER="$FFBUILD_TOOLCHAIN/gcc"
                -D CMAKE_CXX_COMPILER="$FFBUILD_TOOLCHAIN/g++"
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

    # pkg-config yapılandırması
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

    # Build dizinini oluştur ve yapılandır
    mkdir -p opencv/build
    cd opencv/build
    cmake .. "${myconf[@]}"

    # Derleme ve yükleme işlemleri
    make -j$(nproc)
    make install
}

# Yapılandırma ve devre dışı bırakma işlemleri
ffbuild_configure() {
    [[ $TARGET == win* ]] && return 0
    echo --enable-libopencv
}

ffbuild_unconfigure() {
    echo --disable-libopencv
}
