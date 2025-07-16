import CoreData
import Foundation
import Combine

/// Service for managing pet lifecycle, evolution, and health
class PetService: ObservableObject {
    private let persistenceController: PersistenceController
    private var context: NSManagedObjectContext { persistenceController.context }
    
    @Published var currentPet: Pet?
    @Published var availablePetTypes: [PetType] = []
    
    private var cancellables = Set<AnyCancellable>()
    
    init(persistenceController: PersistenceController = .shared) {
        self.persistenceController = persistenceController
        loadAvailablePetTypes()
        loadCurrentPet()
        setupTimers()
    }
    
    // MARK: - Pet Management
    
    /// Creates a new pet of the specified type
    func createPet(name: String, petTypeID: String) -> Pet? {
        guard let petType = availablePetTypes.first(where: { $0.id == petTypeID }) else {
            print("Error: Pet type \(petTypeID) not found")
            return nil
        }
        
        // Mark current pet as dead if it exists
        if let existingPet = currentPet, existingPet.isAlive {
            killCurrentPet()
        }
        
        let pet = Pet(context: context)
        pet.id = UUID()
        pet.name = name
        pet.petTypeID = petTypeID
        pet.currentHealth = Int32(petType.baseHealth)
        pet.maxHealth = Int32(petType.baseHealth)
        pet.happiness = Int32(petType.baseHappiness)
        pet.level = 1
        pet.experience = 0
        pet.evolutionStage = 1
        pet.birthDate = Date()
        pet.isAlive = true
        pet.totalLifetimeExperience = 0
        pet.generationNumber = (currentPet?.generationNumber ?? 0) + 1
        pet.petType = petType
        
        persistenceController.save()
        currentPet = pet
        
        return pet
    }
    
    /// Loads the current active pet
    private func loadCurrentPet() {
        let request: NSFetchRequest<Pet> = Pet.fetchRequest()
        request.predicate = NSPredicate(format: "isAlive == YES")
        request.sortDescriptors = [NSSortDescriptor(keyPath: \Pet.birthDate, ascending: false)]
        request.fetchLimit = 1
        
        do {
            let pets = try context.fetch(request)
            currentPet = pets.first
        } catch {
            print("Failed to load current pet: \(error.localizedDescription)")
        }
    }
    
    /// Loads all available pet types
    private func loadAvailablePetTypes() {
        let request: NSFetchRequest<PetType> = PetType.fetchRequest()
        request.sortDescriptors = [NSSortDescriptor(keyPath: \PetType.name, ascending: true)]
        
        do {
            availablePetTypes = try context.fetch(request)
        } catch {
            print("Failed to load pet types: \(error.localizedDescription)")
        }
    }
    
    // MARK: - Pet Care Actions
    
    /// Interacts with the pet (petting, playing)
    func interactWithPet() {
        guard let pet = currentPet, pet.isAlive else { return }
        
        let happinessGain = 5
        let experienceGain = 2
        
        pet.happiness = min(100, pet.happiness + Int32(happinessGain))
        pet.experience += Int32(experienceGain)
        pet.totalLifetimeExperience += Int32(experienceGain)
        pet.lastInteractionTime = Date()
        
        checkForLevelUp()
        checkForEvolution()
        
        persistenceController.save()
    }
    
    // MARK: - Pet Progression
    
    private func checkForLevelUp() {
        guard let pet = currentPet else { return }
        
        let requiredXP = pet.level * pet.level * 100 // Quadratic scaling
        
        if pet.experience >= requiredXP {
            pet.level += 1
            pet.maxHealth += 5 // Increase max health on level up
            pet.currentHealth = min(pet.currentHealth + 10, pet.maxHealth) // Heal on level up
            
            print("🎉 \(pet.name ?? "Pet") leveled up to level \(pet.level)!")
        }
    }
    
    private func checkForEvolution() {
        guard let pet = currentPet,
              let petType = pet.petType else { return }
        
        let ageInHours = Int(Date().timeIntervalSince(pet.birthDate) / 3600)
        
        // Get available evolution stages
        let evolutionStages = petType.evolutionStages?.allObjects as? [EvolutionStage] ?? []
        let sortedStages = evolutionStages.sorted { $0.stageNumber < $1.stageNumber }
        
        // Find the highest stage the pet qualifies for
        for stage in sortedStages {
            if stage.stageNumber > pet.evolutionStage &&
               ageInHours >= stage.requiredHours &&
               pet.experience >= stage.requiredExperience {
                
                // Update pet stage and stats
                pet.evolutionStage = stage.stageNumber
                pet.maxHealth = Int32(Float(pet.maxHealth) * stage.healthMultiplier)
                pet.currentHealth = pet.maxHealth // Full heal on evolution
                pet.happiness = min(100, Int32(Float(pet.happiness) * stage.happinessMultiplier))
                
                print("✨ \(pet.name ?? "Pet") evolved to \(stage.name ?? "Stage \(stage.stageNumber)")!")
            }
        }
    }
    
