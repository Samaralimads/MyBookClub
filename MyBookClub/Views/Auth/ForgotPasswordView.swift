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
                            .foregroundStyle(.accent)
                    }

                    VStack(spacing: Spacing.sm) {
                        Text("Check your inbox")
                            .font(.appTitle)
                            .foregroundStyle(.inkPrimary)
                        Text("We've sent a password reset link to **\(email)**. Follow the link in the email to set a new password.")
                            .font(.appBody)
                            .foregroundStyle(.inkSecondary)
                            .multilineTextAlignment(.center)
                    }
                    .padding(.horizontal, Spacing.xl)

                    Text("Didn't receive it? Check your spam folder, or tap below to try again.")
                        .font(.appCaption)
                        .foregroundStyle(.inkTertiary)
                        .multilineTextAlignment(.center)
                        .padding(.horizontal, Spacing.xl)

                    Button("Try a different email") {
                        authVM.resetPasswordSent = false
                        email = ""
                    }
                    .font(.appCaption.weight(.semibold))
                    .foregroundStyle(.accent)

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

                    // Logo
                    Image("Logo")
                        .resizable()
                        .scaledToFit()
                        .frame(width: 200)
                        .padding(.bottom, Spacing.md)
                    

                    // Heading
                    VStack(alignment: .leading, spacing: Spacing.xs) {
                        Text("Forgot password?")
                            .font(.appHeadline)
                            .foregroundStyle(.inkPrimary)
                            .padding(.vertical, Spacing.sm)
                        Text("Enter the email linked to your account and we'll send you a reset link.")
                            .font(.appBody)
                            .foregroundStyle(.inkSecondary)
                        
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
                            .foregroundStyle(.red)
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
        .animation(Animations.standard, value: authVM.resetPasswordSent)
        .onDisappear {
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
