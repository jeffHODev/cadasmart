package app.yundongjia.com.blocks_app;

import android.bluetooth.BluetoothDevice;
import android.bluetooth.le.ScanCallback;
import android.bluetooth.le.ScanRecord;
import android.bluetooth.le.ScanResult;
import android.content.Context;
import android.util.Log;

import com.example.nirjon.bledemo4_advertising.util.BLEUtils;

import java.io.File;
import java.io.FileInputStream;
import java.io.FileOutputStream;
import java.io.IOException;
import java.util.ArrayList;
import java.util.HashMap;
import java.util.Hashtable;
import java.util.List;
import java.util.Map;
import java.util.Random;
import java.util.Set;
import java.util.Timer;
import java.util.TimerTask;

public class BluetoothData {

    protected static final String TAG ="BluetoothData";
    protected static final boolean DEBUG = false;
    protected static final boolean DEBUG_COMMAND = false;
    private static BluetoothData instance;

    private static final String FileName = "MobileSerail.dat";
    private static final String DeviceFileName = "DeviceSerail.dat";
//    private static final long MatchTimeOut = 1500L;
//    private static Timer commandTimer;
//    private static boolean advertising = false;
    private static Context defaultContext = null;
    private static boolean bounded = false;
    private static int serial;

    protected static boolean scanExit;
    protected static boolean advertiseExit;

    private static long EXPIETIME = 3000L;
    private static int PAYLOAD_PAIR_LEN = 16;
    private static int PAYLOAD_CROL_LEN = 16;

    private static int PACKAGE_PAIR_HEAD = 0xC0; //配对开头
    private static int PACKAGE_PAIRD_HEAD = 0xE5; //已配对开头
    private static int PACKAGE_PAIR_END  = 0x3F; //配对结尾
    private static int PACKAGE_PAIR_RECEIVE_HEAD = 0xA0; //配对开头
    private static int PACKAGE_UNPAIR_RECEIVE_HEAD = 0xE0; //取消配对开头
    private static int PACKAGE_CONTROL_HEAD =  0x75; //控制HEAD

    protected static final boolean MODE_MUTIL_SUPPORT = false;


    protected static byte controlerBytes[] = new byte[PAYLOAD_CROL_LEN];
    protected static byte advertiseBytes[] = new byte[PAYLOAD_PAIR_LEN];

    private static Map<Integer,Long> pairedDeviceMap = new Hashtable<>();
    private static Map<Integer,Long> unpairDeviceMap = new Hashtable<>();
    protected static BluetoothDataCallback bluetoothDataCallback;
    private static int horizontalValue = 0x80;
    private static int verticalValue = 0x80;
    private static int lightValue = 0x00;
    private static int matchDevice = 0;

    private static List<byte[]>matchQueue = new ArrayList<>();

    protected static BleStatus currentStatus;


    public Thread scanThread;
    public Thread advertiseThread;
    protected static boolean changed = true;
    protected static long advertiseTimestamp = 0l;
    private static String lastSendCommand = "";

    private BluetoothData(){

    }

    public static void initializeStatus(Context context, BluetoothDataCallback callback){
        //默认调节速度及初始化状态

        Log.i(TAG,"initializeStatus 调用");
        defaultContext = context;
        bluetoothDataCallback = callback;
        currentStatus = BleStatus.STATUS_STOP;

        initCrolCommand(context);

            //加载历史设备地址
//            loadLastConnectedDevice();
        if(DEBUG_COMMAND){
            LogUtils.initFineName(context,"ble.txt");
        }

    }



