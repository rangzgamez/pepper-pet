import SwiftUI
import CoreData
import Combine

// MARK: - Pet Display ViewModel

class PetDisplayViewModel: ObservableObject {
    @Published var pet: Pet
    @Published var currentStage: EvolutionStage?
    @Published var nextStage: EvolutionStage?
    @Published var timeUntilEvolution: String = ""
    @Published var experienceProgress: Double = 0.0
    @Published var healthProgress: Double = 0.0
    
    private var cancellables = Set<AnyCancellable>()
    private let petService: PetService
    
    init(pet: Pet, petService: PetService) {
        self.pet = pet
        self.petService = petService
        
        updateStageInfo()
        setupTimers()
    }
    
    // MARK: - Computed Properties
    
    var displayName: String {
        return pet.name
    }
    
    var displayLevel: String {
        return "Level \(pet.level)"
    }
    
    var displayAge: String {
        let ageInHours = Int(Date().timeIntervalSince(pet.birthDate) / 3600)
        let days = ageInHours / 24
        let hours = ageInHours % 24
        
        if days > 0 {
            return "\(days)d \(hours)h old"
        } else {
            return "\(hours)h old"
        }
    }
    
    var healthStatus: String {
        switch pet.currentHealth {
        case 80...100: return "Excellent"
        case 60..<80: return "Good"
        case 40..<60: return "Fair"
        case 20..<40: return "Poor"
        default: return "Critical"
        }
    }
    
    var happinessEmoji: String {
        switch pet.happiness {
        case 80...100: return "😊"
        case 60..<80: return "🙂"
        case 40..<60: return "😐"
        case 20..<40: return "😟"
        default: return "😢"
        }
    }
    
    var evolutionStageDisplay: String {
        return currentStage?.name ?? "Unknown Stage"
    }
    
    var spriteFileName: String {
        return currentStage?.spriteFileName ?? pet.petType.spriteBaseName
    }
    
    // MARK: - Actions
    
    func interactWithPet() {
        petService.interactWithPet()
        updateProgressValues()
    }
    
    func feedPetManually() {
        // Create mock health data for manual feeding
        let mockHealthData = HealthDataInput(
            date: Date(),
            steps: 500,
            activeCalories: 50,
            exerciseMinutes: 5,
            standHours: 1,
            moveRingClosed: false,
            exerciseRingClosed: false,
            standRingClosed: false
        )
        
        petService.feedPet(with: mockHealthData)
        updateProgressValues()
    }
    
    // MARK: - Private Methods
    
    private func updateStageInfo() {
        // Find current evolution stage
        let stages = pet.petType.evolutionStages?.allObjects as? [EvolutionStage] ?? []
        currentStage = stages.first { $0.stageNumber == pet.evolutionStage }
        nextStage = stages.first { $0.stageNumber == pet.evolutionStage + 1 }
        updateProgressValues()
    }
    
    private func updateProgressValues() {
        // Health progress
        healthProgress = Double(pet.currentHealth) / Double(pet.maxHealth)
        
        // Experience progress to next level
        let currentXP = pet.experience
        let requiredXP = pet.level * pet.level * 100
        let previousLevelXP = (pet.level - 1) * (pet.level - 1) * 100
        let levelProgress = Double(currentXP - Int32(previousLevelXP)) / Double(requiredXP - previousLevelXP)
        experienceProgress = max(0.0, min(1.0, levelProgress))
        
        // Time until evolution
        if let nextStage = nextStage {
            let requiredHours = nextStage.requiredHours
            let currentHours = Int32(Int(Date().timeIntervalSince(pet.birthDate) / 3600))
            let hoursRemaining = max(0, requiredHours - currentHours)
            
            let requiredXP = nextStage.requiredExperience
            let currentXP = pet.experience
            let xpRemaining = max(0, requiredXP - currentXP)
            
            if hoursRemaining > 0 && xpRemaining > 0 {
                timeUntilEvolution = "\(hoursRemaining)h, \(xpRemaining) XP needed"
            } else if hoursRemaining > 0 {
                timeUntilEvolution = "\(hoursRemaining)h remaining"
            } else if xpRemaining > 0 {
                timeUntilEvolution = "\(xpRemaining) XP needed"
            } else {
                timeUntilEvolution = "Ready to evolve!"
            }
        } else {
            timeUntilEvolution = "Final evolution"
        }
    }
    
