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
    let userRole: (Club) -> MemberRole?

    @State private var position: MapCameraPosition = .region(
        MKCoordinateRegion(
            center: CLLocationCoordinate2D(latitude: 48.865, longitude: 2.350),
            span: MKCoordinateSpan(latitudeDelta: 0.08, longitudeDelta: 0.08)
        )
    )
    @State private var selectedClub: Club?

    var body: some View {
        if clubs.isEmpty {
            ContentUnavailableView(
                "No clubs nearby yet",
                systemImage: "book.closed",
                description: Text("Be the first to create one!")
            )
        } else {
            Map(position: $position, selection: $selectedClub) {
                UserAnnotation()
                ForEach(clubs) { club in
                    if let lat = club.lat, let lng = club.lng {
                        Annotation("", coordinate: CLLocationCoordinate2D(latitude: lat, longitude: lng), anchor: .bottom) {
                            Image(systemName: "mappin.circle.fill")
                                .font(.system(size: 36))
                                .foregroundStyle(.accent)
                                .shadow(color: .black.opacity(0.2), radius: 4)
                        }
                        .tag(club)
                    }
                }
            }
            .ignoresSafeArea(edges: .bottom)
            .safeAreaInset(edge: .bottom) {
                if let club = selectedClub {
                    NavigationLink(value: club) {
                        MapClubBottomCard(club: club, userRole: userRole(club))
                    }
                    .buttonStyle(.plain)
                    .padding(.horizontal, Spacing.lg)
                    .padding(.bottom, Spacing.lg)
                    .transition(.move(edge: .bottom).combined(with: .opacity))
                }
            }
            .animation(Animations.standard, value: selectedClub)
        }
    }
}

// MARK: - Map Club Bottom Card

struct MapClubBottomCard: View {
    let club: Club
    let userRole: MemberRole?

    var body: some View {
        ClubCard(club: club, userRole: userRole)
            .overlay(alignment: .bottomTrailing) {
                Image(systemName: "chevron.right")
                    .font(.system(size: 14, weight: .semibold))
                    .foregroundStyle(.inkSecondary)
                    .padding(Spacing.md)
            }
    }
}

#Preview {
    NavigationStack {
        DiscoverMap(clubs: [], userRole: { _ in nil })
    }
}
