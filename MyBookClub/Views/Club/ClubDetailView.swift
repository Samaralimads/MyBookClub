//
//  ClubDetailView.swift
//  MyBookClub
//
//  Created by Samara Lima da Silva on 10/03/2026.
//

import SwiftUI

struct ClubDetailView: View {
    let club: Club
    
    @Environment(\.dismiss) private var dismiss
    @State private var vm = ClubDetailViewModel()
    @State private var selectedTab: ClubTab = .about
    @State private var currentClub: Club
    @State private var showSettings = false
    
    init(club: Club) {
        self.club = club
        self._currentClub = State(initialValue: club)
    }
    
    enum ClubTab: String, CaseIterable {
        case about   = "About"
        case book    = "Book"
        case board   = "Board"
        case vote    = "Vote"
        case history = "History"
    }
    
    // MARK: - Body
    
    var body: some View {
        mainContent
            .background(Color.background)
            .animation(Animations.standard, value: vm.isLoading)
            .task {
                if let fresh = await vm.reloadClub(clubId: club.id) {
                    currentClub = fresh
                }
                await vm.loadAll(clubId: club.id)
            }
            .navigationBarHidden(true)
            .sheet(isPresented: $showSettings) { settingsSheet }
            .alert("Your club is full 🎉", isPresented: $vm.showCapacityReachedAlert) {
                Button("Raise Capacity") { showSettings = true }
                Button("OK", role: .cancel) { }
            } message: {
                Text("You've reached your \(currentClub.memberCap)-member limit. No new members can join until you raise the capacity in Club Settings.")
            }
    }
    
    // MARK: - Main Content
    
    private var mainContent: some View {
        ZStack {
            scrollContent
            if vm.isLoading { loadingOverlay }
        }
    }
    
    private var scrollContent: some View {
        ScrollView {
            VStack(spacing: 0) {
                heroHeader
                if !vm.isLoading {
                    clubInfo
                    joinButton
                    tabBar
                    tabContent
                        .padding(.horizontal, Spacing.lg)
                        .padding(.top, Spacing.xl)
                }
            }
        }
        .scrollIndicators(.hidden)
        .scrollContentBackground(.hidden)
        .ignoresSafeArea(edges: .top)
    }
    
    private var loadingOverlay: some View {
        VStack {
            Color.clear.frame(height: 260)
            ZStack {
                Color.background.ignoresSafeArea(edges: .bottom)
                VStack(spacing: Spacing.lg) {
                    ProgressView()
                        .tint(.accent)
                        .scaleEffect(1.2)
                    Text("Loading club…")
                        .font(.appCaption)
                        .foregroundStyle(.inkTertiary)
                }
                .frame(maxHeight: .infinity)
            }
        }
        .transition(.opacity)
    }
    
    // MARK: - Toolbar (custom overlay)
    
    private var customToolbar: some View {
        HStack {
            Button { dismiss() } label: {
                Image(systemName: "chevron.left")
                    .font(.system(size: 19, weight: .semibold))
                    .foregroundStyle(.white)
                    .frame(width: 44, height: 44)
                    .background(.ultraThinMaterial)
                    .clipShape(.circle)
            }
            Spacer()
            HStack(spacing: Spacing.sm) {
                if vm.isOrganiser {
                    Button { showSettings = true } label: {
                        Image(systemName: "gearshape")
                            .font(.system(size: 19, weight: .semibold))
                            .foregroundStyle(.white)
                            .frame(width: 44, height: 44)
                            .background(.ultraThinMaterial)
                            .clipShape(.circle)
                    }
                }
                ShareLink(
                    item: vm.shareURL(for: club.id),
                    subject: Text(currentClub.name),
                    message: Text("Join me at \(currentClub.name) on MyBookClub!")
                ) {
                    Image(systemName: "square.and.arrow.up")
                        .font(.system(size: 19, weight: .semibold))
                        .foregroundStyle(.white)
                        .frame(width: 44, height: 44)
                        .background(.ultraThinMaterial)
                        .clipShape(.circle)
                }
            }
        }
        .padding(.horizontal, Spacing.lg)
        .padding(.top, Spacing.sm)
    }
    
    // MARK: - Settings Sheet
    
    private var settingsSheet: some View {
        NavigationStack {
            CreateClubView(
                club: currentClub,
                onClubUpdated: { updated in
                    Task { currentClub = await vm.applyClubUpdate(updated) }
                },
                onClubDeleted: { dismiss() }
            )
        }
    }
    
    // MARK: - Hero
    
