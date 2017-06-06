//  AddServiceViewController.m
//  SerBees

@import MapKit;
@import MobileCoreServices;
@import CoreLocation;
#import "AddServiceViewController.h"
#import "CTCheckbox.h"
#import "GlobalDefines.h"
#import "DataModelDefines.h"
#import "ServicePost.h"
#import "ServiceImage.h"

typedef NS_ENUM(NSInteger, SubmissionErrorResponse) {
    SubmissionErrorIgnore,
    SubmissionErrorRetry,
    SubmissionErrorSuccess,
};

@interface AddServiceViewController ()<MKMapViewDelegate, UITextViewDelegate, UITextFieldDelegate, UIImagePickerControllerDelegate, UINavigationControllerDelegate, CLLocationManagerDelegate>{
    CGFloat assetWidth, mapWidth;
    BOOL loadingFinished;
}
@property (weak, nonatomic) IBOutlet UILabel *serviceDescriptionLabel;
@property (weak, nonatomic) IBOutlet UIButton *cancelButton;
@property (weak, nonatomic) IBOutlet UIButton *doneButton;
@property (weak, nonatomic) IBOutlet UIButton *assetBT;
@property (weak, nonatomic) IBOutlet UITextField *serviceNameTF;
@property (weak, nonatomic) IBOutlet UITextField *contactTF;
@property (weak, nonatomic) IBOutlet UITextField *phoneTF;
@property (weak, nonatomic) IBOutlet UITextField *emailTF;
@property (weak, nonatomic) IBOutlet UITextField *websiteTF;
@property (weak, nonatomic) IBOutlet UITextView *descriptionTV;
@property (weak, nonatomic) IBOutlet CTCheckbox *showLocationCB;
@property (weak, nonatomic) IBOutlet UILabel *showLocationLB;
@property (weak, nonatomic) IBOutlet MKMapView *mapView;
@property (weak, nonatomic) IBOutlet UIScrollView *scrollView;
@property (weak, nonatomic) IBOutlet UIProgressView *progressBar;
@property (weak, nonatomic) IBOutlet UITextField *address1TF;
@property (weak, nonatomic) IBOutlet UITextField *address2TF;
@property (weak, nonatomic) IBOutlet UIActivityIndicatorView *saveActivityIndicator;

//Tags vies
@property (weak, nonatomic) IBOutlet UILabel *tagsLabel;
@property (weak, nonatomic) IBOutlet UITextView *tagsTV;

// Range View, Units and TextField ; and stepper
@property (weak, nonatomic) IBOutlet UIView *rangeView;
@property (weak, nonatomic) IBOutlet UITextField *rangeTF;
@property (weak, nonatomic) IBOutlet UILabel *rangeUnitsLB;
@property (weak, nonatomic) IBOutlet UIStepper *rangeStepper;

// Constraints
@property (weak, nonatomic) IBOutlet NSLayoutConstraint *assetWidthConstraint;
@property (weak, nonatomic) IBOutlet NSLayoutConstraint *mapWidthConstraint;
@property (weak, nonatomic) IBOutlet NSLayoutConstraint *assetHeightConstraint;

// Map & Location Properties
@property (nonatomic, strong) MKPointAnnotation *pin;
@property (nonatomic, strong) CLLocation *currentLocation;
@property (nonatomic, strong) CLLocationManager *locationManager;

@property (nonatomic,strong) ServiceImage *imageRecord;

@property (strong, nonatomic) id activeTextField;
@end

@implementation AddServiceViewController

#pragma mark - View Life Cycle Methods
- (void)viewDidLoad {
    [super viewDidLoad];
    
    // Add gesture recognizer to dismiss Keyboard when map is tapped
    UITapGestureRecognizer *mapGestureRecognizer = [[UITapGestureRecognizer alloc]initWithTarget:self action:@selector(handleMapTapGesture:)];
    mapGestureRecognizer.numberOfTapsRequired = 1;
    mapGestureRecognizer.numberOfTouchesRequired = 1;
    [self.mapView addGestureRecognizer:mapGestureRecognizer];
    
    // DismissMode for Keyboard - Dissmiss when scroll view is dragged.
    self.scrollView.keyboardDismissMode = UIScrollViewKeyboardDismissModeOnDrag;
    
    // Setup CheckBox target and color
    self.showLocationCB.checked = YES;
    [self.showLocationCB addTarget:self action:@selector(checkboxDidChange:) forControlEvents:UIControlEventValueChanged];
    [self.showLocationCB setCheckboxColor:[UIColor colorWithRed:RGB_GRAY green:RGB_GRAY blue:RGB_GRAY alpha:1.0]];
    [self checkboxDidChange:self.showLocationCB];
    
    // Set Shadow for range view
    self.rangeView.layer.shadowColor = [UIColor blackColor].CGColor;
    self.rangeView.layer.shadowRadius = 5.f;
    self.rangeView.layer.shadowOffset = CGSizeMake(0.f, 3.f);
    self.rangeView.layer.shadowOpacity = 1.f;
    self.rangeView.layer.masksToBounds = NO;
    
    // Verifiy if it is Edit or New
    if(self.currentService != nil){
        loadingFinished = NO;
        [self populateService];
    } else {
        loadingFinished = YES;
    }
    
}

