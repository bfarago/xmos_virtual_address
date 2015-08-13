/*
 * app_test_vm.xc
 *
 *  Created on: 2015.08.06.
 *      Author: Barna Farago (MYND-ideal ltd)
 */
#include "platform.h"
#include "virtaddr.h"
#include <print.h>
#include "sdram.h"
#define SDRAMTILE tile[0]
//tile0 star slot
on SDRAMTILE : out buffered port:32 sdram_dq_ah = XS1_PORT_16A;   //X0D002..09, 14..21
on SDRAMTILE : out buffered port:32 sdram_cas = XS1_PORT_1B;      //X0D001
on SDRAMTILE : out buffered port:32 sdram_ras = XS1_PORT_1G;      //X0D022
on SDRAMTILE : out buffered port:8 sdram_we = XS1_PORT_1C;        //X0D010
on SDRAMTILE : out port sdram_clk = XS1_PORT_1F;                  //X0D013
on SDRAMTILE : clock sdram_cb = XS1_CLKBLK_2;
#define SDRAM_CLIENT_COUNT (1)


unsigned g_testbuf[3]; //global variable will be allocated on that tile(s) where we are refferencing to it... hm.
unsigned g_buf[128]; //sizeof(unsigned)*32 bytes

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
      vsInstallSegmIfunsafe(g_segmTable[2],  &mem[1], &pgr[1]); //sdram
      vsInstallSegmIfunsafe(g_segmTable[3],  &mem[2], &pgr[2]); //file
  }
  vsConfigPage(g_pageTable[0], g_segmTable[1] , 0); //add page(no memmap used, but virt_addr resolved to destination directly)
  vsConfigPage(g_pageTable[1], g_segmTable[2] , 0); //sdram
  vsConfigPage(g_pageTable[2], g_segmTable[3] , 0); //file
  //bush layout is used for the page registration.
  //actually, linked lists starting from root items, which is registered in segm records...

  //Skips malloc because of this
  //vsSetBufferForPage(g_pageTable[1], g_buf, 128);

  memory_extender_handler_install(); //exception handler installed

  //some test fixture
  g_testbuf[0] = 1;
  unsafe {

    //normal case
    unsigned * unsafe p = vsTranslate((uintptr_t)g_testbuf, 1); //segm#1 local ram. Must be the right (local) segm, to point the right point.

#define TEST1
#define TEST_SDRAM

    timer tmr; //Wait for other threads to start
    int t;
    tmr:>t;
    tmr when timerafter(t+1000000) :> void;

    printstrln("test");
#ifdef TEST1
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
    for (unsigned i=0; i<10; i++,p++) *p=i; //bug: known, last page will not be stored yet. :(
    //bug: only low byte is writed by the handler ? if p[i]=i is used... it looks like :/
    p = vsTranslate(128, 3); //re
    for (int i=0; i<10; i++) if (p[i]!=i) {
        printhex(i);
        printhexln(p[i]);
    }
    pgr[2].commit(); //not implemented yet. yep.
    printstrln("file test finished");
#endif

#ifdef TEST_SDRAM
    p = vsTranslate(128, 2); //sdram
    for (int i=0; i<10; i++,p++){
        *p=i; //bug: known, last page will not be stored yet. :(
    }
    for (int i=0; i<10; i++) if (p[i]!=i) {
       printhexln(p[i]);
    }
    pgr[1].commit(); //not implemented yet. yep.
    printstrln("sdram test finished");
#endif
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
  streaming chan c_sdram[SDRAM_CLIENT_COUNT];

  par {
    on tile[1]:   virtaddr_ram(imem[0], ipager[0]);
    on SDRAMTILE: virtaddr_sdram(imem[1], ipager[1], c_sdram[0]);
    on SDRAMTILE: sdram_server(c_sdram, SDRAM_CLIENT_COUNT, sdram_dq_ah, sdram_cas, sdram_ras, sdram_we, sdram_clk, sdram_cb, 2, 128, 16, 8,12, 2, 64, 4096, 4); //4 (500Mhz/2/4)
    on tile[0]:   virtaddr_devpc_file(imem[2], ipager[2]);
    on tile[0]:   virtaddr_test(imem, 3, ipager, 3);
  }
  return 0;
}
