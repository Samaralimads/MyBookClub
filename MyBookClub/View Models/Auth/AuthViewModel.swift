//
//  AuthViewModel.swift
//  MyBookClub
//
//  Created by Samara Lima da Silva on 09/03/2026.
//

import Foundation
import SwiftUI
import AuthenticationServices
import Supabase

@Observable
final class AuthViewModel {

    // MARK: - State

    enum AuthState {
        case loading
        case unauthenticated
        case needsOnboarding   // signed in but profile incomplete
        case authenticated
    }

    var authState: AuthState = .loading
    var error: AppError?
    var isLoading = false

    // Email/password fields
    var email    = ""
    var password = ""
    var displayName = ""

    // MARK: - Supabase Auth Listener

    func startListening() async {
        // Check current session immediately on launch
        if SupabaseService.shared.client.auth.currentSession != nil {
            await checkOnboardingStatus()
        } else {
            authState = .unauthenticated
        }
        
        // Then listen for future changes
        for await (event, _) in SupabaseService.shared.client.auth.authStateChanges {
            switch event {
            case .signedIn:
                await checkOnboardingStatus()
            case .signedOut, .userDeleted:
                authState = .unauthenticated
            default:
                break
            }
        }
    }

    private func checkOnboardingStatus() async {
        do {
            let user = try await SupabaseService.shared.fetchCurrentUser()
            // Profile is complete if they have a display name and at least one genre
            if user.displayName.isEmpty || (user.genrePrefs ?? []).isEmpty {
                authState = .needsOnboarding
            } else {
                authState = .authenticated
            }
        } catch {
            // User row doesn't exist yet — needs onboarding
            authState = .needsOnboarding
        }
    }

    // MARK: - Sign In With Apple

    func handleAppleSignIn(result: Result<ASAuthorization, Error>) async {
        isLoading = true
        defer { isLoading = false }

        do {
            guard case .success(let auth) = result,
                  let credential = auth.credential as? ASAuthorizationAppleIDCredential,
                  let identityToken = credential.identityToken,
                  let tokenString = String(data: identityToken, encoding: .utf8)
            else {
                if case .failure(let err) = result {
                    // ASAuthorizationError.canceled is normal — don't surface it
                    let nsErr = err as NSError
                    if nsErr.code != ASAuthorizationError.canceled.rawValue {
                        self.error = AppError(underlying: err)
                    }
                }
                return
            }

            try await SupabaseService.shared.client.auth.signInWithIdToken(
                credentials: .init(
                    provider: .apple,
                    idToken: tokenString
                )
            )
            // authStateChanges listener will fire and update authState
        } catch {
            self.error = AppError(underlying: error)
        }
    }

    // MARK: - Email / Password

    func signInWithEmail() async {
        isLoading = true
        defer { isLoading = false }
        error = nil

        guard !email.isEmpty, !password.isEmpty else {
            error = AppError("Please enter your email and password.")
            return
        }

        do {
            try await SupabaseService.shared.client.auth.signIn(
                email: email.lowercased().trimmingCharacters(in: .whitespaces),
                password: password
            )
        } catch {
            self.error = AppError(underlying: error)
        }
    }

    func signUpWithEmail() async {
        isLoading = true
        defer { isLoading = false }
        error = nil

        guard !email.isEmpty, !password.isEmpty else {
            error = AppError("Please enter your email and password.")
            return
        }
        guard password.count >= 8 else {
            error = AppError("Password must be at least 8 characters.")
            return
        }

        do {
            try await SupabaseService.shared.client.auth.signUp(
                email: email.lowercased().trimmingCharacters(in: .whitespaces),
                password: password
            )
            // Supabase sends a confirmation email; session fires when confirmed
        } catch {
            self.error = AppError(underlying: error)
        }
    }

    func signOut() async {
        isLoading = true
        defer { isLoading = false }
        do {
            try await SupabaseService.shared.client.auth.signOut()
        } catch {
            self.error = AppError(underlying: error)
        }
    }

    func resetPassword(email: String) async {
        do {
            try await SupabaseService.shared.client.auth.resetPasswordForEmail(email)
        } catch {
            self.error = AppError(underlying: error)
        }
    }
}
