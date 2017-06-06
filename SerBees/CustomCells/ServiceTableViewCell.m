//
//  ServiceTableViewCell.m
//  SerBees


#import "ServiceTableViewCell.h"
#import "ServicePost.h"

@interface ServiceTableViewCell ()

@property (strong, nonatomic) NSString *fontName;
@property (strong, nonatomic) IBOutlet UILabel *serviceName;
@property (weak, nonatomic) IBOutlet UILabel *emailLB;
@property (weak, nonatomic) IBOutlet UILabel *phoneLB;
@property (weak, nonatomic) IBOutlet UILabel *descriptionLB;

@end

@implementation ServiceTableViewCell

- (void)layoutSubviews
{
    [super layoutSubviews];
}

- (void) displayInfoForPost:(ServicePost *)post
{
    // Sets how the cell appears based on the AAPLPost passed in
    [self.assetSpinner startAnimating];
    
    // Round Corners for picture
    self.assetImageView.layer.cornerRadius = 10;
    self.assetImageView.layer.masksToBounds = YES;
    self.assetImageView.image = [post.imageRecord fullImage];
    self.serviceName.text = post.postRecord[ServiceNameKey];
    self.descriptionLB.text = post.postRecord[ServiceDescriptionKey];
    self.emailLB.text = post.postRecord[ServiceEmailKey];
    self.phoneLB.text = post.postRecord[ServicePhoneKey];
}

@end
