//
//  ContactViewController.h
//  uMessage
//
//  Created by Codecamp on 24.02.17.
//  Copyright © 2017 Codecamp. All rights reserved.
//

#import <UIKit/UIKit.h>
@import FirebaseAuth;
@import FirebaseDatabase;

@interface ContactViewController : UIViewController
- (IBAction)backButtonPressed:(id)sender;
@property (weak, nonatomic) IBOutlet UITextField *idContactNick;
@property (weak, nonatomic) IBOutlet UITextField *idContactMail;
@property (strong, nonatomic) FIRDatabaseReference *ref;
@property (strong, nonatomic) FIRDatabaseReference *usersRef;
@property (strong, nonatomic) FIRDatabaseReference *chatRef;
@property (strong, nonatomic) FIRDatabaseReference *userRelRef;
@property (strong, nonatomic) NSMutableArray<FIRDataSnapshot *> *myMessages;
@property (strong, nonatomic) NSMutableDictionary *myUsers;
- (IBAction)searchContactPressed:(id)sender;
@property (weak, nonatomic) IBOutlet UITableView *usersTable;

@end
