//
//  CubHistoryTab.swift
//  MyBookClub
//
//  Created by Samara Lima da Silva on 10/03/2026.
//

import SwiftUI

struct ClubHistoryTab: View {
    let club: Club

    var body: some View {
        VStack(alignment: .leading, spacing: Spacing.lg) {
            Text("Past Books")
                .font(.appHeadline)
                .foregroundStyle(.inkPrimary)
            Text("Reading history coming in Part 3.")
                .font(.appBody)
                .foregroundStyle(.inkTertiary)
        }
        .padding(.bottom, Spacing.xxl)
    }
    
}
