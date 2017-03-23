//
//  GroupSettingsViewController.h
//  uMessage
//
//  Created by Codecamp on 19.03.17.
//  Copyright © 2017 Codecamp. All rights reserved.
//

#import <UIKit/UIKit.h>
@import FirebaseAuth;
@import FirebaseDatabase;
@import FirebaseStorage;

@interface GroupSettingsViewController : UIViewController

//Firebase
@property (strong, nonatomic) FIRDatabaseReference *ref;
@property (strong, nonatomic) FIRDatabaseReference *chatRef;
@property (strong, nonatomic) FIRStorageReference *storageRef;

//UI elements
@property (strong, nonatomic) IBOutlet UIImageView *groupPicture;
@property (strong, nonatomic) IBOutlet UITextField *pictureURL;

// Group ID
@property (strong, nonatomic) NSString *openedByChatId;

// Picture methods
- (IBAction)selectGroupPicture:(id)sender;
- (IBAction)deleteActualyGroupPicture:(id)sender;

@end
