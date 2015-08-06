/*
 * virtaddr.xc
 *
 *  Created on: 2015.07.31.
 *      Author: Barna Farago (MYND-ideal ltd)
 */
#include "virtaddr.h"
#include "memory_extender.h"

/*
This implements the memory operations, can be used in different (more than one) tiles at the end.
 */
select local_imp(server interface memory_extender mem){
    case mem.st8(uintptr_t address, unsigned data):
      unsafe { *((uint8_t *unsafe)address) = data; }
      break;
    case mem.st16(uintptr_t address, unsigned data):
      unsafe { *((int16_t *unsafe)address) = data; }
      break;
    case mem.stw(uintptr_t address, unsigned data):
      unsafe { *((unsigned *unsafe)address) = data; }
      break;
    case mem.ld8u(uintptr_t address) -> uint8_t data:
      unsafe { data = *((uint8_t *unsafe)address); }
      break;
    case mem.ld16s(uintptr_t address) -> int16_t data:
      unsafe { data = *((int16_t *unsafe)address); }
      break;
    case mem.ldw(uintptr_t address) -> unsigned data:
      unsafe { data = *((unsigned *unsafe)address); }
      break;
}

/*[[distributable]] */
/*static void virtaddr_logger(server interface memory_extender mem, server interface virt_pager pgr){
while (1) {
  select {
  case mem.st8(uintptr_t address, unsigned data):
   // debug_printf("Store 0x%x to *(uint8_t*)0x%x\n", data, address);
    unsafe { *((uint8_t *unsafe)address) = data; }
    break;
  case mem.st16(uintptr_t address, unsigned data):
    //debug_printf("Store 0x%x to *(uint16_t*)0x%x\n", data, address);
    unsafe { *((int16_t *unsafe)address) = data; }
    break;
  case mem.stw(uintptr_t address, unsigned data):
    //debug_printf("Store 0x%x to *(unsigned*)0x%x\n", data, address);
    unsafe { *((unsigned *unsafe)address) = data; }
    break;
  case mem.ld8u(uintptr_t address) -> uint8_t data:
    unsafe { data = *((uint8_t *unsafe)address); }
    //debug_printf("Load 0x%x from *(uint8_t*)0x%x\n", data, address);
    break;
  case mem.ld16s(uintptr_t address) -> int16_t data:
    unsafe { data = *((int16_t *unsafe)address); }
    //debug_printf("Load 0x%x from *(uint16_t*)0x%x\n", data, address);
    break;
  case mem.ldw(uintptr_t address) -> unsigned data:
    unsafe { data = *((unsigned *unsafe)address); }
    //debug_printf("Load 0x%x from *(unsigned*)0x%x\n", data, address);
    break;
  case pgr.loadPage(tVirtPage*unsafe page):   break;
  }
 }
}*/
void virtaddr_ram(server interface memory_extender mem, server interface virt_pager pgr)
{
  while (1) {
    select {
    case local_imp(mem);
    case pgr.loadPage(tVirtPage*unsafe page):
        unsafe{
            if (page->length){
                //NOOOOTHING
            }
        }
        break;
    }
  }
}

void virtaddr_sdram(server interface memory_extender mem, server interface virt_pager pgr)
{
  while (1) {
    select {
    case local_imp(mem);
    case pgr.loadPage(tVirtPage*unsafe page):
        // sdram specific strategy will be here
        break;
    }
  }
}

/**
 * Convert an address in external memory to a pointer. Any memory access via
 * this pointer will trigger a load / store exception. On an load / store
 * exception, the exception handler translates the pointer back into an address
 * in external memory and the address in external memory is passed to the
 * memory_extender server.
 */
//inline
unsafe void * unsafe vsTranslate(uintptr_t address, unsigned char segm) {
  /*if ((intptr_t)address < 0) { //sign bit represents the msb
    __builtin_trap(); //msb bit already set
  }*/
  if (address > VIRTADDR_OFFS_MASK){
      __builtin_trap(); //address overrun
  }

  return (void * unsafe)(address | 0x80000000| segm<<VIRTADDR_BITS);
}

tVirtSegm g_segmTable[VIRTSEGMTABLE_MAX];
tVirtPage g_pageTable[VIRTPAGETABLE_MAX];

