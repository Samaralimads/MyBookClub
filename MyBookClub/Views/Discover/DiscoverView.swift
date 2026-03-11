//
//  DiscoverView.swift
//  MyBookClub
//
//  Created by Samara Lima da Silva on 09/03/2026.
//

import SwiftUI
import MapKit

struct DiscoverView: View {
    @State private var vm = DiscoverViewModel()
    @State private var selectedClub: Club?

    var body: some View {
        ZStack {
            Color.background.ignoresSafeArea()

            VStack {
                
                Text("Discover")
                    .font(.appTitle)
                    .foregroundColor(.inkPrimary)
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .padding(.horizontal, Spacing.lg)
                    .padding(.top, Spacing.md)
                
                searchRow
                    .padding(.horizontal, Spacing.lg)
                    .padding(.top, Spacing.sm)

                listMapToggle
                    .padding(.horizontal, Spacing.lg)
                    .padding(.top, Spacing.md)

                filterChips
                    .padding(.top, Spacing.md)

                Divider()
                    .background(Color.border)
                    .padding(.top, Spacing.sm)

                if vm.showMap {
                    DiscoverMapView(clubs: vm.clubs) { club in
                        selectedClub = club
                    }
                } else {
                    clubList
                }
            }
        }
        .task { await vm.loadClubs() }
        .sheet(item: $selectedClub) { club in
            ClubDetailView(club: club)
        }
    }

    // MARK: - Search Row

    private var searchRow: some View {
        HStack(spacing: Spacing.sm) {
            Image(systemName: "magnifyingglass")
                .foregroundColor(.inkTertiary)
                .font(.system(size: 16))

            TextField("Search clubs, books, genres...", text: $vm.searchText)
                .font(.appBody)
                .foregroundColor(.inkPrimary)
                .submitLabel(.search)
                .onSubmit { vm.search() }

            if !vm.searchText.isEmpty {
                Button(action: vm.clearSearch) {
                    Image(systemName: "xmark.circle.fill")
                        .foregroundColor(.inkTertiary)
                }
            }
        }
        .padding(.horizontal, Spacing.md)
        .padding(.vertical, Spacing.md)
        .background(Color.cardBackground)
        .clipShape(RoundedRectangle(cornerRadius: CornerRadius.button))
        .overlay(
            RoundedRectangle(cornerRadius: CornerRadius.button)
                .stroke(Color.border, lineWidth: 1)
        )
    }

    // MARK: - List / Map Toggle

    private var listMapToggle: some View {
        HStack(spacing: 0) {
            toggleSegment(title: "List", icon: "list.bullet", isSelected: !vm.showMap) {
                withAnimation(Animations.standard) { vm.showMap = false }
            }
            toggleSegment(title: "Map", icon: "mappin.and.ellipse", isSelected: vm.showMap) {
                withAnimation(Animations.standard) { vm.showMap = true }
            }
        }
        .background(Color.border.opacity(0.3))
        .clipShape(RoundedRectangle(cornerRadius: CornerRadius.button))
        .overlay(
            RoundedRectangle(cornerRadius: CornerRadius.button)
                .stroke(Color.border, lineWidth: 1)
        )
    }

    private func toggleSegment(
        title: String,
        icon: String,
        isSelected: Bool,
        action: @escaping () -> Void
    ) -> some View {
        Button(action: action) {
            HStack(spacing: 6) {
                Image(systemName: icon)
                    .font(.system(size: 14, weight: .medium))
                Text(title)
                    .font(.appBody.weight(.medium))
            }
            .foregroundColor(isSelected ? .inkPrimary : .inkTertiary)
            .frame(maxWidth: .infinity)
            .padding(.vertical, 12)
            .background(
                Group {
                    if isSelected {
                        Color.cardBackground
                            .clipShape(RoundedRectangle(cornerRadius: CornerRadius.button - 2))
                            .shadow(color: .black.opacity(0.1), radius: 4, x: 0, y: 2)
                    }
                }
            )
        }
        .padding(4)
    }

    // MARK: - Filter Chips: Genre ▾  Distance ▾  Frequency ▾

