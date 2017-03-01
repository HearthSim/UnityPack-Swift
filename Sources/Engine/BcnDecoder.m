//
//  BcnDecoder.m
//  UnityPack-Swift
//
//  Created by Istvan Fehervari on 01/03/2017.
//  Copyright © 2017 Benjamin Michotte. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "BcnDecoder.h"
#include "bcndecode.h"

@implementation BcnDecoder

+(NSImage*)decodeImageFromdata:(NSData*) data size:(NSSize) size encoding:(EncodeType) encoding {
    int src_size = 4 * size.width * size.height;
    int dst_size = src_size;
    int flip = 0;
    
    if (encoding == EncodeType_bc1 || encoding == EncodeType_bc4) {
        src_size >>= 3;
    } else {
        src_size >>= 2;
    }
    if (encoding == EncodeType_bc4) {
        dst_size >>= 2;
    } else if (encoding == EncodeType_bc6) {
        dst_size <<= 2;
    }
    uint8_t *src = (uint8_t*)data.bytes;
    uint8_t *dst = malloc(dst_size*sizeof(uint8_t));
    
    NSImage* result = NULL;
    if (BcnDecode(dst, dst_size, src, src_size, size.width, size.height, encoding, BcnDecoderFormatARGB, flip) < 0) {
        // TODO: create nsimagerep from the result
        
    }
    
    free(dst);

    return result;
}

@end
