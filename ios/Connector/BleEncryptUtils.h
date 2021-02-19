//
//  BleEncryptUtils.h
//  Runner
//
//  Created by ShiAwe on 12/1/19.
//  Copyright © 2019 The Chromium Authors. All rights reserved.
//

#import <Foundation/Foundation.h>

NS_ASSUME_NONNULL_BEGIN

static unsigned char switchSheet[64] = {244,
    168    ,
    160    ,
    140    ,
    40    ,
    236    ,
    68    ,
    0    ,
    108    ,
    72    ,
    36    ,
    152    ,
    212    ,
    156    ,
    12    ,
    172    ,
    164    ,
    188    ,
    204    ,
    128    ,
    56    ,
    232    ,
    92    ,
    28    ,
    148    ,
    176    ,
    200    ,
    84    ,
    52    ,
    8    ,
    116    ,
    240    ,
    220    ,
    20    ,
    196    ,
    192    ,
    80    ,
    24    ,
    100    ,
    124    ,
    112    ,
    120    ,
    136    ,
    144    ,
    88    ,
    44    ,
    248    ,
    132    ,
    48    ,
    104    ,
    96    ,
    4    ,
    64    ,
    76    ,
    224    ,
    184    ,
    216    ,
    252    ,
    32    ,
    16    ,
    228    ,
    60    ,
    208    ,
    180    ,
};

@interface BleEncryptUtils : NSObject
+(NSData *) encrypt:(NSData *) originData;
@end

NS_ASSUME_NONNULL_END
