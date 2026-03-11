//
//  SignInView.swift
//  MyBookClub
//
//  Created by Samara Lima da Silva on 10/03/2026.
//

import SwiftUI
import AuthenticationServices

struct SignInView: View {
    @Environment(AuthViewModel.self) private var authVM
    @State private var showSignUp    = false
    @State private var showForgotPassword = false
    @State private var showPassword  = false

    var body: some View {
        @Bindable var vm = authVM

        ZStack {
            Color.background.ignoresSafeArea()

            ScrollView(showsIndicators: false) {

                VStack(spacing: 0) {

                    // Logo
                    Image("logo")
                        .resizable()
                        .scaledToFit()
                        .frame(width: 250)
                        .padding(.top, Spacing.sm)

                    
                    // Fields
                    VStack(spacing: Spacing.lg) {

                        AuthInputField(
                            label: "Email",
                            icon: "envelope",
                            placeholder: "your@email.com",
                            text: $vm.signInEmail,
                            error: authVM.signInEmailError,
                            keyboardType: .emailAddress
                        )

                        AuthInputField(
                            label: "Password",
                            icon: "lock",
                            placeholder: "••••••••",
                            text: $vm.signInPassword,
                            error: authVM.signInPasswordError,
                            isSecure: true,
                            showSecure: $showPassword,
                        )
                        // Forgot password
                        HStack {
                            Spacer()
                            Button("Forgot password?") {
                                showForgotPassword = true
                            }
                            .font(.appCaption.weight(.semibold))
                            .foregroundColor(.accent)
                        }
                    }
                    .padding(.horizontal, Spacing.xl)

                    // Server error
                    if let error = authVM.error {
                        Text(error.message)
                            .font(.appCaption)
                            .foregroundColor(.red)
                            .frame(maxWidth: .infinity, alignment: .leading)
                            .padding(.horizontal, Spacing.xl)
                            .padding(.top, Spacing.sm)
                    }

                    
                    // Sign In button
                    Button {
                        Task { await authVM.signInWithEmail() }
                    } label: {
                        Text("Sign In")
                    }
                    .buttonStyle(PrimaryButtonStyle())
                    .padding(.horizontal, Spacing.xl)
                    .padding(.top, Spacing.xl)
                    .disabled(!authVM.canSignIn || authVM.isLoading)

                    // or divider
                    AuthDivider()
                        .padding(.horizontal, Spacing.xl)
                        .padding(.vertical, Spacing.lg)

                    // Sign in with Apple
                    SignInWithAppleButton(.signIn) { request in
                        request.requestedScopes = [.fullName, .email]
                    } onCompletion: { result in
                        Task { await authVM.handleAppleSignIn(result: result) }
                    }
                    .signInWithAppleButtonStyle(.white)
                    .frame(height: 50)
                    .cornerRadius(CornerRadius.button)
                    .overlay(
                        RoundedRectangle(cornerRadius: CornerRadius.button)
                            .stroke(Color.border, lineWidth: 1)
                    )
                    .padding(.horizontal, Spacing.xl)

                    // No account yet
                    HStack(spacing: 4) {
                        Text("Don't have an account?")
                            .font(.appCaption)
                            .foregroundColor(.inkSecondary)
                        Button("Create one") { showSignUp = true }
                            .font(.appCaption.weight(.semibold))
                            .foregroundColor(.accent)
                    }
                    .padding(.top, Spacing.lg)

                    // Footer
                    Text("Sign in with your book club account")
                        .font(.appCaption)
                        .foregroundColor(.inkTertiary)
                        .padding(.top, Spacing.xxl)
                        .padding(.bottom, Spacing.xxl)
                }
            }

            if authVM.isLoading { LoadingOverlay() }
        }
        .navigationDestination(isPresented: $showSignUp) {
            SignUpView()
        }
        .navigationDestination(isPresented: $showForgotPassword) {
            ForgotPasswordView()
        }
        .navigationBarHidden(true)
    }
}

#Preview {
    NavigationStack {
        SignInView()
            .environment(AuthViewModel())
    }
}
