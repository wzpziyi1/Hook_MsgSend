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
#import "ZYMethodStackStore.h"
#import <objc/runtime.h>

static NSString * const kLogPath = [[NSSearchPathForDirectoriesInDomains(NSCachesDirectory, NSUserDomainMask, YES) firstObject] stringByAppendingPathComponent:@"method_record_log.txt"];

@interface ZYMethodRecordManager()
{
    NSUInteger _minCost;
    NSUInteger _maxDepth;
}
@end

@implementation ZYMethodRecordManager

+ (void)load {
    [[ZYMethodRecordManager sharedManager] startRecord:5 minTimeCost:1];
}

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
    dispatch_async_safe_main(^{
        setMaxDepth((uint32_t)self->_maxDepth);
        setRecordMinInterval((uint32_t)self->_minCost);
        startMethodTrace();
    });
}

- (void)startRecord:(NSUInteger)maxDepth minTimeCost:(NSUInteger)cost {
    _maxDepth = maxDepth;
    _minCost = cost;
    [self startRecord];
}

- (void)stop {
    dispatch_async_safe_main(^{
        stopMethodTrace();
    });
}

- (void)save {
    dispatch_async_safe_main(^{
        if (![[NSFileManager defaultManager] fileExistsAtPath:kLogPath]) {
            [[NSFileManager defaultManager] createFileAtPath:kLogPath contents:nil attributes:nil];
        }
        uint32_t depth = 0;
        CallRecord *logHeader = getLogRootInfo(&depth);
        if (logHeader == NULL) {
            return;
        }
        ZYMethodRecordModel *model = [[ZYMethodRecordModel alloc] init];
        for (int i = depth - 1; i >= 0; i--) {
            @autoreleasepool {
                CallRecord *record = &logHeader[i];
                model.className = NSStringFromClass(record->cls);
                model.methodName = NSStringFromSelector(record->cmd);
                model.isClassMethod = class_isMetaClass(record->cls);
                model.callDepth = (NSUInteger)record->index;
                model.timeCost = (NSUInteger)record->time;
                ProcessFile([kLogPath UTF8String], [[model descInfo] UTF8String]);
//                NSLog(@"------------------------------------------------------------");
//                NSLog(@"%@", [model descInfo]);
            }
        }
    });
}

- (void)stopRecordAndClean {
    dispatch_async_safe_main(^{
        stopRecordAndCleanLogMemory();
    });
}


static inline void dispatch_async_safe_main(void(^block)(void)) {
    assert(block != nil);
    if ([NSThread isMainThread]) {
        block();
    }
    else {
        dispatch_async(dispatch_get_main_queue(), block);
    }
}
@end
