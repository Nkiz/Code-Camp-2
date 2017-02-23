//
//  TableViewController.m
//  uMessage
//
//  Created by Codecamp on 22.02.17.
//  Copyright © 2017 Codecamp. All rights reserved.
//

#import "TableViewController.h"

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
    //[self filtermyChat];
    
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
                                [self filtermyChat];
                            }
                        }
                    } withCancelBlock:^(NSError * _Nonnull error) {
                        NSLog(@"%@", error.localizedDescription);
                    }];
                }
            }
        }
        /*[[_userRef child:userListArr[i] ] observeEventType:FIRDataEventTypeValue withBlock:^(FIRDataSnapshot * _Nonnull snapshot) {
            // Get user value
            NSDictionary<NSString *, NSString *> *userData = snapshot.value;
            NSString *tmpUser = [userData objectForKey:@"authId"];
            NSMutableArray *columnArray = [NSMutableArray array];
            if(![tmpUser isEqualToString:[FIRAuth auth].currentUser.uid]){
                [_myUsers setObject:[userData objectForKey:@"username"] forKey:snapshot.key];
                NSLog(@"%@", [userData objectForKey:@"username"]);
            }
            self.tmpUserData = snapshot.value;
        } withCancelBlock:^(NSError * _Nonnull error) {
            NSLog(@"%@", error.localizedDescription);
        }];*/

        
        /*[_chatTableView insertRowsAtIndexPaths:@[[NSIndexPath indexPathForRow:_messages.count-1 inSection:0]] withRowAnimation:UITableViewRowAnimationAutomatic];*/
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
    UITableViewCell *cell = [_chatTableView dequeueReusableCellWithIdentifier:@"TableViewCell" forIndexPath:indexPath];
    
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
    
    NSString *name = message[MessageFieldsname];
    NSString *imageURL = message[MessageFieldsimageURL];
    
    NSString *text = message[MessageFieldstext];
    cell.textLabel.text = [NSString stringWithFormat:@"%@: %@", name, text];
    cell.imageView.image = [UIImage imageNamed: @"ic_account_circle"];
    NSString *photoURL = message[MessageFieldsphotoURL];
    if (photoURL) {
        NSURL *URL = [NSURL URLWithString:photoURL];
        if (URL) {
            NSData *data = [NSData dataWithContentsOfURL:URL];
            if (data) {
                cell.imageView.image = [UIImage imageWithData:data];
            }
        }
    }
    */
    NSArray *name = [_myUserList allValues];
    cell.textLabel.text = [name objectAtIndex:indexPath.row];
    return cell;
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
