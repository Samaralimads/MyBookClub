//
//  RootView.swift
//  MyBookClub
//
//  Created by Samara Lima da Silva on 09/03/2026.
//

import SwiftUI

struct RootView: View {
    @Environment(AuthViewModel.self) private var authVM

    var body: some View {
        Group {
            switch authVM.authState {
            case .loading:
                SplashView()

            case .unauthenticated:
                AuthView()

            case .needsOnboarding:
                OnboardingView()

            case .authenticated:
                MainTabView()
            }
        }
        .animation(Animations.standard, value: authVM.authState)
    }
}
