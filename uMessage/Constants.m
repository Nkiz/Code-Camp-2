//
//  Constants.m
//  uMessage
//
//  Created by Max Dratwa on 03.03.17.
//  Copyright © 2017 Codecamp. All rights reserved.
//

#import "Constants.h"

@implementation Constants

// User Interface
NSString *const BubbleCellId = @"BubbleChatCell";
NSString *const BubbleImageCellId = @"BubbleImageChatCell";
NSString *const BubbleLocationCellId = @"BubbleLocationChatCell";

// Database
NSString *const ChatsTable = @"chats";
NSString *const ChatLastMessage = @"lastMsg";
NSString *const ChatLastMessageTimestamp = @"lastMsgTs";


NSString *const MessagesTable = @"messages";
NSString *const MessageUserID = @"userid";
NSString *const MessageText = @"msgText";
NSString *const MessageLocation = @"gpsCoord";
NSString *const MessageTimestamp = @"msgTs";
NSString *const MessageImage = @"imgUrl";
NSString *const MessageReadlist = @"readList";

NSString *const UsersTable = @"users";
NSString *const Username = @"username";

// Date
NSString *const Today = @"Heute";
NSString *const Yesterday = @"Gestern";

// Chat
NSString *const LocationString = @"[Koordinaten]";
NSString *const ImageString = @"[Foto]";
NSString *const PleaseWaitString = @"Bitte warten";
NSString *const UploadImageString = @"Lädt das Bild hoch.";
NSString *const CancelString = @"Abbrechen";
NSString *const ChoosePhotoString = @"Foto auswählen";
NSString *const TakePhotoString = @"Foto aufnehmen";
NSString *const SendVoiceString = @"TODO: Sprachnachricht senden";
NSString *const SendLocationString = @"Standort senden";
NSString *const GetLocationString = @"Sendet den aktuellen Standort.";

// Util
NSString *const EmptyString = @"";

@end