- (void)viewDidAppear:(BOOL)animated {
    
    [[NSNotificationCenter defaultCenter] addObserver:self
                                             selector:@selector(keyboardWillShow:)
                                                 name:UIKeyboardWillShowNotification
                                               object:nil];
    
    [[NSNotificationCenter defaultCenter] addObserver:self
                                             selector:@selector(keyboardDidShow:)
                                                 name:UIKeyboardDidShowNotification
                                               object:nil];
    
    [[NSNotificationCenter defaultCenter] addObserver:self
                                             selector:@selector(keyboardWillHide:)
                                                 name:UIKeyboardWillHideNotification
                                               object:nil];
    
    [[NSNotificationCenter defaultCenter] addObserver:self
                                             selector:@selector(keyboardDidHide:)
                                                 name:UIKeyboardDidHideNotification
                                               object:nil];
    // Verifiy if it is Edit or New
    if(loadingFinished == NO){
        [self populateImage];
    }
}

- (void)viewDidDisappear:(BOOL)animated {
    
    [[NSNotificationCenter defaultCenter] removeObserver:self
                                                    name:UIKeyboardWillShowNotification
                                                  object:nil];
    
    [[NSNotificationCenter defaultCenter] removeObserver:self
                                                    name:UIKeyboardWillHideNotification
                                                  object:nil];
    
    [[NSNotificationCenter defaultCenter] removeObserver:self
                                                    name:UIKeyboardDidShowNotification
                                                  object:nil];
    
    [[NSNotificationCenter defaultCenter] removeObserver:self
                                                    name:UIKeyboardDidHideNotification
                                                  object:nil];
    
}

#pragma mark - Keyboard Notifications
- (void)keyboardWillShow:(NSNotification *)notification {
    
}

- (void)keyboardDidShow:(NSNotification *)notification {
    
    NSDictionary* info = [notification userInfo];
    CGSize kbSize = [[info objectForKey:UIKeyboardFrameBeginUserInfoKey] CGRectValue].size;
    
    UIEdgeInsets contentInsets = UIEdgeInsetsMake(0.0, 0.0, kbSize.height, 0.0);
    self.scrollView.contentInset = contentInsets;
    self.scrollView.scrollIndicatorInsets = contentInsets;
    
    // If active text field is hidden by keyboard, scroll it so it's visible
    // Your app might not need or want this behavior.
    CGRect aRect = self.view.frame;
    aRect.size.height -= kbSize.height + KEYBOARD_PADDING;
    
    // Verify if object is TextView or TextField
    if([self.activeTextField isKindOfClass:([UITextField class])]){
        UITextField *activeText = (UITextField *)self.activeTextField;
        if (!CGRectContainsPoint(aRect,activeText.frame.origin) ) {
            CGRect textRect = activeText.frame;
            textRect.size.height -= NAV_BAR_HEIGHT;
            [self.scrollView scrollRectToVisible:textRect animated:YES];
        }
    } else if([self.activeTextField isKindOfClass:([UITextView class])]){
        UITextView *activeText = (UITextView *)self.activeTextField;
        if (!CGRectContainsPoint(aRect,activeText.frame.origin) ) {
            CGRect textRect = activeText.frame;
            textRect.size.height -= NAV_BAR_HEIGHT;
            [self.scrollView scrollRectToVisible:textRect animated:YES];
        }
    }
}

- (void)keyboardWillHide:(NSNotification *)notification {
    [self.scrollView setContentOffset:CGPointZero animated:YES];
}

- (void)keyboardDidHide:(NSNotification *)notification {
}


#pragma mark - UITextView Delegate Methods
- (BOOL)textViewShouldBeginEditing:(UITextView *)textView {
    // assign textfied to property
    self.activeTextField = textView;
    
    return YES;
}

- (void)textViewDidBeginEditing:(UITextView *)textView {
    // Disable Cancel Button
    self.cancelButton.hidden = YES;
    
    // Change TextView Text Color
    textView.textColor = [UIColor blackColor];
    
    // Animate Enlarge of fields.
    [UIView beginAnimations:@"assetButton Grow" context:NULL];
    [UIView setAnimationDuration:SHRINK_ASSET_TIME];
    [UIView setAnimationCurve:UIViewAnimationCurveEaseInOut];
    [UIView setAnimationBeginsFromCurrentState:YES];
    
    // Shrink Map Width - Increase Asset Width and shrink Height
    self.mapWidthConstraint.constant = REDUCED_MAP_WIDTH;
    
    self.assetWidthConstraint.constant = INCREASED_ASSET_WIDTH;
    self.assetHeightConstraint.constant = REDUCED_ASSET_HEIGHT;
    
    // Hide Location range controls and labels
    self.showLocationCB.alpha = MIN_ALPHA;
    self.showLocationLB.alpha = MIN_ALPHA;
    
    [self.view layoutIfNeeded];
    
    [UIView commitAnimations];
    
    // Change "Done" to "Resume"
    [self.doneButton setTitle:@"Resume" forState:UIControlStateNormal];
    
    // Hide Asset Button
    self.assetBT.hidden = YES;
    
    // Hide Range View and Stepper
    self.rangeView.hidden = YES;
    self.rangeStepper.hidden = YES;
}

