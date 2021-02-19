//
//  BleEncryptUtils.m
//  Runner
//
//  Created by ShiAwe on 12/1/19.
//  Copyright © 2019 The Chromium Authors. All rights reserved.
//

#import "BleEncryptUtils.h"

@implementation BleEncryptUtils

+(NSData *) encrypt:(NSData *) originData {
    //测试不加密
    //return originData;
    
    unsigned char InputData[8];
    [originData getBytes:InputData length:8];
    
    unsigned char exchangeBubber = 0;
    if( InputData[0] & 0x01)            //bit0
    {
        exchangeBubber = InputData[2] & 0x0f;  //
        InputData[2] &= 0xf0;
        InputData[2] |= ( InputData[6] & 0x0f );
        InputData[6] &= 0xf0;
        InputData[6] |= exchangeBubber;
    }
    
    if(InputData[0] & 0x02)           //bit1
    {
        exchangeBubber = InputData[2] & 0xf0;
        InputData[2] &= 0x0f;
        InputData[2] |= ((InputData[5] & 0x0f)<<4);
        InputData[5] &= 0xf0;
        InputData[5] |= exchangeBubber>>4;
    }
    
    if(InputData[0] & 0x04)           //bit2
    {
        exchangeBubber = InputData[3] & 0x0f;
        InputData[3] &= 0xf0;
        InputData[3] |= ((InputData[4] & 0xf0)>>4);
        InputData[4] &= 0x0f;
        InputData[4] |= exchangeBubber<<4;
    }
    
    if(InputData[0] & 0x08)          //bit3
    {
        exchangeBubber = InputData[3] & 0xf0;
        InputData[3] &= 0x0f;
        InputData[3] |= ((InputData[4] & 0x0f))<<4;
        InputData[4] &= 0xf0;
        InputData[4] |= exchangeBubber>>4;
    }
    
    if(InputData[0] & 0x10)         //bit4
    {
        exchangeBubber = InputData[5] & 0xf0;
        InputData[5] &= 0x0f;
        InputData[5] |= (InputData[7] & 0xf0);
        InputData[7] &= 0x0f;
        InputData[7] |= exchangeBubber;
    }
    
    if(InputData[0] & 0x20)         //bit5
    {
        exchangeBubber = InputData[6] & 0xf0;
        InputData[6] &= 0x0f;
        InputData[6] |= ((InputData[7] & 0x0f))<<4;
        InputData[7] &= 0xf0;
        InputData[7] |= exchangeBubber>>4;
    }
    
    if(InputData[0] & 0x40)       //bit6
    {
        exchangeBubber = InputData[2] & 0x0f;
        InputData[2] &= 0xf0;
        InputData[2] |= ((InputData[3] & 0xf0))>>4;
        InputData[3] &= 0x0f;
        InputData[3] |= exchangeBubber<<4;
    }
    
    if(InputData[0] & 0x80)      //bit7
    {
        exchangeBubber = InputData[2] & 0xf0;
        InputData[2] &= 0x0f;
        InputData[2] |= ((InputData[3] & 0x0f))<<4;
        InputData[3] &= 0xf0;
        InputData[3] |= exchangeBubber>>4;
    }
    
    InputData[2] = InputData[2] ^ InputData[1] ^ 0x69;
    InputData[3] = InputData[3] ^ InputData[1] ^ 0x69;
    InputData[4] = InputData[4] ^ InputData[1] ^ 0x69;
    InputData[5] = InputData[5] ^ InputData[1] ^ 0x69;
    InputData[6] = InputData[6] ^ InputData[1] ^ 0x69;
    InputData[7] = InputData[7] ^ InputData[1] ^ 0x69;
    //转换
    for(exchangeBubber=0;exchangeBubber<8;exchangeBubber++)
    {
        InputData[exchangeBubber] = switchSheet[(InputData[exchangeBubber])/4] + InputData[exchangeBubber]%4;
    }
    return [NSData dataWithBytes:InputData length:8];
}

@end
