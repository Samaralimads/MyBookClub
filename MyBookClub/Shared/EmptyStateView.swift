//
//  EmptyStateView.swift
//  MyBookClub
//
//  Created by Samara Lima da Silva on 02/04/2026.
//

import SwiftUI

struct EmptyStateView: View {
    let icon: String
    let title: String
    let description: String

    var body: some View {
        VStack(spacing: Spacing.lg) {
            ZStack {
                Circle()
                    .fill(Color.accentSubtle)
                    .frame(width: 80, height: 80)
                Image(systemName: icon)
                    .font(.system(size: 32))
                    .foregroundStyle(.accent)
            }

            VStack(spacing: Spacing.sm) {
                Text(title)
                    .font(.appHeadline)
                    .foregroundStyle(.inkPrimary)
                    .multilineTextAlignment(.center)

                Text(description)
                    .font(.appBody)
                    .foregroundStyle(.inkSecondary)
                    .multilineTextAlignment(.center)
                    .padding(.horizontal, Spacing.xl)
            }
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, Spacing.xxl)
    }
}

#Preview {
    VStack {
        EmptyStateView(
            icon: "books.vertical.fill",
            title: "No clubs yet",
            description: "Join a club from Discover or create your own."
        )
        EmptyStateView(
            icon: "calendar",
            title: "No upcoming meetings",
            description: "Meetings from your clubs will appear here."
        )
    }
    .background(Color.background)
}
