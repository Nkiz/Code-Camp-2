//
//  TableViewController.m
//  uMessage
//
//  Created by Codecamp on 22.02.17.
//  Copyright © 2017 Codecamp. All rights reserved.
//

#import "ChatViewController.h"

@interface ChatViewController ()<UITextFieldDelegate, UIScrollViewDelegate,UITableViewDataSource, UITableViewDelegate>{
    FIRDatabaseHandle _refAddHandle;
    FIRDatabaseHandle _refRemoveHandle;
}

@property (strong, nonatomic) IBOutlet UINavigationBar *navigationBar;
@property (strong, nonatomic) IBOutlet UITableView *chatTable;
@property (strong, nonatomic) IBOutlet UITextField *chatMsg;
@property (strong, nonatomic) NSMutableArray<FIRDataSnapshot *> *messages;


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



- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}


- (IBAction)sendAction:(UIButton *)sender {
    // current timestamp
    NSISO8601DateFormatter *formatter = [[NSISO8601DateFormatter alloc] init];
    NSString *result = [formatter stringFromDate:[NSDate date]];
    NSDictionary *newMessage = @{@"attUrl": @"",
                                 @"gpsCoord": @"",
                                 @"imgUrl": @"",
                                 @"msgText": _chatMsg.text,
                                 @"msgTs": result,
                                 @"readList": @"",
                                 @"userid": @"",
                                 @"vid": @"",
                                 @"voiceUrl": @"",
                               };
    
    // add message to databse
    [[_messagesRef childByAutoId] setValue:newMessage];
    _chatMsg.text = @"";
    
    //TODO Write last message in chat

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
    }];
}

@end
