//
//  MeetingCard.swift
//  MyBookClub
//
//  Created by Samara Lima da Silva on 01/04/2026.
//

import SwiftUI

struct MeetingCard: View {
    let meeting: Meeting

    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            coverImage

            VStack(alignment: .leading, spacing: Spacing.xs) {
                if let clubName = meeting.clubName {
                    Text(clubName)
                        .font(.appCaption.weight(.semibold))
                        .foregroundStyle(.accent)
                        .lineLimit(1)
                }

                if let bookTitle = meeting.bookTitle {
                    Text(bookTitle)
                        .font(.appHeadline)
                        .foregroundStyle(.inkPrimary)
                        .lineLimit(2)

                    if let author = meeting.bookAuthor {
                        Text("by \(author)")
                            .font(.appCaption)
                            .foregroundStyle(.inkSecondary)
                            .lineLimit(1)
                    }
                } else {
                    Text(meeting.title)
                        .font(.appHeadline)
                        .foregroundStyle(.inkPrimary)
                        .lineLimit(2)
                }

                dateTimeRow
                addressRow
            }
            .padding(Spacing.md)
        }
        .background(Color.cardBackground)
        .clipShape(.rect(cornerRadius: CornerRadius.card))
        .overlay {
            RoundedRectangle(cornerRadius: CornerRadius.card)
                .stroke(Color.border, lineWidth: 1)
        }
    }

    // MARK: - Club cover image

    private var coverImage: some View {
        AsyncImage(url: meeting.clubCoverImageURL.flatMap { URL(string: $0) }) { image in
            image.resizable().scaledToFill()
        } placeholder: {
            Color.purpleTint
                .overlay {
                    Image(systemName: "books.vertical.fill")
                        .foregroundStyle(.accent)
                        .font(.system(size: 32))
                }
        }
        .frame(maxWidth: .infinity)
        .frame(height: 130)
        .clipped()
    }

    // MARK: - Metadata rows

    private var dateTimeRow: some View {
        HStack(spacing: Spacing.sm) {
            Image(systemName: "calendar")
                .font(.system(size: 12))
                .foregroundStyle(.accent)
            Text(meeting.scheduledAt, format: .dateTime.weekday(.wide).month(.wide).day())
                .font(.appCaption)
                .foregroundStyle(.inkSecondary)
            Text("·")
                .foregroundStyle(.inkTertiary)
            Text(meeting.scheduledAt, format: .dateTime.hour().minute())
                .font(.appCaption)
                .foregroundStyle(.inkSecondary)
        }
    }

    @ViewBuilder
    private var addressRow: some View {
        if let address = meeting.address, !address.isEmpty {
            HStack(spacing: Spacing.sm) {
                Image(systemName: "mappin.and.ellipse")
                    .font(.system(size: 12))
                    .foregroundStyle(.accent)
                Text(address)
                    .font(.appCaption)
                    .foregroundStyle(.inkSecondary)
                    .lineLimit(1)
            }
        }
    }
}
