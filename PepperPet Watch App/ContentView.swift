import SwiftUI

struct ContentView: View {
    @State private var petHealth = 100.0
    @State private var petHappiness = 85.0
    @State private var petLevel = 1
    
    var body: some View {
        VStack {
            Text("🌶️ Pepper Pet")
                .font(.headline)
                .padding(.bottom, 5)
            
            // Pet display
            Circle()
                .fill(Color.orange)
                .frame(width: 60, height: 60)
                .overlay(
                    Text("🐱")
                        .font(.title)
                )
            
            // Pet stats
            VStack(alignment: .leading, spacing: 2) {
                Text("Health: \(Int(petHealth))%")
                Text("Happy: \(Int(petHappiness))%")
                Text("Level: \(petLevel)")
            }
            .font(.caption)
            .padding(.top, 5)
            
            // Action buttons
            HStack {
                Button("Feed") {
                    petHealth = min(100, petHealth + 10)
                    petHappiness = min(100, petHappiness + 5)
                }
                .buttonStyle(.borderedProminent)
                .font(.caption)
                
                Button("Play") {
                    petHappiness = min(100, petHappiness + 10)
                }
                .buttonStyle(.bordered)
                .font(.caption)
            }
            .padding(.top, 5)
        }
        .padding()
    }
}
