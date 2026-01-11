//
//  Alerts.swift
//  HypoGuardian
//
//  Created by Adrian Lazaro on 28/10/24.
//

import SwiftUI

struct AlertItem: Identifiable {
    let id: UUID = UUID()
    let title: Text
    let message: Text  //Alerts will take a Text object not a String
    let dismissButton: Alert.Button
}

struct AlertContext {
    //MARK: - Account Related Alerts
    static let fillAllFields     = AlertItem(title: Text("Empty Fields"),
                                             message: Text("Please fill out all fields"),
                                             dismissButton: .default(Text("OK")))
    
    static let invalidEmail      = AlertItem(title: Text("Invalid Email"),
                                             message: Text("Please enter a valid email"),
                                             dismissButton: .default(Text("OK")))
    
    static let userSaveSuccess   = AlertItem(title: Text("Account Saved"),
                                             message: Text("Your account information has been saved successfully"),
                                             dismissButton: .default(Text("OK")))
    
    static let invalidUserData   = AlertItem(title: Text("Account Error"),
                                             message: Text("There was an error saving or retrieving your profile"),
                                             dismissButton: .default(Text("OK")))
    //MARK: - Add Glucose Data related Alerts
    static let glucoseSaveSuccess   = AlertItem(title: Text("Glucose Saved"),
                                                message: Text("Your glucose data has been saved successfully"),
                                                dismissButton: .default(Text("OK")))
    static let invalidGlucoseData   = AlertItem(title: Text("Invalid data"),
                                                message: Text("The glucose value must be between 50 and 400"),
                                                dismissButton: .default(Text("OK")))
    static let glucoseSaveError    = AlertItem(title: Text("Error"),
                                               message: Text("There was an error saving your glucose data"),
                                               dismissButton: .default(Text("OK")))
    //MARK: - Predictions Related Alerts
    static let notEnoughData = AlertItem(
            title: Text("Not Enough Glucose Data"),
            message: Text("There is not enough glucose data from the past 24 hours to make a prediction."),
            dismissButton: .default(Text("OK"))
        )
    
    static let networkErrorOnPrediction = AlertItem(
        title: Text("Oops…"),
        message: Text("We couldn’t get your prediction. Please try again later."),
        dismissButton: .default(Text("OK"))
    )
    
    static let confirmationUnderstandExperimental = AlertItem(
        title: Text("Disclaimer"),
        message: Text("This app uses an experimental AI model. Results are not medical advice and must not guide medical decisions."),
        dismissButton: .default(Text("Yes, I understand"))
    )
    
    //MARK: - Debug/Testing Related Alerts
    static let enableGeneratedGlucoseConfirmation = AlertItem(title: Text("Enable Glucose Data Generation?"), message: Text("This feature is intended for non-diabetic users or testing purposes. \n Fictitious glucose data will be generated and saved to Apple Health. \n Are you sure you want to enable this feature? "), dismissButton: .default(Text("Yes, I know what I am doing")))
    
    static let mockDataAdded     = AlertItem(title: Text("Mock Glucose Added"),
                                             message: Text("Mock glucose data added successfully"),
                                             dismissButton: .default(Text("OK")))
    static let mockDataDeleted   = AlertItem(title: Text("Glucose data deleted"),
                                             message: Text("Glucose data deleted successfully"),
                                             dismissButton: .default(Text("OK")))
}
