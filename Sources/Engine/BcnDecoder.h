//
//  BcnDecoder.h
//  UnityPack-Swift
//
//  Created by Istvan Fehervari on 01/03/2017.
//  Copyright © 2017 Benjamin Michotte. All rights reserved.
//

#ifndef BcnDecoder_h
#define BcnDecoder_h

typedef enum {
    EncodeType_raw = 0,
    EncodeType_bc1 = 1, // BC1: 565 color, 1-bit alpha (dxt1)
    EncodeType_bc2 = 2, // BC2: 565 color, 4-bit alpha (dxt3)
    EncodeType_bc3 = 3, // BC3: 565 color, 2-endpoint 8-bit interpolated alpha (dxt5)
    EncodeType_bc4 = 4, // BC4: 1-channel 8-bit via 1 BC3 alpha block
    EncodeType_bc5 = 5, // BC5: 2-channel 8-bit via 2 BC3 alpha blocks
    // following not implemented
    EncodeType_bc6 = 6, // BC6: 3-channel 16-bit float
    EncodeType_bc7 = 7, // BC7: 4-channel 8-bit via everything
} EncodeType;

@interface BcnDecoder : NSObject

+(NSImage*)decodeImageFromdata:(NSData*) data size:(NSSize) size encoding:(EncodeType) encoding;

@end

#endif /* BcnDecoder_h */