    private func setupTimers() {
        // Update display every minute
        Timer.publish(every: 60, on: .main, in: .common)
            .autoconnect()
            .sink { [weak self] _ in
                self?.updateProgressValues()
            }
            .store(in: &cancellables)
    }
}

// MARK: - Pet Creation ViewModel

class PetCreationViewModel: ObservableObject {
    @Published var selectedPetType: PetType?
    @Published var petName: String = ""
    @Published var availablePetTypes: [PetType] = []
    @Published var isCreating: Bool = false
    @Published var creationError: String?
    
    private let petService: PetService
    private let seedingService: DataSeedingService
    
    init(petService: PetService, seedingService: DataSeedingService) {
        self.petService = petService
        self.seedingService = seedingService
        loadAvailablePetTypes()
    }
    
    // MARK: - Computed Properties
    
    var canCreatePet: Bool {
        return !petName.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty &&
               selectedPetType != nil &&
               !isCreating
    }
    
    var selectedPetTypeDescription: String {
        return selectedPetType?.description_ ?? "Select a pet type to see details"
    }
    
    // MARK: - Actions
    
    func selectPetType(_ petType: PetType) {
        selectedPetType = petType
        if petName.isEmpty {
            // Suggest a default name based on pet type
            switch petType.id {
            case "digital_cat":
                petName = ["Pixel", "Byte", "Circuit", "Nova"].randomElement() ?? "Pixel"
            case "digital_dog":
                petName = ["Rex", "Bolt", "Cyber", "Scout"].randomElement() ?? "Rex"
            case "digital_bird":
                petName = ["Echo", "Swift", "Aurora", "Zephyr"].randomElement() ?? "Echo"
            default:
                petName = "Pepper"
            }
        }
    }
    
    func createPet() {
        guard let petType = selectedPetType else {
            creationError = "Please select a pet type"
            return
        }
        
        let trimmedName = petName.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmedName.isEmpty else {
            creationError = "Please enter a pet name"
            return
        }
        
        guard trimmedName.count <= 20 else {
            creationError = "Pet name must be 20 characters or less"
            return
        }
        
        isCreating = true
        creationError = nil
        
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) { [weak self] in
            if let createdPet = self?.petService.createPet(name: trimmedName, petTypeID: petType.id) {
                print("🎉 Created new pet: \(createdPet.name)")
                self?.resetForm()
            } else {
                self?.creationError = "Failed to create pet. Please try again."
            }
            self?.isCreating = false
        }
    }
    
    private func resetForm() {
        petName = ""
        selectedPetType = nil
        creationError = nil
    }
    
    private func loadAvailablePetTypes() {
        availablePetTypes = seedingService.getUnlockedPetTypes()
    }
}

// MARK: - App State ViewModel

class AppStateViewModel: ObservableObject {
    @Published var currentPet: Pet?
    @Published var appState: AppState = .loading
    @Published var showingPetCreation: Bool = false
    @Published var showingSettings: Bool = false
    
    // Child ViewModels
    @Published var petDisplayViewModel: PetDisplayViewModel?
    @Published var petCreationViewModel: PetCreationViewModel
    @Published var healthIntegrationViewModel: HealthIntegrationViewModel
    
    private let petService: PetService
    private let healthKitService: HealthKitService
    private let seedingService: DataSeedingService
    private var cancellables = Set<AnyCancellable>()
    
    enum AppState {
        case loading
        case noPet
        case hasPet
        case error(String)
        
        var showsPetCreation: Bool {
            if case .noPet = self { return true }
            return false
        }
    }
    
    init(petService: PetService, healthKitService: HealthKitService, seedingService: DataSeedingService) {
        self.petService = petService
        self.healthKitService = healthKitService
        self.seedingService = seedingService
        
        // Initialize child ViewModels
        self.petCreationViewModel = PetCreationViewModel(petService: petService, seedingService: seedingService)
        self.healthIntegrationViewModel = HealthIntegrationViewModel(healthKitService: healthKitService)
        
        setupObservers()
        loadInitialState()
    }
    
