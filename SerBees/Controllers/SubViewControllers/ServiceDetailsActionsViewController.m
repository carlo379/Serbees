//  ServiceDetailsActionsViewController.m
//  SerBees

#import "ServiceDetailsActionsViewController.h"
#import "DataModelDefines.h"
#import <MapKit/MapKit.h>
#import "MapViewAnnotation.h"
#import <MessageUI/MessageUI.h>
#import "AddServiceViewController.h"

@interface ServiceDetailsActionsViewController ()<MFMailComposeViewControllerDelegate,MKMapViewDelegate,CLLocationManagerDelegate,AddServiceViewControllerDelegate>
@property (weak, nonatomic) IBOutlet UIImageView *image;
@property (weak, nonatomic) IBOutlet UILabel *contact;
@property (weak, nonatomic) IBOutlet UILabel *phone;
@property (weak, nonatomic) IBOutlet UILabel *email;
@property (weak, nonatomic) IBOutlet UILabel *website;
@property (weak, nonatomic) IBOutlet UILabel *address1;
@property (weak, nonatomic) IBOutlet UILabel *address2;
@property (weak, nonatomic) IBOutlet UITextView *descriptionService;
@property (weak, nonatomic) IBOutlet UIView *cardView;

// Map & Location Properties
@property (nonatomic, strong) MKPointAnnotation *pin;
@property (nonatomic, strong) CLLocation *currentLocation;
@property (nonatomic, strong) CLLocationManager *locationManager;
@property (weak, nonatomic) IBOutlet MKMapView *mapView;

@end

@implementation ServiceDetailsActionsViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    // Do any additional setup after loading the view.
    self.title = self.servicePost.postRecord[ServiceNameKey];
    self.navigationController.navigationBar.titleTextAttributes = @{NSForegroundColorAttributeName: [UIColor whiteColor]};
    
    // Change Bar Tint Color
    self.navigationController.navigationBar.barTintColor = UIColorFromRGB(0x004080);// Light Blue;
    self.navigationController.navigationBar.translucent = NO;
    
    // Place data from record to view
    [self populateDataFromRecord];
    
    self.cardView.layer.shadowColor = [UIColor blackColor].CGColor;
    self.cardView.layer.shadowRadius = 2.f;
    self.cardView.layer.shadowOffset = CGSizeMake(0.f, 2.f);
    self.cardView.layer.shadowOpacity = 1.f;
    self.cardView.layer.masksToBounds = NO;
    
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
    
}

- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

#pragma mark - Segue Navigation
// In a storyboard-based application, you will often want to do a little preparation before navigation
- (void)prepareForSegue:(UIStoryboardSegue *)segue sender:(id)sender {
    
    if ([segue.identifier isEqualToString: @"editServiceSegue"]) {
        AddServiceViewController *addServiceViewController = (AddServiceViewController *)segue.destinationViewController;
        addServiceViewController.delegate = self;
        addServiceViewController.currentService = self.servicePost;
    }
}

- (void)populateDataFromRecord {
    self.contact.text = self.servicePost.postRecord[ServiceContactKey];
    self.phone.text = self.servicePost.postRecord[ServicePhoneKey];
    self.email.text = self.servicePost.postRecord[ServiceEmailKey];
    self.website.text = self.servicePost.postRecord[ServiceWebsiteKey];
    self.address1.text = self.servicePost.postRecord[ServiceAddress1Key];
    self.address2.text = self.servicePost.postRecord[ServiceAddress2Key];
    self.descriptionService.text = self.servicePost.postRecord[ServiceDescriptionKey];
    
    // Round Corners for picture
    self.image.layer.cornerRadius = 10;
    self.image.layer.shadowColor = [UIColor blackColor].CGColor;
    self.image.layer.shadowRadius = 5.f;
    self.image.layer.shadowOffset = CGSizeMake(0.f, 5.f);
    self.image.layer.shadowOpacity = 1.f;
    self.image.layer.masksToBounds = YES;
    self.image.image = self.servicePost.imageRecord.fullImage;
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
    
    // Set Self Pin
    self.pin = [[MKPointAnnotation alloc]init];
    self.pin.coordinate = self.currentLocation.coordinate;
    
    // Set Service Pin
    MapViewAnnotation *servicePin = [[MapViewAnnotation alloc]initWithRecord:self.servicePost];
    
    [self.mapView addAnnotations:@[self.pin, servicePin]];
    [self.mapView showAnnotations:@[self.pin, servicePin] animated:YES];
    
    [self.locationManager stopUpdatingLocation];
}

