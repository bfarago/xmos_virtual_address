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
#include <flashlib.h>



#define REMOTERAMTILE tile[1]

#if 0
//tile0 star slot
#define SDRAMTILE tile[0]
on SDRAMTILE : out buffered port:32 sdram_dq_ah = XS1_PORT_16A;   //X0D002..09, 14..21
on SDRAMTILE : out buffered port:32 sdram_cas = XS1_PORT_1B;      //X0D001
on SDRAMTILE : out buffered port:32 sdram_ras = XS1_PORT_1G;      //X0D022
on SDRAMTILE : out buffered port:8 sdram_we = XS1_PORT_1C;        //X0D010
on SDRAMTILE : out port sdram_clk = XS1_PORT_1F;                  //X0D013
on SDRAMTILE : clock sdram_cb = XS1_CLKBLK_2;
#endif
#if 1
//tile0 triangle slot
#define SDRAMTILE tile[0]
on SDRAMTILE : out buffered port:32 sdram_dq_ah = XS1_PORT_16B;   //X0D002..09, 14..21
on SDRAMTILE : out buffered port:32 sdram_cas = XS1_PORT_1J;      //X0D001
on SDRAMTILE : out buffered port:32 sdram_ras = XS1_PORT_1I;      //X0D022
on SDRAMTILE : out buffered port:8 sdram_we = XS1_PORT_1K;        //X0D010
on SDRAMTILE : out port sdram_clk = XS1_PORT_1L;                  //X0D013
on SDRAMTILE : clock sdram_cb = XS1_CLKBLK_2;
#endif
#if 0
//tile1 square slot
#define SDRAMTILE tile[1]
on SDRAMTILE : out buffered port:32 sdram_dq_ah = XS1_PORT_16A;
on SDRAMTILE : out buffered port:32 sdram_cas = XS1_PORT_1B;
on SDRAMTILE : out buffered port:32 sdram_ras = XS1_PORT_1G;
on SDRAMTILE : out buffered port:8 sdram_we = XS1_PORT_1C;
on SDRAMTILE : out port sdram_clk = XS1_PORT_1F;
on SDRAMTILE : clock sdram_cb = XS1_CLKBLK_2;
#endif

#define SDRAM_CLIENT_COUNT (1)

// Ports for SPI access from xn file
fl_SPIPorts qspi_ports = {
PORT_SPI_MISO,
PORT_SPI_SS,
PORT_SPI_CLK,
PORT_SPI_MOSI,
on tile[0]: XS1_CLKBLK_1
};
// List of SPI devices that are supported by default.
fl_DeviceSpec deviceSpecs[] =
{
FL_DEVICE_ATMEL_AT25DF041A,
FL_DEVICE_ST_M25PE10,
FL_DEVICE_ST_M25PE20,
FL_DEVICE_ATMEL_AT25FS010,
FL_DEVICE_WINBOND_W25X40,
FL_DEVICE_ATMEL_AT25DF021,
FL_DEVICE_ATMEL_AT25F512,
FL_DEVICE_ESMT_F25L004A,
FL_DEVICE_NUMONYX_M25P10,
FL_DEVICE_NUMONYX_M25P16,
FL_DEVICE_NUMONYX_M45P10E,
FL_DEVICE_SPANSION_S25FL204K,
FL_DEVICE_SST_SST25VF010,
FL_DEVICE_SST_SST25VF016,
FL_DEVICE_SST_SST25VF040,
FL_DEVICE_WINBOND_W25X10,
FL_DEVICE_WINBOND_W25X20,
FL_DEVICE_MACRONIX_MX25L1005C,
FL_DEVICE_MICRON_M25P40,
FL_DEVICE_ALTERA_EPCS1,
};

unsigned g_testbuf[3]; //global variable will be allocated on that tile(s) where we are refferencing to it... hm.
unsigned g_buf[128]; //this buffer will be used for cache the sdram page.

typedef enum{
    SEG_DIRECT,
    SEG_LOCAL0,
    SEG_SDRAM,
    SEG_FILE
}tSegments;

