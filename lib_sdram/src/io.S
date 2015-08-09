// Copyright (c) 2015, XMOS Ltd, All rights reserved
.text
.cc_top sdram_block_write.function
.align 4
.globl sdram_block_write
.type  sdram_block_write, @function
sdram_block_write:

#define WRITE_STACK_WORDS 3
	entsp WRITE_STACK_WORDS

 	//r0 buffer pointer
	//r1 sdram_ports struct
	//r2 t0	- start time
	//r3 word_count
	//sp[1] row_words

#define w_ras	 			r0
#define w_dq_ah	 			r1
#define w_term_time 		r2
#define w_we 				r3
#define w_cp_save			r4
#define w_two				r5
#define w_temp 				r11

	stw r4, sp[0]
	stw r5, sp[2]

	//save the cp
	ldaw r11, cp[0]
	mov w_cp_save, r11

	//adjust the buffer pointer
	ldw w_temp, 	sp[1+WRITE_STACK_WORDS]	//row_words
	sub w_temp, w_temp, r3
	ldaw w_temp, r0[-w_temp]
	set cp, w_temp

	add w_term_time, r2, 2
	add w_term_time, w_term_time, r3
	add w_term_time, w_term_time, r3

	ldw w_temp, 	sp[1+WRITE_STACK_WORDS]	//row_words
	sub w_temp, w_temp, r3
	add w_temp, w_temp, w_temp

	ldw w_ras, 		r1[2]	//ras
	ldw w_we, 		r1[3]	//we
	ldw w_dq_ah, 	r1[0]	//dq_ah

.align 4
	ldc w_two, 2
	bru w_temp

	//(blocking)
	#include "sdram_block_write_body.inc"

	setpt res[w_we], w_term_time
	outpw res[w_we], w_two, 2

	mkmsk w_temp, 32
	out res[w_dq_ah], w_temp

	add w_term_time, w_term_time, 8
	setpt res[w_we],  w_term_time
	outpw res[w_we],  w_two, 2
	setpt res[w_ras], w_term_time
	outpw res[w_ras], w_two, 2

	set cp, w_cp_save

	ldw r5, sp[2]
	ldw r4, sp[0]

	retsp WRITE_STACK_WORDS
.globl sdram_block_write.nstackwords
.linkset sdram_block_write.nstackwords, WRITE_STACK_WORDS
.globl sdram_block_write.maxtimers
.linkset sdram_block_write.maxtimers, 0
.globl sdram_block_write.maxchanends
.linkset sdram_block_write.maxchanends, 0
.globl sdram_block_write.maxthreads
.linkset sdram_block_write.maxthreads, 1
.cc_bottom sdram_block_write.function



.cc_top sdram_block_read.function
.align 4
.globl sdram_block_read
.type  sdram_block_read, @function
sdram_block_read:
#define READ_STACK_WORDS 6
	entsp READ_STACK_WORDS

 	//r0 buffer pointer
	//r1 sdram_ports struct
	//r2 t0	- start time
	//r3 word_count
	//sp[1] row_words
	//sp[2] cas_latency

#define ras	 			r0
#define dq_ah	 		r1
#define term_time 		r2
#define jump_reg 		r3
#define we 				r4
#define start_time		r5
#define sp_save			r6
#define temp 			r11

	stw r4, sp[0]
	stw r5, sp[3]
	stw r6, sp[4]

	//save the dp to sp[5]
	ldaw temp, dp[0]
	stw temp, sp[5]

	//adjust the buffer pointer
	ldw temp, 	sp[READ_STACK_WORDS+1]	//row_words
	sub temp, temp, r3
	ldaw temp, r0[-temp]
	set dp, temp

#define N (1)
	//set the first input time (t+CAS+N)
	ldw temp, 	sp[READ_STACK_WORDS+2]	//cas_latency
	add start_time, r2, temp
	add start_time, start_time, N

	//calculate the time to issue the terminate cmd
	add term_time, start_time, r3
	add term_time, term_time, r3

	ldw temp, 	sp[READ_STACK_WORDS+1]	//row_words
	sub jump_reg, temp, r3
	add jump_reg, jump_reg, jump_reg

	ldaw sp_save, sp[0]

	//load the ports
	ldw ras, 	r1[2]	//ras
	ldw we, 	r1[3]	//we
	ldw dq_ah, 	r1[0]	//dq_ah

	//issue the we term signals(non-blocking)
	setpt res[we], term_time
	ldc temp, 2
	outpw res[we], temp, 2

	//inc the term time by a few for the precharge
	ldc temp, 12
	add term_time, term_time, temp

	//store the midway dp
	ldaw temp, dp[63]
	add temp, temp, 4
	set sp, temp

	setpt res[dq_ah], start_time	//(blocking)
.align 4
	in temp, res[dq_ah]	//input junk
	bru jump_reg
	#include "sdram_block_read_body.inc"

	//r0	ras
	//r1	dq_ah
	//r2	term_time
	//r3	-
	//r4	we
	//r5	-
	//r11	used as a temp

	syncr res[dq_ah]

	ldc temp, 10
	setpt res[ras], term_time
	outpw res[ras], temp, 2
	setpt res[we],  term_time
	outpw res[we],  temp, 2

	mkmsk temp, 32
	out res[dq_ah], temp

	set sp, sp_save

	ldw temp, sp[5]
	set dp, temp

	ldw r6, sp[4]
	ldw r5, sp[3]
	ldw r4, sp[0]
	retsp READ_STACK_WORDS

.globl sdram_block_read.nstackwords
.linkset sdram_block_read.nstackwords, READ_STACK_WORDS
.globl sdram_block_read.maxtimers
.linkset sdram_block_read.maxtimers, 0
.globl sdram_block_read.maxchanends
.linkset sdram_block_read.maxchanends, 0
.globl sdram_block_read.maxthreads
.linkset sdram_block_read.maxthreads, 1

.cc_bottom sdram_block_read.function


