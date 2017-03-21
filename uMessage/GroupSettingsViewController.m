//
//  GroupSettingsViewController.m
//  uMessage
//
//  Created by Codecamp on 19.03.17.
//  Copyright © 2017 Codecamp. All rights reserved.
//

#import "GroupSettingsViewController.h"
#import "TableViewController.h"
#import "Constants.h"
#import "SettingsViewController.h"

@interface GroupSettingsViewController ()

@property (strong, nonatomic) NSString *actualImageName;

@end

@implementation GroupSettingsViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    // Do any additional setup after loading the view.
    self.ref         = [[FIRDatabase database] reference];
    self.chatRef     = [_ref child:@"chats"];
}

- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

- (UIStatusBarStyle)preferredStatusBarStyle
{
    return UIStatusBarStyleLightContent;
}

/*
#pragma mark - Navigation

// In a storyboard-based application, you will often want to do a little preparation before navigation
- (void)prepareForSegue:(UIStoryboardSegue *)segue sender:(id)sender {
    // Get the new view controller using [segue destinationViewController].
    // Pass the selected object to the new view controller.
}
*/

- (void)viewWillAppear:(BOOL)animated {
    
    //get actual group pic
    [self showActualGroupPicture];
}

- (IBAction)selectGroupPicture:(id)sender {
    
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
            
            // Get actual group picture name
            [[self.chatRef child:self.openedByChatId] observeSingleEventOfType:FIRDataEventTypeValue withBlock:^(FIRDataSnapshot * _Nonnull snapshot) {
                
                NSString *tempURL = snapshot.value[@"img"];
                
                if (tempURL && ![tempURL isEqualToString:@""]) {
                    self.actualImageName =[[NSURL URLWithString:tempURL] lastPathComponent];
                    NSLog(@"_actualImageName: %@", self.actualImageName);
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
            NSString *fileName = [NSString stringWithFormat:@"%@%@.%@", self.openedByChatId, timeStampString, fileExtension];
            
            // Upload picture to storage
            // Get data from external URL
            NSData *imageData = UIImageJPEGRepresentation([UIImage imageWithData:[NSData dataWithContentsOfURL:[NSURL URLWithString:self.pictureURL.text]]], 0.8);
            
            // Create a reference to the file you want to upload
            FIRStorageReference *avatarsRef = [self.storageRef child:[NSString stringWithFormat:@"groupAvatars/%@", fileName]];
            
            // Upload file and metadata to the object
            FIRStorageUploadTask *uploadTask = [avatarsRef putData:imageData metadata:metadata];
            
            // Show download message
            UIAlertController *view =   [UIAlertController
                                         alertControllerWithTitle:@"Downloading ..."
                                         message:@"Please wait"
                                         preferredStyle:UIAlertControllerStyleAlert];
            
            //desable transparency of UIActionSheets
            UIView * firstView = view.view.subviews.firstObject;
            UIView * nextView = firstView.subviews.firstObject;
            nextView.backgroundColor = [UIColor whiteColor];
            nextView.layer.cornerRadius = 15;
            
            [self presentViewController:view animated:YES completion:nil];
            
            [uploadTask observeStatus:FIRStorageTaskStatusSuccess handler:^(FIRStorageTaskSnapshot *snapshot) {
                
                // Upload completed successfully
                // Set URL for new user pic
                [self setGroupNewValue:[NSString stringWithFormat:@"gs://umessage-80185.appspot.com/groupAvatars/%@", fileName] forKey:@"img"];
                
                // Get actual user pic
                [self showActualGroupPicture];
                [self dismissViewControllerAnimated:YES completion:nil];
                NSLog(@"Upload completed successfully");
                if(self.actualImageName && ![self.actualImageName isEqualToString:@""]){
                    [self deleteGroupFile:self.actualImageName inFolder:@"groupAvatars"];
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
                            
                            /* ... */
                            
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
                                     //Do some thing here
                                     [view dismissViewControllerAnimated:YES completion:nil];
                                     
                                 }];
            
            //desable transparency of UIActionSheets
            UIView * firstView = view.view.subviews.firstObject;
            UIView * nextView = firstView.subviews.firstObject;
            nextView.backgroundColor = [UIColor whiteColor];
            nextView.layer.cornerRadius = 15;
            
            [view addAction:ok];
            [self presentViewController:view animated:YES completion:nil];
            
        }
    
    //set URL for new group pic
    //[self setGroupNewValue:_pictureURL.text forKey:@"img"];
    
    //get actual group pic
    //[self showActualGroupPicture];
    
    //delete actual group pic in the model
    //[self setGroupNewValue:@"" forKey:@"img"];
    
    //delete shown picture
    //_groupPicture.image = nil;
}

- (IBAction)deleteActualyGroupPicture:(id)sender {
    
    // Get actual user pic
    [[self.chatRef child:self.openedByChatId] observeSingleEventOfType:FIRDataEventTypeValue withBlock:^(FIRDataSnapshot * _Nonnull snapshot) {
        
        NSString *imageURL = snapshot.value[@"img"];
        
        if (imageURL && ![imageURL isEqualToString:@""]) {
            NSString *fileName = [[NSURL URLWithString:imageURL] lastPathComponent];
            [self deleteGroupFile:fileName inFolder:@"groupAvatars"];
            
            // Delete actual user pic URL in DB
            [self setGroupNewValue:@"" forKey:@"img"];
            // Delete shown picture
            self.groupPicture.image = nil;
        }
        
    } withCancelBlock:^(NSError * _Nonnull error) {
        NSLog(@"%@", error.localizedDescription);
    }];
    
}

- (void)deleteGroupFile:(NSString *)fileName inFolder:(NSString *)folder {
    
    NSLog(@"deleteGroupFile - fileName: %@", fileName);
    NSLog(@"deleteGroupFile - folder: %@", folder);
    
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

- (void) showActualGroupPicture {
    
    // Get actual group pic
    [[self.chatRef child:self.openedByChatId] observeSingleEventOfType:FIRDataEventTypeValue withBlock:^(FIRDataSnapshot * _Nonnull snapshot) {
        
        NSString *imageURL = snapshot.value[@"img"];
        
        if (imageURL && ![imageURL isEqualToString:@""]) {
            if ([imageURL hasPrefix:@"gs://"]) {
                [TableViewController getAvatar:imageURL withImageView:self.groupPicture];
            } else {
                self.groupPicture.image = [UIImage imageWithData:[NSData dataWithContentsOfURL:[NSURL URLWithString:imageURL]]];
            }
        }
    } withCancelBlock:^(NSError * _Nonnull error) {
        NSLog(@"%@", error.localizedDescription);
    }];
}

//set new value in the model for current group
- (void) setGroupNewValue:(NSString*)value forKey:(NSString*)key {
    
    NSString *chatID = self.openedByChatId;
    NSDictionary *childUpdates = @{[NSString stringWithFormat:@"/chats/%@/%@/", chatID, key]: value};
    [self.ref updateChildValues:childUpdates];
}

- (BOOL) validateUrl: (NSString *) candidate {
    NSString *urlRegEx =
    @"(http|https)://((\\w)*|([0-9]*)|([-|_])*)+([\\.|/]((\\w)*|([0-9]*)|([-|_])*))+";
    NSPredicate *urlTest = [NSPredicate predicateWithFormat:@"SELF MATCHES %@", urlRegEx];
    return [urlTest evaluateWithObject:candidate];
}

@end
