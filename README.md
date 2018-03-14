# EditAudioVideo-swift
利用AVFoundation完成音视频的合成，这次是swift版本

分析：
这是一个仿秒拍音视频合成的demo。打开秒拍并拍摄一段视频，然后进入编辑界面，给拍摄的视频添加背景音乐，可以选择任何你喜欢的音乐作为背景音乐，还可以调节背景音乐的音量和拍摄视频的原始音量，来进行合成，但是音视频的合成是需要时间的，而滑动调节音量和选择音乐没有卡顿，所以推测在这个编辑界面并没有进行合成操作，只是音视频一起循环播放；而合成操作是在点击发布按钮后才进行的。


分析完毕，实现功能：
1，根据拍摄视频的长短来剪辑音频的长度
2，实现音视频的同步循环播放
3，音视频合成

## 1、剪辑音频
根据时间生成输出路径
```
#pragma mark - 输出路径
+ (NSURL *)exporterPath {
    
    NSInteger nowInter = (long)[[NSDate date] timeIntervalSince1970];
    NSString *fileName = [NSString stringWithFormat:@"output%ld.mp4",(long)nowInter];
    
    NSString *documentsDirectory = NSSearchPathForDirectoriesInDomains(NSDocumentDirectory, NSUserDomainMask, YES).lastObject;
   
    NSString *outputFilePath =[documentsDirectory stringByAppendingPathComponent:fileName];
    
    if([[NSFileManager defaultManager]fileExistsAtPath:outputFilePath]){
        
        [[NSFileManager defaultManager]removeItemAtPath:outputFilePath error:nil];
    }
    
    return [NSURL fileURLWithPath:outputFilePath];
}
```

根据拍摄视频的长短，来剪辑音频的长度，从而实现音视频同步播放
```
#pragma mark - 音视频剪辑,如果是视频（mp4格式）剪辑把下面的两个地方类型换为AVFileTypeAppleM4V
/**
 音视频剪辑

 @param assetURL  音视频资源路径
 @param startTime 开始剪辑的时间
 @param endTime 结束剪辑的时间
 @param completionHandle 剪辑完成后的回调
 */
+ (void)cutAudioVideoResourcePath:(NSURL *)assetURL startTime:(CGFloat)startTime endTime:(CGFloat)endTime complition:(void (^)(NSURL *outputPath,BOOL isSucceed)) completionHandle{
    //    素材
    AVAsset *asset = [AVAsset assetWithURL:assetURL];

    //    导出素材
    AVAssetExportSession *exporter = [[AVAssetExportSession alloc]initWithAsset:asset presetName:AVAssetExportPresetAppleM4A];
    
    //剪辑(设置导出的时间段)
    CMTime start = CMTimeMakeWithSeconds(startTime, asset.duration.timescale);
    CMTime duration = CMTimeMakeWithSeconds(endTime - startTime,asset.duration.timescale);
    exporter.timeRange = CMTimeRangeMake(start, duration);
    
//    输出路径
    NSURL *outputPath = [self exporterPath];
    exporter.outputURL = [self exporterPath];
    
//    输出格式
    exporter.outputFileType = AVFileTypeAppleM4A;
    
    exporter.shouldOptimizeForNetworkUse= YES;
    
//    合成后的回调
    [exporter exportAsynchronouslyWithCompletionHandler:^{
        switch ([exporter status]) {
            case AVAssetExportSessionStatusFailed: {
                NSLog(@"合成失败：%@",[[exporter error] description]);
                completionHandle(outputPath,NO);
            } break;
            case AVAssetExportSessionStatusCancelled: {
                completionHandle(outputPath,NO);
            } break;
            case AVAssetExportSessionStatusCompleted: {
                completionHandle(outputPath,YES);
            } break;
            default: {
                completionHandle(outputPath,NO);
            } break;
        }
    }];
}
```

