//
//  AccountView.swift
//  HypoGuardian
//
//  Created by Adrian Lazaro on 28/10/24.
//

import SwiftUI

struct AccountView: View {
    
    @Environment(HealthKitManager.self) private var healthKitManager
    
    @StateObject var viewModel = AccountViewModel()
    
    @FocusState private var focusedTextField: FormTextField? //It will dismiss the keyboard when nil, aside from making navigation easier
    
    enum FormTextField {
        case firstName, lastName, email
    }
    
    var body: some View {
        
        NavigationView {
            
            Form {
                Section(header: Text("Personal Information")) {
                    TextField("First Name", text: $viewModel.user.firstName)
                        .focused($focusedTextField, equals: .firstName)
                        .onSubmit {
                            focusedTextField = .lastName
                        }
                        .submitLabel(.next)
                        .keyboardType(.namePhonePad)
                        .autocorrectionDisabled()
                    TextField("Last Name", text: $viewModel.user.lastName)   //Tip: On the simulator, Cmd + K to show keyboard
                        .focused($focusedTextField, equals: .lastName)
                        .onSubmit {
                            focusedTextField = .email
                        }
                        .submitLabel(.next)
                        .keyboardType(.namePhonePad)
                        .autocorrectionDisabled()
                    TextField("Email", text: $viewModel.user.email)
                        .focused($focusedTextField, equals: .email)
                        .onSubmit {
                            focusedTextField = nil //Dismiss keyboard
                        }
                        .submitLabel(.done)
                        .keyboardType(.emailAddress)
                        .textInputAutocapitalization(.never)
                        .autocorrectionDisabled()
                    
                    DatePicker("Birthday",
                               selection: $viewModel.user.birthdate,
                               in: Date().oneHundredYearsAgo...Date().fourteenYearsAgo,
                               displayedComponents: .date)
                    Button {
                        viewModel.saveChanges()
                    } label: {
                        Text("Save Changes")
                    }
                }
                
                Section {
                    Toggle("Glucose data generation", isOn: Binding<Bool>(
                        get: { viewModel.user.testingFeaturesEnabled },
                        set: { newValue in
                            if newValue == true && !viewModel.user.testingFeaturesEnabled {
                                // Pedimos confirmación antes de habilitar
                                viewModel.alertItem = AlertContext.enableGeneratedGlucoseConfirmation
                                
                                viewModel.user.testingFeaturesEnabled = true
                                viewModel.saveChangesNoAlert()
                                
                            } else {
                                viewModel.user.testingFeaturesEnabled = false
                                viewModel.saveChangesNoAlert()
                            }
                        })
                    )
                    .toggleStyle(SwitchToggleStyle())
                    .tint(.pink)
                    
                    if (viewModel.user.testingFeaturesEnabled) {
                        Button {
                            Task {
                                await healthKitManager.addMockData()
                            }
                            viewModel.alertItem = AlertContext.mockDataAdded
                        } label: {
                            HStack {
                                Image(systemName: "plus.square.on.square")
                                Text("Generate 7 days of glucose data")
                            }
                            .padding(.vertical, 8)
                            .frame(maxWidth: .infinity)
                            .background(Color.low.opacity(0.1))
                            .foregroundStyle(Color.low)
                            .clipShape(Capsule())
                        }
                        
                        Button {
                            Task {
                                await healthKitManager.deleteMockData()
                            }
                            viewModel.alertItem = AlertContext.mockDataDeleted
                        } label: {
                            HStack {
                                Image(systemName: "trash")
                                Text("Delete generated glucose data")
                            }
                            .padding(.vertical, 8)
                            .frame(maxWidth: .infinity)
                            .background(Color.high.opacity(0.1))
                            .foregroundStyle(Color.high)
                            .clipShape(Capsule())
                        }
                    }
                    
                } header: {
                    Text("Testing Utilities")
                }
                
            }
            .navigationBarTitle("Account")
            .toolbar {
                ToolbarItemGroup(placement: .keyboard) {
                    Button("Dismiss") { focusedTextField = nil }
                }
            }
        }
        .tint(.pink)
        .onAppear {
            viewModel.retrieveUser()
        }
        .alert(item: $viewModel.alertItem) { alertItem in
            Alert(title: alertItem.title,
                  message: alertItem.message,
                  dismissButton: alertItem.dismissButton)
        }
    }
}

#Preview {
    AccountView()
        .environment(HealthKitManager())
}
