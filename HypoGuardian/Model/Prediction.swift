//
//  Prediction.swift
//  HypoGuardian
//
//  Created by Adrian Lazaro on 4/7/25.
//

import Foundation
import SwiftData

@Model
class Prediction {
    var id: UUID
    var date: Date
    var hypoPredicted: Bool
    var confidence: Double // Porcentaje
    var timeHorizon: Int  // En horas, defecto, 24
    
    init(date: Date = .now, hypoPredicted: Bool, confidence: Double = 90.0, timeHorizon: Int = 24) {
        self.id = UUID()
        self.date = date
        self.hypoPredicted = hypoPredicted
        self.confidence = confidence
        self.timeHorizon = timeHorizon
    }
}
