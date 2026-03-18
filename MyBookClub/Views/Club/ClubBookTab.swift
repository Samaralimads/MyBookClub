//
//  ClubBookTab.swift
//  MyBookClub
//
//  Created by Samara Lima da Silva on 10/03/2026.
//

import SwiftUI

struct ClubBookTab: View {
    let club: Club
    let isMember: Bool
    let isOrganiser: Bool
    let nextMeeting: Meeting?
    let onBookChanged: ((Book) -> Void)?

    @State private var vm = ClubBookViewModel()
    @State private var showBookSearch = false

    var body: some View {
        VStack(alignment: .leading, spacing: Spacing.xl) {
            if let book = club.currentBook {
                currentBookSection(book: book)

                if let meeting = nextMeeting, let range = meeting.chapterRange {
                    chaptersChecklistSection(book: book, meeting: meeting, range: range)
                }
            } else {
                emptyState
            }

            if isOrganiser {
                setBookButton
            }
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(.bottom, Spacing.xxl)
        .task { await vm.load(club: club, isMember: isMember) }
        .sheet(isPresented: $showBookSearch) {
            BookSearchSheet { selectedBook in
                Task {
                    await vm.setCurrentBook(club: club, book: selectedBook)
                    onBookChanged?(selectedBook)
                }
            }
        }
    }

    // MARK: - Current Book

    private func currentBookSection(book: Book) -> some View {
        HStack(spacing: Spacing.lg) {
            AsyncImage(url: book.displayCoverURL) { image in
                image.resizable().scaledToFill()
            } placeholder: {
                Color.purpleTint
            }
            .frame(width: 90, height: 134)
            .clipShape(.rect(cornerRadius: CornerRadius.badge))
            .shadow(color: .black.opacity(0.15), radius: 6, y: 3)

            VStack(alignment: .leading, spacing: Spacing.sm) {
                Text("Reading Now")
                    .font(.appCaption.bold())
                    .foregroundStyle(.accent)
                    .tracking(0.6)
                Text(book.title)
                    .font(.appHeadline)
                    .foregroundStyle(.inkPrimary)
                    .lineLimit(3)
                Text(book.author)
                    .font(.appBody)
                    .foregroundStyle(.inkSecondary)

                if let meeting = nextMeeting, let range = meeting.chapterRange,
                   isMember {
                    let completed = vm.readingProgress?.completedChapters.count ?? 0
                    let total = range.count
                    let progress = total > 0 ? Double(completed) / Double(total) : 0

                    VStack(alignment: .leading, spacing: 4) {
                        HStack {
                            Text("Progress Goal")
                                .font(.appCaption)
                                .foregroundStyle(.inkSecondary)
                            Spacer()
                            Text("\(Int(progress * 100))%")
                                .font(.appCaption.bold())
                                .foregroundStyle(.inkSecondary)
                        }
                        ProgressView(value: progress)
                            .tint(progress >= 1.0 ? .green : .accent)
                            .animation(.easeInOut, value: progress)
                    }
                    .padding(.top, Spacing.xs)
                }
            }
        }
    }

    // MARK: - Chapters Checklist

    private func chaptersChecklistSection(book: Book, meeting: Meeting, range: ClosedRange<Int>) -> some View {
        VStack(alignment: .leading, spacing: Spacing.md) {
            Text("Chapters for next meeting")
                .font(.appHeadline)
                .foregroundStyle(.inkPrimary)

            VStack(spacing: Spacing.sm) {
                ForEach(range, id: \.self) { chapter in
                    ChapterChecklistRow(
                        chapter: chapter,
                        title: meeting.title(for: chapter),
                        isChecked: vm.readingProgress?.isCompleted(chapter) ?? false
                    ) {
                        Task {
                            await vm.toggleChapter(
                                clubId: club.id,
                                bookId: book.id,
                                chapter: chapter
                            )
                        }
                    }
                }
            }
        }
    }

    // MARK: - Empty State

    private var emptyState: some View {
        VStack(spacing: Spacing.md) {
            Image(systemName: "book.closed")
                .font(.system(size: 36))
                .foregroundStyle(.inkTertiary)
            Text("No book selected yet")
                .font(.appBody)
                .foregroundStyle(.inkSecondary)
            if isOrganiser {
                Text("Use the button below to set your club's first read.")
                    .font(.appCaption)
                    .foregroundStyle(.inkTertiary)
                    .multilineTextAlignment(.center)
            }
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, Spacing.xxl)
    }

    // MARK: - Set Book (organiser only)

    private var setBookButton: some View {
        Button {
            showBookSearch = true
        } label: {
            Label(
                club.currentBook == nil ? "Set Current Book" : "Change Book",
                systemImage: "magnifyingglass"
            )
            .frame(maxWidth: .infinity)
        }
        .buttonStyle(SecondaryButtonStyle())
        .disabled(vm.isSettingBook)
    }
}

// MARK: - Chapter Row

struct ChapterChecklistRow: View {
    let chapter: Int
    let title: String?
    let isChecked: Bool
    let onToggle: () -> Void

    var body: some View {
        HStack(spacing: Spacing.md) {
            ZStack {
                Circle()
                    .fill(Color.purpleTint)
                    .frame(width: 36, height: 36)
                Image(systemName: "book")
                    .font(.system(size: 14))
                    .foregroundStyle(.accent)
            }

            VStack(alignment: .leading, spacing: 2) {
                if let title {
                    Text("Chapter \(chapter): \(title)")
                        .font(.appBody.bold())
                        .foregroundStyle(.inkPrimary)
                } else {
                    Text("Chapter \(chapter)")
                        .font(.appBody.bold())
                        .foregroundStyle(.inkPrimary)
                }
            }

            Spacer()

                Button(action: onToggle) {
                    ZStack {
                        Circle()
                            .fill(isChecked ? Color.accent : Color.clear)
                            .frame(width: 28, height: 28)
                        Circle()
                            .strokeBorder(isChecked ? Color.accent : Color.border, lineWidth: 1.5)
                            .frame(width: 28, height: 28)
                        if isChecked {
                            Image(systemName: "checkmark")
                                .font(.system(size: 12, weight: .bold))
                                .foregroundStyle(.white)
                        }
                    }
                    .animation(.spring(duration: 0.2), value: isChecked)
                }
                .frame(width: 44, height: 44)
                .contentShape(.rect)
        }
        .padding(Spacing.md)
        .background(Color.cardBackground)
        .clipShape(.rect(cornerRadius: CornerRadius.card))
    }
}
