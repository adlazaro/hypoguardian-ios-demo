//
//  SemiDonutConfidenceChart.swift
//  HypoGuardian
//
//  Created by Adrian Lazaro on 4/7/25.
//

import SwiftUI
import Charts
import Combine

struct SemiDonutConfidenceChart: View {
    var confidence: Double // Between 0-100
    var hypo: Bool = false //for the color
    
    @State private var animatedConfidence: Double = 0
    @State private var displayedConfidence: Int = 0
    @State private var timerCancellable: Cancellable?

    var body: some View {
        Chart {
            // 1. Lower part (invisible, clipped) (50%)
            SectorMark(
                angle: .value("Hidden", 50),
                innerRadius: .ratio(0.7),
                angularInset: 1
            )
            .foregroundStyle(.pink)

            // 2. Confidence sector (visible)
            SectorMark(
                angle: .value("Confidence", animatedConfidence / 2),
                innerRadius: .ratio(0.7)
            )
            .foregroundStyle(hypo ? Color.high.gradient : Color.inRange.gradient)

            // 3. Remaining sector
            SectorMark(
                angle: .value("Remaining", (100 - animatedConfidence) / 2),
                innerRadius: .ratio(0.7)
            )
            .foregroundStyle(Color.gray.opacity(0.2))
        }
        .rotationEffect(.degrees(90))
        .frame(height: 250)
        .chartBackground { proxy in
            GeometryReader { geo in
                let center = CGPoint(
                    x: geo.size.width / 2,
                    y: geo.size.height / 2 - 25
                )
                Text("\(Int(displayedConfidence))%")
                    .font(.largeTitle)
                    .fontWeight(.bold)
                    .position(center)
            }
        }
        //Only shows top half
        .mask {
            Rectangle()
                .frame(height: 125)
                .offset(y: -62.5)
        }
        .frame(height: 125, alignment: .top)
        // Animate
        .onAppear {
            animatedConfidence = 0
            displayedConfidence = 0
            
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.3) {
                //Chart
                withAnimation(.bouncy(duration: 1.5)) {
                    animatedConfidence = confidence
                }
                
                //Number
                let duration = 1.5
                let updateRate = 0.02
                let totalSteps = Int(duration / updateRate)
                var currentStep = 0

                timerCancellable = Timer
                    .publish(every: updateRate, on: .main, in: .common)
                    .autoconnect()
                    .sink { _ in
                        if currentStep >= totalSteps {
                            displayedConfidence = Int(confidence)
                            timerCancellable?.cancel()
                            return
                        }

                        // Ease-out effect
                        let progress = Double(currentStep) / Double(totalSteps)
                        let eased = 1 - pow(1 - progress, 2)
                        displayedConfidence = Int(eased * confidence)

                        currentStep += 1
                    }
            }
        }
        .onDisappear {
                    timerCancellable?.cancel()
        }
    }
}

#Preview {
    SemiDonutConfidenceChart(confidence: 85, hypo: true)
}
