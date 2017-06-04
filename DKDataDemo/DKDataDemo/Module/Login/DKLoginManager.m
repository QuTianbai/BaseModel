//
//  DKLoginManager.m
//  Doukou
//
//  Created by Doukou on 2017/5/31.
//  Copyright © 2017年 厦门趣品网络有限公司. All rights reserved.
//

#import "DKLoginManager.h"
#import "DKDataManager.h"
#import "Header.h"

@interface DKLoginManager ()

@property (nonatomic, strong) DKDataManager *loginRequest;

@end

@implementation DKLoginManager

SINGLETON_CLASS();

- (DKDataManager *)loginRequest {
    if (_loginRequest == nil) {
        _loginRequest = [[DKDataManager alloc] init];
    }
    
    return _loginRequest;
}

- (void)asyncFetchUserConfigWithUsername:(NSString *)username password:(NSString *)password completeBlock:(void (^)(DKLoginResponseModel *model, NSError *error))completeBlock {
    
    DKLoginRequestModel *requestModel = [DKLoginRequestModel new];
    requestModel.verification = username;
    requestModel.password = password;
    
    [self.loginRequest requestWithRequestModel:requestModel completedBlock:^(DKResponseModel *responseModel, NSError *error) {
        if (error == nil) {
            DKLoginResponseModel *ResponseModel = (DKLoginResponseModel *)responseModel;
            BLOCK_SAFE_CALLS(completeBlock, ResponseModel, error);
        } else {
            BLOCK_SAFE_CALLS(completeBlock, nil, error);
        }
    }];
}

@end