    // MARK: - Pet Death System
    
    private func setupTimers() {
        // Check pet health every hour
        Timer.publish(every: 3600, on: .main, in: .common)
            .autoconnect()
            .sink { [weak self] _ in
                self?.updatePetHealth()
            }
            .store(in: &cancellables)
    }
    
    private func updatePetHealth() {
        guard let pet = currentPet, pet.isAlive else { return }
        
        let timeSinceLastFeed = Date().timeIntervalSince(pet.lastFeedTime ?? pet.birthDate)
        let hoursSinceLastFeed = timeSinceLastFeed / 3600
        
        // Pet loses health if not fed
        if hoursSinceLastFeed > 8 { // Start losing health after 8 hours
            let healthLoss = Int32(min(10, (hoursSinceLastFeed - 8) * 2)) // 2 health per hour after 8 hours
            pet.currentHealth = max(0, pet.currentHealth - healthLoss)
            
            if pet.currentHealth <= 0 {
                killCurrentPet()
            }
        }
        
        persistenceController.save()
    }
    
    private func killCurrentPet() {
        guard let pet = currentPet else { return }
        
        pet.isAlive = false
        pet.deathDate = Date()
        
        persistenceController.save()
        
        print("💀 \(pet.name ?? "Pet") has died. Generation \(pet.generationNumber) lasted \(Int(Date().timeIntervalSince(pet.birthDate) / 3600)) hours.")
    }
    
    // MARK: - Health Data Integration
    
    func feedPet(with healthData: HealthDataInput) {
        guard let pet = currentPet, pet.isAlive else { return }
        
        let healthGain = calculateHealthGain(from: healthData)
        let happinessGain = calculateHappinessGain(from: healthData)
        let experienceGain = calculateExperienceGain(from: healthData)
        
        // Update pet stats
        pet.currentHealth = min(pet.maxHealth, pet.currentHealth + Int32(healthGain))
        pet.happiness = min(100, pet.happiness + Int32(happinessGain))
        pet.experience += Int32(experienceGain)
        pet.totalLifetimeExperience += Int32(experienceGain)
        pet.lastFeedTime = Date()
        
        checkForLevelUp()
        checkForEvolution()
        
        persistenceController.save()
    }
    
    private func calculateHealthGain(from healthData: HealthDataInput) -> Int {
        var healthGain = 0
        
        // Steps contribution (0-20 health)
        let stepsRatio = min(1.0, Double(healthData.steps) / 8000.0) // 8000 steps = max
        healthGain += Int(stepsRatio * 20)
        
        // Activity rings contribution (0-15 health each)
        if healthData.moveRingClosed { healthGain += 15 }
        if healthData.exerciseRingClosed { healthGain += 15 }
        if healthData.standRingClosed { healthGain += 10 }
        
        return min(60, healthGain) // Max 60 health per day
    }
    
    private func calculateHappinessGain(from healthData: HealthDataInput) -> Int {
        var happinessGain = 0
        
        // Exercise minutes contribution
        let exerciseRatio = min(1.0, Double(healthData.exerciseMinutes) / 30.0) // 30 min = max
        happinessGain += Int(exerciseRatio * 25)
        
        // Bonus for closing all rings
        if healthData.moveRingClosed && healthData.exerciseRingClosed && healthData.standRingClosed {
            happinessGain += 15
        }
        
        return min(40, happinessGain) // Max 40 happiness per day
    }
    
    private func calculateExperienceGain(from healthData: HealthDataInput) -> Int {
        var experienceGain = 0
        
        // Base experience from activity
        experienceGain += min(50, healthData.steps / 100) // 1 XP per 100 steps, max 50
        experienceGain += Int(healthData.activeCalories / 10) // 1 XP per 10 calories
        experienceGain += healthData.exerciseMinutes * 2 // 2 XP per exercise minute
        
        // Ring completion bonuses
        if healthData.moveRingClosed { experienceGain += 25 }
        if healthData.exerciseRingClosed { experienceGain += 25 }
        if healthData.standRingClosed { experienceGain += 15 }
        
        // Perfect day bonus
        if healthData.activityRingsClosed == 3 {
            experienceGain += 50
        }
        
        return experienceGain
    }
}

// MARK: - Helper Models

struct HealthDataInput {
    let date: Date
    let steps: Int
    let activeCalories: Double
    let exerciseMinutes: Int
    let standHours: Int
    let moveRingClosed: Bool
    let exerciseRingClosed: Bool
    let standRingClosed: Bool
    
    var activityRingsClosed: Int {
        return (moveRingClosed ? 1 : 0) + (exerciseRingClosed ? 1 : 0) + (standRingClosed ? 1 : 0)
    }
}
