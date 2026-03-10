//
//  OnboardingView.swift
//  MyBookClub
//
//  Created by Samara Lima da Silva on 09/03/2026.
//

import SwiftUI

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
                    case .privacyPolicy:  PrivacyPolicyStep(vm: vm)
                    case .displayName:    DisplayNameStep(vm: vm)
                    case .genres:         GenrePickerStep(vm: vm)
                    case .readingFreq:    ReadingFreqStep(vm: vm)
                    }
                }
                .transition(.asymmetric(
                    insertion: .move(edge: .trailing).combined(with: .opacity),
                    removal:   .move(edge: .leading).combined(with: .opacity)
                ))
                .animation(Animations.standard, value: vm.currentStep)

                Spacer()

                // Navigation
                VStack(spacing: Spacing.md) {
                    if vm.isLastStep {
                        Button {
                            Task { await vm.completeOnboarding(authViewModel: authVM) }
                        } label: {
                            Text("Find My Book Club")
                        }
                        .buttonStyle(PrimaryButtonStyle())
                        .disabled(!vm.canAdvanceFromCurrentStep || vm.isLoading)
                    } else {
                        Button {
                            vm.advance()
                        } label: {
                            Text("Continue")
                        }
                        .buttonStyle(PrimaryButtonStyle())
                        .disabled(!vm.canAdvanceFromCurrentStep)
                    }

                    if let error = vm.error {
                        Text(error.message)
                            .font(.appCaption)
                            .foregroundColor(.red)
                    }
                }
                .padding(.horizontal, Spacing.xl)
                .padding(.bottom, Spacing.xxl)
            }

            if vm.isLoading {
                LoadingOverlay()
            }
        }
    }
}

// MARK: - Step: Privacy Policy

private struct PrivacyPolicyStep: View {
    @Bindable var vm: OnboardingViewModel

    var body: some View {
        VStack(alignment: .leading, spacing: Spacing.xl) {
            VStack(alignment: .leading, spacing: Spacing.md) {
                Text("Before we begin")
                    .font(.appTitle)
                    .foregroundColor(.inkPrimary)

                Text("MyBookClub is built for European readers with your privacy in mind. Here's what we collect and why:")
                    .font(.appBody)
                    .foregroundColor(.inkSecondary)
            }

            VStack(alignment: .leading, spacing: Spacing.lg) {
                PrivacyRow(icon: "location.fill",
                           title: "Approximate location",
                           detail: "City-level only — to show clubs near you. Never exact GPS.")

                PrivacyRow(icon: "person.fill",
                           title: "Display name + email",
                           detail: "For your account. Apple Sign-In uses a privacy relay — we never see your real email unless you share it.")

                PrivacyRow(icon: "message.fill",
                           title: "Posts and votes",
                           detail: "Your discussion posts and book votes, visible to your clubs only.")

                PrivacyRow(icon: "trash.fill",
                           title: "Delete any time",
                           detail: "Settings → Delete Account removes all your data permanently within 30 seconds.")
            }

            Link("Read the full Privacy Policy →", destination: URL(string: Config.privacyPolicyURL)!)
                .font(.appCaption)
                .foregroundColor(.accent)

            Toggle(isOn: $vm.hasAcceptedPrivacyPolicy) {
                Text("I've read and accept the Privacy Policy")
                    .font(.appBody)
                    .foregroundColor(.inkPrimary)
            }
            .tint(.accent)
        }
        .padding(.horizontal, Spacing.xl)
        .padding(.top, Spacing.xl)
    }
}

private struct PrivacyRow: View {
    let icon: String
    let title: String
    let detail: String

    var body: some View {
        HStack(alignment: .top, spacing: Spacing.md) {
            Image(systemName: icon)
                .foregroundColor(.accent)
                .frame(width: 20)
            VStack(alignment: .leading, spacing: Spacing.xs) {
                Text(title).font(.appBody.weight(.semibold)).foregroundColor(.inkPrimary)
                Text(detail).font(.appCaption).foregroundColor(.inkSecondary)
            }
        }
    }
}

// MARK: - Step: Display Name

private struct DisplayNameStep: View {
    @Bindable var vm: OnboardingViewModel

