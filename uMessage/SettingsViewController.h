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

// Firebase
@property (strong, nonatomic) FIRDatabaseReference *ref;
@property (strong, nonatomic) FIRStorageReference *storageRef;

// UI elements
@property (strong, nonatomic) IBOutlet UITextField *userStatus;
@property (strong, nonatomic) IBOutlet UIImageView *userPicture;
@property (strong, nonatomic) IBOutlet UITextField *pictureURL;

// Picture and status methods
- (IBAction)saveUserStatus:(id)sender;
- (IBAction)selectUserPicture:(id)sender;
- (IBAction)deleteActualUserPicture:(id)sender;

@end
