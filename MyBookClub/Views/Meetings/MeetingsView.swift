//
//  MeetingsView.swift
//  MyBookClub
//
//  Created by Samara Lima da Silva on 09/03/2026.
//

import SwiftUI

struct MeetingsView: View {
    @State private var vm = MeetingsViewModel()
    @State private var selectedSegment: MeetingSegment = .upcoming
    @State private var selectedMeeting: Meeting? = nil

    var body: some View {
        ZStack {
            Color.background.ignoresSafeArea()

            VStack(spacing: 0) {
                segmentPicker
                    .padding(.horizontal, Spacing.lg)
                    .padding(.top, Spacing.md)
                    .padding(.bottom, Spacing.sm)

                meetingList
            }
            .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .top)
        }
        .navigationTitle("Meetings")
        .navigationBarTitleDisplayMode(.large)
        .task { await vm.load() }
        .navigationDestination(for: Meeting.self) { meeting in
            MeetingDetailView(meeting: meeting)
        }
    }

    // MARK: - Segment Picker

    private var segmentPicker: some View {
        Picker("Meetings", selection: $selectedSegment) {
            ForEach(MeetingSegment.allCases) { segment in
                Text(segment.label).tag(segment)
            }
        }
        .pickerStyle(.segmented)
    }

    // MARK: - Meeting List

    @ViewBuilder
    private var meetingList: some View {
        let meetings = selectedSegment == .upcoming ? vm.upcomingMeetings : vm.pastMeetings

        if vm.isLoading {
            Spacer()
            ProgressView()
                .tint(.accent)
            Spacer()
        } else if meetings.isEmpty {
            emptyState
        } else {
            ScrollView {
                LazyVStack(spacing: Spacing.md) {
                    ForEach(meetings) { meeting in
                        NavigationLink(value: meeting) {
                            MeetingCard(meeting: meeting)
                        }
                        .buttonStyle(.plain)
                    }
                }
                .padding(.horizontal, Spacing.lg)
                .padding(.vertical, Spacing.md)
            }
            .scrollIndicators(.hidden)
        }
    }

    // MARK: - Empty State

    private var emptyState: some View {
        EmptyStateView(
            icon: "calendar",
            title: selectedSegment == .upcoming ? "No Upcoming Meetings" : "No Past Meetings",
            description: selectedSegment == .upcoming
                ? "Meetings from your clubs will appear here."
                : "Past meetings will appear here once they've taken place."
        )
    }
}

// MARK: - Segment

enum MeetingSegment: String, CaseIterable, Identifiable {
    case upcoming, past

    var id: String { rawValue }

    var label: String {
        switch self {
        case .upcoming: "Upcoming"
        case .past:     "Past"
        }
    }
}

// MARK: - Preview

#Preview {
    NavigationStack {
        MeetingsView()
    }
}
