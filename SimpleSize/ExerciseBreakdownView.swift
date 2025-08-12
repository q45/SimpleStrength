//
//  ExerciseBreakdownView.swift
//  SimpleSize
//
//  Created by Quintin Smith on 8/12/25.
//

import SwiftUI
import SwiftData

struct ExerciseBreakdownView: View {
    @Environment(\.modelContext) private var modelContext
    @Environment(\.dismiss) private var dismiss
    @Query private var exercises: [Exercise]
    @Query private var workoutSets: [WorkoutSet]
    
    @State private var selectedTimeFrame: TimeFrame = .allTime
    @State private var showingExerciseDetail = false
    @State private var selectedExercise: Exercise?
    
    enum TimeFrame: String, CaseIterable {
        case lastWeek = "Last Week"
        case lastMonth = "Last Month"
        case allTime = "All Time"
        
        var days: Int? {
            switch self {
            case .lastWeek: return 7
            case .lastMonth: return 30
            case .allTime: return nil
            }
        }
    }
    
    var body: some View {
        NavigationView {
            ZStack {
                // Background gradient
                LinearGradient(
                    colors: [Color(.systemBackground), Color(.systemGray6).opacity(0.3)],
                    startPoint: .top,
                    endPoint: .bottom
                )
                .ignoresSafeArea()
                
                ScrollView {
                    VStack(spacing: 24) {
                        // Time Frame Selector
                        VStack(spacing: 16) {
                            Text("Exercise Breakdown")
                                .font(.system(size: 28, weight: .heavy, design: .default))
                                .foregroundColor(.primary)
                            
                            Picker("Time Frame", selection: $selectedTimeFrame) {
                                ForEach(TimeFrame.allCases, id: \.self) { timeFrame in
                                    Text(timeFrame.rawValue).tag(timeFrame)
                                }
                            }
                            .pickerStyle(SegmentedPickerStyle())
                            .padding(.horizontal)
                        }
                        .padding(.top)
                        
                        // Summary Stats Cards
                        LazyVGrid(columns: [
                            GridItem(.flexible()),
                            GridItem(.flexible())
                        ], spacing: 16) {
                            SummaryStatCard(
                                title: "Total Exercises",
                                value: "\(filteredExercises.count)",
                                color: .blue,
                                icon: "dumbbell.fill"
                            )
                            
                            SummaryStatCard(
                                title: "Total Sets",
                                value: "\(filteredWorkoutSets.count)",
                                color: .green,
                                icon: "chart.bar.fill"
                            )
                            
                            SummaryStatCard(
                                title: "Total Volume",
                                value: "\(Int(totalVolume)) lbs",
                                color: .orange,
                                icon: "scalemass.fill"
                            )
                            
                            SummaryStatCard(
                                title: "Workout Days",
                                value: "\(uniqueWorkoutDays)",
                                color: .purple,
                                icon: "calendar.circle.fill"
                            )
                        }
                        .padding(.horizontal)
                        
                        // Top Exercises by Volume
                        if !topExercisesByVolume.isEmpty {
                            VStack(alignment: .leading, spacing: 16) {
                                Text("Top Exercises by Volume")
                                    .font(.system(size: 24, weight: .bold, design: .default))
                                    .padding(.horizontal)
                                
                                VStack(spacing: 12) {
                                    ForEach(Array(topExercisesByVolume.prefix(5).enumerated()), id: \.element.id) { index, exercise in
                                        TopExerciseRow(
                                            rank: index + 1,
                                            exercise: exercise,
                                            totalVolume: exerciseVolume(for: exercise),
                                            lastWorkout: exercise.lastWorkoutDate
                                        )
                                        .onTapGesture {
                                            selectedExercise = exercise
                                            showingExerciseDetail = true
                                        }
                                    }
                                }
                                .padding(.horizontal)
                            }
                        }
                        
                        // Recent Progress
                        if !recentProgress.isEmpty {
                            VStack(alignment: .leading, spacing: 16) {
                                Text("Recent Progress")
                                    .font(.system(size: 24, weight: .bold, design: .default))
                                    .padding(.horizontal)
                                
                                VStack(spacing: 12) {
                                    ForEach(recentProgress, id: \.exercise.id) { progress in
                                        ProgressRow(progress: progress)
                                    }
                                }
                                .padding(.horizontal)
                            }
                        }
                        
                        // Body Part Breakdown
                        VStack(alignment: .leading, spacing: 16) {
                            Text("Body Part Breakdown")
                                .font(.system(size: 24, weight: .bold, design: .default))
                                .padding(.horizontal)
                            
                            VStack(spacing: 12) {
                                ForEach(BodyPart.allBodyParts, id: \.name) { bodyPart in
                                    BodyPartBreakdownRow(
                                        bodyPart: bodyPart,
                                        exerciseCount: exercises.filter { $0.bodyPart == bodyPart.name }.count,
                                        setCount: workoutSets.filter { $0.exercise?.bodyPart == bodyPart.name }.count,
                                        totalVolume: bodyPartVolume(for: bodyPart.name)
                                    )
                                }
                            }
                            .padding(.horizontal)
                        }
                    }
                    .padding(.bottom, 30)
                }
            }
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Done") {
                        dismiss()
                    }
                    .font(.system(size: 16, weight: .semibold, design: .default))
                }
            }
        }
        .sheet(isPresented: $showingExerciseDetail) {
            if let exercise = selectedExercise {
                ExerciseDetailView(exercise: exercise)
            }
        }
    }
    
    // MARK: - Computed Properties
    
    private var filteredExercises: [Exercise] {
        guard let days = selectedTimeFrame.days else { return exercises }
        let cutoffDate = Calendar.current.date(byAdding: .day, value: -days, to: Date())!
        return exercises.filter { exercise in
            exercise.lastWorkoutDate == nil || exercise.lastWorkoutDate! >= cutoffDate
        }
    }
    
    private var filteredWorkoutSets: [WorkoutSet] {
        guard let days = selectedTimeFrame.days else { return workoutSets }
        let cutoffDate = Calendar.current.date(byAdding: .day, value: -days, to: Date())!
        return workoutSets.filter { $0.timestamp >= cutoffDate }
    }
    
    private var totalVolume: Double {
        filteredWorkoutSets.reduce(0) { $0 + ($1.weight * Double($1.reps)) }
    }
    
    private var uniqueWorkoutDays: Int {
        let calendar = Calendar.current
        let workoutDates = Set(filteredWorkoutSets.map { calendar.startOfDay(for: $0.timestamp) })
        return workoutDates.count
    }
    
    private var topExercisesByVolume: [Exercise] {
        exercises.sorted { exerciseVolume(for: $0) > exerciseVolume(for: $1) }
    }
    
    private var recentProgress: [ExerciseProgress] {
        exercises.compactMap { exercise in
            guard let lastWorkout = exercise.lastWorkoutDate else { return nil }
            
            let recentSets = exercise.workoutSets.filter { set in
                set.timestamp >= Calendar.current.date(byAdding: .day, value: -7, to: Date())!
            }
            
            let previousSets = exercise.workoutSets.filter { set in
                let weekAgo = Calendar.current.date(byAdding: .day, value: -7, to: Date())!
                let twoWeeksAgo = Calendar.current.date(byAdding: .day, value: -14, to: Date())!
                return set.timestamp >= twoWeeksAgo && set.timestamp < weekAgo
            }
            
            let recentVolume = recentSets.reduce(0) { $0 + ($1.weight * Double($1.reps)) }
            let previousVolume = previousSets.reduce(0) { $0 + ($1.weight * Double($1.reps)) }
            
            let volumeChange = recentVolume - previousVolume
            let volumeChangePercent = previousVolume > 0 ? (volumeChange / previousVolume) * 100 : 0
            
            return ExerciseProgress(
                exercise: exercise,
                recentVolume: recentVolume,
                previousVolume: previousVolume,
                volumeChange: volumeChange,
                volumeChangePercent: volumeChangePercent,
                lastWorkout: lastWorkout
            )
        }
        .sorted { $0.volumeChange > $1.volumeChange }
        .prefix(5)
        .map { $0 }
    }
    
    // MARK: - Helper Methods
    
    private func exerciseVolume(for exercise: Exercise) -> Double {
        let sets = selectedTimeFrame.days != nil ? 
            exercise.workoutSets.filter { set in
                let cutoffDate = Calendar.current.date(byAdding: .day, value: -selectedTimeFrame.days!, to: Date())!
                return set.timestamp >= cutoffDate
            } : exercise.workoutSets
        
        return sets.reduce(0) { $0 + ($1.weight * Double($1.reps)) }
    }
    
    private func bodyPartVolume(for bodyPart: String) -> Double {
        let bodyPartSets = workoutSets.filter { $0.exercise?.bodyPart == bodyPart }
        let filteredSets = selectedTimeFrame.days != nil ? 
            bodyPartSets.filter { set in
                let cutoffDate = Calendar.current.date(byAdding: .day, value: -selectedTimeFrame.days!, to: Date())!
                return set.timestamp >= cutoffDate
            } : bodyPartSets
        
        return filteredSets.reduce(0) { $0 + ($1.weight * Double($1.reps)) }
    }
}

