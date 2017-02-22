//
//  DataViewController.m
//  uMessage
//
//  Created by Codecamp on 20.02.17.
//  Copyright © 2017 Codecamp. All rights reserved.
//

#import "DataViewController.h"
@import FirebaseAuth;
@import FirebaseDatabase;
@interface DataViewController ()
@end

@implementation DataViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    // Do any additional setup after loading the view, typically from a nib.
}


- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}


- (void)viewWillAppear:(BOOL)animated {
    [super viewWillAppear:animated];
    self.dataLabel.text = [self.dataObject description];
}

//Login Button clicked
- (IBAction)loginTouchUpInside:(id)sender {
    //Authentiacation with Email and password
    [[FIRAuth auth] signInWithEmail: _loginEmailTextField.text
                           password:_loginPasswordTextField.text
                         completion:^(FIRUser *user, NSError *error)
    {
        
    if(error)
    {
        
    }else{
        FIRUser *user = [FIRAuth auth].currentUser;
        printf(user.email.UTF8String);
        self.ref = [[FIRDatabase database] reference];
        /*FIRDatabaseQuery *recentPostsQuery = [[self.ref child:@"chats"] queryLimitedToFirst:100];
         // [END recent_posts_query]
         printf(recentPostsQuery.description.UTF8String);*/
        
        [[[_ref child:@"users"] child:user.uid] observeSingleEventOfType:FIRDataEventTypeValue withBlock:^(FIRDataSnapshot * _Nonnull snapshot) {
            // Get user value
            NSDictionary *postDict = snapshot.value;
            NSString *tmp = postDict.allValues[1];
            printf(tmp.UTF8String);
        }];
    }
    }];
}

@end
