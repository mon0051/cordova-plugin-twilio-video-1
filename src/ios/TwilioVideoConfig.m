#import "TwilioVideoConfig.h"

#define PRIMARY_COLOR_PROP                  @"primaryColor"
#define SECONDARY_COLOR_PROP                @"secondaryColor"
#define i18n_CONNECTION_ERROR_PROP          @"i18nConnectionError"
#define i18n_DISCONNECTED_WITH_ERROR_PROP   @"i18nDisconnectedWithError"
#define i18n_ACCEPT_PROP                    @"i18nAccept"
#define i18n_CALL_TITLE_PROP                @"i18nCallTitle"
#define i18n_CALL_DURATION_PROP             @"i18nCallDuration"
#define HANDLE_ERROR_IN_APP                 @"handleErrorInApp"
#define HANG_UP_IN_APP                      @"hangUpInApp"
#define VIDEO_NQ_THRESHOLD                  @"videoNetworkQualityThreshold"

@implementation TwilioVideoConfig

+ (instancetype)configFromDict:(NSDictionary *)dict {
    TwilioVideoConfig *config = [[TwilioVideoConfig alloc] init];
    [config parse:dict];
    return config;
}

-(void) parse:(NSDictionary*)config {
    self.primaryColorHex = [self stringInConfig:config forKey:PRIMARY_COLOR_PROP defaultValue:nil];
    self.secondaryColorHex = [self stringInConfig:config forKey:SECONDARY_COLOR_PROP defaultValue:nil];
    self.i18nConnectionError = [self stringInConfig:config forKey:i18n_CONNECTION_ERROR_PROP defaultValue:@"It was not possible to join the room"];
    self.i18nDisconnectedWithError = [self stringInConfig:config forKey:i18n_DISCONNECTED_WITH_ERROR_PROP defaultValue:@"Disconnected"];
    self.i18nAccept = [self stringInConfig:config forKey:i18n_ACCEPT_PROP defaultValue:@"Accept"];
    self.i18nCallTitle = [self stringInConfig:config forKey:i18n_CALL_TITLE_PROP defaultValue:@"Set Duration"];
    self.i18nCallDuration = [self stringInConfig:config forKey:i18n_CALL_DURATION_PROP defaultValue:@"00:15 min"];
    self.handleErrorInApp = [self stringInConfig:config forKey:HANDLE_ERROR_IN_APP defaultValue:nil];
    self.hangUpInApp = [self stringInConfig:config forKey:HANG_UP_IN_APP defaultValue:nil];
    self.videoNetworkQualityThreshold = [[self numberInConfig:config forKey:VIDEO_NQ_THRESHOLD defaultValue:[NSNumber numberWithInt:1]] intValue];
}

- (NSString*) stringInConfig:(NSDictionary*)config forKey:(NSString*)key defaultValue:(NSString*)defaultValue {
    if (config == nil || config == (id)[NSNull null]) return defaultValue;
    NSString* value = [config objectForKey:key];
    if (value == nil) {
        return defaultValue;
    } else {
        return value;
    }
}

- (NSNumber*) numberInConfig:(NSDictionary*)config forKey:(NSString*)key defaultValue:(NSNumber*)defaultValue {
    if (config == nil || config == (id)[NSNull null]) return defaultValue;
    NSNumber* value = [config objectForKey:key];
    if (value == nil) {
        return defaultValue;
    } else {
        return value;
    }
}

+ (UIColor *)colorFromHexString:(NSString *)hexString {
    unsigned rgbValue = 0;
    NSScanner *scanner = [NSScanner scannerWithString:hexString];
    [scanner setScanLocation:1]; // bypass '#' character
    [scanner scanHexInt:&rgbValue];
    return [UIColor colorWithRed:((rgbValue & 0xFF0000) >> 16)/255.0 green:((rgbValue & 0xFF00) >> 8)/255.0 blue:(rgbValue & 0xFF)/255.0 alpha:1.0];
}
@end
