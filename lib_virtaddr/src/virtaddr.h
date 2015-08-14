/*
 * virtaddr.h
 *
 *  Created on: 2015.07.31.
 *      Author: Barna Farago (MYND-ideal ltd)
 */


#ifndef VIRTADDR_H_
#define VIRTADDR_H_

#include "memory_extender.h"

//virtual address msb can point to n different segments
#define VIRTSEGMTABLE_MAX (8)
//virtual page pool size
#define VIRTPAGETABLE_MAX (8)

//page offset is the lsb n bits 0..(n-1)
#define VIRTADDR_BITS (24)
//page offset mask is the n lsb bits
#define VIRTADDR_OFFS_MASK ((1<<VIRTADDR_BITS)-1)
//page segm id is on the msb bits.
#define VIRTADDR_SEGM_MASK (~((1<<VIRTADDR_BITS)-1))

typedef enum{
  OT_INVALID,
  OT_LOCALRAM,  //no paging necessary (each request go trough chan/interface, no cache)
  OT_REMOTERAM, //probably a caching mechanishm may be required, but ... yeah...
  OT_SDRAM,     //planned to be cached
  OT_FILE,
  OT_FLASH,     //planned to be cached
  OT_ROM        //don't need really
} tOriginType;

typedef enum{
  PF_INVALID=1,   //free
  PF_AVAILABLE=2, //this window is registered
  PF_READONLY=4,  //store not posible to this memory window
  PF_MODIFIED=8,  //need to write before finished
  PF_REQUIRED=16  //need to read before populated
} tPageFlags;

interface memory_extender {
    void st8(uintptr_t address, unsigned data);
    void st16(uintptr_t address, unsigned data);
    void stw(uintptr_t address, unsigned data);
    uint8_t ld8u(uintptr_t address);
    int16_t ld16s(uintptr_t address);
    unsigned ldw(uintptr_t address);
    //void paging(); //<-- ehh. I tried, but higher layer must be separated from memory operation itself.
};

//a window in the LOCAL memory address space, where the external memory will be paged to.
typedef struct sVirtPage{
    unsigned base; //start offset of the window
    unsigned length; //length of the window
    unsigned offs;
    uintptr_t localMemPtr;
    unsigned* movable buffer;
    struct sVirtPage*unsafe next;
    tPageFlags flags;
    tOriginType origin; //result type
    client interface memory_extender * unsafe imem;
} tVirtPage;

//preliminary pager interface, some pageing strategy parametrization is a must.
interface virt_pager {
    void loadPage(tVirtPage*unsafe page, uintptr_t& address );
    void storePage(tVirtPage*unsafe page);
    void commit();
};

//requested EXTERNAL memory address space, which can contains more then one paged area.
typedef struct{
    //unsigned extid; //key for search, eh no...
    unsigned base;  //start offset of the window
    unsigned length; //length of the window
} tExtPage;

//a segment of the virtual address space
typedef struct{
    tExtPage ext;     //one by one. Each virtual segment is relating to one external/physical space
    unsigned plength; //default len for a newly allocated page entity
    client interface memory_extender * unsafe imem; //memory/data operation at the end
    client interface virt_pager* unsafe ipgr;   //paging strategy
    tVirtPage* unsafe pageRoot;  //preliminary. todo: reverse link need? (page table must contains segment and offset?)
    tOriginType origin; //classification by origination
} tVirtSegm;



extern tVirtSegm g_segmTable[VIRTSEGMTABLE_MAX];
extern tVirtPage g_pageTable[VIRTPAGETABLE_MAX];

void vsInit();

// config virtual segment: start, length, type
unsigned vsConfigSegm(unsigned id, unsigned base, unsigned len, tOriginType t);

// config specific mem extender if to specific segment. unsafe ptr is used here.
void vsInstallSegmIfunsafe(tVirtSegm& vs, client interface memory_extender* unsafe imem, client interface virt_pager* unsafe ipgr);
// config specific mem extender if to specific segment. movable ptr is used here.
void vsInstallSegmIfmovable(tVirtSegm& vs, client interface memory_extender* movable imem, client interface virt_pager* unsafe ipgr);

//config local page: used in which segment, drifted by offset
void vsConfigPage(tVirtPage& vp, tVirtSegm& vs, unsigned offset);

void vsSetBufferForPage(tVirtPage& vp, unsigned* unsafe buf, unsigned len);
//Resolver (search in segm, seach in cache/page, add if needed, resolve to local buff address. returns by null ptr if err.
tVirtPage*unsafe vsResolveVirtualAddress(uintptr_t &address);

//Get virtual address, on a specific segment. (add msb bits to the input address)
unsafe void * unsafe vsTranslate(uintptr_t address, unsigned char segm);

//service entry point for ram backend
void virtaddr_ram(server interface memory_extender mem, server interface virt_pager pgr);
//service entry point for sdram backend
void virtaddr_sdram(server interface memory_extender mem, server interface virt_pager pgr, streaming chanend c_sdram_client);
//service entry point for file backend
void virtaddr_devpc_file(server interface memory_extender mem, server interface virt_pager pgr);
/*
//TODO: as a long term goal, we need to keep in mind there is overlays too. Here is the descriptor from xmos overlay imp...
//there is no virtualization, but external address is specified of course.
typedef struct overlay_descriptor_t {
  /// The virtual address of the overlay.
  unsigned virtual_address;
  /// The physical address of the overlay.
  unsigned physical_address;
  /// The size of the overlay in bytes.
  unsigned size;
} overlay_descriptor_t;
*/

#endif /* VIRTADDR_H_ */
