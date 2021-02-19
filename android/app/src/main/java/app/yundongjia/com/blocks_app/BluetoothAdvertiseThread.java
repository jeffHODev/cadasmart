package app.yundongjia.com.blocks_app;

import android.bluetooth.BluetoothAdapter;
import android.bluetooth.BluetoothManager;
import android.bluetooth.le.AdvertiseCallback;
import android.bluetooth.le.AdvertiseData;
import android.bluetooth.le.AdvertiseSettings;
import android.bluetooth.le.BluetoothLeAdvertiser;
import android.content.Context;
import android.util.Log;

import com.example.nirjon.bledemo4_advertising.util.BLEUtils;

import static android.bluetooth.le.AdvertiseSettings.ADVERTISE_MODE_LOW_LATENCY;
import static android.bluetooth.le.AdvertiseSettings.ADVERTISE_TX_POWER_HIGH;
import static android.bluetooth.le.AdvertisingSetCallback.ADVERTISE_SUCCESS;

///////////////////
//蓝牙广播线程
class BluetoothAdvertiseThread extends AdvertiseCallback implements Runnable{


    private byte commandDatas[] = new byte[16];
    private byte addressData[] = {0X43,0X41,0X52};// 广播地址
    private byte[] lastDatas = new byte[16];
    private long laststamp = 0;
    private static final int BLE_PAYLOAD_LENGTH = 24;
    private byte[] calculatedPayload = new byte[BLE_PAYLOAD_LENGTH];

    private static long lasttime= 0;
    private boolean advertising = false;

    private AdvertiseSettings myAdvertiseSettings = new AdvertiseSettings.Builder()
            .setAdvertiseMode(ADVERTISE_MODE_LOW_LATENCY)
            .setConnectable(true)
            .setTimeout(0)
            .setTxPowerLevel(ADVERTISE_TX_POWER_HIGH)
            .build();


    private BluetoothLeAdvertiser myAdvertiser;
    private AdvertiseData myAdvertiseData;
    private BluetoothAdapter adapter;
    public AdvertiseData.Builder builder = new AdvertiseData.Builder();
    private Context context;


    BluetoothAdvertiseThread(Context context) {
        this.context = context;
        initAdvertiser();
    }
    void initAdvertiser(){
        BluetoothManager manager = (BluetoothManager)context.getSystemService(context.BLUETOOTH_SERVICE);
        adapter = manager.getAdapter();
        if(!adapter.isEnabled()){
            adapter.enable();
        }
        myAdvertiser = adapter.getBluetoothLeAdvertiser();
    }



    private void fillData(){
        //setMatchDevice(lastaddress);
        //填充地址
        int deviceAddress = BluetoothData.bluetoothDataCallback.getLastAddress();
        byte[] byes = BinaryUtils.intToByte(deviceAddress,3);
        System.arraycopy(byes,0,BluetoothData.controlerBytes,2,3);
        System.arraycopy(byes,0,BluetoothData.advertiseBytes,2,3);

        //控制模式
        if(BluetoothData.currentStatus == BleStatus.STATUS_CONTROL) {
            BluetoothData.controlerBytes[1] = BluetoothData.MODE_MUTIL_SUPPORT?0x14:0x13;
            System.arraycopy(BluetoothData.controlerBytes,0,commandDatas,0,commandDatas.length);

            //配对模式
        }else if(BluetoothData.currentStatus == BleStatus.STATUS_PAIR){
            BluetoothData.advertiseBytes[1] = 0x10; //00010000
            System.arraycopy(BluetoothData.advertiseBytes,0,commandDatas,0,commandDatas.length);

            // 配对模式
        }else if(BluetoothData.currentStatus == BleStatus.STATUS_PAIRING){//
            BluetoothData.advertiseBytes[1] = 0x10; //00010000
            System.arraycopy(BluetoothData.advertiseBytes,0,commandDatas,0,commandDatas.length);

            //解除配对
        }else if(BluetoothData.currentStatus == BleStatus.STATUS_UNPAIRING){
            BluetoothData.advertiseBytes[1] = BluetoothData.MODE_MUTIL_SUPPORT?0x16:0x17;
            System.arraycopy(BluetoothData.advertiseBytes,0,commandDatas,0,commandDatas.length);
        }else{
            BluetoothData.advertiseBytes[1] = 0x10; //00010000
            System.arraycopy(BluetoothData.advertiseBytes,0,commandDatas,0,commandDatas.length);
        }
    }

