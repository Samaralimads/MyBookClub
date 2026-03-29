//
//  CreateClubViewModel.swift
//  MyBookClub
//
//  Created by Samara Lima da Silva on 11/03/2026.
//

import Foundation
import SwiftUI
import PhotosUI
import MapKit

@Observable
final class CreateClubViewModel {
    
    // MARK: - Mode
    
    enum Mode {
        case create
        case edit(Club)
        
        var isEditing: Bool {
            if case .edit = self { return true }
            return false
        }
        
        var existingClub: Club? {
            if case .edit(let club) = self { return club }
            return nil
        }
    }
    
    let mode: Mode
    
    // MARK: - Form Fields
    
    var name = ""
    var description = ""
    var selectedGenre: Genre? = nil
    var isPublic = true
    var memberCapText = ""
    var cityLabel = ""
    
    // Coordinates resolved from the city autocomplete selection
    var resolvedLat: Double? = nil
    var resolvedLng: Double? = nil
    
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
    var existingCoverURL: String? = nil
    
    // MARK: - State
    
    var isLoading        = false
    var error: AppError?
    var createdClub: Club?
    var showDeleteConfirm = false
    var isDeleting        = false
    
    // MARK: - Init
    
    init(mode: Mode = .create) {
        self.mode = mode
        if let club = mode.existingClub {
            prefill(from: club)
        }
    }
    
    private func prefill(from club: Club) {
        name             = club.name
        description      = club.description ?? ""
        cityLabel        = club.cityLabel
        isPublic         = club.isPublic
        memberCapText    = club.memberCap > 0 ? String(club.memberCap) : ""
        existingCoverURL = club.coverImageURL
        resolvedLat      = club.lat
        resolvedLng      = club.lng
        
        if let tag = club.genreTags.first {
            selectedGenre = Genre(rawValue: tag)
        }
        if let day = club.recurringDay {
            recurringDay = day
        }
        if let timeString = club.recurringTime {
            // Parse "HH:mm:ss" back into a Date so the DatePicker is pre-set
            let formatter = DateFormatter()
            formatter.dateFormat = "HH:mm:ss"
            if let date = formatter.date(from: timeString) {
                recurringTime = date
            }
        }
        if let freq = club.recurringDay {
            // Best-effort: keep whatever was stored; frequency isn't persisted separately
            _ = freq
        }
    }
    
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
    
    // MARK: - City Selection
    
    func selectSuggestion(_ completion: MKLocalSearchCompletion, citySearch: CitySearchService) {
        Task {
            if let coord = await citySearch.geocode(completion) {
                resolvedLat = coord.latitude
                resolvedLng = coord.longitude
            }
        }
    }
    
    // MARK: - Create
    
    func createClub(locationService: LocationService) async {
        guard canCreate, let genre = selectedGenre else { return }
        isLoading = true
        defer { isLoading = false }
        error = nil
        
        let lat = resolvedLat ?? locationService.roundedLatitude
        let lng = resolvedLng ?? locationService.roundedLongitude
        
        let timeString: String? = {
            guard recurringDay != nil else { return nil }
            let formatter = DateFormatter()
            formatter.dateFormat = "HH:mm:ss"
            return formatter.string(from: recurringTime)
        }()
        
        do {
            var club = try await SupabaseService.shared.createClub(
                name:          name.trimmingCharacters(in: .whitespaces),
                description:   description.trimmingCharacters(in: .whitespaces),
                genreTags:     [genre.rawValue],
                lat:           lat,
                lng:           lng,
                cityLabel:     cityLabel.trimmingCharacters(in: .whitespaces),
                isPublic:      isPublic,
                memberCap:     memberCap,
                coverImageURL: nil,
                recurringDay:  recurringDay,
                recurringTime: timeString
            )
            
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
    
    // MARK: - Update (edit mode)
    
    func updateClub(locationService: LocationService) async {
        guard canCreate, let genre = selectedGenre,
              let existing = mode.existingClub else { return }
        isLoading = true
        defer { isLoading = false }
        error = nil
        
        let lat = resolvedLat ?? locationService.roundedLatitude
        let lng = resolvedLng ?? locationService.roundedLongitude
        
        let timeString: String? = {
            guard recurringDay != nil else { return nil }
            let formatter = DateFormatter()
            formatter.dateFormat = "HH:mm:ss"
            return formatter.string(from: recurringTime)
        }()
        
        do {
            // Upload new cover if the user picked one
            var newCoverURL = existingCoverURL
            if let image = coverImage {
                newCoverURL = try await ImageUploadService.shared.uploadClubCover(image, clubId: existing.id)
            }
            
            let updated = try await SupabaseService.shared.updateClub(
                clubId:        existing.id,
                name:          name.trimmingCharacters(in: .whitespaces),
                description:   description.trimmingCharacters(in: .whitespaces),
                genreTags:     [genre.rawValue],
                lat:           lat,
                lng:           lng,
                cityLabel:     cityLabel.trimmingCharacters(in: .whitespaces),
                isPublic:      isPublic,
                memberCap:     memberCap,
                coverImageURL: newCoverURL,
                recurringDay:  recurringDay,
                recurringTime: timeString
            )
            
            createdClub = updated
            
        } catch {
            self.error = AppError(underlying: error)
        }
    }
    
    // MARK: - Delete (edit mode only)
    
    func deleteClub() async {
        guard let existing = mode.existingClub else { return }
        isDeleting = true
        defer { isDeleting = false }
        error = nil
        do {
            try await SupabaseService.shared.deleteClub(clubId: existing.id)
        } catch {
            self.error = AppError(underlying: error)
        }
    }
}
