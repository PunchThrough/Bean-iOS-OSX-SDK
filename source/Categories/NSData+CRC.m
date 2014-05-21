//
//  NSData+CRC.m
//  Bean OSX Library
//
//  Created by Raymond Kampmeier on 4/29/14.
//  Copyright (c) 2014 Punch Through Design. All rights reserved.
//

#import "NSData+CRC.h"

#define CRC_POLY        0xEDB88320L
#define CRC_SEED        0xFFFFFFFFL

@implementation NSData (CRC)

void generateCRC32Table(uint32_t *pTable, uint32_t poly)
{
    for (uint32_t i = 0; i <= 255; i++)
    {
        uint32_t crc = i;
        
        for (uint32_t j = 8; j > 0; j--)
        {
            if ((crc & 1) == 1)
                crc = (crc >> 1) ^ poly;
            else
                crc >>= 1;
        }
        pTable[i] = crc;
    }
}

-(uint32_t)crc32
{
    uint32_t *pTable = malloc(sizeof(uint32_t) * 256);
    generateCRC32Table(pTable, CRC_POLY);
    
    uint32_t crc    = CRC_SEED;
    uint8_t *pBytes = (uint8_t *)[self bytes];
    uint32_t length = (uint32_t)[self length];
    
    while (length--)
    {
        crc = (crc>>8) ^ pTable[(crc & 0xFF) ^ *pBytes++];
    }
    
    free(pTable);
    return crc ^ 0xFFFFFFFFL;
}

@end
