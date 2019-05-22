//
//  ZYMethodTraceCore.cpp
//  HookObjc_MsgSend
//
//  Created by wzp on 2019/3/28.
//  Copyright © 2019 wzp. All rights reserved.
//

#include "ZYMethodTraceCore.hpp"
#ifdef __aarch64__
#import "fishhook.h"
#include <dispatch/dispatch.h>
#include <pthread.h>
#include <sys/time.h>
#import <objc/runtime.h>


typedef struct {
    uintptr_t *lr;
    uint32_t index;
    uint32_t lrAllocCount;
}lr_ptr_record;

static CallRecord *_recordRoot = NULL;
static CallRecord *_logRoot = NULL;

static pthread_key_t _pthread_key;

static bool _isRecording = false;
static uint32_t _minTimeCost = 0;
static uint32_t _maxCallDepth = 5;

static uint32_t _curRecordCount = 0;
static uint32_t _curLogCount = 0;
static uint32_t _recordAllocCount = 100;
static uint32_t _logAllocCount = 100;

__unused static id(*origin_objc_msgSend)(id obj, SEL cmd, ...);


static void release_lr_ptr_record(void *ptr) {
    lr_ptr_record *lrRecord = (lr_ptr_record *)ptr;
    if (!lrRecord) return;
    if (lrRecord->lr) free(lrRecord->lr);
    free(lrRecord);
}

static inline lr_ptr_record *get_lr_ptr_record() {
    lr_ptr_record *lrRecord = (lr_ptr_record *)pthread_getspecific(_pthread_key);
    if (lrRecord == NULL) {
        lrRecord = (lr_ptr_record *)malloc(sizeof(lr_ptr_record));
        lrRecord->lrAllocCount = 100;
        lrRecord->index = 0;
        lrRecord->lr = (uintptr_t *)calloc(lrRecord->lrAllocCount, sizeof(uintptr_t));
        pthread_setspecific(_pthread_key, lrRecord);
    }
    return lrRecord;
}

static inline uint32_t get_current_time() {
    struct timeval now;
    gettimeofday(&now, NULL);
    //转成us，取最后100秒的余数
    return (now.tv_sec % 100) * 1000000 + now.tv_usec;
}

static inline void push_call_record(id obj, SEL cmd, uintptr_t lr) {
    if (pthread_main_np()) {
        if (_recordRoot == NULL) {
            _recordAllocCount = 100;
            _curRecordCount = 0;
            _recordRoot = (CallRecord *)malloc(sizeof(CallRecord) * _recordAllocCount);
        }
        else if (_curRecordCount >= _recordAllocCount) {
            _recordAllocCount += 100;
            _recordRoot = (CallRecord *)realloc((void *)_recordRoot, _recordAllocCount * sizeof(CallRecord));
        }
        CallRecord *curNode = &_recordRoot[_curRecordCount];
        curNode->cls = object_getClass(obj);
        curNode->cmd = cmd;
        curNode->index = _curRecordCount++;
        curNode->time = get_current_time();
    }
    lr_ptr_record *lrRecord = get_lr_ptr_record();
    if (lrRecord) {
        if (lrRecord->index >= lrRecord->lrAllocCount - 1) {
            lrRecord->lrAllocCount += 100;
            lrRecord->lr = (uintptr_t *)realloc(lrRecord->lr, sizeof(uintptr_t) * lrRecord->lrAllocCount);
        }
        uint32_t index = lrRecord->index;
        lrRecord->index++;
        lrRecord->lr[index] = lr;
    }
}

static inline uintptr_t pop_call_record() {
    if (pthread_main_np() && _curRecordCount != 0) {
        _curRecordCount--;
        CallRecord *preNode = (CallRecord *)&_recordRoot[_curRecordCount];
        if (_isRecording && preNode->index <= _maxCallDepth) {
            uint32_t nowUsec = get_current_time();
            if (nowUsec < preNode->time) {
                nowUsec += 100 * 1000000;
            }
            //转成毫秒
            preNode->time = (nowUsec - preNode->time) / 1000;
            if (preNode->time >= _minTimeCost) {
                if (_logRoot == NULL) {
                    _logAllocCount = 100;
                    _curLogCount = 0;
                    _logRoot = (CallRecord *)malloc(sizeof(CallRecord) * _logAllocCount);
                }
                else if (_logAllocCount <= _curLogCount) {
                    _logAllocCount += 100;
                    _logRoot = (CallRecord *)realloc(_logRoot, _logAllocCount * sizeof(CallRecord));
                }
                CallRecord *logNode = (CallRecord *)&_logRoot[_curLogCount++];
                logNode->cls = preNode->cls;
                logNode->cmd = preNode->cmd;
                logNode->index = preNode->index;
                logNode->time = preNode->time;
            }
        }
    }
    lr_ptr_record *lrRecord = get_lr_ptr_record();
    lrRecord->index--;
    uint32_t index = lrRecord->index;
    return lrRecord->lr[index];
}

void before_hook_objc_msgSend(id obj, SEL cmd, uintptr_t lr) {
    push_call_record(obj, cmd, lr);
}

