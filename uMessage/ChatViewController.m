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
    
    // set chat title
    _navigationBar.topItem.title = self.chatTitle;
    
}

-(IBAction)prepareForUnwind:(UIStoryboardSegue *)segue {
    NSLog(@"Chat unwind");
}


- (IBAction)backButtonPressed:(id)sender {
    NSLog(@"BackButton pressed");
    
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
}

@end
