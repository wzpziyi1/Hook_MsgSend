//
//  ZYMethodRecordManager.m
//  HookObjc_MsgSend
//
//  Created by wzp on 2019/3/27.
//  Copyright © 2019 wzp. All rights reserved.
//

#import "ZYMethodRecordManager.h"
#import "ZYMethodTraceCore.hpp"
#import "ZYMethodRecordModel.h"
#import <objc/runtime.h>
#import "SMCallTraceCore.h"

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
//    smCallTraceStart();
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
    uint32_t depth = 0;
    CallRecord *logHeader = getLogRootInfo(&depth);
    if (logHeader == NULL) {
        return;
    }
    ZYMethodRecordModel *model = [[ZYMethodRecordModel alloc] init];
    for (int i = depth - 1; i >= 0; i--) {
        CallRecord *record = &logHeader[i];
        model.className = NSStringFromClass(record->cls);
        model.methodName = NSStringFromSelector(record->cmd);
        model.isClassMethod = class_isMetaClass(record->cls);
        model.callDepth = (NSUInteger)record->index;
        model.timeCost = (NSUInteger)record->time;
        NSLog(@"%lu||||%@--%@--%lu", (unsigned long)model.timeCost, model.className, model.methodName, model.callDepth);
    }
}


- (void)stopRecordAndClean {
    stopRecordAndCleanLogMemory();
}
@end
