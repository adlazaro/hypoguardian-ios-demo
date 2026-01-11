//
//  PredictionResponse.swift
//  HypoGuardian
//
//  Created by Adrian Lazaro on 27/1/25.
//

import Foundation

struct PredictionResponse: Codable {
    let hypo_predicted: Bool
    let confidence: Int
}
