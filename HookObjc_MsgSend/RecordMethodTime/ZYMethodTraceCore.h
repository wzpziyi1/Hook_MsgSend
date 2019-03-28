//
//  ZYMethodTraceCore.h
//  HookObjc_MsgSend
//
//  Created by wzp on 2019/3/26.
//  Copyright © 2019 wzp. All rights reserved.
//

#ifndef ZYMethodTraceCore_H
#define ZYMethodTraceCore_H

#include <iostream>
#include <objc/objc.h>
using namespace std;

typedef struct {
    Class cls;
    SEL cmd;
    uint32_t time;
    uint32_t index;
}CallRecord;

void startMethodTrace();
void stopMethodTrace();
void setMaxDepth(uint32_t depth);
void setRecordMinInterval(uint32_t interval);   //毫秒

CallRecord *getLogRootInfo(uint32_t *depth);
void stopRecordAndCleanLogMemory();
#endif
