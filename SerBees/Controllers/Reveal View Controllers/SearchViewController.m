//  SearchViewController.m
//  SerBees

#import "SearchViewController.h"
#import "M13Checkbox.h"
@import MapKit;
@import MobileCoreServices;
@import CoreLocation;
#import "DataModelDefines.h"

@interface SearchViewController ()<UITextFieldDelegate,CLLocationManagerDelegate,MKMapViewDelegate> {
    BOOL keepDoneButtonON;
}

@property (weak, nonatomic) IBOutlet UILabel *radiusLabel;
@property (weak, nonatomic) IBOutlet M13Checkbox *tagsCk;
@property (weak, nonatomic) IBOutlet M13Checkbox *serviceNameCk;
@property (weak, nonatomic) IBOutlet M13Checkbox *descriptionCk;
@property (weak, nonatomic) IBOutlet M13Checkbox *addressCk;
@property (weak, nonatomic) IBOutlet UISearchBar *searchBar;
@property (weak, nonatomic) IBOutlet UISlider *radiusSlider;
@property (weak, nonatomic) IBOutlet UIButton *searchBarButton;
@property (weak, nonatomic) IBOutlet UISwitch *radiusSwitch;
@property (weak, nonatomic) IBOutlet UITextField *minTF;
@property (weak, nonatomic) IBOutlet UITextField *maxTF;
@property (weak, nonatomic) IBOutlet UIButton *doneNumberPadBT;

// Map & Location Properties
@property (nonatomic, strong) MKPointAnnotation *pin;
@property (nonatomic, strong) CLLocation *currentLocation;
@property (nonatomic, strong) CLLocationManager *locationManager;
@property (weak, nonatomic) IBOutlet MKMapView *mapView;

@end

@implementation SearchViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    
    // Initialize Checkboxes
    // Tags
    self.tagsCk.checkAlignment = M13CheckboxAlignmentLeft;
    self.tagsCk.titleLabel.text = @"Tags";
    self.tagsCk.titleLabel.font = [UIFont systemFontOfSize:15];
    self.tagsCk.checkState = M13CheckboxStateChecked;
    // ServiceName
    self.serviceNameCk.checkAlignment = M13CheckboxAlignmentLeft;
    self.serviceNameCk.titleLabel.text = @"Service Name";
    self.serviceNameCk.titleLabel.font = [UIFont systemFontOfSize:15];
    // Description
    self.descriptionCk.checkAlignment = M13CheckboxAlignmentLeft;
    self.descriptionCk.titleLabel.text = @"Description";
    self.descriptionCk.titleLabel.font = [UIFont systemFontOfSize:15];
    // Address
    self.addressCk.checkAlignment = M13CheckboxAlignmentLeft;
    self.addressCk.titleLabel.text = @"Address";
    self.addressCk.titleLabel.font = [UIFont systemFontOfSize:15];
    
    // Round Corners for picture
    self.searchBarButton.layer.cornerRadius = 10;
    self.searchBarButton.layer.masksToBounds = YES;
    
    // Round Corners for Done Button
    self.doneNumberPadBT.layer.cornerRadius = 10;
    self.doneNumberPadBT.layer.masksToBounds = YES;
    
    // Add gesture recognizer to dismiss Keyboard when map is tapped
    UITapGestureRecognizer *mapGestureRecognizer = [[UITapGestureRecognizer alloc]initWithTarget:self action:@selector(handleMapTapGesture:)];
    mapGestureRecognizer.numberOfTapsRequired = 1;
    mapGestureRecognizer.numberOfTouchesRequired = 1;
    [self.mapView addGestureRecognizer:mapGestureRecognizer];
    
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
    
    // Change Bar Tint Color
    self.navigationController.navigationBar.barTintColor = UIColorFromRGB(0x045A82);// Light Blue;
    self.navigationController.navigationBar.translucent = NO;
    
}

- (void)viewDidAppear:(BOOL)animated {
    
    [[NSNotificationCenter defaultCenter] addObserver:self
                                             selector:@selector(keyboardWillShow:)
                                                 name:UIKeyboardWillShowNotification
                                               object:nil];
    
    [[NSNotificationCenter defaultCenter] addObserver:self
                                             selector:@selector(keyboardWillHide:)
                                                 name:UIKeyboardWillHideNotification
                                               object:nil];
    
}

