//
//  DiscoverView.swift
//  MyBookClub
//
//  Created by Samara Lima da Silva on 09/03/2026.
//

import SwiftUI

struct DiscoverView: View {
    @State private var vm = DiscoverViewModel()
    @State private var selectedClub: Club?
    
    var body: some View {
        VStack(spacing: 0) {
            Text("Discover")
                .font(.appTitle)
                .foregroundStyle(.inkPrimary)
                .frame(maxWidth: .infinity, alignment: .leading)
                .padding(.horizontal, Spacing.lg)
                .padding(.vertical, Spacing.md)
            
            DiscoverToolbar(vm: vm)
            
            Divider()
                .background(Color.border)
            
            Group {
                if vm.showMap {
                    DiscoverMap(clubs: vm.clubs) { club in
                        selectedClub = club
                    }
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
        .sheet(item: $selectedClub, content: ClubDetailView.init)
    }
    
    // MARK: - List
    
    @ViewBuilder
    private var discoverList: some View {
        if vm.isLoading {
            Spacer()
            ProgressView().tint(.accent)
            Spacer()
        } else if vm.clubs.isEmpty {
            DiscoverEmptyState()
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
            .scrollIndicators(.hidden)
        }
    }
}

#Preview {
    NavigationStack {
        DiscoverView()
    }
}
