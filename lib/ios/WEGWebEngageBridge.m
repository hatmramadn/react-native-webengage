/**
 *  webengageBridge.m
 *
 *  Created by Uzma Sayyed on 10/16/17.
 */

#import "WEGWebEngageBridge.h"
#import <React/RCTLog.h>
#import <WebEngage/WebEngage.h>
#import <WebEngage/WEGAnalytics.h>
#import <React/RCTBundleURLProvider.h>
@import UserNotifications;

NSString * const DATE_FORMAT = @"yyyy-MM-dd'T'HH:mm:ss.SSS'Z'";
int const DATE_FORMAT_LENGTH = 24;
bool weHasListeners = NO;

@implementation WEGWebEngageBridge

RCT_EXPORT_MODULE(webengageBridge);

+ (id)allocWithZone:(NSZone *)zone {
    static WEGWebEngageBridge *sharedInstance = nil;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        sharedInstance = [super allocWithZone:zone];
    });
    return sharedInstance;
}

- (NSURL *)sourceURLForBridge:(RCTBridge *)bridge {
    #if DEBUG
    return [[RCTBundleURLProvider sharedSettings] jsBundleURLForBundleRoot:@"index"];
    #else
      return [[NSBundle mainBundle] URLForResource:@"main" withExtension:@"jsbundle"];
    #endif
}

- (NSArray<id<RCTBridgeModule>> *)extraModulesForBridge:(RCTBridge *)bridge {
    WEGWebEngageBridge* b = [WEGWebEngageBridge new];
    self.wegBridge = b;
    b.bridge = bridge;
    return @[b];
}

- (NSDate *)getDate:(NSString *)strValue {
    NSDateFormatter * dateFormatter = [[NSDateFormatter alloc] init];
    [dateFormatter setDateFormat:DATE_FORMAT];
    [dateFormatter setTimeZone:[NSTimeZone timeZoneWithAbbreviation:@"UTC"]];
    NSDate * date = [dateFormatter dateFromString:strValue];
    return date;
}

- (NSDictionary *)setDatesInDictionary:(NSMutableDictionary *)mutableDict {
    NSArray * keys = [mutableDict allKeys];
    for (id key in keys) {
        id value = mutableDict[key];
        if ([value isKindOfClass:[NSString class]] && [value length] == DATE_FORMAT_LENGTH) {
            NSDate * date = [self getDate:value];
            if (date != nil) {
                mutableDict[key] = date;
            }
        } else if ([value isKindOfClass:[NSDictionary class]]) {
            NSMutableDictionary * nestedDict = [value mutableCopy];
            mutableDict[key] = [self setDatesInDictionary:nestedDict];
        } else if ([value isKindOfClass:[NSArray class]]) {
            NSMutableArray * nestedArr = [value mutableCopy];
            mutableDict[key] = [self setDatesInArray:nestedArr];
        }
    }
    return mutableDict;
}

- (NSArray *)setDatesInArray:(NSMutableArray *)mutableArr {
    for (int i = 0; i < [mutableArr count]; i++) {
        id value = mutableArr[i];
        if ([value isKindOfClass:[NSString class]] && [value length] == DATE_FORMAT_LENGTH) {
            NSDate * date = [self getDate:value];
            if (date != nil) {
                mutableArr[i] = date;
            }
        } else if ([value isKindOfClass:[NSDictionary class]]) {
            NSMutableDictionary * nestedDict = [value mutableCopy];
            mutableArr[i] = [self setDatesInDictionary:nestedDict];
        } else if ([value isKindOfClass:[NSArray class]]) {
            NSMutableArray * nestedArr = [value mutableCopy];
            mutableArr[i] = [self setDatesInArray:nestedArr];
        }
    }
    return mutableArr;
}

RCT_EXPORT_METHOD(init:(BOOL)autoRegister) {
    [[WebEngage sharedInstance] application:[UIApplication sharedApplication] didFinishLaunchingWithOptions:@{} notificationDelegate:self autoRegister:autoRegister];
}

RCT_EXPORT_METHOD(trackEventWithName:(NSString *)name){
    [[WebEngage sharedInstance].analytics trackEventWithName:name];
}

RCT_EXPORT_METHOD(trackEventWithNameAndData:(NSString *)name andValue:(NSDictionary *)value)
{
    NSMutableDictionary * mutableDict = [value mutableCopy];
    id<WEGAnalytics> weAnalytics = [WebEngage sharedInstance].analytics;
    [weAnalytics trackEventWithName:name andValue:[self setDatesInDictionary:mutableDict]];
}

