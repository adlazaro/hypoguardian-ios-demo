//
//  User.swift
//  HypoGuardian
//
//  Created by Adrian Lazaro on 28/10/24.
//

import Foundation

struct User: Codable { //When Storing a Custom Object in AppStorge/UserDefaults it needs to conform to Codable
    
    var firstName       = ""
    var lastName        = ""
    var email           = ""
    var birthdate       = Date()
    var testingFeaturesEnabled    = false
}
