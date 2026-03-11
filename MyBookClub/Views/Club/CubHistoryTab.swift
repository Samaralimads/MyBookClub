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
                .foregroundColor(.inkPrimary)
            Text("Reading history coming in Part 3.")
                .font(.appBody)
                .foregroundColor(.inkTertiary)
        }
        .padding(.bottom, Spacing.xxl)
    }
    
}