- (void)textViewDidEndEditing:(UITextView *)textView {
    //Clear active field
    //self.activeTextField = nil;
    
    // Hide Cancel Button
    self.cancelButton.hidden = NO;
    
    if(textView == self.descriptionTV){
        // Return Grey color if not text was written
        if([textView.text isEqualToString:@""]){
            self.serviceDescriptionLabel.hidden = NO;
        } else{
            self.serviceDescriptionLabel.hidden = YES;
        }
    } else {
        // Return Grey color if not text was written
        if([textView.text isEqualToString:@""]){
            self.tagsLabel.hidden = NO;
        } else{
            self.tagsLabel.hidden = YES;
        }
    }
    
    // Animate Enlarge of fields.
    [UIView beginAnimations:@"assetButton Shrink" context:NULL];
    [UIView setAnimationDuration:SHRINK_ASSET_TIME];
    [UIView setAnimationCurve:UIViewAnimationCurveEaseInOut];
    [UIView setAnimationBeginsFromCurrentState:YES];
    
    // Shrink Asset
    self.mapWidthConstraint.constant = MAX_WIDTH;
    self.assetHeightConstraint.constant = MAX_WIDTH;
    
    // Hide Range Controls and Labels
    self.showLocationCB.alpha = MAX_ALPHA;
    self.showLocationLB.alpha = MAX_ALPHA;
    
    [self.view layoutIfNeeded];
    
    [UIView commitAnimations];
    
    // Change button title to Done
    if(self.currentService == nil)
        [self.doneButton setTitle:@"Done" forState:UIControlStateNormal];
    else
        [self.doneButton setTitle:@"Update" forState:UIControlStateNormal];
    
    // Show Asset Button
    self.assetBT.hidden = NO;
    
    // Show Range View and Stepper
    self.rangeView.hidden = NO;
    self.rangeStepper.hidden = NO;
}

- (void)textViewDidChange:(UITextView *)textView {
    if(textView == self.descriptionTV)
        self.serviceDescriptionLabel.hidden = YES;
    else
        self.tagsLabel.hidden = YES;
}

#pragma mark - UITextField Delegate Methods
- (BOOL)textFieldShouldBeginEditing:(UITextField *)textField {
    
    return YES;
}

- (void)textFieldDidBeginEditing:(UITextField *)textField{
    // Assign selected field to property
    self.activeTextField = textField;
    
    // Disable Cancel Button
    self.cancelButton.hidden = YES;
    
    // Animate Enlarge of fields.
    [UIView beginAnimations:@"assetButton Shrink" context:NULL];
    [UIView setAnimationDuration:SHRINK_ASSET_TIME];
    [UIView setAnimationCurve:UIViewAnimationCurveEaseInOut];
    [UIView setAnimationBeginsFromCurrentState:YES];
    
    // Shrink Asset
    self.assetWidthConstraint.constant = REDUCED_ASSET_WIDTH;
    self.mapWidthConstraint.constant = INCREASED_MAP_WIDTH;
    
    // Hide Service Description Label on Text View
    self.serviceDescriptionLabel.alpha = MIN_ALPHA;
    
    [self.view layoutIfNeeded];
    
    [UIView commitAnimations];
    
    // Change "Done" to "Resume"
    [self.doneButton setTitle:@"Resume" forState:UIControlStateNormal];
    
    // Hide Asset Button
    self.assetBT.hidden = YES;
    
    // Hide Description TextView
    self.descriptionTV.hidden = YES;
}

- (BOOL)textFieldShouldEndEditing:(UITextField *)textField {
    
    return YES;
}

- (void)textFieldDidEndEditing:(UITextField *)textField {
    // remove textfield from property
    //self.activeTextField = nil;
    
    // Enable Cancel Button
    self.cancelButton.hidden = NO;
    
    // Animate Enlarge of fields.
    [UIView beginAnimations:@"assetButton Shrink" context:NULL];
    [UIView setAnimationDuration:SHRINK_ASSET_TIME];
    [UIView setAnimationCurve:UIViewAnimationCurveEaseInOut];
    [UIView setAnimationBeginsFromCurrentState:YES];
    
    // Shrink Asset
    self.assetWidthConstraint.constant = MAX_WIDTH;
    self.mapWidthConstraint.constant = MAX_WIDTH;
    
    // Show Service Description Label on Text View
    self.serviceDescriptionLabel.alpha = MAX_ALPHA;
    
    [self.view layoutIfNeeded];
    
    [UIView commitAnimations];
    
    // Change button title to Done
    if(self.currentService == nil)
        [self.doneButton setTitle:@"Done" forState:UIControlStateNormal];
    else
        [self.doneButton setTitle:@"Update" forState:UIControlStateNormal];
    
    // Show Asset Button
    self.assetBT.hidden = NO;
    
    // Show Description TextView
    self.descriptionTV.hidden = NO;
}

