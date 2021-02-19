//
//  BleConnector.m
//  MoudleKing_ios
//
//  Created by ShiAwe on 10/12/19.
//  Copyright © 2019 Awe shi. All rights reserved.
//

#import "BleConnector.h"
#import "Advertiser.h"
#import "BleEncryptUtils.h"

#define MODE_MUTIL_SUPPORT 0 //支持单个模块版本
#define PAYLOAD_PAIR_LEN 8  //广播包缓存的长度
#define PAYLOAD_CROL_LEN 16  //广播包缓存的长度
#define EXPIRE_TIME_OUT 5  //过期时长 秒


#define PACKAGE_PAIR_HEAD  0xC0 //配对开头
#define PACKAGE_PAIRD_HEAD  0xE5 //已配对开头
#define PACKAGE_PAIR_END  0x3F //配对结尾
#define PACKAGE_PAIR_RECEIVE_HEAD  0xA0 //配对开头
#define PACKAGE_UNPAIR_RECEIVE_HEAD  0xE0 //取消配对开头

//#define PACKAGE_TYPE_PAIRED  0x41 //未设备配对TYPE
//#define PACKAGE_TYPE_PAIRED  0x41 //未设备配对TYPE

#define PACKAGE_CONTROL_HEAD  0x75 //控制HEAD

#define APP_ID_KEY @"MYAPP_ID" //手机
#define DEVICE_ID_KEY @"DEVICE_ID_KEY" //小车
@interface  BleConnector() <CBCentralManagerDelegate>

@property (strong, nonatomic) NSTimer * mainTimer;
@property (assign, nonatomic) NSInteger mainTimerCount;

@property (strong, nonatomic) NSMutableDictionary * onLineDeviceDic;
@property (strong, nonatomic) NSMutableDictionary * pariedDeviceDic;

@end

static BleConnector *shareManager = nil;
@implementation BleConnector {
    Advertiser* advertiser;
    CBCentralManager *manager;
    
    //广播包
    unsigned char advertiseBytes[PAYLOAD_CROL_LEN]; //配对
    unsigned char controlerBytes[PAYLOAD_CROL_LEN]; //控制
    NSInteger advertiseBytesLen;
    NSInteger currentStatus; //当前设备广播的状态
}

//懒加载
-(NSMutableDictionary *) onLineDeviceDic {
    if(!_onLineDeviceDic) {
        _onLineDeviceDic = [[NSMutableDictionary alloc] init];
    }
    return _onLineDeviceDic;
}

-(NSMutableDictionary *) pariedDeviceDic {
    if(!_pariedDeviceDic) {
        _pariedDeviceDic = [[NSMutableDictionary alloc] init];
    }
    return _pariedDeviceDic;
}

+(id)instance{
    if(shareManager  == nil){
        shareManager  = [[super alloc] init];
    }
    return shareManager;
}

-(id) init {
    self = [super init];
    
    if(self){
    advertiser = [[Advertiser alloc] init];
    [advertiser initialize];
    
    
    manager = [[CBCentralManager alloc]initWithDelegate:self queue:dispatch_get_main_queue()];
    
    self.mainTimerCount = 0;
//    self.mainTimer = [NSTimer scheduledTimerWithTimeInterval:0.25 target:self selector:@selector(mainRun:) userInfo:nil repeats:YES];
    
    [NSThread detachNewThreadSelector:@selector(main:) toTarget:self withObject:nil];
    
    //设备初始化状态 空闲状态
    currentStatus = STATUS_IDEL;
    
    [self initCrolCommand];
    }
    return self;
}

//本地唯一ID
-(NSNumber *) getOrCreateAddress {
    NSNumber * number  = [[NSUserDefaults standardUserDefaults] objectForKey:APP_ID_KEY];
    //NSLog(@"APP_ID_KEY =  %@",number);
    if(number){
        
    } else {
        //number = [NSNumber numberWithInt:arc4random_uniform(1024*1024)];
        
        //生成唯一KEY 不能时3个FF结尾的数据
        int value = arc4random_uniform(1024*1024);
        while(((value >>16)&0xFF)==0xFF &&  ((value >>8)&0xFF)==0xFF &&  ((value)&0xFF)==0xFF){
            //number = [NSNumber numberWithInt:arc4random_uniform(1024*1024)];
            value = arc4random_uniform(1024*1024);
        }
        number = [NSNumber numberWithInt:value];
        [[NSUserDefaults standardUserDefaults] setObject:number forKey:APP_ID_KEY];
        [[NSUserDefaults standardUserDefaults] synchronize];
        NSLog(@"APP_ID_KEY =  %@",number);
    }
    return number;
}