    var body: some View {
        VStack(alignment: .leading, spacing: Spacing.xl) {
            VStack(alignment: .leading, spacing: Spacing.sm) {
                Text("What should we call you?")
                    .font(.appTitle)
                    .foregroundColor(.inkPrimary)
                Text("This is how other club members will see you.")
                    .font(.appBody)
                    .foregroundColor(.inkSecondary)
            }

            TextField("Your name", text: $vm.displayName)
                .textFieldStyle(AppTextFieldStyle())
                .textContentType(.name)
                .submitLabel(.done)

            Text("\(vm.displayName.count)/40")
                .font(.appCaption)
                .foregroundColor(.inkTertiary)
        }
        .padding(.horizontal, Spacing.xl)
        .padding(.top, Spacing.xl)
    }
}

// MARK: - Step: Genres

private struct GenrePickerStep: View {
    @Bindable var vm: OnboardingViewModel
    let columns = [GridItem(.adaptive(minimum: 140), spacing: Spacing.sm)]

    var body: some View {
        VStack(alignment: .leading, spacing: Spacing.xl) {
            VStack(alignment: .leading, spacing: Spacing.sm) {
                Text("What do you love to read?")
                    .font(.appTitle)
                    .foregroundColor(.inkPrimary)
                Text("Pick up to 5 genres. We'll show you matching clubs.")
                    .font(.appBody)
                    .foregroundColor(.inkSecondary)
            }
            .padding(.horizontal, Spacing.xl)

            ScrollView {
                LazyVGrid(columns: columns, spacing: Spacing.sm) {
                    ForEach(Genre.allCases, id: \.rawValue) { genre in
                        GenreChip(
                            genre: genre,
                            isSelected: vm.selectedGenres.contains(genre.rawValue)
                        ) {
                            vm.toggleGenre(genre.rawValue)
                        }
                    }
                }
                .padding(.horizontal, Spacing.xl)
            }
        }
        .padding(.top, Spacing.xl)
    }
}

private struct GenreChip: View {
    let genre: Genre
    let isSelected: Bool
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            HStack(spacing: Spacing.xs) {
                Text(genre.label)
                    .font(.appCaption.weight(.semibold))
                    .foregroundColor(isSelected ? .inkPrimary : .inkSecondary)
            }
            .padding(.vertical, Spacing.sm)
            .padding(.horizontal, Spacing.md)
            .frame(maxWidth: .infinity)
            .background(isSelected ? Color.accentSubtle : Color.cardBackground)
            .overlay(
                RoundedRectangle(cornerRadius: CornerRadius.button)
                    .stroke(isSelected ? Color.accentColor : Color.border, lineWidth: 1.5)
            )
            .clipShape(RoundedRectangle(cornerRadius: CornerRadius.button))
        }
        .animation(Animations.standard, value: isSelected)
    }
}

// MARK: - Step: Reading Frequency

private struct ReadingFreqStep: View {
    @Bindable var vm: OnboardingViewModel

    var body: some View {
        VStack(alignment: .leading, spacing: Spacing.xl) {
            VStack(alignment: .leading, spacing: Spacing.sm) {
                Text("How often do you read?")
                    .font(.appTitle)
                    .foregroundColor(.inkPrimary)
                Text("Helps us match you with clubs that suit your pace.")
                    .font(.appBody)
                    .foregroundColor(.inkSecondary)
            }

            VStack(spacing: Spacing.md) {
                ForEach(ReadingFrequency.allCases, id: \.rawValue) { freq in
                    Button {
                        vm.readingFreq = freq
                    } label: {
                        HStack {
                            Text(freq.label)
                                .font(.appBody)
                                .foregroundColor(.inkPrimary)
                            Spacer()
                            if vm.readingFreq == freq {
                                Image(systemName: "checkmark.circle.fill")
                                    .foregroundColor(.accent)
                            }
                        }
                        .padding(Spacing.lg)
                        .background(vm.readingFreq == freq ? Color.accentSubtle : Color.cardBackground)
                        .clipShape(RoundedRectangle(cornerRadius: CornerRadius.card))
                        .overlay(
                            RoundedRectangle(cornerRadius: CornerRadius.card)
                                .stroke(vm.readingFreq == freq ? Color.accentColor : Color.border, lineWidth: 1.5)
                        )
                    }
                    .animation(Animations.standard, value: vm.readingFreq)
                }
            }
        }
        .padding(.horizontal, Spacing.xl)
        .padding(.top, Spacing.xl)
    }
}


#Preview {
    OnboardingView()
}
