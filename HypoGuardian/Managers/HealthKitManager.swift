//
//  HealthKitManager.swift
//  HypoGuardian
//
//  Created by Adrian Lazaro on 30/10/24.
//

import Foundation
import Observation
import HealthKit

@Observable class HealthKitManager {
    
    let healthStore = HKHealthStore()
    
    let glucoseHealthType = HKQuantityType(.bloodGlucose)
    
    let glucoseUnit = HKUnit(from: "mg/dL")
    
    /// Fetch glucose samples from the last 24 hours.
    /// - Returns: An array of `GlucoseSample` objects.
    func fetchGlucoseDataLastDay() async throws -> [GlucoseSample] {
        // Si el delay está activo, retrocede 27 h; si no, 24 h.
        let useCgmDelay = UserDefaults.standard.bool(forKey: "cgmDataDelay")
        let hoursBack = useCgmDelay ? 27 : 24

        let endDate = Date()                // la query puede seguir terminando en ahora
        let startDate = Calendar.current.date(byAdding: .hour, value: -hoursBack, to: endDate)!

        let predicate = HKQuery.predicateForSamples(withStart: startDate, end: endDate)
        let samplePredicate = HKSamplePredicate.quantitySample(type: glucoseHealthType, predicate: predicate)

        let descriptor = HKSampleQueryDescriptor(
            predicates: [samplePredicate],
            sortDescriptors: [SortDescriptor(\.endDate, order: .reverse)]
        )

        let samples = try await descriptor.result(for: healthStore)
        return samples.map {
            GlucoseSample(date: $0.startDate, value: $0.quantity.doubleValue(for: glucoseUnit))
        }
    }

    
    func fetchGlucoseDataOnlyToday() async -> [GlucoseSample]{
            // Obtain today's date at 00:00
            let startOfDay = Calendar.current.startOfDay(for: Date())
            
            let now = Date()
            
            //Create predicate
            let predicate = HKQuery.predicateForSamples(withStart: startOfDay, end: now)
            
            let samplePredicate = HKSamplePredicate.quantitySample(type: glucoseHealthType, predicate: predicate)
            
            let descriptor = HKSampleQueryDescriptor(
                predicates: [samplePredicate],
                sortDescriptors: [SortDescriptor(\.endDate, order: .reverse)]
            )
            
            do {
                let samples = try await descriptor.result(for: healthStore)
                let glucoseSamples = samples.map {
                    GlucoseSample(date: $0.startDate, value: $0.quantity.doubleValue(for: glucoseUnit))
                }
                return glucoseSamples
            } catch {
                print("❌ Error fetching glucose data for today: \(error)")
                return []
            }
    }
    
    func fetchGlucoseDataSpecificDay(for date: Date) async -> [GlucoseSample] {
        // Get start and end of the provided day
        let startOfDay = Calendar.current.startOfDay(for: date)
        let endOfDay = Calendar.current.date(byAdding: DateComponents(day: 1, second: -1), to: startOfDay)!

        // Create predicate for the date range
        let predicate = HKQuery.predicateForSamples(withStart: startOfDay, end: endOfDay)
        let samplePredicate = HKSamplePredicate.quantitySample(type: glucoseHealthType, predicate: predicate)

        let descriptor = HKSampleQueryDescriptor(
            predicates: [samplePredicate],
            sortDescriptors: [SortDescriptor(\.endDate, order: .reverse)]
        )

        do {
            let samples = try await descriptor.result(for: healthStore)
            let glucoseSamples = samples.map {
                GlucoseSample(date: $0.startDate, value: $0.quantity.doubleValue(for: glucoseUnit))
            }
            return glucoseSamples
        } catch {
            print("❌ Error fetching glucose data for date \(date): \(error)")
            return []
        }
    }
    
