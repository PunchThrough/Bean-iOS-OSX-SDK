#import <Foundation/Foundation.h>

/**
 *  This enum's values directly correspond to the integers used in Intel HEX to represent record types.
 *
 *  For example, if you parse the record type byte as 2, this line is the extended segment address.
 */
typedef NS_ENUM(NSInteger, PTDIntelHexLineRecordType) {
    PTDIntelHexLineRecordType_Data = 0,
    PTDIntelHexLineRecordType_EndOfFile = 1,
    PTDIntelHexLineRecordType_ExtendedSegmentAddress = 2,
    PTDIntelHexLineRecordType_StartSegmentAddress = 3,
    PTDIntelHexLineRecordType_ExtendedLinearAddress = 4,
    PTDIntelHexLineRecordType_StartLinearAddress = 5,
};

/**
 *  PTDIntelHexLine represents one line of a PTDIntelHex object parsed from Intel HEX ASCII text.
 */
@interface PTDIntelHexLine : NSObject

@property (nonatomic, assign) UInt8 byteCount;
@property (nonatomic, assign) UInt16 address;
@property (nonatomic, assign) PTDIntelHexLineRecordType recordType;
@property (nonatomic, strong) NSData *data;
@property (nonatomic, assign) UInt8 checksum;

@end
