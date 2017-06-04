//
//  DKLoginRequestModel.h
//  Doukou
//
//  Created by Doukou on 2017/5/31.
//  Copyright © 2017年 厦门趣品网络有限公司. All rights reserved.
//

#import "DKLoginBaseRequestModel.h"
#import "DKResponseModel.h"

@interface DKLoginRequestModel : DKLoginBaseRequestModel

@property (nonatomic, copy) NSString *verification;
@property (nonatomic, copy) NSString *password;

@end

@interface DKLoginResponseModel : DKResponseModel

@property (nonatomic, copy) NSString *userId;
@property (nonatomic, copy) NSString *token;

@end
