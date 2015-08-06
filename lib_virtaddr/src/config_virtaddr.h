/*
 * config_virtaddr.h
 *
 *  Created on: 2015.08.06.
 *      Author: Barna Farago (MYND-ideal ltd)
 */


#ifndef CONFIG_VIRTADDR_H_
#define CONFIG_VIRTADDR_H_

//system wide whatevers like
//board specific declaration can be here...
typedef enum{
  VP_TILE0,
  VP_TILE1,
  VP_TILE2,
  VP_TILE3,
  VP_SDRAM0,
  VP_FLASH0,
  VP_DEVPC,
  VP_DEVLOG
} tOriginLocation; //TODO: tile and type to different bitfield?

#endif /* CONFIG_VIRTADDR_H_ */