    private static void initCrolCommand(Context context){
        controlerBytes[0] = (byte)PACKAGE_CONTROL_HEAD; //控制命令
        controlerBytes[1] = (byte)0x00;
        controlerBytes[2] = (byte)0x00;   //设备ID
        controlerBytes[3] = (byte)0x00;   //设备ID
        controlerBytes[4] = (byte)0x00;   //设备ID
        controlerBytes[5] = (byte)0x00;   //APP手机地址
        controlerBytes[6] = (byte)0x00;   //APP手机地址
        controlerBytes[7] = (byte)0x00;   //APP手机地址
        controlerBytes[8] = (byte)0x00;   //KEY1
        controlerBytes[9] = (byte)0x00;   //KEY2
        controlerBytes[10] = (byte)0x80;  //DATA1
        controlerBytes[11] = (byte)0x80;  //DATA2
        controlerBytes[12] = (byte)0x00;  //DATA3
        controlerBytes[13] = (byte)0x00;  //DATA4
        controlerBytes[14] = (byte)0x00;  //DATA5
        controlerBytes[15] = (byte)0x00;  //DATA6

        advertiseBytes[0] = (byte)PACKAGE_CONTROL_HEAD; //控制命令
        advertiseBytes[1] = (byte)0x00;
        advertiseBytes[2] = (byte)0x00;   //设备ID
        advertiseBytes[3] = (byte)0x00;   //设备ID
        advertiseBytes[4] = (byte)0x00;   //设备ID
        advertiseBytes[5] = (byte)0x00;   //APP手机地址
        advertiseBytes[6] = (byte)0x00;   //APP手机地址
        advertiseBytes[7] = (byte)0x00;   //APP手机地址
        advertiseBytes[8] = (byte)0x00;   //KEY1
        advertiseBytes[9] = (byte)0x00;   //KEY2
        advertiseBytes[10] = (byte)0x80;  //DATA1
        advertiseBytes[11] = (byte)0x80;  //DATA2
        advertiseBytes[12] = 0x00;  //DATA3
        advertiseBytes[13] = 0x00;  //DATA4
        advertiseBytes[14] = 0x00;  //DATA5
        advertiseBytes[15] = 0x00;  //DATA6

        //[advertiser setPayload:controlerBytes OfLength:PAYLOAD_CROL_LEN];
        //getOrCreateAddress(context);
        fillDeviceSerail(context);
    }

    private static int getOrCreateAddress(Context context){
        //int serial = 0;
        if(context==null){
            return serial;
        }
        File file = new File(context.getFilesDir(),FileName);
        try {
            if (file.exists()) {
                FileInputStream fis = context.openFileInput(FileName);
                byte[] buffer = new byte[3];
                fis.read(buffer);
                serial = BinaryUtils.byteToInt(buffer,0,3);

            } else {
                serial = new Random().nextInt();
                FileOutputStream fos = context.openFileOutput(FileName, Context.MODE_PRIVATE);
                byte[] buffer = BinaryUtils.intToByte(serial,3);
                fos.write(buffer);

            }
        }catch (IOException ioe){
            Log.e(TAG,"保存文件失败:" + ioe.toString());
        }
        return serial;
    }
    /**
     * 获取本机的配对码
     * 发送本机的生成的随机数, 如果不存在则生成已随机数, 并保存到手机端
     * @param context
     * @return
     */
    private static void fillDeviceSerail(Context context){
        int appId = getOrCreateAddress(context);
        byte[] byes = BinaryUtils.intToByte(appId,3);
        System.arraycopy(byes,0,controlerBytes,5,3);
        System.arraycopy(byes,0,advertiseBytes,5,3);

        //历史设备ID
        //loadLastConnectedDevice();
        int lastaddress = bluetoothDataCallback.getLastAddress();
        byes  = BinaryUtils.intToByte(lastaddress,3);
        System.arraycopy(byes,0,advertiseBytes,2,3);

    }

    public static void setData(int index, byte value) {
//        synchronized (controlerBytes) {
            controlerBytes[index] = value;
//        }
    }


    public static void setHorizonalValue(int num) {
        horizontalValue = num;
        //changed = true;
    }

    public static void setVerticalValue(int num) {
        verticalValue = num;
        //changed = true;
    }

    public static void setLightValue(int num) {
        lightValue = num;
        //changed = true;
    }


    public static void sendCommand() {

        byte[] data = {0,0,(byte)verticalValue,(byte)horizontalValue,(byte)lightValue,0,0,0};
        String sendCommandStr = BinaryUtils.byteToStr(data);


        int random = (int)(Math.random()* 100000);

        data[0] = (byte)(random &0xFF);
        data[1] = (byte)((random >>8) & 0xFF);

        BLEUtils.encry(data);

        synchronized (BluetoothData.class) {
            System.arraycopy(data, 0, controlerBytes, 8, 8);
            if(!sendCommandStr.equals(lastSendCommand)){
                lastSendCommand = sendCommandStr;
                changed = true;
            }
        }

        //Log.i(TAG,"等待发送 "+ sendCommandStr+ " =>  " + BinaryUtils.byteToStr(controlerBytes));
        if(DEBUG_COMMAND){
            LogUtils.print("等待发送 "+ sendCommandStr+ " =>  " + BinaryUtils.byteToStr(controlerBytes));
        }

    }

    public static void unpair() {
        //currentStatus = BleStatus.STATUS_UNPAIRING;
        byte[] byes = BinaryUtils.intToByte(matchDevice,3);
        System.arraycopy(byes,0,advertiseBytes,2,3);
        Log.i(TAG,"解除配对 "+matchDevice);
        pairedDeviceMap.remove(matchDevice);

        new Timer().schedule(new TimerTask() {
            @Override
            public void run() {
                currentStatus = BleStatus.STATUS_PAIRING;
            }
        },3000);

    }

