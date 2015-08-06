// Copyright (c) 2013, XMOS Ltd., All rights reserved
// This software is freely distributable under a derivative of the
// University of Illinois/NCSA Open Source License posted in
// LICENSE.txt and at <http://github.xcore.com/>

#include <xs1.h>

#define KERNEL_STACKWORDS 128

.section .dp.bss, "awd", @nobits
.type old_kep, @object
.cc_top old_kep.data
.align 4
old_kep:
.word 0
.size old_kep, .-old_kep
.cc_bottom old_kep.data

.section .dp.data, "awd", @progbits
.type kernel_stack, @object
.cc_top kernel_stack.data
.align 4
kernel_stack:
.space KERNEL_STACKWORDS
.size kernel_stack, .-kernel_stack
.cc_bottom kernel_stack.data

.section .cp.rodata, "ac", @progbits
.type op0_lookup, @object
.cc_top op0_lookup.data
.align 4
op0_lookup:
.byte 4 /* 0 -> 4 */
.byte 11 /* 1 -> 11 */
.byte 0 /* 2 -> unused */
.byte 9 /* 3 -> 9 */
.byte 4 /* 4 -> 4 */
.byte 3 /* 5 -> 3 */
.byte 2 /* 6 -> 2 */
.byte 1 /* 7 -> 1 */
.byte 7 /* 8 -> 7 */
.byte 4 /* 9 -> 4 */
.byte 1 /* 10 -> 1 */
.byte 2 /* 11 -> 2 */
.byte 11 /* 12 -> 11 */
.byte 4 /* 13 -> 4 */
.byte 9 /* 14 -> 9 */
.byte 0 /* 15 -> unused */
.byte 1 /* 16 -> 1 */
.byte 2 /* 17 -> 2 */
.byte 7 /* 18 -> 7 */
.byte 4 /* 19 -> 4 */
.byte 0 /* 20 -> unused */
.byte 0 /* 21 -> unused */
.byte 11 /* 22 -> 11 */
.byte 8 /* 23 -> 8 */
.byte 0 /* 24 -> unused */
.byte 9 /* 25 -> 9 */
.byte 8 /* 26 -> 8 */
.byte 11 /* 27 -> 11 */
.byte 2 /* 28 -> 2 */
.byte 1 /* 29 -> 1 */
.byte 4 /* 30 -> 4 */
.byte 7 /* 31 -> 7 */
.byte 0 /* 32 -> unused */
.byte 10 /* 33 -> 10 */
.byte 7 /* 34 -> 7 */
.byte 8 /* 35 -> 8 */
.byte 1 /* 36 -> 1 */
.byte 2 /* 37 -> 2 */
.byte 7 /* 38 -> 7 */
.byte 0 /* 39 -> 0 */
.byte 2 /* 40 -> 2 */
.byte 1 /* 41 -> 1 */
.byte 4 /* 42 -> 4 */
.byte 7 /* 43 -> 7 */
.byte 10 /* 44 -> 10 */
.byte 0 /* 45 -> unused */
.byte 8 /* 46 -> 8 */
.byte 7 /* 47 -> 7 */
.byte 4 /* 48 -> 4 */
.byte 7 /* 49 -> 7 */
.byte 2 /* 50 -> 2 */
.byte 1 /* 51 -> 1 */
.byte 8 /* 52 -> 8 */
.byte 11 /* 53 -> 11 */
.byte 0 /* 54 -> unused */
.byte 0 /* 55 -> unused */
.byte 11 /* 56 -> 11 */
.byte 8 /* 57 -> 8 */
.byte 0 /* 58 -> unused */
.byte 10 /* 59 -> 10 */
.byte 7 /* 60 -> 7 */
.byte 4 /* 61 -> 4 */
.byte 1 /* 62 -> 1 */
.byte 2 /* 63 -> 2 */
.byte 6 /* 64 -> 6 */
.byte 5 /* 65 -> 5 */
.byte 0 /* 66 -> 0 */
.byte 3 /* 67 -> 3 */
.byte 6 /* 68 -> 6 */
.byte 9 /* 69 -> 9 */
.byte 0 /* 70 -> unused */
.byte 11 /* 71 -> 11 */
.byte 9 /* 72 -> 9 */
.byte 6 /* 73 -> 6 */
.byte 11 /* 74 -> 11 */
.byte 0 /* 75 -> unused */
.byte 1 /* 76 -> 1 */
.byte 6 /* 77 -> 6 */
.byte 3 /* 78 -> 3 */
.byte 0 /* 79 -> 0 */
.byte 11 /* 80 -> 11 */
.byte 0 /* 81 -> unused */
.byte 9 /* 82 -> 9 */
.byte 10 /* 83 -> 10 */
.byte 3 /* 84 -> 3 */
.byte 0 /* 85 -> 0 */
.byte 5 /* 86 -> 5 */
.byte 6 /* 87 -> 6 */
.byte 0 /* 88 -> 0 */
.byte 3 /* 89 -> 3 */
.byte 6 /* 90 -> 6 */
.byte 5 /* 91 -> 5 */
.byte 0 /* 92 -> unused */
.byte 0 /* 93 -> unused */
.byte 10 /* 94 -> 10 */
.byte 9 /* 95 -> 9 */
.byte 3 /* 96 -> 3 */
.byte 0 /* 97 -> 0 */
.byte 5 /* 98 -> 5 */
.byte 6 /* 99 -> 6 */
.byte 0 /* 100 -> unused */
.byte 8 /* 101 -> 8 */
.byte 5 /* 102 -> 5 */
.byte 10 /* 103 -> 10 */
.byte 8 /* 104 -> 8 */
.byte 0 /* 105 -> unused */
.byte 10 /* 106 -> 10 */
.byte 5 /* 107 -> 5 */
.byte 0 /* 108 -> 0 */
.byte 3 /* 109 -> 3 */
.byte 2 /* 110 -> 2 */
.byte 5 /* 111 -> 5 */
.byte 10 /* 112 -> 10 */
.byte 9 /* 113 -> 9 */
.byte 8 /* 114 -> 8 */
.byte 0 /* 115 -> unused */
.byte 6 /* 116 -> 6 */
.byte 5 /* 117 -> 5 */
.byte 0 /* 118 -> 0 */
.byte 3 /* 119 -> 3 */
.byte 5 /* 120 -> 5 */
.byte 6 /* 121 -> 6 */
.byte 3 /* 122 -> 3 */
.byte 0 /* 123 -> 0 */
.byte 9 /* 124 -> 9 */
.byte 10 /* 125 -> 10 */
.size op0_lookup, .-op0_lookup
.cc_bottom op0_lookup.data

