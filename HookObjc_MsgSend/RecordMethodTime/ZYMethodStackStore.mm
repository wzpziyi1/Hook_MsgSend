//
//  ZYMethodStackStore.c
//  HookObjc_MsgSend
//
//  Created by wzp on 2019/4/8.
//  Copyright © 2019 wzp. All rights reserved.
//

#include "ZYMethodStackStore.h"
int ProcessFile( char * inPathName , char * string)
{
    size_t originLength;  // 原数据字节数
    size_t dataLength;    // 数据字节数
    void * dataPtr;       //
    void * start;         //
    struct stat statInfo; // 文件状态
    int fd;               // 文件
    int outError;         // 错误信息
    
    // 打开文件
    // Open the file.
    fd = open( inPathName, O_RDWR | O_CREAT, 0 );
    
    if( fd < 0 )
    {
        outError = errno;
        return 1;
    }
    
    // 获取文件状态
    int fsta = fstat( fd, &statInfo );
    if( fsta != 0 )
    {
        outError = errno;
        return 1;
    }
    
    // 需要映射的文件大小
    dataLength = strlen(string);
    originLength = statInfo.st_size;
    size_t mapsize = originLength + dataLength;
    
    
    // 文件映射到内存
    int result = MapFile(fd, &dataPtr, mapsize ,&statInfo);
    
    // 文件映射成功
    if( result == 0 )
    {
        start = dataPtr;
        dataPtr = (void *)((uintptr_t)dataPtr + (uintptr_t)(statInfo.st_size));
        
        memcpy(dataPtr, string, dataLength);
        
    }
    else
    {
        // 映射失败
        NSLog(@"映射文件失败");
    }
    close(fd);
    return 0;
}
// MapFile

// Exit:    fd              代表文件
//          outDataPtr      映射出的文件内容
//          mapSize         映射的size
//          return value    an errno value on error (see sys/errno.h)
//                          or zero for success
//
int MapFile( int fd, void ** outDataPtr, size_t mapSize , struct stat * stat)
{
    int outError;         // 错误信息
    struct stat statInfo; // 文件状态
    
    statInfo = * stat;
    
    // Return safe values on error.
    outError = 0;
    *outDataPtr = NULL;
    
    *outDataPtr = mmap(NULL,
                       mapSize,
                       PROT_READ|PROT_WRITE,
                       MAP_FILE|MAP_SHARED,
                       fd,
                       0);
    
    // * outDataPtr 文本内容
    
    //        NSLog(@"映射出的文本内容：%s", * outDataPtr);
    if( *outDataPtr == MAP_FAILED )
    {
        outError = errno;
    }
    else
    {
        // 调整文件的大小
        ftruncate(fd, mapSize);
        fsync(fd);//刷新文件
    }
    
    return outError;
}