// MARK: - Supporting Views

struct SummaryStatCard: View {
    let title: String
    let value: String
    let color: Color
    let icon: String
    
    var body: some View {
        VStack(spacing: 12) {
            Image(systemName: icon)
                .font(.system(size: 24, weight: .semibold, design: .default))
                .foregroundColor(color)
            
            Text(value)
                .font(.system(size: 28, weight: .heavy, design: .default))
                .foregroundColor(.primary)
            
            Text(title)
                .font(.system(size: 12, weight: .medium, design: .default))
                .foregroundColor(.secondary)
                .multilineTextAlignment(.center)
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 20)
        .background(Color(.systemBackground))
        .cornerRadius(16)
        .shadow(color: .black.opacity(0.05), radius: 4, x: 0, y: 2)
    }
}

struct TopExerciseRow: View {
    let rank: Int
    let exercise: Exercise
    let totalVolume: Double
    let lastWorkout: Date?
    
    var body: some View {
        HStack(spacing: 16) {
            // Rank badge
            ZStack {
                Circle()
                    .fill(rankColor.opacity(0.1))
                    .frame(width: 40, height: 40)
                
                Text("\(rank)")
                    .font(.system(size: 18, weight: .heavy, design: .default))
                    .foregroundColor(rankColor)
            }
            
            // Exercise details
            VStack(alignment: .leading, spacing: 4) {
                Text(exercise.name)
                    .font(.system(size: 18, weight: .bold, design: .default))
                    .foregroundColor(.primary)
                
                Text("\(Int(totalVolume)) lbs total volume")
                    .font(.system(size: 14, weight: .medium, design: .default))
                    .foregroundColor(.secondary)
                
                if let lastWorkout = lastWorkout {
                    Text("Last: \(formatDate(lastWorkout))")
                        .font(.system(size: 12, weight: .medium, design: .default))
                        .foregroundColor(.green)
                }
            }
            
            Spacer()
            
            Image(systemName: "chevron.right")
                .font(.caption)
                .foregroundColor(.secondary)
        }
        .padding(16)
        .background(Color(.systemBackground))
        .cornerRadius(16)
        .shadow(color: .black.opacity(0.05), radius: 4, x: 0, y: 2)
    }
    