- (BOOL)textField:(UITextField *)textField shouldChangeCharactersInRange:(NSRange)range replacementString:(NSString *)string
{
    if(textField.tag == PHONE_TEXTFIELD_TAG) {
        NSString *newString = [textField.text stringByReplacingCharactersInRange:range withString:string];
        NSArray *components = [newString componentsSeparatedByCharactersInSet:[[NSCharacterSet decimalDigitCharacterSet] invertedSet]];
        NSString *decimalString = [components componentsJoinedByString:@""];
        
        NSUInteger length = decimalString.length;
        BOOL hasLeadingOne = length > 0 && [decimalString characterAtIndex:0] == '1';
        
        if (length == 0 || (length > 10 && !hasLeadingOne) || (length > 11)) {
            textField.text = decimalString;
            return NO;
        }
        
        NSUInteger index = 0;
        NSMutableString *formattedString = [NSMutableString string];
        
        if (hasLeadingOne) {
            [formattedString appendString:@"1 "];
            index += 1;
        }
        
        if (length - index > 3) {
            NSString *areaCode = [decimalString substringWithRange:NSMakeRange(index, 3)];
            [formattedString appendFormat:@"(%@) ",areaCode];
            index += 3;
        }
        
        if (length - index > 3) {
            NSString *prefix = [decimalString substringWithRange:NSMakeRange(index, 3)];
            [formattedString appendFormat:@"%@-",prefix];
            index += 3;
        }
        
        NSString *remainder = [decimalString substringFromIndex:index];
        [formattedString appendString:remainder];
        
        textField.text = formattedString;
        
        return NO;
    }
    return YES;
}

#pragma mark - Custom Methods
- (void)populateImage{
    
    // Set Button picture
    CGFloat assetButtonSize = self.assetBT.frame.size.height;
    
    CGImageRef CGRawImage = self.currentService.imageRecord.fullImage.CGImage;
    CGImageRef cropped = NULL;
    if(CGImageGetHeight(CGRawImage) > CGImageGetWidth(CGRawImage))
    {
        // Crops from top and bottom evenly
        size_t maxDimen = CGImageGetWidth(CGRawImage);
        size_t offset = (CGImageGetHeight(CGRawImage) - CGImageGetWidth(CGRawImage)) / 2;
        cropped = CGImageCreateWithImageInRect(self.currentService.imageRecord.fullImage.CGImage, CGRectMake(0, offset, maxDimen, maxDimen));
    }
    else if(CGImageGetHeight(CGRawImage) <= CGImageGetWidth(CGRawImage))
    {
        // Crops from left and right evenly
        size_t maxDimen = CGImageGetHeight(CGRawImage);
        size_t offset = (CGImageGetWidth(CGRawImage) - CGImageGetHeight(CGRawImage)) / 2;
        cropped = CGImageCreateWithImageInRect(self.currentService.imageRecord.fullImage.CGImage, CGRectMake(offset, 0, maxDimen, maxDimen));
    }
    
    // Resizes thumbnail for asset button depending on device zise and then saves to different temp file
    UIGraphicsBeginImageContext(CGSizeMake(assetButtonSize, assetButtonSize));
    [[UIImage imageWithCGImage:cropped scale:self.currentService.imageRecord.fullImage.scale orientation:self.currentService.imageRecord.fullImage.imageOrientation] drawInRect:CGRectMake(0,0,assetButtonSize,assetButtonSize)];
    UIImage *assetThumbImage = UIGraphicsGetImageFromCurrentImageContext();
    UIGraphicsEndImageContext();
    NSString *path = [NSTemporaryDirectory() stringByAppendingString:@"toAssetThumb.tmp"];
    NSData *imageData = UIImageJPEGRepresentation(assetThumbImage,0.5);
    [imageData writeToFile:path atomically:YES];
    NSURL *assetThumbURL = [NSURL fileURLWithPath:path];
    
    NSData *assetImageData = [NSData dataWithContentsOfURL:assetThumbURL];
    UIImage *assetThumb = [[UIImage alloc] initWithData:assetImageData];
    
    
    self.imageRecord = self.currentService.imageRecord;
    [self.assetBT setTitle:@"" forState:UIControlStateNormal];
    [self.assetBT setBackgroundImage:assetThumb forState:UIControlStateNormal];
    
    // Flag to mark that loading was completed
    loadingFinished = YES;
    
}

- (void)populateService {
    
    self.serviceNameTF.text = self.currentService.postRecord[ServiceNameKey];
    self.contactTF.text = self.currentService.postRecord[ServiceContactKey];
    self.descriptionTV.text = self.currentService.postRecord[ServiceDescriptionKey];
    if([self.descriptionTV.text isEqualToString:@""] || [self.descriptionTV.text isEqualToString:@" "]){
        self.serviceDescriptionLabel.hidden = NO;
    } else {
        self.serviceDescriptionLabel.hidden = YES;
    }
    
    NSArray *tagArray = [[NSArray alloc]initWithArray:self.currentService.postRecord[ServiceTagsKey]];
    NSString *tagString = @"";
    
    for (NSString *tag in tagArray) {
        if([tagString isEqualToString:@""]){
            tagString = tag;
        } else {
            tagString = [tagString stringByAppendingString:[@" " stringByAppendingString:tag]];
        }
    }
    
    if ([tagString isEqualToString:@""] || [tagString isEqualToString:@" "]){
        self.tagsLabel.hidden = NO;
    } else {
        self.tagsLabel.hidden = YES;
        self.tagsTV.text = tagString;
    }
    
    self.phoneTF.text = self.currentService.postRecord[ServicePhoneKey];
    self.emailTF.text = self.currentService.postRecord[ServiceEmailKey];
    self.address1TF.text = self.currentService.postRecord[ServiceAddress1Key];
    self.address2TF.text = self.currentService.postRecord[ServiceAddress2Key];
    self.websiteTF.text = self.currentService.postRecord[ServiceWebsiteKey];
    
    /*/ Location
     self.showLocationCB.checked = YES;
     CLLocation *currentLocation = self.currentService.postRecord[ServiceLocationKey];
     CLLocationCoordinate2D newLoc = CLLocationCoordinate2DMake(currentLocation.coordinate.latitude, currentLocation.coordinate.longitude);
     [self.pin setCoordinate:newLoc];
     */
    self.pin = nil;
    
    // Change "Done" to "Resume"
    [self.doneButton setTitle:@"Update" forState:UIControlStateNormal];
}

