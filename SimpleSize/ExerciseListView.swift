//
//  ExerciseListView.swift
//  SimpleSize
//
//  Created by Quintin Smith on 8/11/25.
//

import SwiftUI
import SwiftData

struct ExerciseListView: View {
    @Environment(\.modelContext) private var modelContext
    @Query private var exercises: [Exercise]
    
    private var filteredExercises: [Exercise] {
        exercises.filter { $0.bodyPart == bodyPart }
    }
    @State private var showingAddExercise = false
    @State private var newExerciseName = ""
    @State private var workoutViewExercise: Exercise?
    
    let bodyPart: String
    
    init(bodyPart: String) {
        self.bodyPart = bodyPart
        self._exercises = Query(filter: #Predicate<Exercise> { exercise in
            exercise.bodyPart == bodyPart
        })
    }
    
    private var workoutViewBinding: Binding<Bool> {
        Binding(
            get: { workoutViewExercise != nil },
            set: { if !$0 { workoutViewExercise = nil } }
        )
    }
    
    var body: some View {
        ScrollView(.vertical, showsIndicators: true) {
            VStack(spacing: 20) {
                // Clean header with exercise count only
                VStack(alignment: .leading, spacing: 8) {
                    HStack {
                        Text("\(filteredExercises.count) Exercises")
                            .font(.system(size: 18, weight: .semibold, design: .default))
                            .foregroundColor(.secondary)
                        
                        Spacer()
                        
                        Button(action: { showingAddExercise = true }) {
                            HStack(spacing: 6) {
                                Image(systemName: "plus.circle.fill")
                                    .font(.system(size: 16, weight: .semibold))
                                Text("Add Exercise")
                                    .font(.system(size: 16, weight: .semibold, design: .default))
                            }
                            .foregroundColor(.blue)
                        }
                    }
                }
                .frame(maxWidth: .infinity, alignment: .leading)
                .padding(.horizontal, 24)
                .padding(.top, 12)
                
                // Exercise List
                VStack(spacing: 12) {
                    ForEach(filteredExercises) { exercise in
                        HStack(spacing: 0) {
                            Button(action: {
                                print("🔄 Exercise button tapped: \(exercise.name)")
                                print("🔄 Exercise ID: \(exercise.id)")
                                print("🔄 Exercise bodyPart: \(exercise.bodyPart)")
                                print("🔄 Exercise name length: \(exercise.name.count)")
                                print("🔄 Exercise name raw: '\(exercise.name)'")
                                print("🔄 Exercise isCustom: \(exercise.isCustom)")
                                print("🔄 Exercise totalSets: \(exercise.totalSets)")
                                print("🔄 Exercise workoutSets count: \(exercise.workoutSets.count)")
                                
                                // Check if exercise name is empty and try to fix it
                                if exercise.name.isEmpty {
                                    print("⚠️ WARNING: Exercise name is empty! Attempting to fix...")
                                    if !exercise.bodyPart.isEmpty {
                                        let defaultNames = getDefaultExercises(for: exercise.bodyPart)
                                        if let firstDefault = defaultNames.first {
                                            exercise.name = firstDefault
                                            print("🔧 Fixed exercise name to: \(firstDefault)")
                                            
                                            do {
                                                try modelContext.save()
                                                print("✅ Successfully saved fixed exercise name")
                                            } catch {
                                                print("❌ Error saving fixed exercise name: \(error)")
                                                modelContext.rollback()
                                            }
                                        }
                                    }
                                }
                                
                                // Set the selected exercise first
                                workoutViewExercise = exercise
                                print("🔄 workoutViewExercise set to: \(workoutViewExercise?.name ?? "nil")")
                                
                                // Debug: Check state after setting
                                DispatchQueue.main.async {
                                    print("🔄 After state update - workoutViewExercise: \(workoutViewExercise?.name ?? "nil")")
                                }
                            }) {
                                ExerciseRowView(exercise: exercise, bodyPart: bodyPart)
                                    .contentShape(Rectangle())
                            }
                            .buttonStyle(PlainButtonStyle())
                            
                            // Delete button with better styling
                            Button(action: {
                                withAnimation {
                                    deleteExercise(offsets: IndexSet(integer: filteredExercises.firstIndex(of: exercise)!))
                                }
                            }) {
                                Image(systemName: "trash")
                                    .font(.system(size: 16, weight: .medium))
                                    .foregroundColor(.red)
                                    .frame(width: 44, height: 44)
                                    .background(Color.red.opacity(0.1))
                                    .cornerRadius(22)
                            }
                            .buttonStyle(PlainButtonStyle())
                        }
                        .background(Color(.systemBackground))
                        .cornerRadius(16)
                        .shadow(color: .black.opacity(0.05), radius: 4, x: 0, y: 2)
                        .padding(.horizontal, 20)
                    }
                    
                    // Add Exercise Button with better styling
                    Button(action: { showingAddExercise = true }) {
                        HStack(spacing: 12) {
                            Image(systemName: "plus.circle.fill")
                                .font(.system(size: 20, weight: .semibold))
                                .foregroundColor(.blue)
                            
                            Text("Add Exercise")
                                .font(.system(size: 18, weight: .bold, design: .default))
                                .foregroundColor(.blue)
                        }
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 20)
                        .background(
                            RoundedRectangle(cornerRadius: 16)
                                .fill(Color.blue.opacity(0.08))
                                .overlay(
                                    RoundedRectangle(cornerRadius: 16)
                                        .stroke(Color.blue.opacity(0.2), lineWidth: 1.5)
                                )
                        )
                    }
                    .padding(.horizontal, 20)
                    .padding(.top, 8)
                }
                .padding(.horizontal, 20)
                
                // Body Part Summary with better styling
                VStack(alignment: .leading, spacing: 18) {
                    HStack {
                        Image(systemName: "chart.line.uptrend.xyaxis")
                            .font(.system(size: 22, weight: .semibold, design: .default))
                            .foregroundColor(.green)
                        
                        Text("\(bodyPart) Summary")
                            .font(.system(size: 20, weight: .bold, design: .default))
                    }
                    .padding(.horizontal, 24)
                    
                    VStack(spacing: 16) {
                        SummaryRow(title: "Total Sets", value: "\(filteredExercises.reduce(0) { $0 + $1.totalSets })")
                        SummaryRow(title: "Exercises Completed", value: "\(filteredExercises.filter { $0.totalSets > 0 }.count)")
                        
                        if let lastWorkout = filteredExercises.compactMap({ $0.lastWorkoutDate }).max() {
                            SummaryRow(title: "Last Workout", value: formatDate(lastWorkout))
                        }
                    }
                    .padding(.horizontal, 24)
                    .padding(.vertical, 20)
                    .background(
                        RoundedRectangle(cornerRadius: 18)
                            .fill(Color(.systemBackground))
                            .shadow(color: .black.opacity(0.04), radius: 6, x: 0, y: 2)
                    )
                    .padding(.horizontal, 20)
                }
            }
            .padding(.vertical, 20)
        }
        .navigationTitle(bodyPart)
        .navigationBarTitleDisplayMode(.large)
        .alert("Add Exercise", isPresented: $showingAddExercise) {
            TextField("Exercise Name", text: $newExerciseName)
            Button("Add") {
                addExercise()
            }
            Button("Cancel", role: .cancel) { }
        } message: {
            Text("Enter the name of the new exercise")
        }
        .onAppear {
            print("🔄 ExerciseListView appeared for \(bodyPart)")
            
            // Prevent multiple calls that could cause loops
            DispatchQueue.main.async {
                if filteredExercises.isEmpty {
                    print("📝 Loading default exercises for \(bodyPart)")
                    loadDefaultExercises()
                } else {
                    print("📊 Found \(filteredExercises.count) existing exercises for \(bodyPart)")
                }
            }
        }
        .fullScreenCover(isPresented: workoutViewBinding, onDismiss: {
            workoutViewExercise = nil
        }, content: {
            VStack {
                if let exercise = workoutViewExercise {
                    NavigationStack {
                        WorkoutView(exercise: exercise)
                            .environment(\.modelContext, modelContext)
                            .navigationBarTitleDisplayMode(.inline)
                    }
                    .onAppear {
                        print("🔄 Opening WorkoutView for exercise: \(exercise.name)")
                        print("🔄 Exercise ID: \(exercise.id)")
                        print("🔄 Exercise bodyPart: \(exercise.bodyPart)")
                        print("🔄 Exercise name length: \(exercise.name.count)")
                        print("🔄 Exercise name raw: '\(exercise.name)'")
                        print("🔄 Exercise isCustom: \(exercise.isCustom)")
                        print("🔄 Exercise totalSets: \(exercise.totalSets)")
                        print("🔄 Exercise workoutSets count: \(exercise.workoutSets.count)")
                    }
                } else {
                    VStack(spacing: 20) {
                        Text("No exercise selected")
                            .font(.title2)
                            .foregroundColor(.red)
                        
                        Text("workoutViewExercise is nil")
                            .font(.caption)
                            .foregroundColor(.secondary)
                        
                        Button("Close") {
                            workoutViewExercise = nil
                        }
                        .buttonStyle(.borderedProminent)
                    }
                    .onAppear {
                        print("❌ workoutViewExercise is nil!")
                        print("❌ workoutViewExercise value: \(workoutViewExercise?.name ?? "nil")")
                    }
                }
            }
        })
    }
    
    private func addExercise() {
        guard !newExerciseName.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty else { return }
        
        let exercise = Exercise(
            name: newExerciseName.trimmingCharacters(in: .whitespacesAndNewlines),
            bodyPart: bodyPart,
            isCustom: true
        )
        
        do {
            modelContext.insert(exercise)
            try modelContext.save()
            print("✅ Successfully added custom exercise: \(exercise.name)")
            
            newExerciseName = ""
            showingAddExercise = false
            
        } catch {
            print("❌ Error adding exercise: \(error)")
            // Rollback if save fails
            modelContext.rollback()
        }
    }
    
    private func deleteExercise(offsets: IndexSet) {
        withAnimation {
            do {
                for index in offsets {
                    let exerciseToDelete = filteredExercises[index]
                    modelContext.delete(exerciseToDelete)
                    print("🗑️ Marked for deletion: \(exerciseToDelete.name)")
                }
                
                try modelContext.save()
                print("💾 Successfully saved deletions")
                
            } catch {
                print("❌ Error deleting exercises: \(error)")
                // Rollback if save fails
                modelContext.rollback()
            }
        }
    }
    
    private func loadDefaultExercises() {
        guard filteredExercises.isEmpty else { return }
        
        print("🔄 Loading default exercises for \(bodyPart)")
        
        // First, clean up any existing exercises with empty names
        cleanupEmptyExerciseNames()
        
        let defaultExerciseNames = getDefaultExercises(for: bodyPart)
        
        do {
            for exerciseName in defaultExerciseNames {
                let exercise = Exercise(name: exerciseName, bodyPart: bodyPart)
                modelContext.insert(exercise)
                print("✅ Inserted: \(exercise.name)")
            }
            
            // Save after all insertions
            try modelContext.save()
            print("💾 Successfully saved default exercises")
            
        } catch {
            print("❌ Error saving default exercises: \(error)")
            // Rollback changes if save fails
            modelContext.rollback()
        }
    }
    
    private func cleanupEmptyExerciseNames() {
        let emptyNameExercises = exercises.filter { $0.name.isEmpty }
        if !emptyNameExercises.isEmpty {
            print("🧹 Cleaning up \(emptyNameExercises.count) exercises with empty names...")
            for exercise in emptyNameExercises {
                print("🧹 Marking for deletion: \(exercise.name)")
                modelContext.delete(exercise)
            }
            do {
                try modelContext.save()
                print("💾 Successfully saved deletions of empty name exercises")
            } catch {
                print("❌ Error saving deletions of empty name exercises: \(error)")
                modelContext.rollback()
            }
        } else {
            print("✅ No exercises with empty names found to clean up.")
        }
    }
    
    private func getDefaultExercises(for bodyPart: String) -> [String] {
        switch bodyPart {
        case "Chest":
            return ["Push-ups", "Bench Press", "Incline Press", "Dumbbell Flyes"]
        case "Back":
            return ["Pull-ups", "Rows", "Lat Pulldown", "Deadlift"]
        case "Shoulders":
            return ["Shoulder Press", "Lateral Raises", "Front Raises", "Rear Delt Flyes"]
        case "Arms":
            return ["Bicep Curls", "Tricep Dips", "Hammer Curls", "Overhead Extensions"]
        case "Legs":
            return ["Squats", "Lunges", "Leg Press", "Calf Raises"]
        case "Core":
            return ["Planks", "Crunches", "Russian Twists", "Dead Bug"]
        default:
            return []
        }
    }
    
    private func formatDate(_ date: Date) -> String {
        let formatter = DateFormatter()
        formatter.dateStyle = .medium
        formatter.timeStyle = .short
        return formatter.string(from: date)
    }
}

