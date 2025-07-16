import HealthKit
import Foundation
import Combine

/// Service for integrating with HealthKit and feeding pet with real health data
class HealthKitService: ObservableObject {
    private let healthStore = HKHealthStore()
    private let petService: PetService
    
    @Published var isAuthorized = false
    @Published var todayActivityRings: ActivityRingsData?
    @Published var currentWorkout: HKWorkout?
    
    private var cancellables = Set<AnyCancellable>()
    
    // HealthKit data types we need
    private let healthDataTypes: Set<HKSampleType> = [
        HKQuantityType.quantityType(forIdentifier: .stepCount)!,
        HKQuantityType.quantityType(forIdentifier: .activeEnergyBurned)!,
        HKQuantityType.quantityType(forIdentifier: .appleExerciseTime)!,
        HKQuantityType.quantityType(forIdentifier: .appleStandTime)!,
        HKQuantityType.quantityType(forIdentifier: .heartRate)!,
        HKObjectType.activitySummaryType(),
        HKObjectType.workoutType()
    ]
    
    init(petService: PetService) {
        self.petService = petService
        setupHealthKit()
        startObservingHealthData()
    }
    
    // MARK: - HealthKit Setup
    
    private func setupHealthKit() {
        guard HKHealthStore.isHealthDataAvailable() else {
            print("HealthKit is not available on this device")
            return
        }
        
        requestAuthorization()
    }
    
    func requestAuthorization() {
        healthStore.requestAuthorization(toShare: [], read: healthDataTypes) { [weak self] success, error in
            DispatchQueue.main.async {
                self?.isAuthorized = success
                if success {
                    self?.startObservingHealthData()
                    self?.loadTodayActivityData()
                } else if let error = error {
                    print("HealthKit authorization failed: \(error.localizedDescription)")
                }
            }
        }
    }
    
    // MARK: - Health Data Observation
    
    private func startObservingHealthData() {
        guard isAuthorized else { return }
        
        // Observe activity summary changes
        observeActivitySummary()
        
        // Load today's data initially
        loadTodayActivityData()
    }
    
    private func observeActivitySummary() {
        let query = HKObserverQuery(sampleType: HKObjectType.activitySummaryType(), predicate: nil) { [weak self] _, _, error in
            if let error = error {
                print("Activity summary observation error: \(error.localizedDescription)")
                return
            }
            
            DispatchQueue.main.async {
                self?.loadTodayActivityData()
            }
        }
        
        healthStore.execute(query)
    }
    
    // MARK: - Activity Data Loading
    
    func loadTodayActivityData() {
        let calendar = Calendar.current
        let now = Date()
        let startOfDay = calendar.startOfDay(for: now)
        
        // Load activity summary for today
        loadActivitySummary(for: startOfDay) { [weak self] activityRings in
            DispatchQueue.main.async {
                self?.todayActivityRings = activityRings
                
                // If we have activity data, feed the pet
                if let rings = activityRings {
                    self?.feedPetWithTodayData(rings)
                }
            }
        }
    }
    
    private func loadActivitySummary(for date: Date, completion: @escaping (ActivityRingsData?) -> Void) {
        let calendar = Calendar.current
        let startOfDay = calendar.startOfDay(for: date)
        let endOfDay = calendar.date(byAdding: .day, value: 1, to: startOfDay)!
        
        let predicate = HKQuery.predicate(forActivitySummariesBetween: startOfDay, and: endOfDay)
        
        let query = HKActivitySummaryQuery(predicate: predicate) { _, summaries, error in
            if let error = error {
                print("Activity summary query error: \(error.localizedDescription)")
                completion(nil)
                return
            }
            
            guard let summary = summaries?.first else {
                completion(nil)
                return
            }
            
            // Load step count for the day
            self.loadStepCount(for: startOfDay, endDate: endOfDay) { steps in
                let activityData = ActivityRingsData(
                    date: date,
                    steps: steps,
                    activeCalories: summary.activeEnergyBurned.doubleValue(for: .kilocalorie()),
                    exerciseMinutes: Int(summary.appleExerciseTime.doubleValue(for: .minute())),
                    standHours: Int(summary.appleStandHours.doubleValue(for: .count())),
                    moveGoal: summary.activeEnergyBurnedGoal.doubleValue(for: .kilocalorie()),
                    exerciseGoal: summary.appleExerciseTimeGoal.doubleValue(for: .minute()),
                    standGoal: summary.appleStandHoursGoal.doubleValue(for: .count())
                )
                
                completion(activityData)
            }
        }
        
        healthStore.execute(query)
    }
    
    private func loadStepCount(for startDate: Date, endDate: Date, completion: @escaping (Int) -> Void) {
        guard let stepType = HKQuantityType.quantityType(forIdentifier: .stepCount) else {
            completion(0)
            return
        }
        
        let predicate = HKQuery.predicateForSamples(withStart: startDate, end: endDate, options: .strictStartDate)
        
        let query = HKStatisticsQuery(quantityType: stepType, quantitySamplePredicate: predicate, options: .cumulativeSum) { _, statistics, error in
            if let error = error {
                print("Step count query error: \(error.localizedDescription)")
                completion(0)
                return
            }
            
            let steps = statistics?.sumQuantity()?.doubleValue(for: .count()) ?? 0
            completion(Int(steps))
        }
        
        healthStore.execute(query)
    }
    
    // MARK: - Pet Feeding
    
    private func feedPetWithTodayData(_ activityData: ActivityRingsData) {
        let healthInput = HealthDataInput(
            date: activityData.date,
            steps: activityData.steps,
            activeCalories: activityData.activeCalories,
            exerciseMinutes: activityData.exerciseMinutes,
            standHours: activityData.standHours,
            moveRingClosed: activityData.moveRingClosed,
            exerciseRingClosed: activityData.exerciseRingClosed,
            standRingClosed: activityData.standRingClosed
        )
        
        petService.feedPet(with: healthInput)
    }
}

// MARK: - Helper Models

struct ActivityRingsData {
    let date: Date
    let steps: Int
    let activeCalories: Double
    let exerciseMinutes: Int
    let standHours: Int
    let moveGoal: Double
    let exerciseGoal: Double
    let standGoal: Double
    
    var moveRingClosed: Bool {
        return activeCalories >= moveGoal
    }
    
    var exerciseRingClosed: Bool {
        return Double(exerciseMinutes) >= exerciseGoal
    }
    
    var standRingClosed: Bool {
        return Double(standHours) >= standGoal
    }
    
    var moveRingProgress: Double {
        return min(1.0, activeCalories / moveGoal)
    }
    
    var exerciseRingProgress: Double {
        return min(1.0, Double(exerciseMinutes) / exerciseGoal)
    }
    
    var standRingProgress: Double {
        return min(1.0, Double(standHours) / standGoal)
    }
}