    private var filterChips: some View {
        HStack(spacing: Spacing.sm) {
            // Genre — shows count badge when multiple selected
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
                        HStack {
                            Text(genre.label)
                            if vm.selectedGenres.contains(genre.rawValue) {
                                Image(systemName: "checkmark")
                            }
                        }
                    }
                }
            } label: {
                FilterDropdownChip(
                    label: "Genre",
                    isActive: !vm.selectedGenres.isEmpty,
                    badge: vm.selectedGenres.isEmpty ? nil : vm.selectedGenres.count
                )
                .frame(maxWidth: .infinity)
            }
            .frame(maxWidth: .infinity)

            Menu {
                Button("Any Distance") {
                    vm.radiusKm = nil
                    Task { await vm.loadClubs() }
                }
                Divider()
                ForEach([1.0, 2.0, 5.0, 10.0, 25.0], id: \.self) { km in
                    Button {
                        vm.radiusKm = km
                        Task { await vm.loadClubs() }
                    } label: {
                        HStack {
                            Text(DistanceFormatter.menuLabel(forKm: km))
                            if vm.radiusKm == km { Image(systemName: "checkmark") }
                        }
                    }
                }
            } label: {
                FilterDropdownChip(
                    label: vm.radiusKm == nil ? "Distance" : DistanceFormatter.string(fromKm: vm.radiusKm!),
                    isActive: vm.radiusKm != nil
                )
                .frame(maxWidth: .infinity)
            }
            .frame(maxWidth: .infinity)

            Menu {
                Button("Any Frequency") {
                    vm.selectedFrequency = nil
                    Task { await vm.loadClubs() }
                }
                Divider()
                ForEach(MeetingFrequency.allCases, id: \.self) { freq in
                    Button {
                        vm.selectedFrequency = freq
                        Task { await vm.loadClubs() }
                    } label: {
                        HStack {
                            Text(freq.label)
                            if vm.selectedFrequency == freq { Image(systemName: "checkmark") }
                        }
                    }
                }
            } label: {
                FilterDropdownChip(
                    label: vm.selectedFrequency?.label ?? "Frequency",
                    isActive: vm.selectedFrequency != nil
                )
                .frame(maxWidth: .infinity)
            }
            .frame(maxWidth: .infinity)
        }
        .padding(.horizontal, Spacing.lg)
    }

    // MARK: - Club List

    private var clubList: some View {
        Group {
            if vm.isLoading {
                Spacer()
                ProgressView().tint(.accentColor)
                Spacer()
            } else if vm.clubs.isEmpty {
                emptyState
            } else {
                ScrollView {
                    LazyVStack(spacing: Spacing.md) {
                        ForEach(vm.clubs) { club in
                            DiscoverClubCard(club: club)
                                .onTapGesture { selectedClub = club }
                        }
                    }
                    .padding(.horizontal, Spacing.lg)
                    .padding(.top, Spacing.lg)
                    .padding(.bottom, Spacing.xxl)
                }
            }
        }
    }

    // MARK: - Empty State

    private var emptyState: some View {
        VStack(spacing: Spacing.lg) {
            Spacer()
            Image(systemName: "book.closed")
                .font(.system(size: 48))
                .foregroundColor(.inkTertiary)
            Text("No clubs found nearby")
                .font(.appHeadline)
                .foregroundColor(.inkPrimary)
            Text("Try expanding your search or changing your filters.")
                .font(.appBody)
                .foregroundColor(.inkSecondary)
                .multilineTextAlignment(.center)
                .padding(.horizontal, Spacing.xxl)
            Button("Create a Club") {}
                .buttonStyle(PrimaryButtonStyle(isFullWidth: false))
            Spacer()
        }
    }
}

// MARK: - Filter Dropdown Chip
// Active = filled purple, inactive = light purple. Cohesive CornerRadius.button.
// Optional badge shows selection count (used by Genre).

struct FilterDropdownChip: View {
    let label: String
    let isActive: Bool
    var badge: Int? = nil

    var body: some View {
        HStack(spacing: 4) {
            Text(label)
                .font(.appBody.weight(isActive ? .semibold : .regular))
                .lineLimit(1)

            // Count badge
            if let count = badge {
                Text("\(count)")
                    .font(.system(size: 11, weight: .bold))
                    .foregroundColor(.accentColor)
                    .frame(width: 18, height: 18)
                    .background(Color.white)
                    .clipShape(Circle())
            }

            Image(systemName: "chevron.down")
                .font(.system(size: 11, weight: .medium))
        }
        .foregroundColor(isActive ? .white : .accentColor)
        .padding(.horizontal, Spacing.md)
        .padding(.vertical, Spacing.sm)
        .frame(maxWidth: .infinity)
        .background(isActive ? Color.accentColor : Color.accentSubtle)
        .clipShape(RoundedRectangle(cornerRadius: CornerRadius.button))
    }
}

