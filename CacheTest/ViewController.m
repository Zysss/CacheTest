//
//  ViewController.m
//  CacheTest
//
//  Created by zhangyansong on 16/8/25.
//  Copyright © 2016年 Svyanto. All rights reserved.
//

#import "ViewController.h"
#import "AFNetworking.h"

@interface ViewController ()

@property (nonatomic,strong) AFURLSessionManager *manager;

@property (nonatomic,strong) NSURLSessionDownloadTask *currentTask;

@property (nonatomic,strong) NSString *eTag;

@property (nonatomic,strong) NSString *lastModified;

@property (nonatomic,strong) UITextField *textField;

@end

static NSString *urlString = @"http://ob7wz948u.bkt.clouddn.com/2016-08-12.markdown?attname=";

@implementation ViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    // Do any additional setup after loading the view, typically from a nib.
    UIButton *button = [ UIButton buttonWithType:UIButtonTypeCustom];
    button.frame = CGRectMake(100, 100, 150, 150);
    button.backgroundColor = [ UIColor redColor];
    [button addTarget:self action:@selector(testETag) forControlEvents:UIControlEventTouchUpInside];
    [self.view addSubview:button];
    
    self.textField = [[ UITextField alloc] initWithFrame:CGRectMake(50, 50, 50, 20)];
    [self.view addSubview:_textField];
    
    UIButton *button1 = [ UIButton buttonWithType:UIButtonTypeCustom];
    button1.frame = CGRectMake(100, 250, 150, 150);
    button1.backgroundColor = [ UIColor blueColor];
    [button1 addTarget:self action:@selector(testETag) forControlEvents:UIControlEventTouchUpInside];
    [self.view addSubview:button1];
}

- (void)testETag{
    NSFileManager *file = [ NSFileManager defaultManager];
    [file removeItemAtURL:[self dataPath] error:nil];
    if (!self.manager) {
        NSURLSessionConfiguration *config = [NSURLSessionConfiguration defaultSessionConfiguration];
        self.manager = [[ AFURLSessionManager alloc] initWithSessionConfiguration:config];
    }
    
    if (_currentTask) {
        [_currentTask cancel];
    }
    NSMutableURLRequest *request = [NSMutableURLRequest requestWithURL:[NSURL URLWithString:urlString ]];
    if (!self.eTag) {
        self.eTag = [NSKeyedUnarchiver unarchiveObjectWithFile:[self eTagPath]];
    }
    if (self.eTag.length > 0) {
        [request setValue:self.eTag forHTTPHeaderField:@"If-None-Match"];
    }
    
    NSURLSessionDownloadTask *task = [_manager downloadTaskWithRequest:request progress:nil destination:^NSURL * _Nonnull(NSURL * _Nonnull targetPath, NSURLResponse * _Nonnull response) {
        NSHTTPURLResponse *httpResponse = (NSHTTPURLResponse *)response;
        NSLog(@"statusCode == %@", @(httpResponse.statusCode));
        // 判断响应的状态码是否是 304 Not Modified （更多状态码含义解释： https://github.com/ChenYilong/iOSDevelopmentTips）
        if (httpResponse.statusCode == 304) {
            // 根据请求获取到`被缓存的响应`！
            return nil;
        } else {
            self.eTag = httpResponse.allHeaderFields[@"Etag"];
            self.lastModified = httpResponse.allHeaderFields[@"Last-Modified"];
            [NSKeyedArchiver archiveRootObject:self.eTag toFile:[self eTagPath]];
        }
        return [self dataPath];
    } completionHandler:^(NSURLResponse * _Nonnull response, NSURL * _Nullable filePath, NSError * _Nullable error) {
        NSHTTPURLResponse *httpResponse = (NSHTTPURLResponse *)response;
        if (httpResponse.statusCode == 304) {
            return ;
        }
        NSData *data = [ NSData dataWithContentsOfURL:filePath];
        NSLog(@"%@",[[NSString alloc] initWithData:data encoding:NSUTF8StringEncoding]);
    }];
    
    
    [task resume];
    self.currentTask = task;
}
- (NSURL *) dataPath{
    NSString *document = [NSSearchPathForDirectoriesInDomains(NSCachesDirectory, NSUserDomainMask, YES) lastObject];
    return [NSURL fileURLWithPath:[NSString stringWithFormat:@"%@/markdown.txt",document]];
}

- (NSString *) eTagPath{
    NSString *document = [NSSearchPathForDirectoriesInDomains(NSCachesDirectory, NSUserDomainMask, YES) lastObject];
    return [document stringByAppendingPathComponent:@"eTagPath"];
}

- (NSString *)lastModifiedPath{
    NSString *document = [NSSearchPathForDirectoriesInDomains(NSCachesDirectory, NSUserDomainMask, YES) lastObject];
    return [document stringByAppendingPathComponent:@"lastModifiedPath"];
}
- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

@end