//填充本机唯一地址及历史链接记录
-(void) fillSerailAddress {
    NSNumber * number = [self getOrCreateAddress];
    int value = [number intValue];
    controlerBytes[5] = (value >>16)&0xFF;
    controlerBytes[6] = (value >>8)&0xFF;
    controlerBytes[7] = (value)&0xFF;
    
    advertiseBytes[5] = (value >>16)&0xFF;
    advertiseBytes[6] = (value >>8)&0xFF;
    advertiseBytes[7] = (value)&0xFF;
    
    NSNumber * deviceId =[[NSUserDefaults standardUserDefaults] objectForKey:DEVICE_ID_KEY];
    if(deviceId!=nil){
        int value =deviceId.intValue;
        advertiseBytes[2] = (value >>16)&0xFF;
        advertiseBytes[3] = (value >>0)&0xFF;
        advertiseBytes[4] = (value)&0xFF;
    }
}

-(void) initCrolCommand {
    controlerBytes[0] = PACKAGE_CONTROL_HEAD; //控制命令
    controlerBytes[1] = 0x00;
    controlerBytes[2] = 0x00;   //设备ID
    controlerBytes[3] = 0x00;   //设备ID
    controlerBytes[4] = 0x00;   //设备ID
    controlerBytes[5] = 0x00;   //APP手机地址
    controlerBytes[6] = 0x00;   //APP手机地址
    controlerBytes[7] = 0x00;   //APP手机地址
    controlerBytes[8] = 0x00;   //KEY1
    controlerBytes[9] = 0x00;   //KEY2
    controlerBytes[10] = 0x80;  //DATA1
    controlerBytes[11] = 0x80;  //DATA2
    controlerBytes[12] = 0x00;  //DATA3
    controlerBytes[13] = 0x00;  //DATA4
    controlerBytes[14] = 0x00;  //DATA5
    controlerBytes[15] = 0x00;  //DATA6
    
    advertiseBytes[0] = PACKAGE_CONTROL_HEAD; //控制命令
    advertiseBytes[1] = 0x00;
    advertiseBytes[2] = 0x00;   //设备ID
    advertiseBytes[3] = 0x00;   //设备ID
    advertiseBytes[4] = 0x00;   //设备ID
    advertiseBytes[5] = 0x00;   //APP手机地址
    advertiseBytes[6] = 0x00;   //APP手机地址
    advertiseBytes[7] = 0x00;   //APP手机地址
    advertiseBytes[8] = 0x00;   //KEY1
    advertiseBytes[9] = 0x00;   //KEY2
    advertiseBytes[10] = 0x80;  //DATA1
    advertiseBytes[11] = 0x80;  //DATA2
    advertiseBytes[12] = 0x00;  //DATA3
    advertiseBytes[13] = 0x00;  //DATA4
    advertiseBytes[14] = 0x00;  //DATA5
    advertiseBytes[15] = 0x00;  //DATA6
    
    [self fillSerailAddress];
}

-(void) main:(id)sender {
    while (true) {
        [self mainRun:nil];
        [NSThread sleepForTimeInterval:0.1];
    }
}