- (void)locationManager:(CLLocationManager *)manager didFailWithError:(NSError *)error
{
    NSLog(@"Error Locating user Location Manager: %@", error);
    if([error.domain isEqualToString: kCLErrorDomain])
        [self retryLocationUpdate];
    else
        [self otherLocationError];
}

- (void)retryLocationUpdate {
    NSLog(@"kCLErrorDomain");
}

- (void)otherLocationError {
    NSLog(@"Other Location Errors");
}

#pragma mark - Map View Delegate
- (MKAnnotationView *)mapView:(MKMapView *)mapView viewForAnnotation:(id<MKAnnotation>)annotation
{
    // Handle any custom annotations.
    if ([annotation isKindOfClass:[MapViewAnnotation class]])
    {
        MapViewAnnotation *mapViewAnnotation = (MapViewAnnotation *)annotation;
        
        // If an existing pin view was not available, create one.
        MKAnnotationView *pinView = [[MKAnnotationView alloc] initWithAnnotation:mapViewAnnotation reuseIdentifier:@"CustomPinAnnotationView"];
        
        pinView.canShowCallout = NO;
        pinView.image = [UIImage imageNamed:@"bee.png"];
        pinView.calloutOffset = CGPointMake(0, -20);
        
        return pinView;
        
    } else {
        MKPinAnnotationView *view = [[MKPinAnnotationView alloc] initWithAnnotation:annotation reuseIdentifier:@""];
        
        view.draggable = YES;
        
        return view;
    }
}

- (IBAction)makeCallPressed:(UIBarButtonItem *)sender {
    
    NSString *cleanedString = [[self.phone.text componentsSeparatedByCharactersInSet:[[NSCharacterSet characterSetWithCharactersInString:@"0123456789"] invertedSet]] componentsJoinedByString:@""];
    
    NSString *number = [@"tel://" stringByAppendingString:cleanedString];
    [[UIApplication sharedApplication] openURL:[NSURL URLWithString:number]];
}

- (IBAction)emailPressed:(UIBarButtonItem *)sender {
    
    NSString *emailTitle = [self.servicePost.postRecord[ServiceNameKey] stringByAppendingString:@" Service Request"];
    NSString *messageBody = [@"Hello " stringByAppendingString:[self.contact.text stringByAppendingString:@", I want information about "]];
    NSArray *toRecipents = [NSArray arrayWithObject:self.email.text];
    
    MFMailComposeViewController *mc = [[MFMailComposeViewController alloc] init];
    mc.mailComposeDelegate = self;
    [mc setSubject:emailTitle];
    [mc setMessageBody:messageBody isHTML:NO];
    [mc setToRecipients:toRecipents];
    
    // Present mail view controller on screen
    [self presentViewController:mc animated:YES completion:NULL];
    
}

- (void) mailComposeController:(MFMailComposeViewController *)controller didFinishWithResult:(MFMailComposeResult)result error:(NSError *)error
{
    switch (result)
    {
        case MFMailComposeResultCancelled:
            NSLog(@"Mail cancelled");
            break;
        case MFMailComposeResultSaved:
            NSLog(@"Mail saved");
            break;
        case MFMailComposeResultSent:
            NSLog(@"Mail sent");
            break;
        case MFMailComposeResultFailed:
            NSLog(@"Mail sent failure: %@", [error localizedDescription]);
            break;
        default:
            break;
    }
    
    // Close the Mail Interface
    [self dismissViewControllerAnimated:YES completion:NULL];
}

#pragma mark - AddServiceViewControllerDelegate Delegate Methods
- (void)dismissRequestedByChildViewController {
    
    [self dismissViewControllerAnimated:YES completion:^{
        [self.parentViewController dismissViewControllerAnimated:YES completion:^{}];
    }];
}

@end
