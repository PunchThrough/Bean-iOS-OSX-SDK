//
//  oad.h
//  BacTrackManagement
//
//  Created by Kevin Johnson on 3/6/13.
//  Copyright (c) 2013 Punch Through Design. All rights reserved.
//


#ifndef __OAD_H__
#define __OAD_H__

#define uint16 uint16_t
#define uint8 uint8_t
#define HAL_FLASH_WORD_SIZE 4

#ifdef __cplusplus
extern "C"
{
#endif
    
    /*********************************************************************
     * INCLUDES
     */
#define ATT_UUID_SIZE 128
#define KEY_BLENGTH    16
    
    /*********************************************************************
     * CONSTANTS
     */
    
#if !defined OAD_IMG_A_PAGE
#define OAD_IMG_A_PAGE        1
#define OAD_IMG_A_AREA        62
#endif
    
#if !defined OAD_IMG_B_PAGE
    // Image-A/B can be very differently sized areas when implementing IBM vice OAD boot loader.
#if defined FEATURE_OAD_IBM
#define OAD_IMG_B_PAGE        8
#else
#define OAD_IMG_B_PAGE        63
#endif
#define OAD_IMG_B_AREA       (124 - OAD_IMG_A_AREA)
#endif
    
#if defined HAL_IMAGE_B
#define OAD_IMG_D_PAGE        OAD_IMG_A_PAGE
#define OAD_IMG_D_AREA        OAD_IMG_A_AREA
#define OAD_IMG_R_PAGE        OAD_IMG_B_PAGE
#define OAD_IMG_R_AREA        OAD_IMG_B_AREA
#else   //#elif defined HAL_IMAGE_A or a non-IBM-enabled OAD Image-A w/ constants in Bank 1 vice 5.
#define OAD_IMG_D_PAGE        OAD_IMG_B_PAGE
#define OAD_IMG_D_AREA        OAD_IMG_B_AREA
#define OAD_IMG_R_PAGE        OAD_IMG_A_PAGE
#define OAD_IMG_R_AREA        OAD_IMG_A_AREA
#endif
    
#define OAD_IMG_CRC_OSET      0x0000
#if defined FEATURE_OAD_SECURE
#define OAD_IMG_HDR_OSET      0x0000
#else  // crc0 is calculated and placed by the IAR linker at 0x0, so img_hdr_t is 2 bytes offset.
#define OAD_IMG_HDR_OSET      0x0002
#endif
    
#define OAD_CHAR_CNT          2
    
#define OAD_CHAR_IMG_NOTIFY   0
#define OAD_CHAR_IMG_BLOCK    1
    
#define OAD_LOCAL_CHAR        0 // Local OAD characteristics
#define OAD_DISC_CHAR         1 // Discovered OAD characteristics
    
    // OAD Parameter IDs
#define OAD_LOCAL_CHAR_NOTIFY 1 // Handle for local Image Notify characteristic. Read only. size uint16.
#define OAD_LOCAL_CHAR_BLOCK  2 // Handle for local Image Block characteristic. Read only. size uint16.
#define OAD_DISC_CHAR_NOTIFY  3 // Handle for discovered Image Notify characteristic. Read/Write. size uint16.
#define OAD_DISC_CHAR_BLOCK   4 // Handle for discovered Image Block characteristic. Read/Write. size uint16.
    
    // Image Identification size
#define OAD_IMG_ID_SIZE       4
    
    // Image header size (version + length + image id size)
#define OAD_IMG_HDR_SIZE      ( 2 + 2 + OAD_IMG_ID_SIZE )
    
    // The Image is transporte in 16-byte blocks in order to avoid using blob operations.
#define OAD_BLOCK_SIZE        16
#define OAD_BLOCKS_PER_PAGE  (HAL_FLASH_PAGE_SIZE / OAD_BLOCK_SIZE)
#define OAD_BLOCK_MAX        (OAD_BLOCKS_PER_PAGE * OAD_IMG_D_AREA)
    
    /*********************************************************************
     * GLOBAL VARIABLES
     */
    
    // OAD Service UUID
    //extern CONST uint8 oadServUUID[ATT_UUID_SIZE];
    
    // OAD Image Notify, OAD Image Block Request, OAD Image Block Response UUID's:
    //extern CONST uint8 oadCharUUID[OAD_CHAR_CNT][ATT_UUID_SIZE];
    
    /*********************************************************************
     * TYPEDEFS
     */
    
    // The Image Header will not be encrypted, but it will be included in a Signature.
    typedef struct {
#if defined FEATURE_OAD_SECURE
        // Secure OAD uses the Signature for image validation instead of calculating a CRC, but the use
        // of CRC==CRC-Shadow for quick boot-up determination of a validated image is still used.
        uint16 crc0;       // CRC must not be 0x0000 or 0xFFFF.
#endif
        uint16 crc1;       // CRC-shadow must be 0xFFFF.
        // User-defined Image Version Number - default logic uses simple a '<' comparison to start an OAD.
        uint16 ver;
        uint16 len;        // Image length in 4-byte blocks (i.e. HAL_FLASH_WORD_SIZE blocks).
        uint8  uid[4];     // User-defined Image Identification bytes.
        uint8  res[4];     // Reserved space for future use.
    } img_hdr_t;
#if defined FEATURE_OAD_SECURE
    static_assert((sizeof(img_hdr_t) == 16), "Bad SBL_ADDR_AES_HDR definition.");
    static_assert(((sizeof(img_hdr_t) % KEY_BLENGTH) == 0),
                  "img_hdr_t is not an even multiple of KEY_BLENGTH");
#endif
    
    // The AES Header must be encrypted and the Signature must include the Image Header.
    typedef struct {
        uint8 signature[KEY_BLENGTH];  // The AES-128 CBC-MAC signature.
        uint8 nonce12[12];             // The 12-byte Nonce for calculating the signature.
        uint8 spare[4];
    } aes_hdr_t;
    
    
#ifdef __cplusplus
}
#endif

#endif
/*********************************************************************
 *********************************************************************/
