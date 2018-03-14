//
//  EditViewController.swift
//  DSWReccord-swift
//
//  Created by 段盛武 on 18/02/2018.
//  Copyright © 2018 D.James. All rights reserved.
//

import UIKit
import AVFoundation

class EditViewController: UIViewController {

    var avPlay = AVPlayer.init(url: URL.init(fileURLWithPath: Bundle.main.path(forResource: "shoutVideo.mp4", ofType: nil)!))
    var audioPlayer:AVAudioPlayer?

    @IBOutlet weak var originalSlider: UISlider!
    
    @IBOutlet weak var BGMSlider: UISlider!
    
    
    override func viewDidLoad() {
        super.viewDidLoad()

        originalSlider.value = 0.5
        originalSlider.value = 0.5
        
//        播放层
        let playView = UIView.init()
        playView.frame = CGRect(x: 0, y: 0, width: UIScreen.main.bounds.size.width, height: 300)
        view.addSubview(playView)

        let playLayer = AVPlayerLayer.init(player: avPlay)
        playView.layer.addSublayer(playLayer)
        playLayer.frame = playView.frame
        

        NotificationCenter.default.addObserver(self, selector: #selector(repeatPlay), name: NSNotification.Name.AVPlayerItemDidPlayToEndTime, object: nil)


//        音量调节
        originalSlider.addTarget(self, action: #selector(volumeBGM2), for: .valueChanged)
        BGMSlider.addTarget(self, action: #selector(volumeOriginal2), for: .valueChanged)

//        音乐剪辑
        let videoAsset = AVAsset.init(url: readFile(name: "shoutVideo.mp4"))
        let videoTime = CGFloat(videoAsset.duration.value)/CGFloat(videoAsset.duration.timescale)

        let musicPath = URL.init(fileURLWithPath: Bundle.main.path(forResource: "music.mp3", ofType: nil)!)
//        let musicAsset = AVAsset.init(url: musicPath)

        EditAudioVideo.cutWith(assetPath: musicPath, startTime: 0, endTime: videoTime) { (url, isSuccess) in
            if isSuccess {
                do {
                    self.audioPlayer = try AVAudioPlayer.init(contentsOf: url)
                    self.audioPlayer?.numberOfLoops = -1
                    self.audioPlayer?.volume = 0.5
                    self.audioPlayer?.prepareToPlay()
                    
                    self.audioPlayer?.play()
                    self.avPlay.play()
                }
                catch {
                    print(error)
                }
            }
        }
        
        
    }

    override func viewDidDisappear(_ animated: Bool) {
        super.viewDidDisappear(animated)
        
        NotificationCenter.default.removeObserver(self)
        self.audioPlayer?.stop()
        self.avPlay.pause()
    }
    
    
    @objc fileprivate func repeatPlay() {
        avPlay.seek(to: CMTimeMake(0, 1))
        avPlay.play()
    }
    
    @objc func volumeBGM2(_ sender: UISlider) {
        
//        print(sender.value)        
        self.audioPlayer?.volume = sender.value
    }
    
    @objc func volumeOriginal2(_ sender: UISlider) {
        
//        print(sender.value)
        self.avPlay.volume = sender.value
    }
    
    
    
//    合成事件(合成是个耗时操作，应该放在子线程)
    @IBAction func synthesisBtnEvent(_ sender: Any) {
        EditAudioVideo.audioVideoSynthesis(audioURL: readFile(name: "music.mp3"), videoURL: readFile(name: "shoutVideo.mp4"), videoVolume: self.avPlay.volume, BGMVolume: (self.audioPlayer?.volume)!) { (pathURL, isSuccess) in
            if isSuccess {
                let showVC = FinishShowController()
                showVC.playPath = pathURL
                self.present(showVC, animated: true, completion: nil)                
            }
        }
        
    }
    
    
    func readFile(name:String) -> URL{
        return URL.init(fileURLWithPath: Bundle.main.path(forResource: name, ofType: nil)!)
        
    }

}
