//  ServicesViewController.h
//  SerBees

@import UIKit;
#import "AAPLCloudManager.h"
@class AAPLPost;


@interface ServicesViewController : UIViewController<UITabBarControllerDelegate>

@property (weak, nonatomic) IBOutlet UITableView *tableView;
@property (weak, nonatomic) IBOutlet UIButton *leftSideMenu;
@property (weak, nonatomic) IBOutlet UIButton *rightSideMenu;
@property (strong, nonatomic) UIRefreshControl *refreshControl;
@property (nonatomic,strong) CKDiscoveredUserInfo *mainUser;

- (void) loadNewPostsWithRecordID:(CKRecordID *)recordID;

@end

