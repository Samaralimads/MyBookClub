//
//  MemberProfileView.swift
//  MyBookClub
//
//  Created by Samara Lima da Silva on 27/04/2026.
//

import SwiftUI

struct MemberProfileView: View {
    let userId: UUID

    @State private var vm = MemberProfileViewModel()
    @Environment(\.dismiss) private var dismiss

    var body: some View {
        ZStack {
            Color.background.ignoresSafeArea()

            if vm.isLoading {
                ProgressView()
                    .tint(.accent)
            } else if let user = vm.user {
                profileContent(user: user)
            } else if vm.error != nil {
                ContentUnavailableView(
                    "Couldn't Load Profile",
                    systemImage: "person.slash",
                    description: Text("Something went wrong. Please try again.")
                )
            }
        }
        .navigationBarTitleDisplayMode(.inline)
        .task { await vm.load(userId: userId) }
    }

    // MARK: - Profile content

    private func profileContent(user: AppUser) -> some View {
        ScrollView {
            VStack(spacing: 0) {
                heroSection(user: user)
                Divider().overlay { Color.border }
                if let bio = user.bio, !bio.isEmpty {
                    bioSection(bio)
                }
                if let genres = user.genrePrefs, !genres.isEmpty {
                    genresSection(genres)
                    Divider().overlay { Color.border }
                }

            }
        }
        .scrollIndicators(.hidden)
    }

    // MARK: - Hero

    private func heroSection(user: AppUser) -> some View {
        VStack(spacing: Spacing.md) {
            AvatarView(urlString: user.avatarURL, size: 80)
                .padding(.top, Spacing.xl)

            VStack(spacing: Spacing.xs) {
                Text(user.displayName)
                    .font(.appHeadline.bold())
                    .foregroundStyle(.inkPrimary)

                Label("Member since \(user.createdAt.formatted(.dateTime.month(.wide).year()))", systemImage: "calendar")
                    .font(.appCaption)
                    .foregroundStyle(.inkSecondary)
            }
        }
        .frame(maxWidth: .infinity)
        .padding(.bottom, Spacing.xl)
    }

    // MARK: - Genres

    private func genresSection(_ genres: [String]) -> some View {
        VStack(alignment: .leading, spacing: Spacing.md) {
            Text("Favourite Genres")
                .font(.appCaption.weight(.semibold))
                .foregroundStyle(.inkSecondary)
                .textCase(.uppercase)
                .tracking(0.6)

            FlowLayout(spacing: Spacing.sm) {
                ForEach(genres, id: \.self) { genre in
                    Text(Genre(rawValue: genre)?.label ?? genre)
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

    // MARK: - Bio

    private func bioSection(_ bio: String) -> some View {
        VStack(alignment: .leading, spacing: Spacing.md) {
            Text("About")
                .font(.appCaption.weight(.semibold))
                .foregroundStyle(.inkSecondary)
                .textCase(.uppercase)
                .tracking(0.6)

            Text(bio)
                .font(.appBody)
                .foregroundStyle(.inkPrimary)
                .fixedSize(horizontal: false, vertical: true)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(Spacing.lg)
    }
}
