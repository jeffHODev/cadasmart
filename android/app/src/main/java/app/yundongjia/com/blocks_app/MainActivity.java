package app.yundongjia.com.blocks_app;

import android.content.SharedPreferences;
import android.os.Bundle;
import android.os.Handler;
import android.os.Looper;
import androidx.annotation.NonNull;
import android.util.Log;

import java.util.Map;

import io.flutter.plugin.common.EventChannel;
import io.flutter.plugin.common.MethodCall;
import io.flutter.plugin.common.MethodChannel;
import io.flutter.plugins.GeneratedPluginRegistrant;

import io.flutter.embedding.android.FlutterActivity;
import io.flutter.embedding.engine.FlutterEngine;
import io.flutter.plugins.GeneratedPluginRegistrant;


public class MainActivity extends FlutterActivity {
    private static final String CHANNEL = "flutter.native/helper";
    private static final String TAG = MainActivity.class.getSimpleName();
    private static final String ToFlutterMethodCHANNEL = "com.yundongjia.blocks/connector";
    private static final String ToNativeMethodCHANNEL = "com.yundongjia.blocks/connector";
    private static final String toFlutterEventChannel = "com.yundongjia.blocks/finder";

    private static final String AddressName = "address";
    private static final String LastAddressName = "lastAddress";

    private EventChannel.EventSink eventSink;
    private MethodChannel nativeMethodChannel;
    private NativeMethodHander nativemethodHander = new NativeMethodHander();
    private StreamHandler toNativestreamHander = new StreamHandler();
    private EventChannel flutterEventChannel;
    private int lastAddress = 0;
    private ActivityStateEnum lastState = ActivityStateEnum.Initialize;


    private BluetoothData.BluetoothDataCallback bluetoothDataCallback = new BluetoothData.BluetoothDataCallback() {

        public void findDevices(Map<String, int[]> map) {
            sendEvent(map);
        }

        public int getLastAddress() {
            return lastAddress;
        }
    };

    private void sendEvent(Map<String, int[]> param) {
        if (eventSink == null) {
            //Log.d(TAG,"Stream eventSink 为空返回");
            return;
        }
        new Handler(Looper.getMainLooper()).post(new Runnable() {
            @Override
            public void run() {
                if (eventSink == null) {
                    return;
                }
                //Log.d(TAG,"Native 调用 Flutter 设备发现通知");
                eventSink.success(param);
                //}
            }
        });
    }

//    @Override
//    protected void onCreate(Bundle savedInstanceState) {
//        super.onCreate(savedInstanceState);
//        Log.i(TAG, "方法跟踪 onCreate");
//
//        loadLastAddress();
//        GeneratedPluginRegistrant.registerWith(this);
//
//        nativeMethodChannel = new MethodChannel(getFlutterView(), ToNativeMethodCHANNEL);
//        nativeMethodChannel.setMethodCallHandler(nativemethodHander);
//
//        flutterEventChannel = new EventChannel(getFlutterView(), toFlutterEventChannel);
//        flutterEventChannel.setStreamHandler(toNativestreamHander);
//
//    }


    @Override
    public void configureFlutterEngine(@NonNull FlutterEngine flutterEngine) {
        GeneratedPluginRegistrant.registerWith(flutterEngine);
        loadLastAddress();
        nativeMethodChannel = new MethodChannel(flutterEngine.getDartExecutor().getBinaryMessenger(), ToNativeMethodCHANNEL);
        nativeMethodChannel.setMethodCallHandler(nativemethodHander);

        flutterEventChannel = new EventChannel(flutterEngine.getDartExecutor().getBinaryMessenger(), toFlutterEventChannel);
        flutterEventChannel.setStreamHandler(toNativestreamHander);

    }

    @Override
    protected void onStart() {
        super.onStart();
        Log.i(TAG, "方法跟踪 onStart");
    }

    @Override
    protected void onStop() {
        Log.i(TAG, "方法跟踪 onStop");
        super.onStop();
        savePreferences();
    }

    @Override
    protected void onResume() {
        super.onResume();
        BluetoothData.initializeStatus(this, bluetoothDataCallback);
        if (lastState == ActivityStateEnum.Paused) {
            BluetoothData.startScan();
        }
        lastState = ActivityStateEnum.Resume;
        Log.i(TAG, "方法跟踪 onResume");
    }

    @Override
    protected void onDestroy() {
        Log.i(TAG, "方法跟踪 onDestroy");
        lastState = ActivityStateEnum.Destory;
        super.onDestroy();
    }

    @Override
    protected void onPause() {
        Log.i(TAG, "方法跟踪 onPause");
        BluetoothData.stopScan();
        lastState = ActivityStateEnum.Paused;
        super.onPause();
    }

    private void setLastAddress(int lastAddress) {
        if (this.lastAddress != lastAddress) {
            this.lastAddress = lastAddress;
            SharedPreferences sharedPreferences = getSharedPreferences(AddressName, MODE_PRIVATE);
            SharedPreferences.Editor editor = sharedPreferences.edit();
            editor.putInt(LastAddressName, this.lastAddress);
            editor.apply();
        }
    }

