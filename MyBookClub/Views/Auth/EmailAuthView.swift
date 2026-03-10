//
//  EmailAuthView.swift
//  MyBookClub
//
//  Created by Samara Lima da Silva on 09/03/2026.
//

import SwiftUI

struct EmailAuthView: View {
    @Environment(AuthViewModel.self) private var authVM
    @Environment(\.dismiss) private var dismiss
    var isSignUp: Bool

    @State private var localEmail    = ""
    @State private var localPassword = ""

    var body: some View {
        NavigationStack {
            ZStack {
                Color.background.ignoresSafeArea()

                VStack(spacing: Spacing.xl) {
                    VStack(spacing: Spacing.md) {
                        TextField("Email", text: $localEmail)
                            .textFieldStyle(AppTextFieldStyle())
                            .keyboardType(.emailAddress)
                            .textContentType(.emailAddress)
                            .autocorrectionDisabled()

                        SecureField("Password", text: $localPassword)
                            .textFieldStyle(AppTextFieldStyle())
                            .textContentType(isSignUp ? .newPassword : .password)
                    }
                    .padding(.horizontal, Spacing.xl)

                    Button {
                        authVM.email    = localEmail
                        authVM.password = localPassword
                        Task {
                            if isSignUp {
                                await authVM.signUpWithEmail()
                            } else {
                                await authVM.signInWithEmail()
                            }
                        }
                    } label: {
                        Text(isSignUp ? "Create Account" : "Sign In")
                    }
                    .buttonStyle(PrimaryButtonStyle())
                    .padding(.horizontal, Spacing.xl)
                    .disabled(authVM.isLoading)

                    if !isSignUp {
                        Button("Forgot password?") {
                            Task { await authVM.resetPassword(email: localEmail) }
                        }
                        .font(.appCaption)
                        .foregroundColor(.accent)
                    }

                    if let error = authVM.error {
                        Text(error.message)
                            .font(.appCaption)
                            .foregroundColor(.red)
                            .padding(.horizontal, Spacing.xl)
                    }

                    Spacer()
                }
                .padding(.top, Spacing.xxl)

                if authVM.isLoading {
                    LoadingOverlay()
                }
            }
            .navigationTitle(isSignUp ? "Create Account" : "Sign In")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarLeading) {
                    Button("Cancel") { dismiss() }
                        .foregroundColor(.accent)
                }
            }
        }
        .presentationBackground(Color.background)
        .onChange(of: authVM.authState) { _, newState in
            if newState != .unauthenticated {
                dismiss()
            }
        }
    }
}

