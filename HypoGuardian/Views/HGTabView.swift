//
//  HGTabView.swift
//  HypoGuardian
//
//  Created by Adrian Lazaro on 28/10/24.
//

import SwiftUI

struct HGTabView: View {
    
    var body: some View {
        
        TabView {
            Group {
                
                TodayView()
                    .tabItem {Label("Today", systemImage: "drop")}
                
                PredictionsView()
                    .tabItem {Label("Predictions", systemImage: "waveform.path.ecg")}
                
                LogView()
                    .tabItem {Label("Log", systemImage: "heart.text.square.fill")}
                
                AccountView()
                    .tabItem {Label("Account", systemImage: "person")}
            }
        }
        .tint(.pink)
    }
}

#Preview {
    HGTabView()
        .environment(HealthKitManager())
}
