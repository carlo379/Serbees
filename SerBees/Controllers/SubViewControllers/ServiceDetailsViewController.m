//  ServiceDetailsViewController.m
//  SerBees

#import "ServiceDetailsViewController.h"

@interface ServiceDetailsViewController ()
@property (weak, nonatomic) IBOutlet UILabel *nameLabel;

@end

@implementation ServiceDetailsViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    // Do any additional setup after loading the view.
    self.nameLabel.text = self.servicePost.postRecord[ServiceNameKey];
}

- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

- (IBAction)cancelPressed:(UIButton *)sender {
    [self dismissViewControllerAnimated:YES completion:nil];
}

@end
