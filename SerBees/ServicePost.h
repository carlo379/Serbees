//  ServicePost.h
//  SerBees

@import CloudKit;
#import "ServiceImage.h"

// Service Record
static NSString * const ServiceRecordType = @"Service";
// Service Field
static NSString * const ServiceImageKey = @"Image";
static NSString * const ServiceDescriptionKey = @"Description";
static NSString * const ServiceDescriptionTagsKey = @"DescriptionTags";
static NSString * const ServiceTagsKey = @"Tags";
static NSString * const ServiceNameKey = @"Name";
static NSString * const ServiceNameTagsKey = @"NameTags";
static NSString * const ServiceContactKey = @"Contact";
static NSString * const ServicePhoneKey = @"Phone";
static NSString * const ServiceEmailKey = @"Email";
static NSString * const ServiceAddressTagsKey = @"AddressTags";
static NSString * const ServiceAddress1Key = @"Address1";
static NSString * const ServiceAddress2Key = @"Address2";
static NSString * const ServiceLocationKey = @"Location";
static NSString * const ServiceCreationDateKey = @"creationDate";
static NSString * const ServiceRecordIDKey = @"recordID";
static NSString * const ServiceWebsiteKey = @"Website";

@interface ServicePost : NSObject

- (instancetype) initWithRecord:(CKRecord *)postRecord;
- (void) loadImageWithKeys:(NSArray *)keys completion:(void(^)())updateBlock;

@property (strong, atomic) CKRecord *postRecord;
@property (strong, atomic) ServiceImage *imageRecord;

@end
