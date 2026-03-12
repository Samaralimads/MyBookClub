//
//  CreateClubViewModel.swift
//  MyBookClub
//
//  Created by Samara Lima da Silva on 11/03/2026.
//

import Foundation
import SwiftUI
import PhotosUI

@Observable
final class CreateClubViewModel {

    // MARK: - Form Fields

    var name              = ""
    var description       = ""
    var selectedGenre: Genre?        = nil
    var isPublic                     = true
    var memberCapText                = ""
    var cityLabel                    = ""

    // Meeting Schedule
    var frequency: MeetingFrequency? = nil
    var recurringDay: String?        = nil
    var recurringTime: Date          = Calendar.current.date(
                                         bySettingHour: 19, minute: 0, second: 0,
                                         of: .now
                                       ) ?? .now

    // Cover image
    var selectedPhotoItem: PhotosPickerItem? = nil {
        didSet { Task { await loadSelectedImage() } }
    }
    var coverImage: UIImage? = nil

    // MARK: - State

    var isLoading   = false
    var error: AppError?
    var createdClub: Club?

    // MARK: - Derived

    var memberCap: Int {
        Int(memberCapText.trimmingCharacters(in: .whitespaces)) ?? 12
    }

    var canCreate: Bool {
        !name.trimmingCharacters(in: .whitespaces).isEmpty &&
        selectedGenre != nil &&
        !description.trimmingCharacters(in: .whitespaces).isEmpty &&
        !cityLabel.trimmingCharacters(in: .whitespaces).isEmpty
    }

    // MARK: - Image Loading

    @MainActor
    private func loadSelectedImage() async {
        guard let item = selectedPhotoItem else { return }
        if let data = try? await item.loadTransferable(type: Data.self),
           let image = UIImage(data: data) {
            coverImage = image
        }
    }

    // MARK: - Create

    func createClub(locationService: LocationService) async {
        guard canCreate, let genre = selectedGenre else { return }
        isLoading = true
        defer { isLoading = false }
        error = nil

        let timeString: String? = {
            guard recurringDay != nil else { return nil }
            let f = DateFormatter()
            f.dateFormat = "HH:mm:ss"
            return f.string(from: recurringTime)
        }()

        do {
            // 1. Create the club row first (we need the club ID for the image path)
            var club = try await SupabaseService.shared.createClub(
                name:          name.trimmingCharacters(in: .whitespaces),
                description:   description.trimmingCharacters(in: .whitespaces),
                genreTags:     [genre.rawValue],
                lat:           locationService.roundedLatitude,
                lng:           locationService.roundedLongitude,
                cityLabel:     cityLabel.trimmingCharacters(in: .whitespaces),
                isPublic:      isPublic,
                memberCap:     memberCap,
                coverImageURL: nil,
                recurringDay:  recurringDay,
                recurringTime: timeString
            )

            // 2. Upload cover image if one was selected, then patch the club row
            if let image = coverImage {
                let url = try await ImageUploadService.shared.uploadClubCover(image, clubId: club.id)
                try await SupabaseService.shared.updateClubCover(clubId: club.id, coverImageURL: url)
                club.coverImageURL = url
            }

            createdClub = club

        } catch {
            self.error = AppError(underlying: error)
        }
    }
}
