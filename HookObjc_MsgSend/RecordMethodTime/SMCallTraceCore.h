//
//  SMCallTraceCore.h
//  DecoupleDemo
//
//  Created by DaiMing on 2017/7/16.
//  Copyright © 2017年 Starming. All rights reserved.
//

#ifndef SMCallTraceCore_h
#define SMCallTraceCore_h

#include <stdio.h>
#include <objc/objc.h>

typedef struct {
    __unsafe_unretained Class cls;
    SEL sel;
    uint64_t time; // us (1/1000 ms)
    int depth;
} smCallRecord;

void smCallTraceStart();
void smCallTraceStop();

void smCallConfigMinTime(uint64_t us); //default 1000
void smCallConfigMaxDepth(int depth);  //default 3

smCallRecord *smGetCallRecords(int *num);
void smClearCallRecords();



#endif /* SMCallTraceCore_h */
