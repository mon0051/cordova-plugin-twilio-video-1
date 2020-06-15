#import <Foundation/Foundation.h>

@interface TwilioVideoConfig : NSObject
@property NSString *primaryColorHex;
@property NSString *secondaryColorHex;
@property NSString *i18nConnectionError;
@property NSString *i18nDisconnectedWithError;
@property NSString *i18nAccept;
@property NSString *i18nCallTitle;
@property NSString *i18nCallDuration;
@property NSString *i18nNetworkQualityBannerText;
@property NSString *i18nNetworkQualityBannerButton;
@property BOOL handleErrorInApp;
@property BOOL hangUpInApp;
@property int startCallTimeInSeconds;
@property int videoNetworkQualityThreshold;
@property NSTimeInterval ignoreNQBannerInSeconds;
@property BOOL disableNQBanner;

+ (instancetype) configFromDict:(NSDictionary*)dict;
+ (UIColor *)colorFromHexString:(NSString *)hexString;
@end
