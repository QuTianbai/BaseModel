//
//  ViewController.m
//  DKDataDemo
//
//  Created by 曲天白 on 2017/6/4.
//  Copyright © 2017年 曲天白. All rights reserved.
//

#import "ViewController.h"
#import "DKLoginManager.h"

@interface ViewController ()

@end

@implementation ViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    // Do any additional setup after loading the view, typically from a nib.
    [GetLoginManager() asyncFetchUserConfigWithUsername:@"13400640683" password:@"123456" completeBlock:^(DKLoginResponseModel *model, NSError *error) {
        
    }];
}


- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}


@end
