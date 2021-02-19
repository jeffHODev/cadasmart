#ifndef _WHITENING_ENCODER_H
#define _WHITENING_ENCODER_H

/**********************************************
 * channel index (BLE): 37		38		39
 * frequency (MHz):		2402	2426	2480
 *
 * channel index (XN297L): 0x3F (63)
***********************************************/

void whitening_init(int index, int *reg);
void whitening_encode(unsigned char *data, int length, int *reg);

//class WhiteningEncoder
//{
//public:
//	explicit WhiteningEncoder(int index);
//	~WhiteningEncoder();
//
//	void reset(int index = -1);
//	void encode(unsigned char *data, int length);
//
//private:
//	int channel_index;
//	int reg[7];
//
//	int getNextReg();
//};

#endif