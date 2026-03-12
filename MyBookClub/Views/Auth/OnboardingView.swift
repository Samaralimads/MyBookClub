//
//  OnboardingView.swift
//  MyBookClub
//
//  Created by Samara Lima da Silva on 09/03/2026.
//

import SwiftUI
import CoreLocation

struct OnboardingView: View {
    @Environment(AuthViewModel.self) private var authVM
    @State private var vm = OnboardingViewModel()

    var body: some View {
        ZStack {
            Color.background.ignoresSafeArea()

            VStack(spacing: 0) {
                // Progress dots
                HStack(spacing: Spacing.sm) {
                    ForEach(OnboardingViewModel.OnboardingStep.allCases, id: \.rawValue) { step in
                        Circle()
                            .fill(step.rawValue <= vm.currentStep.rawValue ? Color.accentColor : Color.border)
                            .frame(width: 8, height: 8)
                            .animation(Animations.standard, value: vm.currentStep)
                    }
                }
                .padding(.top, Spacing.xxl)

                // Step content
                Group {
                    switch vm.currentStep {
                    case .genres:      GenrePickerStep(vm: vm)
                    case .readingFreq: ReadingFreqStep(vm: vm)
                    case .location:    LocationStep(vm: vm)
                    }
                }
                .transition(.asymmetric(
                    insertion: .move(edge: .trailing).combined(with: .opacity),
                    removal:   .move(edge: .leading).combined(with: .opacity)
                ))
                .animation(Animations.standard, value: vm.currentStep)

                Spacer()

                VStack(spacing: Spacing.md) {
                    if vm.isLastStep {
                        Button {
                            Task { await vm.completeOnboarding(authViewModel: authVM) }
                        } label: {
                            Text("Find My Book Club")
                        }
                        .buttonStyle(PrimaryButtonStyle())
                        .disabled(!vm.canAdvance || vm.isLoading)
                    } else {
                        Button { vm.advance() } label: {
                            Text("Continue")
                        }
                        .buttonStyle(PrimaryButtonStyle())
                        .disabled(!vm.canAdvance)
                    }

                    if let error = vm.error {
                        Text(error.message)
                            .font(.appCaption)
                            .foregroundStyle(.red)
                    }
                }
                .padding(.horizontal, Spacing.xl)
                .padding(.bottom, Spacing.xxl)
            }

            if vm.isLoading { LoadingOverlay() }
        }
        .onAppear {
            if !authVM.pendingDisplayName.isEmpty {
                vm.displayName = authVM.pendingDisplayName
            }
        }
    }
}

// MARK: - Genres

private struct GenrePickerStep: View {
    @Bindable var vm: OnboardingViewModel
    private let genres = [
        "Literary Fiction", "Mystery", "Romance", "Sci-Fi", "Fantasy",
        "Historical", "Non-Fiction", "Biography", "Thriller", "Self-Help",
        "Graphic Novel", "Poetry"
    ]
    var body: some View {
        VStack(alignment: .leading, spacing: Spacing.xl) {
            VStack(alignment: .leading, spacing: Spacing.sm) {
                Text("What do you love reading?")
                    .font(.appTitle).foregroundStyle(.inkPrimary)
                Text("Pick up to 5 genres to find clubs that match your taste.")
                    .font(.appBody).foregroundStyle(.inkSecondary)
            }
            FlowLayout(spacing: Spacing.sm) {
                ForEach(genres, id: \.self) { genre in
                    Button {
                        vm.toggleGenre(genre)
                    } label: {
                        Text(genre)
                            .font(.appCaption)
                            .foregroundStyle(vm.selectedGenres.contains(genre) ? .white : .inkPrimary)
                            .padding(.vertical, Spacing.sm)
                            .padding(.horizontal, Spacing.md)
                            .background(vm.selectedGenres.contains(genre) ? Color.accentColor : Color.cardBackground)
                            .overlay(RoundedRectangle(cornerRadius: CornerRadius.button)
                                .stroke(vm.selectedGenres.contains(genre) ? Color.accentColor : Color.border, lineWidth: 1.5))
                            .clipShape(RoundedRectangle(cornerRadius: CornerRadius.button))
                    }
                    .animation(Animations.standard, value: vm.selectedGenres.contains(genre))
                }
            }
        }
        .padding(.horizontal, Spacing.xl)
        .padding(.top, Spacing.xl)
    }
}

// MARK: - Reading Frequency

private struct ReadingFreqStep: View {
    @Bindable var vm: OnboardingViewModel
    var body: some View {
        VStack(alignment: .leading, spacing: Spacing.xl) {
            VStack(alignment: .leading, spacing: Spacing.sm) {
                Text("How often do you read?")
                    .font(.appTitle).foregroundStyle(.inkPrimary)
                Text("Helps us match you with clubs that suit your pace.")
                    .font(.appBody).foregroundStyle(.inkSecondary)
            }
            VStack(spacing: Spacing.md) {
                ForEach(ReadingFrequency.allCases, id: \.rawValue) { freq in
                    Button { vm.readingFreq = freq } label: {
                        HStack {
                            Text(freq.label).font(.appBody).foregroundStyle(.inkPrimary)
                            Spacer()
                            if vm.readingFreq == freq {
                                Image(systemName: "checkmark.circle.fill").foregroundStyle(.accent)
                            }
                        }
                        .padding(Spacing.lg)
                        .background(vm.readingFreq == freq ? Color.accentSubtle : Color.cardBackground)
                        .clipShape(RoundedRectangle(cornerRadius: CornerRadius.card))
                        .overlay(RoundedRectangle(cornerRadius: CornerRadius.card)
                            .stroke(vm.readingFreq == freq ? Color.accentColor : Color.border, lineWidth: 1.5))
                    }
                    .animation(Animations.standard, value: vm.readingFreq)
                }
            }
        }
        .padding(.horizontal, Spacing.xl)
        .padding(.top, Spacing.xl)
    }
}

// MARK: - Location

private struct LocationStep: View {
    @Bindable var vm: OnboardingViewModel
    private var granted: Bool {
        vm.locationService.authorizationStatus == .authorizedWhenInUse
            || vm.locationService.authorizationStatus == .authorizedAlways
    }
    var body: some View {
        VStack(spacing: Spacing.xl) {
            Spacer()
            ZStack {
                Circle().fill(Color.accentSubtle).frame(width: 100, height: 100)
                Image(systemName: granted ? "location.fill" : "location.circle")
                    .font(.system(size: 44)).foregroundStyle(.accent)
            }
            VStack(spacing: Spacing.sm) {
                Text("Find clubs near you")
                    .font(.appTitle).foregroundStyle(.inkPrimary).multilineTextAlignment(.center)
                Text("We use city-level location only to show you nearby clubs.")
                    .font(.appBody).foregroundStyle(.inkSecondary).multilineTextAlignment(.center)
            }
            if granted {
                HStack(spacing: Spacing.sm) {
                    Image(systemName: "checkmark.circle.fill").foregroundStyle(.green)
                    Text("Location enabled").font(.appBody).foregroundStyle(.inkPrimary)
                }
                .padding(Spacing.md)
                .background(Color.cardBackground)
                .clipShape(RoundedRectangle(cornerRadius: CornerRadius.card))
            } else {
                Button { vm.requestLocation() } label: {
                    Label("Enable Location", systemImage: "location.fill")
                }
                .buttonStyle(SecondaryButtonStyle())
            }
            Spacer()
        }
        .padding(.horizontal, Spacing.xl)
        .padding(.top, Spacing.xl)
    }
}


#Preview {
    OnboardingView().environment(AuthViewModel())
}
