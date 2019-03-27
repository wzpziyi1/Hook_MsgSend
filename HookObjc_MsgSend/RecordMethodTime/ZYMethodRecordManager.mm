//
//  ZYMethodRecordManager.m
//  HookObjc_MsgSend
//
//  Created by wzp on 2019/3/27.
//  Copyright © 2019 wzp. All rights reserved.
//

#import "ZYMethodRecordManager.h"
#import "ZYMethodTraceCore.h"
#import "ZYMethodRecordModel.h"

@implementation ZYMethodRecordManager
+ (instancetype)sharedManager {
    static id _instance = nil;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        _instance = [[self alloc] init];
    });
    return _instance;
}
@end
