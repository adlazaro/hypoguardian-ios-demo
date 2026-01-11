//
//  LogView.swift
//  HypoGuardian
//
//  Created by Adrian Lazaro on 28/10/24.
//

import SwiftUI
import SwiftData

struct LogView: View {
    
    @Query(sort: \Prediction.date, order: .reverse) var predictions: [Prediction]
    
    var body: some View {
        NavigationStack {
            ScrollView {
                LazyVStack(spacing: 16) {
                    if predictions.isEmpty {
                        VStack(spacing: 12) {
                            Image(systemName: "clock.arrow.circlepath")
                                .resizable()
                                .scaledToFit()
                                .frame(width: 60, height: 60)
                                .foregroundStyle(.gray.opacity(0.4))
                            Text("No predictions yet.")
                                .font(.title3)
                                .foregroundStyle(.secondary)
                        }
                        .padding(.top, 100)
                    } else {
                        ForEach(groupedPredictions, id: \.key) { (date, dayPredictions) in
                            VStack(alignment: .leading, spacing: 8) {
                                Text(sectionHeader(for: date))
                                    .font(.headline)
                                    .foregroundStyle(.secondary)
                                    .padding(.horizontal)
                                    .padding(.top, 8)

                                ForEach(dayPredictions) { prediction in
                                    NavigationLink(destination: PredictionDetailView(prediction: prediction)) {
                                        PredictionCard(prediction: prediction)
                                            .padding(.horizontal)
                                    }
                                    .buttonStyle(.plain)
                                }
                            }
                        }
                    }
                }
                .padding(.top)
            }
            .navigationTitle("Prediction Log")
        }
    }
    
    private var groupedPredictions: [(key: Date, value: [Prediction])] {
        Dictionary(grouping: predictions) { prediction in
            Calendar.current.startOfDay(for: prediction.date)
        }
        .sorted { $0.key > $1.key }
    }
    
    private func sectionHeader(for date: Date) -> String {
        if Calendar.current.isDateInYesterday(date) {
            return "Yesterday"
        } else if Calendar.current.isDateInToday(date) {
            return "Today"
        } else {
            let formatter = DateFormatter()
            formatter.dateFormat = "d MMM yyyy"
            return formatter.string(from: date)
        }
    }
}

struct PredictionCard: View {
    let prediction: Prediction

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                Image(systemName: prediction.hypoPredicted ? "exclamationmark.triangle.fill" : "checkmark.circle.fill")
                    .foregroundColor(prediction.hypoPredicted ? .low : .inRange)
                    .font(.title2)

                Text(prediction.hypoPredicted ? "Hypoglycemia Predicted" : "No Hypoglycemia predicted")
                    .font(.headline)
                    .foregroundStyle(prediction.hypoPredicted ? .low : .inRange)

                Spacer()

                // Chevron to indicate tappable card
                Image(systemName: "chevron.right")
                    .foregroundStyle(.secondary)
                    .font(.body)
            }

            Text("Date: \(formattedDate(prediction.date))")
                .font(.subheadline)
                .foregroundStyle(.secondary)
        }
        .padding()
        .background(.ultraThinMaterial)
        .clipShape(RoundedRectangle(cornerRadius: 16))
    }

    private func formattedDate(_ date: Date) -> String {
        let formatter = DateFormatter()
        formatter.dateStyle = .medium
        formatter.timeStyle = .short
        return formatter.string(from: date)
    }
}

struct PredictionDetailView: View {
    let prediction: Prediction

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 24) {
                HStack {
                    Image(systemName: prediction.hypoPredicted ? "exclamationmark.triangle.fill" : "checkmark.circle.fill")
                        .foregroundColor(prediction.hypoPredicted ? .low : .inRange)
                        .font(.largeTitle)

                    Text(prediction.hypoPredicted ? "Hypoglycemia Predicted" : "No Hypoglycemia predicted")
                        .font(.title2)
                        .fontWeight(.semibold)
                        .foregroundStyle(prediction.hypoPredicted ? .low : .inRange)
                }

                Divider()

                Group {
                    Text("🗓️ Date")
                        .font(.headline)
                    Text(formattedDate(prediction.date))
                        .foregroundStyle(.secondary)

                    Text("📊 Confidence")
                        .font(.headline)
                        .padding(.top, 8)
                    Text("\(prediction.confidence, specifier: "%.0f")%")
                        .foregroundStyle(.secondary)

                    Text("⏱️ Prediction Horizon")
                        .font(.headline)
                        .padding(.top, 8)
                    Text("Next \(prediction.timeHorizon) hours")
                        .foregroundStyle(.secondary)
                }

                Divider()

                // Espacio para futuras extensiones:
                Text("🧠 Model Details")
                    .font(.headline)
                    .padding(.top)
                Text("This prediction was made using a wavelet-transformed image of your glucose data and a neural network trained to detect hypoglycemia risk.")
                    .font(.footnote)
                    .foregroundStyle(.gray)

                Spacer()
            }
            .padding()
        }
        .navigationTitle("Prediction Detail")
        .navigationBarTitleDisplayMode(.inline)
    }

    private func formattedDate(_ date: Date) -> String {
        let formatter = DateFormatter()
        formatter.dateStyle = .full
        formatter.timeStyle = .short
        return formatter.string(from: date)
    }
}

#Preview {
    LogView()
        .modelContainer(for: Prediction.self, inMemory: true)
}
