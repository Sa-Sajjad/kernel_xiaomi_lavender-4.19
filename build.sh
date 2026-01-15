#!/bin/bash
#
# Compile script for Nyxion kernel.

##----------------------------------------------------------##

START=$(date +"%s")
ZIPNAME="Nyxion-qcom-lavender-4.19-$(date '+%Y%m%d-%H%M').zip"
TC_DIR="$(pwd)/tc/zyc_clang"
IMAGE="out/arch/arm64/boot/Image.gz"

DEFCONFIG="vendor/lavender-perf_defconfig"

export KBUILD_BUILD_USER="Sã Śâjjãd"
export KBUILD_BUILD_HOST="SNX"
export LLVM=1
export LLVM_IAS=1

##----------------------------------------------------------##
post_msg() {
    curl -s -X POST "https://api.telegram.org/bot$token/sendMessage" \
        -d chat_id="$chat_id" \
        -d "disable_web_page_preview=true" \
        -d "parse_mode=html" \
        -d text="$1"
}

##----------------------------------------------------------##

push() {
    curl -F document=@"$1" "https://api.telegram.org/bot$token/sendDocument" \
         -F chat_id="$chat_id" \
         -F "disable_web_page_preview=true" \
         -F "parse_mode=html" \
         -F caption="$2"
}

##----------------------------------------------------------##

if ! [ -d "$TC_DIR" ]; then
    echo "Clang not found, Downloading clang source."
    mkdir -p "$TC_DIR"
    wget https://github.com/ZyCromerZ/Clang/releases/download/15.0.7-20251111-release/Clang-15.0.7-20251111.tar.gz -O "$TC_DIR/zyc_clang.tar.gz"
    echo "Extracting Clang source."
    if ! tar -xvf "$TC_DIR/zyc_clang.tar.gz" -C "$TC_DIR" >/dev/null 2>&1; then
        echo "Extracting failed! Aborting..."
        exit 1
    fi
fi

##----------------------------------------------------------##

case "$1" in
    -r|--regen)
        make O=out ARCH=arm64 $DEFCONFIG savedefconfig && cp out/defconfig arch/arm64/configs/$DEFCONFIG
        echo -e "\nSuccessfully regenerated defconfig at $DEFCONFIG"
        exit
        ;;
    -rf|--regen-full)
        make O=out ARCH=arm64 $DEFCONFIG && cp out/.config arch/arm64/configs/$DEFCONFIG
        echo -e "\nSuccessfully regenerated full defconfig at $DEFCONFIG"
        exit
        ;;
    -c|--clean)
        rm -rf out
        ;;
    -p|--package)
        echo -e "\n Installing required package"
        sudo apt update && sudo apt install -y cpio flex bison bc libarchive-tools zstd wget curl
        ;;
esac


##----------------------------------------------------------##

compile() {
    export PATH="$TC_DIR/bin:$PATH"
    export KBUILD_COMPILER_STRING="$(${TC_DIR}/bin/clang --version | head -n 1 | perl -pe 's/\(http.*?\)//gs' | sed -e 's/  */ /g' -e 's/[[:space:]]*$//')"
    post_msg "<b>CI Build Triggered</b>%0A<b>Kernel Version:</b> <code>$(make kernelversion)</code>%0A<b>Date:</b> <code>$(TZ=Asia/Kolkata date)</code>%0A<b>Device:</b> <code>Redmi Note 7 (lavender)</code>%0A<b>Compiler:</b> <code>$KBUILD_COMPILER_STRING</code>%0A<b>Branch:</b> <code>$(git rev-parse --abbrev-ref HEAD)</code>%0A<b>Top Commit:</b> <code>$(git log --pretty=format:'%h : %s' -1)</code>" >/dev/null 2>&1;

    mkdir -p out
    MAKE_ARGS="ARCH=arm64 O=out CC=clang CROSS_COMPILE=aarch64-linux-gnu- CROSS_COMPILE_ARM32=arm-linux-gnueabi- CROSS_COMPILE_COMPAT=arm-linux-gnueabi- CLANG_TRIPLE=aarch64-linux-gnu-"

    echo -e "\nStarting compilation...\n"

    make $MAKE_ARGS ${DEFCONFIG}
    make $MAKE_ARGS -j$(nproc) 2>&1 | tee error.log

    if ! [ -f "$IMAGE" ]; then
        push "error.log" "Build failed. See log for details."
        rm error.log
        exit 1
    fi

    git clone -q https://github.com/Sa-Sajjad/AnyKernel3 -b 4.19
    cp "$IMAGE" AnyKernel3
}

##----------------------------------------------------------##

zipping() {
    cd AnyKernel3 || exit 1
    zip -r9 "../$ZIPNAME" *
    cd ..
    MD5CHECK=$(md5sum "$ZIPNAME" | cut -d' ' -f1)
    push "$ZIPNAME" " <b>Build took:</b> $(($DIFF / 60)) minute(s) and $(($DIFF % 60)) second(s) | <b>Compiler:</b> <code>$KBUILD_COMPILER_STRING</code> | <b>MD5 Checksum : </b><code>$MD5CHECK</code>" >/dev/null 2>&1;
    rm -rf AnyKernel3
}

##----------------------------------------------------------##

compile
END=$(date +"%s")
DIFF=$(($END - $START))
zipping

##----------------------------------------------------------##
