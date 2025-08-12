//
//  SettingsView.swift
//  SimpleSize
//
//  Created by Quintin Smith on 8/12/25.
//

import SwiftUI
import SwiftData

struct SettingsView: View {
    @Environment(\.dismiss) private var dismiss
    @AppStorage("userBodyWeight") private var bodyWeight: Double = 150.0
    @AppStorage("weightUnit") private var weightUnit: WeightUnit = .lbs
    
    enum WeightUnit: String, CaseIterable {
        case lbs = "lbs"
        case kg = "kg"
        
        var displayName: String {
            switch self {
            case .lbs: return "Pounds"
            case .kg: return "Kilograms"
            }
        }
    }
    
    private func saveSettings() {
        // Validate body weight
        guard bodyWeight > 0 && bodyWeight <= 1000 else {
            print("❌ Invalid body weight: \(bodyWeight)")
            return
        }
        
        print("✅ Settings saved - Body weight: \(bodyWeight) \(weightUnit)")
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
                        // Header
                        VStack(spacing: 16) {
                            Image(systemName: "gearshape.fill")
                                .font(.system(size: 48, weight: .semibold, design: .default))
                                .foregroundColor(.blue)
                            
                            Text("Settings")
                                .font(.system(size: 32, weight: .heavy, design: .default))
                                .foregroundColor(.primary)
                        }
                        .padding(.top)
                        
                        // Body Weight Section
                        VStack(alignment: .leading, spacing: 16) {
                            Text("Body Weight")
                                .font(.system(size: 24, weight: .bold, design: .default))
                                .padding(.horizontal)
                            
                            VStack(spacing: 16) {
                                // Weight Unit Picker
                                VStack(alignment: .leading, spacing: 8) {
                                    Text("Weight Unit")
                                        .font(.system(size: 16, weight: .semibold, design: .default))
                                        .foregroundColor(.secondary)
                                    
                                    Picker("Weight Unit", selection: $weightUnit) {
                                        ForEach(WeightUnit.allCases, id: \.self) { unit in
                                            Text(unit.displayName).tag(unit)
                                        }
                                    }
                                    .pickerStyle(SegmentedPickerStyle())
                                    .onChange(of: weightUnit) { _, _ in
                                        saveSettings()
                                    }
                                }
                                .padding(.horizontal)
                                
                                // Body Weight Input
                                VStack(alignment: .leading, spacing: 8) {
                                    Text("Your Body Weight")
                                        .font(.system(size: 16, weight: .semibold, design: .default))
                                        .foregroundColor(.secondary)
                                    
                                    HStack(spacing: 12) {
                                        TextField("0", value: $bodyWeight, format: .number)
                                            .font(.system(size: 24, weight: .bold, design: .default))
                                            .keyboardType(.decimalPad)
                                            .multilineTextAlignment(.center)
                                            .padding(.horizontal, 16)
                                            .padding(.vertical, 12)
                                            .background(Color(.systemBackground))
                                            .cornerRadius(12)
                                            .shadow(color: .black.opacity(0.05), radius: 4, x: 0, y: 2)
                                            .onChange(of: bodyWeight) { _, newValue in
                                                saveSettings()
                                            }
                                            .onSubmit {
                                                // Dismiss keyboard when submitted
                                                DispatchQueue.main.async {
                                                    UIApplication.shared.sendAction(#selector(UIResponder.resignFirstResponder), to: nil, from: nil, for: nil)
                                                }
                                            }
                                        
                                        Text(weightUnit.rawValue)
                                            .font(.system(size: 20, weight: .semibold, design: .default))
                                            .foregroundColor(.secondary)
                                    }
                                }
                                .padding(.horizontal)
                            }
                            .padding(.vertical, 20)
                            .background(Color(.systemBackground))
                            .cornerRadius(16)
                            .shadow(color: .black.opacity(0.05), radius: 4, x: 0, y: 2)
                            .padding(.horizontal)
                        }
                        
                        // App Info Section
                        VStack(alignment: .leading, spacing: 16) {
                            Text("App Information")
                                .font(.system(size: 24, weight: .bold, design: .default))
                                .padding(.horizontal)
                            
                            VStack(spacing: 12) {
                                InfoRow(title: "Version", value: "1.0.0")
                                InfoRow(title: "Build", value: "1")
                                InfoRow(title: "Developer", value: "Quintin Smith")
                            }
                            .padding(.vertical, 20)
                            .background(Color(.systemBackground))
                            .cornerRadius(16)
                            .shadow(color: .black.opacity(0.05), radius: 4, x: 0, y: 2)
                            .padding(.horizontal)
                        }
                        
                        Spacer(minLength: 30)
                    }
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
            .onTapGesture {
                // Dismiss keyboard when tapping outside
                DispatchQueue.main.async {
                    UIApplication.shared.sendAction(#selector(UIResponder.resignFirstResponder), to: nil, from: nil, for: nil)
                }
            }
            .ignoresSafeArea(.keyboard, edges: .bottom)
        }
    }
}

struct InfoRow: View {
    let title: String
    let value: String
    
    var body: some View {
        HStack {
            Text(title)
                .font(.system(size: 16, weight: .medium, design: .default))
                .foregroundColor(.secondary)
            
            Spacer()
            
            Text(value)
                .font(.system(size: 16, weight: .semibold, design: .default))
                .foregroundColor(.primary)
        }
        .padding(.horizontal, 20)
    }
}

#Preview {
    SettingsView()
}