//循环监听及广播
-(void) mainRun:(id) sender {
    if(currentStatus == STATUS_STOP) {
        [advertiser stop];
        return;
    }
    self.mainTimerCount++;
    //NSLog(@"mainTimerCount = %ld",self.mainTimerCount);
    //if(self.mainTimerCount %2 ==0){
        [advertiser stop];
        //[manager stopScan];
        //NSLog(@"Advertise .. %ld",self.mainTimerCount);
        //控制模式
        if(currentStatus == STATUS_CONTROL) {
            controlerBytes[1] = MODE_MUTIL_SUPPORT?0x14:0x13;
            [advertiser setPayload:controlerBytes OfLength:PAYLOAD_CROL_LEN];
        }else
        //配对模式
        if(currentStatus == STATUS_PAIR){
            advertiseBytes[1] = 0x10; //00010000
            [advertiser setPayload:advertiseBytes OfLength:PAYLOAD_CROL_LEN];
        }else
        //配对模式
        if(currentStatus == STATUS_PAIRING){
            advertiseBytes[1] = 0x10; //00010000
            [advertiser setPayload:advertiseBytes OfLength:PAYLOAD_CROL_LEN];
            //测试数据
            //[self processPairDataTest];
        }else
        //解除配对
        if(currentStatus == STATUS_UNPAIRING){
            advertiseBytes[1] = MODE_MUTIL_SUPPORT?0x16:0x17;
            [advertiser setPayload:advertiseBytes OfLength:PAYLOAD_CROL_LEN];
        }
        
        [advertiser start];
    //}else {
    //if(self.mainTimerCount %2 ==0){
        //NSLog(@"Scann .. %ld",self.mainTimerCount);
        //[advertiser stop];
        
        //控制模式 或者配对模式 直接返回 , 不打开扫码
        /*
        if(currentStatus == STATUS_CONTROL || currentStatus == STATUS_PAIRING) {
            return;
        }
         */
        //[manager stopScan];
        //[manager scanForPeripheralsWithServices:nil options:@{CBCentralManagerScanOptionAllowDuplicatesKey:@YES}];
        
        if(self.mainTimerCount % 40 ==1){
            [manager stopScan];
            //[manager scanForPeripheralsWithServices:nil options:@{CBCentralManagerScanOptionAllowDuplicatesKey:@YES}];
        }
        if(self.mainTimerCount % 40 ==3){
            //[manager stopScan];
            [manager scanForPeripheralsWithServices:nil options:@{CBCentralManagerScanOptionAllowDuplicatesKey:@YES}];
        }
        
        //清除设备
        [self removeExipreonDiction:self.onLineDeviceDic];
        [self removeExipreonDiction:self.pariedDeviceDic];
        
    //}
}

////测试
//-(void) processPairDataTest{
//    int radom = arc4random();
//    Byte buffer[PAYLOAD_CROL_LEN+2];
//    buffer[0] = 0xF0;
//    buffer[1] = 0xFF;
//    buffer[2] = 0x75;
//    buffer[3] = 0x40| (radom%2?0x01:0x02);
//    buffer[4] = (radom&0xFF);
//    buffer[5] = ((radom>>8)&0xFF);
//    buffer[6] = ((radom>>16)&0xFF);
//    [self processPairData:[NSData dataWithBytes:buffer length:PAYLOAD_CROL_LEN+2]];
//
//}

//模拟发送配对信息
-(void) testSendPackage{
    Byte b [] =  {0xFF,0xFF,0xFF};
    NSData * tetData = [NSData dataWithBytes:b length:3];
    NSData * hostData = [NSData dataWithBytes:b length:3];
    [self processDvices:PACKAGE_PAIRD_HEAD deviceData:tetData appData:hostData];
}

//配对数据包的处理 需要去掉开头的 F0FF
-(void) processPairData:(NSData *) data{
    //[self testSendPackage];
    
    //NSLog(@"receive processPairData = %@",data);
    if(!data || (data.length!= (PAYLOAD_CROL_LEN+2))){
        return;
    }
    
    Byte buffer[data.length];
    [data getBytes:buffer length:data.length];
    
    if(((buffer[0]&0xFF) != 0xF0 ) || ((buffer[1]&0xFF) != 0xFF )){
        return;
    }
    //NSLog(@"processPairData = %@",data);
    
    //头不匹配返回
    int head = (buffer[2]&0xFF);
    if(head!=PACKAGE_CONTROL_HEAD) {
        NSLog(@"返回 head!= %X",PACKAGE_CONTROL_HEAD);
        return;
    }
    
    //发包者跟接收者判断
    //NSLog(@"发包者跟接收者判断 = %X",buffer[3]);
    if(!(buffer[3]&0x40)){
        NSLog(@"返回 发包者跟接收者!= %X",(buffer[3]&0x40));
        return;
    }
    //NSLog(@"processPairData = %@",data);
    
    NSInteger type = 0;
    if(buffer[3]&0x01){
        type = PACKAGE_PAIR_HEAD;
    }else
    if(buffer[3]&0x02){
        type = PACKAGE_PAIRD_HEAD;
    }
    NSData * deviceData = [NSData dataWithBytes:buffer+4 length:3];
    NSData * appData = [NSData dataWithBytes:buffer+7 length:3];
    
    NSLog(@"processPairData = %@",data);
    
    //处理设备信息
    [self processDvices:type deviceData:deviceData appData:appData];
        
}

