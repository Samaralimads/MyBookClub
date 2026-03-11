//
//  ForgotPasswordView.swift
//  MyBookClub
//
//  Created by Samara Lima da Silva on 10/03/2026.
//

import SwiftUI

struct ForgotPasswordView: View {
    @Environment(AuthViewModel.self) private var authVM
    @Environment(\.dismiss) private var dismiss

    @State private var email = ""

    var body: some View {
        ZStack {
            Color.background.ignoresSafeArea()

            if authVM.resetPasswordSent {
                // Success state
                VStack(spacing: Spacing.xl) {
                    Spacer()

                    ZStack {
                        Circle()
                            .fill(Color.accentSubtle)
                            .frame(width: 90, height: 90)
                        Image(systemName: "envelope.badge.checkmark")
                            .font(.system(size: 38))
                            .foregroundColor(.accent)
                    }

                    VStack(spacing: Spacing.sm) {
                        Text("Check your inbox")
                            .font(.appTitle)
                            .foregroundColor(.inkPrimary)
                        Text("We've sent a password reset link to **\(email)**. Follow the link in the email to set a new password.")
                            .font(.appBody)
                            .foregroundColor(.inkSecondary)
                            .multilineTextAlignment(.center)
                    }
                    .padding(.horizontal, Spacing.xl)

                    Text("Didn't receive it? Check your spam folder, or tap below to try again.")
                        .font(.appCaption)
                        .foregroundColor(.inkTertiary)
                        .multilineTextAlignment(.center)
                        .padding(.horizontal, Spacing.xl)

                    Button("Try a different email") {
                        authVM.resetPasswordSent = false
                        email = ""
                    }
                    .font(.appCaption.weight(.semibold))
                    .foregroundColor(.accent)

                    Spacer()

                    Button {
                        dismiss()
                    } label: {
                        Text("Back to Sign In")
                    }
                    .buttonStyle(PrimaryButtonStyle())
                    .padding(.horizontal, Spacing.xl)
                    .padding(.bottom, Spacing.xxl)
                }
                .transition(.opacity.combined(with: .move(edge: .trailing)))

            } else {
                // Input state
                VStack(spacing: 0) {

                    // Back button
                    HStack {
                        Button {
                            dismiss()
                        } label: {
                            Image(systemName: "chevron.left")
                                .font(.system(size: 17, weight: .semibold))
                                .foregroundColor(.inkPrimary)
                        }
                        Spacer()
                    }
                    .padding(.horizontal, Spacing.xl)
                    .padding(.top, Spacing.xl)

                    // Logo
                    Image("logo")
                        .resizable()
                        .scaledToFit()
                        .frame(width: 100)
                        .padding(.top, Spacing.xl)
                        .padding(.bottom, Spacing.xxl)

                    // Heading
                    VStack(alignment: .leading, spacing: Spacing.xs) {
                        Text("Forgot password?")
                            .font(.appTitle)
                            .foregroundColor(.inkPrimary)
                        Text("Enter the email linked to your account and we'll send you a reset link.")
                            .font(.appBody)
                            .foregroundColor(.inkSecondary)
                    }
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .padding(.horizontal, Spacing.xl)
                    .padding(.bottom, Spacing.xl)

                    // Email field
                    AuthInputField(
                        label: "Email",
                        icon: "envelope",
                        placeholder: "your@email.com",
                        text: $email,
                        error: email.isEmpty ? nil : (authVM.isValidResetEmail(email) ? nil : "Enter a valid email address"),
                        keyboardType: .emailAddress
                    )
                    .padding(.horizontal, Spacing.xl)

                    if let error = authVM.error {
                        Text(error.message)
                            .font(.appCaption)
                            .foregroundColor(.red)
                            .frame(maxWidth: .infinity, alignment: .leading)
                            .padding(.horizontal, Spacing.xl)
                            .padding(.top, Spacing.sm)
                    }

                    Button {
                        Task { await authVM.sendPasswordReset(email: email) }
                    } label: {
                        Text("Send Reset Link")
                    }
                    .buttonStyle(PrimaryButtonStyle())
                    .padding(.horizontal, Spacing.xl)
                    .padding(.top, Spacing.xl)
                    .disabled(authVM.isLoading || !authVM.isValidResetEmail(email))

                    Spacer()
                }
            }

            if authVM.isLoading { LoadingOverlay() }
        }
        .navigationBarHidden(true)
        .animation(Animations.standard, value: authVM.resetPasswordSent)
        .onDisappear {
            // Clean up so state is fresh next time
            authVM.resetPasswordSent = false
            authVM.error = nil
        }
    }
}

#Preview {
    NavigationStack {
        ForgotPasswordView()
            .environment(AuthViewModel())
    }
}
