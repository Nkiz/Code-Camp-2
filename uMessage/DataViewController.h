//
//  DataViewController.h
//  uMessage
//
//  Created by Codecamp on 20.02.17.
//  Copyright © 2017 Codecamp. All rights reserved.
//

#import <UIKit/UIKit.h>
@import Firebase;

@interface DataViewController : UIViewController

@property (strong, nonatomic) IBOutlet UILabel *dataLabel;
@property (strong, nonatomic) id dataObject;
@property (weak, nonatomic) IBOutlet UITextField *registerEmailTextField;
@property (weak, nonatomic) IBOutlet UITextField *registerNicknameTextField;
@property (weak, nonatomic) IBOutlet UITextField *registerPasswordTextField;

@property (strong, nonatomic) FIRDatabaseReference *ref;

@end