//分类别处理设备， 未配对记录到未配对设备列表， 已配对的回复控制命令
-(void) processDvices:(NSInteger) type deviceData:(NSData*) deviceData appData:(NSData *) appData {
    //不是APPData时返回
    Byte buffer[3];
    [appData  getBytes:buffer length:3];
    NSNumber * number = [self getOrCreateAddress];
    int value = number.intValue;
    if(buffer[0] !=((value >>16)&0xFF) ||
        buffer[1] != ((value >>8)&0xFF) ||
       buffer[2] != ((value)&0xFF)){
        NSLog(@"APPID不匹配返回");
        return;
    }
    
    
    NSMutableDictionary * diction = nil;
    if(type == PACKAGE_PAIR_HEAD){
        NSLog(@"发现未配对设备 %@ ",deviceData);
        diction = self.onLineDeviceDic;
    }else if(type == PACKAGE_PAIRD_HEAD) {
        NSLog(@"发现已配对设备 %@ ",deviceData);
        diction = self.pariedDeviceDic;
        //保存设备ID
        [self saveLastConnectedDevice:deviceData];
        //发送控制命令
        //[self commandStart:nil];
    }else {
        NSLog(@"返回 未知类型!");
        return;
    }
    if(type>0){
       [self addDevice:deviceData toDiction:diction];
    }
}

//保存设备地址
-(void) saveLastConnectedDevice:(NSData *) devicedata{
    Byte buffer[3];
    [devicedata getBytes:buffer length:3];
    int value = ((buffer[0]&0xFF)<<16 |(buffer[1]&0xFF)<<8 | (buffer[2]&0xFF));
    NSNumber * deviceId =[[NSUserDefaults standardUserDefaults] objectForKey:DEVICE_ID_KEY];
    if(deviceId==nil || value!=deviceId.intValue){
        NSNumber * number  = [[NSNumber alloc] initWithInt:value];
        [[NSUserDefaults standardUserDefaults] setObject:number forKey:DEVICE_ID_KEY];
        [[NSUserDefaults standardUserDefaults] synchronize];
    }
    
    
}

-(void) commandStart {
    //发送控制命令
    advertiseBytes[10] = 0x80;  //DATA1
    advertiseBytes[11] = 0x80;  //DATA2
    advertiseBytes[12] = 0x00;  //DATA3
    advertiseBytes[13] = 0x00;  //DATA4
    advertiseBytes[14] = 0x00;  //DATA5
    advertiseBytes[15] = 0x00;  //DATA6
    currentStatus = STATUS_CONTROL;
}

-(NSData * ) getServiceData:(NSArray *) array {
    NSMutableData * receiveData = nil;
    if(array){
        receiveData = [[NSMutableData alloc] init];
        //NSLog(@"data=%@ data.length = %ld",array,[array count]);
        for(CBUUID * d in  array) {
            [receiveData appendData:d.data];
        }
        //NSLog(@"reedata=%@ data.length = %ld",receiveData,[receiveData length]);
        
        [self processPairData:receiveData];
    }
    return receiveData;
}

//控制
-(void) setValue:(NSInteger)value forDeiceIndex:(NSInteger)device forDevicePort:(NSInteger) length {
    //设备ID
    NSLog(@"setValue %06X %06X %d",value,device,length);
    controlerBytes[2] = device&0xFF;
    controlerBytes[3] = (device>>8)&0xFF;
    controlerBytes[4] = (device>>16)&0xFF;
    
//    NSLog(@"controlerBytes %02X %02X %02X %02X %02X %02X %02X %02X %02X %02X %02X %02X %02X %02X %02X %02X",controlerBytes[0],controlerBytes[1],controlerBytes[2],controlerBytes[3],controlerBytes[4],controlerBytes[5],controlerBytes[6],controlerBytes[7],controlerBytes[8],controlerBytes[9],controlerBytes[10],controlerBytes[11],controlerBytes[12],controlerBytes[13],controlerBytes[14],controlerBytes[15]);
    
    Byte data[8];
    //currentStatus = STATUS_CONTROL;
    
    if(length<1){
        return;
    }
    for(int i=0;i<length;i++){
        data[2+i] = (value>>(i*8)&0xFF);
    }
    NSInteger random = arc4random();
    data[0] = random &0xFF;
    data[1] = (random>>8) &0xFF;
    
    //Encrypt(data);
    NSData * encryData  =  [BleEncryptUtils encrypt:[NSData dataWithBytes:data length:8]];
    Byte encryBytes[8];
    [encryData getBytes:encryBytes length:8];
    
// 调试屏蔽
    for(int i=0;i<8;i++){
        controlerBytes[8+i] = encryBytes[i];
    }
    
//    Byte checksum = 0;
//    for(int i=0;i<7;i++){
//        controlerBytes[8+i] = encryBytes[i];
//        if(i>1){
//            checksum = (checksum + encryBytes[i])&0xFF;
//        }
//    }
//    controlerBytes[15] = checksum;
    
    //NSLog(@"加密后的数据 %02X|%02X|%02X|%02X|%02X|%02X|%02X|%02X|%02X|%02X|%02X|%02X|%02X|%02X|%02X|%02X,",controlerBytes[0],controlerBytes[1],controlerBytes[2],controlerBytes[3],controlerBytes[4],controlerBytes[5],controlerBytes[6],controlerBytes[7],controlerBytes[8],controlerBytes[9],controlerBytes[10],controlerBytes[11],controlerBytes[12],controlerBytes[13],controlerBytes[14],controlerBytes[15]);
    //[self setBleStauts:STATUS_CONTROL];
}

