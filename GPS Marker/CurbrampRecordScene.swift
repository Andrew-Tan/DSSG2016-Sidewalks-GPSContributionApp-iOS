//
//  CurbrampRecordScene.swift
//  GPS Marker
//
//  Created by Andrew Tan on 7/1/16.
//  Copyright © 2016 Taskar Center for Accessible Technology. All rights reserved.
//

import UIKit
import CoreLocation
import MapKit
import SwiftyJSON

class CurbrampRecordScene: RecordScene {
    
    // Map
    @IBOutlet weak var mapView: MKMapView!
    
    // Buttons
    @IBOutlet weak var labelCurbramp: UIButton!
    @IBOutlet weak var cancelButton: UIButton!
    
    // Recorded start and end point for sidewalk
    var curbramp: CLLocation?
    var curbrampDroppedPin : MKPointAnnotation?
    
    // File System
    let curbrampFilePath = NSSearchPathForDirectoriesInDomains(.DocumentDirectory, .UserDomainMask, true)[0] + "/curbramp-collection.json"
    var curbrampJSONLibrary: JSON?
    
    override func viewDidLoad() {
        super.viewDidLoad()
        self.title = "Curb Ramp"
        
        // Map delegate configuration
        mapView.delegate = self
        
        // Location manager configuration
        locationManager.delegate = self
        locationManager.requestAlwaysAuthorization()
        
        resetAll()
    }
    
    override func viewDidAppear(animated: Bool) {
        super.viewDidAppear(animated)
        
        // Load GeoJSON file or create a new one
        self.curbrampJSONLibrary = loadData(curbrampFilePath)
    }
    
    // MARK: -Action
    
    /**
     Record when user clicked "Label Curbramp" button
     */
    @IBAction func recordCurbramp() {
        // Get current location
        curbramp = locationManager.location
        
        // Debug: Print recorded point information
        if let validLocation = curbramp {
            print("Long: \(validLocation.coordinate.longitude)")
            print("Lat: \(validLocation.coordinate.latitude)")
            print("Horizontal: \(validLocation.horizontalAccuracy) meters")
            print("Vertical: \(validLocation.verticalAccuracy) meters")
        } else {
            print("Unable to get location information!")
            return
        }
        
        // Set mapView annotation
        // The span value is made relative small, so a big portion of London is visible. The MKCoordinateRegion method defines the visible region, it is set with the setRegion method.
        let span = MKCoordinateSpanMake(0.001, 0.001)
        let region = MKCoordinateRegion(center: curbramp!.coordinate, span: span)
        mapView.setRegion(region, animated: true)
        
        // An annotation is created at the current coordinates with the MKPointAnnotaition class. The annotation is added to the Map View with the addAnnotation method.
        if curbrampDroppedPin != nil {
            mapView.removeAnnotation(curbrampDroppedPin!)
            curbrampDroppedPin = nil
        }
        
        curbrampDroppedPin = MKPointAnnotation()
        curbrampDroppedPin!.coordinate = curbramp!.coordinate
        curbrampDroppedPin!.title = "Curb Ramp"
        mapView.addAnnotation(curbrampDroppedPin!)
        
        // Adjust button visiblities
        labelCurbramp.hidden = false
        labelCurbramp.enabled = false
        
        cancelButton.hidden = false
        cancelButton.enabled = true
        
        saveButton?.enabled = false
        saveButton?.enabled = true
    }
    
    /**
     Cancel recording when user clicked "cancel" button
     */
    @IBAction func cancelRecording() {
        resetAll()
    }
    
    /**
     Save recording when user clicked "save" button
     */
    @IBAction override func saveRecording() {
        super.saveRecording()
        
        // a variable indicating whether recording is saved
        var saveSuccess = true
        
        // Save File
        if curbrampJSONLibrary != nil {
            let curbrampCoordinate = curbramp!.coordinate
            
            // Construct new entry using recorded information
            let newEntry = [["type": "Feature",
                "geometry": ["type": "Point",
                    "coordinates": [curbrampCoordinate.latitude, curbrampCoordinate.longitude]]]]
            
            // Concatenate the new entry with old entries
            curbrampJSONLibrary!["features"] = JSON(curbrampJSONLibrary!["features"].arrayObject! + JSON(newEntry).arrayObject!)
            
            // Debug: Show saved file
            print("Recorded GeoJSON: \(curbrampJSONLibrary)")
            
            
            do {
                try curbrampJSONLibrary?.rawData().writeToFile(curbrampFilePath, atomically: true)
            } catch {
                saveSuccess = false
            }
        } else {
            saveSuccess = false
        }
        
        // Show alert to user
        showSaveSuccessAlert(saveSuccess)
        
        resetAll()
    }
    
    /**
     Reset all scene attributes and visible items to their initial state
     */
    override func resetAll() {
        super.resetAll()
        resetMap(mapView)
        
        // reset button visibility
        labelCurbramp.hidden = false
        labelCurbramp.enabled = true
        
        cancelButton.hidden = true
        cancelButton.enabled = false
        
        // reset all recording variables
        curbramp = nil
        curbrampDroppedPin = nil
    }
    
    //MARK:- CLLocationManagerDelegate methods
    
    override func locationServiceDisabled(manager: CLLocationManager) {
        super.locationServiceDisabled(manager)
        
        labelCurbramp.enabled = false
        mapView.userTrackingMode = .None
    }
    
    override func locationServiceNotDetermined(manager: CLLocationManager) {
        super.locationServiceNotDetermined(manager)
        
        labelCurbramp.enabled = false
        mapView.userTrackingMode = .None
    }
}