// MARK: - Supporting Views

struct ExerciseRowView: View {
    let exercise: Exercise
    let bodyPart: String
    
    private var exerciseStatusColor: Color {
        if exercise.totalSets > 0 {
            return exercise.totalSets >= 10 ? .green : .blue
        } else {
            return .gray
        }
    }
    
    private var exerciseIcon: String {
        let name = exercise.name.lowercased()
        if name.contains("press") || name.contains("push") {
            return "figure.arms.open"
        } else if name.contains("curl") || name.contains("row") || name.contains("pull") {
            return "figure.walk"
        } else if name.contains("squat") || name.contains("lunge") || name.contains("leg") {
            return "figure.walk"
        } else if name.contains("plank") || name.contains("crunch") || name.contains("core") {
            return "figure.core.training"
        } else if name.contains("fly") || name.contains("dip") {
            return "figure.arms.open"
        } else {
            return "dumbbell.fill"
        }
    }
    
    private var lastWorkoutText: String {
        if let lastDate = exercise.lastWorkoutDate {
            let formatter = DateFormatter()
            formatter.dateStyle = .short
            formatter.timeStyle = .none
            return formatter.string(from: lastDate)
        } else {
            return "No workouts"
        }
    }
    
    private var workoutSummary: String {
        if exercise.totalSets > 0 {
            return "\(Int(exercise.totalVolume)) lbs • \(exercise.totalSets) sets"
        } else {
            return "No previous workouts"
        }
    }
    
