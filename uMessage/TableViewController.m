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

@interface TableViewController ()<UITableViewDataSource, UITableViewDelegate>{
    FIRDatabaseHandle _refHandle;
}
@property (weak, nonatomic) IBOutlet UITableView *chatTableView;
@property (strong, nonatomic) NSMutableArray<FIRDataSnapshot *> *chatSnapshot;
@property (strong, nonatomic) NSMutableArray<FIRDataSnapshot *> *messages;
@property (strong, nonatomic) NSMutableDictionary *myUsers;
@property (strong, nonatomic) NSMutableDictionary *myUserList;

@end

@implementation TableViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    self.ref     = [[FIRDatabase database] reference];
    self.userRef = [_ref child:@"users"];
    self.chatRef = [_ref child:@"chats"];
    
    _chatTableView.delegate = self;
    _chatTableView.dataSource = self;
    
    //Load Database
    _messages = [[NSMutableArray alloc] init];
    _myUsers = [NSMutableDictionary dictionary];
    _myUserList = [NSMutableDictionary dictionary];
    [_chatTableView registerClass:UITableViewCell.self forCellReuseIdentifier:@"TableViewCell"];
    [self configureDatabase];
    
}

- (void) configureDatabase{
    _refHandle = [_chatRef observeEventType:FIRDataEventTypeChildAdded withBlock:^(FIRDataSnapshot *snapshot) {
        [_messages addObject:snapshot];
        _chatSnapshot = snapshot.key;
        NSDictionary<NSString *, NSString *> *message = snapshot.value;
        NSArray *userListArr = [ message objectForKey:@"userlist"];
        BOOL myChat = false;
        //check if logged user is in chat-userlist
        for (int x=0; x<userListArr.count; x++ ) {
            if([userListArr[x] isEqualToString:[FIRAuth auth].currentUser.uid]){
                myChat = true;
                break;
            }
        }
        //add chat if logged user included in chat
        if(myChat){
            for(int i=0; i<userListArr.count; i++){
                if(![userListArr[i] isEqualToString:[FIRAuth auth].currentUser.uid]){
                    [_myUsers setObject: userListArr[i] forKey:(snapshot.key)];
                    [[_userRef child:userListArr[i] ] observeSingleEventOfType:FIRDataEventTypeValue withBlock:^(FIRDataSnapshot * _Nonnull snapshot) {
                        // Get user value
                        
                        NSDictionary<NSString *, NSString *> *userData = snapshot.value;
                        NSString *tmpUser = [userData objectForKey:@"authId"];
                        for (NSString *key in _myUsers) {
                            if([tmpUser isEqualToString:([_myUsers objectForKey:key])]){
                                [_myUserList setObject:[userData objectForKey:@"username"] forKey:key];
                                //add cell in Table for Chat
                                [self filtermyChat];
                            }
                        }
                    } withCancelBlock:^(NSError * _Nonnull error) {
                        NSLog(@"%@", error.localizedDescription);
                    }];
                }
            }
        }
    }];
}

- (void) filtermyChat{
    [_chatTableView insertRowsAtIndexPaths:@[[NSIndexPath indexPathForRow:_myUserList.count-1 inSection:0]] withRowAnimation:UITableViewRowAnimationAutomatic];
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
    return [_myUserList count];
}


- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(nonnull NSIndexPath *)indexPath {
    BOOL myChat = false;
    // Dequeue cell
    ChatTableViewCell *cell = [_chatTableView dequeueReusableCellWithIdentifier:@"ChatTableViewCell"forIndexPath:indexPath];
    
    // Unpack message from Firebase DataSnapshot
    /*FIRDataSnapshot *messageSnapshot = _messages[indexPath.row];
    NSDictionary<NSString *, NSString *> *message = messageSnapshot.value;
    NSArray *userListArr = [ message objectForKey:@"userlist"];
    NSString *cellTitle;
    for (int i=0; i< userListArr.count; i++){
        NSDictionary *userDict;
        if([userListArr[i] isEqualToString:[FIRAuth auth].currentUser.uid]){
            myChat = true;
        }else{
            [[_userRef child:userListArr[i] ] observeEventType:FIRDataEventTypeValue withBlock:^(FIRDataSnapshot * _Nonnull snapshot) {
                // Get user value
                self.tmpUserData = snapshot.value;
            } withCancelBlock:^(NSError * _Nonnull error) {
                NSLog(@"%@", error.localizedDescription);
            }];
            cellTitle = (@", %@", self.tmpUserData);
        }
    }
    if(myChat){
        cell.textLabel.text = @"test";
        return cell;
    }*/
    
    //cell.textLabel.text = userListArr[0];
    //NSString *name = message[@"userlist"];
    //cell.textLabel.text = [name objectAtIndex];
    /*
    
    
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
    
    cell.title.text = userListArr[0];
    cell.message.text = message[@"lastMsg"];
    cell.date.text = dateStr;
    
    // TODO: check if unread
    if(indexPath.row % 2 == 0) {
        [cell setRead:NO];
    }
    else {
        [cell setRead:YES];
    }
    
    NSString *imageURL = message[@"img"];
    
    if (imageURL) {
        if ([imageURL hasPrefix:@"gs://"]) {
            [[[FIRStorage storage] referenceForURL:imageURL] dataWithMaxSize:INT64_MAX
                                                                  completion:^(NSData *data, NSError *error) {
                                                                      if (error) {
                                                                          NSLog(@"Error downloading: %@", error);
                                                                          return;
                                                                      }
                                                                      cell.avatar.image = [UIImage imageWithData: data];
                                                                  }];
        } else {
            cell.avatar.image = [UIImage imageWithData:[NSData dataWithContentsOfURL:[NSURL URLWithString:imageURL]]];
        }
    }
    */
    NSArray *name = [_myUserList allValues];
    cell.textLabel.text = [name objectAtIndex:indexPath.row];
    
    return cell;
}

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath
{
    // save selected chat id
    FIRDataSnapshot *messageSnapshot = _messages[indexPath.row];
    self.selectedChatId = messageSnapshot.key;
    
    // open chat
    [self performSegueWithIdentifier:@"ListToChat" sender:self];
}

- (void)prepareForSegue:(UIStoryboardSegue *)segue sender:(id)sender
{
    if ([[segue identifier] isEqualToString:@"ListToChat"])
    {
        // send chat id to controller
        ChatViewController *controller = [segue destinationViewController];
        controller.chatId = _selectedChatId;
    }
}



/*
 - (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath {
 UITableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:<#@"reuseIdentifier"#> forIndexPath:indexPath];
 
 // Configure the cell...
 
 return cell;
 }
 */

/*
 // Override to support conditional editing of the table view.
 - (BOOL)tableView:(UITableView *)tableView canEditRowAtIndexPath:(NSIndexPath *)indexPath {
 // Return NO if you do not want the specified item to be editable.
 return YES;
 }
 */

/*
 // Override to support editing the table view.
 - (void)tableView:(UITableView *)tableView commitEditingStyle:(UITableViewCellEditingStyle)editingStyle forRowAtIndexPath:(NSIndexPath *)indexPath {
 if (editingStyle == UITableViewCellEditingStyleDelete) {
 // Delete the row from the data source
 [tableView deleteRowsAtIndexPaths:@[indexPath] withRowAnimation:UITableViewRowAnimationFade];
 } else if (editingStyle == UITableViewCellEditingStyleInsert) {
 // Create a new instance of the appropriate class, insert it into the array, and add a new row to the table view
 }
 }
 */

/*
 // Override to support rearranging the table view.
 - (void)tableView:(UITableView *)tableView moveRowAtIndexPath:(NSIndexPath *)fromIndexPath toIndexPath:(NSIndexPath *)toIndexPath {
 }
 */

/*
 // Override to support conditional rearranging of the table view.
 - (BOOL)tableView:(UITableView *)tableView canMoveRowAtIndexPath:(NSIndexPath *)indexPath {
 // Return NO if you do not want the item to be re-orderable.
 return YES;
 }
 */

/*
 #pragma mark - Navigation
 
 // In a storyboard-based application, you will often want to do a little preparation before navigation
 - (void)prepareForSegue:(UIStoryboardSegue *)segue sender:(id)sender {
 // Get the new view controller using [segue destinationViewController].
 // Pass the selected object to the new view controller.
 }
 */

- (IBAction)logoutAction:(id)sender {
    NSError *signOutError;
    BOOL status = [[FIRAuth auth] signOut:&signOutError];
    if (!status) {
        NSLog(@"Error signing out: %@", signOutError);
        return;
    }
    [self performSegueWithIdentifier: @"ChatToLogin" sender: self];
}
@end
