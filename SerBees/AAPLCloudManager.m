/*
 Copyright (C) 2014 Apple Inc. All Rights Reserved.
 See LICENSE.txt for this sample’s licensing information

 */
#import "AAPLCloudManager.h"
@import CloudKit;

// **Fields**
// Service Record
NSString * const ServiceRecordType = @"Service";
// Service Field
NSString * const ServiceImageKey = @"Image";
NSString * const ServiceDescriptionKey = @"Description";
NSString * const ServiceTagsKey = @"Tags";

// Questions
NSString * const QuestionField = @"question";
NSString * const LocationField = @"location";
NSString * const AnsweredField = @"answered";
NSString * const CreationDateField = @"creationDate";
NSString * const UniqueIDField = @"uniqueID";
NSString * const StatusField = @"status";
// Answers
NSString * const AnswerField = @"answer";
NSString * const QuestionReferenceField = @"questionReference";
NSString * const AceptedByUserField = @"aceptedByUser";
NSString * const AnswerPointsField = @"answerPoints";

// Assets (Photos or Videos)
NSString * const AssetField = @"asset";
NSString * const AssetThumbField = @"assetThumb";

NSString * const AssetOwnerRefField = @"assetOwnerRef";
// Thumbnails
NSString * const ThumbOwnerRefField = @"thumbOwnerRef";
// Users
NSString * const UserNameField = @"userName";
NSString * const AnswerCountField = @"answerCount";
NSString * const RatingField = @"rating";
// Awards
NSString * const AnswerRefField = @"answerRef";
NSString * const GivenByUserRefField = @"givenByUserRef";

// References
NSString * const ReferenceItemsRecordType = @"ReferenceItems";
NSString * const ReferenceSubItemsRecordType = @"ReferenceSubitems";

// Record Types
static NSString * const QuestionRecordType = @"Questions";
static NSString * const AnswerRecordType = @"Answers";
static NSString * const PhotoRecordType = @"Photos";
static NSString * const ThumbnailRecordType = @"Thumbnails";
static NSString * const AwardRecordType = @"Awards";

// Subscriptions
static NSString * const subscriptionIDkey = @"subscriptionID";

@interface AAPLCloudManager ()

@property (readonly) CKContainer *container;
@property (readonly) CKDatabase *publicDatabase;

@end

@implementation AAPLCloudManager

- (id)init {
    self = [super init];
    if (self) {
        _container = [CKContainer defaultContainer];
        _publicDatabase = [_container publicCloudDatabase];
    }
    
    return self;
}

- (void)requestDiscoverabilityPermission:(void (^)(BOOL discoverable, NSError *errorFound)) completionHandler {
    
    [self.container requestApplicationPermission:CKApplicationPermissionUserDiscoverability
                               completionHandler:^(CKApplicationPermissionStatus applicationPermissionStatus, NSError *error) {
                                   // Log a message if an error occurred
                                   if (error)
                                       NSLog(@"An error occured in %@: %@", NSStringFromSelector(_cmd), error);
                                   
                                   // Return data to completion handler
                                   dispatch_async(dispatch_get_main_queue(), ^{
                                       completionHandler((applicationPermissionStatus == CKApplicationPermissionStatusGranted),error);
                                   });
                               }];
}

- (void)discoverUserInfo:(void (^)(CKDiscoveredUserInfo *user))completionHandler {
    
    [self.container fetchUserRecordIDWithCompletionHandler:^(CKRecordID *recordID, NSError *error) {
        
        if (error) {
            // In your app, handle this error in an awe-inspiring way.
            NSLog(@"An error occured in %@: %@", NSStringFromSelector(_cmd), error);
            abort();
        } else {
            [self.container discoverUserInfoWithUserRecordID:recordID
                                           completionHandler:^(CKDiscoveredUserInfo *user, NSError *error) {
                                               if (error) {
                                                   // In your app, handle this error deftly.
                                                   NSLog(@"An error occured in %@: %@", NSStringFromSelector(_cmd), error);
                                                   abort();
                                               } else {
                                                   dispatch_async(dispatch_get_main_queue(), ^(void){
                                                       completionHandler(user);
                                                   });
                                               }
                                           }];
        }
    }];
}

