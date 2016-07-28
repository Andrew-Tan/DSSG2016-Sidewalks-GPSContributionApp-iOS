//
//  RecordScene.swift
//  GPS Marker
//
//  Created by Andrew Tan on 7/27/16.
//  Copyright © 2016 Taskar Center for Accessible Technology. All rights reserved.
//

import UIKit
import CoreLocation
import MapKit
import SwiftyJSON

class RecordScene: UIViewController, CLLocationManagerDelegate, MKMapViewDelegate {
    
    // Buttons
    var saveButton: UIBarButtonItem?
    
    // Location Service
    let locationManager = CLLocationManager()
    
    // File System
    var jsonFilePath: String!
    var jsonLibrary: JSON!
    
    required init?(coder aDecoder: NSCoder) {
        super.init(coder: aDecoder)
        
        // Load GeoJSON file or create a new one
        // Check if file already exist
        if let JSON_Data = NSData(contentsOfFile: self.jsonFilePath) {
            // File Avaliable, fetch from document
            jsonLibrary = JSON(data: JSON_Data)
        } else {
            // File Not Avaliable, create new library
            jsonLibrary = JSON(["type": "FeatureCollection", "features": []])
        }
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        // Define Save Button on the navigation bar
        navigationItem.rightBarButtonItem = UIBarButtonItem(title: "Save", style: .Plain, target: self, action: #selector(saveRecording))
        saveButton = navigationItem.rightBarButtonItem
        
        // Location manager configuration
        locationManager.delegate = self
        locationManager.requestAlwaysAuthorization()
        
        resetAll()
    }
    
    /**
     Reset all scene attributes and visible items to their initial state
     */
    func resetAll() {
        // reset button visibility
        saveButton?.enabled = false
    }
    
    /**
     Save recording when user clicked "save" button
     */
    func saveRecording() {
        resetAll()
    }
    
    //MARK:- CLLocationManagerDelegate methods
    
    func locationServiceEnabled(manager: CLLocationManager) {
        resetAll()
    }
    
    func locationServiceDisabled(manager: CLLocationManager) {
        saveButton?.enabled = false
        
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
    
    func locationServiceNotDetermined(manager: CLLocationManager) {
        saveButton?.enabled = false
        manager.requestAlwaysAuthorization()
    }
    
    /**
     Handle different cases when location authorization status changed
     
     - parameter manager: the CLLocationManager
     - parameter status: the current status of location authorization
     */
    func locationManager(manager: CLLocationManager, didChangeAuthorizationStatus status: CLAuthorizationStatus) {
        
        switch status {
        case .AuthorizedAlways, .AuthorizedWhenInUse:
            locationServiceEnabled(manager)
        case .NotDetermined:
            locationServiceNotDetermined(manager)
        case .Restricted, .Denied:
            locationServiceDisabled(manager)
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
