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
    
    // reference to database
    self.ref = [[FIRDatabase database] reference];
    
    // login listener
    self.handle = [[FIRAuth auth] addAuthStateDidChangeListener:^(FIRAuth *_Nonnull auth, FIRUser *_Nullable user) {
        if (user) {
            NSLog(@"LOGIN: User %@ logged in.", user.displayName);
            // go to chats ui
        }
    }];
    
}

- (void)dealloc {
    [[FIRAuth auth] removeAuthStateDidChangeListener:_handle];
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

static NSString *const kOK = @"OK";

// Zeige Popup Fenster mit OK Button an
- (void)showMessagePrompt:(NSString *)message {
    UIAlertController *alert =
    [UIAlertController alertControllerWithTitle:nil
                                        message:message
                                 preferredStyle:UIAlertControllerStyleAlert];
    UIAlertAction *okAction =
    [UIAlertAction actionWithTitle:kOK style:UIAlertActionStyleDefault handler:nil];
    [alert addAction:okAction];
    [self presentViewController:alert animated:YES completion:nil];
    
}


- (IBAction)registerTouchUpInside:(UIButton *)sender {
    [self.view endEditing:YES];
    
    if(_registerEmailTextField.hasText && _registerNicknameTextField && _registerPasswordTextField.hasText) {
        [[FIRAuth auth] createUserWithEmail:_registerEmailTextField.text
                                   password:_registerPasswordTextField.text
                                 completion:^(FIRUser *_Nullable user,
                                              NSError *_Nullable error) {
                                     if (error) {
                                         [self showMessagePrompt:error.localizedDescription];
                                         NSLog(@"REGISTER: Failed to create user: %@", error.localizedDescription);
                                         return;
                                     } else {
                                         NSLog(@"REGISTER: User created.");
                                         
                                         // current timestamp
                                         NSISO8601DateFormatter *formatter = [[NSISO8601DateFormatter alloc] init];
                                         NSString *result = [formatter stringFromDate:[NSDate date]];
                                         
                                         // userinfo
                                         NSDictionary *userInfo = @{@"authId": user.uid,
                                                                    @"createdTs": result,
                                                                    @"email": user.email,
                                                                    @"lastLogin": result,
                                                                    @"profileImg": @"",
                                                                    @"status": @"verfügbar",
                                                                    @"username": _registerNicknameTextField.text
                                                                    };
                                         
                                         // add user to databse
                                         [[[_ref child:@"users"] childByAutoId] setValue:userInfo];
                                         NSLog(@"REGISTER: User added to database.");
                                         
                                         [self showMessagePrompt:@"User erstellt."];
                                     }
                                 }];
    }
}

// hide keyboard if you touch outside
- (void)touchesBegan:(NSSet *)touches withEvent:(UIEvent *)event{
    [self.view endEditing:YES];
    [super touchesBegan:touches withEvent:event];
}

@end