- (void)viewDidDisappear:(BOOL)animated {
    
    [[NSNotificationCenter defaultCenter] removeObserver:self
                                                    name:UIKeyboardWillShowNotification
                                                  object:nil];
    
    [[NSNotificationCenter defaultCenter] removeObserver:self
                                                    name:UIKeyboardWillHideNotification
                                                  object:nil];
    
}

- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

- (IBAction)rangeSliderChange:(UISlider *)sender {
    
    self.radiusLabel.text = [NSString stringWithFormat:@"%d km", (int)roundf(sender.value)];
    
    MKCoordinateRegion viewRegion = MKCoordinateRegionMakeWithDistance(self.pin.coordinate, (self.radiusSlider.value * 1000), (self.radiusSlider.value * 1000));
    MKCoordinateRegion adjustedRegion = [self.mapView regionThatFits:viewRegion];
    [self.mapView setRegion:adjustedRegion animated:YES];
    
}

- (IBAction)tagCheckChanged:(id)sender {
    NSLog(@"Tag Checkmark touched");
    
}

- (IBAction)searchPressed:(UIButton *)sender {
    [self searchBarSearchButtonClicked:self.searchBar];
}

- (IBAction)radiusSwitchPressed:(UISwitch *)sender {
    if(sender.isOn){
        self.minTF.text = [NSString stringWithFormat:@"%d", (int)roundf(self.radiusSlider.minimumValue)];
        self.maxTF.text = [NSString stringWithFormat:@"%d", (int)roundf(self.radiusSlider.maximumValue)];
        self.minTF.enabled = YES;
        self.maxTF.enabled = YES;
        self.radiusSlider.enabled = YES;
        self.radiusLabel.text = [NSString stringWithFormat:@"%d km", (int)roundf(self.radiusSlider.value)];
    } else {
        self.minTF.text = @"";
        self.maxTF.text = @"";
        self.minTF.enabled = NO;
        self.maxTF.enabled = NO;
        self.radiusSlider.enabled = NO;
        self.radiusLabel.text = @"None";
        
    }
}

- (IBAction)doneNumPadPressed:(UIButton *)sender {
    NSLog(@"Done Clicked.");
    // Flag end of editing.
    keepDoneButtonON = NO;
    
    [self.view endEditing:YES];
    
    // Ensure Max is not Less than Min
    if([self.maxTF.text intValue]<[self.minTF.text intValue]){
        self.maxTF.text = self.minTF.text;
    }
    
    // Set new values into Slider
    self.radiusSlider.minimumValue = [self.minTF.text integerValue];
    self.radiusSlider.maximumValue = [self.maxTF.text integerValue];
    
    // Calculate Mid point to set Slider in Middle
    float newValue = self.radiusSlider.maximumValue - self.radiusSlider.minimumValue;
    newValue = newValue / 2;
    newValue = self.radiusSlider.minimumValue + newValue;
    self.radiusSlider.value = (int)roundf(newValue);
    
    // Set Radius label to middle also
    self.radiusLabel.text = [NSString stringWithFormat:@"%d km", (int)roundf(self.radiusSlider.value)];
    
    
}

#pragma mark - Keyboard Methods Delegate
- (BOOL)textFieldShouldBeginEditing:(UITextField *)textField {
    if(textField == self.maxTF || textField == self.minTF)
        keepDoneButtonON = YES;
    else
        keepDoneButtonON = NO;
    
    return YES;
}
- (void)textFieldDidBeginEditing:(UITextField *)textField{
    
    if(textField == self.maxTF || textField == self.minTF){
        if(self.doneNumberPadBT.alpha != 1){
            // Shoe Button
            [UIView animateWithDuration:0.1 animations:^{
                self.radiusSlider.alpha = 0;
                self.radiusLabel.alpha = 0;
                self.doneNumberPadBT.alpha = 1;
            }completion:^(BOOL completed){
                self.radiusSlider.hidden = YES;
                self.radiusLabel.hidden = YES;
                self.doneNumberPadBT.hidden = NO;
            }];
        }
    }
}

- (BOOL)textFieldShouldEndEditing:(UITextField *)textField{
    
    if(textField == self.maxTF || textField == self.minTF){
        if(!keepDoneButtonON){
            // Shoe Button
            [UIView animateWithDuration:0.1 animations:^{
                self.radiusSlider.alpha = 1;
                self.radiusLabel.alpha = 1;
                self.doneNumberPadBT.alpha = 0;
            }completion:^(BOOL completed){
                self.radiusSlider.hidden = NO;
                self.radiusLabel.hidden = NO;
                self.doneNumberPadBT.hidden = YES;
            }];
        }
    }
    
    return YES;
}

