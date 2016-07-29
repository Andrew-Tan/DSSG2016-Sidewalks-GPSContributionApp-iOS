//
//  LineStringRecordScene.swift
//  GPS Marker
//
//  Created by Andrew Tan on 7/28/16.
//  Copyright © 2016 Taskar Center for Accessible Technology. All rights reserved.
//

import UIKit
import MapKit
import SwiftyJSON

class LineStringRecordScene: RecordScene {
    
    // Map
    @IBOutlet weak var mapView: MKMapView!
    
    // Buttons
    @IBOutlet weak var startButton: UIButton!
    @IBOutlet weak var endButton: UIButton!
    @IBOutlet weak var cancelButton: UIButton!
    
    // Recorded start and end point for line
    var lineStart: CLLocation?
    var lineStartDroppedPin : MKPointAnnotation?
    var lineEnd: CLLocation?
    var lineEndDroppedPin : MKPointAnnotation?
    
    // Drop down text fields
    @IBOutlet weak var dropDownView: UIView!
    
    // File System
    var lineFilePath: String { get { return "" } }
    var lineJSONLibrary: JSON?
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        // Map delegate configuration
        mapView.delegate = self
        
        // Location manager configuration
        locationManager.delegate = self
        locationManager.requestAlwaysAuthorization()
        
        resetAll()
    }
    
    override func viewDidAppear(animated: Bool) {
        super.viewDidAppear(animated)
        
        dropDown.anchorView = self.dropDownView
    }
    
    // MARK: -Action
    
    /**
     Start recording when user clicked "line start" button
     */
    @IBAction func lineRecordStart() {
        // Get current location
        self.lineStart = locationManager.location
        
        // Debug: Print recorded point information
        if let validLocation = self.lineStart {
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
        let region = MKCoordinateRegion(center: self.lineStart!.coordinate, span: span)
        mapView.setRegion(region, animated: true)
        
        // An annotation is created at the current coordinates with the MKPointAnnotaition class. The annotation is added to the Map View with the addAnnotation method.
        if lineStartDroppedPin != nil {
            mapView.removeAnnotation(lineStartDroppedPin!)
            lineStartDroppedPin = nil
        }
        
        lineStartDroppedPin = MKPointAnnotation()
        lineStartDroppedPin!.coordinate = self.lineStart!.coordinate
        lineStartDroppedPin!.title = "line Start"
        mapView.addAnnotation(lineStartDroppedPin!)
        
        // Adjust button visiblities
        startButton.hidden = false
        startButton.enabled = false
        
        endButton.hidden = false
        endButton.enabled = true
        
        cancelButton.hidden = false
        cancelButton.enabled = true
        
        saveButton.enabled = false
    }
    
    /**
     End recording when user clicked "line end" button
     */
    @IBAction func lineRecordEnd() {
        // Get current location
        self.lineEnd = locationManager.location
        
        // Debug: Print recorded point information
        if let validLocation = self.lineEnd {
            print("Long: \(validLocation.coordinate.longitude)")
            print("Lat: \(validLocation.coordinate.latitude)")
            print("Horizontal: \(validLocation.horizontalAccuracy) meters")
            print("Vertical: \(validLocation.verticalAccuracy) meters")
        } else {
            print("Unable to get location information!")
            return
        }
        
        // Stop map user tracking mode
        mapView.userTrackingMode = .None
        mapView.showsUserLocation = false
        
        // Set mapView annotation
        // The span value is made relative small, so a big portion of London is visible. The MKCoordinateRegion method defines the visible region, it is set with the setRegion method.
        let span = MKCoordinateSpanMake(0.001, 0.001)
        let region = MKCoordinateRegion(center: self.lineEnd!.coordinate, span: span)
        mapView.setRegion(region, animated: true)
        
        // An annotation is created at the current coordinates with the MKPointAnnotaition class. The annotation is added to the Map View with the addAnnotation method.
        if lineEndDroppedPin != nil {
            mapView.removeAnnotation(lineEndDroppedPin!)
            lineEndDroppedPin = nil
        }
        
        lineEndDroppedPin = MKPointAnnotation()
        lineEndDroppedPin!.coordinate = self.lineEnd!.coordinate
        lineEndDroppedPin!.title = "line End"
        mapView.addAnnotation(lineEndDroppedPin!)
        
        if lineStart == nil || lineEnd == nil {
            NSLog("nil value found for line recording scene")
            NSLog("line Start: \(lineStart)")
            NSLog("line End: \(lineEnd)")
            return
        }
        
        // Draw a line between start and end coordinate
        var points = [self.lineStart!.coordinate, self.lineEnd!.coordinate]
        let geodesic = MKGeodesicPolyline(coordinates: &points[0], count:2 )
        self.mapView.addOverlay(geodesic)
        
        // Adjust button visibilities
        startButton.hidden = false
        startButton.enabled = false
        
        endButton.hidden = false
        endButton.enabled = false
        
        cancelButton.hidden = false
        cancelButton.enabled = true
        
        saveButton.enabled = true
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
    override func saveRecording() {
        super.saveRecording()
        
        // a variable indicating whether recording is saved
        var saveSuccess = true
        
        if self.lineStart == nil {
            print("Start is nil")
            return
        }
        
        if self.lineEnd == nil {
            print("End is nil")
            return
        }
        
        // Save File
        if lineJSONLibrary != nil {
            let startCoordinate = self.lineStart!.coordinate
            let endCoordinate = self.lineEnd!.coordinate
            
            // Construct new entry using recorded information
            let newEntry = [["type": "Feature",
                "geometry": ["type": "LineString",
                    "coordinates": [[startCoordinate.latitude, startCoordinate.longitude],
                                    [endCoordinate.latitude, endCoordinate.longitude]]],
                "properties": self.savedProperties]]
            
            // Concatenate the new entry with old entries
            lineJSONLibrary!["features"] = JSON(lineJSONLibrary!["features"].arrayObject! + JSON(newEntry).arrayObject!)
            
            // Debug: Show saved file
            print("Recorded GeoJSON: \(lineJSONLibrary)")
            
            
            do {
                try lineJSONLibrary?.rawData().writeToFile(lineFilePath, atomically: true)
            } catch {
                saveSuccess = false
            }
        } else {
            print("Line JSON library is nil")
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
        startButton.hidden = false
        startButton.enabled = true
        
        endButton.hidden = true
        endButton.enabled = false
        
        cancelButton.hidden = true
        cancelButton.enabled = false
        
        // reset all recording variables
        lineStart = nil
        lineStartDroppedPin = nil
        lineEnd = nil
        lineEnd = nil
    }
    
    
    //MARK:- CLLocationManagerDelegate methods
    
    override func locationServiceDisabled(manager: CLLocationManager) {
        super.locationServiceDisabled(manager)
        
        startButton.enabled = false
        endButton.enabled = false
        mapView.userTrackingMode = .None
    }
    
    override func locationServiceNotDetermined(manager: CLLocationManager) {
        super.locationServiceDisabled(manager)
        
        startButton.enabled = false
        endButton.enabled = false
        mapView.userTrackingMode = .None
    }
    
}
