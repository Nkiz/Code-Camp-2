//
//  BubbleLocationChatCell.m
//  uMessage
//
//  Created by Max Dratwa on 02.03.17.
//  Copyright © 2017 Codecamp. All rights reserved.
//

#import "BubbleLocationChatCell.h"

@implementation BubbleLocationChatCell

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
    [self initMap];
    
    return self;
}

// Set styles for all ui elements
-(void)setStyle:(BubbleStyle)style
{
    [super setStyle:style];
}

-(void)initMap
{
    _map = [[MKMapView alloc] initWithFrame:CGRectMake(3.0, 3.0, 256.0, 144.0)];
    
    [_map.layer setCornerRadius:10.0f];
    [_map setZoomEnabled:NO];
    [_map setScrollEnabled:NO];
    [_map setTintColor:[UIColor colorWithRed:0.11 green:0.74 blue:0.99 alpha:1.0]];
    
    [self.bubble addSubview:_map];
    
    // 3.0 margin around the map
    [self.bubble addConstraint:[NSLayoutConstraint
                                constraintWithItem:_map
                                attribute:NSLayoutAttributeTop
                                relatedBy:NSLayoutRelationEqual
                                toItem:self.bubble
                                attribute:NSLayoutAttributeTop
                                multiplier:1.0
                                constant:3.0]];
    [self.bubble addConstraint:[NSLayoutConstraint
                                constraintWithItem:_map
                                attribute:NSLayoutAttributeLeading
                                relatedBy:NSLayoutRelationEqual
                                toItem:self.bubble
                                attribute:NSLayoutAttributeLeading
                                multiplier:1.0
                                constant:3.0]];
    [self.bubble addConstraint:[NSLayoutConstraint
                                constraintWithItem:_map
                                attribute:NSLayoutAttributeTrailing
                                relatedBy:NSLayoutRelationEqual
                                toItem:self.bubble
                                attribute:NSLayoutAttributeTrailing
                                multiplier:1.0
                                constant:-3.0]];
    [self.bubble addConstraint:[NSLayoutConstraint
                                constraintWithItem:_map
                                attribute:NSLayoutAttributeBottom
                                relatedBy:NSLayoutRelationEqual
                                toItem:self.bubble
                                attribute:NSLayoutAttributeBottom
                                multiplier:1.0
                                constant:-3.0]];
}

-(void)showLocation:(CGFloat)latitude withLongitute:(CGFloat)longitute {
    CLLocationCoordinate2D coord = CLLocationCoordinate2DMake(latitude, longitute);
    
    // Add an annotation
    MKPointAnnotation *point = [[MKPointAnnotation alloc] init];
    point.coordinate = coord;    
    [self.map addAnnotation:point];
    
    MKCoordinateRegion region =
    MKCoordinateRegionMakeWithDistance (coord, 256, 144);
    [_map setRegion:region animated:NO];
}
@end
