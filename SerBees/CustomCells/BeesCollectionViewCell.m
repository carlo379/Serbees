//  BeesCollectionViewCell.m
//  SerBees

#import "BeesCollectionViewCell.h"
#import "ServicePost.h"

@interface BeesCollectionViewCell ()

@property (weak, nonatomic) IBOutlet UILabel *nameLB;
@property (weak, nonatomic) IBOutlet UIImageView *assetView;
@property (weak, nonatomic) IBOutlet UIActivityIndicatorView *spinner;

@end

@implementation BeesCollectionViewCell

- (void) displayInfoForPost:(ServicePost *)post
{
    // Sets how the cell appears based on the AAPLPost passed in
    [self.spinner startAnimating];
    
    // Round Corners for picture
    self.assetView.layer.cornerRadius = 10;
    self.assetView.layer.masksToBounds = YES;
    self.assetView.image = [post.imageRecord fullImage];
    
    self.nameLB.text = post.postRecord[ServiceNameKey];
}

@end
