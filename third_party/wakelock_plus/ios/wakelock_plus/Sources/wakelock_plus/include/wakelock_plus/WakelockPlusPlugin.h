#if TARGET_OS_OSX
#import <FlutterMacOS/FlutterMacOS.h>
#else
#import <Flutter/Flutter.h>
#endif

#import "messages.g.h"

@interface WakelockPlusPlugin : NSObject <FlutterPlugin, WAKELOCKPLUSWakelockPlusApi>

@end