    private var heroHeader: some View {
        AsyncImage(url: currentClub.coverImageURL.flatMap { URL(string: $0) }) { image in
            image.resizable().scaledToFill()
        } placeholder: {
            LinearGradient(
                colors: [Color.accent.opacity(0.7), Color.accent.opacity(0.35)],
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )
        }
        .frame(maxWidth: .infinity, minHeight: 260)
        .clipped()
        .overlay(alignment: .top) {
            customToolbar
                .padding(.top, 44) // status bar height
        }
    }
    
    // MARK: - Club info strip
    
    private var clubInfo: some View {
        VStack(alignment: .leading, spacing: Spacing.sm) {
            if let firstGenre = currentClub.genreTags.first,
               let genre = Genre(rawValue: firstGenre) {
                Text(genre.label.uppercased())
                    .font(.appCaption.weight(.bold))
                    .foregroundStyle(.accent)
                    .tracking(0.8)
            }
            Text(currentClub.name)
                .font(.appTitle)
                .foregroundStyle(.inkPrimary)
            HStack(spacing: Spacing.xl) {
                memberCountView
                cityView
            }
            .foregroundStyle(.inkSecondary)
        }
        .padding(.horizontal, Spacing.lg)
        .padding(.top, Spacing.xl)
        .padding(.bottom, Spacing.md)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(Color.background)
        .clipShape(UnevenRoundedRectangle(
            topLeadingRadius: CornerRadius.sheet,
            topTrailingRadius: CornerRadius.sheet
        ))
        .offset(y: -CornerRadius.sheet)
        .padding(.bottom, -CornerRadius.sheet)
    }
    
    private var memberCountView: some View {
        HStack(spacing: 6) {
            Image(systemName: "person.2").font(.system(size: 14))
            if currentClub.memberCap > 0 {
                Text("\(currentClub.memberCount ?? 0)/\(currentClub.memberCap)")
                    .font(.appBody)
            } else {
                Text("^\(currentClub.memberCount ?? 0) Member](inflect: true)")
                    .font(.appBody)
            }
        }
    }
    
    private var cityView: some View {
        HStack(spacing: 6) {
            Image(systemName: "mappin.and.ellipse").font(.system(size: 14))
            Text(currentClub.cityLabel)
                .font(.appBody)
                .lineLimit(1)
        }
    }
    
    // MARK: - Join / membership button
    
    @ViewBuilder
    private var joinButton: some View {
        if vm.isOrganiser {
            EmptyView()
        } else if vm.membershipStatus == .pending {
            pendingLabel
        } else if vm.isMember {
            joinedMenu
        } else if vm.isAtCapacity(club: currentClub) {
            fullLabel
        } else {
            joinAction
        }
    }
    
    private var pendingLabel: some View {
        HStack(spacing: Spacing.sm) {
            Image(systemName: "clock").font(.system(size: 15))
            Text("Request Pending").font(.appBody.weight(.semibold))
        }
        .foregroundStyle(.inkSecondary)
        .frame(maxWidth: .infinity)
        .padding(.vertical, Spacing.md + 2)
        .background(Color.border.opacity(0.4))
        .clipShape(.rect(cornerRadius: 50))
        .padding(.horizontal, Spacing.lg)
        .padding(.bottom, Spacing.md)
    }
    
    private var joinedMenu: some View {
        Menu {
        // TODO: for v2 (per-club notification preferences for each user)
//            Button(role: .none) { } label: {
//                Label("Manage Notifications", systemImage: "bell")
//            }
//            Divider()
            Button(role: .destructive) {
                Task { await vm.leaveClub(clubId: club.id) }
            } label: {
                Label("Leave Club", systemImage: "rectangle.portrait.and.arrow.right")
            }
        } label: {
            HStack(spacing: Spacing.sm) {
                Image(systemName: "checkmark").font(.system(size: 13, weight: .bold))
                Text("Joined").font(.appBody.weight(.semibold))
                Image(systemName: "chevron.down").font(.system(size: 12, weight: .semibold))
            }
            .foregroundStyle(.inkSecondary)
            .frame(maxWidth: .infinity)
            .padding(.vertical, Spacing.md + 2)
            .background(Color.border.opacity(0.4))
            .clipShape(.rect(cornerRadius: 50))
        }
        .padding(.horizontal, Spacing.lg)
        .padding(.bottom, Spacing.md)
    }
    
