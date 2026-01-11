//
//  AccountViewModel.swift
//  HypoGuardian
//
//  Created by Adrian Lazaro on 28/10/24.
//

import SwiftUI

final class AccountViewModel: ObservableObject {
    
    @AppStorage("user") private var userData: Data? //User Defaluts Data saved at key "user". It gets deleted when the app gets deleted
    
    @Published var user = User()
    
    @Published var alertItem: AlertItem?
    
    func saveChanges() {
        guard isValidForm else { return }
        
        do {
            let data = try JSONEncoder().encode(user)
            userData = data
            alertItem = AlertContext.userSaveSuccess
        } catch {
            alertItem = AlertContext.invalidUserData
        }
    }
    
    //This function will be called on change of the switch
    func saveChangesNoAlert() {
        guard isValidForm else { return }
        
        do {
            let data = try JSONEncoder().encode(user)
            userData = data
        } catch {
            //Nothing
        }
    }
    
    func retrieveUser() {
        //Ensure userData in User Defaults is not nil
        guard let userData else { return }
        
        do {
            user = try JSONDecoder().decode(User.self, from: userData)
        } catch {
            alertItem = AlertContext.invalidUserData
        }
    }
    
    //Text validation
    var isValidForm: Bool {
        guard !user.firstName.isEmpty && !user.lastName.isEmpty && !user.email.isEmpty else { //guard not empty and continue, else return false
            
            alertItem = AlertContext.fillAllFields
            return false
        }
        
        guard user.email.isValidEmail else {   //String.isValidEmail is an extension for String that checks against a Regular Expression (need to import)
            alertItem = AlertContext.invalidEmail
            return false
        }
        
        return true
    }
    
   
    
}
