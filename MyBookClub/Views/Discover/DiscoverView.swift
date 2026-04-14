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
                    DiscoverMap(clubs: vm.clubs, userRole: vm.role(for:))
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
        .task { await vm.loadClubs() }
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
    }
    
    // MARK: - List
    
    @ViewBuilder
    private var discoverList: some View {
        if vm.isLoading {
            Spacer()
            ProgressView().tint(.accent)
            Spacer()
        } else if vm.clubs.isEmpty {
            DiscoverEmptyState(onCreateClub: { showCreate = true })
        } else {
            ScrollView {
                LazyVStack(spacing: Spacing.md) {
                    ForEach(vm.clubs) { club in
                        NavigationLink(value: club) {
                            ClubCard(club: club, userRole: vm.role(for: club))
                        }
                        .buttonStyle(.plain)
                    }
                }
                .padding(.horizontal, Spacing.lg)
                .padding(.top, Spacing.lg)
                .padding(.bottom, Spacing.xxl)
            }
        }
    }
}

#Preview {
    DiscoverView()
}
