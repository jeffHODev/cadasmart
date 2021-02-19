
package app.yundongjia.com.blocks_app;

import android.content.Context;
import android.util.Log;

import java.io.File;
import java.io.FileOutputStream;
import java.io.IOException;
import java.io.OutputStreamWriter;
import java.io.Writer;
import java.text.DateFormat;
import java.text.SimpleDateFormat;
import java.util.Date;
import java.util.Random;
import java.util.concurrent.ExecutorService;
import java.util.concurrent.Executors;

public class LogUtils {

    public static final int VERBOSE = 2;
    public static final int DEBUG = 3;
    public static final int INFO = 4;
    public static final int WARN = 5;
    public static final int ERROR = 6;
    public static final int ASSERT = 7;

    public static int LogLevel = INFO;
    private static boolean skipRepeat = true;
    private static String lastMsg = "";
    private static String gloablFilePath;
    private static FileOutputStream floablOS;
    private static ExecutorService executorService = Executors.newFixedThreadPool(3);
    private static DateFormat dateformat = new SimpleDateFormat("yyyy-MM-dd HH:mm:ss.S");

    private static boolean needPrint(int priority,String msg){
        if(msg==null || msg.length()<1){
            return false;
        }
        if(priority<LogLevel){
            return false;
        }
        if(skipRepeat){
            if(msg.equals(lastMsg)){
                return false;
            }else{
                lastMsg = msg;
                return true;
            }

        }else{
            return true;
        }
    }


    private static void printLog(int bufID, int priority, String tag, String msg) {
        executorService.execute(new Runnable() {
            @Override
            public void run() {
                try {
                    if(!needPrint(priority,msg)){
                        return;
                    }

                    android.util.Log.d(tag,msg);
                    Writer writer = new OutputStreamWriter(floablOS);
                    writer.write(tag);
                    writer.write(":");
                    writer.write(msg);
                    writer.write('\n');
                    writer.flush();
                }catch (IOException foe){
                    android.util.Log.e(tag,gloablFilePath+"文件不存在!");
                }
            }
        });
    }


    public static void print(String msg){
        executorService.execute(new Runnable() {
            @Override
            public void run() {
                try {
                    //android.util.Log.i("LogUtils","Write");
                    Writer writer = new OutputStreamWriter(floablOS);
                    writer.write(dateformat.format(new Date()));
                    writer.write(":");
                    writer.write(msg);
                    writer.write('\n');
                    writer.flush();
                }catch (IOException foe){
                    android.util.Log.e("LogUtils",gloablFilePath+"文件不存在!");
                }
            }
        });
    }




    public static void initFineName(Context context, String filename,boolean skiprepeat){

        skipRepeat = skiprepeat;

        if(floablOS==null){
            File directory  = context.getExternalFilesDir(null);
            if(!directory.exists()){
                directory.mkdirs();
            }
            //File file = new File(directory,filename);
            gloablFilePath =  directory.getAbsolutePath()+"/"+filename;
            Log.i("LogUtils","gloablFilePath="+gloablFilePath);


            try {
                floablOS = new FileOutputStream(gloablFilePath,true);
                floablOS.write("start".getBytes());
                LogUtils.print("=============");
            }catch (IOException fos){
                android.util.Log.e("LogUtils",fos.getMessage());
            }

        }
    }


    public static void initFineName(Context context, String filename){
        initFineName(context,filename,false);
    }

    private LogUtils() {
    }

    /**
     * Send a {@link #VERBOSE} log message.
     * @param tag Used to identify the source of a log message.  It usually identifies
     *        the class or activity where the log call occurs.
     * @param msg The message you would like logged.
     */
    public static int v(String tag, String msg) {
        return println_native(LOG_ID_MAIN, VERBOSE, tag, msg);
    }

    /**
     * Send a {@link #VERBOSE} log message and log the exception.
     * @param tag Used to identify the source of a log message.  It usually identifies
     *        the class or activity where the log call occurs.
     * @param msg The message you would like logged.
     * @param tr An exception to log
     */
    public static int v(String tag, String msg, Throwable tr) {
        return printlns(LOG_ID_MAIN, VERBOSE, tag, msg, tr);
    }

    /**
     * Send a {@link #DEBUG} log message.
     * @param tag Used to identify the source of a log message.  It usually identifies
     *        the class or activity where the log call occurs.
     * @param msg The message you would like logged.
     */
    public static int d(String tag, String msg) {
        return println_native(LOG_ID_MAIN, DEBUG, tag, msg);
    }

