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

	apt update
	apt upgrade
	
	#Generic tools
	apt install -y build-essential cmake pkg-config unzip yasm git checkinstall
	#image i/o Libs
	apt install -y libjpeg-dev libpng-dev libtiff-dev
	#Video/Audio Libs
	# Install basic codec libraries
	apt install -y libavcodec-dev libavformat-dev libswscale-dev

	# Install GStreamer development libraries
	apt install -y libgstreamer1.0-dev libgstreamer-plugins-base1.0-dev

	# Install additional codec and format libraries
	apt install -y libxvidcore-dev libx264-dev libopus-dev libv4l-dev

	# Install additional audio codec libraries
	apt install -y libmp3lame-dev libvorbis-dev

	# Install FFmpeg (which includes libavresample functionality)
	apt install -y ffmpeg

	# Optional: Install VA-API for hardware acceleration
	apt install -y libva-dev
	
	# Install video capture libraries and utilities
    apt install -y libdc1394-25 libdc1394-dev libxine2-dev libv4l-dev v4l-utils
	
	#Create a symbolic link for video device header
	ln -s /usr/include/libv4l1-videodev.h /usr/include/linux/videodev.h
	
	#GTK lib for the graphical user functionalites coming from OpenCV highghui module
	apt install -y libgtk-3-dev
	#Parallelism library C++ for CPU
	apt install -y libtbb-dev
	#Optimization libraries for OpenCV
	apt install -y libatlas-base-dev gfortran
	#Optional libraries:
	apt install -y libprotobuf-dev protobuf-compiler
	apt install -y libgoogle-glog-dev libgflags-dev
	apt install -y libgphoto2-dev libeigen3-dev libhdf5-dev doxygen
	apt install -y libgtk-3-dev libcanberra-gtk* libatlas-base-dev python3-dev python3-numpy

    mkdir build && cd build
	
	# NVIDIA GPU'nun mevcut olup olmadığını kontrol edin
	# NVIDIA GPU'nun mevcut olup olmadığını kontrol edin
	if command -v nvidia-smi &> /dev/null; then
		echo "NVIDIA GPU algılandı, CUDA desteği ve TBB devre dışı bırakılıyor..."
		GPU_OPTIONS="-DWITH_CUDA=ON \
					  -DWITH_CUDNN=ON \
					  -DOPENCV_DNN_CUDA=ON \
					  -DCUDA_ARCH_BIN=ALL \
					  -DENABLE_FAST_MATH=ON \
					  -DCUDA_FAST_MATH=ON \
					  -DWITH_CUBLAS=ON \
					  -DBUILD_opencv_cudacodec=ON"
		TBB_OPTION="-DWITH_TBB=OFF"  # GPU mevcutsa TBB devre dışı
	else
		echo "NVIDIA GPU algılanmadı, sadece CPU desteği etkinleştiriliyor..."
		GPU_OPTIONS="-DWITH_CUDA=OFF \
					  -DWITH_CUDNN=OFF \
					  -DOPENCV_DNN_CUDA=OFF \
					  -DWITH_CUBLAS=OFF \
					  -DBUILD_opencv_cudacodec=OFF"
		TBB_OPTION="-DWITH_TBB=ON"  # GPU yoksa TBB etkin
	fi

    cmake -DCMAKE_TOOLCHAIN_FILE="$FFBUILD_CMAKE_TOOLCHAIN" \
          -DCMAKE_BUILD_TYPE=Release \
          -DCMAKE_INSTALL_PREFIX="$FFBUILD_PREFIX" \
          -DOPENCV_EXTRA_MODULES_PATH=../opencv_contrib/modules \
          -DENABLE_PRECOMPILED_HEADERS=OFF \
          -DBUILD_EXAMPLES=OFF \
          -DBUILD_TESTS=OFF \
          -DBUILD_PERF_TESTS=OFF \
		   $GPU_OPTIONS \
		   $TBB_OPTION \
          -DWITH_OPENCL=OFF \
          -DWITH_V4L=OFF \
		  -DWITH_FFMPEG=OFF \
		  -DWITH_GSTREAMER=OFF \
          -DWITH_MSMF=OFF \
		  -DWITH_DSHOW=OFF \
		  -DWITH_AVFOUNDATION=OFF \
		  -DWITH_1394=OFF \
          -DWITH_IPP=OFF \
          -DWITH_PROTOBUF=OFF \
          -DENABLE_CXX11=ON \
          -DBUILD_PKG_CONFIG=ON \
          -DOPENCV_ENABLE_PKG_CONFIG=ON \
          -DOPENCV_GENERATE_PKGCONFIG=ON \
          -DOPENCV_PC_FILE_NAME=opencv.pc \
          -DOPENCV_ENABLE_NONFREE=ON \
          -DBUILD_EXAMPLES=OFF \
		  -DINSTALL_PYTHON_EXAMPLES=OFF \
		  -DINSTALL_C_EXAMPLES=OFF \
		  -DBUILD_ZLIB=ON \
		  -DBUILD_SHARED_LIBS=OFF ..
   
    make -j$(nproc)
	make install
    ldconfig
	
	#Include the libs in your environment
	echo "/usr/local/lib" >> /etc/ld.so.conf.d/opencv.conf
	ldconfig
	
	
	# OpenCV'nin başarıyla kurulduğunu kontrol et
	echo "OpenCV versiyonu kontrol ediliyor..."
	PKG_CONFIG_PATH="$FFBUILD_PREFIX/lib/pkgconfig:$PKG_CONFIG_PATH"
	export PKG_CONFIG_PATH

	if pkg-config --modversion opencv; then
		echo "OpenCV ${OPENCV_VERSION} başarıyla kuruldu!"
	else
		echo "OpenCV kurulumunda sorun var. PKG_CONFIG_PATH ayarlarını kontrol edin."
		echo "PKG_CONFIG_PATH: $PKG_CONFIG_PATH"
		exit 1
	fi

	# Pkg-config dosyasını doğru yere kopyalama
	mkdir -p "$FFBUILD_PREFIX/lib/pkgconfig"
	# Eğer hedef dizinde dosya zaten varsa, kopyalama işlemi yapmayalım
	if [ ! -f "$FFBUILD_PREFIX/lib/pkgconfig/opencv.pc" ]; then
		cp "$FFBUILD_PREFIX/lib/pkgconfig/opencv.pc" "$FFBUILD_PREFIX/lib/pkgconfig/"
		echo "opencv.pc başarıyla kopyalandı."
	else
		echo "opencv.pc zaten mevcut, kopyalanmadı."
	fi
	
	cat "$FFBUILD_PREFIX/lib/pkgconfig/opencv.pc"
	
	

}

ffbuild_configure() {
    echo --enable-libopencv
}

ffbuild_unconfigure() {
    echo --disable-libopencv
}
