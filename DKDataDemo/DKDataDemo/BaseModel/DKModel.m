//
//  DKModel.m
//  Doukou
//
//  Created by Doukou on 2017/6/2.
//  Copyright © 2017年 厦门趣品网络有限公司. All rights reserved.
//

#import "DKModel.h"
#import <objc/runtime.h>
#import "NSString+Extensions.h"
//#import "DKDebug.h"
#import "DKKeyMapManager.h"
/**
 objc_property_attribute_t
 */
#define DKAttributeType              "T" //变量类型
#define DKAttributeVariable          "V" //变量名称
#define DKAttributeSetter            "S" //set方法名称
#define DKAttributeGetter            "G" //get方法名称

/**
 获取子属性class
 @param property property
 @param varName varName
 @return 子属性class
 */
Class typeNameWithDKProperty(objc_property_t property, NSString *varName) {
    NSString *result;
    
    unsigned int outAttribute;
    objc_property_attribute_t *attributes= property_copyAttributeList(property, &outAttribute);
    NSString *propertyName = [[NSString alloc] initWithCString:property_getName(property) encoding:NSUTF8StringEncoding];
    NSString *variableName, *getMethodName, *setMethodName, *typeName;
    
    for (int j = 0; j < outAttribute; ++j) {
        objc_property_attribute_t attribute = attributes[j];
        NSString *value = [NSString stringWithFormat:@"%s", attribute.value];
        
        if (strcmp(attribute.name, DKAttributeType) == 0)
            // {"T", "@\"NSString\""};
            typeName = [[value stringByReplacingOccurrencesOfString:@"@\"" withString:@""] stringByReplacingOccurrencesOfString:@"\"" withString:@""];
        else if (strcmp(attribute.name, DKAttributeVariable) == 0)
            // {"V", "_name"};
            variableName = value;
        else if (strcmp(attribute.name, DKAttributeSetter) == 0)
            // {"S", eg:"setName"};
            setMethodName = value;
        else if (strcmp(attribute.name, DKAttributeGetter) == 0)
            // {"G", eg:"Name"}
            getMethodName = value;
    }
    // 属性和实例一致
    if ((propertyName.length > 0 && [propertyName compare:varName options:NSCaseInsensitiveSearch/*不区分大小写比较*/] == NSOrderedSame)
        || (variableName.length > 0 && [variableName compare:varName options:NSCaseInsensitiveSearch] == NSOrderedSame)
        || (getMethodName.length > 0 && [getMethodName compare:varName options:NSCaseInsensitiveSearch] == NSOrderedSame)) {
        result = typeName;
    } else {
        // 具有setter 方法的
        NSString *propertySetMethod = [NSString stringWithFormat:@"set%@%@:", [[varName substringToIndex:1] capitalizedString]
                                       ,[varName substringFromIndex:1]];
        if (setMethodName.length > 0 && [setMethodName compare:propertySetMethod options:NSCaseInsensitiveSearch] == NSOrderedSame)
            result = typeName;
    }
    
    if (attributes)
        free(attributes);
    
    return result.length > 0 ? NSClassFromString(result) : nil;
}

/**
 *  获取类中属性的类型
 *
 *  @param cls     类结构
 *  @param varName 属性名称
 *
 *  @return 类型
 */
Class typeNameWithDKClass(Class cls, NSString *varName) {
    if (varName.length <= 0)
        return nil;
    
    unsigned int outCount, i;
    
    NSString *result;
    //从属性找
    while (cls != [NSObject class]) {
        objc_property_t *propertys = class_copyPropertyList(cls, &outCount);
        for (i = 0; i < outCount; ++i) {
            objc_property_t property = propertys[i];
            
            Class typeClass = typeNameWithDKProperty(property, varName);
            if (typeClass) {
                result = NSStringFromClass(typeClass);
                break;
            }
        }
        if (propertys)
            free(propertys);
        
        if (result.length > 0)
            break;
        
        cls = class_getSuperclass(cls);
    }
    
    return result.length > 0 ? NSClassFromString(result) : nil;
}

