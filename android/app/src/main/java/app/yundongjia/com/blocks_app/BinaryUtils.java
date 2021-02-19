package app.yundongjia.com.blocks_app;

public class BinaryUtils {

    public static String byteToStr(byte[] datas){
        StringBuffer sb = new StringBuffer();
        for(byte i : datas){
            sb.append("|");
            String str = String.format("%02X",i&0xFF);
            sb.append(str);
        }
        return sb.toString();
    };

    public static String intToByteString(int value,final int len) {
        byte result[] = new byte[len];
        for(int i=0;i<len;i++){
            result[i] = (byte)((value >> ((len -1 -i)*8))&0xFF);
        }
        return byteToStr(result);
    }

    public static byte[] intToByte(int value,final int len) {
        byte result[] = new byte[len];
        for(int i=0;i<len;i++){
            result[i] = (byte)((value >> ((len -1 -i)*8))&0xFF);
        }
        return result;
    }

    public static int byteToInt(byte[] arr ,int start ,int len ){
        return byteToInt(arr,start,len,true);
    }

    public static int byteToInt(byte[] arr ,int start ,int len ,boolean reverse){
        int result = 0;
        if(reverse){
            for (int i = 0; i < len; i++) {
                result |= ((arr[start + i] & 0xFF) << ((len -1 -i) * 8));
            }
        }else {
            for (int i = 0; i < len; i++) {
                result |= ((arr[start + i] & 0xFF) << (i * 8));
            }
        }
        return result;
    }
}
