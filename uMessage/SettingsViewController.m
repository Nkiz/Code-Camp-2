//
//  SettingsViewController.m
//  uMessage
//
//  Created by Codecamp on 17.03.17.
//  Copyright © 2017 Codecamp. All rights reserved.
//

#import "SettingsViewController.h"
#import "TableViewController.h"
#import "Constants.h"
#import "ChatViewController.h"

@interface SettingsViewController ()

@property (strong, nonatomic) NSString *userID;
@property (strong, nonatomic) NSString *actualImageName;

@end

@implementation SettingsViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    // Do any additional setup after loading the view.
    self.ref = [[FIRDatabase database] reference];
}

- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

- (UIStatusBarStyle)preferredStatusBarStyle
{
    return UIStatusBarStyleLightContent;
}

- (void)touchesBegan:(NSSet *)touches withEvent:(UIEvent *)event{
    NSLog(@"TouchEvent: end editing.");
    [self.view endEditing:YES];
    [super touchesBegan:touches withEvent:event];
}

- (void)viewWillAppear:(BOOL)animated {
    
    // Get actual user status
    self.userID = [FIRAuth auth].currentUser.uid;
    [[[self.ref child:UsersTable] child:self.userID] observeSingleEventOfType:FIRDataEventTypeValue withBlock:^(FIRDataSnapshot * _Nonnull snapshot) {

        self.userStatus.text = snapshot.value[@"status"];
        
    } withCancelBlock:^(NSError * _Nonnull error) {
        NSLog(@"%@", error.localizedDescription);
    }];
    
    // Get actual user pic
    [self showActualUserPicture];
}

- (IBAction)saveUserStatus:(id)sender {
    
    // Write new status
    [self setUserNewValue:self.userStatus.text forKey:@"status"];
    
    // Delete cursor
    [self.userStatus resignFirstResponder];
}

/**
 Upload a pic from internet to the storage and delete old pic.
 Only png, jpg, jpeg allowed for saving traffic
 */
- (IBAction)selectUserPicture:(id)sender {
    
    NSURL *candidateURL = [NSURL URLWithString:self.pictureURL.text];
    // WARNING > "test" is an URL according to RFCs, being just a path
    // so you still should check scheme and all other NSURL attributes you need
    if (candidateURL && candidateURL.scheme && candidateURL.host
        && (
            [[self.pictureURL.text lowercaseString] hasSuffix:@".png"]
            ||[[self.pictureURL.text lowercaseString] hasSuffix:@".jpg"]
            ||[[self.pictureURL.text lowercaseString] hasSuffix:@".jpeg"]
            )){
        // candidate is a well-formed url
        
        // Get actual user picture name
        [[[self.ref child:UsersTable] child:self.userID] observeSingleEventOfType:FIRDataEventTypeValue withBlock:^(FIRDataSnapshot * _Nonnull snapshot) {
            
            NSString *tempURL = snapshot.value[@"profileImg"];
            
            if (tempURL && ![tempURL isEqualToString:@""]) {
                _actualImageName =[[NSURL URLWithString:tempURL] lastPathComponent];
                NSLog(@"_actualImageName: %@", _actualImageName);
            }
        } withCancelBlock:^(NSError * _Nonnull error) {
            NSLog(@"%@", error.localizedDescription);
        }];
        
        // Create a storage reference from our storage service
        self.storageRef = [[FIRStorage storage] reference];
        
        // Create the file metadata
        FIRStorageMetadata *metadata = [[FIRStorageMetadata alloc] init];
        NSString *fileExtension = [[[NSURL URLWithString:self.pictureURL.text] pathExtension] lowercaseString];
        metadata.contentType = [NSString stringWithFormat:@"image/%@", fileExtension];
        
        NSLog(@"metadata.contentType: %@", metadata.contentType);
        
        // Create a timestamp for picture ID
        NSTimeInterval timeStamp = [[NSDate date] timeIntervalSince1970];
        NSString *timeStampString = [NSString stringWithFormat:@"%.0f", timeStamp * 1000000];
        
        // Make a new picture filename
        NSString *fileName = [NSString stringWithFormat:@"%@%@.%@", self.userID, timeStampString, fileExtension];
        
        // Upload picture to storage
        // Get data from external URL
        NSData *imageData = UIImageJPEGRepresentation([UIImage imageWithData:[NSData dataWithContentsOfURL:[NSURL URLWithString:self.pictureURL.text]]], 0.8);
        
        // Create a reference to the file you want to upload
        FIRStorageReference *avatarsRef = [self.storageRef child:[NSString stringWithFormat:@"avatars/%@", fileName]];
        
        // Upload file and metadata to the object
        FIRStorageUploadTask *uploadTask = [avatarsRef putData:imageData metadata:metadata];
        
        // Show download message
        UIAlertController *view =   [UIAlertController
                                      alertControllerWithTitle:@"Downloading ..."
                                      message:@"Please wait"
                                      preferredStyle:UIAlertControllerStyleAlert];
        
        // disable transparency of UIActionSheets
        UIView * firstView = view.view.subviews.firstObject;
        UIView * nextView = firstView.subviews.firstObject;
        nextView.backgroundColor = [UIColor whiteColor];
        nextView.layer.cornerRadius = 15;
        
        [self presentViewController:view animated:YES completion:nil];
        
        [uploadTask observeStatus:FIRStorageTaskStatusSuccess handler:^(FIRStorageTaskSnapshot *snapshot) {
            
            // Upload completed successfully
            // Set URL for new user pic
            [self setUserNewValue:[NSString stringWithFormat:@"gs://umessage-80185.appspot.com/avatars/%@", fileName] forKey:@"profileImg"];
            
            // Get actual user pic
            [self showActualUserPicture];
            [self dismissViewControllerAnimated:YES completion:nil];
            NSLog(@"Upload completed successfully");
            if(self.actualImageName && ![self.actualImageName isEqualToString:@""]){
                [self deleteUserFile:self.actualImageName inFolder:@"avatars"];
                self.actualImageName = @"";
            }
        }];
        
        // Errors only occur in the "Failure" case
        [uploadTask observeStatus:FIRStorageTaskStatusFailure handler:^(FIRStorageTaskSnapshot *snapshot) {
            if (snapshot.error != nil) {
                switch (snapshot.error.code) {
                    case FIRStorageErrorCodeObjectNotFound:
                        // File doesn't exist
                        NSLog(@"SettingsViewContoroller: File doesn't exist: %@", snapshot.error.localizedDescription);
                        break;
                        
                    case FIRStorageErrorCodeUnauthorized:
                        // User doesn't have permission to access file
                        NSLog(@"SettingsViewContoroller: User doesn't have permission to access file: %@", snapshot.error.localizedDescription);
                        break;
                        
                    case FIRStorageErrorCodeCancelled:
                        // User canceled the upload
                        NSLog(@"SettingsViewContoroller: User canceled the upload: %@", snapshot.error.localizedDescription);
                        break;
                        
                    case FIRStorageErrorCodeUnknown:
                        // Unknown error occurred, inspect the server response
                        NSLog(@"SettingsViewContoroller: Unknown error occurred, inspect the server response: %@", snapshot.error.localizedDescription);
                        break;
                }
            }
            [self dismissViewControllerAnimated:YES completion:nil];
        }];
        
    } else {
        // Show warning message
        UIAlertController * view=   [UIAlertController
                                     alertControllerWithTitle:@"Wrong URL!"
                                     message:@"Please try correct URL with png, jpeg or jpg images"
                                     preferredStyle:UIAlertControllerStyleActionSheet];
        
        UIAlertAction* ok = [UIAlertAction
                             actionWithTitle:@"OK"
                             style:UIAlertActionStyleDefault
                             handler:^(UIAlertAction * action)
                             {
                                 // Hide the message
                                 [view dismissViewControllerAnimated:YES completion:nil];
                                 
                             }];
        
        // Disable transparency of UIActionSheets
        UIView * firstView = view.view.subviews.firstObject;
        UIView * nextView = firstView.subviews.firstObject;
        nextView.backgroundColor = [UIColor whiteColor];
        nextView.layer.cornerRadius = 15;
        
        [view addAction:ok];
        [self presentViewController:view animated:YES completion:nil];
    }
    
}

