//
//  DKDataManager.m
//  Doukou
//
//  Created by 曲天白 on 2017/6/4.
//  Copyright © 2017年 厦门趣品网络有限公司. All rights reserved.
//

#import "DKDataManager.h"
#import "DKHttpRequest.h"
#import "Header.h"

@interface NSError (Extensions)

// 生成统一 Domain 的错误对象
+ (NSError *)makeErrorWithCode:(NSInteger)code message:(NSString *)message;

@end

@implementation NSError (Extensions)

+ (NSError *)makeErrorWithCode:(NSInteger)code message:(NSString *)message {
    static NSString *bundleName;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        bundleName = [[[NSBundle mainBundle] infoDictionary] objectForKey:(NSString*)kCFBundleNameKey];
        
    });
    return [NSError errorWithDomain:bundleName
                               code:code
                           userInfo:@{
                                      NSLocalizedDescriptionKey : message == nil ? @"" : message
                                      }];
}

@end

@interface DKDataManager ()

@property (nonatomic, strong) DKHttpRequest *httpManager;

@end

@implementation DKDataManager

- (instancetype)init {
    return [self initWithDelegate:nil];
}

- (instancetype)initWithDelegate:(id<DKDataManagerDelegate>)delegate {
    self = [super init];
    if (self) {
        self.httpManager = [DKHttpRequest new];
        self.delegate = delegate;
        self.timeout = 20;
    }
    return self;
}

#pragma mark - Public methods

- (void)setResponseQueue:(dispatch_queue_t)responseQueue {
    self.httpManager.responseQueue = responseQueue;
}

- (dispatch_queue_t)responseQueue {
    return self.httpManager.responseQueue;
}

- (void)setTimeout:(NSUInteger)timeout {
    _timeout = timeout;
    self.httpManager.timeout = timeout;
}

- (BOOL)isRequesting {
    return self.httpManager.isRequesting;
}

- (BOOL)allowConcurrent {
    return self.httpManager.allowConcurrent;
}

- (void)setAllowConcurrent:(BOOL)allowConcurrent {
    self.httpManager.allowConcurrent = allowConcurrent;
}

- (void)requestWithRequestModel:(DKRequestModel *)requestModel {
    [self.httpManager requestByModel:requestModel withResponseBlock:^(NSError *error, id responseObject) {
        if (error == nil) {
            [self requestSuccessfulWithResponseModel:responseObject];
        } else {
            [self requestFailedWithError:error];
        }
    }];
}

- (void)requestWithRequestModel:(DKRequestModel *)requestModel completedBlock:(void (^)(DKResponseModel *, NSError *))completedBlock {
    if ([self.httpManager canRequest]) {
        [self.httpManager requestByModel:requestModel withResponseBlock:^(NSError *error, id responseObject) {
            BLOCK_SAFE_CALLS(completedBlock, responseObject, error);
        }];
    } else {
        BLOCK_SAFE_CALLS(completedBlock, nil, [NSError makeErrorWithCode:NSURLErrorNotConnectedToInternet
                                                                 message:NSLocalizedString(@"network_error_no_network", @"无网络")]);
    }
}

- (void)cancelRequest {
    [self.httpManager cancelRequest];
}

#pragma mark - Private methods

- (void)requestSuccessfulWithResponseModel:(DKResponseModel *)responseModel {
    if (self.delegate && [self.delegate respondsToSelector:@selector(dataManager:successfulWithData:)]) {
        dispatch_async(dispatch_get_main_queue(), ^{
            [self.delegate dataManager:self successfulWithData:responseModel];
        });
    }
}

- (void)requestFailedWithError:(NSError *)error {
    if (self.delegate && [self.delegate respondsToSelector:@selector(dataManager:failedWithError:)]) {
        dispatch_async(dispatch_get_main_queue(), ^{
            [self.delegate dataManager:self failedWithError:error];
        });
    }
}

@end
