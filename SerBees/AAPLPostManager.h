/*
 Copyright (C) 2014 Apple Inc. All Rights Reserved.
 See LICENSE.txt for this sample’s licensing information
 
 Abstract:
 
  Used by AAPLTableViewController to retrieve remote posts and stitch local posts into the tableview
  
 */

#define updateBy 10

@import Foundation;
@import UIKit;
@import CoreLocation;
@import CloudKit;

@class ServicePost;
@protocol AAPLPostManagerDelegate <NSObject>
- (void)finishLoading;
@end


@interface AAPLPostManager : NSObject

@property (strong, atomic) NSMutableArray *postCells;
@property (weak, atomic) UIRefreshControl *refreshControl;

- (instancetype) initWithReloadHandler:(void(^)(void))reload NS_DESIGNATED_INITIALIZER;
- (void) loadNewPostsWithAAPLPost:(ServicePost *)post;
- (void) loadNewPosts;
- (void) loadBatch;
- (void) loadUserPostsWithUser:(CKDiscoveredUserInfo *)user;
- (void) resetWithTagString:(NSString *)tags andSections:(NSArray *)sectionsArray andRange:(NSInteger)range toLocation:(CLLocation *)location;
- (void) resetWithTagString:(NSString *)tags forUser:(CKDiscoveredUserInfo *)user;

// Delegate Property
@property (nonatomic, weak) id <AAPLPostManagerDelegate> delegate;

@end
