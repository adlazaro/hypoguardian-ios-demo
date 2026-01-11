//
//  Glucose.swift
//  HypoGuardian
//
//  Created by Adrian Lazaro on 30/10/24.
//

import Foundation

struct GlucoseSample: Identifiable, Equatable {
    let id = UUID()
    
    let date: Date
    let value: Double
}

struct GlucoseValues: Codable {
    let glucose_values: [Float]
}
