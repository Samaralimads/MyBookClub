//
//  ClubVoteTab.swift
//  MyBookClub
//
//  Created by Samara Lima da Silva on 10/03/2026.
//

import SwiftUI

struct ClubVoteTab: View {
    let club: Club
    let isMember: Bool
    let isOrganiser: Bool

    @State private var vm = ClubVoteViewModel()
    @State private var showBookSearch = false

    private var hasCurrentBook: Bool { club.currentBookId != nil }

    var body: some View {
        VStack(alignment: .leading, spacing: Spacing.lg) {
            if !isMember {
                membersOnlyBanner
            } else if hasCurrentBook {
                currentlyReadingBanner
            } else if vm.isLoading {
                ProgressView()
                    .tint(.accent)
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, Spacing.xxl)
            } else if let session = vm.activeSession {
                activeVoteSection(session: session)
            }
        }
        .padding(.bottom, Spacing.xxl)
        .task { await vm.load(clubId: club.id, hasCurrentBook: hasCurrentBook) }
        .sheet(isPresented: $showBookSearch) {
            BookSearchSheet { book in
                Task { await vm.suggestBook(book, clubId: club.id) }
            }
        }
    }

    // MARK: - Currently reading banner

    private var currentlyReadingBanner: some View {
        VStack(spacing: Spacing.md) {
            Image(systemName: "book.fill")
                .font(.system(size: 32))
                .foregroundStyle(.accent)
            Text("Currently Reading")
                .font(.appHeadline)
                .foregroundStyle(.inkPrimary)
            Text("Voting for the next book opens once you've finished your current read.")
                .font(.appBody)
                .foregroundStyle(.inkSecondary)
                .multilineTextAlignment(.center)
        }
        .frame(maxWidth: .infinity)
        .padding(Spacing.xl)
        .background(Color.accentSubtle)
        .clipShape(RoundedRectangle(cornerRadius: CornerRadius.card))
    }

    // MARK: - Active session

    private func activeVoteSection(session: VoteSession) -> some View {
        VStack(alignment: .leading, spacing: Spacing.lg) {

            // Header banner
            VStack(alignment: .leading, spacing: Spacing.xs) {
                Text("Next Book Voting")
                    .font(.appBody.weight(.semibold))
                    .foregroundStyle(.inkPrimary)
                Text("Suggest and vote for the next book.")
                    .font(.appCaption)
                    .foregroundStyle(.inkSecondary)
            }
            .frame(maxWidth: .infinity, alignment: .leading)
            .padding(Spacing.lg)
            .background(Color.accentSubtle)
            .clipShape(.rect(cornerRadius: CornerRadius.card))

            // Suggestions
            if let suggestions = session.suggestions, !suggestions.isEmpty {
                VStack(spacing: Spacing.md) {
                    ForEach(suggestions) { suggestion in
                        BookSuggestionRow(suggestion: suggestion) {
                            Task {
                                await vm.castVote(
                                    suggestion: suggestion,
                                    sessionId: session.id,
                                    clubId: club.id
                                )
                            }
                        }
                    }
                }
            } else {
                Text("No books suggested yet. Be the first!")
                    .font(.appBody)
                    .foregroundStyle(.inkSecondary)
                    .frame(maxWidth: .infinity, alignment: .center)
                    .padding(.vertical, Spacing.xl)
            }

            // Suggest a Book dashed button
            Button { showBookSearch = true } label: {
                Label("Suggest a Book", systemImage: "plus")
                    .font(.appBody.weight(.medium))
                    .foregroundStyle(.inkSecondary)
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, Spacing.xl)
            }
            .background(Color.clear)
            .clipShape(.rect(cornerRadius: CornerRadius.card))
            .overlay {
                RoundedRectangle(cornerRadius: CornerRadius.card)
                    .strokeBorder(
                        style: StrokeStyle(lineWidth: 1.5, dash: [6, 4])
                    )
                    .foregroundStyle(Color.inkSecondary.opacity(0.4))
            }

            // Organiser: pick winner manually
            if isOrganiser, let suggestions = session.suggestions, !suggestions.isEmpty {
                VStack(alignment: .leading, spacing: Spacing.sm) {
                    Text("Pick the winner")
                        .font(.appBody.weight(.semibold))
                        .foregroundStyle(.inkPrimary)
                    Text("This will set the selected book as your club's current read.")
                        .font(.appCaption)
                        .foregroundStyle(.inkSecondary)

                    ForEach(suggestions) { suggestion in
                        Button {
                            Task {
                                await vm.closeSession(
                                    session: session,
                                    winnerBookId: suggestion.book.id,
                                    clubId: club.id
                                )
                            }
                        } label: {
                            HStack(spacing: Spacing.sm) {
                                AsyncImage(url: suggestion.book.displayCoverURL) { image in
                                    image.resizable().scaledToFill()
                                } placeholder: {
                                    Color.purpleTint
                                }
                                .frame(width: 32, height: 48)
                                .clipShape(.rect(cornerRadius: CornerRadius.badge))

                                VStack(alignment: .leading, spacing: 2) {
                                    Text(suggestion.book.title)
                                        .font(.appBody.weight(.semibold))
                                        .foregroundStyle(.inkPrimary)
                                        .lineLimit(1)
                                    Text("^[\(suggestion.voteCount) vote](inflect: true)")
                                        .font(.appCaption)
                                        .foregroundStyle(.inkSecondary)
                                }
                                Spacer()
                                Image(systemName: "checkmark.circle")
                                    .foregroundStyle(.accent)
                            }
                            .padding(Spacing.md)
                            .background(Color.cardBackground)
                            .clipShape(.rect(cornerRadius: CornerRadius.card))
                            .overlay {
                                RoundedRectangle(cornerRadius: CornerRadius.card)
                                    .stroke(Color.border, lineWidth: 1)
                            }
                        }
                        .disabled(vm.isVoting)
                    }
                }
                .padding(.top, Spacing.sm)
            }

            if let error = vm.error {
                Text(error.message)
                    .font(.appCaption)
                    .foregroundStyle(.red)
            }
        }
    }

    // MARK: - Members only

    private var membersOnlyBanner: some View {
        VStack(spacing: Spacing.md) {
            Image(systemName: "lock.fill")
                .font(.system(size: 28))
                .foregroundStyle(.accent)
            Text("Members Only")
                .font(.appHeadline)
                .foregroundStyle(.inkPrimary)
            Text("Join this club to vote and suggest books.")
                .font(.appBody)
                .foregroundStyle(.inkSecondary)
                .multilineTextAlignment(.center)
        }
        .frame(maxWidth: .infinity)
        .padding(Spacing.xl)
        .background(Color.accentSubtle)
        .clipShape(RoundedRectangle(cornerRadius: CornerRadius.card))
    }
}

