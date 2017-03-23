//
//  BubbleChatCell.h
//  uMessage
//
//  Created by Max Dratwa on 28.02.17.
//  Copyright © 2017 Codecamp. All rights reserved.
//

#import <UIKit/UIKit.h>

@interface BubbleChatCell : UITableViewCell

@property (strong, nonatomic) IBOutlet UILabel *user;
@property (strong, nonatomic) IBOutlet UILabel *message;
@property (strong, nonatomic) IBOutlet UILabel *date;
@property (strong, nonatomic) IBOutlet UILabel *time;
@property (strong, nonatomic) IBOutlet UIView *bubble;

@property (strong, nonatomic) NSLayoutConstraint *leftConstraint;
@property (strong, nonatomic) NSLayoutConstraint *rightConstraint;
@property (strong, nonatomic) NSLayoutConstraint *topConstraint;
@property (strong, nonatomic) NSLayoutConstraint *timeConstraint;
@property (strong, nonatomic) NSLayoutConstraint *dateConstraint;

@property BOOL isMe;

typedef enum BubbleStyle : NSUInteger
{
    PrivateBubble,
    GroupBubble,
    MyBubble
} BubbleStyle;


- (void)setStyle:(BubbleStyle)style;
- (void)hideDate:(BOOL)hide;

@end