    private var fullLabel: some View {
        HStack(spacing: Spacing.sm) {
            Image(systemName: "person.fill.xmark").font(.system(size: 15))
            Text("Club Full (\(currentClub.memberCount ?? 0)/\(currentClub.memberCap))")
                .font(.appBody.weight(.semibold))
        }
        .foregroundStyle(.inkTertiary)
        .frame(maxWidth: .infinity)
        .padding(.vertical, Spacing.md + 2)
        .background(Color.border.opacity(0.3))
        .clipShape(.rect(cornerRadius: 50))
        .padding(.horizontal, Spacing.lg)
        .padding(.bottom, Spacing.md)
    }
    
    private var joinAction: some View {
        Button {
            Task { await vm.joinClub(club: currentClub) }
        } label: {
            Group {
                if vm.isJoining {
                    ProgressView().tint(.white)
                } else {
                    Text(club.isPublic ? "Join Club" : "Request to Join")
                        .font(.appBody.weight(.semibold))
                }
            }
            .frame(maxWidth: .infinity)
        }
        .buttonStyle(PrimaryButtonStyle())
        .padding(.horizontal, Spacing.lg)
        .padding(.bottom, Spacing.md)
        .disabled(vm.isJoining)
    }
    
    // MARK: - Tab bar
    
    private var tabBar: some View {
        VStack(spacing: 0) {
            HStack(spacing: 0) {
                ForEach(ClubTab.allCases, id: \.rawValue) { tab in
                    Button {
                        withAnimation(Animations.standard) { selectedTab = tab }
                    } label: {
                        VStack(spacing: 0) {
                            Text(tab.rawValue)
                                .font(.appBody.weight(selectedTab == tab ? .semibold : .regular))
                                .foregroundStyle(selectedTab == tab ? .accent : .inkSecondary)
                                .frame(maxWidth: .infinity)
                                .padding(.vertical, Spacing.md)
                            Rectangle()
                                .fill(selectedTab == tab ? Color.accentColor : Color.clear)
                                .frame(height: 2)
                        }
                    }
                }
            }
            Divider().background(Color.border)
        }
    }
    
    // MARK: - Tab content
    
    @ViewBuilder
    private var tabContent: some View {
        switch selectedTab {
        case .about:   aboutTab
        case .book:    bookTab
        case .board:   boardTab
        case .vote:    voteTab
        case .history: historyTab
        }
    }
    
    private var aboutTab: some View {
        ClubAboutTab(
            club: currentClub,
            vm: vm,
            onSchedule: { title, date, from, to, titles, address, isFinal in
                Task {
                    await vm.scheduleMeeting(
                        clubId: club.id, title: title, scheduledAt: date,
                        fromChapter: from, toChapter: to, chapterTitles: titles,
                        address: address, isFinal: isFinal
                    )
                }
            },
            onUpdateMeeting: { title, date, from, to, titles, address, isFinal in
                Task {
                    await vm.updateMeeting(
                        clubId: club.id, title: title, scheduledAt: date,
                        fromChapter: from, toChapter: to, chapterTitles: titles,
                        address: address, isFinal: isFinal
                    )
                }
            }
        )
    }
    
    private var bookTab: some View {
        ClubBookTab(
            club: currentClub,
            isMember: vm.isMember,
            nextMeeting: vm.nextMeeting,
            onArchived: {
                Task { @MainActor in
                    if let fresh = await vm.reloadClub(clubId: club.id) {
                        currentClub = fresh
                    }
                }
            }
        )
    }
    
    private var boardTab: some View {
        ClubBoardTab(
            club: currentClub,
            isOrganiser: vm.isOrganiser,
            isMember: vm.isMember
        )
    }
    
    private var voteTab: some View {
        ClubVoteTab(
            club: currentClub,
            isMember: vm.isMember,
            isOrganiser: vm.isOrganiser,
            onWinnerPicked: { book in
                currentClub.currentBook = book
                currentClub.currentBookId = book.id
                Task {
                    if let fresh = await vm.reloadClub(clubId: club.id) {
                        currentClub = fresh
                    }
                }
            }
        )
    }
    
    private var historyTab: some View {
        ClubHistoryTab(club: currentClub)
    }
}

#Preview {
    ClubDetailView(club: Club(
        id: UUID(),
        organiserId: nil,
        name: "Downtown Fiction Readers",
        description: "A friendly group of fiction lovers meeting bi-weekly.",
        coverImageURL: nil,
        genreTags: ["literary-fiction"],
        cityLabel: "Blue Bottle Coffee, Downtown",
        isPublic: true,
        memberCap: 20,
        createdAt: .now,
        memberCount: 14
    ))
}