- (void)checkboxDidChange:(CTCheckbox *)checkbox
{
    if(checkbox.checked){
        [self.showLocationCB setCheckboxColor:[UIColor blackColor]];
        self.showLocationLB.textColor = [UIColor blackColor];
        self.rangeStepper.hidden = NO;
        self.rangeView.hidden = NO;
        self.rangeTF.text = [NSString stringWithFormat:@"%.0lf", self.rangeStepper.value];
        
        // Set Map Delegate
        self.mapView.delegate = self;
        
        if(self.currentService != nil){
            //Initialize Location Manager
            self.locationManager = [[CLLocationManager alloc] init];
            self.locationManager.distanceFilter = kCLDistanceFilterNone;
            self.locationManager.desiredAccuracy = kCLLocationAccuracyBest;
            self.locationManager.delegate = self;
            
            if ([self.locationManager respondsToSelector:@selector(requestAlwaysAuthorization)]) {
                [self.locationManager requestAlwaysAuthorization];
            }
        }
    } else {
        self.rangeStepper.hidden = YES;
        [self.showLocationCB setCheckboxColor:[UIColor colorWithRed:RGB_GRAY green:RGB_GRAY blue:RGB_GRAY alpha:1.0]];
        self.rangeView.hidden = YES;
        [self.mapView removeAnnotation:self.pin];
        self.pin = nil;
    }
}

- (void)retryLocationUpdate {
    NSLog(@"kCLErrorDomain");
}

- (void)otherLocationError {
    NSLog(@"Other Location Errors");
}

#pragma mark - Gestures
- (void)handleMapTapGesture:(UIGestureRecognizer *)gestureRecognizer
{
    if (gestureRecognizer.state == UIGestureRecognizerStateEnded)
        [self.activeTextField resignFirstResponder];
}

#pragma mark - IBActions
- (IBAction)cancelPressed:(id)sender {
    NSLog(@"Cancel Pressed");
    [self.activeTextField resignFirstResponder];
    [self.delegate dismissRequestedByChildViewController];
}

- (IBAction)donePressed:(id)sender {
    
    NSLog(@"Done Pressed");
    if([self.doneButton.titleLabel.text isEqualToString:@"Resume"])
        [self.activeTextField resignFirstResponder];
    else {
        [self saveData:sender];
    }
}

