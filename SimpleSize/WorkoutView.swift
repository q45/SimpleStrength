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
    
    @Bindable var exercise: Exercise
    @State private var weightInput = ""
    @State private var repsInput = ""
    @State private var isBodyWeight = false
    @State private var isSetsExpanded = false
    
    // Focus management
    @FocusState private var isWeightFocused: Bool
    @FocusState private var isRepsFocused: Bool
    
    private var bodyWeight: Double {
        // Remove automatic body weight from settings - just return 0
        0
    }
    
    private var weightUnit: String {
        UserDefaults.standard.string(forKey: "weightUnit") ?? "lbs"
    }
    
    private var todaysSets: [WorkoutSet] {
        let calendar = Calendar.current
        let today = calendar.startOfDay(for: Date())
        return exercise.workoutSets.filter { set in
            calendar.isDate(set.timestamp, inSameDayAs: today)
        }
    }
    
    private var isInputValid: Bool {
        !weightInput.isEmpty && !repsInput.isEmpty
    }
    
    var body: some View {
        if exercise.name.isEmpty {
            errorView
        } else {
            mainView
        }
    }
    
    private var errorView: some View {
        VStack {
            Text("⚠️ Exercise Data Error")
                .font(.title)
                .foregroundColor(.red)
            Text("Exercise name is empty")
                .font(.caption)
                .foregroundColor(.secondary)
            
            VStack(alignment: .leading, spacing: 8) {
                Text("Debug Info:")
                    .font(.caption)
                    .foregroundColor(.secondary)
                Text("Exercise ID: \(exercise.id)")
                    .font(.caption)
                    .foregroundColor(.secondary)
                Text("Exercise name: '\(exercise.name)'")
                    .font(.caption)
                    .foregroundColor(.secondary)
                Text("Body part: \(exercise.bodyPart)")
                    .font(.caption)
                    .foregroundColor(.secondary)
                Text("Total sets: \(exercise.totalSets)")
                    .font(.caption)
                    .foregroundColor(.secondary)
                Text("Workout sets count: \(exercise.workoutSets.count)")
                    .font(.caption)
                    .foregroundColor(.secondary)
                Text("Is custom: \(exercise.isCustom)")
                    .font(.caption)
                    .foregroundColor(.secondary)
            }
            .padding()
            .background(Color.secondary.opacity(0.1))
            .cornerRadius(8)
            
            Button("Go Back") {
                dismiss()
            }
            .buttonStyle(.borderedProminent)
            .padding(.top)
        }
        .padding()
    }
    
    private var mainView: some View {
        NavigationStack {
            VStack(spacing: 0) {
                headerView
                ScrollViewReader { proxy in
                    ScrollView {
                        VStack(spacing: 24) {
                            WorkoutStatsSection(todaysSets: todaysSets)
                            inputSection
                                .id("inputSection")
                            TodaysSetsSection(isSetsExpanded: $isSetsExpanded, todaysSets: todaysSets)
                            ActionButtonsSection(
                                onAddSet: addSet,
                                onFinishWorkout: finishWorkout,
                                isInputValid: isInputValid,
                                hasSets: !todaysSets.isEmpty
                            )
                        }
                        .padding(.vertical, 20)
                        .padding(.bottom, 200) // Increased bottom padding for keyboard
                    }
                    .onChange(of: isWeightFocused || isRepsFocused) { _, isFocused in
                        if isFocused {
                            print("🔄 Focus changed: weight=\(isWeightFocused), reps=\(isRepsFocused)")
                            // Simple, single scroll when focus changes
                            DispatchQueue.main.asyncAfter(deadline: .now() + 0.3) {
                                withAnimation(.easeInOut(duration: 0.3)) {
                                    proxy.scrollTo("inputSection", anchor: .bottom)
                                }
                            }
                        }
                    }
                }
            }
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("Done") {
                        dismiss()
                    }
                }
                
                ToolbarItem(placement: .keyboard) {
                    HStack {
                        Spacer()
                        Button("Done") {
                            isWeightFocused = false
                            isRepsFocused = false
                            dismissKeyboard()
                        }
                        .foregroundColor(.blue)
                    }
                }
            }
        }
        .onAppear {
            // No automatic body weight population - user enters manually
            isWeightFocused = false
            isRepsFocused = false
        }
        .onDisappear {
            isWeightFocused = false
            isRepsFocused = false
            dismissKeyboard()
        }
        .ignoresSafeArea(.keyboard, edges: .bottom)
        .onTapGesture {
            if isWeightFocused || isRepsFocused {
                isWeightFocused = false
                isRepsFocused = false
                dismissKeyboard()
            }
        }
    }
    
    private var headerView: some View {
        VStack(spacing: 16) {
            Text(exercise.name)
                .font(.system(size: 28, weight: .bold, design: .default))
                .foregroundColor(.primary)
                .multilineTextAlignment(.center)
            
            Text(exercise.bodyPart)
                .font(.system(size: 18, weight: .medium, design: .default))
                .foregroundColor(.secondary)
        }
        .padding(.top, 20)
        .padding(.horizontal, 20)
    }
    
    private var inputSection: some View {
        VStack(spacing: 24) {
            WeightInputField(
                weightInput: $weightInput,
                isWeightFocused: $isWeightFocused,
                isBodyWeight: isBodyWeight,
                weightUnit: weightUnit,
                bodyWeight: bodyWeight,
                onToggle: toggleBodyWeight,
                onSubmit: moveToReps
            )
            
            RepsInputField(
                repsInput: $repsInput,
                isRepsFocused: $isRepsFocused
            )
        }
        .padding(.horizontal, 20)
    }
    
    private func toggleBodyWeight() {
        isBodyWeight.toggle()
        // Keep the current input value when toggling
        // User can manually enter whatever weight they want
    }
    
    private var effectiveWeight: Double {
        if isBodyWeight {
            // When body weight is selected, just use the input value
            return Double(weightInput) ?? 0
        } else {
            return Double(weightInput) ?? 0
        }
    }
    
    private func moveToReps() {
        isWeightFocused = false
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
            isRepsFocused = true
        }
    }
    
    private func addSet() {
        let weight = effectiveWeight
        guard let reps = Int(repsInput), weight > 0, reps > 0 else {
            print("❌ Invalid input: weight=\(weight), reps=\(repsInput)")
            return
        }
        
        print("✅ Adding set: weight=\(weight), reps=\(reps)")
        
        let workoutSet = WorkoutSet(
            weight: weight,
            reps: reps,
            exercise: exercise
        )
        
        do {
            exercise.workoutSets.append(workoutSet)
            try modelContext.save()
            print("💾 Successfully saved workout set")
            
            // Reset form
            weightInput = ""
            repsInput = ""
            
            // Clear focus states
            isWeightFocused = false
            isRepsFocused = false
            
            dismissKeyboard()
            
            // Focus weight input for next set
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
                if !isWeightFocused && !isRepsFocused {
                    isWeightFocused = true
                }
            }
            
        } catch {
            print("❌ Failed to save workout set: \(error.localizedDescription)")
        }
    }
    
    private func finishWorkout() {
        dismiss()
    }
    
    private func dismissKeyboard() {
        DispatchQueue.main.async {
            UIApplication.shared.sendAction(#selector(UIResponder.resignFirstResponder), to: nil, from: nil, for: nil)
        }
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
                .font(.system(size: 24, weight: .heavy, design: .default))
                .foregroundColor(color)
            
            Text(title)
                .font(.system(size: 12, weight: .medium, design: .default))
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
                    .fill(Color.blue.opacity(0.1))
                    .frame(width: 32, height: 32)
                
                Text("\(setNumber)")
                    .font(.system(size: 14, weight: .bold, design: .default))
                    .foregroundColor(.blue)
            }
            
            // Set details
            VStack(alignment: .leading, spacing: 2) {
                Text("\(Int(weight)) lbs × \(reps) reps")
                    .font(.system(size: 16, weight: .semibold, design: .default))
                    .foregroundColor(.primary)
                
                Text("Set \(setNumber)")
                    .font(.system(size: 12, weight: .medium, design: .default))
                    .foregroundColor(.secondary)
            }
            
            Spacer()
            
            // Weight indicator
            Text("\(Int(weight))")
                .font(.system(size: 20, weight: .heavy, design: .default))
                .foregroundColor(.blue)
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 12)
        .background(Color(.systemBackground))
        .cornerRadius(16)
        .shadow(color: .black.opacity(0.05), radius: 4, x: 0, y: 2)
    }
}

