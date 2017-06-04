//
//  DKLoginManager.h
//  Doukou
//
//  Created by Doukou on 2017/5/31.
//  Copyright © 2017年 厦门趣品网络有限公司. All rights reserved.
//


#import "DKLoginRequestModel.h"
#define GetLoginManager()		([DKLoginManager sharedInstance])

@interface DKLoginManager : NSObject

+ (instancetype)sharedInstance;

- (void)asyncFetchUserConfigWithUsername:(NSString *)username password:(NSString *)password completeBlock:(void (^)(DKLoginResponseModel *model, NSError *error))completeBlock;

@end
