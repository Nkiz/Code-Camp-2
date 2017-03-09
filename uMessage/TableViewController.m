//
//  TableViewController.m
//  uMessage
//
//  Created by Codecamp on 22.02.17.
//  Copyright © 2017 Codecamp. All rights reserved.
//

#import "TableViewController.h"
#import "ChatTableViewCell.h"
#import "ChatViewController.h"
#import "DataViewController.h"
#import "ContactViewController.h"

@interface TableViewController ()<UITableViewDataSource, UITabBarDelegate, UITableViewDelegate>{
    FIRDatabaseHandle _refHandle;
    FIRDatabaseHandle _refUserRelHandle;
}
@property (weak, nonatomic) IBOutlet UITableView *chatTableView;
@property (weak, nonatomic) IBOutlet UITableView *contactTableView;
@property (strong, nonatomic) NSMutableArray<FIRDataSnapshot *> *messages;
@property (strong, nonatomic) NSMutableArray<FIRDataSnapshot *> *myMessages;
@property (strong, nonatomic) NSMutableArray<FIRDataSnapshot *> *myUserRels;
@property (strong, nonatomic) NSMutableDictionary *myChats;
@property (strong, nonatomic) NSMutableArray<NSString *> *myChatList;
@property (strong, nonatomic) NSMutableArray<NSString *> *myUserIdList;
@property (strong, nonatomic) NSMutableDictionary *myUserList;
@property (strong, nonatomic) NSMutableDictionary *myUserRel;
@property (strong, nonatomic) NSMutableArray<NSString *> *userList;
@property (strong, nonatomic) NSMutableArray<NSString *> *userArray;
@property (strong, nonatomic) DataViewController *dv;
@property (strong, nonatomic) IBOutlet UITabBar *uiBar;

@property (weak, atomic) NSString *selectedChatId;
@property (weak, atomic) NSString *selectedUserId;
@property (weak, atomic) NSString *selectedChatTitle;
@property NSUInteger selectedRow;

@end

@implementation TableViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    
    self.ref        = [[FIRDatabase database] reference];
    self.userRef    = [_ref child:@"users"];
    self.userRelRef = [_ref child:@"userRel"];
    self.chatRef    = [_ref child:@"chats"];
    
    
    [self setNeedsStatusBarAppearanceUpdate];
    
    _uiBar.delegate = self;
    _chatTableView.delegate = self;
    _chatTableView.dataSource = self;
    
    self.uiBar.selectedItem = [self.uiBar.items objectAtIndex:0];
    
    //Load Database
    _messages = [[NSMutableArray alloc] init];
    _myMessages = [[NSMutableArray alloc] init];
    _userList = [[NSMutableArray alloc] init];
    _myUserIdList = [[NSMutableArray alloc] init];
    _myChats = [NSMutableDictionary dictionary];
    _myUserRel = [NSMutableDictionary dictionary];
    _myUserRels = [[NSMutableArray alloc] init];
    _myChatList = [[NSMutableArray alloc] init];
    _myUserList = [NSMutableDictionary dictionary];
    [_chatTableView registerClass:[ChatTableViewCell class]forCellReuseIdentifier:@"ChatTableViewCell"];
    [_contactTableView registerClass:[ChatTableViewCell class]forCellReuseIdentifier:@"ChatTableViewCell"];
    [self fillContactList];
    [self configureDatabase];
    
}

- (UIStatusBarStyle)preferredStatusBarStyle
{
    return UIStatusBarStyleLightContent;
}

/*-(void)tabBarController:(UITabBarController *)tabBarController didSelectViewController:(UIViewController *)viewController {
    NSLog(@"test");
}*/

-(void)tabBar:(UITabBar *)uiBar didSelectItem:(UITabBarItem *)item{
    if([item.title isEqualToString:@"Chats"]){
        [self.chatTableView setHidden:false];
        [self.contactTableView setHidden:true];
    }else{
        [self.chatTableView setHidden:true];
        [self.contactTableView setHidden:false];
    }
}


