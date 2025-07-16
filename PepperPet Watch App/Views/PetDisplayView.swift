import SwiftUI

// MARK: - Pet Display View

struct PetDisplayView: View {
    @ObservedObject var viewModel: PetDisplayViewModel
    
    var body: some View {
        ScrollView {
            VStack(spacing: 16) {
                // Pet Sprite and Basic Info
                PetSpriteView(spriteFileName: viewModel.spriteFileName)
                    .frame(width: 100, height: 100)
                    .background(
                        RoundedRectangle(cornerRadius: 16)
                            .fill(Color.blue.opacity(0.1))
                    )
                
                VStack(spacing: 4) {
                    Text(viewModel.displayName)
                        .font(.title2.bold())
                    
                    Text(viewModel.evolutionStageDisplay)
                        .font(.caption)
                        .foregroundColor(.secondary)
                    
                    Text(viewModel.displayAge)
                        .font(.caption2)
                        .foregroundColor(.secondary)
                }
                
                // Stats Section
                VStack(spacing: 8) {
                    HStack {
                        Text("Stats")
                            .font(.headline)
                        Spacer()
                        Text(viewModel.displayLevel)
                            .font(.caption.bold())
                            .foregroundColor(.blue)
                    }
                    
                    // Health Bar
                    StatBarView(
                        label: "Health",
                        value: viewModel.healthProgress,
                        color: .red,
                        text: "\(viewModel.pet.currentHealth)/\(viewModel.pet.maxHealth)"
                    )
                    
                    // Happiness Bar
                    StatBarView(
                        label: "Happiness",
                        value: Double(viewModel.pet.happiness) / 100.0,
                        color: .yellow,
                        text: "\(viewModel.pet.happiness)% \(viewModel.happinessEmoji)"
                    )
                    
                    // Experience Bar
                    StatBarView(
                        label: "Experience",
                        value: viewModel.experienceProgress,
                        color: .purple,
                        text: "\(viewModel.pet.experience) XP"
                    )
                }
                .padding()
                .background(
                    RoundedRectangle(cornerRadius: 12)
                        .fill(Color(.systemGray6))
                )
                
                // Evolution Progress
                if !viewModel.timeUntilEvolution.isEmpty && viewModel.timeUntilEvolution != "Final evolution" {
                    VStack(spacing: 4) {
                        HStack {
                            Text("Evolution")
                                .font(.headline)
                            Spacer()
                            if viewModel.timeUntilEvolution == "Ready to evolve!" {
                                Text("Ready! ✨")
                                    .font(.caption.bold())
                                    .foregroundColor(.green)
                            }
                        }
                        
                        Text(viewModel.timeUntilEvolution)
                            .font(.caption)
                            .foregroundColor(.secondary)
                    }
                    .padding()
                    .background(
                        RoundedRectangle(cornerRadius: 12)
                            .fill(Color(.systemGray6))
                    )
                }
                
                // Action Buttons
                VStack(spacing: 8) {
                    HStack(spacing: 8) {
                        Button(action: { viewModel.interactWithPet() }) {
                            Label("Play", systemImage: "hand.wave.fill")
                                .font(.caption)
                                .frame(maxWidth: .infinity)
                        }
                        .buttonStyle(.borderedProminent)
                        
                        Button(action: { viewModel.feedPetManually() }) {
                            Label("Feed", systemImage: "heart.fill")
                                .font(.caption)
                                .frame(maxWidth: .infinity)
                        }
                        .buttonStyle(.bordered)
                    }
                    
                    Text("💡 Walk or exercise to automatically feed your pet!")
                        .font(.caption2)
                        .foregroundColor(.secondary)
                        .multilineTextAlignment(.center)
                }
            }
            .padding()
        }
        .navigationTitle("🌶️ \(viewModel.displayName)")
        .navigationBarTitleDisplayMode(.inline)
    }
}

// MARK: - Pet Creation View

struct PetCreationView: View {
    @ObservedObject var viewModel: PetCreationViewModel
    @State private var showingPetTypeSelector = false
    
