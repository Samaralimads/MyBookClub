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
    let onBookChanged: ((Book) -> Void)?

    @State private var vm = ClubBookViewModel()
    @State private var showBookSearch = false
    @State private var draftChapter: Int = 0

    var body: some View {
        VStack(alignment: .leading, spacing: Spacing.xl) {
            if let book = club.currentBook {
                currentBookSection(book: book)
                if let meeting = vm.nextMeeting, let due = meeting.chaptersDue {
                    chaptersDueSection(due: due, meeting: meeting)
                }
                if isMember {
                    readingProgressSection(book: book)
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
        .onAppear {
            draftChapter = vm.readingProgress?.currentChapter ?? 0
        }
        .onChange(of: vm.readingProgress) { _, progress in
            draftChapter = progress?.currentChapter ?? 0
        }
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
            .clipShape(RoundedRectangle(cornerRadius: CornerRadius.badge))
            .shadow(color: .black.opacity(0.15), radius: 6, y: 3)

            VStack(alignment: .leading, spacing: Spacing.sm) {
                Text("Reading Now")
                    .font(.appCaption.weight(.semibold))
                    .foregroundStyle(.accent)
                    .tracking(0.6)
                Text(book.title)
                    .font(.appHeadline)
                    .foregroundStyle(.inkPrimary)
                    .lineLimit(3)
                Text(book.author)
                    .font(.appBody)
                    .foregroundStyle(.inkSecondary)
            }
        }
    }

    // MARK: - Chapters Due

    private func chaptersDueSection(due: Int, meeting: Meeting) -> some View {
        VStack(alignment: .leading, spacing: Spacing.sm) {
            Text("Next Meeting Target")
                .font(.appHeadline)
                .foregroundStyle(.inkPrimary)

            HStack(spacing: Spacing.md) {
                Image(systemName: "bookmark.fill")
                    .foregroundStyle(.accent)
                Text("Chapter \(due) by \(meeting.scheduledAt, format: .dateTime.day().month())")
                    .font(.appBody)
                    .foregroundStyle(.inkSecondary)
            }
        }
    }

    // MARK: - Reading Progress

    private func readingProgressSection(book: Book) -> some View {
        VStack(alignment: .leading, spacing: Spacing.sm) {
            Text("My Progress")
                .font(.appHeadline)
                .foregroundStyle(.inkPrimary)

            HStack(spacing: Spacing.md) {
                Image(systemName: "book.pages")
                    .foregroundStyle(.accent)

                Text("Chapter \(draftChapter)")
                    .font(.appBody.weight(.semibold))
                    .foregroundStyle(.inkPrimary)
                    .frame(minWidth: 80, alignment: .leading)

                Spacer()

                Stepper("", value: $draftChapter, in: 0...999)
                    .labelsHidden()
                    .onChange(of: draftChapter) { _, chapter in
                        Task {
                            await vm.updateProgress(
                                clubId: club.id,
                                bookId: book.id,
                                chapter: chapter
                            )
                        }
                    }
            }
            .padding(Spacing.md)
            .background(Color.cardBackground)
            .clipShape(RoundedRectangle(cornerRadius: CornerRadius.card))

            if let due = vm.nextMeeting?.chaptersDue, due > 0 {
                let progress = min(Double(draftChapter) / Double(due), 1.0)
                ProgressView(value: progress)
                    .tint(progress >= 1.0 ? .green : .accent)
                    .animation(.easeInOut, value: progress)
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

