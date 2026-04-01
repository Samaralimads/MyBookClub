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

    var body: some View {
        ZStack {
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
            .background(Color.background)
            .ignoresSafeArea(edges: .top)
            
            if vm.isLoading {
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
        }
        .animation(Animations.standard, value: vm.isLoading)
        .task {
            async let clubLoad: Void = {
                if let fresh = await vm.reloadClub(clubId: club.id) {
                    await MainActor.run { currentClub = fresh }
                }
            }()
            async let dataLoad: Void = vm.loadAll(clubId: club.id)
            _ = await (clubLoad, dataLoad)
        }
        .toolbar {
            if vm.isOrganiser {
                ToolbarItem(placement: .topBarTrailing) {
                    Button { showSettings = true } label: {
                        Image(systemName: "gearshape")
                    }
                }
            }
            ToolbarItem(placement: .topBarTrailing) {
                ShareLink(
                    item: shareURL,
                    subject: Text(currentClub.name),
                    message: Text("Join me at \(currentClub.name) on MyBookClub!")
                ) {
                    Image(systemName: "square.and.arrow.up")
                }
            }
        }
        .tint(.primary)
        .toolbarBackground(.hidden, for: .navigationBar)
        .sheet(isPresented: $showSettings) {
            NavigationStack {
                CreateClubView(
                    club: currentClub,
                    onClubUpdated: { updated in currentClub = updated },
                    onClubDeleted: { dismiss() }
                )
            }
        }
        .alert("Your club is full 🎉", isPresented: $vm.showCapacityReachedAlert) {
            Button("Raise Capacity") { showSettings = true }
            Button("OK", role: .cancel) { }
        } message: {
            Text("You've reached your \(currentClub.memberCap)-member limit. No new members can join until you raise the capacity in Club Settings.")
        }
    }

    private var shareURL: URL {
        URL(string: "https://mybookclub.app/club/\(club.id.uuidString)")
            ?? URL(string: "https://mybookclub.app")!
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
                HStack(spacing: 6) {
                    Image(systemName: "person.2").font(.system(size: 14))
                    if currentClub.memberCap > 0 {
                        Text("\(currentClub.memberCount ?? 0)/\(currentClub.memberCap)")
                            .font(.appBody)
                    } else {
                        Text("^[\(currentClub.memberCount ?? 0) Member](inflect: true)")
                            .font(.appBody)
                    }
                }
                HStack(spacing: 6) {
                    Image(systemName: "mappin.and.ellipse").font(.system(size: 14))
                    Text(currentClub.cityLabel)
                        .font(.appBody)
                        .lineLimit(1)
                }
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
            Button(role: .none) { } label: {
                Label("Manage Notifications", systemImage: "bell")
            }
            Divider()
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
        case .about:
            ClubAboutTab(
                club: currentClub,
                vm: vm,
                onSchedule: { title, date, from, to, titles, address, isFinal in
                    Task {
                        await vm.scheduleMeeting(
                            clubId: club.id,
                            title: title,
                            scheduledAt: date,
                            fromChapter: from,
                            toChapter: to,
                            chapterTitles: titles,
                            address: address,
                            isFinal: isFinal
                        )
                    }
                },
                onUpdateMeeting: { title, date, from, to, titles, address, isFinal in
                    Task {
                        await vm.updateMeeting(
                            clubId: club.id,
                            title: title,
                            scheduledAt: date,
                            fromChapter: from,
                            toChapter: to,
                            chapterTitles: titles,
                            address: address,
                            isFinal: isFinal
                        )
                    }
                }
            )

        case .book:
            ClubBookTab(
                club: currentClub,
                isMember: vm.isMember,
                nextMeeting: vm.nextMeeting
            )

        case .board:
            ClubBoardTab(
                club: currentClub,
                isOrganiser: vm.isOrganiser
            )

        case .vote:
            ClubVoteTab(
                club: currentClub,
                isMember: vm.isMember,
                isOrganiser: vm.isOrganiser,
                onWinnerPicked: { book in
                    currentClub.currentBook   = book
                    currentClub.currentBookId = book.id
                }
            )

        case .history:
            ClubHistoryTab(club: currentClub)
        }
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
