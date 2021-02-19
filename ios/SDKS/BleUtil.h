#ifndef BleUtil_h
#define BleUtil_h
#include "whitening.h"
#include "crc16.h"
//#import <UIKit/UIKit.h>

//37 38->2426 39->2480
#define BLE_CHANNEL_INDEX    38

//#define PDU_EXHEADER_LENGTH    13
//#define PDU_EXHEADER_LENGTH    ([[[UIDevice currentDevice] systemVersion] floatValue] >= 13.0f?:16:13)

#define PREAMBLE_LENGTH        3
#define CRC_LENGTH            2

//#ifdef __cplusplus
//extern "C" {
//#endif
void get_rf_payload(const unsigned char *address, int address_length,            // input:    address
                    const unsigned char *rf_payload, int rf_payload_width,        // input:    payload data (xn297l)
                    unsigned char *output_ble_payload,int pdu_exheader_length);                            // output:    BLE additional data
//#ifdef __cplusplus
//}
//#endif

#endif /* BleUtil_h */
