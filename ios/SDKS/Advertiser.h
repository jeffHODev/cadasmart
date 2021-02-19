//
//  Advertiser.h
//  PANBLEPeripherialDemo
//
//  Created by 佳文 on 2018/9/26.
//  Copyright © 2018年 Panchip. All rights reserved.
//

#import <UIKit/UIKit.h>
#import <Foundation/Foundation.h>
#import <CoreBluetooth/CoreBluetooth.h>


@interface Advertiser : NSObject<CBPeripheralManagerDelegate>

@property (strong, nonatomic) CBPeripheralManager* peripheralManager;

- (void)initialize;
- (void)start;
- (void)stop;
- (BOOL)isAdvertising;
- (void)setPayload:(Byte *)payload OfLength:(int)length;

- (BOOL)isBluetoothEnabled;

@end
