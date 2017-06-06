//  ServiceTableViewCell.h
//  SerBees


@import UIKit;
@class ServicePost;

@interface ServiceTableViewCell : UITableViewCell

@property (weak, nonatomic) IBOutlet UIButton *detailsBT;
@property (strong, nonatomic) IBOutlet UIActivityIndicatorView *assetSpinner;
@property (strong, nonatomic) IBOutlet UIImageView *assetImageView;

- (void) displayInfoForPost:(ServicePost *)post;

@end