    public static BluetoothData getInstance(){
        if(instance==null){
            instance = new BluetoothData();
        }
        return instance;
    }

    public static void startScan() {
        getInstance().instanceStartScan();
    }

    public static void stopScan(){
        getInstance().instanceStopScan();
    }

    //开始扫描
    public void instanceStartScan() {

        synchronized(BluetoothData.class)
        {
            if (advertiseThread == null) {
                advertiseExit = false;
                advertiseThread = new Thread(new BluetoothAdvertiseThread(defaultContext));//new BluetoothAdvertiseThread(defaultContext);
                advertiseThread.start();
            }
            //stopScan();
            if (scanThread == null) {
                scanExit = false;
                scanThread = new Thread(new BlueScanThread(defaultContext));
                scanThread.start();
            }

        }
    }

    //停止扫描
    public void instanceStopScan() {
        synchronized(BluetoothData.class) {
            scanExit = true;
            advertiseExit = true;
            if (scanThread != null) {
                //Log.i(TAG,"停止蓝牙扫描");
                scanThread = null;
            }
            if (advertiseThread != null) {
                //((BluetoothAdvertiseThread)advertiseThread).stopAdvertise();
                advertiseThread = null;
            }
        }
    }



    //蓝牙回调
    // 解析设备端的地址
    private static void processAddress(BluetoothDevice device, byte[] scanRecord){


        //Log.d(TAG,"processAddress address= " + device.getAddress() + " scanRecord = " + BinaryUtils.byteToStr(scanRecord)  );


        //头不匹配返回
        int head = (scanRecord[0]&0xFF);
        if(head!=PACKAGE_CONTROL_HEAD) {
            //Log.d(TAG,"返回 head!= "+ BinaryUtils.intToByteString(PACKAGE_CONTROL_HEAD,1));
            return;
        }



        //发包者跟接收者判断
        //NSLog(@"发包者跟接收者判断 = %X",buffer[3]);
        if(!((scanRecord[1]&0x40)>0)){
            //Log.d(TAG,"返回 发包者跟接收者!= "+(scanRecord[3]&0x40));
            return;
        }

        //Log.d(TAG, " 处理数据 scanRecord = " + BinaryUtils.byteToStr(scanRecord) );

        int type = (scanRecord[1]&0x01)>0?PACKAGE_PAIR_HEAD:PACKAGE_PAIRD_HEAD;

        byte[] deviceData = new byte[3];
        byte[] appData = new byte[3];
        System.arraycopy(scanRecord,2,deviceData,0,3);
        System.arraycopy(scanRecord,5,appData,0,3);


        processDvices(type,deviceData,appData);

    }


    //分类别处理设备， 未配对记录到未配对设备列表， 已配对的回复控制命令
    private static void processDvices(int type,byte[] deviceData, byte[] appData) {

        //TODO test
        //serial = 349912;
        //type = PACKAGE_PAIR_HEAD;
        //appData = BinaryUtils.intToByte(serial,3);

        //不是APPData时返回
        byte[] value = BinaryUtils.intToByte(serial,3);

        if(appData[0] != value[0] || appData[1] != value[1] || appData[2] != value[2]){
            //Log.d(TAG,"APPID不匹配返回");
            return;
        }

        int address = BinaryUtils.byteToInt(deviceData,0,3);
        if (type == PACKAGE_PAIR_HEAD) {
            //Log.d(TAG,"发现未配对设备  " + BinaryUtils.byteToStr(deviceData));
            pairedDeviceMap.remove(address);
            unpairDeviceMap.put(address, System.currentTimeMillis());
        } else if (type == PACKAGE_PAIRD_HEAD) {
            //Log.d(TAG,"发现已配对设备  "+ BinaryUtils.byteToStr(deviceData));
            unpairDeviceMap.remove(address);
            pairedDeviceMap.put(address, System.currentTimeMillis());

        }
        triggerDeviceEvent();

    }