struct WeightInputField: View {
    @Binding var weightInput: String
    var isWeightFocused: FocusState<Bool>.Binding
    let isBodyWeight: Bool
    let weightUnit: String
    let bodyWeight: Double
    let onToggle: () -> Void
    let onSubmit: () -> Void
    
    private var weightUnitText: String {
        isBodyWeight ? "BW" : weightUnit
    }
    
    private var weightUnitColor: Color {
        isBodyWeight ? .green : .secondary
    }
    
    private var weightDisplayText: String {
        if isBodyWeight {
            if weightInput.isEmpty {
                return "BW" // Just show "BW" for body weight
            } else {
                return "\(weightInput) BW" // Show "25 BW" for example
            }
        } else {
            if weightInput.isEmpty {
                return "0 lbs"
            } else {
                return "\(weightInput) lbs"
            }
        }
    }
    
    var body: some View {
        VStack(spacing: 12) {
            HStack {
                Text("Weight")
                    .font(.system(size: 18, weight: .semibold, design: .default))
                    .foregroundColor(.secondary)
                
                Spacer()
                
                // Body Weight Toggle
                BodyWeightToggleButton(
                    isBodyWeight: isBodyWeight,
                    bodyWeight: bodyWeight
                ) {
                    onToggle()
                }
            }
            
            ZStack {
                RoundedRectangle(cornerRadius: 20)
                    .fill(Color(.systemBackground))
                    .shadow(color: .black.opacity(0.1), radius: 8, x: 0, y: 4)
                
                // Full-width text field for proper centering
                TextField("0", text: $weightInput)
                    .font(.system(size: 42, weight: .heavy, design: .default))
                    .keyboardType(.numberPad)
                    .multilineTextAlignment(.center)
                    .focused(isWeightFocused)
                    .foregroundColor(.primary)
                    .disabled(false) // Always allow input
                    .onSubmit(onSubmit)
                    .onChange(of: weightInput) { _, newValue in
                        // Filter out non-numeric characters
                        let filtered = newValue.filter { $0.isNumber }
                        if filtered != newValue {
                            weightInput = filtered
                        }
                        
                        // Auto-submit when weight is entered (3+ digits)
                        if filtered.count >= 3 {
                            onSubmit()
                        }
                    }
                    .onTapGesture {
                        // Clear input when tapped if it's just "0"
                        if weightInput == "0" || weightInput.isEmpty {
                            weightInput = ""
                        }
                        print("🔄 Weight field tapped, focus: \(isWeightFocused)")
                    }
                    .padding(.horizontal, 20)
                    .frame(maxWidth: .infinity)
                    .frame(height: 60)
                
                // Unit text overlaid on the right side
                HStack {
                    Spacer()
                    Text(weightDisplayText)
                        .font(.system(size: 20, weight: .semibold, design: .default))
                        .foregroundColor(.secondary)
                        .padding(.trailing, 20)
                }
            }
            .frame(height: 80)
        }
        .frame(maxWidth: .infinity)
    }
}