    var body: some View {
        HStack(spacing: 16) {
            // Status indicator
            ZStack {
                Circle()
                    .fill(exerciseStatusColor.opacity(0.15))
                    .frame(width: 48, height: 48)
                
                if exercise.totalSets > 0 {
                    Text("\(exercise.totalSets)")
                        .font(.system(size: 18, weight: .bold, design: .default))
                        .foregroundColor(exerciseStatusColor)
                } else {
                    Image(systemName: exerciseIcon)
                        .font(.system(size: 20, weight: .medium))
                        .foregroundColor(.gray)
                }
            }
            
            // Exercise details
            VStack(alignment: .leading, spacing: 6) {
                Text(exercise.name)
                    .font(.system(size: 18, weight: .semibold, design: .default))
                    .foregroundColor(.primary)
                
                Text(workoutSummary)
                    .font(.system(size: 14, weight: .medium, design: .default))
                    .foregroundColor(.secondary)
                
                if exercise.totalSets > 0 {
                    HStack(spacing: 8) {
                        Image(systemName: "clock")
                            .font(.system(size: 12, weight: .medium))
                            .foregroundColor(.green)
                        
                        Text(lastWorkoutText)
                            .font(.system(size: 12, weight: .medium, design: .default))
                            .foregroundColor(.green)
                    }
                }
            }
            
            Spacer()
            
            // Navigation arrow
            Image(systemName: "chevron.right")
                .font(.system(size: 14, weight: .medium))
                .foregroundColor(.secondary.opacity(0.6))
        }
        .padding(.horizontal, 20)
        .padding(.vertical, 16)
        .background(
            RoundedRectangle(cornerRadius: 12)
                .fill(Color(.systemBackground))
                .shadow(color: .black.opacity(0.05), radius: 2, x: 0, y: 1)
        )
    }
}

struct SummaryRow: View {
    let title: String
    let value: String
    
    var body: some View {
        HStack(spacing: 16) {
            Text(title)
                .font(.system(size: 17, weight: .medium, design: .default))
                .foregroundColor(.secondary)
            
            Spacer()
            
            Text(value)
                .font(.system(size: 19, weight: .semibold, design: .default))
                .foregroundColor(.primary)
        }
        .padding(.horizontal, 6)
        .padding(.vertical, 4)
    }
}

#Preview {
    ExerciseListView(bodyPart: "Chest")
        .modelContainer(for: Exercise.self, inMemory: true)
}