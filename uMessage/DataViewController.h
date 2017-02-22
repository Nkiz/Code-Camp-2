//
//  DataViewController.h
//  uMessage
//
//  Created by Codecamp on 20.02.17.
//  Copyright © 2017 Codecamp. All rights reserved.
//

#import <UIKit/UIKit.h>
@import FirebaseDatabase;
@interface DataViewController : UIViewController

@property (strong, nonatomic) IBOutlet UILabel *dataLabel;
@property (strong, nonatomic) id dataObject;
@property (weak, nonatomic) IBOutlet UITextField *loginEmailTextField;
@property (weak, nonatomic) IBOutlet UITextField *loginPasswordTextField;
@property (strong, nonatomic) FIRDatabaseReference *ref;
- (IBAction)loginTouchUpInside:(id)sender;

@property (strong, nonatomic) FIRDatabaseReference *ref;
@property (strong, nonatomic) FIRAuthStateDidChangeListenerHandle handle;
@end

