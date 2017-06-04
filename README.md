## BaseModel

#### DKRequsetModel

请求类型
`- (DKHTTPMethod)HTTPMethod`

返回对应模型Class
`- (Class)responseModelClass`

返回字典里面的数据字段Key
`- (NSString *)responseResultClassString`

是否请求已带Json参数, 如果是, 则忽略requestModel里的请求属性
`- (NSString *)queryString`

短地址，要和baseUrl拼接(无添加)
`- (NSString *)url`

主地址
`- (NSString *)baseUrl`

转字典时要忽略的属性
`- (void)addIgnoredObjects:(NSArray *)objects`

是否使用KeyMap
`- (BOOL)enableKeyMapManager`

#### DKResponseModel

添加映射
`- (void)addManualMappingDict:(NSDictionary *)dict`


### DKKeyMapManager 默认形态

#### 编码时(模型转字典)

在原来大写字母前加@"_",并且全部转换为小写字母
`+ (NSString *)encodeKey:(NSString *)originalKey`

#### 解码时(字典转模型)

去除@"_",首字母小写，其他单词首字母大写
 `+ (NSString *)decodeKey:(NSString *)originalKey`

参考文献：

[iOS网络框架－AFNetworking3.1.0源码解读](http://www.jianshu.com/p/c36159094e24)

[POST请求的forHTTPHeaderField](http://www.cnblogs.com/YouXianMing/p/3784313.html)

[AFNetworking POST 请求参数保存在Body 中的解决办法](http://www.cnblogs.com/allen2015/p/4724931.html)

[开发只懂 AFN ？搞定 NSURLSession 才是硬道理](http://www.cocoachina.com/ios/20161018/17785.html)

[iOS - AFNetworking 网络请求](http://www.cnblogs.com/QianChia/p/5768428.html)

