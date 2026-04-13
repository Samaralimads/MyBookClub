//
//  DiscoverToolbar.swift
//  MyBookClub
//
//  Created by Samara Lima da Silva on 11/03/2026.
//

import SwiftUI

// MARK: - Discover Toolbar

struct DiscoverToolbar: View {
    @Bindable var vm: DiscoverViewModel

    var body: some View {
        VStack(spacing: 0) {
            HStack(spacing: Spacing.sm) {
                SearchBar(text: $vm.searchText, onSubmit: vm.search, onClear: vm.clearSearch)

                ViewToggleButton(showMap: $vm.showMap)
            }
            .padding(.horizontal, Spacing.lg)
            .padding(.top, Spacing.sm)

            DiscoverFilterChips(vm: vm)
                .padding(.vertical, Spacing.md)
        }
    }
}

// MARK: - Search Bar

struct SearchBar: View {
    @Binding var text: String
    let onSubmit: () -> Void
    let onClear: () -> Void

    var body: some View {
        HStack(spacing: Spacing.sm) {
            Image(systemName: "magnifyingglass")
                .foregroundStyle(.inkTertiary)
                .font(.system(size: 16))

            TextField("Search clubs, books, genres...", text: $text)
                .font(.appBody)
                .foregroundStyle(.inkPrimary)
                .submitLabel(.search)
                .onSubmit(onSubmit)

            if !text.isEmpty {
                Button {
                    onClear()
                    UIApplication.shared.sendAction(
                        #selector(UIResponder.resignFirstResponder),
                        to: nil, from: nil, for: nil
                    )
                } label: {
                    Image(systemName: "xmark.circle.fill")
                        .foregroundStyle(.inkTertiary)
                }
            }
        }
        .padding(.horizontal, Spacing.md)
        .padding(.vertical, Spacing.md)
        .background(Color.cardBackground)
        .clipShape(.rect(cornerRadius: CornerRadius.button))
        .overlay {
            RoundedRectangle(cornerRadius: CornerRadius.button)
                .stroke(Color.border, lineWidth: 1)
        }
    }
}

// MARK: - View Toggle Button

struct ViewToggleButton: View {
    @Binding var showMap: Bool
 
    var body: some View {
        Button {
            showMap.toggle()
//            withAnimation(Animations.standard) { showMap.toggle() }
        } label: {
            Image(systemName: showMap ? "list.bullet" : "map")
                .font(.system(size: 18, weight: .medium))
                .foregroundStyle(.inkSecondary)
                .frame(width: 50, height: 50)
                .background(Color.cardBackground)
                .clipShape(.rect(cornerRadius: CornerRadius.card))
                .overlay {
                    RoundedRectangle(cornerRadius: CornerRadius.card)
                        .stroke(Color.border, lineWidth: 1)
                }
        }
    }
}

// MARK: - Discover Filter Chips

struct DiscoverFilterChips: View {
    @Bindable var vm: DiscoverViewModel

    var body: some View {
        HStack(spacing: Spacing.sm) {
            genreMenu
            distanceMenu
        }
        .padding(.horizontal, Spacing.lg)
    }

    // MARK: Genre

    private var genreMenu: some View {
        Menu {
            Button("Any Genre") {
                vm.selectedGenres.removeAll()
                Task { await vm.loadClubs() }
            }
            Divider()
            ForEach(Genre.allCases, id: \.rawValue) { genre in
                Button {
                    vm.toggleGenre(genre.rawValue)
                } label: {
                    if vm.selectedGenres.contains(genre.rawValue) {
                        Label(genre.label, systemImage: "checkmark")
                    } else {
                        Text(genre.label)
                    }
                }
            }
        } label: {
            FilterDropdownChip(
                label: "Genre",
                isActive: !vm.selectedGenres.isEmpty,
                badge: vm.selectedGenres.count > 1 ? vm.selectedGenres.count : nil
            )
            .frame(maxWidth: .infinity)
        }
    }

    // MARK: Distance

    private var distanceMenu: some View {
        Menu {
            Button("Any Distance") {
                vm.radiusKm = nil
                Task { await vm.loadClubs() }
            }
            Divider()
            ForEach([1.0, 2.0, 5.0, 10.0], id: \.self) { km in
                Button {
                    vm.radiusKm = km
                    Task { await vm.loadClubs() }
                } label: {
                    let label = DistanceFormatter.string(fromMeters: km * 1_000)
                    if vm.radiusKm == km {
                        Label(label, systemImage: "checkmark")
                    } else {
                        Text(label)
                    }
                }
            }
        } label: {
            FilterDropdownChip(
                label: vm.radiusKm.map { DistanceFormatter.string(fromMeters: $0 * 1_000) } ?? "Distance",
                isActive: vm.radiusKm != nil
            )
            .frame(maxWidth: .infinity)
        }
    }
}

// MARK: - Filter Dropdown Chip

struct FilterDropdownChip: View {
    let label: String
    let isActive: Bool
    var badge: Int? = nil

    var body: some View {
        HStack(spacing: 4) {
            Text(label)
                .font(.appBody.weight(isActive ? .semibold : .regular))
                .lineLimit(1)

            if let count = badge {
                Text("\(count)")
                    .font(.system(size: 11, weight: .bold))
                    .foregroundStyle(.accent)
                    .frame(width: 18, height: 18)
                    .background(.white)
                    .clipShape(.circle)
            }

            Image(systemName: "chevron.down")
                .font(.system(size: 11, weight: .medium))
        }
        .foregroundStyle(isActive ? .white : .accent)
        .padding(.horizontal, Spacing.md)
        .padding(.vertical, Spacing.sm)
        .frame(maxWidth: .infinity)
        .background(isActive ? Color.accent : Color.accentSubtle)
        .clipShape(.rect(cornerRadius: CornerRadius.button))
    }
}

#Preview {
    DiscoverToolbar(vm: DiscoverViewModel())
        .background(Color.background)
}
