//
//  TableViewController.h
//  uMessage
//
//  Created by Codecamp on 22.02.17.
//  Copyright © 2017 Codecamp. All rights reserved.
//

#import <UIKit/UIKit.h>
@import FirebaseAuth;
@import FirebaseDatabase;

@interface TableViewController : UIViewController
@property (strong, nonatomic) FIRDatabaseReference *ref;
@property (strong, nonatomic) FIRDatabaseReference *userRef;
@property (strong, nonatomic) FIRDatabaseReference *chatRef;
@property (strong, nonatomic) NSDictionary *tmpUserData;
- (IBAction)logoutAction:(id)sender;

@end