    private var rankColor: Color {
        switch rank {
        case 1: return .yellow
        case 2: return .gray
        case 3: return .orange
        default: return .blue
        }
    }
    
    private func formatDate(_ date: Date) -> String {
        let formatter = DateFormatter()
        formatter.dateStyle = .medium
        formatter.timeStyle = .none
        return formatter.string(from: date)
    }
}

struct ProgressRow: View {
    let progress: ExerciseProgress
    
    var body: some View {
        HStack(spacing: 16) {
            // Progress indicator
            ZStack {
                Circle()
                    .fill(progressColor.opacity(0.1))
                    .frame(width: 40, height: 40)
                
                Image(systemName: progressIcon)
                    .font(.system(size: 18, weight: .semibold, design: .default))
                    .foregroundColor(progressColor)
            }
            
            // Progress details
            VStack(alignment: .leading, spacing: 4) {
                Text(progress.exercise.name)
                    .font(.system(size: 18, weight: .bold, design: .default))
                    .foregroundColor(.primary)
                
                Text("\(Int(progress.recentVolume)) lbs this week")
                    .font(.system(size: 14, weight: .medium, design: .default))
                    .foregroundColor(.secondary)
                
                HStack(spacing: 4) {
                    Image(systemName: progressIcon)
                        .font(.system(size: 12, weight: .medium, design: .default))
                        .foregroundColor(progressColor)
                    
                    Text(progressText)
                        .font(.system(size: 12, weight: .medium, design: .default))
                        .foregroundColor(progressColor)
                }
            }
            
            Spacer()
        }
        .padding(16)
        .background(Color(.systemBackground))
        .cornerRadius(16)
        .shadow(color: .black.opacity(0.05), radius: 4, x: 0, y: 2)
    }
    
