//
//  PredictionsView.swift
//  HypoGuardian
//
//  Created by Adrian Lazaro on 28/10/24.
//

import SwiftUI
import Charts

struct PredictionsView: View {

    @Environment(HealthKitManager.self) private var healthKitManager
    @Environment(\.modelContext) private var modelContext
    @State private var isLoading = false
    @State private var predictionResponse: PredictionResponse?
    @State private var isShowingDisclaimer = false
    @State private var prediction: Prediction?
    @State private var isShowingPredictionResponse = false
    @State private var isShowingSettings = false
    @State private var alertItem: AlertItem?

    private let waveletService = WaveletImageService()

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: 20) {
                
                    if isLoading {
                        VStack(spacing: 15) {
                            ProgressView()
                                .progressViewStyle(CircularProgressViewStyle(tint: .pink))
                                .scaleEffect(2.0) // Aumenta el tamaño del círculo de carga
                                .padding(.top, 60)

                            Text("Processing your data, this may take a few seconds…")
                                .font(.body)
                                .foregroundColor(.gray)
                                .multilineTextAlignment(.center)
                                .padding(.horizontal)
                        }
                    } else {
                        Image(.doctors)
                            .resizable()
                            .frame(width: 315, height: 223)
                            .padding(.top, 25)
                            
                        
                        Text("Tap the button to get a prediction of hypoglycemia in the next 24 hours.")
                            .font(.callout)
                            .foregroundColor(.secondary)
                            .multilineTextAlignment(.center)
                            .padding(.top, 40)
                        
                        Spacer()
                        
                        Button {
                            // Mostrar disclaimer antes de predecir
                            isShowingDisclaimer = true
                        } label: {
                            Text("Predict")
                                .font(.title3)
                                .bold()
                                .frame(width: 210)
                        }
                        .buttonStyle(.borderedProminent)
                        .controlSize(.extraLarge)
                        .tint(.pink)
                    }
                }
                .padding()
            }
            .navigationTitle("Hypo Predictions")
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    NavigationLink {
                            PredictionSettingsView()
                        } label: {
                            Image(systemName: "gearshape")
                                .font(.system(size: 22))
                                .foregroundColor(.pink)
                        }
                        .accessibilityLabel("Settings")
                    }
                }
        }
        .sheet(isPresented: $isShowingPredictionResponse) {
            PredictionResultView(prediction: prediction)
        }
        .alert("Disclaimer", isPresented: $isShowingDisclaimer) {
            Button("Agree & continue") {
                Task { await getPrediction() }
            }
        } message: {
            Text("This app uses an experimental AI model. Results are not medical advice and must not guide medical decisions.")
        }
        .alert(item: $alertItem) { alertItem in
            Alert(title: alertItem.title,
                  message: alertItem.message,
                  dismissButton: alertItem.dismissButton)
        }
    }
    
    func getPrediction() async {

        do {
            let glucoseSamples = try await healthKitManager.fetchGlucoseDataLastDay()

            guard let glucoseValues = healthKitManager.makeValidatedSeries(from: glucoseSamples) else {
                isLoading = false
                alertItem = AlertContext.notEnoughData
                print("Not enough glucose data in the last 24 hours: \(glucoseSamples.count)")
                return
            }
            
            isLoading = true

            // Inferencia local con Core ML (en background)
            let service = try PredictionService()
            let result = try await Task.detached(priority: .userInitiated) {
                try service.predict(glucose: glucoseValues.map { Float($0) })
            }.value
            
            // Espera artificial de 1 segundo para que se vea el loading
            try await Task.sleep(for: .seconds(1))

            await MainActor.run {
                self.isLoading = false

                // Usamos PredictionResponse para mostrar la UI
                self.predictionResponse = PredictionResponse(
                    hypo_predicted: result.hypoPredicted,
                    confidence: Int(result.confidence * 100)
                )
                self.isShowingPredictionResponse = true

                // Guardado en el model
                let newPrediction = Prediction(hypoPredicted: result.hypoPredicted,
                                               confidence: Double(result.confidence * 100))
                self.modelContext.insert(newPrediction)
                self.prediction = newPrediction

                print("Predicción local y guardada: hypo=\(result.hypoPredicted), conf=\(result.confidence)")
            }

        } catch {
            await MainActor.run {
                self.alertItem = AlertContext.networkErrorOnPrediction
                self.isLoading = false
            }
            print("Error al obtener datos de glucosa o predecir: \(error.localizedDescription)")
        }
    }
}