- (IBAction)deleteActualUserPicture:(id)sender {
    
    // Get actual user pic
    [[[self.ref child:UsersTable] child:self.userID] observeSingleEventOfType:FIRDataEventTypeValue withBlock:^(FIRDataSnapshot * _Nonnull snapshot) {
        
        NSString *imageURL = snapshot.value[@"profileImg"];
        
        if (imageURL && ![imageURL isEqualToString:@""]) {
            NSString *fileName = [[NSURL URLWithString:imageURL] lastPathComponent];
            [self deleteUserFile:fileName inFolder:@"avatars"];
            
            // Delete actual user pic URL in DB
            [self setUserNewValue:@"" forKey:@"profileImg"];
            // Delete shown picture
            self.userPicture.image = nil;
        }
        
    } withCancelBlock:^(NSError * _Nonnull error) {
        NSLog(@"%@", error.localizedDescription);
    }];

}

// Delete needed file in the user model
- (void)deleteUserFile:(NSString *)fileName inFolder:(NSString *)folder {
    
    NSLog(@"deleteUserFile - fileName: %@", fileName);
    NSLog(@"deleteUserFile - folder: %@", folder);
    
    if (fileName && folder && ![fileName isEqualToString:@""] && ![folder isEqualToString:@""]) {
            
        // Create a storage reference from our storage service
        self.storageRef = [[FIRStorage storage] reference];
            
        // Create a reference to the file to delete
        FIRStorageReference *avatarsRef = [self.storageRef child:[NSString stringWithFormat:@"%@/%@", folder, fileName]];
            
        // Delete the file
        [avatarsRef deleteWithCompletion:^(NSError *error){
            if (error != nil) {
                // Uh-oh, an error occurred!
                NSLog(@"%@", error.localizedDescription);
            } else {
                // File deleted successfully
                NSLog(@"File deleted successfully");
            }
        }];
    } else {
        NSLog(@"File was not deleted: fileName or folder is wrong!");
    }
}

- (void) showActualUserPicture {
    
    // Get actual user pic
    [[[self.ref child:UsersTable] child:self.userID] observeSingleEventOfType:FIRDataEventTypeValue withBlock:^(FIRDataSnapshot * _Nonnull snapshot) {
        
        NSString *imageURL = snapshot.value[@"profileImg"];
        
        if (imageURL && ![imageURL isEqualToString:@""]) {
            if ([imageURL hasPrefix:@"gs://"]) {
                [TableViewController getAvatar:imageURL withImageView:self.userPicture];
            } else {
                self.userPicture.image = [UIImage imageWithData:[NSData dataWithContentsOfURL:[NSURL URLWithString:imageURL]]];
            }
        }
    } withCancelBlock:^(NSError * _Nonnull error) {
        NSLog(@"%@", error.localizedDescription);
    }];
}

// Set new value in the model for current user
- (void) setUserNewValue:(NSString*)value forKey:(NSString*)key {
    
    NSDictionary *childUpdates = @{[NSString stringWithFormat:@"/users/%@/%@/", self.userID, key]: value};
    NSLog(@"value: %@", value);
    [self.ref updateChildValues:childUpdates];
}

@end