unsigned vsConfigSegm( unsigned segm, unsigned base, unsigned len, tOriginType t){
    if (segm>=VIRTSEGMTABLE_MAX) return 1;
    tVirtSegm& vs= g_segmTable[segm];
    vs.ext.base= base; vs.ext.length=len; vs.origin=t;
    vs.pageRoot=0;

    return 0;
}
void vsInstallSegmIfunsafe(tVirtSegm& vs, client interface memory_extender* unsafe imem){
    unsafe{
        vs.imem=imem;
    }
}
void vsInstallSegmIfmovable(tVirtSegm& vs, client interface memory_extender* movable imem){
    unsafe{ //convert to unsafe ptr
        vs.imem=imem;
    }
}
tVirtPage*unsafe vsGetUnusedPage(){
    unsafe{
    for (int i=0; i<VIRTPAGETABLE_MAX; i++){
        tVirtPage* unsafe p= &g_pageTable[i];
        if (p->flags & PF_INVALID){
            return p;
        }
    }
    }
    return null;
}
void vsInitSegm(tVirtSegm& vs){
    vs.pageRoot=0; vs.origin=OT_INVALID;
    vs.ext.base=0; vs.ext.length=0;
    vs.imem=null;
}
void vsInitPage(tVirtPage& vp, unsigned length, unsigned* ptr){
    vp.base=0; vp.offs=0; vp.length=length;
    vp.localMemPtr=(uintptr_t)ptr;
    vp.imem=null;
    vp.next=0;
    vp.flags=PF_INVALID;
}
void vsInit(){
    for (int i= 0; i< VIRTSEGMTABLE_MAX; i++){
        vsInitSegm(g_segmTable[i]);
    }
    for (int i= 0; i< VIRTPAGETABLE_MAX; i++){
            vsInitPage(g_pageTable[i], 0, null);
    }
}
void vsConfigPage(tVirtPage& vp, tVirtSegm& vs, unsigned offset){
    //vp.base= offset&~3; vp.offs= offset&3; //align to 32 bit
    vp.base= offset; //notaligned
    vp.flags=PF_AVAILABLE|PF_REQUIRED;
    vp.origin=vs.origin;
    unsafe{
        vp.imem=vs.imem;
        if (!vs.pageRoot){ //first element
            unsafe{
                vs.pageRoot=&vp;
            }
            return;
        }
        tVirtPage* unsafe r= vs.pageRoot; //add to the end of the list. TODO: insert to right place, to be sorted.
        while(r->next) r=r->next;
        r->next=&vp;
    }
}

//Supervisor
tVirtPage*unsafe vsResolveVirtualAddress(uintptr_t &address){
    //bit31 (msb) is allways 1 in virt addresses, but asm code already cleared.
    uintptr_t segm= (address & VIRTADDR_SEGM_MASK)>>VIRTADDR_BITS; //bit 24..30
    uintptr_t voffs= address & VIRTADDR_OFFS_MASK; //TODO: alignment check would be nice to have
    if (segm >= VIRTSEGMTABLE_MAX){
        return null;
    }

    tVirtSegm& vs= g_segmTable[segm];
    voffs-= vs.ext.base; //TODO: not ext but virt! need a new field for this?
    if (voffs>= vs.ext.length){ //assume one segment is contain only one addressing plan (from one external memory base to length bytes)
        return null;  //over of specified external space
    }
    uintptr_t eoffs=vs.ext.base + voffs; //get external offset inside of spec. window.
    unsafe{

    tVirtPage*unsafe pPage=vs.pageRoot;

    if (!pPage){ //first request
        pPage=vsGetUnusedPage(); //get an empty page from the pool
        if (pPage) vsConfigPage(*pPage, vs, eoffs);
    }else{ //already allocated
        //OK, HERE WE ARE !!! CODE IS NOT FINISHED, WE HAVE TO CALL PAGER subsystem... To get the page content.
        if (vs.origin ==OT_LOCALRAM){
            address=eoffs;
            return pPage; // just write RAM, so no paging necessary here
        }
        if (vs.ipgr) vs.ipgr->loadPage(pPage); //do some check, load the external window to the page buffer ?
        //search. Probably move to the paging interface... This part will be reorganised soon.
        while( (pPage->base > eoffs) || (eoffs>=(pPage->base+pPage->length)) ){ //search O(n)
            pPage=pPage->next;
            if (!pPage){//end
                pPage=vsGetUnusedPage();
                if (pPage) {
                    vsConfigPage(*pPage, vs, eoffs); //break;
                }
                break;//return OT_INVALID; //page not found
            }
        }
    }
    if (!pPage){
        return null;  //page reuse not implemented, theres no free page slot
    }
    //so we have the page, hopefully it is allocated too :)

    address= pPage->localMemPtr+ eoffs - pPage->base;
    return pPage;
    }
}
