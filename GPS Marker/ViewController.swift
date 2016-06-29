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

class ViewController: UIViewController, CLLocationManagerDelegate {
    
    @IBOutlet weak var mapView: MKMapView!
    @IBOutlet weak var buttonStack: UIStackView!
    @IBOutlet weak var longLabel: UILabel!
    @IBOutlet weak var latLabel: UILabel!
    @IBOutlet weak var horizontalAccuracy: UILabel!
    @IBOutlet weak var verticalAccuracy: UILabel!
    
    let locationManager = CLLocationManager()
    var currentDroppedPin : MKPointAnnotation?
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        // Location Manager
        locationManager.delegate = self
        locationManager.requestAlwaysAuthorization()
    }
    
    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }
    
    func locationManager(manager: CLLocationManager, didChangeAuthorizationStatus status: CLAuthorizationStatus) {
        
        switch status {
        case .AuthorizedAlways, .AuthorizedWhenInUse:
            buttonStack.hidden = false
            mapView.userTrackingMode = .Follow
        case .NotDetermined:
            buttonStack.hidden = true
            mapView.userTrackingMode = .None
            manager.requestAlwaysAuthorization()
        case .Restricted, .Denied:
            buttonStack.hidden = true
            mapView.userTrackingMode = .None
            let alertController = UIAlertController(
                title: "Background Location Access Disabled",
                message: "In order to record location informaition you reported, please open this app's settings and set location access to 'Always'.",
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
    
    @IBAction func getLocation(sender: UIButton) {
        let currentLocation = locationManager.location
        
        longLabel.text = "Long: \(currentLocation!.coordinate.longitude)"
        latLabel.text = "Lat: \(currentLocation!.coordinate.latitude)"
        horizontalAccuracy.text = "Horizontal: \(currentLocation!.horizontalAccuracy) meters"
        verticalAccuracy.text = "Vertical: \(currentLocation!.verticalAccuracy) meters"
        
        // Set Mapview
        // The span value is made relative small, so a big portion of London is visible. The MKCoordinateRegion method defines the visible region, it is set with the setRegion method.
        let span = MKCoordinateSpanMake(0.001, 0.001)
        let region = MKCoordinateRegion(center: currentLocation!.coordinate, span: span)
        mapView.setRegion(region, animated: true)
        
        // An annotation is created at the current coordinates with the MKPointAnnotaition class. The annotation is added to the Map View with the addAnnotation method.
        if currentDroppedPin != nil {
            mapView.removeAnnotation(currentDroppedPin!)
            currentDroppedPin = nil
        }
        
        currentDroppedPin = MKPointAnnotation()
        currentDroppedPin!.coordinate = currentLocation!.coordinate
        currentDroppedPin!.title = "Button 1 Report Location"
        // currentDroppedPin!.subtitle = "London"
        mapView.addAnnotation(currentDroppedPin!)
    }
}

