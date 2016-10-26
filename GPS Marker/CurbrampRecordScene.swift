//
//  CurbrampRecordScene.swift
//  GPS Marker
//
//  Created by Andrew Tan on 7/1/16.
//  Copyright © 2016 Taskar Center for Accessible Technology. All rights reserved.
//

import UIKit
import MapKit
import SwiftyJSON

class CurbrampRecordScene: PointRecordScene {
    
    // File System
    override var pointFilePath: String { get { return NSSearchPathForDirectoriesInDomains(.documentDirectory, .userDomainMask, true)[0] + "/curbramp-collection.json" } }
    
    override func viewDidLoad() {
        self.title = "Curb Ramp"
        super.viewDidLoad()
    }
    
    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        
        // Load GeoJSON file or create a new one
        self.pointJSONLibrary = loadData(pointFilePath)
        self.pointJSONLibrary!["properties"]["Type"] = JSON("Curb Ramps")
    }
    
    // MARK: -Action
    
    @IBAction func callDropDown(_ sender: UIButton) {
        var senderTitle = "Unknown"
        
        switch (sender.tag) {
        case 50:
            self.title = "Curb Ramp Access"
            senderTitle = "Wheelchair Access"
        case 51:
            self.title = "Curb Ramp State"
            senderTitle = "Curb Ramp"
            break
        case 52:
            self.title = "Curb Ramp Tactile Paving"
            senderTitle = "Tactile Paving"
            break
        default:
            break
        }
        
        displayDropDown(senderTitle, sender: sender)
    }
    
    /**
     Record when user clicked "Label Curbramp" button
     */
    @IBAction func recordCurbramp() {
        self.title = "Curb Ramp Exist"
        super.recordPoint()
    }
    
    /**
     Cancel recording when user clicked "cancel" button
     */
    @IBAction override func cancelRecording() {
        self.title = "Cancel Recording"
        resetAll()
    }
}

