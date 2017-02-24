//
//  TableViewController.m
//  uMessage
//
//  Created by Codecamp on 22.02.17.
//  Copyright © 2017 Codecamp. All rights reserved.
//

@import Photos;
@import CoreLocation;
#import "ChatViewController.h"

@interface ChatViewController ()<UITextFieldDelegate, UIScrollViewDelegate, UIImagePickerControllerDelegate, UINavigationControllerDelegate, UITableViewDataSource, UITableViewDelegate, CLLocationManagerDelegate>{
    FIRDatabaseHandle _refAddHandle;
    FIRDatabaseHandle _refRemoveHandle;
}

@property (strong, nonatomic) IBOutlet UINavigationBar *navigationBar;
@property (strong, nonatomic) IBOutlet UITableView *chatTable;
@property (strong, nonatomic) IBOutlet UITextField *chatMsg;
@property (strong, nonatomic) NSMutableArray<FIRDataSnapshot *> *messages;
@property (strong, nonatomic) IBOutlet UIView *sendView;

@property (strong, nonatomic) FIRStorageReference *storageRef;
@property (strong, nonatomic) CLLocationManager *locationManager;
@property (strong, nonatomic) UIAlertController *alert;

@end

@implementation ChatViewController
- (void)viewDidLoad {
    [super viewDidLoad];
    
    self.ref         = [[FIRDatabase database] reference];
    self.chatRef     = [_ref child:@"messages"];
    self.messagesRef = [_chatRef child:_chatId];
    
    self.chatMsg.delegate = self;
    
    _chatTable.delegate = self;
    _chatTable.dataSource = self;
    
    _messages = [[NSMutableArray alloc] init];
    _navigationBar.topItem.title = self.chatTitle;
    
    // init Storage
    self.storageRef = [[FIRStorage storage] reference];
    
    [_chatTable registerClass:[UITableViewCell class]forCellReuseIdentifier:@"TableViewCell"];
    [self loadMessages];
}

-(IBAction)prepareForUnwind:(UIStoryboardSegue *)segue {
    NSLog(@"Chat unwind");
}


- (IBAction)backButtonPressed:(id)sender {
    [self performSegueWithIdentifier:@"unwindToList" sender:self];
}

- (IBAction)addButtonPressed:(id)sender {
    NSLog(@"AddButton pressed");
}

- (void)viewWillAppear:(BOOL)animated {
    [super viewWillAppear:animated];
    
    [[NSNotificationCenter defaultCenter] addObserver:self
                                             selector:@selector(keyboardWasShown:)
                                                 name:UIKeyboardDidShowNotification object:nil];
    
    [[NSNotificationCenter defaultCenter] addObserver:self
                                             selector:@selector(keyboardWillBeHidden:)
                                                 name:UIKeyboardWillHideNotification object:nil];
}


- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}


- (IBAction)sendAction:(UIButton *)sender {
    // stop editing
    [self.view endEditing:YES];
    
    // current timestamp
    NSISO8601DateFormatter *formatter = [[NSISO8601DateFormatter alloc] init];
    NSString *result = [formatter stringFromDate:[NSDate date]];
    NSDictionary *newMessage = @{@"attUrl": @"",
                                 @"gpsCoord": @"",
                                 @"imgUrl": @"",
                                 @"msgText": _chatMsg.text,
                                 @"msgTs": result,
                                 @"readList": @[[[FIRAuth auth] currentUser].uid],
                                 @"userid": [[FIRAuth auth] currentUser].uid,
                                 @"vid": @"",
                                 @"voiceUrl": @"",
                               };
    
    // add message to databse
    [[_messagesRef childByAutoId] setValue:newMessage];
    _chatMsg.text = @"";

}

- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView {
    return 1;
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section {
    return [_messages count];
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(nonnull NSIndexPath *)indexPath {
    UITableViewCell *cell = [_chatTable dequeueReusableCellWithIdentifier:@"TableViewCell"forIndexPath:indexPath];
    FIRDataSnapshot *messageSnapshot = _messages[indexPath.row];
    NSDictionary<NSString *, NSString *> *message = messageSnapshot.value;
    cell.textLabel.text = message[@"msgText"];
    return cell;
}

- (void) loadMessages{
    _refAddHandle = [_messagesRef observeEventType:FIRDataEventTypeChildAdded withBlock:^(FIRDataSnapshot *snapshot) {
        [_messages addObject:snapshot];
        [_chatTable insertRowsAtIndexPaths:@[[NSIndexPath indexPathForRow:_messages.count-1 inSection:0]] withRowAnimation:UITableViewRowAnimationAutomatic];
        [self scrollToBottom];
    }];
}

-(void)scrollToBottom
{
    [_chatTable scrollToRowAtIndexPath:[NSIndexPath indexPathForRow:self.messages.count-1 inSection:0] atScrollPosition:UITableViewScrollPositionBottom animated:YES];
}

- (void)keyboardWasShown:(NSNotification*)aNotification
{
    NSLog(@"Keyboard was shown.");
    NSDictionary* info = [aNotification userInfo];
    CGSize kbSize = [[info objectForKey:UIKeyboardFrameBeginUserInfoKey] CGRectValue].size;
    
    
    [_chatTable setContentInset:UIEdgeInsetsMake(0, 0, kbSize.height, 0)];
    
    CGRect frame = _sendView.frame;
    frame.origin.y = 608-kbSize.height;
    _sendView.frame = frame;
    
    [self scrollToBottom];
    
    NSLog(@"Keyboard height is %f", kbSize.height);
}

- (void)keyboardWillBeHidden:(NSNotification*)aNotification
{
    NSLog(@"Keyboard will be hidden.");
    [_chatTable setContentInset:UIEdgeInsetsZero];
    CGRect frame = _sendView.frame;
    frame.origin.y = 608;
    _sendView.frame = frame;
    
    [self scrollToBottom];
}


- (BOOL)textFieldShouldReturn:(UITextField *)textField
{
    NSLog(@"TextField should return.");
    if(textField == _chatMsg) {
        [self sendAction:nil];
    }
    return NO;
}


- (IBAction)menuAction:(UIButton *)sender {
    UIAlertController * view =   [UIAlertController
                                 alertControllerWithTitle:nil
                                 message:nil
                                 preferredStyle:UIAlertControllerStyleActionSheet];
    
    
    UIAlertAction* photo = [UIAlertAction
                                 actionWithTitle:@"Foto auswählen"
                                 style:UIAlertActionStyleDefault
                                 handler:^(UIAlertAction * action)
                                 {
                                     UIImagePickerController * picker = [[UIImagePickerController alloc] init];
                                     picker.delegate = self;
                                     
                                     if ([UIImagePickerController isSourceTypeAvailable:UIImagePickerControllerSourceTypeCamera]) {
                                         picker.sourceType = UIImagePickerControllerSourceTypeCamera;
                                     } else {
                                         picker.sourceType = UIImagePickerControllerSourceTypePhotoLibrary;
                                     }
                                     
                                     [self presentViewController:picker animated:YES completion:NULL];
                                                                          
                                     // close menu
                                     [view dismissViewControllerAnimated:YES completion:nil];
                                 }];
    
    
    UIAlertAction* voice = [UIAlertAction
                               actionWithTitle:@"TODO: Sprachnachricht"
                               style:UIAlertActionStyleDefault
                               handler:^(UIAlertAction * action)
                               {
                                   // TODO: voice msg
                                   
                                   // close menu
                                   [view dismissViewControllerAnimated:YES completion:nil];
                               }];
    UIAlertAction* location = [UIAlertAction
                               actionWithTitle:@"TODO: Standort"
                               style:UIAlertActionStyleDefault
                               handler:^(UIAlertAction * action)
                               {
                                   // close menu
                                   [view dismissViewControllerAnimated:YES completion:nil];
                                   
                                   _alert =   [UIAlertController
                                                                 alertControllerWithTitle:@"Bitte warten"
                                                                 message:@"Sendet den aktuellen Standort."
                                                                 preferredStyle:UIAlertControllerStyleAlert];
                                   
                                   [self presentViewController:_alert animated:YES completion:nil];
                                   
                                   [self getCurrentLocation];
                                   
                               }];
    
    UIAlertAction* cancel = [UIAlertAction
                             actionWithTitle:@"Abbrechen"
                             style:UIAlertActionStyleCancel
                             handler:^(UIAlertAction * action)
                             {
                                 // close menu
                                 [view dismissViewControllerAnimated:YES completion:nil];
                                 
                             }];
    
    
    [view addAction:photo];
    [view addAction:voice];
    [view addAction:location];
    [view addAction:cancel];
    [self presentViewController:view animated:YES completion:nil];
}


- (void)imagePickerController:(UIImagePickerController *)picker
didFinishPickingMediaWithInfo:(NSDictionary *)info {
    [picker dismissViewControllerAnimated:YES completion:NULL];
    
    NSURL *referenceURL = info[UIImagePickerControllerReferenceURL];
    // if it's a photo from the library, not an image from the camera
    if (referenceURL) {
        PHFetchResult* assets = [PHAsset fetchAssetsWithALAssetURLs:@[referenceURL] options:nil];
        PHAsset *asset = [assets firstObject];
        [asset requestContentEditingInputWithOptions:nil
                                   completionHandler:^(PHContentEditingInput *contentEditingInput, NSDictionary *info) {
                                       NSURL *imageFile = contentEditingInput.fullSizeImageURL;
                                       NSString *filePath = [NSString stringWithFormat:@"%@/%lld/%@",
                                                             [FIRAuth auth].currentUser.uid,
                                                             (long long)([[NSDate date] timeIntervalSince1970] * 1000.0),
                                                             [referenceURL lastPathComponent]];
                                       [[_storageRef child:filePath]
                                        putFile:imageFile metadata:nil
                                        completion:^(FIRStorageMetadata *metadata, NSError *error) {
                                            if (error) {
                                                NSLog(@"Error uploading: %@", error);
                                                return;
                                            }
                                            [self sendPicture:[_storageRef child:metadata.path].description];
                                        }
                                        ];
                                   }];
    } else {
        UIImage *image = info[UIImagePickerControllerOriginalImage];
        NSData *imageData = UIImageJPEGRepresentation(image, 0.8);
        NSString *imagePath =
        [NSString stringWithFormat:@"%@/%lld.jpg",
         [FIRAuth auth].currentUser.uid,
         (long long)([[NSDate date] timeIntervalSince1970] * 1000.0)];
        FIRStorageMetadata *metadata = [FIRStorageMetadata new];
        metadata.contentType = @"image/jpeg";
        [[_storageRef child:imagePath] putData:imageData metadata:metadata
                                    completion:^(FIRStorageMetadata * _Nullable metadata, NSError * _Nullable error) {
                                        if (error) {
                                            NSLog(@"Error uploading: %@", error);
                                            return;
                                        }
                                        [self sendPicture:[_storageRef child:metadata.path].description];
                                    }];
    }
}

- (void)imagePickerControllerDidCancel:(UIImagePickerController *)picker {
    [picker dismissViewControllerAnimated:YES completion:NULL];
}


- (void)sendPicture:(NSString *)url
{
    // stop editing
    [self.view endEditing:YES];
    
    // current timestamp
    NSISO8601DateFormatter *formatter = [[NSISO8601DateFormatter alloc] init];
    NSString *result = [formatter stringFromDate:[NSDate date]];
    NSDictionary *newMessage = @{@"attUrl": @"",
                                 @"gpsCoord": @"",
                                 @"imgUrl": url,
                                 @"msgText": _chatMsg.text,
                                 @"msgTs": result,
                                 @"readList": @[[[FIRAuth auth] currentUser].uid],
                                 @"userid": [[FIRAuth auth] currentUser].uid,
                                 @"vid": @"",
                                 @"voiceUrl": @"",
                                 };
    
    // add message to databse
    [[_messagesRef childByAutoId] setValue:newMessage];
    _chatMsg.text = @"";

}

- (void)sendLocation:(CLLocation*)location
{
    // stop editing
    [self.view endEditing:YES];
    
    // current location
    NSArray<NSString *> *coords = @[[NSString stringWithFormat:@"%f", location.coordinate.latitude], [NSString stringWithFormat:@"%f", location.coordinate.longitude]];
    
    // current timestamp
    NSISO8601DateFormatter *formatter = [[NSISO8601DateFormatter alloc] init];
    NSString *result = [formatter stringFromDate:[NSDate date]];
    NSDictionary *newMessage = @{@"attUrl": @"",
                                 @"gpsCoord": coords,
                                 @"imgUrl": @"",
                                 @"msgText": @"",
                                 @"msgTs": result,
                                 @"readList": @[[[FIRAuth auth] currentUser].uid],
                                 @"userid": [[FIRAuth auth] currentUser].uid,
                                 @"vid": @"",
                                 @"voiceUrl": @"",
                                 };
    
    // add message to databse
    [[_messagesRef childByAutoId] setValue:newMessage];
    
    // close alert
    [_alert dismissViewControllerAnimated:YES completion:nil];
}

- (void)getCurrentLocation
{
    if(_locationManager == nil) {
        _locationManager = [[CLLocationManager alloc] init];
    }
    
    _locationManager.delegate = self;
    _locationManager.desiredAccuracy = kCLLocationAccuracyNearestTenMeters;
    _locationManager.distanceFilter = kCLDistanceFilterNone;
    
    [self.locationManager requestWhenInUseAuthorization];
    
    [_locationManager startUpdatingLocation];
}

- (void)locationManager:(CLLocationManager *)manager
     didUpdateLocations:(NSArray *)locations {
    
    [self sendLocation:[locations lastObject]];
    
    [_locationManager stopUpdatingLocation];
    _locationManager = nil;
}

@end
