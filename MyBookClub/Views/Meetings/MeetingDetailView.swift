//
//  MeetingDetailView.swift
//  MyBookClub
//
//  Created by Samara Lima da Silva on 01/04/2026.
//

import SwiftUI

struct MeetingDetailView: View {
    let meeting: Meeting

    @State private var rsvpStatus: RSVPStatus? = nil
    @State private var rsvpCounts = RSVPCounts(goingCount: 0, notGoingCount: 0)
    @State private var rsvpMembers: [RSVPMember] = []
    @State private var calendarAlertType: CalendarAlertType? = nil
    @State private var showRSVPList = false

    var body: some View {
        ZStack {
            Color.background.ignoresSafeArea()

            ScrollView {
                VStack(alignment: .leading, spacing: 0) {
                    heroSection
                    contentSection
                }
            }
            .scrollIndicators(.hidden)
        }
        .navigationBarTitleDisplayMode(.inline)
        .task { await loadRSVP() }
        .alert(item: $calendarAlertType) { type in
            switch type {
            case .added(let title):
                Alert(
                    title: Text("Added to Calendar"),
                    message: Text("\"\(title)\" has been added to your calendar."),
                    dismissButton: .default(Text("Great!"))
                )
            case .denied:
                Alert(
                    title: Text("Calendar Access Denied"),
                    message: Text("Please allow calendar access in Settings."),
                    dismissButton: .default(Text("OK"))
                )
            case .error(let msg):
                Alert(
                    title: Text("Couldn't Add Event"),
                    message: Text(msg),
                    dismissButton: .default(Text("OK"))
                )
            }
        }
        .sheet(isPresented: $showRSVPList) {
            RSVPListSheet(
                meetingTitle: meeting.title,
                rsvpMembers: rsvpMembers,
                goingCount: rsvpCounts.goingCount,
                notGoingCount: rsvpCounts.notGoingCount
            )
        }
    }

    // MARK: - Hero: book cover

    private var heroSection: some View {
        HStack {
            Spacer()
            AsyncImage(url: meeting.bookCoverURL.flatMap { URL(string: $0) }) { image in
                image
                    .resizable()
                    .scaledToFit()
                    .frame(width: 140, height: 200)
                    .clipShape(.rect(cornerRadius: 8))
                    .shadow(color: .black.opacity(0.4), radius: 16, x: 0, y: 6)
            } placeholder: {
                RoundedRectangle(cornerRadius: 8)
                    .fill(Color.accentSubtle)
                    .frame(width: 140, height: 200)
                    .overlay {
                        Image(systemName: "book.closed.fill")
                            .font(.system(size: 40))
                            .foregroundStyle(.accent)
                    }
                    .shadow(color: .black.opacity(0.3), radius: 16, x: 0, y: 6)
            }
            Spacer()
        }
        .padding(.bottom, Spacing.xl)
    }

    // MARK: - Content

    private var contentSection: some View {
        VStack(alignment: .leading, spacing: Spacing.xl) {
            clubAndBookHeader
            metadataSection
            readingAssignmentSection
            attendeesSection
            actionButtons
        }
        .padding(.horizontal, Spacing.lg)
        .padding(.bottom, Spacing.xxl)
    }

    // MARK: - Club tag + Book title/author

    private var clubAndBookHeader: some View {
        VStack(alignment: .leading, spacing: Spacing.xs) {
            if let clubName = meeting.clubName {
                Text(clubName.uppercased())
                    .font(.appCaption.weight(.bold))
                    .foregroundStyle(.accent)
                    .tracking(0.8)
            }

            Text(meeting.bookTitle ?? meeting.title)
                .font(.appTitle)
                .foregroundStyle(.inkPrimary)

            if let author = meeting.bookAuthor {
                Text("by \(author)")
                    .font(.appBody)
                    .foregroundStyle(.inkSecondary)
            }
        }
    }

    // MARK: - Date / Time / Location

    private var metadataSection: some View {
        VStack(alignment: .leading, spacing: Spacing.md) {
            MeetingMetadataRow(
                icon: "calendar",
                label: "Date",
                value: meeting.scheduledAt.formatted(.dateTime.weekday(.wide).month(.wide).day())
            )
            MeetingMetadataRow(
                icon: "clock",
                label: "Time",
                value: meeting.scheduledAt.formatted(.dateTime.hour().minute())
            )
            if let address = meeting.address, !address.isEmpty {
                let isVirtual = address.localizedCaseInsensitiveContains("zoom")
                             || address.localizedCaseInsensitiveContains("virtual")
                             || address.localizedCaseInsensitiveContains("meet")
                MeetingMetadataRow(
                    icon: "mappin.and.ellipse",
                    label: "Location",
                    value: address,
                    valueColor: isVirtual ? .accent : .inkPrimary
                )
            }
        }
    }

