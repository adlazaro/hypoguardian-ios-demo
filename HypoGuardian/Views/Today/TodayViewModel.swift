//
//  TodayViewModel.swift
//  HypoGuardian
//
//  Created by Adrian Lazaro on 21/6/25.
//

import SwiftUI

final class TodayViewModel: ObservableObject {
    
    @Published var hypoCount: Int = 0
    @Published var hyperCount: Int = 0
    @Published var inRangeCount: Int = 0
    @Published var averageGlucose: Double = 0.0
    
    
    var totalRecords: Int {
            hypoCount + hyperCount + inRangeCount
    }
    
    var inRangePercentage: Int {
        totalRecords == 0 ? 0 : Int((Double(inRangeCount) / Double(totalRecords)) * 100)
    }
    
    //Update counts based on healthkit data for the past 24 hours
    func analyzeGlucoseData(from data: [GlucoseSample]) {

        let hypoThreshold = 70.0
        let hyperThreshold = 180.0

        var hypo = 0
        var hyper = 0
        var inRange = 0
        
        var totalGlucose = 0.0

        for sample in data {
            totalGlucose += sample.value
            
            if sample.value < hypoThreshold {
                hypo += 1
            } else if sample.value > hyperThreshold {
                hyper += 1
            } else {
                inRange += 1
            }
        }

        hypoCount = hypo
        hyperCount = hyper
        inRangeCount = inRange
        
        averageGlucose = data.isEmpty ? 0.0 : totalGlucose / Double(data.count)
    }
    
    //Used to pass the values to the donut chart
    //With the boolean property animated so they are animated onAppear
    func getAnimatedRangeStats(animated: Bool) -> [GlucoseRangeStat] {
        //We don't want too narrow sections in the chart for hypos and hypers,
        //so even if the real percentage is low, we establish a minimum visible %
        let minVisiblePercentage = 5.0
            let data: [(String, Int, Color)] = [
                ("inRange", inRangeCount, Color("InRangeColor")),
                ("hypos", hypoCount, Color("LowColor")),
                ("hypers", hyperCount, Color("HighColor"))
            ]

            guard totalRecords > 0 else {
                return data.map { category, _, color in
                    GlucoseRangeStat(category: category, percentage: 0, color: color)
                }
            }

            //Real percentages
            let rawPercentages = data.map { (category, count, color) -> (String, Double, Color) in
                let pct = (Double(count) / Double(totalRecords)) * 100
                return (category, pct, color)
            }

            //Detect how much to add
            var totalAdded = 0.0
            var adjustedPercentages: [(String, Double, Color)] = []

            for (category, pct, color) in rawPercentages {
                if pct < minVisiblePercentage {
                    totalAdded += (minVisiblePercentage - pct)
                    adjustedPercentages.append((category, minVisiblePercentage, color))
                } else {
                    adjustedPercentages.append((category, pct, color))
                }
            }

            //Proportionally substract
            let totalAdjustable = adjustedPercentages
                .filter { $0.1 > minVisiblePercentage }
                .map { $0.1 }
                .reduce(0, +)

            let finalStats = adjustedPercentages.map { (category, pct, color) -> GlucoseRangeStat in
                var finalPct = pct
                if pct > minVisiblePercentage, totalAdjustable > 0 {
                    let reduction = ((pct / totalAdjustable) * totalAdded)
                    finalPct -= reduction
                }

                return GlucoseRangeStat(
                    category: category,
                    percentage: animated ? finalPct : 0,
                    color: color
                )
            }

            return finalStats
    }
    
    // Struct to represent time in range
    struct GlucoseRangeStat: Identifiable {
        let id = UUID()
        let category: String
        let percentage: Double
        let color: Color
    }
}
