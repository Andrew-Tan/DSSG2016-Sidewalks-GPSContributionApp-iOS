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
import DropDown

class RecordScene: UIViewController, CLLocationManagerDelegate, MKMapViewDelegate {
    
    // Buttons
    var saveButton: UIBarButtonItem!
    
    // Location Service
    var locationManager: CLLocationManager!
    
    // Drop down menu
    let dropDown = DropDown()
    var savedProperties: [String: String] = [:]
    
    required init?(coder aDecoder: NSCoder) {
        super.init(coder: aDecoder)
        
        locationManager = CLLocationManager()
        
        // Define Save Button on the navigation bar
        navigationItem.rightBarButtonItem = UIBarButtonItem(title: "Save", style: .Plain, target: self, action: #selector(saveRecording))
        saveButton = navigationItem.rightBarButtonItem
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        // Location manager configuration
        locationManager.delegate = self
        locationManager.requestAlwaysAuthorization()
        
        resetAll()
    }
    
    func loadData(jsonFilePath: String) -> JSON {
        // Load GeoJSON file or create a new one
        // Check if file already exist
        var jsonLibrary: JSON
        
        if let JSON_Data = NSData(contentsOfFile: jsonFilePath) {
            // File Avaliable, fetch from document
            jsonLibrary = JSON(data: JSON_Data)
        } else {
            // File Not Avaliable, create new library
            jsonLibrary = JSON(["type": "FeatureCollection", "features": []])
        }
        
        return jsonLibrary
    }
    
    func loadAssetJSON(assetName: String) -> JSON {
        if let asset = NSDataAsset(name: assetName) {
            let data = asset.data
            return JSON(data: data)
        } else {
            return nil
        }
    }
    
    func displayDropDown(optionName: String, sender: UIButton) {
        dropDown.hide()
        
        let assetJSON = loadAssetJSON("Options_\(optionName)")
        var displayKeySet: [String] = []
        var dataKeySet: [String] = []
        
        for (displayKey, dataKey) in assetJSON {
            displayKeySet.append(displayKey)
            dataKeySet.append(dataKey.string!)
        }
        
        dropDown.dataSource = displayKeySet
        
        dropDown.selectionAction = { [unowned self] (index: Int, item: String) in
            sender.setTitle("\(optionName): \(item)", forState: .Normal)
            self.savedProperties[optionName.lowercaseString] = dataKeySet[index]
            print("Current Saved Options: \(self.savedProperties)")
        }
        
        dropDown.show()
    }
    
    /**
     Reset all scene attributes and visible items to their initial state
     */
    func resetAll() {
        // reset button visibility
        saveButton?.enabled = false
    }
    
    func resetMap(mapView: MKMapView) {
        mapView.removeAnnotations(mapView.annotations)
        mapView.removeOverlays(mapView.overlays)
        mapView.userTrackingMode = .Follow
        mapView.showsUserLocation = true
    }
    
    /**
     Save recording when user clicked "save" button
     */
    func saveRecording() {
        return
    }
    
    func showSaveSuccessAlert(success: Bool) {
        
        var title: String
        var msg: String
        if success {
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
        let dismissAction = UIAlertAction(title: "OK", style: .Default, handler: nil)
        alertController.addAction(dismissAction)
        self.presentViewController(alertController, animated: true, completion: nil)
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
