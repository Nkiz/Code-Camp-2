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
    //self.userRef     = [_ref child:@"users"];
    _myUserRels = [[NSMutableArray alloc] init];
    NSLog(@"self.ref: %@", self.ref);
    //NSLog(@"self.userRef: %@", self.userRef);
    //NSLog(@"self.userRelRef: %@", self.userRelRef);
    
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
    
    //get actual status and user pic
    NSString *userID = [FIRAuth auth].currentUser.uid;
    [[[self.ref child:UsersTable] child:userID] observeSingleEventOfType:FIRDataEventTypeValue withBlock:^(FIRDataSnapshot * _Nonnull snapshot) {
        //NSString *status = snapshot.value[@"status"];
        _userStatus.text = snapshot.value[@"status"];
        
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

    
    //FIRDataSnapshot *userSnapshot = _myUserRels;
    //NSDictionary<NSString *, NSString *> *user = userSnapshot.value;
    
    //NSLog(@"_myUserRels: %@", _myUserRels);
    //NSLog(@"user: %@", user);
    
/*
    ChatTableViewCell *cell = [_groupTable dequeueReusableCellWithIdentifier:@"TableViewCell"forIndexPath:indexPath];
    cell.title.text = user[@"username"];
    cell.message.text = user[@"status"];
    
    NSString *imageURL = user[@"profileImg"];
    
    if (imageURL && ![imageURL isEqualToString:@""]) {
        if ([imageURL hasPrefix:@"gs://"]) {
            [self getAvatar:imageURL withImageView:cell.avatar];
        } else {
            cell.avatar.image = [UIImage imageWithData:[NSData dataWithContentsOfURL:[NSURL URLWithString:imageURL]]];
        }
    }
*/
}

- (IBAction)saveUserStatus:(id)sender {
    
    //write new status
    NSString *userID = [FIRAuth auth].currentUser.uid;
    NSString *newStatus = _userStatus.text;
    NSString *key = @"status";
    NSDictionary *childUpdates = @{[NSString stringWithFormat:@"/users/%@/%@/", userID, key]: newStatus};
    [_ref updateChildValues:childUpdates];
    
    [_userStatus resignFirstResponder];
}

- (IBAction)selectUserPicture:(id)sender {
    
    FIRStorage *storage = [FIRStorage storage];
    
}

- (IBAction)deleteUserPicture:(id)sender {
}

@end
