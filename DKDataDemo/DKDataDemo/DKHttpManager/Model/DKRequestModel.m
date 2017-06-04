//
//  DKRequsetModel.m
//  Doukou
//
//  Created by Doukou on 2017/6/2.
//  Copyright © 2017年 厦门趣品网络有限公司. All rights reserved.
//

#import "DKRequestModel.h"

@implementation DKRequestModel

- (instancetype)init {
    self = [super init];
    if (self) {
        [self addIgnoredObjects:@[
                                  NSStringFromSelector(@selector(userInfo))
                                  ]];
    }
    return self;
}

- (NSString *)url {
    assert(0);
    return @"";
}

- (NSString *)baseUrl {
    return @"http://api.dev.doukou.com/v2";
}

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
