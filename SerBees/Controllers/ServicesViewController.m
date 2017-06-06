//  ServicesViewController.m
//  SerBees

@import CloudKit;
@import MobileCoreServices;
#import <CoreLocation/CoreLocation.h>
#import <MapKit/MapKit.h>
#import <QuartzCore/QuartzCore.h>

#import "SWRevealViewController.h"
#import "GlobalDefines.h"
#import "HelperMethods.h"
#import "UIImage+Extensions.h"

#import "ServicesViewController.h"
#import "AppDelegate.h"
#import "ServiceTableViewCell.h"
#import "AAPLPostManager.h"
#import "ServicePost.h"

#import "SearchViewController.h"
#import "MapViewAnnotation.h"
#import "CustomAnnotationView.h"
#import "ServiceDetailsActionsViewController.h"

static NSString * const cellReuseIdentifier = @"serviceCell";

@interface ServicesViewController () <AAPLPostManagerDelegate,CLLocationManagerDelegate,MKMapViewDelegate,UITextViewDelegate,UINavigationControllerDelegate,UIImagePickerControllerDelegate,UIScrollViewDelegate,UISearchBarDelegate,UITableViewDataSource,UITableViewDelegate,UITableViewDelegate,UIImagePickerControllerDelegate,UIAlertViewDelegate,UIActionSheetDelegate,UINavigationControllerDelegate,UIGestureRecognizerDelegate,SearchViewControllerDelegate>
{
    BOOL firstMapMove;
    BOOL _imagePickerWillDismiss;
    BOOL _isFourInchesScreen;
    int _cameraUsed;
    int _cameraOrientation;
    int kSizeReduction;
}

@property (strong, atomic) AAPLPostManager *postManager;
@property (strong) AAPLCloudManager *cloudManager;
@property (strong, nonatomic) SearchViewController *searchViewController;

// User Discoverability Properties
@property (weak, nonatomic) IBOutlet UILabel *userNameLB;
@property (weak, nonatomic) IBOutlet UIActivityIndicatorView *userSpinner;
@property (weak, nonatomic) IBOutlet UIButton *tryAgainBT;
@property (weak, nonatomic) IBOutlet UILabel *titleLabel;

// Sending Message to iCloud properties
@property (weak, nonatomic) IBOutlet UIActivityIndicatorView *sendingSpinner;
@property (weak, nonatomic) IBOutlet UIButton *sendingBT;
@property (weak, nonatomic) IBOutlet UIButton *refreshBt;

// Map & Location Properties
@property (nonatomic, strong) MKPointAnnotation *pin;
@property (nonatomic, strong) CLLocation *currentLocation;
@property (nonatomic, strong) CLLocationManager *locationManager;
@property (nonatomic, retain) NSMutableArray *results;
@property (nonatomic,strong) NSTimer *navBarHideTimer;

// Data Model
@property (strong, nonatomic) NSMutableArray *photosArray;
@property (strong, nonatomic) NSURL *tempPhotoURL;
@property (strong, nonatomic) NSURL *tempPhotoThumbURL;

// UIImagePickerController property
@property (strong, nonatomic) UIImagePickerController *cameraUI;

// Property for Helper Methods
@property (nonatomic, strong) HelperMethods *helperMethod;

@property (weak, nonatomic) IBOutlet MKMapView *mapView;
@property (weak, nonatomic) IBOutlet UIView *navBar;
@property (weak, nonatomic) IBOutlet UIButton *reloadBt;
@property (weak, nonatomic) IBOutlet UIButton *reloadMsg;
@property (weak, nonatomic) IBOutlet UIActivityIndicatorView *messagesSpinner;
@property (weak, nonatomic) IBOutlet UIButton *locationBT;

@property (weak, nonatomic) IBOutlet NSLayoutConstraint *navBarVerticalSpaceConst;
@property (weak, nonatomic) IBOutlet NSLayoutConstraint *mapViewHeightConst;

// Property to store the Selected Record
@property (nonatomic,strong) ServicePost *selectedRecord;

// Search Properties
@property (strong, nonatomic) NSMutableArray *sectionsArray;

@end

