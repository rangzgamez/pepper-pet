import CoreData
import Foundation

/// Service for seeding initial data and managing pet types
class DataSeedingService {
    private let persistenceController: PersistenceController
    private var context: NSManagedObjectContext { persistenceController.context }
    
    init(persistenceController: PersistenceController = .shared) {
        self.persistenceController = persistenceController
    }
    
    // MARK: - Initial Data Setup
    
    /// Seeds the database with initial pet types and evolution stages
    func seedInitialData() {
        // Check if data already exists
        if hasExistingData() {
            print("Data already seeded, skipping...")
            return
        }
        
        print("🌱 Seeding initial data...")
        
        createDigitalCatType()
        createDigitalDogType()
        createDigitalBirdType()
        
        persistenceController.save()
        print("✅ Initial data seeded successfully!")
    }
    
    private func hasExistingData() -> Bool {
        let request: NSFetchRequest<PetType> = PetType.fetchRequest()
        request.fetchLimit = 1
        
        do {
            let count = try context.count(for: request)
            return count > 0
        } catch {
            print("Error checking existing data: \(error.localizedDescription)")
            return false
        }
    }
    
    // MARK: - Pet Type Creation
    
    private func createDigitalCatType() {
        let catType = PetType(context: context)
        catType.id = "digital_cat"
        catType.name = "Digital Cat"
        catType.description_ = "A curious and playful feline companion that thrives on exploration and activity. Cats evolve based on your daily movement and exercise habits."
        catType.baseHealth = 100
        catType.baseHappiness = 90
        catType.evolutionTimeHours = 168 // 7 days total evolution time
        catType.spriteBaseName = "cat"
        catType.isUnlocked = true
        
        // Evolution Stage 1: Kitten
        let kitten = EvolutionStage(context: context)
        kitten.stageNumber = 1
        kitten.name = "Pixel Kitten"
        kitten.description_ = "A tiny digital kitten, full of energy and curiosity. Loves when you move around!"
        kitten.requiredHours = 0
        kitten.requiredExperience = 0
        kitten.spriteFileName = "cat_kitten"
        kitten.healthMultiplier = 1.0
        kitten.happinessMultiplier = 1.0
        kitten.petType = catType
        
        // Evolution Stage 2: Young Cat
        let youngCat = EvolutionStage(context: context)
        youngCat.stageNumber = 2
        youngCat.name = "Cyber Cat"
        youngCat.description_ = "A growing digital cat with increased agility. Your active lifestyle is helping it flourish!"
        youngCat.requiredHours = 72 // 3 days
        youngCat.requiredExperience = 500
        youngCat.spriteFileName = "cat_young"
        youngCat.healthMultiplier = 1.3
        youngCat.happinessMultiplier = 1.2
        youngCat.petType = catType
        
        // Evolution Stage 3: Mystic Cat
        let mysticCat = EvolutionStage(context: context)
        mysticCat.stageNumber = 3
        mysticCat.name = "Mystic Feline"
        mysticCat.description_ = "A wise and powerful digital cat with mystical abilities. Your dedication to fitness has unlocked its true potential!"
        mysticCat.requiredHours = 168 // 7 days
        mysticCat.requiredExperience = 1500
        mysticCat.spriteFileName = "cat_mystic"
        mysticCat.healthMultiplier = 1.6
        mysticCat.happinessMultiplier = 1.5
        mysticCat.petType = catType
    }
    
    private func createDigitalDogType() {
        let dogType = PetType(context: context)
        dogType.id = "digital_dog"
        dogType.name = "Digital Dog"
        dogType.description_ = "A loyal and energetic canine companion that gets stronger with your workouts. Dogs are perfect for fitness enthusiasts!"
        dogType.baseHealth = 120
        dogType.baseHappiness = 100
        dogType.evolutionTimeHours = 168
        dogType.spriteBaseName = "dog"
        dogType.isUnlocked = true
        
        // Evolution Stage 1: Puppy
        let puppy = EvolutionStage(context: context)
        puppy.stageNumber = 1
        puppy.name = "Pixel Pup"
        puppy.description_ = "An adorable digital puppy that bounds with excitement every time you exercise!"
        puppy.requiredHours = 0
        puppy.requiredExperience = 0
        puppy.spriteFileName = "dog_puppy"
        puppy.healthMultiplier = 1.0
        puppy.happinessMultiplier = 1.0
        puppy.petType = dogType
        
        // Evolution Stage 2: Athletic Dog
        let athleticDog = EvolutionStage(context: context)
        athleticDog.stageNumber = 2
        athleticDog.name = "Athletic Hound"
        athleticDog.description_ = "A strong and athletic digital dog. Your workout routine is making it incredibly fit!"
        athleticDog.requiredHours = 72
        athleticDog.requiredExperience = 600
        athleticDog.spriteFileName = "dog_athletic"
        athleticDog.healthMultiplier = 1.4
        athleticDog.happinessMultiplier = 1.2
        athleticDog.petType = dogType
        
        // Evolution Stage 3: Guardian Wolf
        let guardianWolf = EvolutionStage(context: context)
        guardianWolf.stageNumber = 3
        guardianWolf.name = "Guardian Wolf"
        guardianWolf.description_ = "A majestic digital wolf, the ultimate evolution of loyalty and strength. Your fitness journey has created a legendary companion!"
        guardianWolf.requiredHours = 168
        guardianWolf.requiredExperience = 1800
        guardianWolf.spriteFileName = "dog_wolf"
        guardianWolf.healthMultiplier = 1.8
        guardianWolf.happinessMultiplier = 1.4
        guardianWolf.petType = dogType
    }
    
