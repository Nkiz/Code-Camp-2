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
}
@property (weak, nonatomic) IBOutlet UITableView *chatTableView;
@property (strong, nonatomic) NSMutableArray<FIRDataSnapshot *> *chatSnapshot;
@property (strong, nonatomic) NSMutableArray<FIRDataSnapshot *> *messages;
@property (strong, nonatomic) NSMutableArray<FIRDataSnapshot *> *myMessages;
@property (strong, nonatomic) NSMutableDictionary *myUsers;
@property (strong, nonatomic) NSMutableDictionary *myUserList;
@property (strong, nonatomic) DataViewController *dv;
@property (strong, nonatomic) IBOutlet UITabBar *uiBar;

@property (weak, atomic) NSString *selectedChatId;
@property (weak, atomic) NSString *selectedChatTitle;
@property NSUInteger selectedRow;

@end

@implementation TableViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    
    self.ref     = [[FIRDatabase database] reference];
    self.userRef = [_ref child:@"users"];
    self.chatRef = [_ref child:@"chats"];
    
    [self setNeedsStatusBarAppearanceUpdate];
    
    _uiBar.delegate = self;
    _chatTableView.delegate = self;
    _chatTableView.dataSource = self;
    
    self.uiBar.selectedItem = [self.uiBar.items objectAtIndex:0];
    
    //Load Database
    _messages = [[NSMutableArray alloc] init];
    _myMessages = [[NSMutableArray alloc] init];
    _myUsers = [NSMutableDictionary dictionary];
    _myUserList = [NSMutableDictionary dictionary];
    [_chatTableView registerClass:[ChatTableViewCell class]forCellReuseIdentifier:@"ChatTableViewCell"];
    [self configureDatabase];
    
}

- (UIStatusBarStyle)preferredStatusBarStyle
{
    return UIStatusBarStyleLightContent;
}
/*
-(void)tabBarController:(UITabBarController *)tabBarController didSelectViewController:(UIViewController *)viewController {
    //NSLog(@"%@", tabBarController);
}*/

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
                [_myMessages addObject:snapshot];
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
                                [_myUserList setObject:[userData objectForKey:@"username"] forKey:userData[@"authId"]];
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
    
    //Get Data for TableCells
    NSArray *name = [_myUserList allValues];
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
    cell.title.text = [name objectAtIndex:indexPath.row];
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
    
    if (imageURL && ![imageURL isEqualToString:@""]) {
        if ([imageURL hasPrefix:@"gs://"]) {
            [[[FIRStorage storage] referenceForURL:imageURL] dataWithMaxSize:INT64_MAX
                                                                  completion:^(NSData *data, NSError *error) {
                                                                      if (error) {
                                                                          NSLog(@"Error downloading: %@", error);
                                                                          return;
                                                                      }
                                                                      cell.avatar.image = [UIImage imageWithData: data];
                                                                      [tableView reloadData];
                                                                  }];
        } else {
            cell.avatar.image = [UIImage imageWithData:[NSData dataWithContentsOfURL:[NSURL URLWithString:imageURL]]];
        }
    }
    
    return cell;
}

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath
{
    // save selected chat id
    NSArray *name = [_myUserList allValues];
    FIRDataSnapshot *messageSnapshot = _myMessages[indexPath.row];
    self.selectedChatId     = messageSnapshot.key;
    self.selectedChatTitle  = [name objectAtIndex:indexPath.row];
    
    self.selectedRow = indexPath.row;
    
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
        controller.chatTitle = _selectedChatTitle;
        controller.chatUserlist = _myMessages[_selectedRow].value[@"userlist"];
    }
    if([[segue identifier] isEqualToString:@"ListToContact"])
    {
        ContactViewController *contactController = [segue destinationViewController];
        contactController.myMessages = self.myMessages;
        contactController.myUsers    = self.myUsers;
        
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
