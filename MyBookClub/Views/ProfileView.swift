//
//  ProfileView.swift
//  MyBookClub
//
//  Created by Samara Lima da Silva on 09/03/2026.
//

import SwiftUI

struct ProfileView: View {
    @Environment(AuthViewModel.self) private var authVM

    var body: some View {
        ZStack {
            Color.appBackground.ignoresSafeArea()
            VStack(spacing: Spacing.lg) {
                Image(systemName: "person.fill")
                    .font(.system(size: 48))
                    .foregroundColor(.accent)
                Text("Profile")
                    .font(.appTitle)
                    .foregroundColor(.inkPrimary)
                Text("Full profile + settings coming in Part 4")
                    .font(.appBody)
                    .foregroundColor(.inkSecondary)

                // Sign out button for testing
                Button("Sign Out") {
                    Task { await authVM.signOut() }
                }
                .buttonStyle(SecondaryButtonStyle())
                .padding(.top, Spacing.xl)
            }
            .padding(.horizontal, Spacing.xl)
        }
        .navigationTitle("Profile")
        .navigationBarTitleDisplayMode(.inline)
    }
}


#Preview {
    ProfileView()
}