    private var progressColor: Color {
        progress.volumeChange >= 0 ? .green : .red
    }
    
    private var progressIcon: String {
        progress.volumeChange >= 0 ? "arrow.up.circle.fill" : "arrow.down.circle.fill"
    }
    
    private var progressText: String {
        if progress.volumeChange >= 0 {
            return "+\(Int(progress.volumeChange)) lbs (+\(String(format: "%.1f", progress.volumeChangePercent))%)"
        } else {
            return "\(Int(progress.volumeChange)) lbs (\(String(format: "%.1f", progress.volumeChangePercent))%)"
        }
    }
}

struct BodyPartBreakdownRow: View {
    let bodyPart: BodyPart
    let exerciseCount: Int
    let setCount: Int
    let totalVolume: Double
    
    var body: some View {
        HStack(spacing: 16) {
            // Body part icon
            ZStack {
                RoundedRectangle(cornerRadius: 12)
                    .fill(bodyPartColor)
                    .frame(width: 48, height: 48)
                
                Image(systemName: bodyPart.systemImage)
                    .font(.system(size: 20, weight: .semibold, design: .default))
                    .foregroundColor(.white)
            }
            
            // Body part details
            VStack(alignment: .leading, spacing: 4) {
                Text(bodyPart.name)
                    .font(.system(size: 18, weight: .bold, design: .default))
                    .foregroundColor(.primary)
                
                HStack(spacing: 16) {
                    Text("\(exerciseCount) exercises")
                        .font(.system(size: 14, weight: .medium, design: .default))
                        .foregroundColor(.secondary)
                    
                    Text("\(setCount) sets")
                        .font(.system(size: 14, weight: .medium, design: .default))
                        .foregroundColor(.secondary)
                    
                    Text("\(Int(totalVolume)) lbs")
                        .font(.system(size: 14, weight: .medium, design: .default))
                        .foregroundColor(.secondary)
                }
            }
            
            Spacer()
        }
        .padding(16)
        .background(Color(.systemBackground))
        .cornerRadius(16)
        .shadow(color: .black.opacity(0.05), radius: 4, x: 0, y: 2)
    }
    
    private var bodyPartColor: Color {
        switch bodyPart.name {
        case "Chest": return .red
        case "Back": return .blue
        case "Shoulders": return .blue
        case "Arms": return .blue
        case "Legs": return .green
        case "Core": return .green
        default: return .gray
        }
    }
}

// MARK: - Data Models

struct ExerciseProgress {
    let exercise: Exercise
    let recentVolume: Double
    let previousVolume: Double
    let volumeChange: Double
    let volumeChangePercent: Double
    let lastWorkout: Date
}

// MARK: - Exercise Detail View

struct ExerciseDetailView: View {
    let exercise: Exercise
    @Environment(\.dismiss) private var dismiss
    
