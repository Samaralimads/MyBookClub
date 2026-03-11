//
//  SignUpView.swift
//  MyBookClub
//
//  Created by Samara Lima da Silva on 10/03/2026.
//

import SwiftUI
import AuthenticationServices

struct SignUpView: View {
    @Environment(AuthViewModel.self) private var authVM
    @State private var showSignIn = false
    @State private var showPassword        = false
    @State private var showConfirmPassword = false
    
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
                                label: "Full Name",
                                icon: "person",
                                placeholder: "Jane Doe",
                                text: $vm.signUpName,
                                error: authVM.signUpNameError
                            )
                            
                            AuthInputField(
                                label: "Email",
                                icon: "envelope",
                                placeholder: "your@email.com",
                                text: $vm.signUpEmail,
                                error: authVM.signUpEmailError,
                                keyboardType: .emailAddress
                            )
                            
                            AuthInputField(
                                label: "Password",
                                icon: "lock",
                                placeholder: "••••••••",
                                text: $vm.signUpPassword,
                                error: authVM.signUpPasswordError,
                                isSecure: true,
                                showSecure: $showPassword
                            )
                            
                            // Password strength
                            if !authVM.signUpPassword.isEmpty {
                                PasswordStrengthView(
                                    strength: authVM.passwordStrength,
                                    label: authVM.passwordStrengthLabel
                                )
                            }
                        }
                        .padding(.horizontal, Spacing.xl)
                        
                        // Server error
                        if let error = authVM.error {
                            Text(error.message)
                                .font(.appCaption)
                                .foregroundStyle(.red)
                                .frame(maxWidth: .infinity, alignment: .leading)
                                .padding(.horizontal, Spacing.xl)
                                .padding(.top, Spacing.sm)
                        }
                        
                        // Create Account button
                        Button {
                            Task { await authVM.signUpWithEmail() }
                        } label: {
                            Text("Create Account")
                        }
                        .buttonStyle(PrimaryButtonStyle())
                        .padding(.horizontal, Spacing.xl)
                        .padding(.top, Spacing.xl)
                        .disabled(!authVM.canSignUp || authVM.isLoading)
                        
                        // or divider
                        AuthDivider()
                            .padding(.horizontal, Spacing.xl)
                            .padding(.vertical, Spacing.lg)
                        
                        // Sign up with Apple
                        SignInWithAppleButton(.signUp) { request in
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
                        .padding(.bottom, Spacing.xxl)

                        
                        // Already have account
                        HStack(spacing: 4) {
                            Text("Already have an account?")
                                .font(.appCaption)
                                .foregroundStyle(.inkSecondary)
                            Button("Sign in") { showSignIn = true }
                                .font(.appCaption.weight(.semibold))
                                .foregroundStyle(.accent)
                        }
                        .padding(.vertical, Spacing.xxl)
                        
                        // Terms
                        Text("By creating an account, you agree to our [Terms of Service](\(Config.termsURL)) and [Privacy Policy](\(Config.privacyPolicyURL)).")
                            .font(.footnote)                    .foregroundStyle(.inkTertiary)
                            .multilineTextAlignment(.center)
                            .padding(.horizontal, Spacing.xl)
                            .frame(maxWidth: .infinity)
                        
                        
                    }
                }

               
            
            if authVM.isLoading { LoadingOverlay() }
        }
        .navigationDestination(isPresented: $showSignIn) {
            SignInView()
        }
        .navigationBarHidden(true)
    }
}

#Preview {
    NavigationStack {
        SignUpView()
            .environment(AuthViewModel())
    }
}