- (void) configureDatabase{
    _refHandle = [_chatRef observeEventType:FIRDataEventTypeChildAdded withBlock:^(FIRDataSnapshot *snapshot) {
        NSDictionary<NSString *, NSString *> *message = snapshot.value;
        [_messages addObject:snapshot];
        [_contactTableView reloadData];
        NSMutableArray *userListArr = [ message objectForKey:@"userlist"];
        BOOL myChat = false;
        //New chat without userlist -->add userlist
        if(userListArr == nil){
            myChat = true;
            [_myMessages addObject:snapshot];
            userListArr = [[NSMutableArray alloc] init];
            [userListArr addObject:_selectedUserId];
            [userListArr addObject:[FIRAuth auth].currentUser.uid];
        }
        //check if logged user is in chat-userlist
        for (int x=0; x<userListArr.count; x++ ) {
            if([userListArr[x] isEqualToString:[FIRAuth auth].currentUser.uid]){
                [_myMessages addObject:snapshot];
                myChat = true;
                break;
            }
        }
        //add chat if logged user included in chat
        if(myChat){
            _userArray = [[NSMutableArray alloc] init];
            for(int i=0; i<userListArr.count; i++){
                if(![userListArr[i] isEqualToString:[FIRAuth auth].currentUser.uid]){
                    if(![_myChatList containsObject:(snapshot.key)]){
                        [_myChatList addObject:(snapshot.key)];
                    }
                    if(![_myUserIdList containsObject:userListArr[i]]){
                        [_myUserIdList addObject:userListArr[i]];
                    }
                    //For GroupChat, if more than one User in Chat
                    if(userListArr.count > 2){
                        if([_myChats objectForKey:(snapshot.key)]){
                            [_userArray addObject:[_myChats objectForKey:(snapshot.key)]];
                            [_userArray addObject:userListArr[i]];
                            [_myChats setValue:_userArray forKey:(snapshot.key)];
                        }else{
                            [_myChats setObject: userListArr[i] forKey:(snapshot.key)];
                        }
                    // For PrivateChat
                    }else{
                        [_myChats setObject: userListArr[i] forKey:(snapshot.key)];
                    }
                    [[_userRef child:userListArr[i] ] observeSingleEventOfType:FIRDataEventTypeValue withBlock:^(FIRDataSnapshot * _Nonnull snapshot) {
                        // Get user value
                        
                        NSDictionary<NSString *, NSString *> *userData = snapshot.value;
                        //NSString *tmpUser = [userData objectForKey:@"authId"];
                        [_myUserList setObject:[userData objectForKey:@"username"] forKey:userData[@"authId"]];
                        if([_myUserList count] == [_myUserIdList count]){
                            [self fillChatList];
                            [_chatTableView reloadData];
                        }
                    } withCancelBlock:^(NSError * _Nonnull error) {
                        NSLog(@"%@", error.localizedDescription);
                    }];

                }
            }
        }
    }];
    //Handler for change in Chatlist
    [_chatRef observeEventType:FIRDataEventTypeChildChanged withBlock:^(FIRDataSnapshot *snapshot) {
        NSString *chatId = snapshot.key;
        NSDictionary<NSString *, NSString *> *chatData = snapshot.value;
        int index = 0;
        for(int i=0; i < [_myMessages count]; i++){
            FIRDataSnapshot *chat = [_myMessages objectAtIndex:i];
            if([chat.key isEqualToString:snapshot.key]){
                index = i;
                break;
            }
        }
        _myMessages[index] = snapshot;
        [_chatTableView reloadData];
        NSLog(@"test");
    }];
    //Handler for removed Chat from Chatslist
    [_chatRef observeEventType:FIRDataEventTypeChildRemoved withBlock:^(FIRDataSnapshot *snapshot) {
        NSString *chatId = snapshot.key;
        NSString *chatData = snapshot.value;
        int index = 0;
        for(int i=0; i < [_myMessages count]; i++){
            FIRDataSnapshot *chat = [_myMessages objectAtIndex:i];
            if([chat.key isEqualToString:chatId]){
                index = i;
                break;
            }
        }
        [_myMessages removeObjectAtIndex:index];
        [_userList removeObjectAtIndex:index];
        [_chatTableView deleteRowsAtIndexPaths:@[[NSIndexPath indexPathForRow:index inSection:0]] withRowAnimation:UITableViewRowAnimationAutomatic];
    }];
}

