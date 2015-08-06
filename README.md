# xmos_virtual_address
sw emulated segmentation and memory map implementation by virtual address resolver.
The code is experimental, in heavy development :) state.

I shared this project only for further discussion, sharing ideas, and help each-other.

Paging/memmap strategy could be some:
a) modelling (emulating) a segmented + mapped memory modell which fits the requirements (algorithmic way based on alive hw implementations)
b) use special case of "integer model", "dictionary" (data structure theory) addapted to xmos enviroment. 