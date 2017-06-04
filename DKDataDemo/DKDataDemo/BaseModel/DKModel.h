//
//  DKModel.h
//  Doukou
//
//  Created by Doukou on 2017/6/2.
//  Copyright © 2017年 厦门趣品网络有限公司. All rights reserved.
//

#import <Foundation/Foundation.h>

@interface NSDictionary (DKModel)

- (void)toModel:(id)model;

@end

@interface DKModel : NSObject

- (id)initWithData:(id)data;

- (void)copyModelAllPropertiesWithSourceModel:(DKModel *)sourceModel;

@property (nonatomic, readonly) NSArray *data;

@property (nonatomic, strong) id bodyData;

- (BOOL)hasProperties;

- (NSDictionary *)toDictionary;

- (BOOL)enableKeyMapManager;

- (Class)classAtInsideOfObjectWithProperty:(NSString *)propertyName;

- (void)addIgnoredObjects:(NSArray *)objects;

- (void)addManualMappingDict:(NSDictionary *)dict;

- (BOOL)shouldToModelMappingKey:(NSString *)key forValue:(id)value;

- (NSDictionary *)shouldToDictionaryMappingKey:(NSString *)key forValue:(NSDictionary *)value;

@end
