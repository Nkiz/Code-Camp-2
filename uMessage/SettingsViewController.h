//
//  SettingsViewController.h
//  uMessage
//
//  Created by Codecamp on 17.03.17.
//  Copyright © 2017 Codecamp. All rights reserved.
//

#import <UIKit/UIKit.h>
@import FirebaseAuth;
@import FirebaseDatabase;
@import FirebaseStorage;

@interface SettingsViewController : UIViewController

@property (strong, nonatomic) FIRDatabaseReference *ref;

@property (strong, nonatomic) IBOutlet UITextField *userStatus;
@property (strong, nonatomic) IBOutlet UIImageView *userPicture;
@property (strong, nonatomic) IBOutlet UITextField *pictureURL;

- (IBAction)saveUserStatus:(id)sender;
- (IBAction)selectUserPicture:(id)sender;
- (IBAction)deleteUserPicture:(id)sender;

@end