- (void) fillChatList{
    NSInteger tmp_count = [_userList count];
    for(int i=0; i < tmp_count; i++){
        [_userList removeObjectAtIndex:0];
        [_chatTableView deleteRowsAtIndexPaths:@[[NSIndexPath indexPathForRow:0 inSection:0]] withRowAnimation:UITableViewRowAnimationAutomatic];
    }
    for (NSString *chatId in _myChatList) {
        NSMutableArray<NSString*> *chatUser = [_myChats objectForKey:chatId];
        //is String --> one Value, no GroupChat
        if([chatUser isKindOfClass:[NSString class]]){
            [_userList addObject:[_myUserList objectForKey:chatUser]];
        }else{
            NSString *tmp;
            
            for(NSString *chatUsers in chatUser){
                if([chatUser indexOfObject:chatUsers] == 0){
                    tmp = [_myUserList objectForKey:chatUsers];
                }else{
                    tmp = [tmp stringByAppendingString:@", "];
                    tmp = [tmp stringByAppendingString:[_myUserList objectForKey:chatUsers]];
                }
            }
            [_userList addObject:tmp];
        }
        [_chatTableView insertRowsAtIndexPaths:@[[NSIndexPath indexPathForRow:_userList.count-1 inSection:0]] withRowAnimation:UITableViewRowAnimationAutomatic];
    }
}

- (void) fillContactList{
    //Fill Table with Contacts
    [[_userRelRef child:[FIRAuth auth].currentUser.uid] observeEventType:FIRDataEventTypeChildAdded withBlock:^(FIRDataSnapshot * _Nonnull snapshot) {

        NSString *userRel = snapshot.value;
            [[_userRef child:userRel ] observeSingleEventOfType:FIRDataEventTypeValue withBlock:^(FIRDataSnapshot * _Nonnull snapshot) {
                // Get user value
                [_myUserRels addObject: snapshot];
                [_contactTableView insertRowsAtIndexPaths:@[[NSIndexPath indexPathForRow:[_myUserRels count]-1 inSection:0]] withRowAnimation:UITableViewRowAnimationAutomatic];
            }];
    }];
    [[_userRelRef child:[FIRAuth auth].currentUser.uid] observeEventType:FIRDataEventTypeChildRemoved withBlock:^(FIRDataSnapshot *snapshot) {
        NSString *userRel = snapshot.value;
        int index = 0;
        for(int i=0; i < [_myUserRels count]; i++){
            FIRDataSnapshot *user = [_myUserRels objectAtIndex:i];
            NSDictionary<NSString *, NSString *> *userData = user.value;
            if([userData[@"authId"] isEqualToString:userRel]){
                index = i;
                break;
            }
        }
        [_myUserRels removeObjectAtIndex:index];
        [_contactTableView deleteRowsAtIndexPaths:@[[NSIndexPath indexPathForRow:index inSection:0]] withRowAnimation:UITableViewRowAnimationAutomatic];
     }];
}

- (void)dealloc{
    [_chatRef removeAllObservers];
}

- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

#pragma mark - Table view data source

- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView {
    return 1;
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section {
    if(tableView == _chatTableView){
        return [_userList count];
    }else if(tableView == _contactTableView){
        return [_myUserRels count];
    }
    return 0;
}


- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(nonnull NSIndexPath *)indexPath {
    //Check if Chattable or Usertable
    if(tableView == _chatTableView){
        BOOL myChat = false;
        // Dequeue cell
        ChatTableViewCell *cell = [_chatTableView dequeueReusableCellWithIdentifier:@"ChatTableViewCell"forIndexPath:indexPath];
        
        //Get Data for TableCells
        FIRDataSnapshot *messageSnapshot = _myMessages[indexPath.row];
        NSDictionary<NSString *, NSString *> *message = messageSnapshot.value;
        
        // Format Date
        NSISO8601DateFormatter *dateFormat = [[NSISO8601DateFormatter alloc] init];
        NSDate *date = [dateFormat dateFromString:message[@"lastMsgTs"]];
        NSString *dateStr = @"";
        
        if([[NSCalendar currentCalendar] isDateInToday:date])
        {
            dateStr =  [NSDateFormatter localizedStringFromDate:date
                                                      dateStyle:NSDateFormatterNoStyle
                                                      timeStyle:NSDateFormatterShortStyle];
        } else if([[NSCalendar currentCalendar] isDateInYesterday:date]) {
            dateStr = @"Gestern";
        } else {
            dateStr = [NSDateFormatter localizedStringFromDate:date
                                                     dateStyle:NSDateFormatterShortStyle
                                                     timeStyle:NSDateFormatterNoStyle];
        }
        cell.title.text = [_userList objectAtIndex:indexPath.row];
        cell.message.text = message[@"lastMsg"];
        cell.date.text = dateStr;
        
        NSString *imageURL = message[@"img"];
        
        if (imageURL && ![imageURL isEqualToString:@""]) {
            if ([imageURL hasPrefix:@"gs://"]) {
                [self getAvatar:imageURL withImageView:cell.avatar];
            } else {
                cell.avatar.image = [UIImage imageWithData:[NSData dataWithContentsOfURL:[NSURL URLWithString:imageURL]]];
            }
        }
        return cell;
    }else if (tableView == _contactTableView){
        FIRDataSnapshot *userSnapshot = _myUserRels[indexPath.row];
        NSDictionary<NSString *, NSString *> *user = userSnapshot.value;
        ChatTableViewCell *cell = [_contactTableView dequeueReusableCellWithIdentifier:@"ChatTableViewCell"forIndexPath:indexPath];
        cell.title.text = user[@"username"];
        cell.message.text = user[@"status"];
        
        NSString *imageURL = user[@"profileImg"];
        
        if (imageURL && ![imageURL isEqualToString:@""]) {
            if ([imageURL hasPrefix:@"gs://"]) {
                [self getAvatar:imageURL withImageView:cell.avatar];
            } else {
                cell.avatar.image = [UIImage imageWithData:[NSData dataWithContentsOfURL:[NSURL URLWithString:imageURL]]];
            }
        }

        return cell;
    }
    return nil;
}

-(void)getAvatar:(NSString *)url withImageView:(UIImageView *)imageView
{
    //   0   1 2                         3       4
    // @"gs://umessage-80185.appspot.com/avatars/THb9zYI7DPbtOieCFXLn0TmPLfh1.png";
    NSArray *urlComponents = [url componentsSeparatedByString:@"/"];
    
    NSArray *paths = NSSearchPathForDirectoriesInDomains(NSDocumentDirectory, NSUserDomainMask, YES);
    NSString *documentsDirectory = paths[0];
    NSString *filePath = [NSString stringWithFormat:@"file:%@/%@/%@", documentsDirectory, urlComponents[3], urlComponents[4]];
    NSURL *fileURL = [NSURL URLWithString:filePath];
    
    if ([[NSFileManager defaultManager] fileExistsAtPath:fileURL.path]) {
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
                 imageView.image = [UIImage imageWithContentsOfFile:fileURL.path];
             }
         }];
    }
    
    
}

-(NSArray *)tableView:(UITableView *)tableView editActionsForRowAtIndexPath:(NSIndexPath *)indexPath
{
    UITableViewRowAction *deleteAction = [UITableViewRowAction rowActionWithStyle:UITableViewRowActionStyleNormal title:@"Löschen"  handler:^(UITableViewRowAction *action, NSIndexPath *indexPath){
        // delete action
        NSLog(@"Delete Chat with index %li", (long) indexPath.row);
    }];
    deleteAction.backgroundColor = [UIColor redColor];
    
    return @[deleteAction];
}

- (BOOL)tableView:(UITableView *)tableView canEditRowAtIndexPath:(NSIndexPath *)indexPath
{
    if(tableView == _chatTableView)
    {
        return YES;
    }
    return NO;
}

- (void)tableView:(UITableView *)tableView commitEditingStyle:(UITableViewCellEditingStyle)editingStyle forRowAtIndexPath:(NSIndexPath *)indexPath
{
    // do nothing
}

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath
{
    NSString *selectedUser = [_myUserRels objectAtIndex:indexPath.row].value[@"authId"];
    NSString *selectedUserName = [_myUserRels objectAtIndex:indexPath.row].value[@"username"];
     if(tableView == _chatTableView){
         // save selected chat id
         FIRDataSnapshot *messageSnapshot = _myMessages[indexPath.row];
         self.selectedChatId     = messageSnapshot.key;
         self.selectedChatTitle  = [_userList objectAtIndex:indexPath.row];
         self.selectedUserId = selectedUser;
         self.selectedRow = indexPath.row;
    
         // open chat
         [self performSegueWithIdentifier:@"ListToChat" sender:self];
     }else if (tableView == _contactTableView){
         BOOL findChat = false;
         //Get Contactdates for User in Chat
         for (int i=0; i<_myMessages.count; i++) {
             FIRDataSnapshot *messageSnapshot = _myMessages[i];
             NSMutableArray * userList = messageSnapshot.value[@"userlist"];
             for(NSString *key in userList){
                 if([selectedUser isEqualToString:key]){
                     findChat = true;
                     self.selectedChatId = [_myMessages objectAtIndex: i].key;
                     self.selectedChatTitle = selectedUserName;
                     self.selectedUserId = selectedUser;
                     self.selectedRow = indexPath.row;
                     break;
                 }
             }
             if(findChat){
                 break;
             }
         }
         //If new User than create new Chat
         if(!findChat){
             NSString *key = [[_chatRef child:@"chats"] childByAutoId].key;
             self.selectedChatId = key;
             self.selectedChatTitle = selectedUserName;
             self.selectedUserId = selectedUser;
             self.selectedRow = indexPath.row;
         }
         [self performSegueWithIdentifier:@"ListToChat" sender:self];
         
     }
}

