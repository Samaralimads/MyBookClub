//
//  SettingsView.swift
//  MyBookClub
//
//  Created by Samara Lima da Silva on 01/04/2026.
//

import SwiftUI

struct SettingsView: View {
    @Environment(AuthViewModel.self) private var authVM
    @State private var vm = SettingsViewModel()
    @State private var showExportSheet = false

    var body: some View {
        ZStack {
            Color.background.ignoresSafeArea()

            ScrollView {
                VStack(spacing: Spacing.xl) {
                    preferencesSection
                    supportSection
                    gdprSection
                    signOutSection
                }
                .padding(.horizontal, Spacing.lg)
                .padding(.vertical, Spacing.lg)
            }
            .scrollIndicators(.hidden)

            if vm.isDeleting { LoadingOverlay() }
        }
        .navigationTitle("Settings")
        .navigationBarTitleDisplayMode(.inline)
        .alert("Something went wrong", isPresented: .constant(vm.error != nil)) {
            Button("OK") { vm.error = nil }
        } message: {
            Text(vm.error?.message ?? "")
        }
        .confirmationDialog(
            "Delete your account?",
            isPresented: $vm.showDeleteConfirm,
            titleVisibility: .visible
        ) {
            Button("Delete Account", role: .destructive) {
                Task { await vm.deleteAccount(authViewModel: authVM) }
            }
            Button("Cancel", role: .cancel) {}
        } message: {
            Text("This permanently deletes your profile, clubs you organise, and all your data. This cannot be undone.")
        }
        .sheet(isPresented: $showExportSheet) {
            if let url = vm.exportedURL {
                ShareSheet(url: url)
            }
        }
        .onChange(of: vm.exportedURL) { _, url in
            if url != nil { showExportSheet = true }
        }
    }

    // MARK: - Preferences

    private var preferencesSection: some View {
        SettingsGroup(header: "Preferences") {
            SettingsRow(
                icon: "bell.fill",
                iconBackground: Color.accent,
                title: "Notifications"
            ) {
                if let url = URL(string: UIApplication.openNotificationSettingsURLString) {
                    UIApplication.shared.open(url)
                }
            }

            SettingsDivider()

            SettingsRow(
                icon: "location.fill",
                iconBackground: Color(red: 0.2, green: 0.6, blue: 0.9),
                title: "Location Access"
            ) {
                if let url = URL(string: UIApplication.openSettingsURLString) {
                    UIApplication.shared.open(url)
                }
            }

            SettingsDivider()

            SettingsLinkRow(
                icon: "lock.fill",
                iconBackground: Color(red: 0.2, green: 0.6, blue: 0.4),
                title: "Privacy Policy",
                url: URL(string: Config.privacyPolicyURL)!
            )
        }
    }

    // MARK: - Support

    private var supportSection: some View {
        SettingsGroup(header: "Support") {
            SettingsRow(
                icon: "questionmark.circle.fill",
                iconBackground: Color(red: 0.3, green: 0.5, blue: 0.9),
                title: "Help Centre"
            ) {
                if let url = URL(string: "mailto:\(Config.supportEmail)") {
                    UIApplication.shared.open(url)
                }
            }

            SettingsDivider()

            SettingsLinkRow(
                icon: "doc.text.fill",
                iconBackground: Color(red: 0.5, green: 0.5, blue: 0.55),
                title: "Terms & Privacy",
                url: URL(string: Config.privacyPolicyURL)!
            )
        }
    }

    // MARK: - GDPR

    private var gdprSection: some View {
        SettingsGroup(header: "Your Data") {
            Button {
                Task { await vm.exportData() }
            } label: {
                SettingsRowLabel(
                    icon: "square.and.arrow.up.fill",
                    iconBackground: Color(red: 0.6, green: 0.4, blue: 0.8),
                    title: "Export My Data",
                    showChevron: false
                ) {
                    if vm.isExporting {
                        ProgressView().tint(.accent)
                    }
                }
            }
            .disabled(vm.isExporting)

            SettingsDivider()

            Button {
                vm.showDeleteConfirm = true
            } label: {
                SettingsRowLabel(
                    icon: "trash.fill",
                    iconBackground: Color.red.opacity(0.85),
                    title: "Delete Account",
                    titleColor: .red,
                    showChevron: false
                )
            }
        }
    }

