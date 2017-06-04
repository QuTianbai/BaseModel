//
//  Header.h
//  DKDataDemo
//
//  Created by 曲天白 on 2017/6/4.
//  Copyright © 2017年 曲天白. All rights reserved.
//

#ifndef Header_h
#define Header_h

/**
 *  安全地调用 block
 */
#define BLOCK_SAFE_CALLS(block, ...) block ? block(__VA_ARGS__) : nil

/**
 * 单例宏
 */
#define SINGLETON_CLASS()      \
static id manager; \
+ (instancetype)sharedInstance { \
static dispatch_once_t onceToken;   \
dispatch_once(&onceToken, ^{    \
manager = [self new];  \
}); \
return manager; \
}

#endif /* Header_h */
