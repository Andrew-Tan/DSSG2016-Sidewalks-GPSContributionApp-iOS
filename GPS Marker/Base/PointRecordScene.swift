//
//  PointRecordScene.swift
//  Open Sidewalks iOS
//
//  Created by Andrew Tan on 7/29/16.
//  Copyright © 2016 Taskar Center for Accessible Technology. All rights reserved.
//

import UIKit
import MapKit
import SwiftyJSON

class PointRecordScene: RecordScene {
    
    // Map
    @IBOutlet weak var mapView: MKMapView!
    
    // Buttons
    @IBOutlet weak var labelpoint: UIButton!
    @IBOutlet weak var cancelButton: UIButton!
    
    // Recorded start and end point for sidewalk
    var point: CLLocation?
    var pointDroppedPin : MKPointAnnotation?
    
    // Drop down view
    @IBOutlet weak var dropDownView: UIView!
    
    // File System
    var pointFilePath: String { get { return "" } }
    var pointJSONLibrary: JSON?
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        // Map delegate configuration
        mapView.delegate = self
        
        // Location manager configuration
        locationManager.delegate = self
        locationManager.requestAlwaysAuthorization()
        
        resetAll()
    }
    
    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        
        // Drop down view
        dropDown.anchorView = self.dropDownView
    }
    
    // MARK: -Action
    
    /**
     Record when user clicked "Label point" button
     */
    @IBAction func recordPoint() {
        // Get current location
        point = locationManager.location
        if point == nil {
            return
        }
        
        // An annotation is created at the current coordinates with the MKPointAnnotaition class. The annotation is added to the Map View with the addAnnotation method.
        if pointDroppedPin != nil {
            mapView.removeAnnotation(pointDroppedPin!)
            pointDroppedPin = nil
        }
        
        if point!.horizontalAccuracy < 11 {
            pointDroppedPin = self.dropPinOnMap(mapView, locationPoint: self.point!, title: "Curb Ramp")
            afterRecordPointClicked()
        } else {
            let alertController = UIAlertController(
                title: "Warning",
                message: "Current horizontal accuracy is \(point!.horizontalAccuracy) meters, which is not accurate enough, do you want to try again?",
                preferredStyle: .alert)
            
            let dismissAction = UIAlertAction(title: "No, go on!", style: .default, handler: { (alert: UIAlertAction!) in
                self.pointDroppedPin = self.dropPinOnMap(self.mapView, locationPoint: self.point!, title: "Curb Ramp")
                self.afterRecordPointClicked()
            })
            alertController.addAction(dismissAction)
            
            let retryAction = UIAlertAction(title: "Yes, retry!", style: .default, handler: nil)
            alertController.addAction(retryAction)
            
            self.present(alertController, animated: true, completion: nil)
        }
    }
    
    func afterRecordPointClicked() {
        // Adjust button visiblities
        labelpoint.isHidden = false
        labelpoint.isEnabled = false
        
        cancelButton.isHidden = false
        cancelButton.isEnabled = true
        
        saveButton?.isEnabled = false
        saveButton?.isEnabled = true
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
        if pointJSONLibrary != nil {
            let pointCoordinate = point!.coordinate
            
            // Construct new entry using recorded information
            let newEntry = [["type": "Feature",
                "geometry": ["type": "Point",
                    "coordinates": [pointCoordinate.longitude, pointCoordinate.latitude]],
                "properties": self.savedProperties]]
            
            // Concatenate the new entry with old entries
            pointJSONLibrary!["features"] = JSON(pointJSONLibrary!["features"].arrayObject! + JSON(newEntry).arrayObject!)
            
            do {
                // try pointJSONLibrary?.rawData().writeToFile(pointFilePath, atomically: true)
                // TODO: Check Syntax
                if let url_path = URL(string: pointFilePath) {
                    try pointJSONLibrary?.rawData().write(to: url_path)
                } else {
                    print("Cannot get url from point path")
                }
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
        labelpoint.isHidden = false
        labelpoint.isEnabled = true
        
        cancelButton.isHidden = true
        cancelButton.isEnabled = false
        
        // reset all recording variables
        point = nil
        pointDroppedPin = nil
    }
    
    //MARK:- CLLocationManagerDelegate methods
    
    override func locationServiceDisabled(_ manager: CLLocationManager) {
        super.locationServiceDisabled(manager)
        
        labelpoint.isEnabled = false
        mapView.userTrackingMode = .none
    }
    
    override func locationServiceNotDetermined(_ manager: CLLocationManager) {
        super.locationServiceNotDetermined(manager)
        
        labelpoint.isEnabled = false
        mapView.userTrackingMode = .none
    }
}

