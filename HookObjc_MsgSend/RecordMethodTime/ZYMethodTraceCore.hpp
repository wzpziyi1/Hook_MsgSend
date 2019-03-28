//
//  ZYMethodTraceCore.hpp
//  HookObjc_MsgSend
//
//  Created by wzp on 2019/3/28.
//  Copyright © 2019 wzp. All rights reserved.
//

#ifndef ZYMethodTraceCore_hpp
#define ZYMethodTraceCore_hpp

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
#endif /* ZYMethodTraceCore_hpp */
