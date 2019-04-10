//
//  ZYMethodStackStore.h
//  HookObjc_MsgSend
//
//  Created by wzp on 2019/4/8.
//  Copyright © 2019 wzp. All rights reserved.
//

#ifndef ZYMethodStackStore_h
#define ZYMethodStackStore_h

#include <stdio.h>
#include<sys/types.h>
#include<sys/stat.h>
#include<fcntl.h>
#include<unistd.h>
#include<sys/mman.h>
#include <sys/errno.h>
#include <string.h>
#import <mach/mach_time.h>
#import <Foundation/Foundation.h>

#ifdef __cplusplus
extern "C" {
#endif

/**
 映射文件到内存
 */
int MapFile(int fd , void ** outDataPtr, size_t mapSize, struct stat * stat);

/**
 执行文件
 */
int ProcessFile(char * inPathName, char * string);
    
#ifdef __cplusplus
}
#endif

#endif /* ZYMethodStackStore_h */
