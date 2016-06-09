#import "LocationListener.h"

// Check iOS version
#define SYSTEM_VERSION_GREATER_THAN_OR_EQUAL_TO(v) ([[[UIDevice currentDevice] systemVersion] compare: v options: NSNumericSearch] != NSOrderedAscending)

@implementation LocationListener

- (instancetype) initWithController: (CobaltViewController *) viewController
                        andDelegate: (id) delegate
{
    if (self = [super init])
    {
        NSAssert([delegate respondsToSelector: @selector(onLocationListenerStopped:)], @"LocationListener initWithController:andDelegate: delegate does not responds to selector onLocationListenerStopped:");

        _delegate = delegate;

        _viewController = viewController;

        _listening = NO;
    }

    return self;
}

- (void) startUpdatesWithAccuracyFilter: (int) accuracy
                           andAgeFilter: (int) age
                            andInterval: (long) interval
                                andMode: (NSString *) mode
                             andTimeout: (int) timeout
{
    _accuracyFilter = accuracy;
    _ageFilter = age;
    _interval = interval;
    _timeout = timeout;
    _sendAllUpdates = [mode isEqualToString: @"all"];

    // Try to pick the most appropriate mode, with a 50% security margin
         if (accuracy >= 4500) _locationManager.desiredAccuracy = kCLLocationAccuracyThreeKilometers;
    else if (accuracy >= 1500) _locationManager.desiredAccuracy = kCLLocationAccuracyKilometer;
    else if (accuracy >= 150) _locationManager.desiredAccuracy = kCLLocationAccuracyHundredMeters;
    else if (accuracy >= 15) _locationManager.desiredAccuracy = kCLLocationAccuracyNearestTenMeters;
    else if (accuracy >= 0) _locationManager.desiredAccuracy = kCLLocationAccuracyBest;

    _locationManager = [[CLLocationManager alloc] init];
    _locationManager.delegate = self;
}

// Automatically gets called (when the location manager is created)
- (void) locationManager: (CLLocationManager *) locationManager
         didChangeAuthorizationStatus: (CLAuthorizationStatus) authorizationStatus
{
    if (authorizationStatus == kCLAuthorizationStatusAuthorized
     || authorizationStatus == kCLAuthorizationStatusAuthorizedWhenInUse
     || authorizationStatus == kCLAuthorizationStatusAuthorizedAlways) {
        [self startUpdates];
    }
    else if (SYSTEM_VERSION_GREATER_THAN_OR_EQUAL_TO(@"8.0") && authorizationStatus == kCLAuthorizationStatusNotDetermined) {
        [_locationManager requestWhenInUseAuthorization];
    }
    else if (authorizationStatus == kCLAuthorizationStatusDenied
          || authorizationStatus == kCLAuthorizationStatusRestricted
          || authorizationStatus == kCLAuthorizationStatusNotDetermined) {
        [self sendStatusToWeb: _listening ? @"disabled" : @"refused"
                 withLocation: nil];

        [self stopUpdates];
    }
}

- (void) startUpdates
{
    if (!_listening) {
        // [self sendStatusToWeb: @"started" withLocation: nil];

        [_locationManager startUpdatingLocation];

        if (_timeout > 0) {
            _timer = [NSTimer scheduledTimerWithTimeInterval: _timeout / 1000.0
                                                      target: self
                                                    selector: @selector(onTimeout:)
                                                    userInfo: nil
                                                     repeats: NO];
        }

        // Send the last known location
        [self sendLocationToWeb: _locationManager.location];

        _listening = YES;
    }
}

- (void) stopUpdates
{
    if (_listening) {
        [self invalidateTimer];

        // [self sendStatusToWeb: @"stopped" withLocation: nil];

        [_locationManager stopUpdatingLocation];
        _locationManager.delegate = nil;

        _listening = NO;
    }

    [_delegate onLocationListenerStopped: self];
}

- (void) onTimeout: (NSTimer *) timer
{
    [self sendStatusToWeb: @"timeout"
             withLocation: _locationManager.location];
    [self stopUpdates];
}

- (void) invalidateTimer
{
    if (_timer != nil) {
        [_timer invalidate];
        _timer = nil;
    }
}

- (void) sendLocationToWeb: (CLLocation *) location
{
    if (_listening && location != nil) {
        bool sendLocation = NO;
        bool stopUpdates = NO;

        long long currentTime = CFAbsoluteTimeGetCurrent();

        if ((([location.timestamp timeIntervalSinceNow] * 1000) <= _ageFilter) // If location is recent enough
              && (location.horizontalAccuracy <= _accuracyFilter)) { // And accurate enough
            sendLocation = YES;
            stopUpdates = YES;
        }
        else if (_sendAllUpdates && (currentTime >= (_lastSentLocationTimestamp + _interval))) {
            sendLocation = YES;

            _lastSentLocationTimestamp = currentTime;
        }

        if (sendLocation) {
            NSDictionary * message = @{
                kJSType: kJSTypePlugin,
                kJSPluginName: @"location",
                kJSAction: @"onLocationChanged",
                kJSData: [self dictionaryFromLocation: location]
            };

    	    [_viewController sendMessage: message];
        }

        if (stopUpdates) {
            [self stopUpdates];
        }
    }
}

- (void) sendStatusToWeb: (NSString *) status
            withLocation: (CLLocation *) location
{
    NSDictionary * data;

    if (location != nil) {
        data = @{
            @"status": status,
            @"location": [self dictionaryFromLocation: location]
        };
    }
    else {
        data = @{
            @"status": status
        };
    }

    NSDictionary * message = @{
        kJSType: kJSTypePlugin,
        kJSPluginName: @"location",
        kJSAction: @"onStatusChanged",
        kJSData: data
    };

    [_viewController sendMessage: message];
}

// iOS < 6
- (void) locationManager: (CLLocationManager *) manager
     didUpdateToLocation: (CLLocation *) location
            fromLocation: (CLLocation *) oldLocation
{
    [self sendLocationToWeb: location];
}

// iOS >= 6
- (void) locationManager: (CLLocationManager *) manager
      didUpdateLocations: (NSArray *) locations
{
    [self sendLocationToWeb: [locations lastObject]];
}

-(void) locationManager: (CLLocationManager *) manager
       didFailWithError: (NSError *) error
{
    NSLog(@"LocationListener locationManager:didFailWithError: %@", error);
}

- (NSDictionary *) dictionaryFromLocation: (CLLocation *) location
{
    return @{
        @"longitude": [NSNumber numberWithDouble: location.coordinate.longitude],
        @"latitude": [NSNumber numberWithDouble: location.coordinate.latitude],
        @"accuracy": [NSNumber numberWithDouble: location.horizontalAccuracy],
        @"timestamp": [NSNumber numberWithUnsignedLongLong: ((unsigned long long int) ([location.timestamp timeIntervalSince1970] * 1000))]
    };
}

- (void) dealloc
{
    [self stopUpdates];
}

@end
