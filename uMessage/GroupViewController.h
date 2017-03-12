//
//  GroupViewController.h
//  uMessage
//
//  Created by Codecamp on 09.03.17.
//  Copyright © 2017 Codecamp. All rights reserved.
//

#import <UIKit/UIKit.h>
@import FirebaseAuth;
@import FirebaseDatabase;
@import FirebaseStorage;

@interface GroupViewController : UIViewController
@property (weak, nonatomic) IBOutlet UITableView *groupTable;
@property (strong, nonatomic) FIRDatabaseReference *ref;
@property (strong, nonatomic) FIRDatabaseReference *userRef;
@property (strong, nonatomic) FIRDatabaseReference *userRelRef;
@property (strong, nonatomic) FIRDatabaseReference *chatRef;

@property (strong, nonatomic) NSString *openedBy;
@property (strong, nonatomic) NSString *openedByChatId;
@property (strong, nonatomic) NSMutableArray *chatUserlist;
@end
