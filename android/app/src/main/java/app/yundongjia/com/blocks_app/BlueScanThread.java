package app.yundongjia.com.blocks_app;

import android.bluetooth.BluetoothAdapter;
import android.bluetooth.BluetoothManager;
import android.bluetooth.le.BluetoothLeScanner;
import android.bluetooth.le.ScanFilter;
import android.content.Context;
import android.content.Intent;
import android.location.LocationManager;
import android.provider.Settings;
import android.util.Log;

import java.util.ArrayList;
import java.util.HashMap;
import java.util.List;
import java.util.Map;

/**
 * 蓝牙扫描线程类
 */
class BlueScanThread implements Runnable{
    private Context context;
    //private BluetoothManager manager;
    //private BluetoothAdapter adapter;
    private BluetoothLeScanner scanner;
    private int count;
    private List<ScanFilter> filters = new ArrayList<>();

    BlueScanThread(Context context){
        this.context = context;
        initScanner();
        //pauseScan = false;
    }

    private void initScanner(){

        BluetoothManager manager = (BluetoothManager)context.getSystemService(context.BLUETOOTH_SERVICE);
        BluetoothAdapter adapter = manager.getAdapter();
        if(!adapter.isEnabled()){
            adapter.enable();
        }
        //enableLocation();
        scanner  = adapter.getBluetoothLeScanner();
        count = 0;
        ScanFilter  scanFilter  = new ScanFilter.Builder().build();
        filters.add(scanFilter);
    }

    public boolean isLocServiceEnable() {
        LocationManager locationManager = (LocationManager)context.getSystemService(Context.LOCATION_SERVICE);
        boolean gps = locationManager.isProviderEnabled(LocationManager.GPS_PROVIDER);
        boolean network = locationManager.isProviderEnabled(LocationManager.NETWORK_PROVIDER);
        return gps || network;
    }

    private void enableLocation(){
        if(!isLocServiceEnable()) {
            Intent intent = new Intent();
            intent.setAction(Settings.ACTION_LOCATION_SOURCE_SETTINGS);
            intent.setFlags(Intent.FLAG_ACTIVITY_NEW_TASK);

            intent.setAction(Settings.ACTION_SETTINGS);
            context.startActivity(intent);
        }
    }


    public void run(){
        Log.d(BluetoothData.TAG,"蓝牙扫描启动");

        while(true){
            if(BluetoothData.scanExit){
                Log.d(BluetoothData.TAG,"蓝牙扫描退出 ThreadID="+Thread.currentThread().getId());
                scanner.stopScan(BluetoothData.scanStartCallback);
                return;
            }
            Log.d(BluetoothData.TAG,"蓝牙扫描 running");

            try {
                if(BluetoothData.DEBUG){
                    Map<String,int[]> map = new HashMap<>();
                    int[] pairedDivices = {1};
                    map.put("paireddevices",pairedDivices);
                    BluetoothData.bluetoothDataCallback.findDevices(map);
                    Thread.sleep(5);
                    continue;
                }
                if(scanner==null ){
                    initScanner();
                    Thread.sleep(5);
                    continue;
                }

                scanner.stopScan(BluetoothData.scanStartCallback);
                Thread.sleep(5);

                scanner.startScan(BluetoothData.scanStartCallback);
                Thread.sleep(5000);
                //return;

            }catch (InterruptedException e){
                Log.e(BluetoothData.TAG,e.toString());
                //return;
            }
        }
    }
}
