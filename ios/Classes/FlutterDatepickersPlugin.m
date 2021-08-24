#import "FlutterDatepickersPlugin.h"
#if __has_include(<flutter_datepickers/flutter_datepickers-Swift.h>)
#import <flutter_datepickers/flutter_datepickers-Swift.h>
#else
// Support project import fallback if the generated compatibility header
// is not copied when this plugin is created as a library.
// https://forums.swift.org/t/swift-static-libraries-dont-copy-generated-objective-c-header/19816
#import "flutter_datepickers-Swift.h"
#endif

@implementation FlutterDatepickersPlugin
+ (void)registerWithRegistrar:(NSObject<FlutterPluginRegistrar>*)registrar {
  [SwiftFlutterDatepickersPlugin registerWithRegistrar:registrar];
}
@end