RCT_EXPORT_METHOD(screenNavigated:(NSString *)screenName){
    [[WebEngage sharedInstance].analytics navigatingToScreenWithName:screenName];
}

RCT_EXPORT_METHOD(screenNavigatedWithData:(NSString*) screenName andData: (NSDictionary*) userData){
    if (userData) {
        NSMutableDictionary * mutableDict = [userData mutableCopy];
        [[WebEngage sharedInstance].analytics navigatingToScreenWithName:screenName andData:[self setDatesInDictionary:mutableDict]];
    }
}

RCT_EXPORT_METHOD(login:(NSString*)userIdentifier){
    [[WebEngage sharedInstance].user login:userIdentifier];
}

RCT_EXPORT_METHOD(setAttribute:(NSString*)attributeName value:(id)value){
    if ([value isKindOfClass:[NSString class]]) {
        if ([value length] == DATE_FORMAT_LENGTH) {
            NSDate * date = [self getDate:value];
            if (date != nil) {
                [[WebEngage sharedInstance].user setAttribute:attributeName withDateValue:date];
            } else {
                [[WebEngage sharedInstance].user setAttribute:attributeName withStringValue:value];
            }
        } else {
            [[WebEngage sharedInstance].user setAttribute:attributeName withStringValue:value];
        }
    }
    else if ([value isKindOfClass:[NSNumber class]]) {
        [[WebEngage sharedInstance].user setAttribute:attributeName withValue:value];
    }
    else if ([value isKindOfClass:[NSArray class]]) {
        [[WebEngage sharedInstance].user setAttribute:attributeName withArrayValue:value];
    }
    else if ([value isKindOfClass:[NSDictionary class]]) {
        [[WebEngage sharedInstance].user setAttribute:attributeName withDictionaryValue:value];
    }
    else if ([value isKindOfClass:[NSDate class]]) {
        [[WebEngage sharedInstance].user setAttribute:attributeName withDateValue:value];
    }
}

RCT_EXPORT_METHOD(deleteAttribute:(NSString*)attributeName){
    [[WebEngage sharedInstance].user deleteAttribute:attributeName];
}

RCT_EXPORT_METHOD(deleteAttributes:(NSArray*)attributes){
    [[WebEngage sharedInstance].user deleteAttributes:attributes];
}

RCT_EXPORT_METHOD(setEmail:(NSString*)email){
    [[WebEngage sharedInstance].user setEmail:email];
}

RCT_EXPORT_METHOD(setHashedEmail:(NSString*)hashedEmail){
    [[WebEngage sharedInstance].user setHashedEmail:hashedEmail];
}

RCT_EXPORT_METHOD(setPhone: (NSString*) phone){
    [[WebEngage sharedInstance].user setPhone:phone];
}

RCT_EXPORT_METHOD(setHashedPhone:(NSString*)hashedPhone){
    [[WebEngage sharedInstance].user setHashedPhone:hashedPhone];
}

RCT_EXPORT_METHOD(setBirthDateString:(NSString*) dobString){
    [[WebEngage sharedInstance].user setBirthDateString:dobString];
}

RCT_EXPORT_METHOD(setGender:(NSString*)gender){
    [[WebEngage sharedInstance].user setGender:gender];
}

RCT_EXPORT_METHOD(setFirstName:(NSString*)name){
    [[WebEngage sharedInstance].user setFirstName:name];
}

RCT_EXPORT_METHOD(setLastName:(NSString*)name){
    [[WebEngage sharedInstance].user setLastName:name];
}

RCT_EXPORT_METHOD(setCompany:(NSString*)company){
    [[WebEngage sharedInstance].user setCompany:company];
}

RCT_EXPORT_METHOD(updateListenerCount){
}

