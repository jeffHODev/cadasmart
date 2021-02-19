//
//  Advertiser.m
//  PANBLEPeripherialDemo
//
//  Created by 佳文 on 2018/9/26.
//  Copyright © 2018年 Panchip. All rights reserved.
//

#import "Advertiser.h"
#import "BleUtil.h"

//#define TARGET_ADDRESS  {0xc1, 0xc2, 0xc3, 0xc4, 0xc5}
//#define ADDRESS_LENGTH  5

#define TARGET_ADDRESS  {0X43,0X41,0X52}
#define ADDRESS_LENGTH  3

//#define PDU_EXHEADER_LENGTH  ([[[UIDevice currentDevice] systemVersion] floatValue]>= 13.0f?16:13)
#define PDU_EXHEADER_LENGTH  13

@implementation Advertiser {
    NSMutableArray* UUIDs;
}

@synthesize peripheralManager;

- (void)initialize {
    peripheralManager = [[CBPeripheralManager alloc] initWithDelegate:self queue:nil];
}

- (void)start {
    if ([self isBluetoothEnabled] && ![peripheralManager isAdvertising] && UUIDs != nil) {
        [peripheralManager startAdvertising:@{CBAdvertisementDataServiceUUIDsKey:UUIDs}];
    }
}

- (void)stop {
    if ([peripheralManager isAdvertising])
        [peripheralManager stopAdvertising];
}

- (BOOL)isAdvertising {
    return [peripheralManager isAdvertising];
}

- (void)setPayload:(unsigned char *)payload OfLength:(int)length {
    @autoreleasepool {
        
        //NSLog(@"setValue 蓝牙广播数据 = %02X|%02X|%02X|%02X|%02X|%02X|%02X|%02X|%02X|%02X|%02X|%02X|%02X|%02X|%02X|%02X",payload[0],payload[1],payload[2],payload[3],payload[4],payload[5],payload[6],payload[7],payload[8],payload[9],payload[10],payload[11],payload[12],payload[13],payload[14],payload[15]);
        
        int resPayloadLen = length + ADDRESS_LENGTH + PREAMBLE_LENGTH + CRC_LENGTH;
        resPayloadLen = (resPayloadLen%2 == 1)?resPayloadLen+1:resPayloadLen;
        unsigned char address[] = TARGET_ADDRESS;
        unsigned char resPayload[resPayloadLen];
        
        //调试屏蔽原始数据
//        if(payload[1]!=0x10 && (payload[10]== 0x80 || payload[11]== 0x80) ){
//            NSLog(@"setValue 蓝牙广播数据返回 <<<<<");
//            return;
//        }
        
        
        get_rf_payload(address, ADDRESS_LENGTH, payload, length, resPayload,PDU_EXHEADER_LENGTH);
        
        for (int i = 0; i != resPayloadLen/2; ++i) {
            int tmp = resPayload[i*2+1];
            resPayload[i*2+1] = resPayload[i*2];
            resPayload[i*2] = tmp;
        }
        
        if (UUIDs != nil) {
            [UUIDs removeAllObjects];
        } else {
            UUIDs = [[NSMutableArray alloc] init];
        }
        for (int i = 0; i != resPayloadLen/2; ++i) {
            NSData* data = [[NSData alloc] initWithBytes:resPayload+i*2 length:2];
            
            [UUIDs addObject:[CBUUID UUIDWithData:data]];
        }
        
//        NSLog(@"地址为C1C2C3C4C5");
//        NSLog(@"UUIDS = %@",UUIDs);
//        NSLog(@"payload length = %d",resPayloadLen);
//        for(int i=0;i<resPayloadLen;i++) {
//            NSLog(@"%02X,",resPayload[i]);
//        }
        

//        if(length ==8){
//            NSLog(@"broadcase data = %X,%X,%X,%X,%X,%X,%X,%X",payload[0],payload[1],payload[2],payload[3],payload[4],payload[5],payload[6],payload[7]);
//        }
//        if(length ==12){
//            //if(payload[2]|payload[3]){
//             NSLog(@"broadcase data = %X,%X,%X,%X,%X,%X,%X,%X,%X,%X,%X,%X,%X,%X,%X,%X",payload[0],payload[1],payload[2],payload[3],payload[4],payload[5],payload[6],payload[7],payload[8],payload[9],payload[10],payload[11],payload[12],payload[13],payload[14],payload[15]);
            //}
//        }
        
        //打印日志
//        NSString * str = [[UUIDs description]  stringByTrimmingCharactersInSet:[NSCharacterSet whitespaceAndNewlineCharacterSet]];
//        str  = [str stringByReplacingOccurrencesOfString:@"\r" withString:@""];
//        str   = [str stringByReplacingOccurrencesOfString:@"\n" withString:@""];
//        str   = [str stringByReplacingOccurrencesOfString:@"    " withString:@""];
//        NSLog(@"==== broadcase data %@",str);
        
    }
}

- (BOOL)isBluetoothEnabled {
    return peripheralManager.state == CBManagerStatePoweredOn;
}

- (void)peripheralManagerDidStartAdvertising:(CBPeripheralManager *)peripheral error:(NSError *)error {
    //NSLog(@"did start advertising");
}

- (void)peripheralManagerDidUpdateState:(nonnull CBPeripheralManager *)peripheral {
    
}

@end


