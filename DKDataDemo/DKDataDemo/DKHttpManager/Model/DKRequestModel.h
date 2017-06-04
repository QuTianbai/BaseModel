//
//  DKRequsetModel.h
//  Doukou
//
//  Created by Doukou on 2017/6/2.
//  Copyright © 2017年 厦门趣品网络有限公司. All rights reserved.
//

#import "DKModel.h"
#import "DKResponseModel.h"

typedef enum {
    DKHTTPMethodGet,
    DKHTTPMethodPost,
    DKHTTPMethodPut,
    DKHTTPMethodDelete,
    DKHTTPMethodMultipart,
    
    DKHTTPMethodDefault = DKHTTPMethodPost
} DKHTTPMethod;

@protocol DKRequestModelConfig

- (DKHTTPMethod)HTTPMethod;

- (Class)responseModelClass;

- (NSString *)responseResultClassString;

// 是否请求已带Json参数, 如果是, 则忽略requestModel里的请求属性
- (NSString *)queryString;

@required

- (NSString *)url;

- (NSString *)baseUrl;

@end

@interface DKRequestModel : DKModel <DKRequestModelConfig>
// 自定义对象 转model字典记得不转这个属性
@property (nonatomic, strong) id userInfo;

@end