    var body: some View {
        VStack(spacing: 16) {
            // Header
            VStack(spacing: 4) {
                Text("Create Your Pet")
                    .font(.headline.bold())
                Text("Choose a companion!")
                    .font(.caption)
                    .foregroundColor(.secondary)
            }
            
            // Pet Type Selection
            if let selectedType = viewModel.selectedPetType {
                VStack(spacing: 8) {
                    PetSpriteView(spriteFileName: selectedType.spriteBaseName)
                        .frame(width: 60, height: 60)
                    
                    Text(selectedType.name)
                        .font(.caption.bold())
                    
                    Button("Change Type") {
                        showingPetTypeSelector = true
                    }
                    .font(.caption2)
                }
                .padding()
                .background(
                    RoundedRectangle(cornerRadius: 12)
                        .stroke(Color.blue, lineWidth: 1)
                )
            } else {
                Button("Choose Pet Type") {
                    showingPetTypeSelector = true
                }
                .buttonStyle(.borderedProminent)
            }
            
            // Pet Name Input
            VStack(alignment: .leading, spacing: 4) {
                Text("Pet Name")
                    .font(.caption.bold())
                
                TextField("Enter name...", text: $viewModel.petName)
                    .textFieldStyle(.roundedBorder)
                    .autocorrectionDisabled()
            }
            
            Spacer()
            
            // Error Message
            if let error = viewModel.creationError {
                Text(error)
                    .foregroundColor(.red)
                    .font(.caption2)
            }
            
            // Create Button
            Button(action: { viewModel.createPet() }) {
                if viewModel.isCreating {
                    HStack {
                        ProgressView()
                            .scaleEffect(0.8)
                        Text("Creating...")
                    }
                } else {
                    Text("Create Pet")
                }
            }
            .buttonStyle(.borderedProminent)
            .disabled(!viewModel.canCreatePet)
            .frame(maxWidth: .infinity)
        }
        .padding()
        .navigationTitle("🌶️ New Pet")
        .sheet(isPresented: $showingPetTypeSelector) {
            PetTypeSelectorView(
                petTypes: viewModel.availablePetTypes,
                onSelect: { petType in
                    viewModel.selectPetType(petType)
                    showingPetTypeSelector = false
                }
            )
        }
    }
}

// MARK: - Pet Type Selector

struct PetTypeSelectorView: View {
    let petTypes: [PetType]
    let onSelect: (PetType) -> Void
    @Environment(\.dismiss) private var dismiss
    
    var body: some View {
        NavigationView {
            ScrollView {
                LazyVGrid(columns: [GridItem(.flexible()), GridItem(.flexible())], spacing: 12) {
                    ForEach(petTypes, id: \.id) { petType in
                        Button(action: { onSelect(petType) }) {
                            VStack(spacing: 8) {
                                PetSpriteView(spriteFileName: petType.spriteBaseName)
                                    .frame(height: 60)
                                
                                Text(petType.name)
                                    .font(.caption.bold())
                                    .multilineTextAlignment(.center)
                                
                                if let description = petType.description_ {
                                    Text(description)
                                        .font(.caption2)
                                        .foregroundColor(.secondary)
                                        .multilineTextAlignment(.center)
                                        .lineLimit(2)
                                }
                            }
                            .padding(8)
                            .background(
                                RoundedRectangle(cornerRadius: 8)
                                    .fill(Color(.systemGray6))
                            )
                        }
                        .buttonStyle(.plain)
                    }
                }
                .padding()
            }
            .navigationTitle("Choose Pet")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Cancel") {
                        dismiss()
                    }
                }
            }
        }
    }
}

// MARK: - Supporting Views

struct PetSpriteView: View {
    let spriteFileName: String
    
    var body: some View {
        // Placeholder for actual sprite
        RoundedRectangle(cornerRadius: 12)
            .fill(
                LinearGradient(
                    colors: [.blue.opacity(0.3), .purple.opacity(0.3)],
                    startPoint: .topLeading,
                    endPoint: .bottomTrailing
                )
            )
            .overlay {
                Text("🐾")
                    .font(.system(size: 24))
            }
    }
}

struct StatBarView: View {
    let label: String
    let value: Double
    let color: Color
    let text: String
    
    var body: some View {
        VStack(alignment: .leading, spacing: 2) {
            HStack {
                Text(label)
                    .font(.caption2.bold())
                Spacer()
                Text(text)
                    .font(.caption2)
                    .foregroundColor(.secondary)
            }
            
            GeometryReader { geometry in
                ZStack(alignment: .leading) {
                    RoundedRectangle(cornerRadius: 2)
                        .fill(Color(.systemGray5))
                    
                    RoundedRectangle(cornerRadius: 2)
                        .fill(color)
                        .frame(width: geometry.size.width * value)
                }
            }
            .frame(height: 6)
        }
    }
}

// MARK: - Preview Helpers

#if DEBUG
struct PetDisplayView_Previews: PreviewProvider {
    static var previews: some View {
        NavigationView {
            Text("Preview not available - needs Core Data setup")
        }
    }
}
#endif
