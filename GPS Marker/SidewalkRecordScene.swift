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

class SidewalkRecordScene: UIViewController, CLLocationManagerDelegate {
    
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
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        // Location manager configuration
        locationManager.delegate = self
        locationManager.requestAlwaysAuthorization()
        
        resetAll()
    }
    
    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }
    
    /**
     Handle different cases when location authorization status changed
     
     - parameter manager: the CLLocationManager
     - parameter status: the current status of location authorization
     */
    func locationManager(manager: CLLocationManager, didChangeAuthorizationStatus status: CLAuthorizationStatus) {
        mapView.removeAnnotations(mapView.annotations)
        
        switch status {
        case .AuthorizedAlways, .AuthorizedWhenInUse:
            startButton.enabled = true
            endButton.enabled = false
            saveButton.enabled = false
            mapView.userTrackingMode = .Follow
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
    
    /**
     Handle button clicked action
     - parameter sender: the button object who triggered this action
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
        
        // Adjust button states
        startButton.hidden = false
        startButton.enabled = false
        
        endButton.hidden = false
        endButton.enabled = true
        
        cancelButton.hidden = false
        cancelButton.enabled = true
        
        saveButton.hidden = true
        saveButton.enabled = false
    }
    
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
        
        // Adjust button states
        startButton.hidden = false
        startButton.enabled = false
        
        endButton.hidden = false
        endButton.enabled = false
        
        cancelButton.hidden = false
        cancelButton.enabled = true
        
        saveButton.hidden = false
        saveButton.enabled = true
    }
    
    @IBAction func cancelRecording() {
        resetAll()
    }
    
    /**
     Reset all scene attributes to their initial state
     */
    func resetAll() {
        startButton.hidden = false
        startButton.enabled = true
        
        endButton.hidden = true
        endButton.enabled = false
        
        cancelButton.hidden = true
        cancelButton.enabled = false
        
        saveButton.hidden = true
        saveButton.enabled = false
        
        mapView.removeAnnotations(mapView.annotations)
        
        sidewalkStart = nil
        sidewalkStartDroppedPin = nil
        sidewalkEnd = nil
        sidewalkEnd = nil
    }
}
