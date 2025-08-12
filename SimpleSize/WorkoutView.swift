//
//  WorkoutView.swift
//  SimpleSize
//
//  Created by Quintin Smith on 8/11/25.
//

import SwiftUI
import SwiftData

struct WorkoutView: View {
    @Environment(\.modelContext) private var modelContext
    @Environment(\.dismiss) private var dismiss
    
    let exercise: Exercise
    
    @State private var currentWeight: String = ""
    @State private var currentReps: String = ""
    @State private var todaysSets: [WorkoutSet] = []
    @State private var isSetsExpanded = false
    @FocusState private var isWeightFocused: Bool
    @FocusState private var isRepsFocused: Bool
    
    init(exercise: Exercise) {
        self.exercise = exercise
    }
    
    var body: some View {
        ZStack {
            // Background gradient
            LinearGradient(
                colors: [Color(.systemBackground), Color(.systemGray6).opacity(0.3)],
                startPoint: .top,
                endPoint: .bottom
            )
            .ignoresSafeArea()
            
            VStack(spacing: 0) {
                // Header with exercise name
                VStack(spacing: 16) {
                    Text(exercise.name)
                        .font(.system(size: 32, weight: .bold, design: .rounded))
                        .foregroundColor(.primary)
                        .multilineTextAlignment(.center)
                        .padding(.top, 20)
                    
                    // Quick stats
                    if !todaysSets.isEmpty {
                        HStack(spacing: 24) {
                            StatCard(
                                title: "Sets",
                                value: "\(todaysSets.count)",
                                color: .blue
                            )
                            
                            StatCard(
                                title: "Volume",
                                value: "\(Int(todaysSets.reduce(0) { $0 + ($1.weight * Double($1.reps)) })) lbs",
                                color: .green
                            )
                            
                            if let bestSet = todaysSets.max(by: { $0.weight < $1.weight }) {
                                StatCard(
                                    title: "Best",
                                    value: "\(Int(bestSet.weight)) lbs",
                                    color: .orange
                                )
                            }
                        }
                        .padding(.horizontal)
                    }
                }
                
                Spacer()
                
                // Main input section
                VStack(spacing: 32) {
                    // Weight and Reps inputs
                    HStack(spacing: 20) {
                        // Weight Input
                        VStack(spacing: 12) {
                            Text("Weight")
                                .font(.headline)
                                .foregroundColor(.secondary)
                            
                            ZStack {
                                RoundedRectangle(cornerRadius: 20)
                                    .fill(Color(.systemBackground))
                                    .shadow(color: .black.opacity(0.1), radius: 8, x: 0, y: 4)
                                
                                HStack(spacing: 8) {
                                    TextField("0", text: $currentWeight)
                                        .font(.system(size: 36, weight: .bold, design: .rounded))
                                        .keyboardType(.numberPad)
                                        .multilineTextAlignment(.center)
                                        .focused($isWeightFocused)
                                        .foregroundColor(.primary)
                                    
                                    Text("lbs")
                                        .font(.title2)
                                        .foregroundColor(.secondary)
                                        .fontWeight(.medium)
                                }
                                .padding(.horizontal, 20)
                            }
                            .frame(height: 80)
                        }
                        .frame(maxWidth: .infinity)
                        
                        // Reps Input
                        VStack(spacing: 12) {
                            Text("Reps")
                                .font(.headline)
                                .foregroundColor(.secondary)
                            
                            ZStack {
                                RoundedRectangle(cornerRadius: 20)
                                    .fill(Color(.systemBackground))
                                    .shadow(color: .black.opacity(0.1), radius: 8, x: 0, y: 4)
                                
                                TextField("0", text: $currentReps)
                                    .font(.system(size: 36, weight: .bold, design: .rounded))
                                    .keyboardType(.numberPad)
                                    .multilineTextAlignment(.center)
                                    .focused($isRepsFocused)
                                    .foregroundColor(.primary)
                                    .padding(.horizontal, 20)
                            }
                            .frame(height: 80)
                        }
                        .frame(maxWidth: .infinity)
                    }
                    .padding(.horizontal)
                    
                    // Add Set Button
                    Button(action: addSet) {
                        HStack(spacing: 12) {
                            Image(systemName: "plus.circle.fill")
                                .font(.title2)
                            Text("Add Set")
                                .font(.title2)
                                .fontWeight(.semibold)
                        }
                        .foregroundColor(.white)
                        .frame(maxWidth: .infinity)
                        .frame(height: 56)
                        .background(
                            LinearGradient(
                                colors: [Color.accentColor, Color.accentColor.opacity(0.8)],
                                startPoint: .leading,
                                endPoint: .trailing
                            )
                        )
                        .cornerRadius(28)
                        .shadow(color: .accentColor.opacity(0.3), radius: 12, x: 0, y: 6)
                    }
                    .disabled(currentWeight.isEmpty || currentReps.isEmpty)
                    .padding(.horizontal)
                    
                                         // Today's Sets
                     if !todaysSets.isEmpty {
                         VStack(spacing: 16) {
                             Button(action: { isSetsExpanded.toggle() }) {
                                 HStack {
                                     Text("Today's Sets")
                                         .font(.title3)
                                         .fontWeight(.semibold)
                                         .foregroundColor(.primary)
                                     
                                     Spacer()
                                     
                                     HStack(spacing: 6) {
                                         Text("\(todaysSets.count)")
                                             .font(.title3)
                                             .fontWeight(.bold)
                                             .foregroundColor(.accentColor)
                                         
                                         Image(systemName: isSetsExpanded ? "chevron.up" : "chevron.down")
                                             .font(.caption)
                                             .foregroundColor(.secondary)
                                     }
                                 }
                                 .padding(.horizontal, 20)
                                 .padding(.vertical, 12)
                                 .background(Color(.systemBackground))
                                 .cornerRadius(16)
                                 .shadow(color: .black.opacity(0.05), radius: 4, x: 0, y: 2)
                             }
                             .buttonStyle(PlainButtonStyle())
                             
                             if isSetsExpanded {
                                 // Scrollable sets section with max height
                                 ScrollView {
                                     LazyVStack(spacing: 12) {
                                         ForEach(Array(todaysSets.enumerated()), id: \.element.id) { index, set in
                                             SetRowView(setNumber: index + 1, weight: set.weight, reps: set.reps)
                                         }
                                     }
                                     .padding(.bottom, 8) // Add some bottom padding for scroll
                                 }
                                 .frame(maxHeight: 300) // Limit height so it doesn't push buttons off screen
                                 .transition(.asymmetric(
                                     insertion: .scale.combined(with: .opacity),
                                     removal: .scale.combined(with: .opacity)
                                 ))
                             }
                         }
                         .padding(.horizontal)
                     }
                }
                
                Spacer()
                
                // Finish Exercise Button
                if !todaysSets.isEmpty {
                    Button(action: finishWorkout) {
                        HStack(spacing: 12) {
                            Image(systemName: "checkmark.circle.fill")
                                .font(.title2)
                            Text("Finish Exercise")
                                .font(.title2)
                                .fontWeight(.semibold)
                        }
                        .foregroundColor(.white)
                        .frame(maxWidth: .infinity)
                        .frame(height: 56)
                        .background(
                            LinearGradient(
                                colors: [Color.green, Color.green.opacity(0.8)],
                                startPoint: .leading,
                                endPoint: .trailing
                            )
                        )
                        .cornerRadius(28)
                        .shadow(color: .green.opacity(0.3), radius: 12, x: 0, y: 6)
                    }
                    .padding(.horizontal)
                    .padding(.bottom, 30)
                }
            }
        }
        .navigationBarTitleDisplayMode(.inline)
        .onAppear {
            print("WorkoutView appeared for exercise: \(exercise.name)")
            loadTodaysSets()
        }
        .onDisappear {
            print("WorkoutView disappeared for exercise: \(exercise.name)")
        }
        .onTapGesture {
            // Dismiss keyboard when tapping outside
            isWeightFocused = false
            isRepsFocused = false
        }
    }
    
