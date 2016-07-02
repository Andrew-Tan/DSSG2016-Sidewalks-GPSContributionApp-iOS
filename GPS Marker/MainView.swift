//
//  ViewController.swift
//  GPS Marker
//
//  Created by Andrew Tan on 6/29/16.
//  Copyright © 2016 Taskar Center for Accessible Technology. All rights reserved.
//

import UIKit
import CoreLocation
import MapKit

class MainView: UIViewController, CLLocationManagerDelegate {
    
    // Button stack
    @IBOutlet weak var buttonStack: UIStackView!
    
    // Label
    @IBOutlet weak var longLabel: UILabel!
    @IBOutlet weak var latLabel: UILabel!
    @IBOutlet weak var altLabel: UILabel!
    @IBOutlet weak var horizontalAccuracy: UILabel!
    @IBOutlet weak var verticalAccuracy: UILabel!
    
    // Location Service
    let locationManager = CLLocationManager()
    var currentDroppedPin: MKPointAnnotation?
    var updateTimer: NSTimer!
    
    // Activity Indicator
    @IBOutlet weak var activityIndicator: UIActivityIndicatorView!
    
    // GeoJSON file location
    var fileManager: NSFileManager?
    let sidewalkFilePath = NSSearchPathForDirectoriesInDomains(.DocumentDirectory, .UserDomainMask, true)[0] + "/sidewalk-collection.json"
    let curbrampFilePath = NSSearchPathForDirectoriesInDomains(.DocumentDirectory, .UserDomainMask, true)[0] + "/curbramp-collection.json"
    
    override func viewDidLoad() {
        super.viewDidLoad()
        self.title = "GPS Marker"
        navigationController?.navigationBar.barTintColor = UIColor.yellowColor()
        navigationController?.navigationBar.titleTextAttributes = [NSForegroundColorAttributeName: UIColor.blackColor()]
        
        // Location manager configuration
        locationManager.delegate = self
        locationManager.requestAlwaysAuthorization()
    }
    
    override func viewDidAppear(animated: Bool) {
        super.viewDidAppear(animated)
        
        // Start timer: Update GPS info periodcally
        updateGPSInfo()
        updateTimer = NSTimer.scheduledTimerWithTimeInterval(2, target: self, selector: #selector(updateGPSInfo), userInfo: nil, repeats: true)
    }
    
    override func viewDidDisappear(animated: Bool) {
        super.viewDidDisappear(animated)
        
        // Stop timer
        updateTimer.invalidate()
    }
    
    /**
     Get current GPS information from location manager and update displaying labels
     */
    func updateGPSInfo() {
        if let current = locationManager.location {
            let coordinate = current.coordinate
            longLabel.text = "Long: \(coordinate.longitude) degree"
            latLabel.text = "Lat: \(coordinate.latitude) degree"
            altLabel.text = "Alt: \(current.altitude) meters"
            horizontalAccuracy.text = "Horizontal: \(current.horizontalAccuracy) meters"
            verticalAccuracy.text = "Vertical: \(current.verticalAccuracy) meters"
        }
    }
    
    /**
     Display a message window
     */
    func displayMessage(title: String, message: String) {
        let alertController = UIAlertController(
            title: title,
            message: message,
            preferredStyle: .Alert)
        let dismissAction = UIAlertAction(title: "Dismiss", style: .Cancel, handler: nil)
        alertController.addAction(dismissAction)
        self.presentViewController(alertController, animated: true, completion: nil)
    }
    
    /**
     Delete all cache stored on phone
     - parameter displayMsg: a switch indicate whether to give a prompt after procedure is completed (If the deleting process fails, a prompt will be given regardless of this parameter)
     */
    func invalidateCache(displayMsg: Bool) {
        if fileManager == nil {
            fileManager = NSFileManager()
        }
        
        do {
            try fileManager!.removeItemAtPath(sidewalkFilePath)
            try fileManager!.removeItemAtPath(curbrampFilePath)
        } catch {
            if displayMsg {
                displayMessage("SUCCESS", message: "Nothing is in cache")
            }
            return
        }
        
        if displayMsg {
            displayMessage("SUCCESS", message: "Cache is deleted")
        }
    }
    
    /**
     Upload all recorded data to the cloud
     */
    func uploadData() {
        // TODO: Upload data to the cloud
    }
    
    
    // MARK:- Action
    
    /**
     Handle button clicked action
     - parameter sender: the button object who triggered this action
     */
    @IBAction func buttonClicked(sender: UIButton) {
        switch sender.tag {
        case 0:
            // Sidewalk button get clicked
            performSegueWithIdentifier("sidewalkSceneSegue", sender: sender)
            break
        case 1:
            // Curbramp button get clicked
            performSegueWithIdentifier("curbrampSceneSegue", sender: sender)
            break
        case 2:
            displayMessage("UNDER DEVELOPMENT", message: "Please check back later :)")
            break
        case 3:
            // Upload Data button get clicked
            // Upload data
            activityIndicator.startAnimating()
            uploadData()
            activityIndicator.stopAnimating()
            // Delete Cache
            invalidateCache(false)
            break
        case 4:
            // Clear Cache get clicked
            // Ask user again
            let alertController = UIAlertController(
                title: "DELETE CACHE",
                message: "Are you sure? Unuploaded entries will be deleted!",
                preferredStyle: .Alert)
            let dismissAction = UIAlertAction(title: "Cancel", style: .Cancel, handler: nil)
            alertController.addAction(dismissAction)
            let confirmAction = UIAlertAction(title: "DELETE!", style: .Destructive, handler: {(alert: UIAlertAction!) in self.invalidateCache(true)})
            alertController.addAction(confirmAction)
            self.presentViewController(alertController, animated: true, completion: nil)
            break
        default:
            NSLog("Undefined Caller")
            break
        }
    }
    
    //MARK:- CLLocationManagerDelegate methods
    
    /**
     Handle different cases when location authorization status changed
     
     - parameter manager: the CLLocationManager
     - parameter status: the current status of location authorization
     */
    func locationManager(manager: CLLocationManager, didChangeAuthorizationStatus status: CLAuthorizationStatus) {
        
        switch status {
        case .AuthorizedAlways, .AuthorizedWhenInUse:
            buttonStack.hidden = false
        case .NotDetermined:
            buttonStack.hidden = true
            manager.requestAlwaysAuthorization()
        case .Restricted, .Denied:
            buttonStack.hidden = true
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
}

