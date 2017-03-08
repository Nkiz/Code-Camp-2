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
#import "BubbleChatCell.h"
#import "BubbleImageChatCell.h"
#import "BubbleLocationChatCell.h"

@interface ChatViewController () <UITextFieldDelegate, UIScrollViewDelegate, UIImagePickerControllerDelegate, UINavigationControllerDelegate, UITableViewDataSource, UITableViewDelegate, CLLocationManagerDelegate> {
    FIRDatabaseHandle _refAddHandle;
    FIRDatabaseHandle _refRemoveHandle;
}

// UI Elements
@property(strong, nonatomic) IBOutlet UINavigationBar *navigationBar;
@property(strong, nonatomic) IBOutlet UITableView *chatTable;
@property(strong, nonatomic) IBOutlet UITextField *chatMsg;
@property(strong, nonatomic) IBOutlet UIView *sendView;
@property(strong, nonatomic) UIAlertController *alert;

// Chat
@property(strong, nonatomic) NSString *currentUserID;
@property(strong, nonatomic) NSMutableDictionary<NSString *, NSString *> *users;
@property(strong, nonatomic) NSMutableArray<FIRDataSnapshot *> *messages;
@property BOOL isGroup;

// Storage
@property(strong, nonatomic) FIRStorageReference *storageRef;

// Position Manager
@property(strong, nonatomic) CLLocationManager *locationManager;

@end

@implementation ChatViewController

#pragma mark Initialisation

/**
 Init UI Elements and get / display chat information.
 */
- (void)viewDidLoad
{
    [super viewDidLoad];
    
    [self initDelegates];
    [self initDatabase];
    [self initStorage];
    [self initTable];
    [self initChat];
}

/**
 Set controller as delegate
 */
- (void)initDelegates
{
    self.chatMsg.delegate = self;
    self.chatTable.delegate = self;
    self.chatTable.dataSource = self;
}

/**
 Get references to database tables
 */
- (void)initDatabase
{
    self.ref = [[FIRDatabase database] reference];
    self.chatRef = [self.ref child:MessagesTable];
    self.messagesRef = [self.chatRef child:self.chatId];
}

/**
 Get Storage Reference
 */
- (void)initStorage
{
    self.storageRef = [[FIRStorage storage] reference];
}

/**
 Set cell height to auto and register cell styles
 */
- (void)initTable
{
    // automatic table view height
    self.chatTable.rowHeight = UITableViewAutomaticDimension;
    self.chatTable.estimatedRowHeight = 71.0;
    
    // register bubble cell types
    [self.chatTable registerClass:[BubbleChatCell class] forCellReuseIdentifier:BubbleCellId];
    [self.chatTable registerClass:[BubbleImageChatCell class] forCellReuseIdentifier:BubbleImageCellId];
    [self.chatTable registerClass:[BubbleLocationChatCell class] forCellReuseIdentifier:BubbleLocationCellId];
}

/**
 Init local variables, get usernames and load messages
 */
- (void)initChat
{
    // init local vars
    self.users = [[NSMutableDictionary alloc] init];
    self.messages = [[NSMutableArray alloc] init];
    self.currentUserID = [[FIRAuth auth] currentUser].uid;
    
    // group chat, if more than 2 other user are in this chat
    self.isGroup = [self.chatUserlist count] > 1;
    
    [self getUsernames];
}

/**
 Get username for each userid in chat.
 Load messages from database.
 */
- (void)getUsernames
{
    for(NSString *userID in self.chatUserlist) {
        // get user entry from db
        [[[self.ref child:UsersTable] child:userID] observeSingleEventOfType:FIRDataEventTypeValue withBlock:^(FIRDataSnapshot * _Nonnull snapshot) {
            NSString *name = snapshot.value[Username];
            [self.users setValue:name forKey:userID];
            
            // Check if we have all usernames
            if([self.users count] == [self.chatUserlist count]) {
                [self displayTitle];
                [self loadMessages];
            }
        } withCancelBlock:^(NSError * _Nonnull error) {
            NSLog(@"%@", error.localizedDescription);
        }];
    }
}

- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
}

#pragma mark UI Functions

/**
 Display all usernames as title
 */
- (void)displayTitle
{
    NSMutableArray *usernames = [[NSMutableArray alloc] init];
    NSString *myName = self.users[self.currentUserID];
    
    // dont show own name
    for(NSString *name in [self.users allValues]) {
        if(![name isEqualToString:myName]) {
            [usernames addObject:name];
        }
    }
    
    // sort names alphabetically
    NSArray *sortedNames = [usernames sortedArrayUsingSelector:@selector(localizedCaseInsensitiveCompare:)];
    
    // convert array to string
    NSString* title = [sortedNames componentsJoinedByString:@", "];
    
    // show as navigation bar title
    //self.navigationBar.topItem.title = title;
    self.navigationBar.topItem.title = _chatTitle;
}

/**
 Prepare a segue unwind.
 
 @param segue Unwind Segue
 */
- (IBAction)prepareForUnwind:(UIStoryboardSegue *)segue {
    NSLog(@"Chat unwind.");
}

/**
 Add keyboard event listener.
 
 @param animated If YES, use animation
 */
- (void)viewWillAppear:(BOOL)animated {
    [super viewWillAppear:animated];
    
    [[NSNotificationCenter defaultCenter] addObserver:self
                                             selector:@selector(keyboardWillShow:)
                                                 name:UIKeyboardWillShowNotification object:nil];
    
    [[NSNotificationCenter defaultCenter] addObserver:self
                                             selector:@selector(keyboardWillBeHidden:)
                                                 name:UIKeyboardWillHideNotification object:nil];
}

/**
 If the keyboard is shown, resize content to show the TextField.
 */
- (void)keyboardWillShow:(NSNotification *)aNotification {
    NSLog(@"Keyboard was shown.");
    
    // Get keyboard size
    NSDictionary *info = [aNotification userInfo];
    CGSize kbSize = [[info objectForKey:UIKeyboardFrameBeginUserInfoKey] CGRectValue].size;
    
    CGRect tableFrame = self.chatTable.frame;
    tableFrame.size.height -= kbSize.height;
    
    CGRect frame = self.sendView.frame;
    frame.origin.y = 608 - kbSize.height;
    
    [UIView beginAnimations:nil context:NULL];
    [UIView setAnimationBeginsFromCurrentState:YES];
    [UIView setAnimationDuration:0.3f];
    
    // show content hidden by keyboard
    self.sendView.frame = frame;
    self.chatTable.frame = tableFrame;
    
    [UIView commitAnimations];
    
    [self scrollToBottom:YES];
}

/**
 Reset content position, when keyboard is hidden.
 */
- (void)keyboardWillBeHidden:(NSNotification *)aNotification {
    NSLog(@"Keyboard will be hidden.");
    
    CGRect tableFrame = self.chatTable.frame;
    tableFrame.size.height = 545;
    
    CGRect frame = self.sendView.frame;
    frame.origin.y = 608;
    
    [UIView beginAnimations:nil context:NULL];
    [UIView setAnimationBeginsFromCurrentState:YES];
    [UIView setAnimationDuration:0.3f];
    
    self.sendView.frame = frame;
    self.chatTable.frame = tableFrame;
    
    [UIView commitAnimations];
    
    [self scrollToBottom:YES];
}


#pragma mark UI Actions


/**
 Go back to chat list, when back button in navigation bar is pressed.
 */
- (IBAction)backButtonPressed:(id)sender {
    [self performSegueWithIdentifier:@"unwindToList" sender:self];
}

/**
 Show menu, when add button in navigation bar is pressed.
 */
- (IBAction)addButtonPressed:(id)sender {
    NSLog(@"AddButton pressed");
}