    private func addSet() {
        guard let weight = Double(currentWeight),
              let reps = Int(currentReps) else { return }
        
        let workoutSet = WorkoutSet(weight: weight, reps: reps, exercise: exercise)
        modelContext.insert(workoutSet)
        
        // Clear input fields
        currentWeight = ""
        currentReps = ""
        
        // Auto-focus weight field for next set
        isWeightFocused = true
        
        // Update local state immediately instead of reloading
        let today = Calendar.current.startOfDay(for: Date())
        
        // Add the new set to todaysSets immediately
        todaysSets.append(workoutSet)
        todaysSets.sort { $0.timestamp < $1.timestamp }
        
        // Try to save the context
        do {
            try modelContext.save()
        } catch {
            print("Error saving context: \(error)")
        }
    }
    
    private func loadTodaysSets() {
        let today = Calendar.current.startOfDay(for: Date())
        let tomorrow = Calendar.current.date(byAdding: .day, value: 1, to: today)!
        
        // Only update if we don't already have the data
        if todaysSets.isEmpty {
            todaysSets = exercise.workoutSets.filter { workoutSet in
                workoutSet.timestamp >= today && 
                workoutSet.timestamp < tomorrow
            }.sorted { $0.timestamp < $1.timestamp }
        }
    }
    
