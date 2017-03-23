//
//  Utils.m
//  uMessage
//
//  Created by Max Dratwa on 23.03.17.
//  Copyright © 2017 Codecamp. All rights reserved.
//

#import "Utils.h"

@implementation Utils

/**
 Get current timestamp as NSString

 @return String with Timestamp ISO 8601
 */
+ (NSString *)getTimestamp {
    NSISO8601DateFormatter *formatter = [[NSISO8601DateFormatter alloc] init];
    return [formatter stringFromDate:[NSDate date]];
}

@end
