//
//  HypoGuardianApp.swift
//  HypoGuardian
//
//  Created by Adrian Lazaro on 28/10/24.
//

import SwiftUI
import SwiftData

@main
struct HypoGuardianApp: App {
    
    let healthKitManager = HealthKitManager()
    
    var body: some Scene {
        WindowGroup {
            HGTabView().environment(healthKitManager)
        }
        .modelContainer(for: Prediction.self) //Model definition (SwiftData)
    }
}