- (void)uploadAssetWithURL:(NSURL *)assetURL completionHandler:(void (^)(CKRecord *record))completionHandler {
    
    CKRecord *assetRecord = [[CKRecord alloc] initWithRecordType:PhotoRecordType];
    CKAsset *photo = [[CKAsset alloc] initWithFileURL:assetURL];
    assetRecord[AssetField] = photo;
    
    [self.publicDatabase saveRecord:assetRecord completionHandler:^(CKRecord *record, NSError *error) {
        if (error) {
            // In your app, masterfully handle this error.
            NSLog(@"An error occured in %@: %@", NSStringFromSelector(_cmd), error);
            abort();
        } else {
            dispatch_async(dispatch_get_main_queue(), ^(void){
                completionHandler(record);
            });
        }
    }];
}

- (void)addRecordWithQuestion:(NSString *)question andLocation:(CLLocation *)location andAssetURL:(NSURL *)assetURL andAssetThumbURL:(NSURL *)assetThumbURL andID:(NSString *)uniqueIDString completionHandler:(void (^)(CKRecord *record))completionHandler {
    
    // Prepare Record for saving
    CKRecord *record = [[CKRecord alloc] initWithRecordType:QuestionRecordType];
    record[QuestionField] = question;
    record[LocationField] = location;
    record[AnsweredField] = [[NSNumber alloc]initWithInt:0];
    
    if(assetURL){
        CKAsset *photo = [[CKAsset alloc] initWithFileURL:assetURL];
        record[AssetField] = photo;
    }
    
    if(assetThumbURL){
        CKAsset *photoThumb = [[CKAsset alloc] initWithFileURL:assetThumbURL];
        record[AssetThumbField] = photoThumb;
    }
    
    record[UniqueIDField] = uniqueIDString;
    record[StatusField] = [[NSNumber alloc]initWithInt:0];
    
    [self.publicDatabase saveRecord:record completionHandler:^(CKRecord *record, NSError *error) {
        if (error) {
            // In your app, handle this error like a pro.
            NSLog(@"An error occured in %@: %@", NSStringFromSelector(_cmd), error);
            abort();
        } else {
            dispatch_async(dispatch_get_main_queue(), ^(void){
                completionHandler(record);
            });
        }
    }];
}

- (void)addRecordWithAnswer:(NSString *)answer toQuestionID:(CKRecordID *)questionRecordID andLocation:(CLLocation *)location andAssetURL:(NSURL *)assetURL andAssetThumbURL:(NSURL *)assetThumbURL andID:(NSString *)uniqueIDString completionHandler:(void (^)(CKRecord *record))completionHandler {
    
    // Prepare Record for saving
    CKRecord *record = [[CKRecord alloc] initWithRecordType:AnswerRecordType];
    record[AnswerField] = answer;
    record[LocationField] = location;
    record[AnsweredField] = [[NSNumber alloc]initWithInt:0];
    
    if(assetURL){
        CKAsset *photo = [[CKAsset alloc] initWithFileURL:assetURL];
        record[AssetField] = photo;
    }
    
    if(assetThumbURL){
        CKAsset *photoThumb = [[CKAsset alloc] initWithFileURL:assetThumbURL];
        record[AssetThumbField] = photoThumb;
    }
    
    record[UniqueIDField] = uniqueIDString;
    record[StatusField] = [[NSNumber alloc]initWithInt:0];
    
    record[QuestionReferenceField] = [[CKReference alloc] initWithRecordID:questionRecordID action:CKReferenceActionDeleteSelf];

    
    // Save Record
    [self.publicDatabase saveRecord:record completionHandler:^(CKRecord *record, NSError *error) {
        if (error) {
            // In your app, handle this error like a pro.
            NSLog(@"An error occured in %@: %@", NSStringFromSelector(_cmd), error);
            abort();
        } else {
            dispatch_async(dispatch_get_main_queue(), ^(void){
                completionHandler(record);
            });
        }
    }];
}

