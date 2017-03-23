//
//  BubbleChatCell.h
//  uMessage
//
//  Created by Max Dratwa on 28.02.17.
//  Copyright © 2017 Codecamp. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "BubbleChatCell.h"

@interface BubbleImageChatCell : BubbleChatCell

@property (strong, nonatomic) IBOutlet UIImageView *image;

- (void)showImage:(UIImage*)image;

@end
