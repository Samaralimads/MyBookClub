//
//  DiscoverViewModel.swift
//  MyBookClub
//
//  Created by Samara Lima da Silva on 10/03/2026.
//

import Foundation
import CoreLocation

@Observable
final class DiscoverViewModel {

    // MARK: - State
    var clubs: [Club] = []
    var isLoading = false
    var error: AppError?

    // Filters
    var searchText = ""
    var selectedGenres: Set<String> = []
    var radiusKm: Double? = nil  // nil = any distance
    var selectedFrequency: MeetingFrequency?

    // View mode
    var showMap = false

    // Location
    var locationService = LocationService()

    // MARK: - Load

    func loadClubs() async {
        isLoading = true
        defer { isLoading = false }
        error = nil

        if locationService.authorizationStatus == .notDetermined {
            locationService.requestWhenInUse()
        }

        do {
            clubs = try await SupabaseService.shared.fetchNearbyClubs(
                lat: locationService.roundedLatitude,
                lng: locationService.roundedLongitude,
                radiusM: (radiusKm ?? 50.0) * 1000, // nil = 50km wide net
                genres: Array(selectedGenres),
                query: searchText.isEmpty ? nil : searchText
            )
        } catch {
            self.error = AppError(underlying: error)
        }
    }

    func toggleGenre(_ genre: String) {
        if selectedGenres.contains(genre) {
            selectedGenres.remove(genre)
        } else {
            selectedGenres.insert(genre)
        }
        Task { await loadClubs() }
    }

    func search() {
        Task { await loadClubs() }
    }

    func clearSearch() {
        searchText = ""
        Task { await loadClubs() }
    }
}