- (BOOL)textField:(UITextField *)textField shouldChangeCharactersInRange:(NSRange)range replacementString:(NSString *)string {
    int number = [[textField.text stringByAppendingString:string] intValue];
    NSString *formedString = [textField.text stringByAppendingString:string];
    
    // Min Textfield
    if(textField == self.minTF){
        if([formedString length] > 1) {
            if([formedString hasPrefix:@"0"]){
                number = 0;
                textField.text = [NSString stringWithFormat:@"%d", number];
                return NO;
            }
        }
        
        if(number > 100) {
            number = 100;
            textField.text = [NSString stringWithFormat:@"%d", number];
            return NO;
        }
    }
    
    // Max Textfield
    if(textField == self.maxTF){
        if([formedString length] > 4) {
            number = 9999;
            textField.text = [NSString stringWithFormat:@"%d", number];
            return NO;
        }
        
        if([formedString hasPrefix:@"0"]){
            textField.text = @"";
            return NO;
        }
    }
    
    
    return YES;
}

#pragma mark UISearchBarDelegate
- (void) searchBarTextDidBeginEditing:(UISearchBar *)searchBar
{
    [searchBar setShowsCancelButton:YES animated:YES];
}

- (void)searchBarSearchButtonClicked:(UISearchBar *)searchBar
{
    // Tells the postManager to reset the tag string with the new tag string
    [self.delegate searchPressedwithTags:self.searchBar.text andSections:[self collectSections] andRange:[self getRange]];
    [searchBar setShowsCancelButton:NO animated:YES];
    [searchBar resignFirstResponder];
}

- (void) searchBarCancelButtonClicked:(UISearchBar *)searchBar
{
    searchBar.text = @"";
    searchBar.showsCancelButton = NO;
    [searchBar resignFirstResponder];
}

- (NSArray *)collectSections {
    NSMutableArray *sectionsArray = [[NSMutableArray alloc]init];
    
    if(self.tagsCk.checkState == M13CheckboxStateChecked){
        [sectionsArray addObject:@"tags"];
    }
    if(self.serviceNameCk.checkState == M13CheckboxStateChecked){
        [sectionsArray addObject:@"serviceName"];
    }
    if(self.descriptionCk.checkState == M13CheckboxStateChecked){
        [sectionsArray addObject:@"description"];
    }
    if(self.addressCk.checkState == M13CheckboxStateChecked){
        [sectionsArray addObject:@"address"];
    }
    
    // Add Location to Sections Array to perform search
    [sectionsArray addObject:@"location"];
    
    
    return sectionsArray;
}

-(NSInteger)getRange {
    NSInteger range = (NSInteger)roundf(self.radiusSlider.value);
    
    return range;
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
        
        MKCoordinateRegion viewRegion = MKCoordinateRegionMakeWithDistance(self.pin.coordinate, (self.radiusSlider.value * 1000), (self.radiusSlider.value * 1000));
        MKCoordinateRegion adjustedRegion = [self.mapView regionThatFits:viewRegion];
        [self.mapView setRegion:adjustedRegion animated:YES];
        
        [self.mapView addAnnotation:self.pin];
        [self.mapView showAnnotations:@[self.pin] animated:NO];
        
        [self.locationManager stopUpdatingLocation];
        
    } else {
        self.pin.coordinate = self.currentLocation.coordinate;
        
        MKCoordinateRegion viewRegion = MKCoordinateRegionMakeWithDistance(self.pin.coordinate, (self.radiusSlider.value * 1000), (self.radiusSlider.value * 1000));
        MKCoordinateRegion adjustedRegion = [self.mapView regionThatFits:viewRegion];
        [self.mapView setRegion:adjustedRegion animated:YES];
        
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
}

- (void)retryLocationUpdate {
    NSLog(@"kCLErrorDomain");
}

- (void)otherLocationError {
    NSLog(@"Other Location Errors");
}

#pragma mark - Map View Delegate
- (MKAnnotationView *)mapView:(MKMapView *)mapView viewForAnnotation:(id<MKAnnotation>)annotation {
    MKPinAnnotationView *view = [[MKPinAnnotationView alloc] initWithAnnotation:annotation reuseIdentifier:@""];
    
    view.draggable = YES;
    
    return view;
}

#pragma mark - Gestures
- (void)handleMapTapGesture:(UIGestureRecognizer *)gestureRecognizer
{
    if (gestureRecognizer.state == UIGestureRecognizerStateEnded)
        [self.view endEditing:YES];
}


@end
