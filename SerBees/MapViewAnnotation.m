//  MapViewAnnotation.m
//  SerBees

#import "MapViewAnnotation.h"
#import "ServicePost.h"

@implementation MapViewAnnotation

-(id) initWithRecord:(ServicePost *)servicePost
{
    self = [super init];
    
    // Required Properties by MKAnnotation Protocol
    _title = servicePost.postRecord[ServiceNameKey];
    
    CLLocation *questionLocation = servicePost.postRecord[ServiceLocationKey];
    CLLocationCoordinate2D qLocation = CLLocationCoordinate2DMake(questionLocation.coordinate.latitude, questionLocation.coordinate.longitude);
    _coordinate = qLocation;
    
    NSDateFormatter *format = [[NSDateFormatter alloc] init];
    format.dateFormat = @"MM-dd-yyyy";
    
    NSString *tags = @"";
    self.tagsArray = [[NSArray alloc]initWithArray:servicePost.postRecord[ServiceTagsKey]];
    for (NSString *tag in self.tagsArray) {
        if([tags isEqualToString:@""]){
            tags = tag;
        }
        else {
            tags = [tags stringByAppendingString:[@", " stringByAppendingString:tag]];
        }
    }
    
    _subtitle = [NSString stringWithFormat:@"Tags: %@", tags];
    _image = [servicePost.imageRecord thumbnail];
    
    _recordID = servicePost.postRecord[ServiceRecordIDKey];
    
    return self;
}

@end
