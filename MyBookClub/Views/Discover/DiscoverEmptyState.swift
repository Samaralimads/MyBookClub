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
        VStack(spacing: Spacing.lg) {
            EmptyStateView(
                icon: "map",
                title: "No clubs found nearby",
                description: "Try expanding your search radius or changing your filters."
            )
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
