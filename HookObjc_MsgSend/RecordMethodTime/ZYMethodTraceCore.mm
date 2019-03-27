//
//  ZYMethodTraceCore.m
//  HookObjc_MsgSend
//
//  Created by wzp on 2019/3/26.
//  Copyright © 2019 wzp. All rights reserved.
//

#import "ZYMethodTraceCore.h"

#ifdef __aarch64__

#import "fishhook.h"
#include <dispatch/dispatch.h>
#include <pthread.h>
#include <sys/time.h>


static CallRecord *_recordRoot = NULL;
static CallRecord *_logRoot = NULL;

static bool _isRecording = false;
static uint32_t _minTimeCost = 0;
static uint32_t _maxCallDepth = 5;

static uint32_t _curRecordCount = 0;
static uint32_t _curLogCount = 0;
static uint32_t _recordAllocCount = 100;
static uint32_t _logAllocCount = 100;

__unused static id(*origin_objc_msgSend)(id obj, SEL cmd, ...);


inline uint32_t get_current_time() {
    struct timeval now;
    gettimeofday(&now, NULL);
    //转成us，取最后100秒的余数
    return (now.tv_sec % 100) * 1000000 + now.tv_usec;
}

void push_call_record(id obj, SEL cmd) {
    if (_recordRoot == NULL) {
        _recordRoot = (CallRecord *)malloc(sizeof(CallRecord) * _recordAllocCount);
    }
    else if (_curRecordCount >= _recordAllocCount) {
        _recordAllocCount += 100;
        _recordRoot = (CallRecord *)realloc((void *)_recordRoot, _recordAllocCount * sizeof(CallRecord));
    }
    CallRecord *curNode = &_recordRoot[_curRecordCount];
    curNode->obj = obj;
    curNode->cmd = cmd;
    curNode->index = _curRecordCount++;
    curNode->time = get_current_time();
}

void pop_call_record() {
    if (_curRecordCount == 0) {
        return;
    }
    _curRecordCount--;
    CallRecord *preNode = (CallRecord *)&_recordRoot[_curRecordCount];
    if (_isRecording && preNode->index <= _maxCallDepth) {
        uint32_t nowUsec = get_current_time();
        if (nowUsec < preNode->time) {
            nowUsec += 100 * 1000000;
        }
        //转成毫秒
        preNode->time = (nowUsec - preNode->time) / 1000;
        if (preNode->time < _minTimeCost) {
            return;
        }
        if (_logRoot == NULL) {
            _logRoot = (CallRecord *)malloc(sizeof(CallRecord) * _logAllocCount);
        }
        else if (_logAllocCount <= _curLogCount) {
            _logAllocCount += 100;
            _logRoot = (CallRecord *)realloc(_logRoot, _logAllocCount * sizeof(CallRecord));
        }
        CallRecord *logNode = (CallRecord *)&_logRoot[_curLogCount++];
        logNode->obj = preNode->obj;
        logNode->cmd = preNode->cmd;
        logNode->index = preNode->index;
        logNode->time = preNode->time;
    }
}

void *before_hook_objc_msgSend(id obj, SEL cmd) {
    //只记录主线程的方法调用信息
    if (pthread_main_np()) {
        push_call_record(obj, cmd);
    }
    //返回真正的objc_msgSend地址值
    return (void *)origin_objc_msgSend;
}

void after_hook_objc_msgSend(id obj, SEL cmd) {
    if (pthread_main_np()) {
        
    }
}

