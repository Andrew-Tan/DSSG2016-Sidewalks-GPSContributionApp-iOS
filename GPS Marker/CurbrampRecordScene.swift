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

class CurbrampRecordScene: UIViewController, CLLocationManagerDelegate, MKMapViewDelegate {
    
    // Map
    @IBOutlet weak var mapView: MKMapView!
    
    // Buttons
    @IBOutlet weak var labelCurbramp: UIButton!
    @IBOutlet weak var cancelButton: UIButton!
    @IBOutlet weak var saveButton: UIButton!
    
    // Location Service
    let locationManager = CLLocationManager()
    
    // Recorded start and end point for sidewalk
    var curbramp: CLLocation?
    var curbrampDroppedPin : MKPointAnnotation?
    
    // File System
    let curbrampFilePath = NSSearchPathForDirectoriesInDomains(.DocumentDirectory, .UserDomainMask, true)[0] + "/curbramp-collection.json"
    var curbrampJSONLibrary: JSON?
    
    override func viewDidLoad() {
        super.viewDidLoad()
        self.title = "Sidewalk"
        
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
        // Check if file already exist
        if let JSON_Data = NSData(contentsOfFile: curbrampFilePath) {
            // File Avaliable, fetch from document
            curbrampJSONLibrary = JSON(data: JSON_Data)
        } else {
            // File Not Avaliable, create new library
            curbrampJSONLibrary = JSON(["type": "FeatureCollection", "features": []])
        }
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
        
        saveButton.hidden = false
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
    @IBAction func saveRecording() {
        // a variable indicating whether recording is saved
        var saveSuccess = true
        
        // Save File
        if curbrampJSONLibrary != nil && curbrampJSONLibrary!["features"].exists() {
            let curbrampCoordinate = curbramp!.coordinate
            
            let newEntry = [["type": "Feature",
                "geometry": ["type": "Point",
                    "coordinates": [curbrampCoordinate.latitude, curbrampCoordinate.longitude]]]]
            
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
        var title: String
        var msg: String
        if saveSuccess {
            title = "Success"
            msg = "Recording Saved"
        } else {
            title = "Fail"
            msg = "Recording Failed to Save"
        }
        let alertController = UIAlertController(
            title: title,
            message: msg,
            preferredStyle: .Alert)
        let dismissAction = UIAlertAction(title: "OK", style: .Cancel, handler: nil)
        alertController.addAction(dismissAction)
        self.presentViewController(alertController, animated: true, completion: nil)
        
        resetAll()
    }
    
    /**
     Reset all scene attributes to their initial state
     */
    func resetAll() {
        // reset button visibility
        labelCurbramp.hidden = false
        labelCurbramp.enabled = true
        
        cancelButton.hidden = true
        cancelButton.enabled = false
        
        saveButton.hidden = true
        saveButton.enabled = false
        
        // reset map view configuration
        mapView.removeAnnotations(mapView.annotations)
        mapView.removeOverlays(mapView.overlays)
        mapView.userTrackingMode = .Follow
        mapView.showsUserLocation = true
        
        // reset all recording variables
        curbramp = nil
        curbrampDroppedPin = nil
    }
    
    //MARK:- CLLocationManagerDelegate methods
    
    /**
     Handle different cases when location authorization status changed
     
     - parameter manager: the CLLocationManager
     - parameter status: the current status of location authorization
     */
    func locationManager(manager: CLLocationManager, didChangeAuthorizationStatus status: CLAuthorizationStatus) {
        mapView.removeAnnotations(mapView.annotations)
        
        switch status {
        case .AuthorizedAlways, .AuthorizedWhenInUse:
            resetAll()
        case .NotDetermined:
            labelCurbramp.enabled = false
            saveButton.enabled = false
            mapView.userTrackingMode = .None
            manager.requestAlwaysAuthorization()
        case .Restricted, .Denied:
            labelCurbramp.enabled = false
            saveButton.enabled = false
            mapView.userTrackingMode = .None
            let alertController = UIAlertController(
                title: "Background Location Access Disabled",
                message: "In order to record location information you reported, please open this app's settings and set location access to 'Always'.",
                preferredStyle: .Alert)
            
            let cancelAction = UIAlertAction(title: "Cancel", style: .Cancel, handler: nil)
            alertController.addAction(cancelAction)
            
            let openAction = UIAlertAction(title: "Open Settings", style: .Default) { (action) in
                if let url = NSURL(string:UIApplicationOpenSettingsURLString) {
                    UIApplication.sharedApplication().openURL(url)
                }
            }
            alertController.addAction(openAction)
            
            self.presentViewController(alertController, animated: true, completion: nil)
        }
    }
    
    
    //MARK:- MapViewDelegate methods
    
    /**
     Delegate function which return renderer for overlays in the map
     */
    func mapView(mapView: MKMapView, rendererForOverlay overlay: MKOverlay) -> MKOverlayRenderer {
        if overlay is MKPolyline {
            let polylineRenderer = MKPolylineRenderer(overlay: overlay)
            polylineRenderer.strokeColor = UIColor.blueColor()
            polylineRenderer.lineWidth = 5
            return polylineRenderer
        }
        
        return MKOverlayRenderer()
    }
}

