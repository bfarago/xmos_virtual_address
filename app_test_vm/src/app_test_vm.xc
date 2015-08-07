/*
 * app_test_vm.xc
 *
 *  Created on: 2015.08.06.
 *      Author: Barna Farago (MYND-ideal ltd)
 */
#include "platform.h"
#include "virtaddr.h"
#include <print.h>

unsigned g_testbuf[3]; //global variable will be allocated on that tile(s) where we are refferencing to it... hm.

static void virtaddr_test(
        client interface memory_extender mem[extenders], const unsigned extenders,
        client interface virt_pager pgr[pagers], const unsigned pagers)
{
  vsInit();//reset globals, need to call for each tile where handler must be installed
  vsConfigSegm(1, 0x10000, 64*1024, OT_LOCALRAM); //0x81xx xxxx is used for local ram 0x0001 xxxx space
  vsConfigSegm(2, 0, 256*1024, OT_SDRAM); //preliminary, but some sdram will be here
  vsConfigSegm(3, 0, 1024*1024, OT_FILE); //preliminary, devpc file
  unsafe{
      vsInstallSegmIfunsafe(g_segmTable[1],  &mem[0], &pgr[0]); //install on destination tile
      vsInstallSegmIfunsafe(g_segmTable[2],  &mem[1], &pgr[1]); //can be on different tile (only reason to be different)
      vsInstallSegmIfunsafe(g_segmTable[3],  &mem[2], &pgr[2]); //same endpoint? test it
  }
  vsConfigPage(g_pageTable[0], g_segmTable[1] , 0); //add page(no memmap used, but virt_addr resolved to destination directly)
  vsConfigPage(g_pageTable[1], g_segmTable[2] , 0); //another page entity will be registered to the another segm...
  vsConfigPage(g_pageTable[3], g_segmTable[3] , 0); //another page entity will be registered to the another segm...
  //bush layout is used for the page registration.
  //actually, linked lists starting from root items, which is registered in segm records...

  memory_extender_handler_install(); //exception handler installed

  //some test fixture
  g_testbuf[0] = 1;
  unsafe {
    //normal case
    unsigned * unsafe p = vsTranslate((uintptr_t)g_testbuf, 1); //segm#1 local ram. Must be the right (local) segm, to point the right point.
    printhexln((unsigned)p);
    *p += 1;

    //behind the sceene
    uintptr_t tr=(uintptr_t)p;
    tr&=~0x80000000U; //handler does it first step, so we do it here
    tVirtPage*unsafe page= vsResolveVirtualAddress(tr);
    printhexln((unsigned)tr);

    //test paging on file
    //it will create/appends for first time, which is slow.
    p = vsTranslate(512, 3); //segm#3 is a regular binary file on dev pc. wow. :)
    printhexln((unsigned)p);
    *p=0x87654321U;
    *++p=0x55aa55aaU;
    *++p=0x12345678U; //this one still in the actual page
    // add gap, append file
    p = vsTranslate(1024, 3); //segm#3 is a regular binary file on dev pc. wow.
    printhexln((unsigned)p);
    *p=0x12345678U;
    pgr[2].commit(); //not implemented yet. Pager will implements load and store page too.

    p = vsTranslate(128, 3); //step back, already in the file. Page swap. Write more than one page.
    for (int i=0; i<10; i++) p[i]=i; //bug: known, last page will not be stored yet. :(
    //bug: only low byte is writed by the handler ? it looks like :/
    pgr[2].commit(); //not implemented yet. yep.
    printstrln("finished");
  }
}
/*
 TODO: (partly implemented or designed at this level)
 - more than one page window may alive for one segment
 - commit only if page reused, or commit/store called
 - default page allocation size handling
 - heap or similar datastructure (btree, trie, whatever)
 - unittest
 - if file based interface works, next one can be sdram.
 */
int main()
{
  interface memory_extender imem[3];
  interface virt_pager ipager[3];

  par {
    on tile[1]:   virtaddr_ram(imem[0], ipager[0]);
    on tile[0]:   virtaddr_sdram(imem[1], ipager[1]);
    on tile[0]:   virtaddr_devpc_file(imem[2], ipager[2]);
    on tile[0]:   virtaddr_test(imem, 2, ipager, 3);
  }
  return 0;
}
