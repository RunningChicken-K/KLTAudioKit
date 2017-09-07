//
//  KLTAudioUtil.m
//  Test
//
//  Created by CZ10000 on 2017/8/29.
//  Copyright © 2017年 CZ10000. All rights reserved.
//

#import "KLTAudioUtil.h"

@import AVFoundation;
@interface KLTAudioUtil()
{
    AVPlayerItem * _playItem;
}

//录音文件临时保存路径
@property(nonatomic,strong)NSString * recordFilePath;

@property(nonatomic,strong)AVAudioSession * audioSession;
//本地音频播放器
@property(nonatomic,strong)AVAudioPlayer * localPlayer;
//网络播放器
@property(nonatomic,strong)AVPlayer * onlinePlayer;

//录音器
@property(nonatomic,strong)AVAudioRecorder * recorder;

@property(nonatomic,strong)NSTimer * timer;

@property(nonatomic,assign)NSInteger countDown;


@end

@implementation KLTAudioUtil


- (NSString *)recordFilePath
{
    if (_recordFilePath == nil) {
        //AVRecord每次录音时会重写文件 因此只需创建一个文件做临时保存即可
        _recordFilePath = [[NSSearchPathForDirectoriesInDomains(NSDocumentDirectory, NSUserDomainMask, YES) lastObject] stringByAppendingString:@"/RRecord.aac"];
    }
    return _recordFilePath;
}

- (NSTimer *)timer
{
    if (_timer == nil) {
        _timer = [NSTimer timerWithTimeInterval:1 target:self selector:@selector(dealTimer:) userInfo:nil repeats:YES];
        //[_timer setFireDate:[NSDate distantFuture]];
        NSRunLoop *runLoop = [NSRunLoop currentRunLoop];
        [runLoop addTimer:_timer forMode:NSDefaultRunLoopMode];
    }
    return _timer;
}
- (void)dealTimer:(NSTimer *)timer
{
    _countDown ++;
}
- (AVAudioRecorder *)recorder
{
    if (_recorder == nil) {
        
        NSURL * filePath = [NSURL fileURLWithPath:self.recordFilePath];
        
        //设置参数
        /*
         * settings 参数
         1.AVNumberOfChannelsKey 通道数 通常为双声道 值2
         2.AVSampleRateKey 采样率 单位HZ 通常设置成44100 也就是44.1k,采样率必须要设为11025才能使转化成mp3格式后不会失真
         3.AVLinearPCMBitDepthKey 比特率 8 16 24 32
         4.AVEncoderAudioQualityKey 声音质量
         ① AVAudioQualityMin  = 0, 最小的质量
         ② AVAudioQualityLow  = 0x20, 比较低的质量
         ③ AVAudioQualityMedium = 0x40, 中间的质量
         ④ AVAudioQualityHigh  = 0x60,高的质量
         ⑤ AVAudioQualityMax  = 0x7F 最好的质量
         5.AVEncoderBitRateKey 音频编码的比特率 单位Kbps 传输的速率 一般设置128000 也就是128kbps
         
         */
        NSDictionary *recordSetting = @{
                                        //采样率  8000/11025/22050/44100/96000（影响音频的质量）
                                        AVSampleRateKey:[NSNumber numberWithFloat: 11025],
                                        // 音频格式
                                        AVFormatIDKey:[NSNumber numberWithInt: kAudioFormatMPEG4AAC],
                                        //采样位数  8、16、24、32 默认为16
                                        AVLinearPCMBitDepthKey:[NSNumber numberWithInt:8],
                                        // 音频通道数 1 或 2
                                        AVNumberOfChannelsKey:[NSNumber numberWithInt: 1],
                                        //录音质量
                                        AVEncoderAudioQualityKey:[NSNumber numberWithInt:AVAudioQualityMin]
                                        };
        
        NSError * error;
        _recorder = [[AVAudioRecorder alloc] initWithURL:filePath settings:recordSetting error:&error];
        if (!_recorder) {
            NSLog(@"音频格式和文件存储格式不匹配,无法初始化Recorder %@",error);
        }
        ;
        
    }
    return _recorder;
}
- (AVAudioSession *)audioSession
{
    return [AVAudioSession sharedInstance];
}



