//
//  PetRepository.swift
//  PepperPet
//
//  Created by Daniel Rangel on 7/15/25.
//

import Foundation
import CoreData

// MARK: - Repository Protocol
protocol PetRepositoryProtocol {
    func fetchActivePet() -> Result<Pet?, CoreDataService.CoreDataError>
    func createPet(name: String, type: String) -> Result<Pet, CoreDataService.CoreDataError>
    func updatePet(_ pet: Pet) -> Result<Void, CoreDataService.CoreDataError>
    func getAllPets() -> Result<[Pet], CoreDataService.CoreDataError>
}

// MARK: - Pet Repository Implementation
class PetRepository: PetRepositoryProtocol {
    private let coreDataService: CoreDataService
    
    init(coreDataService: CoreDataService = .shared) {
        self.coreDataService = coreDataService
    }
    
    func fetchActivePet() -> Result<Pet?, CoreDataService.CoreDataError> {
        let request: NSFetchRequest<Pet> = Pet.fetchRequest()
        request.predicate = NSPredicate(format: "isDead == NO OR isDead == nil")
        request.sortDescriptors = [NSSortDescriptor(key: "createdAt", ascending: false)]
        request.fetchLimit = 1
        
        do {
            let pets = try coreDataService.viewContext.fetch(request)
            return .success(pets.first)
        } catch {
            return .failure(.fetchFailed(error))
        }
    }
    
    func createPet(name: String, type: String) -> Result<Pet, CoreDataService.CoreDataError> {
        let context = coreDataService.viewContext
        let pet = Pet(context: context)
        
        pet.id = UUID()
        pet.name = name
        pet.type = type
        pet.health = 100.0
        pet.happiness = 80.0
        pet.level = 1
        pet.isDead = false
        pet.createdAt = Date()
        pet.lastFed = Date()
        
        switch coreDataService.save() {
        case .success:
            return .success(pet)
        case .failure(let error):
            return .failure(error)
        }
    }
    
    func updatePet(_ pet: Pet) -> Result<Void, CoreDataService.CoreDataError> {
        return coreDataService.save()
    }
    
    func getAllPets() -> Result<[Pet], CoreDataService.CoreDataError> {
        let request: NSFetchRequest<Pet> = Pet.fetchRequest()
        request.sortDescriptors = [NSSortDescriptor(key: "createdAt", ascending: false)]
        
        do {
            let pets = try coreDataService.viewContext.fetch(request)
            return .success(pets)
        } catch {
            return .failure(.fetchFailed(error))
        }
    }
}
