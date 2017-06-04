//
//  DKHttpRequset.m
//  Doukou
//
//  Created by Doukou on 2017/6/2.
//  Copyright © 2017年 厦门趣品网络有限公司. All rights reserved.
//

#import "DKHttpRequest.h"
#import "AFNetworking.h"
#import "DKRequestModel.h"
#import "DKResponseModel.h"
#import "NSString+Extensions.h"
#define INT_TO_STRING(i)		[NSString stringWithFormat:@"%zd",i]

#define DKHTTPERROR_CODE (1111)
#define DKHTTPSUCESS_CODE (1000)

@interface DKConcurrentMutableDictionary : NSMutableDictionary

@property (nonatomic, strong) NSOperationQueue *processQueue;
@property (nonatomic, strong) NSMutableDictionary *_dictionary;

@end

@implementation DKConcurrentMutableDictionary

- (NSOperationQueue *)processQueue {
    if (_processQueue == nil) {
        _processQueue = [NSOperationQueue new];
        _processQueue.name = @"DKConcurrentMutableDictionary_PROCESS_QUEUE";
        _processQueue.maxConcurrentOperationCount = 1;
    }
    
    return _processQueue;
}

- (NSMutableDictionary *)_dictionary {
    if (__dictionary == nil) {
        __dictionary = [NSMutableDictionary new];
    }
    
    return __dictionary;
}

- (id)objectForKey:(id)aKey {
    return [self._dictionary objectForKey:aKey];
}

- (void)setObject:(id)anObject forKey:(id<NSCopying>)aKey {
    [self.processQueue addOperationWithBlock:^{
        [self._dictionary setObject:anObject forKey:aKey];
    }];
}

- (void)removeObjectForKey:(id)aKey {
    [self.processQueue addOperationWithBlock:^{
        [self._dictionary removeObjectForKey:aKey];
    }];
}

- (void)removeObjectsForKeys:(NSArray *)keyArray {
    [self.processQueue addOperationWithBlock:^{
        [self._dictionary removeObjectsForKeys:keyArray];
    }];
}

- (void)removeAllObjects {
    [self.processQueue addOperationWithBlock:^{
        [self._dictionary removeAllObjects];
    }];
}

- (NSUInteger)count {
    return [self._dictionary count];
}

- (NSArray * _Nonnull)allValues {
    return [self._dictionary allValues];
}

- (NSEnumerator *)keyEnumerator {
    return [self._dictionary keyEnumerator];
}

- (id)initWithObjects:(const id  _Nonnull __unsafe_unretained *)objects forKeys:(const id<NSCopying>  _Nonnull __unsafe_unretained *)keys count:(NSUInteger)cnt {
    return [super initWithObjects:objects forKeys:keys count:cnt];
}

@end

typedef void (^DKRequestSuccessBlock)(NSURLSessionTask *task, id responseObject);
typedef void (^DKRequestFailedBlock)(NSURLSessionTask *task, NSError *error);

static NSMutableDictionary<NSString *, NSString *> *fixedHTTPHeaders; // 统一请求头
static NSMutableDictionary<NSString *, NSArray *> *allTasks; // 当前所有正在执行或还未执行的请求
static NSString *authorization; // 授权

@interface DKHttpRequest ()
@property (nonatomic, strong) NSMutableDictionary<NSString *, NSURLSessionTask *> *tasks;
@end

@implementation DKHttpRequest

+ (void)initialize {
    if (self == [DKHttpRequest class]) {
        [[self class] setFixedHTTPHeader:@"Accept" value:@"application/json"];
        [[self class] setFixedHTTPHeader:@"Content-Type" value:@"application/x-www-form-urlencoded"];
        [[self class] setFixedHTTPHeader:@"platform" value:@"mobile"];
    }
}

+ (NSString *)generateBaseUrl:(NSString *)baseUrl requestURLByString:(NSString *)string {
    assert([NSString isNotBlank:string]);
    return [NSString stringWithFormat:@"%@%@",baseUrl,string];
}

+ (void)setAuthorization:(NSString *)value {
    authorization = value;
}

+ (void)removeAuthorization {
    authorization = nil;
}

+ (BOOL)setFixedHTTPHeader:(NSString *)header value:(NSString *)value {
    if (fixedHTTPHeaders == nil) {
        fixedHTTPHeaders = [[NSMutableDictionary alloc] init];
    }
    
    [fixedHTTPHeaders setObject:value forKey:header];
    
    return YES;
}