    // MARK: - Sign Out

    private var signOutSection: some View {
        Button {
            Task { await authVM.signOut() }
        } label: {
            Text("Sign Out")
                .font(.appBody.weight(.semibold))
                .foregroundStyle(.red)
                .frame(maxWidth: .infinity)
                .frame(height: 50)
                .background(Color.cardBackground)
                .clipShape(.rect(cornerRadius: CornerRadius.card))
                .overlay {
                    RoundedRectangle(cornerRadius: CornerRadius.card)
                        .stroke(Color.border, lineWidth: 1)
                }
        }
    }
}

// MARK: - Settings Group

private struct SettingsGroup<Content: View>: View {
    let header: String
    @ViewBuilder let content: Content

    var body: some View {
        VStack(alignment: .leading, spacing: Spacing.sm) {
            Text(header.uppercased())
                .font(.system(size: 12, weight: .semibold))
                .foregroundStyle(.inkTertiary)
                .kerning(0.6)
                .padding(.leading, Spacing.xs)

            VStack(spacing: 0) {
                content
            }
            .background(Color.cardBackground)
            .clipShape(.rect(cornerRadius: CornerRadius.card))
            .overlay {
                RoundedRectangle(cornerRadius: CornerRadius.card)
                    .stroke(Color.border, lineWidth: 1)
            }
        }
    }
}

// MARK: - Settings Row (button action)

private struct SettingsRow: View {
    let icon: String
    let iconBackground: Color
    let title: String
    var titleColor: Color = .inkPrimary
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            SettingsRowLabel(
                icon: icon,
                iconBackground: iconBackground,
                title: title,
                titleColor: titleColor
            )
        }
    }
}

// MARK: - Settings Link Row (opens URL)

private struct SettingsLinkRow: View {
    let icon: String
    let iconBackground: Color
    let title: String
    let url: URL

    var body: some View {
        Link(destination: url) {
            SettingsRowLabel(
                icon: icon,
                iconBackground: iconBackground,
                title: title
            )
        }
    }
}

// MARK: - Settings Row Label (shared layout)

private struct SettingsRowLabel<Trailing: View>: View {
    let icon: String
    let iconBackground: Color
    let title: String
    var titleColor: Color = .inkPrimary
    var showChevron: Bool = true
    @ViewBuilder var trailing: Trailing

    var body: some View {
        HStack(spacing: Spacing.md) {
            ZStack {
                RoundedRectangle(cornerRadius: 7)
                    .fill(iconBackground)
                    .frame(width: 32, height: 32)
                Image(systemName: icon)
                    .font(.system(size: 14, weight: .medium))
                    .foregroundStyle(.white)
            }

            Text(title)
                .font(.appBody)
                .foregroundStyle(titleColor)

            Spacer()

            trailing

            if showChevron {
                Image(systemName: "chevron.right")
                    .font(.system(size: 13, weight: .semibold))
                    .foregroundStyle(.inkTertiary)
            }
        }
        .padding(.horizontal, Spacing.md)
        .padding(.vertical, Spacing.md)
        .contentShape(.rect)
    }
}

private extension SettingsRowLabel where Trailing == EmptyView {
    init(
        icon: String,
        iconBackground: Color,
        title: String,
        titleColor: Color = .inkPrimary,
        showChevron: Bool = true
    ) {
        self.icon = icon
        self.iconBackground = iconBackground
        self.title = title
        self.titleColor = titleColor
        self.showChevron = showChevron
        self.trailing = EmptyView()
    }
}

// MARK: - Divider

private struct SettingsDivider: View {
    var body: some View {
        Divider()
            .padding(.leading, Spacing.md + 32 + Spacing.md)
    }
}

// MARK: - Share Sheet (for export)

private struct ShareSheet: UIViewControllerRepresentable {
    let url: URL

    func makeUIViewController(context: Context) -> UIActivityViewController {
        UIActivityViewController(activityItems: [url], applicationActivities: nil)
    }

    func updateUIViewController(_ uiViewController: UIActivityViewController, context: Context) {}
}

#Preview {
    NavigationStack {
        SettingsView()
            .environment(AuthViewModel())
    }
}
