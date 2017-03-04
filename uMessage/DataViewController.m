//
//  DataViewController.m
//  uMessage
//
//  Created by Codecamp on 20.02.17.
//  Copyright © 2017 Codecamp. All rights reserved.
//

#import "DataViewController.h"
#import "TableViewController.h"
@import FirebaseAuth;
@import FirebaseDatabase;

@interface DataViewController () <UITextFieldDelegate, UIScrollViewDelegate>

@property (strong, nonatomic) IBOutlet UIView *uiView;
@property (strong, nonatomic) IBOutlet UIScrollView *scrollView;
@property (weak, atomic) UITextField *activeField;

@end

@implementation DataViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    
    // TextFieldDelegate
    self.registerEmailTextField.delegate = self;
    self.registerNicknameTextField.delegate = self;
    self.registerPasswordTextField.delegate = self;
    self.loginEmailTextField.delegate       = self;
    self.loginPasswordTextField.delegate    = self;
    self.scrollView.delegate = self;
    
    // reference to database
    self.ref     = [[FIRDatabase database] reference];
    self.userRef = [_ref child:@"users"];
    
    // login listener
    self.handle = [[FIRAuth auth] addAuthStateDidChangeListener:^(FIRAuth *_Nonnull auth, FIRUser *_Nullable user) {
        if (user) {
            NSLog(@"LOGIN: User %@ logged in.", user.email);
            
            // current timestamp
            NSISO8601DateFormatter *formatter = [[NSISO8601DateFormatter alloc] init];
            NSString *result = [formatter stringFromDate:[NSDate date]];
            
            // update last login in db
            NSString *key = @"lastLogin";
            NSDictionary *childUpdates = @{[NSString stringWithFormat:@"/users/%@/%@/", user.uid, key]: result};
            [_ref updateChildValues:childUpdates];
            
            // go to chats ui
            [self performSegueWithIdentifier: @"LoginToChat" sender: self];
        }
    }];
}


-(IBAction)prepareForUnwind:(UIStoryboardSegue *)segue {
    NSLog(@"Login unwind");
}

- (void)viewWillDisappear:(BOOL)animated {
    self.loginEmailTextField.text       = @"";
    self.loginPasswordTextField.text    = @"";
    self.registerEmailTextField.text    = @"";
    self.registerNicknameTextField.text = @"";
    self.registerPasswordTextField.text = @"";
    
    [[NSNotificationCenter defaultCenter] removeObserver:self];
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
    
    [[NSNotificationCenter defaultCenter] addObserver:self
                                             selector:@selector(keyboardWasShown:)
                                                 name:UIKeyboardDidShowNotification object:nil];
    
    [[NSNotificationCenter defaultCenter] addObserver:self
                                             selector:@selector(keyboardWillBeHidden:)
                                                 name:UIKeyboardWillHideNotification object:nil];
    
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
        NSLog(@"Fehler beim einloggen des Users: %@", error.description);
        [self showMessagePrompt: @"Fehler beim Login"];
    }else{
        FIRUser *user = [FIRAuth auth].currentUser;
        NSLog(@"Loggin erfolgreich: UID %@", user.uid);
        [self showMessagePrompt:@"Loggin erfolgreich"];
        /*printf(user.email.UTF8String);*/
        
        [[_userRef child:user.uid ] observeEventType:FIRDataEventTypeValue withBlock:^(FIRDataSnapshot * _Nonnull snapshot) {
            // Get user value
            NSDictionary *userDict = snapshot.value;
            NSLog(@"Found");
            self.userData = userDict;
            
        } withCancelBlock:^(NSError * _Nonnull error) {
            NSLog(@"%@", error.localizedDescription);
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
                                         [[[_ref child:@"users"] child:user.uid] setValue:userInfo];
                                         NSLog(@"REGISTER: User added to database.");
                                         
                                         [self showMessagePrompt:@"User erstellt."];
                                     }
                                 }];
    }
}

// hide keyboard if you touch outside
// not working with ScrollView
- (void)touchesBegan:(NSSet *)touches withEvent:(UIEvent *)event{
    NSLog(@"TouchEvent: end editing.");
    [self.view endEditing:YES];
    [super touchesBegan:touches withEvent:event];
}

- (void)keyboardWasShown:(NSNotification*)aNotification
{
    NSLog(@"Keyboard was shown.");
    NSDictionary* info = [aNotification userInfo];
    CGSize kbSize = [[info objectForKey:UIKeyboardFrameBeginUserInfoKey] CGRectValue].size;
    
    UIEdgeInsets contentInsets = UIEdgeInsetsMake(0.0, 0.0, kbSize.height, 0.0);
    
    self.scrollView.contentInset = contentInsets;
    self.scrollView.scrollIndicatorInsets = contentInsets;
    
    NSLog(@"Keyboard height is %f / %f", kbSize.height, self.uiView.frame.size.height);
    
    // If active text field is hidden by keyboard, scroll it so it's visible
    // Your app might not need or want this behavior.
    CGRect aRect = self.view.frame;
    aRect.size.height -= kbSize.height;
    
    NSLog(@"Rectangle: %f , %f", aRect.origin.x, aRect.origin.y);
    
    NSLog(@"MailField: %f , %f", _activeField.frame.origin.x, _activeField.frame.origin.y);
    
    if (!CGRectContainsPoint(aRect, _activeField.frame.origin) ) {
        NSLog(@"TextField hidden by keyboard");
        // TODO: scroll to activeField
        [self.scrollView scrollRectToVisible:_activeField.frame animated:YES];
    }
}

// Called when the UIKeyboardWillHideNotification is sent
- (void)keyboardWillBeHidden:(NSNotification*)aNotification
{
    NSLog(@"Keyboard will be hidden.");
    UIEdgeInsets contentInsets = UIEdgeInsetsZero;
    self.scrollView.contentInset = contentInsets;
    self.scrollView.scrollIndicatorInsets = contentInsets;
}

- (void)textFieldDidBeginEditing:(UITextField *)textField
{
    NSLog(@"Active Field is set");
    _activeField = textField;
}

- (BOOL)textFieldShouldReturn:(UITextField *)textField
{
    NSLog(@"TextField should return.");
    if(textField == _registerEmailTextField) {
        [_registerNicknameTextField becomeFirstResponder];
    } else if(textField == _registerNicknameTextField) {
        [_registerPasswordTextField becomeFirstResponder];
    } else if(textField == _registerPasswordTextField) {
        [self.view endEditing:YES];
        
        //[self registerTouchUpInside:nil];
    }
    return NO;
}

- (void)textFieldDidEndEditing:(UITextField *)textField
{
    NSLog(@"Active Field reset");
    _activeField = nil;
}
@end
