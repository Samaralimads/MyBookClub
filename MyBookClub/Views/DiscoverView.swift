//
//  DiscoverView.swift
//  MyBookClub
//
//  Created by Samara Lima da Silva on 09/03/2026.
//

import SwiftUI

struct DiscoverView: View {
    var body: some View {
        ZStack {
            Color.appBackground.ignoresSafeArea()
            VStack(spacing: Spacing.lg) {
                Image(systemName: "map.fill")
                    .font(.system(size: 48))
                    .foregroundColor(.accent)
                Text("Discover")
                    .font(.appTitle)
                    .foregroundColor(.inkPrimary)
                Text("Map-based club discovery coming in Part 2")
                    .font(.appBody)
                    .foregroundColor(.inkSecondary)
            }
        }
        .navigationTitle("Discover")
        .navigationBarTitleDisplayMode(.inline)
    }
}

#Preview {
    DiscoverView()
}