    var body: some View {
        NavigationView {
            ScrollView {
                VStack(spacing: 24) {
                    // Exercise header
                    VStack(spacing: 16) {
                        Text(exercise.name)
                            .font(.system(size: 32, weight: .heavy, design: .default))
                            .multilineTextAlignment(.center)
                        
                        Text(exercise.bodyPart)
                            .font(.system(size: 18, weight: .semibold, design: .default))
                            .foregroundColor(.secondary)
                    }
                    .padding(.top)
                    
                    // Exercise stats
                    LazyVGrid(columns: [
                        GridItem(.flexible()),
                        GridItem(.flexible())
                    ], spacing: 16) {
                        ExerciseStatCard(title: "Total Sets", value: "\(exercise.totalSets)", color: .blue)
                        ExerciseStatCard(title: "Total Volume", value: "\(Int(exercise.totalVolume)) lbs", color: .green)
                        ExerciseStatCard(title: "Best Weight", value: "\(Int(bestWeight)) lbs", color: .orange)
                        ExerciseStatCard(title: "Best Reps", value: "\(bestReps)", color: .purple)
                    }
                    .padding(.horizontal)
                    
                    // Recent workout history
                    if !exercise.workoutSets.isEmpty {
                        VStack(alignment: .leading, spacing: 16) {
                            Text("Recent Workouts")
                                .font(.system(size: 24, weight: .bold, design: .default))
                                .padding(.horizontal)
                            
                            VStack(spacing: 12) {
                                ForEach(Array(exercise.workoutSets.sorted { $0.timestamp > $1.timestamp }.prefix(10)), id: \.id) { set in
                                    WorkoutSetRow(set: set)
                                }
                            }
                            .padding(.horizontal)
                        }
                    }
                }
                .padding(.bottom, 30)
            }
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Done") {
                        dismiss()
                    }
                    .font(.system(size: 16, weight: .semibold, design: .default))
                }
            }
        }
    }
    
    private var bestWeight: Double {
        exercise.workoutSets.max(by: { $0.weight < $1.weight })?.weight ?? 0
    }
    
    private var bestReps: Int {
        exercise.workoutSets.max(by: { $0.reps < $1.reps })?.reps ?? 0
    }
}

struct ExerciseStatCard: View {
    let title: String
    let value: String
    let color: Color
    
    var body: some View {
        VStack(spacing: 8) {
            Text(value)
                .font(.system(size: 24, weight: .heavy, design: .default))
                .foregroundColor(color)
            
            Text(title)
                .font(.system(size: 12, weight: .medium, design: .default))
                .foregroundColor(.secondary)
                .multilineTextAlignment(.center)
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 16)
        .background(Color(.systemBackground))
        .cornerRadius(12)
        .shadow(color: .black.opacity(0.05), radius: 4, x: 0, y: 2)
    }
}

struct WorkoutSetRow: View {
    let set: WorkoutSet
    
    var body: some View {
        HStack(spacing: 16) {
            // Date
            Text(formatDate(set.timestamp))
                .font(.system(size: 14, weight: .medium, design: .default))
                .foregroundColor(.secondary)
                .frame(width: 80, alignment: .leading)
            
            // Set details
            Text("\(Int(set.weight)) lbs × \(set.reps) reps")
                .font(.system(size: 16, weight: .semibold, design: .default))
                .foregroundColor(.primary)
            
            Spacer()
            
            // Volume
            Text("\(Int(set.weight * Double(set.reps))) lbs")
                .font(.system(size: 14, weight: .medium, design: .default))
                .foregroundColor(.blue)
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 12)
        .background(Color(.systemBackground))
        .cornerRadius(12)
        .shadow(color: .black.opacity(0.03), radius: 2, x: 0, y: 1)
    }
    
    private func formatDate(_ date: Date) -> String {
        let formatter = DateFormatter()
        formatter.dateStyle = .short
        formatter.timeStyle = .none
        return formatter.string(from: date)
    }
}

#Preview {
    ExerciseBreakdownView()
        .modelContainer(for: [Exercise.self, WorkoutSet.self], inMemory: true)
}
