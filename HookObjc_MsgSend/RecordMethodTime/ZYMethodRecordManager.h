//
//  ZYMethodRecordManager.h
//  HookObjc_MsgSend
//
//  Created by wzp on 2019/3/27.
//  Copyright © 2019 wzp. All rights reserved.
//

#import <Foundation/Foundation.h>

@interface ZYMethodRecordManager : NSObject
+ (instancetype)sharedManager;

- (void)startRecord;
/**
 @param maxDepth 最深的方法层级
 @param cost 最少的耗时ms
 */
- (void)startRecord:(NSUInteger)maxDepth minTimeCost:(NSUInteger)cost;

- (void)stop;

- (void)save;

- (void)stopSaveAndClean;
@end
