//
//  FinishShowController.swift
//  DSWReccord-swift
//
//  Created by 段盛武 on 25/02/2018.
//  Copyright © 2018 D.James. All rights reserved.
//

import UIKit
import AVFoundation

class FinishShowController: UIViewController {

    var playPath:URL?
    
    var videoPlayer:AVPlayer?
    
    override func viewDidLoad() {
        super.viewDidLoad()

        // Do any additional setup after loading the view.
        view.backgroundColor = UIColor.red
        
        guard let url = playPath else {
            return
        }
        videoPlayer = AVPlayer.init(url: url)
        
        let v = UIView.init(frame: CGRect(x: 0, y: 200, width: UIScreen.main.bounds.size.width, height: 400))
        view.addSubview(v)
        
        let playerLayer = AVPlayerLayer.init(player: videoPlayer)
        v.layer.addSublayer(playerLayer)
        playerLayer.frame = v.bounds
        
        videoPlayer?.play()
    }

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }
    

    /*
    // MARK: - Navigation

    // In a storyboard-based application, you will often want to do a little preparation before navigation
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        // Get the new view controller using segue.destinationViewController.
        // Pass the selected object to the new view controller.
    }
    */

}
