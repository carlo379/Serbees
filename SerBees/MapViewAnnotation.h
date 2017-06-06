//  MapViewAnnotation.h
//  SerBees

@import Foundation;
@import MapKit;
@import CloudKit;
#import "ServicePost.h"

@interface MapViewAnnotation : NSObject<MKAnnotation>

@property (nonatomic, copy) NSString *title;
@property (nonatomic, copy) NSString *subtitle;
@property (nonatomic, copy) NSString *tags;
@property (nonatomic, copy) UIImage *image;
@property (nonatomic, copy) CKRecordID *recordID;
@property (nonatomic, readonly) CLLocationCoordinate2D coordinate;
@property (strong, atomic) NSArray *tagsArray;

-(id) initWithRecord:(ServicePost *)servicePost;

@end
