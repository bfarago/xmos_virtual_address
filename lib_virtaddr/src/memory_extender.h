// Copyright (c) 2013, XMOS Ltd., All rights reserved
// This software is freely distributable under a derivative of the
// University of Illinois/NCSA Open Source License posted in
// LICENSE.txt and at <http://github.xcore.com/>

#ifndef _memory_extender_h_
#define _memory_extender_h_

/**
 * \file
 * \brief Translates load / store exceptions to interface method calls.
 */

#include <stdint.h>

//handler.S
extern void memory_extender_handler_install(void);

//rest of the functions called from handler.S asm.

#endif /* _memory_extender_h_ */
