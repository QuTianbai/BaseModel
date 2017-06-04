//
//  DKLoginBaseRequestModel.m
//  Doukou
//
//  Created by Doukou on 2017/5/31.
//  Copyright © 2017年 厦门趣品网络有限公司. All rights reserved.
//

#import "DKLoginBaseRequestModel.h"

@implementation DKLoginBaseRequestModel

- (Class)responseModelClass {
    return [DKResponseModel class];
}

- (NSString *)responseResultClassString {
    return @"data";
}

- (DKHTTPMethod)HTTPMethod {
    return DKHTTPMethodDefault;
}

- (NSString *)queryString {
    return nil;
}

@end
