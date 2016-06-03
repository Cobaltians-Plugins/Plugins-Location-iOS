#import <CoreLocation/CoreLocation.h>

#import <Cobalt/CobaltAbstractPlugin.h>

#import "LocationListener.h"

@interface CobaltLocationPlugin : CobaltAbstractPlugin <CLLocationManagerDelegate, LocationUpdatesStoppedListener>

@property (nonatomic) NSMapTable * listeningControllers;

- (void) onLocationListenerStopped: (LocationListener *) listener;

@end
