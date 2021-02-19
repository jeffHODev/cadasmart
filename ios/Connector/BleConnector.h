//
//  BleConnector.h
//  MoudleKing_ios
//
//  Created by ShiAwe on 10/12/19.
//  Copyright © 2019 Awe shi. All rights reserved.
//

#import <Foundation/Foundation.h>

NS_ASSUME_NONNULL_BEGIN

#define STATUS_PAIR_RECEIVED 1 //收到配对请求(设备ID)     -> 广播 <手机ID, 设备ID, 序号>
#define STATUS_PAIR_CONFIRM 2  //收到配对确认(手机ID,序号) -> 广播 <手机ID, 设备ID, 序号,ID识别起始位>

#define STATUS_IDEL  0      //空闲状态 允许配对
#define STATUS_STOP  1      //停止
#define STATUS_PAIR  2      //配对模式
#define STATUS_PAIRING  3      //配对模式
#define STATUS_UNPAIRING  4      //取消配对模式
#define STATUS_CONTROL 100  //控制模式

#define NOTIFICATION_FIND_DEVICE @"findDeviceNotification"
#define NOTIFICATION_FIND_DEVICE_KEY @"deviceKey"

@interface BleConnector : NSObject
+(id)instance;

//控制命令
-(void) setValue:(NSInteger)value forDeiceIndex:(NSInteger)index forDevicePort:(NSInteger) port;

//解除配对
-(void) setUnparidAddress:(NSData *) device atIndex:(NSInteger) index;
//-(void) setUnPariForDeiceIndex:(NSInteger)index;

//配对
-(void) setAdvertiseAddress:(NSInteger) device atIndex:(NSInteger) index;

//模式设置
-(void) setBleStauts:(NSInteger) status;

//未配对的设备
-(NSArray<NSNumber *>*) getOnLineDevices;

//配对的设备
-(NSArray<NSNumber *>*) getPairedDevices;

-(void) setAdvertiseDevice:(NSInteger) advertise;

//APPID
-(NSNumber *) getOrCreateAddress;
@end

NS_ASSUME_NONNULL_END