    private func setupObservers() {
        // Observe current pet changes
        petService.$currentPet
            .sink { [weak self] pet in
                self?.currentPet = pet
                self?.updateAppState()
                self?.updatePetDisplayViewModel()
            }
            .store(in: &cancellables)
    }
    
    private func loadInitialState() {
        appState = .loading
        
        // Small delay to show loading state
        DispatchQueue.main.asyncAfter(deadline: .now() + 1.0) { [weak self] in
            self?.updateAppState()
        }
    }
    
    private func updateAppState() {
        if let pet = currentPet, pet.isAlive {
            appState = .hasPet
            showingPetCreation = false
        } else {
            appState = .noPet
            showingPetCreation = true
        }
    }
    
    private func updatePetDisplayViewModel() {
        if let pet = currentPet, pet.isAlive {
            petDisplayViewModel = PetDisplayViewModel(pet: pet, petService: petService)
        } else {
            petDisplayViewModel = nil
        }
    }
    
    // MARK: - Actions
    
    func showPetCreation() {
        showingPetCreation = true
    }
    
    func hidePetCreation() {
        showingPetCreation = false
    }
    
    func showSettings() {
        showingSettings = true
    }
    
    func hideSettings() {
        showingSettings = false
    }
    
    func handlePetDeath() {
        appState = .noPet
        showingPetCreation = true
        petDisplayViewModel = nil
    }
}

// MARK: - Health Integration ViewModel

class HealthIntegrationViewModel: ObservableObject {
    @Published var isHealthKitAuthorized: Bool = false
    @Published var todayActivityRings: ActivityRingsData?
    @Published var isRequestingPermission: Bool = false
    @Published var lastSyncTime: Date?
    @Published var syncStatus: SyncStatus = .idle
    
    private let healthKitService: HealthKitService
    private var cancellables = Set<AnyCancellable>()
    
    init(healthKitService: HealthKitService) {
        self.healthKitService = healthKitService
        
        // Observe HealthKit service changes
        healthKitService.$isAuthorized
            .assign(to: \.isHealthKitAuthorized, on: self)
            .store(in: &cancellables)
        
        healthKitService.$todayActivityRings
            .sink { [weak self] rings in
                self?.todayActivityRings = rings
                if rings != nil {
                    self?.lastSyncTime = Date()
                    self?.syncStatus = .synced
                }
            }
            .store(in: &cancellables)
    }
    
    enum SyncStatus {
        case idle
        case syncing
        case synced
        case error
        
        var displayText: String {
            switch self {
            case .idle: return "Not synced"
            case .syncing: return "Syncing..."
            case .synced: return "Synced"
            case .error: return "Sync failed"
            }
        }
        
        var color: Color {
            switch self {
            case .idle: return .gray
            case .syncing: return .blue
            case .synced: return .green
            case .error: return .red
            }
        }
    }
    
    // MARK: - Computed Properties
    
    var activitySummary: String {
        guard let rings = todayActivityRings else {
            return "No activity data available"
        }
        
        let completedRings = (rings.moveRingClosed ? 1 : 0) +
                           (rings.exerciseRingClosed ? 1 : 0) +
                           (rings.standRingClosed ? 1 : 0)
        
        return "\(completedRings)/3 rings closed • \(rings.steps) steps"
    }
    
    var lastSyncDisplay: String {
        guard let lastSync = lastSyncTime else {
            return "Never synced"
        }
        
        let formatter = RelativeDateTimeFormatter()
        formatter.unitsStyle = .abbreviated
        return "Synced \(formatter.localizedString(for: lastSync, relativeTo: Date()))"
    }
    
    // MARK: - Actions
    
    func requestHealthKitPermission() {
        isRequestingPermission = true
        syncStatus = .syncing
        
        healthKitService.requestAuthorization()
        
        DispatchQueue.main.asyncAfter(deadline: .now() + 2.0) { [weak self] in
            self?.isRequestingPermission = false
            if self?.isHealthKitAuthorized == true {
                self?.syncStatus = .synced
            } else {
                self?.syncStatus = .error
            }
        }
    }
    
    func refreshHealthData() {
        syncStatus = .syncing
        healthKitService.loadTodayActivityData()
    }
}