- (void)prepareForSegue:(UIStoryboardSegue *)segue sender:(id)sender
{
    if ([[segue identifier] isEqualToString:@"ListToChat"])
    {
        // send chat id to controller
        ChatViewController *controller = [segue destinationViewController];
        controller.chatId = _selectedChatId;
        controller.chatTitle = _selectedChatTitle;
        controller.messageUser = _selectedUserId;
        if(_selectedRow < [_myMessages count]){
            controller.chatUserlist = _myMessages[_selectedRow].value[@"userlist"];
        }else{
            NSMutableArray *chatInfo = [[NSMutableArray alloc] init];
            [chatInfo addObject:_selectedUserId];
            [chatInfo addObject:[FIRAuth auth].currentUser.uid];
            controller.chatUserlist = chatInfo;
        }
    }
    if([[segue identifier] isEqualToString:@"ListToContact"])
    {
        ContactViewController *contactController = [segue destinationViewController];
        contactController.myMessages = self.myMessages;
        contactController.myUsers    = self.myChats;
        
    }
}
- (IBAction)settingsAction:(UIBarButtonItem *)sender {
    UIAlertController * view=   [UIAlertController
                                 alertControllerWithTitle:nil
                                 message:nil
                                 preferredStyle:UIAlertControllerStyleActionSheet];
    
    
    UIAlertAction* newContact = [UIAlertAction
                             actionWithTitle:@"Neuer Kontakt"
                             style:UIAlertActionStyleDefault
                             handler:^(UIAlertAction * action)
                             {
                                 // TODO: New Contact
                                 [self performSegueWithIdentifier: @"ListToContact" sender: self];
                                 // close menu
                                 [view dismissViewControllerAnimated:YES completion:nil];
                                 
                             }];
    
    
    UIAlertAction* newGroup = [UIAlertAction
                                 actionWithTitle:@"Neue Gruppe"
                                 style:UIAlertActionStyleDefault
                                 handler:^(UIAlertAction * action)
                                 {
                                     // TODO: New Group
                                     // close menu
                                     [view dismissViewControllerAnimated:YES completion:nil];
                                 }];
    UIAlertAction* settings = [UIAlertAction
                               actionWithTitle:@"Einstellungen"
                               style:UIAlertActionStyleDefault
                               handler:^(UIAlertAction * action)
                               {
                                   // TODO: Settings
                                   [self performSegueWithIdentifier: @"chatsToSettings" sender: self];
                                   
                                   // close menu
                                   [view dismissViewControllerAnimated:YES completion:nil];
                               }];
    
    
    UIAlertAction* logout = [UIAlertAction
                         actionWithTitle:@"Abmelden"
                         style:UIAlertActionStyleDefault
                         handler:^(UIAlertAction * action)
                         {
                             [self logoutAction:self];
                             
                             // close menu
                             [view dismissViewControllerAnimated:YES completion:nil];
                             
                         }];
    
    UIAlertAction* cancel = [UIAlertAction
                             actionWithTitle:@"Abbrechen"
                             style:UIAlertActionStyleCancel
                             handler:^(UIAlertAction * action)
                             {
                                 // close menu
                                 [view dismissViewControllerAnimated:YES completion:nil];
                                 
                             }];
    
    
    [view addAction:newContact];
    [view addAction:newGroup];
    [view addAction:settings];
    [view addAction:logout];
    [view addAction:cancel];
    [self presentViewController:view animated:YES completion:nil];
}

- (IBAction)logoutAction:(id)sender {
    NSError *signOutError;
    BOOL status = [[FIRAuth auth] signOut:&signOutError];
    if (!status) {
        NSLog(@"Error signing out: %@", signOutError);
        return;
    }
    [self performSegueWithIdentifier: @"unwindToLogin" sender: self];
}


-(IBAction)prepareForUnwind:(UIStoryboardSegue *)segue {
    NSLog(@"List unwind");
}

- (void)addNewContact{
    NSLog(@"new Contact");
}

@end
