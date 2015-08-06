// Copyright (c) 2013, XMOS Ltd., All rights reserved
// This software is freely distributable under a derivative of the
// University of Illinois/NCSA Open Source License posted in
// LICENSE.txt and at <http://github.xcore.com/>

#include "memory_extender.h"
#include <stdint.h>
#include "virtaddr.h"

/*
// Dummy function to force an array bound check.
static void ptr_check(client interface memory_extender p[]) {}
*/

void memory_extender_st8(uintptr_t address, unsigned data)
{
  tVirtPage*unsafe page= vsResolveVirtualAddress(address);
  if (page) unsafe { page->imem->st8(address, data); }
}

void memory_extender_st16(uintptr_t address, unsigned data)
{
    tVirtPage*unsafe page= vsResolveVirtualAddress(address);
    if (page) unsafe { page->imem->st16(address, data); }
}

void memory_extender_stw(uintptr_t address, unsigned data)
{
    tVirtPage*unsafe page= vsResolveVirtualAddress(address);
    if (page) unsafe { page->imem->stw(address, data); }
}

uint8_t memory_extender_ld8u(uintptr_t address)
{
    tVirtPage*unsafe page= vsResolveVirtualAddress(address);
    if (page) unsafe {return page->imem->ld8u(address); }
    return 0;
}

int16_t memory_extender_ld16s(uintptr_t address)
{
    tVirtPage*unsafe page= vsResolveVirtualAddress(address);
    if (page) unsafe {return page->imem->ld16s(address); }
    return 0;
}

unsigned memory_extender_ldw(uintptr_t address)
{
    tVirtPage*unsafe page= vsResolveVirtualAddress(address);
    if (page) unsafe {return page->imem->ldw(address); }
    return 0;
}
