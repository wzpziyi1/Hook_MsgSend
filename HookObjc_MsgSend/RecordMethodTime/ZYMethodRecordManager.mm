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

@interface ZYMethodRecordManager()
{
    NSUInteger _minCost;
    NSUInteger _maxDepth;
}
@end

@implementation ZYMethodRecordManager
+ (instancetype)sharedManager {
    static id _instance = nil;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        _instance = [[self alloc] init];
    });
    return _instance;
}

- (instancetype)init {
    if (self = [super init]) {
        _minCost = 10;
        _maxDepth = 3;
    }
    return self;
}

- (void)startRecord {
    setMaxDepth((uint32_t)_maxDepth);
    setRecordMinInterval((uint32_t)_minCost);
    startMethodTrace();
}

- (void)startRecord:(NSUInteger)maxDepth minTimeCost:(NSUInteger)cost {
    _maxDepth = maxDepth;
    _minCost = cost;
    [self startRecord];
}

- (void)stop {
    stopMethodTrace();
}

- (void)save {
    
}

@end