// MARK: - Meeting Frequency

enum MeetingFrequency: String, CaseIterable {
    case weekly     = "weekly"
    case biWeekly   = "bi-weekly"
    case monthly    = "monthly"

    var label: String {
        switch self {
        case .weekly:   return "Weekly"
        case .biWeekly: return "Bi-weekly"
        case .monthly:  return "Monthly"
        }
    }
}

// MARK: - Discover Club Card

struct DiscoverClubCard: View {
    let club: Club

    var body: some View {
        HStack(alignment: .top, spacing: Spacing.md) {
            AsyncImage(url: club.coverImageURL.flatMap { URL(string: $0) }) { image in
                image.resizable().scaledToFill()
            } placeholder: {
                Color.purpleTint
                    .overlay(
                        Image(systemName: "books.vertical.fill")
                            .foregroundColor(.accentColor)
                            .font(.system(size: 28))
                    )
            }
            .frame(width: 100, height: 100)
            .clipShape(RoundedRectangle(cornerRadius: CornerRadius.card))

            VStack(alignment: .leading, spacing: 4) {
                HStack(alignment: .top) {
                    Text(club.name)
                        .font(.appHeadline)
                        .foregroundColor(.inkPrimary)
                        .lineLimit(1)
                    Spacer(minLength: Spacing.sm)
                    Text(DistanceFormatter.string(fromMeters: club.distanceMeters ?? 800))
                        .font(.appCaption)
                        .foregroundColor(.inkSecondary)
                        .fixedSize()
                }

                if let firstGenre = club.genreTags.first,
                   let genre = Genre(rawValue: firstGenre) {
                    Text(genre.label)
                        .font(.appCaption.weight(.semibold))
                        .foregroundColor(.accentColor)
                }

                HStack(spacing: Spacing.md) {
                    HStack(spacing: 4) {
                        Image(systemName: "person.2")
                            .font(.system(size: 11))
                        Text("\(club.memberCount ?? 0)")
                            .font(.appCaption)
                    }
                    .foregroundColor(.inkSecondary)

                    HStack(spacing: 4) {
                        Image(systemName: "calendar")
                            .font(.system(size: 11))
                        Text("Oct 12")
                            .font(.appCaption)
                    }
                    .foregroundColor(.inkSecondary)
                }

                if let book = club.currentBook {
                    HStack(spacing: 4) {
                        Text("Reading:")
                            .font(.appCaption.weight(.semibold))
                            .foregroundColor(.inkPrimary)
                        Text(book.title)
                            .font(.appCaption)
                            .foregroundColor(.inkSecondary)
                            .lineLimit(1)
                    }
                }
            }
            .padding(.top, 2)
        }
        .padding(Spacing.md)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(Color.cardBackground)
        .clipShape(RoundedRectangle(cornerRadius: CornerRadius.card))
        .shadow(color: .black.opacity(0.06), radius: 8, x: 0, y: 2)
    }
}

// MARK: - Temporary test data for map

private let temporaryTestClubs: [Club] = [
    Club(id: UUID(), organiserId: nil, name: "Downtown Fiction Readers",
         description: "Literary fiction lovers", coverImageURL: nil,
         genreTags: ["literary-fiction"], cityLabel: "Paris Centre",
         isPublic: true, memberCap: 20, recurringDay: "Saturday",
         recurringTime: "14:00", currentBookId: nil, createdAt: Date(),
         memberCount: 14, distanceMeters: 1300),
    Club(id: UUID(), organiserId: nil, name: "Sci-Fi & Coffee",
         description: "Science fiction fans", coverImageURL: nil,
         genreTags: ["sci-fi"], cityLabel: "Marais, Paris",
         isPublic: true, memberCap: 15, recurringDay: "Sunday",
         recurringTime: "10:00", currentBookId: nil, createdAt: Date(),
         memberCount: 8, distanceMeters: 1900),
    Club(id: UUID(), organiserId: nil, name: "Nonfiction Navigators",
         description: "Real stories only", coverImageURL: nil,
         genreTags: ["non-fiction"], cityLabel: "Montmartre, Paris",
         isPublic: false, memberCap: 25, recurringDay: "Friday",
         recurringTime: "19:00", currentBookId: nil, createdAt: Date(),
         memberCount: 22, distanceMeters: 4000),
]