uintptr_t after_hook_objc_msgSend() {
    return pop_call_record();
}

#define call(b, value) \
__asm volatile ("stp x8, x9, [sp, #-16]!\n"); \
__asm volatile ("mov x12, %0\n" :: "r"(value)); \
__asm volatile ("ldp x8, x9, [sp], #16\n"); \
__asm volatile (#b " x12\n");

#define save() \
__asm volatile ( \
"stp q6, q7, [sp, #-32]!\n" \
"stp q4, q5, [sp, #-32]!\n" \
"stp q2, q3, [sp, #-32]!\n" \
"stp q0, q1, [sp, #-32]!\n" \
"stp x8, x9, [sp, #-16]!\n" \
"stp x6, x7, [sp, #-16]!\n" \
"stp x4, x5, [sp, #-16]!\n" \
"stp x2, x3, [sp, #-16]!\n" \
"stp x0, x1, [sp, #-16]!\n" \
);

#define load() \
__asm volatile ( \
"ldp x0, x1, [sp], #16\n" \
"ldp x2, x3, [sp], #16\n" \
"ldp x4, x5, [sp], #16\n" \
"ldp x6, x7, [sp], #16\n" \
"ldp x8, x9, [sp], #16\n" \
"ldp q0, q1, [sp], #32\n" \
"ldp q2, q3, [sp], #32\n" \
"ldp q4, q5, [sp], #32\n" \
"ldp q6, q7, [sp], #32\n" \
);

#define link(b, value) \
__asm volatile ("stp x8, lr, [sp, #-16]!\n"); \
__asm volatile ("sub sp, sp, #16\n"); \
call(b, value); \
__asm volatile ("add sp, sp, #16\n"); \
__asm volatile ("ldp x8, lr, [sp], #16\n");

#define ret() __asm volatile ("ret\n");

__attribute__((__naked__))
static void hook_objc_msgSend() {
    
    /*
     save主要是保护现场，一些参数信息
     */
    save()
    
    /*
     objc_msgSend(id self, SEL cmd, ...)
     x0为self
     x1为cmd
     lr寄存器存储着函数执行完的返回地址，
     这里是将lr当做参数传递到before_hook_objc_msgSend
     存储起来，等待after_hook_objc_msgSend调用完后，保护好lr的值
     */
    __asm volatile ("mov x2, lr\n");
    __asm volatile ("mov x3, x4\n");
    
    
    // Call our before_objc_msgSend.
    //x0 是self指针
    //x1 是_cmd
    //x2 是lr，hook_objc_msgSend函数的返回地址
    //将这三个值当成参数串如了before_objc_msgSend方法中
    call(blr, &before_hook_objc_msgSend)
    
    /*
     在调用真正的objc_msgSend之前，需要恢复所有初始数据（也就是寄存器的值）
     还有，sp\fp寄存器的值也需要恢复，因为可能参数很多，有的参数保存在栈空间中
     lr这里不需要恢复，但也已经在before_hook_objc_msgSend函数中存储了
     */
    load()
    
    // 调用真正的objc_msgSend
    call(blr, origin_objc_msgSend)
    
    // 保护调用完objc_msgSend的所有值
    save()
    
    //调用after_hook_objc_msgSend
    call(blr, &after_hook_objc_msgSend)
    
    //after_hook_objc_msgSend的返回值是该hook_objc_msgSend函数执行完的返回地址
    //放在x0寄存器中
    __asm volatile ("mov lr, x0\n");
    
    //恢复调用完objc_msgSend的所有值
    load()
    
    // return
    ret()
}

#pragma mark - public function

void startMethodTrace() {
    _isRecording = true;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        pthread_key_create(&_pthread_key, &release_lr_ptr_record);
        struct rebinding rebind[6];
        rebind[0] = (struct rebinding){"objc_msgSend", (void *)hook_objc_msgSend, (void **)&origin_objc_msgSend};
        rebind_symbols(rebind, 1);
    });
}

void stopMethodTrace() {
    _isRecording = false;
}

void setMaxDepth(uint32_t depth) {
    _maxCallDepth = (depth <= 0) ? 0 : depth;
}
void setRecordMinInterval(uint32_t interval) {
    _minTimeCost = interval;
}

CallRecord *getLogRootInfo(uint32_t *depth) {
    *depth = _curLogCount;
    return _logRoot;
}

void stopRecordAndCleanLogMemory() {
    _isRecording = false;
    _curLogCount = 0;
    _curRecordCount = 0;
    _recordAllocCount = 100;
    _logAllocCount = 100;
    
    if (_recordRoot) {
        free(_recordRoot);
        _recordRoot = NULL;
    }
    if (_logRoot) {
        free(_logRoot);
        _logRoot = NULL;
    }
}

#else
void startMethodTrace() {}
void stopMethodTrace() {}
void setMaxDepth(uint32_t depth) {}
void setRecordMinInterval(uint32_t interval){}

CallRecord *getLogRootInfo(uint32_t *depth) {
    *depth = 0;
    return NULL;
}
void stopRecordAndCleanLogMemory() {}
#endif
