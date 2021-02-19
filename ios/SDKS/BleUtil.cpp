#include <string>
#include "BleUtil.h"

void get_rf_payload(const unsigned char *address, int address_length,            // input:    address
                    const unsigned char *rf_payload, int rf_payload_width,        // input:    payload data (xn297l)
                    unsigned char *output_ble_payload,int pdu_exheader_length)                            // output:    BLE additional data
{
    int PDU_EXHEADER_LENGTH = pdu_exheader_length;
    
    int whitening_reg_ble[7] = {0, };
    int whitening_reg_297[7] = {0, };
    
    whitening_init(BLE_CHANNEL_INDEX, whitening_reg_ble);
    whitening_init(0x3F, whitening_reg_297);
    
    unsigned char *ble_payload;
    ble_payload = new unsigned char[PDU_EXHEADER_LENGTH + PREAMBLE_LENGTH + address_length + rf_payload_width + CRC_LENGTH];
    
    /*** Step1. copy pre, address and rf payload ***/
    ble_payload[PDU_EXHEADER_LENGTH + 0] = 0x71;
    ble_payload[PDU_EXHEADER_LENGTH + 1] = 0x0F;
    ble_payload[PDU_EXHEADER_LENGTH + 2] = 0x55;
    
    for (int i = 0; i < address_length; i++)
    {
        ble_payload[PDU_EXHEADER_LENGTH + PREAMBLE_LENGTH + i] = address[address_length - i -1];
    }
    
    for (int i = 0; i < rf_payload_width; i++)
    {
        ble_payload[PDU_EXHEADER_LENGTH + PREAMBLE_LENGTH + address_length + i] = rf_payload[i];
    }
    
    /*** Step2. xn297l bit invert ***/
    for (int i = 0; i < PREAMBLE_LENGTH + address_length; i++)
    {
        ble_payload[PDU_EXHEADER_LENGTH + i] = invert_8(ble_payload[PDU_EXHEADER_LENGTH + i]);
    }
    
    /*** Step3. add crc16 ***/
    int crc = check_crc16(address, address_length, rf_payload, rf_payload_width);
    
    ble_payload[PDU_EXHEADER_LENGTH + PREAMBLE_LENGTH + address_length + rf_payload_width + 0] = crc & 0xFF;
    ble_payload[PDU_EXHEADER_LENGTH + PREAMBLE_LENGTH + address_length + rf_payload_width + 1] = (crc >> 8) & 0xFF;
    
    /*** Step4. xn297l whitening ***/
    whitening_encode(ble_payload + PDU_EXHEADER_LENGTH + PREAMBLE_LENGTH, address_length + rf_payload_width + CRC_LENGTH, whitening_reg_297);
    
    /*** Step5. BLE whitening ***/
    whitening_encode(ble_payload, PDU_EXHEADER_LENGTH + PREAMBLE_LENGTH + address_length + rf_payload_width + CRC_LENGTH, whitening_reg_ble);
    
    memcpy(output_ble_payload, ble_payload + PDU_EXHEADER_LENGTH, PREAMBLE_LENGTH + address_length + rf_payload_width + CRC_LENGTH);
    delete[] ble_payload;
}
