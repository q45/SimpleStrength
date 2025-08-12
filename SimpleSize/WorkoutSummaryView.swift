//
//  WorkoutSummaryView.swift
//  SimpleSize
//
//  Created by Quintin Smith on 8/11/25.
//

import SwiftUI
import SwiftData

struct WorkoutSummaryView: View {
    @Environment(\.modelContext) private var modelContext
    @Query private var exercises: [Exercise]
    @Query private var workoutSets: [WorkoutSet]
    
    var body: some View {
        NavigationView {
            ScrollView {
                VStack(spacing: 24) {
                    // Workout Progress Card
                    WorkoutProgressCard(exercises: exercises, workoutSets: workoutSets)
                    
                    // Body Part Selection
                    VStack(alignment: .leading, spacing: 16) {
                        Text("Choose Body Part")
                            .font(.title2)
                            .fontWeight(.bold)
                            .padding(.horizontal)
                        
                        VStack(spacing: 12) {
                            ForEach(BodyPart.allBodyParts, id: \.name) { bodyPart in
                                BodyPartRow(
                                    bodyPart: bodyPart,
                                    exercises: exercises.filter { $0.bodyPart == bodyPart.name },
                                    workoutSets: workoutSets.filter { $0.exercise?.bodyPart == bodyPart.name }
                                )
                            }
                        }
                        .padding(.horizontal)
                    }
                    
                    // Summary Stats
                    HStack(spacing: 16) {
                        SummaryCard(
                            title: "Total Exercises",
                            value: "\(exercises.count)",
                            color: .blue,
                            icon: "dumbbell.fill"
                        )
                        
                        SummaryCard(
                            title: "Total Sets",
                            value: "\(workoutSets.count)",
                            color: .green,
                            icon: "chart.bar.fill"
                        )
                    }
                    .padding(.horizontal)
                }
                .padding(.vertical)
            }
            .navigationTitle("Workout")
            .background(Color(.systemGroupedBackground))
        }
    }
}

struct WorkoutProgressCard: View {
    let exercises: [Exercise]
    let workoutSets: [WorkoutSet]
    
    private var totalSets: Int {
        workoutSets.count
    }
    
    private var mostTrainedBodyPart: String {
        let bodyPartCounts = Dictionary(grouping: workoutSets, by: { $0.exercise?.bodyPart ?? "" })
            .mapValues { $0.count }
        
        return bodyPartCounts.max(by: { $0.value < $1.value })?.key ?? "None"
    }
    
    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            HStack {
                Image(systemName: "bolt.fill")
                    .font(.title2)
                    .foregroundColor(.yellow)
                
                Text("Workout Progress")
                    .font(.title2)
                    .fontWeight(.bold)
                    .foregroundColor(.white)
                
                Spacer()
                
                VStack(alignment: .trailing, spacing: 4) {
                    Image(systemName: "chart.line.uptrend.xyaxis")
                        .font(.caption)
                        .foregroundColor(.white.opacity(0.8))
                    
                    Text("Keep going!")
                        .font(.caption)
                        .foregroundColor(.white.opacity(0.8))
                }
            }
            
            VStack(alignment: .leading, spacing: 8) {
                Text("\(totalSets) total sets completed")
                    .font(.headline)
                    .foregroundColor(.white)
                
                if !mostTrainedBodyPart.isEmpty && mostTrainedBodyPart != "None" {
                    Text("Most trained: \(mostTrainedBodyPart)")
                        .font(.subheadline)
                        .foregroundColor(.white.opacity(0.9))
                }
            }
        }
        .padding(20)
        .background(
            LinearGradient(
                colors: [Color.purple, Color.purple.opacity(0.8)],
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )
        )
        .cornerRadius(20)
        .shadow(color: .purple.opacity(0.3), radius: 12, x: 0, y: 6)
        .padding(.horizontal)
    }
}

struct BodyPartRow: View {
    let bodyPart: BodyPart
    let exercises: [Exercise]
    let workoutSets: [WorkoutSet]
    
    private var setsDoneToday: Int {
        let today = Calendar.current.startOfDay(for: Date())
        let tomorrow = Calendar.current.date(byAdding: .day, value: 1, to: today)!
        
        return workoutSets.filter { workoutSet in
            workoutSet.timestamp >= today && workoutSet.timestamp < tomorrow
        }.count
    }
    
    private var hasRecentActivity: Bool {
        setsDoneToday > 0
    }
    
    var body: some View {
        NavigationLink(destination: ExerciseListView(bodyPart: bodyPart.name)) {
            HStack(spacing: 16) {
                // Body part icon
                ZStack {
                    RoundedRectangle(cornerRadius: 12)
                        .fill(bodyPartColor)
                        .frame(width: 48, height: 48)
                    
                    Image(systemName: bodyPart.systemImage)
                        .font(.title2)
                        .foregroundColor(.white)
                }
                
                // Body part details
                VStack(alignment: .leading, spacing: 4) {
                    Text(bodyPart.name)
                        .font(.headline)
                        .foregroundColor(.primary)
                    
                    HStack(spacing: 8) {
                        Text("\(exercises.count) exercises")
                            .font(.subheadline)
                            .foregroundColor(.secondary)
                        
                        if hasRecentActivity {
                            Text("\(setsDoneToday) sets done")
                                .font(.subheadline)
                                .foregroundColor(.green)
                            
                            HStack(spacing: 4) {
                                Text("Today")
                                    .font(.caption)
                                    .foregroundColor(.green)
                                
                                Circle()
                                    .fill(Color.green)
                                    .frame(width: 6, height: 6)
                            }
                        }
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
        .buttonStyle(PlainButtonStyle())
    }
    
    private var bodyPartColor: Color {
        switch bodyPart.name {
        case "Chest": return .red
        case "Back": return .blue
        case "Shoulders": return .orange
        case "Arms": return .purple
        case "Legs": return .green
        case "Core": return .yellow
        default: return .gray
        }
    }
}

struct SummaryCard: View {
    let title: String
    let value: String
    let color: Color
    let icon: String
    
    var body: some View {
        VStack(spacing: 12) {
            Image(systemName: icon)
                .font(.title2)
                .foregroundColor(color)
            
            Text(value)
                .font(.title)
                .fontWeight(.bold)
                .foregroundColor(.primary)
            
            Text(title)
                .font(.caption)
                .foregroundColor(.secondary)
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 20)
        .background(Color(.systemBackground))
        .cornerRadius(16)
        .shadow(color: .black.opacity(0.05), radius: 4, x: 0, y: 2)
    }
}

#Preview {
    WorkoutSummaryView()
        .modelContainer(for: [Exercise.self, WorkoutSet.self], inMemory: true)
}