@implementation ServicesViewController

#pragma mark - Getter and Setter Methods
// Initialize Photos Mutable array
- (HelperMethods *)helperMethod
{
    if(!_helperMethod)_helperMethod = [[HelperMethods alloc] init];
    return _helperMethod;
}

// Initialize UIImagePickerController
- (UIImagePickerController *)cameraUI
{
    if(!_cameraUI)_cameraUI = [[UIImagePickerController alloc] init];
    
    // Hides the controls for moving & scaling pictures, or for trimming movies. To instead show the controls, use YES.
    _cameraUI.allowsEditing = YES;
    
    return _cameraUI;
}

// Initialize Photos Mutable array
- (NSMutableArray *)photosArray
{
    if(!_photosArray)_photosArray = [[NSMutableArray alloc] init];
    return _photosArray;
}

#pragma mark - View Life Cycle Methods
- (void) viewDidLoad {
    [super viewDidLoad];
    
    // Hide Table and start animating spinner
    self.tableView.alpha = 0;
    [self.messagesSpinner startAnimating];
    
    // Set Map Delegate
    self.mapView.delegate = self;
    
    //Initialize Location Manager
    self.locationManager = [[CLLocationManager alloc] init];
    self.locationManager.distanceFilter = kCLDistanceFilterNone;
    self.locationManager.desiredAccuracy = kCLLocationAccuracyBest;
    self.locationManager.delegate = self;
    
    
    if ([self.locationManager respondsToSelector:@selector(requestAlwaysAuthorization)]) {
        [self.locationManager requestAlwaysAuthorization];
    }
    
    //Set the color of the navigation bar text
    self.navigationController.navigationBar.tintColor = [UIColor whiteColor];
    
    // Set first Map Move
    firstMapMove = YES;
    
    // We tell the App Delegate that we're the tableController so it knows to let us know when a push is received
    ((AppDelegate *)[[UIApplication sharedApplication] delegate]).tableController = self;
    
    // The post manager handles fetching and organizing all the posts. When it finishes a fetch it needs to know how to update the tableView
    self.postManager = [[AAPLPostManager alloc] initWithReloadHandler:^{
        [self.tableView reloadData];
        [self updateAnnotations];
        
        if(self.tableView.alpha == 0){
            // Shoe Table and start animating spinner
            self.tableView.alpha = 1.0;
            [self.messagesSpinner stopAnimating];
        }
    }];
    self.postManager.delegate = self;
    
    [self.postManager loadBatch];
    
    // Creates pull to refresh and tells postManager so it can endRefreshing when updates are done
    self.refreshControl = [[UIRefreshControl alloc] init];
    [self.refreshControl addTarget:self.postManager action:@selector(loadNewPosts) forControlEvents:UIControlEventValueChanged];
    [self.tableView addSubview:self.refreshControl];
    self.postManager.refreshControl = self.refreshControl;
    
    /***** Left Sliding Menus SET-UP *****/
    [self.revealViewController panGestureRecognizer];
    [self.revealViewController tapGestureRecognizer];
    
    // Set the Left Side and Right bar button action. When it's tapped, it'll show up the sidebar.
    //[self.leftSideMenu addTarget:self.revealViewController action:@selector(revealToggle:) forControlEvents:UIControlEventTouchUpInside];
    [self.rightSideMenu addTarget:self.revealViewController action:@selector(rightRevealToggle:) forControlEvents:UIControlEventTouchUpInside];
    
    // Estimate the Table Row Height
    self.tableView.rowHeight = UITableViewAutomaticDimension;
    self.tableView.estimatedRowHeight = 116.0;
    
    // Initialize CloudManager Property
    self.cloudManager = [[AAPLCloudManager alloc] init];
    
    // Request Discoverability and populate user name
    [self requestDiscoverabilityPermission];
    
    // DismissMode for Keyboard - Dissmiss when scroll view is dragged.
    self.tableView.keyboardDismissMode = UIScrollViewKeyboardDismissModeOnDrag;
    
    // Hide Elements during loading
    self.reloadBt.hidden = YES;
    self.reloadMsg.hidden = YES;
    self.tableView.hidden = NO;
    
    self.tableView.rowHeight = UITableViewAutomaticDimension;
    self.tableView.estimatedRowHeight = 50.0; // set to whatever your "average" cell height is
    
    // Clean Up Cache directory
    [self eraseCacheFiles];
    
    self.locationBT.layer.shadowColor = [UIColor blackColor].CGColor;
    self.locationBT.layer.shadowRadius = 5.f;
    self.locationBT.layer.shadowOffset = CGSizeMake(0.f, 3.f);
    self.locationBT.layer.shadowOpacity = 1.f;
    self.locationBT.layer.masksToBounds = NO;
    
}

