#include "AppDelegate.h"
#include "GeneratedPluginRegistrant.h"
#import "BleConnector.h"

static Byte verticalValue = 0x80;
static Byte horizonalValue = 0x80;
static Byte lightValue = 0x00;
static NSInteger matachDevice = 0;
static NSTimer *timer;


@interface  AppDelegate()<FlutterStreamHandler>
@property (nonatomic, strong) FlutterEventSink eventSink;
@property (nonatomic, strong) FlutterEventChannel * finderChannel;
@end

@implementation AppDelegate

- (BOOL)application:(UIApplication *)application
    didFinishLaunchingWithOptions:(NSDictionary *)launchOptions {
    
    FlutterViewController* fvcontroller = (FlutterViewController*)self.window.rootViewController;
    
    FlutterMethodChannel* blueChannel = [FlutterMethodChannel methodChannelWithName:@"com.yundongjia.blocks/connector" binaryMessenger:fvcontroller];
    __weak typeof(self) weakSelf = self;
    [blueChannel setMethodCallHandler:^(FlutterMethodCall* call, FlutterResult result) {
        NSLog(@"Flutter -> Native 方法调用 %@",call.method);
        if ([@"getStatus" isEqualToString:call.method]) {
            int batteryLevel = [weakSelf getStatus];
            result(@(batteryLevel));
        }else if([@"setHorizontal" isEqualToString:call.method] ){
            NSNumber * num = (NSNumber *)call.arguments;
            horizonalValue = num.integerValue;
            [[BleConnector instance] setBleStauts:STATUS_CONTROL];
            [self sendCommand];
            result(@(0));
        }else if([@"setVertical" isEqualToString:call.method] ){
            NSNumber * num = (NSNumber *)call.arguments;
            verticalValue = num.integerValue;
            [[BleConnector instance] setBleStauts:STATUS_CONTROL];
            [self sendCommand];
            result(@(0));
        }else if([@"setLight" isEqualToString:call.method] ){
            NSNumber * num = (NSNumber *)call.arguments;
            lightValue = num.intValue &0x03;
//            if(num.integerValue){
//                lightValue = 0x00;
//            }else {
//                lightValue = 0x03;
//            }
            [[BleConnector instance] setBleStauts:STATUS_CONTROL];
            [self sendCommand];
            result(@(0));
        }else if([@"pair" isEqualToString:call.method] ){
            NSLog(@"配对 pair");
            NSNumber * num = (NSNumber *)call.arguments;
            [self pare:num];
            result(@(0));
        }else if([@"setControl" isEqualToString:call.method] ){
            NSLog(@"调用控制 setControl");
            [[BleConnector instance] setBleStauts:STATUS_CONTROL];
            horizonalValue = 0x80;
            verticalValue = 0x80;
            lightValue = 0x00;
            
            NSNumber * num =  call.arguments;
            if(num!=nil){
                matachDevice = num.intValue;
            }
            [self sendCommand];
            result(@(0));
        }else if([@"setPairing" isEqualToString:call.method] ){
            NSLog(@"调用配对中 setPairing");
            [[BleConnector instance] setAdvertiseDevice:matachDevice];
            [[BleConnector instance] setBleStauts:STATUS_PAIRING];
            result(@(0));
        }else if([@"setUnpairing" isEqualToString:call.method] ){
            NSLog(@"调用解绑 setUnpairing");
            [self unpair];
            //[[BleConnector instance] setBleStauts:STATUS_PAIRING];
            result(@(0));
        }else if([@"setStop" isEqualToString:call.method] ){
            NSLog(@"调用停止 setStop");
            [[BleConnector instance] setBleStauts:STATUS_STOP];
            result(@(0));
        }else if([@"startBluetooth" isEqualToString:call.method] ){
           NSLog(@"调用 startBluetooth");
           result(@(0));
        }else if([@"startScan" isEqualToString:call.method] ){
           NSLog(@"调用 startScan");
           result(@(0));
        }else if([@"stopScan" isEqualToString:call.method] ){
           NSLog(@"调用 stopScan");
           result(@(0));

        } else {
            result(FlutterMethodNotImplemented);
        }
    }];
    
    self.finderChannel =  [FlutterEventChannel eventChannelWithName:@"com.yundongjia.blocks/finder" binaryMessenger:fvcontroller];
    [self.finderChannel setStreamHandler:self];
    
    
    [GeneratedPluginRegistrant registerWithRegistry:self];
    // Override point for customization after application launch.
    
    //[NSThread sleepForTimeInterval:3];
    return [super application:application didFinishLaunchingWithOptions:launchOptions];
}