/**
 Send text message, when send button is pressed.
 */
- (IBAction)sendAction:(UIButton *)sender {
    [self checkNewChat];
    // stop editing
    [self.view endEditing:YES];
    
    // get current timestamp
    NSISO8601DateFormatter *formatter = [[NSISO8601DateFormatter alloc] init];
    NSString *timestamp = [formatter stringFromDate:[NSDate date]];
    
    NSDictionary *newMessage = @{MessageAttachment: EmptyString,
                                 MessageLocation: EmptyString,
                                 MessageImage: EmptyString,
                                 MessageText: self.chatMsg.text,
                                 MessageTimestamp: timestamp,
                                 MessageReadlist: @[self.currentUserID],
                                 MessageUserID: self.currentUserID,
                                 MessageVideo: EmptyString,
                                 MessageVoice: EmptyString,
                                 };
    [self sendMessage:newMessage withTimestamp:timestamp];
}

/**
 Send Message to Database
 */
- (void)checkNewChat{
   NSDictionary *userList =  @{@"0":_messageUser,
                               @"1": [FIRAuth auth].currentUser.uid};
    NSDictionary *childUpdates = @{[NSString stringWithFormat:@"/chats/%@/userlist/", self.chatId]: userList};
    [self.ref updateChildValues:childUpdates];
}
- (void)sendMessage:(NSDictionary *)msg withTimestamp:(NSString *)timestamp
{
    // add message to databse
    [[self.messagesRef childByAutoId] setValue:msg];
    
    //Write last message in chat
    [self updateLastChatMessage:self.chatMsg.text withTimestamp:timestamp];
    
    // reset textfield
    self.chatMsg.text = EmptyString;
}

/**
 Only 1 section for chat
 */
- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView {
    return 1;
}

/**
 Number of rows is the number of chat messages
 */
- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section {
    return [self.messages count];
}

/**
 Check if a message with location is selected and open maps.
 */
- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath {
    [self.view endEditing:YES];
    
    // get message for row
    FIRDataSnapshot *messageSnapshot = self.messages[indexPath.row];
    NSDictionary<NSString *, NSString *> *message = messageSnapshot.value;
    
    // is location message ?
    if ([message[MessageLocation] isEqual:EmptyString]) return;
    
    // get coordinates
    NSArray *coord = (NSArray *) message[MessageLocation];
    CGFloat latitude = [coord[0] floatValue];
    CGFloat longitude = [coord[1] floatValue];
    
    // open maps with location and username
    NSString *url = [NSString stringWithFormat:@"http://maps.apple.com/?t=m&q=%@&ll=%f,%f",  self.users[message[MessageUserID]], latitude, longitude];
    NSURL *targetURL = [NSURL URLWithString:url];
    [[UIApplication sharedApplication] openURL:targetURL];
}

/**
 Generate Bubble Chat Cell for row
 */
- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(nonnull NSIndexPath *)indexPath {
    // get chat entry
    FIRDataSnapshot *messageSnapshot = self.messages[indexPath.row];
    NSDictionary<NSString *, NSString *> *message = messageSnapshot.value;
    
    NSString *msg = message[MessageText];
    
    // get content type
    BOOL showImage = NO;
    BOOL showLocation = NO;
    if ([msg isEqual:EmptyString]) {
        if (![message[MessageImage] isEqual:EmptyString]) {
            showImage = YES;
        } else if (![message[MessageLocation] isEqual:EmptyString]) {
            showLocation = YES;
        }
    }
    BubbleChatCell *cell;
    
    if (showImage) {
        // create image cell
        cell = [self.chatTable dequeueReusableCellWithIdentifier:BubbleImageCellId forIndexPath:indexPath];
        
        NSString *imageURL = message[MessageImage];
        
        // is from firebase storage?
        if ([imageURL hasPrefix:@"gs://"]) {
            BubbleImageChatCell* imgCell = (BubbleImageChatCell*) cell;
            
            // download from storage
            [[[FIRStorage storage] referenceForURL:imageURL] dataWithMaxSize:INT64_MAX
                                                                  completion:^(NSData *data, NSError *error) {
                                                                      if (error) {
                                                                          NSLog(@"Error downloading: %@", error);
                                                                          return;
                                                                      }
                                                                      NSLog(@"IMAGE LOADED.");
                                                                      [imgCell showImage:[UIImage imageWithData: data]];
                                                                      //[tableView reloadData];
                                                                  }];
        } else {
            // get image from url
            [(BubbleImageChatCell*)cell showImage:[UIImage imageWithData:[NSData dataWithContentsOfURL:[NSURL URLWithString:imageURL]]]];
        }
        
    } else if (showLocation) {
        // create location cell
        cell = [self.chatTable dequeueReusableCellWithIdentifier:BubbleLocationCellId forIndexPath:indexPath];
        NSArray *coord = (NSArray *) message[MessageLocation];
        CGFloat latitude = [coord[0] floatValue];
        CGFloat longitude = [coord[1] floatValue];
        
        [(BubbleLocationChatCell *) cell showLocation:latitude withLongitute:longitude];
    } else {
        // use default cell
        cell = [self.chatTable dequeueReusableCellWithIdentifier:BubbleCellId forIndexPath:indexPath];
    }
    
    // is my message?
    BOOL myMsg = NO;
    if ([message[MessageUserID] isEqualToString:self.currentUserID]) {
        [cell setStyle:MyBubble];
        myMsg = YES;
    } else {
        if (self.isGroup) {
            // group chat style
            [cell setStyle:GroupBubble];
        } else {
            // private chat style
            [cell setStyle:PrivateBubble];
        }
    }
    
    // Format Date
    NSISO8601DateFormatter *dateFormat = [[NSISO8601DateFormatter alloc] init];
    NSDate *date = [dateFormat dateFromString:message[MessageTimestamp]];
    NSString *dateStr = EmptyString;
    NSString *timeStr = [NSDateFormatter localizedStringFromDate:date
                                                       dateStyle:NSDateFormatterNoStyle
                                                       timeStyle:NSDateFormatterShortStyle];
    
    // show date if its send before yesterday
    if ([[NSCalendar currentCalendar] isDateInToday:date]) {
        dateStr = Today;
    } else if ([[NSCalendar currentCalendar] isDateInYesterday:date]) {
        dateStr = Yesterday;
    } else {
        dateStr = [NSDateFormatter localizedStringFromDate:date
                                                 dateStyle:NSDateFormatterShortStyle
                                                 timeStyle:NSDateFormatterNoStyle];
    }
    
    if(myMsg && [self checkIsReadByAll:messageSnapshot]) {
        timeStr = [@"✓ " stringByAppendingString:timeStr];
    }
    
    cell.user.text = self.users[message[MessageUserID]];
    cell.date.text = dateStr;
    cell.time.text = timeStr;
    cell.message.text = msg;
    
    // only show date, if first entry for that day
    [cell hideDate:[self hideDate:indexPath.row]];
    
    return cell;
}

/**
 Check if a previous message was send on the same day.

 @param row table row index
 @return Returns YES, if a previous message was written on the same day
 */
- (BOOL)hideDate:(NSInteger)row {
    // always show first date
    if (row == 0) {
        return NO;
    } else {
        FIRDataSnapshot *messageSnapshot = self.messages[row];
        NSDictionary<NSString *, NSString *> *message = messageSnapshot.value;
        
        // current message date
        NSISO8601DateFormatter *dateFormat = [[NSISO8601DateFormatter alloc] init];
        NSDate *myDate = [dateFormat dateFromString:message[MessageTimestamp]];
        
        // previous message date
        messageSnapshot = self.messages[row - 1];
        message = messageSnapshot.value;
        NSDate *prevDate = [dateFormat dateFromString:message[MessageTimestamp]];
        
        // compare dates
        return [[NSCalendar currentCalendar] isDate:myDate inSameDayAsDate:prevDate];
    }
}

