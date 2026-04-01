//
//  EditProfileViewModel.swift
//  MyBookClub
//
//  Created by Samara Lima da Silva on 01/04/2026.
//

import SwiftUI
import PhotosUI

@Observable
@MainActor
final class EditProfileViewModel {

    // MARK: - Form fields

    var displayName: String = ""
    var bio: String = ""
    var selectedGenres: Set<String> = []
    // Avatar
    var selectedPhotoItem: PhotosPickerItem? = nil {
        didSet { Task { await loadSelectedPhoto() } }
    }
    var avatarImage: UIImage? = nil
    var existingAvatarURL: String? = nil

    // MARK: - State

    var isLoading = false
    var isSaved = false
    var error: AppError?

    // MARK: - Validation

    var displayNameError: String? {
        let trimmed = displayName.trimmingCharacters(in: .whitespaces)
        guard !trimmed.isEmpty else { return nil }
        if trimmed.count < 2  { return "Name must be at least 2 characters" }
        if trimmed.count > 40 { return "Name must be 40 characters or fewer" }
        return nil
    }

    var bioError: String? {
        bio.count > 300 ? "Bio must be 300 characters or fewer" : nil
    }

    var canSave: Bool {
        displayNameError == nil &&
        bioError == nil &&
        !displayName.trimmingCharacters(in: .whitespaces).isEmpty
    }

    // MARK: - Prefill from existing user

    func prefill(from user: AppUser?) {
        displayName = user?.displayName ?? ""
        bio = user?.bio ?? ""
        selectedGenres = Set(user?.genrePrefs ?? [])
        existingAvatarURL = user?.avatarURL
    }

    // MARK: - Genre toggle (max 5)

    func toggleGenre(_ genre: String) {
        if selectedGenres.contains(genre) {
            selectedGenres.remove(genre)
        } else if selectedGenres.count < 5 {
            selectedGenres.insert(genre)
        }
    }

    // MARK: - Avatar photo loading

    private func loadSelectedPhoto() async {
        guard let item = selectedPhotoItem else { return }
        if let data = try? await item.loadTransferable(type: Data.self),
           let image = UIImage(data: data) {
            avatarImage = image
        }
    }

    // MARK: - Save

    func save() async {
        guard canSave else { return }
        isLoading = true
        defer { isLoading = false }
        error = nil

        do {
            var user = try await SupabaseService.shared.fetchCurrentUser()

            // Upload new avatar if one was picked
            if let image = avatarImage {
                let url = try await ImageUploadService.shared.uploadAvatar(image)
                user.avatarURL = url
            }

            user.displayName = displayName.trimmingCharacters(in: .whitespaces)
            user.bio = bio.trimmingCharacters(in: .whitespaces).isEmpty
                ? nil
                : bio.trimmingCharacters(in: .whitespaces)
            user.genrePrefs = Array(selectedGenres)
            try await SupabaseService.shared.upsertUser(user)
            isSaved = true
        } catch {
            self.error = AppError(underlying: error)
        }
    }
}
