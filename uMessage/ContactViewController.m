//
//  ContactViewController.m
//  uMessage
//
//  Created by Codecamp on 24.02.17.
//  Copyright © 2017 Codecamp. All rights reserved.
//

#import "ContactViewController.h"
#import "ChatTableViewCell.h"
#import "ChatViewController.h"
#import "TableViewController.h"

@interface ContactViewController ()<UITextFieldDelegate, UIScrollViewDelegate,UITableViewDataSource, UITableViewDelegate>{
    FIRDatabaseHandle _refAddHandle;
    FIRDatabaseHandle _refRemoveHandle;
}

@property (strong, nonatomic) NSMutableArray<FIRDataSnapshot *> *users;
@property (strong, nonatomic) NSMutableDictionary *myUserList;
@property (strong, nonatomic) NSMutableDictionary *myUserIds;
@property (weak, atomic) NSString *selectedChatId;
@property (weak, atomic) NSString *selectedChatTitle;
@property (weak, atomic) NSString *selectedUserId;
@end

@implementation ContactViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    
    _usersTable.delegate = self;
    _usersTable.dataSource = self;
    _idContactNick.delegate = self;
    _idContactMail.delegate = self;
    
    //Ref Data
    self.ref         = [[FIRDatabase database] reference];
    self.usersRef    = [_ref child:@"users"];
    self.chatRef     = [_ref child:@"chats"];
    self.userRelRef  = [_ref child:@"userRel"];
    
    _users = [[NSMutableArray alloc] init];
    _myUserList = [NSMutableDictionary dictionary];
    [_usersTable registerClass:[ChatTableViewCell class]forCellReuseIdentifier:@"UsersTableViewCell"];
    
    
}

- (UIStatusBarStyle)preferredStatusBarStyle
{
    return UIStatusBarStyleLightContent;
}

- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
}

- (void) loadUsers{
    _refAddHandle = [_usersRef observeEventType:FIRDataEventTypeChildAdded withBlock:^(FIRDataSnapshot *snapshot) {
        NSDictionary<NSString *, NSString *> *user = snapshot.value;
        //Entered Username or Mail is matched
        if([[user objectForKey:@"email"] hasPrefix:_idContactMail.text] ||
           [[user objectForKey:@"username"] hasPrefix:_idContactNick.text]){
            // dont show me
            if([[user objectForKey:@"authId"] isEqualToString:[FIRAuth auth].currentUser.uid]) return;
            
            [_users addObject:snapshot];
            [_myUserList setObject:[snapshot.value objectForKey:@"username"] forKey:snapshot.key];
            [_usersTable insertRowsAtIndexPaths:@[[NSIndexPath indexPathForRow:_users.count-1 inSection:0]] withRowAnimation:UITableViewRowAnimationAutomatic];
        }
    }];
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(nonnull NSIndexPath *)indexPath {
    ChatTableViewCell *cell = [_usersTable dequeueReusableCellWithIdentifier:@"UsersTableViewCell"forIndexPath:indexPath];
    FIRDataSnapshot *usersSnapshot = _users[indexPath.row];
    NSDictionary<NSString *, NSString *> *user = usersSnapshot.value;
    cell.title.text = user[@"username"];
    cell.message.text = user[@"status"];
    
    NSString *imageURL = user[@"profileImg"];
    
    if (imageURL && ![imageURL isEqualToString:@""]) {
        if ([imageURL hasPrefix:@"gs://"]) {
            [TableViewController getAvatar:imageURL withImageView:cell.avatar];
        } else {
            cell.avatar.image = [UIImage imageWithData:[NSData dataWithContentsOfURL:[NSURL URLWithString:imageURL]]];
        }
    }
    return cell;
}


- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView {
    return 1;
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section {
    return [_users count];
}

-(IBAction)prepareForUnwind:(UIStoryboardSegue *)segue {
    NSLog(@"Contact unwind");
}
- (IBAction)backButtonPressed:(id)sender {
    [self performSegueWithIdentifier:@"ContactToList" sender:self];
}
- (IBAction)searchContactPressed:(id)sender {
    [self.view endEditing:YES];
    
    [_users removeAllObjects];
    [_usersTable reloadData];
    [self loadUsers];
}
- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath
{
    // save selected chat id
    NSArray *myUsers = [_myUserList allValues];
    NSArray *myUserIds = [_myUserList allKeys];
    FIRDataSnapshot *userSnapshot = myUsers[indexPath.row];
    //self.selectedChatId     = userSnapshot.key;
    self.selectedChatTitle    = [myUsers objectAtIndex:indexPath.row];
    self.selectedUserId       = [myUserIds objectAtIndex:indexPath.row];
    
    
    // open chat
    [self performSegueWithIdentifier:@"ContactToChat" sender:self];
}

- (BOOL)textFieldShouldReturn:(UITextField *)textField
{
    NSLog(@"TextField should return.");
    if(textField == _idContactMail || textField == _idContactNick) {
        [self searchContactPressed:nil];
    }
    
    return NO;
}

- (void)prepareForSegue:(UIStoryboardSegue *)segue sender:(id)sender
{
    BOOL findChat = false;
    if ([[segue identifier] isEqualToString:@"ContactToChat"])
    {
        // send chat id to controller
        ChatViewController *controller = [segue destinationViewController];
        for (int i=0; i<_myMessages.count; i++) {
            FIRDataSnapshot *messageSnapshot = _myMessages[i];
            NSMutableArray * userList = messageSnapshot.value[@"userlist"];
            if([userList count] > 2){
                continue;
            }
            for(NSString *key in userList){
                if([_selectedUserId isEqualToString:key]){
                    findChat = true;
                    controller.chatId = [_myMessages objectAtIndex: i].key;
                    controller.chatTitle = _selectedChatTitle;
                    controller.chatUserlist = userList;
                    break;
                }
            }
            if(findChat){
                break;
            }
        }
        if(!findChat){
            //Todo neuer Chat
            NSString *key = [[_chatRef child:@"chats"] childByAutoId].key;
            controller.chatId = key;
            //controller.chatTitle = @"test";
            /*NSDictionary *userListForChat = @{@"0": _selectedUserId,
                                              @"1": [FIRAuth auth].currentUser.uid
                                              };*/
            NSMutableArray *tmpUserList = [[NSMutableArray alloc] init];
            [tmpUserList addObject:_selectedUserId];
            [tmpUserList addObject:[FIRAuth auth].currentUser.uid];
            controller.chatTitle = _selectedChatTitle;
            controller.chatUserlist = tmpUserList;
            NSDictionary *chatInfo = @{@"img": @"",
                                       @"lastMsg": @"",
                                       @"lastMsgTs": @"",
                                       @"userlist": @{
                                               @"0":_selectedUserId,
                                               @"1": [FIRAuth auth].currentUser.uid}
                                       };
            NSDictionary *childUpdates = @{key: chatInfo};
            // add user to databse
            [_chatRef updateChildValues:childUpdates];
            //add user as RelUser
            [[_userRelRef child:[FIRAuth auth].currentUser.uid ] observeSingleEventOfType:FIRDataEventTypeValue withBlock:^(FIRDataSnapshot * _Nonnull snapshot) {
                NSMutableArray *userList = snapshot.value;
                [userList addObject:_selectedUserId];
                NSDictionary *childUpdates = @{[FIRAuth auth].currentUser.uid: userList};
                [_userRelRef updateChildValues:childUpdates];
            }];

            

        }
    }
}
@end