    func saveGlucoseEntry(value: Double, date: Date) async throws {
        let quantity = HKQuantity(unit: glucoseUnit, doubleValue: value)
        
        let sample = HKQuantitySample(
            type: glucoseHealthType,
            quantity: quantity,
            start: date,
            end: date.addingTimeInterval(1) // 1 sec later, by convention
        )
        
        do {
            try await healthStore.save(sample)
            print("✅ Glucose sample saved")
        } catch {
            print("❌ Error saving glucose sample: \(error)")
            throw error
        }
    }
    
    //MARK: - Glucose utilities
    
    /// Builds and validates a 96-value series ready for the prediction API.
    /// - Parameter samples: `[GlucoseSample]` returned by `fetchGlucoseDataLastDay()`
    /// - Returns: `[Float]` of length 96, or `nil` if data quality rules are broken.
    func makeValidatedSeries(from samples: [GlucoseSample]) -> [Float]? {
        // Lee la preferencia guardada por @AppStorage("cgmDataDelay")
        let useCgmDelay = UserDefaults.standard.bool(forKey: "cgmDataDelay")

        // Si hay delay, la serie termina hace 3 horas; si no, termina en ahora.
        let endRef = useCgmDelay ? Date().addingTimeInterval(-3 * 3600) : Date()

        var slots: [Float?] = Array(repeating: nil, count: 96)
        let calendar = Calendar.current

        for sample in samples {
            // Minutos entre la muestra y endRef (0…<1440)
            let minutesAgo = calendar.dateComponents([.minute],
                                                     from: sample.date,
                                                     to: endRef).minute ?? 0
            guard minutesAgo >= 0 && minutesAgo < 1440 else { continue }

            let index = 95 - (minutesAgo / 15) // la más reciente va al último slot
            slots[index] = Float(sample.value) // nos quedamos con la más reciente en el bucket
        }

        return GlucoseSeriesValidator.validateAndFill(slots)
    }

    
    /// Static helper that enforces the business rules.
    enum GlucoseSeriesValidator {
        
        /// Applies the missing-value policy and interpolates where allowed.
        /// - Returns: `[Float]` of length 96 or `nil` if validation fails.
        static func validateAndFill(_ raw: [Float?]) -> [Float]? {
            guard raw.count == 96 else { return nil }
            
            // — Rules —
            let missing = raw.filter { $0 == nil }.count
            guard missing <= 10 else { return nil }
            
            var maxConsecutive = 0, current = 0
            raw.forEach {
                if $0 == nil {
                    current += 1
                    maxConsecutive = max(maxConsecutive, current)
                } else { current = 0 }
            }
            guard maxConsecutive <= 3 else { return nil }
            
            // — Fill gaps by averaging nearest neighbours —
            var filled = raw
            for i in 0..<96 where filled[i] == nil {
                // --- Interpolate the missing value at index i ---
                let left  = filled[..<i].compactMap { $0 }.last        // Float?
                let right = filled[(i+1)..<filled.count].compactMap { $0 }.first
                
                if let l = left, let r = right {
                    filled[i] = (l + r) / 2  // average of neighbours
                } else if let l = left {
                    filled[i] = l // only left neighbour
                } else if let r = right {
                    filled[i] = r // only right neighbour
                } else {
                    return nil // no neighbours at all → validation fails
                }
            }
            
            // Force-unwrap is now safe.
            return filled.compactMap { $0 }
        }
    }
    