## 2、音视频的循环同步播放
下面注释已经很清楚了，不多说了
```
//    添加播放层
    UIView *playView = [[UIView alloc]initWithFrame:CGRectMake(0, 0, self.view.bounds.size.width, 400)];
    [self.view addSubview:playView];
    
//    将资源路径添加到AVPlayerItem上
    AVPlayerItem *playItem = [[AVPlayerItem alloc]initWithURL:[self filePathName:@"abc.mp4"]];
    
//    AVPlayer播放需要添加AVPlayerItem
    self.player = [[AVPlayer alloc]initWithPlayerItem:playItem];
    self.player.volume = 0.5;//默认音量设置为0.5，取值范围0-1
    
//    播放视频需要在AVPlayerLayer上进行显示
    AVPlayerLayer *playerLayer = [AVPlayerLayer playerLayerWithPlayer:self.player];
    playerLayer.frame = playView.frame;//必须要设置playerLayer的frame
    [playView.layer addSublayer:playerLayer];//将AVPlayerLayer添加到播放层的layer上
    
//    添加一个循环播放的通知
    [[NSNotificationCenter defaultCenter]addObserver:self selector:@selector(repeatPlay) name:AVPlayerItemDidPlayToEndTimeNotification object:nil];
    
    
//    背景音乐剪辑播放
//    计算视频的长度，从而进行相应的音频剪辑
    AVAsset *asset = [AVAsset assetWithURL:[self filePathName:@"abc.mp4"]];
    CMTime duration = asset.duration;
    CGFloat videoDuration = duration.value / (float)duration.timescale;
    NSLog(@"%f",videoDuration);
    
//    音频剪辑，调用第一步的音频剪辑工具类
    typeof(self) weakSelf = self;
    [EditAudioVideo cutAudioVideoResourcePath:[self filePathName:@"123.mp3"] startTime:0 endTime:videoDuration complition:^(NSURL *outputPath, BOOL isSucceed) {
        
//        音频剪辑成功后，拿到剪辑后的音频路径
        NSError *error;
        weakSelf.BGMPlayer = [[AVAudioPlayer alloc]initWithContentsOfURL:outputPath error:&error];
        
        if (error == nil) {
            weakSelf.BGMPlayer.numberOfLoops = -1;//循环播放
            weakSelf.BGMPlayer.volume = 0.5;
            
            [weakSelf.BGMPlayer prepareToPlay];//预先加载音频到内存，播放更流畅
            
//            播放音频，同时调用视频播放，实现同步播放
            [weakSelf.BGMPlayer play];
            [weakSelf.player play];
        }else{
            NSLog(@"%@",error);
        }
        
    }];
```

## 3、音视频的合成

1、加载音频和视频资源
```
//    素材
    AVAsset *asset = [AVAsset assetWithURL:assetURL];
    AVAsset *audioAsset = [AVAsset assetWithURL:BGMPath];
 ```
2、分离素材
音频只有音频轨道，而我们录制的视频有两个轨道：音频轨道、视频轨道。需要把音视频资源分离成各个轨道来进行编辑。   
```
    //    分离素材
    AVAssetTrack *videoAssetTrack = [[asset tracksWithMediaType:AVMediaTypeVideo]objectAtIndex:0];//视频素材
    AVAssetTrack *audioAssetTrack = [[audioAsset tracksWithMediaType:AVMediaTypeAudio]objectAtIndex:0];//音频素材
```
    
3、编辑各个轨道需要在AVMutableComposition类的环境中进行
```
    //    编辑视频环境
    AVMutableComposition *composition = [[AVMutableComposition alloc]init];
   ```
 视频素材加入视频轨道
```
    AVMutableCompositionTrack *videoCompositionTrack = [composition addMutableTrackWithMediaType:AVMediaTypeVideo preferredTrackID:kCMPersistentTrackID_Invalid];
```
将视频轨道插入到编辑环境中
```
    [videoCompositionTrack insertTimeRange:CMTimeRangeMake(kCMTimeZero, videoAssetTrack.timeRange.duration) ofTrack:videoAssetTrack atTime:kCMTimeZero error:nil];
    ```
  背景音乐音频素材加入音频轨道