/**
 Start Message Handler. Show every new message in chat table
 */
- (void)loadMessages {
    _refAddHandle = [self.messagesRef observeEventType:FIRDataEventTypeChildAdded withBlock:^(FIRDataSnapshot *snapshot) {
        [self.messages addObject:snapshot];
        
        // animate if unread
        BOOL animate = [self checkIsRead:snapshot];
        
        [self.chatTable insertRowsAtIndexPaths:@[[NSIndexPath indexPathForRow:self.messages.count - 1 inSection:0]] withRowAnimation:UITableViewRowAnimationBottom];
        [self scrollToBottom:animate];
    }];
}

/**
 Check if the message was read by the user.
 Updates readlist in database.
 */
- (BOOL)checkIsRead:(FIRDataSnapshot *)msg {
    NSDictionary<NSString *, NSString *> *message = msg.value;
    
    NSArray *readList = (NSArray *) message[MessageReadlist];
    
    // check if unread
    if (![readList containsObject:self.currentUserID]) {
        
        // update readList in db
        NSString *key = MessageReadlist;
        NSDictionary *childUpdates = @{[NSString stringWithFormat:@"/messages/%@/%@/%@/", self.chatId, msg.key, key]: [readList arrayByAddingObject:self.currentUserID]};
        [self.ref updateChildValues:childUpdates];
        
        return NO;
    }
    
    return YES;
}
/**
 Check if the message was read by all users in chat.
 */
- (BOOL)checkIsReadByAll:(FIRDataSnapshot *)msg {
    NSDictionary<NSString *, NSString *> *message = msg.value;
    
    NSArray *readList = (NSArray *) message[MessageReadlist];
    
    // are all users in readlist?
    if([readList count] == [self.users count]) {
        return YES;
    }
    
    return NO;
}

/**
 Scroll to latest chat message
 */
- (void)scrollToBottom:(BOOL)animated {
    if (self.messages.count > 0) {
        [self.chatTable scrollToRowAtIndexPath:[NSIndexPath indexPathForRow:self.messages.count - 1 inSection:0] atScrollPosition:UITableViewScrollPositionBottom animated:animated];
    }
}

/**
 Handles keyboard return action.
 */
- (BOOL)textFieldShouldReturn:(UITextField *)textField {
    NSLog(@"TextField should return.");
    
    // was send button on keyboard pressed?
    if (textField == self.chatMsg) {
        // send message
        [self sendAction:nil];
    }
    return NO;
}

/**
 Handles send menu action. (plus icon button)
 */