    //MARK: - Testing functions, might not be needed in the future
    func addMockData() async {
        // 50%: true = control excepcional (picos suaves y acotados), false = mal control (lógica base)
        let exceptionalControl = false
        
        // Rango global para buen control (ligeramente más amplio para realismo)
        let goodMin = 87.0
        let goodMax = 185.0

        // Limpia datos mock previos
        await deleteMockData(from: 8)

        var glucData: [HKQuantitySample] = []
        let now = Date()

        // Helper: normal(μ, σ) usando Box–Muller
        func randomNormal(mean: Double, sd: Double) -> Double {
            let u1 = Double.random(in: 0.000001...0.999999)
            let u2 = Double.random(in: 0.000001...0.999999)
            let z0 = sqrt(-2.0 * log(u1)) * cos(2.0 * .pi * u2)
            return mean + sd * z0
        }

        for dayOffset in 0..<7 {
            let date = Calendar.current.date(byAdding: .day, value: -dayOffset, to: now)!
            let startOfDay = Calendar.current.startOfDay(for: date)

            // Para “buen control” limitamos el salto entre muestras del mismo día
            var prevGoodValue: Double? = nil

            for i in 0..<96 {
                let minutesToAdd = i * 15
                let sampleDate = Calendar.current.date(byAdding: .minute, value: minutesToAdd, to: startOfDay)!
                if sampleDate > now { break } // evita futuras

                let hour = Calendar.current.component(.hour, from: sampleDate)

                var glucValue: Double

                if exceptionalControl {
                    // ---- Buen control: por franja con ruido suave y deltas limitados ----
                    // Definición de targets por franja
                    let (minV, maxV, meanV, sdV, maxDelta): (Double, Double, Double, Double, Double) = {
                        switch hour {
                        case 7...9:   // Desayuno: pequeño pico controlado
                            return (100, 135, 120, 6, 18)
                        case 13...15: // Comida: pico moderado
                            return (105, 160, 140, 7, 18)
                        case 20...21: // Cena: pico moderado
                            return (105, 140, 130, 7, 18)
                        case 0...4:   // Madrugada: estable tirando a bajo normal
                            return (87, 110, 95, 5, 12)
                        default:      // Día normal: estable
                            return (95, 120, 105, 5, 12)
                        }
                    }()

                    // Muestra gaussiana alrededor del objetivo
                    var candidate = randomNormal(mean: meanV, sd: sdV)
                    // Clamps por franja y global
                    candidate = max(min(candidate, maxV), minV)
                    candidate = max(min(candidate, goodMax), goodMin)

                    // Limitar la variación respecto a la muestra previa para suavidad
                    if let prev = prevGoodValue {
                        let delta = candidate - prev
                        if abs(delta) > maxDelta {
                            candidate = prev + (delta > 0 ? maxDelta : -maxDelta)
                        }
                    } else {
                        // Primera muestra del día: arranca cerca del objetivo
                        // (en caso de que caiga en los bordes)
                        candidate = randomNormal(mean: meanV, sd: sdV/2)
                        candidate = max(min(candidate, maxV), minV)
                        candidate = max(min(candidate, goodMax), goodMin)
                    }

                    prevGoodValue = candidate
                    glucValue = candidate

                } else {
                    // ---- Mal control: lógica original por franja ----
                    switch hour {
                    case 7...9:   glucValue = Double.random(in: 90...140)     // Desayuno
                    case 13...15: glucValue = Double.random(in: 130...200)    // Comida
                    case 20...21: glucValue = Double.random(in: 130...200)    // Cena
                    case 0...4:   glucValue = Double.random(in: 60...100)     // Madrugada
                    default:      glucValue = Double.random(in: 85...120)     // Día normal
                    }
                }

                let quantity = HKQuantity(unit: glucoseUnit, doubleValue: glucValue)
                let endDate = Calendar.current.date(byAdding: .second, value: 1, to: sampleDate)!
                let sample = HKQuantitySample(type: glucoseHealthType, quantity: quantity, start: sampleDate, end: endDate)
                glucData.append(sample)
            }
        }

        do {
            try await healthStore.save(glucData)
            print("✅ Mock data for last 7 days added. exceptionalControl=\(exceptionalControl)")
        } catch {
            print("❌ Error saving mock data: \(error)")
        }
    }
    
    func deleteMockData(from days: Int = 30) async {
        
        let query = HKQuery.predicateForSamples(withStart: Calendar.current.date(byAdding: .day, value: -(days), to: .now), end: Calendar.current.date(byAdding: .day, value: 2, to: .now))
        
        do {
            try await healthStore.deleteObjects(of: glucoseHealthType, predicate: query) //Could crash
        } catch {
            print("❌Error deleting glucose data")
        }
       
        print("🔵Glucose data deleted")
    }
}
