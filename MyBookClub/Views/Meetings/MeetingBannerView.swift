//
//  MeetingBannerView.swift
//  MyBookClub
//
//  Created by Samara Lima da Silva on 17/03/2026.
//

import SwiftUI

struct MeetingBannerView: View {
    let meeting: Meeting
    let isOrganiser: Bool
    let rsvpStatus: RSVPStatus?
    let rsvpCounts: RSVPCounts
    let rsvpMembers: [RSVPMember]
    let onRSVP: (RSVPStatus) -> Void
    let onEdit: () -> Void

    @State private var calendarAlertType: CalendarAlertType?
    @State private var showRSVPList = false

    var body: some View {
        VStack(alignment: .leading, spacing: Spacing.lg) {
            headerRow
            metadataRows
            rsvpSummaryRow
            actionRow
        }
        .padding(Spacing.lg)
        .background(Color.cardBackground)
        .clipShape(.rect(cornerRadius: CornerRadius.card))
        .overlay {
            RoundedRectangle(cornerRadius: CornerRadius.card)
                .stroke(Color.border, lineWidth: 1)
        }
        .shadow(color: .black.opacity(0.06), radius: 12, x: 0, y: 4)
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

    // MARK: - Header

    private var headerRow: some View {
        HStack(alignment: .top) {
            VStack(alignment: .leading, spacing: 2) {
                Text("Upcoming Meeting")
                    .font(.appHeadline)
                    .foregroundStyle(.inkPrimary)
                Text(meeting.title)
                    .font(.appBody)
                    .foregroundStyle(.inkSecondary)
            }
            Spacer()
            if isOrganiser {
                Button(action: onEdit) {
                    Image(systemName: "pencil")
                        .font(.system(size: 15, weight: .medium))
                        .foregroundStyle(.inkSecondary)
                        .frame(width: 36, height: 36)
                        .background(Color.border.opacity(0.35))
                        .clipShape(.circle)
                }
            }
        }
    }

    // MARK: - Metadata rows

    private var metadataRows: some View {
        VStack(alignment: .leading, spacing: Spacing.md) {
            infoRow(
                icon: "calendar",
                text: meeting.scheduledAt.formatted(.dateTime.weekday(.wide).month(.wide).day())
            )
            infoRow(
                icon: "clock",
                text: meeting.scheduledAt.formatted(.dateTime.hour().minute())
            )
            if let address = meeting.address, !address.isEmpty {
                infoRow(icon: "mappin.and.ellipse", text: address)
            }
        }
    }

    private func infoRow(icon: String, text: String) -> some View {
        HStack(spacing: Spacing.md) {
            ZStack {
                Circle()
                    .fill(Color.purpleTint)
                    .frame(width: 36, height: 36)
                Image(systemName: icon)
                    .font(.system(size: 14))
                    .foregroundStyle(.accent)
            }
            Text(text)
                .font(.appBody.weight(.medium))
                .foregroundStyle(.inkPrimary)
        }
    }

    // MARK: - RSVP summary

    @ViewBuilder
    private var rsvpSummaryRow: some View {
        let total = rsvpCounts.goingCount + rsvpCounts.notGoingCount
        if total > 0 {
            Button { showRSVPList = true } label: {
                HStack(spacing: Spacing.sm) {
                    RSVPAvatarStack(members: rsvpMembers.filter { $0.status == .going })

                    VStack(alignment: .leading, spacing: 2) {
                        if rsvpCounts.goingCount > 0 {
                            Text("^[\(rsvpCounts.goingCount) person](inflect: true) going")
                                .font(.appCaption.weight(.semibold))
                                .foregroundStyle(.inkPrimary)
                        }
                        if rsvpCounts.notGoingCount > 0 {
                            Text("^[\(rsvpCounts.notGoingCount) person](inflect: true) not going")
                                .font(.appCaption)
                                .foregroundStyle(.inkSecondary)
                        }
                    }

                    Spacer()

                    Image(systemName: "chevron.right")
                        .font(.system(size: 12, weight: .semibold))
                        .foregroundStyle(.inkTertiary)
                }
                .padding(.horizontal, Spacing.md)
                .padding(.vertical, Spacing.sm)
                .background(Color.purpleTint.opacity(0.5))
                .clipShape(.rect(cornerRadius: CornerRadius.card))
            }
            .buttonStyle(.plain)
        }
    }

    // MARK: - Action row

    private var actionRow: some View {
        HStack(spacing: Spacing.md) {
            rsvpMenuButton
            addToCalendarButton
        }
    }

    private var rsvpMenuButton: some View {
        Menu {
            Button {
                onRSVP(.going)
            } label: {
                Label(
                    "Going",
                    systemImage: rsvpStatus == .going ? "checkmark.circle.fill" : "checkmark.circle"
                )
            }
            Button {
                onRSVP(.notGoing)
            } label: {
                Label(
                    "Not Going",
                    systemImage: rsvpStatus == .notGoing ? "xmark.circle.fill" : "xmark.circle"
                )
            }
        } label: {
            HStack(spacing: Spacing.sm) {
                Text(rsvpButtonLabel)
                    .font(.appBody.weight(.semibold))
                Image(systemName: "chevron.down")
                    .font(.system(size: 11, weight: .semibold))
            }
            .frame(maxWidth: .infinity)
            .frame(height: 44)
            .foregroundStyle(rsvpForegroundColor)
            .background(rsvpBackgroundColor)
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

    private var addToCalendarButton: some View {
        Button {
            Task { await addToCalendar() }
        } label: {
            Text("Add to Calendar")
                .font(.appBody.weight(.semibold))
                .foregroundStyle(.inkSecondary)
                .frame(maxWidth: .infinity)
                .frame(height: 44)
                .background(Color.border.opacity(0.25))
                .clipShape(.rect(cornerRadius: CornerRadius.button))
        }
    }

    private var rsvpButtonLabel: String {
        switch rsvpStatus {
        case .going:    "Going ✓"
        case .notGoing: "Not Going"
        case nil:       "RSVP"
        }
    }

    private var rsvpBackgroundColor: Color {
        rsvpStatus == .notGoing ? .cardBackground : .accent
    }

    private var rsvpForegroundColor: Color {
        rsvpStatus == .notGoing ? .inkSecondary : .white
    }

    // MARK: - Calendar 

    private func addToCalendar() async {
        let result = await CalendarService.shared.addMeeting(meeting)
        switch result {
        case .success:            calendarAlertType = .added(title: meeting.title)
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

// MARK: - Mini avatar stack

private struct RSVPAvatarStack: View {
    let members: [RSVPMember]

    private let size: CGFloat    = 26
    private let overlap: CGFloat = 8
    private let maxShown         = 4

    var body: some View {
        HStack(spacing: -overlap) {
            ForEach(members.prefix(maxShown)) { member in
                AsyncImage(url: member.avatarURL.flatMap { URL(string: $0) }) { image in
                    image.resizable().scaledToFill()
                } placeholder: {
                    Circle()
                        .fill(Color.purpleTint)
                        .overlay {
                            Image(systemName: "person.fill")
                                .font(.system(size: 10))
                                .foregroundStyle(.accent)
                        }
                }
                .frame(width: size, height: size)
                .clipShape(.circle)
                .overlay { Circle().stroke(Color.cardBackground, lineWidth: 1.5) }
            }
        }
    }
}

// MARK: - RSVP list sheet

struct RSVPListSheet: View {
    let meetingTitle: String
    let rsvpMembers: [RSVPMember]
    let goingCount: Int
    let notGoingCount: Int

    @Environment(\.dismiss) private var dismiss

    private var going: [RSVPMember]    { rsvpMembers.filter { $0.status == .going    } }
    private var notGoing: [RSVPMember] { rsvpMembers.filter { $0.status == .notGoing } }

    var body: some View {
        NavigationStack {
            ZStack {
                Color.background.ignoresSafeArea()
                Group {
                    if rsvpMembers.isEmpty {
                        ContentUnavailableView(
                            "No RSVPs yet",
                            systemImage: "person.slash",
                            description: Text("Be the first to RSVP to this meeting.")
                        )
                    } else {
                        List {
                            if !going.isEmpty {
                                Section("Going (\(goingCount))") {
                                    ForEach(going) { RSVPMemberRow(member: $0) }
                                }
                            }
                            if !notGoing.isEmpty {
                                Section("Not Going (\(notGoingCount))") {
                                    ForEach(notGoing) { RSVPMemberRow(member: $0) }
                                }
                            }
                        }
                        .listStyle(.insetGrouped)
                        .scrollContentBackground(.hidden)
                    }
                }
            }
            .navigationTitle(meetingTitle)
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Button("Done") { dismiss() }
                        .foregroundStyle(.accent)
                }
            }
        }
    }
}

private struct RSVPMemberRow: View {
    let member: RSVPMember

    var body: some View {
        HStack(spacing: Spacing.md) {
            AsyncImage(url: member.avatarURL.flatMap { URL(string: $0) }) { image in
                image.resizable().scaledToFill()
            } placeholder: {
                Circle()
                    .fill(Color.purpleTint)
                    .overlay {
                        Image(systemName: "person.fill").foregroundStyle(.accent)
                    }
            }
            .frame(width: 40, height: 40)
            .clipShape(.circle)

            Text(member.displayName)
                .font(.appBody)
                .foregroundStyle(.inkPrimary)
        }
        .listRowBackground(Color.cardBackground)
    }
}

// MARK: - Preview

#Preview {
    MeetingBannerView(
        meeting: Meeting(
            id: UUID(),
            clubId: UUID(),
            title: "Book Discussion: Chapters 1-10",
            scheduledAt: .now.addingTimeInterval(3600 * 24 * 3),
            fromChapter: 1,
            toChapter: 10,
            chapterTitles: nil,
            notes: nil,
            address: "123 Main St",
            isFinal: false,
            notifSent24h: false,
            notifSent1h: false,
            createdAt: .now,
            clubName: "Downtown Readers",
            clubCoverImageURL: nil,
            bookTitle: nil,
            bookAuthor: nil,
            bookCoverURL: nil
        ),
        isOrganiser: true,
        rsvpStatus: .going,
        rsvpCounts: RSVPCounts(goingCount: 3, notGoingCount: 1),
        rsvpMembers: [],
        onRSVP: { _ in },
        onEdit: {}
    )
    .padding(Spacing.lg)
}
