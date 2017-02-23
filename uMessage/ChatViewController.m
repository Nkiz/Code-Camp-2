//
//  TableViewController.m
//  uMessage
//
//  Created by Codecamp on 22.02.17.
//  Copyright © 2017 Codecamp. All rights reserved.
//

#import "ChatViewController.h"

@interface ChatViewController ()
@property (strong, nonatomic) IBOutlet UINavigationBar *navigationBar;
@property (strong, nonatomic) IBOutlet UITableView *chatTable;
@property (strong, nonatomic) IBOutlet UITextField *chatMsg;

@end

@implementation ChatViewController
- (void)viewDidLoad {
    [super viewDidLoad];
    
    self.ref     = [[FIRDatabase database] reference];
    
    //_navigationBar.navigationItem.title = _chatId;
    
    _navigationBar.topItem.title = self.chatTitle;
}

- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}


- (IBAction)sendAction:(UIButton *)sender {
}

@end