.text
.globl memory_extender_handler_install
.type memory_extender_handler_install, @function
.cc_top memory_extender_handler_install.function
.globl memory_extender_handler_install.nstackwords
.set memory_extender_handler_install.nstackwords, 100
.align 2
memory_extender_handler_install:
  // Save off old kep.
  get r11, kep
  stw r11, dp[old_kep]
  // Set ksp.
  ldaw r0, sp[0]
  ldaw sp, dp[kernel_stack + 1024 - 4]
  stw r0, sp[0]
  krestsp 0
  // Set kep.
  ldap r11, handler
  set kep, r11
  retsp 0
.size memory_extender_handler_install, .-memory_extender_handler_install
.cc_bottom memory_extender_handler_install.function

.set not_enough_stack, handler.nstackwords > KERNEL_STACKWORDS
.assert 1, not_enough_stack, "Not enough kernel stack"

.weak _num_global_chanends_set
.add_to_set _num_global_chanends_set, handler.maxchanends, handler
.weak _num_global_timers_set
.add_to_set _num_global_timers_set, handler.maxtimers, handler

// Exception handler. In the case of a load / store exception the exception
// handler must extract the type of instruction and the source / destination
// register. The crc instruction is used to map the spase set of instruction
// encodings to a dense set of integers that can be used to index a lookup
// table. The polynomials and lookup tables are generated using a brute force
// search, see https://github.com/xcore/tool_map_generator.



.set handler.nstackwords, 10 + \
  (memory_extender_st8.nstackwords $M memory_extender_st16.nstackwords \
   $M memory_extender_stw.nstackwords $M memory_extender_ld8u.nstackwords \
   $M memory_extender_ld16s.nstackwords $M memory_extender_ldw.nstackwords)
.set handler.maxchanends, \
  (memory_extender_st8.maxchanends $M memory_extender_st16.maxchanends \
   $M memory_extender_stw.maxchanends $M memory_extender_ld8u.maxchanends \
   $M memory_extender_ld16s.maxchanends $M memory_extender_ldw.maxchanends)
