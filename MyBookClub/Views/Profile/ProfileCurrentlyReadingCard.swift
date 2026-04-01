//
//  ProfileCurrentlyReadingCard.swift
//  MyBookClub
//
//  Created by Samara Lima da Silva on 09/03/2026.
//

import SwiftUI

struct ProfileCurrentlyReadingCard: View {
    let book: Book
    let clubName: String

    var body: some View {
        HStack(spacing: Spacing.md) {
            coverImage
            bookInfo
        }
        .padding(Spacing.md)
        .cardStyle()
    }

    // MARK: - Subviews

    private var coverImage: some View {
        AsyncImage(url: book.displayCoverURL) { phase in
            switch phase {
            case .success(let image):
                image.resizable().scaledToFill()
            default:
                coverPlaceholder
            }
        }
        .frame(width: 48, height: 68)
        .clipShape(.rect(cornerRadius: CornerRadius.badge))
    }

    private var coverPlaceholder: some View {
        Color.purpleTint
            .overlay {
                Image(systemName: "book.closed")
                    .foregroundStyle(.accent.opacity(0.5))
            }
    }

    private var bookInfo: some View {
        VStack(alignment: .leading, spacing: Spacing.xs) {
            Text(clubName)
                .font(.appCaption.weight(.semibold))
                .foregroundStyle(.accent)
                .lineLimit(1)
            Text(book.title)
                .font(.appBody.weight(.semibold))
                .foregroundStyle(.inkPrimary)
                .lineLimit(2)
            Text(book.author)
                .font(.appCaption)
                .foregroundStyle(.inkSecondary)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
    }
}

#Preview {
    ProfileCurrentlyReadingCard(
        book: Book(
            id: UUID(),
            googleBooksId: "preview",
            title: "The Glass Palace",
            author: "Amitav Ghosh",
            coverURL: nil,
            isbn: nil,
            createdAt: .now
        ),
        clubName: "Paris Literary Circle"
    )
    .padding()
    .background(Color.background)
}
