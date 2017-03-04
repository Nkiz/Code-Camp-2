//
//  Constants.h
//  uMessage
//
//  Created by Max Dratwa on 03.03.17.
//  Copyright © 2017 Codecamp. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <UIKit/UIKit.h>

@interface Constants : NSObject

// User Interface
extern NSString *const BubbleCellId;
extern NSString *const BubbleImageCellId;
extern NSString *const BubbleLocationCellId;

// Database
extern NSString *const ChatsTable;
extern NSString *const ChatLastMessage;
extern NSString *const ChatLastMessageTimestamp;

extern NSString *const MessagesTable;
extern NSString *const MessageTimestamp;
extern NSString *const MessageImage;
extern NSString *const MessageAttachment;
extern NSString *const MessageLocation;
extern NSString *const MessageText;
extern NSString *const MessageReadlist;
extern NSString *const MessageUserID;
extern NSString *const MessageVideo;
extern NSString *const MessageVoice;

extern NSString *const UsersTable;
extern NSString *const Username;

// Date
extern NSString *const Today;
extern NSString *const Yesterday;

// Chat
extern NSString *const LocationString;
extern NSString *const ImageString;
extern NSString *const PleaseWaitString;
extern NSString *const UploadImageString;
extern NSString *const CancelString;
extern NSString *const ChoosePhotoString;
extern NSString *const TakePhotoString;
extern NSString *const SendVoiceString;
extern NSString *const SendLocationString;
extern NSString *const GetLocationString;

// Util
extern NSString *const EmptyString;

@end
