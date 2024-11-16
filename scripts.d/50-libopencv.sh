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
        --disable-cli
        --enable-static
        --enable-pic
        --disable-avs
        --disable-swscale
        --disable-lavf
        --disable-ffms
        --disable-gpac
        --disable-lsmash
        --extra-asflags="-w-macro-params-legacy"
        --extra-cflags="-Wno-error=incompatible-pointer-types"
        --prefix="$FFBUILD_PREFIX"
    )

    # Platform bazlı hedef yapılandırmaları ekleyelim
    if [[ $TARGET == win64 ]]; then
        myconf+=(
            --host="$FFBUILD_TOOLCHAIN"
            --cross-prefix="$FFBUILD_CROSS_PREFIX"
            mingw64
        )
    elif [[ $TARGET == win32 ]]; then
        myconf+=(
            --host="$FFBUILD_TOOLCHAIN"
            --cross-prefix="$FFBUILD_CROSS_PREFIX"
            mingw
        )
    elif [[ $TARGET == linux64 ]]; then
        myconf+=(
            --host="$FFBUILD_TOOLCHAIN"
            --cross-prefix="$FFBUILD_CROSS_PREFIX"
            linux-x86_64
        )
    elif [[ $TARGET == linuxarm64 ]]; then
        myconf+=(
            --host="$FFBUILD_TOOLCHAIN"
            --cross-prefix="$FFBUILD_CROSS_PREFIX"
            linux-aarch64
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

    # Yapılandırma komutu
    ./configure "${myconf[@]}"

    # Makefile'de CFLAGS ve LDFLAGS ayarlamalarını yapalım
    sed -i -e "/^CFLAGS=/s|=.*|=${CFLAGS}|" -e "/^LDFLAGS=/s|=[[:space:]]*$|=${LDFLAGS}|" Makefile

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