- (void)saveData:(id)sender {
    
    if([self.assetBT backgroundImageForState:UIControlStateNormal] == nil || [self.serviceNameTF.text isEqualToString:@""]){
        
        ProgessHUD = [[MBProgressHUD alloc] initWithView:self.view];
        [self.view addSubview:ProgessHUD];
        ProgessHUD.customView = [[UIImageView alloc] initWithImage:[UIImage imageNamed:@"warning"]];
        
        // Set custom view mode
        ProgessHUD.mode = MBProgressHUDModeCustomView;
        
        ProgessHUD.delegate = self;
        ProgessHUD.detailsLabelText = @"is required";
        
        if([self.assetBT backgroundImageForState:UIControlStateNormal] == nil){
            ProgessHUD.labelText = @"The Service 'Image'";
        }
        if([self.serviceNameTF.text isEqualToString:@""]){
            ProgessHUD.labelText = @"The 'Service Name' field";
        }
        if([self.serviceNameTF.text isEqualToString:@""] && [self.assetBT backgroundImageForState:UIControlStateNormal] == nil){
            ProgessHUD.labelText = @"The Image and 'Service Name' field";
            ProgessHUD.detailsLabelText = @"are required";
        }
        ProgessHUD.square = YES;
        
        [ProgessHUD show:YES];
        [ProgessHUD hide:YES afterDelay:2];
        
        return;
        
    }
    
    // Hide Done Button
    self.doneButton.hidden = YES;
    
    // Prevents multiple posting, locks as soon as a post is made
    [self.saveActivityIndicator startAnimating];
    
    // Hides the keyboards and dispatches a UI update to show the upload progress
    self.progressBar.hidden = NO;
    NSArray *recordsToSave;
    ServicePost *newPost;
    
    if(self.currentService == nil){
        
        // Creates post record type and initizalizes all of its values
        CKRecord *newRecord = [[CKRecord alloc] initWithRecordType:ServiceRecordType];
        newRecord[ServiceImageKey] = [[CKReference alloc] initWithRecordID:self.imageRecord.record.recordID action:CKReferenceActionDeleteSelf];
        newRecord[ServiceDescriptionKey] = self.descriptionTV.text;
        newRecord[ServiceDescriptionTagsKey] = [self.descriptionTV.text.lowercaseString componentsSeparatedByString:@" "];
        newRecord[ServiceTagsKey] = [self.tagsTV.text.lowercaseString componentsSeparatedByString:@" "];
        if([self.serviceNameTF.text isEqualToString:@""] || (self.serviceNameTF == nil))
            return;
        newRecord[ServiceNameKey] = self.serviceNameTF.text;
        newRecord[ServiceNameTagsKey] = [self.serviceNameTF.text.lowercaseString componentsSeparatedByString:@" "];
        newRecord[ServiceContactKey] = self.contactTF.text;
        newRecord[ServicePhoneKey] = self.phoneTF.text;
        newRecord[ServiceEmailKey] = self.emailTF.text;
        NSString *combinedAddress = [self.address1TF.text stringByAppendingString:[@" " stringByAppendingString:self.address2TF.text]];
        newRecord[ServiceAddressTagsKey] = [combinedAddress.lowercaseString componentsSeparatedByString:@" "];
        newRecord[ServiceAddress1Key] = self.address1TF.text;
        newRecord[ServiceAddress2Key] = self.address2TF.text;
        newRecord[ServiceLocationKey] = [[CLLocation alloc] initWithLatitude:self.pin.coordinate.latitude longitude:self.pin.coordinate.longitude];
        newRecord[ServiceWebsiteKey] = self.websiteTF.text;
        
        newPost = [[ServicePost alloc] initWithRecord:newRecord];
        newPost.imageRecord = self.imageRecord;
        
        // Only upload image record if it is not on server, otherwise just upload the new post record
        recordsToSave = self.imageRecord.isOnServer ? @[newRecord] : @[newRecord, self.imageRecord.record];
        
    } else {
        
        // Creates post record type and initizalizes all of its values
        self.currentService.postRecord[ServiceImageKey] = [[CKReference alloc] initWithRecordID:self.imageRecord.record.recordID action:CKReferenceActionDeleteSelf];
        self.currentService.postRecord[ServiceDescriptionKey] = self.descriptionTV.text;
        self.currentService.postRecord[ServiceDescriptionTagsKey] = [self.descriptionTV.text.lowercaseString componentsSeparatedByString:@" "];
        self.currentService.postRecord[ServiceTagsKey] = [self.tagsTV.text.lowercaseString componentsSeparatedByString:@" "];
        if([self.serviceNameTF.text isEqualToString:@""] || (self.serviceNameTF == nil))
            return;
        self.currentService.postRecord[ServiceNameKey] = self.serviceNameTF.text;
        self.currentService.postRecord[ServiceNameTagsKey] = [self.serviceNameTF.text.lowercaseString componentsSeparatedByString:@" "];
        self.currentService.postRecord[ServiceContactKey] = self.contactTF.text;
        self.currentService.postRecord[ServicePhoneKey] = self.phoneTF.text;
        self.currentService.postRecord[ServiceEmailKey] = self.emailTF.text;
        NSString *combinedAddress = [self.address1TF.text stringByAppendingString:[@" " stringByAppendingString:self.address2TF.text]];
        self.currentService.postRecord[ServiceAddressTagsKey] = [combinedAddress.lowercaseString componentsSeparatedByString:@" "];
        self.currentService.postRecord[ServiceAddress1Key] = self.address1TF.text;
        self.currentService.postRecord[ServiceAddress2Key] = self.address2TF.text;
        self.currentService.postRecord[ServiceLocationKey] = [[CLLocation alloc] initWithLatitude:self.pin.coordinate.latitude longitude:self.pin.coordinate.longitude];
        self.currentService.postRecord[ServiceWebsiteKey] = self.websiteTF.text;
        
        self.currentService.imageRecord = self.imageRecord;
        
        // Only upload image record if it is not on server, otherwise just upload the new post record
        recordsToSave = self.imageRecord.isOnServer ? @[self.currentService.postRecord] : @[self.currentService.postRecord, self.imageRecord.record];
        
        newPost = self.currentService;
    }
    
    
    CKModifyRecordsOperation *saveOp = [[CKModifyRecordsOperation alloc] initWithRecordsToSave:recordsToSave recordIDsToDelete:nil];
    saveOp.savePolicy = CKRecordSaveChangedKeys;
    saveOp.perRecordProgressBlock = ^(CKRecord *record, double progress)
    {
        // Image record type is probably going to take the longest to upload. Reflect it's progress in the progress bar
        if([record.recordType isEqual:ServiceRecordType])
        {
            dispatch_async(dispatch_get_main_queue(), ^{
                [self.progressBar setProgress:progress*0.95 animated:YES];
            });
        }
    };
    
    // When completed it notifies the tableView to add the post we just uploaded, displays error if it didn't work
    saveOp.modifyRecordsCompletionBlock = ^(NSArray *savedRecords, NSArray *deletedRecordIDs, NSError *operationError){
        SubmissionErrorResponse errorResponse = [self handleError:operationError];
        if(errorResponse == SubmissionErrorSuccess)
        {
            //[self dismissViewControllerAnimated:YES completion:nil];
            [self dismissViewControllerAnimated:YES completion:^{
                [self.delegate dismissRequestedByChildViewController];
            }];
            // Tells delegate to update so it can display our new post
            if([self.delegate respondsToSelector:@selector(AddServiceViewController:postedRecord:)])
            {
                dispatch_async(dispatch_get_main_queue(), ^{
                    [self.delegate AddServiceViewController:self postedRecord:newPost];
                });
            }
        }
        else if(errorResponse == SubmissionErrorRetry)
        {
            NSNumber *retryAfter = operationError.userInfo[CKErrorRetryAfterKey] ?: @3;
            NSLog(@"Error: %@. Recoverable, retry after %@ seconds", [operationError description], retryAfter);
            dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(retryAfter.intValue * NSEC_PER_SEC)), dispatch_get_main_queue(), ^{
                [self donePressed:sender];
            });
        }
        else if(errorResponse == SubmissionErrorIgnore)
        {
            NSLog(@"Error saving record: %@", [operationError description]);
            
            NSString *errorTitle = NSLocalizedString(@"ErrorTitle", @"Title of alert notifying of error");
            NSString *dismissButton = NSLocalizedString(@"DismissError", @"Alert dismiss button string");
            NSString *errorMessage;
            if([operationError code] == CKErrorNotAuthenticated) errorMessage = NSLocalizedString(@"NotAuthenticatedErrorMessage", @"Error message, not logged in");
            else errorMessage = NSLocalizedString(@"UploadFailedErrorMessage", @"Non recoverable upload failed error");
            
            UIAlertController *alert = [UIAlertController alertControllerWithTitle:errorTitle message:errorMessage preferredStyle:UIAlertControllerStyleAlert];
            [alert addAction:[UIAlertAction actionWithTitle:dismissButton style:UIAlertActionStyleCancel handler:nil]];
            
            [self.doneButton addTarget:self action:@selector(donePressed:) forControlEvents:UIControlEventTouchUpInside];
            
            dispatch_async(dispatch_get_main_queue(), ^{
                [self presentViewController:alert animated:YES completion:nil];
                self.progressBar.hidden = YES;
            });
        }
    };
    [[CKContainer defaultContainer].publicCloudDatabase addOperation:saveOp];
}

