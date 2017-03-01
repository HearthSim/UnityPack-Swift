//
//  bcndecode.h
//  UnityPack-Swift
//
//  Created by Istvan Fehervari on 01/03/2017.
//  Copyright © 2017 Benjamin Michotte. All rights reserved.
//

#ifndef bcndecode_h
#define bcndecode_h

#include <stdio.h>

typedef enum {
    BcnDecoderFormatRGBA = 1,
    BcnDecoderFormatBGRA = 2,
    BcnDecoderFormatARGB = 3,
    BcnDecoderFormatABGR = 4
} BcnDecoderFormat;

int BcnDecode(uint8_t *dst, int dst_size, const uint8_t *src, int src_size, int width, int height, int N, int dst_format, int flip);

#endif /* bcndecode_h */
