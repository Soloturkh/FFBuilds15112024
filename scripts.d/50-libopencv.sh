#!/bin/bash
SCRIPT_REPO="https://github.com/opencv/opencv.git"
SCRIPT_COMMIT="4.10.0"
#SCRIPT_COMMIT="71d3237a093b60a27601c20e9ee6c3e52154e8b1"
OPENCV_VERSION="4.10.0"

ffbuild_enabled() {
    return 0
}

ffbuild_dockerdl() {
	default_dl .
    echo "git submodule update --init --recursive --depth=1"
	if [ ! -d "opencv_contrib" ]; then
		echo "git clone --branch \${OPENCV_VERSION} https://github.com/opencv/opencv_contrib.git"
	fi
}

ffbuild_dockerbuild() {
    sudo apt update && sudo apt install -y --no-install-recommends \
    build-essential cmake git unzip pkg-config \
    libjpeg-dev libpng-dev libtiff-dev \
    libavcodec-dev libavformat-dev libswscale-dev \
    libv4l-dev libxvidcore-dev libx264-dev \
    libgtk-3-dev libcanberra-gtk* libatlas-base-dev gfortran \
    python3-dev python3-numpy
	
    mkdir build && cd build

    cmake -DCMAKE_TOOLCHAIN_FILE="$FFBUILD_CMAKE_TOOLCHAIN" \
          -DCMAKE_BUILD_TYPE=Release \
          -DCMAKE_INSTALL_PREFIX="$FFBUILD_PREFIX" \
          -DOPENCV_EXTRA_MODULES_PATH=../opencv_contrib/modules \
          -DENABLE_PRECOMPILED_HEADERS=OFF \
		  -DBUILD_SHARED_LIBS=OFF \
          -DBUILD_EXAMPLES=OFF \
          -DBUILD_TESTS=OFF \
          -DBUILD_PERF_TESTS=OFF \
          -DWITH_FFMPEG=ON \
          -DWITH_OPENMP=ON \
          -DWITH_IPP=OFF \
          -DWITH_PROTOBUF=OFF \
          -DENABLE_CXX11=ON \
          -DBUILD_PKG_CONFIG=ON \
          -DOPENCV_ENABLE_PKG_CONFIG=ON \
          -DOPENCV_GENERATE_PKGCONFIG=ON \
          -DBUILD_EXAMPLES=ON ..
    make -j$(nproc)
    make install
    sudo ldconfig

#cat <<EOF >opencv4.pc
#prefix=$FFBUILD_PREFIX
#exec_prefix=\${prefix}
#libdir=\${exec_prefix}/lib
#includedir=\${prefix}/include/opencv4
#
#Name: OpenCV
#Description: Open Source Computer Vision Library
#Version: $OPENCV_VERSION
#Libs: -L\${exec_prefix}/lib -lopencv_gapi -lopencv_stitching -lopencv_aruco -lopencv_bgsegm -lopencv_bioinspired -lopencv_ccalib -lopencv_dnn_objdetect -lopencv_dnn_superres -lopencv_dpm -lopencv_face -lopencv_freetype -lopencv_fuzzy -lopencv_hfs -lopencv_img_hash -lopencv_intensity_transform -lopencv_line_descriptor -lopencv_mcc -lopencv_quality -lopencv_rapid -lopencv_reg -lopencv_rgbd -lopencv_saliency -lopencv_stereo -lopencv_structured_light -lopencv_phase_unwrapping -lopencv_superres -lopencv_optflow -lopencv_surface_matching -lopencv_tracking -lopencv_highgui -lopencv_datasets -lopencv_text -lopencv_plot -lopencv_videostab -lopencv_videoio -lopencv_wechat_qrcode -lopencv_xfeatures2d -lopencv_shape -lopencv_ml -lopencv_ximgproc -lopencv_video -lopencv_xobjdetect -lopencv_objdetect -lopencv_calib3d -lopencv_imgcodecs -lopencv_features2d -lopencv_dnn -lopencv_flann -lopencv_xphoto -lopencv_photo -lopencv_imgproc -lopencv_core
#Libs.private: -L\${exec_prefix}/lib/opencv4/3rdparty -lade -littnotify -llibwebp -llibopenjp2 -lIlmImf -lquirc -L/usr/lib/x86_64-linux-gnu -ljpeg -lpng -ltiff -lz -L/usr/lib/gcc/x86_64-linux-gnu/11 -lgomp -lpthread -lfreetype -lharfbuzz -lIconv::Iconv -ldl -lm -lrt
#Cflags: -I\${includedir}
#EOF
    
    echo "OpenCV versiyonu kontrol ediliyor..."
    pkg-config --modversion opencv4 || echo "PKG_CONFIG_PATH ayarlarını kontrol edin."
    echo "OpenCV ${OPENCV_VERSION} başarıyla kuruldu!"
}

ffbuild_configure() {
    echo --enable-libopencv
}

ffbuild_unconfigure() {
    echo --disable-libopencv
}
