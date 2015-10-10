#!/bin/sh
set -e

. ../versions

#!/bin/sh

SDKVERSION=`xcrun -sdk iphoneos --show-sdk-version`


##############################################
CURRENTPATH=`pwd`
ARCHS="i386 x86_64 armv7 armv7s arm64"
DEVELOPER=`xcode-select -print-path`

if [ ! -d "$DEVELOPER" ]; then
echo "xcode path is not set correctly $DEVELOPER does not exist (most likely because of xcode > 4.3)"
echo "run"
echo "sudo xcode-select -switch <xcode path>"
echo "for default installation:"
echo "sudo xcode-select -switch /Applications/Xcode.app/Contents/Developer"
exit 1
fi

case $DEVELOPER in
*\ * )
echo "Your Xcode path contains whitespaces, which is not supported."
exit 1
;;
esac

case $CURRENTPATH in
*\ * )
echo "Your path contains whitespaces, which is not supported by 'make install'."
exit 1
;;
esac

set -e

if [ ! -e "c-ares-${CARES_VERSION}.tar.gz" ]
then
curl -O "http://c-ares.haxx.se/download/c-ares-${CARES_VERSION}.tar.gz"
fi

tar zxf c-ares-${CARES_VERSION}.tar.gz
pushd "c-ares-${CARES_VERSION}"

for ARCH in ${ARCHS}
do
if [[ "${ARCH}" == "i386" || "${ARCH}" == "x86_64" ]];
then
PLATFORM="iPhoneSimulator"
else
PLATFORM="iPhoneOS"
fi

export BUILD_TOOLS="${DEVELOPER}"
export BUILD_DEVROOT="${DEVELOPER}/Platforms/${PLATFORM}.platform/Developer"
export BUILD_SDKROOT="${BUILD_DEVROOT}/SDKs/${PLATFORM}${SDKVERSION}.sdk"

export CC="${BUILD_TOOLS}/usr/bin/gcc -arch ${ARCH}"
mkdir -p "${CURRENTPATH}/bin/${PLATFORM}${SDKVERSION}-${ARCH}.sdk"

# Build
export LDFLAGS="-Os -arch ${ARCH} -Wl,-dead_strip -miphoneos-version-min=7.0 -L${BUILD_SDKROOT}/usr/lib"
export CFLAGS="-Os -arch ${ARCH} -pipe -no-cpp-precomp -fembed-bitcode -isysroot ${BUILD_SDKROOT} -miphoneos-version-min=7.0"
export CPPFLAGS="${CFLAGS} -I${BUILD_SDKROOT}/usr/include"
export CXXFLAGS="${CPPFLAGS}"

BUILDDIR="${CURRENTPATH}/c-ares-${CARES_VERSION}/build-ios-${PLATFORM}/${ARCH}"
PREFIX="${CURRENTPATH}/c-ares-${CARES_VERSION}/install-ios-${PLATFORM}/${ARCH}"

mkdir -p ${BUILDDIR}
pushd ${BUILDDIR}

if [ "${ARCH}" == "arm64" ]; then
${CURRENTPATH}/c-ares-${CARES_VERSION}/configure --host=aarch64-apple-darwin --enable-static --disable-shared --prefix="${PREFIX}"
else
${CURRENTPATH}/c-ares-${CARES_VERSION}/configure --host=${ARCH}-apple-darwin --enable-static --disable-shared --prefix="${PREFIX}"
fi

make
cp -f .libs/libcares.a ${CURRENTPATH}/bin/${PLATFORM}${SDKVERSION}-${ARCH}.sdk/
make install
popd

done

popd
mkdir lib || true
lipo -create ${CURRENTPATH}/bin/iPhoneSimulator${SDKVERSION}-i386.sdk/libcares.a ${CURRENTPATH}/bin/iPhoneSimulator${SDKVERSION}-x86_64.sdk/libcares.a  ${CURRENTPATH}/bin/iPhoneOS${SDKVERSION}-armv7.sdk/libcares.a ${CURRENTPATH}/bin/iPhoneOS${SDKVERSION}-armv7s.sdk/libcares.a ${CURRENTPATH}/bin/iPhoneOS${SDKVERSION}-arm64.sdk/libcares.a -output ${CURRENTPATH}/lib/libcares.a
mkdir -p include/cares || true
cp -f c-ares-${CARES_VERSION}/ares.h c-ares-${CARES_VERSION}/build-ios-${PLATFORM}/${ARCH}/ares_build.h c-ares-${CARES_VERSION}/ares_dns.h c-ares-${CARES_VERSION}/ares_rules.h c-ares-${CARES_VERSION}/ares_version.h include/cares/
sed -i '' $'s/\#define CARES_SIZEOF_LONG 8/\#ifdef __LP64__\\\n\#define CARES_SIZEOF_LONG 8\\\n#else\\\n\#define CARES_SIZEOF_LONG 4\\\n\#endif/' include/cares/ares_build.h


rm -rf bin

echo "Done."
