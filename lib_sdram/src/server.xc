// Copyright (c) 2015, XMOS Ltd, All rights reserved
#include <platform.h>
#include <xclib.h>
#include "sdram.h"
#include "control.h"

#define TIMER_TICKS_PER_US 250000000

#define MINIMUM_REFRESH_COUNT 8

static void refresh(unsigned ncycles,
        out buffered port:32 cas,
        out buffered port:32 ras){
    unsigned t;
    t = partout_timestamped(cas, 1, CTRL_CAS_NOP);
    t+=12;
#define REFRESH_MASK 0xeeeeeeee
    cas @ t <: REFRESH_MASK;
    ras @ t <: REFRESH_MASK;
    for (unsigned i = 8; i < ncycles; i+=8){
      cas <: REFRESH_MASK;
      ras <: REFRESH_MASK;
    }
}

void sdram_init(
        out buffered port:32 dq_ah,
        out buffered port:32 cas,
        out buffered port:32 ras,
        out buffered port:8 we,
        out port clk,
        clock cb,
        const static unsigned cas_latency,
        const static unsigned clock_divider
) {
  timer T;
  int time, t;

  cas <: 0;
  ras <: 0;
  we <: 0;
  dq_ah <: 0;

  sync(dq_ah);
  stop_clock(cb);

  T :> time;
  T when timerafter(time + 100 * TIMER_TICKS_PER_US) :> time;

  asm("setclk res[%0], %1"::"r"(cb), "r"(XS1_CLK_XCORE));
  set_clock_div(cb, clock_divider);

  set_port_clock(clk, cb);
  set_port_mode_clock(clk);

  set_port_clock(dq_ah, cb);
  set_port_clock(cas, cb);
  set_port_clock(ras, cb);
  set_port_clock(we, cb);

  set_pad_delay(dq_ah,0);
  set_port_sample_delay(dq_ah);

  start_clock(cb);

  dq_ah @ t <: 0 ;
  t+=200;

  partout(cas,1, 0);
  partout(we, 1, 0);

  T :> time;
  T when timerafter(time + 100 * TIMER_TICKS_PER_US) :> time;

  dq_ah <: 0 @ t;
  sync(dq_ah);

  t+=200;
  partout_timed(ras,1, CTRL_RAS_NOP, t);
  partout_timed(cas,1, CTRL_CAS_NOP, t);
  partout_timed(we, 1, CTRL_WE_NOP,  t);

  T :> time;
  T when timerafter(time + 50 * TIMER_TICKS_PER_US) :> time;

  dq_ah <: 0x04000400 @ t;
  sync(dq_ah);
  t+=600;

  partout_timed(ras, 2, CTRL_RAS_PRECHARGE | (CTRL_RAS_NOP<<1), t);
  partout_timed(we, 2,  CTRL_WE_PRECHARGE  | (CTRL_WE_NOP<<1),  t);
  t+=16;

  refresh(256, cas, ras);

  // set mode register
  unsigned mode_reg;
  if(cas_latency == 2){
      mode_reg = 0x00270027;
  } else {
      mode_reg = 0x00370037;
  }

  dq_ah  <: mode_reg @ t;
  sync(dq_ah);
  t+=256;
  partout_timed(cas, 2, CTRL_CAS_LOAD_MODEREG | (CTRL_CAS_NOP<<1), t);
  partout_timed(ras, 2, CTRL_RAS_LOAD_MODEREG | (CTRL_RAS_NOP<<1), t);
  partout_timed(we, 2,  CTRL_WE_LOAD_MODEREG  | (CTRL_WE_NOP<<1),  t);
  refresh(256, cas, ras);

}

typedef struct {
  unsigned dq_ah;
  unsigned cas;
  unsigned ras;
  unsigned we;
} sdram_ports;

void sdram_block_read(unsigned * buffer, sdram_ports &ports, unsigned t0, unsigned word_count, unsigned row_words, unsigned cas_latency);
void sdram_block_write(unsigned * buffer, sdram_ports &ports, unsigned t0, unsigned word_count, unsigned row_words);

/*
 * These numbers are tuned for 62.5MIPS.
 */
#define WRITE_SETUP_LATENCY (80)
#define READ_SETUP_LATENCY  (70)

#define BANK_SHIFT          (13)//FIXME 15 - bank_address_bits

#define SDRAM_EXTERNAL_MEMORY_ACCESSOR 0

