//
//  NSData+LZMA.m
//  UnityPack-Swift
//
//  Created by Istvan Fehervari on 08/01/2017.
//  Copyright © 2017 Benjamin Michotte. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "NSData+LZMA.h"
#import "LzmaSDKObjCBufferProcessor.h"

@implementation NSData (LZ4)

- (NSData *)decompressLZMA {
    return LzmaSDKObjCBufferDecompressLZMA2(self);
}

@end
