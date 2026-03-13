//
//  DiscoverEmptyState.swift
//  MyBookClub
//
//  Created by Samara Lima da Silva on 11/03/2026.
//

import SwiftUI

struct DiscoverEmptyState: View {
    var onCreateClub: (() -> Void)? = nil

    var body: some View {
        ContentUnavailableView {
            Image(systemName: "book.closed.circle.fill")
                .font(.system(size: 80))
                .foregroundStyle(.accent)

            Label("No clubs found nearby", systemImage: "")
                .font(.appHeadline)
                .foregroundStyle(.inkPrimary)
                .padding(.horizontal, Spacing.xxl)

        } description: {
            Text("Try expanding your search or changing your filters.")
                .font(.appBody)
                .foregroundStyle(.inkSecondary)

        } actions: {
            Button("Create a Club") {
                onCreateClub?()
            }
            .buttonStyle(PrimaryButtonStyle(isFullWidth: false))
        }
    }
}

#Preview {
    DiscoverEmptyState()
}