    private func createDigitalBirdType() {
        let birdType = PetType(context: context)
        birdType.id = "digital_bird"
        birdType.name = "Digital Bird"
        birdType.description_ = "A graceful avian companion that soars higher with your step count. Perfect for walkers and runners!"
        birdType.baseHealth = 80
        birdType.baseHappiness = 110
        birdType.evolutionTimeHours = 168
        birdType.spriteBaseName = "bird"
        birdType.isUnlocked = false // Unlocked after raising first pet
        
        // Evolution Stage 1: Hatchling
        let hatchling = EvolutionStage(context: context)
        hatchling.stageNumber = 1
        hatchling.name = "Digital Chick"
        hatchling.description_ = "A small digital bird that chirps happily with every step you take!"
        hatchling.requiredHours = 0
        hatchling.requiredExperience = 0
        hatchling.spriteFileName = "bird_chick"
        hatchling.healthMultiplier = 1.0
        hatchling.happinessMultiplier = 1.0
        hatchling.petType = birdType
        
        // Evolution Stage 2: Swift Bird
        let swiftBird = EvolutionStage(context: context)
        swiftBird.stageNumber = 2
        swiftBird.name = "Swift Flyer"
        swiftBird.description_ = "A fast and agile digital bird. Your daily walks are helping it develop incredible speed!"
        swiftBird.requiredHours = 72
        swiftBird.requiredExperience = 400
        swiftBird.spriteFileName = "bird_swift"
        swiftBird.healthMultiplier = 1.2
        swiftBird.happinessMultiplier = 1.4
        swiftBird.petType = birdType
        
        // Evolution Stage 3: Phoenix
        let phoenix = EvolutionStage(context: context)
        phoenix.stageNumber = 3
        phoenix.name = "Digital Phoenix"
        phoenix.description_ = "A magnificent digital phoenix that represents rebirth and endless energy. Your consistent activity has created something truly special!"
        phoenix.requiredHours = 168
        phoenix.requiredExperience = 1200
        phoenix.spriteFileName = "bird_phoenix"
        phoenix.healthMultiplier = 1.5
        phoenix.happinessMultiplier = 1.8
        phoenix.petType = birdType
    }
    
    // MARK: - Pet Type Management
    
    func unlockPetType(_ petTypeID: String) {
        let request: NSFetchRequest<PetType> = PetType.fetchRequest()
        request.predicate = NSPredicate(format: "id == %@", petTypeID)
        
        do {
            if let petType = try context.fetch(request).first {
                petType.isUnlocked = true
                persistenceController.save()
                print("🔓 Unlocked pet type: \(petType.name)")
            }
        } catch {
            print("Failed to unlock pet type: \(error.localizedDescription)")
        }
    }
    
    func getUnlockedPetTypes() -> [PetType] {
        let request: NSFetchRequest<PetType> = PetType.fetchRequest()
        request.predicate = NSPredicate(format: "isUnlocked == YES")
        request.sortDescriptors = [NSSortDescriptor(keyPath: \PetType.name, ascending: true)]
        
        do {
            return try context.fetch(request)
        } catch {
            print("Failed to fetch unlocked pet types: \(error.localizedDescription)")
            return []
        }
    }
    
    func getAllPetTypes() -> [PetType] {
        let request: NSFetchRequest<PetType> = PetType.fetchRequest()
        request.sortDescriptors = [NSSortDescriptor(keyPath: \PetType.name, ascending: true)]
        
        do {
            return try context.fetch(request)
        } catch {
            print("Failed to fetch all pet types: \(error.localizedDescription)")
            return []
        }
    }
}
