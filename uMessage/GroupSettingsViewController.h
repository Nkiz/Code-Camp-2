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

@property (strong, nonatomic) FIRDatabaseReference *ref;
@property (strong, nonatomic) FIRDatabaseReference *chatRef;

@property (strong, nonatomic) IBOutlet UIImageView *groupPicture;
@property (strong, nonatomic) IBOutlet UITextField *pictureURL;

@property (strong, nonatomic) NSString *openedBy;
@property (strong, nonatomic) NSString *openedByChatId;
@property (strong, nonatomic) NSMutableArray *chatUserlist;

- (IBAction)selectGroupPicture:(id)sender;
- (IBAction)deleteGroupPicture:(id)sender;

@end
