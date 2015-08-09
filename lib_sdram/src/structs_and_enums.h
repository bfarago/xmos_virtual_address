// Copyright (c) 2015, XMOS Ltd, All rights reserved
#ifndef STRUCTS_AND_ENUMS_H_
#define STRUCTS_AND_ENUMS_H_

#define SDRAM_MAX_CMD_BUFFER 8

typedef struct {
    unsigned address;
    unsigned word_count;
    unsigned * movable buffer;
} sdram_cmd;

/*
 * \typedef
 * This is the internal state used to manage the command buffers. It should not be accessed.
 */
typedef struct s_sdram_state {
  unsigned head;
  unsigned pending_cmds;
  sdram_cmd * unsafe cmd[SDRAM_MAX_CMD_BUFFER];
} s_sdram_state;

typedef enum {
    SDRAM_CMD_READ,
    SDRAM_CMD_WRITE,
    SDRAM_CMD_SHUTDOWN
} e_command;

#endif /* STRUCTS_AND_ENUMS_H_ */
