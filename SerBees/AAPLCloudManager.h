/*
    Copyright (C) 2014 Apple Inc. All Rights Reserved.
    See LICENSE.txt for this sample’s licensing information
    
    Abstract:
    
            This contains all the CloudKit functions used by the View Controllers
         
*/

@import UIKit;
@import Foundation;
@import CloudKit;

@class AAPLUsers;
// Service
extern NSString * const QuestionField;
extern NSString * const LocationField;
extern NSString * const AnsweredField;
extern NSString * const CreationDateField;
extern NSString * const UniqueIDField;
extern NSString * const StatusField;

// Answers
extern NSString * const AnswerField;
extern NSString * const QuestionReferenceField;
extern NSString * const AceptedByUserField;
extern NSString * const AnswerPointsField;
// Photos
extern NSString * const AssetField;
extern NSString * const AssetThumbField;

extern NSString * const AssetOwnerRefField;
// Thumbnails
extern NSString * const ThumbOwnerRefField;
// Users
extern NSString * const UserNameField;
extern NSString * const AnswerCountField;
extern NSString * const RatingField;
// Awards
extern NSString * const AnswerRefField;
extern NSString * const GivenByUserRefField;

@interface AAPLCloudManager : NSObject

- (void)requestDiscoverabilityPermission:(void (^)(BOOL discoverable, NSError *errorFound))completionHandler;
- (void)discoverUserInfo:(void (^)(CKDiscoveredUserInfo *user))completionHandler;

- (void)uploadAssetWithURL:(NSURL *)assetURL completionHandler:(void (^)(CKRecord *record))completionHandler;
- (void)addRecordWithQuestion:(NSString *)question andLocation:(CLLocation *)location andAssetURL:(NSURL *)assetURL andAssetThumbURL:(NSURL *)assetThumbURL andID:(NSString *)uniqueIDString completionHandler:(void (^)(CKRecord *record))completionHandler;
- (void)addRecordWithAnswer:(NSString *)answer toQuestionID:(CKRecordID *)questionRecordID andLocation:(CLLocation *)location andAssetURL:(NSURL *)assetURL andAssetThumbURL:(NSURL *)assetThumbURL andID:(NSString *)uniqueIDString completionHandler:(void (^)(CKRecord *record))completionHandler;

- (void)fetchRecordWithID:(NSString *)recordID completionHandler:(void (^)(CKRecord *record))completionHandler;
- (void)queryForRecordsNearLocation:(CLLocation *)location completionHandler:(void (^)(NSMutableArray *records, NSError *errorFound))completionHandler;
- (void)queryRecordsforUserWithRecordID:(CKRecordID *)recordID completionHandler:(void (^)(NSMutableArray *records, NSError *errorFound))completionHandler;

- (void)saveRecord:(CKRecord *)record;
- (void)deleteRecord:(CKRecord *)record;
- (void)fetchRecordsWithType:(NSString *)recordType completionHandler:(void (^)(NSArray *records))completionHandler;
- (void)queryForRecordsWithReferenceRecordID:(CKRecordID *)referenceRecordID completionHandler:(void (^)(NSMutableArray *records, NSError *errorFound))completionHandler;

@property (nonatomic, readonly, getter=isSubscribed) BOOL subscribed;
- (void)subscribe;
- (void)unsubscribe;
- (void)createReferenceItemSchemaWithCompletionHandler:(void (^)(NSArray *records))completionHandler;

@end
