//  BeesViewController.m
//  SerBees

#import "BeesViewController.h"
#import "GlobalDefines.h"
#import "BeesCollectionViewCell.h"
#import "AppDelegate.h"
#import "AAPLPostManager.h"
#import "AAPLCloudManager.h"
#import "SWRevealViewController.h"
#import "ServicePost.h"
#import "AddServiceViewController.h"
#import "ServiceDetailsActionsViewController.h"
#import "ServicesViewController.h"

@interface BeesViewController ()<UIGestureRecognizerDelegate,UICollectionViewDataSource, UICollectionViewDelegate, UIImagePickerControllerDelegate, UIScrollViewDelegate, UISearchBarDelegate, AddServiceViewControllerDelegate,AAPLPostManagerDelegate>
{
    BOOL resultsReady;
}
@property (strong, atomic) AAPLPostManager *postManager;
@property (weak, nonatomic) IBOutlet UICollectionView *collectionView;
@property (weak, nonatomic) IBOutlet UIButton *refreshButton;
@property (weak, nonatomic) IBOutlet UIActivityIndicatorView *refreshSpinner;
@property (strong, nonatomic) ServicePost *currentServiceSelected;
@property (weak, nonatomic) IBOutlet UIActivityIndicatorView *servicesLoadingSpinner;
@property (nonatomic,strong) CKDiscoveredUserInfo *mainUser;

@end

@implementation BeesViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    
    // Hide Table and start animating spinner
    self.collectionView.alpha = 0;
    [self.servicesLoadingSpinner startAnimating];
    
    // We tell the App Delegate that we're the tableController so it knows to let us know when a push is received
    ((AppDelegate *)[[UIApplication sharedApplication] delegate]).beesViewController = self;
    ServicesViewController *servicesViewController = ((AppDelegate *)[[UIApplication sharedApplication] delegate]).tableController;
    self.mainUser = servicesViewController.mainUser;
    
    // The post manager handles fetching and organizing all the posts. When it finishes a fetch it needs to know how to update the tableView
    self.postManager = [[AAPLPostManager alloc] initWithReloadHandler:^{
        
        [self.collectionView reloadData];
        
        if(resultsReady){
            if(self.collectionView.alpha == 0){
                // Shoe Table and start animating spinner
                self.collectionView.alpha = 1.0;
                [self.servicesLoadingSpinner stopAnimating];
            }
        }
    }];
    
    //[self.postManager loadBatch];
    [self.postManager loadUserPostsWithUser:self.mainUser];
    
    // Creates pull to refresh and tells postManager so it can endRefreshing when updates are done
    UIRefreshControl *refreshControl = [[UIRefreshControl alloc] init];
    [refreshControl addTarget:self action:@selector(loadUserPostsWithUserSlave) forControlEvents:UIControlEventValueChanged];
    [self.collectionView addSubview:refreshControl];
    self.postManager.refreshControl = refreshControl;
    
    // Set as delegate to receive protocol notificatioins
    self.postManager.delegate = self;
    
    // Refresh Posts
    [self.refreshButton addTarget:self action:@selector(loadUserPostsWithUserSlave) forControlEvents:UIControlEventTouchUpInside];
    
    // attach long press gesture to collectionView
    UILongPressGestureRecognizer *lpgr = [[UILongPressGestureRecognizer alloc]initWithTarget:self action:@selector(handleLongPress:)];
    //lpgr.minimumPressDuration = .5; //seconds
    //lpgr.delegate = self;
    //lpgr.delaysTouchesBegan = YES;
    [self.collectionView addGestureRecognizer:lpgr];
}

- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
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
                [self.collectionView reloadData];
            });
        }];
        [self.postManager loadNewPostsWithAAPLPost:postThatFiredPush];
    }];
}

#pragma mark - Segue Navigation
// In a storyboard-based application, you will often want to do a little preparation before navigation
- (void)prepareForSegue:(UIStoryboardSegue *)segue sender:(id)sender {
    
    if ([segue.identifier isEqualToString: @"addServiceSegue"]) {
        AddServiceViewController *addServiceViewController = (AddServiceViewController *)segue.destinationViewController;
        addServiceViewController.delegate = self;
    }
    
    if ([segue.identifier isEqualToString: @"serviceDetailsSegue"]) {
        ServiceDetailsActionsViewController *serviceDetailsActionsViewController = (ServiceDetailsActionsViewController *)[[(UINavigationController *)segue.destinationViewController childViewControllers]objectAtIndex:0];
        //ServiceDetailsActionsViewController *serviceDetailsActionsViewController = (ServiceDetailsActionsViewController *)[navController.childViewControllers objectAtIndex:0];
        
        serviceDetailsActionsViewController.servicePost = self.currentServiceSelected;
    }
}

#pragma mark - IBActions
- (IBAction)addServicePressed:(UIButton *)sender {
    [self performSegueWithIdentifier:@"addServiceSegue" sender:self];
}
- (IBAction)refreshPressed:(UIButton *)sender {
    [self.refreshSpinner startAnimating];
    self.refreshButton.hidden = YES;
}

#pragma mark - UICollectionViewDataSource Methods
- (NSInteger)numberOfSectionsInCollectionView:(UICollectionView *)collectionView
{
    return 1;
}

- (NSInteger)collectionView:(UICollectionView *)collectionView numberOfItemsInSection:(NSInteger)section
{
    // One table cell for each post we have
    return self.postManager.postCells.count;
}