- (void)startRecord
{
  
    if (self.recorder.isRecording) {
        NSLog(@"正在录音，无法开始新的录音");
        return;
    }
    
    NSLog(@"开始录音");
    [self.timer setFireDate:[NSDate distantPast]];
    _countDown = 0;
    [self.audioSession setCategory:AVAudioSessionCategoryPlayAndRecord error:nil];
    NSError * error;
    if ([self.audioSession setActive:YES error:&error]) {
        NSLog(@"初始化session成功%@",error);
    }
    
    
    self.recorder.meteringEnabled = YES;
    [self.recorder prepareToRecord];
    [self.recorder record];
   // NSLog(@"录音状态 %d",self.recorder.isRecording);
    
    
    

}

- (void)stopAndSaveWithCallBack:(void (^)(NSData * data,NSInteger duration))callBack
{
    //NSAssert(!self.recorder.isRecording, @"当前没有进行录音");
    
    
    if ([self.recorder isRecording]) {
        NSLog(@"停止录音");
        [self.timer setFireDate:[NSDate distantFuture]];
        [self.recorder stop];
    }
    
    
    NSFileManager *manager = [NSFileManager defaultManager];
    
    NSUInteger fileSize = [[manager attributesOfItemAtPath:self.recordFilePath error:nil] fileSize];
    if (fileSize > 0) {
        NSLog(@"录音结果保存成功，文件大小为%.2f",fileSize / 1024.0f);
        NSData * data = [NSData dataWithContentsOfFile:self.recordFilePath];
        
        if (callBack) {
            callBack(data,_countDown);
        }
    }
    else
    {
        NSLog(@"录音结果保存失败");
    }
    


}

- (void)playLocalAudioWithData:(NSData *)data
{
    if ([self.localPlayer isPlaying])return;
    NSError * error;
    if (![self.audioSession setActive:YES error:&error]) {
        NSLog(@"%@",error);
    }
    self.localPlayer = [[AVAudioPlayer alloc] initWithData:data error:nil];
    [self.audioSession setCategory:AVAudioSessionCategoryPlayback error:nil];
    [self.localPlayer play];
}

- (void)playOnlineAudioWithUrl:(NSString *)Url
{
    NSURL * url  = [NSURL URLWithString:Url];
    
    if (_playItem) {
        [_playItem removeObserver:self forKeyPath:@"status"];
    }
    _playItem = [[AVPlayerItem alloc]initWithURL:url];
    [_playItem addObserver:self forKeyPath:@"status" options:NSKeyValueObservingOptionNew context:nil];
    self.onlinePlayer = [[AVPlayer alloc]initWithPlayerItem:_playItem];


    
    [self.audioSession setCategory:AVAudioSessionCategoryPlayback error:nil];
    [self.onlinePlayer play];
}
-(void)observeValueForKeyPath:(NSString *)keyPath ofObject:(id)object change:(NSDictionary*)change context:(void *)context {
    
    if ([keyPath isEqualToString:@"status"]) {
        switch (_playItem.status) {
            case AVPlayerItemStatusUnknown:
                NSLog(@"KVO：未知状态，此时不能播放");
                break;
            case AVPlayerItemStatusReadyToPlay:
                //self.status = SUPlayStatusReadyToPlay;
                NSLog(@"KVO：准备完毕，可以播放");
                break;
            case AVPlayerItemStatusFailed:
                NSLog(@"KVO：加载失败，网络或者服务器出现问题");
                break;
            default:
                break;
        }
    }
}

- (void)dealloc
{
    [_playItem removeObserver:self forKeyPath:@"status"];
}


@end










