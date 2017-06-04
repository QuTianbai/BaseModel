//
//  DKHttpRequset.h
//  Doukou
//
//  Created by Doukou on 2017/6/2.
//  Copyright © 2017年 厦门趣品网络有限公司. All rights reserved.
//

#import <Foundation/Foundation.h>

@class DKRequestModel;

typedef enum {
    NetworkHttpResponseDataTypeJSON = 1,    //以 json 解析,默认值
    NetworkHttpResponseDataTypeXML = 2,     //以 xml 解析
    
    NetworkHttpResponseDataTypeDefault = NetworkHttpResponseDataTypeJSON
} NetworkHttpResponseDataType;

typedef void(^DKResponseBlock)(NSError *error,id responseObject);

@interface DKHttpRequest : NSObject

/**
 *  生成服务器请求地址 
 */
+ (NSString *)generateBaseUrl:(NSString *)baseUrl requestURLByString:(NSString *)string;

// 取消所有的请求
+ (void)cancelAllRequests;

/**
 * Response Data 的解析方式，默认为 NetworkHttpResponseDataTypeJSON
 */
@property (nonatomic) NetworkHttpResponseDataType responseDataType;

/**
 *  响应回调队列，默认为一个异步的 Serial 队列
 */
@property (nonatomic, strong) dispatch_queue_t responseQueue;

/**
 *  请求超时时间，单位（秒），默认 20 秒
 */
@property (nonatomic) NSTimeInterval timeout;

/**
 *  是否允许并发请求，默认为 NO
 */
@property (nonatomic, assign) BOOL allowConcurrent;

/**
 *  返回当前是否在请求，如果 allowConcurrent 为 YES，将遍历当前所有的请求，有任何一个在请求就返回 YES
 */
@property (nonatomic, assign) BOOL isRequesting;

/**
 *  取消请求
 */
- (void)cancelRequest;

/**
 *  根据 Model 请求服务器数据
 *
 *  @param model 请求 Model 类
 *  @param block 请求完成或超时时,回调 block
 */
- (void)requestByModel:(DKRequestModel *)requestModel withResponseBlock:(DKResponseBlock)block;

// 默认是判断有无网络(未实现)
- (BOOL)canRequest;

@end
