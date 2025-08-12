//
//  Item.swift
//  SimpleSize
//
//  Created by Quintin Smith on 8/11/25.
//

import Foundation
import SwiftData

@Model
final class Exercise {
    var id: String
    var name: String
    var bodyPart: String
    var isCustom: Bool
    var workoutSets: [WorkoutSet]
    var lastWorkoutDate: Date?
    var totalSets: Int
    var totalVolume: Double
    
    init(name: String, bodyPart: String, isCustom: Bool = false) {
        self.id = UUID().uuidString
        self.name = name
        self.bodyPart = bodyPart
        self.isCustom = isCustom
        self.workoutSets = []
        self.lastWorkoutDate = nil
        self.totalSets = 0
        self.totalVolume = 0
    }
}

@Model
final class WorkoutSet {
    var id: String
    var weight: Double
    var reps: Int
    var timestamp: Date
    var exercise: Exercise?
    var workoutCompletedAt: Date?
    
    init(weight: Double, reps: Int, exercise: Exercise? = nil) {
        self.id = UUID().uuidString
        self.weight = weight
        self.reps = reps
        self.timestamp = Date()
        self.exercise = exercise
        self.workoutCompletedAt = nil
    }
}

struct BodyPart {
    let name: String
    let systemImage: String
    
    static let allBodyParts = [
        BodyPart(name: "Chest", systemImage: "figure.arms.open"),
        BodyPart(name: "Back", systemImage: "figure.walk"),
        BodyPart(name: "Shoulders", systemImage: "figure.arms.open"),
        BodyPart(name: "Arms", systemImage: "arm.and.wrist"),
        BodyPart(name: "Legs", systemImage: "figure.walk"),
        BodyPart(name: "Core", systemImage: "figure.core.workout")
    ]
}
