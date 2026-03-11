//
//  ClubBoardTab.swift
//  MyBookClub
//
//  Created by Samara Lima da Silva on 10/03/2026.
//

import SwiftUI

struct ClubBoardTab: View {
    let club: Club
    let isOrganiser: Bool

    var body: some View {
        VStack(alignment: .leading, spacing: Spacing.lg) {
            Text("Board")
                .font(.appHeadline)
                .foregroundStyle(.inkPrimary)
            Text("Club announcements and discussion coming in Part 3.")
                .font(.appBody)
                .foregroundStyle(.inkTertiary)
        }
        .padding(.bottom, Spacing.xxl)
    }
}
