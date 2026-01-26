//
//  SafePluginRegistrant.m
//  Safe wrapper for plugin registration on iOS 26 beta
//

#import "SafePluginRegistrant.h"
#import <Flutter/Flutter.h>
#import <Foundation/Foundation.h>

#if __has_include(<audioplayers_darwin/AudioplayersDarwinPlugin.h>)
#import <audioplayers_darwin/AudioplayersDarwinPlugin.h>
#define HAS_AUDIOPLAYERS_DARWIN 1
#else
#define HAS_AUDIOPLAYERS_DARWIN 0
#endif

#if __has_include(<cloud_firestore/FLTFirebaseFirestorePlugin.h>)
#import <cloud_firestore/FLTFirebaseFirestorePlugin.h>
#define HAS_CLOUD_FIRESTORE 1
#else
#define HAS_CLOUD_FIRESTORE 0
#endif

#if __has_include(<device_info_plus/FPPDeviceInfoPlusPlugin.h>)
#import <device_info_plus/FPPDeviceInfoPlusPlugin.h>
#define HAS_DEVICE_INFO_PLUS 1
#else
#define HAS_DEVICE_INFO_PLUS 0
#endif

#if __has_include(<flutter_local_notifications/FlutterLocalNotificationsPlugin.h>)
#import <flutter_local_notifications/FlutterLocalNotificationsPlugin.h>
#define HAS_FLUTTER_LOCAL_NOTIFICATIONS 1
#else
#define HAS_FLUTTER_LOCAL_NOTIFICATIONS 0
#endif

#if __has_include(<flutter_timezone/FlutterTimezonePlugin.h>)
#import <flutter_timezone/FlutterTimezonePlugin.h>
#define HAS_FLUTTER_TIMEZONE 1
#else
#define HAS_FLUTTER_TIMEZONE 0
#endif

#if __has_include(<firebase_auth/FLTFirebaseAuthPlugin.h>)
#import <firebase_auth/FLTFirebaseAuthPlugin.h>
#define HAS_FIREBASE_AUTH 1
#else
#define HAS_FIREBASE_AUTH 0
#endif

#if __has_include(<firebase_core/FLTFirebaseCorePlugin.h>)
#import <firebase_core/FLTFirebaseCorePlugin.h>
#define HAS_FIREBASE_CORE 1
#else
#define HAS_FIREBASE_CORE 0
#endif

#if __has_include(<path_provider_foundation/PathProviderPlugin.h>)
#import <path_provider_foundation/PathProviderPlugin.h>
#define HAS_PATH_PROVIDER_FOUNDATION 1
#else
#define HAS_PATH_PROVIDER_FOUNDATION 0
#endif

#if __has_include(<share_plus/FPPSharePlusPlugin.h>)
#import <share_plus/FPPSharePlusPlugin.h>
#define HAS_SHARE_PLUS 1
#else
#define HAS_SHARE_PLUS 0
#endif

#if __has_include(<vibration/VibrationPlugin.h>)
#import <vibration/VibrationPlugin.h>
#define HAS_VIBRATION 1
#else
#define HAS_VIBRATION 0
#endif

static BOOL ShouldSkipAudioplayers(void) {
  NSDictionary *environment = [[NSProcessInfo processInfo] environment];
  NSString *flag = [environment[@"SKIP_AUDIOPLAYERS_PLUGIN"] lowercaseString];
  if (flag.length > 0) {
    return [flag isEqualToString:@"1"] ||
           [flag isEqualToString:@"true"] ||
           [flag isEqualToString:@"yes"];
  }
  return NO;
}

@implementation SafePluginRegistrant

+ (void)registerWithRegistry:(NSObject<FlutterPluginRegistry>*)registry {
  // Register plugins manually with safe fallbacks for iOS 26 beta compatibility

#if HAS_CLOUD_FIRESTORE
  [FLTFirebaseFirestorePlugin registerWithRegistrar:[registry registrarForPlugin:@"FLTFirebaseFirestorePlugin"]];
#else
  NSLog(@"cloud_firestore not available; skipping registration");
#endif

#if HAS_DEVICE_INFO_PLUS
  [FPPDeviceInfoPlusPlugin registerWithRegistrar:[registry registrarForPlugin:@"FPPDeviceInfoPlusPlugin"]];
#else
  NSLog(@"device_info_plus not available; skipping registration");
#endif

#if HAS_FIREBASE_AUTH
  [FLTFirebaseAuthPlugin registerWithRegistrar:[registry registrarForPlugin:@"FLTFirebaseAuthPlugin"]];
#else
  NSLog(@"firebase_auth not available; skipping registration");
#endif

#if HAS_FIREBASE_CORE
  [FLTFirebaseCorePlugin registerWithRegistrar:[registry registrarForPlugin:@"FLTFirebaseCorePlugin"]];
#else
  NSLog(@"firebase_core not available; skipping registration");
#endif

#if HAS_FLUTTER_LOCAL_NOTIFICATIONS
  [FlutterLocalNotificationsPlugin registerWithRegistrar:[registry registrarForPlugin:@"FlutterLocalNotificationsPlugin"]];
#else
  NSLog(@"flutter_local_notifications not available; skipping registration");
#endif

#if HAS_FLUTTER_TIMEZONE
  [FlutterTimezonePlugin registerWithRegistrar:[registry registrarForPlugin:@"FlutterTimezonePlugin"]];
#else
  NSLog(@"flutter_timezone not available; skipping registration");
#endif

#if HAS_PATH_PROVIDER_FOUNDATION
  [PathProviderPlugin registerWithRegistrar:[registry registrarForPlugin:@"PathProviderPlugin"]];
#else
  NSLog(@"path_provider_foundation not available; skipping registration");
#endif

#if HAS_SHARE_PLUS
  [FPPSharePlusPlugin registerWithRegistrar:[registry registrarForPlugin:@"FPPSharePlusPlugin"]];
#else
  NSLog(@"share_plus not available; skipping registration");
#endif

#if HAS_VIBRATION
  [VibrationPlugin registerWithRegistrar:[registry registrarForPlugin:@"VibrationPlugin"]];
#else
  NSLog(@"vibration not available; skipping registration");
#endif

#if HAS_AUDIOPLAYERS_DARWIN
  if (ShouldSkipAudioplayers()) {
    NSLog(@"Skipping audioplayers_darwin registration due to compatibility flag");
  } else {
    [AudioplayersDarwinPlugin registerWithRegistrar:[registry registrarForPlugin:@"AudioplayersDarwinPlugin"]];
  }
#else
  NSLog(@"audioplayers_darwin not available; skipping registration");
#endif
}

@end
