//
//  BubbleChatCell.m
//  uMessage
//
//  Created by Max Dratwa on 28.02.17.
//  Copyright © 2017 Codecamp. All rights reserved.
//

#import "BubbleChatCell.h"

@implementation BubbleChatCell

#pragma mark TableCell Functions

- (void)awakeFromNib {
    [super awakeFromNib];
}

- (void)setSelected:(BOOL)selected animated:(BOOL)animated {
    //[super setSelected:selected animated:animated];
}


- (id)initWithStyle:(UITableViewCellStyle)style reuseIdentifier:(NSString *)reuseIdentifier
{
    self = [super initWithStyle:style reuseIdentifier:reuseIdentifier];
    self.backgroundColor = [UIColor clearColor];
    self.selectionStyle = UITableViewCellSelectionStyleNone;
    
    // init ui elements
    [self initBubble];
    [self initDate];
    [self initTime];
    [self initUser];
    [self initMessage];
    
    return self;
}

// Create default bubble
- (void)initBubble
{
    self.bubble = [[UIView alloc] initWithFrame:CGRectMake(15, 15, 30, 30)];
    [self.bubble setBackgroundColor:[UIColor whiteColor]];
    self.bubble.layer.cornerRadius = 10.0;
    self.bubble.layer.borderColor = [UIColor clearColor].CGColor;
    self.bubble.layer.borderWidth = 0.0;
    self.bubble.translatesAutoresizingMaskIntoConstraints = NO;
    
    [self.contentView addSubview:self.bubble];
    
    // bubble vertical margin
    _dateConstraint = [NSLayoutConstraint
                       constraintWithItem:self.bubble
                       attribute:NSLayoutAttributeTop
                       relatedBy:NSLayoutRelationEqual
                       toItem:self.contentView
                       attribute:NSLayoutAttributeTop
                       multiplier:1.0
                       constant:18.0];
    [_dateConstraint setActive:YES];
    
    [self.contentView addConstraint:[NSLayoutConstraint
                                     constraintWithItem:self.bubble
                                     attribute:NSLayoutAttributeBottom
                                     relatedBy:NSLayoutRelationEqual
                                     toItem:self.contentView
                                     attribute:NSLayoutAttributeBottom
                                     multiplier:1.0
                                     constant:-3.0]];
}

// create multiline text
-(void)initMessage
{
    self.message = [[UILabel alloc] initWithFrame:CGRectMake(10.0, 28.0, 232.0, 15.0)];
    [self.message setFont:[UIFont systemFontOfSize:17.0]];
    [self.message setTextAlignment:NSTextAlignmentLeft];
    [self.message setTextColor:[UIColor blackColor]];
    [self.message setNumberOfLines:0];
    [self.message setLineBreakMode:NSLineBreakByWordWrapping];
    self.message.translatesAutoresizingMaskIntoConstraints= NO;
    
    // Add to content view
    [self.bubble addSubview:self.message];
    
    // horizontal margin
    [self.bubble addConstraint:[NSLayoutConstraint
                                constraintWithItem:self.message
                                attribute:NSLayoutAttributeLeading
                                relatedBy:NSLayoutRelationEqual
                                toItem:self.bubble
                                attribute:NSLayoutAttributeLeading
                                multiplier:1.0
                                constant:10.0]];
    [self.bubble addConstraint:[NSLayoutConstraint
                                constraintWithItem:self.message
                                attribute:NSLayoutAttributeTrailing
                                relatedBy:NSLayoutRelationEqual
                                toItem:self.bubble
                                attribute:NSLayoutAttributeTrailing
                                multiplier:1.0
                                constant:-10.0]];
    
    // bottom margin
    [self.bubble addConstraint:[NSLayoutConstraint
                                constraintWithItem:self.message
                                attribute:NSLayoutAttributeBottom
                                relatedBy:NSLayoutRelationEqual
                                toItem:self.bubble
                                attribute:NSLayoutAttributeBottom
                                multiplier:1.0
                                constant:-5.0]];
}

