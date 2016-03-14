//
//  Settings.swift
//  GhostCam
//
//  Created by Leyun Song on 16/1/19.
//  Copyright © 2016年 Leyun Song. All rights reserved.
//

import UIKit

class Settings {
    var maxSeconds: Int
    var mask :Bool
    var frameRate :Int
    let defaults = NSUserDefaults.standardUserDefaults()
    
    init() {
        maxSeconds = defaults.integerForKey("maxSecondsKey")
        mask = defaults.boolForKey("maskKey")
        frameRate = defaults.integerForKey("frameRateKey")
        print("Mask:\(mask)","FPSLevel:\(frameRate)","MaxSeconds:\(maxSeconds)")
    }
}