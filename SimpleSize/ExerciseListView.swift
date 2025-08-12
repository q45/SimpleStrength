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
    @State private var showingAddExercise = false
    @State private var newExerciseName = ""
    
    let bodyPart: String
    
    init(bodyPart: String) {
        self.bodyPart = bodyPart
        self._exercises = Query(filter: #Predicate<Exercise> { exercise in
            exercise.bodyPart == bodyPart
        })
    }
    
    var body: some View {
        ScrollView {
            VStack(spacing: 20) {
                // Exercise List
                VStack(spacing: 0) {
                    ForEach(exercises) { exercise in
                        HStack {
                            NavigationLink(destination: WorkoutView(exercise: exercise)) {
                                ExerciseRowView(exercise: exercise, bodyPart: bodyPart)
                            }
                            .buttonStyle(PlainButtonStyle())
                            
                            // Delete button
                            Button(action: {
                                withAnimation {
                                    modelContext.delete(exercise)
                                }
                            }) {
                                Image(systemName: "trash")
                                    .font(.title3)
                                    .foregroundColor(.red)
                                    .padding(.horizontal, 12)
                            }
                        }
                        
                        if exercise.id != exercises.last?.id {
                            Divider()
                                .padding(.horizontal)
                        }
                    }
                    
                    // Add Exercise Button
                    Button(action: { showingAddExercise = true }) {
                        HStack(spacing: 12) {
                            Image(systemName: "plus.circle.fill")
                                .font(.title2)
                                .foregroundColor(.blue)
                            
                            Text("Add Exercise")
                                .font(.system(size: 18, weight: .bold, design: .default))
                                .foregroundColor(.blue)
                        }
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 16)
                        .background(Color.blue.opacity(0.1))
                        .cornerRadius(12)
                        .overlay(
                            RoundedRectangle(cornerRadius: 12)
                                .stroke(Color.blue.opacity(0.3), style: StrokeStyle(lineWidth: 1, dash: [5]))
                        )
                    }
                    .padding(.horizontal)
                    .padding(.top, 8)
                }
                .background(Color(.systemBackground))
                .cornerRadius(16)
                .shadow(color: .black.opacity(0.05), radius: 4, x: 0, y: 2)
                .padding(.horizontal)
                
                // Body Part Summary
                VStack(alignment: .leading, spacing: 16) {
                    HStack {
                        Image(systemName: "chart.line.uptrend.xyaxis")
                            .font(.system(size: 24, weight: .semibold, design: .default))
                            .foregroundColor(.green)
                        
                        Text("\(bodyPart) Summary")
                            .font(.system(size: 20, weight: .bold, design: .default))
                    }
                    
                    VStack(spacing: 12) {
                        SummaryRow(title: "Total Sets", value: "\(exercises.reduce(0) { $0 + $1.totalSets })")
                        SummaryRow(title: "Exercises Completed", value: "\(exercises.filter { $0.totalSets > 0 }.count)")
                        
                        if let lastWorkout = exercises.compactMap({ $0.lastWorkoutDate }).max() {
                            SummaryRow(title: "Last Workout", value: formatDate(lastWorkout))
                        }
                    }
                }
                .padding(20)
                .background(Color(.systemBackground))
                .cornerRadius(16)
                .shadow(color: .black.opacity(0.05), radius: 4, x: 0, y: 2)
                .padding(.horizontal)
            }
            .padding(.vertical)
        }
        .navigationTitle(bodyPart)
        .toolbar {
            ToolbarItem(placement: .navigationBarTrailing) {
                Button("Add Exercise") {
                    showingAddExercise = true
                }
            }
        }
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
            loadDefaultExercises()
        }
    }
    
    private func addExercise() {
        guard !newExerciseName.isEmpty else { return }
        
        let exercise = Exercise(name: newExerciseName, bodyPart: bodyPart, isCustom: true)
        modelContext.insert(exercise)
        newExerciseName = ""
    }
    
    private func deleteExercise(offsets: IndexSet) {
        withAnimation {
            for index in offsets {
                modelContext.delete(exercises[index])
            }
        }
    }
    
    private func loadDefaultExercises() {
        let defaultExercises = getDefaultExercises(for: bodyPart)
        
        for exerciseName in defaultExercises {
            let existingExercise = exercises.first { $0.name == exerciseName && !$0.isCustom }
            if existingExercise == nil {
                let exercise = Exercise(name: exerciseName, bodyPart: bodyPart)
                modelContext.insert(exercise)
            }
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
            // Gradient from green to blue based on progress
            return exercise.totalSets >= 10 ? .green : .blue
        } else {
            // Gray for exercises not started
            return .gray
        }
    }
    
    private var exerciseStatusGradient: [Color] {
        if exercise.totalSets > 0 {
            if exercise.totalSets >= 10 {
                // Green gradient for high progress
                return [.green, .green.opacity(0.8)]
            } else {
                // Blue gradient for moderate progress
                return [.blue, .blue.opacity(0.7)]
            }
        } else {
            // Black gradient for not started
            return [.black, .black.opacity(0.6)]
        }
    }
    
    private var exerciseIcon: String {
        // Different icons based on exercise type
        let name = exercise.name.lowercased()
        if name.contains("press") || name.contains("push") {
            return "figure.arms.open"
        } else if name.contains("curl") || name.contains("row") || name.contains("pull") {
            return "figure.walk"
        } else if name.contains("squat") || name.contains("lunge") || name.contains("leg") {
            return "figure.walk"
        } else if name.contains("plank") || name.contains("crunch") || name.contains("core") {
            return "figure.core.workout"
        } else if name.contains("fly") || name.contains("dip") {
            return "figure.arms.open"
        } else {
            return "dumbbell.fill"
        }
    }
    
    private var lastWorkoutText: String {
        if let lastDate = exercise.lastWorkoutDate {
            let formatter = DateFormatter()
            formatter.dateStyle = .medium
            formatter.timeStyle = .short
            return formatter.string(from: lastDate)
        } else {
            return "No previous workouts"
        }
    }
    
    private var workoutSummary: String {
        if exercise.totalSets > 0 {
            return "\(Int(exercise.totalVolume))lbs × \(exercise.totalSets) total sets"
        } else {
            return "No previous workouts"
        }
    }
    
    var body: some View {
        HStack(spacing: 16) {
            // Exercise status icon
            ZStack {
                // Background with gradient
                Circle()
                    .fill(
                        LinearGradient(
                            colors: exerciseStatusGradient,
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        )
                    )
                    .frame(width: 48, height: 48)
                
                if exercise.totalSets > 0 {
                    // Show progress with number of sets
                    VStack(spacing: 2) {
                        Text("\(exercise.totalSets)")
                            .font(.system(size: 18, weight: .heavy, design: .default))
                            .foregroundColor(.white)
                        
                        Text("sets")
                            .font(.system(size: 10, weight: .semibold, design: .default))
                            .foregroundColor(.white.opacity(0.8))
                    }
                } else {
                    // Show exercise type icon for new exercises
                    Image(systemName: exerciseIcon)
                        .font(.system(size: 20, weight: .medium))
                        .foregroundColor(.white)
                }
                
                // Progress ring for visual appeal
                Circle()
                    .stroke(Color.white.opacity(0.2), lineWidth: 2)
                    .frame(width: 48, height: 48)
            }
            .overlay(
                // Add a subtle shadow
                Circle()
                    .fill(Color.clear)
                    .frame(width: 48, height: 48)
                    .shadow(color: exerciseStatusColor.opacity(0.4), radius: 6, x: 0, y: 3)
            )
            
            // Exercise details
            VStack(alignment: .leading, spacing: 4) {
                Text(exercise.name)
                    .font(.system(size: 20, weight: .bold, design: .default))
                    .foregroundColor(.primary)
                
                Text(workoutSummary)
                    .font(.system(size: 16, weight: .medium, design: .default))
                    .foregroundColor(.secondary)
                
                if exercise.totalSets > 0 {
                    HStack(spacing: 4) {
                        Image(systemName: "calendar")
                            .font(.caption)
                            .foregroundColor(.green)
                        
                        Text(lastWorkoutText)
                            .font(.system(size: 12, weight: .medium, design: .default))
                            .foregroundColor(.green)
                        
                        HStack(spacing: 2) {
                            ForEach(0..<3, id: \.self) { _ in
                                Circle()
                                    .fill(Color.green)
                                    .frame(width: 4, height: 4)
                            }
                        }
                        .padding(.leading, 4)
                    }
                }
            }
            
            Spacer()
            
            Image(systemName: "chevron.right")
                .font(.caption)
                .foregroundColor(.secondary)
        }
        .padding(.horizontal, 20)
        .padding(.vertical, 16)
    }
}

struct SummaryRow: View {
    let title: String
    let value: String
    
    var body: some View {
        HStack {
            Text(title)
                .font(.subheadline)
                .foregroundColor(.secondary)
            
            Spacer()
            
            Text(value)
                .font(.subheadline)
                .fontWeight(.medium)
                .foregroundColor(.primary)
        }
    }
}

#Preview {
    ExerciseListView(bodyPart: "Chest")
        .modelContainer(for: Exercise.self, inMemory: true)
}