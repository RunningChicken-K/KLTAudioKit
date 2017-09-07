//
//  QSAudioCache.m
//  AllLife
//
//  Created by CZ10000 on 2017/9/4.
//  Copyright © 2017年 CZ10000. All rights reserved.
//

#import "QSAudioCache.h"
#import "QSAudioUtil.h"
#import <CommonCrypto/CommonDigest.h>
static QSAudioCache * audio = nil;

/**
 添加同步任务到主线程
 */
#define dispatch_main_sync_safe(block)\
if ([NSThread isMainThread]) {\
block();\
} else {\
dispatch_sync(dispatch_get_main_queue(), block);\
}


@interface QSAudioCache ()
{
    @public
    NSString * defaultPath;
    NSCache * memCache;
    
}

@property(nonatomic,strong)QSAudioUtil * audioUtil;

@end


@implementation QSAudioCache


+ (instancetype)shareAudioCache
{
    // 添加同步锁，一次只能一个线程访问。如果有多个线程访问，等待。一个访问结束后下一个。
    @synchronized(self){
        if (nil == audio) {
            audio = [[QSAudioCache alloc]init];
        }
    }
    return audio;
}
- (instancetype)init
{
    if (self = [super init]) {
        NSString * directoryPath = [[NSSearchPathForDirectoriesInDomains(NSCachesDirectory, NSUserDomainMask, YES) lastObject] stringByAppendingString:@"/QSAudioCache"];
        NSFileManager * fileManager = [NSFileManager defaultManager];
        
        if (![fileManager fileExistsAtPath:directoryPath]) {
            NSError * error;
            [fileManager createDirectoryAtPath:directoryPath withIntermediateDirectories:YES attributes:nil error:&error];
            if (error) {
                NSLog(@"创建Audio文件夹失败 %@",error);
            }
        }
        
        defaultPath = directoryPath;
        memCache = [[NSCache alloc]init];
        memCache.name = @"com.konglt.audioCache";
        _audioUtil = [[QSAudioUtil alloc]init];
    
    }
    return self;
    
}

+ (void)playAudioWithUrl:(NSString *)url
{
    
    QSAudioCache * audioCache = [QSAudioCache shareAudioCache];
    
    [audioCache playAudioWithUrl:url];
}

+ (NSUInteger)totalCaceheSize
{
    QSAudioCache * audioCache = [QSAudioCache shareAudioCache];
    
    NSString * defaultPath = audioCache->defaultPath;
    
    NSFileManager * fileManager = [NSFileManager defaultManager];
    NSError * error;
    NSArray * filePathArray =  [fileManager contentsOfDirectoryAtPath:defaultPath error:&error];
    
    NSUInteger totalSize = 0;
    if (filePathArray) {
        
        for (NSString * filePath in filePathArray) {
           totalSize += [[fileManager attributesOfItemAtPath:filePath error:nil] fileSize];
        }
        
    }
    else
    {
        NSLog(@"加载音频缓存文件失败:\n%@",error);
        
    }
    return totalSize;

    
}


- (void)playAudioWithUrl:(NSString *)url
{
   [self audioWithUrl:url WithCallBack:^(NSData *data) {
      
       [self.audioUtil playLocalAudioWithData:data];
       
   }];
}


- (void)audioWithUrl:(NSString *)url WithCallBack:(void (^)(NSData * data))callBack
{
    NSString * keyPath = [self storagePathWithUrl:url];
    
    //先从内从中查找  如果有  直接返回
    NSData * audio = [memCache objectForKey:keyPath];
    if (audio) {
        callBack(audio);
        return;
    }
    
    //查找磁盘  如果有直接返回
    NSLog(@"keyPath is %@",keyPath);
    NSFileManager * fileManager = [NSFileManager defaultManager];
    if ([fileManager fileExistsAtPath:keyPath]) {
        callBack([NSData dataWithContentsOfFile:keyPath]);
    }
    else
    {
        //内存和磁盘都没有 则去下载
        [self downLoadAudioWithUrl:url WithCompletion:^(NSData *data, NSError *error) {
           
            if (!error) {
                //存储到本地
                [self setObject:data WithUrl:url];
                callBack(data);
            }
            else
            {
                NSLog(@"加载语音出错\n%@",error);
            }
        }];
        
    }
    
    
}

- (void)downLoadAudioWithUrl:(NSString *)url WithCompletion:(void (^)(NSData * data,NSError * error))completion
{
    NSURLSession  * session = [NSURLSession sharedSession];
    NSURLRequest * request = [NSURLRequest requestWithURL:[NSURL URLWithString:url]];
    
    NSURLSessionTask * task = [session dataTaskWithRequest:request completionHandler:^(NSData * _Nullable data, NSURLResponse * _Nullable response, NSError * _Nullable error) {
        

        if (completion) {
            completion(data,error);
        }
        
        
    }];
    [task resume];
    
}

- (void)setObject:(NSData *)data WithUrl:(NSString *)url
{
    NSString * path = [self storagePathWithUrl:url];
    NSFileManager * fileManager = [NSFileManager defaultManager];
    
    if (![fileManager fileExistsAtPath:path]) {
        [fileManager createFileAtPath:path contents:nil attributes:nil];
    }
    
    [self writeAudioInToMemeory:data Key:path];
    NSError * writeError;
    BOOL success =  [data writeToFile:path options:NSDataWritingAtomic error:&writeError];
    if (success) {
        if (DEBUG) {
            NSLog(@"写入文件成功 %@ path is %@",writeError,path);
        }
        
    }
    else
    {
        NSLog(@"写入文件失败 %@",writeError);
    }
}
- (void)writeAudioInToMemeory:(NSData *)audio Key:(NSString *)key
{
    [memCache setObject:audio forKey:key];
}

- (NSString *)storagePathWithUrl:(NSString *)url
{
    return [NSString stringWithFormat:@"%@/%@.aac",defaultPath,[self md5:url]];
}

/**
 md5 32位 加密 （小写）
 */

- (NSString *)md5:(NSString *)str
{
    const char *cStr = [str UTF8String];
    
    unsigned char result[32];
    
    CC_MD5( cStr, (CC_LONG)strlen(cStr), result );
    
    return [NSString stringWithFormat:@"%02x%02x%02x%02x%02x%02x%02x%02x%02x%02x%02x%02x%02x%02x%02x%02x",
            result[0],result[1],result[2],result[3],
            
            result[4],result[5],result[6],result[7],
            
            result[8],result[9],result[10],result[11],
            
            result[12],result[13],result[14],result[15]];
}

@end











