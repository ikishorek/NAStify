//
//  GfxProcCG.cpp
//  MegaLib
//
//  Created by Andrei Stoleru on 16.03.2014.
//  Copyright (c) 2014 MEGA. All rights reserved.
//

#include "GfxProcCG.h"
#include <CoreGraphics/CGBitmapContext.h>
#include <ImageIO/CGImageDestination.h>
#include <MobileCoreServices/UTCoreTypes.h>
#include <ImageIO/CGImageProperties.h>

using namespace mega;

GfxProcCG::GfxProcCG()
    : GfxProc()
    , imageSource(NULL)
    , w(0)
    , h(0)
{
    thumbnailParams = CFDictionaryCreateMutable(kCFAllocatorDefault, 3,
                                                &kCFTypeDictionaryKeyCallBacks, &kCFTypeDictionaryValueCallBacks);
    CFDictionaryAddValue(thumbnailParams, kCGImageSourceCreateThumbnailWithTransform, kCFBooleanTrue);
    CFDictionaryAddValue(thumbnailParams, kCGImageSourceCreateThumbnailFromImageAlways, kCFBooleanTrue);

    float comp = 0.75f;
    CFNumberRef compression = CFNumberCreate(kCFAllocatorDefault, kCFNumberFloatType, &comp);
    imageParams = CFDictionaryCreate(kCFAllocatorDefault, (const void **)&kCGImageDestinationLossyCompressionQuality, (const void **)&compression, 1, &kCFTypeDictionaryKeyCallBacks, &kCFTypeDictionaryValueCallBacks);
    CFRelease(compression);
}

GfxProcCG::~GfxProcCG() {
    freebitmap();
    CFRelease(thumbnailParams);
    CFRelease(imageParams);
}

bool GfxProcCG::isgfx(string* name) {
    size_t p = name->find_last_of('.');

    if (!(p + 1)) {
        return false;
    }

    string ext(*name,p);
    std::transform(ext.begin(), ext.end(), ext.begin(), ::tolower);
    return ext == ".png" || ext == ".jpg" || ext == ".tif" || ext == ".tiff"
           || ext == ".gif" || ext == ".bmp" || ext == ".pdf";
}

bool GfxProcCG::readbitmap(FileAccess* fa, string* name, int size) {
    if (!isgfx(name)) {
        return false;
    }

    CGDataProviderRef dataProvider = CGDataProviderCreateWithFilename(name->c_str());
    if (!dataProvider) {
        return false;
    }

    CFMutableDictionaryRef imageOptions = CFDictionaryCreateMutable(kCFAllocatorDefault, 0,
                                                                       &kCFTypeDictionaryKeyCallBacks, &kCFTypeDictionaryValueCallBacks);
    CFDictionaryAddValue(imageOptions, kCGImageSourceShouldCache, kCFBooleanFalse);

    imageSource = CGImageSourceCreateWithDataProvider(dataProvider, imageOptions);
    CGDataProviderRelease(dataProvider);
    if (!imageSource) {
        return false;
    }

    CFDictionaryRef imageProperties = CGImageSourceCopyPropertiesAtIndex(imageSource, 0, imageOptions);
    if (imageProperties) { // trying to get width and heigth from properties
        CFNumberRef width = (CFNumberRef)CFDictionaryGetValue(imageProperties, kCGImagePropertyPixelWidth);
        CFNumberRef heigth = (CFNumberRef)CFDictionaryGetValue(imageProperties, kCGImagePropertyPixelHeight);
        if (width && heigth) {
            CFNumberGetValue(width, kCFNumberCGFloatType, &w);
            CFNumberGetValue(heigth, kCFNumberCGFloatType, &h);
        }
        CFRelease(imageProperties);
    }
    if (!((int)w && (int)h)) { // trying to get fake size from thumbnail
        CGImageRef thumbnail = createThumbnailWithMaxSize(100);
        w = CGImageGetWidth(thumbnail);
        h = CGImageGetHeight(thumbnail);
        CFRelease(thumbnail);
    }
    return (int)w && (int)h;
}

CGImageRef GfxProcCG::createThumbnailWithMaxSize(int size) {
    const double maxSizeDouble = size;
    CFNumberRef maxSize = CFNumberCreate(kCFAllocatorDefault, kCFNumberDoubleType, &maxSizeDouble);
    CFDictionarySetValue(thumbnailParams, kCGImageSourceThumbnailMaxPixelSize, maxSize);
    CFRelease(maxSize);

    return CGImageSourceCreateThumbnailAtIndex(imageSource, 0, thumbnailParams);
}

static inline CGRect tileRect(size_t w, size_t h)
{
    CGRect res;
    // square rw*rw crop thumbnail
    res.size.width = res.size.height = std::min(w, h);
    if (w < h)
    {
        res.origin.x = 0;
        res.origin.y = (h - w) / 2;
    }
    else
    {
        res.origin.x = (w - h) / 2;
        res.origin.y = 0;
    }
    return res;
}

int GfxProcCG::maxSizeForThumbnail(const int rw, const int rh) {
    if (rh) { // rectangular rw*rh bounding box
        return std::max(rw, rh);
    }
    // square rw*rw crop thumbnail
    return (int)(rw * std::max(w, h) / std::min(w, h));
}

bool GfxProcCG::resizebitmap(int rw, int rh, string* jpegout) {
    if (!imageSource) {
        return false;
    }

    jpegout->clear();

    CGImageRef image = createThumbnailWithMaxSize(maxSizeForThumbnail(rw, rh));
    if (!rh) { // Make square image
        CGImageRef newImage = CGImageCreateWithImageInRect(image, tileRect(CGImageGetWidth(image), CGImageGetHeight(image)));
        CFRelease(image);
        image = newImage;
    }
    CFMutableDataRef data = CFDataCreateMutable(kCFAllocatorDefault, 0);
    CGImageDestinationRef destination = CGImageDestinationCreateWithData(data, kUTTypeJPEG, 1, NULL);
    CGImageDestinationAddImage(destination, image, imageParams);
    bool success = CGImageDestinationFinalize(destination);
    CGImageRelease(image);
    CFRelease(destination);

    jpegout->assign((char*)CFDataGetBytePtr(data), CFDataGetLength(data));
    CFRelease(data);
    return success;
}

void GfxProcCG::freebitmap() {
    CFRelease(imageSource);
    imageSource = NULL;
    w = h = 0;
}