#pragma mark - DKModel ()

@interface DKModel ()

@property (nonatomic, strong) NSMutableArray *ignoredObjects;
@property (nonatomic, strong) NSMutableDictionary *manualMappingDict;
@property (nonatomic, strong) NSArray *data;

@end

#pragma mark - NSDictionary (DKModel)

@implementation NSDictionary (DKModel)

- (void)toModel:(DKModel *)model {
    if (!model.hasProperties) {
        return;
    }
    
    if (self.count > 0) {
        NSEnumerator *keyEnumer = [self keyEnumerator];
        for (id key in keyEnumer) {
            NSString *propertyName = key;
            id propertyValue = [self valueForKey:propertyName];
            if (propertyValue == nil || propertyValue == [NSNull null]) {
                continue;
            }
            
            if (model.enableKeyMapManager) {
                propertyName = [DKKeyMapManager decodeKey:propertyName];
            }
            
            if ([model isKindOfClass:[DKModel class]]) {
                BOOL shouldMapping = [model shouldToModelMappingKey:propertyName forValue:propertyValue];
                if (!shouldMapping) {
                    continue;
                }
            }
           
            NSDictionary *manualMappingDictionary = nil;
            if ([model isKindOfClass:[DKModel class]]) {
                manualMappingDictionary = [(DKModel *)model manualMappingDict];
            }
            NSString *manualMappedKey = [manualMappingDictionary objectForKey:propertyName];
            
            if ([NSString isNotBlank:manualMappedKey]) {
                propertyName = manualMappedKey;
            }
            
            Class typeClass = typeNameWithDKClass([model class], propertyName);
            
            if ([propertyValue isKindOfClass:[NSDictionary class]] && typeClass != nil) {
                if (![typeClass isSubclassOfClass:[NSDictionary class]]) {
                    id obj;
                    if ([typeClass isSubclassOfClass:[DKModel class]]) {
                        obj = [[typeClass alloc] initWithData:propertyValue];
                    } else {
                        obj = [[typeClass alloc] init];
                        [propertyValue toModel:obj];
                    }
                    propertyValue = obj;
                }
            } else if ([propertyValue isKindOfClass:[NSArray class]] && typeClass != nil) {
                if ([model respondsToSelector:@selector(classAtInsideOfObjectWithProperty:)]) {
                    Class objClass = [model classAtInsideOfObjectWithProperty:propertyName];
                    if (objClass != nil) {
                        NSMutableArray *tempArray = [[NSMutableArray alloc] initWithCapacity:[propertyValue count]];
                        for (NSDictionary *dict in propertyValue) {
                            id obj;
                            if ([objClass isSubclassOfClass:[DKModel class]]) {
                                obj = [[objClass alloc] initWithData:dict];
                            }
                            else if ([objClass isSubclassOfClass:[NSString class]]) {
                                obj = dict;
#ifdef DKMODEL_ENABLE_SCALAR_TO_STRING
                                if ([dict.class isSubclassOfClass:[NSNumber class]]) {
                                    obj = [(NSNumber *)dict stringValue];
                                }
#endif
                            }
                            else {
                                obj = [[objClass alloc] init];
                                [dict toModel:obj];
                            }
                            [tempArray addObject:obj];
                        }
                        
                        if (tempArray.count > 0)
                            propertyValue = tempArray;
                    }
                }
            } else if ([typeClass isSubclassOfClass:[NSDate class]]) {
                propertyValue = [NSDate dateWithTimeIntervalSince1970:[propertyValue longLongValue] / 1000.0];
            }
#ifdef DKMODEL_ENABLE_SCALAR_TO_STRING
            else if ([typeClass isSubclassOfClass:[NSString class]] && [propertyValue isKindOfClass:[NSNumber class]]) {
                // 如果是数字类型，而接收者是字符串，则转换成字符串
                propertyValue = [propertyValue stringValue];
            }
#endif
            
            NSString *propertySetMethod = [NSString stringWithFormat:@"set%@%@:", [[propertyName substringToIndex:1] capitalizedString]
                                           ,[propertyName substringFromIndex:1]];
            SEL selector = NSSelectorFromString(propertySetMethod);
            if ([model respondsToSelector:selector]) {
                @try {
                    [model setValue:propertyValue forKey:propertyName];
                } @catch (NSException *exception) {
                    NSLog(@"DKModel encountered an error...setValue:%@ forKey:%@，exception：%@",propertyName, propertyValue, exception);
                }
            }
        }
    }
}