- (void) loadNewPostsWithRecordID:(CKRecordID *)recordID
{
    // Called when AAPLAppDelegate receives a push notification
    // The post that triggered the push may not be indexed yet, so a fetch on predicate might not see it.
    // We can still fetch by recordID though
    CKDatabase *publicDB = [CKContainer defaultContainer].publicCloudDatabase;
    [publicDB fetchRecordWithID:recordID completionHandler:^(CKRecord *record, NSError *error) {
        ServicePost *postThatFiredPush = [[ServicePost alloc] initWithRecord:record];
        [postThatFiredPush loadImageWithKeys:@[ServiceImageFullsizeKey] completion:^{
            dispatch_async(dispatch_get_main_queue(), ^{
                [self.tableView reloadData];
            });
        }];
        [self.postManager loadNewPostsWithAAPLPost:postThatFiredPush];
    }];
}

#pragma mark - Segue Navigation
// In a storyboard-based application, you will often want to do a little preparation before navigation
- (void)prepareForSegue:(UIStoryboardSegue *)segue sender:(id)sender {
    
    if ([segue.identifier isEqualToString: @"showDetailsSegue"]) {
        ServiceDetailsActionsViewController *serviceDetailsActionsViewController = (ServiceDetailsActionsViewController *)[[(UINavigationController *)segue.destinationViewController childViewControllers]objectAtIndex:0];
        //ServiceDetailsActionsViewController *serviceDetailsActionsViewController = (ServiceDetailsActionsViewController *)[navController.childViewControllers objectAtIndex:0];
        
        serviceDetailsActionsViewController.servicePost = self.selectedRecord;
    }
}

- (IBAction)detailsInfoPressed:(UIButton *)sender {
    NSLog(@"Detials Info Button Pressed");
    [self performSegueWithIdentifier:@"showDetailsSegue" sender:self];
}

