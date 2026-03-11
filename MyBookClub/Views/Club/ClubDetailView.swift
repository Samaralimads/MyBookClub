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
    @State private var selectedTab: ClubTab = .about
    @State private var membershipStatus: MemberStatus?
    @State private var myRole: MemberRole?
    @State private var isJoining = false
    @State private var error: AppError?

    enum ClubTab: String, CaseIterable {
        case about   = "About"
        case book    = "Book"
        case board   = "Board"
        case vote    = "Vote"
        case history = "History"
    }

    var isMember: Bool   { membershipStatus == .active }
    var isOrganiser: Bool { myRole == .organiser }

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
        .overlay(alignment: .top) {
            navButtons
        }
        .task { await loadMembership() }
    }

    // MARK: - Nav Buttons (float over hero)

    private var navButtons: some View {
        HStack {
            Button { dismiss() } label: {
                Image(systemName: "chevron.left")
                    .font(.system(size: 16, weight: .semibold))
                    .foregroundStyle(.white)
                    .frame(width: 36, height: 36)
                    .background(Color.black.opacity(0.35))
                    .clipShape(Circle())
            }
            Spacer()
            Button { } label: {
                Image(systemName: "square.and.arrow.up")
                    .font(.system(size: 16, weight: .semibold))
                    .foregroundStyle(.white)
                    .frame(width: 36, height: 36)
                    .background(Color.black.opacity(0.35))
                    .clipShape(Circle())
            }
        }
        .padding(.horizontal, Spacing.lg)
        .padding(.top, 56)
    }

    // MARK: - Hero

    private var heroHeader: some View {
        AsyncImage(url: club.coverImageURL.flatMap { URL(string: $0) }) { image in
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

    // MARK: - Club Info (white sheet over hero)

    private var clubInfo: some View {
        VStack(alignment: .leading, spacing: Spacing.sm) {
            if let firstGenre = club.genreTags.first,
               let genre = Genre(rawValue: firstGenre) {
                Text(genre.label.uppercased())
                    .font(.appCaption.weight(.bold))
                    .foregroundStyle(.accent)
                    .tracking(0.8)
            }

            Text(club.name)
                .font(.appTitle)
                .foregroundStyle(.inkPrimary)

            HStack(spacing: Spacing.xl) {
                HStack(spacing: 6) {
                    Image(systemName: "person.2")
                        .font(.system(size: 14))
                    Text("\(club.memberCount ?? 0) Members")
                        .font(.appBody)
                }
                HStack(spacing: 6) {
                    Image(systemName: "mappin.and.ellipse")
                        .font(.system(size: 14))
                    Text(club.cityLabel)
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
        if membershipStatus == .pending {
            Text("Request Pending")
                .font(.appBody.weight(.semibold))
                .foregroundStyle(.inkSecondary)
                .frame(maxWidth: .infinity)
                .padding(.vertical, Spacing.md + 2)
                .background(Color.purpleTint)
                .clipShape(RoundedRectangle(cornerRadius: 50))
                .padding(.horizontal, Spacing.lg)
                .padding(.bottom, Spacing.md)
        } else if !isMember {
            Button {
                Task { await joinClub() }
            } label: {
                Group {
                    if isJoining {
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
            .disabled(isJoining)
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

    // MARK: - Tab Content — delegates to separate view files

    @ViewBuilder
    private var tabContent: some View {
        switch selectedTab {
        case .about:
            ClubAboutTab(club: club)
        case .book:
            ClubBookTab(club: club, isMember: isMember)
        case .board:
            ClubBoardTab(club: club, isOrganiser: isOrganiser)
        case .vote:
            ClubVoteTab(club: club, isMember: isMember)
        case .history:
            ClubHistoryTab(club: club)
        }
    }

    // MARK: - Actions

    private func loadMembership() async {
        do {
            membershipStatus = try await SupabaseService.shared.membershipStatus(clubId: club.id)
            myRole = try await SupabaseService.shared.myRole(clubId: club.id)
        } catch { }
    }

    private func joinClub() async {
        isJoining = true
        defer { isJoining = false }
        do {
            try await SupabaseService.shared.joinClub(clubId: club.id, isPublic: club.isPublic)
            membershipStatus = club.isPublic ? .active : .pending
        } catch {
            self.error = AppError(underlying: error)
        }
    }
}

#Preview {
    ClubDetailView(club: Club(
        id: UUID(),
        organiserId: nil,
        name: "Downtown Fiction Readers",
        description: "A friendly group of fiction lovers meeting bi-weekly to discuss contemporary and literary fiction. All are welcome, whether you've finished the book or not!",
        coverImageURL: nil,
        genreTags: ["literary-fiction"],
        cityLabel: "Blue Bottle Coffee, Downtown",
        isPublic: true,
        memberCap: 20,
        recurringDay: "Saturday",
        recurringTime: "14:00",
        currentBookId: nil,
        createdAt: Date(),
        memberCount: 14
    ))
}
