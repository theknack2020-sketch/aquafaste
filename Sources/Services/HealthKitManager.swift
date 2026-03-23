import Foundation
import HealthKit

actor HealthKitManager {
    static let shared = HealthKitManager()

    private let healthStore = HKHealthStore()
    private var isAuthorized = false

    // MARK: - Authorization

    func requestAuthorization() async -> Bool {
        guard HKHealthStore.isHealthDataAvailable() else {
            print("[AquaFaste] HealthKit not available on this device")
            return false
        }

        let waterType = HKQuantityType(.dietaryWater)
        let weightType = HKQuantityType(.bodyMass)

        let typesToShare: Set<HKSampleType> = [waterType]
        let typesToRead: Set<HKObjectType> = [waterType, weightType]

        do {
            try await healthStore.requestAuthorization(toShare: typesToShare, read: typesToRead)
            isAuthorized = true
            return true
        } catch {
            print("[AquaFaste] HealthKit authorization failed: \(error.localizedDescription)")
            isAuthorized = false
            return false
        }
    }

    // MARK: - Write Water

    func saveWaterIntake(amount: Double, date: Date) async {
        if !isAuthorized {
            let granted = await requestAuthorization()
            guard granted else {
                // HealthKit not authorized — skip silently, water is still tracked locally
                return
            }
        }

        let waterType = HKQuantityType(.dietaryWater)
        let quantity = HKQuantity(unit: .literUnit(with: .milli), doubleValue: amount)
        let sample = HKQuantitySample(
            type: waterType,
            quantity: quantity,
            start: date,
            end: date
        )

        do {
            try await healthStore.save(sample)
        } catch {
            print("[AquaFaste] Failed to save water to HealthKit: \(error.localizedDescription)")
            // Non-fatal — app continues to work without HealthKit sync
        }
    }

    // MARK: - Read Weight

    func readBodyWeight() async -> Double? {
        if !isAuthorized {
            let granted = await requestAuthorization()
            guard granted else { return nil }
        }

        let weightType = HKQuantityType(.bodyMass)
        let sortDescriptor = NSSortDescriptor(key: HKSampleSortIdentifierStartDate, ascending: false)

        return await withCheckedContinuation { continuation in
            let query = HKSampleQuery(
                sampleType: weightType,
                predicate: nil,
                limit: 1,
                sortDescriptors: [sortDescriptor]
            ) { _, samples, _ in
                guard let sample = samples?.first as? HKQuantitySample else {
                    continuation.resume(returning: nil)
                    return
                }
                let kg = sample.quantity.doubleValue(for: .gramUnit(with: .kilo))
                continuation.resume(returning: kg)
            }
            healthStore.execute(query)
        }
    }
}
