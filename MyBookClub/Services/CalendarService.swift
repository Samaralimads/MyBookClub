//
//  CalendarService.swift
//  MyBookClub
//
//  Created by Samara Lima da Silva on 01/04/2026.
//

import EventKit

enum CalendarResult {
    case success
    case denied
    case failure(Error)
}

@MainActor
final class CalendarService {
    static let shared = CalendarService()
    private init() {}

    private let store = EKEventStore()

    func addMeeting(_ meeting: Meeting) async -> CalendarResult {
        do {
            let granted = try await store.requestWriteOnlyAccessToEvents()
            guard granted else { return .denied }
        } catch {
            return .failure(error)
        }

        let event = EKEvent(eventStore: store)
        event.title     = meeting.title
        event.startDate = meeting.scheduledAt
        event.endDate   = meeting.scheduledAt.addingTimeInterval(7_200) // 2 hours
        event.notes     = meeting.notes
        if let address = meeting.address, !address.isEmpty {
            event.structuredLocation = EKStructuredLocation(title: address)
        }
        event.addAlarm(EKAlarm(relativeOffset: -3_600)) // 1 hour before
        event.calendar = store.defaultCalendarForNewEvents

        do {
            try store.save(event, span: .thisEvent)
            return .success
        } catch {
            return .failure(error)
        }
    }
}
