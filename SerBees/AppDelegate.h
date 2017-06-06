//  AppDelegate.h
//  SerBees

@import UIKit;
#import "BeesViewController.h"

@class ServicesViewController;

@interface AppDelegate : UIResponder <UIApplicationDelegate>

@property (strong, nonatomic) UIWindow *window;
@property (strong, nonatomic) IBOutlet ServicesViewController *tableController;
@property (strong, nonatomic) IBOutlet BeesViewController *beesViewController;

@end

