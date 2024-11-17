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
    # Gerekli bağımlılıkları kur
    apt-get update && apt-get install -y --no-install-recommends \
        build-essential cmake pkg-config wget unzip \
        libjpeg-turbo8-dev libpng-dev libtiff-dev \
        libavcodec-dev libavformat-dev libswscale-dev \
        libxvidcore-dev libx264-dev libgtk2.0-dev libatlas-base-dev \
        gfortran python3-dev python3-numpy

    # `pkg-config` dosyasını oluştur
    ffbuild_generate_pkgconfig

    # Derleme seçeneklerini tanımla
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
	
	# Derleme ayarları
    export CFLAGS="$CFLAGS -fno-strict-aliasing"
    export CXXFLAGS="$CXXFLAGS -fno-strict-aliasing"

    # OpenCV derleme için uygun C ve C++ derleyicilerini ayarlayalım
    export CC="${CC/${FFBUILD_CROSS_PREFIX}/}"
    export CXX="${CXX/${FFBUILD_CROSS_PREFIX}/}"
    export AR="${AR/${FFBUILD_CROSS_PREFIX}/}"
    export RANLIB="${RANLIB/${FFBUILD_CROSS_PREFIX}/}"

    # OpenCV için pkg-config desteği ekliyoruz
    mkdir -p "$FFBUILD_PREFIX/lib/pkgconfig"
    echo "prefix=$FFBUILD_PREFIX" > "$FFBUILD_PREFIX/lib/pkgconfig/opencv.pc"
    echo "exec_prefix=\${prefix}" >> "$FFBUILD_PREFIX"
    echo "libdir=\${exec_prefix}/lib" >> "$FFBUILD_PREFIX/lib"
    echo "includedir=\${prefix}/include" >> "$FFBUILD_PREFIX/include/opencv4"
    echo >> "$FFBUILD_PREFIX/lib/pkgconfig/opencv.pc"
    echo "Name: OpenCV" >> "$FFBUILD_PREFIX/lib/pkgconfig/opencv.pc"
    echo "Description: OpenCV - Open Source Computer Vision Library" >> "$FFBUILD_PREFIX/lib/pkgconfig/opencv.pc"
    echo "Version: 9999" >> "$FFBUILD_PREFIX/lib/pkgconfig/opencv.pc"
    echo "Cflags: -I\${includedir}" >> "$FFBUILD_PREFIX/lib/pkgconfig/opencv.pc"

    # Platform bazlı linkleme ayarları
    if [[ $TARGET == linux* ]]; then
        echo "Libs: -L\${libdir} -lopencv_core -lopencv_imgproc -lopencv_highgui -lopencv_videoio -lopencv_imgcodecs -lopencv_objdetect -lopencv_video -lopencv_calib3d -lopencv_features2d -lopencv_dnn -lopencv_ml -lopencv_stitching -lopencv_photo -lopencv_flann" >> "$FFBUILD_PREFIX/lib/pkgconfig/opencv.pc"
		echo "Libs.private: -ldl -lm -lpthread -lrt" >> "$FFBUILD_PREFIX/lib/pkgconfig/opencv.pc"
		echo "Cflags: -I\$\"$FFBUILD_PREFIX/include/opencv4" >> "$FFBUILD_PREFIX/lib/pkgconfig/opencv.pc"
    elif [[ $TARGET == win* ]]; then
        echo "Libs: -L\${libdir} -lopencv_core -lopencv_imgproc -lopencv_highgui -lopencv_videoio -lopencv_imgcodecs -lopencv_objdetect -lopencv_video -lopencv_calib3d -lopencv_features2d -lopencv_dnn -lopencv_ml -lopencv_stitching -lopencv_photo -lopencv_flann" >> "$FFBUILD_PREFIX/lib/pkgconfig/opencv.pc"
        echo "Libs.private: -l:opencv_core.a -l:opencv_imgproc.a -l:opencv_highgui.a -l:opencv_videoio.a -l:opencv_imgcodecs.a -l:opencv_objdetect.a -l:opencv_video.a -l:opencv_calib3d.a -l:opencv_features2d.a -l:opencv_dnn.a -l:opencv_ml.a -l:opencv_stitching.a -l:opencv_photo.a -l:opencv_flann.a" >> "$FFBUILD_PREFIX/lib/pkgconfig/opencv.pc"
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