@end

#pragma mark - NSArray (DKModel)

@implementation NSArray (DKModel)

- (void)toModel:(DKModel *)model {
    if (self.count > 0 && [model hasProperties]) {
        if ([model respondsToSelector:@selector(classAtInsideOfObjectWithProperty:)]) {
            Class objClass = [model classAtInsideOfObjectWithProperty:nil];
            if (objClass != nil) {
                NSMutableArray *tempArray = [[NSMutableArray alloc] initWithCapacity:[self count]];
                for (NSDictionary *dict in self) {
                    id obj;
                    if ([objClass isSubclassOfClass:[DKModel class]]) {
                        obj = [[objClass alloc] initWithData:dict];
                    } else if ([dict isKindOfClass:[NSString class]]) {
                        obj = [NSString stringWithString:(NSString *)dict];
                    } else {
                        obj = [[objClass alloc] init];
                        [dict toModel:obj];
                    }
                    [tempArray addObject:obj];
                }
                if (tempArray.count > 0) {
                    if ([model respondsToSelector:@selector(setData:)]) {
                        [model setValue:tempArray forKey:@"data"];
                    }
                }
            }
        }
    }
}

@end

@implementation DKModel

- (instancetype)init {
    self = [super init];
    if (self) {
        // 忽略DKModel 中的工具属性
        [self addIgnoredObjects:@[
                                  NSStringFromSelector(@selector(ignoredObjects)),
                                  NSStringFromSelector(@selector(data)),
                                  NSStringFromSelector(@selector(manualMappingDict)),
                                  ]];
    }
    return self;
}

- (id)initWithData:(id)data {
    if (data == [NSNull null] || data == nil) {
        return nil;
    }
    if (self = [self init]) {
        [self toModelWithData:data];
        self.bodyData = data;
    }
    return self;
}

- (void)copyModelAllPropertiesWithSourceModel:(DKModel *)sourceModel {
    if (sourceModel) {
        Class cls = [sourceModel class];
        while (cls != [NSObject class]) {
            uint count = 0;
            objc_property_t *propertys =  class_copyPropertyList(cls, &count);
            for (int i = 0; i < count; ++i) {
                objc_property_t property = propertys[i];
                NSString *propertyName = [NSString stringWithCString:property_getName(property) encoding:NSUTF8StringEncoding];
                
                if ([self.ignoredObjects containsObject:propertyName]) {
                    continue;
                }
                
                NSString *propertySetMethod = [NSString stringWithFormat:@"set%@%@:", [[propertyName substringToIndex:1] capitalizedString]
                                               ,[propertyName substringFromIndex:1]];
                SEL selector = NSSelectorFromString(propertySetMethod);
                if ([self respondsToSelector:selector]) {
                    [self setValue:[sourceModel valueForKey:propertyName] forKey:propertyName];
                }
            }
            
            if (propertys)
                free(propertys);
            
            cls = class_getSuperclass(cls);
        }
    }
}

- (BOOL)hasProperties {
    return YES;
}

- (BOOL)enableKeyMapManager {
    return YES;
}

- (void)toModelWithData:(id)data {
    if ([data isKindOfClass:[NSDictionary class]]) {
        [(NSDictionary *)data toModel:self];
    } else if ([data isKindOfClass:[NSArray class]]) {
        [(NSArray *)data toModel:self];
    } else {
        assert(0);
    }
}

