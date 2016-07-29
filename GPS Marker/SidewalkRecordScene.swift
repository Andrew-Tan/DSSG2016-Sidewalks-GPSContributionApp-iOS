//
//  SidewalkRecordScene.swift
//  GPS Marker
//
//  Created by Andrew Tan on 6/29/16.
//  Copyright © 2016 Taskar Center for Accessible Technology. All rights reserved.
//

import UIKit
import MapKit
import SwiftyJSON

class SidewalkRecordScene: LineStringRecordScene {
    
    // File System
    override var lineFilePath: String { get { return NSSearchPathForDirectoriesInDomains(.DocumentDirectory, .UserDomainMask, true)[0] + "/sidewalk-collection.json" } }
    
    override func viewDidLoad() {
        self.title = "Sidewalk"
        super.viewDidLoad()
    }
    
    override func viewDidAppear(animated: Bool) {
        super.viewDidAppear(animated)
        
        // Load GeoJSON file or create a new one
        self.lineJSONLibrary = loadData(lineFilePath)
    }
    
    // MARK: -Action
    
    @IBAction func callDropDown(sender: UIButton) {
        var senderTitle = "Unknown"
        
        switch (sender.tag) {
        case 50:
            self.title = "Sidewalk Access"
            senderTitle = "Access"
        case 51:
            self.title = "Sidewalk Surface"
            senderTitle = "Surface"
            break
        case 52:
            self.title = "Sidewalk Width"
            senderTitle = "Sidewalk Width"
            break
        case 53:
            self.title = "Sidewalk Shade"
            senderTitle = "Shade"
            break
        case 54:
            self.title = "Sidewalk Lit"
            senderTitle = "Lit"
            break
        default:
            break
        }
        
        displayDropDown(senderTitle, sender: sender)
    }
    
    
    /**
     Start recording when user clicked "sidewalk start" button
     */
    @IBAction func sidewalkRecordStart() {
        self.title = "Start Recording Sidewalk"
        super.lineRecordStart()
    }
    
    /**
     End recording when user clicked "sidewalk end" button
     */
    @IBAction func sidewalkRecordEnd() {
        self.title = "End Recording Sidewalk"
        super.lineRecordEnd()
    }
    
    /**
     Cancel recording when user clicked "cancel" button
     */
    @IBAction override func cancelRecording() {
        self.title = "Cancel Recording"
        resetAll()
    }
    
    override func saveRecording() {
        self.title = "Save Recording"
        super.saveRecording()
    }
}