#pragma mark - UITableViewDelegate
- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView {
    
    if(!self.searchViewController){
        SWRevealViewController *revealViewC = (SWRevealViewController *)self.parentViewController;
        self.searchViewController = (SearchViewController *)[revealViewC.rightViewController.childViewControllers objectAtIndex:0];
        
        [self.searchViewController setDelegate:self];
    }
    
    return 1;
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section {
    // One table cell for each post we have
    
    return self.postManager.postCells.count;
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath
{
    // Uses a tableViewCell to display AAPLPost info
    ServiceTableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:cellReuseIdentifier forIndexPath:indexPath];
    if (cell == nil) {
        cell = [[ServiceTableViewCell alloc] init];
    }
    ServicePost *tableCellPost = (self.postManager.postCells)[indexPath.row];
    [cell displayInfoForPost:tableCellPost];
    if(cell.assetImageView.image)
        [cell.assetSpinner stopAnimating];
    else
        [cell.assetSpinner startAnimating];
    
    return cell;
}

// Table Cell Selection Methods
- (NSIndexPath *)tableView:(UITableView *)tableView willSelectRowAtIndexPath:(NSIndexPath *)indexPath
{
    NSLog(@"willSelectRowAtIndexPath");
    
    
    ServiceTableViewCell *cellSelected = (ServiceTableViewCell *)[tableView cellForRowAtIndexPath:[tableView indexPathForSelectedRow]];
    cellSelected.detailsBT.alpha = MIN_ALPHA;
    
    ServiceTableViewCell *cellToBeSelected = (ServiceTableViewCell *)[tableView cellForRowAtIndexPath:indexPath];
    
    // Animate the appearance of the Answer Button after the user selected a Row
    [UIView animateWithDuration:ALPHA_ANIMATION
                          delay:0.0
                        options:(UIViewAnimationOptionCurveEaseIn | UIViewAnimationOptionAllowUserInteraction)
                     animations:^{
                         
                         cellToBeSelected.detailsBT.alpha = MAX_ALPHA;
                         
                     } completion:^(BOOL finished) {
                         //[self showNavBarAndPicture];
                         
                     }];
    
    // Update Photo and Map with Selection
    ServicePost *record = (self.postManager.postCells)[indexPath.row];
    firstMapMove = YES;
    [self updateMapViewWithSelectedRecord:record];
    
    return indexPath;
}

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath {
    NSLog(@"Table Cell Selected");
    
    // Pass Record to property based on the tablecell selected
    self.selectedRecord = (self.postManager.postCells)[indexPath.row];
}

#pragma mark - Scroll View Delegate
- (void) scrollViewDidScroll:(UIScrollView *)scrollView
{
    // Checks to see if the user has scrolled five posts from the bottom and if we want to update
    CGPoint tableBottom = CGPointMake(scrollView.contentOffset.x, scrollView.contentOffset.y + scrollView.bounds.size.height);
    if([self.tableView indexPathForRowAtPoint:tableBottom].row + 5 > self.postManager.postCells.count && self.postManager.postCells.count > 0)
    {
        [self.postManager loadBatch];
    }
}

#pragma mark - Custom Method
- (void)retryLocationUpdate {
    NSLog(@"kCLErrorDomain");
}

- (void)otherLocationError {
    NSLog(@"Other Location Errors");
}

- (void)showNavBar:(NSTimer *)timer
{
    // Nil Timer to avoid firing twice
    self.navBarHideTimer = nil;
    
    // Animate the movement of the Nav Bar back into place after the used moved the map
    [UIView animateWithDuration:.2
                          delay:0.0
                        options:UIViewAnimationOptionCurveEaseIn
                     animations:^{
                         self.navBarVerticalSpaceConst.constant = 0;
                         [self.view layoutIfNeeded]; // Called on parent view
                     } completion:^(BOOL finished) {
                         
                     }];
}

- (void)eraseCacheFiles {
    
    // Clear Cache from Assets (Images or Videos) temporary stored.
    NSFileManager *fileMgr = [NSFileManager defaultManager];
    NSString *cacheFolderPath = [NSSearchPathForDirectoriesInDomains(NSCachesDirectory, NSUserDomainMask, YES) objectAtIndex:0];
    
    NSArray *fileArray = [fileMgr contentsOfDirectoryAtPath:cacheFolderPath error:nil];
    for (NSString *filename in fileArray)  {
        if([filename containsString:@".png"])
            [fileMgr removeItemAtPath:[cacheFolderPath stringByAppendingPathComponent:filename] error:NULL];
    }
}

- (IBAction)requestDiscoverabilityPermission
{
    // Hide Try Again Button while we are communicating with icloud
    self.tryAgainBT.hidden = YES;
    
    // Request Discoverability Permission
    //   Start Spinner
    [self.userSpinner startAnimating];
    [self.cloudManager requestDiscoverabilityPermission:^(BOOL discoverable, NSError *errorFound) {
        
        if (discoverable) {
            [self.cloudManager discoverUserInfo:^(CKDiscoveredUserInfo *user) {
                [self discoveredUserInfo:user];
                
                // Assign Discovered user to mainUser Property to have a reference property to that information.
                self.mainUser = user;
                
                // Since we were successful discovering user and establishing connection, we can hide the Try Again button...
                self.tryAgainBT.hidden = YES;
                
            }];
        } else {
            // Show Try Again Button since an error was found
            self.tryAgainBT.hidden = NO;
            // Stop Spinner
            [self.userSpinner stopAnimating];
            
            // Notify user that there was a problem: iCloud servers or Discoverability...
            if(errorFound){
                
                UIAlertView* curr2=[[UIAlertView alloc] initWithTitle:@"You are not logged to iCloud!" message:@"You Need to Sign-In by Going to Settings->iCloud->iCloud Drive->On" delegate:self cancelButtonTitle:@"OK" otherButtonTitles:@"Settings", nil];
                curr2.tag=121;
                [curr2 show];
                
                [self.messagesSpinner stopAnimating];
                
            } else {
                UIAlertController *alert = [UIAlertController alertControllerWithTitle:@"SerBees" message:@"Allow Permission for Discoverability." preferredStyle:UIAlertControllerStyleAlert];
                
                UIAlertAction *action = [UIAlertAction actionWithTitle:@"OK" style:UIAlertActionStyleDefault handler:^(UIAlertAction *act) {
                    [self dismissViewControllerAnimated:YES completion:nil];
                    
                }];
                
                [alert addAction:action];
                [self presentViewController:alert animated:YES completion:nil];
            }
        }
    }];
    
}

- (void)alertView:(UIAlertView *)alertView clickedButtonAtIndex:(NSInteger)buttonIndex
{
    NSLog(@"buttonIndex:%ld",(long)buttonIndex);
    
    if (alertView.tag == 121 && buttonIndex == 1)
    {
        //code for opening settings app in iOS 8
        [[UIApplication sharedApplication] openURL:[NSURL  URLWithString:UIApplicationOpenSettingsURLString]];
    }
}

- (void)discoveredUserInfo:(CKDiscoveredUserInfo *)user {
    if (user) {
        NSString *fullName = [NSString stringWithFormat:@"%@", user.firstName];
        
        // Stop Spinner because information was received.
        [self.userSpinner stopAnimating];
        
        // Set the user name in the label
        self.userNameLB.text = fullName;
    } else {
        self.userNameLB.text = @"Anonymous";
    }
}

- (IBAction)refreshLocationPressed:(UIButton *)sender {
    // Refresh User Location
    [self.locationManager startUpdatingLocation];
}

#pragma mark - Map View Delegate
- (MKAnnotationView *)mapView:(MKMapView *)mapView viewForAnnotation:(id<MKAnnotation>)annotation {
    
    // If it's the user location, just return nil.
    if ([annotation isKindOfClass:[MKUserLocation class]])
        return nil;
    
    // Handle any custom annotations.
    if ([annotation isKindOfClass:[MapViewAnnotation class]])
    {
        MapViewAnnotation *mapViewAnnotation = (MapViewAnnotation *)annotation;
        
        // Try to dequeue an existing pin view first.
        MKAnnotationView *pinView = (MKAnnotationView*)[mapView dequeueReusableAnnotationViewWithIdentifier:@"CustomPinAnnotationView"];
        
        if (!pinView)
        {
            // If an existing pin view was not available, create one.
            pinView = [[MKAnnotationView alloc] initWithAnnotation:mapViewAnnotation reuseIdentifier:@"CustomPinAnnotationView"];
            pinView.canShowCallout = YES;
            pinView.image = [UIImage imageNamed:@"bee.png"];
            pinView.calloutOffset = CGPointMake(0, -20);
            
            // Add a detail disclosure button to the callout.
            UIButton* rightButton = [UIButton buttonWithType:UIButtonTypeDetailDisclosure];
            //[rightButton setFrame:CGRectMake(0,0,22,22)];
            //[rightButton setImage:[UIImage imageNamed:@"answer"] forState:UIControlStateNormal];
            //[rightButton setTintColor:[UIColor brownColor]];
            
            pinView.rightCalloutAccessoryView = rightButton;
            MapViewAnnotation *annot = (MapViewAnnotation *)pinView.annotation;
            // Add an image to the left callout.
            if(annot.image){
                UIImageView *iconView = [[UIImageView alloc] initWithImage:annot.image];
                pinView.leftCalloutAccessoryView = iconView;
            } else {
                pinView.leftCalloutAccessoryView = nil;
            }
            
        } else {
            pinView.annotation = (MapViewAnnotation *)annotation;
            pinView.image = [UIImage imageNamed:@"bee.png"];
            
            MapViewAnnotation *annot = (MapViewAnnotation *)pinView.annotation;
            // Add an image to the left callout.
            if(annot.image){
                UIImageView *iconView = [[UIImageView alloc] initWithImage:annot.image];
                pinView.leftCalloutAccessoryView = iconView;
            } else {
                pinView.leftCalloutAccessoryView = nil;
            }
            
        }
        
        
        return pinView;
    }
    
    return nil;
}

- (void)mapView:(MKMapView *)mapView didSelectAnnotationView:(MKAnnotationView *)view {
    NSLog(@"didSelectAnnotationView");
    
    // get annotation and verify Kind;
    id <MKAnnotation> annotation = [view annotation];
    if ([annotation isKindOfClass:[MapViewAnnotation class]]){
        
        // then cast to MapViewAnnotation Class
        MapViewAnnotation *mapViewAnnotation = (MapViewAnnotation *)annotation;
        
        // Loop thru records and compare record id with selected annotation
        for(ServicePost *currentRecord in self.postManager.postCells){
            
            // If match found, calculate IndexPath and select programmatically select table row.
            if(currentRecord.postRecord[ServiceRecordIDKey] == mapViewAnnotation.recordID){
                self.selectedRecord = currentRecord;
                NSIndexPath *indexPath = [NSIndexPath indexPathForRow:[self.postManager.postCells indexOfObject:currentRecord] inSection:0];
                [self.tableView selectRowAtIndexPath:indexPath animated:YES scrollPosition:UITableViewScrollPositionTop];
                
                ServiceTableViewCell *cellToBeSelected = (ServiceTableViewCell *)[self.tableView cellForRowAtIndexPath:indexPath];
                
                // Animate the appearance of the Answer Button after the user selected a Row
                [UIView animateWithDuration:ALPHA_ANIMATION
                                      delay:0.0
                                    options:(UIViewAnimationOptionCurveEaseIn | UIViewAnimationOptionAllowUserInteraction)
                                 animations:^{
                                     
                                     cellToBeSelected.detailsBT.alpha = MAX_ALPHA;
                                     
                                 } completion:^(BOOL finished) {
                                     //[self showNavBarAndPicture];
                                     
                                 }];
            }
        }
    }
}

- (void)mapView:(MKMapView *)mapView didDeselectAnnotationView:(MKAnnotationView *)view {
    NSLog(@"did DeSelectAnnotationView");
    
    ServiceTableViewCell *cellSelected = (ServiceTableViewCell *)[self.tableView cellForRowAtIndexPath:[self.tableView indexPathForSelectedRow]];
    cellSelected.detailsBT.alpha = MIN_ALPHA;
}
- (void)mapView:(MKMapView *)mapView annotationView:(MKAnnotationView *)view calloutAccessoryControlTapped:(UIControl *)control
{
    // here we illustrate how to detect which annotation type was clicked on for its callout
    id <MKAnnotation> annotation = [view annotation];
    if ([annotation isKindOfClass:[MapViewAnnotation class]])
    {
        [self performSegueWithIdentifier:@"showDetailsSegue" sender:self];
    }
    
    //[self.navigationController pushViewController:self.detailViewController animated:YES];
}

- (void)mapViewDidFinishLoadingMap:(MKMapView *)mapView{
    NSLog(@"Did Finish Loading Map");
    
    /*
     MKUserLocation *userLocation = self.mapView.userLocation;
     MKCoordinateRegion region = MKCoordinateRegionMakeWithDistance (userLocation.location.coordinate, 50, 50);
     [self.mapView setRegion:region animated:NO];
     */
    
}

- (void)mapView:(MKMapView *)mapView regionWillChangeAnimated:(BOOL)animated
{
    if(!(firstMapMove)){
        
        // Invalidate timer if it has not fired yet, since the user moved the map again.
        [self.navBarHideTimer invalidate];
        
        // Animate the Hiding of the NavBar when the user move the Map.
        [UIView animateWithDuration:NAV_BAR_ANIMATION_TIME
                              delay:0.0
                            options:UIViewAnimationOptionCurveEaseIn
                         animations:^{
                             self.navBarVerticalSpaceConst.constant = -NAV_BAR_HEIGHT;
                             [self.view layoutIfNeeded]; // Called on parent view
                         } completion:^(BOOL finished) {
                             
                         }];
    }
    
}

- (void)mapView:(MKMapView *)mapView regionDidChangeAnimated:(BOOL)animated
{
    if(!(firstMapMove)){
        self.navBarHideTimer = [NSTimer scheduledTimerWithTimeInterval:NAV_BAR_HIDE_TIME
                                                                target:self
                                                              selector:@selector(showNavBar:)
                                                              userInfo:nil
                                                               repeats:NO];
    }
}

- (void)updateMapViewWithSelectedRecord:(ServicePost *)record {
    NSLog(@"updateMapViewWithSelectedRecord");
    
    firstMapMove = NO;
    
    NSArray *annotationArray = [self.mapView annotations];
    
    for(id annotation in annotationArray) {
        if([annotation isKindOfClass:[MapViewAnnotation class]]){
            MapViewAnnotation *currentAnnotation = (MapViewAnnotation *)annotation;
            
            if(currentAnnotation.recordID == record.postRecord[ServiceRecordIDKey]){
                [self.mapView selectAnnotation:currentAnnotation animated:YES];
            }
        }
    }
}

- (void)updateAnnotations {
    
    NSMutableArray *annotations = [[NSMutableArray alloc] init];
    
    for(ServicePost *record in self.postManager.postCells){
        MapViewAnnotation *annotation = [[MapViewAnnotation alloc] initWithRecord:record];
        [annotations addObject:annotation];
    }
    [self.mapView removeAnnotations:self.mapView.annotations];
    [self.mapView addAnnotations:annotations];
}

#pragma mark - CLLocationManagerDelegate Methods
- (void)locationManager:(CLLocationManager *)manager didChangeAuthorizationStatus:(CLAuthorizationStatus)status
{
    NSLog(@"didChangeAuthorizationStatus");
    if(status != kCLAuthorizationStatusNotDetermined)
        [self.locationManager startUpdatingLocation];
    
}

- (void)locationManager:(CLLocationManager *)manager didUpdateLocations:(NSArray *)locations {
    self.currentLocation = locations.lastObject;
    
    if (!self.pin) {
        self.pin = [[MKPointAnnotation alloc]init];
        self.pin.coordinate = self.currentLocation.coordinate;
        
        [self.mapView addAnnotation:self.pin];
        [self.mapView showAnnotations:@[self.pin] animated:NO];
        
        [self.locationManager stopUpdatingLocation];
        
        // Flag the initial location update
        firstMapMove = NO;
    } else {
        self.pin.coordinate = self.currentLocation.coordinate;
        
        [self.mapView addAnnotation:self.pin];
        [self.mapView showAnnotations:@[self.pin] animated:NO];
        
        [self.locationManager stopUpdatingLocation];
    }
}

- (void)locationManager:(CLLocationManager *)manager didFailWithError:(NSError *)error
{
    NSLog(@"Error Locating user Location Manager: %@", error);
    if([error.domain isEqualToString: kCLErrorDomain])
        [self retryLocationUpdate];
    else
        [self otherLocationError];
    
    firstMapMove = NO;
    
}

#pragma mark - SearchViewControllerDelegate Methods
- (void)searchPressedwithTags:(NSString *)tags andSections:(NSArray *)sectionsArray andRange:(NSInteger)range
{
    NSLog(@" Delegate Called");
    
    // Close Right View
    [self.rightSideMenu sendActionsForControlEvents:UIControlEventTouchUpInside];
    
    MKCoordinateRegion viewRegion = MKCoordinateRegionMakeWithDistance(self.pin.coordinate, (range * 1000), (range * 1000));
    MKCoordinateRegion adjustedRegion = [self.mapView regionThatFits:viewRegion];
    [self.mapView setRegion:adjustedRegion animated:YES];
    
    [self.postManager resetWithTagString:tags andSections:sectionsArray andRange:range toLocation:self.currentLocation];
}

#pragma mark - AAPLPostManagerDelegate
- (void)finishLoading{
    [self updateAnnotations];
    [self.tableView reloadData];
}
@end
