//
//  SettingsViewController.m
//  uMessage
//
//  Created by Codecamp on 17.03.17.
//  Copyright © 2017 Codecamp. All rights reserved.
//

#import "SettingsViewController.h"
#import "TableViewController.h"
#import "Constants.h"

@interface SettingsViewController ()

@property (strong, nonatomic) NSMutableArray<FIRDataSnapshot *> *users;
@property (strong, nonatomic) NSMutableArray<FIRDataSnapshot *> *myUserRels;

@end

@implementation SettingsViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    // Do any additional setup after loading the view.
    self.ref         = [[FIRDatabase database] reference];
    _myUserRels = [[NSMutableArray alloc] init];
    NSLog(@"self.ref: %@", self.ref);
}

- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

/*
#pragma mark - Navigation

// In a storyboard-based application, you will often want to do a little preparation before navigation
- (void)prepareForSegue:(UIStoryboardSegue *)segue sender:(id)sender {
    // Get the new view controller using [segue destinationViewController].
    // Pass the selected object to the new view controller.
}
*/

- (void)viewWillAppear:(BOOL)animated {
    
    //get actual user status
    NSString *userID = [FIRAuth auth].currentUser.uid;
    [[[self.ref child:UsersTable] child:userID] observeSingleEventOfType:FIRDataEventTypeValue withBlock:^(FIRDataSnapshot * _Nonnull snapshot) {

        _userStatus.text = snapshot.value[@"status"];
        
    } withCancelBlock:^(NSError * _Nonnull error) {
        NSLog(@"%@", error.localizedDescription);
    }];
    
    //get actual user pic
    [self showActualUserPicture];
}

- (IBAction)saveUserStatus:(id)sender {
    
    //write new status
    [self setUserNewValue:_userStatus.text forKey:@"status"];
    
    //delete cursor
    [_userStatus resignFirstResponder];
}

- (IBAction)selectUserPicture:(id)sender {
    
    //set URL for new user pic
    [self setUserNewValue:_pictureURL.text forKey:@"profileImg"];
    
    //get actual user pic
    [self showActualUserPicture];
}

- (IBAction)deleteUserPicture:(id)sender {
    
    //delete actual user pic in the model
    [self setUserNewValue:@"" forKey:@"profileImg"];
    
    //delete shown picture
    _userPicture.image = nil;
}

- (void) showActualUserPicture {
    
    //get actual user pic
    NSString *userID = [FIRAuth auth].currentUser.uid;
    [[[self.ref child:UsersTable] child:userID] observeSingleEventOfType:FIRDataEventTypeValue withBlock:^(FIRDataSnapshot * _Nonnull snapshot) {
        
        NSString *imageURL = snapshot.value[@"profileImg"];
        
        if (imageURL && ![imageURL isEqualToString:@""]) {
            if ([imageURL hasPrefix:@"gs://"]) {
                [TableViewController getAvatar:imageURL withImageView:_userPicture];
            } else {
                _userPicture.image = [UIImage imageWithData:[NSData dataWithContentsOfURL:[NSURL URLWithString:imageURL]]];
            }
        }
    } withCancelBlock:^(NSError * _Nonnull error) {
        NSLog(@"%@", error.localizedDescription);
    }];
}

//set new value in the model for current user
- (void) setUserNewValue:(NSString*)value forKey:(NSString*)key {
    
    NSString *userID = [FIRAuth auth].currentUser.uid;
    NSDictionary *childUpdates = @{[NSString stringWithFormat:@"/users/%@/%@/", userID, key]: value};
    [_ref updateChildValues:childUpdates];
}

@end
