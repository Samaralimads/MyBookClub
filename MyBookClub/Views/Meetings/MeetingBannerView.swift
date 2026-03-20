//
//  MeetingBannerView.swift
//  MyBookClub
//
//  Created by Samara Lima da Silva on 17/03/2026.
//

import SwiftUI
import EventKit

struct MeetingBannerView: View {
    let meeting: Meeting

    @State private var calendarAlertType: CalendarAlertType? = nil

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

    var body: some View {
        VStack(alignment: .leading, spacing: Spacing.lg) {

            HStack(alignment: .top) {
                VStack(alignment: .leading, spacing: 2) {
                    Text("Upcoming Meeting")
                        .font(.appHeadline)
                        .foregroundStyle(.inkPrimary)
                    Text(meeting.title)
                        .font(.appBody)
                        .foregroundStyle(.inkSecondary)
                }
            }

            VStack(alignment: .leading, spacing: Spacing.md) {
                meetingRow(
                    icon: "calendar",
                    text: meeting.scheduledAt.formatted(
                        .dateTime.weekday(.wide).month(.wide).day()
                    )
                )
                meetingRow(
                    icon: "clock",
                    text: meeting.scheduledAt.formatted(.dateTime.hour().minute())
                )
                if let address = meeting.address, !address.isEmpty {
                    meetingRow(icon: "mappin.and.ellipse", text: address)
                }
            }

            Button {
                Task { await addToCalendar() }
            } label: {
                Label("Add to Calendar", systemImage: "calendar.badge.plus")
                    .font(.appCaption.weight(.semibold))
                    .foregroundStyle(.accent)
                    .frame(maxWidth: .infinity)
                    .frame(height: 40)
                    .background(Color.accentSubtle)
                    .clipShape(.rect(cornerRadius: CornerRadius.button))
            }
        }
        .padding(Spacing.lg)
        .background(Color.cardBackground)
        .clipShape(.rect(cornerRadius: CornerRadius.card))
        .overlay {
            RoundedRectangle(cornerRadius: CornerRadius.card)
                .stroke(Color.border, lineWidth: 1)
        }
        .shadow(color: .black.opacity(0.06), radius: 12, x: 0, y: 4)
        //Calendar result alerts
        .alert(item: $calendarAlertType) { type in
            switch type {
            case .added(let title):
                return Alert(
                    title: Text("Added to Calendar"),
                    message: Text("\"\(title)\" has been added to your calendar."),
                    dismissButton: .default(Text("Great!"))
                )
            case .denied:
                return Alert(
                    title: Text("Calendar Access Denied"),
                    message: Text("Please allow calendar access in Settings to use this feature."),
                    dismissButton: .default(Text("OK"))
                )
            case .error(let msg):
                return Alert(
                    title: Text("Couldn't Add Event"),
                    message: Text(msg),
                    dismissButton: .default(Text("OK"))
                )
            }
        }
    }

    // MARK: - Row helper

    private func meetingRow(icon: String, text: String) -> some View {
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
                .font(.appBody.weight(.semibold))
                .foregroundStyle(.inkPrimary)
        }
    }

    // MARK: - EventKit

    private func addToCalendar() async {
        let store = EKEventStore()

        let granted: Bool
        do {
            granted = try await store.requestWriteOnlyAccessToEvents()
        } catch {
            calendarAlertType = .error(error.localizedDescription)
            return
        }

        guard granted else {
            calendarAlertType = .denied
            return
        }

        let event        = EKEvent(eventStore: store)
        event.title      = meeting.title
        event.startDate  = meeting.scheduledAt
        event.endDate    = meeting.scheduledAt.addingTimeInterval(7200) // default 2h
        event.notes      = meeting.address

        if let address = meeting.address, !address.isEmpty {
            let location        = EKStructuredLocation(title: address)
            event.structuredLocation = location
        }

        // Add a 1-hour-before alarm
        event.addAlarm(EKAlarm(relativeOffset: -3600))

        event.calendar = store.defaultCalendarForNewEvents

        do {
            try store.save(event, span: .thisEvent)
            calendarAlertType = .added(title: meeting.title)
        } catch {
            calendarAlertType = .error(error.localizedDescription)
        }
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
            address: "Blue Bottle Coffee, Downtown",
            isFinal: false,
            notifSent24h: false,
            notifSent1h: false,
            createdAt: .now,
            clubName: "Downtown Readers"
        )
    )
    .padding(Spacing.lg)
}