+ (void)cancelAllRequests {
    NSArray *allValues = allTasks.allValues;
    for (NSInteger i = allValues.count - 1; i >= 0; --i) {
        NSArray *values = allValues[i];
        
        NSURLSessionTask *task = values[0];
        
        [task cancel];
        
        [allTasks removeObjectForKey:INT_TO_STRING(task.taskIdentifier)];
    }
}

- (id)init {
    if (self = [super init]) {
        self.responseDataType = NetworkHttpResponseDataTypeDefault;
        self.responseQueue = dispatch_get_main_queue();
        self.timeout = 20;
    }
    return self;
}

- (void)cancelRequest {
    if (self.tasks.count > 0) {
        [self.tasks enumerateKeysAndObjectsUsingBlock:^(NSString * _Nonnull key, NSURLSessionTask * _Nonnull task, BOOL * _Nonnull stop) {
            [task cancel];
        }];
        
        [allTasks removeObjectsForKeys:self.tasks.allKeys];
        [self.tasks removeAllObjects];
    }
}

- (BOOL)canRequest {
    return YES;
}

- (BOOL)isRequesting {
    return self.tasks.count > 0;
}

static AFHTTPSessionManager *manager;
- (AFHTTPSessionManager *)sharedManager {
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        manager = [AFHTTPSessionManager manager];
        manager.operationQueue.maxConcurrentOperationCount = 5;
        manager.completionQueue = dispatch_get_global_queue(0, 0);
        manager.responseSerializer = [AFJSONResponseSerializer serializer];
        manager.responseSerializer.acceptableContentTypes = [NSSet setWithObjects:@"application/json", @"text/json", @"text/javascript", @"text/html", nil];
        manager.securityPolicy.allowInvalidCertificates = YES;
        manager.securityPolicy.validatesDomainName = NO;
    });
    
    return manager;
}

- (AFHTTPRequestSerializer *)requestHTTPSerializerForModel:(DKRequestModel *)model {
    AFHTTPRequestSerializer *serializer = [AFHTTPRequestSerializer serializer];
    [serializer willChangeValueForKey:@"timeoutInterval"];
    serializer.timeoutInterval = self.timeout;
    serializer.HTTPMethodsEncodingParametersInURI = [NSSet setWithObjects:@"GET", @"HEAD", nil];
    [fixedHTTPHeaders enumerateKeysAndObjectsUsingBlock:^(id  _Nonnull key, id  _Nonnull obj, BOOL * _Nonnull stop) {
        [serializer setValue:obj forHTTPHeaderField:key];
    }];
    
    if (authorization != nil) {
        [serializer setValue:authorization forHTTPHeaderField:@"Authorization"];
    }
    
    return serializer;
}

- (void)requestByModel:(DKRequestModel *)requestModel withResponseBlock:(DKResponseBlock)block {
    if (!self.allowConcurrent) {
        [self cancelRequest];
    }
    NSString *url = [DKHttpRequest generateBaseUrl:requestModel.baseUrl requestURLByString:requestModel.url];
    
    id params = [requestModel queryString];
    if (params == nil) {
        params = [requestModel toDictionary];
    } else {
        url = [url stringByAppendingFormat:@"?%@", params];
        params = nil;
    }
    
    @synchronized([self sharedManager]) {
        NSURLSessionTask *task = nil;
        NSString *HTTPMethod = nil;
        
        switch (requestModel.HTTPMethod) {
            case DKHTTPMethodGet:
                HTTPMethod = @"GET";
                break;
            case DKHTTPMethodPost:
                HTTPMethod = @"POST";
                break;
            case DKHTTPMethodPut:
                HTTPMethod = @"PUT";
                break;
            case DKHTTPMethodDelete:
                HTTPMethod = @"DELETE";
                break;
            default:
                assert(0);
        }
        AFHTTPRequestSerializer *serializer = [self requestHTTPSerializerForModel:requestModel];
        NSURLRequest *request = [serializer requestWithMethod:HTTPMethod URLString:url parameters:params error:nil];
        NSMutableArray<NSURLSessionTask *> *currentTask = [NSMutableArray arrayWithCapacity:1];
        task = [[self sharedManager] dataTaskWithRequest:request completionHandler:^(NSURLResponse * _Nonnull response, id  _Nullable responseObject, NSError * _Nullable error) {
            __strong DKHttpRequest *strongSelf = self;
            
            NSURLSessionTask *tempTask = [currentTask firstObject];
            if (![strongSelf checkTaskIsValid:tempTask]) {
                return;
            }
#ifdef HTTP_CONNECTION_LOG
            DKLog(@"HttpResponse:\n[\n  State:%@\n  Type:%@\n  Url:%@\n  result:%@\n]\n",
                  error == nil ? @"success" : @"fail",
                  tempTask.originalRequest.HTTPMethod, url, responseObject);
#endif
            [strongSelf resultProcess:error operation:tempTask requestModel:requestModel result:responseObject withBlock:block];
        }];
        
        [self.tasks setObject:task forKey:INT_TO_STRING(task.taskIdentifier)];
        [allTasks setObject:@[task, requestModel] forKey:INT_TO_STRING(task.taskIdentifier)];
        
#ifdef HTTP_CONNECTION_LOG
        DKLog(@"HttpRequest:\n[\n  Type:%@\n  Url:%@\n  params:%@\n]", task.originalRequest.HTTPMethod, url, params);
#endif
        
        [currentTask addObject:task];
        [task resume];
    }
}

