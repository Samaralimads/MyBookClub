//
//  EditProfileView.swift
//  MyBookClub
//
//  Created by Samara Lima da Silva on 01/04/2026.
//

import SwiftUI
import PhotosUI

struct EditProfileView: View {
    let user: AppUser?
    @Environment(\.dismiss) private var dismiss
    @State private var vm = EditProfileViewModel()

    var body: some View {
        NavigationStack {
            ZStack {
                Color.background.ignoresSafeArea()

                ScrollView {
                    VStack(alignment: .leading, spacing: Spacing.xl) {
                        avatarSection
                        displayNameSection
                        bioSection
                        genresSection
                            if let error = vm.error {
                            Text(error.message)
                                .font(.appCaption)
                                .foregroundStyle(.red)
                        }
                    }
                    .padding(.horizontal, Spacing.lg)
                    .padding(.vertical, Spacing.lg)
                }
                .scrollIndicators(.hidden)

                if vm.isLoading { LoadingOverlay() }
            }
            .navigationTitle("Edit Profile")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarLeading) {
                    Button("Cancel") { dismiss() }
                        .foregroundStyle(.accent)
                }
                ToolbarItem(placement: .topBarTrailing) {
                    Button("Save") {
                        Task {
                            await vm.save()
                        }
                    }
                    .font(.appBody.weight(.semibold))
                    .foregroundStyle(.accent)
                    .disabled(!vm.canSave || vm.isLoading)
                }
            }

            .onChange(of: vm.isSaved) { _, saved in
                if saved { dismiss() }
            }
        }
        .onAppear {
            vm.prefill(from: user)
        }
    }

    // MARK: - Avatar

    private var avatarSection: some View {
        HStack {
            Spacer()
            PhotosPicker(selection: $vm.selectedPhotoItem, matching: .images) {
                ZStack(alignment: .bottomTrailing) {
                    avatarImage
                    cameraBadge
                }
            }
            Spacer()
        }
        .padding(.top, Spacing.md)
    }

    private var avatarImage: some View {
        Group {
            if let picked = vm.avatarImage {
                Image(uiImage: picked)
                    .resizable()
                    .scaledToFill()
            } else if let urlString = vm.existingAvatarURL,
                      let url = URL(string: urlString) {
                AsyncImage(url: url) { image in
                    image.resizable().scaledToFill()
                } placeholder: {
                    initialsPlaceholder
                }
            } else {
                initialsPlaceholder
            }
        }
        .frame(width: 88, height: 88)
        .clipShape(.circle)
        .overlay { Circle().stroke(Color.accent, lineWidth: 2.5) }
    }

    private var initialsPlaceholder: some View {
        Color.accentSubtle
            .overlay {
                Text(initials)
                    .font(.system(size: 28, weight: .bold))
                    .foregroundStyle(.inkPrimary)
            }
    }

    private var cameraBadge: some View {
        Image(systemName: "camera.fill")
            .font(.system(size: 11, weight: .semibold))
            .foregroundStyle(.white)
            .frame(width: 28, height: 28)
            .background(Color.accent)
            .clipShape(.circle)
            .overlay { Circle().stroke(Color.background, lineWidth: 2) }
    }

    private var initials: String {
        let name = vm.displayName.isEmpty ? (user?.displayName ?? "?") : vm.displayName
        let parts = name.split(separator: " ").map { String($0) }
        if parts.count >= 2 {
            return (parts[0].prefix(1) + parts[1].prefix(1)).uppercased()
        }
        return String(name.prefix(2)).uppercased()
    }

    // MARK: - Display Name

    private var displayNameSection: some View {
        VStack(alignment: .leading, spacing: Spacing.sm) {
            sectionLabel("Display Name")
            TextField("Your name", text: $vm.displayName)
                .font(.appBody)
                .foregroundStyle(.inkPrimary)
                .padding(.horizontal, Spacing.md)
                .frame(height: 50)
                .background(Color.cardBackground)
                .clipShape(.rect(cornerRadius: CornerRadius.card))
                .overlay {
                    RoundedRectangle(cornerRadius: CornerRadius.card)
                        .stroke(vm.displayNameError != nil ? Color.red.opacity(0.7) : Color.border, lineWidth: 1)
                }
            if let err = vm.displayNameError {
                Text(err).font(.appCaption).foregroundStyle(.red)
            } else {
                Text("\(vm.displayName.count)/40")
                    .font(.appCaption)
                    .foregroundStyle(.inkTertiary)
                    .frame(maxWidth: .infinity, alignment: .trailing)
            }
        }
    }

    // MARK: - Bio

    private var bioSection: some View {
        VStack(alignment: .leading, spacing: Spacing.sm) {
            sectionLabel("Bio")
            TextField(
                "Tell other readers about yourself...",
                text: $vm.bio,
                axis: .vertical
            )
            .lineLimit(4...)
            .font(.appBody)
            .foregroundStyle(.inkPrimary)
            .padding(Spacing.md)
            .background(Color.cardBackground)
            .clipShape(.rect(cornerRadius: CornerRadius.card))
            .overlay {
                RoundedRectangle(cornerRadius: CornerRadius.card)
                    .stroke(vm.bioError != nil ? Color.red.opacity(0.7) : Color.border, lineWidth: 1)
            }
            if let err = vm.bioError {
                Text(err).font(.appCaption).foregroundStyle(.red)
            } else {
                Text("\(vm.bio.count)/300")
                    .font(.appCaption)
                    .foregroundStyle(.inkTertiary)
                    .frame(maxWidth: .infinity, alignment: .trailing)
            }
        }
    }

    // MARK: - Genres

    private var genresSection: some View {
        VStack(alignment: .leading, spacing: Spacing.md) {
            sectionLabel("Favourite Genres")
            Text("Pick up to 5")
                .font(.appCaption)
                .foregroundStyle(.inkTertiary)
            FlowLayout(spacing: Spacing.sm) {
                ForEach(Genre.allCases, id: \.rawValue) { genre in
                    let selected = vm.selectedGenres.contains(genre.rawValue)
                    Button {
                        vm.toggleGenre(genre.rawValue)
                    } label: {
                        Text(genre.label)
                            .font(.appCaption)
                            .foregroundStyle(selected ? .white : .inkPrimary)
                            .padding(.vertical, Spacing.xs + 2)
                            .padding(.horizontal, Spacing.md)
                            .background(selected ? Color.accent : Color.cardBackground)
                            .clipShape(.rect(cornerRadius: CornerRadius.button))
                            .overlay {
                                RoundedRectangle(cornerRadius: CornerRadius.button)
                                    .stroke(selected ? Color.accent : Color.border, lineWidth: 1.5)
                            }
                    }
                    .animation(Animations.standard, value: selected)
                    .disabled(!selected && vm.selectedGenres.count >= 5)
                }
            }
        }
    }


    // MARK: - Helpers

    private func sectionLabel(_ title: String) -> some View {
        Text(title)
            .font(.appBody.weight(.semibold))
            .foregroundStyle(.inkPrimary)
    }
}

#Preview {
    EditProfileView(user: nil)
}
