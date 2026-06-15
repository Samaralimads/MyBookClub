//
//  LocationSetupSheet.swift
//  MyBookClub
//
//  Created by Samara Lima da Silva on 15/06/2026.
//

import SwiftUI

struct LocationSetupSheet: View {
    @Bindable var vm: DiscoverViewModel

    var body: some View {
        VStack(spacing: 0) {
            // Handle
            RoundedRectangle(cornerRadius: 2)
                .fill(Color.border)
                .frame(width: 36, height: 4)
                .padding(.top, Spacing.md)
                .padding(.bottom, Spacing.xl)

            VStack(spacing: Spacing.xl) {
                // Icon
                ZStack {
                    Circle().fill(Color.accentSubtle).frame(width: 80, height: 80)
                    Image(systemName: vm.locationGranted ? "location.fill" : "location.circle")
                        .font(.system(size: 36))
                        .foregroundStyle(.accent)
                }

                VStack(spacing: Spacing.sm) {
                    Text("Where are you based?")
                        .font(.appTitle)
                        .foregroundStyle(.inkPrimary)
                        .multilineTextAlignment(.center)
                    Text("Enable location or enter your city — we only use city-level precision.")
                        .font(.appBody)
                        .foregroundStyle(.inkSecondary)
                        .multilineTextAlignment(.center)
                }

                if vm.locationGranted {
                    HStack(spacing: Spacing.sm) {
                        Image(systemName: "checkmark.circle.fill").foregroundStyle(.green)
                        Text("Location enabled").font(.appBody).foregroundStyle(.inkPrimary)
                    }
                    .padding(Spacing.md)
                    .background(Color.cardBackground)
                    .clipShape(RoundedRectangle(cornerRadius: CornerRadius.card))

                    Button {
                        Task { await vm.onLocationGrantedFromSheet() }
                    } label: {
                        Text("Done")
                            .frame(maxWidth: .infinity)
                    }
                    .buttonStyle(PrimaryButtonStyle())
                } else {
                    VStack(spacing: Spacing.md) {
                        Button {
                            vm.requestLocation()
                        } label: {
                            Label("Enable location", systemImage: "location.fill")
                                .frame(maxWidth: .infinity)
                        }
                        .buttonStyle(PrimaryButtonStyle())

                        HStack(spacing: Spacing.md) {
                            Rectangle().fill(Color.border).frame(height: 1)
                            Text("or").font(.appCaption).foregroundStyle(.inkTertiary)
                            Rectangle().fill(Color.border).frame(height: 1)
                        }

                        LocationSheetCitySearch(vm: vm)

                        if vm.resolvedCoordinate != nil {
                            Button {
                                Task { await vm.confirmCity() }
                            } label: {
                                Text("Confirm city")
                                    .frame(maxWidth: .infinity)
                            }
                            .buttonStyle(PrimaryButtonStyle())
                        }
                    }
                }
            }
            .padding(.horizontal, Spacing.xl)

            Spacer()
        }
        .background(Color.background.ignoresSafeArea())
        // Re-check when authorization changes (user came back from Settings)
        .onChange(of: vm.locationGranted) { _, granted in
            if granted {
                Task { await vm.onLocationGrantedFromSheet() }
            }
        }
    }
}

// MARK: - City Search

private struct LocationSheetCitySearch: View {
    @Bindable var vm: DiscoverViewModel

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