```
    AVMutableCompositionTrack *audioCompositionTrack = [composition addMutableTrackWithMediaType:AVMediaTypeAudio preferredTrackID:kCMPersistentTrackID_Invalid];
```
将背景音乐的音频轨道插入到编辑环境中
```
    [audioCompositionTrack insertTimeRange:CMTimeRangeMake(kCMTimeZero, videoAssetTrack.timeRange.duration) ofTrack:audioAssetTrack atTime:kCMTimeZero error:nil];
```
    
   是否加入视频原声，根据需要选择添加，原理同上
```
    AVMutableCompositionTrack *originalAudioCompositionTrack = nil;
    if (needOriginalVoice) {
        AVAssetTrack *originalAudioAssetTrack = [[asset tracksWithMediaType:AVMediaTypeAudio]objectAtIndex:0];
        originalAudioCompositionTrack = [composition addMutableTrackWithMediaType:AVMediaTypeAudio preferredTrackID:kCMPersistentTrackID_Invalid];
        [originalAudioCompositionTrack insertTimeRange:CMTimeRangeMake(kCMTimeZero, videoAssetTrack.timeRange.duration) ofTrack:originalAudioAssetTrack atTime:kCMTimeZero error:nil];
    }
```
将配置好的AVMutableComposition环境添加到导出类

```
//    导出素材
    AVAssetExportSession *exporter = [[AVAssetExportSession alloc]initWithAsset:composition presetName:AVAssetExportPresetMediumQuality];
```
这里有一个坑，AVMutableCompositionTrack轨道中控制音量preferredVolume属性不起作用，不知道为什么，知道的大神指正下。
所以只能用音频混合调节音量

```
#pragma mark - 调节合成的音量
+ (AVAudioMix *)buildAudioMixWithVideoTrack:(AVCompositionTrack *)videoTrack VideoVolume:(float)videoVolume BGMTrack:(AVCompositionTrack *)BGMTrack BGMVolume:(float)BGMVolume controlVolumeRange:(CMTime)volumeRange {
    
//    创建音频混合类
    AVMutableAudioMix *audioMix = [AVMutableAudioMix audioMix];
    
//    拿到视频声音轨道设置音量
    AVMutableAudioMixInputParameters *Videoparameters = [AVMutableAudioMixInputParameters audioMixInputParametersWithTrack:videoTrack];
    [Videoparameters setVolume:videoVolume atTime:volumeRange];
    
//    设置背景音乐音量
    AVMutableAudioMixInputParameters *BGMparameters = [AVMutableAudioMixInputParameters audioMixInputParametersWithTrack:BGMTrack];
    [BGMparameters setVolume:BGMVolume atTime:volumeRange];
    
//    加入混合数组
    audioMix.inputParameters = @[Videoparameters,BGMparameters];
    
    return audioMix;
}
```
拿到视频、音频资源路径，取到设置的音视频对应音量，进行合成
完整合成代码如下

