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
#import "GroupViewController.h"
#import "BubbleChatCell.h"
#import "BubbleImageChatCell.h"
#import "BubbleLocationChatCell.h"
#import "GroupSettingsViewController.h"

@interface ChatViewController () <UITextFieldDelegate, UIScrollViewDelegate, UIImagePickerControllerDelegate, UINavigationControllerDelegate, UITableViewDataSource, UITableViewDelegate, CLLocationManagerDelegate> {
    FIRDatabaseHandle _refAddHandle;
    FIRDatabaseHandle _refRemoveHandle;
    FIRDatabaseHandle _refAddChatHandle;
}

// UI Elements
@property(strong, nonatomic) IBOutlet UINavigationBar *navigationBar;
@property(strong, nonatomic) IBOutlet UITableView *chatTable;
@property(strong, nonatomic) IBOutlet UITextField *chatMsg;
@property(strong, nonatomic) IBOutlet UIView *sendView;
@property(strong, nonatomic) UIAlertController *alert;
@property (strong, nonatomic) IBOutlet UIBarButtonItem *removeButton;

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
    self.allChatsRef = [self.ref child:ChatsTable];
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
    self.isGroup = [self.chatUserlist count] > 2;
    
    // hide remove from group in private chat
    if(!self.isGroup)
    {
        [self.removeButton setEnabled:NO];
        [self.removeButton setTintColor: [UIColor clearColor]];
    }
    
    [self getUsernames];
    [self checkNewChat];
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
    
    for(NSString *userId in self.chatUserlist) {
        // dont show own name
        if(![userId isEqualToString:self.currentUserID]) {
            NSString *name = self.users[userId];
            
            if(name != nil) {
                [usernames addObject:name];
            }
        }
    }
    
    // sort names alphabetically
    NSArray *sortedNames = [usernames sortedArrayUsingSelector:@selector(localizedCaseInsensitiveCompare:)];
    
    // convert array to string
    NSString* title = [sortedNames componentsJoinedByString:@", "];
    
    // show as navigation bar title
    self.navigationBar.topItem.title = title;
    //self.navigationBar.topItem.title = _chatTitle;
}

- (void)checkNewUsers
{
    [[[_allChatsRef child:_chatId] child:@"userlist"] observeEventType:FIRDataEventTypeChildAdded withBlock:^(FIRDataSnapshot * _Nonnull snapshot) {
        // Bug: Firebase sends wrong userID
        // Reload complete userList and find new users
        [self reloadUserList];
    }];
    
    [[[_allChatsRef child:_chatId] child:@"userlist"] observeEventType:FIRDataEventTypeChildRemoved withBlock:^(FIRDataSnapshot * _Nonnull snapshot) {
        // Bug: Firebase sends wrong userID
        // Reload complete userList and find new users
        [self reloadUserList];
    }];
}

- (void)reloadUserList {
    [[[_allChatsRef child:_chatId] child:@"userlist"] observeSingleEventOfType:FIRDataEventTypeValue withBlock:^(FIRDataSnapshot * _Nonnull snapshot) {
        // update userlist
        _chatUserlist = [NSMutableArray arrayWithArray:[[NSSet setWithArray:snapshot.value] allObjects]];
        BOOL oldIsGroup = _isGroup;
        _isGroup = [_chatUserlist count] > 2;
        
        if(oldIsGroup != _isGroup) {
            // reload data to display correct chat bubbles
            [_chatTable reloadData];
            [self scrollToBottom:YES];
        }
        
        // update title
        [self displayTitle];
        
        for(NSString *userId in _chatUserlist) {
            // get username
            NSString *userName = [self.users objectForKey:userId];
                
            // new user name
            if(userName == nil) {
                [[[[self.ref child:UsersTable] child:userId] child:@"username"] observeSingleEventOfType:FIRDataEventTypeValue withBlock:^(FIRDataSnapshot * _Nonnull snapshot) {
                        NSLog(@"Username from DB");
                        
                        [_chatUserlist addObject:userId];
                        [self.users setValue:snapshot.value forKey:userId];
                        
                        // update title with new username
                        [self displayTitle];
                }];
            }
        }
    }];
}

