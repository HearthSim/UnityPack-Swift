//
//  BcnDecoder.m
//  UnityPack-Swift
//
//  Created by Istvan Fehervari on 01/03/2017.
//  Copyright © 2017 Benjamin Michotte. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <AppKit/AppKit.h>
#import "BcnDecoder.h"
#include "bcndecode.h"

@implementation BcnDecoder

+(NSImage*)decodeImageFromdata:(NSData*) data size:(NSSize) size encoding:(EncodeType) encoding {
    int dst_size = 4 * size.width * size.height;
    int flip = 1;
    
    if (encoding == EncodeType_bc4) {
        dst_size >>= 2;
    } else if (encoding == EncodeType_bc6) {
        dst_size <<= 2;
    }
    uint8_t *src = (uint8_t*)data.bytes;
    uint8_t *dst = malloc(dst_size*sizeof(uint8_t));
    
    NSImage* result = nil;
    int data_read = BcnDecode(dst, dst_size, src, (int)data.length, size.width, size.height, encoding, BcnDecoderFormatRGBA, flip);
    if (data_read < 0) {
        printf("error decoding image data");
        free(dst);
        return nil;
    }
    
    NSBitmapImageRep* bitmap = [[NSBitmapImageRep alloc] initWithBitmapDataPlanes:&dst pixelsWide:size.width pixelsHigh:size.height bitsPerSample:8 samplesPerPixel:4 hasAlpha:YES isPlanar:NO colorSpaceName:NSDeviceRGBColorSpace bytesPerRow:0 bitsPerPixel:0];

    result = [[NSImage alloc] initWithSize:size];
    [result addRepresentation:bitmap];
    
    return result;
}

@end