```
/**
 音视频合成

 @param assetURL 原始视频路径
 @param BGMPath 背景音乐路径
 @param needOriginalVoice 是否添加原视频的声音
 @param videoVolume 视频音量
 @param BGMVolume 背景音乐音量
 @param completionHandle 合成后的回调
 */
+ (void)editVideoSynthesizeVieoPath:(NSURL *)assetURL BGMPath:(NSURL *)BGMPath  needOriginalVoice:(BOOL)needOriginalVoice videoVolume:(CGFloat)videoVolume BGMVolume:(CGFloat)BGMVolume complition:(void (^)(NSURL *outputPath,BOOL isSucceed)) completionHandle{
    //    素材
    AVAsset *asset = [AVAsset assetWithURL:assetURL];
    AVAsset *audioAsset = [AVAsset assetWithURL:BGMPath];
    
    //    分离素材
    AVAssetTrack *videoAssetTrack = [[asset tracksWithMediaType:AVMediaTypeVideo]objectAtIndex:0];//视频素材
    AVAssetTrack *audioAssetTrack = [[audioAsset tracksWithMediaType:AVMediaTypeAudio]objectAtIndex:0];//音频素材
    
    //    编辑视频环境
    AVMutableComposition *composition = [[AVMutableComposition alloc]init];
    
    //    视频素材加入视频轨道
    AVMutableCompositionTrack *videoCompositionTrack = [composition addMutableTrackWithMediaType:AVMediaTypeVideo preferredTrackID:kCMPersistentTrackID_Invalid];
    [videoCompositionTrack insertTimeRange:CMTimeRangeMake(kCMTimeZero, videoAssetTrack.timeRange.duration) ofTrack:videoAssetTrack atTime:kCMTimeZero error:nil];
    
    //    音频素材加入音频轨道
    AVMutableCompositionTrack *audioCompositionTrack = [composition addMutableTrackWithMediaType:AVMediaTypeAudio preferredTrackID:kCMPersistentTrackID_Invalid];
    [audioCompositionTrack insertTimeRange:CMTimeRangeMake(kCMTimeZero, videoAssetTrack.timeRange.duration) ofTrack:audioAssetTrack atTime:kCMTimeZero error:nil];
    
    //    是否加入视频原声
    AVMutableCompositionTrack *originalAudioCompositionTrack = nil;
    if (needOriginalVoice) {
        AVAssetTrack *originalAudioAssetTrack = [[asset tracksWithMediaType:AVMediaTypeAudio]objectAtIndex:0];
        originalAudioCompositionTrack = [composition addMutableTrackWithMediaType:AVMediaTypeAudio preferredTrackID:kCMPersistentTrackID_Invalid];
        [originalAudioCompositionTrack insertTimeRange:CMTimeRangeMake(kCMTimeZero, videoAssetTrack.timeRange.duration) ofTrack:originalAudioAssetTrack atTime:kCMTimeZero error:nil];
    }
    
    //    导出素材
    AVAssetExportSession *exporter = [[AVAssetExportSession alloc]initWithAsset:composition presetName:AVAssetExportPresetMediumQuality];
    
//    音量控制
    exporter.audioMix = [self buildAudioMixWithVideoTrack:originalAudioCompositionTrack VideoVolume:videoVolume BGMTrack:audioCompositionTrack BGMVolume:BGMVolume controlVolumeRange:kCMTimeZero];
    
//    设置输出路径
    NSURL *outputPath = [self exporterPath];
    exporter.outputURL = [self exporterPath];
    exporter.outputFileType = AVFileTypeMPEG4;//指定输出格式
    
    [exporter exportAsynchronouslyWithCompletionHandler:^{
        switch ([exporter status]) {
            case AVAssetExportSessionStatusFailed: {
                NSLog(@"合成失败：%@",[[exporter error] description]);
                completionHandle(outputPath,NO);
            } break;
            case AVAssetExportSessionStatusCancelled: {
                completionHandle(outputPath,NO);
            } break;
            case AVAssetExportSessionStatusCompleted: {
                completionHandle(outputPath,YES);
            } break;
            default: {
                completionHandle(outputPath,NO);
            } break;
        }
    }];
```

GitHub代码下载[https://github.com/D-james/AudioVideoEdit](https://github.com/D-james/AudioVideoEdit)，文件比较大，因为把要合成的音频、视频也传上去了。
swift版[https://github.com/D-james/EditAudioVideo-swift](https://github.com/D-james/EditAudioVideo-swift)

参考资料：《AV Foundation开发秘籍:实践掌握iOS & OS X 应用的视听处理技术》