static void virtaddr_test0(
        client interface memory_extender mem[extenders], const unsigned extenders,
        client interface virt_pager pgr[pagers], const unsigned pagers)
{
    // Connect to the SPI device using the flash library function fl_connectToDevice.
    if(fl_connectToDevice(qspi_ports, deviceSpecs, sizeof(deviceSpecs)/sizeof(fl_DeviceSpec)) != 0)
    {
        printstrln("spi flash connection error");
    }else{
        unsigned int partSize= fl_getDataPartitionSize();
        unsigned int secNum= fl_getNumDataSectors();
        //unsigned int secSize= fl_getDataSectorSize(0);
        // Disconnect from the SPI device.
        fl_disconnect();
    }

  vsInit();//reset globals, need to call for each tile where handler must be installed
  vsConfigSegm(SEG_LOCAL0, 0x10000, 64*1024, OT_LOCALRAM); //0x81xx xxxx is used for local ram 0x0001 xxxx space
  vsConfigSegm(SEG_SDRAM, 0, 2*1024*1024, OT_SDRAM); //preliminary, but some sdram will be here
  vsConfigSegm(SEG_FILE, 0, 1024*1024, OT_FILE); //preliminary, devpc file
  unsafe{
      vsInstallSegmIfunsafe(g_segmTable[SEG_LOCAL0],  &mem[0], &pgr[0]); //install on destination tile
      vsInstallSegmIfunsafe(g_segmTable[SEG_SDRAM],  &mem[1], &pgr[1]); //sdram
      vsInstallSegmIfunsafe(g_segmTable[SEG_FILE],  &mem[2], &pgr[2]); //file
  }
  vsConfigPage(g_pageTable[0], g_segmTable[SEG_LOCAL0] , 0); //add page(no memmap used, but virt_addr resolved to destination directly)
  vsConfigPage(g_pageTable[1], g_segmTable[SEG_SDRAM] , 0); //sdram
  vsConfigPage(g_pageTable[2], g_segmTable[SEG_FILE] , 0); //file
  //bush layout is used for the page registration.
  //actually, linked lists starting from root items, which is registered in segm records...

  //Skips malloc because of this, try to set movable (because of the sdram lib requires that way)
  vsSetBufferForPage(g_pageTable[1], g_buf, 128); //sdram related predefinied page
  //here comes the trouble :) How can be do this better?
  unsigned * movable buffers[1]={g_buf}; // see comment at the end of this function. ***
  g_pageTable[1].buffer=move(buffers[0]);

  memory_extender_handler_install(); //exception handler installed

  //some test fixture
  g_testbuf[0] = 1;
  unsafe {

    //normal case
    unsigned * unsafe p = vsTranslate((uintptr_t)g_testbuf, SEG_LOCAL0); //segm#1 local ram. Must be the right (local) segm, to point the right point.

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

    printstrln("file test started");
    //test paging on file
    //it will create/appends for first time, which is slow.
    p = vsTranslate(512, SEG_FILE); //segm#3 is a regular binary file on dev pc. wow. :)
    printhexln((unsigned)p);
    *p=0x87654321U;
    *++p=0x55aa55aaU;
    *++p=0x12345678U; //this one still in the actual page
    // add gap, append file
    p = vsTranslate(1024, SEG_FILE); //segm#3 is a regular binary file on dev pc. wow.
    printhexln((unsigned)p);
    *p=0x12345678U;
    pgr[2].commit(); //not implemented yet. Pager will implements load and store page too.

    p = vsTranslate(128, 3); //step back, already in the file. Page swap. Write more than one page.
    for (unsigned i=0; i<10; i++,p++) *p=i; //bug: known, last page will not be stored yet. :(
    p = vsTranslate(128, 3); //re
    for (int i=0; i<10; i++) if (p[i]!=i) {
        printhex(i);
        printhexln(p[i]);
    }
    pgr[2].commit(); //not implemented yet. yep.
    printstrln("file test finished");
#endif

#ifdef TEST_SDRAM
#define MAXTESTEDOFFS (256*1024)
    p = vsTranslate(128, SEG_SDRAM); //sdram
    for (int i=0; i<MAXTESTEDOFFS; i++,p++){
        *p=i; //bug: known, last page will not be stored yet. :(
    }
    pgr[1].commit(); //not implemented yet. yep.
    p = vsTranslate(128, SEG_SDRAM); //re
    for (int i=0; i<MAXTESTEDOFFS; i++) if (p[i]!=i) {
       printhexln(p[i]);
    }
    tr=(uintptr_t)p+1024;
    printhexln((unsigned)tr);
    tr&=~0x80000000U; //handler does it first step, so we do it here
    page= vsResolveVirtualAddress(tr);
    printhexln((unsigned)tr);

    p = vsTranslate(10, SEG_SDRAM); //sdram
    tr=(uintptr_t)p;
    printhexln((unsigned)tr);
    tr&=~0x80000000U; //handler does it first step, so we do it here
    page= vsResolveVirtualAddress(tr);
    printhexln((unsigned)tr);

    p ++; //same page
    tr=(uintptr_t)p;
    printhexln((unsigned)tr);
    tr&=~0x80000000U; //handler does it first step, so we do it here
    page= vsResolveVirtualAddress(tr);
    printhexln((unsigned)tr);

    printstrln("sdram test finished");
#endif
  }
  // ***stay in scope. Impossible to return from here because of the global movable ptr was used to fill a local movable ptr,
  //and it will be destroyed when stack leaved. The synthetized runtime check code of the local movable ptr will stops at
  //ecallf, it gives ET_ECALL because of the rule described in the Programmers guide:
  //"Movable pointers cannot refer to de-allocated memory. To ensure this the following restriction applies:
  //A movable pointer must point to the same region it was initialized with when it goes out of scope.
  //A runtime check is inserted to ensure this (so an exception can happen when the pointer goes out of scope)."
  while(1){
  }
}
void virtaddr_test1(){
    //vsInit();//reset globals, need to call for each tile where handler must be installed
    //vsConfigSegm(SEG_LOCAL0, 0x10000, 64*1024, OT_REMOTERAM); //0x81xx xxxx is used for local ram 0x0001 xxxx space
    //vsConfigPage(g_pageTable[0], g_segmTable[SEG_LOCAL0] , 0); //add page(no memmap used, but virt_addr resolved to destination directly)
    unsafe {
        memory_extender_handler_install(); //exception handler installed
        unsigned * unsafe p = vsTranslate(0, SEG_LOCAL0);
        *p=2; //it will do nothing, because of the missing segment descriptor
    };
    while(1){
    }
}

