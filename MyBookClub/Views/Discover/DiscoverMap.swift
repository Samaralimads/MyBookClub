//
//  DiscoverMap.swift
//  MyBookClub
//
//  Created by Samara Lima da Silva on 11/03/2026.
//

import SwiftUI
import MapKit

struct DiscoverMap: View {
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
        clubs.isEmpty ? Club.mockDiscover : clubs
    }

    private func coordinate(for index: Int) -> CLLocationCoordinate2D {
        let coords = Club.mockPinCoordinates
        guard index < coords.count else {
            return CLLocationCoordinate2D(latitude: 48.865, longitude: 2.350)
        }
        return CLLocationCoordinate2D(latitude: coords[index].0, longitude: coords[index].1)
    }

    var body: some View {
        Map(position: $position) {
            ForEach(displayClubs.enumerated(), id: \.element.id) { index, club in
                Annotation("", coordinate: coordinate(for: index)) {
                    Image(systemName: "mappin.circle.fill")
                        .font(.system(size: 36))
                        .foregroundStyle(.accent)
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
                    .overlay {
                        Image(systemName: "books.vertical.fill")
                            .foregroundStyle(.accent)
                            .font(.system(size: 32))
                    }
            }
            .frame(maxWidth: .infinity)
            .frame(height: 100)
            .clipped()
            .overlay(alignment: .topTrailing) {
                Button(action: dismiss.callAsFunction) {
                    Image(systemName: "xmark")
                        .font(.system(size: 11, weight: .bold))
                        .foregroundStyle(.inkPrimary)
                        .frame(width: 26, height: 26)
                        .background(Color.cardBackground)
                        .clipShape(.circle)
                        .shadow(color: .black.opacity(0.1), radius: 2)
                }
                .padding(Spacing.sm)
            }

            VStack(alignment: .leading, spacing: Spacing.sm) {
                Text(club.name)
                    .font(.appHeadline)
                    .foregroundStyle(.inkPrimary)

                Label(
                    "^[\(club.memberCount ?? 0) member](inflect: true)",
                    systemImage: "person.2"
                )
                .font(.appBody)
                .foregroundStyle(.inkSecondary)

                Button("View Club", action: onViewClub)
                    .buttonStyle(PrimaryButtonStyle())
            }
            .padding(Spacing.lg)
            .frame(maxWidth: .infinity, alignment: .leading)
        }
        .background(Color.cardBackground)
    }
}

#Preview {
    DiscoverMap(clubs: Club.mockDiscover) { _ in }
}
