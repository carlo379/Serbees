//  ServiceImage.h
//  SerBees

@import UIKit;
@import CloudKit;

static NSString * const ServiceImageRecordType = @"Image";
static NSString * const ServiceImageThumbnailKey = @"Thumb";
static NSString * const ServiceImageFullsizeKey = @"Full";

@interface ServiceImage : NSObject

- (instancetype) initWithImage:(UIImage *)image andButtonSize:(CGFloat)buttonSize;
- (instancetype) initWithRecord:(CKRecord *)record andButtonAssetURL:(NSURL *)assetThumbURL;
- (instancetype) initWithRecord:(CKRecord *)record;

@property (readonly, getter=isOnServer) BOOL onServer;
@property (strong, readonly, atomic) CKRecord *record;
@property (strong, readonly, atomic) UIImage *fullImage;
@property (strong, readonly, atomic) UIImage *thumbnail;
@property (strong, readonly, atomic) UIImage *assetThumb;

@end
