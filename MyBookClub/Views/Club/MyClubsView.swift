//
//  MyClubsView.swift
//  MyBookClub
//
//  Created by Samara Lima da Silva on 09/03/2026.
//

import SwiftUI

struct MyClubsView: View {
    var body: some View {
        ZStack {
            Color.background.ignoresSafeArea()
            VStack(spacing: Spacing.lg) {
                Image(systemName: "books.vertical.fill")
                    .font(.system(size: 48))
                    .foregroundStyle(.accent)
                Text("My Clubs")
                    .font(.appTitle)
                    .foregroundStyle(.inkPrimary)
                Text("Club management coming in Part 2")
                    .font(.appBody)
                    .foregroundStyle(.inkSecondary)
            }
        }
        .navigationTitle("My Clubs")
        .navigationBarTitleDisplayMode(.inline)
    }
}


#Preview {
    MyClubsView()
}
