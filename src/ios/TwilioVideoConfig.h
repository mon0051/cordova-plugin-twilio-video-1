#import <Foundation/Foundation.h>

@interface TwilioVideoConfig : NSObject
@property NSString *primaryColorHex;
@property NSString *secondaryColorHex;
@property NSString *i18nConnectionError;
@property NSString *i18nDisconnectedWithError;
@property NSString *i18nAccept;
@property NSString *i18nCallTitle;
@property NSString *i18nCallDuration;
@property BOOL handleErrorInApp;
@property BOOL hangUpInApp;
@property int startCallTimeInSeconds;
@property int videoNetworkQualityThreshold;
@property NSTimeInterval ignoreNQBannerInSeconds;

+ (instancetype) configFromDict:(NSDictionary*)dict;
+ (UIColor *)colorFromHexString:(NSString *)hexString;
@end
