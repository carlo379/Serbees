//  HelperMethods.h
//  SerBees

#import <Foundation/Foundation.h>

@interface HelperMethods : NSObject

@property (strong, nonatomic) NSString *mediaPath;
@property (strong, nonatomic) NSURL *mediaURL;
//Initializers
- (id)init;
- (id)initWithMediaName:(NSString *)mediaName;   //Designated initializer

//Instance Methods
- (NSString *)pathForMediaName:(NSString *)mediaName;

@end
