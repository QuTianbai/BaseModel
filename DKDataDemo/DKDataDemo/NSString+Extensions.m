

#import "NSString+Extensions.h"
#import <CommonCrypto/CommonCrypto.h>
#import <MobileCoreServices/MobileCoreServices.h>

@implementation NSString (Extensions)

- (BOOL)isContain:(NSString *)asubstr {
    NSRange rg = [self rangeOfString:asubstr];
    return rg.length > 0;
}

- (BOOL)isWhitespaceAndNewlines {
    NSCharacterSet *whitespace = [NSCharacterSet whitespaceAndNewlineCharacterSet];
    for (NSInteger i = 0; i < self.length; ++i) {
        unichar c = [self characterAtIndex:i];
        if (![whitespace characterIsMember:c]) {
            return NO;
        }
    }
    return YES;
}

- (BOOL)isEmptyOrWhitespace {
    if (self.length == 0) {
        return YES;
    }
    
    for (int i = 0; i < self.length; ++i) {
        unichar c = [self characterAtIndex:i];
        if (c != 9 && c != 10 && c != 11 && c != 32) {
            return NO;
        }
    }
    
    return YES;
}

+ (BOOL)isBlank:(NSString *)str {
    return str == nil || [str isEqual:[NSNull null]] || [str isEmptyOrWhitespace];
}

+ (BOOL)isNotBlank:(NSString *)str {
    return ![NSString isBlank:str];
}

- (NSString *)replaceOldString:(NSString *)strOld WithNewString:(NSString *)strNew {
    NSMutableString *strMutale = [NSMutableString stringWithString:self];
    NSRange r;
    r.location = 0;
    r.length = [self length];
    [strMutale replaceOccurrencesOfString:strOld withString:strNew options:NSCaseInsensitiveSearch range:r];
    return [NSString stringWithString:strMutale];
}

@end