// init Date label
-(void)initDate
{
    CGSize size = self.contentView.frame.size;
    
    self.date = [[UILabel alloc] initWithFrame:CGRectMake(0.0, 3.0, size.width, 15.0)];
    [self.date setFont:[UIFont systemFontOfSize:12.0]];
    [self.date setTextAlignment:NSTextAlignmentCenter];
    [self.date setTextColor:[UIColor lightGrayColor]];
    self.date.translatesAutoresizingMaskIntoConstraints = NO;
    
    [self.contentView addSubview:self.date];
    
    // top margin
    [self.contentView addConstraint:[NSLayoutConstraint
                                     constraintWithItem:self.date
                                     attribute:NSLayoutAttributeTop
                                     relatedBy:NSLayoutRelationEqual
                                     toItem:self.contentView
                                     attribute:NSLayoutAttributeTop
                                     multiplier:1.0
                                     constant:3.0]];
    // left margin
    [self.contentView addConstraint:[NSLayoutConstraint
                                     constraintWithItem:self.date
                                     attribute:NSLayoutAttributeLeading
                                     relatedBy:NSLayoutRelationEqual
                                     toItem:self.contentView
                                     attribute:NSLayoutAttributeLeading
                                     multiplier:1.0
                                     constant:0.0]];
    // right margin
    [self.contentView addConstraint:[NSLayoutConstraint
                                     constraintWithItem:self.date
                                     attribute:NSLayoutAttributeTrailing
                                     relatedBy:NSLayoutRelationEqual
                                     toItem:self.contentView
                                     attribute:NSLayoutAttributeTrailing
                                     multiplier:1.0
                                     constant:0.0]];
}

// init time label
-(void)initTime
{
    self.time = [[UILabel alloc] initWithFrame:CGRectMake(216.0, 12.0, 78.0, 15.0)];
    [self.time setFont:[UIFont systemFontOfSize:12.0]];
    [self.time setTextAlignment:NSTextAlignmentLeft];
    [self.time setTextColor:[UIColor lightGrayColor]];
    self.time.translatesAutoresizingMaskIntoConstraints = NO;
    
    [self.bubble addSubview:self.time];
    
    // bottom margin to bubble
    [self.bubble addConstraint:[NSLayoutConstraint
                                constraintWithItem:self.time
                                attribute:NSLayoutAttributeBottom
                                relatedBy:NSLayoutRelationEqual
                                toItem:self.bubble
                                attribute:NSLayoutAttributeBottom
                                multiplier:1.0
                                constant:-7.0]];
}

// init user label
-(void)initUser {
    self.user = [[UILabel alloc] initWithFrame:CGRectMake(10.0, 7.0, 80.0, 21.0)];
    [self.user setFont:[UIFont boldSystemFontOfSize:17.0]];
    [self.user setTextAlignment:NSTextAlignmentLeft];
    [self.user setTextColor:[UIColor blackColor]];
    self.user.translatesAutoresizingMaskIntoConstraints = NO;
    
    [self.bubble addSubview:self.user];
    
    // top margin
    [self.bubble addConstraint:[NSLayoutConstraint
                                constraintWithItem:self.user
                                attribute:NSLayoutAttributeTop
                                relatedBy:NSLayoutRelationEqual
                                toItem:self.bubble
                                attribute:NSLayoutAttributeTop
                                multiplier:1.0
                                constant:7.0]];
    // left margin
    [self.bubble addConstraint:[NSLayoutConstraint
                                constraintWithItem:self.user
                                attribute:NSLayoutAttributeLeading
                                relatedBy:NSLayoutRelationEqual
                                toItem:self.bubble
                                attribute:NSLayoutAttributeLeading
                                multiplier:1.0
                                constant:10.0]];
    // right margin
    [self.bubble addConstraint:[NSLayoutConstraint
                                constraintWithItem:self.user
                                attribute:NSLayoutAttributeTrailing
                                relatedBy:NSLayoutRelationEqual
                                toItem:self.bubble
                                attribute:NSLayoutAttributeTrailing
                                multiplier:1.0
                                constant:-7.0]];
}
// Set styles for all ui elements
-(void)setStyle:(BubbleStyle)style
{
    [self setBubbleStyle:style];
    [self setUserStyle:style];
    [self setDateStyle:style];
    [self setTimeStyle:style];
    [self setMessageStyle:style];
}

