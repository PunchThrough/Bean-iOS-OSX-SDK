#import <Foundation/Foundation.h>

#import "BleProfile.h"

#define BEAN_SCRATCH_SERVICE_UUID PUNCHTHROUGHDESIGN_128_UUID(@"FF20")
#define BEAN_SCRATCH_BANK1_CHARACTERISTIC_UUID PUNCHTHROUGHDESIGN_128_UUID(@"FF21")
#define BEAN_SCRATCH_BANK2_CHARACTERISTIC_UUID PUNCHTHROUGHDESIGN_128_UUID(@"FF22")
#define BEAN_SCRATCH_BANK3_CHARACTERISTIC_UUID PUNCHTHROUGHDESIGN_128_UUID(@"FF23")
#define BEAN_SCRATCH_BANK4_CHARACTERISTIC_UUID PUNCHTHROUGHDESIGN_128_UUID(@"FF24")
#define BEAN_SCRATCH_BANK5_CHARACTERISTIC_UUID PUNCHTHROUGHDESIGN_128_UUID(@"FF25")


@protocol ScratchProfileDelegate <NSObject>

@optional

- (void)didUpdateScratchBank:(NSInteger)bank data:(NSData*)data;

@end


@interface ScratchProfile : BleProfile <BleProfile>

@property (nonatomic, weak) id<ScratchProfileDelegate> delegate;

@property (nonatomic, strong) NSData *scratchBank1;
@property (nonatomic, strong) NSData *scratchBank2;
@property (nonatomic, strong) NSData *scratchBank3;
@property (nonatomic, strong) NSData *scratchBank4;
@property (nonatomic, strong) NSData *scratchBank5;

- (BOOL)readScratchBank:(NSInteger)bank;

@end