- (void)resultProcess:(NSError *)err
            operation:(NSURLSessionTask *)task
         requestModel:(DKRequestModel *)requestModel
               result:(id)data withBlock:(DKResponseBlock)block {
    id modelData = data;
    
    NSError *error = [self makeErrorWithError:err httpResponseCode:[(NSHTTPURLResponse *)task.response statusCode] result:data];
    if (error != nil) {
        if (error.code == -999) { // 被取消的请求不回调
            NSLog(@"请求 %@ 被cancel", task.originalRequest.URL);
            [self.tasks removeObjectForKey:INT_TO_STRING(task.taskIdentifier)];
            [allTasks removeObjectForKey:INT_TO_STRING(task.taskIdentifier)];
            return;
        }

    } else {
        if (modelData && requestModel.responseModelClass) {
            if ([requestModel.responseModelClass isSubclassOfClass:[DKResponseModel class]]) {
                DKResponseModel *responseModel = [requestModel.responseModelClass alloc];
                id data = modelData[requestModel.responseResultClassString];
                if (data != nil && data != [NSNull null]) {
                    responseModel = [responseModel initWithData:data];
                }
                modelData = responseModel;
            }
        }
    }
    
    if (![self checkTaskIsValid:task]) {
        return;
    }
    
    [self.tasks removeObjectForKey:INT_TO_STRING(task.taskIdentifier)];
    [allTasks removeObjectForKey:INT_TO_STRING(task.taskIdentifier)];
    
    if (block) {
        dispatch_async(self.responseQueue, ^{
            block(error, modelData);
        });
    }
}

- (BOOL)checkTaskIsValid:(NSURLSessionTask *)task {
    BOOL valid = task.state != NSURLSessionTaskStateCanceling && task.state != NSURLSessionTaskStateSuspended;
    if (valid) {
        id obj = [self.tasks objectForKey:INT_TO_STRING(task.taskIdentifier)];
        return obj != nil;
    } else {
        return valid;
    }
}

- (NSError *)makeErrorWithError:(NSError *)error httpResponseCode:(NSInteger)httpResponseCode result:(NSDictionary *)data {
    NSDictionary *userInfo = error.userInfo;
    NSInteger errorCode = error.code;
    if (errorCode == 0 && [data isKindOfClass:[NSDictionary class]]) {
        errorCode = DKHTTPSUCESS_CODE;
        NSNumber *codeNum = data[@"code"];
        NSInteger code;
        if (codeNum == nil) {
            code = DKHTTPERROR_CODE;
        } else {
            code = [data[@"code"] integerValue];
        }
        
        if (code != DKHTTPSUCESS_CODE) {
            errorCode = code;
        }
        NSString *errorMessage = data[@"msg"];
        if (![errorMessage isKindOfClass:[NSString class]]) {
            errorMessage = nil;
        }
        if (errorMessage) {
            userInfo = @{ NSLocalizedDescriptionKey : errorMessage };
        } else {
            static NSDictionary *unknownErrorDict;
            static dispatch_once_t onceToken;
            dispatch_once(&onceToken, ^{
                unknownErrorDict = @{ NSLocalizedDescriptionKey : @"未知错误" };
            });
            
            userInfo = unknownErrorDict;
        }
    }
    
    if (errorCode == DKHTTPSUCESS_CODE) {
        return nil;
    } else {
        static NSString *bundleName;
        static dispatch_once_t onceToken;
        dispatch_once(&onceToken, ^{
            bundleName = [[[NSBundle mainBundle] infoDictionary] objectForKey:(NSString*)kCFBundleNameKey];
        });
        
        return [NSError errorWithDomain:bundleName code:errorCode userInfo:userInfo];
    }
}

- (NSMutableDictionary<NSString *, NSURLSessionTask *> *)tasks {
    if (_tasks == nil) {
        _tasks = [NSMutableDictionary new];
    }
    return _tasks;
}

@end