static inline void write_impl(unsigned row, unsigned col, unsigned bank,
        unsigned *  buffer, unsigned word_count,
        out buffered port:32 dq_ah,
        out buffered port:32 cas,
        out buffered port:32 ras,
        out buffered port:8 we,
        const static unsigned row_words) {

/*
    if(SDRAM_EXTERNAL_MEMORY_ACCESSOR){
        if (col)
            col = col - 1;
        else
            col = ((1<<c.col_address_bits) - 1);
    }
*/

    unsigned rowcol = (col << 16) | row | (bank<<BANK_SHIFT) | bank<<(BANK_SHIFT+16) | 1<<(10+16);

    unsigned t = partout_timestamped(cas, 1, CTRL_WE_NOP);
    t += WRITE_SETUP_LATENCY;

    dq_ah @ t<: rowcol;

    partout_timed(cas, 3, CTRL_CAS_ACTIVE | (CTRL_CAS_WRITE<<1) | (CTRL_CAS_NOP<<2), t);
    partout_timed(ras, 3, CTRL_RAS_ACTIVE | (CTRL_RAS_WRITE<<1) | (CTRL_RAS_NOP<<2), t);
    partout_timed(we , 3, CTRL_WE_ACTIVE  | (CTRL_WE_WRITE<<1)  | (CTRL_WE_NOP<<2), t);

    unsafe {
       sdram_ports ports = {*(unsigned*)&dq_ah, *(unsigned*)&cas,*(unsigned*)&ras, *(unsigned*)&we};
        sdram_block_write(buffer, ports, t, word_count, row_words);
    }
}

static inline void read_impl(unsigned row, unsigned col, unsigned bank,
        unsigned *  buffer, unsigned word_count,
        out buffered port:32 dq_ah,
        out buffered port:32 cas,
        out buffered port:32 ras,
        out buffered port:8 we,
        const static unsigned row_words,
        const static unsigned cas_latency) {
/*
    if(SDRAM_EXTERNAL_MEMORY_ACCESSOR){
        if (col)
            col = col - 1;
        else
            col = ((1<<c.col_address_bits) - 1);
    }
*/
    unsigned rowcol = (col << 16) | row | (bank<<BANK_SHIFT) | bank<<(BANK_SHIFT+16) | 1<<(10+16);

    unsigned t = partout_timestamped(ras, 1, CTRL_RAS_NOP);
    t += READ_SETUP_LATENCY;

    dq_ah @ t <: rowcol;
    partout_timed(cas, 3, CTRL_CAS_ACTIVE | (CTRL_CAS_READ<<1) | (CTRL_CAS_NOP<<2), t);
    partout_timed(ras, 3, CTRL_RAS_ACTIVE | (CTRL_RAS_READ<<1) | (CTRL_RAS_NOP<<2), t);


    unsafe {
        sdram_ports ports = {*(unsigned*)&dq_ah, *(unsigned*)&cas,*(unsigned*)&ras, *(unsigned*)&we};
        sdram_block_read( buffer, ports, t, word_count, row_words, cas_latency);
    }
}

static void read(unsigned start_row, unsigned start_col,
    unsigned bank, unsigned *  buffer, unsigned word_count,
    out buffered port:32 dq_ah,
    out buffered port:32 cas,
    out buffered port:32 ras,
    out buffered port:8 we,
    const static unsigned row_words,
    const static unsigned cas_latency,
    const static unsigned col_address_bits,
    const static unsigned row_address_bits,
    const static unsigned bank_address_bits) {

  unsigned words_to_end_of_line;
  unsigned current_col = start_col, current_row = start_row;
  unsigned remaining_words = word_count;

  while (1) {
    unsigned col_count = (1<<col_address_bits);
    words_to_end_of_line = (col_count - current_col) / 2;
    if (words_to_end_of_line < remaining_words) {
      read_impl(current_row, current_col, bank, buffer, words_to_end_of_line, dq_ah, cas, ras, we, row_words, cas_latency);
      current_col = 0;
      current_row++;
      buffer +=  words_to_end_of_line;
      remaining_words -= words_to_end_of_line;
    } else {
      read_impl(current_row, current_col, bank, buffer, remaining_words, dq_ah, cas, ras, we, row_words, cas_latency);
      return;
    }
    if(current_row>>row_address_bits){
      current_row = 0;
      bank = (bank + 1) & ((1<<bank_address_bits)-1);
    }
  }
}

static void write(unsigned start_row, unsigned start_col,
    unsigned bank, unsigned * buffer, unsigned word_count,
    out buffered port:32 dq_ah,
    out buffered port:32 cas,
    out buffered port:32 ras,
    out buffered port:8 we,
    const static unsigned row_words,
    const static unsigned cas_latency,
    const static unsigned col_address_bits,
    const static unsigned row_address_bits,
    const static unsigned bank_address_bits) {

  unsigned words_to_end_of_line;
  unsigned current_col = start_col, current_row = start_row;
  unsigned remaining_words = word_count;

  while (1) {
      unsigned col_count = (1<<col_address_bits);
    words_to_end_of_line = (col_count - current_col) / 2;
    if (words_to_end_of_line < remaining_words) {
      write_impl(current_row, current_col, bank, buffer, words_to_end_of_line, dq_ah, cas, ras, we, row_words);
      current_col = 0;
      current_row++;
      buffer += words_to_end_of_line;
      remaining_words -= words_to_end_of_line;
    } else {
      write_impl(current_row, current_col, bank, buffer, remaining_words, dq_ah, cas, ras, we, row_words);
      return;
    }
    if(current_row>>row_address_bits){
      current_row = 0;
      bank = (bank + 1) & ((1<<bank_address_bits)-1);
    }
  }
}

