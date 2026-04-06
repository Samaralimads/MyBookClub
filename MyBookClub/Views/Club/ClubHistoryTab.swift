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
    @State private var currentIndex = 0
    @State private var dragOffset: CGFloat = 0
    
    var body: some View {
        Group {
            if vm.isLoading {
                ProgressView()
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, Spacing.xxl)
                    .padding(.horizontal, Spacing.lg)
            } else if vm.entries.isEmpty {
                EmptyStateView(
                    icon: "books.vertical",
                    title: "No books finished yet",
                    description: "Completed books will appear here once your final meeting is done."
                )
                .padding(.horizontal, Spacing.lg)
            } else {
                carousel
            }
        }
        .padding(.bottom, Spacing.xxl)
        .task { await vm.load(club: club) }
    }
    
    // MARK: - Carousel
    
    private var carousel: some View {
        VStack(spacing: Spacing.xl) {
            Text("Past Books")
                .font(.appHeadline)
                .foregroundStyle(.inkPrimary)
                .frame(maxWidth: .infinity, alignment: .leading)
                .padding(.horizontal, Spacing.lg)
            
            fanStack
            
            bookInfo
                .padding(.horizontal, Spacing.lg)
            
            paginationDots
            
            if currentIndex < vm.entries.count {
                let entry = vm.entries[currentIndex]
                let rating = vm.ratings[entry.book.id]
                HistoryRatingCards(
                    rating: rating,
                    onRate: { stars in
                        Task {
                            await vm.submitRating(
                                clubId: club.id,
                                bookId: entry.book.id,
                                stars: stars
                            )
                        }
                    }
                )
                .padding(.horizontal, Spacing.lg)
                .id(currentIndex)
            }
        }
    }
    
    // MARK: - Fan stack
    
    private var fanStack: some View {
        Color.clear
            .frame(maxWidth: .infinity)
            .frame(height: 210)
            .overlay {
                ZStack {
                    ForEach(cardIndices, id: \.self) { index in
                        let offset = index - currentIndex
                        FanCard(
                            entry: vm.entries[index],
                            stackOffset: offset,
                            dragOffset: offset == 0 ? dragOffset : 0
                        )
                        .zIndex(offset == 0 ? 10 : abs(offset) == 1 ? 5 : 0)
                    }
                }
            }
            .contentShape(.rect)
            .gesture(
                DragGesture(minimumDistance: 20, coordinateSpace: .local)
                    .onChanged { value in
                        guard abs(value.translation.width) > abs(value.translation.height) else { return }
                        dragOffset = value.translation.width
                    }
                    .onEnded { value in
                        let threshold: CGFloat = 60
                        withAnimation(.spring(response: 0.38, dampingFraction: 0.72)) {
                            if value.translation.width < -threshold, currentIndex < vm.entries.count - 1 {
                                currentIndex += 1
                            } else if value.translation.width > threshold, currentIndex > 0 {
                                currentIndex -= 1
                            }
                            dragOffset = 0
                        }
                    }
            )
    }
    
    private var cardIndices: [Int] {
        let start = max(0, currentIndex - 2)
        let end = min(vm.entries.count - 1, currentIndex + 2)
        return Array(start ... end)
    }
    
    // MARK: - Book info
    
    private var bookInfo: some View {
        Group {
            if currentIndex < vm.entries.count {
                let entry = vm.entries[currentIndex]
                VStack(spacing: Spacing.xs) {
                    Text(entry.book.author)
                        .font(.appBody)
                        .foregroundStyle(.inkSecondary)
                    Text(entry.book.title.uppercased())
                        .font(.appTitle)
                        .foregroundStyle(.inkPrimary)
                        .multilineTextAlignment(.center)
                        .lineLimit(3)
                    Text("Finished \(entry.finishedAt, format: .dateTime.month(.wide).year())")
                        .font(.appCaption)
                        .foregroundStyle(.inkTertiary)
                }
                .multilineTextAlignment(.center)
                .transition(.opacity.combined(with: .move(edge: .bottom)))
                .id(currentIndex)
            }
        }
        .animation(.easeInOut(duration: 0.22), value: currentIndex)
    }
    
    // MARK: - Pagination dots
    
    private var paginationDots: some View {
        HStack(spacing: 6) {
            ForEach(0 ..< vm.entries.count, id: \.self) { index in
                Capsule()
                    .fill(index == currentIndex ? Color.accent : Color.border)
                    .frame(width: index == currentIndex ? 16 : 6, height: 6)
                    .animation(.spring(response: 0.3, dampingFraction: 0.7), value: currentIndex)
            }
        }
    }
}

