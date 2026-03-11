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
                    .foregroundColor(.accent)
                Text("My Clubs")
                    .font(.appTitle)
                    .foregroundColor(.inkPrimary)
                Text("Club management coming in Part 2")
                    .font(.appBody)
                    .foregroundColor(.inkSecondary)
            }
        }
        .navigationTitle("My Clubs")
        .navigationBarTitleDisplayMode(.inline)
    }
}


#Preview {
    MyClubsView()
}
