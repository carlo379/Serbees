//  AddServiceViewController.h
//  SerBees

#import <UIKit/UIKit.h>
#import "ServicePost.h"
@class AddServiceViewController;
#import "MBProgressHUD.h"

@protocol AddServiceViewControllerDelegate <NSObject>
- (void)dismissRequestedByChildViewController;

@optional
- (void) AddServiceViewController:(AddServiceViewController *)controller postedRecord:(ServicePost *)record;

@end

@interface AddServiceViewController : UIViewController <UIScrollViewDelegate,MBProgressHUDDelegate>{
    MBProgressHUD *ProgessHUD;
    MBProgressHUD *CompletedHUD;
}

// Delegate Property
@property (nonatomic, weak) id <AddServiceViewControllerDelegate> delegate;

@property (nonatomic, strong) ServicePost *currentService;
@end