//TODO use the 16 bit ness to do the below correctly
static unsigned addr_to_col(unsigned address, const static unsigned  row_words){
    return 0xff&(address & (row_words-1))<<1;
}
static unsigned addr_to_row(unsigned address, const static unsigned col_address_bits, const static unsigned row_address_bits){
    return (address>>(col_address_bits-1)) & ((1<<row_address_bits)-1);
}
static unsigned addr_to_bank(unsigned address,
        const static unsigned col_address_bits,
        const static unsigned row_address_bits,
        const static unsigned bank_address_bits){
    return (address>>((col_address_bits-1)+ row_address_bits)) & ((1<<bank_address_bits)-1);
}
static int handle_command(e_command cmd_type, sdram_cmd &cmd,
        out buffered port:32 dq_ah,
        out buffered port:32 cas,
        out buffered port:32 ras,
        out buffered port:8 we,
        const static unsigned row_words,
        const static unsigned cas_latency,
        const static unsigned col_address_bits,
        const static unsigned row_address_bits,
        const static unsigned bank_address_bits) {

    unsigned row = addr_to_row(cmd.address, col_address_bits, row_address_bits);
    unsigned col = addr_to_col(cmd.address, row_words);
    unsigned bank = addr_to_bank(cmd.address, col_address_bits, row_address_bits, bank_address_bits);

    switch (cmd_type) {
    case SDRAM_CMD_READ: {
      read(row, col, bank, cmd.buffer, cmd.word_count, dq_ah, cas, ras, we,
              row_words, cas_latency, col_address_bits, row_address_bits, bank_address_bits);
      break;
    }
    case SDRAM_CMD_WRITE: {
      write(row, col, bank, cmd.buffer, cmd.word_count, dq_ah, cas, ras, we,
              row_words, cas_latency, col_address_bits, row_address_bits, bank_address_bits);
      break;
    }
    default:
#if (XCC_VERSION_MAJOR >= 12)
      __builtin_unreachable();
#endif
      break;
  }
  return 0;
}

#define XCORE_CLOCKS_PER_MS 100000

#pragma unsafe arrays
void sdram_server(streaming chanend c_client[client_count],
        const static unsigned client_count,
        out buffered port:32 dq_ah,
        out buffered port:32 cas,
        out buffered port:32 ras,
        out buffered port:8 we,
        out port clk,
        clock cb,
        const static unsigned cas_latency,
        const static unsigned row_words,
        const static unsigned col_bits,
        const static unsigned col_address_bits,
        const static unsigned row_address_bits,
        const static unsigned bank_address_bits,
        const static unsigned refresh_ms,
        const static unsigned refresh_cycles,
        const static unsigned clock_divider){
    timer t;
    unsigned time;
    sdram_cmd cmd_buffer[7][SDRAM_MAX_CMD_BUFFER];
    unsigned head[7] = {0};

    for(unsigned i=0;i<7;i++){
        head[i] = 0;
        cmd_buffer[i]->address = 0;
        cmd_buffer[i]->word_count = 0;
        cmd_buffer[i]->buffer = null;
    }

    sdram_init(dq_ah, cas, ras, we, clk, cb, cas_latency, clock_divider);

    unsafe {
        for(unsigned i=0;i<client_count;i++){
            c_client[i] <: (sdram_cmd * unsafe)&(cmd_buffer[i][0]);
            c_client[i] <: get_local_tile_id();
        }
    }

    refresh(refresh_cycles, cas, ras);
    t:> time;

    unsigned clocks_per_refresh_burst = (XCORE_CLOCKS_PER_MS*refresh_ms*MINIMUM_REFRESH_COUNT) / refresh_cycles;

    unsigned bits = 31  - clz(clocks_per_refresh_burst);

    unsafe {
       char d;
       int running = 1;
       while (running) {
          #pragma ordered
          select {
          case t when timerafter(time) :> unsigned handle_time :{
            unsigned diff = handle_time - time;
            unsigned bursts = diff>>bits;
            refresh(MINIMUM_REFRESH_COUNT*bursts, cas, ras);
            time = handle_time + (1<<bits);
            break;
          }

          case c_client[int i] :> d: {
            e_command cmd = (e_command)d;
            if(cmd == SDRAM_CMD_SHUTDOWN){
                //TODO empty the buffers and close down gracefully
                running = 0;
                break;
            }

            handle_command(cmd, cmd_buffer[i][head[i]%SDRAM_MAX_CMD_BUFFER],dq_ah, cas, ras, we,
                    row_words, cas_latency, col_address_bits, row_address_bits, bank_address_bits);
            head[i]++;
            c_client[i] <: d;
            break;
          }
       }
     }
   }
}