// MARK: - Fan Card

private struct FanCard: View {
    let entry: ClubBookHistory
    let stackOffset: Int
    let dragOffset: CGFloat
    
    private let cardWidth: CGFloat = 120
    private let cardHeight: CGFloat = 170
    
    var body: some View {
        AsyncImage(url: entry.book.displayCoverURL) { image in
            image.resizable().scaledToFill()
        } placeholder: {
            Color.purpleTint
                .overlay {
                    Image(systemName: "book.closed.fill")
                        .font(.system(size: 32))
                        .foregroundStyle(.accent)
                }
        }
        .frame(width: cardWidth, height: cardHeight)
        .clipShape(.rect(cornerRadius: 20))
        .shadow(
            color: .black.opacity(stackOffset == 0 ? 0.45 : 0.25),
            radius: stackOffset == 0 ? 20 : 8,
            y: 4
        )
        .scaleEffect(scale)
        .rotationEffect(.degrees(rotation))
        .offset(x: xOffset, y: yOffset)
        .opacity(opacity)
        .animation(.spring(response: 0.38, dampingFraction: 0.72), value: stackOffset)
        .animation(.spring(response: 0.38, dampingFraction: 0.72), value: dragOffset)
    }
    
    private var xOffset: CGFloat {
        switch stackOffset {
        case 0:  return dragOffset * 0.35
        case -1: return -90
        case  1: return  90
        default: return CGFloat(stackOffset) * 90
        }
    }
    
    private var yOffset: CGFloat { stackOffset == 0 ? 0 : 18 }
    
    private var rotation: Double {
        switch stackOffset {
        case 0:  return Double(dragOffset) * 0.025
        case -1: return -7
        case  1: return  7
        default: return Double(stackOffset) * 7
        }
    }
    
    private var scale: CGFloat {
        switch abs(stackOffset) {
        case 0:  return 1.0
        case 1:  return 0.87
        default: return 0.76
        }
    }
    
    private var opacity: Double {
        switch abs(stackOffset) {
        case 0:  return 1.0
        case 1:  return 0.72
        case 2:  return 0.4
        default: return 0
        }
    }
}

// MARK: - Rating Cards

struct HistoryRatingCards: View {
    let rating: BookRating?
    let onRate: (Double) -> Void
    
    var body: some View {
        HStack(spacing: Spacing.md) {
            RatingCard(label: "My Rating") {
                BookStarRating(
                    rating: rating?.myRating ?? 0,
                    onRate: onRate
                )
                ratingLabel(rating?.myRating)
            }
            RatingCard(label: "Group Avg") {
                StarRatingRow(rating: rating?.avgRating ?? 0)
                ratingLabel(rating?.avgRating)
            }
        }
    }
    
    @ViewBuilder
    private func ratingLabel(_ value: Double?) -> some View {
        if let value {
            Text(value, format: .number.precision(.fractionLength(1)).locale(Locale(identifier: "en_US")))
                .font(.system(size: 22, weight: .bold, design: .rounded))
                .foregroundStyle(.inkPrimary)
        } else {
            Text("—")
                .font(.system(size: 22, weight: .bold, design: .rounded))
                .foregroundStyle(.inkTertiary)
        }
    }
}

// MARK: - Rating Card container

private struct RatingCard<Content: View>: View {
    let label: String
    @ViewBuilder let content: Content
    
    var body: some View {
        VStack(spacing: Spacing.sm) {
            Text(label.uppercased())
                .font(.system(size: 10, weight: .bold))
                .foregroundStyle(.inkTertiary)
                .kerning(0.8)
            content
        }
        .frame(maxWidth: .infinity)
        .padding(Spacing.md)
        .background(Color.cardBackground)
        .clipShape(.rect(cornerRadius: CornerRadius.card))
        .overlay {
            RoundedRectangle(cornerRadius: CornerRadius.card)
                .stroke(Color.border, lineWidth: 1)
        }
    }
}
