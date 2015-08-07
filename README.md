# xmos_virtual_address
sw emulated segmentation and memory map implementation by virtual address resolver.
The code is experimental, in heavy development :) state.

I shared this project only for further discussion, sharing ideas, and help each-other.

Paging/memmap strategy could be some:

a) modelling (emulating) a segmented + mapped memory modell which fits the requirements (algorithmic way based on alive hw implementations)

b) use special case of "integer model", "dictionary" (data structure theory) addapted to xmos enviroment. 


Virtual ADDRESS

Bit 31 is allways 1

Bits 24..30 (7bits) page address. (7F reserved for OTP ROM, 00 reserved for Local Tile's RAM)

Bits 00..23 (24bits) 16Mbyte address space for a segment offset.

Predefined Physical addresses on Each tile

OTP ROM 0xffff c000 - dffff		8kByte

RAM     0x0001 0000 - 0x1FFFF  64kByte