//
//  Movie.swift
//  GhostCam
//
//  Created by Leyun Song on 16/1/7.
//  Copyright © 2016年 Leyun Song. All rights reserved.
//

import UIKit
import AVFoundation

class Movie:NSObject, NSCoding {
    // MARK: Properties
    var name: String
    var preview: UIImage?
    var duration: CMTime
    var filePath: String
    
    // MARK: Types
    struct PropertyKey {
        static let namekey = "name"
        static let previewKey = "preview"
        static let durationKey = "duration"
        static let filePathKey = "filePath"
    }
    
    // MARK: Archiving File Path
    static let DocumentsDirectory = NSFileManager().URLsForDirectory(.DocumentDirectory, inDomains: .UserDomainMask).first!
    static let ArchiveURL = DocumentsDirectory.URLByAppendingPathComponent("movies")
    
    // MARK: Initializaer
    init?(name:String, preview:UIImage, duration:CMTime, filePath:String) {
        self.name = name
        self.preview = preview
        self.duration = duration
        self.filePath = filePath
        
        super.init()
        
        if name.isEmpty || filePath.isEmpty {
            return nil
        }
        
    }
    
    // MARK: NSCoding
    func encodeWithCoder(aCoder: NSCoder) {
        aCoder.encodeObject(name, forKey: PropertyKey.namekey)
        aCoder.encodeObject(preview, forKey: PropertyKey.previewKey)
        aCoder.encodeCMTime(duration, forKey: PropertyKey.durationKey)
        aCoder.encodeObject(filePath, forKey: PropertyKey.filePathKey)
    }
    
    required convenience init?(coder aDecoder: NSCoder) {
        let name = aDecoder.decodeObjectForKey(PropertyKey.namekey) as! String
        let preview = aDecoder.decodeObjectForKey(PropertyKey.previewKey) as! UIImage
        let duration = aDecoder.decodeCMTimeForKey(PropertyKey.durationKey)
        let filePath = aDecoder.decodeObjectForKey(PropertyKey.filePathKey) as! String
        self.init(name:name, preview:preview, duration:duration, filePath:filePath)
        
    }
}
