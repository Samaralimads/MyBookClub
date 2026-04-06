//
//  MyClubsView.swift
//  MyBookClub
//
//  Created by Samara Lima da Silva on 09/03/2026.
//

import SwiftUI
import Supabase

struct MyClubsView: View {
    @State private var clubs: [Club]        = []
    @State private var isLoading            = false
    @State private var error: AppError?
    @State private var showCreate           = false
    
    var body: some View {
        ZStack {
            Color.background.ignoresSafeArea()
            
            
            
            Group {
                if isLoading {
                    ProgressView().tint(.accent)
                } else if let error {
                    ContentUnavailableView(
                        "Couldn't load clubs",
                        systemImage: "wifi.slash",
                        description: Text(error.message)
                    )
                } else if clubs.isEmpty {
                    emptyState
                } else {
                    clubList
                }
            }
        }
        .navigationTitle("My Clubs")
        .navigationBarTitleDisplayMode(.automatic)
        .toolbar {
            ToolbarItem(placement: .topBarTrailing) {
                Button("", systemImage: "plus", action: { showCreate = true })
                    .tint(.accent)
            }
        }
        .sheet(isPresented: $showCreate) {
            NavigationStack {
                CreateClubView { newClub in
                    clubs.insert(newClub, at: 0)
                }
            }
        }
        .task { await loadMyClubs() }
        .refreshable { await loadMyClubs() }
    }
    
    // MARK: - Empty State
    
    private var emptyState: some View {
        EmptyStateView(
            icon: "books.vertical.fill",
            title: "No clubs yet",
            description: "Tap + to create your first club, or join one from Discover."
        )
    }
    
    // MARK: - Club List
    
    private var clubList: some View {
        ScrollView {
            LazyVStack(spacing: Spacing.md) {
                ForEach(clubs) { club in
                    let role: MemberRole? = club.organiserId == SupabaseService.shared.client.auth.currentUser?.id ? .organiser : .member
                    NavigationLink(value: club) {
                        ClubCard(club: club, userRole: role)
                    }
                    .buttonStyle(.plain)
                }
            }
            .padding(.horizontal, Spacing.lg)
            .padding(.top, Spacing.lg)
            .padding(.bottom, Spacing.xxl)
        }
        .scrollIndicators(.hidden)
        .navigationDestination(for: Club.self) { club in
            ClubDetailView(club: club)
        }
    }
    
    // MARK: - Data
    
    private func loadMyClubs() async {
        isLoading = true
        defer { isLoading = false }
        error = nil
        do {
            clubs = try await SupabaseService.shared.fetchMyClubs()
        } catch {
            self.error = AppError(underlying: error)
        }
    }
}

#Preview {
    NavigationStack {
        MyClubsView()
    }
}