- (IBAction)menuAction:(UIButton *)sender {
    UIAlertController *view = [UIAlertController
                               alertControllerWithTitle:nil
                               message:nil
                               preferredStyle:UIAlertControllerStyleActionSheet];
    
    // choose photo from library
    UIAlertAction *photo = [UIAlertAction
                            actionWithTitle:ChoosePhotoString
                            style:UIAlertActionStyleDefault
                            handler:^(UIAlertAction *action) {
                                UIImagePickerController *picker = [[UIImagePickerController alloc] init];
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
    
    // send voice message
    UIAlertAction *voice = [UIAlertAction
                            actionWithTitle:SendVoiceString
                            style:UIAlertActionStyleDefault
                            handler:^(UIAlertAction *action) {
                                // TODO: voice msg
                                
                                // close menu
                                [view dismissViewControllerAnimated:YES completion:nil];
                            }];
    
    // send current location
    UIAlertAction *location = [UIAlertAction
                               actionWithTitle:SendLocationString
                               style:UIAlertActionStyleDefault
                               handler:^(UIAlertAction *action) {
                                   // close menu
                                   [view dismissViewControllerAnimated:YES completion:nil];
                                   
                                   // show alert while sending current location
                                   self.alert = [UIAlertController
                                             alertControllerWithTitle:PleaseWaitString
                                             message:GetLocationString
                                             preferredStyle:UIAlertControllerStyleAlert];
                                   
                                   [self presentViewController:self.alert animated:YES completion:nil];
                                   
                                   [self getCurrentLocation];
                               }];
    
    // close menu without action
    UIAlertAction *cancel = [UIAlertAction
                             actionWithTitle:CancelString
                             style:UIAlertActionStyleCancel
                             handler:^(UIAlertAction *action) {
                                 // close menu
                                 [view dismissViewControllerAnimated:YES completion:nil];
                                 
                             }];
    
    // add menu entries
    [view addAction:photo];
    [view addAction:voice];
    [view addAction:location];
    [view addAction:cancel];
    
    // show menu
    [self presentViewController:view animated:YES completion:nil];
}

/**
 Display image picker
 */
- (void)imagePickerController:(UIImagePickerController *)picker
didFinishPickingMediaWithInfo:(NSDictionary *)info {
    [picker dismissViewControllerAnimated:YES completion:NULL];
    
    self.alert = [UIAlertController
              alertControllerWithTitle:PleaseWaitString
              message:UploadImageString
              preferredStyle:UIAlertControllerStyleAlert];
    
    NSURL *referenceURL = info[UIImagePickerControllerReferenceURL];
    
    // if it's a photo from the library, not an image from the camera
    if (referenceURL) {
        PHFetchResult *assets = [PHAsset fetchAssetsWithALAssetURLs:@[referenceURL] options:nil];
        PHAsset *asset = [assets firstObject];
        [asset requestContentEditingInputWithOptions:nil
                                   completionHandler:^(PHContentEditingInput *contentEditingInput, NSDictionary *info) {
                                       NSURL *imageFile = contentEditingInput.fullSizeImageURL;
                                       NSString *filePath = [NSString stringWithFormat:@"%@/%lld/%@",
                                                             [FIRAuth auth].currentUser.uid,
                                                             (long long) ([[NSDate date] timeIntervalSince1970] * 1000.0),
                                                             [referenceURL lastPathComponent]];
                                       [[self.storageRef child:filePath]
                                        putFile:imageFile metadata:nil
                                        completion:^(FIRStorageMetadata *metadata, NSError *error) {
                                            // close alert
                                            [self.alert dismissViewControllerAnimated:YES completion:nil];
                                            
                                            if (error) {
                                                NSLog(@"Error uploading: %@", error);
                                                return;
                                            }
                                            // add message after image upload
                                            [self sendPicture:[self.storageRef child:metadata.path].description];
                                        }
                                        ];
                                   }];
    } else {
        UIImage *image = info[UIImagePickerControllerOriginalImage];
        NSData *imageData = UIImageJPEGRepresentation(image, 0.8);
        NSString *imagePath =
        [NSString stringWithFormat:@"%@/%lld.jpg",
         [FIRAuth auth].currentUser.uid,
         (long long) ([[NSDate date] timeIntervalSince1970] * 1000.0)];
        FIRStorageMetadata *metadata = [FIRStorageMetadata new];
        metadata.contentType = @"image/jpeg";
        [[self.storageRef child:imagePath] putData:imageData metadata:metadata
                                    completion:^(FIRStorageMetadata *_Nullable metadata, NSError *_Nullable error) {
                                        // close alert
                                        [self.alert dismissViewControllerAnimated:YES completion:nil];
                                        
                                        if (error) {
                                            NSLog(@"Error uploading: %@", error);
                                            return;
                                        }
                                        // add message after image upload
                                        [self sendPicture:[self.storageRef child:metadata.path].description];
                                    }];
    }
}

/**
 Close image picker
 */
- (void)imagePickerControllerDidCancel:(UIImagePickerController *)picker {
    [picker dismissViewControllerAnimated:YES completion:NULL];
}

/**
 Send image message.

 @param url URL to image file
 */
- (void)sendPicture:(NSString *)url {
    // stop editing
    [self.view endEditing:YES];
    
    // current timestamp
    NSISO8601DateFormatter *formatter = [[NSISO8601DateFormatter alloc] init];
    NSString *result = [formatter stringFromDate:[NSDate date]];
    NSDictionary *newMessage = @{MessageAttachment: EmptyString,
                                 MessageLocation: EmptyString,
                                 MessageImage: url,
                                 MessageText: self.chatMsg.text,
                                 MessageTimestamp: result,
                                 MessageReadlist: @[self.currentUserID],
                                 MessageUserID: self.currentUserID,
                                 MessageVideo: EmptyString,
                                 MessageVoice: EmptyString,
                                 };
    
    // add message to databse
    [[self.messagesRef childByAutoId] setValue:newMessage];
    
    // Write last message in chat
    [self updateLastChatMessage:ImageString withTimestamp:result];
    
    self.chatMsg.text = EmptyString;
}


/**
 Send location message.

 @param location Latitude and Longitude of current Location
 */
- (void)sendLocation:(CLLocation *)location {
    // stop editing
    [self.view endEditing:YES];
    
    // current location
    NSArray<NSString *> *coords = @[[NSString stringWithFormat:@"%f", location.coordinate.latitude], [NSString stringWithFormat:@"%f", location.coordinate.longitude]];
    
    // current timestamp
    NSISO8601DateFormatter *formatter = [[NSISO8601DateFormatter alloc] init];
    NSString *result = [formatter stringFromDate:[NSDate date]];
    NSDictionary *newMessage = @{MessageAttachment: EmptyString,
                                 MessageLocation: coords,
                                 MessageImage: EmptyString,
                                 MessageText: EmptyString,
                                 MessageTimestamp: result,
                                 MessageReadlist: @[[[FIRAuth auth] currentUser].uid],
                                 MessageUserID: [[FIRAuth auth] currentUser].uid,
                                 MessageVideo: EmptyString,
                                 MessageVoice: EmptyString,
                                 };
    
    // add message to databse
    [[self.messagesRef childByAutoId] setValue:newMessage];
    
    //Write last message in chat
    [self updateLastChatMessage:LocationString withTimestamp:result];
    
    // close alert
    [self.alert dismissViewControllerAnimated:YES completion:nil];
}

/**
 Update last message of chat in database for chat list

 @param msg text of the last message
 @param timestamp timestamp of the last message
 */
- (void)updateLastChatMessage:(NSString *)msg withTimestamp:(NSString *)timestamp {
    NSDictionary *childUpdates = @{[NSString stringWithFormat:@"/chats/%@/%@/", self.chatId, ChatLastMessage]: msg,
                                   [NSString stringWithFormat:@"/chats/%@/%@/", self.chatId, ChatLastMessageTimestamp]: timestamp};
    [self.ref updateChildValues:childUpdates];
}


/**
 Start Location Manager to get current user location.
 */
- (void)getCurrentLocation {
    if (self.locationManager == nil) {
        self.locationManager = [[CLLocationManager alloc] init];
    }
    
    self.locationManager.delegate = self;
    self.locationManager.desiredAccuracy = kCLLocationAccuracyNearestTenMeters;
    self.locationManager.distanceFilter = kCLDistanceFilterNone;
    
    // check permission
    [self.locationManager requestWhenInUseAuthorization];
    
    [self.locationManager startUpdatingLocation];
}

/**
 Send current location and stop location manager.
 */
- (void)locationManager:(CLLocationManager *)manager
     didUpdateLocations:(NSArray *)locations {
    
    [self sendLocation:[locations lastObject]];
    
    [self.locationManager stopUpdatingLocation];
    self.locationManager = nil;
}


- (UIStatusBarStyle)preferredStatusBarStyle
{
    return UIStatusBarStyleLightContent;
}


@end
