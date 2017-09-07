//
//  KLTAudioUtil.h
//  Test
//
//  Created by CZ10000 on 2017/8/29.
//  Copyright © 2017年 CZ10000. All rights reserved.
//

#import <Foundation/Foundation.h>


@protocol KLTAudioUtilDelegate <NSObject>



@end

@interface KLTAudioUtil : NSObject


@property(nonatomic,weak)id<KLTAudioUtilDelegate> delegate;

/**
 开始录制
 */
- (void)startRecord;


/**
 停止录制并保存录音

 @param callBack 录音保存结束后的回调
 */
- (void)stopAndSaveWithCallBack:(void (^)(NSData * data,NSInteger duration))callBack;



/**
 播放本地音频

 @param data 本地音频数据
 */
- (void)playLocalAudioWithData:(NSData *)data;


/**
 播放网络音频资源

 @param Url 音频资源Url
 */
- (void)playOnlineAudioWithUrl:(NSString *)Url;

@end