-(void)setBubbleStyle:(BubbleStyle)style
{
    UIColor *backgroundColor = [UIColor whiteColor];
    // bubble align left
    CGFloat leftMargin = 5.0;
    NSLayoutRelation leftRelation = NSLayoutRelationEqual;
    CGFloat rightMargin = -65.0;
    NSLayoutRelation rightRelation = NSLayoutRelationLessThanOrEqual;
    
    if(style == MyBubble) {
        backgroundColor = [UIColor colorWithRed:0.11 green:0.74 blue:0.99 alpha:1.0];
        
        // bubble align right
        leftMargin = 65.0;
        leftRelation = NSLayoutRelationGreaterThanOrEqual;
        rightMargin = -5.0;
        rightRelation = NSLayoutRelationEqual;
    } else if(style == PrivateBubble) {
        backgroundColor = [UIColor whiteColor];
        
    } else if(style == GroupBubble) {
        backgroundColor = [UIColor whiteColor];
    }
    
    [self.bubble setBackgroundColor:backgroundColor];
    
    // remove old contraints (reused cell)
    [_rightConstraint setActive:NO];
    [_leftConstraint setActive:NO];
    
    // bubble horizontal position
    _leftConstraint = [NSLayoutConstraint
                       constraintWithItem:self.bubble
                       attribute:NSLayoutAttributeLeading
                       relatedBy:leftRelation
                       toItem:self.contentView
                       attribute:NSLayoutAttributeLeading
                       multiplier:1.0
                       constant:leftMargin];
    
    _rightConstraint = [NSLayoutConstraint
                        constraintWithItem:self.bubble
                        attribute:NSLayoutAttributeTrailing
                        relatedBy:rightRelation
                        toItem:self.contentView
                        attribute:NSLayoutAttributeTrailing
                        multiplier:1.0
                        constant:rightMargin];
    
    [_rightConstraint setActive:YES];
    [_leftConstraint setActive:YES];
    
}
-(void)setUserStyle:(BubbleStyle)style
{
    // only show user in group chat
    if(style == MyBubble) {
        [self.user setHidden:YES];
    } else if(style == PrivateBubble) {
        [self.user setHidden:YES];
    } else if(style == GroupBubble) {
        [self.user setHidden:NO];
    }
}
-(void)setDateStyle:(BubbleStyle)style
{
    // my own message
    if(style == MyBubble) {
        
    } else if(style == PrivateBubble) {
        
    } else if(style == GroupBubble) {
        
    }
}
-(void)setTimeStyle:(BubbleStyle)style
{
    [_timeConstraint setActive:NO];
    
    // display time left (own message) or right
    if(style == MyBubble) {
        _timeConstraint = [NSLayoutConstraint
                           constraintWithItem:self.time
                           attribute:NSLayoutAttributeTrailing
                           relatedBy:NSLayoutRelationLessThanOrEqual
                           toItem:self.bubble
                           attribute:NSLayoutAttributeLeading
                           multiplier:1.0
                           constant:-10.0];
        
        [self.time setTextAlignment:NSTextAlignmentRight];
    } else if(style == PrivateBubble) {
        _timeConstraint = [NSLayoutConstraint
                           constraintWithItem:self.time
                           attribute:NSLayoutAttributeLeading
                           relatedBy:NSLayoutRelationGreaterThanOrEqual
                           toItem:self.bubble
                           attribute:NSLayoutAttributeTrailing
                           multiplier:1.0
                           constant:10.0];
        
        [self.time setTextAlignment:NSTextAlignmentLeft];
    } else if(style == GroupBubble) {
        _timeConstraint = [NSLayoutConstraint
                           constraintWithItem:self.time
                           attribute:NSLayoutAttributeLeading
                           relatedBy:NSLayoutRelationGreaterThanOrEqual
                           toItem:self.bubble
                           attribute:NSLayoutAttributeTrailing
                           multiplier:1.0
                           constant:10.0];
        
        [self.time setTextAlignment:NSTextAlignmentLeft];
    }
    [_timeConstraint setActive:YES];
    
}
-(void)setMessageStyle:(BubbleStyle)style
{
    CGFloat marginTop = 5.0;
    
    // white color for own messages
    if(style == MyBubble) {
        [self.message setTextColor:[UIColor whiteColor]];
        
    } else if(style == PrivateBubble) {
        [self.message setTextColor:[UIColor blackColor]];
        
    } else if(style == GroupBubble) {
        [self.message setTextColor:[UIColor blackColor]];
        
        // adjust margin for user display
        marginTop = 28.0;
    }
    
    // new top margin
    [_topConstraint setActive:NO];
    _topConstraint = [NSLayoutConstraint
                      constraintWithItem:self.message
                      attribute:NSLayoutAttributeTop
                      relatedBy:NSLayoutRelationEqual
                      toItem:self.bubble
                      attribute:NSLayoutAttributeTop
                      multiplier:1.0
                      constant:marginTop];
    [_topConstraint setActive:YES];
    
    
}

// hide date duplicates
-(void)hideDate:(BOOL)hide
{
    CGFloat marginTop = 3.0;
    
    if(hide) {
        [_date setHidden:YES];
    } else {
        [_date setHidden:NO];
        marginTop = 21.0;
    }
    
    [_dateConstraint setActive:NO];
    _dateConstraint = [NSLayoutConstraint
                       constraintWithItem:self.bubble
                       attribute:NSLayoutAttributeTop
                       relatedBy:NSLayoutRelationEqual
                       toItem:self.contentView
                       attribute:NSLayoutAttributeTop
                       multiplier:1.0
                       constant:marginTop];
    [_dateConstraint setActive:YES];
}

@end
