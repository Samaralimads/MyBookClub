//
//  AuthView.swift
//  MyBookClub
//
//  Created by Samara Lima da Silva on 09/03/2026.
//

import SwiftUI
import AuthenticationServices

struct AuthView: View {
    @Environment(AuthViewModel.self) private var authVM
    @State private var showEmailAuth = false
    @State private var isSignUp = false

    var body: some View {
        ZStack {
            Color.background.ignoresSafeArea()

            VStack(spacing: 0) {
                Spacer()

                // Hero
                VStack(spacing: Spacing.lg) {
                    Image(systemName: "book.closed.fill")
                        .font(.system(size: 72))
                        .foregroundColor(.accent)

                    Text("MyBookClub")
                        .font(.appTitle)
                        .foregroundColor(.inkPrimary)

                    Text("Find your people.\nOne chapter at a time.")
                        .font(.appBody)
                        .foregroundColor(.inkSecondary)
                        .multilineTextAlignment(.center)
                }
                .padding(.bottom, Spacing.xxl)

                Spacer()

                // Auth buttons
                VStack(spacing: Spacing.md) {
                    // Sign in with Apple — primary CTA
                    SignInWithAppleButton(.signIn) { request in
                        request.requestedScopes = [.fullName, .email]
                    } onCompletion: { result in
                        Task { await authVM.handleAppleSignIn(result: result) }
                    }
                    .signInWithAppleButtonStyle(.white)
                    .frame(height: 50)
                    .cornerRadius(CornerRadius.button)

                    // Email fallback
                    Button {
                        showEmailAuth = true
                        isSignUp = false
                    } label: {
                        Text("Sign in with Email")
                    }
                    .buttonStyle(SecondaryButtonStyle())

                    Button {
                        showEmailAuth = true
                        isSignUp = true
                    } label: {
                        Text("Create account with Email")
                    }
                    .buttonStyle(SecondaryButtonStyle())
                }
                .padding(.horizontal, Spacing.xl)
                .padding(.bottom, Spacing.xxl)

                // Privacy note
                Text("By continuing, you agree to our [Terms](\(Config.termsURL)) and [Privacy Policy](\(Config.privacyPolicyURL)).")
                    .font(.appCaption)
                    .foregroundColor(.inkTertiary)
                    .multilineTextAlignment(.center)
                    .padding(.horizontal, Spacing.xl)
                    .padding(.bottom, Spacing.xxl)
            }

            // Error overlay
            if let error = authVM.error {
                VStack {
                    Spacer()
                    ErrorBanner(message: error.message) {
                        authVM.error = nil
                    }
                    .padding()
                }
            }

            if authVM.isLoading {
                LoadingOverlay()
            }
        }
        .sheet(isPresented: $showEmailAuth) {
            EmailAuthView(isSignUp: isSignUp)
        }
    }
}

#Preview {
    AuthView()
}
