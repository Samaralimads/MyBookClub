//
//  BookStarRating.swift
//  MyBookClub
//
//  Created by Samara Lima da Silva on 01/04/2026.
//

import SwiftUI

struct BookStarRating: View {
    let rating: Double
    var size: CGFloat = 20
    let onRate: (Double) -> Void

    var body: some View {
        HStack(spacing: 4) {
            ForEach(1 ... 5, id: \.self) { index in
                HalfStarButton(index: index, rating: rating, size: size, onRate: onRate)
            }
        }
    }
}

// MARK: - Read-only display (single star + number)

struct StarRatingReadOnly: View {
    let rating: Double
    var size: CGFloat = 14

    var body: some View {
        HStack(spacing: 3) {
            Image(systemName: "star.fill")
                .font(.system(size: size))
                .foregroundStyle(.starGold)
            Text(rating, format: .number.precision(.fractionLength(1)))
                .font(.system(size: size, weight: .semibold))
                .foregroundStyle(.inkPrimary)
        }
    }
}

// MARK: - Read-only 5-star display

struct StarRatingRow: View {
    let rating: Double
    var size: CGFloat = 20

    var body: some View {
        HStack(spacing: 4) {
            ForEach(1 ... 5, id: \.self) { index in
                StarShape(fill: StarFill(index: index, rating: rating), size: size)
            }
        }
    }
}

// MARK: - Internal: half-star tap button

private struct HalfStarButton: View {
    let index: Int
    let rating: Double
    let size: CGFloat
    let onRate: (Double) -> Void

    var body: some View {
        ZStack(alignment: .leading) {
            // Left half → n - 0.5
            Color.clear
                .contentShape(.rect)
                .onTapGesture { onRate(max(0.5, Double(index) - 0.5)) }
                .frame(width: size / 2, height: size)

            // Right half → n
            Color.clear
                .contentShape(.rect)
                .onTapGesture { onRate(Double(index)) }
                .frame(width: size / 2, height: size)
                .offset(x: size / 2)
        }
        .frame(width: size, height: size)
        .overlay {
            StarShape(fill: StarFill(index: index, rating: rating), size: size)
                .allowsHitTesting(false)
        }
        .sensoryFeedback(.selection, trigger: rating)
    }
}

// MARK: - Internal: star shape renderer

private struct StarShape: View {
    let fill: StarFill
    let size: CGFloat

    var body: some View {
        Image(systemName: fill.systemImage)
            .font(.system(size: size))
            .foregroundStyle(fill == .empty ? .inkTertiary : .starGold)
            .frame(width: size, height: size)
    }
}

// MARK: - Internal: fill state

private enum StarFill {
    case full, half, empty

    init(index: Int, rating: Double) {
        if rating >= Double(index) { self = .full }
        else if rating >= Double(index) - 0.5 { self = .half }
        else { self = .empty }
    }

    var systemImage: String {
        switch self {
        case .full:  "star.fill"
        case .half:  "star.leadinghalf.filled"
        case .empty: "star"
        }
    }
}

// MARK: - Preview

//#Preview {
//    VStack(spacing: Spacing.xl) {
//        BookStarRating(rating: 4.5, onRate: { _ in })
//        BookStarRating(rating: 2.5, onRate: { _ in })
//        StarRatingRow(rating: 4.2)
//        StarRatingReadOnly(rating: 3.7)
//    }
//    .padding()
//}
