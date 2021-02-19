#ifndef _M_CRC_16_H
#define _M_CRC_16_H

unsigned char invert_8(unsigned char data);
unsigned short check_crc16(const unsigned char *addr, unsigned char addr_length, const unsigned char *rf_payload, unsigned char payload_width);

#endif
