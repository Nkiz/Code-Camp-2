//
//  GroupViewController.m
//  uMessage
//
//  Created by Codecamp on 09.03.17.
//  Copyright © 2017 Codecamp. All rights reserved.
//

#import "GroupViewController.h"
#import "ChatTableViewCell.h"
#import "ChatViewController.h"

@interface GroupViewController ()<UITextFieldDelegate, UIScrollViewDelegate,UITableViewDataSource, UITableViewDelegate>{
    FIRDatabaseHandle _refAddHandle;
}

@property (strong, nonatomic) NSMutableArray<FIRDataSnapshot *> *users;
@property (strong, nonatomic) NSMutableArray<FIRDataSnapshot *> *myUserRels;
@property (strong, nonatomic) NSMutableArray<NSString *> *myUserRelList;

@property (weak, atomic) NSString *selectedChatId;
@property (weak, atomic) NSString *selectedUserId;
@property (weak, atomic) NSString *selectedChatTitle;

@property (strong, nonatomic) NSMutableArray<FIRDataSnapshot *> *selectedGroupUsers;
@property NSUInteger selectedRow;

@end


@implementation GroupViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    self.ref         = [[FIRDatabase database] reference];
    self.userRef     = [_ref child:@"users"];
    self.userRelRef  = [_ref child:@"userRel"];
    self.chatRef     = [_ref child:@"chats"];
    _myUserRels = [[NSMutableArray alloc] init];
    _myUserRelList = [[NSMutableArray alloc] init];
    _selectedGroupUsers = [[NSMutableArray alloc] init];
    
    [_groupTable registerClass:[ChatTableViewCell class]forCellReuseIdentifier:@"TableViewCell"];
    _groupTable.allowsMultipleSelection = YES;
    [self loadUsers];
}

- (UIStatusBarStyle)preferredStatusBarStyle
{
    return UIStatusBarStyleLightContent;
}

- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}
- (IBAction)backButtonPressed:(id)sender {
    [self performSegueWithIdentifier:@"GroupToList" sender:self];
}
- (IBAction)addGroup:(id)sender {
    NSString *tmp;
    NSMutableArray *tmpUserRelList = [[NSMutableArray alloc]init];
    for(int i=0; i < [_selectedGroupUsers count]; i++ ){
        NSIndexPath *loopPath = [NSIndexPath indexPathForRow:i inSection:0];
        ChatTableViewCell *cell = [_groupTable cellForRowAtIndexPath:loopPath];
        FIRDataSnapshot *snap = [_selectedGroupUsers objectAtIndex:i];
        NSDictionary<NSString *, NSString *> *userRel = snap.value;
        [_myUserRelList addObject:[userRel valueForKey:@"authId"]];
        if(i == 0){
            tmp = [userRel valueForKey:@"username"];
        }else{
            tmp = [tmp stringByAppendingString:@", "];
            tmp = [tmp stringByAppendingString:[userRel valueForKey:@"username"]];
        }
    }
    tmpUserRelList = _myUserRelList;
    
    //For add User in existing Chat
    if([self.openedBy isEqualToString:@"Chat"]){
        [[_chatRef child:_openedByChatId] observeSingleEventOfType:FIRDataEventTypeValue withBlock:^(FIRDataSnapshot * _Nonnull snapshot) {
            NSDictionary<NSString *, NSString *> *userData = snapshot.value;
            NSMutableArray<NSString*> *userDataList = [userData allValues];
            NSMutableArray *userList = snapshot.value[@"userlist"];
            [tmpUserRelList addObjectsFromArray:userList];
            [userData setValue:tmpUserRelList forKeyPath:@"userlist"];
            NSDictionary *childUpdates = @{_openedByChatId: userData};
            // add user to databse
            [_chatRef updateChildValues:childUpdates];
            NSMutableString * chatTitle;
            int counter = 0;
            for(NSString* userName in tmpUserRelList){
                for(FIRDataSnapshot *userRels in _myUserRels){
                    NSDictionary<NSString *, NSString *> *userRel = userRels.value;
                    if([userName isEqualToString:[userRel objectForKey:@"authId"]]){
                        if(counter == 0){
                            chatTitle = [userRel objectForKey:@"username"];
                        }else{
                            chatTitle = [chatTitle stringByAppendingString:@", "];
                            chatTitle = [chatTitle stringByAppendingString:[userRel objectForKey:@"username"]];
                        }
                    };
                }
                counter++;
            }
            self.selectedChatId     = _openedByChatId;
            self.selectedChatTitle  = chatTitle;
            self.selectedUserId = [FIRAuth auth].currentUser.uid;
            self.selectedRow = 1;
            
            [self performSegueWithIdentifier:@"GroupToChat" sender:self];
        }];
        
    //For create new Chat
    }else if([self.openedBy isEqualToString:@"List"]){
        [tmpUserRelList addObject:[FIRAuth auth].currentUser.uid];
        NSString *key = [[_chatRef child:@"chats"] childByAutoId].key;
        NSDictionary *chatInfo = @{@"img": @"",
                                   @"lastMsg": @"",
                                   @"lastMsgTs": @"",
                                   @"userlist": tmpUserRelList
                                   };
        NSDictionary *childUpdates = @{key: chatInfo};
        // add user to databse
        [_chatRef updateChildValues:childUpdates];
        
        self.selectedChatId     = key;
        self.selectedChatTitle  = tmp;
        self.selectedUserId = [FIRAuth auth].currentUser.uid;
        self.selectedRow = 1;
        
        [self performSegueWithIdentifier:@"GroupToChat" sender:self];
    }
}