/**
 Prepare a segue unwind.
 
 @param segue Unwind Segue
 */
- (IBAction)prepareForUnwind:(UIStoryboardSegue *)segue {
    NSLog(@"Chat unwind: %@", [segue identifier]);
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
    [self.allChatsRef removeObserverWithHandle:_refAddChatHandle];
}

/**
// Show menu, when add new contact button in alert dialog is pressed.
*/
- (IBAction)addButtonPressed:(id)sender {
    //opened Bye
    [self performSegueWithIdentifier:@"ChatToGroup" sender:self];
    NSLog(@"AddButton pressed");
}


// Leave this group, when leave group button in alert dialog is pressed.
 
- (IBAction)leaveGroup:(id)sender {
    [[_allChatsRef child:_chatId] observeSingleEventOfType:FIRDataEventTypeValue withBlock:^(FIRDataSnapshot * _Nonnull snapshot) {
        NSDictionary<NSString *, NSString *> *userData = snapshot.value;
        //NSMutableArray<NSString*> *userDataList = [userData allValues];
        NSMutableArray *userList = snapshot.value[@"userlist"];
        //[tmpUserRelList addObjectsFromArray:userList];
        [userList removeObject:[FIRAuth auth].currentUser.uid];
        [userData setValue:userList forKeyPath:@"userlist"];
        NSDictionary *childUpdates = @{_chatId: userData};
        // add user to databse
        [_allChatsRef updateChildValues:childUpdates];
        [self performSegueWithIdentifier:@"unwindToList" sender:self];
        [self.allChatsRef removeObserverWithHandle:_refAddChatHandle];
    }];
}


/**
 Send text message, when send button is pressed.
 */
- (IBAction)sendAction:(UIButton *)sender {
    // stop editing
    [self.view endEditing:YES];
    
    // dont send empty message
    NSString *text = self.chatMsg.text;
    if([text length] == 0) {
        return;
    }
    
    // get current timestamp
    NSString *timestamp = [Utils getTimestamp];
    
    NSDictionary *newMessage = @{MessageLocation: EmptyString,
                                 MessageImage: EmptyString,
                                 MessageText: text,
                                 MessageTimestamp: timestamp,
                                 MessageReadlist: @[self.currentUserID],
                                 MessageUserID: self.currentUserID
                                 };
    
    [self sendMessage:newMessage withTimestamp:timestamp];
}

/**
 Send Message to Database
 */
- (void)checkNewChat{
    //[] self.chatId
    _refAddChatHandle = [self.allChatsRef observeEventType:FIRDataEventTypeChildAdded withBlock:^(FIRDataSnapshot *snapshot) {
        NSDictionary<NSString *, NSString *> *chat = snapshot.value;
        NSArray *userListArr = [ chat objectForKey:@"userlist"];
        NSString *lstMsg     = [ chat objectForKey:@"lastMsg"];
        
        if(userListArr == nil){
            NSDictionary *userList =  @{@"0":_messageUser,
                                        @"1": [FIRAuth auth].currentUser.uid};
            NSDictionary *childUpdates = @{[NSString stringWithFormat:@"/chats/%@/userlist/", self.chatId]: userList};
            [self.ref updateChildValues:childUpdates];
        }
    }];
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
            
            [self getImage:imageURL withImageView:imgCell.image];
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
    
    NSString *username = self.users[message[MessageUserID]];
    
    if(username == nil) {
        username = @"[Username]";
    }
    
    cell.user.text = username;
    cell.date.text = dateStr;
    cell.time.text = timeStr;
    cell.message.text = msg;
    
    // only show date, if first entry for that day
    [cell hideDate:[self hideDate:indexPath.row]];
    
    return cell;
}

