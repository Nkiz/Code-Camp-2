//
//  ChatTableViewCell.m
//  uMessage
//
//  Created by Max Dratwa on 22.02.17.
//  Copyright © 2017 Codecamp. All rights reserved.
//

#import "ChatTableViewCell.h"

@implementation ChatTableViewCell


- (id)initWithStyle:(UITableViewCellStyle)style reuseIdentifier:(NSString *)reuseIdentifier
{
    self = [super initWithStyle:style reuseIdentifier:reuseIdentifier];
    
    self.accessoryType = UITableViewCellAccessoryDisclosureIndicator;
    
    // Title init
    self.title = [[UILabel alloc] initWithFrame:CGRectMake(80.0, 17.0, 140.0, 21.0)];
    [self.title setFont:[UIFont systemFontOfSize:17.0]];
    [self.title setTextAlignment:NSTextAlignmentLeft];
    [self.title setTextColor:[UIColor blackColor]];
    
    // Message init
    self.message = [[UILabel alloc] initWithFrame:CGRectMake(80.0, 38.0, 232.0, 15.0)];
    [self.message setFont:[UIFont systemFontOfSize:12.0]];
    [self.message setTextAlignment:NSTextAlignmentLeft];
    [self.message setTextColor:[UIColor blackColor]];
    
    // Date init
    self.date = [[UILabel alloc] initWithFrame:CGRectMake(254.0, 22.0, 78.0, 15.0)];
    [self.date setFont:[UIFont systemFontOfSize:12.0]];
    [self.date setTextAlignment:NSTextAlignmentRight];
    [self.date setTextColor:[UIColor lightGrayColor]];
    
    // Avatar init
    self.avatar = [[UIImageView alloc] initWithFrame:CGRectMake(15.0, 10.0, 50.0, 50.0)];
    self.avatar.backgroundColor=[UIColor clearColor];
    [self.avatar.layer setCornerRadius:25.0f];
    [self.avatar.layer setMasksToBounds:YES];
    [self.avatar setImage:[UIImage imageNamed:@"NoAvatar"]];
   
    // Add to content view
    [self.contentView addSubview:self.title];
    [self.contentView addSubview:self.message];
    [self.contentView addSubview:self.date];
    [self.contentView addSubview:self.avatar];
    
    return self;
}

- (void)setRead:(BOOL)read
{
    if(read) {
        UIFontDescriptor *fontD = [self.title.font.fontDescriptor                                                  fontDescriptorWithSymbolicTraits:UIFontDescriptorTraitMonoSpace];
        self.title.font = [UIFont fontWithDescriptor:fontD size:0];
    }
    else {
        UIFontDescriptor *fontD = [self.title.font.fontDescriptor                                                  fontDescriptorWithSymbolicTraits:UIFontDescriptorTraitBold];
        self.title.font = [UIFont fontWithDescriptor:fontD size:0];
    }
}

@end