- (void)prepareForSegue:(UIStoryboardSegue *)segue sender:(id)sender
{
    if ([[segue identifier] isEqualToString:@"GroupToChat"])
    {
        // send chat id to controller
        ChatViewController *controller = [segue destinationViewController];
        controller.chatId = _selectedChatId;
        controller.chatTitle = _selectedChatTitle;
        controller.messageUser = _selectedUserId;
        controller.chatUserlist = _myUserRelList;
        /*if(_selectedRow < [_myMessages count]){
            controller.chatUserlist = _myMessages[_selectedRow].value[@"userlist"];
        }else{
            NSMutableArray *chatInfo = [[NSMutableArray alloc] init];
            [chatInfo addObject:_selectedUserId];
            [chatInfo addObject:[FIRAuth auth].currentUser.uid];
            controller.chatUserlist = chatInfo;
        }*/
    }
}

- (void) loadUsers{
    [[_userRelRef child:[FIRAuth auth].currentUser.uid] observeEventType:FIRDataEventTypeChildAdded withBlock:^(FIRDataSnapshot * _Nonnull snapshot) {
        
        NSString *userRel = snapshot.value;
        
        // only non group members
        if([_chatUserlist containsObject:userRel]) return;
        
        [[_userRef child:userRel ] observeSingleEventOfType:FIRDataEventTypeValue withBlock:^(FIRDataSnapshot * _Nonnull snapshot) {
            // Get user value
            [_myUserRels addObject: snapshot];
            [_groupTable insertRowsAtIndexPaths:@[[NSIndexPath indexPathForRow:[_myUserRels count]-1 inSection:0]] withRowAnimation:UITableViewRowAnimationAutomatic];
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
        [_groupTable deleteRowsAtIndexPaths:@[[NSIndexPath indexPathForRow:index inSection:0]] withRowAnimation:UITableViewRowAnimationAutomatic];
    }];

}


- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView {
    return 1;
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section {
    return [_myUserRels count];
}


- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath {

    FIRDataSnapshot *userSnapshot = _myUserRels[indexPath.row];
    NSDictionary<NSString *, NSString *> *user = userSnapshot.value;
    ChatTableViewCell *cell = [_groupTable dequeueReusableCellWithIdentifier:@"TableViewCell"forIndexPath:indexPath];
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

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath
{
    ChatTableViewCell *cell = [tableView cellForRowAtIndexPath:indexPath];
    FIRDataSnapshot *userSnapshot = _myUserRels[indexPath.row];
    [_selectedGroupUsers addObject:userSnapshot];
}

- (void)tableView:(UITableView *)tableView didDeselectRowAtIndexPath:(nonnull NSIndexPath *)indexPath{
    ChatTableViewCell *cell = [tableView cellForRowAtIndexPath:indexPath];
    FIRDataSnapshot *userSnapshot = _myUserRels[indexPath.row];
    [_selectedGroupUsers removeObject:userSnapshot];
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

@end