//解除配对
//-(void) setUnPariForDeiceIndex:(NSInteger)index {
//    controlerBytes[0] = (0xB0 | ((index+1)&0x0F));
//    currentStatus = STATUS_UNPAIRING;
//}
-(void) setUnparidAddress:(NSData *) device atIndex:(NSInteger) index {
    currentStatus = STATUS_UNPAIRING;
    Byte buffer[3];
    [device getBytes:buffer length:3];
    //advertiseBytes[0] = PACKAGE_PAIR_RECEIVE_HEAD;
    advertiseBytes[2] = buffer[0];
    advertiseBytes[3] = buffer[1];
    advertiseBytes[4] = buffer[2];
    NSLog(@"解除配对 %@",device);
    [self removeOnLineForDevice:device];
}

////配对
-(void) setAdvertiseAddress:(NSInteger) device atIndex:(NSInteger) index {
    currentStatus  = STATUS_CONTROL;
    controlerBytes[2] = device&0xFF;
    controlerBytes[3] = (device>>8)&0xFF;
    controlerBytes[4] = (device>>16)&0xFF;
    //advertiseBytes[7] = index;L
    NSLog(@"配对设备 = %06X ",device);
    //[self removeOnLineForDevice:device];
    
    NSInteger value = 0x80 | (0x80<<8) | 0x00 <<16;
    [self setValue:value forDeiceIndex:device forDevicePort:3];
}

#pragma mark - Central 蓝牙委托
- (void)centralManager:(CBCentralManager *)central didDiscoverPeripheral:(CBPeripheral *)peripheral advertisementData:(NSDictionary *)advertisementData RSSI:(NSNumber *)RSSI; //找到外设的委托
{
    //NSLog(@"centralManager %@",advertisementData);
    if(advertisementData){
        NSData * object = (NSData *)advertisementData[@"kCBAdvDataManufacturerData"] ;
        if(object) {
            [self processPairData:object];
        }
    }
}

- (void)centralManager:(CBCentralManager *)central didConnectPeripheral:(CBPeripheral *)peripheral;//连接外设成功的委托
{
    
}
- (void)centralManager:(CBCentralManager *)central didFailToConnectPeripheral:(CBPeripheral *)peripheral error:(NSError *)error;//外设连接失败的委托
{
    
}
- (void)centralManager:(CBCentralManager *)central didDisconnectPeripheral:(CBPeripheral *)peripheral error:(NSError *)error;//断开外设的委托
{
    
}

-(void)centralManagerDidUpdateState:(CBCentralManager *)central{
    
    switch (central.state) {
        case CBManagerStateUnknown:
            //NSLog(@">>>CBCentralManagerStateUnknown");
            break;
        case CBManagerStateResetting:
            //NSLog(@">>>CBCentralManagerStateResetting");
            break;
        case CBManagerStateUnsupported:
            //NSLog(@">>>CBCentralManagerStateUnsupported");
            break;
        case CBManagerStateUnauthorized:
            //NSLog(@">>>CBCentralManagerStateUnauthorized");
            break;
        case CBManagerStatePoweredOff:
            //NSLog(@">>>CBCentralManagerStatePoweredOff");
            break;
        case CBManagerStatePoweredOn:
            //NSLog(@">>>CBCentralManagerStatePoweredOn");
            //开始扫描周围的外设
            /*
             第一个参数nil就是扫描周围所有的外设，扫描到外设后会进入
             - (void)centralManager:(CBCentralManager *)central didDiscoverPeripheral:( *)peripheral advertisementData:(NSDictionary *)advertisementData RSSI:(NSNumber *)RSSI;
             */
            //[manager scanForPeripheralsWithServices:nil options:nil];
            [manager scanForPeripheralsWithServices:nil options:@{CBCentralManagerScanOptionAllowDuplicatesKey:@YES}];
            
            break;
        default:
            break;
    }
    
}

