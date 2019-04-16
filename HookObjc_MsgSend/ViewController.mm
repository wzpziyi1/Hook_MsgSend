//
//  ViewController.m
//  HookObjc_MsgSend
//
//  Created by wzp on 2019/3/26.
//  Copyright © 2019 wzp. All rights reserved.
//

#import "ViewController.h"
#import <objc/objc.h>
#import "ZYMethodRecordManager.h"
#import "ZYMethodStackStore.h"

@interface ViewController ()

@end

@implementation ViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    // Do any additional setup after loading the view, typically from a nib.
//    NSString *path = [[NSSearchPathForDirectoriesInDomains(NSCachesDirectory, NSUserDomainMask, YES) lastObject] stringByAppendingPathComponent:@"111.txt"];
//    ProcessFile([path UTF8String], "11111111");
    [self test];
}

- (void)viewDidAppear:(BOOL)animated {
    [super viewDidAppear:animated];
    [[ZYMethodRecordManager sharedManager] save];
    [[ZYMethodRecordManager sharedManager] stop];
}

- (void)test {
    for (int i = 0; i <= 3000000; i++) {
        @autoreleasepool {
            NSString *tmp = [[NSString alloc] init];
            tmp = @"111111";
        }
    }
    [self dosomething];
}

- (void)dosomething {
    for (int i = 0; i <= 3000000; i++) {
        @autoreleasepool {
            NSString *tmp = [[NSString alloc] init];
            tmp = @"111111";
        }
    }
}

@end
