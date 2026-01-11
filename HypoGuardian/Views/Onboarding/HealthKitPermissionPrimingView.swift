//
//  HealthKitPermissionPrimingView.swift
//  HypoGuardian
//
//  Created by Adrian Lazaro on 28/10/24.
//

import SwiftUI
import HealthKitUI

struct HealthKitPermissionPrimingView: View {
    
    @Environment(HealthKitManager.self) private var healthKitManager
    @State private var isShowingHealthKitPermissions = false
    
    @Binding var hasSeen: Bool
    @Environment(\.dismiss) private var dismiss
    
    var description = """
    This app needs to sync your Blood Glucose data with Apple Health.

    You can also add new glucose entries from the app. Your data is private and secured.
    """
    
    var body: some View {
        
        VStack (spacing: 110){
            
            VStack (alignment: .center, spacing: 12) {
                Image(.appleHealth)
                    .resizable()
                    .frame(width: 90, height: 90)
                    .shadow(color: .gray.opacity(0.3), radius: 16)
                    .padding(.bottom, 12)
                
                Text("Apple Health Integration")
                    .font(.title2)
                    .bold()
                
                Text(description)
                    .foregroundStyle(.secondary)
                    .font(.body)
                    .multilineTextAlignment(.center)
            }
            
            Button {
                isShowingHealthKitPermissions = true
            } label: {
                Text("Connect")
                    .font(.title3)
                    .bold()
                    .frame(width: 210)
            }
            .buttonStyle(.borderedProminent)
            .controlSize(.extraLarge)
            .tint(.pink)
            
        }
        .padding(30)
        .interactiveDismissDisabled() // Make unable to swipe down (important)
        .onAppear {
            hasSeen = true
        }
        .healthDataAccessRequest(store: healthKitManager.healthStore,  //This modifier requires iOS 17
                                 shareTypes: [healthKitManager.glucoseHealthType],
                                 readTypes: [healthKitManager.glucoseHealthType],
                                 trigger: isShowingHealthKitPermissions) { result in
            switch result {
            case .success(_):
                dismiss()
            case .failure(_):
                //Handle the error later
                dismiss()
            }
        }
    }
}

#Preview {
    HealthKitPermissionPrimingView(hasSeen: .constant(false))
        .environment(HealthKitManager())
}

// Clear Previews Cache (on project directory)
// sudo xcode-select -s /Applications/Xcode.app
// xcrun simctl --set previews delete all
