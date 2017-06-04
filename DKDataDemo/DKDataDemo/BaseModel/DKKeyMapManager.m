//
//  DKKeyMapManager.m
//  Doukou
//
//  Created by Doukou on 2017/6/2.
//  Copyright © 2017年 厦门趣品网络有限公司. All rights reserved.
//

#import "DKKeyMapManager.h"
#import "NSString+Extensions.h"
/**
 是否有大写字母

 @param originalKey originalKey
 @return BOOL
 */
BOOL needsToEncode(NSString *originalKey) {
    NSCharacterSet *uppercaseLetterSet = [NSCharacterSet uppercaseLetterCharacterSet];
    return [originalKey rangeOfCharacterFromSet:uppercaseLetterSet].location != NSNotFound;
}

/**
 去除所有@"_",并且全部小写

 @param originalKey originalKey
 @return 去除所有@"_",并且全部小写
 */
NSString *decodeKey(NSString *originalKey) {
    // 单词首字母大写,并且去除@"_"
    NSString *capitalizedKey = [[originalKey capitalizedString] replaceOldString:@"_" WithNewString:@""];
    // 首字母变小写
    return [NSString stringWithFormat:@"%@%@",[[capitalizedKey substringToIndex:1] lowercaseString],[capitalizedKey substringFromIndex:1]];
}

/**
 在原来每个大写字母前加@"_",并且全部转换为小写字母

 @param originalKey originalKey
 @return 在原来每个大写字母前加@"_",并且全部转换为小写字母
 */
NSString *encodeKey(NSString *originalKey) {
    NSCharacterSet *uppercaseLetterSet = [NSCharacterSet uppercaseLetterCharacterSet];
    
    NSMutableString *encodedKey = [NSMutableString stringWithString:originalKey];
    NSRange range = NSMakeRange(0, originalKey.length);
    //在大写字母前加入@"_"
    while ((range = [encodedKey rangeOfCharacterFromSet:uppercaseLetterSet
                                                options:0
                                                  range:range]).location != NSNotFound) {
        [encodedKey insertString:@"_" atIndex:range.location];
        range = NSMakeRange(range.location + 2, encodedKey.length - range.location - 2);
    }
    return [encodedKey lowercaseString];
}

@interface DKKeyMapManager ()

@property (nonatomic, strong) NSMutableDictionary *encodedKeyMapDict;
@property (nonatomic, strong) NSMutableDictionary *decodedKeyMapDict;

@end

@implementation DKKeyMapManager

static DKKeyMapManager *keyMapManager;
+ (void)initialize {
    if (self == [DKKeyMapManager class]) {
        keyMapManager = [DKKeyMapManager new];
    }
}

- (instancetype)init {
    self = [super init];
    if (self) {
        _encodedKeyMapDict = [NSMutableDictionary dictionary];
        _decodedKeyMapDict = [NSMutableDictionary dictionary];
    }
    return self;
}

/**
 去除@"_",并且全部小写

 @param originalKey originalKey
 @return 去除@"_",并且全部小写
 */
+ (NSString *)decodeKey:(NSString *)originalKey {
    @synchronized (keyMapManager) {
        assert([NSString isNotBlank:originalKey]);
        
        if ([originalKey isContain:@"_"]) {
            NSString *mappedKey = [keyMapManager.decodedKeyMapDict objectForKey:originalKey];
            if ([NSString isBlank:mappedKey]) {
                mappedKey = decodeKey(originalKey);
                if ([NSString isNotBlank:mappedKey]) {
                    [keyMapManager.decodedKeyMapDict setObject:[mappedKey copy] forKey:originalKey];
                }
            }
            return mappedKey;
        }
        return originalKey;
    }
}

/**
 在原来大写字母前加@"_",并且全部转换为小写字母

 @param originalKey originalKey
 @return 在原来大写字母前加@"_",并且全部转换为小写字母
 */
+ (NSString *)encodeKey:(NSString *)originalKey {
    @synchronized (keyMapManager) {
        assert([NSString isNotBlank:originalKey]);
        
        if (needsToEncode(originalKey)) {
            NSString *mappedKey = [keyMapManager.encodedKeyMapDict objectForKey:originalKey];
            if ([NSString isBlank:mappedKey]) {
                mappedKey = encodeKey(originalKey);
                [keyMapManager.encodedKeyMapDict setObject:mappedKey forKey:originalKey];
            }
            return mappedKey;
        }
        return originalKey;
    }
}


@end
