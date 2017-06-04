
#import <Foundation/Foundation.h>


@interface NSString (Extensions)

+ (BOOL)isBlank:(NSString *)str;

+ (BOOL)isNotBlank:(NSString *)str;

- (BOOL)isContain:(NSString*)asubstr;

- (BOOL)isWhitespaceAndNewlines;

- (BOOL)isEmptyOrWhitespace;

- (NSString *)replaceOldString:(NSString *)strOld WithNewString:(NSString *)strNew;



@end

