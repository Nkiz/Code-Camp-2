//
//  TableViewController.m
//  uMessage
//
//  Created by Codecamp on 22.02.17.
//  Copyright © 2017 Codecamp. All rights reserved.
//

#import "TableViewController.h"
#import "ChatTableViewCell.h"

@interface TableViewController ()<UITableViewDataSource, UITableViewDelegate>{
    FIRDatabaseHandle _refHandle;
}
@property (weak, nonatomic) IBOutlet UITableView *chatTableView;
@property (strong, nonatomic) NSMutableArray<FIRDataSnapshot *> *messages;

@end

@implementation TableViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    self.ref     = [[FIRDatabase database] reference];
    self.chatRef = [_ref child:@"chats"];
    
    _chatTableView.delegate = self;
    _chatTableView.dataSource = self;
    
    _messages = [[NSMutableArray alloc] init];
    
    [_chatTableView registerClass:[ChatTableViewCell class] forCellReuseIdentifier:@"ChatTableViewCell"];
    
    _refHandle = [_chatRef observeEventType:FIRDataEventTypeChildAdded withBlock:^(FIRDataSnapshot *snapshot) {
        [_messages addObject:snapshot];
        [_chatTableView insertRowsAtIndexPaths:@[[NSIndexPath indexPathForRow:_messages.count-1 inSection:0]] withRowAnimation:UITableViewRowAnimationAutomatic];
    }];
    // Uncomment the following line to preserve selection between presentations.
    // self.clearsSelectionOnViewWillAppear = NO;
    
    // Uncomment the following line to display an Edit button in the navigation bar for this view controller.
    // self.navigationItem.rightBarButtonItem = self.editButtonItem;
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
    return [_messages count];
}


- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(nonnull NSIndexPath *)indexPath {
    // Dequeue cell
    ChatTableViewCell *cell = [_chatTableView dequeueReusableCellWithIdentifier:@"ChatTableViewCell"forIndexPath:indexPath];
    
    // Unpack message from Firebase DataSnapshot
    FIRDataSnapshot *messageSnapshot = _messages[indexPath.row];
    NSDictionary<NSString *, NSString *> *message = messageSnapshot.value;
    
    NSArray *userListArr = [ message objectForKey:@"userlist"];
    
    
    
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
    [self performSegueWithIdentifier: @"ChatToLogin" sender: self];
}
@end
