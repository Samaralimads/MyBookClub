//
//  OnboardingViewModel.swift
//  MyBookClub
//
//  Created by Samara Lima da Silva on 09/03/2026.
//

import Foundation
import SwiftUI
import CoreLocation

@Observable
final class OnboardingViewModel {

    var displayName      = ""
    var selectedGenres: Set<String> = []
    var readingFreq: ReadingFrequency = .weekly
    var currentStep: OnboardingStep = .genres
    var isLoading = false
    var error: AppError?
    var locationService = LocationService()

    // Manual city selection
    var citySearch = CitySearchService()
    var resolvedCoordinate: CLLocationCoordinate2D?
    var resolvedCityLabel: String?

    enum OnboardingStep: Int, CaseIterable {
        case genres      = 0
        case readingFreq = 1
        case location    = 2
    }

    var locationGranted: Bool {
        locationService.authorizationStatus == .authorizedWhenInUse
            || locationService.authorizationStatus == .authorizedAlways
    }

    var canAdvance: Bool {
        switch currentStep {
        case .genres:      return !selectedGenres.isEmpty
        case .readingFreq: return true
        case .location:    return locationGranted || resolvedCoordinate != nil
        }
    }

    var isLastStep: Bool { currentStep == .location }

    func advance() {
        guard let next = OnboardingStep(rawValue: currentStep.rawValue + 1) else { return }
        withAnimation(Animations.standard) { currentStep = next }
    }

    func toggleGenre(_ genre: String) {
        if selectedGenres.contains(genre) {
            selectedGenres.remove(genre)
        } else if selectedGenres.count < 5 {
            selectedGenres.insert(genre)
        }
    }

    func requestLocation() {
        locationService.requestWhenInUse()
    }

    func selectCity(_ index: Int) async {
        guard index < citySearch.completionResults.count else { return }
        let result = citySearch.completionResults[index]
        let label = citySearch.suggestions[index]
        if let coord = await citySearch.geocode(result) {
            resolvedCoordinate = coord
            resolvedCityLabel = label
            citySearch.query = label
            citySearch.suggestions = []
        }
    }

    func completeOnboarding(authViewModel: AuthViewModel) async {
        isLoading = true
        defer { isLoading = false }
        error = nil

        do {
            let uid = try await SupabaseService.shared.currentUserID

            let name = displayName.trimmingCharacters(in: .whitespaces).isEmpty
                ? "Reader" : displayName.trimmingCharacters(in: .whitespaces)

            let user = AppUser(
                id: uid,
                displayName: name,
                bio: nil,
                avatarURL: nil,
                genrePrefs: Array(selectedGenres),
                currentlyReadingBookId: nil,
                city: resolvedCityLabel,
                readingFreq: readingFreq,
                apnsToken: nil,
                createdAt: .now
            )

            try await SupabaseService.shared.upsertUser(user)
            authViewModel.authState = .authenticated
        } catch {
            self.error = AppError(underlying: error)
        }
    }
}
