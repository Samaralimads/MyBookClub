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

    // MARK: - Auth State

    enum AuthState {
        case loading
        case unauthenticated
        case needsOnboarding
        case authenticated
    }

    var authState: AuthState = .loading
    var error: AppError?
    var isLoading = false

    // Captured during sign-up or Apple — passed to onboarding
    var pendingDisplayName = ""

    // Password reset
    var resetPasswordSent = false

    // MARK: - Sign In Fields + Validation

    var signInEmail    = ""
    var signInPassword = ""

    var signInEmailError: String? {
        guard !signInEmail.isEmpty else { return nil }
        return isValidEmail(signInEmail) ? nil : "Enter a valid email address"
    }
    var signInPasswordError: String? {
        guard !signInPassword.isEmpty else { return nil }
        return signInPassword.count >= 8 ? nil : "Password must be at least 8 characters"
    }
    var canSignIn: Bool {
        signInEmailError == nil && signInPasswordError == nil
            && !signInEmail.isEmpty && !signInPassword.isEmpty
    }

    // MARK: - Sign Up Fields + Validation

    var signUpName            = ""
    var signUpEmail           = ""
    var signUpPassword        = ""

    var signUpNameError: String? {
        guard !signUpName.isEmpty else { return nil }
        return signUpName.trimmingCharacters(in: .whitespaces).count >= 2
            ? nil : "Name must be at least 2 characters"
    }
    var signUpEmailError: String? {
        guard !signUpEmail.isEmpty else { return nil }
        return isValidEmail(signUpEmail) ? nil : "Enter a valid email address"
    }
    var signUpPasswordError: String? {
        guard !signUpPassword.isEmpty else { return nil }
        var issues: [String] = []
        if signUpPassword.count < 8 { issues.append("at least 8 characters") }
        if !signUpPassword.contains(where: { $0.isUppercase }) { issues.append("one uppercase letter") }
        if !signUpPassword.contains(where: { $0.isNumber })    { issues.append("one number") }
        return issues.isEmpty ? nil : "Password needs: \(issues.joined(separator: ", "))"
    }
    var passwordStrength: Int {
        var score = 0
        let p = signUpPassword
        if p.count >= 8  { score += 1 }
        if p.count >= 12 { score += 1 }
        if p.contains(where: { $0.isUppercase }) { score += 1 }
        if p.contains(where: { $0.isNumber })    { score += 1 }
        if p.contains(where: { "!@#$%^&*".contains($0) }) { score += 1 }
        return score
    }
    var passwordStrengthLabel: String {
        switch passwordStrength {
        case 0, 1: return "Weak"
        case 2, 3: return "Fair"
        case 4:    return "Strong"
        default:   return "Very strong"
        }
    }
    var canSignUp: Bool {
        signUpNameError == nil && signUpEmailError == nil
            && signUpPasswordError == nil
            && !signUpName.trimmingCharacters(in: .whitespaces).isEmpty
            && !signUpEmail.isEmpty && !signUpPassword.isEmpty 
    }

    // MARK: - Helpers

    private func isValidEmail(_ email: String) -> Bool {
        let pattern = #"^[A-Za-z0-9._%+\-]+@[A-Za-z0-9.\-]+\.[A-Za-z]{2,}$"#
        return email.range(of: pattern, options: .regularExpression) != nil
    }

    // MARK: - Supabase Auth Listener

    func startListening() async {
        if SupabaseService.shared.client.auth.currentSession != nil {
            await checkOnboardingStatus()
        } else {
            authState = .unauthenticated
        }

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
            if user.displayName.isEmpty || (user.genrePrefs ?? []).isEmpty {
                authState = .needsOnboarding
            } else {
                authState = .authenticated
            }
        } catch {
            authState = .needsOnboarding
        }
    }

    // MARK: - Sign In With Apple

    func handleAppleSignIn(result: Result<ASAuthorization, Error>) async {
        isLoading = true
        defer { isLoading = false }
        error = nil

        do {
            guard case .success(let auth) = result,
                  let credential = auth.credential as? ASAuthorizationAppleIDCredential,
                  let identityToken = credential.identityToken,
                  let tokenString = String(data: identityToken, encoding: .utf8)
            else {
                if case .failure(let err) = result {
                    let nsErr = err as NSError
                    if nsErr.code != ASAuthorizationError.canceled.rawValue {
                        self.error = AppError(underlying: err)
                    }
                }
                return
            }

            if let firstName = credential.fullName?.givenName {
                pendingDisplayName = firstName
            }

            try await SupabaseService.shared.client.auth.signInWithIdToken(
                credentials: .init(provider: .apple, idToken: tokenString)
            )
        } catch {
            self.error = AppError(underlying: error)
        }
    }

    // MARK: - Email Sign In

    func signInWithEmail() async {
        isLoading = true
        defer { isLoading = false }
        error = nil

        do {
            try await SupabaseService.shared.client.auth.signIn(
                email: signInEmail.lowercased().trimmingCharacters(in: .whitespaces),
                password: signInPassword
            )
        } catch {
            self.error = AppError(underlying: error)
        }
    }

    // MARK: - Email Sign Up

    func signUpWithEmail() async {
        isLoading = true
        defer { isLoading = false }
        error = nil

        pendingDisplayName = signUpName.trimmingCharacters(in: .whitespaces)

        do {
            try await SupabaseService.shared.client.auth.signUp(
                email: signUpEmail.lowercased().trimmingCharacters(in: .whitespaces),
                password: signUpPassword
            )
        } catch {
            self.error = AppError(underlying: error)
        }
    }

    // MARK: - Forgot Password

    func isValidResetEmail(_ email: String) -> Bool {
        isValidEmail(email)
    }

    func sendPasswordReset(email: String) async {
        isLoading = true
        defer { isLoading = false }
        error = nil
        do {
            try await SupabaseService.shared.client.auth.resetPasswordForEmail(email)
            resetPasswordSent = true
        } catch {
            self.error = AppError(underlying: error)
        }
    }

    // MARK: - Sign Out

    func signOut() async {
        isLoading = true
        defer { isLoading = false }
        do {
            try await SupabaseService.shared.client.auth.signOut()
        } catch {
            self.error = AppError(underlying: error)
        }
    }
}
