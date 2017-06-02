//
//  DKKeyMapManager.h
//  Doukou
//
//  Created by Doukou on 2017/6/2.
//  Copyright © 2017年 厦门趣品网络有限公司. All rights reserved.
//

#import <Foundation/Foundation.h>

@interface DKKeyMapManager : NSObject

+ (NSString *)decodeKey:(NSString *)originalKey;
+ (NSString *)encodeKey:(NSString *)originalKey;

@end
