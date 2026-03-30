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
    var myClubIds: Set<UUID> = []
    var isLoading = false
    var error: AppError?

    // Filters
    var searchText = ""
    var selectedGenres: Set<String> = []
    var radiusKm: Double? = nil

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
            async let nearbyClubs = SupabaseService.shared.fetchNearbyClubs(
                lat: locationService.roundedLatitude,
                lng: locationService.roundedLongitude,
                radiusM: (radiusKm ?? 50.0) * 1000,
                genres: Array(selectedGenres),
                query: searchText.isEmpty ? nil : searchText
            )
            async let myClubs = SupabaseService.shared.fetchMyClubs()

            let (fetched, mine) = try await (nearbyClubs, myClubs)
            clubs = fetched
            myClubIds = Set(mine.map(\.id))
        } catch {
            self.error = AppError(underlying: error)
        }
    }

    // MARK: - Role helper

    func role(for club: Club) -> MemberRole? {
        guard myClubIds.contains(club.id) else { return nil }
        return club.organiserId == SupabaseService.shared.currentUserID ? .organiser : .member
    }

    // MARK: - Filters

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