- (void)fetchRecordWithID:(NSString *)recordID completionHandler:(void (^)(CKRecord *record))completionHandler {
    
    CKRecordID *current = [[CKRecordID alloc] initWithRecordName:recordID];
    [self.publicDatabase fetchRecordWithID:current completionHandler:^(CKRecord *record, NSError *error) {
        
        if (error) {
            // In your app, handle this error gracefully.
            NSLog(@"An error occured in %@: %@", NSStringFromSelector(_cmd), error);
            abort();
        } else {
            dispatch_async(dispatch_get_main_queue(), ^(void){
                completionHandler(record);
            });
        }
    }];
}

- (void)queryForRecordsNearLocation:(CLLocation *)location completionHandler:(void (^)(NSMutableArray *records, NSError *errorFound))completionHandler {
    
    CGFloat radiusInKilometers = 1000000;
    NSPredicate *predicate = [NSPredicate predicateWithFormat:@"distanceToLocation:fromLocation:(location, %@) < %f", location, radiusInKilometers];
    
    NSSortDescriptor *dateDescriptor = [[NSSortDescriptor alloc] initWithKey:@"creationDate" ascending:NO];
    NSSortDescriptor *locationDescriptor = [[CKLocationSortDescriptor alloc]initWithKey:LocationField relativeLocation:location];
    NSArray *sortDescriptors = @[dateDescriptor,locationDescriptor];
    
    CKQuery *query = [[CKQuery alloc] initWithRecordType:QuestionRecordType predicate:predicate];
    query.sortDescriptors = sortDescriptors;

    CKQueryOperation *queryOperation = [[CKQueryOperation alloc] initWithQuery:query];
    
    // Just request the name field for all records since we have location range
    queryOperation.desiredKeys = @[QuestionField,LocationField,AssetThumbField,AnsweredField];
    
    NSMutableArray *results = [[NSMutableArray alloc] init];
    
    [queryOperation setRecordFetchedBlock:^(CKRecord *record) {
        [results addObject:record];
    }];
    
    queryOperation.queryCompletionBlock = ^(CKQueryCursor *cursor, NSError *error) {
        // Error occurred Log a message
        if (error){
            NSLog(@"An error occured in %@: %@", NSStringFromSelector(_cmd), error);
        }
        dispatch_async(dispatch_get_main_queue(), ^(void){
            completionHandler(results, error);
        });
    };
    
    [self.publicDatabase addOperation:queryOperation];
}

- (void)queryRecordsforUserWithRecordID:(CKRecordID *)recordID completionHandler:(void (^)(NSMutableArray *records, NSError *errorFound))completionHandler {
    
    NSPredicate *predicate = [NSPredicate predicateWithFormat:@"creatorUserRecordID = %@", recordID];
    
    NSSortDescriptor *dateDescriptor = [[NSSortDescriptor alloc] initWithKey:@"creationDate" ascending:NO];
    NSArray *sortDescriptors = @[dateDescriptor];
    
    CKQuery *query = [[CKQuery alloc] initWithRecordType:QuestionRecordType predicate:predicate];
    query.sortDescriptors = sortDescriptors;
    
    CKQueryOperation *queryOperation = [[CKQueryOperation alloc] initWithQuery:query];
    
    // Just request the name field for all records since we have location range
    queryOperation.desiredKeys = @[QuestionField,AssetThumbField,AnsweredField];
    
    NSMutableArray *results = [[NSMutableArray alloc] init];
    
    [queryOperation setRecordFetchedBlock:^(CKRecord *record) {
        [results addObject:record];
    }];
    
    queryOperation.queryCompletionBlock = ^(CKQueryCursor *cursor, NSError *error) {
        // Error occurred Log a message
        if (error){
            NSLog(@"An error occured in %@: %@", NSStringFromSelector(_cmd), error);
        }
        dispatch_async(dispatch_get_main_queue(), ^(void){
            completionHandler(results, error);
        });
    };
    
    [self.publicDatabase addOperation:queryOperation];
}

