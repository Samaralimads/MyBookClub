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
    @State private var pendingCounts: [UUID: Int] = [:]
    
    var body: some View {
        ZStack {
            Color.background.ignoresSafeArea()

            VStack(spacing: 0) {
                HStack {
                    Text("My Clubs")
                        .font(.appTitle)
                        .foregroundStyle(.inkPrimary)
                    Spacer()
                    Button("", systemImage: "plus", action: { showCreate = true })
                        .tint(.accent)
                }
                .padding(.horizontal, Spacing.lg)
                .padding(.top, Spacing.md)
                .padding(.bottom, Spacing.sm)
                .background(Color.background)

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
                .frame(maxWidth: .infinity, maxHeight: .infinity)
            }
        }
        .toolbar(.hidden, for: .navigationBar)
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
                        ClubCard(club: club, userRole: role, pendingCount: pendingCounts[club.id, default: 0])
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
            await loadPendingCounts()
        } catch {
            self.error = AppError(underlying: error)
        }
    }

    private func loadPendingCounts() async {
        let currentUserId = SupabaseService.shared.client.auth.currentUser?.id
        await withTaskGroup(of: (UUID, Int).self) { group in
            for club in clubs where club.organiserId == currentUserId {
                group.addTask {
                    let count = (try? await SupabaseService.shared.fetchPendingMembers(clubId: club.id))?.count ?? 0
                    return (club.id, count)
                }
            }
            for await (id, count) in group {
                pendingCounts[id] = count
            }
        }
    }
}

#Preview {
    NavigationStack {
        MyClubsView()
    }
}


