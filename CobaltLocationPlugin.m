#import "CobaltLocationPlugin.h"
#import <Cobalt/PubSub.h>

@implementation CobaltLocationPlugin

- (id) init
{
    if (self = [super init])
    {
        _listeningControllers = [NSMapTable weakToStrongObjectsMapTable];
    }

    return self;
}

- (void)onMessageFromWebView:(WebViewType)webView
          inCobaltController:(nonnull CobaltViewController *)viewController
                  withAction:(nonnull NSString *)action
                        data:(nullable NSDictionary *)data
          andCallbackChannel:(nullable NSString *)callbackChannel{
    
    if ([action isEqualToString: @"startLocation"]) {
        [self startLocationUpdatesForController: viewController
                                    withOptions: data];
    }
    else if ([action isEqualToString: @"stopLocation"]) {
        [self stopLocationUpdatesForController: viewController];
    }
    else {
        NSLog(@"CobaltLocationPlugin onMessageWithCobaltController:andData: unknown action %@", action);
    }
}

- (void) startLocationUpdatesForController: (CobaltViewController *) viewController
                               withOptions: (NSDictionary *) options
{
    LocationListener * listener = [_listeningControllers objectForKey: viewController];

    if (listener == nil) {
        NSNumber * accuracyOption = [options objectForKey: @"accuracy"];
        int accuracy = 100;
        if (accuracyOption != nil) {
            accuracy = [accuracyOption intValue];
        }

        NSNumber * ageOption = [options objectForKey: @"age"];
        int age = 12000;
        if (ageOption != nil) {
            age = [ageOption intValue];
        }

        NSNumber * intervalOption = [options objectForKey: @"interval"];
        long interval = 500;
        if (intervalOption != nil) {
            interval = [intervalOption longLongValue];
        }

        NSString * mode = [options objectForKey: @"mode"];
        if (mode == nil) {
            mode = @"all";
        }

        NSNumber * timeoutOption = [options objectForKey: @"timeout"];
        int timeout = 0;
        if (timeoutOption != nil) {
            timeout = [timeoutOption intValue];
        }

        LocationListener * newListener = [[LocationListener alloc] initWithController: viewController
                                                                          andDelegate: self];

        [newListener startUpdatesWithAccuracyFilter: accuracy
                                       andAgeFilter: age
                                        andInterval: interval
                                            andMode: mode
                                         andTimeout: timeout];

        [_listeningControllers setObject: newListener
                                  forKey: viewController];
    }
    else {
        [self stopLocationUpdatesForController: viewController];
        [self startLocationUpdatesForController: viewController
                                    withOptions: options];
    }
}

- (void) stopLocationUpdatesForController: (CobaltViewController *) viewController
{
    LocationListener * listener = [_listeningControllers objectForKey: viewController];

    if (listener != nil) {
        [listener stopUpdates];
        [_listeningControllers removeObjectForKey: viewController];
    }
}

- (void) onLocationListenerStopped: (LocationListener *) listener
{
    [_listeningControllers removeObjectForKey: [listener getViewController]];
}

@end
