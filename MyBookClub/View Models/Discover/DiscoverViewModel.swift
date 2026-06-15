//
//  DiscoverViewModel.swift
//  MyBookClub
//
//  Created by Samara Lima da Silva on 10/03/2026.
//

import Foundation
import CoreLocation
import Supabase

@Observable
final class DiscoverViewModel {

    // MARK: - State
    var clubs: [Club] = []
    var allClubs: [Club] = []
    var myClubIds: Set<UUID> = []
    var currentUser: AppUser?
    var isLoading = false
    var error: AppError?

    // Filters (list only)
    var searchText = ""
    var selectedGenres: Set<String> = []
    var radiusKm: Double? = nil

    // View mode
    var showMap = false

    // Location
    var locationService = LocationService()
    private var hasReloadedWithRealLocation = false

    // Location setup sheet
    var showLocationSheet = false
    var citySearch = CitySearchService()
    var resolvedCoordinate: CLLocationCoordinate2D?
    var resolvedCityLabel: String?

    // MARK: - Computed

    var locationGranted: Bool {
        locationService.authorizationStatus == .authorizedWhenInUse
            || locationService.authorizationStatus == .authorizedAlways
    }

    /// Banner is shown when user has no GPS and no saved city
    var showLocationBanner: Bool {
        !locationGranted && currentUser?.city == nil
    }

    // MARK: - Load

    func initialLoad() async {
        if locationGranted {
            locationService.startUpdating()
        }
        await loadClubs()
    }

    func loadClubs() async {
        isLoading = true
        defer { isLoading = false }
        error = nil

        do {
            // Use 50km radius if GPS is granted or a manual city coordinate is set.
            // Fall back to world-scale only if we have no location at all (banner scenario).
            let hasLocation = locationGranted || locationService.coordinate != nil
            let listRadiusM = hasLocation ? (radiusKm ?? 50.0) * 1_000 : 20_000_000.0
            let mapRadiusM  = 20_000_000.0

            // Use stored coordinate if available; fall back to 0,0 only when world-scale is active anyway
            let lat = locationService.roundedLatitude ?? 0.0
            let lng = locationService.roundedLongitude ?? 0.0

            async let listFetch = SupabaseService.shared.fetchNearbyClubs(
                lat: lat,
                lng: lng,
                radiusM: listRadiusM,
                genres: Array(selectedGenres),
                query: searchText.isEmpty ? nil : searchText
            )
            async let mapFetch = SupabaseService.shared.fetchNearbyClubs(
                lat: lat,
                lng: lng,
                radiusM: mapRadiusM,
                genres: [],
                query: nil
            )
            async let myClubs  = SupabaseService.shared.fetchMyClubs()
            async let user     = SupabaseService.shared.fetchCurrentUser()

            let (fetched, allFetched, mine, fetchedUser) = try await (listFetch, mapFetch, myClubs, user)
            clubs       = fetched
            allClubs    = allFetched
            myClubIds   = Set(mine.map(\.id))
            currentUser = fetchedUser
        } catch {
            self.error = AppError(underlying: error)
        }
    }

    func onLocationUpdated() async {
        guard !hasReloadedWithRealLocation,
              locationService.currentLocation != nil else { return }
        hasReloadedWithRealLocation = true
        locationService.stopUpdating()
        await loadClubs()
    }

    // MARK: - Location setup

    func requestLocation() {
        locationService.requestWhenInUse()
    }

    func selectCity(_ index: Int) async {
        guard index < citySearch.completionResults.count else { return }
        let result = citySearch.completionResults[index]
        let label  = citySearch.suggestions[index]
        if let coord = await citySearch.geocode(result) {
            resolvedCoordinate = coord
            resolvedCityLabel  = label
            citySearch.query   = label
            citySearch.suggestions = []
        }
    }

    /// Called when the user confirms their city in the location sheet.
    /// Saves city label to the user record and reloads with the new coordinate.
    func confirmCity() async {
        guard let label = resolvedCityLabel,
              let coord = resolvedCoordinate,
              var user = currentUser else { return }

        user.city = label
        try? await SupabaseService.shared.upsertUser(user)

        // Seed the location service with the chosen coordinate so the list reloads correctly
        locationService.setManualCoordinate(coord)
        currentUser = user
        showLocationSheet = false
        await loadClubs()
    }

    /// Called when GPS is granted via the sheet — reload so the banner disappears.
    func onLocationGrantedFromSheet() async {
        showLocationSheet = false
        locationService.startUpdating()
        await loadClubs()
    }

    // MARK: - Role helper

    func role(for club: Club) -> MemberRole? {
        guard myClubIds.contains(club.id) else { return nil }
        return club.organiserId == SupabaseService.shared.client.auth.currentUser?.id ? .organiser : .member
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