// MARK: - Book Suggestion Row

struct BookSuggestionRow: View {
    let suggestion: BookSuggestion
    let onVote: () -> Void

    var body: some View {
        HStack(spacing: Spacing.lg) {

            // Cover
            AsyncImage(url: suggestion.book.displayCoverURL) { image in
                image.resizable().scaledToFill()
            } placeholder: {
                Color.purpleTint
                    .overlay {
                        Image(systemName: "book.closed")
                            .foregroundStyle(.accent.opacity(0.5))
                    }
            }
            .frame(width: 64, height: 96)
            .clipShape(.rect(cornerRadius: CornerRadius.badge))
            .shadow(color: .black.opacity(0.1), radius: 4, y: 2)

            // Info + vote
            VStack(alignment: .leading, spacing: Spacing.xs) {
                Text(suggestion.book.title)
                    .font(.appBody.weight(.semibold))
                    .foregroundStyle(.inkPrimary)
                    .lineLimit(2)
                Text(suggestion.book.author)
                    .font(.appCaption)
                    .foregroundStyle(.inkSecondary)

                HStack(spacing: Spacing.sm) {
                    Button(action: onVote) {
                        HStack(spacing: Spacing.xs) {
                            Image(systemName: suggestion.hasVoted
                                  ? "hand.thumbsup.fill"
                                  : "hand.thumbsup")
                                .font(.system(size: 13))
                            Text("Vote")
                                .font(.appCaption.weight(.medium))
                        }
                        .foregroundStyle(suggestion.hasVoted ? .white : .inkPrimary)
                        .padding(.horizontal, Spacing.md)
                        .frame(height: 32)
                        .background(suggestion.hasVoted ? Color.accent : Color.clear)
                        .clipShape(.rect(cornerRadius: CornerRadius.badge))
                        .overlay {
                            RoundedRectangle(cornerRadius: CornerRadius.badge)
                                .stroke(
                                    suggestion.hasVoted ? Color.accent : Color.inkPrimary,
                                    lineWidth: 1
                                )
                        }
                    }
                    .animation(Animations.standard, value: suggestion.hasVoted)

                    Text("^[\(suggestion.voteCount) vote](inflect: true)")
                        .font(.appCaption.weight(.medium))
                        .foregroundStyle(.inkPrimary)
                }
                .padding(.top, Spacing.xs)
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
    }
}
