//
//  MeetingsView.swift
//  MyBookClub
//
//  Created by Samara Lima da Silva on 09/03/2026.
//

import SwiftUI

struct MeetingsView: View {
    var body: some View {
        ZStack {
            Color.background.ignoresSafeArea()
            VStack(spacing: Spacing.lg) {
                Image(systemName: "calendar")
                    .font(.system(size: 48))
                    .foregroundStyle(.accent)
                Text("Meetings")
                    .font(.appTitle)
                    .foregroundStyle(.inkPrimary)
                Text("Cross-club meeting list coming in Part 3")
                    .font(.appBody)
                    .foregroundStyle(.inkSecondary)
            }
        }
        .navigationTitle("Meetings")
        .navigationBarTitleDisplayMode(.inline)
    }
}

#Preview {
    MeetingsView()
}