struct PredictionResultView: View {
    var prediction: Prediction?
    @Environment(\.dismiss) private var dismiss
    @State private var showInfo: Bool = false

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: 30) {
                    // Estado de la predicción
                    HStack {
                        Image(systemName: prediction?.hypoPredicted == true ? "exclamationmark.triangle.fill" : "checkmark.circle.fill")
                            .font(.largeTitle)
                            .foregroundColor(prediction?.hypoPredicted == true ? .high : .inRange)
                        
                        Text(prediction?.hypoPredicted == true ? "Hypoglycemia Predicted" : "No Hypoglycemia predicted")
                            .font(.title2)
                            .fontWeight(.semibold)
                            .foregroundStyle(prediction?.hypoPredicted == true ? .high : .inRange)
                    }
                    .padding(.top)

                    // Medidor semicircular de confianza
                    SemiDonutConfidenceChart(confidence: prediction?.confidence ?? 90, hypo: prediction?.hypoPredicted ?? false)
                    
                    // Disclaimer
                    VStack(alignment: .leading, spacing: 8) {
                        Label {
                            Text("Important")
                                .font(.headline)
                        } icon: {
                            Image(systemName: "exclamationmark.bubble")
                                .foregroundColor(.pink)
                        }

                        Text("This app uses an experimental AI model and is not a substitute for professional medical advice. Always consult your doctor and pay attention to your symptoms.")
                            .font(.footnote)
                            .foregroundStyle(.secondary)
                    }
                    .padding(.top)
                    
                    // Botón para mostrar más info
                    Button {
                        withAnimation(.easeInOut) {
                            showInfo.toggle()
                        }
                    } label: {
                        Label(showInfo ? "Hide Info" : "Know More", systemImage: showInfo ? "chevron.up" : "info.circle")
                            .font(.subheadline)
                            .fontWeight(.medium)
                            .padding(.vertical, 8)
                            .padding(.horizontal, 12)
                            .background(.thinMaterial)
                            .clipShape(Capsule())
                    }

                    // Imagen + texto condicional
                    if showInfo {
                        VStack(spacing: 10) {
                            Text("Prediction based on your glucose trends. An AI model estimates your risk of experiencing low blood sugar (hypoglycemia) in the next 24 hours.")
                                .font(.footnote)
                                .multilineTextAlignment(.center)
                                .foregroundStyle(.secondary)
                            
                            Image(.waveletDay)
                                .resizable()
                                .scaledToFit()
                                .frame(width: 125)
                                .clipShape(RoundedRectangle(cornerRadius: 23))
                            
                            // Texto breve explicativo de la imagen
                            Text("Image representation of your glucose data from the past day.")
                                .font(.caption)
                                .foregroundStyle(.secondary)
                                .multilineTextAlignment(.center)
                        }
                        .transition(.opacity)
                    }

                    Spacer()
                }
                .padding()
            }
            .navigationTitle("Prediction")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Button("Done") { dismiss() }
                        .font(.title2)
                        .fontWeight(.medium)
                }
            }
        }
    }
}

struct PredictionSettingsView: View {
    // Se guarda automáticamente en UserDefaults con la clave "cgmDataDelay"
    @AppStorage("cgmDataDelay") private var cgmDataDelay: Bool = false

    var body: some View {
        Form {
            Section {
                Toggle("CGM data delay", isOn: $cgmDataDelay)
            } footer: {
                Text("""
If your Continuous Glucose Monitor (CGM) —for example, Dexcom— delays exporting \
the last ~3 hours of data to Apple Health, enable this option. When ON, \
HypoGuardian will switch to an alternate prediction strategy that handles \
incomplete daily series more robustly, avoiding gaps and improving reliability.
""")
                .font(.footnote)
                .foregroundStyle(.primary)
            }
        }
        .navigationTitle("Prediction Settings")
        .navigationBarTitleDisplayMode(.inline)
    }
}


#Preview {
    PredictionsView()
        .environment(HealthKitManager())
}