/*
 TODO: (partly implemented or designed at this level)
 - more than one page window may alive for one segment
 - commit only if page reused, or commit/store called
 - default page allocation size handling
 - heap or similar datastructure (btree, trie, whatever)
 - unittest (actually we just use hardcoded print fn)
 - if file based interface works, next one can be sdram.
 - benchmark & refactoring the code to asm
 */
int main()
{
  interface memory_extender imem[3];
  interface virt_pager ipager[3];
  streaming chan c_sdram[SDRAM_CLIENT_COUNT];


  par {
    on REMOTERAMTILE:   virtaddr_ram(imem[0], ipager[0]);
    on tile[0]: virtaddr_sdram(imem[1], ipager[1], c_sdram[0]);
    on SDRAMTILE: sdram_server(c_sdram, SDRAM_CLIENT_COUNT, sdram_dq_ah, sdram_cas, sdram_ras, sdram_we, sdram_clk, sdram_cb, 2, 128, 16, 8,12, 2, 64, 4096, 4); //4 (500Mhz/2/4)
    on tile[0]:   virtaddr_devpc_file(imem[2], ipager[2]);
    on tile[0]:   virtaddr_test0(imem, 3, ipager, 3);
    on tile[1]: virtaddr_test1();
  }
  return 0;
}