    private void fillAdvertiseDat() {


        fillData();

        //Log.d(TAG, "蓝牙广播数据 命令:" + BinaryUtils.byteToStr(commandDatas));
        BLEUtils.get_rf_payload(addressData, addressData.length, commandDatas, commandDatas.length, calculatedPayload);


        //myAdvertiseData = new AdvertiseData.Builder().addManufacturerData(65520, calculatedPayload).build();
        myAdvertiseData = builder.addManufacturerData(0xC200, calculatedPayload).build();
    }


    @Override
    public void run(){
        Log.d(BluetoothData.TAG,"蓝牙广播开始");

        if(BluetoothData.DEBUG){
            return;
        }

        while(true){

            if(BluetoothData.advertiseExit){
                Log.d(BluetoothData.TAG,"蓝牙广播退出"+" ThreadID="+Thread.currentThread().getId());
                myAdvertiser.stopAdvertising(this);
                return;
            }

            BluetoothData.sendCommand();
            //加入广播数据
            fillAdvertiseDat();


            try {

                if (addressData != null) {


                    if (myAdvertiser == null) {
                        initAdvertiser();
                        Thread.sleep(5);
                        continue;
                    }

                    long localTimestamp = System.currentTimeMillis();

//                        if(localTimestamp -  advertiseTimestamp > 18000 ){
//                            changed = true;
//                        }


                    //myAdvertiser.stopAdvertising(myAdvertiseCallback);

                    if(BluetoothData.changed) {
                        synchronized (BluetoothData.class) {
                            BluetoothData.changed = false;
                            BluetoothData.advertiseTimestamp = localTimestamp;
                            myAdvertiser.stopAdvertising(this);
                            //Log.d(BluetoothData.TAG, "蓝牙广播数据 命令:" + BinaryUtils.byteToStr(commandDatas) + " ThreadID=" + Thread.currentThread().getId());
                            myAdvertiser.startAdvertising(myAdvertiseSettings, myAdvertiseData, this);
                        }

                        //System.arraycopy(commandDatas,0,lastDatas,0,16);

                        //Thread.sleep(100);
                    }


                    //Log.i(TAG,"BleAdvertiseThread runing threadid=" + getId());

                } else {
                    Log.d(BluetoothData.TAG, "commandData is null or addressData is null");
                }
                Thread.sleep(50);
            } catch (Exception e) {
                Log.e(BluetoothData.TAG,"蓝牙广播出错 " + e.getMessage());
            }


        }

    }


    @Override
    public void onStartSuccess(AdvertiseSettings settingsInEffect) {
        super.onStartSuccess(settingsInEffect);
        long current = System.currentTimeMillis();

        if(BluetoothData.DEBUG_COMMAND){
            LogUtils.print("发送成功                              " + BinaryUtils.byteToStr(BluetoothData.controlerBytes));
        }
        //Log.i(BluetoothData.TAG,"蓝牙广播回调成功 " + getErrorMessage(ADVERTISE_SUCCESS)  +"time = "+ current + " last= "+lasttime  +" escape = " + (current-lasttime));
        lasttime = current;
        advertising = true;
    }
    @Override
    public void onStartFailure(int errorCode) {
        super.onStartFailure(errorCode);
        long current = System.currentTimeMillis();
        Log.e(BluetoothData.TAG,"蓝牙广播回调失败 " + getErrorMessage(errorCode)  +" time=" + current + " last= "+lasttime  +" escape = " + (current-lasttime));
        lasttime = current;
        if(errorCode!=ADVERTISE_SUCCESS){
            myAdvertiser.stopAdvertising(this);
        }
        //advertising = false;
    }

    private String getErrorMessage( int errorCode){

        String result = "未知错误";
        switch(errorCode){
            case ADVERTISE_SUCCESS: result = "广播成功"; break;
            case ADVERTISE_FAILED_ALREADY_STARTED: result =  "广播已启动了 ADVERTISE_FAILED_ALREADY_STARTED";break;
            case ADVERTISE_FAILED_DATA_TOO_LARGE: result =  "广播数据包太大 ADVERTISE_FAILED_DATA_TOO_LARGE";break;
            case ADVERTISE_FAILED_FEATURE_UNSUPPORTED: result =  "广播不支持 ADVERTISE_FAILED_FEATURE_UNSUPPORTED";break;
            case ADVERTISE_FAILED_INTERNAL_ERROR: result =  "广播内部错误 ADVERTISE_FAILED_INTERNAL_ERROR";break;
            case ADVERTISE_FAILED_TOO_MANY_ADVERTISERS: result =  "广播太多的广播者 ADVERTISE_FAILED_TOO_MANY_ADVERTISERS";break;
        }
        return result;

    }

}