RCT_EXPORT_METHOD(setOptIn:(NSString*)channel status:(BOOL)status) {
    NSLocale* locale = [NSLocale localeWithLocaleIdentifier:@"en_US"];
    NSString* ch = [channel lowercaseStringWithLocale:locale];
    if ([ch isEqualToString:@"push"]) {
        [[WebEngage sharedInstance].user setOptInStatusForChannel:WEGEngagementChannelPush status:status];
    } else if ([ch isEqualToString:@"sms"]) {
        [[WebEngage sharedInstance].user setOptInStatusForChannel:WEGEngagementChannelSMS status:status];
    } else if ([ch isEqualToString:@"email"]) {
        [[WebEngage sharedInstance].user setOptInStatusForChannel:WEGEngagementChannelEmail status:status];
    } else if ([ch isEqualToString:@"in_app"]) {
        [[WebEngage sharedInstance].user setOptInStatusForChannel:WEGEngagementChannelInApp status:status];
    } else if ([ch isEqualToString:@"whatsapp"]) {
        [[WebEngage sharedInstance].user setOptInStatusForChannel:WEGEngagementChannelWhatsapp status:status];
    } else {
        NSLog(@"WebEngage: Invalid channel: %@. Must be one of [push, sms, email, in_app, whatsapp].", ch);
    }
}

RCT_EXPORT_METHOD(logout){
    [[WebEngage sharedInstance].user logout];
}

- (NSArray<NSString *> *)supportedEvents {
    return @[@"notificationPrepared", @"notificationShown", @"notificationClicked", @"notificationDismissed", @"pushNotificationClicked",@"universalLinkClicked"];
}

- (void)notification:(NSMutableDictionary *)inAppNotificationData clickedWithAction:(NSString *)actionId {
    RCTLogInfo(@"in-app notification clicked with action %@", actionId);
    inAppNotificationData[@"clickId"] = actionId;
    NSArray *actions = [inAppNotificationData valueForKey:@"actions"];
    if (actions != nil) {
        for (id action in actions) {
            if (action != nil) {
                NSString *actionEId = [action valueForKey:@"actionEId"];
                if ([actionEId isEqualToString: actionId]) {
                    inAppNotificationData[@"deepLink"] = [action valueForKey:@"actionLink"];
                }
            }
        }
    }
    [self sendEventWithName:@"notificationClicked" body:inAppNotificationData];
}

- (void)notificationDismissed:(NSMutableDictionary *)inAppNotificationData {
    RCTLogInfo(@"webengageBridge: in-app notification dismissed");
    [self sendEventWithName:@"notificationDismissed" body:inAppNotificationData];
}

- (NSMutableDictionary *)notificationPrepared:(NSMutableDictionary *)inAppNotificationData shouldStop:(BOOL *)stopRendering {
    [self sendEventWithName:@"notificationPrepared" body:inAppNotificationData];
    return inAppNotificationData;
}

- (void)notificationShown:(NSMutableDictionary *)inAppNotificationData {
    RCTLogInfo(@"webengageBridge: in-app notification shown");
    [self sendEventWithName:@"notificationShown" body:inAppNotificationData];
}

-(void)WEGHandleDeeplink:(NSString *)deeplink userData:(NSDictionary *)data{
    RCTLogInfo(@"webengageBridge: push notification clicked with deeplink: %@", deeplink);
    NSDictionary *pushData = @{@"deeplink":deeplink, @"userData":data};
     if (weHasListeners) {
        [self sendEventWithName:@"pushNotificationClicked" body:pushData];
    } else {
        if (self.pendingEventsDict == nil) {
            self.pendingEventsDict = [NSMutableDictionary dictionary];
            self.pendingEventsDict[@"pushNotificationClicked"] = pushData;
        } else {
            self.pendingEventsDict[@"pushNotificationClicked"] = pushData;
        }
    }
}

- (void)sendUniversalLinkLocation:(NSString *)location{
    RCTLogInfo(@"webengageBridge: universal link clicked with location: %@", location);
    NSDictionary *data = @{@"location":location};
    if (weHasListeners) {
        [self sendEventWithName:@"universalLinkClicked" body:data];
    } else {
        if (self.pendingEventsDict == nil) {
            self.pendingEventsDict = [NSMutableDictionary dictionary];
            self.pendingEventsDict[@"universalLinkClicked"] = data;
        } else {
            self.pendingEventsDict[@"universalLinkClicked"] = data;
        }
    }
}


// Will be called when this module's first listener is added.
- (void) startObserving {
    weHasListeners = YES;
    if (self.pendingEventsDict != nil) {
        for (id key in self.pendingEventsDict) {
            [self sendEventWithName:key body:self.pendingEventsDict[key]];
            [self.pendingEventsDict removeObjectForKey: key];
        }
    }
}

- (void)stopObserving {
    weHasListeners = NO;
}
@end
