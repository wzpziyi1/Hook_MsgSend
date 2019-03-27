//
//  ZYMethodRecordModel.h
//  HookObjc_MsgSend
//
//  Created by wzp on 2019/3/27.
//  Copyright © 2019 wzp. All rights reserved.
//

#import <Foundation/Foundation.h>


@interface ZYMethodRecordModel : NSObject
@property (nonatomic, copy) NSString *className;
@property (nonatomic, copy) NSString *methodName;
@property (nonatomic, assign) BOOL isClassMethod;       //是否类方法
@property (nonatomic, assign) NSUInteger callDepth;     //层级
@property (nonatomic, assign) NSUInteger timeCost;      //耗时

@property (nonatomic, strong) NSMutableArray<ZYMethodRecordModel *> *subRecordModelArr;
@end