#pragma mark - 蓝牙命令

-(void) setBleStauts:(NSInteger) status {
    currentStatus = status;
    //命令初始化
//    controlerBytes[10] = 0x80;  //DATA1
//    controlerBytes[11] = 0x80;  //DATA2
//    controlerBytes[12] = 0x00;  //DATA3
//    controlerBytes[13] = 0x00;  //DATA4
//    controlerBytes[14] = 0x00;  //DATA5
//    controlerBytes[15] = 0x00;  //DATA6
    if(currentStatus==STATUS_CONTROL){
    }
//    if(currentStatus == STATUS_PAIRING){
        NSNumber * deviceId =[[NSUserDefaults standardUserDefaults] objectForKey:DEVICE_ID_KEY];
        if(deviceId!=nil){
            int value =deviceId.intValue;
            advertiseBytes[2] = (value >>16)&0xFF;
            advertiseBytes[3] = (value >>0)&0xFF;
            advertiseBytes[4] = (value)&0xFF;
        }
//    }
}

//配对的设备
-(NSArray<NSNumber *>*) getOnLineDevices{
    return self.onLineDeviceDic.allKeys;
}

//未配对的设备
-(NSArray<NSNumber *>*) getPairedDevices{
    return self.pariedDeviceDic.allKeys;
}

//移除在线设备
-(void) removeOnLineForDevice:(NSData *)deviceData{
    Byte bytes[3];
    [deviceData getBytes:bytes length:3];
    NSInteger n = bytes[0]<<16| bytes[1]<<8 | bytes[2];
    NSNumber * number = [NSNumber numberWithInteger:n];
    NSLog(@"移除在线设备 = %@",deviceData);
    [self.onLineDeviceDic removeObjectForKey:number];
    [[NSNotificationCenter defaultCenter] postNotificationName:NOTIFICATION_FIND_DEVICE  object:nil userInfo:nil];
    //NSLog(@"移除在线设备后 = %@ array= %@",deviceData,self.onLineDeviceDic);
}

//删除过期的设备
-(void) removeExipreonDiction:(NSMutableDictionary *)diction {
    NSDate * current = [NSDate date];
    NSArray * allKeys = diction.allKeys;
    BOOL changed = NO;
    for(NSNumber * key in allKeys) {
        NSDate * date = [diction objectForKey:key];
        if([date timeIntervalSince1970] < ([current timeIntervalSince1970]-EXPIRE_TIME_OUT)){
            // NSLog(@"移除缓存列表中的设备= %@, %@ ",key,diction);
            //NSLog(@"移除缓存中过期设备 %lX ", [key integerValue]);
            [diction removeObjectForKey:key];
            changed = YES;
        }
    }
    
    //广播设备变更
    if(changed) {
        //NSLog(@"设备变更下发通知");
        [[NSNotificationCenter defaultCenter] postNotificationName:NOTIFICATION_FIND_DEVICE  object:nil userInfo:nil];
    }
}

-(void) addDevice:(NSData *) deviceData toDiction:(NSMutableDictionary *)diction {
    
    Byte bytes[3];
    [deviceData getBytes:bytes length:3];
    NSInteger n = bytes[0]| bytes[1]<<8 | bytes[2]<<16;
    NSNumber * number = [NSNumber numberWithInteger:n];
    
    NSDate * current = [NSDate date];
    
//    NSArray * allKeys = diction.allKeys;
//    for(NSNumber * key in allKeys) {
//        NSDate * date = [diction objectForKey:key];
//        if([date timeIntervalSince1970] < [current timeIntervalSince1970]- EXPIRE_TIME_OUT){
//            [diction removeObjectForKey:key];
//        }
//    }
//    NSLog(@"更新设备 = %@",deviceData);
    [diction setObject:current forKey:number];
    //广播设备变更
    [[NSNotificationCenter defaultCenter] postNotificationName:NOTIFICATION_FIND_DEVICE  object:nil userInfo:nil];
    
}

-(void) setAdvertiseDevice:(NSInteger) advertise {
    advertiseBytes[2] = (advertise >>16)&0xFF;
    advertiseBytes[3] = (advertise >>8)&0xFF;
    advertiseBytes[4] = (advertise)&0xFF;
}

@end
