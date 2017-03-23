//
//  ChatViewController.h
//  uMessage
//
//  Created by Max Dratwa on 23.02.17.
//  Copyright © 2017 Codecamp. All rights reserved.
//

#import <UIKit/UIKit.h>
@import Firebase;
@import FirebaseAuth;
@import FirebaseDatabase;
@import FirebaseStorage;
#import "Constants.h"
#import "Utils.h"

/**
 Chat Window Controller
 */
@interface ChatViewController : UIViewController

// Database References
@property (strong, nonatomic) FIRDatabaseReference *ref;
@property (strong, nonatomic) FIRDatabaseReference *chatRef;
@property (strong, nonatomic) FIRDatabaseReference *allChatsRef;
@property (strong, nonatomic) FIRDatabaseReference *messagesRef;

// Chat Information
@property (strong, nonatomic) NSString *chatId;
@property (strong, nonatomic) NSString *chatTitle;
@property (strong, nonatomic) NSString *chatUserId;
@property (strong, nonatomic) NSString *messageUser;
@property (strong, nonatomic) NSMutableArray *chatUserlist;



@end