__attribute__((naked))
id hook_objc_msgSend(id self, SEL op) {
    __asm__ __volatile__ (
                          //保护fp\lr寄存器，开辟栈空间给函数
                          "stp fp, lr, [sp, #-16]!;\n"
                          "mov fp, sp;\n"
                          
                          //保护传递的参数，其中x8是syscall用到的
                          //后面用到了x12寄存器，也保存下
                          "sub    sp, sp, #(10*8 + 8*16);\n"
                          "stp    q0, q1, [sp, #(0*16)];\n"
                          "stp    q2, q3, [sp, #(2*16)];\n"
                          "stp    q4, q5, [sp, #(4*16)];\n"
                          "stp    q6, q7, [sp, #(6*16)];\n"
                          "stp    x0, x1, [sp, #(8*16+0*8)];\n"
                          "stp    x2, x3, [sp, #(8*16+2*8)];\n"
                          "stp    x4, x5, [sp, #(8*16+4*8)];\n"
                          "stp    x6, x7, [sp, #(8*16+6*8)];\n"
                          "stp    x8, x12, [sp, #(8*16+8*8)];\n"
                          );
    
    __asm__ __volatile__ (
                          //调用自己写的函数，注意c函数before_hook_objc_msgSend
                          //before_hook_objc_msgSend函数里面返回真正的objc_msgSend函数地址
                          "mov x12, %0\n" :: "r"(&before_hook_objc_msgSend)
                          );

    __asm__ __volatile__ (
                          //跳转到x12地址开始执行
                          "BLR x12;\n"
                          //将objc_msgSend地址存入x9寄存器
                          "mov x9, x0;\n"
                          // 恢复真正要调用objc_msgSend的现场
                          "ldp    q0, q1, [sp, #(0*16)];\n"
                          "ldp    q2, q3, [sp, #(2*16)];\n"
                          "ldp    q4, q5, [sp, #(4*16)];\n"
                          "ldp    q6, q7, [sp, #(6*16)];\n"
                          "ldp    x0, x1, [sp, #(8*16+0*8)];\n"
                          "ldp    x2, x3, [sp, #(8*16+2*8)];\n"
                          "ldp    x4, x5, [sp, #(8*16+4*8)];\n"
                          "ldp    x6, x7, [sp, #(8*16+6*8)];\n"
                          "ldp    x8, x12, [sp, #(8*16+8*8)];\n"
                          
                          //调用真正的objc_msgSend
                          "BLR x9;\n"
                          
                          //保护调用完objc_msgSend后的现场
                          //主要保护参数、返回值
                          "stp    q0, q1, [sp, #(0*16)];\n"
                          "stp    q2, q3, [sp, #(2*16)];\n"
                          "stp    q4, q5, [sp, #(4*16)];\n"
                          "stp    q6, q7, [sp, #(6*16)];\n"
                          "stp    x0, x1, [sp, #(8*16+0*8)];\n"
                          "stp    x2, x3, [sp, #(8*16+2*8)];\n"
                          "stp    x4, x5, [sp, #(8*16+4*8)];\n"
                          "stp    x6, x7, [sp, #(8*16+6*8)];\n"
                          "stp    x8, x12, [sp, #(8*16+8*8)];\n"
                          );
    
    
    __asm__ __volatile__ (
                          "mov x12, %0\n" :: "r"(&after_hook_objc_msgSend)
                          );
    
    __asm__ __volatile__ (
                          //调用after_hook_objc_msgSend函数
                          "BLR x12;\n"
                          
                          // 恢复调用after_hook_objc_msgSend之前的现场
                          "ldp    q0, q1, [sp, #(0*16)];\n"
                          "ldp    q2, q3, [sp, #(2*16)];\n"
                          "ldp    q4, q5, [sp, #(4*16)];\n"
                          "ldp    q6, q7, [sp, #(6*16)];\n"
                          "ldp    x0, x1, [sp, #(8*16+0*8)];\n"
                          "ldp    x2, x3, [sp, #(8*16+2*8)];\n"
                          "ldp    x4, x5, [sp, #(8*16+4*8)];\n"
                          "ldp    x6, x7, [sp, #(8*16+6*8)];\n"
                          "ldp    x8, x12, [sp, #(8*16+8*8)];\n"
                          
                          //恢复sp\fp\lr，跳转回lr的地址继续执行
                          "mov    sp, fp;\n"
                          "ldp    fp, lr, [sp], #16;\n"
                          "ret;\n"
                          );
}

#pragma mark - public function

void startMethodTrace() {
    _isRecording = true;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        struct rebinding rebind[5];
        rebind[0] = (struct rebinding){"objc_msgSend", (void *)hook_objc_msgSend, (void **)&origin_objc_msgSend};
        rebind_symbols(rebind, 1);
    });
}

void setMaxDepth(int depth) {
    _maxCallDepth = (depth <= 0) ? 0 : depth;
}
void setRecordMinInterval(int interval) {
    _minTimeCost = (interval * 1000 < 0) ? 0 : interval * 1000;
}

#else
void startMethodTrace() {}
void stopMethodTrace() {}
void setMaxDepth(int depth) {}
void setRecordMinInterval(int interval){}
#endif