    private func finishWorkout() {
        // Mark all today's sets as completed
        for set in todaysSets {
            set.workoutCompletedAt = Date()
        }
        
        // Update exercise stats
        exercise.lastWorkoutDate = Date()
        exercise.totalSets += todaysSets.count
        exercise.totalVolume += todaysSets.reduce(0) { $0 + ($1.weight * Double($1.reps)) }
        
        dismiss()
    }
}

// MARK: - Supporting Views

struct StatCard: View {
    let title: String
    let value: String
    let color: Color
    
    var body: some View {
        VStack(spacing: 4) {
            Text(value)
                .font(.title2)
                .fontWeight(.bold)
                .foregroundColor(color)
            
            Text(title)
                .font(.caption)
                .foregroundColor(.secondary)
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 12)
        .background(Color(.systemBackground))
        .cornerRadius(12)
        .shadow(color: .black.opacity(0.05), radius: 4, x: 0, y: 2)
    }
}

struct SetRowView: View {
    let setNumber: Int
    let weight: Double
    let reps: Int
    
    var body: some View {
        HStack(spacing: 16) {
            // Set number badge
            ZStack {
                Circle()
                    .fill(Color.accentColor.opacity(0.1))
                    .frame(width: 32, height: 32)
                
                Text("\(setNumber)")
                    .font(.caption)
                    .fontWeight(.bold)
                    .foregroundColor(.accentColor)
            }
            
            // Set details
            VStack(alignment: .leading, spacing: 2) {
                Text("\(Int(weight)) lbs × \(reps) reps")
                    .font(.body)
                    .fontWeight(.medium)
                    .foregroundColor(.primary)
                
                Text("Set \(setNumber)")
                    .font(.caption)
                    .foregroundColor(.secondary)
            }
            
            Spacer()
            
            // Weight indicator
            Text("\(Int(weight))")
                .font(.title3)
                .fontWeight(.bold)
                .foregroundColor(.accentColor)
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 12)
        .background(Color(.systemBackground))
        .cornerRadius(16)
        .shadow(color: .black.opacity(0.05), radius: 4, x: 0, y: 2)
    }
}

#Preview {
    NavigationView {
        WorkoutView(exercise: Exercise(name: "Bench Press", bodyPart: "Chest"))
            .modelContainer(for: [Exercise.self, WorkoutSet.self], inMemory: true)
    }
}