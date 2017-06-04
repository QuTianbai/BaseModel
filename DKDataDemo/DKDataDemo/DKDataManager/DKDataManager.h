//
//  DKDataManager.h
//  Doukou
//
//  Created by 曲天白 on 2017/6/4.
//  Copyright © 2017年 厦门趣品网络有限公司. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "DKRequestModel.h"
#import "DKResponseModel.h"

@class DKDataManager;

@protocol DKDataManagerDelegate <NSObject>

- (void)dataManager:(DKDataManager *)dataManager successfulWithData:(DKResponseModel *)responseModel;
- (void)dataManager:(DKDataManager *)dataManager failedWithError:(NSError *)error;

@end

@interface DKDataManager : NSObject

- (instancetype)initWithDelegate:(id<DKDataManagerDelegate>)delegate;

@property (nonatomic, weak) id<DKDataManagerDelegate> delegate;

// 超时时间，默认20秒
@property (nonatomic, assign) NSUInteger timeout;

/**
 *  响应回调队列，默认为一个异步的 Serial 队列
 */
@property (nonatomic, strong) dispatch_queue_t responseQueue;

/**
 *  返回当前是否在请求，如果 allowConcurrent 为 YES，将遍历当前所有的请求，有任何一个在请求就返回 YES
 */
@property (nonatomic, assign, readonly) BOOL isRequesting;

/**
 *  是否允许并发请求，默认为 NO
 */
@property (nonatomic, assign) BOOL allowConcurrent;

- (void)requestWithRequestModel:(DKRequestModel *)requestModel;

- (void)requestWithRequestModel:(DKRequestModel *)requestModel
                 completedBlock:(void(^)(DKResponseModel *responseModel, NSError *error))completedBlock;

- (void)cancelRequest;

@end