- (void)saveRecord:(CKRecord *)record {
    [self.publicDatabase saveRecord:record completionHandler:^(CKRecord *record, NSError *error) {
        if (error) {
            // In your app, handle this error awesomely.
            NSLog(@"An error occured in %@: %@", NSStringFromSelector(_cmd), error);
            abort();
        } else {
            NSLog(@"Successfully saved record");
        }
    }];
}

- (void)deleteRecord:(CKRecord *)record {
    [self.publicDatabase deleteRecordWithID:record.recordID completionHandler:^(CKRecordID *recordID, NSError *error) {
        if (error) {
            // In your app, handle this error. Please.
            NSLog(@"An error occured in %@: %@", NSStringFromSelector(_cmd), error);
            abort();
        } else {
            NSLog(@"Successfully deleted record");
        }
    }];
}

- (void)fetchRecordsWithType:(NSString *)recordType completionHandler:(void (^)(NSArray *records))completionHandler {
    
    NSPredicate *truePredicate = [NSPredicate predicateWithValue:YES];
    CKQuery *query = [[CKQuery alloc] initWithRecordType:recordType predicate:truePredicate];
    
    CKQueryOperation *queryOperation = [[CKQueryOperation alloc] initWithQuery:query];
    // Just request the name field for all records
    queryOperation.desiredKeys = @[UserNameField];
    
    NSMutableArray *results = [[NSMutableArray alloc] init];
    
    queryOperation.recordFetchedBlock = ^(CKRecord *record) {
        [results addObject:record];
    };
    
    queryOperation.queryCompletionBlock = ^(CKQueryCursor *cursor, NSError *error) {
        if (error) {
            // Error Code 11 - Unknown Item: did not find required record type
            if ([error code] == 11) {
                
                // Since schema is missing, create the schema with demo records and return results
                
                [self createReferenceItemSchemaWithCompletionHandler:^(NSArray *records) {
                    completionHandler(records);
                }];
            }
            else {
                // In your app, this error needs love and care.
                NSLog(@"An error occured in %@: %@", NSStringFromSelector(_cmd), error);
                //abort();
            }
        } else {
            dispatch_async(dispatch_get_main_queue(), ^(void){
                completionHandler(results);
            });
        }
    };
    
    [self.publicDatabase addOperation:queryOperation];
}

- (void)queryForRecordsWithReferenceRecordID:(CKRecordID *)referenceRecordID completionHandler:(void (^)(NSMutableArray *records, NSError *errorFound))completionHandler {
    
    CKReference *parent = [[CKReference alloc] initWithRecordID:referenceRecordID action:CKReferenceActionNone];
    
    NSPredicate *predicate = [NSPredicate predicateWithFormat:@"questionReference == %@", parent];
    CKQuery *query = [[CKQuery alloc] initWithRecordType:AnswerRecordType predicate:predicate];
    
    CKQueryOperation *queryOperation = [[CKQueryOperation alloc] initWithQuery:query];
    // Just request the name field for all records
    queryOperation.desiredKeys = @[AnswerField,LocationField,AssetThumbField,AnsweredField];
    
    NSMutableArray *results = [[NSMutableArray alloc] init];
    
    queryOperation.recordFetchedBlock = ^(CKRecord *record) {
        [results addObject:record];
    };
    
    queryOperation.queryCompletionBlock = ^(CKQueryCursor *cursor, NSError *error) {
        if (error) {
            // In your app, you should do the Right Thing
            NSLog(@"An error occured in %@: %@", NSStringFromSelector(_cmd), error);
        }
        dispatch_async(dispatch_get_main_queue(), ^(void){
            completionHandler(results, error);
        });
    };
    
    [self.publicDatabase addOperation:queryOperation];
}

