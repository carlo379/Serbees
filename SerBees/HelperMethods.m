//  HelperMethods.m
//  SerBees

#import "HelperMethods.h"

@implementation HelperMethods

- (id)init
{
    return [self initWithMediaName:nil];
}

- (id)initWithMediaName:(NSString *)mediaName
{
    self = [super init];
    if (self){
        self.mediaPath = [self pathForMediaName:mediaName];
        self.mediaURL = [NSURL fileURLWithPath:self.mediaPath];
    }
    
    return self;
}

- (NSString *)pathForMediaName:(NSString *)mediaName
{
    NSArray *paths = NSSearchPathForDirectoriesInDomains(NSDocumentDirectory, NSUserDomainMask, YES);
    NSString *documentsDirectory = [paths objectAtIndex:0];
    NSString *mediaPath = [documentsDirectory stringByAppendingPathComponent:mediaName];
    
    if (mediaPath) {
        return mediaPath;
    } else {
        return nil;
    }
}

@end
