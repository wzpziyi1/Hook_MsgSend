//
//  ZYMethodRecordModel.m
//  HookObjc_MsgSend
//
//  Created by wzp on 2019/3/27.
//  Copyright © 2019 wzp. All rights reserved.
//

#import "ZYMethodRecordModel.h"

@implementation ZYMethodRecordModel

- (NSString *)descInfo {
    NSMutableString *info = [NSMutableString string];
    int callDepth = (int)self.callDepth;
    do {
        [info appendString:@"**"];
        callDepth--;
    } while (callDepth >= 0);
    
    if (self.isClassMethod) {
        [info appendString:@"+"];
    }
    else {
        [info appendString:@"-"];
    }
    if (self.className.length && self.methodName.length) {
        [info appendFormat:@"[%@ %@]",self.className, self.methodName];
    }
    
    [info appendFormat:@"  CostTime: %ld ms\n", self.timeCost];
    return info;
}
@end
