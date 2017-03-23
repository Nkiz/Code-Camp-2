//
//  BubbleChatCell.m
//  uMessage
//
//  Created by Max Dratwa on 28.02.17.
//  Copyright © 2017 Codecamp. All rights reserved.
//

#import "BubbleImageChatCell.h"

@implementation BubbleImageChatCell


- (void)awakeFromNib {
    [super awakeFromNib];
}

- (void)setSelected:(BOOL)selected animated:(BOOL)animated {
    [super setSelected:selected animated:animated];
}

- (id)initWithStyle:(UITableViewCellStyle)style reuseIdentifier:(NSString *)reuseIdentifier
{
    self = [super initWithStyle:style reuseIdentifier:reuseIdentifier];
    
    // init ui elements
    self.bubble.frame = CGRectMake(15.0, 15.0, 262.0, 150.0);
    [self initImage];
    
    return self;
}

// Set styles for all ui elements
-(void)setStyle:(BubbleStyle)style
{
    [super setStyle:style];
}

-(void)initImage
{
    _image = [[UIImageView alloc] initWithFrame:CGRectMake(3.0, 3.0, 256.0, 144.0)];
    _image.backgroundColor=[UIColor clearColor];
    [_image.layer setCornerRadius:10.0f];
    [_image.layer setMasksToBounds:YES];
    _image.contentMode = UIViewContentModeScaleAspectFill;
    [_image setImage:[UIImage imageNamed:@"Placeholder"]];
    
    [self.bubble addSubview:_image];
    
    // 3.0 margin around the image
    [self.bubble addConstraint:[NSLayoutConstraint
                                constraintWithItem:_image
                                attribute:NSLayoutAttributeTop
                                relatedBy:NSLayoutRelationEqual
                                toItem:self.bubble
                                attribute:NSLayoutAttributeTop
                                multiplier:1.0
                                constant:3.0]];
    [self.bubble addConstraint:[NSLayoutConstraint
                                constraintWithItem:_image
                                attribute:NSLayoutAttributeLeading
                                relatedBy:NSLayoutRelationEqual
                                toItem:self.bubble
                                attribute:NSLayoutAttributeLeading
                                multiplier:1.0
                                constant:3.0]];
    [self.bubble addConstraint:[NSLayoutConstraint
                                constraintWithItem:_image
                                attribute:NSLayoutAttributeTrailing
                                relatedBy:NSLayoutRelationEqual
                                toItem:self.bubble
                                attribute:NSLayoutAttributeTrailing
                                multiplier:1.0
                                constant:-3.0]];
    [self.bubble addConstraint:[NSLayoutConstraint
                                constraintWithItem:_image
                                attribute:NSLayoutAttributeBottom
                                relatedBy:NSLayoutRelationEqual
                                toItem:self.bubble
                                attribute:NSLayoutAttributeBottom
                                multiplier:1.0
                                constant:-3.0]];
}

-(void)showImage:(UIImage *)image {
    
    [_image setImage:image];
}

@end