    // MARK: - Reading assignment

    @ViewBuilder
    private var readingAssignmentSection: some View {
        if let from = meeting.fromChapter, let to = meeting.toChapter {
            MeetingMetadataRow(
                icon: "bookmark.fill",
                label: "Reading Assignment",
                value: from == to
                    ? "Chapter \(from)"
                    : "Chapters \(from) to \(to)"
            )
        }
    }

    // MARK: - Attendees

    private var attendeesSection: some View {
        VStack(alignment: .leading, spacing: Spacing.md) {
            Button {
                showRSVPList = true
            } label: {
                HStack(spacing: Spacing.sm) {
                    Image(systemName: "person.2")
                        .foregroundStyle(.accent)
                    let total = rsvpCounts.goingCount + rsvpCounts.notGoingCount
                    Text("^[\(total) Attending](inflect: true)")
                        .font(.appHeadline)
                        .foregroundStyle(.inkPrimary)
                    Spacer()
                    Image(systemName: "chevron.right")
                        .font(.system(size: 13, weight: .semibold))
                        .foregroundStyle(.inkTertiary)
                }
            }
            .buttonStyle(.plain)

            HStack(alignment: .top, spacing: 0) {
                if rsvpCounts.goingCount > 0 {
                    RSVPGroupColumn(
                        label: "Going",
                        count: rsvpCounts.goingCount,
                        members: rsvpMembers.filter { $0.status == .going }
                    )
                }
                if rsvpCounts.goingCount > 0 && rsvpCounts.notGoingCount > 0 {
                    Divider()
                        .frame(maxHeight: 60)
                        .padding(.horizontal, Spacing.lg)
                }
                if rsvpCounts.notGoingCount > 0 {
                    RSVPGroupColumn(
                        label: "Not Going",
                        count: rsvpCounts.notGoingCount,
                        members: rsvpMembers.filter { $0.status == .notGoing }
                    )
                }
            }
        }
        .padding(Spacing.md)
        .background(Color.cardBackground)
        .clipShape(.rect(cornerRadius: CornerRadius.card))
        .overlay {
            RoundedRectangle(cornerRadius: CornerRadius.card)
                .stroke(Color.border, lineWidth: 1)
        }
    }

    // MARK: - RSVP + Calendar buttons

    private var actionButtons: some View {
        HStack(spacing: Spacing.md) {
            RSVPMenuButton(rsvpStatus: rsvpStatus, onRSVP: rsvp)
                .frame(maxWidth: .infinity)

            Button {
                Task { await addToCalendar() }
            } label: {
                Label("Calendar", systemImage: "calendar.badge.plus")
                    .font(.appBody.weight(.semibold))
                    .frame(maxWidth: .infinity)
                    .frame(height: 50)
                    .foregroundStyle(.accent)
                    .background(Color.accentSubtle)
                    .clipShape(.rect(cornerRadius: CornerRadius.button))
            }
        }
    }

    // MARK: - Actions

    private func loadRSVP() async {
        do {
            rsvpStatus  = try await SupabaseService.shared.fetchMyRSVP(meetingId: meeting.id).map { $0.status }
            rsvpCounts  = try await SupabaseService.shared.fetchRSVPCounts(meetingId: meeting.id)
            rsvpMembers = try await SupabaseService.shared.fetchRSVPMembers(meetingId: meeting.id)
        } catch { }
    }

    private func rsvp(_ status: RSVPStatus) {
        rsvpStatus = status
        Task {
            do {
                try await SupabaseService.shared.upsertRSVP(
                    meetingId: meeting.id,
                    clubId: meeting.clubId,
                    status: status
                )
                rsvpCounts  = try await SupabaseService.shared.fetchRSVPCounts(meetingId: meeting.id)
                rsvpMembers = try await SupabaseService.shared.fetchRSVPMembers(meetingId: meeting.id)
            } catch {
                await loadRSVP()
            }
        }
    }

    private func addToCalendar() async {
        let result = await CalendarService.shared.addMeeting(meeting)
        switch result {
        case .success:            calendarAlertType = .added(title: meeting.bookTitle ?? meeting.title)
        case .denied:             calendarAlertType = .denied
        case .failure(let error): calendarAlertType = .error(error.localizedDescription)
        }
    }

    // MARK: - Alert type

    private enum CalendarAlertType: Identifiable {
        case added(title: String)
        case denied
        case error(String)

