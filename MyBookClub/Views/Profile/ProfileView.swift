//
//  ProfileView.swift
//  MyBookClub
//
//  Created by Samara Lima da Silva on 09/03/2026.
//

import SwiftUI

struct ProfileView: View {
    @Environment(AuthViewModel.self) private var authVM
    @State private var vm = ProfileViewModel()
    @State private var showSettings = false
    @State private var showEditProfile = false

    var body: some View {
        ZStack {
            Color.background.ignoresSafeArea()
            scrollContent
        }
        .navigationTitle("Profile")
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            ToolbarItem(placement: .topBarTrailing) {
                settingsButton
            }
        }
        .task { await vm.load() }
        .navigationDestination(isPresented: $showSettings) {
            SettingsView()
        }
        .sheet(isPresented: $showEditProfile) {
            EditProfileView(user: vm.user)
                .onDisappear { Task { await vm.load() } }
        }
        .alert("Something went wrong", isPresented: .constant(vm.error != nil)) {
            Button("OK") { vm.error = nil }
        } message: {
            Text(vm.error?.localizedDescription ?? "")
        }
    }

    // MARK: - Scroll content

    private var scrollContent: some View {
        ScrollView {
            VStack(spacing: 0) {
                heroSection
                Divider().overlay(Color.border)

                statsSection
                Divider().overlay(Color.border)

                if let genres = vm.user?.genrePrefs, !genres.isEmpty {
                    genresSection(genres)
                    Divider().overlay(Color.border)
                }

                if !vm.currentlyReadingBooks.isEmpty {
                    currentlyReadingSection(vm.currentlyReadingBooks)
                }
            }
        }
        .scrollIndicators(.hidden)
    }

    // MARK: - Hero

    private var heroSection: some View {
        VStack(spacing: Spacing.md) {
            ProfileAvatarView(
                avatarURL: vm.user?.avatarURL,
                initials: vm.avatarInitials,
                onEditTap: { showEditProfile = true }
            )

            Text(vm.user?.displayName ?? " ")
                .font(.appHeadline.bold())
                .foregroundStyle(.inkPrimary)

            if let bio = vm.user?.bio, !bio.isEmpty {
                Text(bio)
                    .font(.appCaption)
                    .foregroundStyle(.inkSecondary)
                    .multilineTextAlignment(.center)
                    .padding(.horizontal, Spacing.xl)
            }
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, Spacing.xl)
    }

    // MARK: - Stats

    private var statsSection: some View {
        HStack(spacing: 0) {
            statItem(value: vm.clubCount, label: "Clubs Joined")
            Divider()
                .frame(height: 36)
                .overlay(Color.border)
            statItem(value: vm.booksRead, label: "Books Read")
        }
        .padding(.vertical, Spacing.lg)
    }

    private func statItem(value: Int, label: String) -> some View {
        VStack(spacing: Spacing.xs) {
            Text("\(value)")
                .font(.appTitle)
                .foregroundStyle(.inkPrimary)
            Text(label)
                .font(.appCaption)
                .foregroundStyle(.inkTertiary)
                .multilineTextAlignment(.center)
        }
        .frame(maxWidth: .infinity)
    }

    // MARK: - Genres

    private func genresSection(_ genres: [String]) -> some View {
        VStack(alignment: .leading, spacing: Spacing.md) {
            sectionHeader("Favourite Genres")
            FlowLayout(spacing: Spacing.sm) {
                ForEach(genres, id: \.self) { genre in
                    Text(genre)
                        .font(.appCaption)
                        .foregroundStyle(.accent)
                        .padding(.vertical, Spacing.xs + 2)
                        .padding(.horizontal, Spacing.md)
                        .background(Color.accentSubtle)
                        .clipShape(.rect(cornerRadius: 20))
                        .overlay {
                            RoundedRectangle(cornerRadius: 20)
                                .stroke(Color.accent.opacity(0.4), lineWidth: 1)
                        }
                }
            }
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(Spacing.lg)
    }

    // MARK: - Currently Reading

    private func currentlyReadingSection(_ entries: [(book: Book, clubName: String)]) -> some View {
        VStack(alignment: .leading, spacing: Spacing.md) {
            sectionHeader(entries.count == 1 ? "Currently Reading" : "Currently Reading")
            VStack(spacing: Spacing.sm) {
                ForEach(entries, id: \.book.id) { entry in
                    ProfileCurrentlyReadingCard(book: entry.book, clubName: entry.clubName)
                }
            }
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(Spacing.lg)
    }

    // MARK: - Helpers

    private func sectionHeader(_ title: String) -> some View {
        Text(title.uppercased())
            .font(.system(size: 12, weight: .semibold))
            .foregroundStyle(.inkTertiary)
            .kerning(0.6)
    }

    private var settingsButton: some View {
        Button {
            showSettings = true
        } label: {
            Image(systemName: "gearshape")
                .font(.system(size: 17, weight: .medium))
                .foregroundStyle(.inkSecondary)
                .frame(width: 44, height: 44)
        }
        .accessibilityLabel("Settings")
    }
}


#Preview {
    NavigationStack {
        ProfileView()
            .environment(AuthViewModel())
    }
}
