//
//  KLTAudioCache.h
//  AllLife
//
//  Created by CZ10000 on 2017/9/4.
//  Copyright © 2017年 CZ10000. All rights reserved.
//

#import <Foundation/Foundation.h>

@interface KLTAudioCache : NSObject

+ (instancetype)shareAudioCache;

/**
 播放音频

 @param url 音频的url地址
 */
+ (void)playAudioWithUrl:(NSString *)url;



+ (NSUInteger)totalCaceheSize;


@end
