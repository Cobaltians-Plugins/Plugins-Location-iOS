#import <Foundation/Foundation.h>
#import <CoreLocation/CoreLocation.h>

#import <Cobalt/CobaltAbstractPlugin.h>

@interface LocationListener: NSObject <CLLocationManagerDelegate>

@property (nonatomic) id delegate;

@property (nonatomic) CLLocationManager * locationManager;
@property (nonatomic, weak, getter=getViewController) CobaltViewController * viewController;

@property (nonatomic) int accuracyFilter;
@property (nonatomic) int distanceFilter;
@property (nonatomic) int ageFilter;
@property (nonatomic) long interval;
@property (nonatomic) int timeout;
@property (nonatomic) bool sendAllUpdates;

@property (nonatomic) NSTimer * timer;

@property (nonatomic) bool listening;
@property (nonatomic) long long lastSentLocationTimestamp;

- (instancetype) initWithController: (CobaltViewController *) viewController
                        andDelegate: (id) delegate;

- (void) startUpdatesWithAccuracyFilter: (int) accuracy
                           andAgeFilter: (int) age
                            andInterval: (long) interval
                                andMode: (NSString *) mode
                             andTimeout: (int) timeout;
- (void) stopUpdates;

- (void) onTimeout: (NSTimer *) timer;

@end

@protocol LocationUpdatesStoppedListener

- (void) onLocationListenerStopped: (LocationListener *) listener;

@end
