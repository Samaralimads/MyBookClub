//
//  PlanMeetingSheet.swift
//  MyBookClub
//
//  Created by Samara Lima da Silva on 17/03/2026.
//

import SwiftUI
import MapKit

struct PlanMeetingSheet: View {
    let existingMeeting: Meeting?
    let isScheduling: Bool
    let onSchedule: (String, Date, Int?, Int?, [String]?, String?, Bool) -> Void
    let onDismiss: () -> Void

    @State private var fromChapterText = ""
    @State private var toChapterText   = ""
    @State private var includeChapterTitles = false
    @State private var chapterTitles: [String] = []
    @State private var date = Date.now
    @State private var locationText = ""
    @State private var placeSearch  = PlaceSearchService()
    @State private var isFinalMeeting = false

    // MARK: - Derived

    private var fromChapter: Int? { Int(fromChapterText) }
    private var toChapter: Int?   { Int(toChapterText) }

    private var chapterCount: Int {
        guard let from = fromChapter, let to = toChapter, from <= to else { return 0 }
        return to - from + 1
    }

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(alignment: .leading, spacing: Spacing.xl) {
                    headerText
                    readingAssignmentSection
                    dateTimeSection
                    locationSection
                    finalMeetingSection
                    Spacer()
                    actionButtons

                }
                .padding(.horizontal, Spacing.lg)
                .padding(.vertical, Spacing.xl)
            }
            .scrollDismissesKeyboard(.interactively)
            .background(Color.background)
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Button(action: onDismiss) {
                        Image(systemName: "xmark")
                            .font(.system(size: 14, weight: .semibold))
                            .foregroundStyle(.inkSecondary)
                    }
                }
            }
        }
        .onAppear(perform: prefill)
        .onChange(of: chapterCount) { _, count in
            resizeChapterTitles(to: count)
        }
    }

    // MARK: - Header

    private var headerText: some View {
        VStack(alignment: .leading, spacing: Spacing.xs) {
            Text("Plan Next Meeting")
                .font(.appTitle)
                .foregroundStyle(.inkPrimary)
            Text("Set the details for your next discussion.")
                .font(.appBody)
                .foregroundStyle(.inkSecondary)
                .padding(.bottom, 20)
        }
    }

    // MARK: - Reading Assignment

    private var readingAssignmentSection: some View {
        VStack(alignment: .leading, spacing: Spacing.md) {
            Text("Reading Assignment")
                .font(.appHeadline)
                .foregroundStyle(.inkPrimary)

            HStack(spacing: Spacing.md) {
                chapterTextField(label: "From Chapter", text: $fromChapterText, placeholder: "1")
                chapterTextField(label: "To Chapter",   text: $toChapterText,   placeholder: "10")
            }

            // Chapter titles toggle + fields
            VStack(spacing: 0) {
                Toggle(isOn: $includeChapterTitles) {
                    VStack(alignment: .leading, spacing: 2) {
                        Text("Include Chapter Titles")
                            .font(.appBody.weight(.semibold))
                            .foregroundStyle(.inkPrimary)
                        Text("Add specific names to the assigned chapters")
                            .font(.appCaption)
                            .foregroundStyle(.inkSecondary)
                    }
                }
                .tint(.accent)
                .padding(Spacing.md)

                if includeChapterTitles && chapterCount > 0 {
                    Divider()
                    chapterTitlesFields
                }
            }
            .background(Color.cardBackground)
            .clipShape(.rect(cornerRadius: CornerRadius.card))
        }
    }

    private func chapterTextField(label: String, text: Binding<String>, placeholder: String) -> some View {
        VStack(alignment: .leading, spacing: Spacing.xs) {
            Text(label)
                .font(.appCaption)
                .foregroundStyle(.inkSecondary)
            TextField(placeholder, text: text)
                .keyboardType(.numberPad)
                .font(.appBody)
                .foregroundStyle(.inkPrimary)
                .padding(.horizontal, Spacing.md)
                .frame(height: 50)
                .background(Color.cardBackground)
                .clipShape(.rect(cornerRadius: CornerRadius.card))
                .overlay {
                    RoundedRectangle(cornerRadius: CornerRadius.card)
                        .stroke(Color.border, lineWidth: 1)
                }
        }
    }

    private var chapterTitlesFields: some View {
        VStack(spacing: 0) {
            ForEach(0..<chapterCount, id: \.self) { index in
                let chapterNumber = (fromChapter ?? 1) + index
                HStack(spacing: Spacing.md) {
                    Text("Ch \(chapterNumber)")
                        .font(.appCaption.weight(.semibold))
                        .foregroundStyle(.inkSecondary)
                        .frame(width: 40, alignment: .leading)

                    TextField("Title for Chapter \(chapterNumber)", text: titleBinding(at: index))
                        .font(.appBody)
                        .foregroundStyle(.inkPrimary)
                        .padding(.vertical, Spacing.sm)
                }
                .padding(.horizontal, Spacing.md)
                .padding(.vertical, Spacing.xs)

                if index < chapterCount - 1 {
                    Divider().padding(.leading, Spacing.md + 40)
                }
            }
        }
    }

    // MARK: - Date & Time

    private var dateTimeSection: some View {
        HStack(spacing: Spacing.md) {
            VStack(alignment: .leading, spacing: Spacing.xs) {
                Text("Date")
                    .font(.appHeadline)
                    .foregroundStyle(.inkPrimary)
                DatePicker("", selection: $date, displayedComponents: .date)
                    .datePickerStyle(.compact)
                    .labelsHidden()
                    .tint(.accent)
                    .padding(Spacing.md)
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .background(Color.cardBackground)
                    .clipShape(.rect(cornerRadius: CornerRadius.card))
            }

            VStack(alignment: .leading, spacing: Spacing.xs) {
                Text("Time")
                    .font(.appHeadline)
                    .foregroundStyle(.inkPrimary)
                DatePicker("", selection: $date, displayedComponents: .hourAndMinute)
                    .datePickerStyle(.compact)
                    .labelsHidden()
                    .tint(.accent)
                    .padding(Spacing.md)
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .background(Color.cardBackground)
                    .clipShape(.rect(cornerRadius: CornerRadius.card))
            }
        }
    }

    // MARK: - Location (global place autocomplete)

    private var locationSection: some View {
        VStack(alignment: .leading, spacing: Spacing.xs) {
            Text("Location")
                .font(.appHeadline)
                .foregroundStyle(.inkPrimary)

            VStack(alignment: .leading, spacing: 0) {
                // Input row
                HStack(spacing: Spacing.sm) {
                    Image(systemName: "mappin")
                        .font(.system(size: 15))
                        .foregroundStyle(.inkSecondary)
                    TextField("Café, bookshop, address…", text: $locationText)
                        .font(.appBody)
                        .foregroundStyle(.inkPrimary)
                        .autocorrectionDisabled()
                        .onChange(of: locationText) { _, newValue in
                            placeSearch.query = newValue
                        }
                    if !locationText.isEmpty {
                        Button {
                            locationText      = ""
                            placeSearch.query = ""
                        } label: {
                            Image(systemName: "xmark.circle.fill")
                                .foregroundStyle(.inkTertiary)
                        }
                    }
                }
                .padding(.horizontal, Spacing.md)
                .frame(height: 50)
                .background(Color.cardBackground)
                .clipShape(
                    placeSearch.suggestions.isEmpty
                        ? AnyShape(.rect(cornerRadius: CornerRadius.card))
                        : AnyShape(UnevenRoundedRectangle(
                            topLeadingRadius: CornerRadius.card,
                            bottomLeadingRadius: 0,
                            bottomTrailingRadius: 0,
                            topTrailingRadius: CornerRadius.card
                        ))
                )
                .overlay {
                    AnyShape(UnevenRoundedRectangle(
                        topLeadingRadius: CornerRadius.card,
                        bottomLeadingRadius: placeSearch.suggestions.isEmpty ? CornerRadius.card : 0,
                        bottomTrailingRadius: placeSearch.suggestions.isEmpty ? CornerRadius.card : 0,
                        topTrailingRadius: CornerRadius.card
                    ))
                    .stroke(Color.border, lineWidth: 1)
                }

                // Suggestions dropdown
                if !placeSearch.suggestions.isEmpty {
                    VStack(alignment: .leading, spacing: 0) {
                        ForEach(Array(placeSearch.completionResults.enumerated()), id: \.offset) { index, result in
                            Button {
                                locationText      = placeSearch.suggestions[index]
                                placeSearch.query = ""
                            } label: {
                                HStack(spacing: Spacing.sm) {
                                    Image(systemName: "mappin.circle")
                                        .font(.system(size: 14))
                                        .foregroundStyle(.accent)
                                    VStack(alignment: .leading, spacing: 2) {
                                        Text(result.title)
                                            .font(.appBody)
                                            .foregroundStyle(.inkPrimary)
                                            .lineLimit(1)
                                        if !result.subtitle.isEmpty {
                                            Text(result.subtitle)
                                                .font(.appCaption)
                                                .foregroundStyle(.inkSecondary)
                                                .lineLimit(1)
                                        }
                                    }
                                    Spacer()
                                }
                                .padding(.horizontal, Spacing.md)
                                .frame(minHeight: 48)
                                .background(Color.cardBackground)
                            }
                            if index < placeSearch.completionResults.count - 1 {
                                Divider()
                                    .padding(.leading, Spacing.xl + Spacing.md)
                            }
                        }
                    }
                    .clipShape(UnevenRoundedRectangle(
                        topLeadingRadius: 0,
                        bottomLeadingRadius: CornerRadius.card,
                        bottomTrailingRadius: CornerRadius.card,
                        topTrailingRadius: 0
                    ))
                    .overlay {
                        UnevenRoundedRectangle(
                            topLeadingRadius: 0,
                            bottomLeadingRadius: CornerRadius.card,
                            bottomTrailingRadius: CornerRadius.card,
                            topTrailingRadius: 0
                        )
                        .stroke(Color.border, lineWidth: 1)
                    }
                }
            }
        }
    }
    // MARK: - Final Meeting toggle

    private var finalMeetingSection: some View {
        VStack(alignment: .leading, spacing: Spacing.xs) {
            Toggle(isOn: $isFinalMeeting) {
                VStack(alignment: .leading, spacing: 2) {
                    Text("Final meeting for this book")
                        .font(.appHeadline)
                        .foregroundStyle(.inkPrimary)
                    Text("After this meeting ends, the book moves to History.")
                        .font(.appCaption)
                        .foregroundStyle(.inkSecondary)
                }
            }
            .tint(.accent)
            .padding(Spacing.md)
            .background(Color.cardBackground)
            .clipShape(.rect(cornerRadius: CornerRadius.card))
        }
    }
    
    // MARK: - Action Buttons

    private var actionButtons: some View {
        HStack(spacing: Spacing.md) {
            Button("Cancel", action: onDismiss)
                .buttonStyle(SecondaryButtonStyle())

            Button {
                let from = fromChapter
                let to   = toChapter
                let titlesToSend: [String]? = includeChapterTitles && chapterCount > 0
                    ? Array(chapterTitles.prefix(chapterCount))
                    : nil

                let meetingTitle: String
                if let f = from, let t = to, f <= t {
                    meetingTitle = "Book Discussion: Chapters \(f)-\(t)"
                } else {
                    meetingTitle = "Book Discussion"
                }

                onSchedule(
                    meetingTitle,
                    date,
                    from,
                    to,
                    titlesToSend,
                    locationText.isEmpty ? nil : locationText,
                    isFinalMeeting
                )
            } label: {
                Group {
                    if isScheduling {
                        ProgressView().tint(.white)
                    } else {
                        Text("Schedule")
                            .font(.appBody.weight(.semibold))
                    }
                }
                .frame(maxWidth: .infinity)
            }
            .buttonStyle(PrimaryButtonStyle())
            .disabled(isScheduling)
        }
        .padding(.horizontal, Spacing.lg)
        .padding(.vertical, Spacing.md)
        .background(Color.background)
    }

    // MARK: - Helpers

    private func titleBinding(at index: Int) -> Binding<String> {
        Binding(
            get: { chapterTitles.indices.contains(index) ? chapterTitles[index] : "" },
            set: { if chapterTitles.indices.contains(index) { chapterTitles[index] = $0 } }
        )
    }

    private func resizeChapterTitles(to count: Int) {
        if chapterTitles.count < count {
            chapterTitles.append(contentsOf: Array(repeating: "", count: count - chapterTitles.count))
        } else if chapterTitles.count > count {
            chapterTitles = Array(chapterTitles.prefix(count))
        }
    }

    private func prefill() {
        guard let m = existingMeeting else { return }
        fromChapterText = m.fromChapter.map(String.init) ?? ""
        toChapterText   = m.toChapter.map(String.init) ?? ""
        date            = m.scheduledAt
        locationText    = m.address ?? ""
        isFinalMeeting = m.isFinal
        if let titles = m.chapterTitles, !titles.isEmpty {
            includeChapterTitles = true
            chapterTitles = titles
        }
        resizeChapterTitles(to: chapterCount)
    }
}

#Preview {
    PlanMeetingSheet(
        existingMeeting: nil,
        isScheduling: false,
        onSchedule: { _, _, _, _, _, _, _ in },
        onDismiss: {}
    )
}