// Download image to documents
-(void)getImage:(NSString *)url withImageView:(UIImageView *)imageView
{
    //   0   1 2                          3                            4             5
    // @""gs://umessage-80185.appspot.com/DNZPu76tgmb5bvPJAvDMiq6RhYb2/1487939843972/asset.JPG"";
    NSArray *urlComponents = [url componentsSeparatedByString:@"/"];
    
    NSArray *paths = NSSearchPathForDirectoriesInDomains(NSDocumentDirectory, NSUserDomainMask, YES);
    NSString *documentsDirectory = paths[0];
    NSString *filePath = [NSString stringWithFormat:@"file:%@/%@/%@/%@", documentsDirectory, urlComponents[3], urlComponents[4], urlComponents[5]];
    NSURL *fileURL = [NSURL URLWithString:filePath];
    
    if ([[NSFileManager defaultManager] fileExistsAtPath:fileURL.path]) {
        NSLog(@"Load image from documents");
        imageView.image = [UIImage imageWithContentsOfFile:fileURL.path];
    } else {
        // Start Download
        [[[FIRStorage storage] referenceForURL:url]
         writeToFile:fileURL
         completion:^(NSURL * _Nullable URL, NSError * _Nullable error) {
             if (error) {
                 NSLog(@"Error downloading: %@", error);
                 return;
             } else if (URL) {
                 NSLog(@"Load image from storage");
                 imageView.image = [UIImage imageWithContentsOfFile:fileURL.path];
             }
         }];
    }    
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
    // check if new users are added
    [self checkNewUsers];
    
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
    
    // take a new photo
    UIAlertAction *takePhoto = [UIAlertAction
                            actionWithTitle:TakePhotoString
                            style:UIAlertActionStyleDefault
                            handler:^(UIAlertAction *action) {
                                UIImagePickerController *picker = [[UIImagePickerController alloc] init];
                                picker.delegate = self;picker.sourceType = UIImagePickerControllerSourceTypeCamera;
                                
                                [self presentViewController:picker animated:YES completion:NULL];
                                
                                // close menu
                                [view dismissViewControllerAnimated:YES completion:nil];
                            }];
    
    // choose photo from library
    UIAlertAction *photo = [UIAlertAction
                            actionWithTitle:ChoosePhotoString
                            style:UIAlertActionStyleDefault
                            handler:^(UIAlertAction *action) {
                                UIImagePickerController *picker = [[UIImagePickerController alloc] init];
                                picker.delegate = self;
                                picker.sourceType = UIImagePickerControllerSourceTypePhotoLibrary;
                                
                                [self presentViewController:picker animated:YES completion:NULL];
                                
                                // close menu
                                [view dismissViewControllerAnimated:YES completion:nil];
                            }];
    /*
    // send voice message
    UIAlertAction *voice = [UIAlertAction
                            actionWithTitle:SendVoiceString
                            style:UIAlertActionStyleDefault
                            handler:^(UIAlertAction *action) {
                                // TODO: voice msg
                                
                                // close menu
                                [view dismissViewControllerAnimated:YES completion:nil];
                            }];
    */
     
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
    
    // Check if camera is available (simulator)
    if ([UIImagePickerController isSourceTypeAvailable:UIImagePickerControllerSourceTypeCamera]) {
        [view addAction:takePhoto];
    }
    
    // disable transparency of UIActionSheets
    UIView * firstView = view.view.subviews.firstObject;
    UIView * nextView = firstView.subviews.firstObject;
    nextView.backgroundColor = [UIColor whiteColor];
    nextView.layer.cornerRadius = 15;
    
    [view addAction:photo];
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
    NSString *timestamp = [Utils getTimestamp];
    
    NSDictionary *newMessage = @{MessageLocation: EmptyString,
                                 MessageImage: url,
                                 MessageText: EmptyString,
                                 MessageTimestamp: timestamp,
                                 MessageReadlist: @[self.currentUserID],
                                 MessageUserID: self.currentUserID
                                 };
    
    // add message to databse
    [[self.messagesRef childByAutoId] setValue:newMessage];
    
    // Write last message in chat
    [self updateLastChatMessage:ImageString withTimestamp:timestamp];
    
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
    NSString *timestamp = [Utils getTimestamp];
    
    NSDictionary *newMessage = @{MessageLocation: coords,
                                 MessageImage: EmptyString,
                                 MessageText: EmptyString,
                                 MessageTimestamp: timestamp,
                                 MessageReadlist: @[[[FIRAuth auth] currentUser].uid],
                                 MessageUserID: [[FIRAuth auth] currentUser].uid
                                 };
    
    // add message to databse
    [[self.messagesRef childByAutoId] setValue:newMessage];
    
    //Write last message in chat
    [self updateLastChatMessage:LocationString withTimestamp:timestamp];
    
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

- (void)prepareForSegue:(UIStoryboardSegue *)segue sender:(id)sender
{
    if ([[segue identifier] isEqualToString:@"ChatToGroup"])
    {
        GroupViewController *controller = [segue destinationViewController];
        controller.openedBy = @"Chat";
        controller.openedByChatId = self.chatId;
        controller.chatUserlist = self.chatUserlist;
    }
    if ([[segue identifier] isEqualToString:@"GroupToSettings"])
    {
        GroupSettingsViewController *controller = [segue destinationViewController];
        //controller.openedBy = @"Chat";
        controller.openedByChatId = self.chatId;
        //controller.chatUserlist = self.chatUserlist;
    }
}


/**
 Show allert dialog, when settings button in navigation bar is pressed.
 */
- (IBAction)showSettings:(UIBarButtonItem *)sender {
    
    UIAlertController * view=   [UIAlertController
                                 alertControllerWithTitle:nil
                                 message:nil
                                 preferredStyle:UIAlertControllerStyleActionSheet];
    
    
    UIAlertAction* addNewContact = [UIAlertAction
                                    actionWithTitle:@"Neuen Kontakt hinzufügen"
                                    style:UIAlertActionStyleDefault
                                    handler:^(UIAlertAction * action)
                                    {
                                        //Show menu, when add new contact button in alert dialog is pressed.
                                        [self performSegueWithIdentifier:@"ChatToGroup" sender:self];
                                        NSLog(@"AddButton pressed");
                                        
                                        // close menu
                                        [view dismissViewControllerAnimated:YES completion:nil];
                                        
                                    }];
    
    UIAlertAction* showGroupSettings = [UIAlertAction
                                        actionWithTitle:@"Gruppeneinstellungen"
                                        style:UIAlertActionStyleDefault
                                        handler:^(UIAlertAction * action)
                                        {
                                            // TODO: group settings
                                            [self performSegueWithIdentifier: @"GroupToSettings" sender: self];
                                            
                                            // close menu
                                            [view dismissViewControllerAnimated:YES completion:nil];
                                        }];
    
    UIAlertAction* leaveGroup;
    
    if(_isGroup){
        
        leaveGroup = [UIAlertAction
                      actionWithTitle:@"Gruppe verlassen"
                      style:UIAlertActionStyleDefault
                      handler:^(UIAlertAction * action)
                      {
                          //Leave this group, when leave group button in alert dialog is pressed.
                          [self leaveGroup:self];
                                     
                          // close menu
                          [view dismissViewControllerAnimated:YES completion:nil];
                      }];
    }
    
    UIAlertAction* cancel = [UIAlertAction
                             actionWithTitle:@"Abbrechen"
                             style:UIAlertActionStyleCancel
                             handler:^(UIAlertAction * action)
                             {
                                 // close menu when user taps outside
                                 [view dismissViewControllerAnimated:YES completion:nil];
                                 
                             }];
    
    // disable transparency of UIActionSheets
    UIView * firstView = view.view.subviews.firstObject;
    UIView * nextView = firstView.subviews.firstObject;
    nextView.backgroundColor = [UIColor whiteColor];
    nextView.layer.cornerRadius = 15;
    
    [view addAction:addNewContact];
    [view addAction:showGroupSettings];
    if(_isGroup){
        [view addAction:leaveGroup];
    }
    [view addAction:cancel];
    [self presentViewController:view animated:YES completion:nil];
}

@end