- (int)getStatus {
    NSLog(@"getStatus 调用");
    UIDevice* device = UIDevice.currentDevice;
    device.batteryMonitoringEnabled = YES;
    if (device.batteryState == UIDeviceBatteryStateUnknown) {
        return -1;
    } else {
        return (int)(device.batteryLevel * 100);
    }
}

-(void) pare:(NSNumber *) device {
    matachDevice = device.integerValue;
    //[[BleConnector instance] setValue:0 forDeiceIndex:device.integerValue forDevicePort:0];
    [[BleConnector instance] setAdvertiseAddress:matachDevice atIndex:0];
}

-(void) sendCommand{
    NSInteger value = verticalValue | (horizonalValue<<8) | lightValue <<16;
    [[BleConnector instance] setValue:value forDeiceIndex:matachDevice forDevicePort:3];
}

//解除命令
- (void)unpair{
    Byte address[3];
    if(matachDevice){
        address[0] = matachDevice &0xFF;
        address[1] = (matachDevice>>8) &0xFF;
        address[2] = (matachDevice>>16) &0xFF;
    }else {
        address[0] = 0xFF;
        address[1] = 0xFF;
        address[2] = 0xFF;
    }
    
    //[NSData dataWithBytes:address length:3];
    [[BleConnector instance] setUnparidAddress:[NSData dataWithBytes:address length:3] atIndex:0];
    if(timer && timer.isValid) {
        [timer invalidate];
    }
    timer =  [NSTimer scheduledTimerWithTimeInterval:3 repeats:NO block:^(NSTimer * _Nonnull timer) {
        [[BleConnector instance] setBleStauts:STATUS_PAIRING];
    }];
}

-(void) deviceChanged:(NSNotification *) notification {
    
    NSLog(@"deviceChanged 调用");
    NSArray * onLinearray = [[BleConnector instance] getOnLineDevices];
    NSArray * pariedarray  = [[BleConnector instance] getPairedDevices];
//    NSMutableArray * newArray = [NSMutableArray arrayWithCapacity:10];
//    [newArray  addObjectsFromArray:onLinearray];
//    if([pariedarray containsObject:[NSNumber numberWithInt:matachDevice]]){
//        [newArray addObject:[NSNumber numberWithInt:matachDevice]];
//    }
//    if(newArray.count>0) {
//        NSLog(@"deviceChanged 调用给Flutter");
//        self.eventSink(newArray);
//    }
    self.eventSink(@{@"unpairdevices":onLinearray,@"paireddevices":pariedarray});
}

- (void)applicationDidBecomeActive:(UIApplication *)application{
    //[super applicationDidBecomeActive:application];
    //注册监听
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(deviceChanged:) name:NOTIFICATION_FIND_DEVICE object:nil];
    verticalValue = 0x80;
    horizonalValue = 0x80;
    lightValue = 0x00;
    //matachDevice = 0;
    if(timer && timer.isValid) {
        [timer invalidate];
    }
    NSLog(@"applicationDidBecomeActive");
    
}
- (void)applicationWillResignActive:(UIApplication *)application{
    //取消注册监听
    [[NSNotificationCenter defaultCenter] removeObserver:self name:NOTIFICATION_FIND_DEVICE object:nil];
    NSLog(@"applicationWillResignActive");
    verticalValue = 0x80;
    horizonalValue = 0x80;
    lightValue = 0x00;
    //matachDevice = 0;
    if(timer && timer.isValid) {
        [timer invalidate];
    }
    //[super applicationWillResignActive:application];
}

-(void) applicationWillTerminate:(UIApplication *)application{
    //取消注册监听
    [[NSNotificationCenter defaultCenter] removeObserver:self name:NOTIFICATION_FIND_DEVICE object:nil];
    NSLog(@"applicationWillTerminate");
    verticalValue = 0x80;
    horizonalValue = 0x80;
    lightValue = 0x00;
    //matachDevice = 0;
    if(timer && timer.isValid) {
        [timer invalidate];
    }
    //[super applicationWillTerminate:application];
}


- (FlutterError* _Nullable)onListenWithArguments:(id _Nullable)arguments
                                       eventSink:(FlutterEventSink)events{
    self.eventSink = events;
    [[BleConnector instance] setBleStauts:STATUS_PAIRING];
    NSLog(@"onListenWithArguments");
    //self.eventSink(@"unnkow");
    return nil;
    
}

- (FlutterError* _Nullable)onCancelWithArguments:(id _Nullable)arguments {
    [[BleConnector instance] setBleStauts:STATUS_STOP];
     NSLog(@"onCancelWithArguments");
    return nil;
}

@end
