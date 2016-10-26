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
    
    override func viewDidAppear(_ animated: Bool) {
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
        if lineStart == nil {
            return
        }
        
        handleDrawPin(mapView, point: lineStart!, status: "start")
    }
    
    fileprivate func handleDrawPin(_ mapView: MKMapView, point: CLLocation, status: String) {
        // An annotation is created at the current coordinates with the MKPointAnnotaition class. The annotation is added to the Map View with the addAnnotation method.
        
        if point.horizontalAccuracy < 11 {
            if status == "start" {
                if lineStartDroppedPin != nil {
                    mapView.removeAnnotation(lineStartDroppedPin!)
                    lineStartDroppedPin = nil
                }
                self.lineStartDroppedPin = self.dropPinOnMap(mapView, locationPoint: point, title: "Start")
                afterRecordStartClicked()
            } else if status == "end" {
                if lineEndDroppedPin != nil {
                    mapView.removeAnnotation(lineStartDroppedPin!)
                    lineEndDroppedPin = nil
                }
                self.lineEndDroppedPin = self.dropPinOnMap(mapView, locationPoint: point, title: "End")
                self.afterRecordEndClicked()
            }
        } else {
            let alertController = UIAlertController(
                title: "Warning",
                message: "Current horizontal accuracy is \(point.horizontalAccuracy) meters, which is not accurate enough, do you want to try again?",
                preferredStyle: .alert)
            
            let dismissAction = UIAlertAction(title: "No, go on!", style: .default, handler: { (alert: UIAlertAction!) in
                if status == "start" {
                    if self.lineStartDroppedPin != nil {
                        mapView.removeAnnotation(self.lineStartDroppedPin!)
                        self.lineStartDroppedPin = nil
                    }
                    self.lineStartDroppedPin = self.dropPinOnMap(mapView, locationPoint: point, title: "Start")
                    self.afterRecordStartClicked()
                } else if status == "end" {
                    if self.lineEndDroppedPin != nil {
                        mapView.removeAnnotation(self.lineEndDroppedPin!)
                        self.lineEndDroppedPin = nil
                    }
                    self.lineEndDroppedPin = self.dropPinOnMap(mapView, locationPoint: point, title: "End")
                    self.afterRecordEndClicked()
                }
            })
            alertController.addAction(dismissAction)
            
            let retryAction = UIAlertAction(title: "Yes, retry!", style: .default, handler: nil)
            alertController.addAction(retryAction)
            
            self.present(alertController, animated: true, completion: nil)
        }
    }
    
    fileprivate func afterRecordStartClicked() {
        // Adjust button visiblities
        startButton.isHidden = false
        startButton.isEnabled = false
        
        endButton.isHidden = false
        endButton.isEnabled = true
        
        cancelButton.isHidden = false
        cancelButton.isEnabled = true
        
        saveButton.isEnabled = false
    }
    
    /**
     End recording when user clicked "line end" button
     */
    @IBAction func lineRecordEnd() {
        // Get current location
        self.lineEnd = locationManager.location
        if lineEnd == nil {
            return
        }
        
        handleDrawPin(mapView, point: lineEnd!, status: "end")
    }
    
    fileprivate func afterRecordEndClicked() {
        // Stop map user tracking mode
        mapView.userTrackingMode = .none
        mapView.showsUserLocation = false
        
        if lineStart == nil || lineEnd == nil {
            NSLog("nil value found for line recording scene")
            NSLog("line Start: \(lineStart)")
            NSLog("line End: \(lineEnd)")
            return
        }
        
        // Draw a line between start and end coordinate
        // TODO: remember to check back
        let points = [self.lineStart!.coordinate, self.lineEnd!.coordinate]
        let geodesic = MKGeodesicPolyline(coordinates: points, count:2 )
        self.mapView.add(geodesic)
        
        // Adjust button visibilities
        startButton.isHidden = false
        startButton.isEnabled = false
        
        endButton.isHidden = false
        endButton.isEnabled = false
        
        cancelButton.isHidden = false
        cancelButton.isEnabled = true
        
        saveButton.isEnabled = true
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
                                          "coordinates": [[startCoordinate.longitude, startCoordinate.latitude],
                                                          [endCoordinate.longitude, endCoordinate.latitude]]],
                             "properties": self.savedProperties]]
            
            // Concatenate the new entry with old entries
            lineJSONLibrary!["features"] = JSON(lineJSONLibrary!["features"].arrayObject! + JSON(newEntry).arrayObject!)
            
            do {
                // try lineJSONLibrary?.rawData().writeToFile(lineFilePath, atomically: true)
                
                // TODO: check syntax
                if let url_path = URL(string: lineFilePath) {
                    try lineJSONLibrary?.rawData().write(to: url_path)
                } else {
                    print("Cannot get url from line path")
                }
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
        startButton.isHidden = false
        startButton.isEnabled = true
        
        endButton.isHidden = true
        endButton.isEnabled = false
        
        cancelButton.isHidden = true
        cancelButton.isEnabled = false
        
        // reset all recording variables
        lineStart = nil
        lineStartDroppedPin = nil
        lineEnd = nil
        lineEnd = nil
    }
    
    
    //MARK:- CLLocationManagerDelegate methods
    
    override func locationServiceDisabled(_ manager: CLLocationManager) {
        super.locationServiceDisabled(manager)
        
        startButton.isEnabled = false
        endButton.isEnabled = false
        mapView.userTrackingMode = .none
    }
    
    override func locationServiceNotDetermined(_ manager: CLLocationManager) {
        super.locationServiceDisabled(manager)
        
        startButton.isEnabled = false
        endButton.isEnabled = false
        mapView.userTrackingMode = .none
    }
    
}
