#include "crc16.h"

unsigned char invert_8(unsigned char data)
{
	unsigned char temp = 0;
	
	for (unsigned char i = 0; i < 8; i++)
	{
		if (data & (1 << i))
		{
			temp |= 1 << (7 - i);
		}
	}
	
	return temp;
}

unsigned short invert_16(unsigned short data)
{
	unsigned short temp = 0;
	
	for (unsigned char i = 0; i < 16; i++)
	{
		if (data & (1 << i))
		{
			temp |= 1 << (15 - i);
		}
	}
	
	return temp;
}

unsigned short check_crc16(const unsigned char *addr, unsigned char addr_length, const unsigned char *rf_payload, unsigned char payload_width)
{
	unsigned short crc = 0xFFFF;
	unsigned short poly = 0x1021;
	unsigned char input_byte = 0;
	
	for (unsigned char i = 0; i < addr_length; i++)
	{
		// Addr: invert endian
		input_byte = addr[addr_length - 1 - i];
		
		crc ^= (input_byte << 8);
		
		for (unsigned char j = 0; j < 8; j++)
		{
			if (crc & 0x8000)
			{
				crc = (crc << 1) ^ poly;
			}
			else
			{
				crc = (crc << 1);
			}
		}
	}
	
	for (unsigned char i = 0; i < payload_width; i++)
	{
		// Payload: invert bit order
		input_byte = invert_8(rf_payload[i]);
		
		crc ^= (input_byte << 8);
		
		for (unsigned char j = 0; j < 8; j++)
		{
			if (crc & 0x8000)
			{
				crc = (crc << 1) ^ poly;
			}
			else
			{
				crc = (crc << 1);
			}
		}
	}
	
	crc = invert_16(crc);
	
	return (crc ^ 0xFFFF);
}
