//
//  ContentView.swift
//  SimpleSize
//
//  Created by Quintin Smith on 8/11/25.
//

import SwiftUI
import SwiftData

struct ContentView: View {
    var body: some View {
        WorkoutSummaryView()
    }
}

#Preview {
    ContentView()
        .modelContainer(for: [Exercise.self, WorkoutSet.self], inMemory: true)
}
