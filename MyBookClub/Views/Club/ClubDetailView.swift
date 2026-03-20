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
        ScrollView {
            VStack(spacing: 0) {
                heroHeader
                clubInfo
                joinButton
                tabBar
                tabContent
                    .padding(.horizontal, Spacing.lg)
                    .padding(.top, Spacing.xl)
            }
        }
        .background(Color.background)
        .ignoresSafeArea(edges: .top)
        .task {
            await vm.loadMembership(clubId: club.id)
            await vm.loadNextMeeting(clubId: club.id)
            await vm.loadMembers(clubId: club.id)
            if let fresh = await vm.reloadClub(clubId: club.id) {
                currentClub = fresh
            }
        }
        .toolbar {
            if vm.isOrganiser {
                ToolbarItem(placement: .topBarTrailing) {
                    Button("", systemImage: "gearshape") {
                        showSettings = true
                    }
                    .tint(.black)
                }
            }

            ToolbarItem(placement: .topBarTrailing) {
                ShareLink(
                    item: shareURL,
                    subject: Text(currentClub.name),
                    message: Text("Join me at \(currentClub.name) on MyBookClub!")
                ) {
                    Image(systemName: "square.and.arrow.up")
                        .foregroundStyle(.black)
                }
            }
        }
        .toolbarBackground(.hidden, for: .navigationBar)
        .sheet(isPresented: $showSettings) {
            NavigationStack {
                CreateClubView(
                    club: currentClub,
                    onClubUpdated: { updated in
                        currentClub = updated
                    },
                    onClubDeleted: {
                        dismiss()
                    }
                )
            }
        }
    }

    private var shareURL: URL {
        URL(string: "https://mybookclub.app/club/\(club.id.uuidString)") ?? URL(string: "https://mybookclub.app")!
    }

    // MARK: - Hero

    private var heroHeader: some View {
        AsyncImage(url: currentClub.coverImageURL.flatMap { URL(string: $0) }) { image in
            image.resizable().scaledToFill()
        } placeholder: {
            LinearGradient(
                colors: [Color.accent.opacity(0.7), Color.accent.opacity(0.35)],
                startPoint: .topLeading, endPoint: .bottomTrailing
            )
        }
        .frame(maxWidth: .infinity, minHeight: 260)
        .clipped()
    }

    // MARK: - Club Info

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
                    Image(systemName: "person.2")
                        .font(.system(size: 14))
                    Text("^[\(currentClub.memberCount ?? 0) Member](inflect: true)")
                        .font(.appBody)
                }
                HStack(spacing: 6) {
                    Image(systemName: "mappin.and.ellipse")
                        .font(.system(size: 14))
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

    // MARK: - Join Button

    @ViewBuilder
    private var joinButton: some View {
        if vm.isOrganiser {
            EmptyView()
        } else if vm.membershipStatus == .pending {
            HStack(spacing: Spacing.sm) {
                Image(systemName: "clock")
                    .font(.system(size: 15))
                Text("Request Pending")
                    .font(.appBody.weight(.semibold))
            }
            .foregroundStyle(.inkSecondary)
            .frame(maxWidth: .infinity)
            .padding(.vertical, Spacing.md + 2)
            .background(Color.border.opacity(0.4))
            .clipShape(RoundedRectangle(cornerRadius: 50))
            .padding(.horizontal, Spacing.lg)
            .padding(.bottom, Spacing.md)
        } else if vm.isMember {
            Menu {
                Button(role: .none) {
                    // TODO: notification preferences
                } label: {
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
                    Image(systemName: "checkmark")
                        .font(.system(size: 13, weight: .bold))
                    Text("Joined")
                        .font(.appBody.weight(.semibold))
                    Image(systemName: "chevron.down")
                        .font(.system(size: 12, weight: .semibold))
                }
                .foregroundStyle(.inkSecondary)
                .frame(maxWidth: .infinity)
                .padding(.vertical, Spacing.md + 2)
                .background(Color.border.opacity(0.4))
                .clipShape(RoundedRectangle(cornerRadius: 50))
            }
            .padding(.horizontal, Spacing.lg)
            .padding(.bottom, Spacing.md)
        } else {
            Button {
                Task { await vm.joinClub(clubId: club.id, isPublic: club.isPublic) }
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
    }

    // MARK: - Tab Bar

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

    // MARK: - Tab Content

    @ViewBuilder
    private var tabContent: some View {
        switch selectedTab {
        case .about:
            ClubAboutTab(
                club: currentClub,
                isOrganiser: vm.isOrganiser,
                nextMeeting: vm.nextMeeting,
                isScheduling: vm.isScheduling,
                members: vm.members,
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
                }
            )
        case .book:
            ClubBookTab(
                club: currentClub,
                isMember: vm.isMember,
                isOrganiser: vm.isOrganiser,
                nextMeeting: vm.nextMeeting,
                onBookChanged: { book in
                    currentClub.currentBook = book
                    currentClub.currentBookId = book.id
                },
                onArchived: {
                    Task { @MainActor in
                        if let fresh = await vm.reloadClub(clubId: club.id) {
                            currentClub = fresh
                        }
                    }
                }
            )
        case .board:
            ClubBoardTab(club: currentClub, isOrganiser: vm.isOrganiser)
        case .vote:
            ClubVoteTab(club: currentClub, isMember: vm.isMember)
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
        recurringDay: "Saturday",
        recurringTime: "14:00",
        currentBookId: nil,
        createdAt: .now,
        memberCount: 14
    ))
}
