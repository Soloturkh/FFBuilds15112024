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
        gfortran python3-dev python3-numpy libopencv-dev

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

    # Build dizini oluştur
    mkdir -p build
    cd build

    # CMake ile yapılandırma işlemi
    cmake .. "${myconf[@]}"

    # Derleme ve yükleme işlemleri
    make -j$(nproc)
    make install

    # OpenCV için pkg-config desteği ekliyoruz
    mkdir -p "$FFBUILD_PREFIX/lib/pkgconfig"
    echo "prefix=$FFBUILD_PREFIX" > opencv.pc
    echo "exec_prefix=\${prefix}" >> opencv.pc
    echo "libdir=\${exec_prefix}/lib" >> opencv.pc
    echo "includedir=\${prefix}/include" >> opencv.pc
    echo >> opencv.pc
    echo "Name: OpenCV" >> opencv.pc
    echo "Description: Open Source Computer Vision Library" >> opencv.pc
    echo "Version: 4.5.4" >> opencv.pc

    if [[ $TARGET == linux* ]]; then
		echo "Libs: -L\${exec_prefix}/lib/x86_64-linux-gnu -lopencv_stitching -lopencv_alphamat -lopencv_aruco -lopencv_barcode -lopencv_bgsegm -lopencv_bioinspired -lopencv_ccalib -lopencv_dnn_objdetect -lopencv_dnn_superres -lopencv_dpm -lopencv_face -lopencv_freetype -lopencv_fuzzy -lopencv_hdf -lopencv_hfs -lopencv_img_hash -lopencv_intensity_transform -lopencv_line_descriptor -lopencv_mcc -lopencv_quality -lopencv_rapid -lopencv_reg -lopencv_rgbd -lopencv_saliency -lopencv_shape -lopencv_stereo -lopencv_structured_light -lopencv_phase_unwrapping -lopencv_superres -lopencv_optflow -lopencv_surface_matching -lopencv_tracking -lopencv_highgui -lopencv_datasets -lopencv_text -lopencv_plot -lopencv_ml -lopencv_videostab -lopencv_videoio -lopencv_viz -lopencv_wechat_qrcode -lopencv_ximgproc -lopencv_video -lopencv_xobjdetect -lopencv_objdetect -lopencv_calib3d -lopencv_imgcodecs -lopencv_features2d -lopencv_dnn -lopencv_flann -lopencv_xphoto -lopencv_photo -lopencv_imgproc -lopencv_core" >> opencv.pc
		echo "Libs.private: -ldl -lm -lpthread -lrt" >> opencv.pc
		echo "Cflags: -I\${includedir}" >> opencv.pc
    elif [[ $TARGET == win* ]]; then
        echo "Libs: -L\${libdir} -l:opencv.a" >> opencv.pc
        echo "Libs.private: -lole32 -lshlwapi -lcfgmgr32" >> opencv.pc
    fi

    cp opencv.pc "$FFBUILD_PREFIX"/lib/pkgconfig/opencv.pc
    mv opencv.pc "$FFBUILD_PREFIX"/lib/pkgconfig/opencv4.pc
}

ffbuild_configure() {
    # win* hedefleri için libopencv'yi etkinleştir
    [[ $TARGET == win* ]] && return 0
    echo --enable-libopencv
}

ffbuild_unconfigure() {
    echo --disable-libopencv
}
