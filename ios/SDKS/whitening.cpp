#include "whitening.h"

void whitening_init(int index, int *reg)
{
	reg[0] = 1;
	
	for (int i = 1; i < 7; i++)
	{
		reg[i] = (index >> (6 - i)) & 0x01;
	}
}

int whitening_output(int *reg)
{
	int temp = reg[3] ^ reg[6];
	
	reg[3] = reg[2];
	reg[2] = reg[1];
	reg[1] = reg[0];
	reg[0] = reg[6];
	reg[6] = reg[5];
	reg[5] = reg[4];
	reg[4] = temp;
	
	return reg[0];
}

void whitening_encode(unsigned char *data, int length, int *reg)
{
	for (int data_index = 0; data_index < length; data_index++)
	{
		int data_input = data[data_index];
		int data_bit = 0;
		int data_output = 0;
		
		for (int bit_index = 0; bit_index < 8; bit_index++)
		{
			data_bit = (data_input >> (bit_index)) & 0x01;
			
			data_bit ^= whitening_output(reg);
			
			data_output += (data_bit << (bit_index));
		}
		
		data[data_index] = data_output;
	}
}
