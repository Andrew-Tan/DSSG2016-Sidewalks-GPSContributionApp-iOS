//
//  UserLogin.swift
//  GPS Marker
//
//  Created by Andrew Tan on 7/8/16.
//  Copyright © 2016 Taskar Center for Accessible Technology. All rights reserved.
//

import UIKit
import SwiftyJSON

class UserLoginScene: UIViewController {
    
    var fileManager = NSFileManager()
    let userCredentialFilePath = NSSearchPathForDirectoriesInDomains(.DocumentDirectory, .UserDomainMask, true)[0] + "/user-credential.json"
    var userCredentialJSON: JSON?
    
    // MARK:- Properties
    @IBOutlet weak var userID: UITextField!
    @IBOutlet weak var IDType: UISegmentedControl!
    @IBOutlet weak var emailAddress: UITextField!
    
    override func viewDidLoad() {
        super.viewDidLoad()
        self.title = "User Credential"
        
        // Load User Credential From File & Check if file already exist
        if let JSON_Data = NSData(contentsOfFile: userCredentialFilePath) {
            // File Avaliable, fetch from document
            userCredentialJSON = JSON(data: JSON_Data)
            userID.text = userCredentialJSON!["UserID"].description
            
            if userCredentialJSON!["IDType"].description == "Arbitrary" {
                IDType.selectedSegmentIndex = 0
            } else {
                IDType.selectedSegmentIndex = 1
            }
            
            emailAddress.text = userCredentialJSON!["Email"].description
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
    
    // MARK:- Action
    @IBAction func saveCredential() {
        
        var credential = ["UserID": "", "IDType": "", "Email": ""]
        
        if let userIDEntry = userID.text {
            if userIDEntry != "" {
                credential["UserID"] = userIDEntry
            } else {
                displayMessage("Error", message: "Do not leave user ID blank")
                return
            }
        } else {
            displayMessage("Error", message: "Do not leave user ID blank")
            return
        }
        
        let IDTypeEntry = IDType.selectedSegmentIndex
        if IDTypeEntry == 0 {
            credential["IDType"] = "Arbitrary"
        } else {
            credential["IDType"] = "OSM"
        }
        
        if let emailAddressEntry = emailAddress.text {
            credential["Email"] = emailAddressEntry
        } else {
            credential["Email"] = ""
        }
        
        do {
            userCredentialJSON = JSON(credential)
            try userCredentialJSON!.rawData().writeToFile(userCredentialFilePath, atomically: true)
        } catch {
            displayMessage("Save Failed", message: "Unable to Save")
            return
        }
        
        credential["Platform"] = "iOS"
        
        displayMessage("Success", message: "Credential Saved")
        print("\(userCredentialJSON)")
    }
}