- (IBAction)assetPressed:(id)sender {
    NSLog(@"Asset Pressed.");
    [self.activeTextField resignFirstResponder];
    
    NSString *alertTitle = NSLocalizedString(@"ComposeAlertControllerTitle", @"Title of alert controller that lets user compose a post");
    NSString *takeAssetButton = NSLocalizedString(@"CameraButton", @"Title for button opens up camera to take photo");
    NSString *uploadButton = NSLocalizedString(@"UploadButton", @"Title for button that opens photo library to select photo");
    
    // Shows the user options for selecting an image to post
    UIAlertController *assetMethod = [UIAlertController alertControllerWithTitle:alertTitle message:nil preferredStyle:UIAlertControllerStyleActionSheet];
    assetMethod.modalPresentationStyle = UIModalPresentationPopover;
    UIPopoverPresentationController *popPresenter = assetMethod.popoverPresentationController;
    popPresenter.barButtonItem = self.navigationItem.rightBarButtonItem;
    
    // Create WeakSelf Variable
    __weak AddServiceViewController *weakSelf = self;
    
    // Initialize ImagePicker
    UIImagePickerController *imagePicker = [[UIImagePickerController alloc] init];
    imagePicker.delegate = weakSelf;
    imagePicker.allowsEditing = YES;
    // Create Action Variable
    UIAlertAction *takeAsset, *uploadAsset;
    
    // Verify which camera source are available
    if ([UIImagePickerController isSourceTypeAvailable:UIImagePickerControllerSourceTypeCamera]){
        
        takeAsset = [UIAlertAction actionWithTitle:takeAssetButton style:UIAlertActionStyleDefault handler:^(UIAlertAction *action) {
            imagePicker.sourceType = UIImagePickerControllerSourceTypeCamera;
            
            NSArray *mediaTypesArray = [UIImagePickerController availableMediaTypesForSourceType:imagePicker.sourceType];
            imagePicker.mediaTypes = mediaTypesArray;
            
            [weakSelf presentViewController:imagePicker animated:YES completion:nil];
        }];
        
        [assetMethod addAction:takeAsset];
    }
    
    if ([UIImagePickerController isSourceTypeAvailable:UIImagePickerControllerSourceTypePhotoLibrary]){
        
        uploadAsset = [UIAlertAction actionWithTitle:uploadButton style:UIAlertActionStyleDefault handler:^(UIAlertAction *action) {
            imagePicker.sourceType = UIImagePickerControllerSourceTypePhotoLibrary;
            
            [weakSelf presentViewController:imagePicker animated:YES completion:nil];
        }];
        
        [assetMethod addAction:uploadAsset];
    }
    
    UIAlertAction *cancel = [UIAlertAction actionWithTitle:@"Cancel" style:UIAlertActionStyleCancel handler:nil];
    [assetMethod addAction:cancel];
    
    [self presentViewController:assetMethod animated:YES completion:nil];
    
}
- (IBAction)rangeChanged:(id)sender {
    self.rangeTF.text = [NSString stringWithFormat:@"%.0lf", (self.rangeStepper.value)];
    
    MKCoordinateRegion viewRegion = MKCoordinateRegionMakeWithDistance(self.pin.coordinate, (self.rangeStepper.value * 1000), (self.rangeStepper.value * 1000));
    MKCoordinateRegion adjustedRegion = [self.mapView regionThatFits:viewRegion];
    [self.mapView setRegion:adjustedRegion animated:YES];
}

