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

@property (strong, nonatomic) IBOutlet UILabel *registerLabel;
@property (strong, nonatomic) IBOutlet UILabel *loginLabel;
@property (strong, nonatomic) IBOutlet UIView *registerView;

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
    
    // reference to database
    self.ref     = [[FIRDatabase database] reference];
    self.userRef = [_ref child:@"users"];
    
    // login listener
    self.handle = [[FIRAuth auth] addAuthStateDidChangeListener:^(FIRAuth *_Nonnull auth, FIRUser *_Nullable user) {
        if (user) {
            NSLog(@"LOGIN: User %@ logged in.", user.email);
            
            // current timestamp
            NSString *timestamp = [Utils getTimestamp];
            
            // update last login in db
            NSString *key = @"lastLogin";
            NSDictionary *childUpdates = @{[NSString stringWithFormat:@"/users/%@/%@/", user.uid, key]: timestamp};
            [_ref updateChildValues:childUpdates];
            
            // go to chats ui
            [self performSegueWithIdentifier: @"LoginToChat" sender: self];
        }
    }];
    
    // login / register tabs
    UITapGestureRecognizer *tapGestureRecognizer = [[UITapGestureRecognizer alloc] initWithTarget:self action:@selector(loginTap:)];
    tapGestureRecognizer.numberOfTapsRequired = 1;
    [_loginLabel addGestureRecognizer:tapGestureRecognizer];
    _loginLabel.userInteractionEnabled = YES;
    
    tapGestureRecognizer = [[UITapGestureRecognizer alloc] initWithTarget:self action:@selector(registerTap:)];
    tapGestureRecognizer.numberOfTapsRequired = 1;
    [_registerLabel addGestureRecognizer:tapGestureRecognizer];
    _registerLabel.userInteractionEnabled = YES;
}

- (void)loginTap:(UIGestureRecognizer *)gestureRecognizer
{
    _uiView.hidden = YES;
    _registerView.hidden = NO;
}
- (void)registerTap:(UIGestureRecognizer *)gestureRecognizer
{
    _registerView.hidden = YES;
    _uiView.hidden = NO;
    
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
                                         NSString *timestamp = [Utils getTimestamp];
                                         
                                         // userinfo
                                         NSDictionary *userInfo = @{@"createdTs": timestamp,
                                                                    @"email": user.email,
                                                                    @"lastLogin": timestamp,
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
        
        [self registerTouchUpInside:nil];
    } else if(textField == _loginPasswordTextField) {
        [self.view endEditing:YES];
        
        [self loginTouchUpInside:nil];
    }
    return NO;
}

- (void)textFieldDidEndEditing:(UITextField *)textField
{
    NSLog(@"Active Field reset");
    _activeField = nil;
}

- (UIStatusBarStyle)preferredStatusBarStyle
{
    return UIStatusBarStyleLightContent;
}

@end