    /**
     * Send a {@link #DEBUG} log message and log the exception.
     * @param tag Used to identify the source of a log message.  It usually identifies
     *        the class or activity where the log call occurs.
     * @param msg The message you would like logged.
     * @param tr An exception to log
     */
    public static int d(String tag, String msg, Throwable tr) {
        return printlns(LOG_ID_MAIN, DEBUG, tag, msg, tr);
    }

    /**
     * Send an {@link #INFO} log message.
     * @param tag Used to identify the source of a log message.  It usually identifies
     *        the class or activity where the log call occurs.
     * @param msg The message you would like logged.
     */
    public static int i(String tag, String msg) {
        return println_native(LOG_ID_MAIN, INFO, tag, msg);
    }

    /**
     * Send a {@link #INFO} log message and log the exception.
     * @param tag Used to identify the source of a log message.  It usually identifies
     *        the class or activity where the log call occurs.
     * @param msg The message you would like logged.
     * @param tr An exception to log
     */
    public static int i(String tag, String msg, Throwable tr) {
        return printlns(LOG_ID_MAIN, INFO, tag, msg, tr);
    }

    /**
     * Send a {@link #WARN} log message.
     * @param tag Used to identify the source of a log message.  It usually identifies
     *        the class or activity where the log call occurs.
     * @param msg The message you would like logged.
     */
    public static int w(String tag, String msg) {
        return println_native(LOG_ID_MAIN, WARN, tag, msg);
    }

    /**
     * Send a {@link #WARN} log message and log the exception.
     * @param tag Used to identify the source of a log message.  It usually identifies
     *        the class or activity where the log call occurs.
     * @param msg The message you would like logged.
     * @param tr An exception to log
     */
    public static int w(String tag, String msg, Throwable tr) {
        return printlns(LOG_ID_MAIN, WARN, tag, msg, tr);
    }


    /*
     * Send a {@link #WARN} log message and log the exception.
     * @param tag Used to identify the source of a log message.  It usually identifies
     *        the class or activity where the log call occurs.
     * @param tr An exception to log
     */
    public static int w(String tag, Throwable tr) {
        return printlns(LOG_ID_MAIN, WARN, tag, "", tr);
    }

    /**
     * Send an {@link #ERROR} log message.
     * @param tag Used to identify the source of a log message.  It usually identifies
     *        the class or activity where the log call occurs.
     * @param msg The message you would like logged.
     */
    public static int e(String tag, String msg) {
        return println_native(LOG_ID_MAIN, ERROR, tag, msg);
    }

    /**
     * Send a {@link #ERROR} log message and log the exception.
     * @param tag Used to identify the source of a log message.  It usually identifies
     *        the class or activity where the log call occurs.
     * @param msg The message you would like logged.
     * @param tr An exception to log
     */
    public static int e(String tag, String msg, Throwable tr) {
        return printlns(LOG_ID_MAIN, ERROR, tag, msg, tr);
    }



    /**
     * Low-level logging call.
     * @param priority The priority/type of this log message
     * @param tag Used to identify the source of a log message.  It usually identifies
     *        the class or activity where the log call occurs.
     * @param msg The message you would like logged.
     * @return The number of bytes written.
     */
    public static int println(int priority, String tag, String msg) {
        return println_native(LOG_ID_MAIN, priority, tag, msg);
    }

    /** @hide */ public static final int LOG_ID_MAIN = 0;

    /** @hide */
    public static int println_native(int bufID, int priority, String tag, String msg){

        if(gloablFilePath==null) {
            return android.util.Log.println(priority, tag, msg);
        }else{
            //android.util.Log.d("TAG",gloablFilePath);
            printLog(bufID,priority,tag,msg);
        }
        return 0;

    }



    /**
     * Return the maximum payload the log daemon accepts without truncation.
     * @return LOGGER_ENTRY_MAX_PAYLOAD.
     */
    private static native int logger_entry_max_payload_native();

    /**
     * Helper function for long messages. Uses the LineBreakBufferedWriter to break
     * up long messages and stacktraces along newlines, but tries to write in large
     * chunks. This is to avoid truncation.
     * @hide
     */
    public static int printlns(int bufID, int priority, String tag, String msg,
                               Throwable tr) {
        Random random = new Random();
        int i  = random.nextInt();
        msg = msg+"#"+i;
        println_native(bufID,priority,tag,msg);
        if(tr!=null){
            println_native(bufID,priority,tag,tr.getLocalizedMessage());
        }

        return 0;

    }


}
