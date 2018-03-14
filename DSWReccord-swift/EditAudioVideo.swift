//
//  EditAudioVideo.swift
//  DSWReccord-swift
//
//  Created by 段盛武 on 20/02/2018.
//  Copyright © 2018 D.James. All rights reserved.
//

import UIKit
import AVFoundation

class EditAudioVideo: NSObject {

//    音视频合成
    class func audioVideoSynthesis(audioURL:URL, videoURL:URL, videoVolume:Float, BGMVolume:Float,handly:@escaping (_ outputPath:URL, _ isSuccess:Bool)->()) -> ()  {
        
//        1.准备素材
        let audioAsset = AVAsset.init(url: audioURL)
        let videoAsset = AVAsset.init(url: videoURL)
        
//        2.分离素材
        let videoAudioTrack = videoAsset.tracks(withMediaType: .audio).first
        let videoVideoTrack = videoAsset.tracks(withMediaType: .video).first
        
        let audioTrack = audioAsset.tracks(withMediaType: .audio).first
        
        let videoTime = CMTimeRangeMake(kCMTimeZero, videoAsset.duration)
        
//        3.建立环境组合素材
        let composition = AVMutableComposition.init()
        
//        视频
        let videoComposition = composition.addMutableTrack(withMediaType: .video, preferredTrackID: kCMPersistentTrackID_Invalid)
        do {
            try videoComposition?.insertTimeRange(videoTime, of: videoVideoTrack!, at: kCMTimeZero)
        } catch  {
            print(error)
        }
        
//        音频
        let audioComposition = composition.addMutableTrack(withMediaType: .audio, preferredTrackID: kCMPersistentTrackID_Invalid)
        let audioVideoComposition = composition.addMutableTrack(withMediaType: .audio, preferredTrackID: kCMPersistentTrackID_Invalid)
        do {
            try audioComposition?.insertTimeRange(videoTime, of: audioTrack!, at: kCMTimeZero)
            try audioVideoComposition?.insertTimeRange(videoTime, of: videoAudioTrack!, at: kCMTimeZero)
        } catch  {
            print(error)
        }
        
//        4.导出组合好的素材
        let exportSession = AVAssetExportSession.init(asset: composition, presetName: AVAssetExportPresetMediumQuality)
        exportSession?.outputFileType = AVFileType.mov
        exportSession?.shouldOptimizeForNetworkUse = true
        
        exportSession?.audioMix = self.volumeControl(avtrack: audioVideoComposition, atrack: audioComposition, videoVolume: videoVolume, audioVolume: BGMVolume, time: kCMTimeZero)
        
        let outPath = outputPath()
        exportSession?.outputURL = outPath
        
        
        exportSession?.exportAsynchronously(completionHandler: {
            switch exportSession?.status {
                
            case .some(.completed):
                handly(outPath,true)
            case .none,.some(.waiting),.some(.exporting),.some(.failed),.some(.cancelled),.some(.unknown):
                handly(outPath,false)
                print(exportSession?.error ?? "")
            }

        })
    }
    
    //    MARK: - 音量设置
    class func volumeControl(avtrack:AVCompositionTrack?, atrack:AVCompositionTrack?, videoVolume:Float, audioVolume:Float, time:CMTime) -> AVMutableAudioMix {
        
        let avInput = AVMutableAudioMixInputParameters.init(track: avtrack)
        avInput.setVolume(videoVolume, at: time)
        
        let aInput = AVMutableAudioMixInputParameters.init(track: atrack)
        aInput.setVolume(audioVolume, at: time)
        
        let audioMix = AVMutableAudioMix.init()
        audioMix.inputParameters = [avInput,aInput]
        
        return audioMix
    }
    
//    音视频剪接
    class func cutWith(assetPath:URL, startTime:CGFloat, endTime:CGFloat, handly:@escaping (_ outputPath:URL, _ isSuccess:Bool)->()) -> () {
        
        let asset = AVAsset.init(url: assetPath)
        
        let exportSession = AVAssetExportSession.init(asset: asset, presetName: AVAssetExportPresetAppleM4A)
        
        exportSession?.outputFileType = AVFileType.m4a
        
        let outPath = outputPath()
        exportSession?.outputURL = outPath
        exportSession?.shouldOptimizeForNetworkUse = true
        
        let start = CMTimeMake(Int64(startTime), 1)
        let duration = CMTimeMake(Int64(endTime - startTime), 1)
        exportSession?.timeRange = CMTimeRangeMake(start, duration)
        
        exportSession?.exportAsynchronously(completionHandler: {
            switch exportSession?.status {
                
            case .none,.some(.waiting),.some(.exporting),.some(.failed),.some(.cancelled),.some(.unknown):
                handly(outPath,false)

            case .some(.completed):
                handly(outPath,true)

            }
        })
        
    }
    
    
//    输出地址
    class func outputPath() -> URL {
        let documentDicectory = NSSearchPathForDirectoriesInDomains(.documentDirectory, .userDomainMask, true).last
        
        let time = Date.init().timeIntervalSince1970
        
        let pathStr = documentDicectory! + "/audio" + String(time) + ".mp4"
        
        return URL.init(fileURLWithPath: pathStr)
    }
    
    
    
    
}


