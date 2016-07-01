//
//  SidewalkRecordScene.swift
//  GPS Marker
//
//  Created by Andrew Tan on 6/29/16.
//  Copyright © 2016 Taskar Center for Accessible Technology. All rights reserved.
//

import UIKit
import CoreLocation
import MapKit

class SidewalkRecordScene: UIViewController, CLLocationManagerDelegate, MKMapViewDelegate {
    
    // Map
    @IBOutlet weak var mapView: MKMapView!
    
    // Buttons
    @IBOutlet weak var startButton: UIButton!
    @IBOutlet weak var endButton: UIButton!
    @IBOutlet weak var cancelButton: UIButton!
    @IBOutlet weak var saveButton: UIButton!
    
    // Location Service
    let locationManager = CLLocationManager()
    
    // Recorded start and end point for sidewalk
    var sidewalkStart: CLLocation?
    var sidewalkStartDroppedPin : MKPointAnnotation?
    var sidewalkEnd: CLLocation?
    var sidewalkEndDroppedPin : MKPointAnnotation?
    
    // File System
    let sidewalkFilePath = NSSearchPathForDirectoriesInDomains(.DocumentDirectory, .UserDomainMask, true)[0] + "/sidewalk-collection.json"
    var sidewalkJSONLibrary: JSON?
    
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
        
        // Load GeoJSON file or create a new one
        // Check if file already exist
        if let JSON_Data = NSData(contentsOfFile: sidewalkFilePath) {
            // File Avaliable, fetch from document
            sidewalkJSONLibrary = JSON(data: JSON_Data)
        } else {
            // File Not Avaliable, create new library
            sidewalkJSONLibrary = JSON(["type": "FeatureCollection", "features": []])
        }
    }
    
    // MARK: -Action
    
    /**
     Start recording when user clicked "sidewalk start" button
     */
    @IBAction func sidewalkRecordStart() {
        // Get current location
        sidewalkStart = locationManager.location
        
        // Debug: Print recorded point information
        if let validLocation = sidewalkStart {
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
        let region = MKCoordinateRegion(center: sidewalkStart!.coordinate, span: span)
        mapView.setRegion(region, animated: true)
        
        // An annotation is created at the current coordinates with the MKPointAnnotaition class. The annotation is added to the Map View with the addAnnotation method.
        if sidewalkStartDroppedPin != nil {
            mapView.removeAnnotation(sidewalkStartDroppedPin!)
            sidewalkStartDroppedPin = nil
        }
        
        sidewalkStartDroppedPin = MKPointAnnotation()
        sidewalkStartDroppedPin!.coordinate = sidewalkStart!.coordinate
        sidewalkStartDroppedPin!.title = "Sidewalk Start"
        mapView.addAnnotation(sidewalkStartDroppedPin!)
        
        // Adjust button visiblities
        startButton.hidden = false
        startButton.enabled = false
        
        endButton.hidden = false
        endButton.enabled = true
        
        cancelButton.hidden = false
        cancelButton.enabled = true
        
        saveButton.hidden = true
        saveButton.enabled = false
    }
    
    /**
     End recording when user clicked "sidewalk end" button
     */
    @IBAction func sidewalkRecordEnd() {
        // Get current location
        sidewalkEnd = locationManager.location
        
        // Debug: Print recorded point information
        if let validLocation = sidewalkEnd {
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
        let region = MKCoordinateRegion(center: sidewalkEnd!.coordinate, span: span)
        mapView.setRegion(region, animated: true)
        
        // An annotation is created at the current coordinates with the MKPointAnnotaition class. The annotation is added to the Map View with the addAnnotation method.
        if sidewalkEndDroppedPin != nil {
            mapView.removeAnnotation(sidewalkEndDroppedPin!)
            sidewalkEndDroppedPin = nil
        }
        
        sidewalkEndDroppedPin = MKPointAnnotation()
        sidewalkEndDroppedPin!.coordinate = sidewalkEnd!.coordinate
        sidewalkEndDroppedPin!.title = "Sidewalk End"
        mapView.addAnnotation(sidewalkEndDroppedPin!)
        
        if sidewalkStart == nil || sidewalkEnd == nil {
            print("nil value found?")
            print("Sidewalk Start: \(sidewalkStart)")
            print("Sidewalk End: \(sidewalkEnd)")
            return
        }
        
        // Draw a line between start and end coordinate
        var points = [sidewalkStart!.coordinate, sidewalkEnd!.coordinate]
        let geodesic = MKGeodesicPolyline(coordinates: &points[0], count:2 )
        self.mapView.addOverlay(geodesic)
        
        // Adjust button visibilities
        startButton.hidden = false
        startButton.enabled = false
        
        endButton.hidden = false
        endButton.enabled = false
        
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
        // TODO: Save all the recorded coordinates
        // a variable indicating whether recording is saved
        var saveSuccess = true
        
        // Save File
        if sidewalkJSONLibrary != nil {
            print("JSON Library before recording: \(sidewalkJSONLibrary)")
            let startCoordinate = sidewalkStart!.coordinate
            let endCoordinate = sidewalkEnd!.coordinate
            if sidewalkJSONLibrary!["features"].exists() {
                let newEntry = [["type": "Feature",
                    "geometry": ["type": "LineString",
                        "coordinates": [[startCoordinate.latitude, startCoordinate.longitude],
                            [endCoordinate.latitude, endCoordinate.longitude]]]]]
                
                sidewalkJSONLibrary!["features"] = JSON(sidewalkJSONLibrary!["features"].arrayObject! + JSON(newEntry).arrayObject!)
                print("Recorded GeoJSON: \(sidewalkJSONLibrary)")
                do {
                    try sidewalkJSONLibrary?.rawData().writeToFile(sidewalkFilePath, atomically: true)
                } catch {
                    saveSuccess = false
                }
            } else {
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
        startButton.hidden = false
        startButton.enabled = true
        
        endButton.hidden = true
        endButton.enabled = false
        
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
        sidewalkStart = nil
        sidewalkStartDroppedPin = nil
        sidewalkEnd = nil
        sidewalkEnd = nil
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
            startButton.enabled = false
            endButton.enabled = false
            saveButton.enabled = false
            mapView.userTrackingMode = .None
            manager.requestAlwaysAuthorization()
        case .Restricted, .Denied:
            startButton.enabled = false
            endButton.enabled = false
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
