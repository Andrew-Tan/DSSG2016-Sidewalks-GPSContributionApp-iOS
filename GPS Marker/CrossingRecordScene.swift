//
//  CrossingRecordScene.swift
//  GPS Marker
//
//  Created by Andrew Tan on 7/28/16.
//  Copyright © 2016 Taskar Center for Accessible Technology. All rights reserved.
//

import UIKit
import MapKit
import SwiftyJSON

class CrossingRecordScene: LineStringRecordScene {
    
    // File System
    override var lineFilePath: String { get { return NSSearchPathForDirectoriesInDomains(.documentDirectory, .userDomainMask, true)[0] + "/crossing-collection.json" } }
    
    override func viewDidLoad() {
        self.title = "Crossing"
        super.viewDidLoad()
    }
    
    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        
        // Load GeoJSON file or create a new one
        self.lineJSONLibrary = loadData(lineFilePath)
        self.lineJSONLibrary!["properties"]["Type"] = JSON("Crossings")
    }
    
    // MARK: -Action
    
    @IBAction func callDropDown(_ sender: UIButton) {
        var senderTitle = "Unknown"
        
        switch (sender.tag) {
        case 50:
            self.title = "Crossing Surface"
            senderTitle = "Surface"
        case 51:
            self.title = "Crossing Access"
            senderTitle = "Wheelchair Access"
            break
        case 52:
            self.title = "Crossing Type"
            senderTitle = "Crossing Type"
            break
        case 53:
            self.title = "Start Curb Ramp"
            senderTitle = "Start Curb Ramp"
            break
        case 54:
            self.title = "End Curb Ramp"
            senderTitle = "End Curb Ramp"
            break
        default:
            break
        }
        
        displayDropDown(senderTitle, sender: sender)
    }
    
    
    /**
     Start recording when user clicked "sidewalk start" button
     */
    @IBAction func crossingRecordStart() {
        self.title = "Crossing Start"
        super.lineRecordStart()
    }
    
    /**
     End recording when user clicked "sidewalk end" button
     */
    @IBAction func crossingRecordEnd() {
        self.title = "Crossing End"
        super.lineRecordEnd()
    }
}

 
