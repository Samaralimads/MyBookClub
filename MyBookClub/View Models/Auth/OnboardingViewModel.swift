//
//  OnboardingViewModel.swift
//  MyBookClub
//
//  Created by Samara Lima da Silva on 09/03/2026.
//

import Foundation
import SwiftUI

@Observable
final class OnboardingViewModel {

    var displayName  = ""
    var selectedGenres: Set<String> = []
    var readingFreq: ReadingFrequency = .weekly
    var hasAcceptedPrivacyPolicy = false
    var currentStep: OnboardingStep = .privacyPolicy
    var isLoading = false
    var error: AppError?

    enum OnboardingStep: Int, CaseIterable {
        case privacyPolicy = 0
        case displayName   = 1
        case genres        = 2
        case readingFreq   = 3
    }

    var canAdvanceFromCurrentStep: Bool {
        switch currentStep {
        case .privacyPolicy: return hasAcceptedPrivacyPolicy
        case .displayName:   return displayName.trimmingCharacters(in: .whitespaces).count >= 2
        case .genres:        return !selectedGenres.isEmpty
        case .readingFreq:   return true
        }
    }

    var isLastStep: Bool { currentStep == .readingFreq }

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

    func completeOnboarding(authViewModel: AuthViewModel) async {
        isLoading = true
        defer { isLoading = false }
        error = nil

        guard let uid = SupabaseService.shared.currentUserID else {
            error = AppError("Not signed in")
            return
        }

        let user = AppUser(
            id: uid,
            displayName: displayName.trimmingCharacters(in: .whitespaces),
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
