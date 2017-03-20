//
//  GroupSettingsViewController.m
//  uMessage
//
//  Created by Codecamp on 19.03.17.
//  Copyright © 2017 Codecamp. All rights reserved.
//

#import "GroupSettingsViewController.h"
#import "TableViewController.h"
#import "Constants.h"

@interface GroupSettingsViewController ()

@end

@implementation GroupSettingsViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    // Do any additional setup after loading the view.
    self.ref         = [[FIRDatabase database] reference];
    self.chatRef     = [_ref child:@"chats"];
}

- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

- (void)viewWillAppear:(BOOL)animated {
    
    //get actual group pic
    [self showActualGroupPicture];
}

/*
#pragma mark - Navigation

// In a storyboard-based application, you will often want to do a little preparation before navigation
- (void)prepareForSegue:(UIStoryboardSegue *)segue sender:(id)sender {
    // Get the new view controller using [segue destinationViewController].
    // Pass the selected object to the new view controller.
}
*/

- (IBAction)selectGroupPicture:(id)sender {
    
    //set URL for new group pic
    [self setGroupNewValue:_pictureURL.text forKey:@"img"];
    
    //get actual group pic
    [self showActualGroupPicture];
}

- (IBAction)deleteGroupPicture:(id)sender {
    
    //delete actual group pic in the model
    [self setGroupNewValue:@"" forKey:@"img"];
    
    //delete shown picture
    _groupPicture.image = nil;
}

- (void) showActualGroupPicture {
    NSLog(@"_openedByChatId: %@", _openedByChatId);
    
    //get actual group pic
    [[_chatRef child:_openedByChatId] observeSingleEventOfType:FIRDataEventTypeValue withBlock:^(FIRDataSnapshot * _Nonnull snapshot) {
        
        NSString *imageURL = snapshot.value[@"img"];
        
        if (imageURL && ![imageURL isEqualToString:@""]) {
            if ([imageURL hasPrefix:@"gs://"]) {
                [TableViewController getAvatar:imageURL withImageView:_groupPicture];
            } else {
                _groupPicture.image = [UIImage imageWithData:[NSData dataWithContentsOfURL:[NSURL URLWithString:imageURL]]];
            }
        }
    } withCancelBlock:^(NSError * _Nonnull error) {
        NSLog(@"%@", error.localizedDescription);
    }];
}

//set new value in the model for current group
- (void) setGroupNewValue:(NSString*)value forKey:(NSString*)key {
    
    NSString *chatID = _openedByChatId;
    NSDictionary *childUpdates = @{[NSString stringWithFormat:@"/chats/%@/%@/", chatID, key]: value};
    [_ref updateChildValues:childUpdates];
}
@end
