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
                    HistoryBookCard(entry: entry, club: club)
                }
            }
        }
    }

    // MARK: - Empty state

    private var emptyState: some View {
        EmptyStateView(
            icon: "books.vertical",
            title: "No books finished yet",
            description: "Completed books will appear here once your final meeting is done."
        )
    }
}

// MARK: - History Book Card

private struct HistoryBookCard: View {
    let entry: ClubBookHistory
    let club: Club

    @State private var rating: BookRating = BookRating(myRating: nil, avgRating: nil, ratingCount: 0)
    @State private var isRating = false

    var body: some View {
        VStack(alignment: .leading, spacing: Spacing.md) {

            // Book info row
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

                    // Group rating
                    if let avg = rating.avgRating, rating.ratingCount > 0 {
                        HStack(spacing: Spacing.xs) {
                            StarRatingReadOnly(rating: avg)
                            Text("· ^[\(rating.ratingCount) rating](inflect: true)")
                                .font(.appCaption)
                                .foregroundStyle(.inkTertiary)
                        }
                        .padding(.top, Spacing.xs)
                    }
                }

                Spacer()
            }

            Divider().overlay(Color.border)

            // My rating
            VStack(alignment: .leading, spacing: Spacing.sm) {
                Text(rating.myRating == nil ? "Rate this book" : "Your rating")
                    .font(.appCaption)
                    .foregroundStyle(.inkTertiary)

                BookStarRating(rating: rating.myRating ?? 0) { tappedStar in
                    Task { await submitRating(tappedStar) }
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
        .shadow(color: .black.opacity(0.06), radius: 12, x: 0, y: 4)
        .task { await loadRating() }
    }

    // MARK: - Actions

    private func loadRating() async {
        do {
            rating = try await SupabaseService.shared.fetchBookRating(
                clubId: club.id,
                bookId: entry.book.id
            )
        } catch { }
    }

    private func submitRating(_ stars: Int) async {
        // Optimistic update
        rating = BookRating(
            myRating: stars,
            avgRating: rating.avgRating,
            ratingCount: rating.ratingCount
        )
        do {
            try await SupabaseService.shared.upsertBookRating(
                clubId: club.id,
                bookId: entry.book.id,
                rating: stars
            )
            // Reload to get updated group average
            rating = try await SupabaseService.shared.fetchBookRating(
                clubId: club.id,
                bookId: entry.book.id
            )
        } catch { }
    }
}