        var id: String {
            switch self {
            case .added(let t): "added_\(t)"
            case .denied:       "denied"
            case .error(let m): "error_\(m)"
            }
        }
    }
}

// MARK: - MeetingMetadataRow

struct MeetingMetadataRow: View {
    let icon: String
    let label: String
    let value: String
    var valueColor: Color = .inkPrimary

    var body: some View {
        HStack(spacing: Spacing.md) {
            ZStack {
                Circle()
                    .fill(Color.accentSubtle)
                    .frame(width: 44, height: 44)
                Image(systemName: icon)
                    .foregroundStyle(.accent)
                    .font(.system(size: 18))
            }
            VStack(alignment: .leading, spacing: 2) {
                Text(label)
                    .font(.appCaption)
                    .foregroundStyle(.inkSecondary)
                Text(value)
                    .font(.appBody.weight(.semibold))
                    .foregroundStyle(valueColor)
            }
        }
    }
}

// MARK: - RSVPGroupColumn

private struct RSVPGroupColumn: View {
    let label: String
    let count: Int
    let members: [RSVPMember]

    private let avatarSize: CGFloat = 36
    private let maxShown = 4

    var body: some View {
        VStack(alignment: .leading, spacing: Spacing.xs) {
            HStack(spacing: 4) {
                Text(label)
                    .font(.appCaption)
                    .foregroundStyle(.inkSecondary)
                Text("\(count)")
                    .font(.appCaption.weight(.semibold))
                    .foregroundStyle(.inkSecondary)
            }
            HStack(spacing: -8) {
                ForEach(members.prefix(maxShown)) { member in
                    AsyncImage(url: member.avatarURL.flatMap { URL(string: $0) }) { image in
                        image.resizable().scaledToFill()
                    } placeholder: {
                        Circle()
                            .fill(Color.purpleTint)
                            .overlay {
                                Image(systemName: "person.fill")
                                    .foregroundStyle(.accent)
                                    .font(.system(size: 14))
                            }
                    }
                    .frame(width: avatarSize, height: avatarSize)
                    .clipShape(.circle)
                    .overlay { Circle().stroke(Color.cardBackground, lineWidth: 2) }
                }
            }
        }
    }
}

// MARK: - RSVPMenuButton

private struct RSVPMenuButton: View {
    let rsvpStatus: RSVPStatus?
    let onRSVP: (RSVPStatus) -> Void

    var body: some View {
        Menu {
            Button("Going", systemImage: rsvpStatus == .going ? "checkmark.circle.fill" : "checkmark.circle") {
                onRSVP(.going)
            }
            Button("Not Going", systemImage: rsvpStatus == .notGoing ? "xmark.circle.fill" : "xmark.circle") {
                onRSVP(.notGoing)
            }
        } label: {
            HStack(spacing: Spacing.sm) {
                Text(rsvpLabel)
                    .font(.appBody.weight(.semibold))
                Image(systemName: "chevron.down")
                    .font(.system(size: 11, weight: .semibold))
            }
            .frame(maxWidth: .infinity)
            .frame(height: 50)
            .foregroundStyle(rsvpForeground)
            .background(rsvpBackground)
            .clipShape(.rect(cornerRadius: CornerRadius.button))
            .overlay {
                if rsvpStatus == .notGoing {
                    RoundedRectangle(cornerRadius: CornerRadius.button)
                        .stroke(Color.border, lineWidth: 1.5)
                }
            }
        }
        .animation(Animations.standard, value: rsvpStatus)
    }

    private var rsvpLabel: String {
        switch rsvpStatus {
        case .going:    "Going ✓"
        case .notGoing: "Not Going"
        case nil:       "RSVP"
        }
    }

    private var rsvpBackground: Color {
        rsvpStatus == .notGoing ? .cardBackground : .accent
    }

    private var rsvpForeground: Color {
        rsvpStatus == .notGoing ? .inkSecondary : .white
    }
}

// MARK: - Preview

#Preview {
    NavigationStack {
        MeetingDetailView(
            meeting: Meeting(
                id: UUID(),
                clubId: UUID(),
                title: "Dune – Chapters 1–12",
                scheduledAt: Calendar.current.date(byAdding: .day, value: 3, to: .now)!,
                fromChapter: 1,
                toChapter: 12,
                chapterTitles: nil,
                notes: nil,
                address: "Virtual – Zoom",
                isFinal: false,
                notifSent24h: false,
                notifSent1h: false,
                createdAt: .now,
                clubName: "Sci-Fi & Coffee",
                clubCoverImageURL: nil,
                bookTitle: "Dune",
                bookAuthor: "Frank Herbert",
                bookCoverURL: nil
            )
        )
    }
}
