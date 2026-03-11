//
//  ClubVoteTab.swift
//  MyBookClub
//
//  Created by Samara Lima da Silva on 10/03/2026.
//

import SwiftUI

struct ClubVoteTab: View {
    let club: Club
    let isMember: Bool

    var body: some View {
        VStack(alignment: .leading, spacing: Spacing.lg) {
            Text("Next Book Voting")
                .font(.appHeadline)
                .foregroundColor(.inkPrimary)

            if isMember {
                Text("Voting coming in Part 3.")
                    .font(.appBody)
                    .foregroundColor(.inkTertiary)
            } else {
                membersOnlyBanner
            }
        }
        .padding(.bottom, Spacing.xxl)
    }

    private var membersOnlyBanner: some View {
        VStack(spacing: Spacing.md) {
            Image(systemName: "lock.fill")
                .font(.system(size: 28))
                .foregroundColor(.accentColor)
            Text("Members Only")
                .font(.appHeadline)
                .foregroundColor(.inkPrimary)
            Text("Join this club to access voting.")
                .font(.appBody)
                .foregroundColor(.inkSecondary)
                .multilineTextAlignment(.center)
        }
        .frame(maxWidth: .infinity)
        .padding(Spacing.xl)
        .background(Color.accentSubtle)
        .clipShape(RoundedRectangle(cornerRadius: CornerRadius.card))
    }
    
}

