//  BeesCollectionViewCell.h
//  SerBees


#import <UIKit/UIKit.h>
@class ServicePost;

@interface BeesCollectionViewCell : UICollectionViewCell

- (void) displayInfoForPost:(ServicePost *)post;

@end