#pragma mark UIImagePickerControllerDelegate
-(void) imagePickerController:(UIImagePickerController *)picker didFinishPickingMediaWithInfo:(NSDictionary *)info
{
    CGFloat assetButtonSize = self.assetBT.frame.size.width;
    self.imageRecord = [[ServiceImage alloc] initWithImage:info[UIImagePickerControllerOriginalImage] andButtonSize:assetButtonSize];
    __weak AddServiceViewController *weakSelf = self;
    
    // Dismisses imagePicker Add image to Button
    [picker dismissViewControllerAnimated:YES completion:^{
        UIImage *image = self.imageRecord.assetThumb;
        if(image){
            [weakSelf.assetBT setTitle:@"" forState:UIControlStateNormal];
            [weakSelf.assetBT setBackgroundImage:self.imageRecord.assetThumb forState:UIControlStateNormal];
        }
    }];
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
        
        MKCoordinateRegion viewRegion = MKCoordinateRegionMakeWithDistance(self.pin.coordinate, (self.rangeStepper.value * 1000), (self.rangeStepper.value * 1000));
        MKCoordinateRegion adjustedRegion = [self.mapView regionThatFits:viewRegion];
        [self.mapView setRegion:adjustedRegion animated:YES];
        
        if(self.currentService != nil){
            CLLocation *currentLocation = self.currentService.postRecord[ServiceLocationKey];
            CLLocationCoordinate2D newLoc = CLLocationCoordinate2DMake(currentLocation.coordinate.latitude, currentLocation.coordinate.longitude);
            [self.pin setCoordinate:newLoc];
        }
        [self.mapView addAnnotation:self.pin];
        [self.mapView showAnnotations:@[self.pin] animated:NO];
        
        [self.locationManager stopUpdatingLocation];
        
    } else {
        self.pin.coordinate = self.currentLocation.coordinate;
        
        if(self.currentService != nil){
            CLLocation *currentLocation = self.currentService.postRecord[ServiceLocationKey];
            CLLocationCoordinate2D newLoc = CLLocationCoordinate2DMake(currentLocation.coordinate.latitude, currentLocation.coordinate.longitude);
            [self.pin setCoordinate:newLoc];
        }
        
        MKCoordinateRegion viewRegion = MKCoordinateRegionMakeWithDistance(self.pin.coordinate, (self.rangeStepper.value * 1000), (self.rangeStepper.value * 1000));
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



#pragma mark - Map View Delegate
- (MKAnnotationView *)mapView:(MKMapView *)mapView viewForAnnotation:(id<MKAnnotation>)annotation {
    MKPinAnnotationView *view = [[MKPinAnnotationView alloc] initWithAnnotation:annotation reuseIdentifier:@""];
    
    view.draggable = YES;
    
    return view;
}

- (SubmissionErrorResponse) handleError:(NSError *)error
{
    if (error == nil) {
        return SubmissionErrorSuccess;
    }
    switch ([error code])
    {
        case CKErrorUnknownItem:
            // This error occurs if it can't find the subscription named autoUpdate. (It tries to delete one that doesn't exits or it searches for one it can't find)
            // This is okay and expected behavior
            return SubmissionErrorIgnore;
            break;
        case CKErrorNetworkUnavailable:
        case CKErrorNetworkFailure:
            // A reachability check might be appropriate here so we don't just keep retrying if the user has no service
        case CKErrorServiceUnavailable:
        case CKErrorRequestRateLimited:
            return SubmissionErrorRetry;
            break;
            
        case CKErrorPartialFailure:
            // This shouldn't happen on a query operation
        case CKErrorNotAuthenticated:
        case CKErrorBadDatabase:
        case CKErrorIncompatibleVersion:
        case CKErrorBadContainer:
        case CKErrorPermissionFailure:
        case CKErrorMissingEntitlement:
            // This app uses the publicDB with default world readable permissions
        case CKErrorAssetFileNotFound:
        case CKErrorAssetFileModified:
            // Users don't really have an option to delete files so this shouldn't happen
        case CKErrorQuotaExceeded:
            // We should not retry if it'll exceed our quota
        case CKErrorOperationCancelled:
            // Nothing to do here, we intentionally cancelled
        case CKErrorInvalidArguments:
        case CKErrorResultsTruncated:
        case CKErrorServerRecordChanged:
        case CKErrorChangeTokenExpired:
        case CKErrorBatchRequestFailed:
        case CKErrorZoneBusy:
        case CKErrorZoneNotFound:
        case CKErrorLimitExceeded:
        case CKErrorUserDeletedZone:
            // All of these errors are irrelevant for this save operation. We're only saving new records, not modifying old ones
        case CKErrorInternalError:
        case CKErrorServerRejectedRequest:
        case CKErrorConstraintViolation:
            //Non-recoverable, should not retry
        default:
            return SubmissionErrorIgnore;
            break;
    }
}

@end
