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

@interface BubbleLocationChatCell : BubbleChatCell

@property (strong, nonatomic) IBOutlet MKMapView *map;

-(void)showLocation:(CGFloat)latitude withLongitute:(CGFloat)longitute;

@end
