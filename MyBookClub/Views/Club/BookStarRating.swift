//
//  BookStarRating.swift
//  MyBookClub
//
//  Created by Samara Lima da Silva on 01/04/2026.
//

import SwiftUI

struct BookStarRating: View {
    let rating: Int
    let onRate: (Int) -> Void
    var size: CGFloat = 24

    var body: some View {
        HStack(spacing: 4) {
            ForEach(1...5, id: \.self) { star in
                Button {
                    onRate(star)
                } label: {
                    Image(systemName: star <= rating ? "star.fill" : "star")
                        .font(.system(size: size))
                        .foregroundStyle(star <= rating ? Color.yellow : Color.inkTertiary)
                }
                .sensoryFeedback(.selection, trigger: rating)
            }
        }
    }
}

struct StarRatingReadOnly: View {
    let rating: Double
    var size: CGFloat = 14

    var body: some View {
        HStack(spacing: 3) {
            Image(systemName: "star.fill")
                .font(.system(size: size))
                .foregroundStyle(Color.yellow)
            Text(rating.formatted(.number.precision(.fractionLength(1))))
                .font(.system(size: size, weight: .semibold))
                .foregroundStyle(.inkPrimary)
        }
    }
}

#Preview {
    VStack(spacing: Spacing.lg) {
        BookStarRating(rating: 3, onRate: { _ in })
        StarRatingReadOnly(rating: 4.2)
    }
    .padding()
    .background(Color.background)
}
