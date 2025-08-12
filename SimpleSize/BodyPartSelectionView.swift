//
//  BodyPartSelectionView.swift
//  SimpleSize
//
//  Created by Quintin Smith on 8/11/25.
//

import SwiftUI

struct BodyPartSelectionView: View {
    var body: some View {
        NavigationView {
            List {
                ForEach(BodyPart.allBodyParts, id: \.name) { bodyPart in
                    NavigationLink(destination: ExerciseListView(bodyPart: bodyPart.name)) {
                        HStack {
                            Image(systemName: bodyPart.systemImage)
                                .foregroundColor(.blue)
                                .frame(width: 30, height: 30)
                            Text(bodyPart.name)
                                .font(.system(size: 20, weight: .bold, design: .default))
                        }
                        .padding(.vertical, 8)
                    }
                }
            }
            .navigationTitle("Select Body Part")
        }
    }
}

#Preview {
    BodyPartSelectionView()
}