- (UICollectionViewCell *)collectionView:(UICollectionView *)cv cellForItemAtIndexPath:(NSIndexPath *)indexPath;
{
    BeesCollectionViewCell *cell = [cv dequeueReusableCellWithReuseIdentifier:SERVICES_CELL_ID forIndexPath:indexPath];
    if (cell == nil) {
        cell = [[BeesCollectionViewCell alloc] init];
    }
    ServicePost *collectionCellPost = (self.postManager.postCells)[indexPath.row];
    [cell displayInfoForPost:collectionCellPost];
    
    return cell;
}

#pragma mark - UICollectionViewDelegate Methods
- (void)collectionView:(UICollectionView *)collectionView didSelectItemAtIndexPath:(NSIndexPath *)indexPath
{
    NSLog(@"Cell Selected");
    self.currentServiceSelected = (self.postManager.postCells)[indexPath.row];
    [self performSegueWithIdentifier:@"serviceDetailsSegue" sender:self];
    
}
- (void)collectionView:(UICollectionView *)collectionView didDeselectItemAtIndexPath:(NSIndexPath *)indexPath {
    // TODO: Deselect item
}

#pragma mark - AddServiceViewControllerDelegate Delegate Methods
- (void)dismissRequestedByChildViewController {
    
    [self dismissViewControllerAnimated:YES completion:^{
        
        
    }];
}

- (void) AddServiceViewController:(AddServiceViewController *)controller postedRecord:(ServicePost *)record;
{
    [self.postManager loadNewPostsWithAAPLPost:record];
}

#pragma mark - AAPLPostManagerDelegate Method
- (void)finishLoading {
    [self.refreshSpinner stopAnimating];
    self.refreshButton.hidden = NO;
    
    // Set Flag to signal results are ready in self.postmanager
    resultsReady = YES;
    
    if(resultsReady){
        if(self.collectionView.alpha == 0){
            // Shoe Table and start animating spinner
            self.collectionView.alpha = 1.0;
            [self.servicesLoadingSpinner stopAnimating];
        }
    }
}


#pragma mark UISearchBarDelegate
- (void) searchBarTextDidBeginEditing:(UISearchBar *)searchBar
{
    [searchBar setShowsCancelButton:YES animated:YES];
}

- (void) searchBarSearchButtonClicked:(UISearchBar *)searchBar
{
    // Hide Collection View and show spinner
    self.collectionView.alpha = 0;
    [self.servicesLoadingSpinner startAnimating];
    
    // Set Flag to signal results are NOT ready in self.postmanager
    resultsReady = NO;
    
    // Tells the postManager to reset the tag string with the new tag string
    [self.postManager resetWithTagString:searchBar.text forUser:self.mainUser];
    [searchBar setShowsCancelButton:NO animated:YES];
    [searchBar resignFirstResponder];
}

- (void) searchBarCancelButtonClicked:(UISearchBar *)searchBar
{
    // Hide Collection View and show spinner
    self.collectionView.alpha = 0;
    [self.servicesLoadingSpinner startAnimating];
    
    // Set Flag to signal results are NOT ready in self.postmanager
    resultsReady = NO;
    
    searchBar.text = @"";
    [self.postManager resetWithTagString:@"" forUser:self.mainUser];
    searchBar.showsCancelButton = NO;
    [searchBar resignFirstResponder];
}

#pragma mark Custom Methods
-(void)loadUserPostsWithUserSlave{
    [self.postManager loadUserPostsWithUser:self.mainUser];
}
-(void)handleLongPress:(UILongPressGestureRecognizer *)gestureRecognizer
{
    CGPoint point = [gestureRecognizer locationInView:self.collectionView];
    
    // Show Alert Before Deleting
    UIAlertController * alert=   [UIAlertController
                                  alertControllerWithTitle:@"Delete Service"
                                  message:@"Do you really want to Delete this Service"
                                  preferredStyle:UIAlertControllerStyleAlert];
    
    UIAlertAction* cancel = [UIAlertAction actionWithTitle:@"Cancel" style:UIAlertActionStyleDefault
                                                   handler:^(UIAlertAction * action) {
                                                       // Do Nothing
                                                   }];
    
    UIAlertAction* delete = [UIAlertAction actionWithTitle:@"Delete" style:UIAlertActionStyleDestructive
                                                   handler:^(UIAlertAction * action) {
                                                       [self executeDeleteOnCGPoint:point];
                                                       
                                                   }];
    
    [alert addAction:cancel];
    [alert addAction:delete];
    
    
    [self presentViewController:alert animated:YES completion:nil];
    
}

-(void)executeDeleteOnCGPoint:(CGPoint)point{
    
    NSIndexPath *indexPath = [self.collectionView indexPathForItemAtPoint:point];
    if (indexPath == nil){
        NSLog(@"couldn't find index path");
    } else {
        
        [self.collectionView performBatchUpdates:^{
            AAPLCloudManager *cloudManager = [[AAPLCloudManager alloc]init];
            ServicePost *currentRecord = self.postManager.postCells[indexPath.row];
            [cloudManager deleteRecord:currentRecord.imageRecord.record];
            [self.postManager.postCells removeObjectAtIndex:indexPath.row];
            [self.collectionView deleteItemsAtIndexPaths:[NSArray arrayWithObject:indexPath]];
            
        } completion:^(BOOL finished) {}];
    }
}

@end
