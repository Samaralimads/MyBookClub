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

    var body: some View {
        VStack(alignment: .leading, spacing: Spacing.xl) {
            VStack(alignment: .leading, spacing: Spacing.sm) {
                Text("What do you love reading?")
                    .font(.appTitle).foregroundStyle(.inkPrimary)
                Text("Pick up to 5 genres to find clubs that match your taste.")
                    .font(.appBody).foregroundStyle(.inkSecondary)
            }
            FlowLayout(spacing: Spacing.sm) {
                ForEach(Genre.allCases, id: \.rawValue) { genre in
                    Button {
                        vm.toggleGenre(genre.rawValue)
                    } label: {
                        let selected = vm.selectedGenres.contains(genre.rawValue)
                        Text(genre.label)                       
                            .font(.appCaption)
                            .foregroundStyle(selected ? .white : .inkPrimary)
                            .padding(.vertical, Spacing.sm)
                            .padding(.horizontal, Spacing.md)
                            .background(selected ? Color.accentColor : Color.cardBackground)
                            .overlay(RoundedRectangle(cornerRadius: CornerRadius.button)
                                .stroke(selected ? Color.accentColor : Color.border, lineWidth: 1.5))
                            .clipShape(RoundedRectangle(cornerRadius: CornerRadius.button))
                    }
                    .animation(Animations.standard, value: vm.selectedGenres.contains(genre.rawValue))
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

    var body: some View {
        VStack(spacing: Spacing.xl) {
            Spacer()

            ZStack {
                Circle().fill(Color.accentSubtle).frame(width: 100, height: 100)
                Image(systemName: vm.locationGranted ? "location.fill" : "location.circle")
                    .font(.system(size: 44)).foregroundStyle(.accent)
            }

            VStack(spacing: Spacing.sm) {
                Text("Find clubs near you")
                    .font(.appTitle).foregroundStyle(.inkPrimary).multilineTextAlignment(.center)
                Text("Enable location or enter your city — we only use city-level precision.")
                    .font(.appBody).foregroundStyle(.inkSecondary).multilineTextAlignment(.center)
            }

            if vm.locationGranted {
                HStack(spacing: Spacing.sm) {
                    Image(systemName: "checkmark.circle.fill").foregroundStyle(.green)
                    Text("Location enabled").font(.appBody).foregroundStyle(.inkPrimary)
                }
                .padding(Spacing.md)
                .background(Color.cardBackground)
                .clipShape(RoundedRectangle(cornerRadius: CornerRadius.card))
            } else {
                VStack(spacing: Spacing.md) {
                    // Primary CTA — filled button
                    Button { vm.requestLocation() } label: {
                        Label("Enable location", systemImage: "location.fill")
                            .frame(maxWidth: .infinity)
                    }
                    .buttonStyle(PrimaryButtonStyle())

                    // Divider
                    HStack(spacing: Spacing.md) {
                        Rectangle().fill(Color.border).frame(height: 1)
                        Text("or").font(.appCaption).foregroundStyle(.inkTertiary)
                        Rectangle().fill(Color.border).frame(height: 1)
                    }

                    // City search
                    CitySearchField(vm: vm)
                }
            }

            Spacer()
        }
        .padding(.horizontal, Spacing.xl)
        .padding(.top, Spacing.xl)
    }
}

// MARK: - City Search Field

private struct CitySearchField: View {
    @Bindable var vm: OnboardingViewModel

    var body: some View {
        VStack(spacing: Spacing.sm) {
            HStack(spacing: Spacing.sm) {
                Image(systemName: "magnifyingglass")
                    .foregroundStyle(.inkTertiary)
                    .font(.system(size: 16))

                TextField("City — Paris, London, New York…", text: $vm.citySearch.query)
                    .font(.appBody)
                    .foregroundStyle(.inkPrimary)
                    .autocorrectionDisabled()
                    .onChange(of: vm.citySearch.query) { _, newValue in
                        // Clear resolved coordinate if user edits the field manually
                        if newValue != vm.resolvedCityLabel {
                            vm.resolvedCoordinate = nil
                            vm.resolvedCityLabel = nil
                        }
                    }

                if !vm.citySearch.query.isEmpty {
                    Button {
                        vm.citySearch.query = ""
                        vm.resolvedCoordinate = nil
                        vm.resolvedCityLabel = nil
                    } label: {
                        Image(systemName: "xmark.circle.fill")
                            .foregroundStyle(.inkTertiary)
                    }
                }
            }
            .padding(.horizontal, Spacing.md)
            .padding(.vertical, Spacing.md)
            .background(Color.cardBackground)
            .clipShape(RoundedRectangle(cornerRadius: CornerRadius.button))
            .overlay {
                RoundedRectangle(cornerRadius: CornerRadius.button)
                    .stroke(
                        vm.resolvedCoordinate != nil ? Color.accentColor : Color.border,
                        lineWidth: vm.resolvedCoordinate != nil ? 1.5 : 1
                    )
            }

            if vm.resolvedCoordinate != nil {
                HStack(spacing: Spacing.sm) {
                    Image(systemName: "checkmark.circle.fill").foregroundStyle(.green)
                    Text("City set").font(.appCaption).foregroundStyle(.inkSecondary)
                    Spacer()
                }
                .padding(.horizontal, Spacing.sm)
            } else if !vm.citySearch.suggestions.isEmpty {
                VStack(spacing: 2) {
                    ForEach(Array(vm.citySearch.suggestions.enumerated()), id: \.offset) { idx, suggestion in
                        Button {
                            Task { await vm.selectCity(idx) }
                        } label: {
                            HStack(spacing: Spacing.md) {
                                Image(systemName: "mappin")
                                    .foregroundStyle(.inkTertiary)
                                    .font(.system(size: 14))
                                Text(suggestion)
                                    .font(.appCaption)
                                    .foregroundStyle(.inkPrimary)
                                    .multilineTextAlignment(.leading)
                                Spacer()
                            }
                            .padding(.horizontal, Spacing.md)
                            .padding(.vertical, Spacing.sm)
                        }
                        if idx < vm.citySearch.suggestions.count - 1 {
                            Divider().padding(.horizontal, Spacing.md)
                        }
                    }
                }
                .background(Color.cardBackground)
                .clipShape(RoundedRectangle(cornerRadius: CornerRadius.card))
                .overlay {
                    RoundedRectangle(cornerRadius: CornerRadius.card)
                        .stroke(Color.border, lineWidth: 1)
                }
            }
        }
    }
}

#Preview {
    OnboardingView().environment(AuthViewModel())
}
