//
//  NetworkManager.swift
//  HypoGuardian
//
//  Created by Adrian Lazaro on 27/1/25.
//

import UIKit

final class NetworkManager {
    
    static let shared = NetworkManager()
    
    // Loaded from environment / configuration
    private let baseURL: URL = {
        var components = URLComponents()
        components.scheme = "https"
        components.host = ProcessInfo.processInfo.environment["HYPOGUARDIAN_API_HOST"]
        components.path = "/api"

        return components.url!
    }()

    private var predictURL: String {
            return "\(baseURL)/predict/"
    }
    
    private init() { }
    
    func predictHypoglycemia(glucoseValues: [Float], completion: @escaping (Result<PredictionResponse, Error>) -> Void) {
            // Create URL
            guard let url = URL(string: predictURL) else {
                completion(.failure(NSError(domain: "", code: -1, userInfo: [NSLocalizedDescriptionKey: "Invalid URL"])))
                return
            }
            
            // Create the model
            let requestData = GlucoseValues(glucose_values: glucoseValues)
            guard let jsonData = try? JSONEncoder().encode(requestData) else {
                completion(.failure(NSError(domain: "", code: -1, userInfo: [NSLocalizedDescriptionKey: "Invalid data"])))
                return
            }
            
            // Configure request
            var request = URLRequest(url: url)
            request.httpMethod = "POST"
            request.setValue("application/json", forHTTPHeaderField: "Content-Type")
            request.httpBody = jsonData
            
            // Create network task
            let task = URLSession.shared.dataTask(with: request) { data, response, error in
                if let error = error {
                    completion(.failure(error))
                    return
                }
                
                guard let httpResponse = response as? HTTPURLResponse, httpResponse.statusCode == 200 else {
                    completion(.failure(NSError(domain: "", code: -1, userInfo: [NSLocalizedDescriptionKey: "Invalid response"])))
                    return
                }
                
                guard let data = data else {
                    completion(.failure(NSError(domain: "", code: -1, userInfo: [NSLocalizedDescriptionKey: "No data received"])))
                    return
                }
                
                // Decode answer
                do {
                    let predictionResponse = try JSONDecoder().decode(PredictionResponse.self, from: data)
                    completion(.success(predictionResponse))
                } catch {
                    completion(.failure(error))
                }
            }
            
            // Init task
            task.resume()
        }
    
}
