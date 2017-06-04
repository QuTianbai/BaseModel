//
//  DKLoginRequestModel.m
//  Doukou
//
//  Created by Doukou on 2017/5/31.
//  Copyright © 2017年 厦门趣品网络有限公司. All rights reserved.
//

#import "DKLoginRequestModel.h"

@implementation DKLoginRequestModel

- (NSString *)url {
    return @"/user/login.json";
}

- (DKHTTPMethod)HTTPMethod {
    return DKHTTPMethodPost;
}

- (Class)responseModelClass {
    return [DKLoginResponseModel class];
}

@end

@implementation DKLoginResponseModel

- (instancetype)init {
    self = [super init];
    if (self) {
//        [self addManualMappingDict:@{@"user_id" : @"userId"}];
    }
    
    return self;
}

@end
