//
//  DiscoverView.swift
//  MyBookClub
//
//  Created by Samara Lima da Silva on 09/03/2026.
//

import SwiftUI

struct DiscoverView: View {
    @State private var vm = DiscoverViewModel()
    @State private var showCreate = false

    var body: some View {
        NavigationStack {
            VStack(spacing: 0) {
                Text("Discover")
                    .font(.appTitle)
                    .foregroundStyle(.inkPrimary)
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .padding(.horizontal, Spacing.lg)
                    .padding(.top, Spacing.md)
                    .padding(.bottom, Spacing.sm)
                    .background(Color.background)

                DiscoverToolbar(vm: vm)

                Divider()
                    .background(Color.border)

                Group {
                    if vm.showMap {
                        DiscoverMap(clubs: vm.allClubs, userRole: vm.role(for:))
                            .transition(.opacity)
                    } else {
                        discoverList
                            .transition(.opacity)
                    }
                }
                .frame(maxWidth: .infinity, maxHeight: .infinity)
            }
            .toolbar(.hidden, for: .navigationBar)
            .background(Color.background.ignoresSafeArea())
            .task { await vm.initialLoad() }
            .onChange(of: vm.locationService.currentLocation) { _, _ in
                Task { await vm.onLocationUpdated() }
            }
            .navigationDestination(for: Club.self) { club in
                ClubDetailView(club: club)
            }
            .sheet(isPresented: $showCreate) {
                NavigationStack {
                    CreateClubView { _ in
                        Task { await vm.loadClubs() }
                    }
                }
            }
            .sheet(isPresented: $vm.showLocationSheet) {
                LocationSetupSheet(vm: vm)
                    .presentationDetents([.medium, .large])
                    .presentationDragIndicator(.hidden)
            }
        }
    }

    // MARK: - List

    @ViewBuilder
    private var discoverList: some View {
        if vm.isLoading {
            Spacer()
            ProgressView().tint(.accent)
            Spacer()
        } else {
            VStack(spacing: 0) {
                // Banner lives outside ScrollView — no NavigationLink interference
                if vm.showLocationBanner {
                    LocationBannerView {
                        vm.showLocationSheet = true
                    }
                }

                ScrollView {
                    LazyVStack(spacing: Spacing.md) {
                        if vm.clubs.isEmpty && vm.currentUser != nil {
                            DiscoverEmptyState(onCreateClub: { showCreate = true })
                                .padding(.top, Spacing.xxl)
                        } else {
                            ForEach(vm.clubs) { club in
                                NavigationLink(value: club) {
                                    ClubCard(club: club, userRole: vm.role(for: club))
                                }
                                .buttonStyle(.plain)
                                .padding(.horizontal, Spacing.lg)
                            }
                        }
                    }
                    .padding(.top, Spacing.lg)
                    .padding(.bottom, Spacing.xxl)
                }
            }
        }
    }
}

#Preview {
    DiscoverView()
}
