//
//  DKResponseModel.m
//  Doukou
//
//  Created by Doukou on 2017/6/2.
//  Copyright © 2017年 厦门趣品网络有限公司. All rights reserved.
//

#import "DKResponseModel.h"

@implementation DKResponseModel

- (instancetype)init {
    self = [super init];
    if (self) {
        
    }
    return self;
}

- (BOOL)hasProperties {
    return [self isMemberOfClass:[DKResponseModel class]] ? NO : YES;
}

@end
