#include "AppDelegate.h"
#include "GeneratedPluginRegistrant.h"
@import GoogleMaps;

@implementation AppDelegate


[GMSServices provideAPIKey:@"AIzaSyBqUzisHSa-tab1eKmhJwSpKod7XQkJCW0"];
[GMSPlacesClient provideAPIKey:@"AIzaSyBqUzisHSa-tab1eKmhJwSpKod7XQkJCW0"];

- (BOOL)application:(UIApplication *)application
    didFinishLaunchingWithOptions:(NSDictionary *)launchOptions {
  [GeneratedPluginRegistrant registerWithRegistry:self];
  // Override point for customization after application launch.
  return [super application:application didFinishLaunchingWithOptions:launchOptions];
}

@end