    //保存设备地址
//    private static void saveLastConnectedDevice( byte[] deviceaddress){
//        Log.d(TAG,"保存最后配对的设备  "+ BinaryUtils.byteToStr(deviceaddress));
//        setAdvertiseDevice(BinaryUtils.byteToInt(deviceaddress,0,3));
//        File file = new File(defaultContext.getFilesDir(),DeviceFileName);
//        try {
//            FileOutputStream fos = defaultContext.openFileOutput(DeviceFileName, Context.MODE_PRIVATE);
//            fos.write(deviceaddress);
//        }catch (IOException ioe){
//            Log.e(TAG,"保存最后配对的设备  失败");
//        }
//    }

//    private static void loadLastConnectedDevice(){
//        File file = new File(defaultContext.getFilesDir(),DeviceFileName);
//        try {
//            if (file.exists()) {
//                FileInputStream fis = defaultContext.openFileInput(DeviceFileName);
//                byte[] buffer = new byte[3];
//                fis.read(buffer);
//                lastaddress =BinaryUtils.byteToInt(buffer,0,3);
//                Log.d(TAG,"加载最后配对的设备  "+ BinaryUtils.byteToStr(buffer));
//            }
//        }catch (IOException ioe){
//            Log.e(TAG,"读取文件失败:"+ioe.toString());
//        }
//
//    }

    private static void removeExpireDevices(Map<Integer,Long> map){
        List<Integer> expiredAddressList = new ArrayList<>();
        long current = System.currentTimeMillis() - EXPIETIME;
        for(Integer address : map.keySet() ){
            long time = map.get(address);
            if(time<current){
                expiredAddressList.add(address);
            }
        }

        for(Integer address : expiredAddressList ){
            map.remove(address);
        }
    }

    private static void triggerDeviceEvent(){

        removeExpireDevices(unpairDeviceMap);
        removeExpireDevices(pairedDeviceMap);
        if (bluetoothDataCallback != null) {
            Map<String,int[]> map = new HashMap<>();
            map.put("paireddevices",parseSetToArray(pairedDeviceMap.keySet()));
            map.put("unpairdevices",parseSetToArray(unpairDeviceMap.keySet()));
//            if(pairedDeviceMap.keySet().size()>0){
//                Log.d(TAG,"发现设备蓝牙配对设备 回调 Flutter");
//            }
//            if(unpairDeviceMap.keySet().size()>0){
//                Log.d(TAG,"发现设备蓝牙未配对设备 回调 Flutter");
//            }


            bluetoothDataCallback.findDevices(map);
        }

    }


    private static int[] parseSetToArray(Set<Integer> set){
        int[] result = new int[set.size()];
        int i = 0;
        for(Integer val : set){
            result[i] = val;
            i++;
        }
        return result;
    }


    protected static ScanCallback scanStartCallback = new ScanCallback() {
        @Override
        public void onScanResult(int callbackType, ScanResult result) {
            super.onScanResult(callbackType, result);
            //Log.i(TAG,"蓝牙扫描结果 回调类型 " + callbackType + " result = " + result.toString());
            ScanRecord record  =  result.getScanRecord();
            if(record==null){
                return;
            }
            byte[] bytes  = record.getManufacturerSpecificData(65520);
            if(bytes==null || bytes.length<16){
                return;
            }
            processAddress(result.getDevice(),bytes);

        }


        @Override
        public void onScanFailed(int errorCode) {
            super.onScanFailed(errorCode);
            Log.e(TAG,"蓝牙扫描失败" + getErrorDesc(errorCode));
        }

        private String getErrorDesc(int errorCode){
            String result = "未知错误";
            switch(errorCode){
                case SCAN_FAILED_ALREADY_STARTED: result = "扫描已经启动"; break;
                case SCAN_FAILED_APPLICATION_REGISTRATION_FAILED: result =  "SCAN_FAILED_APPLICATION_REGISTRATION_FAILED";break;
                case SCAN_FAILED_FEATURE_UNSUPPORTED: result =  "SCAN_FAILED_FEATURE_UNSUPPORTED";break;
                case SCAN_FAILED_INTERNAL_ERROR: result =  "SCAN_FAILED_INTERNAL_ERROR";break;
                case 5: result =  "SCAN_FAILED_OUT_OF_HARDWARE_RESOURCES";break;
                case 6: result =  "SCAN_FAILED_SCANNING_TOO_FREQUENTLY";break;
            }
            return result;
        }
    };





    ///////////////////
    /**
     * 查找到设备后的回调接口
     *  回调接口
     */
    interface BluetoothDataCallback {

        void findDevices(Map<String ,int[]> pairedDevices);
        int getLastAddress();

    }

    //#pragma mark - 蓝牙命令
    public static void setBleStauts(BleStatus status) {
        //Log.i(TAG,"setBleStauts status = " + status.name());
        synchronized (BluetoothData.class) {
            currentStatus = status;
            changed = true;
        }
    }

}

///////////////////////////

