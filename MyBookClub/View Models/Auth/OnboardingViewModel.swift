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

    enum OnboardingStep: Int, CaseIterable {
        case genres      = 0
        case readingFreq = 1
        case location    = 2
    }

    var canAdvance: Bool {
        switch currentStep {
        case .genres:      return !selectedGenres.isEmpty
        case .readingFreq: return true
        case .location:    return true
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

    func completeOnboarding(authViewModel: AuthViewModel) async {
        isLoading = true
        defer { isLoading = false }
        error = nil

        guard let uid = SupabaseService.shared.currentUserID else {
            error = AppError("Not signed in")
            return
        }

        let name = displayName.trimmingCharacters(in: .whitespaces).isEmpty
            ? "Reader" : displayName.trimmingCharacters(in: .whitespaces)

        let user = AppUser(
            id: uid,
            displayName: name,
            bio: nil,
            avatarURL: nil,
            genrePrefs: Array(selectedGenres),
            currentlyReadingBookId: nil,
            city: nil,
            readingFreq: readingFreq,
            apnsToken: nil,
            createdAt: Date()
        )

        do {
            try await SupabaseService.shared.upsertUser(user)
            authViewModel.authState = .authenticated
        } catch {
            self.error = AppError(underlying: error)
        }
    }
}