.type handler, @function
.cc_top handler.function
.align 128
handler:
  kentsp 9
  stw spc, sp[1]
  stw r0, sp[2]
  stw r1, sp[3]
  stw r2, sp[4]
  stw r3, sp[5]
  stw r4, sp[6]
  stw r11, sp[7]
  stw lr, sp[8]

  // Registers:
  // r0 - address.
  // r2 - spc.
  // r3 - 0.
  // r4 - source / destination register.
  get r11, et
  eq r11, r11, XS1_ET_LOAD_STORE
  bf r11, unhandled
  // Get the SPC.
  stw spc, sp[1]
  ldw r2, sp[1]
  // Get the address.
  get r11, ed
  // Check MSB is set
  ashr r0, r11, 32
  bf r0, unhandled
  // Clear MSB.
  shl r0, r11, 1
  shr r0, r0, 1
  // Get the first 16bits of the instruction.
  ldc r3, 0
  ld16s r1, r2[r3]
  // Extract the source / destination register.
  ldc r11, 0x07f0
  and r4, r1, r11
  ldc r11, 0x4f
  crc32 r4, r11, r11
  ldaw r11, cp[op0_lookup]
  ld8u r4, r11[r4]
  // Increment spc.
  add r2, r2, 2
  // Extract the instruction type.
  ldc r11, 0x9800
  and r1, r1, r11
  ldc r11, 5
  crc32 r1, r11, r11
  bru r1
  .jmptable long, unhandled, short_ld8u, short_ld16s, short_ldw, short_stw
short_ld8u:
  stw r2, sp[1]
  bl memory_extender_ld8u
  bl set_reg
  bu load_handler_return
short_ld16s:
  stw r2, sp[1]
  bl memory_extender_ld16s
  bl set_reg
  bu load_handler_return
short_ldw:
  stw r2, sp[1]
  bl memory_extender_ldw
  bl set_reg
  bu load_handler_return
unhandled:
  ldw r11, dp[old_kep]
  set kep, r11
  bu handler_return

short_stw:
  stw r2, sp[1]
  bl get_reg
  bl memory_extender_stw
  bu handler_return
long:
  add r11, r2, 2
  stw r11, sp[1]
  ld16s r2, r2[r3]
  ldc r11, 0x3
  crc32 r2, r11, r11
  bru r2
  .jmptable long_st8, long_st16, unhandled, long_stw
long_st8:
  bl get_reg
  bl memory_extender_st8
  bu handler_return
long_st16:
  bl get_reg
  bl memory_extender_st16
  bu handler_return
long_stw:
  bl get_reg
  bl memory_extender_stw
  bu handler_return

load_handler_return:
  bl set_reg

handler_return:
  ldw lr, sp[8]
  ldw r11, sp[7]
  ldw r4, sp[6]
  ldw r3, sp[5]
  ldw r2, sp[4]
  ldw r1, sp[3]
  ldw r0, sp[2]
  ldw spc, sp[1]
  krestsp 9
  kret
.size handler, .-handler

.type set_reg, @function
// set_reg function. Takes value in r0, register num in r4
set_reg:
  bru r4
  .jmptable set_r0, set_r1, set_r2, set_r3, set_r4, set_r5, set_r6, set_r7, set_r8, set_r9, set_r10, set_r11
set_r0:
  stw r0, sp[2]
  retsp 0
set_r1:
  stw r0, sp[3]
  retsp 0
set_r2:
  stw r0, sp[4]
  retsp 0
set_r3:
  stw r0, sp[5]
  retsp 0
set_r4:
  stw r0, sp[6]
  retsp 0
set_r5:
  mov r5, r0
  retsp 0
set_r6:
  mov r6, r0
  retsp 0
set_r7:
  mov r7, r0
  retsp 0
set_r8:
  mov r8, r0
  retsp 0
set_r9:
  mov r9, r0
  retsp 0
set_r10:
  mov r10, r0
  retsp 0
set_r11:
  stw r0, sp[7]
  retsp 0
.size set_reg, .-set_reg

.type get_reg, @function
// get_reg function. Takes register number in r4, returns result in r1
get_reg:
  bru r4
  .jmptable get_r0, get_r1, get_r2, get_r3, get_r4, get_r5, get_r6, get_r7, get_r8, get_r9, get_r10, get_r11
get_r0:
  ldw r1, sp[2]
  retsp 0
get_r1:
  ldw r1, sp[3]
  retsp 0
get_r2:
  ldw r1, sp[4]
  retsp 0
get_r3:
  ldw r1, sp[5]
  retsp 0
get_r4:
  ldw r1, sp[6]
  retsp 0
get_r5:
  mov r1, r5
  retsp 0
get_r6:
  mov r1, r6
  retsp 0
get_r7:
  mov r1, r7
  retsp 0
get_r8:
  mov r1, r8
  retsp 0
get_r9:
  mov r1, r9
  retsp 0
get_r10:
  mov r1, r10
  retsp 0
get_r11:
  ldw r1, sp[7]
  retsp 0
.size get_reg, .-get_reg
.cc_bottom handler.function
