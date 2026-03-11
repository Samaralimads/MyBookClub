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
    @State private var showSignUp         = false
    @State private var showForgotPassword = false
    @State private var showPassword       = false

    var body: some View {
        @Bindable var vm = authVM

        ZStack {
            Color.background.ignoresSafeArea()

                ScrollView {
                    VStack(spacing: 0) {

                        // Logo
                        Image("Logo")
                            .resizable()
                            .scaledToFit()
                            .frame(width: 200)
                            .padding(.vertical, Spacing.md)
                        

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
                                showSecure: $showPassword
                            )

                            // Forgot password
                            HStack {
                                Spacer()
                                Button("Forgot password?") {
                                    showForgotPassword = true
                                }
                                .font(.appCaption.weight(.semibold))
                                .foregroundStyle(.accent)
                            }
                        }
                        .padding(.horizontal, Spacing.xl)
                        .padding(.bottom, Spacing.lg)

                        // Server error
                        if let error = authVM.error {
                            Text(error.message)
                                .font(.appCaption)
                                .foregroundStyle(.red)
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

                        // Divider
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
                        .clipShape(.rect(cornerRadius: CornerRadius.button))
                        .overlay(
                            RoundedRectangle(cornerRadius: CornerRadius.button)
                                .stroke(Color.border, lineWidth: 1)
                        )
                        .padding(.horizontal, Spacing.xl)
                        .padding(.bottom, Spacing.xl)
                    }
                }
                
            if authVM.isLoading {
                LoadingOverlay()
            }
        }
        .overlay(alignment: .bottom) {
            // Bottom sign up prompt
            
            HStack(spacing: 4) {
                Text("Don't have an account?")
                    .font(.appCaption)
                    .foregroundStyle(.inkSecondary)
                Button("Create one") {
                    showSignUp = true
                }
                .font(.appCaption.weight(.semibold))
                .foregroundStyle(.accent)
            }
            .padding(.bottom, Spacing.md)
        }
        .ignoresSafeArea(.keyboard, edges: .bottom)
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