struct RepsInputField: View {
    @Binding var repsInput: String
    var isRepsFocused: FocusState<Bool>.Binding
    
    var body: some View {
        VStack(spacing: 12) {
            Text("Reps")
                .font(.system(size: 18, weight: .semibold, design: .default))
                .foregroundColor(.secondary)
            
            ZStack {
                RoundedRectangle(cornerRadius: 20)
                    .fill(Color(.systemBackground))
                    .shadow(color: .black.opacity(0.1), radius: 8, x: 0, y: 4)
                
                TextField("0", text: $repsInput)
                    .font(.system(size: 42, weight: .heavy, design: .default))
                    .keyboardType(.numberPad)
                    .multilineTextAlignment(.center)
                    .focused(isRepsFocused)
                    .foregroundColor(.primary)
                    .frame(maxWidth: .infinity)
                    .frame(height: 60)
                    .onSubmit {
                        // Dismiss keyboard when reps is submitted
                        isRepsFocused.wrappedValue = false
                        DispatchQueue.main.async {
                            UIApplication.shared.sendAction(#selector(UIResponder.resignFirstResponder), to: nil, from: nil, for: nil)
                        }
                    }
                    .onChange(of: repsInput) { _, newValue in
                        // Filter out non-numeric characters
                        let filtered = newValue.filter { $0.isNumber }
                        if filtered != newValue {
                            repsInput = filtered
                        }
                        
                        // Auto-submit when reps is entered (2+ digits)
                        if filtered.count >= 2 {
                            isRepsFocused.wrappedValue = false
                            DispatchQueue.main.async {
                                UIApplication.shared.sendAction(#selector(UIResponder.resignFirstResponder), to: nil, from: nil, for: nil)
                            }
                        }
                    }
                    .onTapGesture {
                        // Clear input when tapped if it's just "0"
                        if repsInput == "0" {
                            repsInput = ""
                        }
                        print("🔄 Reps field tapped, focus: \(isRepsFocused)")
                    }
            }
            .frame(height: 80)
        }
        .frame(maxWidth: .infinity)
    }
}

struct BodyWeightToggleButton: View {
    let isBodyWeight: Bool
    let bodyWeight: Double
    let onToggle: () -> Void
    
    private var toggleColor: Color {
        isBodyWeight ? .green : .secondary
    }
    
    private var toggleBackground: Color {
        isBodyWeight ? Color.green.opacity(0.1) : Color(.systemGray5)
    }
    
    private var toggleBorder: Color {
        isBodyWeight ? Color.green.opacity(0.3) : Color.clear
    }
    
    private var toggleText: String {
        isBodyWeight ? "Body Weight" : "Add Weight"
    }
    
    var body: some View {
        Button(action: onToggle) {
            HStack(spacing: 6) {
                Image(systemName: isBodyWeight ? "person.fill" : "person")
                    .font(.system(size: 14, weight: .semibold, design: .default))
                    .foregroundColor(toggleColor)
                
                Text(toggleText)
                    .font(.system(size: 12, weight: .medium, design: .default))
                    .foregroundColor(toggleColor)
            }
            .padding(.horizontal, 12)
            .padding(.vertical, 6)
            .background(
                RoundedRectangle(cornerRadius: 16)
                    .fill(toggleBackground)
            )
            .overlay(
                RoundedRectangle(cornerRadius: 16)
                    .stroke(toggleBorder, lineWidth: 1)
            )
        }
    }
}

struct WorkoutStatsSection: View {
    let todaysSets: [WorkoutSet]
    
    private var totalSets: Int {
        todaysSets.count
    }
    
    private var totalVolume: Double {
        todaysSets.reduce(0) { $0 + ($1.weight * Double($1.reps)) }
    }
    
    private var bestSet: WorkoutSet? {
        todaysSets.max(by: { $0.weight < $1.weight })
    }
    
    var body: some View {
        VStack(spacing: 16) {
            Text("Today's Progress")
                .font(.system(size: 20, weight: .bold, design: .default))
                .foregroundColor(.primary)
            
            HStack(spacing: 20) {
                StatCard(
                    title: "Sets",
                    value: "\(totalSets)",
                    color: .blue
                )
                
                StatCard(
                    title: "Volume",
                    value: "\(Int(totalVolume)) lbs",
                    color: .green
                )
                
                if let bestSet = bestSet {
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
}

struct TodaysSetsSection: View {
    @Binding var isSetsExpanded: Bool
    let todaysSets: [WorkoutSet]
    
    var body: some View {
        VStack(spacing: 16) {
            Button(action: { isSetsExpanded.toggle() }) {
                HStack {
                    Text("Today's Sets")
                        .font(.system(size: 20, weight: .bold, design: .default))
                        .foregroundColor(.primary)
                    
                    Spacer()
                    
                    HStack(spacing: 6) {
                        Text("\(todaysSets.count)")
                            .font(.system(size: 20, weight: .heavy, design: .default))
                            .foregroundColor(.blue)
                        
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

struct ActionButtonsSection: View {
    let onAddSet: () -> Void
    let onFinishWorkout: () -> Void
    let isInputValid: Bool
    let hasSets: Bool
    
    var body: some View {
        VStack(spacing: 16) {
            // Add Set Button
            Button(action: onAddSet) {
                HStack(spacing: 12) {
                    Image(systemName: "plus.circle.fill")
                        .font(.title2)
                    Text("Add Set")
                        .font(.system(size: 20, weight: .bold, design: .default))
                }
                .foregroundColor(.white)
                .frame(maxWidth: .infinity)
                .frame(height: 56)
                .background(
                    LinearGradient(
                        colors: [Color.blue, Color.blue.opacity(0.8)],
                        startPoint: .leading,
                        endPoint: .trailing
                    )
                )
                .cornerRadius(28)
                .shadow(color: .blue.opacity(0.3), radius: 12, x: 0, y: 6)
            }
            .disabled(!isInputValid)
            .padding(.horizontal)
            
            // Finish Exercise Button
            if hasSets {
                Button(action: onFinishWorkout) {
                    HStack(spacing: 12) {
                        Image(systemName: "checkmark.circle.fill")
                            .font(.title2)
                        Text("Finish Exercise")
                            .font(.system(size: 20, weight: .bold, design: .default))
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
}

#Preview {
    NavigationView {
        WorkoutView(exercise: Exercise(name: "Bench Press", bodyPart: "Chest"))
            .modelContainer(for: [Exercise.self, WorkoutSet.self], inMemory: true)
    }
}