- (void)subscribe {
    
    if (self.subscribed == NO) {
        
        NSPredicate *truePredicate = [NSPredicate predicateWithValue:YES];
        CKSubscription *itemSubscription = [[CKSubscription alloc] initWithRecordType:QuestionRecordType
                                                                            predicate:truePredicate
                                                                              options:CKSubscriptionOptionsFiresOnRecordCreation];
        
        
        CKNotificationInfo *notification = [[CKNotificationInfo alloc] init];
        notification.alertBody = @"New Item Added!";
        itemSubscription.notificationInfo = notification;
        
        [self.publicDatabase saveSubscription:itemSubscription completionHandler:^(CKSubscription *subscription, NSError *error) {
            if (error) {
                // In your app, handle this error appropriately.
                NSLog(@"An error occured in %@: %@", NSStringFromSelector(_cmd), error);
                abort();
            } else {
                NSLog(@"Subscribed to Item");
                NSUserDefaults *defaults = [NSUserDefaults standardUserDefaults];
                [defaults setBool:YES forKey:@"subscribed"];
                [defaults setObject:subscription.subscriptionID forKey:subscriptionIDkey];
            }
        }];
    }
}

- (void)unsubscribe {
    if (self.subscribed == YES) {
        
        NSString *subscriptionID = [[NSUserDefaults standardUserDefaults] objectForKey:subscriptionIDkey];
        
        CKModifySubscriptionsOperation *modifyOperation = [[CKModifySubscriptionsOperation alloc] init];
        modifyOperation.subscriptionIDsToDelete = @[subscriptionID];
        
        modifyOperation.modifySubscriptionsCompletionBlock = ^(NSArray *savedSubscriptions, NSArray *deletedSubscriptionIDs, NSError *error) {
            if (error) {
                // In your app, handle this error beautifully.
                NSLog(@"An error occured in %@: %@", NSStringFromSelector(_cmd), error);
                abort();
            } else {
                NSLog(@"Unsubscribed to Item");
                [[NSUserDefaults standardUserDefaults] removeObjectForKey:subscriptionIDkey];
            }
        };
        
        [self.publicDatabase addOperation:modifyOperation];
    }
}

- (BOOL)isSubscribed {
    return [[NSUserDefaults standardUserDefaults] objectForKey:subscriptionIDkey] != nil;
}

- (void)createReferenceItemSchemaWithCompletionHandler:(void (^)(NSArray *records))completionHandler {
    
    // Create initial entries for Reference Items if record type is not created
    
    CKRecord *firstItem = [[CKRecord alloc] initWithRecordType:ReferenceItemsRecordType];
    firstItem[UserNameField] = @"personal list";
    [self saveRecord:firstItem];
    
    CKRecord *secondItem = [[CKRecord alloc] initWithRecordType:ReferenceItemsRecordType];
    secondItem[UserNameField] = @"work list";
    [self saveRecord:secondItem];
    
    CKRecord *firstSubitem = [[CKRecord alloc] initWithRecordType:ReferenceSubItemsRecordType];
    CKRecordID *firstParentRecordID = [firstItem recordID];
    firstSubitem[UserNameField] = @"buy milk";
    firstSubitem[AnswerRefField] = [[CKReference alloc] initWithRecordID:firstParentRecordID action:CKReferenceActionDeleteSelf];
    [self saveRecord:firstSubitem];
    
    CKRecord *secondSubitem = [[CKRecord alloc] initWithRecordType:ReferenceSubItemsRecordType];
    CKRecordID *secondParentRecordID = [secondItem recordID];
    secondSubitem[UserNameField] = @"fix bugs";
    secondSubitem[AnswerRefField] = [[CKReference alloc] initWithRecordID:secondParentRecordID action:CKReferenceActionDeleteSelf];
    [self saveRecord:secondSubitem];
    
    NSArray *results = [[NSArray alloc] initWithObjects:firstItem, secondItem, nil];
    completionHandler(results);
}

@end
