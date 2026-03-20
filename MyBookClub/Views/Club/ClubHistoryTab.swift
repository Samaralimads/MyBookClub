//
//  ClubHistoryTab.swift
//  MyBookClub
//
//  Created by Samara Lima da Silva on 10/03/2026.
//

import SwiftUI

struct ClubHistoryTab: View {
    let club: Club

    @State private var vm = ClubHistoryViewModel()

    var body: some View {
        Group {
            if vm.isLoading {
                ProgressView()
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, Spacing.xxl)
            } else if vm.entries.isEmpty {
                emptyState
            } else {
                bookList
            }
        }
        .padding(.bottom, Spacing.xxl)
        .task { await vm.load(club: club) }
    }

    // MARK: - Book list

    private var bookList: some View {
        VStack(alignment: .leading, spacing: Spacing.lg) {
            Text("Past Books")
                .font(.appHeadline)
                .foregroundStyle(.inkPrimary)

            VStack(spacing: Spacing.md) {
                ForEach(vm.entries) { entry in
                    historyRow(entry: entry)
                }
            }
        }
    }

    private func historyRow(entry: ClubBookHistory) -> some View {
        HStack(spacing: Spacing.md) {
            AsyncImage(url: entry.book.displayCoverURL) { image in
                image.resizable().scaledToFill()
            } placeholder: {
                Color.purpleTint
            }
            .frame(width: 52, height: 78)
            .clipShape(.rect(cornerRadius: CornerRadius.badge))
            .shadow(color: .black.opacity(0.15), radius: 4, y: 2)

            VStack(alignment: .leading, spacing: Spacing.xs) {
                Text(entry.book.title)
                    .font(.appHeadline)
                    .foregroundStyle(.inkPrimary)
                    .lineLimit(2)

                Text(entry.book.author)
                    .font(.appBody)
                    .foregroundStyle(.inkSecondary)
                    .lineLimit(1)

                Text("Finished \(entry.finishedAt, format: .dateTime.month(.wide).year())")
                    .font(.appCaption)
                    .foregroundStyle(.inkTertiary)
            }

            Spacer()
        }
        .padding(Spacing.md)
        .background(Color.cardBackground)
        .clipShape(.rect(cornerRadius: CornerRadius.card))
        .overlay {
            RoundedRectangle(cornerRadius: CornerRadius.card)
                .stroke(Color.border, lineWidth: 1)
        }
        .shadow(color: .black.opacity(0.06), radius: 12, x: 0, y: 4)
    }

    // MARK: - Empty state

    private var emptyState: some View {
        VStack(spacing: Spacing.md) {
            Image(systemName: "books.vertical")
                .font(.system(size: 36))
                .foregroundStyle(.inkTertiary)
            Text("No books finished yet")
                .font(.appBody)
                .foregroundStyle(.inkSecondary)
            Text("Completed books will appear here once your final meeting is done.")
                .font(.appCaption)
                .foregroundStyle(.inkTertiary)
                .multilineTextAlignment(.center)
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, Spacing.xxl)
    }
}

