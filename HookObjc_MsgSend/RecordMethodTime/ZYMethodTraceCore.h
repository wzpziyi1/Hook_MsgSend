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
    id obj;
    SEL cmd;
    uint32_t time;
    uint32_t index;
}CallRecord;

void startMethodTrace();
void stopMethodTrace();
void setMaxDepth(int depth);
void setRecordMinInterval(int interval);   //interval毫秒
#endif
