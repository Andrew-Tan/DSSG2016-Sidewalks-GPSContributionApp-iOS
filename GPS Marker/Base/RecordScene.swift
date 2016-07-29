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
        
        // Setting global configuration for drop down menu
        configureDropDown()
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        // Location manager configuration
        locationManager.delegate = self
        locationManager.requestAlwaysAuthorization()
        
        resetAll()
    }
    
    /**
     Configure global options for drop down
    */
    func configureDropDown() {
        DropDown.appearance().textColor = UIColor.blackColor()
        DropDown.appearance().textFont = UIFont.systemFontOfSize(15)
        DropDown.appearance().backgroundColor = UIColor.whiteColor()
        DropDown.appearance().selectionBackgroundColor = UIColor.lightGrayColor()
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
            jsonLibrary = JSON(["type": "FeatureCollection",
                "features": [],
                "properties": [:]])
        }
        
        return jsonLibrary
    }
    
    /**
     Load JSON object from an Assets.xcassets
     
     - param assetName: The name of the asset
     */
    private func loadAssetJSON(assetName: String) -> JSON {
        if let asset = NSDataAsset(name: assetName) {
            let data = asset.data
            return JSON(data: data)
        } else {
            return nil
        }
    }
    
    /**
     Prepare and show drop down menu for attributes
     
     - param optionName: The name of the option, should have an entry in the format "Options_XXX" in Assets.xcassets
     - param sender: The button who activate this drop down
    */
    func displayDropDown(optionName: String, sender: UIButton) {
        dropDown.hide()
        
        if optionName == "Unknown" {
            dropDown.dataSource = ["Unknow Option"]
            dropDown.selectionAction = { (index: Int, item: String) in
                return
            }
            
            dropDown.show()
            return
        }
        
        let assetJSON = loadAssetJSON("Options_\(optionName)")
        var displayKeySet: [String] = ["Unknown"]
        var dataKeySet: [String] = ["unknown"]
        
        for (displayKey, dataKey) in assetJSON {
            displayKeySet.append(displayKey)
            dataKeySet.append(dataKey.string!)
        }
        
        dropDown.dataSource = displayKeySet
        dropDown.direction = .Top
        dropDown.bottomOffset = CGPoint(x: 0, y: -(dropDown.anchorView as! UIView).bounds.height)

        dropDown.selectionAction = { [unowned self] (index: Int, item: String) in
            sender.setTitle("\(optionName): \(item)", forState: .Normal)
            if item == "Unknown" {
                self.savedProperties[optionName.lowercaseString] = nil
            } else {
                self.savedProperties[optionName.lowercaseString] = dataKeySet[index]
            }
        }
        
        dropDown.show()
    }
    
    /**
     Reset all scene attributes and visible items to their initial state
     */
    func resetAll() {
        saveButton?.enabled = false
    }
    
    /**
     Reset a map view to its initial state
    */
    func resetMap(mapView: MKMapView) {
        mapView.removeAnnotations(mapView.annotations)
        mapView.removeOverlays(mapView.overlays)
        mapView.userTrackingMode = .Follow
        mapView.showsUserLocation = true
    }
    
    /**
     Save recording when user clicked "save" button
     Should be overrieded by future inherited class
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
