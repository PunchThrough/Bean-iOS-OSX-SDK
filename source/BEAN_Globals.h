//
//  BEAN_Globals.h
//  BleArduino
//
//  Created by Raymond Kampmeier on 1/16/14.
//  Copyright (c) 2014 Punch Through Design. All rights reserved.
//

#ifndef BleArduino_BEAN_Globals_h
#define BleArduino_BEAN_Globals_h

#define __objectivec TRUE

#define member_size(type, member) sizeof(((type *)0)->member)

//a495xxxx-c5b1-4b44-b512-1370f02d74de
#define PUNCHTHROUGHDESIGN_128_UUID(uuid16) @"A495" uuid16 @"-C5B1-4B44-B512-1370F02D74DE"

// based on http://doing-it-wrong.mikeweller.com/2012/07/youre-doing-it-wrong-1-nslogdebug-ios.html
#if DEBUG == 1
    #define PTDLog NSLog
#else
    #define PTDLog(...)
#endif

#endif