private let temporaryPinCoordinates: [(Double, Double)] = [
    (48.860, 2.347),
    (48.855, 2.362),
    (48.884, 2.340),
]

// MARK: - Discover Map View

struct DiscoverMapView: View {
    let clubs: [Club]
    let onSelectClub: (Club) -> Void

    @State private var position: MapCameraPosition = .region(
        MKCoordinateRegion(
            center: CLLocationCoordinate2D(latitude: 48.865, longitude: 2.350),
            span: MKCoordinateSpan(latitudeDelta: 0.08, longitudeDelta: 0.08)
        )
    )
    @State private var sheetClub: Club?

    private var displayClubs: [Club] {
        clubs.isEmpty ? temporaryTestClubs : clubs
    }

    private func coordinate(for index: Int) -> CLLocationCoordinate2D {
        guard index < temporaryPinCoordinates.count else {
            return CLLocationCoordinate2D(latitude: 48.865, longitude: 2.350)
        }
        let c = temporaryPinCoordinates[index]
        return CLLocationCoordinate2D(latitude: c.0, longitude: c.1)
    }

    var body: some View {
        Map(position: $position) {
            ForEach(Array(displayClubs.enumerated()), id: \.element.id) { index, club in
                Annotation("", coordinate: coordinate(for: index)) {
                    Image(systemName: "mappin.circle.fill")
                        .font(.system(size: 36))
                        .foregroundColor(.accentColor)
                        .shadow(color: .black.opacity(0.2), radius: 4)
                        .onTapGesture { sheetClub = club }
                }
            }
        }
        .ignoresSafeArea(edges: .bottom)
        .sheet(item: $sheetClub) { club in
            MapClubBottomSheet(club: club) {
                sheetClub = nil
                onSelectClub(club)
            }
            .presentationDetents([.height(260)])
            .presentationDragIndicator(.visible)
            .presentationCornerRadius(CornerRadius.sheet)
            .presentationBackgroundInteraction(.enabled)
        }
    }
}

// MARK: - Map Club Bottom Sheet

struct MapClubBottomSheet: View {
    let club: Club
    let onViewClub: () -> Void
    @Environment(\.dismiss) private var dismiss

    var body: some View {
        VStack(spacing: 0) {
            AsyncImage(url: club.coverImageURL.flatMap { URL(string: $0) }) { image in
                image.resizable().scaledToFill()
            } placeholder: {
                Color.purpleTint
                    .overlay(
                        Image(systemName: "books.vertical.fill")
                            .foregroundColor(.accentColor)
                            .font(.system(size: 32))
                    )
            }
            .frame(maxWidth: .infinity)
            .frame(height: 100)
            .clipped()
            .overlay(alignment: .topTrailing) {
                Button { dismiss() } label: {
                    Image(systemName: "xmark")
                        .font(.system(size: 11, weight: .bold))
                        .foregroundColor(.inkPrimary)
                        .frame(width: 26, height: 26)
                        .background(Color.cardBackground)
                        .clipShape(Circle())
                        .shadow(color: .black.opacity(0.1), radius: 2)
                }
                .padding(Spacing.sm)
            }

            VStack(alignment: .leading, spacing: Spacing.sm) {
                Text(club.name)
                    .font(.appHeadline)
                    .foregroundColor(.inkPrimary)

                HStack(spacing: 4) {
                    Image(systemName: "person.2")
                        .font(.system(size: 13))
                    Text("\(club.memberCount ?? 0) members")
                        .font(.appBody)
                }
                .foregroundColor(.inkSecondary)

                Button("View Club") { onViewClub() }
                    .buttonStyle(PrimaryButtonStyle())
            }
            .padding(Spacing.lg)
            .frame(maxWidth: .infinity, alignment: .leading)
        }
        .background(Color.cardBackground)
    }
}

#Preview {
    NavigationStack {
        DiscoverView()
    }
}
