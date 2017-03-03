//
//  BubbleLocationChatCell.h
//  uMessage
//
//  Created by Max Dratwa on 02.03.17.
//  Copyright © 2017 Codecamp. All rights reserved.
//

#import <UIKit/UIKit.h>
#import <MapKit/MapKit.h>
#import "BubbleChatCell.h"

@interface BubbleLocationChatCell : UITableViewCell

@property (strong, nonatomic) IBOutlet UILabel *user;
@property (strong, nonatomic) IBOutlet UILabel *message;
@property (strong, nonatomic) IBOutlet UILabel *date;
@property (strong, nonatomic) IBOutlet UILabel *time;
@property (strong, nonatomic) IBOutlet MKMapView *map;

@property (strong, nonatomic) IBOutlet UIView *bubble;

@property (strong, nonatomic) NSLayoutConstraint *leftConstraint;
@property (strong, nonatomic) NSLayoutConstraint *rightConstraint;
@property (strong, nonatomic) NSLayoutConstraint *topConstraint;
@property (strong, nonatomic) NSLayoutConstraint *timeConstraint;
@property (strong, nonatomic) NSLayoutConstraint *dateConstraint;

@property BOOL isMe;

- (void)setStyle:(BubbleStyle)style;
- (void)hideDate:(BOOL)hide;

-(void)showLocation:(CGFloat)latitude withLongitute:(CGFloat)longitute;

@end
