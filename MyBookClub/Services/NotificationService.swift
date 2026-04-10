//
//  NotificationService.swift
//  MyBookClub
//
//  Created by Samara Lima da Silva on 09/03/2026.
//

import Foundation
import UserNotifications
import UIKit

@Observable
final class NotificationService: NSObject, UNUserNotificationCenterDelegate {
    
    static let shared = NotificationService()
    var isAuthorized = false

    override init() {
        super.init()
        UNUserNotificationCenter.current().delegate = self
    }

    // MARK: - Permission

    func requestPermission() async {
        do {
            let granted = try await UNUserNotificationCenter.current()
                .requestAuthorization(options: [.alert, .sound, .badge])
            isAuthorized = granted
            if granted {
                await MainActor.run {
                    UIApplication.shared.registerForRemoteNotifications()
                }
            }
        } catch {
            isAuthorized = false
        }
    }

    // MARK: - APNs token registration

    /// Call from AppDelegate / SwiftUI .onReceive(NotificationCenter.default.publisher)
    func registerDeviceToken(_ tokenData: Data) async {
        let token = tokenData.map { String(format: "%02.2hhx", $0) }.joined()
        try? await SupabaseService.shared.updateAPNSToken(token)
    }

    // MARK: - Local meeting reminders
    // These are SUPPLEMENTARY to the Supabase Edge Function remote pushes.
    // Schedule when the user creates a meeting while the app is active.

    func scheduleMeetingReminder(meeting: Meeting) {
        guard isAuthorized else { return }

        let content = UNMutableNotificationContent()
        content.title = meeting.title
        content.sound = .default

        // 24h reminder
        let minus24h = meeting.scheduledAt.addingTimeInterval(-86400)
        if minus24h > Date() {
            content.body = "Tomorrow: \(meeting.title)"
            let trigger24 = UNCalendarNotificationTrigger(
                dateMatching: Calendar.current.dateComponents([.year, .month, .day, .hour, .minute], from: minus24h),
                repeats: false
            )
            let request24 = UNNotificationRequest(
                identifier: "meeting-24h-\(meeting.id.uuidString)",
                content: content,
                trigger: trigger24
            )
            UNUserNotificationCenter.current().add(request24)
        }

        // 1h reminder
        let minus1h = meeting.scheduledAt.addingTimeInterval(-3600)
        if minus1h > Date() {
            let content1h = content.mutableCopy() as! UNMutableNotificationContent
            content1h.body = "Starting in 1 hour: \(meeting.title)"
            let trigger1h = UNCalendarNotificationTrigger(
                dateMatching: Calendar.current.dateComponents([.year, .month, .day, .hour, .minute], from: minus1h),
                repeats: false
            )
            let request1h = UNNotificationRequest(
                identifier: "meeting-1h-\(meeting.id.uuidString)",
                content: content1h,
                trigger: trigger1h
            )
            UNUserNotificationCenter.current().add(request1h)
        }
    }

    func cancelMeetingReminders(meetingId: UUID) {
        UNUserNotificationCenter.current().removePendingNotificationRequests(
            withIdentifiers: [
                "meeting-24h-\(meetingId.uuidString)",
                "meeting-1h-\(meetingId.uuidString)",
            ]
        )
    }

    // MARK: - UNUserNotificationCenterDelegate

    /// Show notifications even when app is in foreground
    func userNotificationCenter(
        _ center: UNUserNotificationCenter,
        willPresent notification: UNNotification,
        withCompletionHandler completionHandler: @escaping (UNNotificationPresentationOptions) -> Void
    ) {
        completionHandler([.banner, .sound])
    }
}