    private void savePreferences() {
        SharedPreferences sharedPreferences = getSharedPreferences(AddressName, MODE_PRIVATE);
        SharedPreferences.Editor editor = sharedPreferences.edit();
        editor.putInt(LastAddressName, this.lastAddress);
        editor.apply();
    }

    private void loadLastAddress() {
        SharedPreferences sharedPreferences = getSharedPreferences(AddressName, MODE_PRIVATE);
        this.lastAddress = sharedPreferences.getInt(LastAddressName, 0);
    }


    //////////////

    /**
     * Native 方法处理类
     */
    class NativeMethodHander implements MethodChannel.MethodCallHandler {
        @Override
        public void onMethodCall(MethodCall call, MethodChannel.Result result) {
            //Log.d(TAG,"Flutter 调用原生方法 {} "+ call.method);
            if ("getStatus".equals(call.method)) {
                //int batteryLevel = [weakSelf getStatus];
                //result(@(batteryLevel));

            } else if ("setHorizontal".equals(call.method)) {
                Integer num = (Integer) call.arguments;
                BluetoothData.setHorizonalValue(num);
                BluetoothData.setBleStauts(BleStatus.STATUS_CONTROL);
//        BluetoothData.sendCommand();
                result.success(0);

            } else if ("setVertical".equals(call.method)) {
                Integer num = (Integer) call.arguments;
                BluetoothData.setVerticalValue(num);
                BluetoothData.setBleStauts(BleStatus.STATUS_CONTROL);
//        BluetoothData.sendCommand();
                result.success(0);

            } else if ("setLight".equals(call.method)) {
                Integer num = (Integer) call.arguments;
                BluetoothData.setLightValue(num);
                BluetoothData.setBleStauts(BleStatus.STATUS_CONTROL);
//        BluetoothData.sendCommand();
                result.success(0);

            } else if ("pair".equals(call.method)) {
                Integer num = (Integer) call.arguments;
                BluetoothData.setHorizonalValue(0x80);
                BluetoothData.setVerticalValue(0x80);
                BluetoothData.setLightValue(0x00);
                setLastAddress(num);
                //BluetoothData.setAdvertiseDevice(num);
                //lastAddress = num;

                BluetoothData.setBleStauts(BleStatus.STATUS_CONTROL);
//        BluetoothData.sendCommand();
                //Log.i(TAG,"Flutter 调用 pair " + num);
                result.success(0);

            } else if ("setControl".equals(call.method)) {
                BluetoothData.setHorizonalValue(0x80);
                BluetoothData.setVerticalValue(0x80);
                BluetoothData.setLightValue(0x00);
                Integer num = (Integer) call.arguments;

                //BluetoothData.setMatchDevice(num!=null?num:lastAddress);
                BluetoothData.setBleStauts(BleStatus.STATUS_CONTROL);
                //Log.i(TAG,"Flutter 调用 setControl " + num);
//        BluetoothData.sendCommand();

                result.success(0);
            } else if ("setPairing".equals(call.method)) {
//        NSLog(@"调用配对中 setPairing");
//        [[BleConnector instance] setAdvertiseDevice:matachDevice];

                BluetoothData.setBleStauts(BleStatus.STATUS_PAIRING);
                result.success(0);

            } else if ("setUnpairing".equals(call.method)) {
//        NSLog(@"调用解绑 setUnpairing");
//            [self unpair];
                BluetoothData.setBleStauts(BleStatus.STATUS_UNPAIRING);
                BluetoothData.unpair();
                result.success(0);

            } else if ("setStop".equals(call.method)) {
                BluetoothData.setBleStauts(BleStatus.STATUS_STOP);
                result.success(0);

            } else if ("startBluetooth".equals(call.method)) {
                //TODO 启动蓝牙
                result.success(0);
            } else if ("startScan".equals(call.method)) {
                //启动
                BluetoothData.startScan();
                result.success(0);
            } else if ("stopScan".equals(call.method)) {
                BluetoothData.stopScan();
                result.success(0);
            } else {
                result.success(0);
            }

        }


    }

    //////////////

    /**
     * event回掉
     */
    class StreamHandler implements EventChannel.StreamHandler {
        //private String key;
        @Override
        public void onListen(Object arguments, EventChannel.EventSink events) {
            String key = (String) arguments;
            eventSink = events;

            BluetoothData.setBleStauts(BleStatus.STATUS_PAIRING);
            //BluetoothData.startScan();
            Log.d(TAG, "onListenWithArguments");

        }

        @Override
        public void onCancel(Object obj) {
            String key = (String) obj;
            Log.i(TAG, "flutter event cancel argums = " + obj);
            //sinkMap.remove(key);
            eventSink = null;
        }
    }

    /////////////

    /**
     * Activity State
     */
    enum ActivityStateEnum {
        Initialize, Resume, Stop, Paused, Destory
    }


}