- (NSDictionary *)toDictionary {
    unsigned int outCount;
    Class cls = [self class];
    
    NSMutableDictionary *returnDic = [[NSMutableDictionary alloc] init];
    
    while (cls != [NSObject class]) {
        objc_property_t *propertys = class_copyPropertyList(cls, &outCount);
        
        for (int i = 0 ; i < outCount ; i ++) {
            objc_property_t property = propertys[i];
            NSString *propertyName = [NSString stringWithCString:property_getName(property) encoding:NSUTF8StringEncoding];
            if ([propertyName isEqualToString:NSStringFromSelector(@selector(description))]
                || [propertyName isEqualToString:NSStringFromSelector(@selector(debugDescription))]) {
                continue;
            }
            
            if ([self.ignoredObjects containsObject:propertyName]) {
                continue;
            }
            
            id propertyValue = [self valueForKey:propertyName];
            
            Class typeClass = typeNameWithDKProperty(property, propertyName);
            if ([typeClass isSubclassOfClass:[NSArray class]]) {
                NSMutableArray *arr = [[NSMutableArray alloc] init];
                for (id obj in propertyValue) {
                    if ([obj isKindOfClass:[DKModel class]]) {
                        [arr addObject:[obj toDictionary]];
                    } else {
                        [arr addObject:obj];
                    }
                }
                propertyValue = arr;
            } else if ([typeClass isSubclassOfClass:[DKModel class]]) {
                id obj = [propertyValue toDictionary];
                propertyValue = obj;
            } else if ([typeClass isSubclassOfClass:[NSDate class]]) {
                propertyValue = @((unsigned long long)([(NSDate *)propertyValue timeIntervalSince1970] * 1000));
            }
            
            if (propertyValue) {
                NSString *mappedKey = [self.manualMappingDict objectForKey:propertyName];
                if ([NSString isNotBlank:mappedKey]) {
                    propertyName = mappedKey;
                }
                
                if (self.enableKeyMapManager) {
                    propertyName = [DKKeyMapManager encodeKey:propertyName];
                }
                
                NSDictionary *entries = [self shouldToDictionaryMappingKey:propertyName forValue:propertyValue];
                if (entries && entries.count > 0) {
                    [returnDic addEntriesFromDictionary:entries];
                }
            }
        }
        
        if (propertys)
            free(propertys);
        
        cls = class_getSuperclass(cls);
    }
    return returnDic.count ? returnDic : nil;
}

- (void)addIgnoredObjects:(NSArray *)objects {
    assert([objects isKindOfClass:[NSArray class]]);
    [self.ignoredObjects addObjectsFromArray:objects];
}

- (void)addManualMappingDict:(NSDictionary *)dict {
    assert([dict isKindOfClass:[NSDictionary class]]);
    [self.manualMappingDict addEntriesFromDictionary:dict];
}

- (Class)classAtInsideOfObjectWithProperty:(NSString *)propertyName {
    return nil;
}

- (NSString *)description {
    NSDictionary *dict = [self toDictionary];
    NSMutableString *mDescription = [[NSMutableString alloc] init];
    [mDescription appendFormat:@"%@\r",[super description]];
    if (dict.count > 0) {
        NSEnumerator *keyEnumer = [dict keyEnumerator];
        for (id key in keyEnumer) {
            NSString *propertyName = key;
            id propertyValue = [dict valueForKey:propertyName];
            if (propertyValue == nil)
                continue;
            
            [mDescription appendFormat:@"%@:%@\r",propertyName, propertyValue];
        }
        
        if (mDescription.length > 0)
            return mDescription;
    }
    
    return [super description];
}

#pragma mark - Private methods

- (NSMutableArray *)ignoredObjects {
    if (_ignoredObjects == nil) {
        _ignoredObjects = [NSMutableArray new];
    }
    return _ignoredObjects;
}

- (NSMutableDictionary *)manualMappingDict {
    if (_manualMappingDict == nil) {
        _manualMappingDict = [NSMutableDictionary new];
    }
    return _manualMappingDict;
}

- (BOOL)shouldToModelMappingKey:(NSString *)key forValue:(id)value {
    return YES;
}

- (NSDictionary *)shouldToDictionaryMappingKey:(NSString *)key forValue:(NSDictionary *)value {
    return @{key : value};
}

@end
